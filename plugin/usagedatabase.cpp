#include "usagedatabase.h"
#include <QDir>
#include <QStandardPaths>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFileInfo>
#include <QDebug>
#include <QMap>
#include <QTimeZone>
#include <cmath>

std::atomic<int> UsageDatabase::s_instanceCounter{0};

namespace {
constexpr int MAX_SERIES_POINTS = 240;

struct BucketAggregate {
    double sum = 0.0;
    int count = 0;
    QDateTime bucketStart;
};

QDateTime parseSnapshotTimestamp(const QString &raw)
{
    QDateTime dt = QDateTime::fromString(raw, Qt::ISODate);
    if (!dt.isValid()) {
        dt = QDateTime::fromString(raw, QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    }
    if (!dt.isValid()) {
        return {};
    }

    if (dt.timeSpec() == Qt::UTC
        || dt.timeSpec() == Qt::OffsetFromUTC
        || dt.timeSpec() == Qt::TimeZone) {
        return dt.toUTC();
    }

    return QDateTime(dt.date(), dt.time(), QTimeZone::utc());
}

QString toDbDateTimeString(const QDateTime &dt)
{
    return dt.toUTC().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
}

int effectiveBucketSeconds(const QDateTime &fromUtc, const QDateTime &toUtc, int bucketMinutes)
{
    int baseBucketSecs = qBound(1, bucketMinutes, 24 * 60) * 60;
    qint64 rangeSecs = qMax<qint64>(1, fromUtc.secsTo(toUtc));
    int minBucketSecs = static_cast<int>(
        std::ceil(static_cast<double>(rangeSecs) / static_cast<double>(MAX_SERIES_POINTS)));
    return qMax(baseBucketSecs, minBucketSecs);
}

double deltaPercent(double first, double last)
{
    if (qFuzzyIsNull(first)) {
        return 0.0;
    }
    return ((last - first) / std::abs(first)) * 100.0;
}

QVariantList bucketToPoints(const QMap<qint64, BucketAggregate> &buckets)
{
    QVariantList points;
    for (auto it = buckets.constBegin(); it != buckets.constEnd(); ++it) {
        const BucketAggregate &bucket = it.value();
        if (bucket.count <= 0 || !bucket.bucketStart.isValid()) {
            continue;
        }

        QVariantMap point;
        point[QStringLiteral("timestamp")] = bucket.bucketStart.toString(Qt::ISODate);
        point[QStringLiteral("value")] = bucket.sum / static_cast<double>(bucket.count);
        points.append(point);
    }
    return points;
}
} // namespace

UsageDatabase::UsageDatabase(QObject *parent)
    : QObject(parent)
    , m_connectionName(QStringLiteral("aiusagemonitor_history_%1").arg(s_instanceCounter.fetch_add(1)))
{
}

UsageDatabase::~UsageDatabase()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
    QSqlDatabase::removeDatabase(m_connectionName);
}

bool UsageDatabase::isEnabled() const { return m_enabled; }
void UsageDatabase::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        Q_EMIT enabledChanged();
    }
}

int UsageDatabase::retentionDays() const { return m_retentionDays; }
void UsageDatabase::setRetentionDays(int days)
{
    // Clamp to valid range: 1–365
    days = qBound(1, days, 365);
    if (m_retentionDays != days) {
        m_retentionDays = days;
        Q_EMIT retentionDaysChanged();
    }
}

void UsageDatabase::initDatabase()
{
    if (m_initialized)
        return;

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                      + QStringLiteral("/plasma-ai-usage-monitor");
    QDir().mkpath(dataDir);

    QString dbPath = dataDir + QStringLiteral("/usage_history.db");

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName);
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "UsageDatabase: Failed to open database:" << m_db.lastError().text();
        return;
    }

    // Enable WAL mode for better concurrent read performance
    QSqlQuery pragma(m_db);
    pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));

    createTables();
    m_initialized = true;
}

void UsageDatabase::createTables()
{
    QSqlQuery query(m_db);

    // Usage snapshots -- one row per provider per refresh
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS usage_snapshots ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  provider TEXT NOT NULL,"
        "  input_tokens INTEGER DEFAULT 0,"
        "  output_tokens INTEGER DEFAULT 0,"
        "  request_count INTEGER DEFAULT 0,"
        "  cost REAL DEFAULT 0.0,"
        "  daily_cost REAL DEFAULT 0.0,"
        "  monthly_cost REAL DEFAULT 0.0,"
        "  rl_requests INTEGER DEFAULT 0,"
        "  rl_requests_remaining INTEGER DEFAULT 0,"
        "  rl_tokens INTEGER DEFAULT 0,"
        "  rl_tokens_remaining INTEGER DEFAULT 0"
        ")"
    ));

    // Indexes for efficient time-range queries
    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_snapshots_provider_time "
        "ON usage_snapshots(provider, timestamp)"
    ));

    // Rate limit events -- recorded when thresholds are hit
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS rate_limit_events ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  provider TEXT NOT NULL,"
        "  event_type TEXT NOT NULL,"
        "  percent_used INTEGER DEFAULT 0"
        ")"
    ));

    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_ratelimit_provider_time "
        "ON rate_limit_events(provider, timestamp)"
    ));

    // Subscription tool usage snapshots
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS subscription_tool_usage ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  tool_name TEXT NOT NULL,"
        "  usage_count INTEGER DEFAULT 0,"
        "  usage_limit INTEGER DEFAULT 0,"
        "  period_type TEXT NOT NULL,"
        "  plan_tier TEXT DEFAULT '',"
        "  limit_reached BOOLEAN DEFAULT 0"
        ")"
    ));

    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_tool_usage_name_time "
        "ON subscription_tool_usage(tool_name, timestamp)"
    ));
}

void UsageDatabase::recordSnapshot(const QString &provider,
                                    qint64 inputTokens,
                                    qint64 outputTokens,
                                    int requestCount,
                                    double cost,
                                    double dailyCost,
                                    double monthlyCost,
                                    int rateLimitRequests,
                                    int rateLimitRequestsRemaining,
                                    int rateLimitTokens,
                                    int rateLimitTokensRemaining)
{
    if (!m_enabled)
        return;

    // Throttle writes: skip if the same provider wrote recently AND data hasn't changed
    qint64 now = QDateTime::currentSecsSinceEpoch();
    qint64 lastWrite = m_lastWriteTime.value(provider, 0);
    double lastCost = m_lastWrittenCost.value(provider, -1.0);

    bool dataChanged = (cost != lastCost);
    bool throttled = (now - lastWrite) < WRITE_THROTTLE_SECS;

    if (throttled && !dataChanged)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO usage_snapshots "
        "(provider, input_tokens, output_tokens, request_count, cost, daily_cost, monthly_cost, "
        "rl_requests, rl_requests_remaining, rl_tokens, rl_tokens_remaining) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    ));
    query.addBindValue(provider);
    query.addBindValue(inputTokens);
    query.addBindValue(outputTokens);
    query.addBindValue(requestCount);
    query.addBindValue(cost);
    query.addBindValue(dailyCost);
    query.addBindValue(monthlyCost);
    query.addBindValue(rateLimitRequests);
    query.addBindValue(rateLimitRequestsRemaining);
    query.addBindValue(rateLimitTokens);
    query.addBindValue(rateLimitTokensRemaining);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record snapshot:" << query.lastError().text();
    } else {
        m_lastWriteTime[provider] = now;
        m_lastWrittenCost[provider] = cost;
    }
}

void UsageDatabase::recordRateLimitEvent(const QString &provider,
                                          const QString &eventType,
                                          int percentUsed)
{
    if (!m_enabled)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO rate_limit_events (provider, event_type, percent_used) VALUES (?, ?, ?)"
    ));
    query.addBindValue(provider);
    query.addBindValue(eventType);
    query.addBindValue(percentUsed);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record rate limit event:" << query.lastError().text();
    }
}

void UsageDatabase::recordToolSnapshot(const QString &toolName,
                                        int usageCount,
                                        int usageLimit,
                                        const QString &periodType,
                                        const QString &planTier,
                                        bool limitReached)
{
    if (!m_enabled)
        return;

    // Throttle writes: skip if the same tool wrote recently AND data hasn't changed
    qint64 now = QDateTime::currentSecsSinceEpoch();
    QString throttleKey = QStringLiteral("tool:") + toolName;
    qint64 lastWrite = m_lastWriteTime.value(throttleKey, 0);
    double lastCount = m_lastWrittenCost.value(throttleKey, -1.0);

    bool dataChanged = (static_cast<double>(usageCount) != lastCount);
    bool throttled = (now - lastWrite) < WRITE_THROTTLE_SECS;

    if (throttled && !dataChanged)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO subscription_tool_usage "
        "(tool_name, usage_count, usage_limit, period_type, plan_tier, limit_reached) "
        "VALUES (?, ?, ?, ?, ?, ?)"
    ));
    query.addBindValue(toolName);
    query.addBindValue(usageCount);
    query.addBindValue(usageLimit);
    query.addBindValue(periodType);
    query.addBindValue(planTier);
    query.addBindValue(limitReached ? 1 : 0);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record tool snapshot:" << query.lastError().text();
    } else {
        m_lastWriteTime[throttleKey] = now;
        m_lastWrittenCost[throttleKey] = static_cast<double>(usageCount);
    }
}

QVariantList UsageDatabase::getSnapshots(const QString &provider,
                                          const QDateTime &from,
                                          const QDateTime &to) const
{
    QVariantList results;

    if (!m_initialized)
        return results;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT timestamp, input_tokens, output_tokens, request_count, cost, "
        "daily_cost, monthly_cost, rl_requests, rl_requests_remaining, "
        "rl_tokens, rl_tokens_remaining "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ? "
        "ORDER BY timestamp ASC"
    ));
    query.addBindValue(provider);
    query.addBindValue(toDbDateTimeString(from));
    query.addBindValue(toDbDateTimeString(to));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getSnapshots query failed:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("timestamp")] = query.value(0).toString();
        row[QStringLiteral("inputTokens")] = query.value(1).toLongLong();
        row[QStringLiteral("outputTokens")] = query.value(2).toLongLong();
        row[QStringLiteral("requestCount")] = query.value(3).toInt();
        row[QStringLiteral("cost")] = query.value(4).toDouble();
        row[QStringLiteral("dailyCost")] = query.value(5).toDouble();
        row[QStringLiteral("monthlyCost")] = query.value(6).toDouble();
        row[QStringLiteral("rlRequests")] = query.value(7).toInt();
        row[QStringLiteral("rlRequestsRemaining")] = query.value(8).toInt();
        row[QStringLiteral("rlTokens")] = query.value(9).toInt();
        row[QStringLiteral("rlTokensRemaining")] = query.value(10).toInt();
        results.append(row);
    }

    return results;
}

QVariantList UsageDatabase::getDailyCosts(const QString &provider,
                                           const QDateTime &from,
                                           const QDateTime &to) const
{
    QVariantList results;

    if (!m_initialized)
        return results;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT date(timestamp) as day, MAX(cost) as total_cost, MAX(daily_cost) as max_daily "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ? "
        "GROUP BY day ORDER BY day ASC"
    ));
    query.addBindValue(provider);
    query.addBindValue(toDbDateTimeString(from));
    query.addBindValue(toDbDateTimeString(to));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getDailyCosts query failed:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("date")] = query.value(0).toString();
        row[QStringLiteral("totalCost")] = query.value(1).toDouble();
        row[QStringLiteral("maxDailyCost")] = query.value(2).toDouble();
        results.append(row);
    }

    return results;
}

QVariantMap UsageDatabase::getSummary(const QString &provider,
                                      const QDateTime &from,
                                      const QDateTime &to) const
{
    QVariantMap result;

    if (!m_initialized)
        return result;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT MAX(cost) as total_cost, "
        "AVG(daily_cost) as avg_daily, MAX(daily_cost) as max_daily, "
        "MAX(request_count) as total_requests, "
        "MAX(input_tokens + output_tokens) as peak_tokens, "
        "COUNT(*) as snapshot_count "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ?"
    ));
    query.addBindValue(provider);
    query.addBindValue(toDbDateTimeString(from));
    query.addBindValue(toDbDateTimeString(to));

    if (!query.exec() || !query.next()) {
        qWarning() << "UsageDatabase: getSummary query failed:" << query.lastError().text();
        return result;
    }

    result[QStringLiteral("totalCost")] = query.value(0).toDouble();
    result[QStringLiteral("avgDailyCost")] = query.value(1).toDouble();
    result[QStringLiteral("maxDailyCost")] = query.value(2).toDouble();
    result[QStringLiteral("totalRequests")] = query.value(3).toInt();
    result[QStringLiteral("peakTokenUsage")] = query.value(4).toLongLong();
    result[QStringLiteral("snapshotCount")] = query.value(5).toInt();

    return result;
}

QStringList UsageDatabase::getProviders() const
{
    QStringList providers;

    if (!m_initialized)
        return providers;

    QSqlQuery query(m_db);
    query.exec(QStringLiteral(
        "SELECT DISTINCT provider FROM usage_snapshots ORDER BY provider"
    ));

    while (query.next()) {
        providers.append(query.value(0).toString());
    }

    return providers;
}

QVariantList UsageDatabase::getToolSnapshots(const QString &toolName,
                                               const QDateTime &from,
                                               const QDateTime &to) const
{
    QVariantList results;

    if (!m_initialized)
        return results;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT timestamp, usage_count, usage_limit, period_type, "
        "plan_tier, limit_reached "
        "FROM subscription_tool_usage "
        "WHERE tool_name = ? AND timestamp >= ? AND timestamp <= ? "
        "ORDER BY timestamp ASC"
    ));
    query.addBindValue(toolName);
    query.addBindValue(toDbDateTimeString(from));
    query.addBindValue(toDbDateTimeString(to));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getToolSnapshots query failed:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("timestamp")] = query.value(0).toString();
        row[QStringLiteral("usageCount")] = query.value(1).toInt();
        row[QStringLiteral("usageLimit")] = query.value(2).toInt();
        row[QStringLiteral("periodType")] = query.value(3).toString();
        row[QStringLiteral("planTier")] = query.value(4).toString();
        row[QStringLiteral("limitReached")] = query.value(5).toBool();
        int limit = query.value(2).toInt();
        row[QStringLiteral("percentUsed")] = limit > 0
            ? qRound(query.value(1).toDouble() / limit * 100.0) : 0;
        results.append(row);
    }

    return results;
}

QStringList UsageDatabase::getToolNames() const
{
    QStringList names;

    if (!m_initialized)
        return names;

    QSqlQuery query(m_db);
    query.exec(QStringLiteral(
        "SELECT DISTINCT tool_name FROM subscription_tool_usage ORDER BY tool_name"
    ));

    while (query.next()) {
        names.append(query.value(0).toString());
    }

    return names;
}

QVariantList UsageDatabase::getProviderSeries(const QStringList &providers,
                                              const QDateTime &from,
                                              const QDateTime &to,
                                              const QString &metric,
                                              int bucketMinutes) const
{
    QVariantList results;

    if (!m_initialized || providers.isEmpty()) {
        return results;
    }

    if (metric != QStringLiteral("cost")
        && metric != QStringLiteral("tokens")
        && metric != QStringLiteral("requests")
        && metric != QStringLiteral("rateLimitUsed")) {
        return results;
    }

    const QDateTime fromUtc = from.toUTC();
    const QDateTime toUtc = to.toUTC();
    if (!fromUtc.isValid() || !toUtc.isValid() || fromUtc >= toUtc) {
        return results;
    }

    const int bucketSecs = effectiveBucketSeconds(fromUtc, toUtc, bucketMinutes);

    for (const QString &provider : providers) {
        if (provider.isEmpty()) {
            continue;
        }

        QSqlQuery query(m_db);
        query.prepare(QStringLiteral(
            "SELECT timestamp, cost, input_tokens, output_tokens, request_count, "
            "rl_requests, rl_requests_remaining "
            "FROM usage_snapshots "
            "WHERE provider = ? AND timestamp >= ? AND timestamp <= ? "
            "ORDER BY timestamp ASC"
        ));
        query.addBindValue(provider);
        query.addBindValue(toDbDateTimeString(fromUtc));
        query.addBindValue(toDbDateTimeString(toUtc));

        if (!query.exec()) {
            qWarning() << "UsageDatabase: getProviderSeries query failed for" << provider
                       << ":" << query.lastError().text();
            continue;
        }

        QMap<qint64, BucketAggregate> buckets;
        int sampleCount = 0;

        while (query.next()) {
            const QDateTime ts = parseSnapshotTimestamp(query.value(0).toString());
            if (!ts.isValid() || ts < fromUtc || ts > toUtc) {
                continue;
            }

            double value = 0.0;
            if (metric == QStringLiteral("cost")) {
                value = query.value(1).toDouble();
            } else if (metric == QStringLiteral("tokens")) {
                value = static_cast<double>(query.value(2).toLongLong() + query.value(3).toLongLong());
            } else if (metric == QStringLiteral("requests")) {
                value = static_cast<double>(query.value(4).toInt());
            } else if (metric == QStringLiteral("rateLimitUsed")) {
                const int limit = query.value(5).toInt();
                const int remaining = query.value(6).toInt();
                if (limit > 0) {
                    value = (static_cast<double>(limit - remaining) / static_cast<double>(limit)) * 100.0;
                }
            }

            const qint64 bucketIndex = fromUtc.secsTo(ts) / bucketSecs;
            BucketAggregate &bucket = buckets[bucketIndex];
            if (!bucket.bucketStart.isValid()) {
                bucket.bucketStart = fromUtc.addSecs(bucketIndex * bucketSecs);
            }
            bucket.sum += value;
            bucket.count++;
            sampleCount++;
        }

        const QVariantList points = bucketToPoints(buckets);
        QVariantMap series;
        series[QStringLiteral("name")] = provider;
        series[QStringLiteral("points")] = points;
        series[QStringLiteral("sampleCount")] = sampleCount;

        double latestValue = 0.0;
        double change = 0.0;
        if (!points.isEmpty()) {
            const double first = points.first().toMap().value(QStringLiteral("value")).toDouble();
            latestValue = points.last().toMap().value(QStringLiteral("value")).toDouble();
            change = deltaPercent(first, latestValue);
        }

        series[QStringLiteral("latestValue")] = latestValue;
        series[QStringLiteral("deltaPercent")] = change;
        results.append(series);
    }

    return results;
}

QVariantList UsageDatabase::getToolSeries(const QStringList &tools,
                                          const QDateTime &from,
                                          const QDateTime &to,
                                          const QString &metric,
                                          int bucketMinutes) const
{
    QVariantList results;

    if (!m_initialized || tools.isEmpty()) {
        return results;
    }

    if (metric != QStringLiteral("percentUsed")
        && metric != QStringLiteral("usageCount")
        && metric != QStringLiteral("remaining")) {
        return results;
    }

    const QDateTime fromUtc = from.toUTC();
    const QDateTime toUtc = to.toUTC();
    if (!fromUtc.isValid() || !toUtc.isValid() || fromUtc >= toUtc) {
        return results;
    }

    const int bucketSecs = effectiveBucketSeconds(fromUtc, toUtc, bucketMinutes);

    for (const QString &tool : tools) {
        if (tool.isEmpty()) {
            continue;
        }

        QSqlQuery query(m_db);
        query.prepare(QStringLiteral(
            "SELECT timestamp, usage_count, usage_limit "
            "FROM subscription_tool_usage "
            "WHERE tool_name = ? AND timestamp >= ? AND timestamp <= ? "
            "ORDER BY timestamp ASC"
        ));
        query.addBindValue(tool);
        query.addBindValue(toDbDateTimeString(fromUtc));
        query.addBindValue(toDbDateTimeString(toUtc));

        if (!query.exec()) {
            qWarning() << "UsageDatabase: getToolSeries query failed for" << tool
                       << ":" << query.lastError().text();
            continue;
        }

        QMap<qint64, BucketAggregate> buckets;
        int sampleCount = 0;

        while (query.next()) {
            const QDateTime ts = parseSnapshotTimestamp(query.value(0).toString());
            if (!ts.isValid() || ts < fromUtc || ts > toUtc) {
                continue;
            }

            const int usageCount = query.value(1).toInt();
            const int usageLimit = query.value(2).toInt();

            double value = 0.0;
            if (metric == QStringLiteral("usageCount")) {
                value = static_cast<double>(usageCount);
            } else if (metric == QStringLiteral("remaining")) {
                value = static_cast<double>(qMax(0, usageLimit - usageCount));
            } else if (metric == QStringLiteral("percentUsed")) {
                if (usageLimit > 0) {
                    value = (static_cast<double>(usageCount) / static_cast<double>(usageLimit)) * 100.0;
                }
            }

            const qint64 bucketIndex = fromUtc.secsTo(ts) / bucketSecs;
            BucketAggregate &bucket = buckets[bucketIndex];
            if (!bucket.bucketStart.isValid()) {
                bucket.bucketStart = fromUtc.addSecs(bucketIndex * bucketSecs);
            }
            bucket.sum += value;
            bucket.count++;
            sampleCount++;
        }

        const QVariantList points = bucketToPoints(buckets);
        QVariantMap series;
        series[QStringLiteral("name")] = tool;
        series[QStringLiteral("points")] = points;
        series[QStringLiteral("sampleCount")] = sampleCount;

        double latestValue = 0.0;
        double change = 0.0;
        if (!points.isEmpty()) {
            const double first = points.first().toMap().value(QStringLiteral("value")).toDouble();
            latestValue = points.last().toMap().value(QStringLiteral("value")).toDouble();
            change = deltaPercent(first, latestValue);
        }

        series[QStringLiteral("latestValue")] = latestValue;
        series[QStringLiteral("deltaPercent")] = change;
        results.append(series);
    }

    return results;
}

QString UsageDatabase::exportCsv(const QString &provider,
                                  const QDateTime &from,
                                  const QDateTime &to) const
{
    QString csv;
    csv += QStringLiteral("timestamp,provider,input_tokens,output_tokens,request_count,"
                          "cost,daily_cost,monthly_cost,rl_requests,rl_requests_remaining,"
                          "rl_tokens,rl_tokens_remaining\n");

    QVariantList snapshots = getSnapshots(provider, from, to);
    for (const QVariant &snap : snapshots) {
        QVariantMap row = snap.toMap();
        // Qt's multi-arg .arg() supports at most 9 QString arguments,
        // so we split into two chained calls.
        csv += QStringLiteral("%1,%2,%3,%4,%5,%6,%7,%8,%9,")
                   .arg(row[QStringLiteral("timestamp")].toString(),
                        provider,
                        QString::number(row[QStringLiteral("inputTokens")].toLongLong()),
                        QString::number(row[QStringLiteral("outputTokens")].toLongLong()),
                        QString::number(row[QStringLiteral("requestCount")].toInt()),
                        QString::number(row[QStringLiteral("cost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("dailyCost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("monthlyCost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("rlRequests")].toInt()));
        csv += QStringLiteral("%1,%2,%3\n")
                   .arg(QString::number(row[QStringLiteral("rlRequestsRemaining")].toInt()),
                        QString::number(row[QStringLiteral("rlTokens")].toInt()),
                        QString::number(row[QStringLiteral("rlTokensRemaining")].toInt()));
    }

    return csv;
}

QString UsageDatabase::exportJson(const QString &provider,
                                   const QDateTime &from,
                                   const QDateTime &to) const
{
    QVariantList snapshots = getSnapshots(provider, from, to);

    QJsonArray arr;
    for (const QVariant &snap : snapshots) {
        arr.append(QJsonObject::fromVariantMap(snap.toMap()));
    }

    QJsonObject root;
    root[QStringLiteral("provider")] = provider;
    root[QStringLiteral("from")] = from.toString(Qt::ISODate);
    root[QStringLiteral("to")] = to.toString(Qt::ISODate);
    root[QStringLiteral("snapshots")] = arr;

    return QString::fromUtf8(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

void UsageDatabase::init()
{
    if (m_enabled) {
        initDatabase();
    }
}

void UsageDatabase::pruneOldData()
{
    if (!m_initialized)
        return;

    QDateTime cutoff = QDateTime::currentDateTimeUtc().addDays(-m_retentionDays);
    QString cutoffStr = toDbDateTimeString(cutoff);

    // Wrap all deletes in a single transaction for atomicity and performance
    m_db.transaction();

    int totalDeleted = 0;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "DELETE FROM usage_snapshots WHERE timestamp < ?"
    ));
    query.addBindValue(cutoffStr);
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune snapshots:" << query.lastError().text();
    } else {
        totalDeleted += query.numRowsAffected();
    }

    query.prepare(QStringLiteral(
        "DELETE FROM rate_limit_events WHERE timestamp < ?"
    ));
    query.addBindValue(cutoffStr);
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune events:" << query.lastError().text();
    } else {
        totalDeleted += query.numRowsAffected();
    }

    query.prepare(QStringLiteral(
        "DELETE FROM subscription_tool_usage WHERE timestamp < ?"
    ));
    query.addBindValue(cutoffStr);
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune tool usage:" << query.lastError().text();
    } else {
        totalDeleted += query.numRowsAffected();
    }

    m_db.commit();

    // Only vacuum if a meaningful number of rows were deleted
    if (totalDeleted > 100) {
        QSqlQuery vacuum(m_db);
        vacuum.exec(QStringLiteral("PRAGMA incremental_vacuum"));
    }
}

qint64 UsageDatabase::databaseSize() const
{
    if (!m_initialized)
        return 0;

    QFileInfo fi(m_db.databaseName());
    return fi.size();
}

QVariantMap UsageDatabase::getYearlyActivity(int mode) const
{
    QVariantMap result;
    QVariantList days;
    double maxIntensity = 0.0;

    if (!m_initialized) {
        result["maxIntensity"] = 0.0;
        result["days"] = days;
        return result;
    }

    QSqlQuery query(m_db);
    // Aggregate by date. We take the last 365 days.
    // Mode 0: daily_cost (financial intensity)
    // Mode 1: input_tokens + output_tokens (volume intensity)
    QString valueExpr = (mode == 0) ? QStringLiteral("SUM(daily_cost)") : QStringLiteral("SUM(input_tokens + output_tokens)");

    query.prepare(QStringLiteral(
        "SELECT date(timestamp) as day, %1 as value "
        "FROM usage_snapshots "
        "WHERE timestamp >= date('now', '-365 days') "
        "GROUP BY day "
        "ORDER BY day ASC"
    ).arg(valueExpr));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getYearlyActivity query failed:" << query.lastError().text();
        result["maxIntensity"] = 0.0;
        result["days"] = days;
        return result;
    }

    while (query.next()) {
        QVariantMap day;
        day[QStringLiteral("date")] = query.value(0).toString();
        double val = query.value(1).toDouble();
        day[QStringLiteral("value")] = val;
        days.append(day);

        if (val > maxIntensity) {
            maxIntensity = val;
        }
    }

    result[QStringLiteral("maxIntensity")] = maxIntensity;
    result[QStringLiteral("days")] = days;
    return result;
}

QVariantList UsageDatabase::getEfficiencySeries(int daysCount) const
{
    QVariantList series;

    if (!m_initialized)
        return series;

    QSqlQuery query(m_db);
    // Efficiency = Output Tokens / Input Tokens.
    // We aggregate by day and use CASE to avoid division by zero.
    query.prepare(QStringLiteral(
        "SELECT date(timestamp) as day, "
        "SUM(input_tokens) as total_in, "
        "SUM(output_tokens) as total_out "
        "FROM usage_snapshots "
        "WHERE timestamp >= date('now', '-%1 days') "
        "GROUP BY day "
        "ORDER BY day ASC"
    ).arg(daysCount));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getEfficiencySeries query failed:" << query.lastError().text();
        return series;
    }

    while (query.next()) {
        QVariantMap entry;
        entry[QStringLiteral("date")] = query.value(0).toString();
        
        double input = query.value(1).toDouble();
        double output = query.value(2).toDouble();
        
        double ratio = 0.0;
        if (input > 0) {
            ratio = output / input;
        } else if (output > 0) {
            // If we have output but no input (unlikely but possible in some APIs),
            // we could cap it or return a high value. Let's cap at 10x for safety.
            ratio = 10.0;
        }

        entry[QStringLiteral("value")] = ratio;
        series.append(entry);
    }

    return series;
}
