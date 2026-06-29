# ============================================================
# 脚本：银狐 WDAC 策略清理工具
# 功能：删除恶意 WDAC 策略，解除杀毒软件封锁，部署急救箱
# 兼容：Windows 8.1 / 10 / 11
# 用法：iex (irm https://你的托管地址/SilverfoxCleanScript.ps1)
# ============================================================

# ---------- 1. 自动提权 ----------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        $scriptPath = "SilverfoxCleanScript.ps1"
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# ---------- 2. 界面 ----------
Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "      银狐 WDAC 策略清理工具" -ForegroundColor Yellow
Write-Host "      解除杀毒软件被屏蔽的问题" -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$desktop = [Environment]::GetFolderPath("Desktop")
$backupDir = Join-Path $desktop "WDAC_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ---------- 3. 优先使用 CiTool.exe（Windows 11 22H2+）----------
Write-Host "[1/5] 尝试使用 CiTool.exe 清理策略..." -ForegroundColor Magenta
$citool = Get-Command "CiTool.exe" -ErrorAction SilentlyContinue
$removed = 0
if ($citool) {
    try {
        $policies = & CiTool.exe -lp -json | ConvertFrom-Json
        foreach ($policy in $policies) {
            if ($policy.'Platform Policy' -eq $true) {
                Write-Host "     跳过系统策略: $($policy.'Friendly Name')" -ForegroundColor Gray
                continue
            }
            $id = $policy.'Policy ID'
            & CiTool.exe -rp $id -json | Out-Null
            Write-Host "     已删除非系统策略: $($policy.'Friendly Name') ($id)" -ForegroundColor Green
            $removed++
        }
        if ($removed -eq 0) {
            Write-Host "     未发现非系统策略" -ForegroundColor Green
        }
    } catch {
        Write-Host "     CiTool 执行失败，转用手动删除" -ForegroundColor Yellow
        $removed = -1
    }
} else {
    Write-Host "     系统不支持 CiTool.exe（Windows 11 22H2+ 才有），将使用手动删除" -ForegroundColor Yellow
    $removed = -1
}

# ---------- 4. 手动删除（作为备用或补充）----------
if ($removed -eq -1) {
    Write-Host "[2/5] 手动清理策略文件..." -ForegroundColor Magenta
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "     备份目录: $backupDir" -ForegroundColor Gray

    $policyPaths = @(
        "C:\Windows\System32\CodeIntegrity\SiPolicy.p7b",
        "$env:SystemDrive\EFI\Microsoft\Boot\SiPolicy.p7b"
    )

    $deleted = $false
    foreach ($p in $policyPaths) {
        $files = Get-ChildItem -Path $p -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Copy-Item -Path $f.FullName -Destination $backupDir -Force
            Remove-Item -Path $f.FullName -Force
            Write-Host "     已删除并备份: $($f.Name)" -ForegroundColor Green
            $deleted = $true
        }
    }
    if (-not $deleted) {
        Write-Host "     未找到任何策略文件" -ForegroundColor Yellow
    }
    Write-Host "     ⚠️ 手动模式仅删除 SiPolicy.p7b，不删除 .cip 策略文件" -ForegroundColor Yellow
    Write-Host "     ⚠️ 可能存在清理不干净的情况，建议使用 CiTool 模式（Windows 11 22H2+）" -ForegroundColor Yellow
}

# ---------- 5. 生成备用 CMD 脚本 ----------
Write-Host "[3/5] 生成桌面备用 CMD 清理脚本..." -ForegroundColor Magenta
$cmdPath = Join-Path $desktop "清理WDAC.cmd"
$cmdContent = @"
@echo off
title WDAC 策略快速清理工具
echo 正在删除策略文件...
del /f /a "C:\Windows\System32\CodeIntegrity\SiPolicy.p7b" 2>nul
del /f /a "%SystemDrive%\EFI\Microsoft\Boot\SiPolicy.p7b" 2>nul
echo 文件已删除，请重启电脑！
echo 注意：此脚本仅删除 SiPolicy.p7b，不删除 .cip 策略文件
echo 可能存在清理不干净的情况，请使用 Windows 11 22H2+ 的 CiTool 工具进行完整清理
pause
"@
[System.IO.File]::WriteAllText($cmdPath, $cmdContent, [System.Text.UTF8Encoding]::new($false))
Write-Host "     已生成: $cmdPath" -ForegroundColor Green

# ---------- 6. 下载 360 系统急救箱 ----------
Write-Host "[4/5] 下载系统急救箱..." -ForegroundColor Magenta
$is64 = [Environment]::Is64BitOperatingSystem
$url = if ($is64) {
    "https://dl.360safe.com/360c0mpkill_5.1.64.1287-0922.zip"
} else {
    "https://dl.360safe.com/360c0mpkill_5.1.0.1287-0922.zip"
}
$downloadDir = Join-Path $desktop "系统急救箱"
New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
$zipFile = Join-Path $downloadDir "SysRepair.zip"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zipFile -UseBasicParsing
    Expand-Archive -Path $zipFile -DestinationPath $downloadDir -Force
    Remove-Item $zipFile -Force
    Write-Host "     下载解压完成，文件夹已打开" -ForegroundColor Green
    Start-Process explorer.exe $downloadDir
} catch {
    Write-Host "     下载失败，请手动从 https://weishi.360.cn/jijiuxiang/index.html 下载急救箱" -ForegroundColor Red
}

# ---------- 7. 完成提示 ----------
Write-Host "[5/5] 完成！" -ForegroundColor Green
Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "策略文件已清理（备份在桌面 WDAC_Backup_* 文件夹）" -ForegroundColor Green
Write-Host "必须【重启电脑】才能使更改生效！" -ForegroundColor Red
Write-Host "📁 建议：先运行急救箱全盘扫描，再重启" -ForegroundColor Yellow
Write-Host "🛠️  备用脚本: 桌面\清理WDAC.cmd" -ForegroundColor Cyan
Write-Host "⚠️ 警告：手动模式仅删除 SiPolicy.p7b，不删除 .cip 策略文件" -ForegroundColor Red
Write-Host "⚠️ 若杀毒软件仍无法启动，建议使用 Windows 11 22H2+ 的 CiTool 工具" -ForegroundColor Red
Write-Host "=====================================================" -ForegroundColor Cyan
Read-Host "按 Enter 退出"