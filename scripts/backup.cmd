@echo off
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0backup.ps1"
if %errorlevel% neq 0 echo FAIL: backup did not complete. See the lines above.
echo.
if not "%~1"=="--nopause" pause
