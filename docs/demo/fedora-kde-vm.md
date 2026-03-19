## Fedora KDE Demo Environment

Use this workflow when you need a real Plasma session for live testing, polished screenshots, or release-candidate verification from a Windows workstation.

## Why a VM is the canonical path

- the widget is a Plasma 6 plasmoid, so screenshot quality depends on a real KDE desktop session
- a Windows-created Python virtual environment is not portable to Fedora Linux
- the demo workflow needs both the compiled QML plugin and the plasmoid package installed in a Linux environment

## Recommended host setup

- Windows 11 host with Hyper-V, VMware, or VirtualBox
- Fedora 43 KDE guest with a shared folder that points at this repository
- Firefox installed in the guest if you want to exercise Browser Sync diagnostics manually
- a clean user profile in the guest for screenshot capture

## Fedora guest packages

Install the normal build dependencies plus Python tooling for the demo helpers:

```bash
sudo dnf install \
  cmake extra-cmake-modules gcc-c++ just python3 python3-pip python3-venv firefox \
  qt6-qtbase qt6-qtbase-devel qt6-qtdeclarative-devel libplasma-devel \
  kf6-kwallet-devel kf6-ki18n-devel kf6-knotifications-devel kf6-kcoreaddons-devel
```

## Shared-workspace virtual environment

Create the repo-local `.venv` from inside the Fedora VM so the interpreter, scripts, and native paths all match the Linux runtime:

```bash
cd /path/to/shared/plasma-ai-usage-monitor
bash scripts/demo/bootstrap_demo_env.sh
source .venv/bin/activate
```

This environment is for the mock server and future capture helpers. Do not create the live-test `.venv` on Windows first.

## Optional Windows host helper environment

If you want to validate the mock server or JSON preset from the Windows workspace before booting the Fedora VM, you can create a separate host-only environment:

```powershell
./scripts/demo/bootstrap_demo_env.ps1
```

That script creates `.venv-host`, which is safe for Windows-side helper usage and does not conflict with the Fedora `.venv` used for real widget testing.

## Start the mocked demo server

With the Linux `.venv` active:

```bash
python scripts/demo/mock_ai_usage_server.py
```

By default the mock server listens on `http://127.0.0.1:8787` and serves the `scripts/demo/showcase_preset.json` values.

## Install the widget inside the VM

For a first full install in the guest, prefer the compiled-plugin path:

```bash
just build-debug
sudo cmake --install build
just install-user
just reload
```

For later QML-only iterations, you can usually use:

```bash
just dev
```

## Suggested mock base URLs

Point providers at the following custom base URLs so the widget renders deterministic screenshot-safe values:

| Surface       | Custom base URL                               |
| ------------- | --------------------------------------------- |
| OpenAI        | `http://127.0.0.1:8787/mock/openai/v1`        |
| Anthropic     | `http://127.0.0.1:8787/mock/anthropic/v1`     |
| Google Gemini | `http://127.0.0.1:8787/mock/google/v1beta`    |
| Mistral       | `http://127.0.0.1:8787/mock/mistral`          |
| DeepSeek      | `http://127.0.0.1:8787/mock/deepseek`         |
| Groq          | `http://127.0.0.1:8787/mock/groq`             |
| xAI           | `http://127.0.0.1:8787/mock/xai`              |
| OpenRouter    | `http://127.0.0.1:8787/mock/openrouter`       |
| Together AI   | `http://127.0.0.1:8787/mock/together`         |
| Cohere        | `http://127.0.0.1:8787/mock/cohere`           |
| Google Veo    | `http://127.0.0.1:8787/mock/googleveo/v1beta` |
| Azure OpenAI  | `http://127.0.0.1:8787/mock/azure`            |
| Loofi Server  | `http://127.0.0.1:8787/mock/loofi`            |

## Canonical demo preset

The mocked preset is designed for media capture rather than exhaustive functional testing:

- multiple connected providers with visible cost, request, and quota bars
- one richer card with balance or credits data
- a Loofi card with active model, training stage, and GPU memory percentage
- subscription cards driven by local/manual controls instead of live secrets
- a clean history/compare scene populated by manual refreshes during the session

Adjust `scripts/demo/showcase_preset.json` if you need different numbers for a capture session.

## Screenshot flow

1. boot the VM into a clean Plasma session
2. start the mock server
3. install or reload the widget
4. apply the canonical mock base URLs
5. use the shot list in `assets/screenshots/README.md`
6. review every capture at full size before replacing the canonical assets

## Notes for manual QA

- verify the popup after a cold Plasma restart
- verify at least one manual refresh per enabled provider
- verify that screenshots do not include personal data, local hostnames, or browser sessions
- keep the panel layout stable between shots so the GitHub and KDE Store media set looks intentional
