# Roadmap — Plasma AI Usage Monitor

> **Current version:** v3.7.0 (Azure OpenAI dedicated provider + wiring hardening)
> **Last updated:** 2026-02-26

---

## Version Summary

| Version | Codename | Theme | Status |
|---------|----------|-------|--------|
| v3.7.0 | **Pulse** | Azure OpenAI Dedicated Provider (no OpenAI aliasing) | Released |
| v3.6.0 | **Pulse** | Azure OpenAI Provider Wiring | Released |
| v3.5.3 | **Pulse** | Release Plasmoid Packaging Stability Hotfix (ZIP timestamp clamp) | Released |
| v3.5.2 | **Pulse** | Release Packaging Stability Hotfix (deterministic tarballing) | Released |
| v3.5.1 | **Pulse** | Release Workflow Hotfix (AppStream icon validation) | Released |
| v3.5.0 | **Pulse** | Packaging Consistency Hardening | Released |
| v3.4.0 | **Pulse** | Subscription Cost Aggregation + Copilot Activity Detection | Released |
| v4.0.0 | **Horizon** | UX Polish + Provider Expansion | Active |
| v5.0.0 | **Lighthouse** | Intelligence + Forecasting | Planned |
| v6.0.0 | **Nexus** | Team + Multi-User | Planned |
| v7.0.0 | **Forge** | Extensibility + Ecosystem | Planned |
| v8.0.0 | **Cosmos** | Cross-Platform + Cloud | Planned |

---

## v4.0.0 — "Horizon" (UX Polish + Provider Expansion)

**Goal:** Expand provider coverage to all major AI services, harden browser sync, improve the dashboard UI, and add packaging for broader distribution.

### New Providers

| Feature | Description | Priority |
|---------|-------------|----------|
| **Google Veo** | Video generation API monitoring — token/frame usage, cost estimation (provider file already scaffolded as `googleveoprovider.cpp`) | High |
| **AWS Bedrock** | Monitor cross-model usage via Bedrock billing API (Claude, Llama, Mistral, Titan on AWS) | High |
| **Azure OpenAI** | Track Azure-hosted OpenAI deployments — separate from openai.com billing, uses Azure metering API *(Dedicated provider backend, deploymentId UI wiring, and Azure test coverage completed in 3.7.0; metering endpoint refinements pending)* | Medium |
| **Perplexity AI** | OpenAI-compatible API with search credits tracking | Medium |
| **Fireworks AI** | Serverless inference — OpenAI-compatible, credit balance endpoint | Low |

### New Subscription Tools

| Feature | Description | Priority |
|---------|-------------|----------|
| **Cursor AI** | Track Cursor Pro/Business premium request limits — filesystem watcher on `~/.cursor/` | High |
| **Windsurf (Codeium)** | Monitor Windsurf/Codeium Pro flow action credits — filesystem watcher on `~/.codeium/` | High |
| **JetBrains AI Assistant** | Track JetBrains AI monthly quota — config dir at `~/.config/JetBrains/` | Medium |

### Browser Sync Improvements

| Feature | Description | Priority |
|---------|-------------|----------|
| **Chrome/Chromium cookie support** | Decrypt Chrome's encrypted `Cookies` database via DPAPI/libsecret for browser sync on non-Firefox browsers | High |
| **Multi-browser profile support** | Detect and list multiple Firefox/Chrome profiles, let user select which profile to sync | Medium |
| **Remove "Experimental" label** | Harden sync with retry logic, connection health checks, and graceful degradation — promote to stable feature | Medium |
| **Session persistence** | Cache last-known sync state to survive widget restarts without immediate re-sync | Low |

### UI/UX Improvements

| Feature | Description | Priority |
|---------|-------------|----------|
| **Dashboard redesign** | Unified overview page with grid of mini-cards, aggregate cost/token gauges, and at-a-glance status for all providers | High |
| **Dark/light theme awareness** | Inherit Plasma color scheme properly in all chart canvases, cards, and popups — fix any hardcoded colors | High |
| **Interactive cost breakdown** | Drill-down pie chart showing cost distribution across providers for selected time range | Medium |
| **Stacked area chart** | New chart mode showing combined provider costs/tokens over time as stacked layers | Medium |
| **Keyboard navigation** | Full keyboard accessibility for all interactive elements (cards, charts, config tabs) | Medium |
| **Responsive popup sizing** | Auto-adjust popup height based on enabled providers/tools to avoid scrolling with few providers | Low |

### Packaging & Distribution

| Feature | Description | Priority |
|---------|-------------|----------|
| **Flatpak package** | Build and publish as a Flatpak for distro-agnostic installation | High |
| **Arch Linux AUR** | PKGBUILD for AUR publishing | Medium |
| **openSUSE OBS** | Open Build Service package for SUSE/openSUSE | Low |
| **KDE Store submission** | Publish plasmoid on store.kde.org for 1-click install from Plasma's widget browser | High |

### Infrastructure

| Feature | Description | Priority |
|---------|-------------|----------|
| **QML test framework** | Add QML unit tests for UI logic (Utils.js functions, config validation, display mode switching) | High |
| **Integration tests** | End-to-end tests with mocked HTTP server verifying full refresh → DB write → UI update cycle | Medium |
| **CI: Flatpak build** | GitHub Actions workflow to build and validate Flatpak package | Medium |
| **Automated screenshot generation** | CI script using `plasmawindowed` + `import` to capture widget screenshots for README/store listing | Low |

---

## v5.0.0 — "Lighthouse" (Intelligence + Forecasting)

**Goal:** Transform from a passive monitor into an intelligent cost advisor with predictive analytics, anomaly detection, and optimization recommendations.

### Predictive Analytics

| Feature | Description | Priority |
|---------|-------------|----------|
| **Cost forecasting** | Linear regression + exponential smoothing on historical data to project end-of-month cost per provider | High |
| **Budget burn-rate indicator** | Calculate current spending velocity and project when daily/monthly budgets will be exhausted | High |
| **Usage trend prediction** | Predict token/request usage trends based on historical patterns (weekday vs weekend, time-of-day) | Medium |
| **Forecast confidence bands** | Show prediction intervals (p25/p75/p95) on forecast charts | Low |

### Anomaly Detection

| Feature | Description | Priority |
|---------|-------------|----------|
| **Spending spike alerts** | Detect unusual cost increases (>2σ from rolling average) and fire KDE notification with details | High |
| **Rate limit surge detection** | Alert when rate limit consumption pattern suggests imminent throttling | Medium |
| **Dead provider detection** | Detect providers that haven't returned data in N refresh cycles and flag them | Medium |
| **Anomaly history log** | Persistent log of detected anomalies with timestamps, severity, and resolution status | Low |

### Cost Optimization

| Feature | Description | Priority |
|---------|-------------|----------|
| **Model cost comparison** | Side-by-side table comparing $/1M tokens across all providers for equivalent-capability models | High |
| **Cheaper alternative suggestions** | When a user's primary model has a cheaper equivalent (e.g., GPT-4o-mini vs GPT-4o), show a suggestion badge | High |
| **Cost-per-quality score** | Weighted score combining cost, latency, and capability tier for informed model selection | Medium |
| **Monthly cost report** | Auto-generated end-of-month summary with top spending providers, trends, and optimization tips | Medium |
| **What-if calculator** | "If I switch from model X to model Y, how much would I save per month?" simulation tool | Low |

### Smart Alerts

| Feature | Description | Priority |
|---------|-------------|----------|
| **Adaptive thresholds** | Automatically adjust warning thresholds based on historical usage patterns instead of fixed percentages | High |
| **Alert prioritization** | Suppress low-impact alerts during high-usage periods, escalate unusual patterns | Medium |
| **Alert digest** | Batch non-urgent notifications into a single periodic digest instead of individual popups | Medium |
| **Custom alert rules** | User-defined conditions (e.g., "alert if Anthropic cost > $5/day AND requests > 100") using a simple expression builder | Low |

### Data & Visualization

| Feature | Description | Priority |
|---------|-------------|----------|
| **Heatmap view** | Calendar heatmap showing daily cost intensity (like GitHub contribution graph) | Medium |
| **Token efficiency chart** | Output-to-input token ratio over time — detect if prompts are becoming less efficient | Medium |
| **Cost-per-request trends** | Track average cost per API request to detect model pricing drift or usage pattern changes | Low |
| **Export to Google Sheets** | One-click export of usage data to a Google Sheet via OAuth (optional cloud feature) | Low |

---

## v6.0.0 — "Nexus" (Team + Multi-User)

**Goal:** Enable team and organization-level AI cost management with shared dashboards, policy enforcement, and external integrations.

### Team Features

| Feature | Description | Priority |
|---------|-------------|----------|
| **Multi-user aggregation** | Aggregate usage data from multiple machines into a central SQLite or PostgreSQL database | High |
| **Team dashboard** | Shared read-only web view showing combined team spending, per-user breakdown, and budget utilization | High |
| **Shared budget pools** | Define organization-wide budget limits that span all team members' usage | Medium |
| **Per-user quotas** | Set individual usage limits within team budgets with automatic enforcement notifications | Medium |
| **Usage leaderboard** | Ranked list of team members by cost/tokens/requests with opt-in privacy controls | Low |

### Integration Hub

| Feature | Description | Priority |
|---------|-------------|----------|
| **Slack webhook alerts** | Send budget warnings, anomaly detections, and daily digests to a Slack channel | High |
| **Discord webhook alerts** | Same as Slack but for Discord servers | High |
| **Email digest** | Scheduled email reports (daily/weekly/monthly) with cost summaries and trends | Medium |
| **Grafana data source** | Expose usage metrics via HTTP endpoint for Grafana dashboard integration | Medium |
| **Prometheus exporter** | `/metrics` endpoint exposing provider costs, tokens, rate limits as Prometheus gauges/counters | Medium |
| **PagerDuty/OpsGenie** | Critical alert routing to incident management platforms | Low |

### Policy & Governance

| Feature | Description | Priority |
|---------|-------------|----------|
| **Usage policies** | Define rules like "no API calls between 2-6 AM" or "max $50/day per user" with configurable enforcement (warn/block) | High |
| **Audit trail** | Immutable log of all API key changes, budget modifications, and policy updates with timestamps and user attribution | High |
| **Cost allocation tags** | Tag API usage by project/department/team for chargeback accounting | Medium |
| **Compliance reports** | Generated reports showing budget adherence, policy violations, and usage patterns for management review | Low |

### External Data Sources

| Feature | Description | Priority |
|---------|-------------|----------|
| **OpenAI Billing API v2** | Adopt new OpenAI billing/credits API when available for more granular cost data | High |
| **Anthropic Console API** | Monitor Anthropic workspace billing when/if API becomes available | Medium |
| **GCP billing export** | Import Google Cloud billing data for Vertex AI / Gemini API usage | Medium |
| **AWS Cost Explorer** | Pull Bedrock costs from AWS Cost Explorer API | Medium |

---

## v7.0.0 — "Forge" (Extensibility + Ecosystem)

**Goal:** Open the platform for community contributions with a plugin system, local AI monitoring, scripting APIs, and first-class developer tooling.

### Plugin System

| Feature | Description | Priority |
|---------|-------------|----------|
| **Provider plugin API** | Define a C++ abstract interface + QML component template for adding custom providers without modifying core code | High |
| **Plugin loader** | Discover and load provider plugins from `~/.local/share/plasma-ai-usage-monitor/plugins/` at startup | High |
| **Plugin metadata spec** | JSON manifest format for plugins (name, version, author, provider type, dependencies) | High |
| **Plugin manager UI** | Settings tab to enable/disable/configure installed plugins | Medium |
| **Plugin marketplace** | Simple catalog (GitHub-hosted JSON index) listing community-contributed plugins | Low |

### Local AI Monitoring

| Feature | Description | Priority |
|---------|-------------|----------|
| **Ollama integration** | Monitor Ollama server usage — model loads, token generation speed, GPU memory, and inference costs (electricity-based) | High |
| **llama.cpp / vLLM** | Track local inference via log parsing or API endpoint monitoring | Medium |
| **GPU utilization** | Display NVIDIA (`nvidia-smi`) or AMD (`rocm-smi`) GPU usage when running local models | Medium |
| **Local vs cloud cost comparison** | Compare the electricity/hardware cost of local inference vs cloud API pricing for the same model family | Low |
| **LM Studio** | Monitor LM Studio serving metrics via its local API | Low |

### Developer Tooling

| Feature | Description | Priority |
|---------|-------------|----------|
| **D-Bus interface** | Expose provider status, costs, and budget data via D-Bus for scripting and integration with other Linux apps | High |
| **CLI companion tool** | Standalone command-line tool (`ai-usage-cli`) for querying usage data, exporting reports, and managing budgets without a running Plasma session | High |
| **Systemd user service** | Optional background service for continuous data collection independent of Plasma Shell (for headless servers or Wayland compositors without Plasma) | Medium |
| **KRunner plugin** | Search and display AI usage stats from KRunner (Alt+Space) | Medium |
| **Shell widget** | Minimal shell script that reads the SQLite database and prints usage summary to terminal | Low |

### Data Management

| Feature | Description | Priority |
|---------|-------------|----------|
| **Database migration system** | Versioned schema migrations for SQLite database to handle upgrades cleanly | High |
| **Backup & restore** | One-click backup of usage history database and settings to a compressed archive | Medium |
| **Data deduplication** | Detect and merge duplicate snapshots (race conditions from rapid refreshes) | Medium |
| **Multi-database support** | Optionally use PostgreSQL or MySQL for team deployments instead of SQLite | Low |

### Community & Publishing

| Feature | Description | Priority |
|---------|-------------|----------|
| **Full i18n framework** | Complete KDE i18n integration with `.po` files, Weblate project for community translations | High |
| **Developer documentation** | Plugin authoring guide, API reference, architecture overview for contributors | High |
| **KDE Store featured listing** | Screenshots, demo video, and polished metadata for KDE Store listing | Medium |
| **Fedora/COPR repo** | Publish RPM updates to a COPR repository for easy `dnf install` on Fedora | Medium |

---

## v8.0.0 — "Cosmos" (Cross-Platform + Cloud)

**Goal:** Break beyond KDE Plasma to reach users on any desktop, platform, or device with cloud sync, mobile companion, and advanced ML-powered insights.

### Cross-Desktop Support

| Feature | Description | Priority |
|---------|-------------|----------|
| **GNOME Shell extension** | Port core monitoring to a GNOME Shell extension using GJS + libsoup | High |
| **System tray fallback** | Generic system tray widget using Qt6 for desktops without Plasma or GNOME (XFCE, MATE, i3, Sway, Hyprland) | High |
| **macOS menu bar** | Native SwiftUI/AppKit menu bar app using shared backend logic via C++ bridge | Medium |
| **Windows system tray** | Qt6-based system tray application for Windows using the same C++ plugin library | Medium |

### Cloud Sync

| Feature | Description | Priority |
|---------|-------------|----------|
| **Cloud data sync** | Optional encrypted sync of usage history to a self-hosted or managed backend (e.g., Supabase, Firebase, or custom REST API) | High |
| **Multi-machine aggregation** | Merge usage data from multiple devices into a unified view | High |
| **Conflict resolution** | Handle concurrent updates from multiple machines with last-write-wins or CRDT-based merging | Medium |
| **End-to-end encryption** | All cloud-synced data encrypted client-side with user-controlled key before upload | High |

### Companion Apps

| Feature | Description | Priority |
|---------|-------------|----------|
| **Web dashboard** | Responsive web app (React/Vue) for viewing usage data, charts, and managing budgets from any browser | High |
| **Mobile companion (Android)** | KDE Connect integration or standalone Android app showing real-time cost/usage notifications | Medium |
| **Mobile companion (iOS)** | Lightweight iOS app with push notifications for budget alerts | Low |
| **Electron desktop app** | Cross-platform desktop app wrapping the web dashboard for non-Linux users who want a native window | Low |

### Advanced Intelligence

| Feature | Description | Priority |
|---------|-------------|----------|
| **ML anomaly detection** | Isolation forest or autoencoder-based anomaly detection trained on user's historical patterns | Medium |
| **Natural language insights** | LLM-generated plain-English summaries of usage trends (e.g., "Your Anthropic spending is 3x higher this week, driven by Claude Sonnet usage") — runs locally via Ollama if available | Medium |
| **Auto-budget recommendation** | Analyze 30-day history and recommend optimal budget limits per provider | Medium |
| **Usage pattern clustering** | Identify distinct usage patterns (e.g., "development sprints" vs "normal usage") and show them as named phases | Low |
| **Carbon footprint estimation** | Estimate CO₂ emissions from API usage based on provider data center locations and energy mix | Low |

### Enterprise

| Feature | Description | Priority |
|---------|-------------|----------|
| **SSO/LDAP authentication** | Enterprise single sign-on for team dashboard and cloud sync | Medium |
| **Role-based access** | Admin/viewer/analyst roles for team features | Medium |
| **SLA monitoring** | Track API uptime, response latency percentiles, and error rates against SLA commitments | Medium |
| **Invoicing integration** | Export usage data in formats compatible with accounting software (QuickBooks, Xero CSV) | Low |
| **White-label support** | Rebrandable deployment for organizations that want custom naming/theming | Low |

---

## Completed Versions

| Version | Date | Highlights |
|---------|------|------------|
| v3.6.0 | 2026-02-26 | Azure OpenAI provider backend dispatch + normalization, provider test coverage, and full UI/config wiring (providers, alerts, budgets) |
| v3.5.2 | 2026-02-26 | Source tarball packaging switched to tracked-file archiving to prevent CI tar race failures in release workflow |
| v3.5.1 | 2026-02-26 | AppStream metainfo icon validation hotfix to unblock GitHub release workflow |
| v3.5.0 | 2026-02-26 | Flatpak scaffold validation hardening, packaging consistency checks added to build/release workflows, deterministic packaging check baseline documented |
| v3.4.0 | 2026-02-26 | Subscription-tool cost aggregation in totals, Copilot IDE activity auto-detection, Firefox-only Browser Sync clarification, onboarding flow update, Copilot detection regression test |
| v3.3.0 | 2026-02-25 | Guided install/doctor UX, first-run setup wizard, Browser Sync profile persistence |
| v3.2.0 | 2026-02-22 | AppStream metainfo, COPR build infra, release artifact and packaging validation |
| v3.1.0 | 2026-02-20 | OpenRouter, Together AI, Cohere providers |
| v3.0.0 | 2026-02-19 | 2026 pricing update, new models for all providers |
| v2.9.0 | 2026-02-18 | 43 new C++ unit tests across 4 test files |
| v2.8.2 | 2026-02-16 | Mocked HTTP tests, subscription tests, clang-tidy CI gate |
| v2.8.1 | 2026-02-16 | Version display fix, install/reload scripts |
| v2.8.0 | 2026-02-16 | Compare analytics mode, multi-series chart, AppInfo singleton |
| v2.7.0 | 2026-02-17 | Reliability fixes (reply-after-delete, DB connection, timer bindings) |
| v2.6.0 | 2026-02-16 | Request lifecycle hardening, generation counters, cookie cache |
| v2.5.0 | 2026-02-16 | Centralized request builder, retry with backoff, budget signals, HTTPS warnings |
| v2.4.0 | 2026-02-17 | Model badge, cost toggle, chart tooltips, Bézier curves |
| v2.3.0 | 2026-02-16 | Browser cookie sync (experimental), subscription cost display |
| v2.2.0 | 2026-02-15 | Subscription tool tracking (Claude Code, Codex CLI, GitHub Copilot) |
| v2.1.0 | 2026-02-15 | OpenAI-compatible base class, cost estimation, collapsible cards |
| v2.0.0 | 2026-02-15 | 4 new providers, SQLite history, budgets, data export |
| v1.0.0 | 2026-02-15 | Initial release (OpenAI, Anthropic, Google Gemini) |

---

## Research Notes

### AI API Monitoring Landscape (2026)

Key trends informing this roadmap:

1. **Provider proliferation** — The AI provider market has fragmented. Users commonly juggle 5-10 providers simultaneously. Provider-agnostic monitoring is essential.

2. **Subscription tool explosion** — AI coding assistants (Cursor, Windsurf, Copilot, Claude Code, Codex, JetBrains AI, Tabnine) all have different quota models. Users need unified tracking.

3. **Cost unpredictability** — With token-based pricing, reasoning models (o1, o3, DeepSeek R1), and variable output lengths, monthly AI costs are hard to predict. Forecasting is a top user request.

4. **Team cost management** — Organizations struggle to track per-developer AI spending. Chargeback and allocation tooling is immature at the individual level.

5. **Local AI growth** — Ollama has become mainstream for local inference. Users want to compare local (electricity) vs cloud (API) costs for the same model families.

6. **Multi-modal expansion** — Video (Veo, Sora), image (DALL-E, Midjourney), and audio (ElevenLabs) APIs add new cost dimensions beyond text tokens.

7. **Compliance requirements** — Enterprise teams increasingly need audit trails, usage policies, and export capabilities for AI cost governance.

### Competitive Analysis

| Tool | Platform | Providers | Local AI | Forecasting | Team |
|------|----------|-----------|----------|-------------|------|
| **This widget** | KDE Plasma 6 | 10 + 3 subs | No | No | No |
| OpenAI Dashboard | Web | OpenAI only | No | No | Org-level |
| Helicone | Web (SaaS) | Proxy-based | No | Yes | Yes |
| LangSmith | Web (SaaS) | LangChain ecosystem | No | Limited | Yes |
| LiteLLM | CLI/Web | Proxy-based | No | No | Yes |
| Portkey | Web (SaaS) | Gateway-based | No | Yes | Yes |

**Our differentiation:** Native desktop widget (always visible), no proxy/gateway required (direct API polling), subscription tool tracking, fully offline/local, open source, KDE-native UX.

### Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Provider API changes | Medium | Version-pinned API clients, graceful degradation |
| Browser sync breakage | High | Abstraction layer, multiple extraction backends, user warnings |
| KDE Plasma API changes | Low | Pin to stable KF6 APIs, test against Plasma 6.x releases |
| Feature bloat | Medium | Strict version scoping, user-configurable feature toggles |
| Cross-platform complexity | High | Shared C++ core with platform-specific shells |

