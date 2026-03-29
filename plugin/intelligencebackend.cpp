#include "intelligencebackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QDebug>

IntelligenceBackend::IntelligenceBackend(QObject *parent)
    : QObject(parent), m_networkManager(new QNetworkAccessManager(this))
{}

void IntelligenceBackend::setFullInsight(const QString &val) {
    if (m_fullInsight != val) { m_fullInsight = val; emit fullInsightChanged(); }
}

void IntelligenceBackend::setShortSnippet(const QString &val) {
    if (m_shortSnippet != val) { m_shortSnippet = val; emit shortSnippetChanged(); }
}

void IntelligenceBackend::setBannerAlert(const QString &val) {
    if (m_bannerAlert != val) { m_bannerAlert = val; emit bannerAlertChanged(); }
}

void IntelligenceBackend::setDatabase(UsageDatabase* db) {
    if (m_database != db) { m_database = db; emit databaseChanged(); }
}

void IntelligenceBackend::generate(const QString &ollamaUrl, const QString &modelName) {
    if (m_isGenerating || !m_database) return;
    
    m_isGenerating = true;
    emit isGeneratingChanged();

    QString history = m_database->getRecentHistoryJson(7);
    
    QString systemPrompt = QStringLiteral(
        "You are an AI financial analyst for the 'Plasma AI Usage Monitor'. "
        "Analyze the following 7-day usage history and provide insights in a structured format. "
        "Focus on cost-saving and unusual patterns. "
        "Format your response EXACTLY like this:\n"
        "[BANNER] (One short sentence for a dashboard alert, e.g. 'Spending is up 20%')\n"
        "[SNIPPET] (One very short sentence for a card summary, e.g. 'Trending higher')\n"
        "[FULL] (A detailed 2-3 paragraph analysis with specific recommendations)\n"
    );

    QJsonObject root;
    root[QStringLiteral("model")] = modelName;
    root[QStringLiteral("prompt")] = systemPrompt + "\n\nUsage History:\n" + history;
    root[QStringLiteral("stream")] = false;

    QNetworkRequest request(QUrl(ollamaUrl + QStringLiteral("/api/generate")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(root).toJson());
    connect(reply, &QNetworkReply::finished, this, &IntelligenceBackend::onOllamaReply);
}

void IntelligenceBackend::onOllamaReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    m_isGenerating = false;
    emit isGeneratingChanged();

    if (reply->error() == QNetworkReply::NoError) {
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        QString responseText = doc.object().value(QStringLiteral("response")).toString();

        int bannerIdx = responseText.indexOf(QStringLiteral("[BANNER]"));
        int snippetIdx = responseText.indexOf(QStringLiteral("[SNIPPET]"));
        int fullIdx = responseText.indexOf(QStringLiteral("[FULL]"));

        if (bannerIdx != -1 && snippetIdx != -1 && fullIdx != -1) {
            setBannerAlert(responseText.mid(bannerIdx + 8, snippetIdx - (bannerIdx + 8)).trimmed());
            setShortSnippet(responseText.mid(snippetIdx + 9, fullIdx - (snippetIdx + 9)).trimmed());
            setFullInsight(responseText.mid(fullIdx + 6).trimmed());
            emit generationFinished(true);
        } else {
            setFullInsight(responseText);
            setShortSnippet(QStringLiteral("Analysis complete"));
            setBannerAlert(QStringLiteral("AI Insight generated"));
            emit generationFinished(true);
        }
    } else {
        emit generationFinished(false, reply->errorString());
    }

    reply->deleteLater();
}
