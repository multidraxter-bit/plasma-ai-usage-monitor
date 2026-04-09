#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "=== Plasma AI Usage Monitor - Dev Smoke Check ==="
echo

bash scripts/show_installed_versions.sh
echo

USER_PLASMOID_DIR="${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor"
BUILD_DIR="${ROOT_DIR}/build"

if [[ -d "$USER_PLASMOID_DIR" ]]; then
  echo "Local plasmoid package: present"
else
  echo "Local plasmoid package: not installed"
fi

if [[ -d "$BUILD_DIR" ]]; then
  echo "Build directory: present (${BUILD_DIR})"
else
  echo "Build directory: missing"
fi

echo
echo "Recommended next step:"
if [[ -d "$BUILD_DIR" ]]; then
  echo "  - QML-only changes: just dev"
  echo "  - C++ plugin changes: just install && just reload"
else
  echo "  - QML-only changes: just dev"
  echo "  - First C++ build/install: just build-debug && just install && just reload"
fi

echo
echo "If the widget still looks stale after reload:"
echo "  - run: just versions"
echo "  - if the user-local package shadows the system install, remove it with: just uninstall-user"
echo "  - if the plasmoid package is present but the compiled plugin is missing, rebuild/install the plugin before reloading Plasma"
