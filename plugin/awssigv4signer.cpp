#include "awssigv4signer.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QMessageAuthenticationCode>

#include <algorithm>

namespace {
QByteArray toLowerTrimmed(const QByteArray &value)
{
    QByteArray normalized = value.trimmed().toLower();
    while (normalized.contains("  ")) {
        normalized.replace("  ", " ");
    }
    return normalized;
}
}

AwsSigV4Signer::SignedHeaders AwsSigV4Signer::sign(
    const QString &accessKeyId,
    const QString &secretAccessKey,
    const QString &sessionToken,
    const QString &region,
    const QString &service,
    const QString &method,
    const QString &canonicalUri,
    const QString &canonicalQueryString,
    const QList<QPair<QByteArray, QByteArray>> &headers,
    const QByteArray &payload,
    const QDateTime &timestampUtc)
{
    SignedHeaders signedHeaders;
    signedHeaders.payloadHash = sha256Hex(payload);
    signedHeaders.amzDate = timestampUtc.toUTC().toString(QStringLiteral("yyyyMMdd'T'HHmmss'Z'")).toUtf8();
    const QString shortDate = timestampUtc.toUTC().toString(QStringLiteral("yyyyMMdd"));

    const auto normalized = normalizedHeaders(headers, signedHeaders.amzDate,
                                              signedHeaders.payloadHash, sessionToken);
    signedHeaders.headers = normalized;

    QList<QByteArray> headerNames;
    QByteArray canonicalHeaders;
    for (const auto &header : normalized) {
        headerNames.append(header.first);
        canonicalHeaders += header.first + ":" + header.second + "\n";
    }

    std::sort(headerNames.begin(), headerNames.end());
    std::sort(signedHeaders.headers.begin(), signedHeaders.headers.end(),
              [](const auto &lhs, const auto &rhs) {
                  return lhs.first < rhs.first;
              });

    const QByteArray signedHeaderNames = headerNames.join(";");
    const QByteArray canonicalRequest = method.toUtf8().toUpper()
        + "\n"
        + canonicalUri.toUtf8()
        + "\n"
        + canonicalQueryString.toUtf8()
        + "\n"
        + canonicalHeaders
        + "\n"
        + signedHeaderNames
        + "\n"
        + signedHeaders.payloadHash;

    const QByteArray scope = shortDate.toUtf8() + "/" + region.toUtf8() + "/"
        + service.toUtf8() + "/aws4_request";
    const QByteArray stringToSign = QByteArrayLiteral("AWS4-HMAC-SHA256\n")
        + signedHeaders.amzDate + "\n"
        + scope + "\n"
        + sha256Hex(canonicalRequest);

    const QByteArray signature = hmacSha256(signingKey(secretAccessKey, shortDate, region, service),
                                            stringToSign).toHex();

    signedHeaders.authorizationHeader =
        "AWS4-HMAC-SHA256 Credential=" + accessKeyId.toUtf8() + "/" + scope
        + ", SignedHeaders=" + signedHeaderNames
        + ", Signature=" + signature;

    return signedHeaders;
}

QByteArray AwsSigV4Signer::sha256Hex(const QByteArray &data)
{
    return QCryptographicHash::hash(data, QCryptographicHash::Sha256).toHex();
}

QByteArray AwsSigV4Signer::hmacSha256(const QByteArray &key, const QByteArray &message)
{
    return QMessageAuthenticationCode::hash(message, key, QCryptographicHash::Sha256);
}

QByteArray AwsSigV4Signer::signingKey(const QString &secretAccessKey,
                                      const QString &date,
                                      const QString &region,
                                      const QString &service)
{
    const QByteArray kDate = hmacSha256("AWS4" + secretAccessKey.toUtf8(), date.toUtf8());
    const QByteArray kRegion = hmacSha256(kDate, region.toUtf8());
    const QByteArray kService = hmacSha256(kRegion, service.toUtf8());
    return hmacSha256(kService, QByteArrayLiteral("aws4_request"));
}

QList<QPair<QByteArray, QByteArray>> AwsSigV4Signer::normalizedHeaders(
    const QList<QPair<QByteArray, QByteArray>> &headers,
    const QByteArray &amzDate,
    const QByteArray &payloadHash,
    const QString &sessionToken)
{
    QList<QPair<QByteArray, QByteArray>> normalized;
    normalized.reserve(headers.size() + 3);

    for (const auto &header : headers) {
        normalized.append({toLowerTrimmed(header.first), toLowerTrimmed(header.second)});
    }

    normalized.append({QByteArrayLiteral("x-amz-date"), amzDate});
    normalized.append({QByteArrayLiteral("x-amz-content-sha256"), payloadHash});
    if (!sessionToken.isEmpty()) {
        normalized.append({QByteArrayLiteral("x-amz-security-token"), sessionToken.toUtf8()});
    }

    std::sort(normalized.begin(), normalized.end(),
              [](const auto &lhs, const auto &rhs) {
                  return lhs.first < rhs.first;
              });
    return normalized;
}
