@echo off
setlocal DisableDelayedExpansion
title newWindowsEvn Installer
echo Installing newWindowsEvn...
echo.
if not exist "%~dp0install.ps1" (
    echo ERROR: install.ps1 is missing. Extract the entire repository first.
    set "install_result=1"
    goto finished
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
set "install_result=%ERRORLEVEL%"
:finished
echo.
if "%install_result%"=="0" (
    echo SUCCESS: Completed. Reopen your terminal and run yazi or y.
) else (
    echo ERROR: Installation failed with exit code %install_result%. Review the messages above.
)
echo.
if not defined DEVKIT_NO_PAUSE pause
exit /b %install_result%
