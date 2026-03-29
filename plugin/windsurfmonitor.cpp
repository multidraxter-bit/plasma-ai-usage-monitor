#include "windsurfmonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

WindsurfMonitor::WindsurfMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_debounceTimer(new QTimer(this))
{
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(10000); // 10 second debounce
    connect(m_debounceTimer, &QTimer::timeout, this, [this]() {
        if (m_pendingIncrement) {
            m_pendingIncrement = false;
            incrementUsage();
        }
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged, this, &WindsurfMonitor::onFilesystemChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, &WindsurfMonitor::onFilesystemChanged);
}

QStringList WindsurfMonitor::availablePlans() const
{
    return {
        QStringLiteral("Individual"),
        QStringLiteral("Pro"),
        QStringLiteral("Teams")
    };
}

int WindsurfMonitor::defaultLimitForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Individual")) return 50;
    if (plan == QStringLiteral("Pro")) return 500;
    if (plan == QStringLiteral("Teams")) return 1000;
    return 50;
}

double WindsurfMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Pro")) return 20.0;
    if (plan == QStringLiteral("Teams")) return 40.0;
    return 0.0;
}

void WindsurfMonitor::checkToolInstalled()
{
    QString configDir = QDir::homePath() + QStringLiteral("/.codeium");
    bool found = QDir(configDir).exists();
    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void WindsurfMonitor::setupWatcher()
{
    QString configDir = QDir::homePath() + QStringLiteral("/.codeium");
    if (QDir(configDir).exists()) {
        m_watcher->addPath(configDir);
    }
}

void WindsurfMonitor::detectActivity()
{
    QString configDir = QDir::homePath() + QStringLiteral("/.codeium");
    QDir dir(configDir);
    if (!dir.exists()) return;

    const auto entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot, QDir::Time);
    if (!entries.isEmpty()) {
        QDateTime latest = entries.first().lastModified();
        if (latest > m_lastKnownModification) {
            m_lastKnownModification = latest;
            m_pendingIncrement = true;
            if (!m_debounceTimer->isActive()) {
                m_debounceTimer->start();
            }
        }
    }
}

void WindsurfMonitor::onFilesystemChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();

    // Re-add path if it's a file (watcher removes after change)
    if (QFileInfo(path).isFile() && !m_watcher->files().contains(path)) {
        m_watcher->addPath(path);
    }
}
