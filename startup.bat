@echo off
REM .gitmobile - Windows Startup Script

echo ================================================================
echo           .gitmobile - Initializing Environment...              
echo ================================================================
echo.

REM 1. Check for runtime (node or deno)
set RUNNER=none
where node >nul 2>nul
if %errorlevel% equ 0 (
  set RUNNER=node
  goto found_runner
)

where deno >nul 2>nul
if %errorlevel% equ 0 (
  set RUNNER=deno
  goto found_runner
)

:found_runner
if "%RUNNER%"=="none" (
  echo [ERROR] Neither Node.js nor Deno found in PATH.
  echo Please install Node.js from https://nodejs.org or Deno from https://deno.com
  pause
  exit /b 1
)

echo [1/3] Runtime detected: %RUNNER%

REM 2. Ensure dependencies are installed if missing
if not exist "%~dp0.gitmobile\node_modules" (
  echo       Installing .gitmobile dependencies...
  if "%RUNNER%"=="node" (
    pushd "%~dp0.gitmobile"
    call npm install --omit=dev --silent
    popd
  ) else (
    pushd "%~dp0.gitmobile"
    deno install
    popd
  )
  echo       Dependencies installed.
)

REM 3. Configure Git auto-upstream and non-blocking SSH
git config push.autoSetupRemote true >nul 2>nul
git config core.sshCommand "ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" >nul 2>nul
echo [2/3] Git settings configured.

REM 4. Launch Server
echo [3/3] Starting .gitmobile server...
echo.

if "%RUNNER%"=="node" (
  node "%~dp0.gitmobile\server\index.js"
) else (
  deno run -A "%~dp0.gitmobile\server\index.js"
)

pause
