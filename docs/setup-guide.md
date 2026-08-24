# Setup Guide — Run Claude Code Agents From Your Phone

A complete, from-scratch guide to the setup **eli** installs for you: a cloud server running a fleet of Claude Code agents, reachable from anywhere over Tailscale, driven from an Android phone via Termux. No bot, no custom daemon — just SSH + Claude Code.

> **The whole flow in one line:**
> Phone (Termux) → `ssh mac` → `cd` into a project → `claude` → pick the relevant agent → keep working.

All server IPs, usernames, and hostnames below are placeholders like `<SERVER_IP>`, `<USER>`, `<TAILNET_IP>`. Swap in your own.

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

## 1. Provision the server (Hetzner Cloud)

1. Make a [Hetzner Cloud](https://www.hetzner.com/cloud) account → new project → **Add Server**.
2. Recommended box: **CX43** — 4 vCPU, 16 GB RAM, 160 GB SSD, ~$14/month. Comfortably runs 3+ concurrent Claude Code agents. (Smaller CX-series works for 1–2 agents; more RAM = more parallel agents.)
3. **Image:** Ubuntu 24.04 LTS.
4. **SSH key:** paste your phone's *and* your Mac's public key here now (see step 2) so you can log in without a password. You can also add keys later.
5. Create. Note the **public IPv4** — that's your `<SERVER_IP>`.

First login and hardening:
```bash
ssh root@<SERVER_IP>

# Create a non-root user you'll actually work as
adduser <USER>
usermod -aG sudo <USER>

# (optional but recommended) disable password login once keys work
# in /etc/ssh/sshd_config set:  PasswordAuthentication no
sudo systemctl restart ssh
```

---

## 2. SSH keys (phone + Mac → server)

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

If your Mac and server should also SSH to each other, repeat the same: generate a key on the Mac, add its pubkey to the server (and vice-versa). This is exactly the "pubkey on Mac + on the Hetzner server" step.

---

## 3. Tailscale (reach the server from anywhere)

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
- If you want the box reachable by name, enable **MagicDNS** in the Tailscale admin console.

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
- `pkg install openssh mosh` — **mosh** survives network changes / spotty signal far better than raw SSH for mobile use.
- Termux widgets let you put a one-tap `ssh mac` button on your home screen.

---

## 5. Install Claude Code on the server

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

# jump into the project I want to work on
cd ~/investor

# start Claude Code — it loads CLAUDE.md + available agents automatically
claude

# then, in the session:
#   - pick the relevant agent from the picker, or
#   - let the main session delegate to subagents, or
#   - check on the always-on fleet jobs and steer them
```
That's it. The agents keep running on the server whether or not my phone is connected; SSH is just the window I look through. Disconnect the phone, the work continues; reconnect later, pick up where it left off.

---

## Recap checklist

- [ ] Hetzner CX43, Ubuntu 24.04, non-root sudo user
- [ ] ed25519 keypair on phone (Termux) **and** Mac; both pubkeys in server `~/.ssh/authorized_keys`
- [ ] Tailscale installed + logged in on server, Mac, and phone (same account)
- [ ] `~/.ssh/config` `Host mac` shortcut in Termux (tailnet IP, keepalive)
- [ ] Node + Claude Code CLI + uv installed on server; `claude` authed once
- [ ] Per-project `CLAUDE.md`, `.claude/agents/*.md`, and/or `.claude/skills/<agent>/` defining each agent
- [ ] `ssh mac` → `cd project` → `claude` → work
