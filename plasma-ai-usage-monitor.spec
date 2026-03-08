Name:           plasma-ai-usage-monitor
Version:        3.8.0
Release:        1%{?dist}
Summary:        KDE Plasma 6 widget to monitor AI API token usage, rate limits, and costs
License:        GPL-3.0-or-later
URL:            https://github.com/loofitheboss/plasma-ai-usage-monitor
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.16
BuildRequires:  extra-cmake-modules
BuildRequires:  gcc-c++
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  libplasma-devel
BuildRequires:  kf6-kwallet-devel
BuildRequires:  kf6-ki18n-devel
BuildRequires:  kf6-knotifications-devel
BuildRequires:  libappstream-glib
BuildRequires:  qt6-qtbase-private-devel

Requires:       plasma-workspace >= 6.0
Requires:       kf6-kwallet
Requires:       kf6-kirigami
Requires:       kf6-kcmutils
Requires:       qt6-qtbase-sql

%description
A native KDE Plasma 6 plasmoid that monitors AI API token usage,
rate limits, costs, and budgets across multiple providers including
OpenAI, Anthropic (Claude), Google (Gemini), Mistral AI, DeepSeek,
Groq, xAI (Grok), OpenRouter, Together AI, and Cohere.

Features:
- Real-time rate limit monitoring for all providers
- Usage and cost tracking with historical trends
- Token-based cost estimation (~30 models with pricing tables)
- Budget management with daily/monthly limits
- SQLite-based usage history with chart visualization
- Secure API key storage via KDE Wallet
- Configurable alerts with KDE notifications
- Per-provider refresh intervals and notification controls
- Collapsible provider cards with accessibility support
- Data export (CSV/JSON)
- Panel icon with status badge indicator
- HTTPS security warnings for custom base URLs

%prep
%autosetup

%build
%cmake
%cmake_build

%install
%cmake_install

%check
%ctest
appstream-util validate-relax --nonet %{buildroot}%{_datadir}/metainfo/com.github.loofi.aiusagemonitor.metainfo.xml

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_datadir}/plasma/plasmoids/com.github.loofi.aiusagemonitor/
%{_libdir}/qt6/qml/com/github/loofi/aiusagemonitor/
%{_datadir}/knotifications6/plasma_applet_com.github.loofi.aiusagemonitor.notifyrc
%{_datadir}/metainfo/com.github.loofi.aiusagemonitor.metainfo.xml

%changelog
* Thu Feb 26 2026 Loofi <loofi@github.com> - 3.7.0-1
- Add Horizon dashboard overview strip in full view with KPI tiles for providers, connectivity, total cost, and tool monitors
- Add provider section header with connected/enabled status badge and targeted empty-state guidance
- Redesign full dashboard live layout grouping for clearer scanability before provider and subscription cards
- Improve provider/subscription card theme adaptation with state-aware tinted surfaces and borders

* Thu Feb 26 2026 Loofi <loofi@github.com> - 3.4.0-1
- Add GitHub Copilot activity auto-detection using IDE state/log paths (Code, VSCodium, Code OSS)
- Add Copilot activity baseline and incremental usage tracking tests
- Include subscription tool monthly costs in compact/popup total cost summaries
- Expand onboarding from 3 to 4 steps with subscription tools guidance
- Restrict Browser Sync browser selection to Firefox and clarify unsupported options

* Sun Feb 22 2026 Loofi <loofi@github.com> - 3.2.0-1
- Add AppStream metainfo for KDE Discover and AppStream catalogs
- Add COPR build infrastructure (.copr/Makefile, scripts/build_srpm.sh)
- Add .plasmoid archive to GitHub Release artifacts
- Add AppStream validation to release CI and RPM spec
- Update README with COPR install instructions
- Extend version consistency check to cover metainfo XML

* Thu Feb 20 2026 Loofi <loofi@github.com> - 3.1.0-1
- Add OpenRouter provider with 22-model pricing and credits balance endpoint
- Add Together AI provider with 12-model pricing (Llama, Qwen, DeepSeek, Mixtral, Gemma)
- Add Cohere provider with 7-model pricing via OpenAI-compatible endpoint
- Add provider config UI sections with model selectors and API key management
- Add per-provider refresh timers, notification, and budget controls
- Add 3 new mocked-HTTP unit tests for new providers

* Wed Feb 19 2026 Loofi <loofi@github.com> - 3.0.0-1
- Update model pricing tables for all 7 providers (2026 pricing)
- Add missing pricing: gemini-2.0-flash-lite, grok-2-mini, deepseek-coder
- Add Mistral -latest alias pricing (mistral-large-latest, etc.)
- Add Anthropic date-suffixed model pricing (claude-3-5-sonnet-20241022, etc.)
- Sync QML model dropdowns with C++ pricing tables
- Add Claude 3.7 Sonnet, Gemini 2.5 Pro/Flash, Llama 3.1 70B to selectors

* Tue Feb 18 2026 Loofi <loofi@github.com> - 2.9.0-1
- Add 43 new C++ unit tests across ProviderBackend, SubscriptionToolBackend,
  UpdateChecker, and UsageDatabase
- Test budget signals, cost estimation, generation counter, state transitions
- Test subscription limit warnings, period calculations, auto-reset
- Test version properties, interval clamping, database pruning, export

* Mon Feb 16 2026 Loofi <loofi@github.com> - 2.8.2-1
- Improve Browser Sync connection diagnostics with actionable status messages
- Add provider mocked-HTTP unit tests (OpenAI, Anthropic, DeepSeek)
- Add subscription monitor unit tests including sync failure diagnostics
- Add blocking clang-tidy CI gate with compile_commands-based runner

* Mon Feb 16 2026 Loofi <loofi@github.com> - 2.8.1-1
- Fix stale UI version display by preferring plasmoid metadata version in QML
- Normalize update checker version parsing for v-prefixed and suffixed tags
- Add local upgrade/reload helper scripts for reliable Plasma package updates
- Add diagnostics for repo/local/system installed version mismatch
- Add test guard against hardcoded semantic version strings in QML

* Mon Feb 16 2026 Loofi <loofi@github.com> - 2.8.0-1
- Add `AppInfo.version` singleton and remove hardcoded QML version drift
- Add compare analytics mode for providers/tools with metric-aware series APIs
- Add `MultiSeriesChart.qml` with compact legend chips and ranked hover tooltip
- Fix History mapping to use db names for query/export (Google/Mistral/xAI labels)
- Apply per-provider notification gating consistently across all provider alerts
- Add explicit History loading/empty states and safer export enablement
- Add tests for series metrics/bucketing and display-name/db-name regression
- Add version consistency check and run ctest in CI build workflow

* Mon Feb 17 2026 Loofi <loofi@github.com> - 2.7.0-1
- Fix reply-after-deleteLater in OpenAI onCostsReply and onMonthlyCostsReply
- Fix reads-after-deleteLater in OpenAICompatible 429 and success paths
- Fix shared DB connection name crash when multiple UsageDatabase instances exist
- Fix compactDisplayMode config alias writing integer index instead of string
- Fix timer binding breakage — remove imperative handler that broke declarative bindings
- Add retry with exponential backoff to OpenAI costs and monthly costs endpoints
- Add write throttling to tool snapshot recording (matching provider snapshot throttle)
- Add restrictive permissions (owner-only) on cookie temp file copies
- Add retentionDays range clamping (1–365 days)
- Fix textToCents returning NaN for invalid budget input (now defaults to 0)

* Mon Feb 16 2026 Loofi <loofi@github.com> - 2.6.0-1
- Fix m_activeReplies never populated — beginRefresh() now actually aborts in-flight requests
- Fix retry logic sending GET instead of POST for chat completion retries
- Fix pruneOldData() totalDeleted only counting last table (now sums all 3 DELETEs)
- Fix double deleteLater() in OpenAICompatible and OpenAI retry paths
- Add beginRefresh(), createRequest(), and generation counter to GoogleProvider
- Add generation counter and createRequest() to DeepSeek fetchBalance()
- Add stale-reply guard to CopilotMonitor fetchOrgMetrics()
- Add trackReply() for registering in-flight replies across all providers
- Add short-lived cookie DB cache in BrowserCookieExtractor (avoids triple reads)
- Add i18n() wrapping to all user-visible error messages in providers
- Split updatechecker.h into .h/.cpp (was header-only with full implementation)
- Add 30s timeout to UpdateChecker GitHub API request
- Add updateLastRefreshed() to Google error path (was showing stale time on failure)

* Mon Feb 16 2026 Loofi <loofi@github.com> - 2.5.0-1
- Add centralized request builder with 30s timeout on all API requests
- Add generation counter for request cancellation on re-refresh
- Add retry with exponential backoff for transient HTTP errors (429/500/502/503)
- Add Retry-After header parsing for 429 rate limit responses
- Separate budgetWarning and budgetExceeded signals with notification dedup
- Add HTTPS validation warning for custom base URLs
- Centralize rate limit header parsing in ProviderBackend base class
- Remove duplicate QNetworkAccessManager in CopilotMonitor
- Add DB write throttling (60s per provider, skip if data unchanged)
- Wrap pruneOldData() in SQLite transaction for atomic multi-table cleanup
- Add eager database init via UsageDatabase::init() to avoid first-write stall
- Optimize UsageChart hover - only repaint when hoveredIndex changes

* Mon Feb 17 2026 Loofi <loofi@github.com> - 2.4.0-1
- Add model name badge in ProviderCard header
- Add subscription tool warning/critical indicators in panel badge
- Fix rate limit bars to show "used" instead of "remaining" for visual consistency
- Add All/Day/Month toggle to CostSummaryCard with per-provider breakdown
- Add hover tooltips with crosshair to UsageChart canvas
- Fix UsageChart Y-axis to start at zero for accurate visual scale
- Add Bézier smooth curve interpolation to UsageChart
- Refactor configBudget.qml from copy-paste to data-driven Repeater (−160 lines)
- Add getToolSnapshots() and getToolNames() to UsageDatabase for tool history queries

* Sun Feb 16 2026 Loofi <loofi@github.com> - 2.3.0-1
- Add browser cookie sync for real-time usage data from Claude.ai and ChatGPT
- Add BrowserCookieExtractor for reading Firefox session cookies (read-only)
- Add full dashboard view: session info, extra usage, tertiary limits, credits
- Add subscription cost display per tool ($X/mo badge)
- Extend ClaudeCodeMonitor with API sync (session %, weekly, extra usage/billing)
- Extend CodexCliMonitor with API sync (5h, weekly, code review, credits)
- Add CopilotMonitor subscription cost support
- Redesign SubscriptionToolCard.qml as full dashboard replica
- Add browser sync config section with connection test buttons
- Add sync refresh button and auto-sync timer in main widget
- Mark browser sync as experimental with ToS disclaimer

* Sun Feb 15 2026 Loofi <loofi@github.com> - 2.2.0-1
- Add subscription tool tracking for Claude Code, Codex CLI, and GitHub Copilot
- Add SubscriptionToolBackend abstract base class with rolling time windows
- Add ClaudeCodeMonitor with 5h session + weekly dual limits (Pro/Max5x/Max20x)
- Add CodexCliMonitor with 5h window (Plus/Pro/Business plans)
- Add CopilotMonitor with monthly limits + optional GitHub API org metrics
- Add SubscriptionToolCard.qml with progress bars and time-until-reset
- Add configSubscriptions.qml with per-tool plan/limit/notification settings
- Add subscription_tool_usage table to SQLite database
- Fix token accumulation bug in OpenAICompatibleProvider (session-level tracking)
- Fix estimatedMonthlyCost returning 0 for non-OpenAI providers
- Fix budget notifications not firing from direct cost setters
- Add DeepSeek account balance display in ProviderCard
- Add Google Gemini free/paid tier selector with tier-aware rate limits

* Sat Feb 15 2026 Loofi <loofi@github.com> - 2.1.0-1
- Add OpenAICompatibleProvider base class, dedup Mistral/Groq/xAI/DeepSeek
- Add token-based cost estimation with per-model pricing (~30 models)
- Add per-provider refresh timers (individual timers per provider)
- Add collapsible provider cards with animated transitions
- Add HTTPS security warnings on custom base URL fields
- Add ClipboardHelper C++ class for data export
- Add accessibility annotations (ProviderCard, CostSummaryCard, CompactRepresentation)
- Data-driven provider cards via Repeater (eliminates hardcoded cards)
- Deduplicate provider arrays (single allProviders source of truth)
- Enable cost/usage display for Anthropic and Google providers
- Fix version mismatch (CMakeLists 1.0.0 to 2.0.0)
- Fix xAI default model (grok-3-mini to grok-3)
- Fix token tracking for Mistral/Groq/xAI providers
- Fix DeepSeek cost display (separate balance from cost)
- Fix OpenAI monthly cost tracking (new billing API endpoint)

* Sun Feb 15 2026 Loofi <loofi@github.com> - 2.0.0-1
- Add Mistral AI, DeepSeek, Groq, and xAI/Grok providers
- Add SQLite-based usage history with chart visualization
- Add budget management with daily/monthly limits per provider
- Add per-provider refresh intervals and notification controls
- Add data export (CSV/JSON) and trend analysis
- Add custom base URL support for all providers (proxy support)
- Fix compact display mode rendering (cost/count modes)
- Fix rate limit remaining=0 edge case in OpenAI provider
- Remove dead parseRateLimitHeaders() method

* Sun Feb 15 2026 Loofi <loofi@github.com> - 1.0.0-1
- Initial release
- Support for OpenAI, Anthropic, and Google Gemini providers
- KWallet integration for secure API key storage
- KDE notifications for rate limit warnings
