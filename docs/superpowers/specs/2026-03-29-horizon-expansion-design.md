# Design Specification: Horizon Expansion (AWS Bedrock, Forecasting & JetBrains)

**Date:** 2026-03-29
**Topic:** AWS Bedrock, Predictive Budgeting, and JetBrains AI Assistant
**Status:** Approved

## 1. Objective
Expand the Plasma AI Usage Monitor's reach and intelligence by adding a major cloud provider (AWS Bedrock), predictive spending visualization (Forecasting), and completing the IDE tracking suite (JetBrains AI Assistant).

## 2. AWS Bedrock Provider (Sub-Project 1)

### 2.1 Backend Architecture
- **Class:** `BedrockProvider` (C++)
- **Authentication:** Supports AWS profiles from `~/.aws/credentials` or manual Access Key/Secret entry (stored in KWallet).
- **Communication:** Implements a lightweight AWS SigV4 signer in C++.
- **Data Source:** Polls the AWS CloudWatch Metrics API for `InputTokenCount` and `OutputTokenCount`.
- **Cost Calculation:** Local estimation using a built-in JSON lookup table for major Bedrock model IDs (Claude 3.5, Llama 3.1, etc.).

### 2.2 UI Integration
- **Card:** Standard provider card with a "Region" badge (e.g., "us-east-1").
- **Settings:** Adds AWS configuration fields (Access Key, Secret, Region, Profile) to the provider setup page.

## 3. Predictive Budgeting & Forecasting (Sub-Project 2)

### 3.1 Intelligence Engine
- **Logic:** Uses linear regression on the last 7 days of daily spending history to project costs to the end of the current month.
- **Update Frequency:** Recalculated whenever new history snapshots are recorded.

### 3.2 Visual Integration
- **Usage Charts:** Adds dashed "projection" polylines to `UsageChart.qml` extending from the current timestamp to the end of the month.
- **Budget Health:** Progress bars will include a "ghost" or "outline" segment representing the forecasted total against the budget limit.
- **Intelligence Tab:** The Intelligence Engine will explain the forecast (e.g., "Spending is trending 15% higher than last week").

## 4. JetBrains AI Assistant Support (Sub-Project 3)

### 4.1 Backend Architecture
- **Class:** `JetBrainsMonitor` (C++)
- **Data Source:** Monitors local JetBrains configuration/cache directories (e.g., `~/.config/JetBrains/`) for usage telemetry or log files.
- **Quota Model:** Supports "Individual" and "Enterprise" plan presets with monthly request limits.

### 4.2 UI Integration
- **Card:** Standard subscription tool card with JetBrains branding.
- **Cost Summary:** Automatically includes the $10/mo (Individual) or $15/mo (Enterprise) cost in the monthly aggregate spending.

## 5. Technical Details

### 5.1 C++ Implementation
- All new backends will follow the established `ProviderBackend` and `SubscriptionToolBackend` interfaces.
- Non-blocking network requests using `QNetworkAccessManager`.

### 5.2 Persistence
- Forecast data and tool state will be persisted in `plasmoid.configuration` or the SQLite database where appropriate.

## 6. Success Criteria
- [ ] AWS Bedrock usage is tracked and costs estimated accurately.
- [ ] Users can see dashed projection lines on usage charts.
- [ ] JetBrains AI Assistant usage is tracked via local filesystem monitoring.
- [ ] No regression in performance or UI responsiveness.
