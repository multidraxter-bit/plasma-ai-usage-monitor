#include "subscriptiontoolbackend.h"
#include <QDate>
#include <QDebug>
#include <QTimeZone>
#include <QNetworkAccessManager>

SubscriptionToolBackend::SubscriptionToolBackend(QObject *parent)
    : QObject(parent)
    , m_resetCheckTimer(new QTimer(this))
{
    // Check for period resets every 60 seconds
    m_resetCheckTimer->setInterval(60 * 1000);
    connect(m_resetCheckTimer, &QTimer::timeout, this, &SubscriptionToolBackend::checkAndResetPeriod);
}

SubscriptionToolBackend::~SubscriptionToolBackend() = default;

// --- State ---

bool SubscriptionToolBackend::isEnabled() const { return m_enabled; }
void SubscriptionToolBackend::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        if (enabled) {
            checkToolInstalled();
            if (m_periodStart.isNull()) {
                m_periodStart = QDateTime::currentDateTimeUtc();
                m_secondaryPeriodStart = QDateTime::currentDateTimeUtc();
            }
            m_resetCheckTimer->start();
        } else {
            m_resetCheckTimer->stop();
        }
        Q_EMIT enabledChanged();
    }
}

bool SubscriptionToolBackend::isInstalled() const { return m_installed; }
void SubscriptionToolBackend::setInstalled(bool installed)
{
    if (m_installed != installed) {
        m_installed = installed;
        Q_EMIT installedChanged();
    }
}

QString SubscriptionToolBackend::planTier() const { return m_planTier; }
void SubscriptionToolBackend::setPlanTier(const QString &tier)
{
    if (m_planTier != tier) {
        m_planTier = tier;
        Q_EMIT planTierChanged();
    }
}

// --- Usage ---

int SubscriptionToolBackend::usageCount() const { return m_usageCount; }
void SubscriptionToolBackend::setUsageCount(int count)
{
    m_usageCount = count;
}

int SubscriptionToolBackend::usageLimit() const { return m_usageLimit; }
void SubscriptionToolBackend::setUsageLimit(int limit)
{
    if (m_usageLimit != limit) {
        m_usageLimit = limit;
        Q_EMIT usageLimitChanged();
    }
}

double SubscriptionToolBackend::percentUsed() const
{
    if (m_usageLimit <= 0) return 0.0;
    return (static_cast<double>(m_usageCount) / m_usageLimit) * 100.0;
}

bool SubscriptionToolBackend::isLimitReached() const
{
    return m_usageLimit > 0 && m_usageCount >= m_usageLimit;
}

// --- Secondary Window ---

int SubscriptionToolBackend::secondaryUsageCount() const { return m_secondaryUsageCount; }
void SubscriptionToolBackend::setSecondaryUsageCount(int count)
{
    m_secondaryUsageCount = count;
}

int SubscriptionToolBackend::secondaryUsageLimit() const { return m_secondaryUsageLimit; }
void SubscriptionToolBackend::setSecondaryUsageLimit(int limit)
{
    if (m_secondaryUsageLimit != limit) {
        m_secondaryUsageLimit = limit;
        Q_EMIT usageLimitChanged();
    }
}

double SubscriptionToolBackend::secondaryPercentUsed() const
{
    if (m_secondaryUsageLimit <= 0) return 0.0;
    return (static_cast<double>(m_secondaryUsageCount) / m_secondaryUsageLimit) * 100.0;
}

bool SubscriptionToolBackend::isSecondaryLimitReached() const
{
    return m_secondaryUsageLimit > 0 && m_secondaryUsageCount >= m_secondaryUsageLimit;
}

QString SubscriptionToolBackend::secondaryPeriodLabel() const { return QString(); }
bool SubscriptionToolBackend::hasSecondaryLimit() const { return false; }
SubscriptionToolBackend::UsagePeriod SubscriptionToolBackend::secondaryPeriodType() const { return Weekly; }
int SubscriptionToolBackend::defaultSecondaryLimitForPlan(const QString &) const { return 0; }

// --- Time ---

QDateTime SubscriptionToolBackend::periodStart() const { return m_periodStart; }
void SubscriptionToolBackend::setPeriodStart(const QDateTime &start) { m_periodStart = start; }
void SubscriptionToolBackend::setSecondaryPeriodStart(const QDateTime &start) { m_secondaryPeriodStart = start; }

QDateTime SubscriptionToolBackend::periodEnd() const
{
    return calculatePeriodEnd(primaryPeriodType(), m_periodStart);
}

int SubscriptionToolBackend::monthlyResetDay() const
{
    return m_monthlyResetDay;
}

void SubscriptionToolBackend::setMonthlyResetDay(int day)
{
    const int normalized = qBound(1, day, 28);
    if (m_monthlyResetDay != normalized) {
        m_monthlyResetDay = normalized;
        Q_EMIT usageLimitChanged();
        Q_EMIT usageUpdated();
    }
}

int SubscriptionToolBackend::secondsUntilReset() const
{
    QDateTime end = periodEnd();
    if (!end.isValid()) return 0;
    qint64 secs = QDateTime::currentDateTimeUtc().secsTo(end);
    return secs > 0 ? static_cast<int>(secs) : 0;
}

QString SubscriptionToolBackend::timeUntilReset() const
{
    int secs = secondsUntilReset();
    if (secs <= 0) return QStringLiteral("now");

    int hours = secs / 3600;
    int mins = (secs % 3600) / 60;

    if (hours > 24) {
        int days = hours / 24;
        return QStringLiteral("%1d %2h").arg(days).arg(hours % 24);
    }
    if (hours > 0) {
        return QStringLiteral("%1h %2m").arg(hours).arg(mins);
    }
    return QStringLiteral("%1m").arg(mins);
}

QDateTime SubscriptionToolBackend::lastActivity() const { return m_lastActivity; }
void SubscriptionToolBackend::setLastActivity(const QDateTime &time) { m_lastActivity = time; }

// --- Actions ---

void SubscriptionToolBackend::incrementUsage()
{
    checkAndResetPeriod();

    m_usageCount++;
    m_secondaryUsageCount++;
    m_lastActivity = QDateTime::currentDateTimeUtc();

    checkLimitWarnings();
    Q_EMIT usageUpdated();
    Q_EMIT activityDetected(toolName());
}

void SubscriptionToolBackend::resetUsage()
{
    m_usageCount = 0;
    m_periodStart = QDateTime::currentDateTimeUtc();
    Q_EMIT usageUpdated();
}

// --- Period Management ---

QDateTime SubscriptionToolBackend::calculatePeriodEnd(UsagePeriod period, const QDateTime &start) const
{
    if (!start.isValid()) return QDateTime();

    switch (period) {
    case FiveHour:
        return start.addSecs(5 * 3600);
    case Daily:
        return start.addDays(1);
    case Weekly:
        return start.addDays(7);
    case Monthly: {
        QDate d = start.date();
        QDate resetThisMonth(d.year(), d.month(), m_monthlyResetDay);
        if (d < resetThisMonth) {
            return QDateTime(resetThisMonth, QTime(0, 0), QTimeZone::utc());
        }

        QDate nextMonth = d.addMonths(1);
        QDate resetNextMonth(nextMonth.year(), nextMonth.month(), m_monthlyResetDay);
        return QDateTime(resetNextMonth, QTime(0, 0), QTimeZone::utc());
    }
    }
    return QDateTime();
}

void SubscriptionToolBackend::checkAndResetPeriod()
{
    QDateTime now = QDateTime::currentDateTimeUtc();

    // Check primary period
    QDateTime end = calculatePeriodEnd(primaryPeriodType(), m_periodStart);
    if (end.isValid() && now >= end) {
        m_usageCount = 0;
        m_periodStart = now;
        Q_EMIT usageUpdated();
    }

    // Check secondary period
    if (hasSecondaryLimit()) {
        QDateTime secEnd = calculatePeriodEnd(secondaryPeriodType(), m_secondaryPeriodStart);
        if (secEnd.isValid() && now >= secEnd) {
            m_secondaryUsageCount = 0;
            m_secondaryPeriodStart = now;
            Q_EMIT usageUpdated();
        }
    }
}

// --- Warning Checks ---

void SubscriptionToolBackend::checkLimitWarnings()
{
    if (m_usageLimit <= 0) return;

    double pct = percentUsed();

    if (m_usageCount >= m_usageLimit) {
        Q_EMIT usageLimitReached(toolName());
    } else if (pct >= 80.0) {
        Q_EMIT limitWarning(toolName(), static_cast<int>(pct));
    }

    // Check secondary limit too
    if (hasSecondaryLimit() && m_secondaryUsageLimit > 0) {
        if (m_secondaryUsageCount >= m_secondaryUsageLimit) {
            Q_EMIT usageLimitReached(toolName());
        }
    }
}

// --- Secondary Time ---

QDateTime SubscriptionToolBackend::secondaryPeriodEnd() const
{
    if (!hasSecondaryLimit()) return QDateTime();
    return calculatePeriodEnd(secondaryPeriodType(), m_secondaryPeriodStart);
}

int SubscriptionToolBackend::secondarySecondsUntilReset() const
{
    QDateTime end = secondaryPeriodEnd();
    if (!end.isValid()) return 0;
    qint64 secs = QDateTime::currentDateTimeUtc().secsTo(end);
    return secs > 0 ? static_cast<int>(secs) : 0;
}

QString SubscriptionToolBackend::secondaryTimeUntilReset() const
{
    int secs = secondarySecondsUntilReset();
    if (secs <= 0) return QStringLiteral("now");

    int hours = secs / 3600;
    int mins = (secs % 3600) / 60;

    if (hours > 24) {
        int days = hours / 24;
        return QStringLiteral("%1d %2h").arg(days).arg(hours % 24);
    }
    if (hours > 0) {
        return QStringLiteral("%1h %2m").arg(hours).arg(mins);
    }
    return QStringLiteral("%1m").arg(mins);
}

// --- Session Info ---

double SubscriptionToolBackend::sessionPercentUsed() const { return m_sessionPercentUsed; }
bool SubscriptionToolBackend::hasSessionInfo() const { return m_hasSessionInfo; }
void SubscriptionToolBackend::setSessionPercentUsed(double pct)
{
    m_sessionPercentUsed = pct;
    Q_EMIT usageUpdated();
}
void SubscriptionToolBackend::setHasSessionInfo(bool has)
{
    m_hasSessionInfo = has;
    Q_EMIT usageUpdated();
}

// --- Extra / Metered Usage ---

bool SubscriptionToolBackend::hasExtraUsage() const { return m_hasExtraUsage; }
double SubscriptionToolBackend::extraUsageSpent() const { return m_extraUsageSpent; }
double SubscriptionToolBackend::extraUsageLimit() const { return m_extraUsageLimit; }
double SubscriptionToolBackend::extraUsagePercent() const
{
    if (m_extraUsageLimit <= 0.0) return 0.0;
    return (m_extraUsageSpent / m_extraUsageLimit) * 100.0;
}
QDateTime SubscriptionToolBackend::extraUsageResetDate() const { return m_extraUsageResetDate; }
QString SubscriptionToolBackend::currencySymbol() const { return m_currencySymbol; }

void SubscriptionToolBackend::setExtraUsageSpent(double spent) { m_extraUsageSpent = spent; }
void SubscriptionToolBackend::setExtraUsageLimit(double limit) { m_extraUsageLimit = limit; }
void SubscriptionToolBackend::setExtraUsageResetDate(const QDateTime &date) { m_extraUsageResetDate = date; }
void SubscriptionToolBackend::setCurrencySymbol(const QString &symbol) { m_currencySymbol = symbol; }
void SubscriptionToolBackend::setHasExtraUsage(bool has) { m_hasExtraUsage = has; }

// --- Subscription Cost ---

double SubscriptionToolBackend::subscriptionCost() const { return m_subscriptionCost; }
bool SubscriptionToolBackend::hasSubscriptionCost() const { return false; }
void SubscriptionToolBackend::setSubscriptionCostValue(double cost) { m_subscriptionCost = cost; }
double SubscriptionToolBackend::defaultCostForPlan(const QString &) const { return 0.0; }

// --- Tertiary Usage ---

bool SubscriptionToolBackend::hasTertiaryLimit() const { return false; }
QString SubscriptionToolBackend::tertiaryPeriodLabel() const { return QString(); }
double SubscriptionToolBackend::tertiaryPercentRemaining() const { return m_tertiaryPercentRemaining; }
QDateTime SubscriptionToolBackend::tertiaryResetDate() const { return m_tertiaryResetDate; }
void SubscriptionToolBackend::setTertiaryPercentRemaining(double pct) { m_tertiaryPercentRemaining = pct; }
void SubscriptionToolBackend::setTertiaryResetDate(const QDateTime &date) { m_tertiaryResetDate = date; }

// --- Credits ---

bool SubscriptionToolBackend::hasCredits() const { return false; }
int SubscriptionToolBackend::remainingCredits() const { return m_remainingCredits; }
void SubscriptionToolBackend::setRemainingCredits(int credits) { m_remainingCredits = credits; }

// --- Browser Sync ---

bool SubscriptionToolBackend::isSyncEnabled() const { return m_syncEnabled; }
void SubscriptionToolBackend::setSyncEnabled(bool enabled)
{
    if (m_syncEnabled != enabled) {
        m_syncEnabled = enabled;
        Q_EMIT syncEnabledChanged();
    }
}

QString SubscriptionToolBackend::syncStatus() const { return m_syncStatus; }
QDateTime SubscriptionToolBackend::lastSyncTime() const { return m_lastSyncTime; }
bool SubscriptionToolBackend::isSyncing() const { return m_syncing; }

void SubscriptionToolBackend::setSyncing(bool syncing)
{
    if (m_syncing != syncing) {
        m_syncing = syncing;
        Q_EMIT syncStatusChanged();
    }
}

void SubscriptionToolBackend::setSyncStatus(const QString &status)
{
    if (m_syncStatus != status) {
        m_syncStatus = status;
        Q_EMIT syncStatusChanged();
    }
}

void SubscriptionToolBackend::setLastSyncTime(const QDateTime &time)
{
    m_lastSyncTime = time;
    Q_EMIT syncStatusChanged();
}

void SubscriptionToolBackend::syncFromBrowser(const QString &cookieHeader, int browserType)
{
    Q_UNUSED(cookieHeader);
    Q_UNUSED(browserType);
    // Default implementation — subclasses override for actual sync
    setSyncStatus(QStringLiteral("Not supported"));
    const QString message = QStringLiteral("Sync not implemented for this tool");
    Q_EMIT syncDiagnostic(toolName(), QStringLiteral("not_supported"), message);
    Q_EMIT syncCompleted(false, message);
}

QNetworkAccessManager *SubscriptionToolBackend::networkManager()
{
    if (m_networkManager == nullptr) {
        m_networkManager = new QNetworkAccessManager(this);
    }
    return m_networkManager;
}
