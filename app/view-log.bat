@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "conf\aria2.log" (
    echo 还没有日志。先双击 start.bat 启动，再点几个下载试试。
    pause
    exit /b 1
)
echo 实时显示日志，按 Ctrl+C 退出。
echo.
powershell -NoProfile -Command "Get-Content -LiteralPath '%~dp0conf\aria2.log' -Tail 25 -Wait"