#include "forecastengine.h"
#include <QDate>
#include <cmath>
#include <QDebug>
#include <QVariantMap>

ForecastEngine::ForecastEngine(QObject *parent) : QObject(parent) {}

double ForecastEngine::calculateMonthlyProjection(const QVariantList &history) const {
    if (history.size() < 2) return 0.0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = history.size();

    for (int i = 0; i < n; ++i) {
        double x = i;
        double y = history[i].toMap().value("cost").toDouble();
        if (y == 0) y = history[i].toMap().value("totalCost").toDouble();
        
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
    }

    double denominator = (n * sumX2 - sumX * sumX);
    if (std::abs(denominator) < 1e-9) return sumY; // fallback to current sum

    double slope = (n * sumXY - sumX * sumY) / denominator;
    double intercept = (sumY - slope * sumX) / n;

    QDate today = QDate::currentDate();
    int daysInMonth = today.daysInMonth();
    int dayOfMonth = today.day();
    int remainingDays = daysInMonth - dayOfMonth;

    // Last known value
    double lastValue = history.last().toMap().value("cost").toDouble();
    if (lastValue == 0) lastValue = history.last().toMap().value("totalCost").toDouble();
    
    // Simple linear projection for remaining days
    double projectedAdditional = 0;
    for (int d = 1; d <= remainingDays; ++d) {
        double val = slope * (n - 1 + d) + intercept;
        projectedAdditional += std::max(0.0, val);
    }

    return lastValue + projectedAdditional;
}

double ForecastEngine::calculateTrendSlope(const QVariantList &history) const {
    if (history.size() < 2) return 0.0;
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = history.size();

    for (int i = 0; i < n; ++i) {
        double x = i;
        double y = history[i].toMap().value("cost").toDouble();
        if (y == 0) y = history[i].toMap().value("totalCost").toDouble();
        
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
    }

    double denominator = (n * sumX2 - sumX * sumX);
    if (std::abs(denominator) < 1e-9) return 0.0;

    return (n * sumXY - sumX * sumY) / denominator;
}
