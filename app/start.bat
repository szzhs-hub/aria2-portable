@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
if not exist "conf\aria2.conf" (
    echo [提示] 还没有安装，请先双击 install.bat
    pause
    exit /b 1
)
tasklist /fi "imagename eq aria2c.exe" 2>nul | find /i "aria2c.exe" >nul
if errorlevel 1 (
    echo 正在后台启动 aria2 ...
    wscript //nologo "%~dp0daemon.vbs"
    timeout /t 2 /nobreak >nul
) else (
    echo aria2 已在后台运行。
)
call "%~dp0panel.bat"
endlocal