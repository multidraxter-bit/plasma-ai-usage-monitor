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
    : LocalActivityMonitorBase(parent)
{
    setInstallExecutableNames({QStringLiteral("gh")});
    setIgnoredPathSuffixes({QStringLiteral(".log"), QStringLiteral(".json")});
    setDebounceIntervalMs(250);
}

void CopilotMonitor::checkToolInstalled()
{
    // Use base class logic for executables
    LocalActivityMonitorBase::checkToolInstalled();
    if (isInstalled()) return;

    // Check for VS Code Copilot extension directory (specific for Copilot)
    QString vscodeExtDir = QDir::homePath() + QStringLiteral("/.vscode/extensions");
    QDir extDir(vscodeExtDir);
    if (extDir.exists()) {
        const auto entries = extDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const auto &entry : entries) {
            if (entry.startsWith(QStringLiteral("github.copilot"))) {
                setInstalled(true);
                return;
            }
        }
    }

    // Check for Neovim Copilot plugin
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
            setInstalled(true);
            return;
        }
    }
}

void CopilotMonitor::detectActivity()
{
    if (watchedPaths().isEmpty()) {
        const QString home = QDir::homePath();
        setWatchedPaths({
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
        });
    }

    LocalActivityMonitorBase::detectActivity();
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

QString CopilotMonitor::billingMode() const
{
    return m_billingMode;
}

void CopilotMonitor::setBillingMode(const QString &mode)
{
    const QString normalized = mode.trimmed().isEmpty()
        ? QStringLiteral("premium_requests")
        : mode.trimmed();
    if (m_billingMode != normalized) {
        m_billingMode = normalized;
        Q_EMIT billingModeChanged();
    }
}

QString CopilotMonitor::usageSourceLabel() const
{
    if (m_billingMode == QStringLiteral("usage_based")) {
        return QStringLiteral("Usage-based billing mode: local activity is an estimate unless GitHub org metrics are configured.");
    }
    if (m_billingMode == QStringLiteral("credits")) {
        return QStringLiteral("Credits mode: local activity is self-tracked and does not claim exact billing credits.");
    }
    return QStringLiteral("Premium request mode: local activity is self-tracked against plan assumptions.");
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
    QString demoUrl = QString::fromLocal8Bit(qgetenv("PLASMA_AI_MONITOR_DEMO_BASE_URL")).trimmed();
    if (demoUrl.isEmpty()) {
        demoUrl = QStringLiteral("http://localhost:8080");
    }
    while (demoUrl.endsWith(QLatin1Char('/'))) {
        demoUrl.chop(1);
    }
    QUrl url = qEnvironmentVariableIsSet("PLASMA_AI_MONITOR_DEMO")
        ? QUrl(QStringLiteral("%1/copilot/orgs/%2/copilot/billing").arg(demoUrl, m_orgName))
        : QUrl(QStringLiteral("https://api.github.com/orgs/%1/copilot/billing").arg(m_orgName));

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
