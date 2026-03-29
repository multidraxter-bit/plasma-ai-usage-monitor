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
