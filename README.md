# M.A.N. — Minima Agentic Node

Agent-friendly, headless Minima blockchain node with stable MxID identity, natural language chat interface, and integration SDKs for Node.js and Python.

## Quick Start

```bash
./bootstrap.sh        # One-click setup (downloads JAR on first run, ~70MB)
./minima/start.sh     # Start the node
```

The node starts with RPC enabled on `localhost:9005`. Open the webview to access the chat interface on port 5000.

## Key Features

- **Natural language chat** — ask questions like "What's my balance?" and get answers (port 5000)
- **Integration SDKs** — Node.js and Python clients with normalized responses, retries, and balance safety
- **On-chain records** — post permanent data to the blockchain via transaction builder pipeline
- **Webhooks** — receive push notifications for new blocks, mining, transactions, and timers
- **MxID identity** — stable, reachable identity that survives restarts and IP changes
- **MDS (MiniDapps)** — serverless dapp infrastructure on port 9003
- **KISSVM scripting** — on-chain smart contract language reference
- **25 RPC command schemas** — machine-readable JSON schemas for all commands

## Agent Quickstart

**1. Run node:** `./minima/start.sh`

**2. Back up immediately:** `./minima/cli.sh vault` (view seed phrase)

**3. Initialize MxID:** `./minima/mxid_init.sh` (stable identity)

**4. Explore MDS:** `./minima/mds_list.sh --table` (view MiniDapps)

**5. Get Maxima address:** `./minima/get_maxima.sh`

**6. Send value:** `./minima/cli.sh "send address:MxG... amount:1"`

**7. Add contact:** `./minima/cli.sh "maxcontacts action:add contact:MxG...@IP:PORT"`

**8. Send message:** `./minima/cli.sh "maxima action:send to:MxG... application:app data:hello"`

See [AGENT_QUICKSTART.md](minima/AGENT_QUICKSTART.md) for full details.

## Chat Interface

A natural language interface to the Minima node, running on port 5000 via Flask.

Ask questions like:
- "What's my balance?"
- "Show node status"
- "Send 1 Minima to MxG08..."

Safe queries execute automatically. Transactions and sensitive operations (send, vault, backup) require confirmation.

### LLM Providers

| Provider | Variable | Notes |
|----------|----------|-------|
| OpenAI / Replit AI | `LLM_PROVIDER=openai` | Default, no API key needed on Replit |
| Anthropic (Claude) | `LLM_PROVIDER=anthropic` | Requires `ANTHROPIC_API_KEY` |
| Ollama (local) | `LLM_PROVIDER=ollama` | Local models, no API key |
| Custom (OpenAI-compatible) | `LLM_PROVIDER=custom` | Set `LLM_BASE_URL` and `LLM_API_KEY` |

Optional: set `LLM_MODEL` to override the default model for any provider.

## Integration SDKs

Use these instead of raw HTTP — they handle the LF-only response format, retries, and balance normalization.

### Node.js

```javascript
import { MinimaClient } from './integration/node/minima-client.js';

const client = new MinimaClient();           // default: localhost:9005
const status = await client.status();        // chain info
const bal    = await client.balance();       // normalized balances
const nfts   = await client.nfts();          // NFTs (decimals=0)
const addr   = await client.getaddress();    // receive address
const tx     = await client.send('MxG08...', 1);
```

### Python

```python
from minima_client import MinimaClient

client = MinimaClient()                      # default: localhost:9005
status = client.status()                     # chain info
bal    = client.balance()                    # normalized balances
nfts   = client.nfts()                       # NFTs (decimals=0)
addr   = client.getaddress()                 # receive address
tx     = client.send("MxG08...", 1)
```

### Shell

```bash
./minima/cli.sh status
./minima/cli.sh balance
./minima/cli.sh "send address:MxG08... amount:1"
```

### Balance Semantics — Important

> **`total` is NOT the wallet balance.** It is the token's max supply (~1 billion for Minima). This is the #1 integration mistake.

| Field | Meaning | Use for |
|-------|---------|---------|
| **`sendable`** | Spendable right now | **Primary balance display** |
| `confirmed` | Full wallet (includes locked) | Full balance |
| `unconfirmed` | Pending incoming | Pending indicator |
| `total` | Token max supply / hardcap | **NEVER display as balance** |

### LF-Only HTTP Responses

Minima RPC returns bare JSON with LF-only line endings (`\n`, no `\r`). Node.js `http.get()` may return garbled data. Always use the SDK clients or `fetch()`.

## On-Chain Records

Post permanent data to the blockchain. Returns a `txpowid` — the on-chain proof.

```bash
./minima/record_data.sh --data "sensor:42,ts:1700000000"
./minima/record_data.sh --data "event:alert" --port 100 --burn 0.01
./minima/record_data.sh --data "log:critical" --mine
```

SDK usage:

```javascript
const result = await client.recordOnChain('sensor:42,ts:1700000000');
// result.txpowid = "0x..."
```

```python
result = client.record_onchain("sensor:42,ts:1700000000")
# result["txpowid"] = "0x..."
```

See [ONCHAIN_RECORDS.md](minima/ONCHAIN_RECORDS.md) for the full transaction builder recipe and [KISSVM.md](minima/KISSVM.md) for the scripting language reference.

## Webhooks

Receive push notifications from the node via HTTP POST.

```bash
./minima/cli.sh "webhooks action:add hook:http://127.0.0.1:8099/events"
./minima/cli.sh "webhooks action:add hook:http://127.0.0.1:8099/blocks filter:NEWBLOCK"
```

| Event | Frequency | Description |
|-------|-----------|-------------|
| `NEWBLOCK` | ~50s | New block accepted |
| `MINING` | ~50s | Mining attempt started |
| `MDS_TIMER_10SECONDS` | 10s | Heartbeat |
| `MDS_TIMER_60SECONDS` | 60s | Slow heartbeat |
| `NEWTRANSACTION` | On activity | Wallet-relevant transaction |
| `NEWBALANCE` | On activity | Balance changed |

Webhooks are not persistent — re-register after node restart. See [WEBHOOKS.md](minima/WEBHOOKS.md) for payload examples and the [webhook listener template](templates/node-webhook-listener/).

## MxID — Stable Agent Identity

MxID is a reachable, stable identity that survives restarts, IP changes, and address rotation.

**Prerequisites:** `jq` installed

### Quick Setup (Wizard)
```bash
./minima/mxid_init.sh
```

The wizard auto-detects if your node can be its own MLS (public IP + port listening) and guides you through the entire setup.

### Manual Setup
```bash
./minima/mxid_setup_mls.sh          # 1. Set Static MLS
./minima/mxid_register_permanent.sh  # 2. Register Permanent MAX#
./minima/mxid_lockdown_contacts.sh   # 3. Lock down contacts
./minima/mxid_claim.sh               # 4. Claim MxID
```

### Identity Primitives
```bash
./minima/mxid_info.sh       # Identity card (JSON)
./minima/mxid_challenge.sh  # Generate verification challenge
./minima/mxid_sign.sh       # Sign data
./minima/mxid_verify.sh     # Verify signature
```

### MLS Auto-Detection

The wizard automatically selects the best MLS strategy:

| Mode | When Selected | Description |
|------|---------------|-------------|
| **Sovereign** | Public IP + port listening | Node is its own MLS |
| **Community** | Private IP + `COMMUNITY_MLS_HOST` set | Uses shared community MLS |
| **Manual** | Otherwise | User enters MLS manually |

Configure via environment variables:
```bash
COMMUNITY_MLS_HOST="Mx...@1.2.3.4:9001" ./minima/mxid_init.sh  # Fallback MLS
AUTO_DETECT_MLS=false ./minima/mxid_init.sh                    # Force manual
```

### Graduation to Sovereignty

If you start with community MLS, the wizard prints a single command to upgrade later:
```bash
./minima/cli.sh maxextra action:staticmls host:$(./minima/cli.sh maxima | jq -r '.response.p2pidentity')
```

After switching, re-register your Permanent MAX# on the new MLS.

Once claimed, publish: `"I'm MxID verified. MAX#0x3081...#Mx...@IP:PORT"`

## RPC Interface & Configuration

| Port | Protocol | Purpose | Access |
|------|----------|---------|--------|
| 5000 | HTTP | Chat interface (Flask) | Webview |
| 9001 | TCP | P2P network (peer sync) | Open |
| 9003 | HTTPS | MDS (MiniDapp System) | Password-protected, SSL |
| 9005 | HTTP | RPC API (all commands) | Local only |

| Setting | Value |
|---------|-------|
| Data Dir | `./minima/data` |
| Bootstrap Node | `megammr.minima.global:9001` |

### CLI Commands
```bash
./minima/cli.sh status     # Node status
./minima/cli.sh balance    # Wallet balance
./minima/get_maxima.sh     # Current Maxima address
```

### HTTP API
```bash
curl http://localhost:9005/status
curl http://localhost:9005/balance
curl "http://localhost:9005/maxima%20action:info"
```

### Response Schemas

All 25 RPC commands have documented response schemas:
- Human-readable: [RESPONSE_SCHEMAS.md](minima/RESPONSE_SCHEMAS.md)
- Machine-readable: `minima/rpc/schemas/*.schema.json`

## MDS (MiniDapp System)

MDS provides a web interface for MiniDapps on port 9003.

**Security:**
- SSL-encrypted connection
- High-entropy password required (16+ chars, mixed case, numbers, symbols)
- Password set via `MDS_PASSWORD` secret, or auto-generated on startup
- Block port 9003 at firewall if external access not needed

**Access:** `https://localhost:9003`

**Commands:**
```bash
./minima/cli.sh mds              # Show MDS status
./minima/cli.sh mds action:list  # List installed MiniDapps
```

| Script | Purpose |
|--------|---------|
| `mds_install.sh` | Install MiniDapp from URL or file |
| `mds_list.sh` | List installed MiniDapps with session IDs |
| `mds_api.sh` | Send API requests to installed MiniDapps |
| `mds_store.sh` | Add/list/browse community MiniDapp stores |

See [MINIDAPPS.md](minima/MINIDAPPS.md) for detailed documentation and community store directory.

## Templates

Reference implementations for common integration patterns:

| Template | Language | Description |
|----------|----------|-------------|
| [node-web-dashboard](templates/node-web-dashboard/) | Node.js/Express | Web dashboard with correct 3-balance display |
| [node-webhook-listener](templates/node-webhook-listener/) | Node.js | Zero-dependency webhook event listener |
| [python-bot](templates/python-bot/) | Python | Periodic balance and status monitor |
| [ros2-bridge](templates/ros2-bridge/) | Python/ROS2 | Bridge Minima RPC to ROS2 topics (status + balance as messages) |

## Documentation

| Document | Description |
|----------|-------------|
| [Agent Quickstart](minima/AGENT_QUICKSTART.md) | Essential operations for agents |
| [Commands Reference](minima/COMMANDS.md) | Full RPC command list |
| [Response Schemas](minima/RESPONSE_SCHEMAS.md) | Field semantics for all 25 commands |
| [On-Chain Records](minima/ONCHAIN_RECORDS.md) | Transaction builder recipe |
| [KISSVM Glossary](minima/KISSVM.md) | Scripting language reference |
| [Webhooks](minima/WEBHOOKS.md) | Event catalog and payload docs |
| [MxID Specification](minima/MXID.md) | Stable identity system |
| [MiniDapps Guide](minima/MINIDAPPS.md) | Serverless dapp infrastructure |
| [Backup & Restore](minima/BACKUP.md) | Backup, restore, and resync guide |
| [Full Feature List](FEATURES.md) | Complete capabilities overview |

## Project Structure

```
/
├── bootstrap.sh                   # One-click setup script
├── main.py                        # Entry point
├── replit.md                      # Project context (agent persistent memory)
├── .agents/skills/                # Agent skills
│   └── minima-integration/        # Minima integration skill (SKILL.md)
├── chat/                          # Natural language chat interface
│   ├── app.py                     # Flask web server (port 5000)
│   ├── minima_agent.py            # LLM agent + command execution
│   ├── providers/                 # LLM provider abstraction
│   │   ├── base.py                # Abstract base class
│   │   ├── openai_provider.py     # OpenAI / Replit AI
│   │   ├── anthropic_provider.py  # Claude
│   │   ├── ollama_provider.py     # Local models
│   │   └── custom_provider.py     # OpenAI-compatible endpoints
│   ├── templates/                 # HTML templates
│   └── static/                    # CSS styles
├── integration/                   # Language SDKs
│   ├── node/
│   │   └── minima-client.js       # Node.js RPC client (ESM, JSDoc typed)
│   └── python/
│       └── minima_client.py       # Python RPC client
├── minima/
│   ├── minima.jar                 # Minima node JAR (downloaded on first run)
│   ├── start.sh                   # Node startup script
│   ├── cli.sh                     # Agent-friendly CLI wrapper
│   ├── record_data.sh             # Post data on-chain (--data/--port/--burn/--mine)
│   ├── get_maxima.sh              # Get current Maxima address
│   ├── mds_install.sh             # Install MiniDapps
│   ├── mds_list.sh                # List installed MiniDapps
│   ├── mds_api.sh                 # Call MiniDapp API endpoints
│   ├── mds_store.sh               # Manage MiniDapp stores
│   ├── mxid_init.sh               # Full MxID wizard
│   ├── mxid_setup_mls.sh          # Set Static MLS
│   ├── mxid_register_permanent.sh # Register Permanent MAX#
│   ├── mxid_lockdown_contacts.sh  # Contact anti-spam
│   ├── mxid_claim.sh              # Claim MxID identity
│   ├── mxid_info.sh               # Identity card JSON
│   ├── mxid_challenge.sh          # Generate verification challenge
│   ├── mxid_sign.sh               # Sign with Maxima key
│   ├── mxid_verify.sh             # Verify signature
│   ├── COMMANDS.md                # Full RPC command reference
│   ├── RESPONSE_SCHEMAS.md        # Response field semantics (25 commands)
│   ├── ONCHAIN_RECORDS.md         # On-chain data record guide
│   ├── KISSVM.md                  # KISSVM scripting language glossary
│   ├── WEBHOOKS.md                # Webhook event catalog
│   ├── MXID.md                    # MxID specification
│   ├── MINIDAPPS.md               # MiniDapp guide
│   ├── BACKUP.md                  # Backup, restore, resync guide
│   ├── AGENT_QUICKSTART.md        # Agent operations guide
│   ├── rpc/schemas/               # Machine-readable JSON schemas
│   └── data/                      # Node data directory (gitignored)
├── templates/                     # Reference implementations
│   ├── node-web-dashboard/        # Express dashboard (3-balance display)
│   ├── node-webhook-listener/     # Webhook event listener (zero-dep Node.js)
│   ├── python-bot/                # CLI balance/status monitor
│   └── ros2-bridge/               # ROS2 topic bridge skeleton
└── FEATURES.md                    # Complete feature list
```

## MxID Scripts Reference

| Script | Purpose |
|--------|---------|
| `mxid_init.sh` | Full wizard with auto-detection |
| `mxid_setup_mls.sh` | Set Static MLS host |
| `mxid_register_permanent.sh` | Register Permanent MAX# |
| `mxid_lockdown_contacts.sh` | Disable unsolicited contacts |
| `mxid_claim.sh` | Claim and print MxID |
| `mxid_info.sh` | Output identity card (JSON) |
| `mxid_challenge.sh` | Generate 32-byte challenge |
| `mxid_sign.sh` | Sign data with Maxima key |
| `mxid_verify.sh` | Verify signature |
