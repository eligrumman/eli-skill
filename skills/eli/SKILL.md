---
name: eli
description: Eli — your Claude Code expert. Set up a cloud fleet of Claude Code agents you drive from your phone over SSH + Tailscale, plus tips and best practices from an Agentic AI Team Lead who runs autonomous Claude Code agents daily. Use when user says "eli", "eli walk me", "eli help", "eli what do you think", "set up agents on a server", "run claude code from my phone", "התקן אייג'נטים בענן".
argument-hint: [setup|help|what do you think]
---

# eli — Your Claude Code Expert

By [Eli Grumman](https://www.linkedin.com/in/eli-grumman-495b0636/) — an expert with Claude Code from its early days, building and running autonomous agents locally and in the cloud; Agentic AI Team Lead at Axonius.

## What I Can Help With

- **Set up your agent fleet** — a cloud server running Claude Code agents you reach from your phone over SSH + Tailscale (the main feature)
- **Claude Code tips** — best practices from using Claude Code daily since its early days
- **Skills & agents guidance** — how to structure `.claude/agents/*.md` subagents and persistent fleet agents
- **Setup recommendations** — servers, SSH hardening, permissions, MCP

## The Setup — in one line

> Phone (Termux) → `ssh mac` → `claude agents` → one screen with every session across all your projects → attach to the one you want and keep working.

Three machines on one tailnet:

| Machine | Role |
|---|---|
| **Cloud server** (Hetzner) | Runs the agents 24/7. The real workhorse. |
| **Mac** (optional) | A second always-on box / dev machine, also on the tailnet. |
| **Android phone** (Termux) | Your remote control. SSH in from anywhere. |

Glued together by **Tailscale** (a zero-config private VPN), so every machine reaches every other by a stable private IP — no port-forwarding, no exposing SSH to the public internet.

All IPs, usernames, and hostnames below are placeholders: `<SERVER_IP>`, `<USER>`, `<TAILNET_IP>`. Swap in your own.

**New to all this? Plain-language glossary** (this guide assumes you know Claude Code and nothing else):
- **Server** — a computer that runs 24/7 so agents never stop: a **Mac you own** (plugged in, awake) or one you **rent from Hetzner** (a datacenter-computer rental company, a few $/month).
- **Terminal / command line** — a text window where you type commands instead of clicking.
- **SSH (Secure Shell)** — the encrypted way to open a command line *on another computer* over the internet. `ssh mac` = "open a command line on my server."
- **SSH client app** — the app you run SSH from: **Android → Termux**, **iPhone → Termius** (details in Step 2).
- **SSH key (public / private)** — a passwordless login: a **key pair** whose **private** half stays secret on your device and **public** half is copied to the server. Never share the private key.
- **Tailscale / VPN** — a private network that lets your phone reach your server from anywhere without exposing it to the public internet (Step 3).
- **Tailnet** — your own private network of Tailscale devices: everything signed into the same Tailscale account, reachable by its `100.x.y.z` address.
- **VNC / Screen Sharing** — viewing/controlling the server's real desktop remotely, for when a command line isn't enough (browser login, GUI app).
- **`claude agents`** — the Claude Code command showing *all* your sessions, across every project, in one screen. Your daily entry point.

## First Interaction

When triggered with "walk me" (or "setup"/"help"), confirm the plan and walk the user through the six steps below in order. **First ask where to run their agents** — an old MacBook they already own, a Mac Mini, or a cloud server (Hetzner, from ~€6.80/mo ≈ $7.50 up to ~€16.40/mo ≈ $18) — tying it to "Choosing Your Machine: Mac vs Hetzner" below, then adapt (the Mac is optional; the server and phone are the core). A good opener: "First I'll ask where to run your agents — an old MacBook, a Mac Mini, or a cloud server — then walk you through the rest." Wait for confirmation between steps that require the user to act (creating the server, pasting keys, logging into Tailscale).

## Prerequisites

- **A Claude Code subscription** (Pro or Max)
- **A cloud provider account** (Hetzner recommended) — or any always-on machine you already own
- **A Tailscale account** (free tier is plenty)
- **A phone with an SSH client app** — Android → Termux (or Termius); iPhone → Termius

## Step 1 — Provision the server (Hetzner Cloud)

> **Do these two things first:** (1) Hetzner requires identity verification before you can create servers — upload a passport or national ID via their verification page. It can take a few hours, so start it now. (2) The creation screen asks you to paste an SSH **public key** — so jump to Step 2, generate your keys, then come back. (The key you paste at creation is installed for the **root** user; the manual `authorized_keys` step in Step 2 is for the non-root user you create below, or for adding more keys later.)

1. Make a [Hetzner Cloud](https://www.hetzner.com/cloud) account → new project → **Add Server**.
2. Recommended box: **CX42** — 8 vCPU, 16 GB RAM, 160 GB SSD, ~€16.40/month (≈ $18). Comfortably runs **30+** concurrent Claude Code sessions. (The cheaper entry box **CX32** — 4 vCPU, 8 GB RAM, 80 GB SSD, ~€6.80/month ≈ $7.50 — runs **~10–20**.) The Hetzner CX line is CX22 / CX32 / CX42 / CX52. RAM is almost never the real limit — see "Where to Run" below.
3. **Image:** Ubuntu 24.04 LTS.
4. **SSH key:** paste your phone's *and* your Mac's public key here now (see Step 2) so you can log in without a password. You can add keys later too.
5. Create. Note the **public IPv4** — that's your `<SERVER_IP>`.

First login and hardening:
```bash
ssh root@<SERVER_IP>

# Create a non-root user you'll actually work as
adduser <USER>
usermod -aG sudo <USER>

# Copy your SSH key to the new user
rsync --archive --chown=<USER>:<USER> ~/.ssh /home/<USER>

# Basic firewall
ufw allow OpenSSH
ufw enable

# Automatic security updates (recommended for an always-on box)
sudo apt install -y unattended-upgrades
```

Note: that `rsync` line copies **root's** `authorized_keys` to the new `<USER>` **before** we disable root login below — that's exactly why the SSH key you already use keeps working after root login is turned off. Don't skip it.

**Disable root login and password auth — the Ubuntu 24.04 gotcha.** Editing only `/etc/ssh/sshd_config` does **not** work on Hetzner's image: it ships `/etc/ssh/sshd_config.d/50-cloud-init.conf` with `PasswordAuthentication yes`, and that drop-in overrides the main file. Add your own drop-in that wins (files load in order, so `99-` beats `50-`):
```bash
sudo tee /etc/ssh/sshd_config.d/99-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
EOF
sudo systemctl restart ssh
```

> ⚠️ **Before you close your root session, verify key-only login works in a SECOND terminal:** `ssh <USER>@<SERVER_IP>` then `sudo whoami` should print `root`. Only once that new session works should you log out of root — otherwise a typo can lock you out of the box entirely.

## Step 2 — SSH keys (phone + Mac → server)

**First, the app you type into on your phone.** SSH needs a *client app*. **Android → Termux** — a free Linux terminal app for Android; download from [Google Play](https://play.google.com/store/apps/details?id=com.termux) — also available on [F-Droid](https://f-droid.org/packages/com.termux/) and [GitHub releases](https://github.com/termux/termux-app/releases). **iPhone → [Termius](https://apps.apple.com/app/termius-ssh-client/id549039908)** — a friendly-GUI SSH client (iOS/Android/Mac/Windows); you save the server as a connection and tap to connect. So: **Android → Termux (or Termius); iPhone → Termius.** Commands below are shown for Termux; in Termius enter the same keys/host through its GUI.

The rule: **your private key (the secret half of your login) never leaves the device; you copy the *public* key to the server.**

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

**On iPhone (Termius) — the key sub-flow:** Termius has no command line, so you make the key in its GUI. Open **Termius → Keychain → + (New Key) → Generate**, pick **Ed25519**, save it. Tap the key → **Copy Public Key** (that's the half that goes on the server). Then **Hosts → + (New Host)**, set **Address** to your `<TAILNET_IP>` (or `<SERVER_IP>` at first), **Username** to `<USER>`, and under **Keys** attach the key you just made. Tap the host to connect.

**On the server**, add both public keys:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # paste each pubkey on its own line
chmod 600 ~/.ssh/authorized_keys
```

**One-command alternative — `ssh-copy-id`.** This only works while password login is still enabled, so **do it before you disable password auth in Step 1** (`ssh-copy-id` needs to log in with a password to install the key). From your Mac or Termux you can install a pubkey in one shot instead of editing `authorized_keys` by hand:
```bash
ssh-copy-id <USER>@<SERVER_IP>
```

If your Mac and server should also SSH to each other, repeat: generate a key on the Mac, add its pubkey to the server (and vice-versa).

## Step 3 — Tailscale (reach the server from anywhere)

Public IPs change and expose you; Tailscale gives every machine a stable private IP on your own tailnet.

**What is Tailscale?** A free app that links your own devices — phone, Mac, server — over a private, secure connection, as if they were all on the same home Wi-Fi, even when they're in different places. Install it on each device and sign in with the **same account**. Each device gets its own **private address** (it looks like `100.x.y.z`) that only your other devices can reach, so your phone connects to your server from **anywhere** — café Wi-Fi, mobile data — **without touching your router settings and without putting your server on the public internet**. Turn on **MagicDNS** to use an easy name like `mac` instead of the number.

**On the server:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# open the printed URL, log in → the server joins your tailnet
tailscale ip -4    # note this -> <TAILNET_IP> for the server
```

**On the Mac:** install the Tailscale app (or `brew install --cask tailscale` — the GUI menu-bar app, which is what you want on a Mac), log in with the same account.

**On the phone:** install **Tailscale** from the Play Store, log in with the same account, toggle it **on**.

Now every device reaches the server at `<TAILNET_IP>` regardless of network. Notes from experience:
- The tailnet IP only resolves when Tailscale is **up** on both ends. If it's flaky, keep the public `<SERVER_IP>` as a fallback.
- Want the box reachable by name? Enable **MagicDNS** in the Tailscale admin console.

### Tailscale pitfalls & common newbie mistakes

**General**
- **Same account on every device** — the #1 mistake is the server on one Tailscale account and the phone on another, so they can't see each other. All devices on the same tailnet (or explicitly shared in).
- **Toggled ON at both ends** at connect time. If `ssh mac` hangs, check Tailscale is actually up on the phone **and** the server.
- **Key expiry** — by default a device's key expires (~180 days) and it silently drops off the tailnet until you re-auth. For an always-on server, **disable key expiry** for that machine in the admin console.
- Use the `100.x` IP directly, or **MagicDNS** for names; keep the **public IP as a fallback**.

**Linux server:** `sudo tailscale up`; make sure it auto-starts (`sudo systemctl enable --now tailscaled`). Headless auth → it prints a login URL to open on another device, or use `sudo tailscale up --authkey tskey-...`. Don't firewall the `tailscale0` interface. (`tailscale up --ssh` is optional and not needed with key-based SSH.)

**Mac:** prefer the **standalone / open-source** build (`brew install --cask tailscale`) over the Mac App Store app so you get the `tailscale` CLI. Approve the **VPN / network-extension permission prompt** on first launch (needs the screen once). Ensure it **launches at login**, and don't leave **"Use exit node"** on.

**Mobile (Android):** Tailscale is a **separate app** from Termux — install, log in, toggle ON. **Exclude it from battery optimization** so the VPN survives in the background. **After a phone reboot it may come back OFF** — the toggle often reverts, so `ssh mac` hangs until you reopen Tailscale and turn it on; enable **"Connect on start / run on boot"** in the app settings. Rule of thumb: can't reach the server right after a phone restart? Check Tailscale is ON first. Leave Android **"Always-on VPN"** off; if a name won't resolve, toggle Tailscale off/on or fall back to the public IP (captive-portal Wi-Fi).

**Debugging (any platform):** `tailscale status` (peers + direct-vs-relayed), `tailscale ping <host>`, `tailscale netcheck` (NAT/relay diagnosis).

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
- `pkg install openssh mosh` — **mosh** survives network changes / spotty signal far better than raw SSH for mobile use. Over Tailscale it just works; if you ever fall back to the public IP with `ufw` on, open UDP **60000–61000** (`sudo ufw allow 60000:61000/udp`).
- Termux widgets let you put a one-tap `ssh mac` button on your home screen.

## Step 5 — Install Claude Code on the server

Primary method — the **native installer** (no Node, no sudo):
```bash
curl -fsSL https://claude.ai/install.sh | bash

# uv (fast Python package manager — handy for agent projects)
curl -LsSf https://astral.sh/uv/install.sh | sh

claude          # first run walks you through login/auth
```

Fallback — via **npm** (needs Node):
```bash
# Node
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Claude Code CLI
npm install -g @anthropic-ai/claude-code
```

If you use the npm route instead, **don't use `sudo`** — either use the native installer above, or configure an npm user prefix so global installs don't need root (see Anthropic's install docs).

**Headless login.** On a server with no browser, `claude` prints a **login URL** — open it on your phone or laptop browser, approve, and the token persists on the server. From then on every SSH session can just run `claude`. This requires an active **Claude Pro, Max, Team, Enterprise, or Console** subscription on that account.

## Your Control Center — `claude agents` (agent view)

`claude agents` opens **agent view**: one screen listing every background session you've started, grouped by state (**Needs input** / **Working** / **Completed** / **Pinned**). Make this the primary entry point instead of plain `claude`. Read the official [`claude agents` / agent view docs](https://code.claude.com/docs/en/agent-view) for full detail.

- **All projects at once** by default, regardless of launch directory. Narrow with `claude agents --cwd ~/projects/my-app`.
- **Dispatch:** type a prompt + `Enter` → a new background session starts as a row. Each `Enter` = a separate session, so run several in parallel.
- **Peek:** select a row + `Space` to see its latest output or the question it's waiting on; reply inline with `Enter`.
- **Attach:** `Enter` or `→`; **detach:** `←` on an empty prompt (or `Esc`).
- **Bring an existing session in:** `/bg` inside a normal `claude` session (or press `←`).
- **Survives disconnects:** each session keeps running **without a terminal attached** — close Termux/Termius or drop signal and the agents keep working; reopen `claude agents` later and they're all there. This is why disconnecting doesn't kill your work.
- **Quota, not RAM, is the limit:** each session uses your Claude subscription quota **independently**.
- **Research preview** — keyboard shortcuts may change.

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

# open agent view — every session across all projects, in one screen
claude agents

# then, right there:
#   - type a prompt + Enter to dispatch a new background session
#   - Space to peek at what a session is doing or asking
#   - Enter / → to attach and steer; ← or Esc to detach
#   - jump straight to one project:  claude agents --cwd ~/investor
```

That's it. The agents keep running on the server whether or not the phone is connected; agent view is just the window you look through. Disconnect the phone, the work continues; reopen `claude agents` later, everything's still there.

## Recap Checklist

- [ ] Hetzner CX42 (or CX32), Ubuntu 24.04, non-root sudo user
- [ ] SSH hardened: `99-hardening.conf` drop-in with `PasswordAuthentication no` + `PermitRootLogin no`, verified in a second terminal before logging out of root
- [ ] ed25519 keypair on phone (Termux) **and** Mac; both pubkeys in server `~/.ssh/authorized_keys`
- [ ] Tailscale installed + logged in on server, Mac, and phone — **same account on all devices**
- [ ] Tailscale **key expiry disabled** for the always-on server (so it never silently drops off the tailnet)
- [ ] On the phone: Tailscale excluded from **battery optimization** + **"Connect on start / run on boot"** enabled
- [ ] `~/.ssh/config` `Host mac` shortcut in Termux/Termius (tailnet IP, keepalive)
- [ ] Node + Claude Code CLI + uv installed on server; `claude` authed once
- [ ] Per-project `CLAUDE.md`, `.claude/agents/*.md`, and/or `.claude/skills/<agent>/` defining each agent
- [ ] `ssh mac` → `claude agents` → attach to a session → work

**If the server is a Mac, also:**
- [ ] Remote Login (SSH) turned on, restricted to your user
- [ ] Plugged into AC power; `pmset` no-sleep config set
- [ ] Screen Sharing enabled; reachable at `vnc://<TAILNET_IP>`
- [ ] Restart-after-power-failure on (if supported on your model); automatic login on (not with FileVault)

## Verify It Works — end-to-end smoke test

Run this once, in order, to prove the whole chain is live:

1. **Tailscale:** on the phone, `tailscale status` (or check the app) shows all peers — server, Mac, phone — connected.
2. **SSH with no password:** `ssh mac` connects straight to a shell with **no password prompt** (key auth working).
3. **Claude installed:** on the server, `claude --version` prints a version.
4. **Agent view opens:** `claude agents` opens the agent view screen.
5. **Survives a reboot:** reboot the phone, reopen Tailscale, confirm it reconnects and `ssh mac` still works. (If it hangs, Tailscale came back OFF — that's the #1 cause.)

If all five pass, you're done.

## Choosing Your Machine: Mac vs Hetzner

Decide where the agents live before provisioning. Two honest options:

| | **Mac** (old MacBook / Mac Mini you own) | **Hetzner** (Linux cloud server) |
|---|---|---|
| Cost | **Free** — your own hardware, no monthly bill | from ~€6.80/mo (≈ $7.50) up to ~€16.40/mo (≈ $18) |
| Uptime | Depends on your home network + power; you keep it alive | Built for uptime: higher speed, better stability, independent of your home network |
| Best for | Mac-only apps that don't exist on Linux; a GUI/browser on the box | Always-on loops / agents that must never go down and shouldn't depend on your house's internet or power |

**Both are valid, and many people run both:** Linux/Hetzner for the always-up fleet, a Mac for GUI/browser/Mac-app work. Pick based on what you need.

**Which should I pick?** Want a set-and-forget, always-on fleet that never depends on your home? Go **Hetzner**. Already own a Mac and want a free box you can also see the screen of (GUI, browser, Mac apps)? Run it on the **Mac** — just turn on Remote Login and keep it plugged in and awake (see below).

## Running the Server on a Mac

If the always-on box is a Mac (an old MacBook or a Mac Mini) instead of — or alongside — a cloud server, a few Mac-specific things keep it reliable. Everything else (SSH keys, Tailscale, the `ssh mac` shortcut, installing Claude Code) is the same; on macOS use `brew install` where the Ubuntu steps use `apt` (install [Homebrew](https://brew.sh) first if you don't have it, then `brew install node` only if you take the npm route to Claude Code).

### a) Turn on Remote Login (do this first)
macOS ships with its SSH server **off**, so `ssh mac` fails until you enable it: **System Settings → General → Sharing → Remote Login → On**, and restrict it to your user. Your Mac's `~/.ssh/authorized_keys` then takes your pasted public key exactly the way a Linux server does — same file, same `chmod 700 ~/.ssh` / `chmod 600 authorized_keys`.

### b) Keep it powered
A laptop acting as a server must stay **plugged into AC power at all times** — always on the charger. Never run it on battery as a server: the battery drains, the machine sleeps or dies, and your fleet goes with it.

### c) Never let it sleep
Set power management so the Mac never sleeps:

```
sudo pmset -a sleep 0 displaysleep 0 disksleep 0 womp 1 ttyskeepawake 1 tcpkeepalive 1 powernap 1 standby 1
```

Key flags: `sleep 0` = never system-sleep; `displaysleep 0` = display never sleeps; `disksleep 0` = disks stay spun up; `womp 1` = wake for network access (Wake-on-LAN / magic packet); `ttyskeepawake 1` = stays awake while a remote SSH/tty session is active; `tcpkeepalive 1` = keeps TCP connections alive during low-power; `powernap 1` / `standby 1` = background tasks keep running.

For a one-off, scriptable "stay awake for this task," use `caffeinate` — e.g. `caffeinate -dimsu claude ...` holds the Mac awake for as long as that command runs. A live SSH session already asserts wake via `ttyskeepawake`, so day-to-day you rarely need it.

**MacBook with the lid closed (clamshell):** `sudo pmset -a disablesleep 1` lets a MacBook keep running with the lid shut even without an external display. It disables clamshell sleep entirely, so use it deliberately — leaving the lid open is the simpler, cooler-running option.

### d) See the screen remotely — Screen Sharing (VNC) over Tailscale
SSH + Claude is your day-to-day. But sometimes you need the actual desktop: a browser login, a GUI app, a stuck dialog. Screen Sharing is that escape hatch.

- On the Mac server: **System Settings → General → Sharing → enable Screen Sharing** (or **Remote Management**). It serves VNC on port **5900**.
- Because the Mac is on your tailnet, you can reach that screen from **anywhere**, not just the LAN.
- From another Mac: Finder → **Go → Connect to Server** (**⌘K / Cmd + K**) → enter `vnc://<TAILNET_IP>` → log in with the Mac's user. You now see and control the desktop.

SSH + Claude is how you work every day; Screen Sharing is how you take the wheel when an agent needs a browser, hits a GUI prompt, or something visual breaks.

### e) Recovery after reboot / power outage
Set the Mac to come back on its own, then relaunch agents by hand:

- **Start up automatically after a power failure:** `sudo systemsetup -setrestartpowerfailure on` (or System Settings → Energy). This is only supported on some Mac models — it errors on many MacBooks, which is fine; just skip it there.
- **Automatic login** for your user (System Settings → Users & Groups → Automatically log in as…) so the Mac returns to a logged-in desktop that SSH and Screen Sharing can reach without someone typing a password at the keyboard. Note: **FileVault silently disables auto-login** — you can have one or the other, not both, so leave FileVault off on a headless server box.
- After it's back up, **SSH in and relaunch your agents by hand**: `ssh mac` → `cd project` → `claude` (or restart your background jobs). Keep it simple — no launchd auto-relaunch needed.

## Where to Run — Always-On Machine

You need a machine that's always on and connected. Options:

### Option 1: Hetzner Cloud (Recommended)

Cheapest for what you get, EU-based, reliable.

| Type | Specs | Price |
|---|---|---|
| **CX32** | 4 vCPU, 8 GB RAM, 80 GB SSD | ~€6.80/mo (≈ $7.50) — cheaper entry box (~10–20 sessions) |
| **CX42** | 8 vCPU, 16 GB RAM, 160 GB SSD | ~€16.40/mo (≈ $18) — recommended, runs 30+ sessions |

(The Hetzner CX line is CX22 / CX32 / CX42 / CX52.)

An idle Claude Code session is ~50–150 MB; a hard-working one a few hundred MB (measured median ~320 MB, average ~367 MB RSS — *RSS (resident set size) is the memory a process actually holds in RAM* — across **35 real concurrent sessions** on a 32 GB box, and RSS overcounts shared framework memory). **RAM is almost never the real limit** — your **Claude subscription quota / rate limits** are (every session bills independently), with CPU a factor during heavy simultaneous bursts. Pick the cheapest box that fits your budget; you'll hit your plan limits before you run out of memory.

### Option 2: An old laptop / Mac Mini you already own

Repurpose what's lying around. A used Mac Mini or an old laptop with a scratched screen — Claude Code doesn't care about screens. Minimum 8 GB RAM; 16 GB runs 30+ sessions. One-time cost, no monthly bill. Put it on Tailscale and reach it exactly the same way (`ssh mac`) — see "Running the Server on a Mac" above for keeping it awake and reachable.

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
| `Connection timed out` / `ssh mac` hangs | Tailscale is off or expired on one device. Confirm it's **up** on both phone and server; try the public `<SERVER_IP>` as fallback. |
| `Permission denied (publickey)` | Check the server's `~/.ssh` is `700`, `authorized_keys` is `600`, and you're logging in as the right user with your device's `id_ed25519.pub` present in it. |
| `EACCES` during `npm install -g` | Use the native installer (`curl -fsSL https://claude.ai/install.sh \| bash`) — don't `sudo npm`; instead configure an npm user prefix so global installs don't need root (see Anthropic's install docs). |
| `claude: command not found` after install | Open a new shell (so PATH reloads), or add the install dir to your PATH; then re-run `claude`. |
| Session drops on mobile | Use `mosh mac` instead of `ssh mac`; add `ServerAliveInterval 60` to `~/.ssh/config`. |
| `uv: command not found` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Tailnet IP won't resolve by name | Enable **MagicDNS** in the Tailscale admin console. |
