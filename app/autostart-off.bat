@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -Command "$p=Join-Path ([Environment]::GetFolderPath('Startup')) 'Aria2 后台服务.lnk';if(Test-Path $p){Remove-Item $p -Force;Write-Host ('已取消开机自启：' + $p)}else{Write-Host '本来就没有设置开机自启。'}"
echo.
pause