#ifndef JETBRAINSMONITOR_H
#define JETBRAINSMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QDateTime>

class JetBrainsMonitor : public SubscriptionToolBackend
{
    Q_OBJECT

public:
    explicit JetBrainsMonitor(QObject *parent = nullptr);

    QString toolName() const override { return QStringLiteral("JetBrains AI"); }
    QString iconName() const override { return QStringLiteral("code-context"); }
    QString toolColor() const override { return QStringLiteral("#000000"); }

    QString periodLabel() const override { return QStringLiteral("Monthly"); }

    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;
    Q_INVOKABLE double defaultCostForPlan(const QString &plan) const override;

    double subscriptionCost() const override;
    bool hasSubscriptionCost() const override { return true; }

    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return Monthly; }

private:
    QStringList findLogFiles() const;
    QDateTime m_lastDetectedActivity;
};

#endif
