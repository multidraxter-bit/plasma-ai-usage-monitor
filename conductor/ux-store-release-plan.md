# UX Polish, Demo Environment & KDE Store Submission Plan

## Objective
Improve the user experience (UX) of the Plasma AI Usage Monitor, build a repeatable demo environment to capture high-quality screenshots, and successfully submit the widget to the KDE Store.

## Background & Motivation
Based on the roadmap (v3.9.0 "Showcase" and v4.0.0 "Horizon"), the application is mature enough for public distribution. To successfully acquire and retain users from the KDE Store, we need polished listing assets, a smoother user experience, and a stable demo environment to consistently produce accurate UI representations without exposing real developer API keys or personal usage data.

## Scope & Impact
- **UI/UX Polish:** Refine the QML views to improve the visual hierarchy, fix main popup orchestration, and ensure correct Kirigami theme inheritance (dark/light modes).
- **Demo Environment:** Create a lightweight mock API server to supply deterministic usage data for screenshots, alongside a documented Fedora KDE VM workflow.
- **KDE Store Assets:** Capture new canonical screenshots using the mock data. Update `README.md` and AppStream metadata, followed by the actual KDE Store submission.

## Implementation Steps

### Phase 1: UX & Stability Polish
- **Popup Orchestration:** Clean up `main.qml` startup sequence, timers, and snapshot recording to reduce popup fragility.
- **Theme Awareness:** Audit `FullRepresentation.qml`, `ProviderCard.qml`, and charts to ensure they perfectly inherit Plasma color schemes (`Kirigami.Theme`) without hardcoded colors.
- **Keyboard Navigation:** Ensure full keyboard accessibility for all interactive elements (cards, charts, config tabs) in `package/contents/ui/`.
- **Demo Mode Flags:** Add logic (or custom base URL config overrides) so the UI can gracefully point to local mock endpoints without displaying developer-local specifics.

### Phase 2: Demo Environment Setup
- **Mock Server:** Implement a lightweight local server (`scripts/demo/mock_server.py`) using Python inside a `.venv`. It will return static/deterministic JSON responses mimicking real APIs (OpenAI, Anthropic, etc.).
- **Demo Presets:** Define the canonical provider states, values, and budgets used for screenshots so they can be reproduced instantly.
- **Capture Scripts:** Add a helper script to bootstrap the demo environment, start the mock server, and configure the widget endpoints.

### Phase 3: Assets & Screenshots
- **Run Environment:** Spin up the Fedora 43 KDE VM (as per `docs/demo/fedora-kde-vm.md`) with the mock server.
- **Capture Playbook:** Take updated, polished screenshots:
  - `assets/screenshots/main-window.png` (Live dashboard with mock data)
  - `assets/screenshots/panel-view.png` (Compact representation)
  - `assets/screenshots/settings-view.png` (Config dialog)
  - *Optional:* History/Compare Analytics view and Subscriptions view.
- **Documentation:** Update `assets/screenshots/README.md` and repository `README.md` with the new images.

### Phase 4: KDE Store Submission
- **Metadata Update:** Update `com.github.loofi.aiusagemonitor.metainfo.xml` to include any new screenshot references and confirm the short/long descriptions match the checklist guidelines.
- **Validation:** Run `scripts/package_plasmoid.sh --check` and ensure AppStream metadata validates cleanly.
- **Packaging:** Create the `com.github.loofi.aiusagemonitor.plasmoid` archive.
- **Manual Publication:** Follow the sequence in `docs/store/submission-checklist.md` to manually upload the plasmoid, refreshed screenshots, and listing copy to the KDE Store. Ensure the compiled plugin requirement is clearly stated.

## Verification & Testing
- Manually toggle between Plasma Dark and Light themes to verify QML component adaptability.
- Run the mock server and verify the widget successfully polls it without triggering "connection refused" or parsing errors.
- Run `appstreamcli validate com.github.loofi.aiusagemonitor.metainfo.xml` to ensure KDE store metadata is compliant before publishing.
