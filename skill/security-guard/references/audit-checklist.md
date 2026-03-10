# 每晚巡检 — 13 项核心指标详解

> Agent 在部署巡检脚本和解读巡检报告时参考本文件。

---

## 指标总览

| # | 指标 | 检测方法 | 健康标准 | 异常阈值 |
|---|------|---------|---------|---------|
| 1 | OpenClaw 基础审计 | `openclaw security audit --deep` | 无 critical 发现 | 任何 critical |
| 2 | 进程与网络 | 监听端口 + Top 15 进程 | 无未知监听 | 未知端口/出站连接 |
| 3 | 敏感目录变更 | `find -mtime -1` 扫描 5 个目录 | 变更文件合理 | 异常大量变更 |
| 4 | 系统定时任务 | crontab + cron.d + systemd timers | 无可疑任务 | 未知定时任务 |
| 5 | OpenClaw Cron | `openclaw cron list` | 与预期一致 | 出现未知任务 |
| 6 | SSH 安全 | 登录记录 + 失败尝试 | 0 次暴力尝试 | 多次失败登录 |
| 7 | 配置完整性 | 哈希基线对比 + 权限检查 | 校验通过 + 600 | 基线不匹配/权限异常 |
| 8 | 黄线交叉验证 | sudo 日志 vs memory 日志 | 记录匹配 | 未记录的 sudo |
| 9 | 磁盘使用 | 根分区使用率 + 大文件 | <85% | ≥85% 或异常大文件 |
| 10 | 环境变量 | gateway 进程 environ | 变量名在白名单内 | 异常凭证变量 |
| 11 | DLP 扫描 | 正则扫描私钥/助记词 | 0 hits | 任何 hit |
| 12 | Skill/MCP 基线 | 哈希清单 diff | 与基线一致 | 哈希变化 |
| 13 | 灾备同步 | git commit + push | 推送成功 | 推送失败(warn) |

---

## 各指标详细说明

### 1. OpenClaw 基础审计

**命令**：`openclaw security audit --deep`

覆盖配置安全性、端口暴露、信任模型等。这是 OpenClaw 原生的安全扫描，作为巡检的基础层。

### 2. 进程与网络审计

**检查内容**：
- 监听端口（TCP + UDP）及关联进程
- 高资源占用进程 Top 15
- 异常出站连接

**Linux 命令**：
```bash
ss -tunlp          # 监听端口
ss -tnp            # TCP 出站连接
top -b -n 1 | head -n 15
```

**macOS 命令**：
```bash
lsof -nP -iTCP -sTCP:LISTEN    # 监听端口
netstat -an | grep ESTABLISHED  # 出站连接
top -l 1 | head -n 20
```

### 3. 敏感目录变更

**扫描目录**：`$OC/`、`/etc/`、`~/.ssh/`、`~/.gnupg/`、`/usr/local/bin/`

**命令**：
```bash
find <dir> -type f -mtime -1 2>/dev/null | wc -l
```

### 4. 系统定时任务

**检查范围**：
- 用户 crontab + `/etc/cron.d/`
- systemd timers（`systemctl list-timers --all`）
- 用户级 unit（`~/.config/systemd/user/`）
- macOS: `launchctl list`

### 5. OpenClaw Cron Jobs

**命令**：`openclaw cron list`

对比预期清单（部署时应记录预期的 Cron 列表）。

### 6. 登录与 SSH

**数据源**：
- `last -a -n 5`（最近登录）
- `journalctl -u sshd --since "24 hours ago"`（Linux）
- `log show --predicate 'process == "sshd"' --last 24h`（macOS）
- `/var/log/auth.log` 或 `/var/log/secure`（回退方案）

### 7. 关键文件完整性

**哈希校验**：
```bash
# Linux
sha256sum -c $OC/.config-baseline.sha256
# macOS
shasum -a 256 -c $OC/.config-baseline.sha256
```

**权限检查**：
- `openclaw.json` → 600
- `paired.json` → 600（不做哈希校验）
- `sshd_config` → 读取并记录
- `authorized_keys` → 读取并记录

### 8. 黄线操作交叉验证

对比 `/var/log/auth.log` 中的 sudo 记录与 `memory/YYYY-MM-DD.md` 中的黄线日志。未记录的 sudo 执行视为异常。

### 9. 磁盘使用

- 根分区使用率（`df -h /`），≥85% 告警
- 最近 24h 新增大文件（>100MB）

### 10. Gateway 环境变量

读取 gateway 进程的 `/proc/<pid>/environ`（Linux），列出含 KEY/TOKEN/SECRET/PASSWORD 的变量名（值脱敏）。

macOS 替代：`ps aux | grep openclaw-gateway`（信息有限）。

### 11. 明文凭证泄露扫描 (DLP)

**扫描目标**：`$OC/workspace/`（尤其 `memory/` 和 `logs/`）

**正则模式**：
- ETH 私钥：`\b0x[a-fA-F0-9]{64}\b`
- 12/24 词助记词：`\b([a-z]{3,12}\s+){11}([a-z]{3,12})\b`

### 12. Skill/MCP 完整性

对所有已安装 Skill/MCP 目录执行 `find + sha256sum`，生成哈希清单。与上次巡检基线 diff，有变化则告警。

基线文件：`$OC/security-baselines/skill-mcp-baseline.sha256`

### 13. 大脑灾备自动同步

在 `$OC/` 中执行 `git add . && git commit && git push`。

**重要**：灾备推送失败不阻塞巡检报告输出，记录为 warn 并继续。

---

## 巡检简报输出格式

```text
🛡️ OpenClaw 每日安全巡检简报 (YYYY-MM-DD)

1. 平台审计: ✅ 已执行原生扫描
2. 进程网络: ✅ 无异常出站/监听端口
3. 目录变更: ✅ 3 个文件变更
4. 系统 Cron: ✅ 未发现可疑系统级任务
5. 本地 Cron: ✅ 任务列表与预期一致
6. SSH 安全: ✅ 0 次失败尝试
7. 配置基线: ✅ 哈希校验通过且权限合规
8. 黄线审计: ✅ 2 次 sudo（与 memory 比对一致）
9. 磁盘容量: ✅ 根分区占用 19%, 0 个大文件
10. 环境变量: ✅ 凭证变量在白名单内
11. 凭证扫描: ✅ 未发现明文私钥或助记词
12. Skill基线: ✅ 与上次基线一致
13. 灾备备份: ✅ 已推送至远端仓库

📝 详细战报已保存: /tmp/openclaw/security-reports/report-YYYY-MM-DD.txt
```
