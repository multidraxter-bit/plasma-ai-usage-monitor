# Predictive Budgeting (Forecasting) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add spending projections to usage charts and budget bars using linear regression on historical data.

**Architecture:** A new `ForecastEngine` (C++) performs linear regression on recent usage history. QML components (`UsageChart`, `ProviderCard`) are updated to visualize these projections as dashed lines and "ghost" progress segments.

**Tech Stack:** C++20, Qt6 (QML), KF6.

---

### Task 1: ForecastEngine C++ Backend

**Files:**
- Create: `plugin/forecastengine.h`
- Create: `plugin/forecastengine.cpp`
- Modify: `plugin/CMakeLists.txt`

- [ ] **Step 1: Create ForecastEngine Header**

```cpp
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
     * Calculates a projected value at end-of-month based on 7 days of daily history.
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
```

- [ ] **Step 2: Create ForecastEngine Implementation**

```cpp
#include "forecastengine.h"
#include <QDate>
#include <cmath>
#include <QDebug>

ForecastEngine::ForecastEngine(QObject *parent) : QObject(parent) {}

double ForecastEngine::calculateMonthlyProjection(const QVariantList &history) const {
    if (history.size() < 2) return 0.0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = history.size();

    for (int i = 0; i < n; ++i) {
        double x = i;
        double y = history[i].toMap().value("cost").toDouble();
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
    }

    double denominator = (n * sumX2 - sumX * sumX);
    if (std::abs(denominator) < 1e-9) return sumY / n * 30; // fallback to average

    double slope = (n * sumXY - sumX * sumY) / denominator;
    double intercept = (sumY - slope * sumX) / n;

    QDate today = QDate::currentDate();
    int daysInMonth = today.daysInMonth();
    int dayOfMonth = today.day();
    int remainingDays = daysInMonth - dayOfMonth;

    // Last known value
    double lastValue = history.last().toMap().value("cost").toDouble();
    
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
    // ... simplified slope calculation ...
    return 0.0;
}
```

- [ ] **Step 3: Update CMakeLists.txt**

Add `forecastengine.cpp` and `forecastengine.h` to the source lists.

- [ ] **Step 4: Commit**

```bash
git add plugin/forecastengine.h plugin/forecastengine.cpp plugin/CMakeLists.txt
git commit -m "feat(intelligence): add ForecastEngine for linear regression"
```

---

### Task 2: QML Plugin Registration

**Files:**
- Modify: `plugin/aiusageplugin.cpp`

- [ ] **Step 1: Register ForecastEngine**

Add `qmlRegisterSingletonType<ForecastEngine>(uri, 1, 0, "ForecastEngine", [](QQmlEngine *, QJSEngine *) -> QObject * { return new ForecastEngine(); });`

- [ ] **Step 2: Commit**

```bash
git add plugin/aiusageplugin.cpp
git commit -m "feat(plugin): register ForecastEngine as QML singleton"
```

---

### Task 3: Visual Projection in UsageChart.qml

**Files:**
- Modify: `package/contents/ui/UsageChart.qml`

- [ ] **Step 1: Update onPaint to draw projection**

Calculate the projected points and draw them using a dashed line (`ctx.setLineDash([5, 5])`).

- [ ] **Step 2: Commit**

```bash
git add package/contents/ui/UsageChart.qml
git commit -m "feat(ui): draw dashed projection line in UsageChart"
```

---

### Task 4: Ghost Segments in ProviderCard.qml

**Files:**
- Modify: `package/contents/ui/ProviderCard.qml`

- [ ] **Step 1: Add Forecasted Segment to Progress Bars**

Update the progress bar implementation to include a second segment with lower opacity representing the forecasted month-end total.

- [ ] **Step 2: Commit**

```bash
git add package/contents/ui/ProviderCard.qml
git commit -m "feat(ui): add ghost forecast segments to budget progress bars"
```

---

### Task 5: Intelligence Engine Integration

**Files:**
- Modify: `plugin/intelligencebackend.cpp`

- [ ] **Step 1: Include Forecast in Prompt**

Update the system prompt to include the forecasted end-of-month values so Ollama can analyze them.

- [ ] **Step 2: Commit**

```bash
git add plugin/intelligencebackend.cpp
git commit -m "feat(intelligence): feed forecast data into LLM analysis"
```

---

### Task 6: Verification

- [ ] **Step 1: Build and Install**

Run: `just build && just install && just reload`

- [ ] **Step 2: Verify Charts**

Ensure dashed lines appear when there is historical data.

- [ ] **Step 3: Verify Budgets**

Check if progress bars show the projected "over-budget" warning segments.
