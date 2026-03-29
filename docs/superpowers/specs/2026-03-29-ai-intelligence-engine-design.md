# Design Specification: AI Intelligence Engine (Natural Language Insights)

**Date:** 2026-03-29
**Topic:** AI Intelligence Engine
**Status:** Approved

## 1. Objective
Deliver a new "Intelligence" layer to the Plasma AI Usage Monitor that provides natural language summaries, spending insights, and cost-saving recommendations powered by a local Ollama instance.

## 2. User Experience (UX)

### 2.1 Multi-Surface Presentation
Insights will be displayed in three complementary locations across the widget:
- **Top of Dashboard (Banner):** A dismissible high-priority alert card (e.g., "Insight: Spending up 30%").
- **Cost Summary Card (Snippet):** A single-line italicized trend summary (e.g., "Insight: Trending lower than last month").
- **Intelligence Tab (Deep Dive):** A dedicated new tab hosting the full detailed analysis and recommendations.

### 2.2 Trigger & Sync
- **On-Demand Generation:** Users trigger the analysis via a "Generate Insights" button in the Intelligence Tab.
- **Contextual Sync:** A single generation action updates all three display surfaces simultaneously to ensure a unified view of the data.
- **Progress Visibility:** The UI will show a loading state (e.g., "Analyzing patterns...") during the Ollama generation process.

## 3. Architecture & Implementation

### 3.1 Data Pipeline
1.  **Data Aggregator (C++):** Queries the `UsageDatabase` (SQLite) for the last 7 days of historical usage, including costs, models used, and request counts.
2.  **Prompt Generator:** Formats this history into a structured text prompt for the LLM.
3.  **Local LLM Integration:** Communicates with the local Ollama API (`http://localhost:11434/api/generate`) asynchronously using `QNetworkAccessManager`.
    -   **Default Model:** `qwen2.5:1.5b` (lightweight) or `llama3`.
4.  **Insight Parser:** Extracts the "Banner Alert", "Summary Snippet", and "Full Analysis" from the LLM response.

### 3.2 Component Breakdown
- **`IntelligenceTab.qml` (New):** The primary interface for triggering and reading full insights.
- **`InsightBanner.qml` (New):** The dismissible dashboard alert.
- **`IntelligenceBackend` (C++):** A new backend class to manage data aggregation and Ollama communication.
- **`plasmoid.configuration`:** Stores the last generated insight and timestamp to persist across restarts.

## 4. Technical Details

### 4.1 Prompt Engineering
The system prompt will instruct the model to:
- Be concise and actionable.
- Focus on cost-saving opportunities (e.g., "Switch to GPT-4o for standard tasks").
- Highlight unexpected spikes or deviations in spending patterns.

### 4.2 Error Handling
- **Ollama Offline:** Gracefully inform the user if the local Ollama server is not running or the model is not found.
- **Parsing Failures:** Fall back to displaying the raw LLM output if the structured extraction fails.

## 5. Success Criteria
- [ ] Users can trigger a 7-day usage analysis with a single click.
- [ ] Insights are visible in the dashboard banner, cost card, and intelligence tab.
- [ ] The process is asynchronous and does not block the Plasma UI.
- [ ] Insights persist across widget reloads/restarts.
