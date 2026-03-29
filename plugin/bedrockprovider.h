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
