# ============================================================
# 银狐 WDAC 清理工具 - 启动器
# 功能：检测管理员权限，若无则提权，然后执行主脚本
# 用户只需双击此文件即可
# ============================================================

# ---------- 1. 让用户选择下载源 ----------
Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "      银狐 WDAC 策略清理工具 - 启动器" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "请根据你的网络环境选择下载源：" -ForegroundColor White
Write-Host ""
Write-Host "  [1] Gitee （国内用户推荐，速度快）" -ForegroundColor Green
Write-Host "  [2] GitHub（国际用户推荐）" -ForegroundColor Green
Write-Host ""
$choice = Read-Host "请输入数字 (1 或 2)"

switch ($choice) {
    "1" { 
        $mainScriptURL = "https://gitee.com/mb-v/SilverfoxCleanScript/raw/master/SilverfoxCleanScript.ps1"
        Write-Host "已选择: Gitee" -ForegroundColor Cyan
    }
    "2" { 
        $mainScriptURL = "https://raw.githubusercontent.com/herta0426/SilverfoxCleanScript/main/SilverfoxCleanScript.ps1"
        Write-Host "已选择: GitHub" -ForegroundColor Cyan
    }
    default { 
        Write-Host "输入无效，默认使用 Gitee 源。" -ForegroundColor Yellow
        $mainScriptURL = "https://gitee.com/mb-v/SilverfoxCleanScript/raw/master/SilverfoxCleanScript.ps1"
    }
}
Write-Host ""

# ---------- 2. 检测当前是否管理员 ----------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if ($isAdmin) {
    # ---------- 已是管理员，直接下载并执行 ----------
    Write-Host "正在下载主脚本..." -ForegroundColor Cyan
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        $scriptContent = Invoke-RestMethod -Uri $mainScriptURL -UseBasicParsing
        Write-Host "正在执行清理..." -ForegroundColor Cyan
        Invoke-Expression $scriptContent
    } catch {
        Write-Host "下载主脚本失败: $_" -ForegroundColor Red
        Write-Host "请检查网络连接后重试。" -ForegroundColor Yellow
        Read-Host "按 Enter 退出"
    }
} else {
    # ---------- 非管理员，提权后执行 ----------
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    
    # 将选中的 URL 编码后传给提权后的进程
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes(
        "`$mainScriptURL='$mainScriptURL'; [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; `$c=Invoke-RestMethod -Uri `$mainScriptURL -UseBasicParsing; Invoke-Expression `$c"
    ))
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCommand"
}