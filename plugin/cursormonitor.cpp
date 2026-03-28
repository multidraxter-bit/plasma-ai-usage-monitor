#include "cursormonitor.h"
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QDirIterator>
#include <QDebug>

CursorMonitor::CursorMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
{
}

void CursorMonitor::checkToolInstalled()
{
    // Check for existence of ~/.cursor
    bool found = QDir(QDir::homePath() + QStringLiteral("/.cursor")).exists();
    setInstalled(found);
}

void CursorMonitor::detectActivity()
{
    const QString home = QDir::homePath();
    const QStringList candidatePaths = {
        home + QStringLiteral("/.cursor/chats"),
        home + QStringLiteral("/.cursor/ai-tracking/ai-code-tracking.db")
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
        return;
    }

    if (!m_lastDetectedActivity.isValid()) {
        m_lastDetectedActivity = newestTimestamp;
        return;
    }

    if (newestTimestamp > m_lastDetectedActivity) {
        m_lastDetectedActivity = newestTimestamp;
        
        // Debounce: only increment if 10s passed since last increment
        QDateTime now = QDateTime::currentDateTime();
        if (!m_lastIncrementTime.isValid() || m_lastIncrementTime.secsTo(now) >= 10) {
            m_lastIncrementTime = now;
            qInfo() << "CursorMonitor: activity detected from" << newestPath << "at" << newestTimestamp;
            incrementUsage();
        }
    }
}

QDateTime CursorMonitor::latestModification(const QString &path, int maxEntries) const
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

QStringList CursorMonitor::availablePlans() const
{
    return {
        QStringLiteral("Free"),
        QStringLiteral("Pro"),
        QStringLiteral("Business")
    };
}

int CursorMonitor::defaultLimitForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Free")) return 50;
    if (plan == QStringLiteral("Pro")) return 500;
    if (plan == QStringLiteral("Business")) return 1000;
    return 50;
}

double CursorMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}

double CursorMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Free")) return 0.0;
    if (plan == QStringLiteral("Pro")) return 20.0;
    if (plan == QStringLiteral("Business")) return 40.0;
    return 0.0;
}
