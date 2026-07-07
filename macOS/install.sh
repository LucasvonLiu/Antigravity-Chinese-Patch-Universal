#!/bin/bash
# ============================================================
#  Antigravity 中文汉化补丁 — macOS 安装脚本
#  功能：安装/更新汉化 | 卸载还原 | 状态检查
# ============================================================
set -euo pipefail

# ── 颜色定义 ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── 路径定义 ──────────────────────────────────────────────
APP_PATH="/Applications/Antigravity.app"
RESOURCES_DIR="$APP_PATH/Contents/Resources"
ORIGINAL_ASAR="$RESOURCES_DIR/app.asar"
BACKUP_ASAR="$RESOURCES_DIR/app.asar.bak"
PATCH_MARKER="Antigravity Chinese Localization Patch"

# 脚本所在目录 (支持 symlink)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_PATCH_JS="$SCRIPT_DIR/macOS汉化工具.app/Contents/Resources/dist/preload_patch.js"

# 临时工作目录
TEMP_DIR="$(mktemp -d /tmp/antigravity_patch.XXXXXX)"

# ── 清理函数 ──────────────────────────────────────────────
cleanup() {
  rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# ── 工具函数 ──────────────────────────────────────────────
info()    { echo -e "${CYAN}[信息]${RESET} $1"; }
success() { echo -e "${GREEN}[完成]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[警告]${RESET} $1"; }
error()   { echo -e "${RED}[错误]${RESET} $1"; }

check_prerequisites() {
  # 检查 Antigravity 是否已安装
  if [[ ! -d "$APP_PATH" ]]; then
    error "未找到 Antigravity.app，请确认已安装至 /Applications 目录。"
    exit 1
  fi
  if [[ ! -f "$ORIGINAL_ASAR" ]]; then
    error "未找到 app.asar 文件：$ORIGINAL_ASAR"
    exit 1
  fi

  # 检查 Node.js / npx 环境
  if ! command -v npx &>/dev/null; then
    error "未检测到 Node.js / npx 环境。"
    echo -e "  请先安装 Node.js：${BOLD}https://nodejs.org${RESET}"
    echo -e "  或使用 Homebrew：${BOLD}brew install node${RESET}"
    exit 1
  fi

  # 检查补丁脚本
  if [[ ! -f "$LOCAL_PATCH_JS" ]]; then
    error "未找到本地补丁脚本：$LOCAL_PATCH_JS"
    echo -e "  请确认 dist/preload_patch.js 文件存在。"
    exit 1
  fi
}

# 检查当前 asar 是否已被汉化
is_patched() {
  local asar_path="$1"
  local check_dir="$TEMP_DIR/check_extract"
  rm -rf "$check_dir" 2>/dev/null || true

  if npx --yes @electron/asar extract "$asar_path" "$check_dir" 2>/dev/null; then
    local preload="$check_dir/dist/preload.js"
    if [[ -f "$preload" ]] && grep -q "$PATCH_MARKER" "$preload" 2>/dev/null; then
      rm -rf "$check_dir"
      return 0
    fi
  fi
  rm -rf "$check_dir" 2>/dev/null || true
  return 1
}

# 关闭 Antigravity 客户端
stop_client() {
  if pgrep -xq "Antigravity"; then
    info "正在关闭 Antigravity 客户端..."
    pkill -x "Antigravity" 2>/dev/null || true
    sleep 2
  fi
}

# 启动 Antigravity 客户端
start_client() {
  if [[ -d "$APP_PATH" ]]; then
    info "正在重新启动 Antigravity 客户端..."
    open -a "$APP_PATH" &
  else
    warn "无法自动启动客户端，请手动打开 Antigravity。"
  fi
}

# ── 功能 1：安装/更新汉化 ────────────────────────────────
apply_patch() {
  echo ""
  echo -e "${CYAN}════════════════════════════════════════════${RESET}"
  echo -e "${CYAN}     正在安装/更新中文汉化补丁${RESET}"
  echo -e "${CYAN}════════════════════════════════════════════${RESET}"
  echo ""

  check_prerequisites
  stop_client

  # 动态注入 —— 始终从当前 app.asar 解包
  # 注意：app.asar 引用了同级的 app.asar.unpacked 目录，
  # 因此只能对当前位置的 asar 执行解包，不能对备份副本操作。
  local extract_dir="$TEMP_DIR/asar_extracted"

  info "正在解包 app.asar..."
  npx --yes @electron/asar extract "$ORIGINAL_ASAR" "$extract_dir"

  local target_preload="$extract_dir/dist/preload.js"
  if [[ ! -f "$target_preload" ]]; then
    error "解包后未找到 dist/preload.js，asar 文件结构可能已变更。"
    return 1
  fi

  # 智能备份管理（仅备份 preload.js 原始文件，避免 asar.unpacked 引用断裂）
  local preload_backup="$RESOURCES_DIR/preload.js.original.bak"
  if grep -q "$PATCH_MARKER" "$target_preload" 2>/dev/null; then
    info "检测到已汉化的客户端。"
    if [[ -f "$preload_backup" ]]; then
      info "正在从备份还原原始 preload.js 后重新注入..."
      cp "$preload_backup" "$target_preload"
    else
      warn "无原始备份，将在已汉化的 preload.js 上重新注入。"
    fi
  else
    info "检测到未汉化的客户端，正在备份原始 preload.js..."
    cp "$target_preload" "$preload_backup"
    success "备份完成 → $preload_backup"
  fi

  info "正在注入汉化代码..."
  # 读取补丁代码中 marker 之后的内容
  local patch_code
  patch_code=$(sed -n "/$PATCH_MARKER/,\$p" "$LOCAL_PATCH_JS")

  if [[ -z "$patch_code" ]]; then
    warn "未找到补丁标记，将追加整个补丁文件。"
    patch_code=$(cat "$LOCAL_PATCH_JS")
  fi

  # 追加到原始 preload.js 末尾
  printf '\n\n%s' "$patch_code" >> "$target_preload"
  success "汉化代码注入完成。"

  info "正在重新打包 app.asar..."
  npx --yes @electron/asar pack "$extract_dir" "$ORIGINAL_ASAR" --unpack-dir "node_modules"
  success "打包完成。"

  start_client

  echo ""
  success "🎉 汉化补丁安装成功！请查看已重新启动的 Antigravity 客户端。"
}

# ── 功能 2：卸载还原 ──────────────────────────────────────
restore_backup() {
  echo ""
  echo -e "${YELLOW}════════════════════════════════════════════${RESET}"
  echo -e "${YELLOW}     正在还原官方原版客户端${RESET}"
  echo -e "${YELLOW}════════════════════════════════════════════${RESET}"
  echo ""

  local preload_backup="$RESOURCES_DIR/preload.js.original.bak"

  if [[ ! -f "$preload_backup" ]]; then
    error "未找到原始 preload.js 备份文件，无法还原。"
    echo "  如果从未安装过汉化补丁，则不需要还原。"
    return 1
  fi

  check_prerequisites
  stop_client

  local extract_dir="$TEMP_DIR/asar_restore"

  info "正在解包当前 app.asar..."
  npx --yes @electron/asar extract "$ORIGINAL_ASAR" "$extract_dir"

  info "正在还原原始 preload.js..."
  cp "$preload_backup" "$extract_dir/dist/preload.js"

  info "正在重新打包 app.asar..."
  npx --yes @electron/asar pack "$extract_dir" "$ORIGINAL_ASAR" --unpack-dir "node_modules"
  success "还原完成。"

  start_client

  echo ""
  success "✅ 已成功还原为官方原版客户端。"
}

# ── 功能 3：检查状态 ──────────────────────────────────────
check_status() {
  echo ""
  echo -e "${BLUE}════════════════════════════════════════════${RESET}"
  echo -e "${BLUE}     Antigravity 客户端状态检查${RESET}"
  echo -e "${BLUE}════════════════════════════════════════════${RESET}"
  echo ""

  # 安装检查
  if [[ -d "$APP_PATH" ]]; then
    success "客户端安装路径: $APP_PATH"
  else
    error "客户端未安装"
    return
  fi

  # app.asar 文件信息
  if [[ -f "$ORIGINAL_ASAR" ]]; then
    local size
    size=$(stat -f%z "$ORIGINAL_ASAR" 2>/dev/null || stat -c%s "$ORIGINAL_ASAR" 2>/dev/null || echo "未知")
    local size_mb
    size_mb=$(echo "scale=2; $size / 1048576" | bc 2>/dev/null || echo "未知")
    info "app.asar 大小: ${size_mb} MB (${size} 字节)"

    # 检查客户端版本
    if command -v npx &>/dev/null; then
      local ver_dir="$TEMP_DIR/ver_check"
      if npx --yes @electron/asar extract "$ORIGINAL_ASAR" "$ver_dir" 2>/dev/null; then
        local pkg="$ver_dir/package.json"
        if [[ -f "$pkg" ]]; then
          local version
          version=$(grep -o '"version": *"[^"]*"' "$pkg" | head -1 | cut -d'"' -f4)
          if [[ -n "$version" ]]; then
            info "客户端版本: ${BOLD}$version${RESET}"
          fi
        fi
      fi
    fi

    # 汉化状态
    if is_patched "$ORIGINAL_ASAR"; then
      echo -e "  汉化状态: ${CYAN}${BOLD}已汉化 ✓${RESET}"
    else
      echo -e "  汉化状态: ${GREEN}${BOLD}未汉化 (官方原版)${RESET}"
    fi
  else
    error "app.asar 文件不存在"
  fi

  # 备份状态
  local preload_backup="$RESOURCES_DIR/preload.js.original.bak"
  if [[ -f "$preload_backup" ]]; then
    success "原版 preload.js 备份: 存在 ✓"
  else
    warn "原版 preload.js 备份: 不存在"
  fi

  # Node.js 环境
  if command -v npx &>/dev/null; then
    local node_ver
    node_ver=$(node --version 2>/dev/null || echo "未知")
    success "Node.js 环境: 已安装 ($node_ver)"
  else
    warn "Node.js 环境: 未安装"
  fi

  echo ""
}

# ── 主菜单 ────────────────────────────────────────────────
show_menu() {
  clear
  echo -e "${CYAN}${BOLD}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║     Antigravity 中文汉化补丁 — macOS 管理工具       ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "  ${GREEN}1.${RESET} 🚀 安装/更新中文汉化补丁"
  echo -e "  ${YELLOW}2.${RESET} 🛡️  卸载补丁并还原官方原版"
  echo -e "  ${BLUE}3.${RESET} 🔍 检查当前汉化状态与版本"
  echo -e "  ${RED}4.${RESET} 🚪 退出"
  echo ""
  echo -ne "  请输入选项 [1-4]: "
}

# ── 入口 ──────────────────────────────────────────────────
main() {
  while true; do
    show_menu
    read -r choice
    case "$choice" in
      1) apply_patch ;;
      2) restore_backup ;;
      3) check_status ;;
      4)
        echo ""
        echo -e "${GREEN}再见！祝您使用愉快 🎉${RESET}"
        echo ""
        exit 0
        ;;
      *)
        warn "无效选项，请重新输入。"
        sleep 1
        ;;
    esac
    echo ""
    echo -ne "  按回车键返回主菜单..."
    read -r
  done
}

main "$@"
