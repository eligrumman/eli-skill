# eli

**Your Claude Code expert. As a skill.**

> Install it. Type "eli walk me". That's it.

---

## The Problem

You're running Claude Code on a powerful machine — but you're not always sitting in front of it.

You're on the couch, on a train, out for a walk. The agents are back home, mid-task. You want to jump in, steer them, kick off something new — from your phone, from anywhere, without a laptop.

The usual "remote control" options all give something up:

- **Claude Code Remote Control** is great — for a *single* session. Close the terminal and it's dead. Internet drops for 10 minutes and it's dead. No parallel agents.
- **A separate mobile agent** (a different assistant entirely) means you lose your `CLAUDE.md`, your MCP servers, your project context, your tool permissions — everything that makes *your* Claude Code yours.

## The Solution

Run your agents on a small cloud server that's always on, and reach it from your phone over **SSH + Tailscale**. No bot layer, no daemon, no third-party bridge — just Claude Code and a terminal.

**The whole flow in one line:**

> Phone (Termux) → `ssh mac` → `claude agents` → one screen with every session across all your projects → attach to the one you want and keep working.

`claude agents` opens Claude Code's **agent view**: one screen listing every background session you've started, across all your projects, grouped by state (Needs input / Working / Completed / Pinned). Type a prompt + `Enter` to dispatch a new one, `Space` to peek, `Enter`/`→` to attach. Crucially, **each background session keeps running without a terminal attached** — close your SSH app or lose signal and the agents keep working; reopen `claude agents` later and they're all still there. (It's a research preview; shortcuts may change. Read the official [`claude agents` / agent view docs](https://code.claude.com/docs/en/agent-view) for full detail.)

Three machines, one private network:

| Machine | Role |
|---|---|
| **Cloud server** (Hetzner) | Runs the agents 24/7. The real workhorse. |
| **Mac** (optional) | A second always-on box / dev machine, also on the tailnet. |
| **Android phone** (Termux) | Your remote control. SSH in from anywhere. |

They're glued together by **Tailscale** — a zero-config private VPN — so every machine reaches every other by a stable private IP. No port-forwarding, no exposing SSH to the public internet.

The agents keep running on the server whether or not your phone is connected. SSH is just the window you look through: disconnect, the work continues; reconnect later, pick up where it left off.

## New Here? Plain-Language Glossary

This assumes you know Claude Code and nothing else. The terms, in one place:

- **Server** — a computer that runs 24/7 so your agents never stop. Either a **Mac you own** (kept plugged in and awake) or one you **rent from Hetzner** (a company that rents computers in a datacenter for a few dollars a month).
- **Terminal / command line** — a text window where you type commands instead of clicking.
- **SSH (Secure Shell)** — the standard, encrypted way to open a command line *on another computer* over the internet. `ssh mac` = "open a command line on my server."
- **SSH client app** — the app you run SSH from. **Android → Termux** (a free Linux terminal app; download from [Google Play](https://play.google.com/store/apps/details?id=com.termux) — also available on [F-Droid](https://f-droid.org/packages/com.termux/) and [GitHub releases](https://github.com/termux/termux-app/releases)). **iPhone → [Termius](https://apps.apple.com/app/termius-ssh-client/id549039908)** (a friendly GUI SSH client — iOS/Android/Mac/Windows; Android users can use either).
- **SSH key (public / private)** — a passwordless login. You generate a **key pair**: the **private** key stays secret on your device, the **public** key is copied to the server. Never share the private key.
- **Tailnet** — your own private network of Tailscale devices. Every machine you sign into Tailscale with the same account joins the same tailnet and can reach the others by their private `100.x.y.z` address.
- **Tailscale (the app that connects your devices)** — a free app that links your own devices — phone, Mac, server — over a private, secure connection, as if they were all on the same home Wi-Fi, even when they're in different places. Install it on each device and sign in with the **same account**. Each device gets its own **private address** (it looks like `100.x.y.z`) that only your other devices can reach, so your phone connects to your server from anywhere — café Wi-Fi, mobile data — **without touching your router settings and without putting your server on the public internet**. Turn on **MagicDNS** to use an easy name like `mac` instead of the number.
- **VNC / Screen Sharing** — seeing and controlling the server's actual desktop screen remotely, for when a command line isn't enough (a browser login, a GUI app).
- **`claude agents`** — the Claude Code command that shows *all* your running sessions, across every project, in one screen. Your daily entry point.

The [setup guide](docs/setup-guide.md) also covers **Tailscale pitfalls** newcomers hit — same account on every device, disabling key expiry on the always-on server, and excluding the Tailscale app from battery optimization (plus "connect on boot") on the phone so it doesn't silently drop.

## Why This Beats the Alternatives

- **It's real Claude Code** — your `CLAUDE.md`, MCP servers, skills, permissions, and project context, exactly as on your desktop. Nothing reimplemented, nothing lost.
- **True multi-agent** — run many concurrent sessions from one `claude agents` screen. In practice your **Claude subscription quota**, not your server's RAM, is what caps how many run at once (each session bills independently). Each project is its own folder with its own agents.
- **Survives everything** — the session lives on the server as a background job, not on your phone. Network drops, app switches, and reboots don't kill your work.
- **No custom infrastructure** — nothing to run but Claude Code itself. SSH and Tailscale are boring, battle-tested, and secure.
- **Cheap** — a Hetzner CX42 (8 vCPU, 16 GB RAM) comfortably runs 30+ concurrent sessions for about €16.40/month (≈ $18).

This repo gives you **eli** — a Claude Code skill that walks you through the entire setup. Built by [Eli Grumman](https://www.linkedin.com/in/eli-grumman-495b0636/) — an expert with Claude Code from its early days, building and running autonomous agents locally and in the cloud; Agentic AI Team Lead at Axonius.

---

## Install

Run the installer (clones the repo and copies the skill into `~/.claude/skills/`):

```bash
curl -fsSL https://raw.githubusercontent.com/eligrumman/eli-skill/main/install.sh | sh
```

Or install it manually:

```bash
git clone https://github.com/eligrumman/eli-skill.git
cp -r eli-skill/skills/eli ~/.claude/skills/
```

Then tell your agent:

```
eli walk me
```

---

## What Happens Next

First it asks where to run your agents — an old MacBook you already own, a Mac Mini, or a cloud server (Hetzner, from ~€6.80/mo ≈ $7.50 up to ~€16.40/mo ≈ $18). Then `eli walk me` walks you through the whole thing, step by step:

1. **Provision a server** — Hetzner Cloud, Ubuntu 24.04, a non-root sudo user, SSH hardening. (On a Mac instead: turn on Remote Login first.)
2. **SSH keys** — generate a keypair on your phone *and* your Mac; both public keys go on the server. Private keys never leave your devices.
3. **Tailscale** — install and log in on the server, Mac, and phone (same account). Now everything reaches the server by a stable private IP.
4. **Termux `Host mac` shortcut** — so from the phone you just type `ssh mac`.
5. **Install Claude Code** on the server — the native installer (or Node + npm), `uv`, and a one-time headless `claude` login that persists.
6. **The agent model** — how to structure projects so each one carries its own agents.

For the full written walkthrough, see [docs/setup-guide.md](docs/setup-guide.md) (English) or [docs/setup-guide-he.md](docs/setup-guide-he.md) (Hebrew).

---

## The Agent Model

An "agent" here isn't a special server. It's a **project folder plus a role definition**. Two styles:

### Style A — Subagent as a markdown file

Drop role files in `.claude/agents/*.md`. Each is markdown with YAML frontmatter; the body is that agent's full operating manual (persona, exact commands, rules). Claude Code surfaces it in the agent picker and spawns it on demand. Great for on-demand roles — a QA checker, a reviewer.

```markdown
---
name: qa
description: MANDATORY browser-based QA verifier. Use BEFORE any claim that a UI feature works.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are the QA verifier. Open the real page in Chrome, screenshot it,
read the console, and report only observed facts — never "should work".
```

### Style B — Persistent fleet agent

For always-on workers, each agent is a long-running **Claude Code background job** whose:

- **identity** comes from its own `state.json` (it reads this first every session to learn its name),
- **behavior** comes from a same-named **skill** in `.claude/skills/<agent-name>/` (its operating manual, including its `/loop` interval, e.g. `/loop 15m`),
- **mission** comes from a canonical prompt line in a shared control file.

On startup each agent reads `state.json` → looks up its mission → loads *only its own* skill → confirms its `/loop` is running → then acts **only within its domain**, prefixing commits with `[agent-name]` and escalating anything out-of-domain rather than fixing it.

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
- **Separation of duties** — a coordinator agent never patches domain logic; a domain failure is a not-good-enough prompt/skill/loop, fixed *there*.
- **Single source of truth** — one manifest / prompt file; missions read verbatim, never copied.
- **Isolated worktrees** — agents edit in their own `git worktree` so they don't collide.
- **Permissions as guardrails** — `settings.json` allowlists safe commands and denies every force-push variant.

---

## Requirements

| Requirement | Why |
|---|---|
| **Claude subscription** | a Claude Code plan (Pro or Max) for each machine running agents |
| **A cloud server** (or any always-on box) | Runs the agents 24/7 |
| **Tailscale account** | Reach the server privately from anywhere |
| **A phone with an SSH app** (Android → Termux; iPhone → Termius) | Your remote control |

---

## Where to Run

You need a machine that's always on. First, the honest tradeoff:

| | **Mac** (old MacBook / Mac Mini you own) | **Hetzner** (Linux cloud server) |
|---|---|---|
| Cost | **Free** — your own hardware, no monthly bill | from ~€6.80/mo (≈ $7.50) up to ~€16.40/mo (≈ $18) |
| Uptime | Depends on your home network + power; you keep it alive | Built for uptime: higher speed, better stability, independent of your home network |
| Best for | Mac-only apps that don't exist on Linux; a GUI/browser on the box | Always-on loops / agents that must never go down and shouldn't depend on your house's internet or power |

**Both are valid, and many people run both:** Linux/Hetzner for the always-up fleet, a Mac for GUI/browser/Mac-app work. Want a set-and-forget always-on fleet? Go Hetzner. Already own a Mac and want a free box you can also see the screen of? Run it on the Mac (turn on Remote Login and keep it plugged in and awake — see below).

### Option 1: Hetzner Cloud (Recommended)

Cheapest ongoing, EU-based, reliable. This is what the guide sets up.

| Type | Specs | Price |
|---|---|---|
| **CX32** | 4 vCPU, 8 GB RAM, 80 GB SSD | ~€6.80/mo (≈ $7.50) — the cheaper entry box |
| **CX42** | 8 vCPU, 16 GB RAM, 160 GB SSD | ~€16.40/mo (≈ $18) — recommended, runs 30+ concurrent sessions |

(The Hetzner CX line is CX22 / CX32 / CX42 / CX52; the CX32 and CX42 are the sweet spots here.)

An idle Claude Code session is ~50–150 MB; a hard-working one a few hundred MB (measured median ~320 MB across 35 real concurrent sessions on a 32 GB box). **RAM is almost never the real limit** — your **Claude subscription quota / rate limits** are (every session bills independently), with CPU a factor during heavy simultaneous bursts. Pick the cheapest box that fits your budget; you'll hit your plan limits before you run out of memory.

### Option 2: An old laptop / Mac Mini you already own

Repurpose what's lying around. A used Mac Mini or an old laptop with a scratched screen — Claude Code doesn't care about screens. Minimum 8 GB RAM; 16 GB runs 30+ sessions. One-time cost, no monthly bill. Put it on Tailscale and reach it exactly the same way.

**Running the server on a Mac** — a few Mac-specific essentials, covered in full in the [setup guide](docs/setup-guide.md#8-running-the-server-on-a-mac):

- **Turn on Remote Login first** — System Settings → General → Sharing → **Remote Login → On** (restrict it to your user). This is what makes `ssh mac` work at all: macOS ships with the SSH server **off** by default. Your Mac's `~/.ssh/authorized_keys` takes your pasted public key exactly the way a Linux server does.
- **Keep it powered** — a laptop-as-server must stay plugged into AC power at all times. Never run it on battery.
- **Never let it sleep** — `sudo pmset -a sleep 0 displaysleep 0 disksleep 0 womp 1 ttyskeepawake 1 tcpkeepalive 1 powernap 1 standby 1`. (`caffeinate -dimsu <cmd>` holds it awake for a single task; a live SSH session already keeps it awake via `ttyskeepawake`.) For a lid-closed MacBook, `sudo pmset -a disablesleep 1` — or just leave the lid open, which is simpler and runs cooler.
- **See the screen remotely** — enable **Screen Sharing** (System Settings → General → Sharing); it serves VNC on port 5900. Over Tailscale you reach it from anywhere: from another Mac, Finder → Go → Connect to Server (⌘K) → `vnc://<TAILNET_IP>`. SSH + Claude is your day-to-day; Screen Sharing is how you take the wheel when an agent needs a browser or hits a GUI prompt.
- **Recovery after a power outage** — `sudo systemsetup -setrestartpowerfailure on` (if supported on your Mac model — it errors on many MacBooks) plus automatic login, so the Mac boots back to a reachable logged-in desktop; then SSH in and relaunch your agents by hand. Note: **FileVault silently disables auto-login** — pick one or the other.

---

## FAQ

<details>
<summary><strong>Do I need MCP servers?</strong></summary>

No — and for an always-on setup it's often better without them. Each MCP server adds ~200–300 MB and another process that can break. Claude Code without MCP is lean at ~300 MB/session. Install only what you truly need.
</details>

<details>
<summary><strong>Is exposing SSH safe?</strong></summary>

You don't expose it. With Tailscale, the server is reachable only by devices on your own tailnet — the public internet never sees the SSH port. Add key-only auth (disable password login) and you're in good shape. Keep the public IP as a fallback only.

One Ubuntu 24.04 gotcha: editing only `/etc/ssh/sshd_config` does **not** disable password login, because Hetzner's cloud image ships `/etc/ssh/sshd_config.d/50-cloud-init.conf` with `PasswordAuthentication yes` that overrides it. Add a drop-in `/etc/ssh/sshd_config.d/99-hardening.conf` with `PasswordAuthentication no` and `PermitRootLogin no`, then `sudo systemctl restart ssh`. **Verify key-only login works in a SECOND terminal BEFORE closing your root session** so a typo can't lock you out. Full steps are in the [setup guide](docs/setup-guide.md).
</details>

<details>
<summary><strong>Can I run multiple agents in parallel?</strong></summary>

Yes — that's the whole point. Run `claude agents` to see every session in one screen and dispatch new ones with a prompt + `Enter`. You can run far more than you'd expect: memory is rarely the ceiling (an idle session is ~50–150 MB), so in practice your **Claude subscription quota** is what limits how many run at once, since each session bills independently.
</details>

<details>
<summary><strong>What if my phone disconnects?</strong></summary>

The agents keep running on the server as background sessions. SSH is just your window in. Reconnect later — a fresh `ssh mac` → `claude agents` shows every session exactly where you left it. For flaky mobile signal, `mosh` survives network changes far better than raw SSH. Over Tailscale `mosh` just works; if you ever fall back to the public IP with `ufw` on, open UDP **60000–61000** for it.
</details>

---

## What's Inside

```
eli-skill/
├── skills/
│   └── eli/
│       └── SKILL.md          # The "eli" skill (setup walkthrough + agent model)
├── docs/
│   ├── setup-guide.md        # Full English setup guide
│   └── setup-guide-he.md     # Full Hebrew setup guide
├── install.sh                # One-liner installer
├── LICENSE
└── README.md
```

---

## Credits

- Setup skill and documentation by [Eli Grumman](https://www.linkedin.com/in/eli-grumman-495b0636/) — an expert with Claude Code from its early days, building and running autonomous agents locally and in the cloud; Agentic AI Team Lead at Axonius.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
