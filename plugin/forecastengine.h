#ifndef FORECASTENGINE_H
#define FORECASTENGINE_H

#include <QObject>
#include <QDateTime>
#include <QVariantList>

class ForecastEngine : public QObject
{
    Q_OBJECT
public:
    explicit ForecastEngine(QObject *parent = nullptr);

    /**
     * Calculates a projected value at end-of-month based on history.
     * @param history  List of QVariantMap with 'date' and 'totalCost' (or other metric)
     * @return The projected total at the end of the month.
     */
    Q_INVOKABLE double calculateMonthlyProjection(const QVariantList &history) const;

    /**
     * Calculates the slope (trend) of the usage.
     */
    Q_INVOKABLE double calculateTrendSlope(const QVariantList &history) const;
};

#endif
