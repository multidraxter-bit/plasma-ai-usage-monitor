#include "localmetricsserver.h"

#include <QTcpServer>
#include <QTcpSocket>
#include <QHostAddress>

LocalMetricsServer::LocalMetricsServer(QObject *parent)
    : QObject(parent)
    , m_server(new QTcpServer(this))
{
    connect(m_server, &QTcpServer::newConnection, this, [this]() {
        while (m_server->hasPendingConnections()) {
            QTcpSocket *socket = m_server->nextPendingConnection();
            connect(socket, &QTcpSocket::readyRead, this, [this, socket]() {
                socket->readAll();
                const QByteArray body = m_payload.toUtf8();
                const QByteArray response =
                    "HTTP/1.1 200 OK\r\n"
                    "Content-Type: text/plain; version=0.0.4; charset=utf-8\r\n"
                    "Cache-Control: no-store\r\n"
                    "Content-Length: " + QByteArray::number(body.size()) + "\r\n"
                    "Connection: close\r\n\r\n" + body;
                socket->write(response);
                socket->disconnectFromHost();
            });
            connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
        }
    });
}

LocalMetricsServer::~LocalMetricsServer() = default;

bool LocalMetricsServer::isEnabled() const
{
    return m_enabled;
}

void LocalMetricsServer::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        restartServer();
        Q_EMIT enabledChanged();
    }
}

int LocalMetricsServer::port() const
{
    return m_port;
}

void LocalMetricsServer::setPort(int port)
{
    const int clampedPort = qBound(1024, port, 65535);
    if (m_port != clampedPort) {
        m_port = clampedPort;
        restartServer();
        Q_EMIT portChanged();
    }
}

QString LocalMetricsServer::payload() const
{
    return m_payload;
}

void LocalMetricsServer::setPayload(const QString &payload)
{
    if (m_payload != payload) {
        m_payload = payload;
        Q_EMIT payloadChanged();
    }
}

bool LocalMetricsServer::isListening() const
{
    return m_server->isListening();
}

void LocalMetricsServer::restartServer()
{
    const bool wasListening = m_server->isListening();
    if (wasListening) {
        m_server->close();
    }

    if (m_enabled) {
        if (!m_server->listen(QHostAddress::LocalHost, static_cast<quint16>(m_port))) {
            Q_EMIT error(m_server->errorString());
        }
    }

    if (wasListening != m_server->isListening()) {
        Q_EMIT listeningChanged();
    }
}
