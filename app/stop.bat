@echo off
chcp 65001 >nul
cd /d "%~dp0"
tasklist /fi "imagename eq aria2c.exe" 2>nul | find /i "aria2c.exe" >nul
if errorlevel 1 (
    echo aria2 当前没有在运行。
    timeout /t 2 /nobreak >nul
    exit /b 0
)
echo 正在停止 aria2 ...
taskkill /f /im aria2c.exe >nul 2>&1
echo 已停止。未完成的任务会记录在 conf\aria2.session 里，下次启动继续。
timeout /t 2 /nobreak >nul