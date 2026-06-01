@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launch_game.ps1"
if errorlevel 1 (
  echo.
  echo Launcher failed. See the message above.
  pause
)
