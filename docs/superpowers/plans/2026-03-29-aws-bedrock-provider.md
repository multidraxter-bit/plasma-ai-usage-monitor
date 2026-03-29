# AWS Bedrock Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a new AWS Bedrock provider that tracks token usage and estimates costs using CloudWatch metrics and local pricing tables.

**Architecture:** A new `BedrockProvider` class (C++) handles AWS SigV4 signing and polls the CloudWatch API for usage metrics. It uses local price estimation since AWS doesn't provide an instant Bedrock billing API.

**Tech Stack:** C++20, Qt6 (Network, Qml), AWS SigV4 Signing, CloudWatch API.

---

### Task 1: AWS SigV4 Signer Utility

**Files:**
- Create: `plugin/awssigv4signer.h`
- Create: `plugin/awssigv4signer.cpp`
- Modify: `plugin/CMakeLists.txt`

- [ ] **Step 1: Create AWS SigV4 Signer Header**

```cpp
#ifndef AWSSIGV4SIGNER_H
#define AWSSIGV4SIGNER_H

#include <QString>
#include <QByteArray>
#include <QDateTime>
#include <QNetworkRequest>
#include <QMap>

class AwsSigV4Signer {
public:
    struct Credentials {
        QString accessKey;
        QString secretKey;
        QString sessionToken;
    };

    static void sign(QNetworkRequest &request,
                    const QByteArray &payload,
                    const Credentials &creds,
                    const QString &region,
                    const QString &service,
                    const QDateTime &dateTime = QDateTime::currentDateTimeUtc());

private:
    static QByteArray hmacSha256(const QByteArray &key, const QByteArray &data);
    static QByteArray hashSha256(const QByteArray &data);
};

#endif
```

- [ ] **Step 2: Create AWS SigV4 Signer Implementation**

```cpp
#include "awssigv4signer.h"
#include <QCryptographicHash>
#include <QMessageAuthenticationCode>
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>

void AwsSigV4Signer::sign(QNetworkRequest &request, const QByteArray &payload, const Credentials &creds, const QString &region, const QString &service, const QDateTime &dateTime) {
    QString dateStr = dateTime.toString(QStringLiteral("yyyyMMdd"));
    QString amzDate = dateTime.toString(QStringLiteral("yyyyMMddTHHmmssZ"));
    
    request.setRawHeader("X-Amz-Date", amzDate.toUtf8());
    if (!creds.sessionToken.isEmpty()) {
        request.setRawHeader("X-Amz-Security-Token", creds.sessionToken.toUtf8());
    }

    QUrl url = request.url();
    QString host = url.host();
    request.setRawHeader("Host", host.toUtf8());

    // 1. Canonical Request
    QByteArray canonicalRequest;
    canonicalRequest += request.attribute(QNetworkRequest::CustomVerbAttribute).toByteArray().isEmpty() ? "POST\n" : request.attribute(QNetworkRequest::CustomVerbAttribute).toByteArray() + "\n";
    canonicalRequest += url.path().isEmpty() ? "/\n" : url.path().toUtf8() + "\n";
    canonicalRequest += "\n"; // No query params for now

    QMap<QString, QString> headers;
    headers["host"] = host.toLower();
    headers["x-amz-date"] = amzDate.toLower();
    if (!creds.sessionToken.isEmpty()) headers["x-amz-security-token"] = creds.sessionToken.toLower();
    headers["content-type"] = request.header(QNetworkRequest::ContentTypeHeader).toString().toLower();

    QString signedHeaders;
    for (auto it = headers.begin(); it != headers.end(); ++it) {
        canonicalRequest += it.key().toUtf8() + ":" + it.value().toUtf8() + "\n";
        if (!signedHeaders.isEmpty()) signedHeaders += ";";
        signedHeaders += it.key();
    }
    canonicalRequest += "\n" + signedHeaders.toUtf8() + "\n";
    canonicalRequest += hashSha256(payload).toHex();

    // 2. String to Sign
    QByteArray stringToSign;
    stringToSign += "AWS4-HMAC-SHA256\n";
    stringToSign += amzDate.toUtf8() + "\n";
    stringToSign += dateStr.toUtf8() + "/" + region.toUtf8() + "/" + service.toUtf8() + "/aws4_request\n";
    stringToSign += hashSha256(canonicalRequest).toHex();

    // 3. Signature
    QByteArray kDate = hmacSha256("AWS4" + creds.secretKey.toUtf8(), dateStr.toUtf8());
    QByteArray kRegion = hmacSha256(kDate, region.toUtf8());
    QByteArray kService = hmacSha256(kRegion, service.toUtf8());
    QByteArray kSigning = hmacSha256(kService, "aws4_request");
    QByteArray signature = hmacSha256(kSigning, stringToSign).toHex();

    QString authHeader = QStringLiteral("AWS4-HMAC-SHA256 Credential=%1/%2/%3/%4/aws4_request, SignedHeaders=%5, Signature=%6")
        .arg(creds.accessKey, dateStr, region, service, signedHeaders, QString::fromUtf8(signature));
    
    request.setRawHeader("Authorization", authHeader.toUtf8());
}

QByteArray AwsSigV4Signer::hmacSha256(const QByteArray &key, const QByteArray &data) {
    return QMessageAuthenticationCode::hash(data, key, QCryptographicHash::Sha256);
}

QByteArray AwsSigV4Signer::hashSha256(const QByteArray &data) {
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256);
}
```

- [ ] **Step 3: Update CMakeLists.txt**

Add `awssigv4signer.cpp` and `awssigv4signer.h` to `aiusagemonitor_SRCS` and `aiusagemonitor_HDRS`.

- [ ] **Step 4: Commit**

```bash
git add plugin/awssigv4signer.h plugin/awssigv4signer.cpp plugin/CMakeLists.txt
git commit -m "feat(aws): add AWS SigV4 signer utility"
```

---

### Task 2: BedrockProvider C++ Backend

**Files:**
- Create: `plugin/bedrockprovider.h`
- Create: `plugin/bedrockprovider.cpp`
- Modify: `plugin/CMakeLists.txt`

- [ ] **Step 1: Create BedrockProvider Header**

```cpp
#ifndef BEDROCKPROVIDER_H
#define BEDROCKPROVIDER_H

#include "providerbackend.h"
#include "awssigv4signer.h"

class BedrockProvider : public ProviderBackend
{
    Q_OBJECT
    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString region READ region WRITE setRegion NOTIFY regionChanged)
    Q_PROPERTY(QString accessKey READ accessKey WRITE setAccessKey NOTIFY authChanged)
    Q_PROPERTY(QString secretKey READ secretKey WRITE setSecretKey NOTIFY authChanged)

public:
    explicit BedrockProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("AWS Bedrock"); }
    QString iconName() const override { return QStringLiteral("cloud"); }

    QString model() const { return m_model; }
    void setModel(const QString &m);

    QString region() const { return m_region; }
    void setRegion(const QString &r);

    QString accessKey() const { return m_accessKey; }
    void setAccessKey(const QString &k);

    QString secretKey() const { return m_secretKey; }
    void setSecretKey(const QString &k);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();
    void regionChanged();
    void authChanged();

private Q_SLOTS:
    void onCloudWatchReply(QNetworkReply *reply);

private:
    void setupPricing();
    QString m_model = QStringLiteral("anthropic.claude-3-5-sonnet-20240620-v1:0");
    QString m_region = QStringLiteral("us-east-1");
    QString m_accessKey;
    QString m_secretKey;
};

#endif
```

- [ ] **Step 2: Create BedrockProvider Implementation**

```cpp
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
    registerModelPricing(QStringLiteral("meta.llama3-1-70b-instruct-v1:0"), 0.99, 0.99);
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

    QJsonObject query;
    query["Id"] = "usage";
    QJsonObject metricStat;
    QJsonObject metric;
    metric["Namespace"] = "AWS/Bedrock";
    metric["MetricName"] = "InputTokenCount"; // We'll need multiple queries for full data
    QJsonArray dims;
    QJsonObject dim; dim["Name"] = "ModelId"; dim["Value"] = m_model;
    dims.append(dim);
    metric["Dimensions"] = dims;
    metricStat["Metric"] = metric;
    metricStat["Period"] = 86400 * 31;
    metricStat["Stat"] = "Sum";
    query["MetricStat"] = metricStat;

    QJsonArray queries; queries.append(query);
    QJsonObject root;
    root["MetricDataQueries"] = queries;
    root["StartTime"] = startOfMonth.toSecsSinceEpoch();
    root["EndTime"] = now.toSecsSinceEpoch();

    QByteArray payload = QJsonDocument(root).toJson();
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
    setLoading(false);
    if (reply->error() == QNetworkReply::NoError) {
        setConnected(true);
        clearError();
        // Parsing logic here (simplified for plan)
        updateLastRefreshed();
    } else {
        setError(reply->errorString());
    }
    reply->deleteLater();
}
```

- [ ] **Step 3: Update CMakeLists.txt**

Add `bedrockprovider.cpp` and `bedrockprovider.h` to the source lists.

- [ ] **Step 4: Commit**

```bash
git add plugin/bedrockprovider.h plugin/bedrockprovider.cpp plugin/CMakeLists.txt
git commit -m "feat(bedrock): implement BedrockProvider backend"
```

---

### Task 3: QML Plugin Registration

**Files:**
- Modify: `plugin/aiusageplugin.cpp`

- [ ] **Step 1: Register BedrockProvider**

Add `qmlRegisterType<BedrockProvider>(uri, 1, 0, "BedrockProvider");` to `registerTypes`.

- [ ] **Step 2: Commit**

```bash
git add plugin/aiusageplugin.cpp
git commit -m "feat(plugin): register BedrockProvider for QML"
```

---

### Task 4: Configuration & Integration

**Files:**
- Modify: `package/contents/config/main.xml`
- Modify: `package/contents/ui/main.qml`
- Modify: `package/contents/ui/configProviders.qml`

- [ ] **Step 1: Add Bedrock Config Keys to main.xml**

Add `bedrockEnabled`, `bedrockModel`, `bedrockRegion`, `bedrockAccessKey`, `bedrockSecretKey`.

- [ ] **Step 2: Instantiate BedrockProvider in main.qml**

Add the `BedrockProvider` object and wire up its properties to `plasmoid.configuration`.

- [ ] **Step 3: Add Bedrock Configuration UI to configProviders.qml**

Add a new section for AWS Bedrock with fields for Model, Region, and Credentials.

- [ ] **Step 4: Commit**

```bash
git add package/contents/config/main.xml package/contents/ui/main.qml package/contents/ui/configProviders.qml
git commit -m "feat(ui): integrate AWS Bedrock into configuration and main view"
```

---

### Task 5: Verification

- [ ] **Step 1: Build and Install**

Run: `just build && just install && just reload`

- [ ] **Step 2: Verify Provider Appears**

Open settings and verify "AWS Bedrock" is in the provider list.

- [ ] **Step 3: Test refresh**

Enter credentials and trigger a refresh. Verify CloudWatch metrics are fetched (or error is reported).
