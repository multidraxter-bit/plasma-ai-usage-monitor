# AI Usage Monitor — KDE Plasma 6 Widget

<p align="center">
  <img src="assets/logo.png" alt="Plasma AI Monitor" width="200" />
</p>

<p align="center">
  <strong>Monitor AI API usage, costs, rate limits, and budgets — right from your Plasma panel.</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#api-key-requirements">API Keys</a> •
  <a href="#documentation">Docs</a> •
  <a href="#changelog">Changelog</a>
</p>

---

A native KDE Plasma 6 plasmoid that monitors AI API token usage, rate limits, and costs across multiple providers. Sits in your panel as a compact icon with a colored status badge and expands into a detailed popup with per-provider stats, usage history charts, and budget tracking. Also tracks subscription-based AI coding tool usage limits for Claude Code, Codex CLI, and GitHub Copilot.

**Supported providers:** OpenAI, Anthropic (Claude), Google Gemini, Mistral AI, DeepSeek, Groq, xAI (Grok), OpenRouter, Together AI, Cohere

**Supported subscription tools:** Claude Code, OpenAI Codex CLI, GitHub Copilot

## Features

- **Real-time monitoring** — Periodic background polling with configurable per-provider refresh intervals (default 5 min) and manual refresh
- **10 AI providers** — OpenAI, Anthropic, Google Gemini, Mistral AI, DeepSeek, Groq, xAI/Grok, OpenRouter, Together AI, Cohere
- **Token usage tracking** — Input/output tokens used, requests made, quota/tier limits
- **Cost tracking** — Dollar spending with daily and monthly cost breakdowns; automatic token-based cost estimation for providers without billing APIs (~30 models with pricing tables)
- **Budget management** — Per-provider daily/monthly budgets with configurable warning thresholds and notifications when budgets are exceeded
- **Usage history** — SQLite-backed persistence with configurable retention (7-365 days, default 90)
- **Interactive charts** — Canvas-based line/area charts showing cost, tokens, requests, and rate limit trends over 24h/7d/30d
- **Compare analytics mode** — Multi-series history comparison across providers or subscription tools with ranking, delta trends, compact legend chips, and hover crosshair/tooltip
- **Trend summaries** — Total cost, average daily cost, peak usage, and snapshot counts per time range
- **Rate limit visualization** — Progress bars with color-coded thresholds (green/yellow/red)
- **Collapsible provider cards** — Click to collapse/expand; collapsed cards show a compact cost summary
- **KDE notifications** — Desktop alerts for rate limit warnings, API errors, budget exceeded, provider disconnect/reconnect
- **Notification controls** — Per-provider toggles, cooldown period, Do Not Disturb schedule
- **Secure key storage** — API keys stored in KWallet, never written to config files on disk
- **Panel display modes** — Compact icon shows green/yellow/red status badge, or current cost, or active provider count
- **Proxy support** — Custom base URLs per provider for API proxies/gateways, with inline HTTPS security warnings
- **Data export** — CSV and JSON export of usage history (copies to clipboard)
- **Accessibility** — Screen reader annotations on provider cards, cost summary, and panel icon
- **Per-provider configuration** — Enable/disable providers independently, select models, set refresh intervals, configure budgets

## Subscription Tool Tracking

In addition to API providers, the widget tracks usage limits for subscription-based AI coding tools:

### Claude Code

- Monitors `~/.claude/` directory for activity via filesystem watcher
- Plans: **Pro** (45/5h, 225/week), **Max 5x** (225/5h, 1125/week), **Max 20x** (900/5h, 4500/week)
- Dual limits: 5-hour session window + weekly rolling window

### Codex CLI

- Monitors `~/.codex/` directory for activity via filesystem watcher
- Plans: **Plus** (45/5h), **Pro** (300/5h), **Business** (45/5h)
- Single 5-hour rolling window

### GitHub Copilot

- Tracks monthly premium request limits (resets 1st of each month UTC)
- Plans: **Free** (50/mo), **Pro** (300/mo), **Pro+** (1500/mo), **Business** (300/mo), **Enterprise** (1000/mo)
- Optional GitHub API integration for organization-level seat metrics (requires PAT with `manage_billing:copilot` scope)

**Note:** None of these tools expose public APIs for individual quota checking. Usage is self-tracked locally via filesystem monitoring and manual counting, with limits auto-populated from plan presets.

### Browser Sync (Experimental)

Optionally sync real-time usage data by reading session cookies from your Firefox browser:

- **Claude Code** — Syncs session usage %, weekly limits, and extra usage spending from claude.ai internal API
- **Codex CLI** — Syncs 5-hour usage, weekly limits, code review quotas, and remaining credits from chatgpt.com internal API

**How it works:** The widget reads cookies from Firefox's `cookies.sqlite` database (read-only) and makes authenticated requests to the same internal APIs that the web dashboards use. Your cookie data never leaves your machine — all requests go directly to the official services.

**Enable:** Settings → Subscriptions → Browser Sync → Enable sync

**Requirements:** Firefox with an active session on claude.ai and/or chatgpt.com. Chrome/Chromium is not currently supported (encrypted cookies).
If you have multiple Firefox profiles, you can choose a specific profile in
Settings → Subscriptions → Browser Sync.

> **Warning:** This feature uses internal, undocumented APIs. It may stop working if services change their API structure. Use at your own risk.

## What Each Provider Reports

| Metric | OpenAI | Anthropic | Google | Mistral | DeepSeek | Groq | xAI |
|--------|--------|-----------|--------|---------|----------|------|-----|
| Token usage (in/out) | Yes | No | No | Yes | Yes | Yes | Yes |
| Rate limits remaining | Yes | Yes | No* | Yes | Yes | Yes | Yes |
| Cost / spending | Yes (billing) | Est.** | Est.** | Est.** | Est.** | Est.** | Est.** |
| Request count | Yes | Yes | No | Yes | Yes | Yes | Yes |
| Connection status | Yes | Yes | Yes | Yes | Yes | Yes | Yes |

*\* Google Gemini displays known free-tier limits from documentation (static).*
*\*\* Estimated from token usage and per-model pricing tables. Labeled "Est. Cost" in the UI with a tooltip.*

- **OpenAI** has the richest data: real usage from `/organization/usage/completions`, dollar costs from `/organization/costs` and `/organization/costs` (monthly), and rate limits from response headers. Requires an **Admin API key**.
- **Anthropic** has no usage/billing API. The widget pings `/v1/messages/count_tokens` (lightweight, no token cost) and reads the `anthropic-ratelimit-*` response headers for rate limit data. Cost is estimated from registered model pricing.
- **Google Gemini** has no usage API and no rate limit headers. The widget verifies connectivity via `countTokens` and displays known free-tier limits from documentation. Cost is estimated from registered model pricing.
- **Mistral AI, Groq, xAI** — These use an OpenAI-compatible API. The widget sends a minimal chat completion request (1 token), reads `x-ratelimit-*` response headers, and accumulates token usage. Cost is estimated from per-model pricing tables.
- **DeepSeek** — Same as above, plus a separate balance endpoint (`/user/balance`) to fetch the prepaid account balance.

## Screenshots

*Screenshots coming soon — the widget is functional and can be added to any Plasma 6 panel or desktop.*

<p align="center">
  <img src="assets/logo.png" alt="Plasma AI Monitor Logo" width="128" />
</p>

## Requirements

- **KDE Plasma 6** (Plasma 6.0+)
- **Qt 6** (Core, Qml, Quick, Network, Sql)
- **KDE Frameworks 6** (KWallet, KNotifications, KI18n)
- **Fedora 43 KDE** (tested) — should work on any distro with Plasma 6

### Build Dependencies (Fedora)

```text
cmake
extra-cmake-modules
gcc-c++
qt6-qtbase-devel
qt6-qtdeclarative-devel
qt6-qtbase-sql
libplasma-devel
kf6-kwallet-devel
kf6-ki18n-devel
kf6-knotifications-devel
```

## Development Workflow

Install [`just`](https://github.com/casey/just) to use the unified `Justfile` recipes:

```bash
sudo dnf install just   # Fedora
# or: cargo install just
```

| Recipe | Description |
|--------|-------------|
| `just build` | Configure + build (Release) |
| `just build-debug` | Configure + build (Debug, enables tests) |
| `just test` | Build debug + run unit tests via ctest |
| `just check` | Version consistency + no-hardcoded-versions checks |
| `just doctor` | Validate install/build prerequisites |
| `just doctor-fix` | Validate and auto-install missing Fedora deps |
| `just versions` | Show repo / user-local / system installed versions |
| `just clean` | Remove the `build/` directory |
| **System-wide (sudo)** | |
| `just install` | Build then `sudo cmake --install build` |
| `just reinstall` | Uninstall + install |
| `just uninstall` | Remove via `build/install_manifest.txt` |
| **User-local (no sudo)** | |
| `just dev` | Install user-local QML + reload plasmashell (fastest dev loop) |
| `just install-user` | `kpackagetool6 --upgrade package/` |
| `just uninstall-user` | Remove user-local QML package |
| `just reload` | Restart plasmashell |
| **Bootstrap** | |
| `just bootstrap` | Guided install (auto picks COPR on Fedora) |
| `just bootstrap-source` | Guided source install with dependency auto-fix |
| `just bootstrap-copr` | Guided Fedora COPR install |
| `just bootstrap-user` | Guided user-local install + reload |
| **COPR / DNF** | |
| `just copr-install` | Enable COPR + `dnf install` |
| `just copr-update` | `dnf upgrade` from COPR |
| `just copr-remove` | Remove package + COPR repo |
| **Version** | |
| `just bump VERSION=3.4.0` | Bump version in all 4 files atomically |

**Typical dev loop (QML changes):**

```bash
# Edit package/contents/ui/*.qml, then:
just dev
```

**Typical dev loop (C++ plugin changes):**

```bash
# Edit plugin/*.cpp, then:
just install   # sudo required; rebuilds and installs to /usr
just reload
```

**Release a new version:**

```bash
just bump VERSION=3.4.0
# Update CHANGELOG.md, then:
git commit -am "chore: bump version to v3.4.0"
git tag v3.4.0 && git push --tags
```

---

## Installation

### Guided Bootstrap (Recommended for source installs)

Use the guided bootstrap script to run preflight checks and install with the
right method:

```bash
git clone https://github.com/loofitheboss/plasma-ai-usage-monitor.git
cd plasma-ai-usage-monitor
./scripts/install_bootstrap.sh
```

Useful modes:

```bash
# Force source build/install
./scripts/install_bootstrap.sh --method source --install-missing

# Force user-local plasmoid-only install (no system plugin install)
./scripts/install_bootstrap.sh --method user
```

Run only dependency checks:

```bash
./scripts/install_doctor.sh
```

### Install from COPR (Recommended)

```bash
sudo dnf copr enable loofitheboss/plasma-ai-usage-monitor
sudo dnf install plasma-ai-usage-monitor
```

This installs both the QML plasmoid package and the C++ plugin. After installation, log out and back in (or run `plasmashell --replace &`), then add the widget from "Add Widgets...".

To uninstall:

```bash
sudo dnf remove plasma-ai-usage-monitor
sudo dnf copr remove loofitheboss/plasma-ai-usage-monitor
```

### Quick Install (Fedora)

The included `install.sh` script now delegates to the guided bootstrap flow
in source mode with Fedora dependency auto-fix enabled:

```bash
git clone https://github.com/loofitheboss/plasma-ai-usage-monitor.git
cd plasma-ai-usage-monitor
chmod +x install.sh
./install.sh
```

### Manual Build

```bash
# Install build dependencies (Fedora)
sudo dnf install cmake extra-cmake-modules gcc-c++ \
    qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtbase-sql \
    libplasma-devel kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel

# Build
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Install (requires sudo for system QML plugin path)
sudo cmake --install .
```

### After Installation

1. Right-click your desktop or panel
2. Select **Add Widgets...**
3. Search for **AI Usage Monitor**
4. Drag it to your panel or desktop
5. Right-click the widget > **Configure** to add your API keys

To test without adding to a panel:

```bash
plasmawindowed com.github.loofi.aiusagemonitor
```

If the widget doesn't appear after installation:

```bash
plasmashell --replace &
```

### Fix "still shows old version" (for example `v1.0`)

If Plasma still shows an older widget build, verify what is installed and
override it with a local user install:

```bash
./scripts/show_installed_versions.sh
./scripts/install_local_plasmoid.sh
./scripts/reload_plasma.sh
```

The local install at `~/.local/share/plasma/plasmoids/` takes precedence over
system package files in `/usr/share/plasma/plasmoids/`.

### Run Tests

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
ctest --test-dir build --output-on-failure
./scripts/check_version_consistency.sh
./scripts/check_no_hardcoded_versions.sh
./scripts/show_installed_versions.sh
```

## Configuration

Right-click the widget and select **Configure** to access six settings tabs:

### General

- **Refresh interval** — How often to poll APIs (30s to 30min, default 5min)
- **Compact display mode** — What to show in the panel: icon only, current cost, or active provider count
- **Per-provider refresh intervals** — Override the global interval for specific providers

### Providers

Each provider has:

- **Enable/disable** toggle
- **API key** field — Keys are stored in KWallet. Use the eye icon to show/hide, and the clear button to remove a key.
- **Model selector** — Choose which model to query (e.g., `gpt-4o`, `claude-sonnet-4-20250514`, `gemini-2.0-flash`, `mistral-large-latest`, `deepseek-chat`, `llama-3.3-70b-versatile`, `grok-3`)
- **Custom base URL** — Optional proxy/gateway URL override. Shows a security warning if you enter an `http://` (non-HTTPS) URL.
- **Project ID** (OpenAI only) — Optional, to filter usage to a specific project

### Alerts

- **Master toggle** — Enable/disable all alerts
- **Warning threshold** — Percentage of rate limit to trigger a yellow warning (default 80%)
- **Critical threshold** — Percentage to trigger a red critical alert (default 95%)
- **Notification types** — Toggle API error, budget warning, provider disconnect, and provider reconnect notifications independently
- **Per-provider toggles** — Enable/disable notifications for specific providers
- **Cooldown** — Minimum minutes between repeated notifications (1-60, default 15)
- **Do Not Disturb** — Schedule a time window to suppress all notifications

### Budget

- **Per-provider daily and monthly budgets** — Set spending limits in dollars (e.g., $10.50/day, $100.00/month)
- **Warning percentage** — Trigger a warning at this percentage of budget (default 80%)

### Subscriptions

- **Claude Code** — Enable/disable, plan tier (Pro/Max 5x/Max 20x), custom usage limit, notifications
- **Codex CLI** — Enable/disable, plan tier (Plus/Pro/Business), custom usage limit, notifications
- **Browser Sync profile** — Select a Firefox profile explicitly or use auto/default detection
- **GitHub Copilot** — Enable/disable, plan tier (Free/Pro/Pro+/Business/Enterprise), custom limit, notifications
- **GitHub API (optional)** — Personal access token and organization name for Copilot seat metrics
- **Auto-detect** — Each tool shows a detection badge (detected/not found) based on installed binaries and config directories

### History

- **Enable/disable** usage history recording
- **Retention period** — How long to keep data (7-365 days, default 90)
- **Detail mode** — Single-provider trends (cost/tokens/requests/rate limit) with trend summary
- **Compare mode** — Multi-series comparison across providers or subscription tools with metric selector and ranking
- **Responsive controls** — History controls are horizontally scrollable on narrow popups/mobile widths
- **Clear states** — Loading, no-provider, no-history, and no-compare-data placeholders
- **Database size** display
- **Prune** button to manually clean old data

## Architecture

```text
plasma-ai-usage-monitor/
├── CMakeLists.txt                  # Root build system (v3.4.0)
├── install.sh                      # Build & install script
├── plasma-ai-usage-monitor.spec    # RPM packaging spec
├── plasma_applet_...notifyrc       # KDE notification events
├── package/                        # Plasmoid package (QML + metadata)
│   ├── metadata.json               # Plasma 6 plugin metadata
│   └── contents/
│       ├── config/
│       │   ├── config.qml          # Config tab definitions (6 tabs)
│       │   └── main.xml            # KConfigXT schema
│       └── ui/
│           ├── main.qml            # Root PlasmoidItem (providers, tools, timers, notifications)
│           ├── CompactRepresentation.qml  # Panel icon (3 display modes)
│           ├── FullRepresentation.qml     # Popup with Live/History tabs + subscription tools
│           ├── ProviderCard.qml           # Collapsible provider stats card
│           ├── SubscriptionToolCard.qml   # Subscription tool usage card
│           ├── CostSummaryCard.qml        # Aggregate cost breakdown
│           ├── UsageChart.qml             # Canvas line/area chart
│           ├── MultiSeriesChart.qml       # Multi-line compare chart for analytics mode
│           ├── TrendSummary.qml           # Summary stats grid
│           ├── configGeneral.qml
│           ├── configProviders.qml
│           ├── configAlerts.qml
│           ├── configBudget.qml
│           ├── configSubscriptions.qml    # Subscription tool settings
│           └── configHistory.qml
└── plugin/                         # C++ QML plugin
    ├── CMakeLists.txt
    ├── qmldir                      # QML module registration
    ├── aiusageplugin.{h,cpp}       # QQmlExtensionPlugin (20 types)
    ├── appinfo.{h,cpp}             # App version singleton for QML (build-version source of truth)
    ├── secretsmanager.{h,cpp}      # KWallet wrapper
    ├── clipboardhelper.h            # Clipboard copy/paste helper
    ├── providerbackend.{h,cpp}     # Abstract base class + cost estimation
    ├── openaicompatibleprovider.{h,cpp}  # Intermediate base for OpenAI-compatible APIs
    ├── openaiprovider.{h,cpp}      # OpenAI API integration
    ├── anthropicprovider.{h,cpp}   # Anthropic API integration
    ├── googleprovider.{h,cpp}      # Google Gemini integration
    ├── mistralprovider.{h,cpp}     # Mistral AI (extends OpenAICompatibleProvider)
    ├── deepseekprovider.{h,cpp}    # DeepSeek (extends OpenAICompatibleProvider)
    ├── groqprovider.{h,cpp}        # Groq (extends OpenAICompatibleProvider)
    ├── xaiprovider.{h,cpp}         # xAI/Grok (extends OpenAICompatibleProvider)
    ├── openrouterprovider.{h,cpp}  # OpenRouter (extends OpenAICompatibleProvider)
    ├── togetherprovider.{h,cpp}    # Together AI (extends OpenAICompatibleProvider)
    ├── cohereprovider.{h,cpp}      # Cohere (extends OpenAICompatibleProvider)
    ├── googleveoprovider.{h,cpp}   # Google Veo video generation monitor
    ├── subscriptiontoolbackend.{h,cpp}   # Abstract base for subscription tools
    ├── claudecodemonitor.{h,cpp}         # Claude Code usage monitor
    ├── codexclimonitor.{h,cpp}           # Codex CLI usage monitor
    ├── copilotmonitor.{h,cpp}            # GitHub Copilot usage monitor
    ├── updatechecker.{h,cpp}             # GitHub release update checker
    ├── browsercookieextractor.{h,cpp}    # Firefox cookie extraction for browser sync
    └── usagedatabase.{h,cpp}       # SQLite usage history persistence
```

### C++ Plugin

The QML plugin (`com.github.loofi.aiusagemonitor`) provides 20 types:

- **`AppInfo`** — QML singleton exposing the build version (`AppInfo.version`) so update checks and About pages stay in sync with CMake/package metadata.
- **`SecretsManager`** — Wraps KWallet for secure API key storage. Uses wallet folder `"ai-usage-monitor"` with async open and a pending operations queue.
- **`ProviderBackend`** (abstract) — Base class with properties for token usage, rate limits, cost tracking (real and estimated), budget management, error tracking, and custom base URL support. Includes per-model pricing tables and `updateEstimatedCost()` for token-based cost estimation. Signals for quota warnings, budget exceeded, provider disconnect/reconnect.
- **`OpenAICompatibleProvider`** (abstract) — Intermediate base class for providers using OpenAI-compatible chat completions APIs. Handles sending a minimal completion request, parsing `x-ratelimit-*` headers, extracting token usage from response body, and calling `updateEstimatedCost()`. Subclasses only need to provide `name()`, `iconName()`, `defaultBaseUrl()`, and optionally override hooks.
- **`OpenAIProvider`** — Queries `GET /organization/usage/completions`, `GET /organization/costs`, and monthly costs. Reads `x-ratelimit-*` response headers. Requires an Admin API key.
- **`AnthropicProvider`** — Pings `POST /v1/messages/count_tokens`. Reads `anthropic-ratelimit-*` headers. Registers pricing for Claude models.
- **`GoogleProvider`** — Pings `POST /v1beta/models/{model}:countTokens`. Applies static known free-tier limits. Registers pricing for Gemini models.
- **`MistralProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for 6 Mistral models.
- **`DeepSeekProvider`** — Extends `OpenAICompatibleProvider`. Also fetches prepaid balance from `/user/balance`. Registers pricing for deepseek-chat and deepseek-reasoner.
- **`GroqProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for 5 Groq models.
- **`XAIProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for grok-3, grok-3-mini, grok-2.
- **`OpenRouterProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for 22 models. Fetches credits balance.
- **`TogetherProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for 12 models (Llama, Qwen, DeepSeek, Mixtral, Gemma).
- **`CohereProvider`** — Extends `OpenAICompatibleProvider`. Registers pricing for 7 Cohere models.
- **`GoogleVeoProvider`** — Google Veo video generation usage monitor.
- **`ClipboardHelper`** — Simple helper class for copying text to the system clipboard (replaces the previous TextArea workaround).
- **`UsageDatabase`** — SQLite persistence with WAL mode, configurable retention, auto-pruning, CSV/JSON export, and aggregated provider/tool series APIs for compare analytics.
- **`SubscriptionToolBackend`** (abstract) — Base class for subscription-based AI coding tool monitors. Tracks usage counts against fixed limits with rolling time windows (5-hour, daily, weekly, monthly). Supports dual primary/secondary periods, automatic period resets, and 80% limit warnings.
- **`ClaudeCodeMonitor`** — Monitors Claude Code CLI usage via `QFileSystemWatcher` on `~/.claude/`. Supports Pro/Max 5x/Max 20x plans with dual 5-hour session and weekly rolling windows.
- **`CodexCliMonitor`** — Monitors OpenAI Codex CLI usage via `QFileSystemWatcher` on `~/.codex/`. Supports Plus/Pro/Business plans with 5-hour rolling windows.
- **`CopilotMonitor`** — Monitors GitHub Copilot premium request usage with monthly period (resets 1st of month UTC). Supports Free/Pro/Pro+/Business/Enterprise plans. Optionally queries GitHub REST API for organization-level Copilot billing metrics.

### QML Frontend

- **`main.qml`** — Instantiates 10 C++ API backends + 3 subscription tool monitors, manages per-provider refresh timers, handles KWallet lifecycle, fires KDE notifications with cooldown and DND support, records snapshots to UsageDatabase. Uses `allProviders` and `allSubscriptionTools` arrays to drive tooltips, refresh, and notification routing.
- **`CompactRepresentation.qml`** — Panel icon with 3 display modes (icon with status badge, cost display, provider count), smooth animations, and screen reader accessibility
- **`FullRepresentation.qml`** — Popup with status summary bar, tabbed Live/History view, data-driven provider cards via Repeater, subscription tool cards section, detail history, compare mode (providers/tools + metrics), responsive history controls, loading/empty states, and export buttons
- **`MultiSeriesChart.qml`** — Multi-line comparison chart with compact legend chips, hover crosshair, and ranked per-series tooltip values
- **`ProviderCard.qml`** — Collapsible card showing connection status, token usage, cost (real or estimated), rate limit bars, budget progress bars, error badges with expandable details, relative time display, and accessibility annotations
- **`SubscriptionToolCard.qml`** — Card for subscription tool usage showing plan tier badge, color-coded progress bars for primary and secondary limits, time-until-reset countdown, last activity, limit-reached warning, and manual increment/reset buttons

## API Key Requirements

### OpenAI

You need an **Admin API key** (not a regular one) to access the usage and costs endpoints. Create one at [platform.openai.com/api-keys](https://platform.openai.com/api-keys) with the "Admin" role.

### Anthropic

A standard API key from [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys). The widget uses a lightweight `count_tokens` call that consumes no tokens.

### Google Gemini

A standard API key from [aistudio.google.com/apikey](https://aistudio.google.com/apikey). The widget only verifies connectivity and displays known tier limits.

### Mistral AI

A standard API key from [console.mistral.ai/api-keys](https://console.mistral.ai/api-keys).

### DeepSeek

A standard API key from [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

### Groq

A standard API key from [console.groq.com/keys](https://console.groq.com/keys).

### xAI / Grok

A standard API key from [console.x.ai](https://console.x.ai).

### OpenRouter

A standard API key from [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).

### Together AI

A standard API key from [api.together.ai/settings/api-keys](https://api.together.ai/settings/api-keys).

### Cohere

A standard API key from [dashboard.cohere.com/api-keys](https://dashboard.cohere.com/api-keys).

## RPM Packaging

An RPM spec file is included for Fedora/RHEL packaging:

```bash
rpmbuild -ba plasma-ai-usage-monitor.spec
```

## Troubleshooting

**Widget doesn't appear after install:**

```bash
plasmashell --replace &
```

**QML plugin not found:**
The C++ plugin must be installed to the system QML path (`/usr/lib64/qt6/qml/` on Fedora). The `install.sh` script and CMake handle this automatically with `sudo`.

**KWallet not opening:**
Make sure KWallet is enabled in System Settings > KDE Wallet. The widget requires KWallet to store API keys securely.

**OpenAI returns 403:**
The usage/costs endpoints require an Admin API key. Regular API keys will get a 403 Forbidden response.

**Usage history not recording:**
Check that the History tab is enabled in configuration. Data is stored in `~/.local/share/plasma-ai-usage-monitor/usage_history.db`.

## Documentation

| Document | Description |
|----------|-------------|
| [CHANGELOG.md](CHANGELOG.md) | Full version history from v1.0.0 to present |
| [SECURITY.md](SECURITY.md) | Security policy, vulnerability reporting, and design decisions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development setup, coding standards, and contribution workflow |

## Changelog

### v3.4.0 — Subscription Cost + Copilot Detection

- Add Copilot activity auto-detection from local IDE state/log paths
- Include subscription tool costs in compact and full total-cost summaries
- Add Firefox-only Browser Sync guidance and onboarding step improvements
- Add test coverage for Copilot activity increment detection

### v3.2.0 — AppStream & COPR Packaging

- Add AppStream metainfo for KDE Discover and AppStream catalogs
- Add COPR build infrastructure for Fedora package distribution
- Add `.plasmoid` archive as GitHub Release artifact
- Add AppStream validation in CI and RPM spec

### v3.1.0 — New Providers (OpenRouter, Together AI, Cohere)

- Add OpenRouter provider with 22-model pricing and credits balance
- Add Together AI provider with 12-model pricing
- Add Cohere provider with 7-model pricing
- Add unit tests for all 3 new providers

### v3.0.0 — 2026 Pricing Update

- Update model pricing tables for all providers to 2026 pricing
- Add new models for Anthropic, Google, Mistral, Groq, and xAI

See [CHANGELOG.md](CHANGELOG.md) for the full version history.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) for the full text.

## Author

**Loofi** — [github.com/loofitheboss](https://github.com/loofitheboss)
