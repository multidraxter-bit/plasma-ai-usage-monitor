#ifndef OLLAMAPROVIDER_H
#define OLLAMAPROVIDER_H

#include "providerbackend.h"
#include <QVariantList>

/**
 * Ollama provider backend.
 * 
 * Polls http://localhost:11434/api/ps to list active models and memory usage.
 * This provider tracks local VRAM and system memory used by active models.
 */
class OllamaProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QVariantList activeModels READ activeModels NOTIFY activeModelsChanged)
    Q_PROPERTY(double totalMemory READ totalMemory NOTIFY totalMemoryChanged)
    Q_PROPERTY(double vramMemory READ vramMemory NOTIFY vramMemoryChanged)

public:
    explicit OllamaProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("Ollama"); }
    QString iconName() const override { return QStringLiteral("server"); }

    QVariantList activeModels() const { return m_activeModels; }
    double totalMemory() const { return m_totalMemory; }
    double vramMemory() const { return m_vramMemory; }

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void activeModelsChanged();
    void totalMemoryChanged();
    void vramMemoryChanged();

private Q_SLOTS:
    void onPsReply(QNetworkReply *reply);

private:
    QVariantList m_activeModels;
    double m_totalMemory = 0.0;
    double m_vramMemory = 0.0;
};

#endif // OLLAMAPROVIDER_H
