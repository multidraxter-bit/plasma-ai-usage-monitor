#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "install.sh now delegates to scripts/install_bootstrap.sh"
echo
exec bash "$ROOT_DIR/scripts/install_bootstrap.sh" \
  --method auto \
  --install-missing \
  --yes \
  "$@"
