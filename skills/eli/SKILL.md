---
name: eli
description: Eli — your Claude Code expert. Install CCBot, get tips, best practices, and opinions from someone who spends $1,000/month on Opus. Use when user says "eli", "eli help", "eli install", "eli setup", "eli what do you think", "install ccbot", "setup ccbot", "התקן ccbot".
argument-hint: [install ccbot|help|what do you think]
---

# eli — Your Claude Code Expert

By [Eli Groman](https://www.linkedin.com/in/eli-grumman-495b0636/) — deaf developer, Claude Code power user, $1,000+/month on Opus.

## What I Can Help With

- **Install CCBot** — Telegram remote control for Claude Code (the main feature)
- **Claude Code tips** — best practices from 6+ months of daily Opus usage
- **Skills guidance** — how to build and structure Claude Code skills
- **Setup recommendations** — always-on machines, MCP servers, permissions

## CCBot Installation

## First Interaction

When triggered, present the user with this choice:

```
🔴🔵 ברוכים הבאים ל-CCBot Setup

האייג'נט מציע לכם 2 גלולות:

🔴 אדומה — אוטומט מלא. אני מתקין, מגדיר, מפעיל.
   אתם רק מתחברים לטלגרם בדפדפן ויושבים בשקט בלי להפריע.

🔵 כחולה — שלב-שלב. אני מסביר, אתם מבצעים. שליטה מלאה.

איזו גלולה?
```

Wait for the user's choice before proceeding.

## Prerequisites

- **Claude Code Max subscription** (required for Opus)
- **Telegram account**
- **Python 3.10+** and **uv** installed
- **tmux** installed (`brew install tmux` on macOS, `apt install tmux` on Linux)
- **An always-on machine** (see "Where to Run CCBot" section below)

## 🔴 Red Pill: Full Auto

Claude does everything automatically. The user only needs to interact with Telegram for BotFather steps (Telegram requires manual bot creation — no way around it).

**IMPORTANT for auto mode:** Open Telegram Web (web.telegram.org) in the browser BEFORE starting. Claude will guide the user through BotFather steps while doing everything else automatically.

**Flow:**

1. **Clone the repo**
   ```bash
   git clone https://github.com/six-ddc/ccbot.git ~/ccbot
   cd ~/ccbot
   ```

2. **Install dependencies**
   ```bash
   uv sync
   ```

3. **Guide user through BotFather** (manual — give exact instructions):
   - Open Telegram, search for `@BotFather`
   - Send `/newbot`
   - Choose a display name (e.g., "My Claude Bot")
   - Choose a username (must end in `bot`, e.g., `my_claude_ccbot`)
   - Copy the bot token BotFather gives you
   - **Tell the user:** "שלח לי את הטוקן שקיבלת מ-BotFather"

4. **Get user's Telegram ID** (manual — give exact instructions):
   - Open Telegram, search for `@userinfobot`
   - Send `/start`
   - It replies with your user ID (a number like `123456789`)
   - **Tell the user:** "שלח לי את ה-ID שקיבלת"

5. **Create .env file** (automatic once user provides token + ID):
   ```bash
   cp .env.example .env
   ```
   Then fill in `TELEGRAM_BOT_TOKEN` and `ALLOWED_USERS`. Keep defaults for everything else.

6. **Install the SessionStart hook** (automatic):
   ```bash
   uv run ccbot hook --install
   ```

7. **Create Telegram Forum group** (manual — give exact instructions):
   - Open Telegram → New Group
   - Name it "Claude Code" or "CCBot"
   - Make it a **Supergroup**: Group Settings → Edit → toggle any admin setting to trigger the upgrade
   - Enable **Topics**: Group Settings → Topics → Enable
   - Add your bot to the group and make it **admin**

8. **Enable Threaded Mode in BotFather** (manual — give exact instructions):
   - Open @BotFather's profile page in Telegram
   - Tap **Open App** (the mini app button at the bottom)
   - Select your bot from the list
   - Go to **Settings** → **Bot Settings**
   - Enable **Threaded Mode**

9. **Disable Group Privacy** (manual):
   - Go back to @BotFather chat
   - Send `/setprivacy`
   - Select your bot
   - Choose **Disable** (so the bot can read messages in the group)

10. **Start CCBot** (automatic):
    ```bash
    tmux new-session -d -s ccbot -n bot
    tmux send-keys -t ccbot:bot "cd ~/ccbot && uv run ccbot" Enter
    ```

11. **Verify** (automatic + manual):
    - Wait a few seconds for bot to start
    - **Tell the user:** "פתח את הגרופ בטלגרם, צור טופיק חדש, ושלח הודעה כלשהי. אם הבוט מגיב עם directory browser — הכל עובד!"

## 🔵 Blue Pill: Step by Step

Claude explains each step clearly. User executes. Wait for user confirmation between steps.

**Present this checklist:**

```
CCBot Setup Checklist
=====================

□ 1. Clone the repo
     git clone https://github.com/six-ddc/ccbot.git ~/ccbot && cd ~/ccbot

□ 2. Install dependencies
     uv sync

□ 3. Create Telegram bot
     → Open @BotFather in Telegram
     → Send /newbot
     → Pick a name and username (must end in "bot")
     → Save the token

□ 4. Get your Telegram user ID
     → Open @userinfobot in Telegram
     → Send /start
     → Save the number it gives you

□ 5. Configure .env
     cp .env.example .env
     → Edit .env:
       TELEGRAM_BOT_TOKEN=<your token from step 3>
       ALLOWED_USERS=<your ID from step 4>

□ 6. Install the Claude Code hook
     uv run ccbot hook --install

□ 7. Create Telegram Forum group
     → New Group in Telegram
     → Enable Topics in group settings
     → Add your bot as admin

□ 8. Enable Threaded Mode
     → Open @BotFather profile → Open App (mini app)
     → Select your bot → Settings → Bot Settings
     → Enable Threaded Mode

□ 9. Disable Group Privacy
     → @BotFather → /setprivacy → Select bot → Disable

□ 10. Start CCBot in tmux
      tmux new-session -d -s ccbot -n bot
      tmux send-keys -t ccbot:bot "cd ~/ccbot && uv run ccbot" Enter

□ 11. Test it
      → Open the Telegram group
      → Create a new topic
      → Send any message
      → Bot should show directory browser = success!
```

---

## Where to Run CCBot — Always-On Machine

CCBot needs a machine that's always on and connected to the internet. Options:

### Option 1: Your Old Laptop / Mac Mini (Recommended)

The cheapest and best option. Buy a used Mac Mini or repurpose an old laptop.

- **Used Mac Mini M2** on יד2: 1,500-2,500 ₪ (one-time cost)
- **Old laptop with a scratched screen**: Claude Code doesn't care about screens
- **Minimum specs**: 8GB RAM, any modern CPU
- **Ideal**: 16GB RAM — comfortably runs 5+ Claude Code sessions in parallel
- **RAM per session**: Claude Code uses ~300-500MB per session. With 16GB you can run 10+ sessions easily.

### Option 2: Linux VPS (Cheapest Ongoing)

For the adventurous. Claude Code runs perfectly on Linux.

| Provider | Specs | Price |
|---|---|---|
| **Hetzner CAX21** | 4 vCPU ARM, 8GB RAM | ~$8/month |
| **Hetzner CCX23** | 4 vCPU, 16GB RAM | ~$33/month |

**Setup on Linux VPS:**
```bash
# Install Claude Code
curl -fsSL https://cli.claude.ai/install.sh | sh

# Authenticate (headless — no browser needed)
export ANTHROPIC_API_KEY=your_key_here

# Install tmux + uv
apt install tmux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Then follow the regular CCBot setup
```

**Caveat**: VPS means no local GUI — you'll authenticate via API key instead of browser OAuth. For dangerously-skip-permissions on a VPS:
```
CLAUDE_COMMAND=claude --dangerously-skip-permissions
```

### Option 3: Cloud Mac (~$100/month)

If you want macOS in the cloud:

| Provider | Specs | Price |
|---|---|---|
| **Macly** | Mac Mini M4, 16GB RAM | $100/month |
| **MacStadium** | Mac Mini M2, 8GB RAM | $109/month |
| **MacStadium M4** | Mac Mini M4, 16GB RAM | $119/month |

**My take:** For $100/month you can buy a used Mac Mini in 15-25 months. Buy used. It pays for itself fast.

---

## FAQ: Why CCBot and Not Something Else?

### "What about Remote Control?"

Claude Code Remote Control (`/rc` or `claude remote-control`) lets you continue a session from your phone via claude.ai or the Claude app.

**Pros:**
- Built-in, no setup needed
- Secure — Anthropic's infrastructure
- Works from any browser or the Claude app

**Cons:**
- **One session at a time** — no multi-session
- **Terminal must stay open** — close the terminal and the session dies
- **10-minute network timeout** — if your internet drops for 10+ min, the session ends
- **No notifications** — you have to actively check, it doesn't come to you
- No Telegram integration

**Bottom line:** Great for quick access to a single session. Not for managing multiple agents 24/7.

### "What about OpenClaw?"

OpenClaw is a general-purpose AI assistant platform (250K+ GitHub stars). It connects to messaging apps (Telegram, WhatsApp, Discord) and can run Claude or GPT.

**Pros:**
- Huge ecosystem — 700+ skills
- Multi-platform (WhatsApp, Discord, Slack, etc.)
- Model-agnostic (Claude, GPT, Gemini, local models)

**Cons:**
- **Not Claude Code** — OpenClaw is a different agent. You lose CLAUDE.md, MCP servers, project context, tool permissions — everything that makes Claude Code powerful
- **Security nightmare** — 6 critical CVEs in 2 months, 341 malicious skills found in the marketplace, supply chain attacks
- **Complex setup** — Node.js 22+, Gateway server, API keys, skill configuration
- **Context fragmentation** — sessions across channels don't share context
- **Massive overkill** — you want to control Claude Code from your phone, not install a new operating system

**Bottom line:** OpenClaw is a different product for different people. If you want Claude Code specifically — with your skills, your CLAUDE.md, your MCP servers — CCBot is the answer.

### "Why not just SSH + tmux?"

You could SSH into your machine and `tmux attach`. That works.

**But CCBot gives you:**
- Telegram notifications when Claude asks a question or finishes a task — you don't have to keep checking
- Inline buttons for permissions — approve/reject with one tap
- `/screenshot` for visual terminal capture
- Topic-based multi-session — visual organization
- Voice messages (talk to Claude from your phone)
- Session history with pagination
- Directory browser to start new sessions from Telegram

SSH is a pipe. CCBot is a control center.

### "Do I need MCP servers?"

**No, and here's a secret: for CCBot it's actually better without them.**

MCP servers add memory overhead and complexity. Each MCP server is an additional process. On an always-on machine, that means more RAM and more things that can break.

Claude Code without MCP is lean — ~300MB per session. Add 3-4 MCP servers and you're looking at 500-800MB.

For a 24/7 CCBot setup, keep it simple:
- Install only the MCP servers you truly need
- Or run CCBot sessions without MCP entirely — Claude Code is extremely capable on its own with just the built-in tools

---

## Environment Variables Reference

| Variable | Required | Default | Description |
|---|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Yes | — | Bot token from @BotFather |
| `ALLOWED_USERS` | Yes | — | Comma-separated Telegram user IDs |
| `TMUX_SESSION_NAME` | No | `ccbot` | Name of the tmux session CCBot manages |
| `CLAUDE_COMMAND` | No | `claude` | Command to launch Claude Code in new windows |
| `MONITOR_POLL_INTERVAL` | No | `2.0` | How often (seconds) to poll session files |

## Troubleshooting

| Problem | Fix |
|---|---|
| `uv: command not found` | Install uv: `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| `tmux: command not found` | macOS: `brew install tmux` / Linux: `apt install tmux` |
| Bot doesn't respond in group | Check: bot is admin + Threaded Mode enabled + Group Privacy disabled |
| `TELEGRAM_BOT_TOKEN not set` | Check `.env` file exists in `~/ccbot/` with the token filled in |
| Hook not tracking sessions | Run `uv run ccbot hook --install` again, restart Claude Code |
| Bot can't see messages | @BotFather → `/setprivacy` → Select bot → Disable |
| High memory usage | Restart Claude Code sessions periodically. Known memory leak issues — ~300MB/session normally but can grow over time |

## How CCBot Works (Technical)

- CCBot does **NOT** use the Claude API. It operates on tmux — reading terminal output and sending keystrokes.
- The terminal remains the source of truth. You can always `tmux attach -t ccbot` and continue from your desktop.
- **1 Telegram topic = 1 tmux window = 1 Claude Code session.**
- Closing a topic kills the associated tmux window.
- The bot supports voice messages, `/esc` to interrupt, `/screenshot` for terminal capture, and forwarding any Claude Code slash command.
- Built by [ddc](https://github.com/six-ddc) — who built CCBot using CCBot.

## Available Commands

| Command | What it does |
|---|---|
| `/esc` | Stop Claude mid-action |
| `/screenshot` | Terminal screenshot as image |
| `/clear` | Clear session, start fresh |
| `/compact` | Compress conversation context |
| `/cost` | Show token usage |
| `/history` | Browse message history |
| Any `/command` | Forwarded directly to Claude Code |
