#include "groqprovider.h"

GroqProvider::GroqProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model
    setModel(QStringLiteral("llama-3.3-70b-versatile"));

    // Register model pricing ($ per 1M tokens) — Groq pricing as of 2026
    registerModelPricing(QStringLiteral("llama-3.3-70b-versatile"), 0.59, 0.79);
    registerModelPricing(QStringLiteral("gemma-4-31b-it"), 0.30, 0.30);
    registerModelPricing(QStringLiteral("llama-3.1-70b-versatile"), 0.59, 0.79);
    registerModelPricing(QStringLiteral("llama-3.1-8b-instant"), 0.05, 0.08);
    registerModelPricing(QStringLiteral("mixtral-8x7b-32768"), 0.24, 0.24);
    registerModelPricing(QStringLiteral("gemma2-9b-it"), 0.20, 0.20);
}
