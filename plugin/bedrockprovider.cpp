#include "bedrockprovider.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

BedrockProvider::BedrockProvider(QObject *parent) : ProviderBackend(parent) {
    setupPricing();
}

void BedrockProvider::setModel(const QString &m) { if (m_model != m) { m_model = m; emit modelChanged(); } }
void BedrockProvider::setRegion(const QString &r) { if (m_region != r) { m_region = r; emit regionChanged(); } }
void BedrockProvider::setAccessKey(const QString &k) { if (m_accessKey != k) { m_accessKey = k; emit authChanged(); } }
void BedrockProvider::setSecretKey(const QString &k) { if (m_secretKey != k) { m_secretKey = k; emit authChanged(); } }

void BedrockProvider::setupPricing() {
    registerModelPricing(QStringLiteral("anthropic.claude-3-5-sonnet-20240620-v1:0"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("anthropic.claude-3-sonnet-20240229-v1:0"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("anthropic.claude-3-haiku-20240307-v1:0"), 0.25, 1.25);
    registerModelPricing(QStringLiteral("meta.llama3-1-70b-instruct-v1:0"), 0.99, 0.99);
    registerModelPricing(QStringLiteral("meta.llama3-1-8b-instruct-v1:0"), 0.30, 0.60);
}

void BedrockProvider::refresh() {
    if (m_accessKey.isEmpty() || m_secretKey.isEmpty()) {
        setError(tr("AWS credentials missing"));
        return;
    }

    beginRefresh();
    setLoading(true);

    QDateTime now = QDateTime::currentDateTimeUtc();
    QDateTime startOfMonth = QDateTime(now.date().addDays(-now.date().day() + 1), QTime(0, 0));

    // We'll query CloudWatch for token counts.
    // For Bedrock, the Namespace is AWS/Bedrock
    // Metrics: InputTokenCount, OutputTokenCount
    // Dimension: ModelId

    QJsonArray queries;
    
    auto addQuery = [&](const QString &id, const QString &metricName) {
        QJsonObject q;
        q["Id"] = id;
        QJsonObject ms;
        QJsonObject m;
        m["Namespace"] = "AWS/Bedrock";
        m["MetricName"] = metricName;
        QJsonArray dims;
        QJsonObject dim; dim["Name"] = "ModelId"; dim["Value"] = m_model;
        dims.append(dim);
        m["Dimensions"] = dims;
        ms["Metric"] = m;
        ms["Period"] = 86400 * 31; // Big period for monthly sum
        ms["Stat"] = "Sum";
        q["MetricStat"] = ms;
        queries.append(q);
    };

    addQuery("input", "InputTokenCount");
    addQuery("output", "OutputTokenCount");
    addQuery("invocations", "Invocations");

    QJsonObject root;
    root["MetricDataQueries"] = queries;
    root["StartTime"] = startOfMonth.toSecsSinceEpoch();
    root["EndTime"] = now.toSecsSinceEpoch();

    QByteArray payload = QJsonDocument(root).toJson(QJsonDocument::Compact);
    QUrl url(QStringLiteral("https://monitoring.%1.amazonaws.com/").arg(m_region));
    
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-amz-json-1.1");
    request.setRawHeader("X-Amz-Target", "GranularMetricData.GetMetricData");

    AwsSigV4Signer::Credentials creds;
    creds.accessKey = m_accessKey;
    creds.secretKey = m_secretKey;
    AwsSigV4Signer::sign(request, payload, creds, m_region, "monitoring");

    QNetworkReply *reply = networkManager()->post(request, payload);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onCloudWatchReply(reply); });
    trackReply(reply);
}

void BedrockProvider::onCloudWatchReply(QNetworkReply *reply) {
    if (!isCurrentGeneration(reply->property("generation").toInt())) {
        reply->deleteLater();
        return;
    }

    setLoading(false);
    if (reply->error() == QNetworkReply::NoError) {
        setConnected(true);
        clearError();

        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QJsonArray results = doc.object().value("MetricDataResults").toArray();

        qint64 input = 0;
        qint64 output = 0;
        int count = 0;

        for (const QJsonValue &v : results) {
            QJsonObject res = v.toObject();
            QString id = res.value("Id").toString();
            QJsonArray values = res.value("Values").toArray();
            double sum = values.isEmpty() ? 0.0 : values.at(0).toDouble();

            if (id == "input") input = static_cast<qint64>(sum);
            else if (id == "output") output = static_cast<qint64>(sum);
            else if (id == "invocations") count = static_cast<int>(sum);
        }

        setInputTokens(input);
        setOutputTokens(output);
        setRequestCount(count);
        updateEstimatedCost(m_model);
        updateLastRefreshed();
    } else {
        setError(reply->errorString());
    }
    reply->deleteLater();
}
