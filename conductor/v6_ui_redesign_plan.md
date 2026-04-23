# v6.0.0 UI Redesign Implementation Plan

## Objective
Design and implement a UI redesign for v6.0.0 of the KDE Plasma 6 widget. Focus on a cleaner, premium, operator-friendly Kirigami/Plasma experience without changing the backend architecture.

## Phase 1: Visual Language & Foundation
- Establish a consistent card grammar and spacing system across the app using `Kirigami.Units`.
- Refine the use of `Kirigami.Theme` roles (e.g., `backgroundColor`, `highlightColor`, `textColor`, `positiveTextColor`, `negativeTextColor`) to ensure excellent contrast in both light and dark modes.
- Ensure all interactive elements have `KeyNavigation` and proper `Accessible` roles.

## Phase 2: Live View & Dashboard Layout
- **Files**: `FullRepresentation.qml`, `main.qml`
- **Actions**:
  - Reorganize the Live view into a clear vertical hierarchy: Top Summary / Health Strip -> "Needs Attention" -> High-value Rollup Cards -> Providers -> Subscription Tools.
  - Reduce visual duplication between summary chips and card headers.
  - Make healthy states quieter and warning/error states more visually intentional.

## Phase 3: Card Redesign
- **Files**: `ProviderCard.qml`, `SubscriptionToolCard.qml`, `CostSummaryCard.qml`
- **Actions**:
  - Update `ProviderCard.qml` grouping: header identity, connection status, metrics, budgets, rate limits, and last refresh. Improve narrow width rendering.
  - Update `SubscriptionToolCard.qml` to align with the visual system of `ProviderCard`. Improve the display of plan status, usage bars, resets, and sync state.
  - Clean up `CostSummaryCard.qml` to feel more integrated into the dashboard.

## Phase 4: History & Analyst Views
- **Files**: `AnalystTab.qml` (if exists), `MultiSeriesChart.qml`, `UsageChart.qml`, `TrendSummary.qml`
- **Actions**:
  - Refine history control layouts to remove the "toolbar dump" feel.
  - Improve the visual design of charts and ranking panels to look more intentional.
  - Enhance empty, loading, and no-data states.
  - Ensure the compare mode feels like a first-class view.

## Phase 5: Onboarding & Config Screens
- **Files**: `SetupWizard.qml` (if exists) / `FullRepresentation.qml`, `configGeneral.qml`, `configProviders.qml`, `configAlerts.qml`, `configBudget.qml`, `configSubscriptions.qml`, `configHistory.qml`
- **Actions**:
  - Polish the first-run zero-state.
  - Bring all KCM config screens up to the new v6 visual language, improving field grouping and visual clarity.

## Phase 6: Validation & Documentation
- Build and test locally using `cmake -B build && cmake --build build` and `cmake --build build --target test`.
- Verify light/dark theme correctness, accessibility, and narrow popup responsiveness.
- Update `CHANGELOG.md`, `README.md`, and capture new screenshots for `assets/screenshots/`.
