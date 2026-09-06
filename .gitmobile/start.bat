@echo off
REM .gitmobile Launcher for Windows
echo Starting .gitmobile server...

where node >nul 2>nul
if %errorlevel% equ 0 (
  node "%~dp0server\index.js"
  goto end
)

where deno >nul 2>nul
if %errorlevel% equ 0 (
  deno run -A "%~dp0server\index.js"
  goto end
)

echo Error: Neither Node.js nor Deno found in PATH.
pause

:end
