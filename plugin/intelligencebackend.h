#ifndef INTELLIGENCEBACKEND_H
#define INTELLIGENCEBACKEND_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QNetworkAccessManager>
#include "usagedatabase.h"

class IntelligenceBackend : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString fullInsight READ fullInsight WRITE setFullInsight NOTIFY fullInsightChanged)
    Q_PROPERTY(QString shortSnippet READ shortSnippet WRITE setShortSnippet NOTIFY shortSnippetChanged)
    Q_PROPERTY(QString bannerAlert READ bannerAlert WRITE setBannerAlert NOTIFY bannerAlertChanged)
    Q_PROPERTY(bool isGenerating READ isGenerating NOTIFY isGeneratingChanged)
    Q_PROPERTY(UsageDatabase* database READ database WRITE setDatabase NOTIFY databaseChanged)

public:
    explicit IntelligenceBackend(QObject *parent = nullptr);

    QString fullInsight() const { return m_fullInsight; }
    void setFullInsight(const QString &val);

    QString shortSnippet() const { return m_shortSnippet; }
    void setShortSnippet(const QString &val);

    QString bannerAlert() const { return m_bannerAlert; }
    void setBannerAlert(const QString &val);

    bool isGenerating() const { return m_isGenerating; }

    UsageDatabase* database() const { return m_database; }
    void setDatabase(UsageDatabase* db);

    Q_INVOKABLE void generate(const QString &ollamaUrl, const QString &modelName);

Q_SIGNALS:
    void fullInsightChanged();
    void shortSnippetChanged();
    void bannerAlertChanged();
    void isGeneratingChanged();
    void databaseChanged();
    void generationFinished(bool success, const QString &error = QString());

private Q_SLOTS:
    void onOllamaReply();

private:
    QString m_fullInsight;
    QString m_shortSnippet;
    QString m_bannerAlert;
    bool m_isGenerating = false;
    UsageDatabase* m_database = nullptr;
    QNetworkAccessManager *m_networkManager;
};

#endif
