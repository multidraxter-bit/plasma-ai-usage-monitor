#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="."
SPEC_PATH="plasma-ai-usage-monitor.spec"
VERSION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --spec)
      SPEC_PATH="${2:-}"
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$SPEC_PATH" ]]; then
  echo "Missing spec file: $SPEC_PATH" >&2
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  VERSION="$(sed -n 's/^Version:[[:space:]]*\([0-9.]*\).*/\1/p' "$SPEC_PATH" | head -1)"
fi

if [[ -z "$VERSION" ]]; then
  echo "Failed to determine version from $SPEC_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

TOPDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TOPDIR"
}
trap cleanup EXIT

mkdir -p "$TOPDIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
cp "$SPEC_PATH" "$TOPDIR/SPECS/"

SOURCE_TARBALL="$TOPDIR/SOURCES/plasma-ai-usage-monitor-${VERSION}.tar.gz"
PREFIX_DIR="plasma-ai-usage-monitor-${VERSION}/"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git archive \
    --format=tar.gz \
    --prefix="$PREFIX_DIR" \
    -o "$SOURCE_TARBALL" \
    HEAD
else
  echo "build_srpm.sh requires a git worktree" >&2
  exit 1
fi

rpmbuild -bs --define "_topdir $TOPDIR" "$TOPDIR/SPECS/$(basename "$SPEC_PATH")"

find "$TOPDIR/SRPMS" -maxdepth 1 -name '*.src.rpm' -exec cp {} "$OUTPUT_DIR"/ \;

echo "Created SRPM(s) in ${OUTPUT_DIR}"
