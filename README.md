# Telegram Agents Master

**Manage multiple Claude Code agents from Telegram. 24/7. From any phone.**

> You have a team of AI agents. Now control them from your pocket.

---

## The Problem

You're running Claude Code on a powerful machine — but you're not always sitting in front of it.

| Solution | Multi-Session | Notifications | Works Offline | Mobile-First |
|---|:---:|:---:|:---:|:---:|
| SSH + tmux | - | - | + | - |
| Claude Remote Control | - | - | - | + |
| OpenClaw | + | + | - | - |
| **CCBot + This Skill** | **+** | **+** | **+** | **+** |

**Remote Control** is great — for a single session. Close the terminal? Dead. Internet drops for 10 minutes? Dead. No notifications, no multi-session.

**OpenClaw** is a different agent entirely. You lose CLAUDE.md, MCP servers, project context, tool permissions — everything that makes Claude Code *yours*.

**CCBot** is a thin layer on top of tmux. It reads terminal output and sends keystrokes. Your terminal stays the source of truth. 1 Telegram topic = 1 tmux window = 1 Claude Code session.

This repo gives you a **Claude Code skill** that installs and configures the entire setup — automatically.

---

## Install

One command. Paste this into Claude Code:

```
/skill install github:eligrumman/telegram-agents-master
```

Or manually:

```bash
git clone https://github.com/eligrumman/telegram-agents-master.git
cp -r telegram-agents-master/skills/ccbot-setup ~/.claude/skills/
```

Then tell your agent:

```
install ccbot
```

---

## What Happens Next

Your agent offers you two pills:

```
🔴🔵 Welcome to CCBot Setup

🔴 Red — Full auto. I install, configure, launch.
   You just open Telegram in a browser and sit quietly.

🔵 Blue — Step by step. I explain, you execute. Full control.

Your choice.
```

**Red pill:** Claude does everything — clones the repo, installs dependencies, creates your `.env`, installs hooks, starts tmux. You only handle the Telegram parts (creating a bot, setting up a group).

**Blue pill:** Claude walks you through a checklist. You run every command. Full control.

---

## What You Get

| Feature | Description |
|---|---|
| **Multi-session** | Each Telegram topic = a separate Claude Code session |
| **Real-time notifications** | Claude asks a question? You get a push notification |
| **Permission buttons** | Approve/reject with one tap |
| **Voice messages** | Talk to Claude from your phone |
| **Terminal screenshots** | `/screenshot` — see exactly what Claude sees |
| **Directory browser** | Start new sessions by picking a project folder |
| **Session history** | Scroll through past messages with pagination |
| **Desktop handoff** | `tmux attach` — pick up right where you left off |

---

## Requirements

| Requirement | Why |
|---|---|
| **Claude Code Max subscription** | Opus access — no Opus, no team |
| **Telegram account** | The control interface |
| **Python 3.10+** and **uv** | CCBot runtime |
| **tmux** | Session persistence layer |
| **Always-on machine** | See [Where to Run](#where-to-run) below |

---

## Where to Run

CCBot needs a machine that's always on. Here are your options:

### Option 1: Old Laptop / Mac Mini (Recommended)

The cheapest and best option. Repurpose what you already have.

- **Used Mac Mini M2** — 1,500-2,500 ₪ one-time (~$400-700)
- **Old laptop with a scratched screen** — Claude Code doesn't care about screens
- **Minimum:** 8GB RAM, any modern CPU
- **Ideal:** 16GB RAM — runs 10+ Claude Code sessions comfortably

**RAM per session:** Claude Code uses ~300-500MB. With 16GB you have room for a small army.

> My setup? A used laptop with a screen scratch that knocked thousands off the price. Claude Code doesn't care about scratches.

### Option 2: Linux VPS (Cheapest Ongoing)

For the adventurous. Claude Code runs perfectly on Linux.

| Provider | Specs | Price |
|---|---|---|
| **Hetzner CAX21** | 4 vCPU ARM, 8GB RAM | ~$8/month |
| **Hetzner CCX23** | 4 vCPU, 16GB RAM | ~$33/month |

```bash
# Quick setup on a fresh Linux VPS
curl -fsSL https://cli.claude.ai/install.sh | sh
apt install tmux
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Option 3: Cloud Mac (~$100/month)

If you want macOS in the cloud:

| Provider | Specs | Price |
|---|---|---|
| **Macly** | Mac Mini M4, 16GB RAM | $100/month |
| **MacStadium** | Mac Mini M2, 8GB RAM | $109/month |
| **MacStadium M4** | Mac Mini M4, 16GB RAM | $119/month |

> For $100/month, you'll pay for a used Mac Mini in 15-25 months. Buy used. It pays for itself fast.

---

## How It Works

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Telegram   │────▶│    CCBot     │────▶│    tmux      │
│  (your phone)│◀────│  (bridge)    │◀────│ (Claude Code)│
└──────────────┘     └──────────────┘     └──────────────┘
```

1. You send a message in a Telegram topic
2. CCBot receives it and types it into the matching tmux window
3. Claude Code processes and outputs to terminal
4. CCBot reads the terminal output and sends it back to Telegram
5. If Claude needs permission — you get a notification with approve/reject buttons

**CCBot does NOT use the Claude API.** It operates entirely on tmux — reading and writing to the terminal. The terminal is always the source of truth.

---

## Commands

| Command | What it does |
|---|---|
| `/esc` | Stop Claude mid-action |
| `/screenshot` | Terminal screenshot as image |
| `/clear` | Clear session, start fresh |
| `/compact` | Compress conversation context |
| `/cost` | Show token usage |
| `/history` | Browse message history |
| Any `/command` | Forwarded directly to Claude Code |

---

## FAQ

<details>
<summary><strong>Do I need MCP servers?</strong></summary>

No. For an always-on CCBot setup, it's actually better without them.

MCP servers add memory overhead (~200-300MB each). Claude Code without MCP is lean at ~300MB/session. Add 3-4 MCP servers and you're at 500-800MB.

For 24/7 operation: install only what you truly need, or skip MCP entirely. Claude Code is extremely capable with just its built-in tools.
</details>

<details>
<summary><strong>What about security?</strong></summary>

- `ALLOWED_USERS` restricts who can control the bot (Telegram user IDs)
- The bot only responds to authorized users
- All communication goes through Telegram's encrypted infrastructure
- CCBot runs locally on your machine — nothing goes to third-party servers
</details>

<details>
<summary><strong>Can I run multiple agents in parallel?</strong></summary>

Yes. Each Telegram topic is a separate Claude Code session. Open 3 topics = 3 agents running simultaneously. Jump between them like WhatsApp chats.
</details>

<details>
<summary><strong>What if I want to go back to my desktop?</strong></summary>

`tmux attach -t ccbot` — everything is right where you left it. The terminal never stopped running.
</details>

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `uv: command not found` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `tmux: command not found` | macOS: `brew install tmux` / Linux: `apt install tmux` |
| Bot doesn't respond in group | Bot must be admin + Threaded Mode enabled + Group Privacy disabled |
| `TELEGRAM_BOT_TOKEN not set` | Check `.env` file exists in `~/ccbot/` with the token |
| Hook not tracking sessions | Run `uv run ccbot hook --install` again, restart Claude Code |
| Bot can't see messages | `@BotFather` → `/setprivacy` → Select bot → Disable |

---

## What's Inside

```
telegram-agents-master/
├── skills/
│   └── ccbot-setup/
│       └── SKILL.md          # The Claude Code skill (auto + guided modes)
├── docs/
│   └── setup-guide-he.md     # Full Hebrew setup guide (10 steps)
├── install.sh                # One-liner installer
├── LICENSE
└── README.md
```

---

## Credits

- **[CCBot](https://github.com/six-ddc/ccbot)** by [ddc](https://github.com/six-ddc) — who built CCBot using CCBot
- Setup skill and documentation by [Eli Groman](https://www.linkedin.com/in/eli-grumman-495b0636/)

---

## License

MIT License. See [LICENSE](LICENSE) for details.
