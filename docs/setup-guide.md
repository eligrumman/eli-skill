# Setup Guide — Run Claude Code Agents From Your Phone

A complete, from-scratch guide to the setup **eli** installs for you: a cloud server running a fleet of Claude Code agents, reachable from anywhere over Tailscale, driven from an Android phone via Termux. No bot, no custom daemon — just SSH + Claude Code.

> **The whole flow in one line:**
> Phone (Termux) → `ssh mac` → `claude agents` → one screen with every session across all your projects → attach to the one you want and keep working.

All server IPs, usernames, and hostnames below are placeholders like `<SERVER_IP>`, `<USER>`, `<TAILNET_IP>`. Swap in your own.

> **New to all this? Start here — a plain-language glossary.** This guide assumes you know Claude Code and nothing else. Every term is defined again where it first appears, but here they are in one place:
> - **Server** — a computer that runs 24/7 so your agents never stop. Either a **Mac you own** (kept plugged in and awake) or one you **rent from Hetzner** (a company that rents computers in a datacenter for a few dollars a month).
> - **Terminal / command line** — a text window where you type commands instead of clicking buttons.
> - **SSH (Secure Shell)** — the standard, encrypted way to open a command line *on another computer* over the internet. `ssh mac` means "open a command line on my server."
> - **SSH client app** — the app on your phone you use to run SSH. **Android → Termux** (or Termius); **iPhone → Termius**. (Explained with download links in step 2.)
> - **SSH key (public / private)** — a passwordless login. You generate a **key pair**: the **private** key stays secret on your device, the **public** key gets copied to the server. Anyone holding the matching private key can log in, so you never share it.
> - **Tailscale / VPN** — a private network that lets your phone reach your server from anywhere, without exposing it to the public internet. (Explained in step 3.)
> - **Tailnet** — your own private network of Tailscale devices: everything signed into the same Tailscale account, reachable by its `100.x.y.z` address.
> - **VNC / Screen Sharing** — seeing and controlling the server's actual desktop screen remotely, for when a command line isn't enough (a browser login, a GUI app).
> - **`claude agents`** — the Claude Code command that shows *all* your running sessions, across every project, in one screen. Your daily entry point.

---

## 0. What you're building

Three machines, one tailnet:

| Machine | Role |
|---|---|
| **Cloud server** (Hetzner) | Runs the agents 24/7. The real workhorse. |
| **Mac** (optional) | A second always-on box / dev machine, also on the tailnet. |
| **Android phone** (Termux) | Your remote control. SSH in from anywhere. |

They're glued together by **Tailscale** (a zero-config VPN), so every machine can reach every other by a stable private IP — no port-forwarding, no exposing SSH to the public internet.

---

## Choosing your machine: Mac vs Hetzner

Before you provision anything, decide where the agents will live. Two honest options:

| | **Mac** (old MacBook / Mac Mini you own) | **Hetzner** (Linux cloud server) |
|---|---|---|
| Cost | **Free** — your own hardware, no monthly bill | from ~€6.80/mo (≈ $7.50) up to ~€16.40/mo (≈ $18) |
| Uptime | Depends on your home network + power; you're the one keeping it alive | Built for uptime: higher speed, better stability, independent of your home network |
| Best for | Mac-only apps that don't exist on Linux; a GUI/browser on the box | Always-on loops / agents that must never go down and shouldn't depend on your house's internet or power |

**Both are valid, and many people run both:** Linux/Hetzner for the always-up fleet, a Mac for GUI/browser/Mac-app work. Pick based on what you need.

**Which should I pick?** Want a set-and-forget, always-on fleet that never depends on your home? Go **Hetzner**. Already own a Mac and want a free box you can also see the screen of (GUI, browser, Mac apps)? Run it on the **Mac** — just turn on Remote Login and keep it plugged in and awake (see "Running the server on a Mac" below).

---

## 1. Provision the server (Hetzner Cloud)

> **Do these two things first:** (1) **Hetzner requires identity verification** before you can create servers — upload a passport or national ID via their verification page. It can take a few hours, so start it now. (2) The creation screen asks you to paste an SSH **public key** — so jump ahead to step 2, generate your keys, then come back. (The key you paste at creation is installed for the **root** user; the manual `authorized_keys` step in step 2 is for the non-root user you create below, or for adding more keys later.)

1. Make a [Hetzner Cloud](https://www.hetzner.com/cloud) account → new project → **Add Server**.
2. Recommended box: **CX42** — 8 vCPU, 16 GB RAM, 160 GB SSD, ~€16.40/month (≈ $18). Comfortably runs **30+** concurrent Claude Code sessions. (The cheaper entry box **CX32** — 4 vCPU, 8 GB RAM, 80 GB SSD, ~€6.80/month ≈ $7.50 — comfortably runs **~10–20**.) The Hetzner CX line is CX22 / CX32 / CX42 / CX52. See the capacity note below — RAM is almost never the real limit.
3. **Image:** Ubuntu 24.04 LTS.
4. **SSH key:** paste your phone's *and* your Mac's public key here now (see step 2) so you can log in without a password. You can also add keys later.
5. Create. Note the **public IPv4** — that's your `<SERVER_IP>`.

> **How many agents can it really run?** Far more than you'd think. On a 32 GB Mac the owner has run **35 Claude Code sessions simultaneously** — each ranging ~65 MB (idle) to ~740 MB (actively working), **median ~320 MB, average ~367 MB RSS** — *RSS (resident set size) is the memory a process actually holds in RAM* — and RSS overcounts shared framework memory, so the true incremental cost per extra session is lower. Rule of thumb: an **idle** session is ~50–150 MB; a **hard-working** one a few hundred MB. So **CX32 (8 GB) comfortably runs ~10–20 sessions; CX42 (16 GB) runs 30+** (approximate).
>
> **RAM is almost never the real limit.** The real ceilings are (1) your **Claude subscription quota / rate limits** — every session bills independently — and (2) CPU during heavy simultaneous bursts. Pick the cheapest box that fits your budget; you'll hit your Claude plan limits before you run out of memory.

First login and hardening:
```bash
ssh root@<SERVER_IP>

# Create a non-root user you'll actually work as
adduser <USER>
usermod -aG sudo <USER>

# Copy your SSH key from root to the new user
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

---

## 2. SSH keys (phone + Mac → server)

**First — the app you'll type commands into on your phone.** SSH needs a *client app* on the phone. Pick by platform:

- **Termux (Android)** — a free **terminal app for Android**: it gives you a Linux command line right on your phone, which is where you type `ssh` to reach your server. Android only. Download from [Google Play](https://play.google.com/store/apps/details?id=com.termux) — also available on [F-Droid](https://f-droid.org/packages/com.termux/) and [GitHub releases](https://github.com/termux/termux-app/releases).
- **Termius (iPhone + others)** — a polished **SSH client with a friendly GUI**: instead of typing commands, you save your server as a connection and tap to connect. Cross-platform — **iOS, Android, Mac, Windows**. This is the pick for **iPhone users** (Termux is Android-only). Download: [Apple App Store](https://apps.apple.com/app/termius-ssh-client/id549039908).

**In short: Android → Termux (or Termius); iPhone → Termius.** The commands below are shown for Termux; in Termius you enter the same keys/host through its GUI.

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

**On iPhone (Termius) — the key sub-flow.** Termius has no command line, so you generate the key in its GUI: open **Termius → Keychain → + (New Key) → Generate**, pick **Ed25519**, and save it. Tap the key → **Copy Public Key** (that's the half that goes on the server). Then **Hosts → + (New Host)**: set **Address** to your `<TAILNET_IP>` (or `<SERVER_IP>` at first), **Username** to `<USER>`, and under **Keys** attach the key you just made. Tap the host to connect — no password.

**On the server**, add both public keys:
```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys   # paste each pubkey on its own line
chmod 600 ~/.ssh/authorized_keys
```

**One-command alternative — `ssh-copy-id`.** This only works while password login is still enabled, so **do it before you disable password auth in step 1** (`ssh-copy-id` needs to log in with a password to install the key). From your Mac or Termux you can install a pubkey in a single command instead of editing `authorized_keys` by hand:
```bash
ssh-copy-id <USER>@<SERVER_IP>
```

If your Mac and server should also SSH to each other, repeat the same: generate a key on the Mac, add its pubkey to the server (and vice-versa). This is exactly the "pubkey on Mac + on the Hetzner server" step.

---

## 3. Tailscale (reach the server from anywhere)

Public IPs change and expose you; Tailscale gives every machine a stable private IP on your own tailnet.

### What is Tailscale and how does it work?

Tailscale is a free app that links your own devices — your phone, your Mac, your server — over a private, secure connection, as if they were all on the same home Wi-Fi, even when they're in different places. You install it on each device and sign in with the **same account** on all of them. What that buys you:

- Each device gets its own **private address** (it looks like `100.x.y.z`) that only your other devices can reach. That's how your phone connects to your server from **anywhere** — café Wi-Fi, mobile data — **without touching your router settings and without putting your server on the public internet**.
- **MagicDNS** (turn it on in Tailscale) lets you use an easy name like `mac` instead of the number.

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
- If you want the box reachable by name, enable **MagicDNS** in the Tailscale admin console.

### Tailscale pitfalls & common newbie mistakes

**General**
- **Same account on every device.** The #1 mistake: the server is logged into one Tailscale account and the phone into another, so they can't see each other. All devices must be on the same tailnet (or explicitly shared in).
- **Tailscale must be toggled ON at both ends** at connect time. If `ssh mac` hangs, check Tailscale is actually up on the phone **and** the server.
- **Key expiry.** By default a device's key expires (~180 days) and it silently drops off the tailnet until you re-authenticate. For an always-on server, **disable key expiry** for that machine in the admin console so it never drops.
- Use the `100.x` IP directly, or enable **MagicDNS** for names. Keep the server's **public IP as a fallback** for when the tailnet is flaky.

**Linux server**
- After install, `sudo tailscale up`; ensure the service auto-starts on reboot (`sudo systemctl enable --now tailscaled`).
- **Headless auth:** no browser on the server → it prints a login URL; open it on your phone/laptop to authorize. Or provision non-interactively with an auth key: `sudo tailscale up --authkey tskey-...`.
- Don't firewall the `tailscale0` interface if you run ufw/iptables.
- (Optional) `tailscale up --ssh` enables Tailscale-managed SSH; not required if you already use key-based SSH.

**Mac**
- Two flavors: the **Mac App Store** app vs the **standalone/open-source** app (or `brew install --cask tailscale`). For a Mac used as a *server*, prefer the standalone build so you get the `tailscale` CLI.
- On first launch macOS shows a **VPN / network-extension permission prompt** — you must approve it, which needs the screen (do it via physical access or Screen Sharing once).
- Make sure Tailscale **launches at login** (especially on a headless auto-login Mac), and the menu-bar app is logged in.
- Don't accidentally leave **"Use exit node"** on — it routes all your traffic through another device and is slow/confusing.

**Mobile (Android)**
- Tailscale is a **separate app** from Termux — install it, log in, toggle ON. Termux does not run Tailscale itself.
- **Android battery optimization can kill the VPN.** Exclude Tailscale from battery optimization so it stays connected in the background.
- **After a phone reboot, Tailscale may come back OFF.** When your phone restarts (or an OS update reboots it), the VPN toggle often reverts to off — so `ssh mac` just hangs until you reopen the Tailscale app and toggle it back ON. Enable Tailscale's **"Connect on start / run on boot"** option in the Android app settings (and exclude it from battery optimization). Rule of thumb: if you can't reach the server right after restarting your phone, check Tailscale is ON first — it's the most common cause.
- Be careful with Android **"Always-on VPN" / "Block connections without VPN"** — usually leave these off; just toggle Tailscale when you need it.
- If a MagicDNS name won't resolve or `ssh mac` times out on mobile: toggle Tailscale off/on, or you may be behind a captive-portal Wi-Fi → fall back to the public IP.

**Debugging commands (any platform)**
- `tailscale status` — shows peers and whether a connection is **direct or relayed**.
- `tailscale ping <host>` — tests connectivity to a peer.
- `tailscale netcheck` — diagnoses NAT/relay conditions.

---

## 4. Termux "mac" shortcut (the phone-side ergonomics)

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

---

## 5. Install Claude Code on the server

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

---

## Your control center: `claude agents` (agent view)

`claude agents` opens **agent view** — one screen listing every background session you've started, grouped by state (**Needs input** / **Working** / **Completed** / **Pinned**). Make this your primary entry point instead of plain `claude`. Read the official [`claude agents` / agent view docs](https://code.claude.com/docs/en/agent-view) for full detail.

- **All projects at once.** By default agent view lists sessions across **all** your projects, regardless of which directory you launched from. Narrow to one project with `claude agents --cwd ~/projects/my-app`.
- **Dispatch a task:** type a prompt and press `Enter` → a new background session starts as a row. Each `Enter` launches a *separate* session, so you can fire off several in parallel.
- **Peek:** select a row and press `Space` to see its latest output or the question it's waiting on; reply inline with `Enter`.
- **Attach:** `Enter` or `→` on a row enters the full conversation. **Detach:** `←` on an empty prompt (or `Esc`) returns to the table.
- **Bring an existing session in:** run `/bg` inside a normal `claude` session (or press `←`) to background it into agent view.
- **They survive disconnects.** Each background session keeps running **without a terminal attached** — so you can close Termux/Termius or lose your phone signal and the agents keep working. Reopen `claude agents` later and they're all still there. This is the real answer to "won't it die when I disconnect?" — no, background sessions persist on the server.
- **Quota, not RAM, is the limit.** Each session uses your Claude subscription quota **independently**, so that — not memory — is the practical ceiling on how many to run at once (see the capacity note under step 1).
- It's a **research preview**; keyboard shortcuts may change.

---

## 6. How the agents actually work

This is the part that matters. An "agent" here isn't a special server; it's a **project folder plus a role definition**. There are two styles I use.

### Style A — Subagent as a markdown file
Inside a project you drop role files in `.claude/agents/*.md`. Each is a markdown file with YAML frontmatter; the body is that agent's full operating manual (persona, exact commands, rules). Example (`.claude/agents/qa.md`):
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
A real agent-driven project (my `investor` project) looks like:
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

---

## 7. A day in the life

```bash
# from the phone, anywhere
ssh mac

# open agent view — every session across all my projects, in one screen
claude agents

# then, right there:
#   - type a prompt + Enter to dispatch a new background session
#   - Space to peek at what a session is doing or asking
#   - Enter / → to attach to one and steer it; ← or Esc to detach
#   - jump straight to a single project with:  claude agents --cwd ~/investor
```
That's it. The agents keep running on the server whether or not my phone is connected; agent view is just the window I look through. Disconnect the phone, the work continues; reopen `claude agents` later, everything's still there.

---

## 8. Running the server on a Mac

If you're using a Mac (an old MacBook or a Mac Mini) as the always-on box instead of — or alongside — a cloud server, a few Mac-specific things keep it reliable. Everything else in this guide (SSH keys, Tailscale, the `ssh mac` shortcut, installing Claude Code) is the same; on macOS use `brew install` where the Ubuntu steps use `apt` (install [Homebrew](https://brew.sh) first if you don't have it, then `brew install node` only if you take the npm route to Claude Code).

### a) Turn on Remote Login (do this first)
macOS ships with its SSH server **off**, so `ssh mac` fails until you enable it: **System Settings → General → Sharing → Remote Login → On**, and restrict it to your user. Your Mac's `~/.ssh/authorized_keys` then takes your pasted public key exactly the way a Linux server does — same file, same `chmod 700 ~/.ssh` / `chmod 600 authorized_keys`.

### b) Keep it powered
A laptop acting as a server must stay **plugged into AC power at all times** — always on the charger. Never run it on battery as a server: the battery drains, the machine sleeps or dies, and your fleet goes with it.

### c) Never let it sleep
Set power management so the Mac never sleeps. This is the exact configuration to run:

```
sudo pmset -a sleep 0 displaysleep 0 disksleep 0 womp 1 ttyskeepawake 1 tcpkeepalive 1 powernap 1 standby 1
```

What the key flags do:
- `sleep 0` — never system-sleep
- `displaysleep 0` — the display never sleeps
- `disksleep 0` — disks stay spun up
- `womp 1` — wake for network access (Wake-on-LAN / magic packet)
- `ttyskeepawake 1` — stays awake while a remote SSH/tty session is active
- `tcpkeepalive 1` — keeps TCP connections alive during low-power
- `powernap 1` / `standby 1` — background tasks keep running

For a one-off, scriptable "stay awake for this task," use `caffeinate` — e.g. `caffeinate -dimsu claude ...` holds the Mac awake for as long as that command runs. Note that a live SSH session already asserts wake via `ttyskeepawake`, so day-to-day you rarely need it.

**MacBook with the lid closed (clamshell):** `sudo pmset -a disablesleep 1` lets a MacBook keep running with the lid shut even without an external display. It disables clamshell sleep entirely — the machine will never sleep from closing the lid — so use it deliberately. Leaving the lid open is the simpler, cooler-running option.

### d) See the screen remotely — Screen Sharing (VNC) over Tailscale
SSH + Claude is your day-to-day. But sometimes you need the actual desktop: a browser login, a GUI app, a stuck dialog. Screen Sharing is that escape hatch.

- On the Mac server: **System Settings → General → Sharing → enable Screen Sharing** (or **Remote Management**). It serves VNC on port **5900**.
- Because the Mac is on your tailnet, you can reach that screen from **anywhere**, not just the LAN.
- From another Mac: Finder → **Go → Connect to Server** (**⌘K / Cmd + K**) → enter `vnc://<TAILNET_IP>` → log in with the Mac's user. You now see and control the desktop.

Frame it this way: SSH + Claude is how you work every day; Screen Sharing is how you take the wheel when an agent needs a browser, hits a GUI prompt, or something visual breaks.

### e) Recovery after reboot / power outage
Power blips and reboots happen. Set the Mac to come back on its own, then relaunch agents by hand:

- **Start up automatically after a power failure:**
  ```
  sudo systemsetup -setrestartpowerfailure on
  ```
  (or System Settings → Energy.) This is only supported on some Mac models — it errors on many MacBooks, which is fine; just skip it there.
- **Automatic login** for your user (System Settings → Users & Groups → Automatically log in as…) so the Mac returns to a logged-in desktop that SSH and Screen Sharing can reach without someone typing a password at the keyboard. Note: **FileVault silently disables auto-login** — you can have one or the other, not both, so leave FileVault off on a headless server box.
- After it's back up, **SSH in and relaunch your agents by hand**: `ssh mac` → `cd project` → `claude` (or restart your background jobs). Keep it simple — no launchd auto-relaunch needed.

---

## Recap checklist

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

---

## Verify it works — end-to-end smoke test

Run this once, in order, to prove the whole chain is live (distinct from the recap above — this is a live test, not a paperwork check):

1. **Tailscale:** on the phone, `tailscale status` (or the app) shows all peers — server, Mac, phone — connected.
2. **SSH with no password:** `ssh mac` connects straight to a shell with **no password prompt** (key auth working).
3. **Claude installed:** on the server, `claude --version` prints a version.
4. **Agent view opens:** `claude agents` opens the agent view screen.
5. **Survives a reboot:** reboot the phone, reopen Tailscale, confirm it reconnects and `ssh mac` still works. (If it hangs, Tailscale came back OFF — the #1 cause.)

If all five pass, you're done.

---

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
