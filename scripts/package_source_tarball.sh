#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

VERSION=""
OUTPUT_DIR="."
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$VERSION" ]]; then
  VERSION="$(sed -n 's/^project(plasma-ai-usage-monitor VERSION \([0-9.]*\)).*/\1/p' CMakeLists.txt | head -1)"
fi

if [[ -z "$VERSION" ]]; then
  echo "Failed to determine version" >&2
  exit 1
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  [[ -f CMakeLists.txt ]] || { echo "Missing CMakeLists.txt" >&2; exit 1; }
  [[ -d package ]] || { echo "Missing package/ directory" >&2; exit 1; }
  [[ -f package/metadata.json ]] || { echo "Missing package/metadata.json" >&2; exit 1; }
  echo "Source packaging check OK (version=${VERSION})"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
ARCHIVE_NAME="plasma-ai-usage-monitor-${VERSION}.tar.gz"
ARCHIVE_PATH="${OUTPUT_DIR%/}/${ARCHIVE_NAME}"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"
TMP_DIR="$(mktemp -d)"
TMP_ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE_NAME}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Deterministic tarball from tracked files only.
  git -c core.quotepath=off ls-files -z | tar \
    --null \
    --no-recursion \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --pax-option=delete=atime,delete=ctime \
    -czf "$TMP_ARCHIVE_PATH" \
    --files-from=-
else
  # Fallback mode for non-git environments.
  tar \
    --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH}" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --pax-option=delete=atime,delete=ctime \
    --warning=no-file-changed \
    -czf "$TMP_ARCHIVE_PATH" \
    --exclude=.git \
    --exclude=build \
    --exclude=build-* \
    --exclude=dist \
    --exclude=*.tar.gz \
    .
fi

mv "$TMP_ARCHIVE_PATH" "$ARCHIVE_PATH"

echo "Created ${ARCHIVE_PATH}"
