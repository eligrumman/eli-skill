---
name: eli
description: Eli — your Claude Code expert. Set up a cloud fleet of Claude Code agents you drive from your phone over SSH + Tailscale, plus tips, best practices, and opinions from someone who spends $1,000/month on Opus. Use when user says "eli", "eli help", "eli setup", "eli what do you think", "set up agents on a server", "run claude code from my phone", "התקן אייג'נטים בענן".
argument-hint: [setup|help|what do you think]
---

# eli — Your Claude Code Expert

By [Eli Groman](https://www.linkedin.com/in/eli-grumman-495b0636/) — Claude Code power user, $1,000+/month on Opus.

## What I Can Help With

- **Set up your agent fleet** — a cloud server running Claude Code agents you reach from your phone over SSH + Tailscale (the main feature)
- **Claude Code tips** — best practices from months of daily Opus usage
- **Skills & agents guidance** — how to structure `.claude/agents/*.md` subagents and persistent fleet agents
- **Setup recommendations** — servers, SSH hardening, permissions, MCP

## The Setup — in one line

> Phone (Termux) → `ssh mac` → `cd` into a project → `claude` → pick the relevant agent → keep working.

Three machines on one tailnet:

| Machine | Role |
|---|---|
| **Cloud server** (Hetzner) | Runs the agents 24/7. The real workhorse. |
| **Mac** (optional) | A second always-on box / dev machine, also on the tailnet. |
| **Android phone** (Termux) | Your remote control. SSH in from anywhere. |

Glued together by **Tailscale** (a zero-config private VPN), so every machine reaches every other by a stable private IP — no port-forwarding, no exposing SSH to the public internet.

All IPs, usernames, and hostnames below are placeholders: `<SERVER_IP>`, `<USER>`, `<TAILNET_IP>`. Swap in your own.

## First Interaction

When triggered with "setup", confirm the plan and walk the user through the six steps below in order. Ask which machines they have (server? Mac? just a phone?) and adapt — the Mac is optional; the server and phone are the core. Wait for confirmation between steps that require the user to act (creating the server, pasting keys, logging into Tailscale).

## Prerequisites

- **Claude Code Max subscription** (required for Opus)
- **A cloud provider account** (Hetzner recommended) — or any always-on machine you already own
- **A Tailscale account** (free tier is plenty)
- **An Android phone with Termux** installed

## Step 1 — Provision the server (Hetzner Cloud)

1. Make a [Hetzner Cloud](https://www.hetzner.com/cloud) account → new project → **Add Server**.
2. Recommended box: **CX43** — 4 vCPU, 16 GB RAM, 160 GB SSD, ~$14/month. Comfortably runs 3+ concurrent Claude Code agents. (Smaller CX-series works for 1–2 agents; more RAM = more parallel agents.)
3. **Image:** Ubuntu 24.04 LTS.
4. **SSH key:** paste your phone's *and* your Mac's public key here now (see Step 2) so you can log in without a password. You can add keys later too.
5. Create. Note the **public IPv4** — that's your `<SERVER_IP>`.

Hetzner requires identity verification before you can create servers — upload a passport or national ID via their verification page. Takes a few hours. Do it first.

First login and hardening:
```bash
ssh root@<SERVER_IP>

# Create a non-root user you'll actually work as
adduser <USER>
usermod -aG sudo <USER>

# Copy your SSH key to the new user
rsync --archive --chown=<USER>:<USER> ~/.ssh /home/<USER>

# Disable root SSH login and (once keys work) password login
# in /etc/ssh/sshd_config set:  PermitRootLogin no
#                               PasswordAuthentication no
sudo systemctl restart ssh

# Basic firewall
ufw allow OpenSSH
ufw enable
```

Before logging out of root, open a new terminal and confirm the new user works: `ssh <USER>@<SERVER_IP>` then `sudo whoami` should print `root`.

## Step 2 — SSH keys (phone + Mac → server)

The rule: **your private key never leaves the device; you copy the *public* key to the server.**

**On the phone (Termux):**
```bash
pkg install openssh          # first time only
ssh-keygen -t ed25519        # accept defaults; set a passphrase if you like
cat ~/.ssh/id_ed25519.pub    # copy this line
```

**On the Mac:**
```bash
ssh-keygen -t ed25519        # if you don't already have one
cat ~/.ssh/id_ed25519.pub    # copy this line too
```

**On the server**, add both public keys:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # paste each pubkey on its own line
chmod 600 ~/.ssh/authorized_keys
```

If your Mac and server should also SSH to each other, repeat: generate a key on the Mac, add its pubkey to the server (and vice-versa).

## Step 3 — Tailscale (reach the server from anywhere)

Public IPs change and expose you; Tailscale gives every machine a stable private IP on your own tailnet.

**On the server:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# open the printed URL, log in → the server joins your tailnet
tailscale ip -4    # note this -> <TAILNET_IP> for the server
```

**On the Mac:** install the Tailscale app (or `brew install tailscale`), log in with the same account.

**On the phone:** install **Tailscale** from the Play Store, log in with the same account, toggle it **on**.

Now every device reaches the server at `<TAILNET_IP>` regardless of network. Notes from experience:
- The tailnet IP only resolves when Tailscale is **up** on both ends. If it's flaky, keep the public `<SERVER_IP>` as a fallback.
- Want the box reachable by name? Enable **MagicDNS** in the Tailscale admin console.

## Step 4 — Termux "mac" shortcut (phone-side ergonomics)

The trick that makes this fast: a named SSH host so you type `ssh mac` instead of a full command.

In Termux, edit `~/.ssh/config`:
```
Host mac
    HostName <TAILNET_IP>        # or <SERVER_IP> as fallback
    User <USER>
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60       # keeps the session from dropping on mobile
    ServerAliveCountMax 3
```

Now from the phone: `ssh mac` → you're on the server. (Name it whatever you want — "mac", "server", "fleet".)

Optional quality-of-life on Termux:
- `pkg install openssh mosh` — **mosh** survives network changes / spotty signal far better than raw SSH for mobile use.
- Termux widgets let you put a one-tap `ssh mac` button on your home screen.

## Step 5 — Install Claude Code on the server

```bash
# Node (Claude Code ships as an npm package)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# uv (fast Python package manager — handy for agent projects)
curl -LsSf https://astral.sh/uv/install.sh | sh

claude          # first run walks you through login/auth
```

Auth once and it persists on the server. From then on every SSH session can just run `claude`.

## Step 6 — How the agents actually work

An "agent" here isn't a special server; it's a **project folder plus a role definition**. Two styles.

### Style A — Subagent as a markdown file

Inside a project you drop role files in `.claude/agents/*.md`. Each is markdown with YAML frontmatter; the body is that agent's full operating manual (persona, exact commands, rules). Example (`.claude/agents/qa.md`):
```markdown
---
name: qa
description: MANDATORY browser-based QA verifier. Use BEFORE any claim that a UI feature works.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are the QA verifier. Open the real page in Chrome, screenshot it,
read the console, and report only observed facts — never "should work".
...full operating manual...
```
Claude Code surfaces it in the agent picker, and the main session spawns it on demand. Great for on-demand roles (a QA checker, a reviewer).

### Style B — Persistent fleet agent (job + skill + prompt)

For always-on workers, each agent is a long-running **Claude Code background job** whose:
- **identity** comes from its own `state.json` (it reads this first every session to learn its name),
- **behavior** comes from a same-named **skill** in `.claude/skills/<agent-name>/` (its operating manual, including its `/loop` interval, e.g. `/loop 15m`),
- **mission** comes from a canonical prompt line in a shared control file (e.g. `agent_prompts.txt`).

On startup each agent: reads `state.json` → looks up its mission → loads *only its own* skill → confirms its `/loop` is running → then acts **only within its domain**, prefixing commits with `[agent-name]` and escalating anything out-of-domain rather than fixing it.

### The project layout that ties it together

```
project/
├── CLAUDE.md                     # the "constitution": binding rules for every agent
├── .claude/
│   ├── agents/*.md               # Style-A subagents (e.g. qa.md)
│   ├── skills/<agent>/           # Style-B operating manuals, one per fleet agent
│   ├── settings.json             # permissions allowlist + force-push denylist
│   └── worktrees/                # each agent works in an isolated git worktree
├── docs/ops/                     # runbooks, fleet-constitution.md, incident logs
└── <domain code>/                # the actual thing the agents operate
```

Key discipline that keeps a fleet sane:
- **`CLAUDE.md` is binding**, not decorative — it's the operating contract for the human *and* every agent.
- **Separation of duties:** a coordinator agent never patches domain logic; a domain failure = a not-good-enough prompt/skill/loop, fixed *there*.
- **Single source of truth:** one manifest / prompt file; missions read verbatim, never copied.
- **Isolated worktrees:** agents edit in their own `git worktree` so they don't collide.
- **Permissions as guardrails:** `settings.json` allowlists safe commands and denies every force-push variant.

## A Day in the Life

```bash
# from the phone, anywhere
ssh mac

# jump into the project I want to work on
cd ~/investor

# start Claude Code — it loads CLAUDE.md + available agents automatically
claude

# then, in the session:
#   - pick the relevant agent from the picker, or
#   - let the main session delegate to subagents, or
#   - check on the always-on fleet jobs and steer them
```

That's it. The agents keep running on the server whether or not the phone is connected; SSH is just the window you look through. Disconnect the phone, the work continues; reconnect later, pick up where it left off.

## Recap Checklist

- [ ] Hetzner CX43, Ubuntu 24.04, non-root sudo user
- [ ] ed25519 keypair on phone (Termux) **and** Mac; both pubkeys in server `~/.ssh/authorized_keys`
- [ ] Tailscale installed + logged in on server, Mac, and phone (same account)
- [ ] `~/.ssh/config` `Host mac` shortcut in Termux (tailnet IP, keepalive)
- [ ] Node + Claude Code CLI + uv installed on server; `claude` authed once
- [ ] Per-project `CLAUDE.md`, `.claude/agents/*.md`, and/or `.claude/skills/<agent>/` defining each agent
- [ ] `ssh mac` → `cd project` → `claude` → work

**If the server is a Mac, also:**
- [ ] Plugged into AC power; `pmset` no-sleep config set
- [ ] Screen Sharing enabled; reachable at `vnc://<TAILNET_IP>`
- [ ] Restart-after-power-failure on; automatic login on

## Choosing Your Machine: Mac vs Hetzner

Decide where the agents live before provisioning. Two honest options:

| | **Mac** (old MacBook / Mac Mini you own) | **Hetzner** (Linux cloud server) |
|---|---|---|
| Cost | **Free** — your own hardware, no monthly bill | ~$15/month |
| Uptime | Depends on your home network + power; you keep it alive | Built for uptime: higher speed, better stability, independent of your home network |
| Best for | Mac-only apps that don't exist on Linux; a GUI/browser on the box | Always-on loops / agents that must never go down and shouldn't depend on your house's internet or power |

**Both are valid, and many people run both:** Linux/Hetzner for the always-up fleet, a Mac for GUI/browser/Mac-app work. Pick based on what you need.

**Which should I pick?** Want a set-and-forget, always-on fleet that never depends on your home? Go **Hetzner**. Already own a Mac and want a free box you can also see the screen of (GUI, browser, Mac apps)? Run it on the **Mac** — just keep it plugged in and awake (see below).

## Running the Server on a Mac

If the always-on box is a Mac (an old MacBook or a Mac Mini) instead of — or alongside — a cloud server, a few Mac-specific things keep it reliable. Everything else (SSH keys, Tailscale, the `ssh mac` shortcut, installing Claude Code) is the same; on macOS use `brew install` where the Ubuntu steps use `apt`.

### a) Keep it powered
A laptop acting as a server must stay **plugged into AC power at all times** — always on the charger. Never run it on battery as a server: the battery drains, the machine sleeps or dies, and your fleet goes with it.

### b) Never let it sleep
Set power management so the Mac never sleeps:

```
sudo pmset -a sleep 0 displaysleep 0 disksleep 0 womp 1 ttyskeepawake 1 tcpkeepalive 1 powernap 1 standby 1
```

Key flags: `sleep 0` = never system-sleep; `displaysleep 0` = display never sleeps; `disksleep 0` = disks stay spun up; `womp 1` = wake for network access (Wake-on-LAN / magic packet); `ttyskeepawake 1` = stays awake while a remote SSH/tty session is active; `tcpkeepalive 1` = keeps TCP connections alive during low-power; `powernap 1` / `standby 1` = background tasks keep running.

For a one-off, scriptable "stay awake for this task," use `caffeinate` — e.g. `caffeinate -dimsu claude ...` holds the Mac awake for as long as that command runs. A live SSH session already asserts wake via `ttyskeepawake`, so day-to-day you rarely need it.

**MacBook with the lid closed (clamshell):** `sudo pmset -a disablesleep 1` lets a MacBook keep running with the lid shut even without an external display. It disables clamshell sleep entirely, so use it deliberately — leaving the lid open is the simpler, cooler-running option.

### c) See the screen remotely — Screen Sharing (VNC) over Tailscale
SSH + Claude is your day-to-day. But sometimes you need the actual desktop: a browser login, a GUI app, a stuck dialog. Screen Sharing is that escape hatch.

- On the Mac server: **System Settings → General → Sharing → enable Screen Sharing** (or **Remote Management**). It serves VNC on port **5900**.
- Because the Mac is on your tailnet, you can reach that screen from **anywhere**, not just the LAN.
- From another Mac: Finder → **Go → Connect to Server** (**⌘K / Cmd + K**) → enter `vnc://<TAILNET_IP>` → log in with the Mac's user. You now see and control the desktop.

SSH + Claude is how you work every day; Screen Sharing is how you take the wheel when an agent needs a browser, hits a GUI prompt, or something visual breaks.

### d) Recovery after reboot / power outage
Set the Mac to come back on its own, then relaunch agents by hand:

- **Start up automatically after a power failure:** `sudo systemsetup -setrestartpowerfailure on` (or System Settings → Energy).
- **Automatic login** for your user (System Settings → Users & Groups → Automatically log in as…) so the Mac returns to a logged-in desktop that SSH and Screen Sharing can reach without someone typing a password at the keyboard.
- After it's back up, **SSH in and relaunch your agents by hand**: `ssh mac` → `cd project` → `claude` (or restart your background jobs). Keep it simple — no launchd auto-relaunch needed.

## Where to Run — Always-On Machine

You need a machine that's always on and connected. Options:

### Option 1: Hetzner Cloud (Recommended)

Cheapest for what you get, EU-based, reliable.

| Type | Specs | Price |
|---|---|---|
| **CX22** | 4 vCPU, 8 GB RAM | ~$8/month (1–2 agents) |
| **CX43** | 4 vCPU, 16 GB RAM, 160 GB SSD | ~$14/month (3+ agents) |

Claude Code uses ~300–500 MB per session. More RAM = more parallel agents.

### Option 2: An old laptop / Mac Mini you already own

Repurpose what's lying around. A used Mac Mini or an old laptop with a scratched screen — Claude Code doesn't care about screens. Minimum 8 GB RAM; 16 GB runs 10+ sessions. One-time cost, no monthly bill. Put it on Tailscale and reach it exactly the same way (`ssh mac`) — see "Running the Server on a Mac" above for keeping it awake and reachable.

## FAQ

### "Isn't exposing SSH dangerous?"

You don't expose it. With Tailscale the server is reachable only by devices on your own tailnet — the public internet never sees the SSH port. Add key-only auth (disable password login), disable root login, enable `ufw`, and keep the public `<SERVER_IP>` as a fallback only.

### "What about Claude Code Remote Control?"

Remote Control lets you continue a *single* session from your phone via claude.ai or the Claude app. Built-in, secure, zero setup — great for a quick check-in. But: one session at a time, the terminal must stay open, a ~10-minute network drop ends it, and no parallel agents. This server setup is for running and steering *multiple* agents 24/7.

### "Do I need MCP servers?"

No — and for an always-on setup it's often better without them. Each MCP server adds ~200–300 MB and another process that can break. Claude Code without MCP is lean at ~300 MB/session. Install only what you truly need, or skip MCP entirely — Claude Code is extremely capable with just its built-in tools.

## Troubleshooting

| Problem | Fix |
|---|---|
| `ssh mac` hangs / can't connect | Is Tailscale **up** on both phone and server? Try the public `<SERVER_IP>` as fallback. |
| Session drops on mobile | Use `mosh mac` instead of `ssh mac`; add `ServerAliveInterval 60` to `~/.ssh/config`. |
| `claude: command not found` | Re-run the Node + `npm install -g @anthropic-ai/claude-code` steps on the server. |
| `uv: command not found` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Permission denied (publickey) | Confirm your device's `id_ed25519.pub` is in the server's `~/.ssh/authorized_keys`. |
| Tailnet IP won't resolve by name | Enable **MagicDNS** in the Tailscale admin console. |
