#include "ollamaprovider.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkReply>

OllamaProvider::OllamaProvider(QObject *parent)
    : ProviderBackend(parent)
{
}

void OllamaProvider::refresh()
{
    beginRefresh();
    setLoading(true);

    // Default to local Ollama. If a custom base URL is set, effectiveBaseUrl() will return it.
    QUrl url(QStringLiteral("%1/ps").arg(effectiveBaseUrl("http://localhost:11434/api")));
    QNetworkRequest request = createRequest(url);
    
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    
    int generation = currentGeneration();
    connect(reply, &QNetworkReply::finished, this, [this, reply, generation]() {
        if (!isCurrentGeneration(generation)) {
            reply->deleteLater();
            return;
        }
        onPsReply(reply);
    });
}

void OllamaProvider::onPsReply(QNetworkReply *reply)
{
    setLoading(false);
    
    if (reply->error() != QNetworkReply::NoError) {
        setError(reply->errorString());
        setConnected(false);
        reply->deleteLater();
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    if (!doc.isObject()) {
        setError(QStringLiteral("Invalid JSON response from Ollama"));
        setConnected(false);
        reply->deleteLater();
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray models = root.value(QStringLiteral("models")).toArray();

    QVariantList activeModelsList;
    double totalMem = 0.0;
    double vramMem = 0.0;

    for (const QJsonValue &value : models) {
        QJsonObject modelObj = value.toObject();
        QVariantMap modelMap;
        modelMap[QStringLiteral("name")] = modelObj.value(QStringLiteral("name")).toString();
        
        double size = modelObj.value(QStringLiteral("size")).toDouble();
        double sizeVram = modelObj.value(QStringLiteral("size_vram")).toDouble();
        
        modelMap[QStringLiteral("size")] = size;
        modelMap[QStringLiteral("sizeVram")] = sizeVram;
        
        totalMem += size;
        vramMem += sizeVram;
        
        activeModelsList.append(modelMap);
    }

    if (m_activeModels != activeModelsList) {
        m_activeModels = activeModelsList;
        emit activeModelsChanged();
    }

    if (m_totalMemory != totalMem) {
        m_totalMemory = totalMem;
        emit totalMemoryChanged();
    }

    if (m_vramMemory != vramMem) {
        m_vramMemory = vramMem;
        emit vramMemoryChanged();
    }

    setConnected(true);
    clearError();
    updateLastRefreshed();
    
    // Ensure all cost properties return 0.0
    setCost(0.0);
    setDailyCost(0.0);
    setMonthlyCost(0.0);

    reply->deleteLater();
}
