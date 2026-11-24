@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo ==========================================
echo    Aria2 便携版 - 安装
echo ==========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
echo.
pause