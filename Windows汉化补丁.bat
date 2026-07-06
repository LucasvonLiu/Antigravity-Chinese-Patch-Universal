@echo off
title Antigravity Chinese Patch Installer (Windows版汉化补丁)
echo ============================================================
echo      Antigravity 跨平台汉化补丁 — Windows 原生安装器
echo ============================================================
echo.
echo 正在调用底层 PowerShell 核心脚本，请稍等...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\patch_antigravity.ps1"
echo.
echo ------------------------------------------------------------
echo 操作完成！按任意键退出...
pause >nul
