#include "browsercookieextractor.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QStandardPaths>
#include <QTemporaryFile>
#include <QUuid>

BrowserCookieExtractor::BrowserCookieExtractor(QObject *parent)
    : QObject(parent)
{
}

int BrowserCookieExtractor::browserType() const { return m_browserType; }
void BrowserCookieExtractor::setBrowserType(int type)
{
    if (m_browserType != type) {
        m_browserType = type;
        Q_EMIT browserTypeChanged();
    }
}

QString BrowserCookieExtractor::selectedFirefoxProfile() const
{
    return m_selectedFirefoxProfile;
}

void BrowserCookieExtractor::setSelectedFirefoxProfile(const QString &profile)
{
    if (m_selectedFirefoxProfile != profile) {
        m_selectedFirefoxProfile = profile;
        // Invalidate cache when profile changes.
        m_cachedDomain.clear();
        m_cachedCookies.clear();
        m_cacheTimestamp = 0;
        Q_EMIT selectedFirefoxProfileChanged();
        Q_EMIT profilesChanged();
    }
}

bool BrowserCookieExtractor::hasFirefoxProfile() const
{
    return !firefoxProfilePath().isEmpty();
}

QString BrowserCookieExtractor::cookieDbPath() const
{
    switch (m_browserType) {
    case Firefox: {
        QString profile = firefoxProfilePath();
        if (!profile.isEmpty()) {
            return profile + QStringLiteral("/cookies.sqlite");
        }
        break;
    }
    case Chrome:
        return chromeProfilePath() + QStringLiteral("/Cookies");
    case Chromium:
        return chromiumProfilePath() + QStringLiteral("/Cookies");
    }
    return QString();
}

// --- Firefox Profile Detection ---

QString BrowserCookieExtractor::firefoxProfilePath() const
{
    QString mozDir = QDir::homePath() + QStringLiteral("/.mozilla/firefox");
    QDir dir(mozDir);
    if (!dir.exists()) return QString();

    // If user selected a specific profile, try it first.
    if (!m_selectedFirefoxProfile.trimmed().isEmpty()) {
        const QString selectedPath = firefoxProfilePathByName(m_selectedFirefoxProfile.trimmed());
        if (!selectedPath.isEmpty()) {
            return selectedPath;
        }
    }

    // Read profiles.ini to find the default profile
    QString profilesIni = mozDir + QStringLiteral("/profiles.ini");
    if (QFileInfo::exists(profilesIni)) {
        QSettings ini(profilesIni, QSettings::IniFormat);
        QStringList groups = ini.childGroups();

        // Look for default-release profile first, then any default
        for (const QString &group : groups) {
            if (!group.startsWith(QStringLiteral("Profile"))) continue;
            ini.beginGroup(group);
            bool isDefault = ini.value(QStringLiteral("Default"), 0).toInt() == 1;
            QString name = ini.value(QStringLiteral("Name")).toString();
            QString path = ini.value(QStringLiteral("Path")).toString();
            bool isRelative = ini.value(QStringLiteral("IsRelative"), 1).toInt() == 1;
            ini.endGroup();

            if (isDefault || name.contains(QStringLiteral("default-release"))) {
                QString fullPath = isRelative ? (mozDir + QStringLiteral("/") + path) : path;
                if (QFileInfo::exists(fullPath + QStringLiteral("/cookies.sqlite"))) {
                    return fullPath;
                }
            }
        }

        // Fallback: find any profile with cookies.sqlite
        for (const QString &group : groups) {
            if (!group.startsWith(QStringLiteral("Profile"))) continue;
            ini.beginGroup(group);
            QString path = ini.value(QStringLiteral("Path")).toString();
            bool isRelative = ini.value(QStringLiteral("IsRelative"), 1).toInt() == 1;
            ini.endGroup();

            QString fullPath = isRelative ? (mozDir + QStringLiteral("/") + path) : path;
            if (QFileInfo::exists(fullPath + QStringLiteral("/cookies.sqlite"))) {
                return fullPath;
            }
        }
    }

    // Last resort: look for *.default-release directory
    const auto entries = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const auto &entry : entries) {
        if (entry.fileName().endsWith(QStringLiteral(".default-release"))
            || entry.fileName().endsWith(QStringLiteral(".default"))) {
            if (QFileInfo::exists(entry.absoluteFilePath() + QStringLiteral("/cookies.sqlite"))) {
                return entry.absoluteFilePath();
            }
        }
    }

    return QString();
}

QString BrowserCookieExtractor::firefoxProfilePathByName(const QString &profileName) const
{
    if (profileName.trimmed().isEmpty()) {
        return QString();
    }

    const QString mozDir = QDir::homePath() + QStringLiteral("/.mozilla/firefox");
    const QString profilesIni = mozDir + QStringLiteral("/profiles.ini");
    if (!QFileInfo::exists(profilesIni)) {
        return QString();
    }

    QSettings ini(profilesIni, QSettings::IniFormat);
    const QStringList groups = ini.childGroups();
    for (const QString &group : groups) {
        if (!group.startsWith(QStringLiteral("Profile"))) continue;
        ini.beginGroup(group);
        const QString name = ini.value(QStringLiteral("Name")).toString().trimmed();
        const QString path = ini.value(QStringLiteral("Path")).toString();
        const bool isRelative = ini.value(QStringLiteral("IsRelative"), 1).toInt() == 1;
        ini.endGroup();

        if (name != profileName) continue;

        const QString fullPath = isRelative ? (mozDir + QStringLiteral("/") + path) : path;
        if (QFileInfo::exists(fullPath + QStringLiteral("/cookies.sqlite"))) {
            return fullPath;
        }
    }

    return QString();
}

QStringList BrowserCookieExtractor::firefoxProfiles() const
{
    QStringList profiles;
    QString mozDir = QDir::homePath() + QStringLiteral("/.mozilla/firefox");
    QDir dir(mozDir);
    if (!dir.exists()) return profiles;

    QString profilesIni = mozDir + QStringLiteral("/profiles.ini");
    if (QFileInfo::exists(profilesIni)) {
        QSettings ini(profilesIni, QSettings::IniFormat);
        QStringList groups = ini.childGroups();
        for (const QString &group : groups) {
            if (!group.startsWith(QStringLiteral("Profile"))) continue;
            ini.beginGroup(group);
            QString name = ini.value(QStringLiteral("Name")).toString();
            ini.endGroup();
            if (!name.isEmpty() && !profiles.contains(name)) profiles.append(name);
        }
    }
    return profiles;
}

QString BrowserCookieExtractor::chromeProfilePath() const
{
    return QDir::homePath() + QStringLiteral("/.config/google-chrome/Default");
}

QString BrowserCookieExtractor::chromiumProfilePath() const
{
    return QDir::homePath() + QStringLiteral("/.config/chromium/Default");
}

// --- Cookie Reading (Firefox) ---

QMap<QString, QString> BrowserCookieExtractor::readFirefoxCookies(const QString &domain) const
{
    // Return cached result if same domain and within TTL
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (domain == m_cachedDomain && (now - m_cacheTimestamp) < CACHE_TTL_MS) {
        return m_cachedCookies;
    }

    QMap<QString, QString> cookies;

    QString dbPath = cookieDbPath();
    if (dbPath.isEmpty() || !QFileInfo::exists(dbPath)) {
        return cookies;
    }

    // Use a unique connection name to avoid conflicts
    QString connName = QStringLiteral("firefox_cookies_") + QUuid::createUuid().toString(QUuid::WithoutBraces);

    // Copy the database to a temp file to avoid Firefox WAL lock issues.
    // Firefox holds an exclusive lock on cookies.sqlite while running,
    // so we make a snapshot copy and read from that instead.
    QTemporaryFile tmpFile;
    tmpFile.setAutoRemove(true);
    if (!tmpFile.open()) {
        qWarning() << "BrowserCookieExtractor: Cannot create temp file for cookie db copy";
        return cookies;
    }
    // Set restrictive permissions — temp file contains session cookies
    tmpFile.setPermissions(QFile::ReadOwner | QFile::WriteOwner);
    QString tmpPath = tmpFile.fileName();
    tmpFile.close();

    if (!QFile::copy(dbPath, tmpPath)) {
        // QFile::copy fails if dest exists (QTemporaryFile created it), remove first
        QFile::remove(tmpPath);
        if (!QFile::copy(dbPath, tmpPath)) {
            qWarning() << "BrowserCookieExtractor: Cannot copy cookies.sqlite to temp file";
            return cookies;
        }
    }

    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
        db.setDatabaseName(tmpPath);

        if (!db.open()) {
            qWarning() << "BrowserCookieExtractor: Cannot open Firefox cookies.sqlite:" << db.lastError().text();
            QSqlDatabase::removeDatabase(connName);
            return cookies;
        }

        QSqlQuery query(db);
        // Firefox stores expiry as Unix timestamp in seconds
        // Filter out expired cookies
        query.prepare(QStringLiteral(
            "SELECT name, value FROM moz_cookies "
            "WHERE (host = :domain1 OR host = :domain2) "
            "AND (expiry > :now OR expiry = 0)"
        ));
        query.bindValue(QStringLiteral(":domain1"), domain);
        // Also match with/without leading dot
        QString altDomain = domain.startsWith(QLatin1Char('.'))
            ? domain.mid(1) : (QStringLiteral(".") + domain);
        query.bindValue(QStringLiteral(":domain2"), altDomain);
        query.bindValue(QStringLiteral(":now"), QDateTime::currentSecsSinceEpoch());

        if (query.exec()) {
            while (query.next()) {
                cookies.insert(query.value(0).toString(), query.value(1).toString());
            }
        } else {
            qWarning() << "BrowserCookieExtractor: Cookie query failed:" << query.lastError().text();
        }

        db.close();
    }

    QSqlDatabase::removeDatabase(connName);
    QFile::remove(tmpPath);

    // Update cache
    m_cachedDomain = domain;
    m_cachedCookies = cookies;
    m_cacheTimestamp = QDateTime::currentMSecsSinceEpoch();

    return cookies;
}

QString BrowserCookieExtractor::getCookie(const QString &domain, const QString &name) const
{
    if (m_browserType != Firefox) {
        // Chrome/Chromium cookies are encrypted — not supported yet
        qWarning() << "BrowserCookieExtractor: Only Firefox is currently supported for cookie extraction";
        return QString();
    }

    QMap<QString, QString> cookies = readFirefoxCookies(domain);
    return cookies.value(name);
}

bool BrowserCookieExtractor::hasCookiesFor(const QString &domain) const
{
    if (m_browserType != Firefox) return false;
    QMap<QString, QString> cookies = readFirefoxCookies(domain);
    return !cookies.isEmpty();
}

QString BrowserCookieExtractor::getCookieHeader(const QString &domain) const
{
    if (m_browserType != Firefox) return QString();

    QMap<QString, QString> cookies = readFirefoxCookies(domain);
    QStringList parts;
    for (auto it = cookies.constBegin(); it != cookies.constEnd(); ++it) {
        parts.append(it.key() + QStringLiteral("=") + it.value());
    }
    return parts.join(QStringLiteral("; "));
}

QString BrowserCookieExtractor::testConnection(const QString &service) const
{
    QString domain;
    QStringList sessionCookieNames;

    if (m_browserType != Firefox) {
        return QStringLiteral("unsupported_browser");
    }

    if (service == QStringLiteral("claude")) {
        domain = QStringLiteral("claude.ai");
        // Claude.ai primary session cookies
        sessionCookieNames = {
            QStringLiteral("sessionKey"),
            QStringLiteral("__Secure-next-auth.session-token"),
        };
    } else if (service == QStringLiteral("chatgpt") || service == QStringLiteral("codex")) {
        domain = QStringLiteral("chatgpt.com");
        // ChatGPT primary session cookies
        sessionCookieNames = {
            QStringLiteral("__Secure-next-auth.session-token"),
            QStringLiteral("__Secure-next-auth.callback-url"),
        };
    } else if (service == QStringLiteral("github")) {
        domain = QStringLiteral("github.com");
        sessionCookieNames = {
            QStringLiteral("user_session"),
            QStringLiteral("dotcom_user"),
        };
    } else {
        return QStringLiteral("unknown_service");
    }

    if (firefoxProfilePath().isEmpty()) {
        return QStringLiteral("profile_missing");
    }

    const QString dbPath = cookieDbPath();
    if (dbPath.isEmpty() || !QFileInfo::exists(dbPath)) {
        return QStringLiteral("cookie_db_missing");
    }

    if (!hasCookiesFor(domain)) {
        return QStringLiteral("cookies_not_found");
    }

    // Has cookies — check for actual session cookies (not just CF bot management etc.)
    QMap<QString, QString> cookies = readFirefoxCookies(domain);

    for (const QString &name : sessionCookieNames) {
        if (cookies.contains(name) && !cookies.value(name).isEmpty()) {
            return QStringLiteral("connected");
        }
    }

    // Has cookies for the domain but none of the expected session cookies.
    return QStringLiteral("session_missing_or_expired");
}

QString BrowserCookieExtractor::connectionMessage(const QString &service, const QString &code) const
{
    Q_UNUSED(service);

    QString normalizedCode = code;
    if (normalizedCode == QStringLiteral("not_found")) {
        normalizedCode = QStringLiteral("cookies_not_found");
    } else if (normalizedCode == QStringLiteral("expired")) {
        normalizedCode = QStringLiteral("session_missing_or_expired");
    }

    if (normalizedCode == QStringLiteral("connected")) {
        return QStringLiteral("Connected");
    }
    if (normalizedCode == QStringLiteral("profile_missing")) {
        return QStringLiteral("No Firefox profile detected on this system.");
    }
    if (normalizedCode == QStringLiteral("cookie_db_missing")) {
        return QStringLiteral("Firefox profile found, but cookies.sqlite is missing or unreadable.");
    }
    if (normalizedCode == QStringLiteral("cookies_not_found")) {
        return QStringLiteral("No cookies found for this service.");
    }
    if (normalizedCode == QStringLiteral("session_missing_or_expired")) {
        return QStringLiteral("Session cookies missing or expired. Sign in again.");
    }
    if (normalizedCode == QStringLiteral("unsupported_browser")) {
        return QStringLiteral("Browser Sync currently supports Firefox only.");
    }
    if (normalizedCode == QStringLiteral("unknown_service")) {
        return QStringLiteral("Unknown service.");
    }

    return QStringLiteral("Connection check failed.");
}
