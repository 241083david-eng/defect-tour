@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0.."
set "MSGFILE=scripts\save-message.txt"
git add -A
if %errorlevel% neq 0 (
  echo FAIL: git add failed. See the lines above.
  goto end
)
git diff --cached --quiet
if %errorlevel%==0 (
  echo NOTE: nothing new to save.
  goto end
)
rem Secret scan of what is about to be saved (gitleaks, rules in .gitleaks.toml if present). Exit code 3 = a secret was found.
set "GITLEAKS=gitleaks"
where gitleaks >nul 2>nul || for /d %%P in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gitleaks.Gitleaks_*") do if exist "%%P\gitleaks.exe" set "GITLEAKS=%%P\gitleaks.exe"
"%GITLEAKS%" git --staged --no-banner --redact -v --exit-code 3 -l warn .
if %errorlevel%==3 (
  git reset -q
  echo FAIL: a password, key or token was found in the changes. Nothing was saved. Send a screenshot of this window to the chat.
  goto end
)
if %errorlevel% neq 0 (
  git reset -q
  echo FAIL: the secret scan could not run ^(is gitleaks installed?^). Nothing was saved. Send a screenshot of this window to the chat.
  goto end
)
if exist "%MSGFILE%" (
  git commit -q -F "%MSGFILE%"
) else (
  git commit -q -m "Manual save"
)
if %errorlevel% neq 0 (
  echo FAIL: git commit failed. See the lines above.
  goto end
)
echo PASS: saved.
git log -1 --format="%%h %%s"
if exist "%MSGFILE%" del "%MSGFILE%"
:end
echo.
if not "%~1"=="--nopause" pause
