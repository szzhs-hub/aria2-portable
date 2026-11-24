@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -Command "$s=New-Object -ComObject WScript.Shell;$p=Join-Path ([Environment]::GetFolderPath('Startup')) 'Aria2 后台服务.lnk';$l=$s.CreateShortcut($p);$l.TargetPath='%~dp0daemon.vbs';$l.WorkingDirectory='%~dp0';$l.WindowStyle=7;$l.Description='Aria2 后台服务';$l.Save();Write-Host ('已设置开机自启：' + $p)"
echo.
pause