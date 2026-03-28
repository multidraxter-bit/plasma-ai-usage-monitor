#ifndef CURSORMONITOR_H
#define CURSORMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QDateTime>

/**
 * Monitor for Cursor AI usage.
 *
 * Tracks usage by watching ~/.cursor/chats and ~/.cursor/ai-tracking/ai-code-tracking.db.
 *
 * Plans:
 * - Free: 50 requests, $0
 * - Pro: 500 requests, $20
 * - Business: 1000 requests, $40
 */
class CursorMonitor : public SubscriptionToolBackend
{
    Q_OBJECT

public:
    explicit CursorMonitor(QObject *parent = nullptr);

    // Identity
    QString toolName() const override { return QStringLiteral("Cursor"); }
    QString iconName() const override { return QStringLiteral("code-context"); }
    QString toolColor() const override { return QStringLiteral("#3ABFF8"); }

    // Period labels
    QString periodLabel() const override { return QStringLiteral("Monthly"); }

    // Plan management
    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;
    Q_INVOKABLE double defaultCostForPlan(const QString &plan) const override;

    // Cost
    double subscriptionCost() const override;
    bool hasSubscriptionCost() const override { return true; }

    // Tool detection
    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return Monthly; }

private:
    QDateTime latestModification(const QString &path, int maxEntries = 100) const;
    QDateTime m_lastDetectedActivity;
    QDateTime m_lastIncrementTime;
};

#endif // CURSORMONITOR_H
