@echo off
chcp 65001 >nul
title GTA4 D3D Error Fix - Uninstall / Restore
cd /d "%~dp0"

echo.
echo ===============================================
echo   GTA4 Fix Pack - Uninstall / Restore
echo ===============================================
echo.

where powershell >nul 2>nul
if errorlevel 1 (
    echo [X] PowerShell not found.
    echo     Please manually delete d3d9.dll, dinput8.dll and the plugins
    echo     folder from the game root folder.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
pause
