#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

METHOD="auto"
ASSUME_YES=false
DRY_RUN=false
INSTALL_MISSING=false

usage() {
  cat <<'USAGE'
install_bootstrap.sh - guided installation helper for Plasma AI Usage Monitor

Usage:
  scripts/install_bootstrap.sh [--method auto|copr|source|user] [--yes] [--dry-run] [--install-missing]

Options:
  --method <mode>     auto (default), copr, source, or user.
  --yes               Skip interactive confirmation prompts.
  --dry-run           Print commands without executing.
  --install-missing   For source installs on Fedora, install missing deps via doctor.
  -h, --help          Show this help.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --method)
      shift
      METHOD="${1:-}"
      ;;
    --yes)
      ASSUME_YES=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --install-missing)
      INSTALL_MISSING=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

OS_ID="unknown"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  OS_ID="${ID:-unknown}"
fi

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run]'
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
  else
    "$@"
  fi
}

confirm_or_exit() {
  local prompt="$1"
  if [[ "$ASSUME_YES" == true ]]; then
    return 0
  fi

  read -r -p "$prompt [y/N]: " answer
  case "$answer" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "Cancelled."
      exit 1
      ;;
  esac
}

if [[ "$METHOD" == "auto" ]]; then
  if [[ "$OS_ID" == "fedora" ]] && command -v dnf >/dev/null 2>&1; then
    METHOD="copr"
  else
    METHOD="source"
  fi
fi

case "$METHOD" in
  copr)
    if [[ "$OS_ID" != "fedora" ]] || ! command -v dnf >/dev/null 2>&1; then
      echo "COPR install is only supported on Fedora with dnf."
      exit 1
    fi

    confirm_or_exit "Install from COPR (system-wide, requires sudo)?"
    run_cmd sudo dnf copr enable loofitheboss/plasma-ai-usage-monitor
    run_cmd sudo dnf install -y plasma-ai-usage-monitor
    ;;

  source)
    if [[ "$INSTALL_MISSING" == true ]]; then
      run_cmd bash "$ROOT_DIR/scripts/install_doctor.sh" --install-missing
    else
      run_cmd bash "$ROOT_DIR/scripts/install_doctor.sh"
    fi

    confirm_or_exit "Build and install from source to /usr (requires sudo)?"
    run_cmd cmake -S "$ROOT_DIR" -B "$ROOT_DIR/build" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release

    if command -v nproc >/dev/null 2>&1; then
      jobs="$(nproc)"
    else
      jobs="4"
    fi
    run_cmd cmake --build "$ROOT_DIR/build" --parallel "$jobs"
    run_cmd sudo cmake --install "$ROOT_DIR/build"

    # Check for stale user-local copy that would shadow system install
    USER_META="${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"
    SYS_META="/usr/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"
    if [[ -f "$USER_META" ]]; then
      user_ver=$(sed -n 's/.*"Version": "\([0-9.]*\)".*/\1/p' "$USER_META" | head -1)
      sys_ver=$(sed -n 's/.*"Version": "\([0-9.]*\)".*/\1/p' "$SYS_META" 2>/dev/null | head -1 || echo "unknown")
      if [[ -n "$user_ver" && "$user_ver" != "$sys_ver" ]]; then
        echo
        echo "WARNING: Stale user-local version detected!"
        echo "  User-local: $user_ver  (~/.local/share/plasma/plasmoids/...)"
        echo "  System:     $sys_ver   (/usr/share/plasma/plasmoids/...)"
        echo "  The user-local copy shadows the system install."
        echo "  Fix: kpackagetool6 --type Plasma/Applet --remove com.github.loofi.aiusagemonitor"
        echo "  Or:  just uninstall-user"
      fi
    fi
    ;;

  user)
    confirm_or_exit "Install user-local plasmoid only (no C++ plugin install)?"
    run_cmd bash "$ROOT_DIR/scripts/install_local_plasmoid.sh"
    run_cmd bash "$ROOT_DIR/scripts/reload_plasma.sh"
    ;;

  *)
    echo "Invalid method: $METHOD"
    usage
    exit 2
    ;;
esac

echo
echo "Install/bootstrap complete."

# Offer plasmashell reload so widget appears immediately
if command -v plasmashell >/dev/null 2>&1; then
  if [[ "$ASSUME_YES" == true ]]; then
    echo "Reloading plasmashell to activate widget..."
    run_cmd bash "$ROOT_DIR/scripts/reload_plasma.sh"
  else
    echo
    read -r -p "Reload plasmashell now to make widget appear? [Y/n]: " reload_answer
    case "${reload_answer:-y}" in
      y|Y|yes|YES|"")
        run_cmd bash "$ROOT_DIR/scripts/reload_plasma.sh"
        ;;
      *)
        echo "Skipped. Run manually: ./scripts/reload_plasma.sh"
        ;;
    esac
  fi
fi

echo
echo "Next steps:"
echo "  1. Right-click panel → Add Widgets → search 'AI Usage Monitor'"
echo "  2. Right-click widget → Configure → add your API keys"
echo "  3. If widget still not visible, run: ./scripts/show_installed_versions.sh"
