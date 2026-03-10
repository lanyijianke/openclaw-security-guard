#!/usr/bin/env bash
# Security Guard — 防御矩阵部署辅助脚本
# 用法: deploy-matrix.sh <command>
#   check       - 检测当前安全状态
#   permissions - 权限收窄
#   baseline    - 生成哈希基线
#   status      - 输出完整安全状态报告

set -euo pipefail

OS_TYPE="$(uname -s)"
OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

# ────────────── 颜色 ──────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 安全校验：解析真实路径，防止符号链接重定向
if command -v realpath >/dev/null 2>&1; then
  OC_REAL=$(realpath "$OC" 2>/dev/null || echo "$OC")
  if [ "$OC" != "$OC_REAL" ]; then
    echo -e "${YELLOW}⚠️  OC 路径包含符号链接: $OC -> $OC_REAL${NC}"
    OC="$OC_REAL"
  fi
fi

ok() { echo -e "  ${GREEN}✅${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
fail() { echo -e "  ${RED}❌${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ️${NC}  $1"; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# ────────────── 跨平台工具 ──────────────

file_perm() {
  if [ "$OS_TYPE" = "Darwin" ]; then
    stat -f "%Lp" "$1" 2>/dev/null || echo "MISSING"
  else
    stat -c "%a" "$1" 2>/dev/null || echo "MISSING"
  fi
}

hash_cmd() {
  if [ "$OS_TYPE" = "Darwin" ]; then
    shasum -a 256 "$@"
  else
    sha256sum "$@"
  fi
}

hash_check() {
  if [ "$OS_TYPE" = "Darwin" ]; then
    shasum -a 256 -c "$@"
  else
    sha256sum -c "$@"
  fi
}

# ────────────── check ──────────────

do_check() {
  header "🔍 Security Guard — 环境检测"
  echo ""

  # OS
  info "操作系统: $OS_TYPE $(uname -r)"

  # OpenClaw
  if command -v openclaw >/dev/null 2>&1; then
    ok "OpenClaw 已安装"
  else
    fail "OpenClaw 未安装或不在 PATH 中"
  fi

  # OC 目录
  if [ -d "$OC" ]; then
    ok "状态目录: $OC"
  else
    fail "状态目录不存在: $OC"
    return 1
  fi

  # 权限
  if [ "$(id -u)" = "0" ]; then
    warn "当前以 root 运行"
  elif sudo -n true 2>/dev/null; then
    ok "sudo 可用 (无需密码)"
  else
    info "sudo 需要密码"
  fi

  # 依赖
  for CMD in git grep find; do
    if command -v "$CMD" >/dev/null 2>&1; then
      ok "$CMD 可用"
    else
      fail "$CMD 未安装"
    fi
  done

  # sha256
  if [ "$OS_TYPE" = "Darwin" ]; then
    command -v shasum >/dev/null 2>&1 && ok "shasum 可用" || fail "shasum 未安装"
  else
    command -v sha256sum >/dev/null 2>&1 && ok "sha256sum 可用" || fail "sha256sum 未安装"
  fi

  echo ""
}

# ────────────── permissions ──────────────

do_permissions() {
  header "🔒 Security Guard — 权限收窄"
  echo ""

  for F in "$OC/openclaw.json" "$OC/devices/paired.json"; do
    if [ -L "$F" ]; then
      fail "$(basename "$F") 是符号链接 -> $(readlink "$F" 2>/dev/null || echo '未知')，已跳过（防止误改外部文件）"
    elif [ -f "$F" ]; then
      PERM=$(file_perm "$F")
      if [ "$PERM" = "600" ]; then
        ok "$(basename "$F") 权限已为 600"
      else
        info "$(basename "$F") 当前权限: $PERM → 收窄为 600"
        chmod 600 "$F"
        ok "$(basename "$F") 已设置为 600"
      fi
    else
      warn "$(basename "$F") 不存在: $F"
    fi
  done

  echo ""
}

# ────────────── baseline ──────────────

do_baseline() {
  header "🔐 Security Guard — 哈希基线"
  echo ""

  BASELINE="$OC/.config-baseline.sha256"

  if [ -L "$OC/openclaw.json" ]; then
    fail "openclaw.json 是符号链接，拒绝生成基线（防止对错误对象校验）"
    echo ""
    return 1
  fi

  if [ -f "$OC/openclaw.json" ]; then
    if [ -f "$BASELINE" ]; then
      info "基线已存在，正在对比..."
      if (cd "$OC" && hash_check .config-baseline.sha256 2>&1); then
        ok "哈希校验通过 (与基线一致)"
        info "如需重建基线，请删除 $BASELINE 后重新运行"
      else
        warn "哈希校验失败！文件可能已被修改"
        info "如确认安全，运行: rm $BASELINE && $0 baseline"
      fi
    else
      info "首次生成基线..."
      (cd "$OC" && hash_cmd openclaw.json > .config-baseline.sha256)
      warn "基线已生成: $BASELINE（请确认当前 openclaw.json 状态可信）"
    fi
  else
    fail "openclaw.json 不存在"
  fi

  echo ""
}

# ────────────── status ──────────────

do_status() {
  header "📋 Security Guard — 安全状态报告"
  echo ""

  # 1) AGENTS.md 红/黄线（使用官方标记而非模糊匹配）
  AGENTS_FILE="$OC/workspace/AGENTS.md"
  MARKER="<!-- security-guard-rules -->"
  MARKER_END="<!-- /security-guard-rules -->"
  if [ -f "$AGENTS_FILE" ] && grep -q "$MARKER" "$AGENTS_FILE" 2>/dev/null && grep -q "$MARKER_END" "$AGENTS_FILE" 2>/dev/null; then
    ok "AGENTS.md 包含完整安全规则（开始/结束标记均存在）"
  elif [ -f "$AGENTS_FILE" ] && grep -q "$MARKER" "$AGENTS_FILE" 2>/dev/null; then
    warn "AGENTS.md 包含开始标记但缺少结束标记（规则可能不完整）"
  elif [ -f "$AGENTS_FILE" ]; then
    warn "AGENTS.md 存在但未发现 Security Guard 规则标记"
  else
    fail "AGENTS.md 不存在"
  fi

  # 2) 权限
  for F in "$OC/openclaw.json" "$OC/devices/paired.json"; do
    if [ -f "$F" ]; then
      PERM=$(file_perm "$F")
      if [ "$PERM" = "600" ]; then
        ok "$(basename "$F") 权限: $PERM ✓"
      else
        warn "$(basename "$F") 权限: $PERM (应为 600)"
      fi
    fi
  done

  # 3) 哈希基线
  BASELINE="$OC/.config-baseline.sha256"
  if [ -f "$BASELINE" ]; then
    if (cd "$OC" && hash_check .config-baseline.sha256 >/dev/null 2>&1); then
      ok "哈希基线: 校验通过"
    else
      fail "哈希基线: 校验失败"
    fi
  else
    warn "哈希基线: 未生成"
  fi

  # 4) 巡检脚本
  AUDIT_SCRIPT="$OC/workspace/scripts/nightly-audit.sh"
  if [ -f "$AUDIT_SCRIPT" ]; then
    ok "巡检脚本已部署"
    if [ "$OS_TYPE" != "Darwin" ]; then
      if lsattr "$AUDIT_SCRIPT" 2>/dev/null | grep -q 'i'; then
        ok "巡检脚本已锁定 (chattr +i)"
      else
        warn "巡检脚本未锁定"
      fi
    fi
  else
    warn "巡检脚本未部署"
  fi

  # 5) Cron（解析任务名列，防止其他字段误匹配）
  if command -v openclaw >/dev/null 2>&1; then
    CRON_OUTPUT=$(openclaw cron list 2>/dev/null || true)
    # 提取首列（任务名）进行精确匹配
    if echo "$CRON_OUTPUT" | awk '{print $1}' | grep -qx "nightly-security-audit"; then
      ok "巡检 Cron Job 已注册"
      echo "$CRON_OUTPUT" | grep "nightly-security-audit" | while read -r LINE; do
        info "  $LINE"
      done
    else
      warn "巡检 Cron Job 未注册"
    fi
  fi

  echo ""
}

# ────────────── 主入口 ──────────────

usage() {
  echo "Security Guard — 防御矩阵部署辅助"
  echo ""
  echo "用法: $0 <command>"
  echo ""
  echo "Commands:"
  echo "  check        检测环境与依赖"
  echo "  permissions  收窄核心文件权限 (chmod 600)"
  echo "  baseline     生成/验证哈希基线"
  echo "  status       输出完整安全状态报告"
  echo ""
}

case "${1:-}" in
  check)       do_check ;;
  permissions) do_permissions ;;
  baseline)    do_baseline ;;
  status)      do_status ;;
  *)           usage ;;
esac
