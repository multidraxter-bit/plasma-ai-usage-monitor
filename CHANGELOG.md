# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.5.3] — 2026-02-26

### Fixed

- Fix `.plasmoid` archive generation in release CI by clamping `SOURCE_DATE_EPOCH` to ZIP's minimum supported timestamp (1980-01-01)

## [3.5.2] — 2026-02-26

### Fixed

- Fix release tarball packaging in CI by generating source archives from tracked files (`git ls-files`) to avoid `tar: .: file changed as we read it`

## [3.5.1] — 2026-02-26

### Fixed

- Fix AppStream metainfo validation by switching to a valid stock icon name (`utilities-system-monitor`) for release workflow compatibility

## [3.5.0] — 2026-02-26

### Added

- Add minimal Flatpak scaffold under `packaging/flatpak/` for distribution kickoff
- Add deterministic local packaging scripts for source tarball and `.plasmoid` archive generation
- Add Flatpak scaffold validation script for CI and local checks
- Add mocked HTTP coverage for `GoogleVeoProvider` (tier fallback, header limits, auth failure)
- Add real Plasma widget screenshots under `assets/screenshots/` (main, panel, settings-oriented)

### Changed

- Strengthen Flatpak scaffold validation to enforce manifest core fields and metadata/CMake version identity checks
- Update build and release workflows to run full packaging consistency checks (`check_version_consistency`, Flatpak scaffold, source/plasmoid check mode)
- Update release workflow to generate source/plasmoid artifacts via packaging scripts
- Improve `GoogleVeoProvider` success-path handling with response validation and request counting
- Prefer API-provided rate-limit headers for Google Veo when available, with known-limit fallback
- Replace README screenshot placeholder with actual captures and add walkthrough doc link

## [3.4.0] — 2026-02-26

### Added

- Add GitHub Copilot activity auto-detection from local IDE state/log paths (`Code`, `VSCodium`, `Code - OSS`) in `CopilotMonitor`
- Add baseline + increment regression test for Copilot activity detection in `plugin/tests/test_subscription_tools.cpp`
- Add subscription-tool cost rows to `CostSummaryCard.qml` for cumulative view transparency
- Add explicit Firefox-only support guidance in Subscriptions config UI

### Changed

- Include enabled subscription tool costs in total cost aggregation (`main.qml`, `CompactRepresentation.qml`, `CostSummaryCard.qml`)
- Expand onboarding flow from 3 to 4 steps and include subscription-tools setup guidance (`FullRepresentation.qml`)
- Clarify browser-sync config schema label to reflect Firefox-only support (`package/contents/config/main.xml`)

## [3.3.0] — 2026-02-25

### Added

- Add `scripts/install_doctor.sh` preflight checker for required commands, Fedora package checks, and SQLite driver diagnostics
- Add `scripts/install_bootstrap.sh` guided installer with `auto|copr|source|user` modes and dry-run support
- Add new Just recipes for install UX: `doctor`, `doctor-fix`, `bootstrap`, `bootstrap-source`, `bootstrap-copr`, `bootstrap-user`
- Add first-run setup wizard state in config (`setupWizardCompleted`, `setupWizardDismissed`)
- Add first-run onboarding wizard in `FullRepresentation.qml` with step-by-step setup guidance
- Add persisted Firefox profile selection for Browser Sync (`browserSyncProfile`) with auto/default fallback

### Changed

- Update `install.sh` to delegate to the guided bootstrap flow (`source` mode with dependency auto-fix)
- Update README and CONTRIBUTING docs with guided bootstrap and doctor workflows
- Expand `hasAnyProvider()` checks to include OpenRouter, Together AI, Cohere, and Google Veo for correct empty-state behavior
- Improve Browser Sync settings UX with profile reload and safer fallback when saved profiles disappear

## [3.2.0] — 2026-02-22

### Added

- Add AppStream metainfo (`com.github.loofi.aiusagemonitor.metainfo.xml`) for KDE Discover and AppStream catalogs
- Add COPR build infrastructure (`.copr/Makefile`, `scripts/build_srpm.sh`) for Fedora package distribution
- Add `.plasmoid` archive as GitHub Release artifact for KDE Store submission
- Add AppStream validation step in release CI workflow and RPM `%check` section
- Add `%license`, `%doc`, and `%check` sections to RPM spec
- Add COPR install instructions to README
- Add `assets/screenshots/` directory for KDE Store listing preparation
- Extend version consistency check to validate AppStream metainfo version

### Changed

- Update RPM spec `Source0` to use full GitHub archive URL (required for COPR)
- Update release workflow to include `libappstream-glib` and `zip` for new validation and packaging steps

## [3.1.0] — 2026-02-20

### Added

- Add OpenRouter provider with 22-model pricing and credits balance endpoint
- Add Together AI provider with 12-model pricing (Llama, Qwen, DeepSeek, Mixtral, Gemma)
- Add Cohere provider with 7-model pricing via OpenAI-compatible endpoint
- Add configProviders.qml sections for all 3 new providers with model selectors, API key management, and custom base URL support
- Add per-provider refresh timers, notification toggles, and budget controls for OpenRouter, Together AI, and Cohere
- Add unit tests for OpenRouter (usage + credits), Together AI, and Cohere providers

## [3.0.0] — 2026-02-19

### Changed

- Update model pricing tables for all 7 providers to 2026 pricing
- Reorder Google Gemini pricing by model generation (2.5 → 2.0 → 1.5)
- Reorder Groq pricing to group Llama models together
- Sync QML model selector dropdowns with registered C++ pricing

### Added

- Add `gemini-2.0-flash-lite` pricing ($0.075/$0.30 per 1M tokens)
- Add `grok-2-mini` pricing ($2.00/$10.00 per 1M tokens)
- Add `deepseek-coder` pricing ($0.14/$0.28 per 1M tokens)
- Add Anthropic date-suffixed model pricing (`claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`)
- Add Mistral `-latest` alias pricing (`mistral-large-latest`, `mistral-medium-latest`, `mistral-small-latest`, `codestral-latest`)
- Add Claude 3.7 Sonnet to Anthropic model selector
- Add Gemini 2.5 Pro and 2.5 Flash (stable) to Google model selector
- Add Llama 3.1 70B Versatile to Groq model selector

### Fixed

- Fix duplicate v2.9.0 changelog entry in RPM spec file

## [2.9.0] — 2026-02-18

### Added

- Add 43 new C++ unit tests across 4 test files covering ProviderBackend, SubscriptionToolBackend, UpdateChecker, and UsageDatabase
- Test budget warning/exceeded signals with dedup validation
- Test token-based cost estimation with exact and prefix model matching
- Test generation counter for stale request detection
- Test disconnect/reconnect signal transitions
- Test subscription limit warnings, period calculations, and auto-reset
- Test version property setters and interval clamping in UpdateChecker
- Test database pruning, CSV/JSON export, summary aggregation, retention clamping, and disabled recording

## [2.8.2] — 2026-02-16

### Added

- Add provider mocked-HTTP test suite covering OpenAI, Anthropic, and DeepSeek response parsing
- Add subscription monitor test suite for plan defaults, install detection, usage reset behavior, and sync diagnostics
- Add blocking `clang-tidy` CI gate with repository `.clang-tidy` config and `scripts/run_clang_tidy_ci.sh`
- Add `syncDiagnostic(toolName, code, message)` signal for deterministic browser-sync failure diagnostics

### Changed

- Improve Browser Sync connection checks with normalized status codes and explicit profile/cookie/session detection
- Improve Subscriptions config UX by mapping diagnostics to user-safe messages with actionable guidance text

## [2.8.1] — 2026-02-16

### Fixed

- Fix stale UI version display by preferring plasmoid metadata version in QML
- Normalize update checker parsing for prefixed/suffixed version strings

### Added

- Add local install/reload scripts to override stale system package installs
- Add diagnostics script for repo/local/system version mismatch visibility
- Add CI/CTest guard to prevent hardcoded semantic versions in QML

## [2.8.0] — 2026-02-16

### Added

- Add `AppInfo.version` singleton and remove hardcoded UI version drift
- Add compare analytics mode for cross-provider and cross-tool history views
- Add multi-series chart with legend, ranked hover tooltip, and crosshair
- Add aggregated series APIs: `getProviderSeries()` and `getToolSeries()`
- Add test coverage for series metrics/bucketing and history mapping regressions
- Add version-consistency CI test and run `ctest` in GitHub Actions

### Fixed

- Fix history mapping (display label vs DB name) for Google/Mistral/xAI
- Fix provider notification gating consistency for quota/budget/connectivity/error alerts
- Add explicit loading/empty states and export gating in History

## [2.7.0] — 2026-02-17

### Fixed

- Fix reply-after-deleteLater in OpenAI costs and monthly costs handlers
- Fix reads-after-deleteLater in OpenAICompatible 429 and success paths
- Fix shared DB connection name crash when multiple UsageDatabase instances exist
- Fix compactDisplayMode config alias writing integer index instead of string
- Fix timer binding breakage — remove imperative handler that broke declarative bindings
- Fix textToCents returning NaN for invalid budget input (now defaults to 0)

### Added

- Add retry with exponential backoff to OpenAI costs and monthly costs endpoints
- Add write throttling to tool snapshot recording (matching provider snapshot throttle)
- Add restrictive permissions (owner-only) on cookie temp file copies
- Add retentionDays range clamping (1–365 days)

## [2.6.0] — 2026-02-16

### Fixed

- Fix m_activeReplies never populated — beginRefresh() now actually aborts in-flight requests
- Fix retry logic sending GET instead of POST for chat completion retries
- Fix pruneOldData() totalDeleted only counting last table (now sums all 3 DELETEs)
- Fix double deleteLater() in OpenAICompatible and OpenAI retry paths

### Added

- Add beginRefresh(), createRequest(), and generation counter to GoogleProvider
- Add generation counter and createRequest() to DeepSeek fetchBalance()
- Add stale-reply guard to CopilotMonitor fetchOrgMetrics()
- Add trackReply() for registering in-flight replies across all providers
- Add short-lived cookie DB cache in BrowserCookieExtractor (avoids triple reads)
- Add i18n() wrapping to all user-visible error messages in providers
- Split updatechecker.h into .h/.cpp (was header-only with full implementation)
- Add 30s timeout to UpdateChecker GitHub API request

## [2.5.0] — 2026-02-16

### Added

- Add centralized request builder with 30s timeout on all API requests
- Add generation counter for request cancellation on re-refresh
- Add retry with exponential backoff for transient HTTP errors (429/500/502/503)
- Add Retry-After header parsing for 429 rate limit responses
- Separate budgetWarning and budgetExceeded signals with notification dedup
- Add HTTPS validation warning for custom base URLs
- Centralize rate limit header parsing in ProviderBackend base class
- Add DB write throttling (60s per provider, skip if data unchanged)
- Wrap pruneOldData() in SQLite transaction for atomic multi-table cleanup
- Add eager database init via UsageDatabase::init() to avoid first-write stall

### Fixed

- Remove duplicate QNetworkAccessManager in CopilotMonitor
- Optimize UsageChart hover — only repaint when hoveredIndex changes

## [2.4.0] — 2026-02-17

### Added

- Add model name badge in ProviderCard header
- Add subscription tool warning/critical indicators in panel badge
- Add All/Day/Month toggle to CostSummaryCard with per-provider breakdown
- Add hover tooltips with crosshair to UsageChart canvas
- Add Bézier smooth curve interpolation to UsageChart

### Fixed

- Fix rate limit bars to show "used" instead of "remaining" for visual consistency
- Fix UsageChart Y-axis to start at zero for accurate visual scale
- Refactor configBudget.qml from copy-paste to data-driven Repeater

## [2.3.0] — 2026-02-16

### Added

- Add browser cookie sync for real-time usage data from Claude.ai and ChatGPT
- Add BrowserCookieExtractor for reading Firefox session cookies (read-only)
- Full dashboard view: session info, extra usage, tertiary limits, credits
- Add subscription cost display per tool ($X/mo badge)
- Extend ClaudeCodeMonitor with API sync (session %, weekly, extra usage/billing)
- Extend CodexCliMonitor with API sync (5h, weekly, code review, credits)
- Add CopilotMonitor subscription cost support
- Redesign SubscriptionToolCard.qml as full dashboard replica
- Add browser sync config section with connection test buttons
- Add sync refresh button and auto-sync timer in main widget
- Mark browser sync as experimental with ToS disclaimer

## [2.2.0] — 2026-02-15

### Added

- Add subscription tool tracking for Claude Code, Codex CLI, and GitHub Copilot
- Add SubscriptionToolBackend abstract base class with rolling time windows
- Add ClaudeCodeMonitor with 5h session + weekly dual limits (Pro/Max5x/Max20x)
- Add CodexCliMonitor with 5h window (Plus/Pro/Business plans)
- Add CopilotMonitor with monthly limits + optional GitHub API org metrics
- Add SubscriptionToolCard.qml with progress bars and time-until-reset
- Add configSubscriptions.qml with per-tool plan/limit/notification settings
- Add subscription_tool_usage table to SQLite database
- Add DeepSeek account balance display in ProviderCard
- Add Google Gemini free/paid tier selector with tier-aware rate limits

### Fixed

- Fix token accumulation bug in OpenAICompatibleProvider (session-level tracking)
- Fix estimatedMonthlyCost returning 0 for non-OpenAI providers
- Fix budget notifications not firing from direct cost setters

## [2.1.0] — 2026-02-15

### Added

- Add OpenAICompatibleProvider base class, dedup Mistral/Groq/xAI/DeepSeek
- Add token-based cost estimation with per-model pricing (~30 models)
- Add per-provider refresh timers (individual timers per provider)
- Add collapsible provider cards with animated transitions
- Add HTTPS security warnings on custom base URL fields
- Add ClipboardHelper C++ class for data export
- Add accessibility annotations (ProviderCard, CostSummaryCard, CompactRepresentation)
- Data-driven provider cards via Repeater (eliminates hardcoded cards)
- Enable cost/usage display for Anthropic and Google providers

### Fixed

- Fix version mismatch (CMakeLists 1.0.0 to 2.0.0)
- Fix xAI default model (grok-3-mini to grok-3)
- Fix token tracking for Mistral/Groq/xAI providers
- Fix DeepSeek cost display (separate balance from cost)
- Fix OpenAI monthly cost tracking (new billing API endpoint)

## [2.0.0] — 2026-02-15

### Added

- Add Mistral AI, DeepSeek, Groq, and xAI/Grok providers
- Add SQLite-based usage history with chart visualization
- Add budget management with daily/monthly limits per provider
- Add per-provider refresh intervals and notification controls
- Add data export (CSV/JSON) and trend analysis
- Add custom base URL support for all providers (proxy support)

### Fixed

- Fix compact display mode rendering (cost/count modes)
- Fix rate limit remaining=0 edge case in OpenAI provider
- Remove dead parseRateLimitHeaders() method

## [1.0.0] — 2026-02-15

### Added

- Initial release
- Support for OpenAI, Anthropic, and Google Gemini providers
- KWallet integration for secure API key storage
- KDE notifications for rate limit warnings

[Unreleased]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.5.3...HEAD
[3.5.3]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.5.2...v3.5.3
[3.5.2]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.5.1...v3.5.2
[3.5.1]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.5.0...v3.5.1
[3.5.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.4.0...v3.5.0
[3.4.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.9.0...v3.0.0
[2.9.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.8.2...v2.9.0
[2.8.2]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.8.1...v2.8.2
[2.8.1]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.8.0...v2.8.1
[2.8.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.7.0...v2.8.0
[2.7.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.6.0...v2.7.0
[2.6.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.5.0...v2.6.0
[2.5.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.4.0...v2.5.0
[2.4.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.2.0...v2.3.0
[2.2.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/loofitheboss/plasma-ai-usage-monitor/releases/tag/v1.0.0
