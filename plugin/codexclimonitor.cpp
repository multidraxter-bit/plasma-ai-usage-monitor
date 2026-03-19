#include "codexclimonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <KLocalizedString>

#include "browsercookieextractor.h"

CodexCliMonitor::CodexCliMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_debounceTimer(new QTimer(this))
{
    // Debounce: multiple filesystem events within 5 seconds count as one message
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(5000);
    connect(m_debounceTimer, &QTimer::timeout, this, [this]() {
        if (m_pendingIncrement) {
            m_pendingIncrement = false;
            incrementUsage();
        }
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &CodexCliMonitor::onDirectoryChanged);
}

QString CodexCliMonitor::codexConfigDir() const
{
    // Codex CLI stores config in ~/.codex/
    return QDir::homePath() + QStringLiteral("/.codex");
}

void CodexCliMonitor::checkToolInstalled()
{
    bool found = false;

    // Check if 'codex' binary exists in PATH
    QString codexPath = QStandardPaths::findExecutable(QStringLiteral("codex"));
    if (!codexPath.isEmpty()) {
        found = true;
    }

    // Also check for ~/.codex/ directory
    QDir configDir(codexConfigDir());
    if (configDir.exists()) {
        found = true;
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void CodexCliMonitor::setupWatcher()
{
    QString configDir = codexConfigDir();
    QDir dir(configDir);

    if (dir.exists()) {
        m_watcher->addPath(configDir);

        // Watch subdirectories for session activity
        const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const auto &subdir : subdirs) {
            m_watcher->addPath(subdir.absoluteFilePath());
        }
    }
}

void CodexCliMonitor::detectActivity()
{
    QString configDir = codexConfigDir();
    QDir dir(configDir);

    if (!dir.exists()) return;

    QDateTime latestMod;

    // Check all files in the codex directory for recent modifications
    const auto entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot,
                                            QDir::Time);
    if (!entries.isEmpty()) {
        latestMod = entries.first().lastModified();
    }

    if (latestMod.isValid() && latestMod > m_lastKnownModification) {
        m_lastKnownModification = latestMod;
        m_pendingIncrement = true;
        if (!m_debounceTimer->isActive()) {
            m_debounceTimer->start();
        }
    }
}

void CodexCliMonitor::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();
}

QStringList CodexCliMonitor::availablePlans() const
{
    return {
        QStringLiteral("Plus"),
        QStringLiteral("Pro"),
        QStringLiteral("Business")
    };
}

int CodexCliMonitor::defaultLimitForPlan(const QString &plan) const
{
    // Lower bound of 5-hour window for local messages
    if (plan == QStringLiteral("Plus")) return 45;
    if (plan == QStringLiteral("Pro")) return 300;
    if (plan == QStringLiteral("Business")) return 45;
    return 45;
}

int CodexCliMonitor::defaultSecondaryLimitForPlan(const QString &plan) const
{
    // Weekly usage limits
    if (plan == QStringLiteral("Plus")) return 100;
    if (plan == QStringLiteral("Pro")) return 500;
    if (plan == QStringLiteral("Business")) return 100;
    return 100;
}

double CodexCliMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}

double CodexCliMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Plus")) return 20.0;
    if (plan == QStringLiteral("Pro")) return 200.0;
    if (plan == QStringLiteral("Business")) return 30.0;
    return 20.0;
}

// --- Browser Sync ---

void CodexCliMonitor::syncFromBrowser(const QString &cookieHeader, int browserType)
{
    if (isSyncing()) return;
    setSyncing(true);
    setSyncStatus(QStringLiteral("Syncing..."));

    if (browserType != BrowserCookieExtractor::Firefox) {
        setSyncing(false);
        setSyncStatus(i18n("Browser unsupported"));
        const QString message = i18n("Browser Sync currently supports Firefox only");
        Q_EMIT syncDiagnostic(toolName(), QStringLiteral("unsupported_browser"), message);
        Q_EMIT syncCompleted(false, message);
        return;
    }

    if (cookieHeader.isEmpty()) {
        setSyncing(false);
        setSyncStatus(i18n("Not logged in"));
        const QString message = i18n("Not logged in — open chatgpt.com in Firefox first");
        Q_EMIT syncDiagnostic(toolName(), QStringLiteral("not_logged_in"), message);
        Q_EMIT syncCompleted(false, message);
        return;
    }

    fetchAccountCheck(cookieHeader);
}

void CodexCliMonitor::fetchAccountCheck(const QString &cookieHeader)
{
    // ChatGPT internal API for account/usage info
    QUrl url = qEnvironmentVariableIsSet("PLASMA_AI_MONITOR_DEMO")
        ? QUrl(QStringLiteral("http://localhost:8080/chatgpt/backend-api/accounts/check/v4-2023-04-27"))
        : QUrl(QStringLiteral("https://chatgpt.com/backend-api/accounts/check/v4-2023-04-27"));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0");
    // Force HTTP/1.1 — Qt's HTTP/2 implementation triggers 401 on ChatGPT backend API
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setAttribute(QNetworkRequest::CookieLoadControlAttribute, QNetworkRequest::Manual);
    request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
    request.setTransferTimeout(30000); // 30 second timeout

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qWarning() << "CodexCliMonitor: Account check failed:" << reply->errorString() << "HTTP" << httpStatus;
            setSyncing(false);
            if (httpStatus == 401 || httpStatus == 403) {
                setSyncStatus(i18n("Session expired"));
                const QString message = i18n("Session expired — please log in to chatgpt.com in Firefox again");
                Q_EMIT syncDiagnostic(toolName(), QStringLiteral("session_expired"), message);
                Q_EMIT syncCompleted(false, message);
            } else {
                setSyncStatus(i18n("Sync failed"));
                const QString message = reply->errorString();
                Q_EMIT syncDiagnostic(toolName(), QStringLiteral("network_error"), message);
                Q_EMIT syncCompleted(false, message);
            }
            return;
        }

        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isNull() || !doc.isObject()) {
            setSyncing(false);
            setSyncStatus(i18n("Invalid response"));
            const QString message = i18n("Unexpected response from ChatGPT");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("invalid_response"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }

        QJsonObject root = doc.object();

        // The response contains accounts → account_id → rate_limits and usage
        // Navigate to the first account
        QJsonObject accounts = root.value(QStringLiteral("accounts")).toObject();
        QJsonObject accountData;
        for (auto it = accounts.begin(); it != accounts.end(); ++it) {
            accountData = it.value().toObject();
            break;
        }

        if (accountData.isEmpty()) {
            // Try alternate structure
            accountData = root;
        }

        // Parse rate limits
        QJsonObject rateLimits = accountData.value(QStringLiteral("rate_limits")).toObject();
        if (rateLimits.isEmpty()) {
            qWarning() << "CodexCliMonitor: No rate_limits found in response";
        }
        if (!rateLimits.isEmpty()) {
            // Primary: 5-hour usage limit
            QJsonObject fiveHour = rateLimits.value(QStringLiteral("message_cap")).toObject();
            if (fiveHour.isEmpty()) {
                // Try alternate key
                for (auto it = rateLimits.begin(); it != rateLimits.end(); ++it) {
                    QJsonObject rl = it.value().toObject();
                    QString type = rl.value(QStringLiteral("type")).toString();
                    if (type.contains(QStringLiteral("5h")) || type.contains(QStringLiteral("five_hour"))) {
                        fiveHour = rl;
                        break;
                    }
                }
            }

            if (!fiveHour.isEmpty()) {
                int remaining = fiveHour.value(QStringLiteral("remaining")).toInt(-1);
                int limit = fiveHour.value(QStringLiteral("limit")).toInt(0);
                if (limit > 0) {
                    setUsageLimit(limit);
                    if (remaining >= 0) setUsageCount(limit - remaining);
                }
                // Parse resets_at for primary period
                QString resetsAt = fiveHour.value(QStringLiteral("resets_at")).toString();
                if (!resetsAt.isEmpty()) {
                    QDateTime resetTime = QDateTime::fromString(resetsAt, Qt::ISODate);
                    if (resetTime.isValid()) {
                        // Period start = reset time minus 5 hours
                        setPeriodStart(resetTime.addSecs(-5 * 3600));
                    }
                }
            }

            // Weekly usage limit
            QJsonObject weekly;
            for (auto it = rateLimits.begin(); it != rateLimits.end(); ++it) {
                QJsonObject rl = it.value().toObject();
                QString type = rl.value(QStringLiteral("type")).toString();
                if (type.contains(QStringLiteral("week"))) {
                    weekly = rl;
                    break;
                }
            }
            if (!weekly.isEmpty()) {
                int remaining = weekly.value(QStringLiteral("remaining")).toInt(-1);
                int limit = weekly.value(QStringLiteral("limit")).toInt(0);
                if (limit > 0) {
                    setSecondaryUsageLimit(limit);
                    if (remaining >= 0) setSecondaryUsageCount(limit - remaining);
                }
                // Parse resets_at for secondary period
                QString resetsAt = weekly.value(QStringLiteral("resets_at")).toString();
                if (!resetsAt.isEmpty()) {
                    QDateTime resetTime = QDateTime::fromString(resetsAt, Qt::ISODate);
                    if (resetTime.isValid()) {
                        // Period start = reset time minus 7 days
                        setSecondaryPeriodStart(resetTime.addDays(-7));
                    }
                }
            }

            // Code review (tertiary)
            QJsonObject codeReview;
            for (auto it = rateLimits.begin(); it != rateLimits.end(); ++it) {
                QJsonObject rl = it.value().toObject();
                QString type = rl.value(QStringLiteral("type")).toString();
                if (type.contains(QStringLiteral("code_review")) || type.contains(QStringLiteral("review"))) {
                    codeReview = rl;
                    break;
                }
            }
            if (!codeReview.isEmpty()) {
                int remaining = codeReview.value(QStringLiteral("remaining")).toInt(-1);
                int limit = codeReview.value(QStringLiteral("limit")).toInt(0);
                if (limit > 0 && remaining >= 0) {
                    double pctRemaining = (static_cast<double>(remaining) / limit) * 100.0;
                    setTertiaryPercentRemaining(pctRemaining);
                    m_hasTertiary = true;

                    QString resetsAt = codeReview.value(QStringLiteral("resets_at")).toString();
                    if (!resetsAt.isEmpty()) {
                        setTertiaryResetDate(QDateTime::fromString(resetsAt, Qt::ISODate));
                    }
                }
            }
        }

        // Parse credits/remaining
        double credits = accountData.value(QStringLiteral("remaining_credits")).toDouble(-1);
        if (credits < 0) {
            // Try alternate path
            QJsonObject billing = accountData.value(QStringLiteral("billing")).toObject();
            credits = billing.value(QStringLiteral("remaining_credits")).toDouble(-1);
        }
        if (credits >= 0) {
            setRemainingCredits(credits);
            m_hasCreditsData = true;
        }

        // Detect plan from entitlement
        QString entitlement = accountData.value(QStringLiteral("entitlement")).toString();
        if (entitlement.contains(QStringLiteral("pro"), Qt::CaseInsensitive)) {
            setPlanTier(QStringLiteral("Pro"));
        } else if (entitlement.contains(QStringLiteral("plus"), Qt::CaseInsensitive)) {
            setPlanTier(QStringLiteral("Plus"));
        }

        // Sync complete
        setSyncing(false);
        setLastSyncTime(QDateTime::currentDateTimeUtc());
        setSyncStatus(i18n("Synced"));
        Q_EMIT syncCompleted(true, i18n("Codex usage data synced successfully"));
        Q_EMIT usageUpdated();
    });
}
