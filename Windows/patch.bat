@echo off
chcp 65001 >nul 2>&1
title Antigravity Chinese Patch
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\patch_antigravity.ps1"
pause >nul
