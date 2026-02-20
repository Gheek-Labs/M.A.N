# On-Chain Data Records

Post arbitrary data to the Minima blockchain permanently. Returns a `txpowid` — the on-chain proof.

**Related:** [COMMANDS.md](COMMANDS.md) | [RESPONSE_SCHEMAS.md](RESPONSE_SCHEMAS.md)

---

## AGENT WARNING — hash ≠ on-chain record

| Operation | What it does | Returns | On-chain? |
|-----------|-------------|---------|-----------|
| `hash data:hello` | Local Keccak-256 hash | `{ hash: "0x..." }` | **NO** — purely local, no txpowid |
| `record_data.sh "hello"` | Self-send with state data | `{ txpowid: "0x..." }` | **YES** — permanent on-chain record |

**The `hash` command does NOT write anything to the blockchain.** It computes a local hash. To create an on-chain record, you must post a transaction with your data embedded as state variables.

**The explorer link uses `txpowid`, not the hash output.** You cannot look up a `hash` result on the explorer — only `txpowid` values from actual transactions.

---

## How It Works

Minima transactions carry **state variables** (key 0–255) that are stored on-chain permanently. The recipe:

1. Hash your data locally (optional but recommended for large data)
2. Self-send a tiny amount (0.000000001 Minima) with your data in state variables
3. The transaction's `txpowid` is your permanent on-chain proof
4. Look it up: `https://explorer.minima.global/transactions/<txpowid>`

### State Variable Layout

| State Key | Purpose | Example |
|-----------|---------|---------|
| 0 | Data hash or raw data | `0x3a7b...` or `"hello world"` |
| 1 | Label / description | `"document-v2"` |
| 2 | Timestamp (ISO 8601) | `"2026-02-20T12:00:00Z"` |
| 3+ | Additional metadata | Any string |

---

## Shell Script

```bash
# Record a string on-chain
./minima/record_data.sh "hello world"

# Record with a label
./minima/record_data.sh "hello world" "my-label"

# Record a pre-computed hash
./minima/record_data.sh "0x3a7b2c..." "document-hash"
```

Output:
```json
{
  "txpowid": "0x1234abcd...",
  "explorer": "https://explorer.minima.global/transactions/0x1234abcd...",
  "data": "hello world",
  "label": "my-label"
}
```

---

## SDK Usage

### Python

```python
from minima_client import MinimaClient

client = MinimaClient()

# Record data on-chain
result = client.record_onchain("hello world", label="my-document")
print(result['txpowid'])       # 0x1234abcd...
print(result['explorer_url'])  # https://explorer.minima.global/transactions/0x1234abcd...

# Record a pre-computed hash
h = client.hash("large document content")
result = client.record_onchain(h['hash'], label="doc-hash")
```

### Node.js

```javascript
import { MinimaClient } from './minima-client.js';

const client = new MinimaClient();

// Record data on-chain
const result = await client.recordOnChain('hello world', { label: 'my-document' });
console.log(result.txpowid);      // 0x1234abcd...
console.log(result.explorerUrl);   // https://explorer.minima.global/transactions/0x1234abcd...

// Record a pre-computed hash
const h = await client.hash('large document content');
const result2 = await client.recordOnChain(h.hash, { label: 'doc-hash' });
```

---

## Common Mistakes

### 1. Using `hash` thinking it records on-chain

```python
# WRONG — this is purely local, nothing goes on-chain
result = client.hash("my data")
# result has no txpowid, no explorer link

# RIGHT — this posts to the blockchain
result = client.record_onchain("my data")
# result has txpowid and explorer_url
```

### 2. Using hash output as explorer link

```python
# WRONG — hash output is not a txpowid
h = client.hash("data")
url = f"https://explorer.minima.global/transactions/{h['hash']}"  # 404!

# RIGHT — use txpowid from an actual transaction
result = client.record_onchain("data")
url = result['explorer_url']  # works
```

### 3. Sending too much for a record

```python
# WRONG — wastes funds
client.send(my_address, 100, ...)  # don't need 100 Minima to record data

# RIGHT — record_onchain uses minimum amount (0.000000001)
client.record_onchain("data")
```

---

## Verification

To verify a record exists on-chain:

```bash
# By txpowid
./minima/cli.sh txpow txpowid:0x1234abcd...

# The state variables in the response contain your data
# Look for body.txn.state[0], state[1], etc.
```

---

## Cost

Each on-chain record costs **0.000000001 Minima** (one billionth). This is the minimum transaction amount. At current supply, this is effectively free for reasonable usage.

---

## Flow Diagram

```
Your Data
    │
    ▼
hash (optional) ──→ local hash (NOT on-chain)
    │
    ▼
record_onchain() ──→ self-send with state data
    │                     │
    │                     ▼
    │               Transaction posted
    │                     │
    │                     ▼
    │               txpowid returned ──→ explorer link
    │
    ▼
Verify: txpow txpowid:0x...
```
