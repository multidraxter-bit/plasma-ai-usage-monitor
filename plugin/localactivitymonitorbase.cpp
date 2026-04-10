#include "localactivitymonitorbase.h"

#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QStandardPaths>

LocalActivityMonitorBase::LocalActivityMonitorBase(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
    , m_debounceTimer(new QTimer(this))
{
    m_debounceTimer->setSingleShot(true);
    m_debounceTimer->setInterval(5000);
    connect(m_debounceTimer, &QTimer::timeout, this, [this]() {
        if (!m_pendingIncrement) {
            return;
        }
        m_pendingIncrement = false;
        incrementUsage();
    });

    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &LocalActivityMonitorBase::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &LocalActivityMonitorBase::onFileChanged);
}

LocalActivityMonitorBase::~LocalActivityMonitorBase() = default;

void LocalActivityMonitorBase::setInstallExecutableNames(const QStringList &names)
{
    m_installExecutableNames = names;
}

void LocalActivityMonitorBase::setInstallPaths(const QStringList &paths)
{
    m_installPaths = paths;
}

void LocalActivityMonitorBase::setWatchedPaths(const QStringList &paths)
{
    m_watchedPaths = paths;
}

void LocalActivityMonitorBase::setIgnoredPathSuffixes(const QStringList &suffixes)
{
    m_ignoredPathSuffixes = suffixes;
}

void LocalActivityMonitorBase::setDebounceIntervalMs(int intervalMs)
{
    m_debounceTimer->setInterval(qMax(250, intervalMs));
}

QStringList LocalActivityMonitorBase::watchedPaths() const
{
    return m_watchedPaths;
}

QDateTime LocalActivityMonitorBase::latestKnownModification() const
{
    return m_lastKnownModification;
}

void LocalActivityMonitorBase::setLatestKnownModification(const QDateTime &time)
{
    m_lastKnownModification = time;
}

void LocalActivityMonitorBase::checkToolInstalled()
{
    bool found = false;

    for (const QString &name : std::as_const(m_installExecutableNames)) {
        if (!QStandardPaths::findExecutable(name).isEmpty()) {
            found = true;
            break;
        }
    }

    if (!found) {
        for (const QString &path : std::as_const(m_installPaths)) {
            if (QFileInfo::exists(path)) {
                found = true;
                break;
            }
        }
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void LocalActivityMonitorBase::detectActivity()
{
    QDateTime newestTimestamp;

    for (const QString &path : std::as_const(m_watchedPaths)) {
        const QDateTime modified = latestModification(path);
        if (modified.isValid() && (!newestTimestamp.isValid() || modified > newestTimestamp)) {
            newestTimestamp = modified;
        }
    }

    scheduleIncrement(newestTimestamp);
}

QDateTime LocalActivityMonitorBase::latestModification(const QString &path, int maxEntries)
{
    QFileInfo info(path);
    if (!info.exists()) {
        return {};
    }

    if (info.isFile()) {
        return info.lastModified();
    }

    QDateTime newest = info.lastModified();
    QDirIterator it(path,
                    QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot,
                    QDirIterator::Subdirectories);
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

void LocalActivityMonitorBase::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) {
        return;
    }
    detectActivity();
}

void LocalActivityMonitorBase::onFileChanged(const QString &path)
{
    if (!isEnabled()) {
        return;
    }

    if (shouldIgnorePath(path)) {
        if (QFileInfo::exists(path) && !m_watcher->files().contains(path)) {
            m_watcher->addPath(path);
        }
        return;
    }

    scheduleIncrement(QFileInfo(path).lastModified());

    if (QFileInfo::exists(path) && !m_watcher->files().contains(path)) {
        m_watcher->addPath(path);
    }
}

void LocalActivityMonitorBase::setupWatcher()
{
    const QStringList existingDirs = m_watcher->directories();
    if (!existingDirs.isEmpty()) {
        m_watcher->removePaths(existingDirs);
    }

    const QStringList existingFiles = m_watcher->files();
    if (!existingFiles.isEmpty()) {
        m_watcher->removePaths(existingFiles);
    }

    QStringList pathsToWatch;
    for (const QString &path : std::as_const(m_watchedPaths)) {
        QFileInfo info(path);
        if (!info.exists()) {
            continue;
        }

        pathsToWatch.append(info.absoluteFilePath());

        if (info.isDir()) {
            QDirIterator it(info.absoluteFilePath(),
                            QDir::Dirs | QDir::NoDotAndDotDot,
                            QDirIterator::Subdirectories);
            while (it.hasNext()) {
                pathsToWatch.append(it.next());
            }
        }
    }

    pathsToWatch.removeDuplicates();
    if (!pathsToWatch.isEmpty()) {
        m_watcher->addPaths(pathsToWatch);
    }
}

void LocalActivityMonitorBase::scheduleIncrement(const QDateTime &modified)
{
    if (!modified.isValid() || modified <= m_lastKnownModification) {
        return;
    }

    m_lastKnownModification = modified;
    m_pendingIncrement = true;
    if (!m_debounceTimer->isActive()) {
        m_debounceTimer->start();
    }
}

bool LocalActivityMonitorBase::shouldIgnorePath(const QString &path) const
{
    for (const QString &suffix : std::as_const(m_ignoredPathSuffixes)) {
        if (path.endsWith(suffix)) {
            return true;
        }
    }
    return false;
}
