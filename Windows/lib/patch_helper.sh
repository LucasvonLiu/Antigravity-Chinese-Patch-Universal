#!/bin/bash
# ============================================================
#  Antigravity 汉化补丁 — 非交互式核心逻辑
#  供 AppleScript .app 和 install.sh 共同调用
#  用法: patch_helper.sh install|restore|status <patch_js_path>
# ============================================================
set -euo pipefail
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

ACTION="${1:-}"
PATCH_JS="${2:-}"

APP_PATH="/Applications/Antigravity.app"
RESOURCES_DIR="$APP_PATH/Contents/Resources"
ASAR="$RESOURCES_DIR/app.asar"
PRELOAD_BAK="$RESOURCES_DIR/preload.js.original.bak"
MARKER="Antigravity Chinese Localization Patch"

# ── 前置检查 ──────────────────────────────────────────────
preflight() {
  if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR:未找到 Antigravity.app，请确认已安装至 /Applications 目录。"
    exit 1
  fi
  if [[ ! -f "$ASAR" ]]; then
    echo "ERROR:未找到 app.asar 文件。"
    exit 1
  fi
  if ! command -v npx &>/dev/null; then
    echo "ERROR:未检测到 Node.js / npx 环境。请先安装 Node.js (https://nodejs.org)。"
    exit 1
  fi
}

# ── 关闭客户端 ────────────────────────────────────────────
quit_client() {
  if pgrep -xq "Antigravity" 2>/dev/null; then
    pkill -x "Antigravity" 2>/dev/null || true
    sleep 2
  fi
}

# ── 安装/更新 ─────────────────────────────────────────────
do_install() {
  if [[ -z "$PATCH_JS" || ! -f "$PATCH_JS" ]]; then
    echo "ERROR:未找到补丁文件：$PATCH_JS"
    exit 1
  fi

  preflight
  quit_client

  local temp_dir
  temp_dir=$(mktemp -d /tmp/agyp.XXXXXX)
  trap "rm -rf '$temp_dir'" EXIT

  echo "PROGRESS:正在解包 app.asar..."
  npx --yes @electron/asar extract "$ASAR" "$temp_dir/ex" 2>/dev/null

  local target="$temp_dir/ex/dist/preload.js"
  if [[ ! -f "$target" ]]; then
    echo "ERROR:解包后未找到 dist/preload.js。"
    exit 1
  fi

  # 智能备份 / 还原
  if grep -q "$MARKER" "$target" 2>/dev/null; then
    echo "PROGRESS:检测到已汉化，正在从备份还原..."
    if [[ -f "$PRELOAD_BAK" ]]; then
      cp "$PRELOAD_BAK" "$target"
    fi
  else
    echo "PROGRESS:备份原始 preload.js..."
    cp "$target" "$PRELOAD_BAK"
  fi

  echo "PROGRESS:正在注入汉化代码..."
  local patch_code
  patch_code=$(sed -n "/$MARKER/,\$p" "$PATCH_JS")
  if [[ -z "$patch_code" ]]; then
    patch_code=$(cat "$PATCH_JS")
  fi
  printf '\n\n%s' "$patch_code" >> "$target"

  echo "PROGRESS:正在重新打包 app.asar..."
  npx --yes @electron/asar pack "$temp_dir/ex" "$ASAR" --unpack-dir "node_modules" 2>/dev/null

  echo "PROGRESS:正在启动客户端..."
  open -a "$APP_PATH" &

  echo "SUCCESS:汉化补丁安装成功！"
}

# ── 卸载还原 ──────────────────────────────────────────────
do_restore() {
  if [[ ! -f "$PRELOAD_BAK" ]]; then
    echo "ERROR:未找到原始备份文件，无法还原。如从未安装过汉化补丁则无需还原。"
    exit 1
  fi

  preflight
  quit_client

  local temp_dir
  temp_dir=$(mktemp -d /tmp/agyp.XXXXXX)
  trap "rm -rf '$temp_dir'" EXIT

  echo "PROGRESS:正在解包 app.asar..."
  npx --yes @electron/asar extract "$ASAR" "$temp_dir/ex" 2>/dev/null

  echo "PROGRESS:正在还原原始 preload.js..."
  cp "$PRELOAD_BAK" "$temp_dir/ex/dist/preload.js"

  echo "PROGRESS:正在重新打包 app.asar..."
  npx --yes @electron/asar pack "$temp_dir/ex" "$ASAR" --unpack-dir "node_modules" 2>/dev/null

  echo "PROGRESS:正在启动客户端..."
  open -a "$APP_PATH" &

  echo "SUCCESS:已成功还原为官方原版客户端。"
}

# ── 状态检查 ──────────────────────────────────────────────
do_status() {
  local info=""

  # 安装状态
  if [[ -d "$APP_PATH" ]]; then
    info+="✅ 客户端已安装\n"
  else
    echo "STATUS:❌ 客户端未安装"
    return
  fi

  # 版本 & 汉化状态
  if command -v npx &>/dev/null && [[ -f "$ASAR" ]]; then
    local temp_dir
    temp_dir=$(mktemp -d /tmp/agyp.XXXXXX)
    if npx --yes @electron/asar extract "$ASAR" "$temp_dir/ex" 2>/dev/null; then
      # 版本号
      local pkg="$temp_dir/ex/package.json"
      if [[ -f "$pkg" ]]; then
        local ver
        ver=$(grep -o '"version": *"[^"]*"' "$pkg" 2>/dev/null | head -1 | cut -d'"' -f4 || true)
        if [[ -n "$ver" ]]; then
          info+="📦 客户端版本: $ver\n"
        fi
      fi
      # 汉化状态
      local preload="$temp_dir/ex/dist/preload.js"
      if [[ -f "$preload" ]] && grep -q "$MARKER" "$preload" 2>/dev/null; then
        info+="🟢 汉化状态: 已汉化\n"
      else
        info+="⚪ 汉化状态: 未汉化 (官方原版)\n"
      fi
    fi
    rm -rf "$temp_dir"
  fi

  # 备份状态
  if [[ -f "$PRELOAD_BAK" ]]; then
    info+="✅ 原版备份: 存在\n"
  else
    info+="⚪ 原版备份: 不存在\n"
  fi

  # Node.js
  if command -v npx &>/dev/null; then
    local nv
    nv=$(node --version 2>/dev/null || echo "未知")
    info+="✅ Node.js: $nv"
  else
    info+="❌ Node.js: 未安装"
  fi

  echo -e "STATUS:$info"
}

# ── 入口 ──────────────────────────────────────────────────
case "$ACTION" in
  install)  do_install ;;
  restore)  do_restore ;;
  status)   do_status ;;
  *)
    echo "ERROR:未知操作: $ACTION"
    echo "用法: $0 install|restore|status [patch_js_path]"
    exit 1
    ;;
esac
