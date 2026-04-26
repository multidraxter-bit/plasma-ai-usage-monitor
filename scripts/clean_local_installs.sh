#!/usr/bin/env bash
set -euo pipefail

echo "=== Plasma AI Usage Monitor - Local Install Cleaner ==="
echo

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    echo "[DRY RUN MODE] No files will be deleted."
    echo
fi

PATHS_TO_CHECK=(
    "${HOME}/.local/share/plasma/plasmoids/com.github.loofi.aiusagemonitor"
    "${HOME}/.local/lib64/qt6/qml/com/github/loofi/aiusagemonitor"
    "${HOME}/.local/lib/qt6/qml/com/github/loofi/aiusagemonitor"
)

FOUND=0

for path in "${PATHS_TO_CHECK[@]}"; do
    if [[ -d "$path" ]]; then
        FOUND=1
        echo "Found stale install: $path"
        if [[ $DRY_RUN -eq 0 ]]; then
            rm -rf "$path"
            echo "  -> Deleted."
        else
            echo "  -> Would delete."
        fi
    elif [[ -f "$path" ]]; then
        FOUND=1
        echo "Found stale file: $path"
        if [[ $DRY_RUN -eq 0 ]]; then
            rm -f "$path"
            echo "  -> Deleted."
        else
            echo "  -> Would delete."
        fi
    else
        echo "Clean: $path (not found)"
    fi
done

echo
if [[ $FOUND -eq 1 ]]; then
    if [[ $DRY_RUN -eq 0 ]]; then
        echo "Cleanup complete. Stale user-local files removed."
        echo "Run 'just reload' if Plasma was already running."
    else
        echo "Dry run complete. Run without --dry-run to delete."
    fi
else
    echo "No stale user-local installs found."
fi
