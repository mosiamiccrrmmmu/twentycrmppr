@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo   PHARMED CRM 3.0.4 - Local Run
echo ============================================
echo.

if not exist ".env" (
  if exist ".env.example" (
    echo [0] Creating .env from .env.example ...
    copy /Y ".env.example" ".env" >nul
    echo     Done.
  ) else (
    echo [ERROR] .env.example not found.
    pause
    exit /b 1
  )
)

set PY_CMD=
where py >nul 2>&1
if %errorlevel%==0 (
  py -3.12 -c "import sys" >nul 2>&1
  if not errorlevel 1 set PY_CMD=py -3.12
  if not defined PY_CMD (
    py -3.11 -c "import sys" >nul 2>&1
    if not errorlevel 1 set PY_CMD=py -3.11
  )
  if not defined PY_CMD (
    py -3.10 -c "import sys" >nul 2>&1
    if not errorlevel 1 set PY_CMD=py -3.10
  )
  if not defined PY_CMD set PY_CMD=py -3
) else (
  where python >nul 2>&1
  if %errorlevel%==0 set PY_CMD=python
)

if not defined PY_CMD (
  echo [ERROR] Python not found.
  echo Install Python 3.11 or 3.12 from python.org
  echo and check "Add python.exe to PATH".
  pause
  exit /b 1
)

echo Using: %PY_CMD%
%PY_CMD% --version
echo.

if not exist ".venv\Scripts\python.exe" (
  echo [1/4] Creating virtual environment...
  %PY_CMD% -m venv .venv
  if errorlevel 1 goto :fail
) else (
  echo [1/4] Virtual environment already exists.
)

echo [2/4] Installing packages (this may take a few minutes)...
.venv\Scripts\python.exe -m pip install --upgrade pip
if errorlevel 1 goto :fail
.venv\Scripts\python.exe -m pip install -r requirements.txt
if errorlevel 1 (
  echo.
  echo [ERROR] Package install failed.
  echo If you have Python 3.13+, install Python 3.12 instead:
  echo https://www.python.org/downloads/release/python-3128/
  goto :fail
)

echo [3/4] Creating / syncing the 4 bootstrap users...
.venv\Scripts\python.exe -m scripts.seed
if errorlevel 1 goto :fail
.venv\Scripts\python.exe -m scripts.verify_bootstrap_accounts
if errorlevel 1 goto :fail

echo.
echo [4/4] Starting server...
echo.
echo   URL: http://127.0.0.1:8000/
echo.
echo   Users:
echo     admin      Admin@12345
echo     bayat      Bayat@12345
echo     mostofi    Mostofi@12345
echo     tavakoli   Tavakoli@12345
echo.
echo   Keep this window open.
echo ============================================
echo.

.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1
if errorlevel 1 goto :fail
goto :eof

:fail
echo.
echo ========== ERROR ==========
echo Read the messages above.
echo.
pause
exit /b 1
