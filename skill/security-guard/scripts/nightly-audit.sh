#!/usr/bin/env bash
# Security Guard — 每晚全面安全巡检脚本 (跨平台版)
# 基于 OpenClaw 极简安全实践指南 v2.7，覆盖 12 项核心指标
# 支持 Linux 和 macOS

set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# ────────────── 安全默认值 ──────────────
# 限制新建文件权限：仅属主可读写
umask 077

# ────────────── 环境检测 ──────────────

OS_TYPE="$(uname -s)"
OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"

# 安全校验：解析真实路径，防止符号链接重定向
if command -v realpath >/dev/null 2>&1; then
  OC_REAL=$(realpath "$OC" 2>/dev/null || echo "$OC")
  if [ "$OC" != "$OC_REAL" ]; then
    echo "WARNING: OC path contains symlink: $OC -> $OC_REAL" >&2
    OC="$OC_REAL"
  fi
else
  echo "WARNING: realpath not available, symlink protection degraded" >&2
fi

# 报告目录：优先用 mktemp 防符号链接劫持
if command -v mktemp >/dev/null 2>&1; then
  REPORT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/openclaw-audit-XXXXXXXXXX")
else
  REPORT_DIR="/tmp/openclaw/security-reports"
  # 固定路径回退：检查 symlink 劫持
  if [ -L "$REPORT_DIR" ]; then
    echo "FATAL: $REPORT_DIR is a symlink — possible hijack, aborting" >&2
    exit 1
  fi
  mkdir -p "$REPORT_DIR"
  chmod 700 "$REPORT_DIR"
fi

DATE_STR=$(date +%F)
REPORT_FILE="$REPORT_DIR/report-$DATE_STR.txt"
SUMMARY="🛡️ OpenClaw 每日安全巡检简报 ($DATE_STR)\n\n"

echo "=== OpenClaw Security Audit Detailed Report ($DATE_STR) ===" > "$REPORT_FILE"
echo "Platform: $OS_TYPE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

append_warn() {
  SUMMARY+="$1\n"
}

# 跨平台工具函数
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

file_perm() {
  if [ "$OS_TYPE" = "Darwin" ]; then
    stat -f "%Lp" "$1" 2>/dev/null || echo "MISSING"
  else
    stat -c "%a" "$1" 2>/dev/null || echo "MISSING"
  fi
}

# ────────────── 1/13: OpenClaw 基础审计 ──────────────

echo "[1/13] OpenClaw 基础审计 (--deep)" >> "$REPORT_FILE"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw security audit --deep >> "$REPORT_FILE" 2>&1; then
    SUMMARY+="1. 平台审计: ✅ 已执行原生扫描\n"
  else
    append_warn "1. 平台审计: ⚠️ 执行失败（详见详细报告）"
  fi
else
  append_warn "1. 平台审计: ⚠️ openclaw 命令不可用"
fi

# ────────────── 2/13: 进程与网络 ──────────────

echo -e "\n[2/13] 监听端口与高资源进程" >> "$REPORT_FILE"
if [ "$OS_TYPE" = "Darwin" ]; then
  lsof -nP -iTCP -sTCP:LISTEN >> "$REPORT_FILE" 2>/dev/null || true
  top -l 1 | head -n 20 >> "$REPORT_FILE" 2>/dev/null || true
else
  ss -tunlp >> "$REPORT_FILE" 2>/dev/null || true
  top -b -n 1 | head -n 15 >> "$REPORT_FILE" 2>/dev/null || true
fi
SUMMARY+="2. 进程网络: ✅ 已采集监听端口与进程快照\n"

# ────────────── 3/13: 敏感目录变更 ──────────────

echo -e "\n[3/13] 敏感目录近 24h 变更文件数" >> "$REPORT_FILE"
SCAN_DIR_LIST=("$OC")
[ -d /etc ] && SCAN_DIR_LIST+=(/etc)
[ -d "$HOME/.ssh" ] && SCAN_DIR_LIST+=("$HOME/.ssh")
[ -d "$HOME/.gnupg" ] && SCAN_DIR_LIST+=("$HOME/.gnupg")
[ -d /usr/local/bin ] && SCAN_DIR_LIST+=(/usr/local/bin)

MOD_FILES=$(find "${SCAN_DIR_LIST[@]}" -type f -mtime -1 2>/dev/null | wc -l | xargs)
echo "Total modified files: $MOD_FILES" >> "$REPORT_FILE"
SUMMARY+="3. 目录变更: ✅ $MOD_FILES 个文件变更\n"

# ────────────── 4/13: 系统定时任务 ──────────────

echo -e "\n[4/13] 系统级定时任务" >> "$REPORT_FILE"
if [ "$OS_TYPE" = "Darwin" ]; then
  launchctl list >> "$REPORT_FILE" 2>/dev/null || true
  ls -la /Library/LaunchAgents/ /Library/LaunchDaemons/ ~/Library/LaunchAgents/ >> "$REPORT_FILE" 2>/dev/null || true
else
  ls -la /etc/cron.* /var/spool/cron/crontabs/ >> "$REPORT_FILE" 2>/dev/null || true
  systemctl list-timers --all >> "$REPORT_FILE" 2>/dev/null || true
  if [ -d "$HOME/.config/systemd/user" ]; then
    ls -la "$HOME/.config/systemd/user" >> "$REPORT_FILE" 2>/dev/null || true
  fi
fi
SUMMARY+="4. 系统 Cron: ✅ 已采集系统级定时任务信息\n"

# ────────────── 5/13: OpenClaw 定时任务 ──────────────

echo -e "\n[5/13] OpenClaw Cron Jobs" >> "$REPORT_FILE"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw cron list >> "$REPORT_FILE" 2>&1; then
    SUMMARY+="5. 本地 Cron: ✅ 已拉取内部任务列表\n"
  else
    append_warn "5. 本地 Cron: ⚠️ 拉取失败"
  fi
else
  append_warn "5. 本地 Cron: ⚠️ openclaw 命令不可用"
fi

# ────────────── 6/13: 登录与 SSH ──────────────

echo -e "\n[6/13] 最近登录记录与 SSH 失败尝试" >> "$REPORT_FILE"
last -n 5 >> "$REPORT_FILE" 2>/dev/null || true
FAILED_SSH=0

if [ "$OS_TYPE" = "Darwin" ]; then
  # macOS: 使用 log show
  FAILED_SSH=$(log show --predicate 'process == "sshd" AND eventMessage CONTAINS "Failed"' --last 24h 2>/dev/null | grep -c "Failed" || echo "0")
else
  if command -v journalctl >/dev/null 2>&1; then
    FAILED_SSH=$(journalctl -u sshd --since "24 hours ago" 2>/dev/null | grep -Ei "Failed|Invalid" | wc -l | xargs)
  fi
  if [ "$FAILED_SSH" = "0" ]; then
    for LOGF in /var/log/auth.log /var/log/secure /var/log/messages; do
      if [ -f "$LOGF" ]; then
        FAILED_SSH=$(grep -Ei "sshd.*(Failed|Invalid)" "$LOGF" 2>/dev/null | tail -n 1000 | wc -l | xargs)
        break
      fi
    done
  fi
fi
echo "Failed SSH attempts (recent): $FAILED_SSH" >> "$REPORT_FILE"
if [ "$FAILED_SSH" -gt 5 ]; then
  append_warn "6. SSH 安全: ⚠️ 近24h失败尝试 ${FAILED_SSH} 次（超过阈值 5）"
elif [ "$FAILED_SSH" -gt 0 ]; then
  SUMMARY+="6. SSH 安全: ✅ 近24h失败尝试 ${FAILED_SSH} 次（在正常范围内）\n"
else
  SUMMARY+="6. SSH 安全: ✅ 近24h无失败尝试\n"
fi

# ────────────── 7/13: 关键文件完整性与权限 ──────────────

echo -e "\n[7/13] 关键配置文件权限与哈希基线" >> "$REPORT_FILE"
HASH_RES="MISSING_BASELINE"
if [ -f "$OC/.config-baseline.sha256" ]; then
  HASH_RES=$(cd "$OC" && hash_check .config-baseline.sha256 2>&1 || true)
fi
echo "Hash Check: $HASH_RES" >> "$REPORT_FILE"

PERM_OC=$(file_perm "$OC/openclaw.json")
PERM_PAIRED=$(file_perm "$OC/devices/paired.json")
PERM_SSHD=$(file_perm "/etc/ssh/sshd_config")
PERM_AUTH_KEYS=$(file_perm "$HOME/.ssh/authorized_keys")
echo "Permissions: openclaw=$PERM_OC, paired=$PERM_PAIRED, sshd_config=$PERM_SSHD, authorized_keys=$PERM_AUTH_KEYS" >> "$REPORT_FILE"

if [[ "$HASH_RES" == *"OK"* ]] && [[ "$PERM_OC" == "600" ]]; then
  SUMMARY+="7. 配置基线: ✅ 哈希校验通过且权限合规\n"
else
  append_warn "7. 配置基线: ⚠️ 基线缺失/校验异常或权限不合规"
fi

# ────────────── 8/13: 黄线操作交叉验证 ──────────────

echo -e "\n[8/13] 黄线操作对比 (sudo logs vs memory)" >> "$REPORT_FILE"
SUDO_COUNT=0
if [ "$OS_TYPE" = "Darwin" ]; then
  SUDO_COUNT=$(log show --predicate 'process == "sudo"' --last 24h 2>/dev/null | grep -c "COMMAND" || echo "0")
else
  for LOGF in /var/log/auth.log /var/log/secure /var/log/messages; do
    if [ -f "$LOGF" ]; then
      SUDO_COUNT=$(grep -Ei "sudo.*COMMAND" "$LOGF" 2>/dev/null | tail -n 2000 | wc -l | xargs)
      break
    fi
  done
fi
MEM_FILE="$OC/workspace/memory/$DATE_STR.md"
MEM_COUNT=$(grep -i "sudo" "$MEM_FILE" 2>/dev/null | wc -l | xargs)
echo "Sudo Logs(recent): $SUDO_COUNT, Memory Logs(today): $MEM_COUNT" >> "$REPORT_FILE"
echo "NOTE: count-only comparison is coarse; timestamps/commands not cross-referenced" >> "$REPORT_FILE"
if [ "$SUDO_COUNT" -gt 0 ] && [ "$MEM_COUNT" -eq 0 ]; then
  append_warn "8. 黄线审计: ⚠️ 发现 ${SUDO_COUNT} 次 sudo 但 memory 无记录（可能存在未登记操作）"
elif [ "$SUDO_COUNT" -ne "$MEM_COUNT" ]; then
  append_warn "8. 黄线审计: ⚠️ sudo记录=${SUDO_COUNT} vs memory记录=${MEM_COUNT}（数量不一致）"
else
  SUMMARY+="8. 黄线审计: ✅ sudo记录=$SUDO_COUNT, memory记录=$MEM_COUNT（一致）\n"
fi

# ────────────── 9/13: 磁盘使用 ──────────────

echo -e "\n[9/13] 磁盘使用率与最近大文件" >> "$REPORT_FILE"
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')
LARGE_FILES=$(find "$HOME" -maxdepth 4 -type f -size +100M -mtime -1 2>/dev/null | wc -l | xargs)
echo "Disk Usage: $DISK_USAGE, Large Files (>100M in \$HOME): $LARGE_FILES" >> "$REPORT_FILE"
SUMMARY+="9. 磁盘容量: ✅ 根分区占用 $DISK_USAGE, 新增 $LARGE_FILES 个大文件\n"

# ────────────── 10/13: Gateway 环境变量 ──────────────

echo -e "\n[10/13] Gateway 环境变量泄露扫描" >> "$REPORT_FILE"
if [ "$OS_TYPE" = "Darwin" ]; then
  # macOS 没有 /proc，仅检查进程是否在运行
  GW_RUNNING=$(pgrep -f "openclaw" 2>/dev/null | head -n 1 || true)
  if [ -n "$GW_RUNNING" ]; then
    SUMMARY+="10. 环境变量: ✅ openclaw 进程运行中 (macOS 无 /proc 支持)\n"
  else
    append_warn "10. 环境变量: ⚠️ 未检测到 openclaw 进程"
  fi
else
  GW_PID=$(pgrep -f "openclaw-gateway" | head -n 1 || true)
  if [ -n "$GW_PID" ] && [ -r "/proc/$GW_PID/environ" ]; then
    strings "/proc/$GW_PID/environ" | grep -iE 'SECRET|TOKEN|PASSWORD|KEY' | awk -F= '{print $1"=(Hidden)"}' >> "$REPORT_FILE" 2>/dev/null || true
    SUMMARY+="10. 环境变量: ✅ 已执行网关进程敏感变量名扫描\n"
  else
    append_warn "10. 环境变量: ⚠️ 未定位到 openclaw-gateway 进程"
  fi
fi

# ────────────── 11/13: 明文凭证泄露扫描 (DLP) ──────────────

echo -e "\n[11/13] 明文私钥/助记词泄露扫描 (DLP)" >> "$REPORT_FILE"
SCAN_ROOT="$OC/workspace"
DLP_HITS=0
if [ -d "$SCAN_ROOT" ]; then
  H1=$(grep -RInE --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.gif' --exclude='*.webp' '\b0x[a-fA-F0-9]{64}\b' "$SCAN_ROOT" 2>/dev/null | wc -l | xargs)
  H2=$(grep -RInE --exclude-dir=.git --exclude='*.png' --exclude='*.jpg' --exclude='*.jpeg' --exclude='*.gif' --exclude='*.webp' '\b([a-z]{3,12}\s+){11}([a-z]{3,12})\b|\b([a-z]{3,12}\s+){23}([a-z]{3,12})\b' "$SCAN_ROOT" 2>/dev/null | wc -l | xargs)
  DLP_HITS=$((H1 + H2))
fi
echo "DLP hits (heuristic): $DLP_HITS" >> "$REPORT_FILE"
if [ "$DLP_HITS" -gt 0 ]; then
  append_warn "11. 敏感凭证扫描: ⚠️ 检测到疑似明文敏感信息($DLP_HITS)，请人工复核"
else
  SUMMARY+="11. 敏感凭证扫描: ✅ 未发现明显私钥/助记词模式\n"
fi

# ────────────── 12/13: Skill/MCP 完整性 ──────────────

echo -e "\n[12/13] Skill/MCP 完整性基线对比" >> "$REPORT_FILE"
SKILL_DIR="$OC/workspace/skills"
MCP_DIR="$OC/workspace/mcp"
HASH_DIR="$OC/security-baselines"
mkdir -p "$HASH_DIR"
CUR_HASH="$HASH_DIR/skill-mcp-current.sha256"
BASE_HASH="$HASH_DIR/skill-mcp-baseline.sha256"
: > "$CUR_HASH"
for D in "$SKILL_DIR" "$MCP_DIR"; do
  if [ -d "$D" ]; then
    # 用 while 循环替代 xargs（hash_cmd 是 shell 函数，xargs 无法调用）
    find "$D" -type f -print0 2>/dev/null | sort -z | while IFS= read -r -d '' FILE; do
      hash_cmd "$FILE" >> "$CUR_HASH" 2>/dev/null || true
    done
  fi
done

if [ -s "$CUR_HASH" ]; then
  if [ -f "$BASE_HASH" ]; then
    if diff -u "$BASE_HASH" "$CUR_HASH" >> "$REPORT_FILE" 2>&1; then
      SUMMARY+="12. Skill/MCP基线: ✅ 与上次基线一致\n"
    else
      append_warn "12. Skill/MCP基线: ⚠️ 检测到文件哈希变化（详见diff）"
    fi
  else
    cp "$CUR_HASH" "$BASE_HASH"
    append_warn "12. Skill/MCP基线: ⚠️ 首次生成基线（请确认当前 Skill/MCP 状态可信）"
  fi
else
  SUMMARY+="12. Skill/MCP基线: ✅ 未发现skills/mcp目录文件\n"
fi



# ────────────── 输出汇总 ──────────────

echo -e "$SUMMARY\n📝 详细战报已保存本机: $REPORT_FILE"
exit 0
