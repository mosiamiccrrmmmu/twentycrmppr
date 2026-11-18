@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ============================================
echo   PHARMED CRM 3.0.4 — نصب / همگام‌سازی / اجرا
echo   سامانه CRM فروش فارمد پلیمر رایان
echo   مخصوص اجرا روی سیستم محلی (حداکثر ۴ کاربر)
echo ============================================
echo.

REM اگر .env وجود نداشت از .env.example بساز
if not exist ".env" (
  if exist ".env.example" (
    echo [0] فایل .env پیدا نشد — از .env.example کپی می‌شود...
    copy /Y ".env.example" ".env" >nul
    echo     فایل .env ساخته شد. رمزهای اولیه داخل آن هستند.
    echo.
  ) else (
    echo [ERROR] نه .env و نه .env.example پیدا نشد.
    pause
    exit /b 1
  )
)

REM Prefer Python 3.11 or 3.12
set "PY_CMD="
where py >nul 2>&1
if %errorlevel%==0 (
  py -3.12 -c "import sys" >nul 2>&1 && set "PY_CMD=py -3.12"
  if not defined PY_CMD py -3.11 -c "import sys" >nul 2>&1 && set "PY_CMD=py -3.11"
  if not defined PY_CMD py -3.10 -c "import sys" >nul 2>&1 && set "PY_CMD=py -3.10"
  if not defined PY_CMD set "PY_CMD=py -3"
) else (
  where python >nul 2>&1 && set "PY_CMD=python"
)

if not defined PY_CMD (
  echo [ERROR] Python پیدا نشد.
  echo لطفاً Python 3.11 یا 3.12 را از python.org نصب کنید
  echo و تیک "Add python.exe to PATH" را بزنید.
  pause
  exit /b 1
)

echo Using: %PY_CMD%
%PY_CMD% -c "import sys; print('Python', sys.version); v=sys.version_info; exit(0 if v.major==3 and 10<=v.minor<=12 else 1)"
if errorlevel 1 (
  echo.
  echo [هشدار] نسخه Python شما برای نصب آسان مناسب نیست.
  echo پیشنهاد قوی: Python 3.11 یا 3.12 نصب کنید.
  echo https://www.python.org/downloads/
  echo.
  pause
)

if not exist ".venv\Scripts\python.exe" (
  echo [1/4] ساخت محیط مجازی Python...
  %PY_CMD% -m venv .venv
  if errorlevel 1 goto :error
) else (
  echo [1/4] محیط مجازی موجود است.
)

echo [2/4] نصب / به‌روزرسانی وابستگی‌ها...
.venv\Scripts\python.exe -m pip install --upgrade pip
if errorlevel 1 goto :error
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 (
  echo.
  echo ============================================================
  echo نصب پکیج‌ها شکست خورد.
  echo علت رایج: Python خیلی جدید (3.13+) یا نبود Visual C++ Build Tools
  echo راه‌حل: Python 3.12 نصب کنید و دوباره این فایل را اجرا کنید.
  echo https://www.python.org/downloads/release/python-3128/
  echo ============================================================
  goto :error
)

echo [3/4] ساخت / همگام‌سازی ۴ کاربر اولیه از .env...
.venv\Scripts\python.exe -m scripts.seed
if errorlevel 1 goto :error
.venv\Scripts\python.exe -m scripts.verify_bootstrap_accounts
if errorlevel 1 goto :error

echo.
echo [4/4] در حال اجرای PHARMED CRM...
echo.
echo   آدرس:  http://127.0.0.1:8000/
echo   این پنجره را باز نگه دارید.
echo.
echo   کاربران اولیه:
echo     admin     → Admin@12345
echo     bayat     → Bayat@12345
echo     mostofi   → Mostofi@12345
echo     tavakoli  → Tavakoli@12345
echo.
echo   بعد از ورود حتماً رمزها را عوض کنید.
echo ============================================
echo.

.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
if errorlevel 1 goto :error
exit /b 0

:error
echo.
echo اجرا ناموفق بود. پیام خطا را کپی کنید.
pause
exit /b 1
