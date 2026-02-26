#include <QtTest>

#include <QHash>
#include <QSignalSpy>
#include <QHostAddress>
#include <QTcpServer>
#include <QTcpSocket>
#include <QUrl>

#include "anthropicprovider.h"
#include "cohereprovider.h"
#include "deepseekprovider.h"
#include "googleveoprovider.h"
#include "openaiprovider.h"
#include "openrouterprovider.h"
#include "togetherprovider.h"

class HttpStubServer : public QObject
{
    Q_OBJECT

public:
    struct Response {
        int status = 200;
        QByteArray body = "{}";
        QList<QPair<QByteArray, QByteArray>> headers;
    };

    explicit HttpStubServer(QObject *parent = nullptr)
        : QObject(parent)
    {
        connect(&m_server, &QTcpServer::newConnection, this, [this]() {
            while (m_server.hasPendingConnections()) {
                QTcpSocket *socket = m_server.nextPendingConnection();
                connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
                    m_buffers[socket] += socket->readAll();
                    if (!m_buffers[socket].contains("\r\n\r\n")) {
                        return;
                    }

                    const QList<QByteArray> lines = m_buffers[socket].split('\n');
                    if (lines.isEmpty()) {
                        socket->disconnectFromHost();
                        return;
                    }

                    const QList<QByteArray> firstLine = lines.first().trimmed().split(' ');
                    if (firstLine.size() < 2) {
                        socket->disconnectFromHost();
                        return;
                    }

                    const QString method = QString::fromUtf8(firstLine.at(0));
                    const QString rawTarget = QString::fromUtf8(firstLine.at(1));
                    const QString path = QUrl(rawTarget).path();

                    m_hitCount[path] = m_hitCount.value(path) + 1;

                    const QString key = method + QStringLiteral(" ") + path;
                    Response response = m_routes.value(key, Response{404, "{\"error\":\"not found\"}", {}});

                    QByteArray payload;
                    payload += "HTTP/1.1 " + QByteArray::number(response.status) + " OK\r\n";
                    payload += "Content-Type: application/json\r\n";
                    for (const auto &header : response.headers) {
                        payload += header.first + ": " + header.second + "\r\n";
                    }
                    payload += "Content-Length: " + QByteArray::number(response.body.size()) + "\r\n";
                    payload += "Connection: close\r\n\r\n";
                    payload += response.body;

                    socket->write(payload);
                    socket->disconnectFromHost();
                });

                connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
            }
        });
    }

    bool listen()
    {
        return m_server.listen(QHostAddress::LocalHost, 0);
    }

    QString baseUrl() const
    {
        return QStringLiteral("http://127.0.0.1:%1").arg(m_server.serverPort());
    }

    void setResponse(const QString &method,
                     const QString &path,
                     int status,
                     const QByteArray &body,
                     const QList<QPair<QByteArray, QByteArray>> &headers = {})
    {
        m_routes.insert(method + QStringLiteral(" ") + path, Response{status, body, headers});
    }

    int hitCount(const QString &path) const
    {
        return m_hitCount.value(path, 0);
    }

private:
    QTcpServer m_server;
    QHash<QTcpSocket *, QByteArray> m_buffers;
    QHash<QString, Response> m_routes;
    QHash<QString, int> m_hitCount;
};

class ProvidersMockedHttpTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void openAiSuccessAndHeaders();
    void openAiAuthError();
    void anthropicRateLimitHeaders();
    void deepSeekUsageAndBalance();
    void googleVeoKnownLimitsByTier();
    void googleVeoUsesHeaderLimitsWhenPresent();
    void googleVeoAuthError();
    void openRouterUsageAndCredits();
    void togetherAiUsageAndHeaders();
    void cohereUsageAndHeaders();
};

void ProvidersMockedHttpTest::openAiSuccessAndHeaders()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray usageBody = R"JSON({
        "data": [{
            "result": [{
                "input_tokens": 100,
                "output_tokens": 50,
                "num_model_requests": 7
            }]
        }]
    })JSON";

    const QByteArray costsBody = R"JSON({
        "data": [{
            "result": [{
                "amount": 250
            }]
        }]
    })JSON";

    server.setResponse(
        QStringLiteral("GET"),
        QStringLiteral("/v1/organization/usage/completions"),
        200,
        usageBody,
        {
            {"x-ratelimit-limit-requests", "100"},
            {"x-ratelimit-remaining-requests", "60"},
            {"x-ratelimit-limit-tokens", "2000"},
            {"x-ratelimit-remaining-tokens", "1500"},
            {"x-ratelimit-reset-requests", "30s"},
        });
    server.setResponse(QStringLiteral("GET"), QStringLiteral("/v1/organization/costs"), 200, costsBody);

    OpenAIProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1"));

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.inputTokens(), 100);
    QCOMPARE(provider.outputTokens(), 50);
    QCOMPARE(provider.requestCount(), 7);
    QCOMPARE(provider.rateLimitRequests(), 100);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 60);
    QCOMPARE(provider.rateLimitTokens(), 2000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 1500);
    QCOMPARE(provider.rateLimitResetTime(), QStringLiteral("30s"));
    QCOMPARE(provider.dailyCost(), 2.5);
    QCOMPARE(provider.monthlyCost(), 2.5);
    QVERIFY(provider.isConnected());

    QVERIFY(server.hitCount(QStringLiteral("/v1/organization/usage/completions")) >= 1);
    QVERIFY(server.hitCount(QStringLiteral("/v1/organization/costs")) >= 2);
}

void ProvidersMockedHttpTest::openAiAuthError()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray authError = R"JSON({"error":"unauthorized"})JSON";
    server.setResponse(QStringLiteral("GET"), QStringLiteral("/v1/organization/usage/completions"), 401, authError);
    server.setResponse(QStringLiteral("GET"), QStringLiteral("/v1/organization/costs"), 401, authError);

    OpenAIProvider provider;
    provider.setApiKey(QStringLiteral("bad-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1"));

    QSignalSpy errorSpy(&provider, &ProviderBackend::errorChanged);
    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);
    QVERIFY(errorSpy.count() >= 1);
    QVERIFY(provider.errorCount() >= 1);
    QVERIFY(!provider.errorString().isEmpty());
    QVERIFY(!provider.isConnected());
}

void ProvidersMockedHttpTest::anthropicRateLimitHeaders()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    server.setResponse(
        QStringLiteral("POST"),
        QStringLiteral("/v1/messages/count_tokens"),
        200,
        QByteArrayLiteral("{}"),
        {
            {"anthropic-ratelimit-requests-limit", "80"},
            {"anthropic-ratelimit-requests-remaining", "20"},
            {"anthropic-ratelimit-input-tokens-limit", "1000"},
            {"anthropic-ratelimit-input-tokens-remaining", "400"},
            {"anthropic-ratelimit-output-tokens-limit", "2000"},
            {"anthropic-ratelimit-output-tokens-remaining", "900"},
            {"anthropic-ratelimit-requests-reset", "2026-02-16T12:34:56Z"},
        });

    AnthropicProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1"));

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.rateLimitRequests(), 80);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 20);
    QCOMPARE(provider.rateLimitTokens(), 3000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 1300);
    QVERIFY(provider.isConnected());
    QVERIFY(!provider.rateLimitResetTime().isEmpty());
}

void ProvidersMockedHttpTest::deepSeekUsageAndBalance()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray usageBody = R"JSON({
        "usage": {
            "prompt_tokens": 11,
            "completion_tokens": 9
        }
    })JSON";

    const QByteArray balanceBody = R"JSON({
        "is_available": true,
        "balance_infos": [
            {"total_balance": "12.34"},
            {"total_balance": "0.66"}
        ]
    })JSON";

    server.setResponse(
        QStringLiteral("POST"),
        QStringLiteral("/chat/completions"),
        200,
        usageBody,
        {
            {"x-ratelimit-limit-requests", "120"},
            {"x-ratelimit-remaining-requests", "110"},
            {"x-ratelimit-limit-tokens", "6000"},
            {"x-ratelimit-remaining-tokens", "5800"},
            {"x-ratelimit-reset-requests", "20s"},
        });
    server.setResponse(QStringLiteral("GET"), QStringLiteral("/user/balance"), 200, balanceBody);

    DeepSeekProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl());

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.inputTokens(), 11);
    QCOMPARE(provider.outputTokens(), 9);
    QCOMPARE(provider.requestCount(), 1);
    QCOMPARE(provider.rateLimitRequests(), 120);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 110);
    QCOMPARE(provider.rateLimitTokens(), 6000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 5800);
    QCOMPARE(provider.balance(), 13.0);
    QVERIFY(provider.isConnected());
}

void ProvidersMockedHttpTest::googleVeoKnownLimitsByTier()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray modelInfoBody = R"JSON({
        "name": "models/veo-2",
        "displayName": "Veo 2"
    })JSON";

    server.setResponse(
        QStringLiteral("GET"),
        QStringLiteral("/v1beta/models/veo-2"),
        200,
        modelInfoBody);

    GoogleVeoProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1beta"));
    provider.setModel(QStringLiteral("veo-2"));
    provider.setTier(QStringLiteral("free"));

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.rateLimitRequests(), 10);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 10);
    QCOMPARE(provider.rateLimitTokens(), 0);
    QCOMPARE(provider.rateLimitTokensRemaining(), 0);
    QCOMPARE(provider.requestCount(), 1);
    QVERIFY(provider.isConnected());
}

void ProvidersMockedHttpTest::googleVeoUsesHeaderLimitsWhenPresent()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray modelInfoBody = R"JSON({
        "name": "models/veo-3",
        "displayName": "Veo 3"
    })JSON";

    server.setResponse(
        QStringLiteral("GET"),
        QStringLiteral("/v1beta/models/veo-3"),
        200,
        modelInfoBody,
        {
            {"x-ratelimit-limit-requests", "77"},
            {"x-ratelimit-remaining-requests", "66"},
            {"x-ratelimit-limit-tokens", "12345"},
            {"x-ratelimit-remaining-tokens", "12000"},
            {"x-ratelimit-reset-requests", "45s"},
        });

    GoogleVeoProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1beta"));
    provider.setModel(QStringLiteral("veo-3"));
    provider.setTier(QStringLiteral("paid"));

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.rateLimitRequests(), 77);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 66);
    QCOMPARE(provider.rateLimitTokens(), 12345);
    QCOMPARE(provider.rateLimitTokensRemaining(), 12000);
    QCOMPARE(provider.rateLimitResetTime(), QStringLiteral("45s"));
    QCOMPARE(provider.requestCount(), 1);
    QVERIFY(provider.isConnected());
}

void ProvidersMockedHttpTest::googleVeoAuthError()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray authError = R"JSON({"error":"unauthorized"})JSON";
    server.setResponse(
        QStringLiteral("GET"),
        QStringLiteral("/v1beta/models/veo-3"),
        404,
        authError);

    GoogleVeoProvider provider;
    provider.setApiKey(QStringLiteral("bad-key"));
    provider.setCustomBaseUrl(server.baseUrl() + QStringLiteral("/v1beta"));
    provider.setModel(QStringLiteral("veo-3"));

    QSignalSpy errorSpy(&provider, &ProviderBackend::errorChanged);
    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);
    QVERIFY(errorSpy.count() >= 1);
    QVERIFY(provider.errorCount() >= 1);
    QVERIFY(!provider.errorString().isEmpty());
    QVERIFY(!provider.isConnected());
}

void ProvidersMockedHttpTest::openRouterUsageAndCredits()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray usageBody = R"JSON({
        "usage": {
            "prompt_tokens": 200,
            "completion_tokens": 80
        }
    })JSON";

    const QByteArray creditsBody = R"JSON({
        "data": {
            "label": "my-key",
            "usage": 3.50,
            "limit": 25.00
        }
    })JSON";

    server.setResponse(
        QStringLiteral("POST"),
        QStringLiteral("/chat/completions"),
        200,
        usageBody,
        {
            {"x-ratelimit-limit-requests", "200"},
            {"x-ratelimit-remaining-requests", "180"},
            {"x-ratelimit-limit-tokens", "10000"},
            {"x-ratelimit-remaining-tokens", "9500"},
            {"x-ratelimit-reset-requests", "15s"},
        });
    server.setResponse(QStringLiteral("GET"), QStringLiteral("/auth/key"), 200, creditsBody);

    OpenRouterProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl());

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.inputTokens(), 200);
    QCOMPARE(provider.outputTokens(), 80);
    QCOMPARE(provider.requestCount(), 1);
    QCOMPARE(provider.rateLimitRequests(), 200);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 180);
    QCOMPARE(provider.rateLimitTokens(), 10000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 9500);
    QCOMPARE(provider.rateLimitResetTime(), QStringLiteral("15s"));
    QCOMPARE(provider.credits(), 21.50);
    QVERIFY(provider.isConnected());

    QVERIFY(server.hitCount(QStringLiteral("/chat/completions")) >= 1);
    QVERIFY(server.hitCount(QStringLiteral("/auth/key")) >= 1);
}

void ProvidersMockedHttpTest::togetherAiUsageAndHeaders()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray usageBody = R"JSON({
        "usage": {
            "prompt_tokens": 50,
            "completion_tokens": 30
        }
    })JSON";

    server.setResponse(
        QStringLiteral("POST"),
        QStringLiteral("/chat/completions"),
        200,
        usageBody,
        {
            {"x-ratelimit-limit-requests", "60"},
            {"x-ratelimit-remaining-requests", "55"},
            {"x-ratelimit-limit-tokens", "4000"},
            {"x-ratelimit-remaining-tokens", "3800"},
            {"x-ratelimit-reset-requests", "60s"},
        });

    TogetherProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl());

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.inputTokens(), 50);
    QCOMPARE(provider.outputTokens(), 30);
    QCOMPARE(provider.requestCount(), 1);
    QCOMPARE(provider.rateLimitRequests(), 60);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 55);
    QCOMPARE(provider.rateLimitTokens(), 4000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 3800);
    QVERIFY(provider.isConnected());
}

void ProvidersMockedHttpTest::cohereUsageAndHeaders()
{
    HttpStubServer server;
    QVERIFY(server.listen());

    const QByteArray usageBody = R"JSON({
        "usage": {
            "prompt_tokens": 75,
            "completion_tokens": 25
        }
    })JSON";

    server.setResponse(
        QStringLiteral("POST"),
        QStringLiteral("/chat/completions"),
        200,
        usageBody,
        {
            {"x-ratelimit-limit-requests", "40"},
            {"x-ratelimit-remaining-requests", "35"},
            {"x-ratelimit-limit-tokens", "8000"},
            {"x-ratelimit-remaining-tokens", "7700"},
        });

    CohereProvider provider;
    provider.setApiKey(QStringLiteral("test-key"));
    provider.setCustomBaseUrl(server.baseUrl());

    QSignalSpy dataSpy(&provider, &ProviderBackend::dataUpdated);
    provider.refresh();

    QTRY_VERIFY_WITH_TIMEOUT(dataSpy.count() >= 1, 3000);

    QCOMPARE(provider.inputTokens(), 75);
    QCOMPARE(provider.outputTokens(), 25);
    QCOMPARE(provider.requestCount(), 1);
    QCOMPARE(provider.rateLimitRequests(), 40);
    QCOMPARE(provider.rateLimitRequestsRemaining(), 35);
    QCOMPARE(provider.rateLimitTokens(), 8000);
    QCOMPARE(provider.rateLimitTokensRemaining(), 7700);
    QVERIFY(provider.isConnected());
}

QTEST_MAIN(ProvidersMockedHttpTest)
#include "test_providers_mocked_http.moc"
