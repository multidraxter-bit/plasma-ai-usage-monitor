#include "jetbrainsmonitor.h"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QFileInfo>

JetBrainsMonitor::JetBrainsMonitor(QObject *parent) : SubscriptionToolBackend(parent) {
    setPlanTier(QStringLiteral("Individual"));
}

QStringList JetBrainsMonitor::availablePlans() const {
    return { QStringLiteral("Individual"), QStringLiteral("Enterprise") };
}

int JetBrainsMonitor::defaultLimitForPlan(const QString &plan) const {
    if (plan == QStringLiteral("Enterprise")) return 5000;
    return 2000;
}

double JetBrainsMonitor::defaultCostForPlan(const QString &plan) const {
    if (plan == QStringLiteral("Enterprise")) return 15.0;
    return 10.0;
}

double JetBrainsMonitor::subscriptionCost() const {
    return defaultCostForPlan(planTier());
}

void JetBrainsMonitor::checkToolInstalled() {
    QStringList logs = findLogFiles();
    setInstalled(!logs.isEmpty());
}

void JetBrainsMonitor::detectActivity() {
    QStringList logs = findLogFiles();
    QDateTime latest;
    
    for (const QString &logPath : logs) {
        QFileInfo fi(logPath);
        if (fi.lastModified() > latest) latest = fi.lastModified();
    }

    if (latest.isValid() && latest > m_lastDetectedActivity) {
        m_lastDetectedActivity = latest;
        incrementUsage(1); // count log change as activity
    }
}

QStringList JetBrainsMonitor::findLogFiles() const {
    QStringList results;
    QString cachePath = QDir::homePath() + QStringLiteral("/.cache/JetBrains");
    QDir dir(cachePath);
    if (!dir.exists()) return results;

    QStringList subdirs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &subdir : subdirs) {
        QString logPath = cachePath + "/" + subdir + "/log/idea.log";
        if (QFile::exists(logPath)) results.append(logPath);
    }
    return results;
}
