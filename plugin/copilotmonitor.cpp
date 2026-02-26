#include "copilotmonitor.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkRequest>
#include <QDirIterator>
#include <QDebug>

CopilotMonitor::CopilotMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
{
}

void CopilotMonitor::checkToolInstalled()
{
    bool found = false;

    // Check for GitHub CLI with Copilot extension
    QString ghPath = QStandardPaths::findExecutable(QStringLiteral("gh"));
    if (!ghPath.isEmpty()) {
        // gh CLI is available; Copilot extension may be installed
        found = true;
    }

    // Check for VS Code Copilot extension directory
    QString vscodeExtDir = QDir::homePath() + QStringLiteral("/.vscode/extensions");
    QDir extDir(vscodeExtDir);
    if (extDir.exists()) {
        const auto entries = extDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const auto &entry : entries) {
            if (entry.startsWith(QStringLiteral("github.copilot"))) {
                found = true;
                break;
            }
        }
    }

    // Check for Neovim Copilot plugin (specific plugin directories, not just nvim)
    QString nvimDataDir = QDir::homePath() + QStringLiteral("/.local/share/nvim");
    QStringList copilotPluginPaths = {
        nvimDataDir + QStringLiteral("/plugged/copilot.vim"),
        nvimDataDir + QStringLiteral("/lazy/copilot.lua"),
        nvimDataDir + QStringLiteral("/lazy/copilot.vim"),
        nvimDataDir + QStringLiteral("/site/pack/packer/start/copilot.vim"),
        nvimDataDir + QStringLiteral("/site/pack/packer/start/copilot.lua"),
    };
    for (const auto &pluginPath : copilotPluginPaths) {
        if (QDir(pluginPath).exists()) {
            found = true;
            break;
        }
    }

    setInstalled(found);
}

void CopilotMonitor::detectActivity()
{
    const QString home = QDir::homePath();
    const QStringList candidatePaths = {
        home + QStringLiteral("/.config/Code/User/globalStorage/github.copilot"),
        home + QStringLiteral("/.config/Code/User/globalStorage/github.copilot-chat"),
        home + QStringLiteral("/.config/Code/User/workspaceStorage"),
        home + QStringLiteral("/.config/Code/logs"),
        home + QStringLiteral("/.config/VSCodium/User/globalStorage/github.copilot"),
        home + QStringLiteral("/.config/VSCodium/User/globalStorage/github.copilot-chat"),
        home + QStringLiteral("/.config/VSCodium/User/workspaceStorage"),
        home + QStringLiteral("/.config/VSCodium/logs"),
        home + QStringLiteral("/.config/Code - OSS/User/globalStorage/github.copilot"),
        home + QStringLiteral("/.config/Code - OSS/User/globalStorage/github.copilot-chat"),
        home + QStringLiteral("/.config/Code - OSS/User/workspaceStorage"),
        home + QStringLiteral("/.config/Code - OSS/logs")
    };

    QDateTime newestTimestamp;
    QString newestPath;

    for (const QString &path : candidatePaths) {
        const QDateTime modified = latestModification(path);
        if (modified.isValid() && (!newestTimestamp.isValid() || modified > newestTimestamp)) {
            newestTimestamp = modified;
            newestPath = path;
        }
    }

    if (!newestTimestamp.isValid()) {
        if (!m_loggedDetectionFallback) {
            m_loggedDetectionFallback = true;
            qInfo() << "CopilotMonitor: detectActivity fallback active; no Copilot state/log paths found."
                    << "Manual tracking and org metrics remain available.";
        }
        return;
    }

    if (!m_lastDetectedActivity.isValid()) {
        m_lastDetectedActivity = newestTimestamp;
        qInfo() << "CopilotMonitor: detectActivity baseline initialized at" << newestTimestamp
                << "from" << newestPath;
        return;
    }

    if (newestTimestamp > m_lastDetectedActivity) {
        m_lastDetectedActivity = newestTimestamp;
        qInfo() << "CopilotMonitor: activity detected from" << newestPath
                << "at" << newestTimestamp;
        incrementUsage();
    }
}

QDateTime CopilotMonitor::latestModification(const QString &path, int maxEntries) const
{
    QFileInfo info(path);
    if (!info.exists()) {
        return QDateTime();
    }

    if (info.isFile()) {
        return info.lastModified();
    }

    QDateTime newest = info.lastModified();
    QDirIterator it(path, QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    int scanned = 0;
    while (it.hasNext() && scanned < maxEntries) {
        it.next();
        const QFileInfo entry = it.fileInfo();
        if (entry.lastModified().isValid() && entry.lastModified() > newest) {
            newest = entry.lastModified();
        }
        scanned++;
    }

    return newest;
}

// --- GitHub API ---

QString CopilotMonitor::githubToken() const { return m_githubToken; }
void CopilotMonitor::setGithubToken(const QString &token)
{
    if (m_githubToken != token) {
        m_githubToken = token;
        Q_EMIT githubTokenChanged();
    }
}

QString CopilotMonitor::orgName() const { return m_orgName; }
void CopilotMonitor::setOrgName(const QString &name)
{
    if (m_orgName != name) {
        m_orgName = name;
        Q_EMIT orgNameChanged();
    }
}

bool CopilotMonitor::hasOrgMetrics() const { return m_hasOrgMetrics; }
int CopilotMonitor::orgActiveUsers() const { return m_orgActiveUsers; }
int CopilotMonitor::orgTotalSeats() const { return m_orgTotalSeats; }

void CopilotMonitor::fetchOrgMetrics()
{
    if (m_githubToken.isEmpty() || m_orgName.isEmpty()) return;

    m_fetchGeneration++;
    int gen = m_fetchGeneration;

    // GET /orgs/{org}/copilot/billing
    QUrl url(QStringLiteral("https://api.github.com/orgs/%1/copilot/billing").arg(m_orgName));

    QNetworkRequest request(url);
    request.setTransferTimeout(30000);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(m_githubToken).toUtf8());
    request.setRawHeader("Accept", "application/vnd.github+json");
    request.setRawHeader("X-GitHub-Api-Version", "2022-11-28");

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (gen != m_fetchGeneration) { reply->deleteLater(); return; }
        onBillingReply(reply);
    });
}

void CopilotMonitor::onBillingReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "CopilotMonitor: GitHub API error:" << reply->errorString();
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) return;

    QJsonObject root = doc.object();

    // Extract seat information
    int totalSeats = root.value(QStringLiteral("total_seats")).toInt(0);
    // seat_breakdown contains active_this_cycle, inactive_this_cycle, etc.
    QJsonObject breakdown = root.value(QStringLiteral("seat_breakdown")).toObject();
    int activeUsers = breakdown.value(QStringLiteral("active_this_cycle")).toInt(0);

    m_orgTotalSeats = totalSeats;
    m_orgActiveUsers = activeUsers;
    m_hasOrgMetrics = true;

    Q_EMIT orgMetricsUpdated();
}

QStringList CopilotMonitor::availablePlans() const
{
    return {
        QStringLiteral("Free"),
        QStringLiteral("Pro"),
        QStringLiteral("Pro+"),
        QStringLiteral("Business"),
        QStringLiteral("Enterprise")
    };
}

int CopilotMonitor::defaultLimitForPlan(const QString &plan) const
{
    // Monthly premium request limits
    if (plan == QStringLiteral("Free")) return 50;
    if (plan == QStringLiteral("Pro")) return 300;
    if (plan == QStringLiteral("Pro+")) return 1500;
    if (plan == QStringLiteral("Business")) return 300;
    if (plan == QStringLiteral("Enterprise")) return 1000;
    return 50;
}

double CopilotMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}

double CopilotMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Free")) return 0.0;
    if (plan == QStringLiteral("Pro")) return 10.0;
    if (plan == QStringLiteral("Pro+")) return 39.0;
    if (plan == QStringLiteral("Business")) return 19.0;
    if (plan == QStringLiteral("Enterprise")) return 39.0;
    return 0.0;
}
