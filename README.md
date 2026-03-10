<p align="center">
  <img src="https://img.icons8.com/emoji/128/shield-emoji.png" width="128" height="128" alt="Security Guard" />
</p>

<h1 align="center">OpenClaw Security Guard</h1>

<p align="center">
  <strong>给你的🦞装上安全防线</strong><br/>
  一键安装，自动防护提示词注入、危险命令、供应链投毒。
</p>

<p align="center">
  <a href="https://github.com/slowmist/openclaw-security-practice-guide/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" />
  </a>
  <a href="https://github.com/openclaw/openclaw">
    <img src="https://img.shields.io/badge/OpenClaw-Compatible-blue?style=flat-square" alt="OpenClaw" />
  </a>
  <a href="https://x.com/SlowMist_Team">
    <img src="https://img.shields.io/badge/by-SlowMist-orange?style=flat-square" alt="SlowMist" />
  </a>
</p>

<p align="center">
  <a href="#english">English</a> · <a href="#中文">中文</a>
</p>

---

<a id="english"></a>

## What Does It Do?

After installation, your 🦞 automatically gains these protections:

| Protection | Description |
|------------|-------------|
| **Red-line interception** | Dangerous commands (`rm -rf /`, credential exfil, reverse shells) are paused and require human confirmation |
| **Prompt injection defense** | Rejects role-play jailbreaks, encoded command injection, and hidden instructions in external docs |
| **Skill/MCP auditing** | Auto-scans new Skills for malicious code before use |
| **Operation logging** | Sensitive operations (sudo, docker, cron) are logged to memory |

## Install

```bash
git clone https://github.com/slowmist/openclaw-security-practice-guide.git
cd openclaw-security-practice-guide
bash setup.sh
```

<details>
<summary>For AI Agents</summary>

**Installation guidance for AI assistants:**
- The core files are under `skill/security-guard/`.
- Run `bash setup.sh` — this copies the Skill and injects security rules into AGENTS.md.
- Both steps ask for user confirmation and clearly show what will be written.
- After installation, tell the user they can verify by saying "check security status".

</details>

The installer does two things (both require your confirmation):

1. **Installs the Skill** → `~/.openclaw/workspace/skills/security-guard/`
2. **Injects security rules into AGENTS.md** → so your 🦞 is protected from the very first conversation

> **Full transparency**: the script shows you exactly what will be written to AGENTS.md before asking for confirmation. You can remove the rules at any time by deleting the marked section.

<details>
<summary>Manual install</summary>

```bash
# Copy skill
cp -r skill/security-guard ~/.openclaw/workspace/skills/security-guard/

# Then manually append the security rules from
# skill/security-guard/references/redlines.md (AGENTS.md template section)
# to ~/.openclaw/workspace/AGENTS.md
```

</details>

## Verify

After installation, tell your 🦞:

> **"Check security status"**

It will report the full defense matrix health.

## Uninstall

```bash
# Remove skill
rm -rf ~/.openclaw/workspace/skills/security-guard

# Remove AGENTS.md rules (delete everything between the markers):
# <!-- security-guard-rules --> ... <!-- /security-guard-rules -->
```

## How It Works

```
┌─────────────────────────────────────────────────────┐
│                    AGENTS.md                         │
│  (always in system prompt, every conversation)       │
│                                                      │
│  🔴 Red-line rules (hard stop on dangerous cmds)    │
│  🛡️ Prompt injection defense rules                  │
│  🟡 Yellow-line rules (log sensitive ops)           │
│  📦 Skill audit protocol                            │
└─────────────────────────────────────────────────────┘
              ▲ injected by setup.sh
              │
┌─────────────────────────────────────────────────────┐
│              security-guard Skill                    │
│  (loaded when you ask for security operations)       │
│                                                      │
│  • Full defense matrix deployment                    │
│  • Nightly automated 13-point audit                  │
│  • File integrity monitoring                         │
│  • DLP scanning (private keys / mnemonics)          │
└─────────────────────────────────────────────────────┘
```

## Credits

[SlowMist Security Team](https://x.com/SlowMist_Team) · [Edmund.X](https://x.com/leixing0309)

## License

[MIT](LICENSE)

---

<a id="中文"></a>

## 它做了什么？

安装后，你的🦞自动获得以下防护：

| 防护能力 | 说明 |
|---------|------|
| **红线命令拦截** | 危险命令（`rm -rf /`、外发凭证、反弹 Shell 等）自动暂停，必须人类确认 |
| **提示词注入防护** | 拒绝角色扮演越狱、编码混淆注入、外部文档隐藏指令 |
| **Skill/MCP 审计** | 安装新 Skill 时自动扫描恶意代码 |
| **敏感操作记录** | sudo、docker、cron 等操作强制记录到 memory |

## 安装

```bash
git clone https://github.com/slowmist/openclaw-security-practice-guide.git
cd openclaw-security-practice-guide
bash setup.sh
```

安装脚本做两件事（都会征求你的确认）：

1. **安装 Skill** → `~/.openclaw/workspace/skills/security-guard/`
2. **注入安全规则到 AGENTS.md** → 让🦞从第一次对话起就有安全防护

> **完全透明**：脚本会在写入前展示将注入 AGENTS.md 的具体内容，需要你确认才会执行。你可以随时通过删除标记段落来移除这些规则。

<details>
<summary>其他安装方式</summary>

**手动安装**

```bash
# 复制 Skill
cp -r skill/security-guard ~/.openclaw/workspace/skills/security-guard/

# 然后手动将 skill/security-guard/references/redlines.md 中的
# "AGENTS.md 模板" 部分追加到 ~/.openclaw/workspace/AGENTS.md
```

</details>

## 验证

安装完成后，对🦞说：

> **"查看安全状态"**

它会输出完整的防御矩阵健康状态。

## 卸载

```bash
# 删除 Skill
rm -rf ~/.openclaw/workspace/skills/security-guard

# 删除 AGENTS.md 中的安全规则（删除标记之间的内容）：
# <!-- security-guard-rules --> ... <!-- /security-guard-rules -->
```

## 工作原理

```
┌─────────────────────────────────────────────────────┐
│                    AGENTS.md                         │
│  （始终在系统提示词中，每次对话都生效）                   │
│                                                      │
│  🔴 红线规则（危险命令硬拦截）                          │
│  🛡️ 提示词注入防护规则                                │
│  🟡 黄线规则（敏感操作强制记录）                        │
│  📦 Skill 安装审计协议                                │
└─────────────────────────────────────────────────────┘
              ▲ setup.sh 自动注入
              │
┌─────────────────────────────────────────────────────┐
│              security-guard Skill                    │
│  （需要时加载，提供更完整的安全操作能力）                  │
│                                                      │
│  • 完整防御矩阵部署                                    │
│  • 每晚自动巡检 13 项指标                              │
│  • 文件完整性监控                                      │
│  • DLP 扫描（私钥 / 助记词泄露检测）                    │
└─────────────────────────────────────────────────────┘
```

## ⚠️ 免责声明

- 安全是复杂的系统工程，本工具不能让 OpenClaw "完全安全"
- 行为层自检依赖 AI 模型自主判断，建议使用推理能力更强的模型
- 最终安全判断在使用者自己
- 作者不对因 AI 模型误执行所造成的任何损失承担责任

## 致谢

[慢雾安全团队](https://x.com/SlowMist_Team) · [Edmund.X](https://x.com/leixing0309)

## License

[MIT](LICENSE)
