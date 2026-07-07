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
        $patchCode = @'
// Antigravity Chinese Localization Patch (macOS Optimized)
// https://github.com/good9527/Antigravity-Chinese-Patch 鈥?娣卞害閲嶅啓鐗?
// 淇锛氫唬鐮佸尯鍩熼殧绂?/ MutationObserver 鑺傛祦 / 瀛愪覆璇激娑堥櫎
(function () {
  'use strict';

  // ============================================================
  //  搂1  缈昏瘧瀛楀吀 (Map 鈥斺€?姣旀櫘閫氬璞℃煡鎵炬洿蹇?
  // ============================================================
  const dictionary = new Map(Object.entries({
    'New Conversation': '鏂板缓瀵硅瘽',
    'Conversation History': '鍘嗗彶瀵硅瘽',
    'Scheduled Tasks': '璁″垝浠诲姟',
    'Projects': '椤圭洰',
    'Conversations': '瀵硅瘽',
    'Settings': '璁剧疆',
    'Untitled Conversation': '鏃犳爣棰樺璇?,
    'No conversations yet': '鏆傛棤瀵硅瘽',
    'See all': '鏌ョ湅鍏ㄩ儴',
    'Install IDE': '瀹夎 IDE',
    'Close': '鍏抽棴',
    'Cancel': '鍙栨秷',
    'Save': '淇濆瓨',
    'Delete': '鍒犻櫎',
    'Rename': '閲嶅懡鍚?,
    'Ask anything, @ to mention, / for actions': '闂垜浠讳綍闂锛岀敤 @ 鎻愬強鏂囦欢锛岀敤 / 鎵ц鍔ㄤ綔',
    'Open': '鎵撳紑',
    'Edit': '缂栬緫',
    'Customize': '瀹氬埗',

    // 渚ф爮瀵艰埅
    'Account': '璐︽埛',
    'Permissions': '鏉冮檺',
    'Appearance': '澶栬',
    'Customizations': '鑷畾涔?,
    'Browser': '娴忚鍣?,
    'App': '搴旂敤',
    'Not in Project': '闈為」鐩璇?,
    'Provide Feedback': '鎻愪氦鍙嶉',
    'General': '甯歌',
    'Models': '妯″瀷',
    'Shortcuts': '蹇嵎閿?,

    // 椤堕儴鑿滃崟
    'File': '鏂囦欢',
    'View': '瑙嗗浘',
    'Window': '绐楀彛',
    'Help': '甯姪',
    'New Window': '鏂板缓绐楀彛',
    'Create Project': '鍒涘缓椤圭洰',
    'Command Palette': '鍛戒护闈㈡澘',
    'Check for Updates': '妫€鏌ユ洿鏂?,

    // 鍙嶉椤?
    'Feedback Type': '鍙嶉绫诲瀷',
    'Bug Report': '缂洪櫡鎶ュ憡',
    'Feature Request': '鍔熻兘闇€姹?,
    'Auth and Billing': '璐︽埛涓庤处鍗?,
    'General Feedback': '甯歌鍙嶉',
    'Description': '闂鎻忚堪',
    'Steps to reproduce the issue': '閲嶇幇姝ラ',
    'Expected behavior': '棰勬湡缁撴灉',
    'Actual behavior': '瀹為檯缁撴灉',
    'Any error messages': '閿欒鎻愮ず淇℃伅',
    'Any relevant information': '鍏朵粬鐩稿叧淇℃伅',
    'Describe the bug you encountered...': '璇疯缁嗘弿杩版偍閬囧埌鐨勭己闄?Bug)...',
    'Steps to Reproduce': '閲嶇幇姝ラ璇存槑',
    'Attach a screenshot (optional)': '娣诲姞鎴浘 (鍙€?',
    'Attach Antigravity server logs': '闄勫甫 Antigravity 鏈嶅姟绔棩蹇?,
    'Submit': '鎻愪氦',
    'Please list the steps to reproduce the issue': '璇峰垪鍑洪噸鐜版闂鐨勬楠?,
    'Please describe the issue in detail. The more actionable your feedback, the quicker our team can address your request. Some helpful information includes': '璇疯缁嗘弿杩版偍閬囧埌鐨勯棶棰樸€傛偍鐨勫弽棣堣秺鍏蜂綋锛屾垜浠殑鍥㈤槦灏辫兘瓒婂揩鍦板鐞嗘偍鐨勮姹傘€備竴浜涙湁甯姪鐨勪俊鎭寘鎷?,

    // 蹇嵎閿〉
    'RECOMMENDED': '鎺ㄨ崘蹇嵎閿?,
    'NAVIGATION': '鐣岄潰瀵艰埅',
    'CONVERSATION': '瀵硅瘽浜や簰',
    'LAYOUT CONTROLS': '甯冨眬鎺у埗',
    'Open Conversation Picker': '鎵撳紑瀵硅瘽閫夋嫨鍣?,
    'Open File Search': '鎵撳紑鏂囦欢鎼滅储',
    'Focus Input': '鑱氱劍杈撳叆妗?,
    'Go Back': '鍚庨€€',
    'Go Forward': '鍓嶈繘',
    'File Picker': '鎵撳紑鏂囦欢閫夋嫨鍣?,
    'Select Previous Conversation': '閫夋嫨涓婁竴涓璇?,
    'Select Next Conversation': '閫夋嫨涓嬩竴涓璇?,
    'Open Settings': '鎵撳紑璁剧疆涓績',
    'Toggle Model Selector': '鍒囨崲妯″瀷閫夋嫨鍣?,
    'Toggle Voice Recording': '寮€鍚?鍏抽棴璇煶褰曞埗',
    'Find in Pane': '鍦ㄧ獥鏍间腑鏌ユ壘',
    'Toggle Sidebar': '寮€鍚?鍏抽棴渚ц竟鏍?,
    'Toggle Auxiliary Pane': '寮€鍚?鍏抽棴杈呭姪绐楁牸',
    'Zoom In': '鏀惧ぇ',
    'Zoom Out': '缂╁皬',
    'Reset Zoom': '閲嶇疆缂╂斁',

    // 鏉冮檺涓庡畨鍏?
    'Agent Settings': '鏅鸿兘浣撹缃?,
    'Security Preset': '瀹夊叏棰勮',
    'Turbo Mode': '鏋侀€熸ā寮?,
    'Turbo mode': '鏋侀€熸ā寮?,
    'Agent Behavior': '鏅鸿兘浣撹涓?,
    'Artifact Review Policy': 'Artifact 瀹℃牳绛栫暐',
    'Always Proceed': '濮嬬粓缁х画',
    'Always Ask': '濮嬬粓璇㈤棶',
    'Local Permissions': '鏈湴鏉冮檺',
    'global settings': '鍏ㄥ眬璁剧疆',
    'File Access Rules': '鏂囦欢璁块棶瑙勫垯',
    'Network Access Rules': '缃戠粶璁块棶瑙勫垯',
    'Terminal Commands': '缁堢鍛戒护',
    'Commands Outside Sandbox': '娌欑澶栧懡浠?,
    'MCP Tools': 'MCP 宸ュ叿',
    'Default': '榛樿',
    'Full Machine': '瀹屽叏鏈哄櫒璁块棶',
    'Custom': '鑷畾涔?,
    'Danger Zone': '鍗遍櫓鍖哄煙',
    'Delete Project': '鍒犻櫎椤圭洰',

    // 瀹夊叏棰勮鎻忚堪
    'Cautious': '璋ㄦ厧妯″紡',
    'Balanced': '鍧囪　妯″紡',
    'Auto': '鑷姩妯″紡',
    'Automatic': '鑷姩',
    'Allow': '鍏佽',
    'Deny': '鎷掔粷',
    'Ask': '璇㈤棶',
    'Allowed': '宸插厑璁?,
    'Denied': '宸叉嫆缁?,
    'Add Rule': '娣诲姞瑙勫垯',
    'Add Path': '娣诲姞璺緞',
    'Add URL': '娣诲姞 URL',
    'Add Command': '娣诲姞鍛戒护',
    'No rules defined': '鏆傛湭瀹氫箟瑙勫垯',
    'Workspace': '宸ヤ綔鍖?,
    'Global': '鍏ㄥ眬',
    'Inherited': '宸茬户鎵?,
    'Override': '瑕嗙洊',
    'Reset to Default': '鎭㈠榛樿鍊?,
    'Unsaved Changes': '鏈夋湭淇濆瓨鐨勬洿鏀?,
    'Save Changes': '淇濆瓨鏇存敼',
    'Discard Changes': '涓㈠純鏇存敼',
    'Apply': '搴旂敤',
    'Enabled': '宸插惎鐢?,
    'Disabled': '宸茬鐢?,
    'On': '寮€鍚?,
    'Off': '鍏抽棴',
    'None': '鏃?,
    'Loading...': '鍔犺浇涓?..',
    'Error': '閿欒',
    'Warning': '璀﹀憡',
    'Success': '鎴愬姛',
    'Info': '鎻愮ず',
    'Confirm': '纭',
    'Yes': '鏄?,
    'No': '鍚?,
    'OK': '纭',
    'Done': '瀹屾垚',
    'Back': '杩斿洖',
    'Next': '涓嬩竴姝?,
    'Previous': '涓婁竴姝?,
    'Finish': '瀹屾垚',
    'Continue': '缁х画',
    'Skip': '璺宠繃',
    'Reset': '閲嶇疆',

    // 椤圭洰璁剧疆
    'Folders': '椤圭洰鏂囦欢澶?,
    '+ Add Folder': '+ 娣诲姞鏂囦欢澶?,
    'Project-Specific Settings': '椤圭洰鐗瑰畾璁剧疆',
    'Go To Projects': '鍓嶅線椤圭洰',
    'File Permissions': '鏂囦欢鏉冮檺',
    'Network Permissions': '缃戠粶鏉冮檺',
    'Terminal & Tooling Permissions': '缁堢涓庡伐鍏锋潈闄?,

    // 瀹㈡埛绔缃?
    'App Settings': '搴旂敤璁剧疆',
    'Prevent Sleep': '闃叉鐫＄湢',
    'Keep In Menu Bar': '淇濈暀鍦ㄨ彍鍗曟爮涓?,
    'Notifications': '閫氱煡',
    'Notification Settings': '閫氱煡璁剧疆',
    'Open System Preferences': '鎵撳紑绯荤粺鍋忓ソ璁剧疆',

    // 娴忚鍣ㄨ缃?
    'Browser Settings': '娴忚鍣ㄨ缃?,
    'Browser Javascript Execution Policy': '娴忚鍣?JS 鎵ц绛栫暐',
    'Actuation Permissions': '鎵ц鏉冮檺',
    'Browser Actuation Rules': '娴忚鍣ㄦ搷浣滆鍒?,

    // 鑷畾涔?/ MCP
    'Token Usage': 'Token 鐢ㄩ噺',
    'Installed MCP Servers': '宸插畨瑁呯殑 MCP 鏈嶅姟',
    'Add MCP +': '+ 娣诲姞 MCP 鏈嶅姟',
    'Refresh': '鍒锋柊',
    'No MCP Servers': '鏆傛棤 MCP 鏈嶅姟',
    'Build With Google Plugins': '鍩轰簬 Google 瀹樻柟鎻掍欢鏋勫缓',

    // 妯″瀷 / 棰濆害
    'Model Credits': 'AI 棰濆害',
    'Enable AI Credit Overages': '鍏佽瓒呴浣跨敤 AI 棰濆害',
    'See Activity': '鏌ョ湅娲诲姩',
    'Get More AI Credits': '鑾峰彇鏇村 AI 棰濆害',
    'Model Quota': '妯″瀷閰嶉',

    // 澶栬
    'Chat Settings': '鑱婂ぉ璁剧疆',
    'Verbose agent chat': '鏄剧ず璇︾粏鎬濊€冭繃绋?,
    'Preset': '棰勮涓婚鑹?,
    'Default Light': '榛樿娴呰壊',
    'Default Dark': '榛樿娣辫壊',
    'Background': '鑳屾櫙搴曡壊',
    'Foreground': '鍓嶆櫙鏂囧瓧瀛楄壊',
    'Accent': '鍏ㄥ眬寮鸿皟鑹?,
    'Light Theme': '娴呰壊涓婚',
    'Dark Theme': '娣辫壊涓婚',
    'System': '璺熼殢绯荤粺',
    'Light': '娴呰壊',
    'Dark': '娣辫壊',

    // 璐︽埛
    'Marketing Emails': '鎺ユ敹浜у搧鎺ㄥ箍涓庢妧鏈懆鎶?,
    'Upgrade': '璁㈤槄鍗囩骇',
    'Sign Out': '閫€鍑哄綋鍓嶈处鎴?,
    'Terms of Service': '鏈嶅姟鏉℃璇存槑',
    'Email': '閭璐﹀彿',

    // 涓婁笅鏂囪彍鍗?
    'Add Context': '娣诲姞涓婁笅鏂?,
    'Media': '濯掍綋鏂囦欢 (鍥剧墖/瑙嗛)',
    'Mentions': '鎻愬強椤?(@ 绗﹀彿)',
    'Actions': '鍔ㄤ綔鎸囦护 (/ 绗﹀彿)',

    // 绐楀彛鎺у埗
    'Minimize': '鏈€灏忓寲',
    'Maximize': '鏈€澶у寲',
    'Toggle Developer Tools': '鍒囨崲寮€鍙戣€呭伐鍏?,

    // 閾炬帴鐗囨
    'Inherits from': '缁ф壙鑷?,
    'Local permissions have higher priority': '鏈湴鏉冮檺鍏锋湁鏇撮珮浼樺厛绾?,
    'Learn more': '浜嗚В鏇村',
    '. Local permissions have higher priority': '銆傛湰鍦版潈闄愬叿鏈夋洿楂樹紭鍏堢骇',
    'Learn more about ': '浜嗚В鏇村鍏充簬 ',
    'Learn more about': '浜嗚В鏇村鍏充簬',

    // 鎼滅储涓庨€氱敤鎿嶄綔
    'Search conversations...': '鎼滅储瀵硅瘽...',
    'Filter': '绛涢€?,
    'Enable Telemetry': '鍏佽鏀堕泦鍖垮悕浣跨敤鏁版嵁',
    'Manually customize individual settings.': '鎵嬪姩閰嶇疆鍏蜂綋鐨勬潈闄愯鍒欍€?,
    'Search': '鎼滅储',
    'Copy': '澶嶅埗',
    'Copied!': '宸插鍒讹紒',
    'Clear All': '娓呴櫎鍏ㄩ儴',
    'Clear History': '娓呴櫎鍘嗗彶璁板綍',
    'Stop generating': '鍋滄鐢熸垚',
    'Regenerate': '閲嶆柊鐢熸垚',
    'Retry': '閲嶈瘯',
    'Advanced Settings': '楂樼骇璁剧疆',
    'Updates': '鏇存柊',
    'Review': '瀹℃牳',
    'Plan': '璁㈤槄璁″垝',
    'Your Plan:': '璁㈤槄璁″垝锛?,
    'Google AI Pro': 'Google AI 涓撲笟鐗?,
    'Google AI Ultra': 'Google AI 鏃楄埌鐗?,
    'You can upgrade to a Google AI Ultra plan to receive higher rate limits.': '鎮ㄥ彲浠ュ崌绾у埌 Google AI 鏃楄埌鐗堣鍒掍互鑾峰彇鏇撮珮鐨勯€熺巼闄愬埗銆?,
    'Verbose Agent Chat': '灞曠ず鏅鸿兘浣撳畬鏁存€濊€冩楠?,
    'Conversation Width': '瀵硅瘽鍖哄煙瀹藉害',
    'Configure the maximum width of the conversation panel.': '閰嶇疆瀵硅瘽闈㈡澘鐨勬渶澶у搴︺€?,
    'Gemini Models': 'Gemini 妯″瀷',
    'Claude and GPT models': 'Claude 鍜?GPT 妯″瀷',
    'Weekly Limit': '姣忓懆棰濆害闄愬埗',
    'Five Hour Limit': '5灏忔椂棰濆害闄愬埗',
    'Within each group, models share a weekly limit and a 5-hour limit. Quota is consumed proportionally to the cost of the tokens. Thus, limits will last longer with shorter tasks or using more cost-effective models. The 5-hour limit smooths out aggregate demand to fairly distribute global capacity across all users, while your weekly limit is tied directly to your individual tier.': '鍦ㄦ瘡涓垎缁勫唴锛屾ā鍨嬪叡浜瘡鍛ㄥ拰 5 灏忔椂鐨勯搴﹂檺鍒躲€傞厤棰濈殑娑堣€椾笌鎵€鐢?Token 鐨勬垚鏈垚姣斾緥銆傚洜姝わ紝浠诲姟瓒婄煭鎴栦娇鐢ㄨ秺鍏锋€т环姣旂殑妯″瀷锛岄檺棰濈殑鎸佺画鏃堕棿瓒婇暱銆? 灏忔椂棰濆害闄愬埗鐢ㄤ簬骞虫姂鎬讳綋闇€姹傦紝浠ヤ究鍦ㄦ墍鏈夌敤鎴蜂箣闂村叕骞冲垎閰嶅叏鐞冩湇鍔¤兘鍔涳紝鑰屾偍鐨勬瘡鍛ㄩ搴﹂檺鍒跺垯鐩存帴涓庢偍鐨勪釜浜虹瓑绾ф寕閽┿€?,

    // 鐘舵€佹寚绀?& 鎬濊€冩楠?
    'Working..': '姝ｅ湪澶勭悊..',
    'Working...': '姝ｅ湪澶勭悊...',
    'Working': '姝ｅ湪澶勭悊',
    'Thinking..': '姝ｅ湪鎬濊€?.',
    'Thinking...': '姝ｅ湪鎬濊€?..',
    'Thinking': '姝ｅ湪鎬濊€?,
    'Analyzing..': '姝ｅ湪鍒嗘瀽..',
    'Analyzing...': '姝ｅ湪鍒嗘瀽...',
    'Analyzing': '姝ｅ湪鍒嗘瀽',

    // 鎬濊€冩楠ゆ姌鍙犲潡鏍囩
    'Thought for': '鎬濊€冪敤鏃?,
    'Thought': '鎬濊€冭繃绋?,
    'Thinking step': '鎬濊€冩楠?,
    'thinking step': '鎬濊€冩楠?,
    'thinking steps': '鎬濊€冩楠?,
    'Thinking Steps': '鎬濊€冩楠?,
    'Show thinking': '灞曞紑鎬濊€冭繃绋?,
    'Hide thinking': '鏀惰捣鎬濊€冭繃绋?,
    'Show thought': '灞曞紑鎬濊€冭繃绋?,
    'Hide thought': '鏀惰捣鎬濊€冭繃绋?,
    'Show Thinking': '灞曞紑鎬濊€冭繃绋?,
    'Hide Thinking': '鏀惰捣鎬濊€冭繃绋?,
    'View thinking': '鏌ョ湅鎬濊€冭繃绋?,
    'View Thinking': '鏌ョ湅鎬濊€冭繃绋?,
    'Expanded': '宸插睍寮€',
    'Collapsed': '宸叉敹璧?,
    'Expand': '灞曞紑',
    'Collapse': '鏀惰捣',
    'Show details': '鏄剧ず璇︽儏',
    'Hide details': '闅愯棌璇︽儏',
    'Show more': '鏄剧ず鏇村',
    'Show less': '鏄剧ず鏇村皯',
    'Read more': '闃呰鏇村',
    'Read less': '鏀惰捣鍐呭',
    'See more': '鏌ョ湅鏇村',
    'See less': '鏀惰捣鍐呭',
    'View more': '鏌ョ湅鏇村',
    'View less': '鏀惰捣鍐呭',

    // 瀵硅瘽鎿嶄綔
    'Message': '娑堟伅',
    'Messages': '娑堟伅鍒楄〃',
    'Reply': '鍥炲',
    'Edit message': '缂栬緫娑堟伅',
    'Delete message': '鍒犻櫎娑堟伅',
    'Copy message': '澶嶅埗娑堟伅',
    'Regenerate response': '閲嶆柊鐢熸垚鍥炲',
    'New message': '鏂版秷鎭?,
    'Send message': '鍙戦€佹秷鎭?,
    'Type a message': '杈撳叆娑堟伅...',
    'You': '浣?,
    'Assistant': '鍔╂墜',
    'User': '鐢ㄦ埛',
    'System': '绯荤粺',
    'Pending': '绛夊緟涓?,
    'Streaming': '娴佸紡杈撳嚭涓?,
    'Complete': '宸插畬鎴?,
    'Failed': '澶辫触',
    'Cancelled': '宸插彇娑?,
    'Interrupted': '宸蹭腑鏂?,
    'Paused': '宸叉殏鍋?,
    'Resumed': '宸叉仮澶?,
    'Queued': '绛夊緟闃熷垪',
    'Processing': '澶勭悊涓?,
    'Generating': '鐢熸垚涓?,
    'Loading': '鍔犺浇涓?,

    // 宸ュ叿璋冪敤鐘舵€?
    'Tool call': '宸ュ叿璋冪敤',
    'Tool calls': '宸ュ叿璋冪敤鍒楄〃',
    'Running tool': '姝ｅ湪鎵ц宸ュ叿',
    'Tool result': '宸ュ叿杩斿洖缁撴灉',
    'Function call': '鍑芥暟璋冪敤',
    'Function result': '鍑芥暟杩斿洖缁撴灉',
    'Calling': '璋冪敤涓?,
    'Called': '宸茶皟鐢?,
    'Executed': '宸叉墽琛?,
    'Execution': '鎵ц',
    'Result': '缁撴灉',
    'Output': '杈撳嚭',
    'Input': '杈撳叆',
    'Error': '閿欒',
    'Timeout': '瓒呮椂',
    'Rate limited': '閫熺巼鍙楅檺',
    'Permission denied': '鏉冮檺琚嫆缁?,

    // 鏂囦欢鎿嶄綔鐘舵€?
    'Reading file': '璇诲彇鏂囦欢涓?,
    'Writing file': '鍐欏叆鏂囦欢涓?,
    'Creating file': '鍒涘缓鏂囦欢涓?,
    'Deleting file': '鍒犻櫎鏂囦欢涓?,
    'Editing file': '缂栬緫鏂囦欢涓?,
    'Searching file': '鎼滅储鏂囦欢涓?,
    'File read': '鏂囦欢宸茶鍙?,
    'File written': '鏂囦欢宸插啓鍏?,
    'File created': '鏂囦欢宸插垱寤?,
    'File deleted': '鏂囦欢宸插垹闄?,
    'File edited': '鏂囦欢宸茬紪杈?,
    'Running command': '杩愯鍛戒护涓?,
    'Command executed': '鍛戒护宸叉墽琛?,
    'Searching web': '鎼滅储缃戠粶涓?,
    'Web search': '缃戠粶鎼滅储',
    'Browsing': '娴忚涓?,
    'Navigating': '瀵艰埅涓?,

    // 闀挎弿杩版枃妗堬紙绮剧‘鍖归厤锛屼慨姝ｅ師鐗?"and" 鏈炕璇戠殑 bug锛?
    'Requires manual review for all terminal commands and file accesses outside of the working folders': '瀵瑰伐浣滃尯澶栫殑鎵€鏈夌粓绔懡浠ゅ拰鏂囦欢璁块棶鍧囬渶瑕佹墜鍔ㄥ鏍?,
    'All terminal commands require review. The agent can read or write to any file in the machine': '鎵€鏈夌粓绔懡浠ら兘闇€瑕佸鏍搞€傛櫤鑳戒綋鍙互璇诲彇鎴栧啓鍏ョ郴缁熶腑鐨勪换浣曟枃浠?,
    'Disables all safety barriers for maximal iteration velocity': '绂佺敤鎵€鏈夊畨鍏ㄥ睆闅滀互鎹㈠彇鏈€澶ц凯浠ｉ€熷害',
    'Permanently delete this project and all of its conversations': '姘镐箙鍒犻櫎姝ら」鐩強鍏舵墍鏈夌殑瀵硅瘽璁板綍',
    'Agent settings and permissions for conversations outside of projects': '椤圭洰澶栭儴瀵硅瘽鐨勬櫤鑳戒綋璁剧疆涓庢潈闄?,
    'Choose a predefined security preset for the agent. This controls terminal auto-execution policy, and file access policy': '涓烘櫤鑳戒綋閫夋嫨棰勮鐨勫畨鍏ㄧ骇鍒€傝繖鎺у埗浜嗙粓绔懡浠よ嚜鍔ㄦ墽琛岀瓥鐣ュ拰鏂囦欢璁块棶绛栫暐',
    'Learn more about Turbo mode': '浜嗚В鍏充簬鏋侀€熸ā寮忕殑璇︽儏',
    'Learn more about Turbo Mode': '浜嗚В鍏充簬鏋侀€熸ā寮忕殑璇︽儏',
    "Specifies Agent's behavior when asking for review on artifacts, which are documents it creates to enable a richer conversation experience": '鎸囧畾鏅鸿兘浣撳湪璇锋眰瀹℃牳鍏跺垱寤虹殑浜х墿锛堝嵆涓轰簡鎻愪緵鏇翠赴瀵屽璇濅綋楠岃€岀敓鎴愮殑鏂囨。锛夋椂鐨勫姩浣滆涓?,
    'Inherits from global settings. Local permissions have higher priority. Learn more': '缁ф壙鑷叏灞€璁剧疆銆傚伐浣滃尯鏈湴鏉冮檺鍏锋湁鏇撮珮鐨勪紭鍏堢骇銆備簡瑙ｆ洿澶?,
    'Configure allowed and denied paths for file reads and writes': '閰嶇疆鍏佽鍜屾嫆缁濈殑鏂囦欢璇诲彇鍙婂啓鍏ヨ矾寰?,
    'Configure allowed and denied URLs for reading': '閰嶇疆鍏佽鍜屾嫆缁濊闂殑缃戠粶閾炬帴 (URL)',
    'Configure allowed terminal commands': '閰嶇疆鍏佽鍦ㄧ郴缁熺粓绔墽琛岀殑鍛戒护鐧藉悕鍗?,
    'Configure allowed commands outside the sandbox': '閰嶇疆鍏佽鍦ㄦ矙绠辩幆澧冨閮ㄧ洿鎺ユ墽琛岀殑绯荤粺鍛戒护',
    'Manage project folders, agent settings, and permissions': '绠＄悊褰撳墠宸ヤ綔鍖虹殑椤圭洰鏂囦欢澶广€佹櫤鑳戒綋璁惧畾浠ュ強璁块棶鎺у埗鏉冮檺',
    'Manage application settings': '绠＄悊鏈鎴风搴旂敤绋嬪簭鐨勫叏灞€鍩虹璁剧疆',
    'Prevent the computer from sleeping while the app is running': '闃绘璁＄畻鏈哄湪 Antigravity 搴旂敤杩愯鏈熼棿鑷姩杩涘叆绯荤粺鐫＄湢鐘舵€?,
    'The app will be accessible from the menu bar and will keep running in the background when all windows are closed': '鍏抽棴鎵€鏈夌獥鍙ｅ悗锛屽簲鐢ㄤ粛鍙€氳繃椤堕儴鑿滃崟鏍?绯荤粺鎵樼洏杩涜璁块棶锛屽苟鍦ㄧ郴缁熷悗鍙伴潤榛樿繍琛?,
    "To modify notification settings, open your operating system's system preferences": '鑻ラ渶鑷畾涔変慨鏀瑰簲鐢ㄩ€氱煡璁剧疆锛岃鎵撳紑鎮ㄨ绠楁満鎿嶄綔绯荤粺鐨勭郴缁熼閫夐」杩涜璋冩暣',
    'Configure the browser subagent. It requires Google Chrome to be installed. The browser subagent can be invoked by typing /browser in the conversation input box': '閰嶇疆娴忚鍣ㄥ瓙鏅鸿兘浣撴湇鍔★紙闇€瑕佸畨瑁?Google Chrome 娴忚鍣級銆傚湪鑱婂ぉ绐楀彛涓緭鍏?/browser 鍗冲彲鍙敜娴忚鍣ㄥ姪鎵?,
    'Controls whether the agent can run custom JavaScript to automate complex browser actions': '鎺у埗鏅鸿兘浣撴槸鍚﹀彲浠ラ€氳繃鎵ц鑷畾涔夌殑 JavaScript 鑴氭湰鏉ヨ嚜鍔ㄥ寲澶勭悊澶嶆潅鐨勭綉椤垫祻瑙堟搷浣?,
    'Configure allowed and denied URLs for browser actuation': '閰嶇疆鍏佽鍜屾嫆缁濇祻瑙堝櫒鍔╂墜杩涜妯℃嫙缃戦〉浜や簰鐨勭綉鍧€(URL)瑙勫垯',
    'Configure default behaviors, skills, and MCP servers. Learn more': '缁熶竴閰嶇疆鏅鸿兘浣撶殑榛樿鍔ㄤ綔琛屼负銆佷笓灞炴妧鑳戒互鍙?Model Context Protocol (MCP) 鏈嶅姟鍣ㄣ€傜偣鍑讳簡瑙ｆ洿澶?,
    'The breakdown below shows token usage from customizations like skills, rules, and MCP. If the budget is exceeded, large customizations will be truncated automatically': '涓嬫柟琛ㄦ牸灞曠ず浜嗚嚜瀹氫箟鎶€鑳姐€佽鍒欏簱浠ュ強 MCP 绛夋墿灞曞姛鑳界殑 Token 娑堣€楁槑缁嗐€傝嫢瓒呭嚭闄愰锛岃緝闀跨殑鑷畾涔夊唴瀹逛細琚簳灞傛埅鏂?,
    'No customizations found for this workspace': '褰撳墠宸ヤ綔鍖哄皻鏈彂鐜颁换浣曡嚜瀹氫箟鎶€鑳姐€佽鍒欐垨鏈嶅姟鍣ㄨ缃?,
    "You currently don't have any MCP Servers installed. Add an MCP server above": '鎮ㄥ綋鍓嶅皻鏈儴缃蹭换浣?MCP 鏈嶅姟鍣ㄣ€傝閫氳繃涓婃柟鐨勬寜閽坊鍔犱竴涓?MCP 鏈嶅姟',
    'Configure AI models and view your quota': '鍦ㄦ澶勯厤缃偍涓撳睘鐨?AI 璇█妯″瀷锛屽苟瀹炴椂鏌ヨ鍚勬ā鍨嬬殑閰嶉浣欓噺',
    "When toggled on, Antigravity will use your AI credits to fulfill model requests once you're out of model quota. Antigravity will always use your model quota first before using AI credits": '寮€鍚寮€鍏冲悗锛岃嫢鎮ㄧ殑姣忔棩鍏嶈垂棰濆害鑰楀敖锛孉ntigravity 灏嗕娇鐢ㄦ偍鐨勪粯璐?AI 璐︽埛鐐规暟缁х画澶勭悊璇锋眰銆傜郴缁熶細濮嬬粓浼樺厛娑堣€楁偍鐨勬瘡鏃ュ厤璐归厤棰?,
    "Configure the agent's visual theme and display preferences": '閰嶇疆鏅鸿兘浣撶殑鏁翠綋瑙嗚閰嶈壊涓婚涓庣獥鍙ｆ樉绀哄亸濂?,
    'Display and preserve intermediate thinking steps': '鍦ㄨ亰澶╃晫闈㈠疄鏃舵覆鏌撳苟淇濈暀鏅鸿兘浣撳湪鎵ц浠诲姟鏃剁殑瀹屾暣鎬濊€冭繃绋?(Thinking Steps)',
    'Select light, dark, or inherit system settings': '閫夋嫨鏄庝寒涓婚銆佹繁鑹蹭富棰橈紝鎴栫洿鎺ュ悓姝ユ偍鎿嶄綔绯荤粺鐨勫弻鑹插瑙?,
    'Configure global allowed and denied resource permissions. Learn more': '閰嶇疆绯荤粺鍏ㄥ眬鍏佽鎴栫姝㈢殑纭欢鍙婅蒋浠惰祫婧愯闂潈闄愩€傜偣鍑讳簡瑙ｆ洿澶?,
    'Modify scoped permissions, folders, and agent settings like Sandbox and Terminal Command Execution': '鍏ㄥ眬閰嶇疆鐗瑰畾宸ヤ綔鍖虹殑鐙珛鎺堟潈銆佹寕杞芥枃浠跺す锛屼互鍙婂懡浠ゆ矙绠辨墽琛岀瓑楂橀樁鐜璁惧畾',
    'Configure external tools via Model Context Protocol': '閫氳繃涓氬唴閫氱敤鐨?Model Context Protocol (MCP) 缁熶竴閰嶇疆鍜屾墿灞曞閮ㄨ皟璇曞伐鍏?,
    'Manage your plan, credentials, and general preferences': '渚挎嵎绠＄悊鎮ㄧ殑璐︽埛璁㈤槄璁″垝銆佸畨鍏ㄥ嚟璇佷互鍙婂叏灞€閫氱敤绯荤粺鍋忓ソ',
    'When toggled on, Antigravity collects usage data to help Google enhance performance and features': '寮€鍚閫夐」鍚庯紝Antigravity 灏嗘敹闆嗛儴鍒嗗尶鍚嶄娇鐢ㄦ暟鎹紝浠ュ府鍔?Google 鎸佺画浼樺寲澶фā鍨嬫€ц兘涓庡鎴风浜や簰鍔熻兘',
    'Receive product updates, tips, and promotions from Google Antigravity via email': '鍏佽閫氳繃鐢靛瓙閭瀹氭湡鎺ユ敹鏉ヨ嚜 Google Antigravity 鐨勪骇鍝佽凯浠ｅ姩鎬併€佷娇鐢ㄦ妧宸т互鍙婃椿鍔ㄤ俊鎭?,
    'You can upgrade to a Google AI Ultra plan to receive the highest rate limits': '鎮ㄥ彲浠ラ殢鏃跺崌绾ц嚦 Google AI 鏃楄埌鐗?(Ultra Plan) 浠ヨ幏鍙栨瀬閫熷搷搴斿拰鏃犻檺鍒剁殑閰嶉闄愭祦棰濆害',
    'By using this app, you agree to its Terms of Service': '缁х画浣跨敤鏈鎴风搴旂敤绋嬪簭锛屽嵆浠ｈ〃鎮ㄥ畬鍏ㄧ煡鏅撳苟鍚屾剰鍏剁敤鎴锋湇鍔″崗璁笌闅愮鏉℃',
    'Keyboard shortcuts for quick navigation and control': '浣跨敤绮惧績璁捐鐨勯敭鐩樺揩鎹烽敭鏉ュ揩閫熷鑸€佸垏鎹㈢獥鍙ｅ苟鎺у埗鏅鸿兘浣撶殑楂橀鎿嶄綔',
    'By using this app, you agree to its': '缁х画浣跨敤鏈鎴风搴旂敤绋嬪簭锛屽嵆浠ｈ〃鎮ㄥ悓鎰忓叾',
    'Your Plan: Google AI Pro': '璁㈤槄璁″垝锛欸oogle AI 涓撲笟鐗?,
    'Your Plan: Google AI Ultra': '璁㈤槄璁″垝锛欸oogle AI 鏃楄埌鐗?,
    'Configure global allowed and denied resource permissions.': '閰嶇疆鍏ㄥ眬鍏佽鍜屾嫆缁濈殑璧勬簮鏉冮檺銆?,
    'Configure default behaviors, skills, and MCP servers.': '閰嶇疆榛樿琛屼负銆佹妧鑳藉拰 MCP 鏈嶅姟銆?,
    'Configure the browser subagent. It requires': '閰嶇疆娴忚鍣ㄥ瓙鏅鸿兘浣撱€傝繍琛屾鍔熻兘闇€瑕佸畨瑁?,
    'to be installed. The browser subagent can be invoked by typing /browser in the conversation input box.': '銆傛偍鍙互鍦ㄨ緭鍏ユ涓緭鍏?/browser 鏉ュ彫鍞ゆ祻瑙堝櫒鍔╂墜銆?,
    'to be installed. The browser subagent can be invoked by typing': '銆傛偍鍙互鍦ㄨ緭鍏ユ涓緭鍏?',
    'in the conversation input box.': ' 鏉ュ彫鍞ゆ祻瑙堝櫒鍔╂墜銆?,
    'Are you sure you want to quit?': '鎮ㄧ‘瀹氳閫€鍑哄悧锛?,
    'There may be agents or background tasks running.': '鍙兘鏈夋櫤鑳戒綋鎴栧悗鍙颁换鍔℃鍦ㄨ繍琛屻€?,
    'Quit': '閫€鍑?,
    'View your available model quota and AI credits. Model quota refreshes periodically based on your plan. Enable AI Credit Overages to continue using models when your quota is exhausted.': '鏌ョ湅鎮ㄥ彲鐢ㄧ殑妯″瀷閰嶉鍜?AI 鐐规暟銆傛ā鍨嬮厤棰濅細鏍规嵁鎮ㄧ殑璁㈤槄璁″垝瀹氭湡閲嶇疆銆傚紑鍚厑璁歌秴鍑洪搴﹀悗鎵ｉ櫎鐐规暟锛屽彲鍦ㄩ厤棰濊€楀敖鍚庣户缁娇鐢ㄦā鍨嬨€?,
    'Schedule timer: Timer has expired': '璋冨害瀹氭椂鍣細瀹氭椂鍣ㄥ凡杩囨湡',
  }));

  // ============================================================
  //  搂2  棰勭紪璇戞鍒欐ā寮?(鍔ㄦ€佺姸鎬?& 鏁板瓧妯℃澘)
  // ============================================================
  const dynamicPatterns = [
    // See all (12)
    { re: /^See all \((\d+)\)$/, fn: (m) => `鏌ョ湅鍏ㄩ儴 (${m[1]})` },
    // Refreshes in N hours, M minutes
    {
      re: /^Refreshes in (.+)$/,
      fn: (m) => {
        let t = m[1];
        t = t.replace(/\bhours?\b/g, '灏忔椂').replace(/\bminutes?\b/g, '鍒嗛挓').replace(/,\s*/g, ' ');
        return `棰濆害閲嶇疆鍊掕鏃讹細${t}`;
      },
    },
    // Your Plan: ...
    {
      re: /^Your Plan: (.+)$/,
      fn: (m) => {
        const plan = m[1].replace('Google AI Pro', 'Google AI 涓撲笟鐗?).replace('Google AI Ultra', 'Google AI 鏃楄埌鐗?);
        return `璁㈤槄璁″垝锛?{plan}`;
      },
    },
    // Available AI Credits: $X.XX
    { re: /^Available AI Credits: (.+)$/, fn: (m) => `鍙敤 AI 鐐规暟浣欓: ${m[1]}` },
    // Token budget
    { re: /^(.+) of the customization budget is available\.$/, fn: (m) => `${m[1]} 鐨勮嚜瀹氫箟 Token 棰勭畻褰撳墠鍙敤銆俙 },
    // Version X.Y.Z
    { re: /^Version (.+)$/, fn: (m) => `鐗堟湰 ${m[1]}` },
    // Send feedback as <email>
    { re: /^Send feedback as (.+)$/, fn: (m) => `浠?${m[1]} 鐨勮韩浠藉彂閫佸弽棣坄 },
    // Explored N files / tasks
    { re: /^Explored (\d+) (files?|tasks?)$/i, fn: (m) => `宸叉帰绱?${m[1]} 涓?{m[2].startsWith('f') ? '鏂囦欢' : '浠诲姟'}` },
    // Edited N files
    { re: /^Edited (\d+) files?$/i, fn: (m) => `宸茬紪杈?${m[1]} 涓枃浠禶 },
    // Timed N seconds
    { re: /^Timed (\d+) seconds?$/i, fn: (m) => `宸茶鏃?${m[1]} 绉抈 },
    // Thinking for Ns
    {
      re: /^Thinking for (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `鎬濊€冧腑 (${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '姣' : '绉?})`,
    },
    // Working for Ns
    {
      re: /^Working for (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `澶勭悊涓?(${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '姣' : '绉?})`,
    },
    // Completed/Finished/Done in Ns
    {
      re: /^(?:Completed|Finished|Done) in (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `宸插畬鎴?(鑰楁椂 ${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '姣' : '绉?})`,
    },
    // Generated image in Ns
    {
      re: /^Generated image in (\d+(?:\.\d+)?)\s*(s|seconds?|ms)?$/i,
      fn: (m) => `宸茬敓鎴愬浘鐗?(鑰楁椂 ${m[1]}${m[2] && m[2].toLowerCase().startsWith('ms') ? '姣' : '绉?})`,
    },
    // You have used some of your weekly limit, it will fully refresh in ...
    {
      re: /^You have used some of your weekly limit, it will fully refresh in (.+)\.$/i,
      fn: (m) => {
        let t = m[1].replace(/\bdays?\b/g, '澶?).replace(/\bhours?\b/g, '灏忔椂').replace(/\bminutes?\b/g, '鍒嗛挓').replace(/,\s*/g, ' ');
        return `鎮ㄥ凡娑堣€椾簡閮ㄥ垎姣忓懆闄愰锛屽皢鍦?${t} 鍚庡畬鍏ㄩ噸缃€俙;
      },
    },
    // You have used some of your 5-hour limit, it will fully refresh in ...
    {
      re: /^You have used some of your 5-hour limit, it will fully refresh in (.+)\.$/i,
      fn: (m) => {
        let t = m[1].replace(/\bhours?\b/g, '灏忔椂').replace(/\bminutes?\b/g, '鍒嗛挓').replace(/,\s*/g, ' ');
        return `鎮ㄥ凡娑堣€椾簡閮ㄥ垎 5 灏忔椂闄愰锛屽皢鍦?${t} 鍚庡畬鍏ㄩ噸缃€俙;
      },
    },
    // Bulletproof match for browser subagent description
    {
      re: /^\s*to be installed\. The browser subagent can be invoked by typing\s*\/browser\s*in the conversation input box\s*\.?\s*$/i,
      fn: () => '銆傛偍鍙互鍦ㄨ緭鍏ユ涓緭鍏?/browser 鏉ュ彫鍞ゆ祻瑙堝櫒鍔╂墜銆?
    },
    // Confirm Quit Modal
    {
      re: /^\s*Are you sure you want to quit\s*\??\s*$/i,
      fn: () => '鎮ㄧ‘瀹氳閫€鍑哄悧锛?
    },
    {
      re: /^\s*There may be agents or background tasks running\s*\.?\s*$/i,
      fn: () => '鍙兘鏈夋櫤鑳戒綋鎴栧悗鍙颁换鍔℃鍦ㄨ繍琛屻€?
    },
    {
      re: /^\s*Quit\s*$/i,
      fn: () => '閫€鍑?
    },
    {
      re: /^\s*Cancel\s*$/i,
      fn: () => '鍙栨秷'
    },
    // Thinking for N seconds
    {
      re: /^Thought for (\d+(?:\.\d+)?)\s*(s|sec(?:onds?)?)?$/i,
      fn: (m) => `鎬濊€冪敤鏃?${m[1]} 绉抈,
    },
    {
      re: /^Thought for (\d+(?:\.\d+)?)\s*ms$/i,
      fn: (m) => `鎬濊€冪敤鏃?${m[1]} 姣`,
    },
    // Show/Hide thinking (N s)
    {
      re: /^(Show|Hide|View)\s+[Tt]hinking(?:\s*\(([^)]+)\))?$/,
      fn: (m) => {
        const action = m[1].toLowerCase() === 'hide' ? '鏀惰捣' : '灞曞紑';
        const time = m[2] ? ` (${m[2]})` : '';
        return `${action}鎬濊€冭繃绋?{time}`;
      },
    },
    // Thinking (N s)
    {
      re: /^[Tt]hinking\s*\((\d+(?:\.\d+)?)\s*(s|sec(?:onds?)?|ms)?\)$/,
      fn: (m) => {
        const unit = m[2] && m[2].toLowerCase().startsWith('ms') ? '姣' : '绉?;
        return `鎬濊€冧腑 (${m[1]} ${unit})`;
      },
    },
    // Step N of M
    {
      re: /^Step (\d+) of (\d+)$/i,
      fn: (m) => `姝ラ ${m[1]} / ${m[2]}`,
    },
    // Ran N tool calls
    {
      re: /^Ran (\d+) tool calls?$/i,
      fn: (m) => `宸叉墽琛?${m[1]} 娆″伐鍏疯皟鐢╜,
    },
    // Used N tokens
    {
      re: /^Used (\d+(?:,\d+)?) tokens?$/i,
      fn: (m) => `宸叉秷鑰?${m[1]} 涓?Token`,
    },
    // N tokens used
    {
      re: /^(\d+(?:,\d+)?) tokens? used$/i,
      fn: (m) => `宸叉秷鑰?${m[1]} 涓?Token`,
    },
  ];

  // ============================================================
  //  搂3  鏍囩偣鏄犲皠
  // ============================================================
  const punctuationMap = { '.': '銆?, ':': '锛?, '?': '锛?, '!': '锛?, ',': '锛? };

  // ============================================================
  //  搂4  鏍稿績缈昏瘧鍑芥暟
  // ============================================================
  function translateText(text) {
    if (!text) return null;

    // 鏍囧噯鍖栦笉鎹㈣绌烘牸 (React 缁勪欢涓?\u00a0 甯歌)
    const normalized = text.replaceAll('\u00a0', ' ');
    const trimmed = normalized.trim();
    if (!trimmed) return null;

    // 璺宠繃宸茬粡鏄函涓枃 / 鍚腑鏂囧瓧绗︾殑鏂囨湰锛堥伩鍏嶄簩娆＄炕璇戯級
    if (/^[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef\s\d()锛堬級/\-:锛?銆?锛?锛?锛焆+$/.test(trimmed)) return null;

    // 1. 瀛楀吀绮剧‘鍖归厤
    const exact = dictionary.get(trimmed);
    if (exact) return normalized.replace(trimmed, exact);

    // 2. 鍘诲熬鏍囩偣鍚庡尮閰?
    const lastChar = trimmed[trimmed.length - 1];
    if (punctuationMap[lastChar]) {
      const core = trimmed.slice(0, -1).trim();
      const coreMatch = dictionary.get(core);
      if (coreMatch) return normalized.replace(trimmed, coreMatch + punctuationMap[lastChar]);
    }

    // 3. 鍔ㄦ€佹鍒欐ā寮忓尮閰?
    for (const { re, fn } of dynamicPatterns) {
      const m = trimmed.match(re);
      if (m) return normalized.replace(trimmed, fn(m));
    }

    return null;
  }

  // ============================================================
  //  搂5  浠ｇ爜鍖哄煙闅旂 鈥?缁濅笉缈昏瘧浠ｇ爜
  // ============================================================
  const CODE_TAGS = new Set(['PRE', 'CODE', 'TEXTAREA', 'SCRIPT', 'STYLE', 'NOSCRIPT']);
  const CODE_CLASS_FRAGMENTS = [
    'monaco-editor', 'view-lines', 'view-line',
    'CodeMirror', 'cm-editor', 'cm-content',
    'hljs', 'prism-code', 'shiki',
    'code-block', 'codeblock', 'code-container',
    'markdown-code', 'language-',
  ];

  /**
   * 鍒ゆ柇涓€涓妭鐐规槸鍚︿綅浜庝唬鐮佸睍绀哄尯鍩熷唴銆?
   * 鍚戜笂鏌ユ壘绁栧厛鍏冪礌锛屽鏋滈亣鍒?<pre>/<code>/<textarea> 鎴?
   * 鍚湁缂栬緫鍣?浠ｇ爜楂樹寒绫诲悕鐨勫鍣紝鍒欒涓鸿鑺傜偣浣嶄簬浠ｇ爜鍖哄煙銆?
   */
  function isInsideCodeRegion(node) {
    let current = node.nodeType === 1 ? node : node.parentElement;
    // 鏈€澶氬悜涓婃煡鎵?20 灞傦紝閬垮厤鏋佺娣卞眰 DOM 鐨勬€ц兘闂
    let depth = 0;
    while (current && depth < 20) {
      if (CODE_TAGS.has(current.tagName)) return true;
      if (current.className && typeof current.className === 'string') {
        const cls = current.className;
        for (const frag of CODE_CLASS_FRAGMENTS) {
          if (cls.includes(frag)) return true;
        }
      }
      // 妫€鏌?contenteditable锛圡onaco Editor 浣跨敤锛?
      if (current.getAttribute && current.getAttribute('role') === 'code') return true;
      current = current.parentElement;
      depth++;
    }
    return false;
  }

  // ============================================================
  //  搂6  DOM 閬嶅巻缈昏瘧
  // ============================================================
  function walk(node) {
    if (!node) return;

    if (node.nodeType === 3) {
      // TEXT_NODE
      if (isInsideCodeRegion(node)) return;
      const translated = translateText(node.nodeValue);
      if (translated !== null) node.nodeValue = translated;
    } else if (node.nodeType === 1) {
      // ELEMENT_NODE 鈥?瀵逛簬宸茬煡鐨勪唬鐮佸鍣紝鐩存帴璺宠繃鏁存５瀛愭爲
      if (CODE_TAGS.has(node.tagName)) return;
      if (node.className && typeof node.className === 'string') {
        for (const frag of CODE_CLASS_FRAGMENTS) {
          if (node.className.includes(frag)) return;
        }
      }

      // placeholder 缈昏瘧
      if (node.placeholder) {
        const translated = translateText(node.placeholder);
        if (translated !== null) node.placeholder = translated;
      }
      // input[type=button|submit] value 缈昏瘧
      if (node.tagName === 'INPUT' && (node.type === 'button' || node.type === 'submit')) {
        const translated = translateText(node.value);
        if (translated !== null) node.value = translated;
      }
      // title 灞炴€х炕璇?
      if (node.title) {
        const translated = translateText(node.title);
        if (translated !== null) node.title = translated;
      }
      // aria-label 缈昏瘧
      if (node.getAttribute && node.getAttribute('aria-label')) {
        const ariaLabel = node.getAttribute('aria-label');
        const translated = translateText(ariaLabel);
        if (translated !== null) node.setAttribute('aria-label', translated);
      }

      // Shadow DOM 绌块€?
      if (node.shadowRoot) walk(node.shadowRoot);
      for (let child = node.firstChild; child; child = child.nextSibling) {
        walk(child);
      }
    } else if (node.nodeType === 11) {
      // DOCUMENT_FRAGMENT_NODE (ShadowRoot)
      for (let child = node.firstChild; child; child = child.nextSibling) {
        walk(child);
      }
    }
  }

  // ============================================================
  //  搂7  MutationObserver 鈥?requestAnimationFrame 鑺傛祦
  // ============================================================
  let pendingMutations = [];
  let rafScheduled = false;

  function processPendingMutations() {
    const mutations = pendingMutations;
    pendingMutations = [];
    rafScheduled = false;

    // 鏆傛椂鏂紑 observer锛岄伩鍏嶇炕璇戞搷浣滆Е鍙戜簩娆＄洃鍚?
    observer.disconnect();

    for (const mutation of mutations) {
      if (mutation.type === 'childList') {
        for (const addedNode of mutation.addedNodes) {
          walk(addedNode);
        }
      } else if (mutation.type === 'characterData') {
        if (!isInsideCodeRegion(mutation.target)) {
          const translated = translateText(mutation.target.nodeValue);
          if (translated !== null) mutation.target.nodeValue = translated;
        }
      } else if (mutation.type === 'attributes') {
        const target = mutation.target;
        if (isInsideCodeRegion(target)) continue;
        if (mutation.attributeName === 'placeholder' && target.placeholder) {
          const translated = translateText(target.placeholder);
          if (translated !== null) target.placeholder = translated;
        }
        if (mutation.attributeName === 'value' && target.tagName === 'INPUT') {
          const translated = translateText(target.value);
          if (translated !== null) target.value = translated;
        }
      }
    }

    startObserver();
  }

  const observer = new MutationObserver((mutations) => {
    pendingMutations.push(...mutations);
    if (!rafScheduled) {
      rafScheduled = true;
      requestAnimationFrame(processPendingMutations);
    }
  });

  function startObserver() {
    observer.observe(document.documentElement, {
      childList: true,
      subtree: true,
      characterData: true,
      attributes: true,
      attributeFilter: ['placeholder', 'value'],
    });
  }

  // ============================================================
  //  搂8  document.title 鎷︽埅
  // ============================================================
  try {
    const originalTitleDescriptor = Object.getOwnPropertyDescriptor(Document.prototype, 'title');
    if (originalTitleDescriptor && originalTitleDescriptor.set) {
      Object.defineProperty(document, 'title', {
        get() {
          return originalTitleDescriptor.get.call(this);
        },
        set(val) {
          if (!val) {
            originalTitleDescriptor.set.call(this, val);
            return;
          }
          const trimmed = val.trim();
          let translated = val;
          const exact = dictionary.get(trimmed);
          if (exact) {
            translated = val.replace(trimmed, exact);
          } else if (trimmed.includes(' - Antigravity')) {
            const part = trimmed.replace(' - Antigravity', '').trim();
            const partMatch = dictionary.get(part);
            if (partMatch) translated = `${partMatch} - Antigravity`;
          }
          originalTitleDescriptor.set.call(this, translated);
        },
      });
    }
  } catch (e) {
    console.error('[CN Patch] Failed to hook document.title:', e);
  }

  // ============================================================
  //  搂8.5  瀹氭椂鍏ㄩ噺鎵弿 鈥?搴斿鎳掑姞杞?/ Shadow DOM 婕忚瘧
  //  姣?500 ms 鎵弿涓€娆?body锛屽苟棰濆缈昏瘧 data-* 灞炴€?
  // ============================================================
  function translateDataAttributes(root) {
    try {
      // 缈昏瘧甯︽湁璇箟鏂囨湰鐨?data-* 灞炴€э紙濡?data-tooltip銆乨ata-label 绛夛級
      const selectors = [
        '[data-tooltip]', '[data-label]', '[data-title]',
        '[data-placeholder]', '[data-content]', '[data-text]',
        '[aria-description]', '[aria-placeholder]',
      ];
      const elements = (root || document).querySelectorAll(selectors.join(','));
      elements.forEach(el => {
        ['data-tooltip','data-label','data-title','data-placeholder','data-content','data-text'].forEach(attr => {
          const val = el.getAttribute(attr);
          if (val) {
            const t = translateText(val);
            if (t !== null) el.setAttribute(attr, t);
          }
        });
        const ariaDesc = el.getAttribute('aria-description');
        if (ariaDesc) {
          const t = translateText(ariaDesc);
          if (t !== null) el.setAttribute('aria-description', t);
        }
        const ariaPlaceholder = el.getAttribute('aria-placeholder');
        if (ariaPlaceholder) {
          const t = translateText(ariaPlaceholder);
          if (t !== null) el.setAttribute('aria-placeholder', t);
        }
      });
    } catch (e) { /* ignore */ }
  }

  let scanCount = 0;
  const MAX_FAST_SCANS = 60; // 鍓?0绉掓瘡500ms涓€娆★紝涔嬪悗闄嶉€?
  function schedulePeriodicScan() {
    const interval = scanCount < MAX_FAST_SCANS ? 500 : 3000;
    setTimeout(() => {
      try {
        observer.disconnect();
        if (document.body) {
          walk(document.body);
          translateDataAttributes(document);
        }
        // 绌块€忔墍鏈?Shadow DOM
        document.querySelectorAll('*').forEach(el => {
          if (el.shadowRoot) {
            walk(el.shadowRoot);
            translateDataAttributes(el.shadowRoot);
          }
        });
        startObserver();
      } catch (e) { /* ignore */ }
      scanCount++;
      schedulePeriodicScan();
    }, interval);
  }

  schedulePeriodicScan();

  // ============================================================
  //  搂9  浜戠瀛楀吀鐑洿鏂帮紙localStorage 缂撳瓨 + GitHub 寮傛鎷夊彇锛?
  // ============================================================
  try {
    const cached = localStorage.getItem('antigravity_chinese_patch_dict');
    if (cached) {
      const data = JSON.parse(cached);
      for (const [k, v] of Object.entries(data)) {
        dictionary.set(k, v);
      }
    }
  } catch (e) {
    console.error('[CN Patch] Failed to load cached cloud dictionary:', e);
  }

  fetch('https://raw.githubusercontent.com/good9527/Antigravity-Chinese-Patch/main/dist/dictionary.json')
    .then((res) => {
      if (res.ok) return res.json();
      throw new Error('Network response was not ok');
    })
    .then((data) => {
      if (data && typeof data === 'object') {
        localStorage.setItem('antigravity_chinese_patch_dict', JSON.stringify(data));
        for (const [k, v] of Object.entries(data)) {
          dictionary.set(k, v);
        }
        console.log('[CN Patch] Cloud dictionary updated. Total keys:', dictionary.size);
        // 绔嬪嵆鍒锋柊缈昏瘧
        if (document.body) walk(document.body);
      }
    })
    .catch((err) => {
      console.warn('[CN Patch] Cloud update unavailable, using local dictionary.', err);
    });

  // ============================================================
  //  搂10  鍚姩鍏ュ彛
  // ============================================================
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      walk(document.body);
      startObserver();
    });
  } else {
    walk(document.body);
    startObserver();
  }

  console.log('[CN Patch] Antigravity 涓枃姹夊寲琛ヤ竵宸插姞杞?(macOS 浼樺寲鐗?');
})();

'@

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

