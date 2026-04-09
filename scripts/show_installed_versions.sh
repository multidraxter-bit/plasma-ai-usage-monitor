#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

REPO_METADATA="${ROOT_DIR}/package/metadata.json"
PLASMOID_ID="com.github.loofi.aiusagemonitor"
USER_METADATA="${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"
SYSTEM_METADATA="/usr/share/plasma/plasmoids/com.github.loofi.aiusagemonitor/metadata.json"
USER_PLASMOID_DIR="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"
SYSTEM_PLASMOID_DIR="/usr/share/plasma/plasmoids/${PLASMOID_ID}"
QML_RELATIVE_DIR="com/github/loofi/aiusagemonitor"

find_qml_module_dir() {
  local candidates=(
    "${HOME}/.local/lib64/qt6/qml/${QML_RELATIVE_DIR}"
    "${HOME}/.local/lib/qt6/qml/${QML_RELATIVE_DIR}"
    "${HOME}/.local/lib/qml/${QML_RELATIVE_DIR}"
    "/usr/lib64/qt6/qml/${QML_RELATIVE_DIR}"
    "/usr/lib/qt6/qml/${QML_RELATIVE_DIR}"
    "/usr/lib/x86_64-linux-gnu/qt6/qml/${QML_RELATIVE_DIR}"
    "/usr/lib/qml/${QML_RELATIVE_DIR}"
  )

  local dir
  for dir in "${candidates[@]}"; do
    if [[ -f "${dir}/qmldir" ]]; then
      echo "$dir"
      return 0
    fi
  done

  return 1
}

find_plugin_library() {
  local module_dir="$1"
  local candidates=(
    "${module_dir}/libaiusagemonitorplugin.so"
    "${module_dir}/aiusagemonitorplugin.so"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  local discovered
  discovered="$(find "$module_dir" -maxdepth 1 -type f -name '*aiusage*plugin*.so' 2>/dev/null | head -1 || true)"
  if [[ -n "$discovered" ]]; then
    echo "$discovered"
    return 0
  fi

  return 1
}

extract_version() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "not-installed"
    return 0
  fi

  sed -n 's/.*"Version": "\([0-9.]*\)".*/\1/p' "$file" | head -1
}

echo "AI Usage Monitor version report"
echo "  repo:   $(extract_version "$REPO_METADATA")  ($REPO_METADATA)"
echo "  user:   $(extract_version "$USER_METADATA")  ($USER_METADATA)"
echo "  system: $(extract_version "$SYSTEM_METADATA")  ($SYSTEM_METADATA)"

USER_INSTALL_STATE="missing"
SYSTEM_INSTALL_STATE="missing"
[[ -d "$USER_PLASMOID_DIR" ]] && USER_INSTALL_STATE="present"
[[ -d "$SYSTEM_PLASMOID_DIR" ]] && SYSTEM_INSTALL_STATE="present"

echo
echo "Plasmoid package locations"
echo "  user package:   ${USER_INSTALL_STATE}  (${USER_PLASMOID_DIR})"
echo "  system package: ${SYSTEM_INSTALL_STATE}  (${SYSTEM_PLASMOID_DIR})"

echo
QML_MODULE_DIR="$(find_qml_module_dir || true)"
if [[ -n "$QML_MODULE_DIR" ]]; then
  echo "Compiled QML module"
  echo "  qmldir: ${QML_MODULE_DIR}/qmldir"
  PLUGIN_LIBRARY="$(find_plugin_library "$QML_MODULE_DIR" || true)"
  if [[ -n "$PLUGIN_LIBRARY" ]]; then
    echo "  plugin: ${PLUGIN_LIBRARY}"
  else
    echo "  plugin: missing shared library next to qmldir"
  fi
else
  echo "Compiled QML module"
  echo "  qmldir: not found in common Qt6 install paths"
fi

if [[ "$USER_INSTALL_STATE" == "present" && "$SYSTEM_INSTALL_STATE" == "present" ]]; then
  echo
  echo "Warning: both user-local and system plasmoid packages are installed."
  echo "The user-local package usually wins and can shadow system updates."
fi

if [[ "$USER_INSTALL_STATE" == "present" && -z "${QML_MODULE_DIR:-}" ]]; then
  echo
  echo "Warning: the user-local plasmoid package exists, but the compiled QML plugin was not found."
  echo "QML-only changes may appear, but C++ plugin changes will not load until the plugin is rebuilt and installed."
fi
