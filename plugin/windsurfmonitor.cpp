#include "windsurfmonitor.h"

#include <QDir>

WindsurfMonitor::WindsurfMonitor(QObject *parent)
    : LocalActivityMonitorBase(parent)
{
    const QString root = QDir::homePath() + QStringLiteral("/.codeium");
    setInstallExecutableNames({QStringLiteral("windsurf")});
    setInstallPaths({root});
    setWatchedPaths({root});
}

QStringList WindsurfMonitor::availablePlans() const
{
    return {
        QStringLiteral("Pro"),
        QStringLiteral("Teams")
    };
}

int WindsurfMonitor::defaultLimitForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Teams")) return 2000;
    return 500;
}

double WindsurfMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Teams")) return 30.0;
    return 15.0;
}

double WindsurfMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}
