#include "awssigv4signer.h"
#include <QCryptographicHash>
#include <QMessageAuthenticationCode>
#include <QUrl>
#include <QUrlQuery>
#include <QDebug>

void AwsSigV4Signer::sign(QNetworkRequest &request, const QByteArray &payload, const Credentials &creds, const QString &region, const QString &service, const QDateTime &dateTime) {
    QString dateStr = dateTime.toString(QStringLiteral("yyyyMMdd"));
    QString amzDate = dateTime.toString(QStringLiteral("yyyyMMddTHHmmssZ"));
    
    request.setRawHeader("X-Amz-Date", amzDate.toUtf8());
    if (!creds.sessionToken.isEmpty()) {
        request.setRawHeader("X-Amz-Security-Token", creds.sessionToken.toUtf8());
    }

    QUrl url = request.url();
    QString host = url.host();
    request.setRawHeader("Host", host.toUtf8());

    // 1. Canonical Request
    QByteArray canonicalRequest;
    canonicalRequest += request.attribute(QNetworkRequest::CustomVerbAttribute).toByteArray().isEmpty() ? "POST\n" : request.attribute(QNetworkRequest::CustomVerbAttribute).toByteArray() + "\n";
    canonicalRequest += url.path().isEmpty() ? "/\n" : url.path().toUtf8() + "\n";
    canonicalRequest += "\n"; // No query params for now

    QMap<QString, QString> headers;
    headers["host"] = host.toLower();
    headers["x-amz-date"] = amzDate.toLower();
    if (!creds.sessionToken.isEmpty()) headers["x-amz-security-token"] = creds.sessionToken.toLower();
    headers["content-type"] = request.header(QNetworkRequest::ContentTypeHeader).toString().toLower();

    QString signedHeaders;
    for (auto it = headers.begin(); it != headers.end(); ++it) {
        canonicalRequest += it.key().toUtf8() + ":" + it.value().toUtf8() + "\n";
        if (!signedHeaders.isEmpty()) signedHeaders += ";";
        signedHeaders += it.key();
    }
    canonicalRequest += "\n" + signedHeaders.toUtf8() + "\n";
    canonicalRequest += hashSha256(payload).toHex();

    // 2. String to Sign
    QByteArray stringToSign;
    stringToSign += "AWS4-HMAC-SHA256\n";
    stringToSign += amzDate.toUtf8() + "\n";
    stringToSign += dateStr.toUtf8() + "/" + region.toUtf8() + "/" + service.toUtf8() + "/aws4_request\n";
    stringToSign += hashSha256(canonicalRequest).toHex();

    // 3. Signature
    QByteArray kDate = hmacSha256("AWS4" + creds.secretKey.toUtf8(), dateStr.toUtf8());
    QByteArray kRegion = hmacSha256(kDate, region.toUtf8());
    QByteArray kService = hmacSha256(kRegion, service.toUtf8());
    QByteArray kSigning = hmacSha256(kService, "aws4_request");
    QByteArray signature = hmacSha256(kSigning, stringToSign).toHex();

    QString authHeader = QStringLiteral("AWS4-HMAC-SHA256 Credential=%1/%2/%3/%4/aws4_request, SignedHeaders=%5, Signature=%6")
        .arg(creds.accessKey, dateStr, region, service, signedHeaders, QString::fromUtf8(signature));
    
    request.setRawHeader("Authorization", authHeader.toUtf8());
}

QByteArray AwsSigV4Signer::hmacSha256(const QByteArray &key, const QByteArray &data) {
    return QMessageAuthenticationCode::hash(data, key, QCryptographicHash::Sha256);
}

QByteArray AwsSigV4Signer::hashSha256(const QByteArray &data) {
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256);
}
