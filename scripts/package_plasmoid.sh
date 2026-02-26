#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="."
CHECK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  [[ -d package ]] || { echo "Missing package/ directory" >&2; exit 1; }
  [[ -f package/metadata.json ]] || { echo "Missing package/metadata.json" >&2; exit 1; }
  command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }
  echo "Plasmoid packaging check OK"
  exit 0
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_PATH="${OUTPUT_DIR%/}/com.github.loofi.aiusagemonitor.plasmoid"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}"

# ZIP format cannot encode timestamps before 1980-01-01.
# Clamp SOURCE_DATE_EPOCH to avoid struct packing failures in Python's zipfile.
if [[ "$SOURCE_DATE_EPOCH" -lt 315532800 ]]; then
  SOURCE_DATE_EPOCH=315532800
fi

python3 - "$ROOT_DIR" "$OUTPUT_PATH" "$SOURCE_DATE_EPOCH" <<'PY'
import os
import stat
import sys
import time
import zipfile

root_dir = sys.argv[1]
out_path = sys.argv[2]
source_date_epoch = int(sys.argv[3])
package_dir = os.path.join(root_dir, 'package')

fixed_dt = time.gmtime(source_date_epoch)[:6]

with zipfile.ZipFile(out_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
    for dirpath, _, filenames in os.walk(package_dir):
        filenames.sort()
        for filename in filenames:
            full_path = os.path.join(dirpath, filename)
            rel_path = os.path.relpath(full_path, package_dir).replace('\\', '/')
            arcname = f'package/{rel_path}'
            info = zipfile.ZipInfo(arcname)
            info.date_time = fixed_dt
            info.compress_type = zipfile.ZIP_DEFLATED
            mode = stat.S_IMODE(os.stat(full_path).st_mode)
            info.external_attr = (mode & 0xFFFF) << 16
            with open(full_path, 'rb') as src:
                zf.writestr(info, src.read())

print(f'Created {out_path}')
PY
