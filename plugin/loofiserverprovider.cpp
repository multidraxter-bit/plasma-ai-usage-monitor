#include "loofiserverprovider.h"

#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>

namespace {
constexpr auto DEFAULT_LOOFI_SERVER_URL = "http://127.0.0.1:3000";
}

LoofiServerProvider::LoofiServerProvider(QObject *parent)
    : ProviderBackend(parent)
{}

QString LoofiServerProvider::serverUrl() const
{
    if (!customBaseUrl().trimmed().isEmpty()) {
        return effectiveBaseUrl("");
    }

    QString url = qEnvironmentVariable("LOOFI_SERVER_URL", DEFAULT_LOOFI_SERVER_URL);
    while (url.endsWith(QLatin1Char('/'))) {
        url.chop(1);
    }
    return url;
}

void LoofiServerProvider::refresh()
{
    beginRefresh();
    setLoading(true);
    clearError();

    const QString token = qEnvironmentVariable("LOOFI_SERVER_TOKEN");
    QNetworkRequest req = createRequest(
        QUrl(serverUrl() + QStringLiteral("/api/v2/metrics-summary")));

    if (!token.isEmpty()) {
        req.setRawHeader("Authorization",
                         QStringLiteral("Bearer %1").arg(token).toUtf8());
    }

    const int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(req);
    trackReply(reply);

    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        reply->deleteLater();
        if (!isCurrentGeneration(gen))
            return;

        setLoading(false);

        if (reply->error() != QNetworkReply::NoError) {
            setError(QStringLiteral("Loofi: %1").arg(reply->errorString()));
            setConnected(false);
            return;
        }

        const auto doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) {
            setError(QStringLiteral("Loofi: invalid JSON response"));
            setConnected(false);
            return;
        }

        const QJsonObject obj = doc.object();

        m_activeModel   = obj.value(QLatin1String("model")).toString(QLatin1String("?"));
        m_trainingStage = obj.value(QLatin1String("training_stage")).toString(QLatin1String("idle"));
        m_gpuMemoryPct  = obj.value(QLatin1String("gpu_memory_pct")).toDouble(-1.0);

        const int infer = obj.value(QLatin1String("inference_count_24h")).toInt(0);
        setRequestCount(infer);

        updateLastRefreshed();
        setConnected(true);
        clearError();

        Q_EMIT serverDataUpdated();
        Q_EMIT dataUpdated();
    });
}
