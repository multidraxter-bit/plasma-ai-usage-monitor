#include "ollamacloudprovider.h"

OllamaCloudProvider::OllamaCloudProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Ollama's OpenAI-compatible cloud API accepts standard model names.
    setModel(QStringLiteral("gpt-oss:120b"));
}
