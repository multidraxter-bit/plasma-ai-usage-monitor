#ifndef WINDSURFMONITOR_H
#define WINDSURFMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QFileSystemWatcher>
#include <QDateTime>

class WindsurfMonitor : public SubscriptionToolBackend
{
    Q_OBJECT
public:
    explicit WindsurfMonitor(QObject *parent = nullptr);

    QString toolName() const override { return QStringLiteral("Windsurf (Codeium)"); }
    QString iconName() const override { return QStringLiteral("com.github.loofi.aiusagemonitor-windsurf"); }
    QString toolColor() const override { return QStringLiteral("#00ADFF"); }
    QString periodLabel() const override { return QStringLiteral("Monthly"); }

    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;
    Q_INVOKABLE double defaultCostForPlan(const QString &plan) const override;
    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return Monthly; }

private Q_SLOTS:
    void onFilesystemChanged(const QString &path);

private:
    void setupWatcher();
    QFileSystemWatcher *m_watcher;
    QDateTime m_lastKnownModification;
    QTimer *m_debounceTimer;
    bool m_pendingIncrement = false;
};

#endif
