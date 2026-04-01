#include <QtTest>
#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QUuid>
#include <QDateTime>
#include <QDebug>

#include "usagedatabase.h"

namespace {
QString dbFilePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/plasma-ai-usage-monitor/usage_history.db");
}

bool updateSnapshotData(const QString &provider, double dailyCost, qint64 input, qint64 output, const QString &timestamp)
{
    const QString connName = QStringLiteral("analyst_test_conn_%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
        db.setDatabaseName(dbFilePath());
        if (db.open()) {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "UPDATE usage_snapshots SET timestamp = ? "
                "WHERE provider = ? AND daily_cost = ? AND input_tokens = ? AND output_tokens = ?"
            ));
            query.addBindValue(timestamp);
            query.addBindValue(provider);
            query.addBindValue(dailyCost);
            query.addBindValue(input);
            query.addBindValue(output);
            ok = query.exec() && query.numRowsAffected() > 0;
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connName);
    return ok;
}
} // namespace

class UsageDatabaseAnalystTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testYearlyActivity();
    void testEfficiencySeries();
};

void UsageDatabaseAnalystTest::testYearlyActivity()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    qputenv("XDG_DATA_HOME", tmp.path().toUtf8());

    UsageDatabase db;
    db.init();

    QDateTime now = QDateTime::currentDateTimeUtc();
    QString today = now.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    QString yesterday = now.addDays(-1).toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));
    QString longAgo = now.addDays(-400).toString(QStringLiteral("yyyy-MM-dd HH:mm:ss"));

    // Seed data
    db.recordSnapshot("openai", 100, 200, 1, 0.01, 1.5, 30.0, 0, 0, 0, 0); // Today
    QVERIFY(updateSnapshotData("openai", 1.5, 100, 200, today));

    db.recordSnapshot("anthropic", 50, 150, 1, 0.02, 2.5, 40.0, 0, 0, 0, 0); // Yesterday
    QVERIFY(updateSnapshotData("anthropic", 2.5, 50, 150, yesterday));

    db.recordSnapshot("openai", 1000, 2000, 1, 0.1, 10.0, 100.0, 0, 0, 0, 0); // Too old
    QVERIFY(updateSnapshotData("openai", 10.0, 1000, 2000, longAgo));

    // Test Mode 0: Cost
    QVariantMap costActivity = db.getYearlyActivity(0);
    QVERIFY(costActivity.contains("maxIntensity"));
    QVERIFY(costActivity.contains("days"));
    QVariantList costDays = costActivity["days"].toList();
    
    // We expect daily_cost to be aggregated per day.
    // Today: 1.5
    // Yesterday: 2.5
    // Total maxIntensity should be 2.5 (if multiple snapshots per day, they sum, but here 1 per day)
    QCOMPARE(costActivity["maxIntensity"].toDouble(), 2.5);
    
    bool foundToday = false;
    bool foundYesterday = false;
    for (const QVariant &v : costDays) {
        QVariantMap day = v.toMap();
        if (day["date"].toString() == now.toString("yyyy-MM-dd")) {
            QCOMPARE(day["value"].toDouble(), 1.5);
            foundToday = true;
        } else if (day["date"].toString() == now.addDays(-1).toString("yyyy-MM-dd")) {
            QCOMPARE(day["value"].toDouble(), 2.5);
            foundYesterday = true;
        }
    }
    QVERIFY(foundToday);
    QVERIFY(foundYesterday);

    // Test Mode 1: Tokens
    QVariantMap tokenActivity = db.getYearlyActivity(1);
    // Today: 100+200 = 300
    // Yesterday: 50+150 = 200
    QCOMPARE(tokenActivity["maxIntensity"].toDouble(), 300.0);
}

void UsageDatabaseAnalystTest::testEfficiencySeries()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    qputenv("XDG_DATA_HOME", tmp.path().toUtf8());

    UsageDatabase db;
    db.init();

    QDateTime now = QDateTime::currentDateTimeUtc();
    
    // Day 0: 100 in, 200 out -> efficiency 2.0
    db.recordSnapshot("p1", 100, 200, 1, 0, 0, 0, 0, 0, 0, 0);
    QVERIFY(updateSnapshotData("p1", 0, 100, 200, now.toString("yyyy-MM-dd HH:mm:ss")));

    // Day 1: 100 in, 50 out -> efficiency 0.5
    db.recordSnapshot("p1", 100, 50, 1, 0, 0, 0, 0, 0, 0, 0);
    QVERIFY(updateSnapshotData("p1", 0, 100, 50, now.addDays(-1).toString("yyyy-MM-dd HH:mm:ss")));

    // Day 2: 0 in, 0 out -> handle division by zero (should be 0 or skipped, let's say 0)
    db.recordSnapshot("p1", 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);
    QVERIFY(updateSnapshotData("p1", 0, 0, 0, now.addDays(-2).toString("yyyy-MM-dd HH:mm:ss")));

    QVariantList series = db.getEfficiencySeries(7);
    QCOMPARE(series.size(), 3); // 3 days with data

    // Check values (order might depend on implementation, usually ASC date or DESC date)
    // Let's assume we sort by date.
    
    QMap<QString, double> values;
    for (const QVariant &v : series) {
        QVariantMap m = v.toMap();
        values[m["date"].toString()] = m["value"].toDouble();
    }

    QCOMPARE(values[now.toString("yyyy-MM-dd")], 2.0);
    QCOMPARE(values[now.addDays(-1).toString("yyyy-MM-dd")], 0.5);
    QCOMPARE(values[now.addDays(-2).toString("yyyy-MM-dd")], 0.0);
}

QTEST_MAIN(UsageDatabaseAnalystTest)
#include "test_usagedatabase_analyst.moc"
