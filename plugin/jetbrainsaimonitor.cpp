#include "jetbrainsaimonitor.h"

#include <QDir>

JetBrainsAiMonitor::JetBrainsAiMonitor(QObject *parent)
    : LocalActivityMonitorBase(parent)
{
    const QString root = QDir::homePath() + QStringLiteral("/.config/JetBrains");
    setInstallPaths({root});
    setWatchedPaths({root});
}

QStringList JetBrainsAiMonitor::availablePlans() const
{
    return {
        QStringLiteral("AI Free"),
        QStringLiteral("AI Pro"),
        QStringLiteral("All Products + AI")
    };
}

int JetBrainsAiMonitor::defaultLimitForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("AI Pro")) return 1500;
    if (plan == QStringLiteral("All Products + AI")) return 3000;
    return 100;
}

double JetBrainsAiMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("AI Pro")) return 10.0;
    if (plan == QStringLiteral("All Products + AI")) return 29.0;
    return 0.0;
}

double JetBrainsAiMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}
