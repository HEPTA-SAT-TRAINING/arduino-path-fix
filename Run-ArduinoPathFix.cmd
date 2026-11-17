@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Fix-ArduinoPaths.ps1"
set "result=%ERRORLEVEL%"
echo.
if not "%result%"=="0" (
  echo The setup did not complete. Review the message above.
) else (
  echo The setup completed. Check compilation in Arduino IDE.
)
echo.
pause
exit /b %result%
