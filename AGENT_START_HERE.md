# START HERE — Agent Onboarding

**You must complete the bootstrap sequence below before using any SDKs, templates, chat interface, or advanced features.**

Skipping these steps will result in an unstable node, missing identity, and no backup.

## Mandatory Bootstrap Sequence

### Step 1: Initialize the node

```bash
./bootstrap.sh
```

This downloads the Minima JAR (~70MB on first run) and prepares the environment.

### Step 2: Start the node

```bash
./minima/start.sh
```

Or use the configured "Minima Node" workflow (auto-starts).

**Verify it's running:**

```bash
./minima/cli.sh status
```

Wait until `status: true` and you see a non-zero `chain.block` value. The node needs a few seconds to sync.

### Step 3: Back up immediately

**Do this before anything else. If you lose your seed phrase, everything is unrecoverable.**

```bash
./minima/cli.sh vault
```

Write down the seed phrase. Then create an encrypted backup:

```bash
./minima/cli.sh backup password:YourStrongPassword123
```

### Step 4: Initialize MxID (stable identity)

MxID gives your agent a reachable, stable identity that survives restarts and IP changes.

```bash
./minima/mxid_init.sh
```

The wizard auto-detects your MLS mode (Sovereign, Community, or Manual) and walks you through the full setup.

**Prerequisite:** `jq` must be installed.

### Step 5: Verify peers and connectivity

```bash
./minima/cli.sh peers
./minima/cli.sh network
```

Confirm you have connected peers (typically 2-5). If zero peers, wait a minute — P2P discovery takes time.

---

## You Are Now Ready

Once all 5 steps are complete, your node is bootstrapped, backed up, and has a stable identity. Now you can explore:

| What | Where |
|------|-------|
| Full agent operations guide | [`minima/AGENT_QUICKSTART.md`](minima/AGENT_QUICKSTART.md) |
| Integration SDKs (Node.js + Python) | [`integration/`](integration/) |
| Natural language chat interface | Port 5000 (open webview) |
| On-chain records | [`minima/ONCHAIN_RECORDS.md`](minima/ONCHAIN_RECORDS.md) |
| Webhooks | [`minima/WEBHOOKS.md`](minima/WEBHOOKS.md) |
| MDS MiniDapps | [`minima/MINIDAPPS.md`](minima/MINIDAPPS.md) |
| Templates (dashboard, bot, ROS2, webhook listener) | [`templates/`](templates/) |
| Full RPC command reference | [`minima/COMMANDS.md`](minima/COMMANDS.md) |
| Response schemas (25 commands) | [`minima/RESPONSE_SCHEMAS.md`](minima/RESPONSE_SCHEMAS.md) |
| Agent integration skill (for Replit Agent) | [`.agents/skills/minima-integration/SKILL.md`](.agents/skills/minima-integration/SKILL.md) |

## Common Bootstrap Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Skipping backup | Seed phrase lost forever if node data corrupted | Run `vault` immediately after first start |
| Skipping MxID | No stable identity; Maxima address rotates every few minutes | Run `mxid_init.sh` after backup |
| Using SDK before node is running | `ECONNREFUSED` on port 9005 | Start node first, verify with `cli.sh status` |
| Displaying `total` as balance | Shows ~1 billion instead of actual balance | Always use `sendable` field |
