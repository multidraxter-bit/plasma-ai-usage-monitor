#ifndef AWSSIGV4SIGNER_H
#define AWSSIGV4SIGNER_H

#include <QByteArray>
#include <QDateTime>
#include <QList>
#include <QPair>
#include <QString>

class AwsSigV4Signer
{
public:
    struct SignedHeaders {
        QList<QPair<QByteArray, QByteArray>> headers;
        QByteArray authorizationHeader;
        QByteArray amzDate;
        QByteArray payloadHash;
    };

    static SignedHeaders sign(const QString &accessKeyId,
                              const QString &secretAccessKey,
                              const QString &sessionToken,
                              const QString &region,
                              const QString &service,
                              const QString &method,
                              const QString &canonicalUri,
                              const QString &canonicalQueryString,
                              const QList<QPair<QByteArray, QByteArray>> &headers,
                              const QByteArray &payload,
                              const QDateTime &timestampUtc = QDateTime::currentDateTimeUtc());

    static QByteArray sha256Hex(const QByteArray &data);

private:
    static QByteArray hmacSha256(const QByteArray &key, const QByteArray &message);
    static QByteArray signingKey(const QString &secretAccessKey,
                                 const QString &date,
                                 const QString &region,
                                 const QString &service);
    static QList<QPair<QByteArray, QByteArray>> normalizedHeaders(
        const QList<QPair<QByteArray, QByteArray>> &headers,
        const QByteArray &amzDate,
        const QByteArray &payloadHash,
        const QString &sessionToken);
};

#endif // AWSSIGV4SIGNER_H
