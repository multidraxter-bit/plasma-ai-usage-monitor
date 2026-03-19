#pragma once
#include "providerbackend.h"

/**
 * Provider backend for a self-hosted Loofi AI server.
 *
 * Polls GET /api/v2/metrics-summary and surfaces:
 *   - active model name
 *   - training stage
 *   - GPU memory %
 *   - 24-hour inference count (mapped to requestCount)
 *
 * Configuration (via environment variables):
 *   LOOFI_SERVER_URL   – base URL of the server  (default: http://127.0.0.1:3000)
 *   LOOFI_SERVER_TOKEN – Bearer token for auth    (default: empty / no auth)
 */
class LoofiServerProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model         READ activeModel   NOTIFY serverDataUpdated)
    Q_PROPERTY(QString activeModel   READ activeModel   NOTIFY serverDataUpdated)
    Q_PROPERTY(QString trainingStage READ trainingStage NOTIFY serverDataUpdated)
    Q_PROPERTY(double  gpuMemoryPct  READ gpuMemoryPct  NOTIFY serverDataUpdated)

public:
    explicit LoofiServerProvider(QObject *parent = nullptr);

    // ProviderBackend interface
    QString name()     const override { return QStringLiteral("Loofi Server"); }
    QString iconName() const override { return QStringLiteral("computer"); }

    Q_INVOKABLE void refresh() override;

    // Extra properties exposed to QML
    QString activeModel()   const { return m_activeModel; }
    QString trainingStage() const { return m_trainingStage; }
    double  gpuMemoryPct()  const { return m_gpuMemoryPct; }

Q_SIGNALS:
    void serverDataUpdated();

private:
    QString serverUrl() const;

    QString m_activeModel;
    QString m_trainingStage;
    double  m_gpuMemoryPct = -1.0;
};
