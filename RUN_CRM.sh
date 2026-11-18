#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "============================================"
echo "  PHARMED CRM 3.0.4 — نصب / همگام‌سازی / اجرا"
echo "  سامانه CRM فروش فارمد پلیمر رایان"
echo "  مخصوص اجرا روی سیستم محلی (حداکثر ۴ کاربر)"
echo "============================================"
echo

# ساخت .env اگر وجود ندارد
if [[ ! -f .env ]]; then
  if [[ -f .env.example ]]; then
    echo "[0] فایل .env پیدا نشد — از .env.example کپی می‌شود..."
    cp .env.example .env
    echo "    فایل .env ساخته شد."
    echo
  else
    echo "[ERROR] نه .env و نه .env.example پیدا نشد."
    exit 1
  fi
fi

# انتخاب Python
PY=""
for cand in python3.12 python3.11 python3.10 python3; do
  if command -v "$cand" &>/dev/null; then
    ver=$("$cand" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || true)
    if [[ "$ver" == "3.12" || "$ver" == "3.11" || "$ver" == "3.10" ]]; then
      PY="$cand"
      break
    fi
  fi
done
if [[ -z "$PY" ]]; then
  if command -v python3 &>/dev/null; then
    PY=python3
  else
    echo "[ERROR] Python 3.10+ پیدا نشد. لطفاً نصب کنید."
    exit 1
  fi
fi

echo "Using: $PY ($($PY --version 2>&1))"

if [[ ! -d .venv ]]; then
  echo "[1/4] ساخت محیط مجازی..."
  "$PY" -m venv .venv
else
  echo "[1/4] محیط مجازی موجود است."
fi

echo "[2/4] نصب وابستگی‌ها..."
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

echo "[3/4] ساخت / همگام‌سازی ۴ کاربر اولیه..."
.venv/bin/python -m scripts.seed
.venv/bin/python -m scripts.verify_bootstrap_accounts

echo
echo "[4/4] در حال اجرای PHARMED CRM روی http://127.0.0.1:8000/"
echo "این ترمینال را باز نگه دارید."
echo
echo "کاربران اولیه:"
echo "  admin     → Admin@12345"
echo "  bayat     → Bayat@12345"
echo "  mostofi   → Mostofi@12345"
echo "  tavakoli  → Tavakoli@12345"
echo
echo "بعد از ورود حتماً رمزها را عوض کنید."
echo "============================================"
echo

exec .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
