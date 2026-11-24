@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo.
echo 卸载会做三件事：
echo   1. 停止后台的 aria2 进程
echo   2. 删除开机自启项
echo   3. 删除桌面上的两个快捷方式
echo.
echo 不会删除任何已下载的文件。
echo.
choice /c YN /m "确定继续吗"
if errorlevel 2 exit /b 0
taskkill /f /im aria2c.exe >nul 2>&1
powershell -NoProfile -Command "$s=[Environment]::GetFolderPath('Startup');$d=[Environment]::GetFolderPath('Desktop');Remove-Item (Join-Path $s 'Aria2 后台服务.lnk') -Force -ErrorAction SilentlyContinue;Remove-Item (Join-Path $d 'Aria2 下载器.lnk') -Force -ErrorAction SilentlyContinue;Remove-Item (Join-Path $d 'Aria2 面板.lnk') -Force -ErrorAction SilentlyContinue;Write-Host '自启项和快捷方式已清理。'"
echo.
echo 完成。现在可以直接删除整个文件夹了（记得先确认 Download\ 里没有要留的文件）。
echo.
pause