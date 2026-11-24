# Aria2 便携版 - 安装脚本
# 由 install.bat 调用；负责生成配置、密钥、面板地址、扩展导入配置和桌面快捷方式。

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Fail([string]$msg) {
    Write-Host ""
    Write-Host "[错误] $msg" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

if (-not (Test-Path (Join-Path $Root 'aria2c.exe'))) { Fail '缺少 aria2c.exe，请确认压缩包解压完整。' }
if (-not (Test-Path (Join-Path $Root 'aria-ng\index.html'))) { Fail '缺少 aria-ng\index.html，请确认压缩包解压完整。' }

New-Item -ItemType Directory -Force -Path (Join-Path $Root 'Downloads') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root 'conf') | Out-Null

$confPath = Join-Path $Root 'conf\aria2.conf'
$template = Join-Path $Root 'conf\aria2.conf.template'

# ---------- 1. 密钥：装过就沿用，避免浏览器扩展里保存的地址失效 ----------
$secret = $null
if (Test-Path $confPath) {
    $m = Select-String -LiteralPath $confPath -Pattern '^rpc-secret=(.+)$' | Select-Object -First 1
    if ($m) { $secret = $m.Matches[0].Groups[1].Value.Trim() }
}
$reused = [bool]$secret
if (-not $secret) { $secret = [guid]::NewGuid().ToString('N') }

# 端口：装过就沿用，避免已配置的扩展连不上
$port = 6800
if (Test-Path $confPath) {
    $pm = Select-String -LiteralPath $confPath -Pattern '^rpc-listen-port=(\d+)$' | Select-Object -First 1
    if ($pm) { $port = [int]$pm.Matches[0].Groups[1].Value }
}

# ---------- 2. AriaNg 面板地址里的密钥是 base64url 编码 ----------
$b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($secret)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

# ---------- 3. 生成 aria2.conf ----------
$conf = (Get-Content -LiteralPath $template -Raw -Encoding UTF8).Replace('@BASEDIR@', $Root).Replace('@SECRET@', $secret).Replace('@PORT@', "$port")
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($confPath, $conf, $utf8NoBom)

# ---------- 4. 会话文件（不存在时 aria2 会启动失败）----------
$sessionFile = Join-Path $Root 'conf\aria2.session'
if (-not (Test-Path $sessionFile)) { [IO.File]::WriteAllText($sessionFile, '', $utf8NoBom) }

# ---------- 5. 面板地址：写成纯 ASCII 文件，避免批处理解析 %xx ----------
$panelUri = ([uri]("$Root\aria-ng\index.html")).AbsoluteUri
$panelUrl = "$panelUri#!/settings/rpc/set/http/127.0.0.1/$port/jsonrpc/$b64"
[IO.File]::WriteAllText((Join-Path $Root 'conf\panel-url.txt'), $panelUrl + "`r`n", $utf8NoBom)

# ---------- 6. 生成 panel.bat（GBK 编码，cmd 中文不乱码）----------
$panelBat = @'
@echo off
chcp 936 >nul
setlocal
cd /d "%~dp0"
set "URL="
set /p URL=<"%~dp0conf\panel-url.txt"
if not defined URL (
    echo [错误] 找不到面板地址，请重新运行 install.bat
    pause
    exit /b 1
)
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" "%URL%"
    goto :done
)
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" "%URL%"
    goto :done
)
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "%URL%"
    goto :done
)
if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" "%URL%"
    goto :done
)
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    start "" "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" "%URL%"
    goto :done
)
if exist "%ProgramFiles%\Mozilla Firefox\firefox.exe" (
    start "" "%ProgramFiles%\Mozilla Firefox\firefox.exe" "%URL%"
    goto :done
)
start "" "%URL%"

:done
endlocal
'@
[IO.File]::WriteAllText((Join-Path $Root 'panel.bat'), $panelBat.Replace("`n", "`r`n"), [Text.Encoding]::GetEncoding(936))

# ---------- 7. 给浏览器扩展用的导入配置 ----------
$extConfig = @{
    rpcList           = @(@{ name = '本机 Aria2'; url = "http://token:$secret@127.0.0.1:$port/jsonrpc"; pattern = '' })
    fileSize          = 1
    integration       = $true
    contextMenus      = $true
    allowNotification = $true
    keepSilent        = $false
    badgeText         = $true
    keepAwake         = $false
    monitorAria2      = $true
    webUIOpenStyle    = 'tab'
    captureMagnet     = $false
} | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText((Join-Path $Root 'Aria2-Explorer-配置.json'), $extConfig, $utf8NoBom)

# ---------- 8. 桌面快捷方式 ----------
$shell = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath('Desktop')
$links = @(
    @{ Name = 'Aria2 下载器.lnk'; Target = (Join-Path $Root 'start.bat');    Desc = '启动 Aria2 后台服务并打开下载面板' },
    @{ Name = 'Aria2 面板.lnk';   Target = (Join-Path $Root 'panel.bat');    Desc = '打开 Aria2 下载面板' }
)
foreach ($l in $links) {
    $sc = $shell.CreateShortcut((Join-Path $desktop $l.Name))
    $sc.TargetPath = $l.Target
    $sc.WorkingDirectory = $Root
    $sc.IconLocation = (Join-Path $Root 'aria2c.exe') + ',0'
    $sc.Description = $l.Desc
    $sc.Save()
}

# ---------- 9. 结果 ----------
Write-Host ""
Write-Host "================ 安装完成 ================" -ForegroundColor Green
Write-Host ("安装目录 : {0}" -f $Root)
Write-Host ("下载目录 : {0}" -f (Join-Path $Root 'Downloads'))
Write-Host ("RPC 地址 : http://127.0.0.1:{0}/jsonrpc" -f $port)
Write-Host ("RPC 密钥 : {0}" -f $secret)
if ($reused) { Write-Host "（沿用上一次安装的密钥）" -ForegroundColor DarkGray }
Write-Host ""
Write-Host "下一步：" -ForegroundColor Cyan
Write-Host "  1) 已生成桌面图标「Aria2 下载器」和「Aria2 面板」"
Write-Host "  2) 浏览器安装扩展 Aria2 Explorer，然后导入同目录下的"
Write-Host "     Aria2-Explorer-配置.json （扩展选项页 → 导入/导出 → 导入）"
Write-Host "  3) 双击「Aria2 下载器」开始使用"
Write-Host ""
Write-Host "详细用法见 使用说明.html" -ForegroundColor DarkGray