# patch_antigravity.ps1
# 跨平台架构的 Windows 核心脚本
# 功能：安装、还原、检测状态

$ErrorActionPreference = "Stop"

# 定义路径
$programDir = "$env:LOCALAPPDATA\Programs\antigravity"
$resourcesDir = "$programDir\resources"
$originalAsar = "$resourcesDir\app.asar"
$backupAsar = "$resourcesDir\app.asar.bak"

# 相对路径解析 (兼容在不同目录下被 bat 调用的情况)
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $scriptDir) {
    $scriptDir = Get-Location
}

# 根目录路径（因为脚本在 lib/ 文件夹里，所以上推一层）
$rootDir = (Get-Item $scriptDir).Parent.FullName
$localPreloadJs = Join-Path $rootDir "dist\preload_patch.js"

Function Stop-Client {
    Write-Host "正在关闭 Antigravity 客户端..." -ForegroundColor Yellow
    $processes = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
    if ($processes) {
        Stop-Process -Name "Antigravity" -Force
        Start-Sleep -Seconds 2
    }
}

Function Start-Client {
    $exePath = Join-Path $programDir "Antigravity.exe"
    if (Test-Path $exePath) {
        Write-Host "正在重启 Antigravity 客户端..." -ForegroundColor Green
        Start-Process "cmd.exe" -ArgumentList "/c start `"`" `"$exePath`"" -WindowStyle Hidden
    } else {
        Write-Warning "未找到 Antigravity.exe。请手动启动软件。"
    }
}

Function Show-Menu {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "     Antigravity 跨平台汉化工具 — Windows 核心服务" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  1. 🚀 安装 / 更新汉化补丁" -ForegroundColor Green
    Write-Host "  2. 🛡️  卸载补丁并还原官方原版" -ForegroundColor Yellow
    Write-Host "  3. 🔍 检查当前汉化状态与版本" -ForegroundColor Blue
    Write-Host "  4. 🚪 退出" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    $choice = Read-Host "请输入对应选项的数字并回车 [1-4]"
    return $choice
}

Function Apply-Patch {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     正在安装中文汉化补丁 (动态注入模式)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not (Test-Path $originalAsar)) {
        Write-Error "错误: 未找到 Antigravity 安装目录 ($programDir)。请先安装官方客户端。"
        Read-Host "按回车键返回主菜单..."
        return
    }

    if (-not (Test-Path $localPreloadJs)) {
        Write-Error "错误: 核心补丁文件缺失 ($localPreloadJs)。请勿随意移动文件目录！"
        Read-Host "按回车键返回主菜单..."
        return
    }
    
    $nodeCheck = Get-Command npx -ErrorAction SilentlyContinue
    if (-not $nodeCheck) {
        Write-Error "错误: 未检测到 Node.js (npx) 环境。在跨平台架构下，动态注入功能必须依赖 Node.js。"
        Write-Host "请前往 https://nodejs.org 下载并安装 Node.js 后重试。" -ForegroundColor Yellow
        Read-Host "按回车键返回主菜单..."
        return
    }

    Stop-Client
    
    # 检测备份并建立备份
    $tempDir = Join-Path $env:TEMP "antigravity_asar_temp"
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

    $isCurrentPatched = $false
    try {
        $checkTemp = Join-Path $tempDir "check_extract"
        & npx --yes @electron/asar extract $originalAsar $checkTemp
        $checkPreload = Join-Path $checkTemp "dist\preload.js"
        if (Test-Path $checkPreload) {
            $preloadText = Get-Content -Path $checkPreload -Raw
            if ($preloadText -like "*Antigravity Chinese Localization Patch*") {
                $isCurrentPatched = $true
            }
        }
        if (Test-Path $checkTemp) { Remove-Item -Recurse -Force $checkTemp -ErrorAction SilentlyContinue }
    } catch {}

    if (-not $isCurrentPatched) {
        Write-Host "检测到官方纯净版本客户端。正在更新安全备份..." -ForegroundColor Green
        Copy-Item $originalAsar $backupAsar -Force
    } else {
        Write-Host "检测到已汉化版本的客户端。使用现有安全备份。" -ForegroundColor Yellow
    }

    # 执行动态注入
    try {
        Write-Host "正在解包 app.asar... 这可能需要几秒钟。" -ForegroundColor Gray
        $asarTemp = Join-Path $tempDir "asar_extracted"
        & npx --yes @electron/asar extract $backupAsar $asarTemp
        
        Write-Host "正在将补丁代码注入到系统底层..." -ForegroundColor Gray
        $targetPreload = Join-Path $asarTemp "dist\preload.js"
        if (Test-Path $targetPreload) {
            $originalPreloadContent = Get-Content -Path $targetPreload -Raw
            $localContent = Get-Content -Path $localPreloadJs -Raw
            $patchMarker = "// Antigravity Chinese Localization Patch"
            $markerIndex = $localContent.IndexOf($patchMarker)
            if ($markerIndex -ge 0) {
                $patchCode = $localContent.Substring($markerIndex)
                $newPreloadContent = $originalPreloadContent + "`r`n`r`n" + $patchCode
                Set-Content -Path $targetPreload -Value $newPreloadContent -Force
                Write-Host "✅ 补丁代码注入成功！" -ForegroundColor Green
            } else {
                Write-Warning "警告：未能找到补丁注入标记。"
            }
        }
        
        Write-Host "正在重新封包核心引擎..." -ForegroundColor Gray
        & npx --yes @electron/asar pack $asarTemp $originalAsar --unpack-dir "node_modules"
        
        if (Test-Path $asarTemp) { Remove-Item -Recurse -Force $asarTemp -ErrorAction SilentlyContinue }
        
        Write-Host "✅ 汉化补丁安装圆满完成！" -ForegroundColor Green
        Start-Client
    } catch {
        Write-Error "发生严重错误，安装失败: $_"
    }
    
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
    
    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

Function Restore-Backup {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host "     正在还原 Antigravity 官方英文原版" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Yellow
    Write-Host ""
    
    if (-not (Test-Path $backupAsar)) {
        Write-Host "错误: 找不到安全备份文件 'app.asar.bak'。如果你是第一次运行且没安装过补丁，那么当前就是原装版无需还原。" -ForegroundColor Red
        Write-Host ""
        Read-Host "按回车键返回主菜单..."
        return
    }
    
    Stop-Client
    
    try {
        Write-Host "正在覆盖还原原版核心文件..." -ForegroundColor Green
        Copy-Item $backupAsar $originalAsar -Force
        Write-Host "✅ 成功还原为官方原汁原味客户端！" -ForegroundColor Green
        Start-Client
    } catch {
        Write-Host "错误: 还原备份文件失败: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

Function Check-Status {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     Antigravity 客户端汉化状态分析" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "程序安装路径: $programDir"
    
    if (Test-Path $originalAsar) {
        $size = (Get-Item $originalAsar).Length
        $sizeMB = [Math]::Round($size / 1MB, 2)
        Write-Host "活动核心文件 (app.asar) 大小: $sizeMB MB" -ForegroundColor Gray
        
        $isPatched = "Unpatched (官方原装纯净版)"
        $patchedColor = "Green"
        
        $nodeCheck = Get-Command npx -ErrorAction SilentlyContinue
        if ($nodeCheck) {
            try {
                $tempDir = Join-Path $env:TEMP "antigravity_inspect_temp"
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
                & npx --yes @electron/asar extract $originalAsar $tempDir
                $preloadPath = Join-Path $tempDir "dist\preload.js"
                $packagePath = Join-Path $tempDir "package.json"
                
                if (Test-Path $packagePath) {
                    $pkg = Get-Content $packagePath | ConvertFrom-Json
                    Write-Host "客户端内核版本号: $($pkg.version)" -ForegroundColor White
                }
                
                if (Test-Path $preloadPath) {
                    $preloadText = Get-Content -Path $preloadPath -Raw
                    if ($preloadText -like "*Antigravity Chinese Localization Patch*") {
                        $isPatched = "Patched (✅ 已汉化状态)"
                        $patchedColor = "Cyan"
                    }
                }
                if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
            } catch {
                $isPatched = "Unknown (分析引擎异常)"
                $patchedColor = "Yellow"
            }
        }
        Write-Host "当前汉化状态: $isPatched" -ForegroundColor $patchedColor
    } else {
        Write-Host "活动核心文件: ❌ 未找到 (你是不是没安装？)" -ForegroundColor Red
    }
    
    if (Test-Path $backupAsar) {
        Write-Host "官方备份文件 (app.asar.bak): ✅ 存在 (安全)" -ForegroundColor Green
    } else {
        Write-Host "官方备份文件 (app.asar.bak): ⚪ 不存在" -ForegroundColor Yellow
    }
    
    $nodeCheck = Get-Command npx -ErrorAction SilentlyContinue
    if ($nodeCheck) {
        Write-Host "Node.js (npx) 运行环境: ✅ 已就绪" -ForegroundColor Green
    } else {
        Write-Host "Node.js (npx) 运行环境: ❌ 缺失 (安装补丁需要它)" -ForegroundColor Red
    }
    
    Write-Host ""
    Read-Host "按回车键返回主菜单..."
}

# 交互主循环
do {
    $choice = Show-Menu
    switch ($choice) {
        "1" { Apply-Patch }
        "2" { Restore-Backup }
        "3" { Check-Status }
        "4" { break }
        default {
            Write-Host "选项无效，请重新输入。" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice -ne "4")

Clear-Host
Write-Host "感谢使用跨平台 Antigravity 中文汉化补丁！祝你工作高效！" -ForegroundColor Green
