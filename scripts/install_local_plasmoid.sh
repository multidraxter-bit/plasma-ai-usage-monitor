#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
  echo "kpackagetool6 not found. Install KDE Plasma 6 development tools first."
  exit 1
fi

PLASMOID_ID="com.github.loofi.aiusagemonitor"
USER_PLASMOID_DIR="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"

if [[ -d "$USER_PLASMOID_DIR" ]]; then
  echo "Upgrading local plasmoid package from: ${ROOT_DIR}/package"
  kpackagetool6 --type Plasma/Applet --upgrade "${ROOT_DIR}/package"
else
  echo "Installing local plasmoid package from: ${ROOT_DIR}/package"
  kpackagetool6 --type Plasma/Applet --install "${ROOT_DIR}/package"
fi

echo "Done. Local package installed at:"
echo "  ${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor"
echo
echo "Next step:"
echo "  - For QML-only changes, reload Plasma: ./scripts/reload_plasma.sh"
echo "  - For C++ plugin changes, a plasmoid-only install is not enough; rebuild and reinstall the plugin before reloading Plasma"
