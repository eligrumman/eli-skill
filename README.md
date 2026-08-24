# eli

**Your Claude Code expert. As a skill.**

> Install it. Type "eli help me". That's it.

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

> Phone (Termux) → `ssh mac` → `cd` into a project → `claude` → pick the relevant agent → keep working.

Three machines, one private network:

| Machine | Role |
|---|---|
| **Cloud server** (Hetzner) | Runs the agents 24/7. The real workhorse. |
| **Mac** (optional) | A second always-on box / dev machine, also on the tailnet. |
| **Android phone** (Termux) | Your remote control. SSH in from anywhere. |

They're glued together by **Tailscale** — a zero-config private VPN — so every machine reaches every other by a stable private IP. No port-forwarding, no exposing SSH to the public internet.

The agents keep running on the server whether or not your phone is connected. SSH is just the window you look through: disconnect, the work continues; reconnect later, pick up where it left off.

## Why This Beats the Alternatives

- **It's real Claude Code** — your `CLAUDE.md`, MCP servers, skills, permissions, and project context, exactly as on your desktop. Nothing reimplemented, nothing lost.
- **True multi-agent** — run as many concurrent agents as your server's RAM allows. Each project is its own folder with its own agents.
- **Survives everything** — the session lives on the server, not on your phone. Network drops, app switches, and reboots don't kill your work.
- **No custom infrastructure** — nothing to run but Claude Code itself. SSH and Tailscale are boring, battle-tested, and secure.
- **Cheap** — a Hetzner CX43 (4 vCPU, 16 GB RAM) comfortably runs 3+ agents for about $14/month.

This repo gives you **eli** — a Claude Code skill that walks you through the entire setup. Built by [Eli Groman](https://www.linkedin.com/in/eli-grumman-495b0636/), who spends $1,000+/month on Opus so you don't have to figure this out alone.

---

## Install

One command. Paste this into Claude Code:

```
/skill install github:eligrumman/eli-skill
```

Or manually:

```bash
git clone https://github.com/eligrumman/eli-skill.git
cp -r eli-skill/skills/eli ~/.claude/skills/
```

Or run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/eligrumman/eli-skill/main/install.sh | sh
```

Then tell your agent:

```
eli setup
```

---

## What Happens Next

`eli setup` walks you through the whole thing, in order:

1. **Provision a server** — Hetzner Cloud, Ubuntu 24.04, a non-root sudo user.
2. **SSH keys** — generate a keypair on your phone *and* your Mac; both public keys go on the server. Private keys never leave your devices.
3. **Tailscale** — install and log in on the server, Mac, and phone (same account). Now everything reaches the server by a stable private IP.
4. **Termux `Host mac` shortcut** — so from the phone you just type `ssh mac`.
5. **Install Claude Code** on the server — Node, the CLI, `uv`, and a one-time `claude` login that persists.
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
| **Claude Code Max subscription** | Opus access — no Opus, no team |
| **A cloud server** (or any always-on box) | Runs the agents 24/7 |
| **Tailscale account** | Reach the server privately from anywhere |
| **Android phone with Termux** | Your remote control |

---

## Where to Run

You need a machine that's always on. First, the honest tradeoff:

| | **Mac** (old MacBook / Mac Mini you own) | **Hetzner** (Linux cloud server) |
|---|---|---|
| Cost | **Free** — your own hardware, no monthly bill | ~$15/month |
| Uptime | Depends on your home network + power; you keep it alive | Built for uptime: higher speed, better stability, independent of your home network |
| Best for | Mac-only apps that don't exist on Linux; a GUI/browser on the box | Always-on loops / agents that must never go down and shouldn't depend on your house's internet or power |

**Both are valid, and many people run both:** Linux/Hetzner for the always-up fleet, a Mac for GUI/browser/Mac-app work. Want a set-and-forget always-on fleet? Go Hetzner. Already own a Mac and want a free box you can also see the screen of? Run it on the Mac (keep it plugged in and awake — see below).

### Option 1: Hetzner Cloud (Recommended)

Cheapest ongoing, EU-based, reliable. This is what the guide sets up.

| Type | Specs | Price |
|---|---|---|
| **CX22** | 4 vCPU, 8 GB RAM | ~$8/month (1–2 agents) |
| **CX43** | 4 vCPU, 16 GB RAM, 160 GB SSD | ~$14/month (3+ agents) |

More RAM = more parallel agents. Claude Code uses ~300–500 MB per session.

### Option 2: An old laptop / Mac Mini you already own

Repurpose what's lying around. A used Mac Mini or an old laptop with a scratched screen — Claude Code doesn't care about screens. Minimum 8 GB RAM; 16 GB runs a small army. One-time cost, no monthly bill. Put it on Tailscale and reach it exactly the same way.

**Running the server on a Mac** — a few Mac-specific essentials, covered in full in the [setup guide](docs/setup-guide.md#8-running-the-server-on-a-mac):

- **Keep it powered** — a laptop-as-server must stay plugged into AC power at all times. Never run it on battery.
- **Never let it sleep** — `sudo pmset -a sleep 0 displaysleep 0 disksleep 0 womp 1 ttyskeepawake 1 tcpkeepalive 1 powernap 1 standby 1`. (`caffeinate -dimsu <cmd>` holds it awake for a single task; a live SSH session already keeps it awake via `ttyskeepawake`.) For a lid-closed MacBook, `sudo pmset -a disablesleep 1` — or just leave the lid open, which is simpler and runs cooler.
- **See the screen remotely** — enable **Screen Sharing** (System Settings → General → Sharing); it serves VNC on port 5900. Over Tailscale you reach it from anywhere: from another Mac, Finder → Go → Connect to Server (⌘K) → `vnc://<TAILNET_IP>`. SSH + Claude is your day-to-day; Screen Sharing is how you take the wheel when an agent needs a browser or hits a GUI prompt.
- **Recovery after a power outage** — `sudo systemsetup -setrestartpowerfailure on` plus automatic login, so the Mac boots back to a reachable logged-in desktop; then SSH in and relaunch your agents by hand.

---

## FAQ

<details>
<summary><strong>Do I need MCP servers?</strong></summary>

No — and for an always-on setup it's often better without them. Each MCP server adds ~200–300 MB and another process that can break. Claude Code without MCP is lean at ~300 MB/session. Install only what you truly need.
</details>

<details>
<summary><strong>Is exposing SSH safe?</strong></summary>

You don't expose it. With Tailscale, the server is reachable only by devices on your own tailnet — the public internet never sees the SSH port. Add key-only auth (disable password login) and you're in good shape. Keep the public IP as a fallback only.
</details>

<details>
<summary><strong>Can I run multiple agents in parallel?</strong></summary>

Yes. Each project folder is its own set of agents, and you can run as many concurrent Claude Code sessions as your server's RAM allows. Jump between them by `cd`-ing into different projects.
</details>

<details>
<summary><strong>What if my phone disconnects?</strong></summary>

The agents keep running on the server. SSH is just your window in. Reconnect later — with `mosh` or a fresh `ssh mac` — and pick up where you left off. For flaky mobile signal, `mosh` survives network changes far better than raw SSH.
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

- Setup skill and documentation by [Eli Groman](https://www.linkedin.com/in/eli-grumman-495b0636/) — Claude Code power user, $1,000+/month on Opus.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
