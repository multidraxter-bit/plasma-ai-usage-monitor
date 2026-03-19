#!/usr/bin/env bash
set -euo pipefail

AUTO_INSTALL=false
STRICT=false

usage() {
  cat <<'USAGE'
install_doctor.sh - preflight checks for building/installing Plasma AI Usage Monitor

Usage:
  scripts/install_doctor.sh [--install-missing] [--strict]

Options:
  --install-missing  On Fedora, install missing build dependencies with dnf.
  --strict           Exit non-zero if any warning-level runtime tool is missing.
  -h, --help         Show this help.
USAGE
}

while (($# > 0)); do
  case "$1" in
    --install-missing)
      AUTO_INSTALL=true
      ;;
    --strict)
      STRICT=true
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
OS_PRETTY="Unknown"
if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  source /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_PRETTY="${PRETTY_NAME:-$OS_ID}"
fi

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "ok"
  else
    echo "missing"
  fi
}

required_cmds=(cmake g++ kpackagetool6)
warning_cmds=(plasmashell plasmawindowed)

missing_required=()
missing_warning=()
for cmd in "${required_cmds[@]}"; do
  if [[ "$(check_cmd "$cmd")" == "missing" ]]; then
    missing_required+=("$cmd")
  fi
done
for cmd in "${warning_cmds[@]}"; do
  if [[ "$(check_cmd "$cmd")" == "missing" ]]; then
    missing_warning+=("$cmd")
  fi
done

fedora_packages=(
  cmake
  extra-cmake-modules
  gcc-c++
  qt6-qtbase
  qt6-qtbase-devel
  qt6-qtdeclarative-devel
  libplasma-devel
  kf6-kwallet-devel
  kf6-ki18n-devel
  kf6-knotifications-devel
  kf6-kcoreaddons-devel
)

missing_fedora_packages=()
if [[ "$OS_ID" == "fedora" ]] && command -v rpm >/dev/null 2>&1; then
  for pkg in "${fedora_packages[@]}"; do
    if ! rpm -q "$pkg" >/dev/null 2>&1; then
      missing_fedora_packages+=("$pkg")
    fi
  done
fi

sqlite_driver_ok=false
if [[ -f /usr/lib64/qt6/plugins/sqldrivers/libqsqlite.so ]] || [[ -f /usr/lib/qt6/plugins/sqldrivers/libqsqlite.so ]]; then
  sqlite_driver_ok=true
fi

echo "=== Plasma AI Usage Monitor - Install Doctor ==="
echo "OS: $OS_PRETTY"
echo

echo "Required command checks:"
for cmd in "${required_cmds[@]}"; do
  state="$(check_cmd "$cmd")"
  printf '  - %-14s %s\n' "$cmd" "$state"
done

echo

echo "Runtime tool checks (recommended):"
for cmd in "${warning_cmds[@]}"; do
  state="$(check_cmd "$cmd")"
  printf '  - %-14s %s\n' "$cmd" "$state"
done

echo
if [[ "$OS_ID" == "fedora" ]] && command -v rpm >/dev/null 2>&1; then
  echo "Fedora package checks:"
  for pkg in "${fedora_packages[@]}"; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
      printf '  - %-28s installed\n' "$pkg"
    else
      printf '  - %-28s missing\n' "$pkg"
    fi
  done
  echo
fi

echo "SQLite driver: $([[ "$sqlite_driver_ok" == true ]] && echo "ok" || echo "warning: not found")"

do_install=false
if [[ "$AUTO_INSTALL" == true ]] && [[ "$OS_ID" == "fedora" ]]; then
  if [[ ${#missing_fedora_packages[@]} -gt 0 ]]; then
    do_install=true
  fi
fi

if [[ "$do_install" == true ]]; then
  echo
  echo "Installing missing Fedora dependencies..."
  sudo dnf install -y "${missing_fedora_packages[@]}"
  echo "Dependency install finished. Re-run doctor to confirm."
fi

echo
has_blocking=false
if [[ ${#missing_required[@]} -gt 0 ]]; then
  has_blocking=true
  echo "Blocking issues:"
  for item in "${missing_required[@]}"; do
    echo "  - Missing required command: $item"
  done
fi

if [[ "$OS_ID" == "fedora" ]] && [[ ${#missing_fedora_packages[@]} -gt 0 ]] && [[ "$AUTO_INSTALL" != true ]]; then
  has_blocking=true
  echo "  - Missing Fedora build packages. Install with:"
  echo "    sudo dnf install ${missing_fedora_packages[*]}"
fi

if [[ "$sqlite_driver_ok" != true ]]; then
  echo "Warning: Qt SQLite driver not detected. History charts may not work until Qt SQL driver is available."
fi

if [[ ${#missing_warning[@]} -gt 0 ]]; then
  echo "Warnings:"
  for item in "${missing_warning[@]}"; do
    echo "  - Missing runtime command: $item"
  done
fi

if [[ "$has_blocking" == true ]]; then
  echo
  echo "Doctor result: FAIL"
  exit 1
fi

if [[ "$STRICT" == true ]] && [[ ${#missing_warning[@]} -gt 0 ]]; then
  echo
  echo "Doctor result: FAIL (strict mode)"
  exit 1
fi

echo "Doctor result: PASS"
