# ============================================================
#  Antigravity 中文汉化补丁 — Windows 安装脚本
#  功能：安装/更新汉化 | 卸载还原 | 状态检查
#  对标 macOS install.sh 架构
# ============================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 路径定义 ──────────────────────────────────────────────
$programDir    = "$env:LOCALAPPDATA\Programs\antigravity"
$resourcesDir  = "$programDir\resources"
$originalAsar  = "$resourcesDir\app.asar"
$preloadBackup = "$resourcesDir\preload.js.original.bak"
$patchMarker   = "Antigravity Chinese Localization Patch"

# 脚本所在目录
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Get-Location }
$rootDir = (Get-Item $scriptDir).Parent.FullName
$localPatchJs = Join-Path $rootDir "dist\preload_patch.js"

# ── 工具函数 ──────────────────────────────────────────────
function Write-Info    ($msg) { Write-Host "[信息] $msg" -ForegroundColor Cyan }
function Write-Success ($msg) { Write-Host "[完成] $msg" -ForegroundColor Green }
function Write-Warn    ($msg) { Write-Host "[警告] $msg" -ForegroundColor Yellow }
function Write-Err     ($msg) { Write-Host "[错误] $msg" -ForegroundColor Red }

function Test-Prerequisites {
    if (-not (Test-Path $programDir)) {
        Write-Err "未找到 Antigravity 安装目录，请确认已安装至默认位置。"
        return $false
    }
    if (-not (Test-Path $originalAsar)) {
        Write-Err "未找到 app.asar 文件：$originalAsar"
        return $false
    }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Err "未检测到 Node.js / npx 环境。"
        Write-Host "  请前往 https://nodejs.org 下载安装 Node.js" -ForegroundColor Yellow
        return $false
    }
    if (-not (Test-Path $localPatchJs)) {
        Write-Err "未找到本地补丁脚本：$localPatchJs"
        return $false
    }
    return $true
}

function Stop-Client {
    $proc = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
    if ($proc) {
        Write-Info "正在关闭 Antigravity 客户端..."
        Stop-Process -Name "Antigravity" -Force
        Start-Sleep -Seconds 2
    }
}

function Start-Client {
    $exePath = Join-Path $programDir "Antigravity.exe"
    if (Test-Path $exePath) {
        Write-Info "正在重新启动 Antigravity 客户端..."
        Start-Process $exePath
    } else {
        Write-Warn "无法自动启动客户端，请手动打开 Antigravity。"
    }
}

# ── 功能 1：安装/更新汉化 ────────────────────────────────
function Apply-Patch {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "     正在安装/更新中文汉化补丁" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Prerequisites)) {
        Read-Host "按回车键返回主菜单..."
        return
    }

    Stop-Client

    # 临时工作目录
    $tempDir = Join-Path $env:TEMP "antigravity_patch_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    try {
        Write-Info "正在解包 app.asar..."
        $extractDir = Join-Path $tempDir "asar_extracted"
        & npx --yes @electron/asar extract $originalAsar $extractDir

        $targetPreload = Join-Path $extractDir "dist\preload.js"
        if (-not (Test-Path $targetPreload)) {
            Write-Err "解包后未找到 dist/preload.js，asar 文件结构可能已变更。"
            return
        }

        # 智能备份管理（对标 macOS：仅备份 preload.js，避免 asar.unpacked 引用断裂）
        $preloadContent = [System.IO.File]::ReadAllText($targetPreload, [System.Text.Encoding]::UTF8)
        if ($preloadContent -match [regex]::Escape($patchMarker)) {
            Write-Info "检测到已汉化的客户端。"
            if (Test-Path $preloadBackup) {
                Write-Info "正在从备份还原原始 preload.js 后重新注入..."
                Copy-Item $preloadBackup $targetPreload -Force
            } else {
                Write-Warn "无原始备份，将在已汉化的 preload.js 上重新注入。"
            }
        } else {
            Write-Info "检测到未汉化的客户端，正在备份原始 preload.js..."
            Copy-Item $targetPreload $preloadBackup -Force
            Write-Success "备份完成 -> $preloadBackup"
        }

        Write-Info "正在注入汉化代码..."
        # 读取补丁代码中 marker 之后的内容
        $patchFull = [System.IO.File]::ReadAllText($localPatchJs, [System.Text.Encoding]::UTF8)
        $markerIndex = $patchFull.IndexOf("// $patchMarker")
        if ($markerIndex -ge 0) {
            $patchCode = $patchFull.Substring($markerIndex)
        } else {
            Write-Warn "未找到补丁标记，将追加整个补丁文件。"
            $patchCode = $patchFull
        }

        # 追加到原始 preload.js 末尾（使用 UTF-8 无 BOM，避免干扰 JS 解析）
        $originalContent = [System.IO.File]::ReadAllText($targetPreload, [System.Text.Encoding]::UTF8)
        $newContent = $originalContent + "`r`n`r`n" + $patchCode
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($targetPreload, $newContent, $utf8NoBom)
        Write-Success "汉化代码注入完成。"

        Write-Info "正在重新打包 app.asar..."
        & npx --yes @electron/asar pack $extractDir $originalAsar --unpack-dir "node_modules"
        Write-Success "打包完成。"

        Start-Client

        Write-Host ""
        Write-Success "汉化补丁安装成功！请查看已重新启动的 Antigravity 客户端。"
    } catch {
        Write-Err "安装过程出错: $_"
    } finally {
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }

    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

# ── 功能 2：卸载还原 ──────────────────────────────────────
function Restore-Backup {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "     正在还原官方原版客户端" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""

    if (-not (Test-Path $preloadBackup)) {
        Write-Err "未找到原始 preload.js 备份文件，无法还原。"
        Write-Host "  如果从未安装过汉化补丁，则不需要还原。"
        Read-Host "按回车键返回主菜单..."
        return
    }

    if (-not (Test-Prerequisites)) {
        Read-Host "按回车键返回主菜单..."
        return
    }

    Stop-Client

    $tempDir = Join-Path $env:TEMP "antigravity_restore_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    try {
        Write-Info "正在解包当前 app.asar..."
        $extractDir = Join-Path $tempDir "asar_restore"
        & npx --yes @electron/asar extract $originalAsar $extractDir

        Write-Info "正在还原原始 preload.js..."
        Copy-Item $preloadBackup (Join-Path $extractDir "dist\preload.js") -Force

        Write-Info "正在重新打包 app.asar..."
        & npx --yes @electron/asar pack $extractDir $originalAsar --unpack-dir "node_modules"
        Write-Success "还原完成。"

        Start-Client

        Write-Host ""
        Write-Success "已成功还原为官方原版客户端。"
    } catch {
        Write-Err "还原过程出错: $_"
    } finally {
        if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    }

    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

# ── 功能 3：检查状态 ──────────────────────────────────────
function Check-Status {
    Write-Host ""
    Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "     Antigravity 客户端状态检查" -ForegroundColor Blue
    Write-Host "════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    # 安装检查
    if (Test-Path $programDir) {
        Write-Success "客户端安装路径: $programDir"
    } else {
        Write-Err "客户端未安装"
        Read-Host "按回车键返回主菜单..."
        return
    }

    # app.asar 文件信息
    if (Test-Path $originalAsar) {
        $size = (Get-Item $originalAsar).Length
        $sizeMB = [Math]::Round($size / 1MB, 2)
        Write-Info "app.asar 大小: $sizeMB MB ($size 字节)"

        # 检查客户端版本和汉化状态
        if (Get-Command npx -ErrorAction SilentlyContinue) {
            $tempDir = Join-Path $env:TEMP "antigravity_check_$(Get-Random)"
            try {
                & npx --yes @electron/asar extract $originalAsar $tempDir 2>$null
                $pkg = Join-Path $tempDir "package.json"
                if (Test-Path $pkg) {
                    $version = (Get-Content $pkg -Raw | ConvertFrom-Json).version
                    if ($version) { Write-Info "客户端版本: $version" }
                }
                $preload = Join-Path $tempDir "dist\preload.js"
                if (Test-Path $preload) {
                    $text = [System.IO.File]::ReadAllText($preload, [System.Text.Encoding]::UTF8)
                    if ($text -match [regex]::Escape($patchMarker)) {
                        Write-Host "  汉化状态: 已汉化" -ForegroundColor Cyan
                    } else {
                        Write-Host "  汉化状态: 未汉化 (官方原版)" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Warn "状态解析异常"
            } finally {
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            }
        }
    } else {
        Write-Err "app.asar 文件不存在"
    }

    # 备份状态
    if (Test-Path $preloadBackup) {
        Write-Success "原版 preload.js 备份: 存在"
    } else {
        Write-Warn "原版 preload.js 备份: 不存在"
    }

    # Node.js 环境
    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVer = (& node --version).Trim()
        Write-Success "Node.js 环境: 已安装 ($nodeVer)"
    } else {
        Write-Warn "Node.js 环境: 未安装"
    }

    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

# ── 主菜单 ────────────────────────────────────────────────
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║     Antigravity 中文汉化补丁 — Windows 管理工具     ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. 安装/更新中文汉化补丁" -ForegroundColor Green
    Write-Host "  2. 卸载补丁并还原官方原版" -ForegroundColor Yellow
    Write-Host "  3. 检查当前汉化状态与版本" -ForegroundColor Blue
    Write-Host "  4. 退出" -ForegroundColor Gray
    Write-Host ""
    return (Read-Host "  请输入选项 [1-4]")
}

# ── 入口 ──────────────────────────────────────────────────
do {
    $choice = Show-Menu
    switch ($choice) {
        "1" { Apply-Patch }
        "2" { Restore-Backup }
        "3" { Check-Status }
        "4" { break }
        default {
            Write-Warn "无效选项，请重新输入。"
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "4")

Write-Host ""
Write-Host "再见！祝您使用愉快" -ForegroundColor Green
Write-Host ""
