# SilverfoxCleanScript

> 针对银狐病毒的 PowerShell 一键清理工具  
> 删除恶意 WDAC 策略 · 解除杀软屏蔽 · 自动部署 360 系统急救箱  
> 兼容 Windows 10 / Windows 11

## 主要功能

**智能清理 WDAC 策略**

- 优先使用系统内置的 `CiTool.exe`（Windows 11 22H2 及以上）精确删除非系统策略。
- 若系统不支持，则回退到手动删除 `SiPolicy.p7b` 文件，并自动备份到桌面。

**解除杀毒软件屏蔽** – 清理策略后，被杀毒软件（包括 Windows Defender、360、火绒等）可恢复正常运行。

**自动部署 360 系统急救箱** – 根据系统位数自动下载并解压最新版急救箱到桌面，便于后续全盘扫描。

**生成备用清理脚本** – 在桌面生成 `清理WDAC.cmd`，供无法运行 PowerShell 时应急使用。

**完整备份** – 手动删除模式下，策略文件会备份至桌面 `WDAC_Backup_*` 文件夹，便于恢复。

## 快速使用

**以管理员身份打开 PowerShell**，根据网络环境选择以下任一命令执行：

### GitHub

```powershell
irm https://raw.githubusercontent.com/herta0426/SilverfoxCleanScript/refs/heads/main/SilverfoxCleanScript.ps1 | iex
```
### Gitee

```powershell
irm https://raw.giteeusercontent.com/mb-v/SilverfoxCleanScript/raw/master/SilverfoxCleanScript.ps1 | iex
```

