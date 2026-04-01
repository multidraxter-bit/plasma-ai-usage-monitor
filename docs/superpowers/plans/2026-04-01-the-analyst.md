# The Analyst (v5.0.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the Plasma AI Usage Monitor into an intelligent advisor with deep visualization (Heatmap) and efficiency metrics.

**Architecture:** 
- **Backend:** Enhance `UsageDatabase` with high-performance aggregation methods in C++.
- **Frontend:** Add a new "Analyst" tab featuring a custom Canvas-based activity heatmap and efficiency charts in QML.
- **Intelligence:** Feed aggregated data to the local Ollama engine for natural language insights.

**Tech Stack:** C++, Qt 6, QML (Kirigami), SQLite.

---

### Task 1: Database Aggregation (C++ Backend)

**Files:**
- Modify: `plugin/usagedatabase.h`
- Modify: `plugin/usagedatabase.cpp`
- Test: `plugin/tests/test_usagedatabase.cpp`

- [ ] **Step 1: Write the failing tests for aggregation**
Add tests to verify the new aggregation methods return expected JSON structures for a range of dates.

```cpp
// plugin/tests/test_usagedatabase.cpp
void TestUsageDatabase::testGetYearlyActivity() {
    UsageDatabase db;
    db.init(":memory:");
    // Seed some data...
    QVariantMap result = db.getYearlyActivity(0 /* Cost mode */);
    QVERIFY(!result.isEmpty());
    QVERIFY(result.contains("maxIntensity"));
    QVERIFY(result.contains("days"));
}

void TestUsageDatabase::testGetEfficiencySeries() {
    UsageDatabase db;
    db.init(":memory:");
    // Seed some data with varying input/output tokens...
    QVariantList series = db.getEfficiencySeries(30);
    QVERIFY(series.size() <= 30);
}
```

- [ ] **Step 2: Run tests to verify they fail to compile**
Run: `cmake --build build --target test`
Expected: FAIL (methods not defined).

- [ ] **Step 3: Define the aggregation methods in `usagedatabase.h`**

```cpp
// plugin/usagedatabase.h
public:
    Q_INVOKABLE QVariantMap getYearlyActivity(int mode);
    Q_INVOKABLE QVariantList getEfficiencySeries(int days);
```

- [ ] **Step 4: Implement the aggregation methods in `usagedatabase.cpp`**
Implement the SQL queries to aggregate daily costs and token ratios.

```cpp
// plugin/usagedatabase.cpp
QVariantMap UsageDatabase::getYearlyActivity(int mode) {
    QVariantMap result;
    QVariantList days;
    double maxIntensity = 0.0;
    
    // SQL: SELECT date(timestamp, 'unixepoch') as day, sum(cost) as cost, sum(input_tokens + output_tokens) as tokens 
    // FROM usage_history GROUP BY day ORDER BY day DESC LIMIT 365
    // Calculate maxIntensity for normalization.
    
    result["maxIntensity"] = maxIntensity;
    result["days"] = days;
    return result;
}

QVariantList UsageDatabase::getEfficiencySeries(int daysCount) {
    QVariantList series;
    // SQL: SELECT date(timestamp, 'unixepoch') as day, sum(input_tokens) as input, sum(output_tokens) as output
    // FROM usage_history GROUP BY day ORDER BY day DESC LIMIT daysCount
    // Each entry: { "date": "...", "ratio": output/input }
    return series;
}
```

- [ ] **Step 5: Run tests to verify they pass**
Run: `cmake --build build --target test`
Expected: PASS.

- [ ] **Step 6: Commit**
```bash
git add plugin/usagedatabase.* plugin/tests/test_usagedatabase.cpp
git commit -m "feat(db): add yearly activity and efficiency series aggregation"
```

---

### Task 2: Activity Heatmap Component (QML)

**Files:**
- Create: `package/contents/ui/ActivityHeatmap.qml`
- Modify: `plugin/aiusageplugin.cpp` (if needed for registration)

- [ ] **Step 1: Create the Heatmap Canvas component**
Implement the 52x7 grid drawing logic using QML Canvas.

```qml
// package/contents/ui/ActivityHeatmap.qml
import QtQuick
import org.kde.kirigami as Kirigami

Canvas {
    id: heatmap
    property var activityData: []
    property double maxIntensity: 1.0
    property color baseColor: Kirigami.Theme.highlightColor

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        // Draw 52x7 grid...
        // Color = baseColor with alpha = (intensity / maxIntensity)
    }
}
```

- [ ] **Step 2: Add interactivity (Tooltips)**
Implement hover detection to show specific day stats.

```qml
// package/contents/ui/ActivityHeatmap.qml
MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onPositionChanged: {
        // Calculate week/day from mouse position...
        // Trigger tooltip display.
    }
}
```

- [ ] **Step 3: Commit**
```bash
git add package/contents/ui/ActivityHeatmap.qml
git commit -m "feat(ui): add ActivityHeatmap component"
```

---

### Task 3: Efficiency Metrics UI

**Files:**
- Create: `package/contents/ui/EfficiencyMetricCard.qml`

- [ ] **Step 1: Implement the Efficiency Card**
Display the current ratio and a specialized trend chart.

```qml
// package/contents/ui/EfficiencyMetricCard.qml
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.Card {
    property double efficiencyRatio: 1.0
    
    contentItem: ColumnLayout {
        Label { text: "Prompt Efficiency"; font.bold: true }
        Label { 
            text: efficiencyRatio.toFixed(2) + "x"
            font.pointSize: 24
            color: efficiencyRatio > 1.2 ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.textColor
        }
        // Small trend chart placeholder...
    }
}
```

- [ ] **Step 2: Commit**
```bash
git add package/contents/ui/EfficiencyMetricCard.qml
git commit -m "feat(ui): add EfficiencyMetricCard"
```

---

### Task 4: Analyst Tab Integration

**Files:**
- Create: `package/contents/ui/AnalystTab.qml`
- Modify: `package/contents/ui/FullRepresentation.qml`

- [ ] **Step 1: Create the Analyst Tab view**
Assemble the header KPIs, Heatmap, and Efficiency card.

```qml
// package/contents/ui/AnalystTab.qml
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.largeSpacing
    
    RowLayout {
        EfficiencyMetricCard { efficiencyRatio: 1.45 }
        // Another KPI tile for Activity Score
    }
    
    ActivityHeatmap { 
        Layout.fillWidth: true
        height: 150
    }
}
```

- [ ] **Step 2: Integrate into the main popup**
Add the "Analyst" tab to the `TabBar` or `NavigationTabBar`.

```qml
// package/contents/ui/FullRepresentation.qml
Kirigami.NavigationTabBar {
    // ...
    Kirigami.NavigationTab {
        icon: "view-statistics"
        title: "Analyst"
        page: AnalystTab {}
    }
}
```

- [ ] **Step 3: Commit**
```bash
git add package/contents/ui/AnalystTab.qml package/contents/ui/FullRepresentation.qml
git commit -m "feat(ui): integrate Analyst tab into main representation"
```

---

### Task 5: Intelligence Engine Integration

**Files:**
- Modify: `plugin/claudecodemonitor.cpp` (or relevant intelligence engine controller)
- Modify: `package/contents/ui/main.qml`

- [ ] **Step 1: Feed Analyst data to Ollama**
When the Analyst tab is opened, trigger a new intelligence summary using aggregated heatmap/efficiency data.

```cpp
// Logic to inject:
// "Analyze this efficiency trend: Last 7 days ratios: [1.2, 1.4, 0.9...]"
```

- [ ] **Step 2: Commit**
```bash
git commit -m "feat(intelligence): connect analyst data to Ollama engine"
```

---

### Task 6: Final Polish & Verification

**Files:**
- Modify: `package/contents/ui/ActivityHeatmap.qml`
- Modify: `package/metadata.json` (version bump)

- [ ] **Step 1: Verify Theme Awareness**
Switch Plasma themes and ensure the heatmap colors update correctly.

- [ ] **Step 2: Bump version to v5.0.0**
```json
// package/metadata.json
"Version": "5.0.0"
```

- [ ] **Step 3: Final verification run**
Run the widget, open the Analyst tab, and verify all visual components render correctly.

- [ ] **Step 4: Commit**
```bash
git commit -am "chore: finalize v5.0.0 'The Analyst' release"
```
