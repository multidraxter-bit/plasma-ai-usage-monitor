# Design Spec: Ollama Local LLM Monitoring

**Date:** 2026-03-29  
**Topic:** Real-time monitoring of local Ollama server status and resource usage  
**Status:** Approved (Design Phase)

## 1. Overview
This feature integrates **Ollama** into the AI Usage Monitor. Since Ollama runs locally, the focus is on server availability, loaded models, and memory (VRAM/RAM) consumption rather than API costs.

## 2. Technical Design

### 2.1 Backend Provider
**New Class:** `OllamaProvider` (inheriting from `ProviderBackend`)

*   **Server Endpoint:** `http://localhost:11434/api/ps`
*   **Polling Logic:** Poll every 30 seconds while the dashboard is open.
*   **Data Fields:**
    *   `status`: Online/Offline.
    *   `models`: Array of objects containing `name`, `size`, `vram_size`, and `expires_at`.
    *   `totalMemory`: Total bytes used by all loaded models.
    *   `vramMemory`: Bytes used in GPU VRAM.
*   **Cost Metrics:** All cost properties (`dailyCost`, `monthlyCost`, etc.) will return `0.0` to ensure local usage does not skew billing summaries.

### 2.2 UI Implementation
**Location:** `package/contents/ui/OllamaCard.qml` (New Component)

*   **Header:** Standard `ProviderCard` style with the Ollama logo and an "Online/Offline" status badge.
*   **Active Models:** A list showing currently loaded models. If no models are loaded, show "Idle (No models in memory)".
*   **Resource Usage:**
    *   A progress bar or gauge showing total memory usage.
    *   Text labels for "VRAM" vs "System RAM" split.
*   **Dashboard Integration:** Add `OllamaCard` to the "Live" tab when enabled.

### 2.3 Configuration
**Location:** `package/contents/config/main.xml`

*   `ollamaEnabled`: Boolean (default: `false`)
*   `ollamaServerUrl`: String (default: `http://localhost:11434`)
*   `ollamaRefreshInterval`: Int (default: `30`)

## 3. Data Flow
1.  `OllamaProvider` issues an async GET request to the `/api/ps` endpoint.
2.  On success, it parses the JSON response to update the `models` list and calculate memory totals.
3.  On failure (e.g., connection refused), it sets status to "Offline".
4.  QML bindings automatically update the `OllamaCard` UI and the "Providers" connection status in the summary grid.

## 4. Testing & Validation
*   **Connectivity Test:** Verify the card shows "Offline" when Ollama is stopped and "Online" when it starts.
*   **Model Detection Test:** Run `ollama run llama3`, then verify the model appears in the widget's active list.
*   **Memory Test:** Verify the memory usage values match the output of the `ollama ps` command.

## 5. Deployment
1.  Implement `OllamaProvider` C++ class.
2.  Register the type in `plugin.cpp`.
3.  Add configuration entries to `main.xml`.
4.  Create `OllamaCard.qml` and wire it into `FullRepresentation.qml`.
