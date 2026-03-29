# Design Spec: Dashboard UI Overhaul & Chrome Browser Sync

**Date:** 2026-03-29  
**Topic:** Grid-based dashboard modernization and multi-browser quota syncing  
**Status:** Approved (Design Phase)

## 1. Overview
This update aims to fulfill the "make all things look nice" goal by replacing the vertical list dashboard with a modern, card-based grid. It also expands "Browser Sync" to include Chrome/Chromium, allowing users who don't use Firefox to track their live AI quotas.

## 2. Technical Design

### 2.1 Dashboard UI Overhaul
**Location:** `package/contents/ui/FullRepresentation.qml`

*   **Responsive Grid:** Replace the `ColumnLayout` in the "Live" tab with a `Flow` or `GridLayout`.
    *   **Narrow View (Panel/Small Popup):** 1 column.
    *   **Wide View:** 2 columns.
*   **Unified Card Styling:** Update `ProviderCard.qml`, `SubscriptionToolCard.qml`, and `OllamaCard.qml` to share a consistent `implicitHeight` and background style.
*   **Visual Hierarchy:**
    *   **Summary Box:** Remains at the top (full width).
    *   **Action Row:** Add a global "Refresh All / Sync All" floating action button or clearer header buttons.

### 2.2 Chrome/Chromium Browser Sync
**Location:** `plugin/browsercookieextractor.cpp`

*   **Directory Detection:** Add detection for:
    *   Chrome: `~/.config/google-chrome/Default/Cookies`
    *   Brave: `~/.config/BraveSoftware/Brave-Browser/Default/Cookies`
    *   Edge: `~/.config/microsoft-edge/Default/Cookies`
*   **Cookie Extraction:**
    *   Implement the SQL query logic for the Chromium `cookies` table (different schema than Firefox).
    *   **Encryption Note:** Chromium cookies on Linux are typically encrypted via AES-256-GCM using a key from the system keyring.
    *   **Phase 1:** Implement "Detection & Unencrypted Read" (works for some Chromium forks and dev environments).
    *   **Phase 2:** Provide a clear error message/guide if the cookie is encrypted, rather than just saying "Unsupported Browser".

## 3. Data Flow
1.  `FullRepresentation.qml` calculates the available width and sets the grid column count.
2.  `BrowserCookieExtractor` attempts to locate the Chrome cookie database based on the user's configuration.
3.  If found, `ClaudeCodeMonitor` and `CodexCliMonitor` use the Chrome-extracted headers for their periodic quota syncs.

## 4. Testing & Validation
*   **UI Resize Test:** Drag the popup width and verify the grid snaps between 1 and 2 columns correctly.
*   **Card Consistency:** Verify that an Ollama card and an OpenAI card have the same visual weight and padding.
*   **Chrome Detection:** Select "Chrome" in settings and verify the "Connected" status (or specific encryption error) appears in the diagnostic log.

## 5. Deployment
1.  Update `FullRepresentation.qml` layout structure.
2.  Refactor QML cards for style parity.
3.  Implement Chrome path detection in `BrowserCookieExtractor`.
4.  Update `main.xml` to allow selecting Chrome/Chromium/Brave as the sync source.
