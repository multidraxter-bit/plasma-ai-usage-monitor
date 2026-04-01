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
#include <algorithm>

std::atomic<int> UsageDatabase::s_instanceCounter{0};

namespace {
constexpr int MAX_SERIES_POINTS = 240;

struct BucketAggregate {
    double sum = 0.0;
    int count = 0;
    QDateTime bucketStart;
};

struct DailyOverviewRow {
    QString day;
    double totalCost = 0.0;
    double totalTokens = 0.0;
    int providerCount = 0;
};

double percentChange(double previous, double current)
{
    if (qFuzzyIsNull(previous)) {
        return 0.0;
    }
    return ((current - previous) / std::abs(previous)) * 100.0;
}

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
        "  model TEXT DEFAULT '',"
        "  input_tokens INTEGER DEFAULT 0,"
        "  output_tokens INTEGER DEFAULT 0,"
        "  request_count INTEGER DEFAULT 0,"
        "  cost REAL DEFAULT 0.0,"
        "  is_estimated_cost INTEGER DEFAULT 0,"
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

    // Migrate older databases created before analyst metadata existed.
    ensureColumnExists(QStringLiteral("usage_snapshots"),
                       QStringLiteral("model"),
                       QStringLiteral("TEXT DEFAULT ''"));
    ensureColumnExists(QStringLiteral("usage_snapshots"),
                       QStringLiteral("is_estimated_cost"),
                       QStringLiteral("INTEGER DEFAULT 0"));
}

void UsageDatabase::ensureColumnExists(const QString &table,
                                       const QString &column,
                                       const QString &definition)
{
    QSqlQuery pragma(m_db);
    if (!pragma.exec(QStringLiteral("PRAGMA table_info(%1)").arg(table))) {
        qWarning() << "UsageDatabase: Failed to inspect table schema for" << table
                   << ":" << pragma.lastError().text();
        return;
    }

    while (pragma.next()) {
        if (pragma.value(1).toString() == column) {
            return;
        }
    }

    QSqlQuery alter(m_db);
    const QString sql = QStringLiteral("ALTER TABLE %1 ADD COLUMN %2 %3")
        .arg(table, column, definition);
    if (!alter.exec(sql)) {
        qWarning() << "UsageDatabase: Failed to add column" << column << "to" << table
                   << ":" << alter.lastError().text();
    }
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
                                    int rateLimitTokensRemaining,
                                    const QString &model,
                                    bool isEstimatedCost)
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
        "(provider, model, input_tokens, output_tokens, request_count, cost, is_estimated_cost, "
        "daily_cost, monthly_cost, rl_requests, rl_requests_remaining, rl_tokens, rl_tokens_remaining) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    ));
    query.addBindValue(provider);
    query.addBindValue(model.trimmed());
    query.addBindValue(inputTokens);
    query.addBindValue(outputTokens);
    query.addBindValue(requestCount);
    query.addBindValue(cost);
    query.addBindValue(isEstimatedCost ? 1 : 0);
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
        "SELECT timestamp, model, input_tokens, output_tokens, request_count, cost, "
        "is_estimated_cost, daily_cost, monthly_cost, rl_requests, rl_requests_remaining, "
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
        row[QStringLiteral("model")] = query.value(1).toString();
        row[QStringLiteral("inputTokens")] = query.value(2).toLongLong();
        row[QStringLiteral("outputTokens")] = query.value(3).toLongLong();
        row[QStringLiteral("requestCount")] = query.value(4).toInt();
        row[QStringLiteral("cost")] = query.value(5).toDouble();
        row[QStringLiteral("isEstimatedCost")] = query.value(6).toBool();
        row[QStringLiteral("dailyCost")] = query.value(7).toDouble();
        row[QStringLiteral("monthlyCost")] = query.value(8).toDouble();
        row[QStringLiteral("rlRequests")] = query.value(9).toInt();
        row[QStringLiteral("rlRequestsRemaining")] = query.value(10).toInt();
        row[QStringLiteral("rlTokens")] = query.value(11).toInt();
        row[QStringLiteral("rlTokensRemaining")] = query.value(12).toInt();
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
    csv += QStringLiteral("timestamp,provider,model,input_tokens,output_tokens,request_count,"
                          "cost,is_estimated_cost,daily_cost,monthly_cost,rl_requests,rl_requests_remaining,"
                          "rl_tokens,rl_tokens_remaining\n");

    QVariantList snapshots = getSnapshots(provider, from, to);
    for (const QVariant &snap : snapshots) {
        QVariantMap row = snap.toMap();
        const QStringList fields = {
            row[QStringLiteral("timestamp")].toString(),
            provider,
            row[QStringLiteral("model")].toString(),
            QString::number(row[QStringLiteral("inputTokens")].toLongLong()),
            QString::number(row[QStringLiteral("outputTokens")].toLongLong()),
            QString::number(row[QStringLiteral("requestCount")].toInt()),
            QString::number(row[QStringLiteral("cost")].toDouble(), 'f', 6),
            row[QStringLiteral("isEstimatedCost")].toBool() ? QStringLiteral("1") : QStringLiteral("0"),
            QString::number(row[QStringLiteral("dailyCost")].toDouble(), 'f', 6),
            QString::number(row[QStringLiteral("monthlyCost")].toDouble(), 'f', 6),
            QString::number(row[QStringLiteral("rlRequests")].toInt()),
            QString::number(row[QStringLiteral("rlRequestsRemaining")].toInt()),
            QString::number(row[QStringLiteral("rlTokens")].toInt()),
            QString::number(row[QStringLiteral("rlTokensRemaining")].toInt())
        };
        csv += fields.join(QLatin1Char(',')) + QLatin1Char('\n');
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
    QString valueExpr = (mode == 0)
        ? QStringLiteral("SUM(provider_daily_cost)")
        : QStringLiteral("SUM(provider_tokens)");

    query.prepare(QStringLiteral(
        "SELECT day, %1 as value "
        "FROM ("
        "  SELECT date(timestamp) as day, provider, "
        "         MAX(daily_cost) as provider_daily_cost, "
        "         MAX(input_tokens + output_tokens) as provider_tokens "
        "  FROM usage_snapshots "
        "  WHERE timestamp >= date('now', '-365 days') "
        "  GROUP BY day, provider"
        ") "
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
    query.prepare(QStringLiteral(
        "SELECT day, "
        "SUM(provider_input) as total_in, "
        "SUM(provider_output) as total_out "
        "FROM ("
        "  SELECT date(timestamp) as day, provider, "
        "         MAX(input_tokens) as provider_input, "
        "         MAX(output_tokens) as provider_output "
        "  FROM usage_snapshots "
        "  WHERE timestamp >= date('now', '-%1 days') "
        "  GROUP BY day, provider"
        ") "
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

QVariantMap UsageDatabase::getAnalystOverview(int days) const
{
    QVariantMap result;
    result[QStringLiteral("averageDailyCost")] = 0.0;
    result[QStringLiteral("currentDailyCost")] = 0.0;
    result[QStringLiteral("weekOverWeekPercent")] = 0.0;
    result[QStringLiteral("volatilityPercent")] = 0.0;
    result[QStringLiteral("anomalyCount")] = 0;
    result[QStringLiteral("anomalies")] = QVariantList{};
    result[QStringLiteral("topDrivers")] = QVariantList{};
    result[QStringLiteral("topModels")] = QVariantList{};
    result[QStringLiteral("days")] = QVariantList{};

    if (!m_initialized) {
        return result;
    }

    const int clampedDays = qBound(7, days, 365);
    QList<DailyOverviewRow> dailyRows;

    QSqlQuery dayQuery(m_db);
    dayQuery.prepare(QStringLiteral(
        "SELECT day, SUM(provider_daily_cost) as total_cost, "
        "       SUM(provider_tokens) as total_tokens, COUNT(*) as provider_count "
        "FROM ("
        "  SELECT date(timestamp) as day, provider, "
        "         MAX(daily_cost) as provider_daily_cost, "
        "         MAX(input_tokens + output_tokens) as provider_tokens "
        "  FROM usage_snapshots "
        "  WHERE timestamp >= date('now', '-%1 days') "
        "  GROUP BY day, provider"
        ") "
        "GROUP BY day "
        "ORDER BY day ASC"
    ).arg(clampedDays));

    if (!dayQuery.exec()) {
        qWarning() << "UsageDatabase: getAnalystOverview daily query failed:"
                   << dayQuery.lastError().text();
        return result;
    }

    QVariantList dayMaps;
    while (dayQuery.next()) {
        DailyOverviewRow row;
        row.day = dayQuery.value(0).toString();
        row.totalCost = dayQuery.value(1).toDouble();
        row.totalTokens = dayQuery.value(2).toDouble();
        row.providerCount = dayQuery.value(3).toInt();
        dailyRows.append(row);

        QVariantMap map;
        map[QStringLiteral("date")] = row.day;
        map[QStringLiteral("totalCost")] = row.totalCost;
        map[QStringLiteral("totalTokens")] = row.totalTokens;
        map[QStringLiteral("providerCount")] = row.providerCount;
        dayMaps.append(map);
    }
    result[QStringLiteral("days")] = dayMaps;

    if (!dailyRows.isEmpty()) {
        double sum = 0.0;
        QList<double> costs;
        costs.reserve(dailyRows.size());
        for (const DailyOverviewRow &row : std::as_const(dailyRows)) {
            sum += row.totalCost;
            costs.append(row.totalCost);
        }

        const double averageDailyCost = sum / static_cast<double>(dailyRows.size());
        const double currentDailyCost = dailyRows.last().totalCost;
        result[QStringLiteral("averageDailyCost")] = averageDailyCost;
        result[QStringLiteral("currentDailyCost")] = currentDailyCost;

        double variance = 0.0;
        if (!qFuzzyIsNull(averageDailyCost)) {
            for (double cost : std::as_const(costs)) {
                const double delta = cost - averageDailyCost;
                variance += delta * delta;
            }
            variance /= static_cast<double>(costs.size());
            result[QStringLiteral("volatilityPercent")] =
                (std::sqrt(variance) / averageDailyCost) * 100.0;
        }

        if (dailyRows.size() >= 14) {
            double previousWeek = 0.0;
            double currentWeek = 0.0;
            const int split = dailyRows.size() - 7;
            for (int i = std::max(0, split - 7); i < split; ++i) {
                previousWeek += dailyRows.at(i).totalCost;
            }
            for (int i = split; i < dailyRows.size(); ++i) {
                currentWeek += dailyRows.at(i).totalCost;
            }
            result[QStringLiteral("weekOverWeekPercent")] =
                percentChange(previousWeek, currentWeek);
        }

        QVariantList anomalies;
        const double baseline = averageDailyCost;
        for (const DailyOverviewRow &row : std::as_const(dailyRows)) {
            if (baseline <= 0.0) {
                continue;
            }
            if (row.totalCost < baseline * 1.75 || row.totalCost < baseline + 0.25) {
                continue;
            }

            QVariantMap anomaly;
            anomaly[QStringLiteral("date")] = row.day;
            anomaly[QStringLiteral("value")] = row.totalCost;
            anomaly[QStringLiteral("deltaPercent")] = percentChange(baseline, row.totalCost);
            anomalies.append(anomaly);
        }
        result[QStringLiteral("anomalies")] = anomalies;
        result[QStringLiteral("anomalyCount")] = anomalies.size();
    }

    QSqlQuery latestQuery(m_db);
    latestQuery.prepare(QStringLiteral(
        "SELECT provider, model, cost, is_estimated_cost, daily_cost, monthly_cost "
        "FROM usage_snapshots "
        "WHERE id IN ("
        "  SELECT MAX(id) FROM usage_snapshots "
        "  WHERE timestamp >= date('now', '-%1 days') "
        "  GROUP BY provider"
        ")"
    ).arg(clampedDays));

    if (!latestQuery.exec()) {
        qWarning() << "UsageDatabase: getAnalystOverview driver query failed:"
                   << latestQuery.lastError().text();
        return result;
    }

    struct DriverRow {
        QString provider;
        QString model;
        double value = 0.0;
        bool estimated = false;
    };

    QList<DriverRow> drivers;
    QMap<QString, double> modelTotals;
    QMap<QString, bool> modelEstimated;
    const int daysInMonth = QDate::currentDate().daysInMonth();

    while (latestQuery.next()) {
        DriverRow row;
        row.provider = latestQuery.value(0).toString();
        row.model = latestQuery.value(1).toString().trimmed();
        const double cost = latestQuery.value(2).toDouble();
        row.estimated = latestQuery.value(3).toBool();
        const double dailyCost = latestQuery.value(4).toDouble();
        const double monthlyCost = latestQuery.value(5).toDouble();

        row.value = monthlyCost > 0.0 ? monthlyCost
            : (dailyCost > 0.0 ? dailyCost * static_cast<double>(daysInMonth) : cost);
        if (row.value <= 0.0) {
            continue;
        }

        if (row.model.isEmpty()) {
            row.model = row.provider;
        }

        drivers.append(row);
        modelTotals[row.model] += row.value;
        modelEstimated[row.model] = modelEstimated.value(row.model, false) || row.estimated;
    }

    std::sort(drivers.begin(), drivers.end(), [](const DriverRow &lhs, const DriverRow &rhs) {
        return lhs.value > rhs.value;
    });

    QVariantList topDrivers;
    const int driverLimit = std::min(5, static_cast<int>(drivers.size()));
    for (int i = 0; i < driverLimit; ++i) {
        const DriverRow &driver = drivers.at(i);
        QVariantMap map;
        map[QStringLiteral("provider")] = driver.provider;
        map[QStringLiteral("model")] = driver.model;
        map[QStringLiteral("value")] = driver.value;
        map[QStringLiteral("estimated")] = driver.estimated;
        topDrivers.append(map);
    }
    result[QStringLiteral("topDrivers")] = topDrivers;

    struct ModelRow {
        QString model;
        double value = 0.0;
        bool estimated = false;
    };

    QList<ModelRow> models;
    for (auto it = modelTotals.constBegin(); it != modelTotals.constEnd(); ++it) {
        ModelRow row;
        row.model = it.key();
        row.value = it.value();
        row.estimated = modelEstimated.value(it.key(), false);
        models.append(row);
    }

    std::sort(models.begin(), models.end(), [](const ModelRow &lhs, const ModelRow &rhs) {
        return lhs.value > rhs.value;
    });

    QVariantList topModels;
    const int modelLimit = std::min(5, static_cast<int>(models.size()));
    for (int i = 0; i < modelLimit; ++i) {
        const ModelRow &model = models.at(i);
        QVariantMap map;
        map[QStringLiteral("model")] = model.model;
        map[QStringLiteral("value")] = model.value;
        map[QStringLiteral("estimated")] = model.estimated;
        topModels.append(map);
    }
    result[QStringLiteral("topModels")] = topModels;

    return result;
}
