#include "cursormonitor.h"

#include <QDir>

CursorMonitor::CursorMonitor(QObject *parent)
    : LocalActivityMonitorBase(parent)
{
    const QString root = QDir::homePath() + QStringLiteral("/.cursor");
    setInstallExecutableNames({QStringLiteral("cursor")});
    setInstallPaths({root});
    setWatchedPaths({root});
}

QStringList CursorMonitor::availablePlans() const
{
    return {
        QStringLiteral("Pro"),
        QStringLiteral("Business")
    };
}

int CursorMonitor::defaultLimitForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Business")) return 2000;
    return 500;
}

double CursorMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Business")) return 40.0;
    return 20.0;
}

double CursorMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}
