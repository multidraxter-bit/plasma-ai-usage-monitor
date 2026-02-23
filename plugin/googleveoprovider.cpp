#include "googleveoprovider.h"
#include <KLocalizedString>
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QDebug>

GoogleVeoProvider::GoogleVeoProvider(QObject *parent)
    : ProviderBackend(parent)
{
    // Veo pricing — per-video cost mapped to per-1M-token equivalents
    // for the cost estimation framework.
    // Veo 3: ~$0.50/sec generated video
    // Veo 2: ~$0.35/sec generated video
    // We register token-based placeholders; actual cost depends on video duration.
    registerModelPricing(QStringLiteral("veo-3"), 50.0, 50.0);
    registerModelPricing(QStringLiteral("veo-2"), 35.0, 35.0);
}

QString GoogleVeoProvider::model() const { return m_model; }
void GoogleVeoProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

QString GoogleVeoProvider::tier() const { return m_tier; }
void GoogleVeoProvider::setTier(const QString &tier)
{
    if (m_tier != tier) {
        m_tier = tier;
        Q_EMIT tierChanged();
    }
}

void GoogleVeoProvider::refresh()
{
    if (!hasApiKey()) {
        setError(i18n("No API key configured"));
        setConnected(false);
        return;
    }

    beginRefresh();
    setLoading(true);
    clearError();
    fetchModelInfo();
}

void GoogleVeoProvider::fetchModelInfo()
{
    // GET /v1beta/models/{model} as a lightweight connectivity check
    QUrl url(QStringLiteral("%1/models/%2")
                 .arg(effectiveBaseUrl(BASE_URL), m_model));

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("key"), apiKey());
    url.setQuery(query);

    // Use createRequest for timeout, then clear Bearer auth (Google uses query-param auth)
    QNetworkRequest request = createRequest(url);
    request.setRawHeader("Authorization", QByteArray());

    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
        onModelInfoReply(reply);
    });
}

void GoogleVeoProvider::onModelInfoReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (httpStatus == 400 || httpStatus == 404) {
            setError(i18n("Invalid API key or model name"));
        } else if (httpStatus == 429) {
            setError(i18n("Rate limited"));
        } else {
            setError(i18n("API error: %1 (HTTP %2)",
                         reply->errorString(),
                         QString::number(httpStatus)));
        }
        setLoading(false);
        setConnected(false);
        updateLastRefreshed();
        Q_EMIT dataUpdated();
        return;
    }

    // A successful response confirms the key and model are valid.
    applyKnownLimits();

    setConnected(true);
    setLoading(false);
    updateLastRefreshed();
    Q_EMIT dataUpdated();
}

void GoogleVeoProvider::applyKnownLimits()
{
    // Known rate limits for Veo models (as of 2025-2026)
    bool isPaid = (m_tier == QStringLiteral("paid"));

    if (m_model.contains(QStringLiteral("veo-2"))) {
        setRateLimitRequests(isPaid ? 200 : 10);
        setRateLimitRequestsRemaining(isPaid ? 200 : 10);
    } else {
        // veo-3 and all other Veo models share the same limits
        setRateLimitRequests(isPaid ? 100 : 5);
        setRateLimitRequestsRemaining(isPaid ? 100 : 5);
    }

    setRateLimitResetTime(isPaid ? QStringLiteral("N/A (paid tier limits)")
                                 : QStringLiteral("N/A (free tier limits)"));
}
