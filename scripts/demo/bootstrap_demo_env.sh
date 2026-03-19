#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
REQ_FILE="${ROOT_DIR}/scripts/demo/requirements.txt"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to bootstrap the demo environment" >&2
  exit 1
fi

if [[ ! -d "${VENV_DIR}" ]]; then
  python3 -m venv "${VENV_DIR}"
fi

"${VENV_DIR}/bin/python" -m pip install --upgrade pip >/dev/null

if [[ -f "${REQ_FILE}" ]]; then
  mapfile -t non_comment_lines < <(grep -Ev '^\s*($|#)' "${REQ_FILE}" || true)
  if [[ ${#non_comment_lines[@]} -gt 0 ]]; then
    "${VENV_DIR}/bin/python" -m pip install -r "${REQ_FILE}"
  fi
fi

cat <<EOF
Demo environment ready.

Next steps:
  source .venv/bin/activate
  python scripts/demo/mock_ai_usage_server.py
EOF
