@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup-wsl-dev.ps1" %*
set "exitcode=%errorlevel%"
if not "%exitcode%"=="0" (
    echo.
    echo Setup failed with exit code %exitcode%.
    echo Review the PowerShell error above for details.
    pause
)
endlocal
exit /b %exitcode%
