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

After installation, your 🧡 gains these behavioral rules via AGENTS.md system prompt:

> **⚠️ Important**: These are AI behavioral rules, not hard technical controls. Their effectiveness depends on the AI model's ability to interpret and follow them. Use a capable model (Gemini / Opus / GPT) for best results.

| Protection | How it works |
|------------|-------------|
| **Red-line interception** | Rules instruct the AI to pause and ask for human confirmation before dangerous commands |
| **Prompt injection defense** | Rules instruct the AI to reject jailbreaks, encoded injection, and hidden instructions |
| **Skill/MCP audit protocol** | Rules instruct the AI to scan new Skills before use (requires AI compliance) |
| **Operation logging** | Rules instruct the AI to log sensitive operations to memory |

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

> **Transparency**: the script shows a summary of the rules before writing. You can review the full rule text in `skill/security-guard/references/redlines.md` or in the script source. Rules can be removed at any time by deleting the marked section.

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
│  • Nightly automated 12-point audit                  │
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

安装后，你的🧡会通过 AGENTS.md 系统提示词获得以下行为规则：

> **⚠️ 重要提示**：这些是 AI 行为规则，不是硬性技术控制。它们的有效性取决于 AI 模型的理解和遵循能力。建议使用推理能力较强的模型（Gemini / Opus / GPT）。

| 防护能力 | 工作方式 |
|---------|------|
| **红线命令拦截** | 规则指示 AI 在执行危险命令前暂停并请求人类确认 |
| **提示词注入防护** | 规则指示 AI 拒绝角色扮演越狱、编码混淆注入、外部文档隐藏指令 |
| **Skill/MCP 审计协议** | 规则指示 AI 在使用新 Skill 前进行审计（需要 AI 遵循） |
| **敏感操作记录** | 规则指示 AI 将 sudo、docker、cron 等操作记录到 memory |

## 安装

```bash
git clone https://github.com/slowmist/openclaw-security-practice-guide.git
cd openclaw-security-practice-guide
bash setup.sh
```

安装脚本做两件事（都会征求你的确认）：

1. **安装 Skill** → `~/.openclaw/workspace/skills/security-guard/`
2. **注入安全规则到 AGENTS.md** → 让🦞从第一次对话起就有安全防护

> **透明度**：脚本会在写入前展示规则摘要。完整规则内容可在 `skill/security-guard/references/redlines.md` 或脚本源码中查看。你可以随时通过删除标记段落来移除这些规则。

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
│  • 每晚自动巡检 12 项指标                              │
│  • 文件完整性监控                                      │
│  • DLP 扫描（私钥 / 助记词泄露检测）                    │
└─────────────────────────────────────────────────────┘
```

## ⚠️ 免责声明

- **这是行为层防护，不是硬性拦截**：所有规则通过 AI 系统提示词实现，依赖模型的理解和遵循能力
- 如果模型被绕过、忽略规则或能力不足，这些保护可能失效
- 安全是复杂的系统工程，本工具不能让 OpenClaw "完全安全"
- 建议使用推理能力更强的模型（Gemini / Opus / GPT）
- 最终安全判断在使用者自己
- 作者不对因 AI 模型误执行所造成的任何损失承担责任

## 致谢

[慢雾安全团队](https://x.com/SlowMist_Team) · [Edmund.X](https://x.com/leixing0309)

## License

[MIT](LICENSE)
