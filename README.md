# SilverfoxCleanScript
针对银狐病毒的PowerShell清理工具，删除恶意WDAC策略、解除杀软屏蔽、自动部署360系统急救箱，兼容Win10/Win11。
# 银狐 WDAC 清理工具

一键删除银狐木马植入的恶意 WDAC 策略，恢复杀毒软件运行。

## 快速使用

**以管理员身份打开 PowerShell**，执行：

```powershell
irm https://raw.githubusercontent.com/herta0426/SilverfoxCleanScript/refs/heads/main/SilverfoxCleanScript.ps1 | iex
