# Design Spec: The Analyst (v5.0.0) — Intelligence & Deep Visualization

**Status:** Draft
**Date:** 2026-04-01
**Target Version:** v5.0.0 "Lighthouse"
**Codename:** The Analyst

## 1. Executive Summary
"The Analyst" transforms the Plasma AI Usage Monitor from a passive tracking tool into a deep visualization and efficiency advisor. Building on the v4.3.0 foundation, it introduces a dedicated "Analyst" tab featuring a GitHub-style activity heatmap, long-term trend analysis, and a new "Prompt Efficiency" metric (Output/Input token ratio).

## 2. Goals & Success Criteria
- **Deep Visibility:** Users can see an entire year of activity in a single view.
- **Efficiency Insights:** Users can measure if their prompts are becoming more concise relative to generation.
- **Actionable Data:** Use the local Ollama engine to explain spending and activity patterns.
- **Performance:** Ensure the heatmap and efficiency charts load instantly without blocking the UI.

## 3. Architecture & Data Flow

### 3.1 Data Aggregation (C++ Backend)
The `UsageDatabase` class will be extended with high-performance aggregation methods:
- `getYearlyActivity(int mode)`: Returns a JSON-mapped list of 365 daily buckets containing `date`, `cost`, `tokens`, and `requests`.
- `getEfficiencySeries(int days)`: Returns a series of daily `output_tokens / input_tokens` ratios.

### 3.2 State Management (QML)
- `analystIntensityMode`: A persistent configuration setting (0 = Cost, 1 = Volume/Tokens).
- `analystNormalization`: A setting to enable/disable outlier clamping in the heatmap color scale.

## 4. Components & UI Layout

### 4.1 The "Analyst" Tab (`AnalystTab.qml`)
A new top-level navigation tab alongside Live, History, and Intelligence.
- **KPI Summary Row:** Large status tiles for "Activity Score" and "Avg. Efficiency."
- **Activity Heatmap:** A 52x7 grid drawn via `QQuickCanvas2D`.
    - **Color Scale:** 5-step theme-aware palette (e.g., Kirigami.Theme.highlightColor with varying opacity).
    - **Interactivity:** Hover for date/stat tooltips; click to drill down into the weekly efficiency chart.
- **Efficiency Trends Chart:** A specialized line chart showing the `Output/Input` ratio over 30 days.

### 4.2 Intelligence Integration
- **Context:** Feeds the last 7-14 days of heatmap and efficiency data to the local Ollama server.
- **Insights:** Generates natural language summaries of weekly efficiency gains/losses and spending spikes.

## 5. Technical Constraints & Out of Scope
- **Non-Token Providers:** For providers that don't report tokens (e.g., Google Gemini in some modes), we will use a fallback "estimated" ratio or mark them as "N/A" in the efficiency view.
- **Headless Mode:** The heatmap requires a running Plasma session for QML rendering; it will not be available in the CLI companion.

## 6. Implementation Phases
1. **Phase 1 (Database):** Add C++ aggregation methods to `UsageDatabase`.
2. **Phase 2 (Visuals):** Implement the `ActivityHeatmap.qml` Canvas component.
3. **Phase 3 (Metrics):** Implement the Efficiency Ratio calculation and `EfficiencyMetricCard.qml`.
4. **Phase 4 (Intelligence):** Wire the analyst data into the existing Ollama Intelligence Engine.
5. **Phase 5 (Polish):** Theme awareness, responsiveness, and final accessibility audit.

## 7. Verification Plan
- **Data Integrity:** Compare heatmap daily totals against raw SQLite history records.
- **Performance:** Verify <100ms load time for the Analyst tab with 365 days of data.
- **Theming:** Test in both Breeze Light and Breeze Dark themes.
- **Intelligence:** Ensure Ollama insights correctly reference specific heatmap spikes.
