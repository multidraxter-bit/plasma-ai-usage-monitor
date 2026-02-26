#include <QtTest>
#include <QSignalSpy>

#include "providerbackend.h"

/**
 * Minimal concrete subclass for testing ProviderBackend's non-virtual logic.
 * Exposes protected methods via public wrappers.
 */
class TestProvider : public ProviderBackend
{
    Q_OBJECT
public:
    explicit TestProvider(QObject *parent = nullptr)
        : ProviderBackend(parent)
    {}

    QString name() const override { return QStringLiteral("TestProvider"); }
    QString iconName() const override { return QStringLiteral("test-icon"); }
    void refresh() override { /* no-op */ }

    // Public wrappers for protected methods
    using ProviderBackend::setConnected;
    using ProviderBackend::setLoading;
    using ProviderBackend::setError;
    using ProviderBackend::clearError;
    using ProviderBackend::setInputTokens;
    using ProviderBackend::setOutputTokens;
    using ProviderBackend::setRequestCount;
    using ProviderBackend::setCost;
    using ProviderBackend::setDailyCost;
    using ProviderBackend::setMonthlyCost;
    using ProviderBackend::effectiveBaseUrl;
    using ProviderBackend::beginRefresh;
    using ProviderBackend::isCurrentGeneration;
    using ProviderBackend::registerModelPricing;
    using ProviderBackend::updateEstimatedCost;
    using ProviderBackend::checkBudgetLimits;
    using ProviderBackend::isRetryableStatus;
};

class ProviderBackendTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testProviderKeyEnumConversionAzure();
    void testProviderKeyEnumConversionAzureAliases();
    void testProviderConfigFallbackUnknownDeterministic();
    void testExistingProviderMappingsUnchanged();
    void testBudgetWarningSignal();
    void testBudgetExceededSignal();
    void testBudgetDedupFlags();
    void testMonthlyBudgetSignals();
    void testCostEstimation();
    void testCostEstimationPrefixMatch();
    void testGenerationCounter();
    void testDisconnectReconnectSignals();
    void testNoSignalOnSameState();
    void testReconnectRequiresPriorConnection();
    void testErrorCountAndConsecutiveErrors();
    void testClearError();
    void testIsRetryableStatus();
    void testEffectiveBaseUrl();
    void testEffectiveBaseUrlTrailingSlash();
    void testTotalTokens();
};

void ProviderBackendTest::testBudgetWarningSignal()
{
    TestProvider p;
    p.setDailyBudget(10.0);
    p.setBudgetWarningPercent(80);

    QSignalSpy warningSpy(&p, &ProviderBackend::budgetWarning);

    // Set daily cost to 80% of budget — should trigger warning
    p.setDailyCost(8.0);
    QCOMPARE(warningSpy.count(), 1);

    QList<QVariant> args = warningSpy.takeFirst();
    QCOMPARE(args.at(0).toString(), QStringLiteral("TestProvider"));
    QCOMPARE(args.at(1).toString(), QStringLiteral("daily"));
    QVERIFY(qAbs(args.at(2).toDouble() - 8.0) < 0.01);
    QVERIFY(qAbs(args.at(3).toDouble() - 10.0) < 0.01);
}

void ProviderBackendTest::testProviderKeyEnumConversionAzure()
{
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("azure")),
             ProviderBackend::ProviderId::AzureOpenAI);
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("azure-openai")),
             ProviderBackend::ProviderId::AzureOpenAI);
    QCOMPARE(ProviderBackend::providerKeyFromId(ProviderBackend::ProviderId::AzureOpenAI),
             QStringLiteral("azure-openai"));

    const ProviderBackend::ProviderConfig azureConfig = ProviderBackend::makeProviderConfig(
        QStringLiteral("azure-openai"),
        QStringLiteral("https://example.openai.azure.com"),
        QStringLiteral("gpt-4o"),
        QStringLiteral("my-deployment"),
        QStringLiteral("secret"));

    QCOMPARE(azureConfig.providerId, ProviderBackend::ProviderId::AzureOpenAI);
    QCOMPARE(azureConfig.providerKey, QStringLiteral("azure-openai"));
    QCOMPARE(azureConfig.authKeySlot, QStringLiteral("azure_openai_api_key"));
}

void ProviderBackendTest::testProviderKeyEnumConversionAzureAliases()
{
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("AZURE_OPENAI")),
             ProviderBackend::ProviderId::AzureOpenAI);
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral(" Azure ")),
             ProviderBackend::ProviderId::AzureOpenAI);
    QCOMPARE(ProviderBackend::defaultAuthKeySlotForProvider(ProviderBackend::ProviderId::AzureOpenAI),
             QStringLiteral("azure_openai_api_key"));
}

void ProviderBackendTest::testProviderConfigFallbackUnknownDeterministic()
{
    const ProviderBackend::ProviderConfig unknownConfig = ProviderBackend::makeProviderConfig(
        QStringLiteral("some-future-provider"),
        QStringLiteral("https://example.invalid"),
        QStringLiteral("model-x"),
        QStringLiteral("deployment-x"),
        QStringLiteral("secret"));

    QCOMPARE(unknownConfig.providerId, ProviderBackend::ProviderId::Unknown);
    QCOMPARE(unknownConfig.providerKey, QStringLiteral("unknown"));
    QCOMPARE(unknownConfig.authKeySlot, QStringLiteral("unknown_api_key"));

    const ProviderBackend::NormalizedUsageCost normalized =
        ProviderBackend::normalizeUsageCost(ProviderBackend::ProviderId::Unknown, QJsonObject{});
    QVERIFY(!normalized.parsed);
    QCOMPARE(normalized.inputTokens, 0);
    QCOMPARE(normalized.outputTokens, 0);
    QCOMPARE(normalized.requestCount, 0);
    QCOMPARE(normalized.cost, 0.0);
}

void ProviderBackendTest::testExistingProviderMappingsUnchanged()
{
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("openai")),
             ProviderBackend::ProviderId::OpenAI);
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("google")),
             ProviderBackend::ProviderId::Google);
    QCOMPARE(ProviderBackend::providerIdFromKey(QStringLiteral("xai")),
             ProviderBackend::ProviderId::XAI);
    QCOMPARE(ProviderBackend::providerKeyFromId(ProviderBackend::ProviderId::OpenAI),
             QStringLiteral("openai"));
    QCOMPARE(ProviderBackend::providerKeyFromId(ProviderBackend::ProviderId::Google),
             QStringLiteral("google"));
    QCOMPARE(ProviderBackend::providerKeyFromId(ProviderBackend::ProviderId::XAI),
             QStringLiteral("xai"));
}

void ProviderBackendTest::testBudgetExceededSignal()
{
    TestProvider p;
    p.setDailyBudget(10.0);

    QSignalSpy exceededSpy(&p, &ProviderBackend::budgetExceeded);

    // Set daily cost at 100% — should trigger exceeded
    p.setDailyCost(10.0);
    QCOMPARE(exceededSpy.count(), 1);

    QList<QVariant> args = exceededSpy.takeFirst();
    QCOMPARE(args.at(1).toString(), QStringLiteral("daily"));
}

void ProviderBackendTest::testBudgetDedupFlags()
{
    TestProvider p;
    p.setDailyBudget(10.0);

    QSignalSpy exceededSpy(&p, &ProviderBackend::budgetExceeded);

    // Exceed budget twice — should only emit once (dedup)
    p.setDailyCost(10.0);
    QCOMPARE(exceededSpy.count(), 1);
    p.setDailyCost(11.0);
    QCOMPARE(exceededSpy.count(), 1); // still 1, deduped

    // Reset by dropping below warning threshold
    p.setDailyCost(1.0);
    p.setDailyCost(10.0);
    QCOMPARE(exceededSpy.count(), 2); // now emits again
}

void ProviderBackendTest::testMonthlyBudgetSignals()
{
    TestProvider p;
    p.setMonthlyBudget(100.0);
    p.setBudgetWarningPercent(80);

    QSignalSpy warningSpy(&p, &ProviderBackend::budgetWarning);
    QSignalSpy exceededSpy(&p, &ProviderBackend::budgetExceeded);

    p.setMonthlyCost(80.0);
    QCOMPARE(warningSpy.count(), 1);
    QCOMPARE(warningSpy.first().at(1).toString(), QStringLiteral("monthly"));

    p.setMonthlyCost(100.0);
    QCOMPARE(exceededSpy.count(), 1);
    QCOMPARE(exceededSpy.first().at(1).toString(), QStringLiteral("monthly"));
}

void ProviderBackendTest::testCostEstimation()
{
    TestProvider p;
    // Register model: $3/M input, $15/M output
    p.registerModelPricing(QStringLiteral("test-model"), 3.0, 15.0);

    p.setInputTokens(1000000);  // 1M input tokens
    p.setOutputTokens(500000);  // 0.5M output tokens

    p.updateEstimatedCost(QStringLiteral("test-model"));

    // Expected: (1M/1M)*3 + (0.5M/1M)*15 = 3.0 + 7.5 = 10.5
    QVERIFY(qAbs(p.cost() - 10.5) < 0.01);
    QVERIFY(p.isEstimatedCost());
}

void ProviderBackendTest::testCostEstimationPrefixMatch()
{
    TestProvider p;
    p.registerModelPricing(QStringLiteral("mistral-large"), 2.0, 6.0);

    p.setInputTokens(2000000);
    p.setOutputTokens(1000000);

    // Use a model name that starts with the registered prefix
    p.updateEstimatedCost(QStringLiteral("mistral-large-latest"));

    // Expected: (2M/1M)*2 + (1M/1M)*6 = 4.0 + 6.0 = 10.0
    QVERIFY(qAbs(p.cost() - 10.0) < 0.01);
    QVERIFY(p.isEstimatedCost());
}

void ProviderBackendTest::testGenerationCounter()
{
    TestProvider p;
    QCOMPARE(p.currentGeneration(), 0);

    int gen0 = p.currentGeneration();
    p.beginRefresh();
    QCOMPARE(p.currentGeneration(), 1);
    QVERIFY(!p.isCurrentGeneration(gen0));
    QVERIFY(p.isCurrentGeneration(1));

    p.beginRefresh();
    QCOMPARE(p.currentGeneration(), 2);
    QVERIFY(!p.isCurrentGeneration(1));
}

void ProviderBackendTest::testDisconnectReconnectSignals()
{
    TestProvider p;
    QSignalSpy disconnectSpy(&p, &ProviderBackend::providerDisconnected);
    QSignalSpy reconnectSpy(&p, &ProviderBackend::providerReconnected);

    // First connection — no disconnect/reconnect signals
    p.setConnected(true);
    QCOMPARE(disconnectSpy.count(), 0);
    QCOMPARE(reconnectSpy.count(), 0);

    // Disconnect
    p.setConnected(false);
    QCOMPARE(disconnectSpy.count(), 1);
    QCOMPARE(disconnectSpy.first().at(0).toString(), QStringLiteral("TestProvider"));

    // Reconnect
    p.setConnected(true);
    QCOMPARE(reconnectSpy.count(), 1);
    QCOMPARE(reconnectSpy.first().at(0).toString(), QStringLiteral("TestProvider"));
}

void ProviderBackendTest::testNoSignalOnSameState()
{
    TestProvider p;
    QSignalSpy connSpy(&p, &ProviderBackend::connectedChanged);

    p.setConnected(true);
    QCOMPARE(connSpy.count(), 1);

    // Setting same state again — no signal
    p.setConnected(true);
    QCOMPARE(connSpy.count(), 1);
}

void ProviderBackendTest::testReconnectRequiresPriorConnection()
{
    TestProvider p;
    QSignalSpy reconnectSpy(&p, &ProviderBackend::providerReconnected);

    // Never connected → set to false → set to true
    // Should NOT emit reconnected because it was never connected before
    p.setConnected(false); // no change, starts false
    p.setConnected(true);
    QCOMPARE(reconnectSpy.count(), 0);
}

void ProviderBackendTest::testErrorCountAndConsecutiveErrors()
{
    TestProvider p;
    QCOMPARE(p.errorCount(), 0);
    QCOMPARE(p.consecutiveErrors(), 0);

    p.setError(QStringLiteral("Error 1"));
    QCOMPARE(p.errorCount(), 1);
    QCOMPARE(p.consecutiveErrors(), 1);
    QCOMPARE(p.errorString(), QStringLiteral("Error 1"));

    p.setError(QStringLiteral("Error 2"));
    QCOMPARE(p.errorCount(), 2);
    QCOMPARE(p.consecutiveErrors(), 2);
}

void ProviderBackendTest::testClearError()
{
    TestProvider p;
    p.setError(QStringLiteral("Some error"));
    QCOMPARE(p.consecutiveErrors(), 1);

    QSignalSpy errorSpy(&p, &ProviderBackend::errorChanged);
    p.clearError();

    QVERIFY(p.errorString().isEmpty());
    QCOMPARE(p.consecutiveErrors(), 0);
    QCOMPARE(p.errorCount(), 1); // total count persists
    QCOMPARE(errorSpy.count(), 1);

    // Clearing already clear error — no signal
    p.clearError();
    QCOMPARE(errorSpy.count(), 1);
}

void ProviderBackendTest::testIsRetryableStatus()
{
    QVERIFY(TestProvider::isRetryableStatus(429));
    QVERIFY(TestProvider::isRetryableStatus(500));
    QVERIFY(TestProvider::isRetryableStatus(502));
    QVERIFY(TestProvider::isRetryableStatus(503));

    QVERIFY(!TestProvider::isRetryableStatus(200));
    QVERIFY(!TestProvider::isRetryableStatus(400));
    QVERIFY(!TestProvider::isRetryableStatus(401));
    QVERIFY(!TestProvider::isRetryableStatus(403));
    QVERIFY(!TestProvider::isRetryableStatus(404));
    QVERIFY(!TestProvider::isRetryableStatus(504));
}

void ProviderBackendTest::testEffectiveBaseUrl()
{
    TestProvider p;

    // No custom URL — should return default
    QCOMPARE(p.effectiveBaseUrl("https://api.example.com"), QStringLiteral("https://api.example.com"));

    // Set custom URL — should override
    p.setCustomBaseUrl(QStringLiteral("https://proxy.example.com"));
    QCOMPARE(p.effectiveBaseUrl("https://api.example.com"), QStringLiteral("https://proxy.example.com"));

    // Clear custom URL — back to default
    p.setCustomBaseUrl(QString());
    QCOMPARE(p.effectiveBaseUrl("https://api.example.com"), QStringLiteral("https://api.example.com"));
}

void ProviderBackendTest::testEffectiveBaseUrlTrailingSlash()
{
    TestProvider p;
    p.setCustomBaseUrl(QStringLiteral("https://proxy.example.com///"));
    QCOMPARE(p.effectiveBaseUrl("https://api.example.com"), QStringLiteral("https://proxy.example.com"));
}

void ProviderBackendTest::testTotalTokens()
{
    TestProvider p;
    p.setInputTokens(100);
    p.setOutputTokens(50);
    QCOMPARE(p.totalTokens(), 150);
}

QTEST_MAIN(ProviderBackendTest)
#include "test_providerbackend.moc"
