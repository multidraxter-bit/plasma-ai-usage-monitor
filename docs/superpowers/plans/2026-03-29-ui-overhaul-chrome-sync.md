# Dashboard UI Overhaul & Chrome Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize the dashboard with a responsive grid layout and expand browser sync support to Chrome/Chromium.

**Architecture:** Refactor `FullRepresentation.qml` to use `GridLayout` for responsive cards. Update `BrowserCookieExtractor.cpp` to support Chromium cookie database schemas.

**Tech Stack:** C++20, Qt6 (SQL, Network), QML, Kirigami

---

### Task 1: Chrome/Chromium Sync Backend (C++)

**Files:**
- Modify: `plugin/browsercookieextractor.h`
- Modify: `plugin/browsercookieextractor.cpp`

- [ ] **Step 1: Update BrowserCookieExtractor header**
Add support for Brave and Edge types.

```cpp
enum BrowserType {
    Firefox = 0,
    Chrome = 1,
    Chromium = 2,
    Brave = 3,
    Edge = 4
};
```

- [ ] **Step 2: Implement Chromium path detection**
Update `cookieDbPath()` and add helpers for Brave/Edge paths in `browsercookieextractor.cpp`.

- [ ] **Step 3: Implement Chromium cookie reading**
Implement `readChromiumCookies(const QString &domain)` using the Chromium schema (`cookies` table instead of `moz_cookies`). Note: Use a `QTemporaryFile` for the snapshot just like Firefox.

- [ ] **Step 4: Commit**
```bash
git add plugin/browsercookieextractor.*
git commit -m "feat(cpp): support Chrome/Chromium cookie extraction"
```

### Task 2: Dashboard Grid Refactor (QML)

**Files:**
- Modify: `package/contents/ui/FullRepresentation.qml`

- [ ] **Step 1: Replace liveColumn ColumnLayout with GridLayout**
Update the "Live" tab container to use a `GridLayout` that adjusts its `columns` property based on the popup width.

```qml
// In FullRepresentation.qml
GridLayout {
    id: cardsGrid
    Layout.fillWidth: true
    columns: fullRoot.narrowPopup ? 1 : 2
    columnSpacing: Kirigami.Units.largeSpacing
    rowSpacing: Kirigami.Units.largeSpacing
    // ...
}
```

- [ ] **Step 2: Re-wrap existing cards**
Move the `Repeater` blocks for Providers, Subscription Tools, and Ollama into the new `cardsGrid`. Ensure the summary box remains full-width above the grid.

- [ ] **Step 3: Commit**
```bash
git add package/contents/ui/FullRepresentation.qml
git commit -m "feat(ui): refactor dashboard to responsive card grid"
```

### Task 3: Unified Card Styling (QML)

**Files:**
- Modify: `package/contents/ui/ProviderCard.qml`
- Modify: `package/contents/ui/SubscriptionToolCard.qml`
- Modify: `package/contents/ui/OllamaCard.qml`

- [ ] **Step 1: Standardize ProviderCard**
Ensure it uses `Layout.fillWidth: true` and has consistent internal padding.

- [ ] **Step 2: Standardize SubscriptionToolCard**
Update background radius and border to match `ProviderCard`.

- [ ] **Step 3: Standardize OllamaCard**
Ensure its header alignment and font sizes match the standard `ProviderCard`.

- [ ] **Step 4: Commit**
```bash
git add package/contents/ui/*Card.qml
git commit -m "style(ui): unify card styling across all monitor types"
```

### Task 4: Configuration & Cleanup

**Files:**
- Modify: `package/contents/config/main.xml`
- Modify: `package/contents/ui/ConfigGeneral.qml` (if exists, or relevant settings page)

- [ ] **Step 1: Update browser sync options in main.xml**
Add options for the new browser types.

- [ ] **Step 2: Bump Version to v4.2.0**
Run `just bump 4.2.0` and update `CHANGELOG.md` and `ROADMAP.md`.

- [ ] **Step 3: Final Commit & Push**
```bash
git commit -am "chore: release v4.2.0 with UI overhaul and Chrome sync"
git tag v4.2.0
git push origin main --tags
```
