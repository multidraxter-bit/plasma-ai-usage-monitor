#include "webhooknotifier.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>

WebhookNotifier::WebhookNotifier(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
}

WebhookNotifier::~WebhookNotifier() = default;

bool WebhookNotifier::slackEnabled() const { return m_slackEnabled; }
void WebhookNotifier::setSlackEnabled(bool enabled)
{
    if (m_slackEnabled != enabled) {
        m_slackEnabled = enabled;
        Q_EMIT configChanged();
    }
}

bool WebhookNotifier::discordEnabled() const { return m_discordEnabled; }
void WebhookNotifier::setDiscordEnabled(bool enabled)
{
    if (m_discordEnabled != enabled) {
        m_discordEnabled = enabled;
        Q_EMIT configChanged();
    }
}

QString WebhookNotifier::slackWebhookUrl() const { return m_slackWebhookUrl; }
void WebhookNotifier::setSlackWebhookUrl(const QString &url)
{
    if (m_slackWebhookUrl != url) {
        m_slackWebhookUrl = url.trimmed();
        Q_EMIT configChanged();
    }
}

QString WebhookNotifier::discordWebhookUrl() const { return m_discordWebhookUrl; }
void WebhookNotifier::setDiscordWebhookUrl(const QString &url)
{
    if (m_discordWebhookUrl != url) {
        m_discordWebhookUrl = url.trimmed();
        Q_EMIT configChanged();
    }
}

int WebhookNotifier::cooldownMinutes() const { return m_cooldownMinutes; }
void WebhookNotifier::setCooldownMinutes(int minutes)
{
    const int clamped = qBound(1, minutes, 1440);
    if (m_cooldownMinutes != clamped) {
        m_cooldownMinutes = clamped;
        Q_EMIT configChanged();
    }
}

void WebhookNotifier::sendAlert(const QString &eventKey,
                                const QString &title,
                                const QString &message,
                                bool critical)
{
    if (!shouldSend(eventKey)) {
        return;
    }

    if (m_slackEnabled && !m_slackWebhookUrl.isEmpty()) {
        postSlack(title, message, critical);
    }
    if (m_discordEnabled && !m_discordWebhookUrl.isEmpty()) {
        postDiscord(title, message, critical);
    }
}

bool WebhookNotifier::shouldSend(const QString &eventKey)
{
    const QDateTime now = QDateTime::currentDateTimeUtc();
    const QDateTime last = m_lastSent.value(eventKey);
    if (last.isValid() && last.secsTo(now) < (m_cooldownMinutes * 60)) {
        return false;
    }
    m_lastSent.insert(eventKey, now);
    return true;
}

void WebhookNotifier::postSlack(const QString &title, const QString &message, bool critical)
{
    QNetworkRequest request{QUrl(m_slackWebhookUrl)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    QJsonObject payload;
    payload.insert(QStringLiteral("text"),
                   QStringLiteral("%1 %2\n%3")
                       .arg(critical ? QStringLiteral("[critical]") : QStringLiteral("[info]"),
                            title,
                            message));

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            Q_EMIT deliveryFailed(QStringLiteral("slack"), reply->errorString());
        }
        reply->deleteLater();
    });
}

void WebhookNotifier::postDiscord(const QString &title, const QString &message, bool critical)
{
    QNetworkRequest request{QUrl(m_discordWebhookUrl)};
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));

    QJsonObject embed;
    embed.insert(QStringLiteral("title"), title);
    embed.insert(QStringLiteral("description"), message);
    embed.insert(QStringLiteral("color"), critical ? 15158332 : 3447003);

    QJsonObject payload;
    payload.insert(QStringLiteral("content"), QStringLiteral("AI Usage Monitor"));
    payload.insert(QStringLiteral("embeds"), QJsonArray{embed});

    QNetworkReply *reply = m_networkManager->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() != QNetworkReply::NoError) {
            Q_EMIT deliveryFailed(QStringLiteral("discord"), reply->errorString());
        }
        reply->deleteLater();
    });
}
