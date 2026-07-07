# ============================================================
#  Antigravity 中文汉化补丁 — Windows 原生图形界面
#  双击 gui.bat 即可运行，无需打开终端
#  对标 macOS macOS汉化工具.applescript 架构
# ============================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ── 路径定义 ──────────────────────────────────────────────
$programDir    = "$env:LOCALAPPDATA\Programs\antigravity"
$resourcesDir  = "$programDir\resources"
$originalAsar  = "$resourcesDir\app.asar"
$preloadBackup = "$resourcesDir\preload.js.original.bak"
$patchMarker   = "Antigravity Chinese Localization Patch"

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = Get-Location }
$rootDir = (Get-Item $scriptDir).Parent.FullName
$localPatchJs = Join-Path $rootDir "dist\preload_patch.js"

# ── 工具函数 ──────────────────────────────────────────────
function Show-Msg($text, $title, $icon) {
    [System.Windows.Forms.MessageBox]::Show(
        $text, $title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $icon
    ) | Out-Null
}

function Show-Confirm($text, $title) {
    return [System.Windows.Forms.MessageBox]::Show(
        $text, $title,
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

function Stop-Client {
    $proc = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Name "Antigravity" -Force
        Start-Sleep -Seconds 2
    }
}

function Start-Client {
    $exePath = Join-Path $programDir "Antigravity.exe"
    if (Test-Path $exePath) { Start-Process $exePath }
}

# ── 前置检查 ──────────────────────────────────────────────
function Test-Preflight {
    if (-not (Test-Path $originalAsar)) {
        Show-Msg "未找到 Antigravity 安装目录。`n请确认已安装客户端。" "文件缺失" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    if (-not (Test-Path $localPatchJs)) {
        Show-Msg "未找到补丁文件。`n请将本工具放回汉化补丁项目文件夹内。" "文件缺失" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Show-Msg "未检测到 Node.js 环境。`n请先安装 Node.js：https://nodejs.org" "环境缺失" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    return $true
}

# ── 安装/更新汉化 ────────────────────────────────────────
function Invoke-Install {
    if (-not (Test-Preflight)) { return }

    $res = Show-Confirm ("即将安装中文汉化补丁`n`n此操作将会：`n  - 自动关闭 Antigravity 客户端`n  - 注入汉化代码`n  - 重新打包并启动客户端`n`n首次运行可能需要下载依赖，请耐心等待。") "安装确认"
    if ($res -ne "OK") { return }

    try {
        Stop-Client

        $tempDir = Join-Path $env:TEMP "antigravity_patch_$(Get-Random)"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        $extractDir = Join-Path $tempDir "ex"

        & npx --yes @electron/asar extract $originalAsar $extractDir
        $target = Join-Path $extractDir "dist\preload.js"
        if (-not (Test-Path $target)) { throw "解包后未找到 dist/preload.js" }

        # 智能备份 / 还原
        $content = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        if ($content -match [regex]::Escape($patchMarker)) {
            if (Test-Path $preloadBackup) { Copy-Item $preloadBackup $target -Force }
        } else {
            Copy-Item $target $preloadBackup -Force
        }

        # 注入补丁代码
        $patchFull = [System.IO.File]::ReadAllText($localPatchJs, [System.Text.Encoding]::UTF8)
        $idx = $patchFull.IndexOf("// $patchMarker")
        $patchCode = if ($idx -ge 0) { $patchFull.Substring($idx) } else { $patchFull }

        $original = [System.IO.File]::ReadAllText($target, [System.Text.Encoding]::UTF8)
        $merged = $original + "`r`n`r`n" + $patchCode
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($target, $merged, $utf8NoBom)

        & npx --yes @electron/asar pack $extractDir $originalAsar --unpack-dir "node_modules"
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

        Start-Client
        Show-Msg "汉化补丁安装成功！`n`nAntigravity 客户端已重新启动。`n请查看汉化效果。" "安装完成" ([System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Show-Msg "安装过程出错：`n$_" "安装失败" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ── 卸载还原 ─────────────────────────────────────────────
function Invoke-Restore {
    if (-not (Test-Path $preloadBackup)) {
        Show-Msg "未找到原始备份文件，无法还原。`n如从未安装过汉化补丁则无需还原。" "还原失败" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $res = Show-Confirm ("即将卸载汉化补丁并还原官方原版。`n`n此操作将会：`n  - 自动关闭 Antigravity 客户端`n  - 还原原始 preload.js`n  - 重新打包并启动客户端") "卸载确认"
    if ($res -ne "OK") { return }

    try {
        Stop-Client

        $tempDir = Join-Path $env:TEMP "antigravity_restore_$(Get-Random)"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        $extractDir = Join-Path $tempDir "ex"

        & npx --yes @electron/asar extract $originalAsar $extractDir
        Copy-Item $preloadBackup (Join-Path $extractDir "dist\preload.js") -Force
        & npx --yes @electron/asar pack $extractDir $originalAsar --unpack-dir "node_modules"
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

        Start-Client
        Show-Msg "已成功还原为官方原版客户端。" "还原完成" ([System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        Show-Msg "还原过程出错：`n$_" "还原失败" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ── 检查状态 ─────────────────────────────────────────────
function Invoke-CheckStatus {
    $info = ""

    if (Test-Path $programDir) {
        $info += "✅ 客户端已安装`n"
    } else {
        Show-Msg "❌ 客户端未安装" "检查结果" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if ((Get-Command npx -ErrorAction SilentlyContinue) -and (Test-Path $originalAsar)) {
        $tempDir = Join-Path $env:TEMP "antigravity_check_$(Get-Random)"
        try {
            & npx --yes @electron/asar extract $originalAsar $tempDir 2>$null
            $pkg = Join-Path $tempDir "package.json"
            if (Test-Path $pkg) {
                $ver = (Get-Content $pkg -Raw | ConvertFrom-Json).version
                if ($ver) { $info += "📦 客户端版本: $ver`n" }
            }
            $preload = Join-Path $tempDir "dist\preload.js"
            if (Test-Path $preload) {
                $text = [System.IO.File]::ReadAllText($preload, [System.Text.Encoding]::UTF8)
                if ($text -match [regex]::Escape($patchMarker)) {
                    $info += "🟢 汉化状态: 已汉化`n"
                } else {
                    $info += "⚪ 汉化状态: 未汉化 (官方原版)`n"
                }
            }
        } catch {
            $info += "⚠️ 状态解析异常`n"
        } finally {
            if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue }
        }
    }

    if (Test-Path $preloadBackup) {
        $info += "✅ 原版备份: 存在`n"
    } else {
        $info += "⚪ 原版备份: 不存在`n"
    }

    if (Get-Command node -ErrorAction SilentlyContinue) {
        $nodeVer = (& node --version).Trim()
        $info += "✅ Node.js: $nodeVer"
    } else {
        $info += "❌ Node.js: 未安装"
    }

    Show-Msg $info "Antigravity 状态检查" ([System.Windows.Forms.MessageBoxIcon]::Information)
}

# ── 图形界面 ─────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "Antigravity 中文汉化补丁"
$form.Size = New-Object System.Drawing.Size(340, 260)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)

$label = New-Object System.Windows.Forms.Label
$label.Text = "请选择要执行的操作："
$label.Location = New-Object System.Drawing.Point(30, 20)
$label.Size = New-Object System.Drawing.Size(280, 25)
$form.Controls.Add($label)

$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text = "安装 / 更新汉化"
$btnInstall.Location = New-Object System.Drawing.Point(60, 60)
$btnInstall.Size = New-Object System.Drawing.Size(200, 38)
$btnInstall.Add_Click({ Invoke-Install })
$form.Controls.Add($btnInstall)

$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "卸载并还原官方原版"
$btnRestore.Location = New-Object System.Drawing.Point(60, 110)
$btnRestore.Size = New-Object System.Drawing.Size(200, 38)
$btnRestore.Add_Click({ Invoke-Restore })
$form.Controls.Add($btnRestore)

$btnStatus = New-Object System.Windows.Forms.Button
$btnStatus.Text = "检查当前状态"
$btnStatus.Location = New-Object System.Drawing.Point(60, 160)
$btnStatus.Size = New-Object System.Drawing.Size(200, 38)
$btnStatus.Add_Click({ Invoke-CheckStatus })
$form.Controls.Add($btnStatus)

[void]$form.ShowDialog()
