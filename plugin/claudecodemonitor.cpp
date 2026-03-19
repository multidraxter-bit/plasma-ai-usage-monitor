#include "claudecodemonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <KLocalizedString>

#include "browsercookieextractor.h"

ClaudeCodeMonitor::ClaudeCodeMonitor(QObject *parent)
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
            this, &ClaudeCodeMonitor::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &ClaudeCodeMonitor::onFileChanged);
}

QString ClaudeCodeMonitor::claudeConfigDir() const
{
    // Claude Code stores config in ~/.claude/ by default
    // Can be overridden with CLAUDE_CONFIG_DIR env var
    QString envDir = QString::fromLocal8Bit(qgetenv("CLAUDE_CONFIG_DIR"));
    if (!envDir.isEmpty()) return envDir;
    return QDir::homePath() + QStringLiteral("/.claude");
}

void ClaudeCodeMonitor::checkToolInstalled()
{
    bool found = false;

    // Check if 'claude' binary exists in PATH
    QString claudePath = QStandardPaths::findExecutable(QStringLiteral("claude"));
    if (!claudePath.isEmpty()) {
        found = true;
    }

    // Also check for ~/.claude/ directory
    QDir configDir(claudeConfigDir());
    if (configDir.exists()) {
        found = true;
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void ClaudeCodeMonitor::setupWatcher()
{
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (dir.exists()) {
        m_watcher->addPath(configDir);

        // Watch key files that change during usage
        QString settingsFile = configDir + QStringLiteral("/settings.json");
        if (QFileInfo::exists(settingsFile)) {
            m_watcher->addPath(settingsFile);
        }

        // Watch projects directory for conversation activity
        QString projectsDir = configDir + QStringLiteral("/projects");
        if (QDir(projectsDir).exists()) {
            m_watcher->addPath(projectsDir);
        }
    }

    // Also watch ~/.claude.json (global state file)
    QString globalState = QDir::homePath() + QStringLiteral("/.claude.json");
    if (QFileInfo::exists(globalState)) {
        m_watcher->addPath(globalState);
    }
}

void ClaudeCodeMonitor::detectActivity()
{
    // Manually check for recent activity by looking at file modification times
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (!dir.exists()) return;

    QDateTime latestMod;

    // Check projects directory for recent changes
    QString projectsDir = configDir + QStringLiteral("/projects");
    QDir pDir(projectsDir);
    if (pDir.exists()) {
        const auto entries = pDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot,
                                                 QDir::Time);
        if (!entries.isEmpty()) {
            latestMod = entries.first().lastModified();
        }
    }

    // Check global state file
    QFileInfo globalState(QDir::homePath() + QStringLiteral("/.claude.json"));
    if (globalState.exists() && globalState.lastModified() > latestMod) {
        latestMod = globalState.lastModified();
    }

    // If we see a new modification since last check, schedule a debounced increment
    if (latestMod.isValid() && latestMod > m_lastKnownModification) {
        m_lastKnownModification = latestMod;
        m_pendingIncrement = true;
        if (!m_debounceTimer->isActive()) {
            m_debounceTimer->start();
        }
    }
}

void ClaudeCodeMonitor::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();
}

void ClaudeCodeMonitor::onFileChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;

    // Only count conversation-related file changes, not config edits
    // Skip settings.json and other non-conversation files
    if (path.endsWith(QStringLiteral("/settings.json"))
        || path.endsWith(QStringLiteral("/.claude.json"))) {
        // Re-add the file to the watcher but don't count as usage
        if (!m_watcher->files().contains(path) && QFileInfo::exists(path)) {
            m_watcher->addPath(path);
        }
        return;
    }

    QFileInfo fi(path);
    if (fi.exists() && fi.lastModified() > m_lastKnownModification) {
        m_lastKnownModification = fi.lastModified();
        m_pendingIncrement = true;
        if (!m_debounceTimer->isActive()) {
            m_debounceTimer->start();
        }
    }

    // Re-add the file to the watcher (QFileSystemWatcher removes files after change)
    if (!m_watcher->files().contains(path) && QFileInfo::exists(path)) {
        m_watcher->addPath(path);
    }
}

QStringList ClaudeCodeMonitor::availablePlans() const
{
    return {
        QStringLiteral("Pro"),
        QStringLiteral("Max 5x"),
        QStringLiteral("Max 20x")
    };
}

int ClaudeCodeMonitor::defaultLimitForPlan(const QString &plan) const
{
    // 5-hour session limits (approximate, vary by message complexity)
    if (plan == QStringLiteral("Pro")) return 45;
    if (plan == QStringLiteral("Max 5x")) return 225;
    if (plan == QStringLiteral("Max 20x")) return 900;
    return 45;
}

int ClaudeCodeMonitor::defaultSecondaryLimitForPlan(const QString &plan) const
{
    // Weekly limits
    if (plan == QStringLiteral("Pro")) return 225;
    if (plan == QStringLiteral("Max 5x")) return 1125;
    if (plan == QStringLiteral("Max 20x")) return 4500;
    return 225;
}

double ClaudeCodeMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}

double ClaudeCodeMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Pro")) return 20.0;
    if (plan == QStringLiteral("Max 5x")) return 100.0;
    if (plan == QStringLiteral("Max 20x")) return 200.0;
    return 20.0;
}

// --- Browser Sync ---

void ClaudeCodeMonitor::syncFromBrowser(const QString &cookieHeader, int browserType)
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
        const QString message = i18n("Not logged in — open claude.ai in Firefox first");
        Q_EMIT syncDiagnostic(toolName(), QStringLiteral("not_logged_in"), message);
        Q_EMIT syncCompleted(false, message);
        return;
    }

    fetchAccountInfo(cookieHeader);
}

void ClaudeCodeMonitor::fetchAccountInfo(const QString &cookieHeader)
{
    // Use /api/bootstrap to get account info and organization UUID
    QUrl url = qEnvironmentVariableIsSet("PLASMA_AI_MONITOR_DEMO") 
        ? QUrl(QStringLiteral("http://localhost:8080/claude/api/bootstrap"))
        : QUrl(QStringLiteral("https://claude.ai/api/bootstrap"));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0");
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setAttribute(QNetworkRequest::CookieLoadControlAttribute, QNetworkRequest::Manual);
    request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
    request.setTransferTimeout(30000); // 30 second timeout

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, cookieHeader]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qWarning() << "ClaudeCodeMonitor: Bootstrap fetch failed:" << reply->errorString() << "HTTP" << httpStatus;
            setSyncing(false);
            if (httpStatus == 401 || httpStatus == 403) {
                setSyncStatus(i18n("Session expired"));
                const QString message = i18n("Session expired — please log in to claude.ai in Firefox again");
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
            const QString message = i18n("Unexpected response from Claude.ai");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("invalid_response"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }

        QJsonObject root = doc.object();

        // Extract organization UUID from bootstrap response
        // Structure: { account: { memberships: [ { organization: { uuid: "..." } } ] } }
        QString orgUuid;
        QJsonObject account = root.value(QStringLiteral("account")).toObject();
        if (account.isEmpty()) {
            setSyncing(false);
            setSyncStatus(i18n("Invalid response"));
            const QString message = i18n("API response format may have changed — missing account data");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("format_changed"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }
        QJsonArray memberships = account.value(QStringLiteral("memberships")).toArray();
        QJsonObject org; // Declared in outer scope for plan detection below
        if (!memberships.isEmpty()) {
            QJsonObject firstMembership = memberships.first().toObject();
            org = firstMembership.value(QStringLiteral("organization")).toObject();
            orgUuid = org.value(QStringLiteral("uuid")).toString();
        }

        // Fallback: try top-level uuid
        if (orgUuid.isEmpty()) {
            orgUuid = account.value(QStringLiteral("uuid")).toString();
        }

        if (orgUuid.isEmpty()) {
            setSyncing(false);
            setSyncStatus(i18n("No organization"));
            const QString message = i18n("Could not find your Claude organization");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("organization_missing"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }

        m_orgUuid = orgUuid;

        // Auto-detect plan from organization subscription data
        QJsonObject subscription = org.value(QStringLiteral("subscription")).toObject();
        if (!subscription.isEmpty()) {
            QString planType = subscription.value(QStringLiteral("type")).toString();
            // Also check for rate_limit_tier as fallback
            if (planType.isEmpty()) {
                planType = org.value(QStringLiteral("rate_limit_tier")).toString();
            }

            QString detectedPlan;
            if (planType.contains(QStringLiteral("max_20x"), Qt::CaseInsensitive)
                || planType.contains(QStringLiteral("max20x"), Qt::CaseInsensitive)
                || planType == QStringLiteral("scale_max_20x")) {
                detectedPlan = QStringLiteral("Max 20x");
            } else if (planType.contains(QStringLiteral("max_5x"), Qt::CaseInsensitive)
                       || planType.contains(QStringLiteral("max5x"), Qt::CaseInsensitive)
                       || planType == QStringLiteral("scale_max_5x")) {
                detectedPlan = QStringLiteral("Max 5x");
            } else if (planType.contains(QStringLiteral("pro"), Qt::CaseInsensitive)
                       || planType == QStringLiteral("professional")) {
                detectedPlan = QStringLiteral("Pro");
            }

            if (!detectedPlan.isEmpty() && detectedPlan != planTier()) {
                qDebug() << "ClaudeCodeMonitor: Auto-detected plan:" << detectedPlan << "(raw:" << planType << ")";
                setPlanTier(detectedPlan);
                setUsageLimit(defaultLimitForPlan(detectedPlan));
                setSecondaryUsageLimit(defaultSecondaryLimitForPlan(detectedPlan));
            }
        }

        fetchUsageData(orgUuid, cookieHeader);
    });
}

void ClaudeCodeMonitor::fetchUsageData(const QString &orgUuid, const QString &cookieHeader)
{
    QUrl url = qEnvironmentVariableIsSet("PLASMA_AI_MONITOR_DEMO")
        ? QUrl(QStringLiteral("http://localhost:8080/claude/api/organizations/%1/usage").arg(orgUuid))
        : QUrl(QStringLiteral("https://claude.ai/api/organizations/%1/usage").arg(orgUuid));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0");
    request.setAttribute(QNetworkRequest::Http2AllowedAttribute, false);
    request.setAttribute(QNetworkRequest::CookieLoadControlAttribute, QNetworkRequest::Manual);
    request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
    request.setTransferTimeout(30000); // 30 second timeout

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
            qWarning() << "ClaudeCodeMonitor: Usage fetch failed:" << reply->errorString() << "HTTP" << httpStatus;
            setSyncing(false);
            if (httpStatus == 401 || httpStatus == 403) {
                setSyncStatus(i18n("Session expired"));
                const QString message = i18n("Session expired — please log in to claude.ai in Firefox again");
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
        if (!doc.isObject()) {
            setSyncing(false);
            setSyncStatus(i18n("Invalid response"));
            const QString message = i18n("Unexpected response from Claude.ai");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("invalid_response"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }

        QJsonObject root = doc.object();

        // Validate expected fields exist
        if (!root.contains(QStringLiteral("five_hour")) && !root.contains(QStringLiteral("seven_day"))) {
            setSyncing(false);
            setSyncStatus(i18n("Invalid response"));
            const QString message = i18n("API response format may have changed — no usage data found");
            Q_EMIT syncDiagnostic(toolName(), QStringLiteral("format_changed"), message);
            Q_EMIT syncCompleted(false, message);
            return;
        }

        // Parse 5-hour session usage
        QJsonObject fiveHour = root.value(QStringLiteral("five_hour")).toObject();
        if (!fiveHour.isEmpty()) {
            double utilization = fiveHour.value(QStringLiteral("utilization")).toDouble(0.0);
            setSessionPercentUsed(utilization);
            setHasSessionInfo(true);

            // Convert percentage to count based on configured limit
            int limit = usageLimit();
            if (limit > 0) {
                int used = static_cast<int>((utilization / 100.0) * limit);
                setUsageCount(used);
            }

            // Update period reset time
            QString resetsAt = fiveHour.value(QStringLiteral("resets_at")).toString();
            if (!resetsAt.isEmpty()) {
                QDateTime resetTime = QDateTime::fromString(resetsAt, Qt::ISODate);
                if (resetTime.isValid()) {
                    // Calculate period start from reset time (reset = start + 5h)
                    setPeriodStart(resetTime.addSecs(-5 * 3600));
                }
            }
        }

        // Parse 7-day (weekly) usage
        QJsonObject sevenDay = root.value(QStringLiteral("seven_day")).toObject();
        if (!sevenDay.isEmpty()) {
            double utilization = sevenDay.value(QStringLiteral("utilization")).toDouble(0.0);
            int secLimit = secondaryUsageLimit();
            if (secLimit > 0) {
                int used = static_cast<int>((utilization / 100.0) * secLimit);
                setSecondaryUsageCount(used);
            }
        }

        // Parse extra_usage (metered spending)
        QJsonValue extraVal = root.value(QStringLiteral("extra_usage"));
        if (!extraVal.isNull() && extraVal.isObject()) {
            QJsonObject extra = extraVal.toObject();
            setHasExtraUsage(true);
            double spentCents = extra.value(QStringLiteral("spent_cents")).toDouble(0);
            setExtraUsageSpent(spentCents / 100.0);
            double limitCents = extra.value(QStringLiteral("monthly_limit_cents")).toDouble(0);
            setExtraUsageLimit(limitCents / 100.0);
            QString resetsAt = extra.value(QStringLiteral("resets_at")).toString();
            if (!resetsAt.isEmpty()) {
                setExtraUsageResetDate(QDateTime::fromString(resetsAt, Qt::ISODate));
            }
        }

        // Sync complete
        setSyncing(false);
        setLastSyncTime(QDateTime::currentDateTimeUtc());
        setSyncStatus(i18n("Synced"));
        Q_EMIT syncCompleted(true, i18n("Claude usage data synced successfully"));
        Q_EMIT usageUpdated();
    });
}
