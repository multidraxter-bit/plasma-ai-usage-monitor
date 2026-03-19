# Implementation Plan: UX Polish, Demo Environment & KDE Store Release (v3.9.0)

## Objective
Deliver a refined user experience, implement a stable demo environment for high-quality screenshots, and officially submit the Plasma AI Usage Monitor widget to the KDE Store.

## 1. UX & Stability Polish

### 1.1 Fix Main Popup Orchestration
- **File:** `package/contents/ui/main.qml`
- **Action:** Refactor startup sequence and snapshot timers. Ensure timer triggers are stable and do not unnecessarily flicker or block the UI upon loading.
- **Verification:** Widget should open instantly from the panel without freezing or UI glitches, even with many providers enabled.

### 1.2 Improve Kirigami Theme Awareness
- **Files:** `package/contents/ui/FullRepresentation.qml`, `package/contents/ui/ProviderCard.qml`, `package/contents/ui/SubscriptionToolCard.qml`
- **Action:** Audit custom colors. Replace any hardcoded hex colors with `Kirigami.Theme` palette colors (e.g., `Kirigami.Theme.backgroundColor`, `Kirigami.Theme.textColor`, `Kirigami.Theme.highlightColor`) to ensure seamless transition between Plasma Dark and Light modes.
- **Verification:** Toggle between Breeze Light and Breeze Dark; all text and background elements must remain legible and stylistically appropriate.

### 1.3 Enhance Keyboard Accessibility
- **Action:** Add or verify `KeyNavigation` and `activeFocusOnTab: true` to primary interactive elements (tabs, provider cards, configure buttons).
- **Verification:** The user should be able to tab through the widget and interact using Space/Enter keys.

## 2. Demo Environment Setup

### 2.1 Create Mock API Server
- **File:** `scripts/demo/mock_server.py`
- **Action:** Create a lightweight Python HTTP server (e.g., using `http.server` or `Flask` in a `.venv`) that listens on `localhost:8080`.
- **Functionality:** Return static, deterministic JSON responses that mimic the actual payload structures from OpenAI, Anthropic, Google Gemini, and Subscription APIs. 

### 2.2 Add Demo Overrides to QML/C++
- **Action:** Expose a mechanism (e.g., an environment variable `PLASMA_AI_MONITOR_DEMO=1` or a config override) that forces the C++ provider backend to hit `http://localhost:8080` instead of the real production API endpoints.
- **Verification:** Start the mock server, run the widget with the demo flag, and verify it successfully displays the fake usage data without authentication errors.

## 3. Capture Store-Ready Screenshots

### 3.1 Setup Fedora KDE VM
- **Action:** Boot the Fedora 43 KDE testing VM. Start the mock server. Load the widget onto the Plasma Panel.
- **Verification:** Confirm the widget shows the deterministic mock data seamlessly.

### 3.2 Execute Screenshot Playbook
Capture the following standardized views using `Spectacle` or a window capture tool:
1. `assets/screenshots/main-window.png`: The fully expanded dashboard showing multiple active providers and aggregate costs.
2. `assets/screenshots/panel-view.png`: The compact view on the desktop panel.
3. `assets/screenshots/settings-view.png`: The configuration dialog showing the provider setup.
4. *Optional*: `assets/screenshots/history-view.png`: The history/compare analytics chart.

### 3.3 Update Documentation
- **Files:** `README.md`, `assets/screenshots/README.md`
- **Action:** Embed the new screenshots and add a small note regarding the Demo Mode for contributors.

## 4. KDE Store Submission Readiness

### 4.1 Update AppStream Metadata
- **File:** `com.github.loofi.aiusagemonitor.metainfo.xml`
- **Action:** Verify image `<screenshot>` URLs point correctly to the new `assets/screenshots/` paths on the `main` branch. Ensure the summary and description accurately reflect the features.

### 4.2 Build and Package
- **Action:** Run the packaging script `scripts/package_plasmoid.sh`. Ensure the output `.plasmoid` file is cleanly generated without errors.

### 4.3 Manual Publication Steps
1. Navigate to the KDE Store (store.kde.org).
2. Upload `com.github.loofi.aiusagemonitor.plasmoid`.
3. Upload the freshly generated screenshots.
4. Add the short description and highlight the fact that the compiled C++ plugin is required.
5. Publish the listing.

## Verification & Testing
- **UI:** Switch Plasma themes and verify QML components.
- **Mock Server:** Hit `http://localhost:8080/openai/v1/dashboard/billing/usage` locally and ensure the mock response is returned.
- **Metadata:** Run `appstreamcli validate com.github.loofi.aiusagemonitor.metainfo.xml`.