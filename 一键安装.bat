@echo off
chcp 65001 >nul
title GTA4 D3D Error Fix - One-Click Installer
cd /d "%~dp0"

echo.
echo ===============================================
echo   GTA4  D3D Error / DD3D30  Fix Pack
echo   One-Click Installer
echo ===============================================
echo.

where powershell >nul 2>nul
if errorlevel 1 (
    echo [X] PowerShell not found.
    echo     Please copy d3d9.dll, dinput8.dll and the plugins folder
    echo     manually into the game root folder (where GTAIV.exe is).
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
pause
