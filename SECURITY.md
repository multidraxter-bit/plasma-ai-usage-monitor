# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in AI Usage Monitor, please report it responsibly:

1. **Email:** Send details to <loofi@github.com>
2. **GitHub:** Open a [security advisory](https://github.com/multidraxter-bit/plasma-ai-usage-monitor/security/advisories/new) (private by default)

Please include:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We aim to respond within **48 hours** and release a fix within **7 days** for critical issues.

**Do not** open a public GitHub issue for security vulnerabilities.

## Scope

The following components are in scope for security reports:

| Component | Concern |
|-----------|---------|
| **KWallet integration** (`secretsmanager.cpp`) | API key storage and retrieval |
| **Browser cookie extraction** (`browsercookieextractor.cpp`) | Firefox session cookie handling |
| **Network requests** (all providers) | API key transmission, TLS enforcement |
| **SQLite database** (`usagedatabase.cpp`) | Local data storage and access |
| **Custom base URLs** | Proxy/gateway URL validation |

## Security Design

### API Key Storage

- All API keys are stored in **KDE Wallet (KWallet)**, never written to config files on disk
- Keys are accessed via the `SecretsManager` class using the wallet folder `"ai-usage-monitor"`
- If KWallet is unavailable, the widget cannot store or retrieve keys — there is no insecure fallback

### Network Security

- All provider API calls use **HTTPS** by default
- Custom base URLs display an inline **security warning** if an `http://` (non-HTTPS) URL is entered
- All network requests have a **30-second timeout**
- Retry logic respects `Retry-After` headers from rate-limited responses

### Browser Cookie Handling

- Cookie extraction reads Firefox's `cookies.sqlite` database in **read-only mode**
- Temporary copies of the cookie database use **owner-only permissions** (0600)
- Cookie data is used only for direct API calls to the same services — never stored, logged, or transmitted elsewhere
- Browser sync is **disabled by default** and marked as experimental

### Data Privacy

- **No telemetry** — the widget does not phone home or send analytics
- **All data stays local** — usage history in SQLite, keys in KWallet
- **No cloud sync** — all API calls go directly to provider endpoints

### Build Security

- CI builds with **warnings-as-errors** to catch potential issues
- Version consistency checks prevent metadata drift
- C++20 with modern compiler warnings enabled

## Supported Versions

| Version | Supported |
|---------|-----------|
| 2.x.x   | ✅ Yes    |
| 1.x.x   | ❌ No     |

## Dependencies

Key runtime dependencies and their security relevance:

| Dependency | Purpose | Trust Level |
|-----------|---------|-------------|
| Qt 6 (Network, Sql) | HTTP requests, SQLite | Upstream (Qt Project) |
| KWallet (KF6) | Secret storage | Upstream (KDE) |
| KNotifications (KF6) | Desktop alerts | Upstream (KDE) |
| SQLite | Usage history | Bundled in Qt |
