#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "============================================"
echo "  PHARMED CRM 3.0.4 - Local Run"
echo "============================================"
if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "[0] .env created"
fi
PY=""
for c in python3.12 python3.11 python3.10 python3; do
  command -v "$c" &>/dev/null && PY="$c" && break
done
[[ -z "$PY" ]] && { echo "Python not found"; exit 1; }
echo "Using $PY"
[[ ! -d .venv ]] && "$PY" -m venv .venv
.venv/bin/python -m pip install --upgrade pip -q
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python -m scripts.seed
.venv/bin/python -m scripts.verify_bootstrap_accounts
echo "Server: http://127.0.0.1:8000/"
echo "Users: admin/Admin@12345 | bayat/Bayat@12345 | mostofi/Mostofi@12345 | tavakoli/Tavakoli@12345"
exec .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
