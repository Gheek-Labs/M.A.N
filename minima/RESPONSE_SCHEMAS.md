# Minima RPC Response Schemas

Human/agent-readable guide to Minima RPC response formats with semantic annotations and agent warnings.

**Machine-readable schemas:** `minima/rpc/schemas/*.schema.json`

**Language integration kits:** `integration/python/minima_client.py` | `integration/node/minima-client.js`

**Full command reference:** [COMMANDS.md](COMMANDS.md)

---

## General Response Format

Every RPC response follows this envelope:

```json
{
  "command": "status",
  "status": true,        // true = success, false = error
  "pending": false,      // true if command is async
  "response": { ... },   // Command-specific payload (object or array)
  "error": "..."         // Only present when status is false
}
```

> **AGENT WARNING:** Always check `status` before reading `response`. When `status` is `false`, `response` may be absent and `error` will contain the failure reason.

### Type Conventions

Minima RPC uses **mixed types** — some numeric fields are integers, some are strings. This table shows the actual types returned by the live node:

| Pattern | Examples | Actual Type |
|---------|----------|-------------|
| Block numbers, counts, sizes | `status.length`, `chain.block`, `chain.size`, `txpow.mempool`, `network.port` | **integer** |
| Large numbers, amounts | `weight`, `minima`, `coins`, `confirmed`, `sendable`, `amount` | **string** |
| Hash/address values | `hash`, `address`, `publickey`, `coinid` | **string** (0x-prefixed) |
| Block speed | `chain.speed` | **float** |
| Booleans | `locked`, `hostset`, `staticmls` | **boolean** |

> **AGENT WARNING:** Do NOT assume all numeric fields are strings. Use `_safe_int()` / `safeInt()` wrappers which handle both int and string inputs.

---

## balance

Returns token balances for this node's wallet.

```json
{ "status": true, "response": [{
  "token": "Minima",
  "tokenid": "0x00",
  "confirmed": "12",
  "unconfirmed": "0",
  "sendable": "12",
  "coins": "27",
  "total": "1000000000"
}]}
```

| Field | Type | Meaning |
|-------|------|---------|
| `token` | string | Token display name |
| `tokenid` | string | Token ID. `0x00` = native Minima |
| `confirmed` | string | Full wallet balance (includes locked coins) |
| `unconfirmed` | string | Received but pending confirmation |
| `sendable` | string | **Available to spend** (confirmed minus locked) |
| `coins` | string | Number of UTXO coins for this token |
| `total` | string | **TOKEN MAX SUPPLY / HARDCAP** |

> **AGENT WARNING — `total` is a trap:**
> `total` is the token's maximum supply (~1 billion for Minima), **NOT** your wallet balance.
> - Display `sendable` as the **primary balance** (what the user can spend).
> - Display `confirmed` as the full wallet balance.
> - Display `unconfirmed` as pending incoming.
> - **NEVER** display `total` as a balance.

### balance tokendetails:true

When called with `tokendetails:true`, returns richer metadata for custom tokens:

```json
{ "status": true, "response": [{
  "token": "Minima",
  "tokenid": "0x00",
  "confirmed": "12",
  "unconfirmed": "0",
  "sendable": "12",
  "coins": "27",
  "total": "1000000000"
}, {
  "token": {
    "name": "porq",
    "url": "<artimage>/9j/4AAQ...",
    "description": "Welcome to the porq network...",
    "ticker": "porq",
    "webvalidate": ""
  },
  "tokenid": "0x050DFE5A...",
  "confirmed": "10",
  "unconfirmed": "0",
  "sendable": "10",
  "coins": "1",
  "total": "1000000000000",
  "details": {
    "decimals": 8,
    "script": "RETURN TRUE",
    "totalamount": "0.000000000000000000000001",
    "scale": "36",
    "created": "794199"
  }
}]}
```

| Field | Type | Meaning |
|-------|------|---------|
| `token` | string or object | For native Minima: string `"Minima"`. For custom tokens: object with `name`, `url`, `description`, `ticker`, `webvalidate` |
| `details.decimals` | **integer** | Decimal places. **0 = NFT** (non-fungible, indivisible) |
| `details.script` | string | Token script |
| `details.totalamount` | string | Total in smallest unit |
| `details.scale` | string | Scale factor |
| `details.created` | string | Block number when created |

> **NFT Detection:** Filter for `details.decimals == 0` to find Non-Fungible Tokens.
> The `decimals:0` filter is **not** a server-side parameter — filter client-side after fetching.
> SDK provides `nfts()` method for convenience.

---

## status

Returns general node info: version, chain height, memory, connected peers.

```json
{ "status": true, "response": {
  "version": "1.0.46.8",
  "uptime": "0 Years 0 Months 0 Weeks 0 Days 1 Hours 5 Minutes 30 Seconds",
  "locked": false,
  "length": 5328,
  "weight": "815010928291270",
  "minima": "999979665.55068805473389496137790014706585395910793557",
  "coins": "1328161",
  "data": "/home/runner/workspace/minima/data/1.0",
  "memory": {
    "ram": "405.8 MB",
    "disk": "1.0 GB",
    "files": { ... }
  },
  "chain": {
    "block": 1958640,
    "time": "Fri Feb 20 10:59:14 GMT 2026",
    "hash": "0x00000020243A...",
    "speed": 0.020941,
    "difficulty": "0x00000050B884...",
    "size": 2072,
    "length": 2070,
    "branches": 2,
    "weight": "107983317170",
    "cascade": { ... }
  },
  "txpow": {
    "mempool": 1,
    "ramdb": 19055,
    "txpowdb": 19051,
    "archivedb": 100001
  },
  "network": {
    "host": "172.31.116.66",
    "hostset": false,
    "port": 9001,
    "connecting": 0,
    "connected": 5,
    "rpc": { "enabled": true, "port": 9005 }
  }
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `version` | string | Minima version |
| `uptime` | string | Human-readable uptime |
| `locked` | boolean | Whether wallet keys are password-locked |
| `length` | **integer** | Chain height |
| `weight` | string | Chain weight (large number) |
| `minima` | string | Total Minima in circulation (decimal string) |
| `coins` | string | Total UTXOs |
| `chain.block` | **integer** | Current block number |
| `chain.time` | string | Block timestamp as human-readable date (NOT millis) |
| `chain.speed` | **float** | Block speed |
| `chain.size` | **integer** | Chain tree size |
| `chain.length` | **integer** | Chain tree length |
| `chain.branches` | **integer** | Active branches |
| `txpow.mempool` | **integer** | Pending transactions |
| `txpow.ramdb` | **integer** | RAM DB entries |
| `txpow.txpowdb` | **integer** | TxPoW DB entries |
| `txpow.archivedb` | **integer** | Archive DB entries |
| `network.host` | string | Node IP address |
| `network.hostset` | boolean | Whether host was manually set |
| `network.port` | **integer** | P2P port |
| `network.connected` | **integer** | Active peer connections |

> **AGENT WARNING:**
> - The `devices` field does **NOT** exist in the status response.
> - `length`, `chain.block`, `chain.size`, `chain.length`, all `txpow.*`, `network.port`, `network.connected` are **integers** (not strings).
> - `weight`, `minima`, `coins` remain **strings** (large numbers).
> - `chain.speed` is a **float**.
> - `chain.time` is a date string like `"Fri Feb 20 10:59:14 GMT 2026"`, NOT millis.

---

## send

Send Minima or tokens to an address. Returns full TxPoW on success.

**Parameters:** `address:MxG... amount:1 (tokenid:0x00) (split:N) (burn:N)`

### Success response:
```json
{ "status": true, "response": {
  "txpowid": "0xE121FF1C82B2B1E50A...",
  "isblock": false,
  "istransaction": false,
  "size": 5302,
  "burn": 0,
  "header": {
    "block": "1931455",
    "timemilli": "1770223384435",
    "date": "Wed Feb 04 16:43:04 GMT 2026"
  },
  "body": {
    "txn": {
      "inputs": [{ "coinid": "0x...", "amount": "2", "address": "0x...", "miniaddress": "MxG08...", "tokenid": "0x00" }],
      "outputs": [
        { "coinid": "0x...", "amount": "1", "address": "0x...", "miniaddress": "MxG08...", "tokenid": "0x00" },
        { "coinid": "0x...", "amount": "1", "address": "0x...", "miniaddress": "MxG08...", "tokenid": "0x00" }
      ],
      "transactionid": "0x8446..."
    }
  }
}}
```

### Error response:
```json
{ "status": false, "error": "Insufficient funds" }
```

| Field | Type | Meaning |
|-------|------|---------|
| `txpowid` | string | Transaction ID for explorer: `https://explorer.minima.global/transactions/<txpowid>` |
| `header.block` | string | Block height at transaction time |
| `header.timemilli` | string | Unix timestamp in milliseconds |
| `body.txn.inputs` | array | Coins consumed by this transaction |
| `body.txn.outputs` | array | Coins created (destination + change) |
| `body.txn.transactionid` | string | Internal tx hash (different from `txpowid`) |

> **AGENT WARNING:**
> - `txpowid` is the external transaction ID. Use it for explorer links.
> - `transactionid` is the internal hash — do **not** use for explorer links.
> - `amount` fields in inputs/outputs are **strings**.
> - `split:N` parameter (1-10) divides the amount into multiple output coins.
> - Use `getaddress` first to get own address for self-splits.

---

## hash

Hash data using Minima's Keccak-256 / SHA3 hash function.

> **AGENT WARNING — LOCAL OPERATION ONLY:**
> `hash` computes a hash locally. It does **NOT** write anything to the blockchain and does **NOT** return a `txpowid`. The hash output **cannot** be looked up on the explorer.
>
> To create an **on-chain record**, use `record_data.sh` or the SDK `recordOnChain()` / `record_onchain()` method instead. See [ONCHAIN_RECORDS.md](ONCHAIN_RECORDS.md).
>
> **Explorer links use `txpowid` (from transactions), not hash output.**

**Parameters:** `data:hello` or `data:0xABCD`

```json
{ "status": true, "response": {
  "input": "hello",
  "data": "0x68656C6C6F",
  "type": "sha3",
  "hash": "0x3338BE694F50C5F338814986CDF0686453A888B84F424D792AF4B9202398F392"
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `input` | string | Original input as provided |
| `data` | string | Input converted to hex (0x-prefixed) |
| `type` | string | Hash algorithm used (e.g., "sha3") |
| `hash` | string | Hash result, `0x`-prefixed. **Local only — not a txpowid, not on-chain.** |

---

## random

Generate cryptographic random data using Minima's internal RNG.

```json
{ "status": true, "response": {
  "size": "32",
  "random": "0x63733C4E9DB63E81B41B199118602DD7A2F687886EE9D8BD930FAAC76D7F2D09",
  "hashed": "0x11132C83AC8B435DBB857D502E374E0AA81A67541D1A835ACC9C6B092AC38CA0",
  "type": "sha3",
  "keycode": "ZRJ7-79RD-UG6Q-M6CH-1G2R"
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `size` | string | Byte size of random data |
| `random` | string | Raw random value, `0x`-prefixed |
| `hashed` | string | SHA3 hash of the random value |
| `type` | string | Hash algorithm used |
| `keycode` | string | Human-readable keycode form (e.g., "ZRJ7-79RD-UG6Q-M6CH-1G2R") |

---

## tokens

List all tokens known to this node.

```json
{ "status": true, "response": [{
  "name": "Minima",
  "tokenid": "0x00",
  "total": "1000000000",
  "decimals": 44,
  "scale": 1
}]}
```

| Field | Type | Meaning |
|-------|------|---------|
| `tokenid` | string | Token ID. `0x00` = native Minima |
| `name` | string or object | Token name. **NOTE: This field is `name` in `tokens`, but `token` in `balance`** |
| `total` | string | Token total supply (**NOT wallet balance**) |
| `decimals` | **integer** | Decimal places. **NOT a string** |
| `scale` | **integer** | Scale factor. **NOT a string** |

For custom tokens, additional fields appear: `script`, `coinid`, `totalamount`.

> **AGENT WARNING:**
> - `total` is the same concept as `balance.total` — it's the token supply, not how much you have.
> - The token name field is **`name`** in this response, but **`token`** in the balance response.
> - `decimals` and `scale` are **integers**, not strings (unlike most other numeric fields).
> - For custom tokens, `name` can be an **object** with `name`/`url`/`description`/`ticker`.

---

## getaddress

Get the node's current default receiving address.

```json
{ "status": true, "response": {
  "script": "RETURN SIGNEDBY(0x364BDF...)",
  "address": "0x6CE21C6073E84C8EACD64B9A70606343AA4AD19049F241E8C90CD570E5DF4B90",
  "miniaddress": "MxG083CS8E60SV89W7APYWBJ9Z60ZQ3Y95D3429U90UHW8CQYZEBNQBW08JZF7U",
  "simple": true,
  "default": true,
  "publickey": "0x364BDF449C0BB5D58636CE33DC55E59D7C920191A1F188AADA6BFD956743A8B3",
  "track": true
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `script` | string | Script associated with this address |
| `address` | string | Hex address (`0x`-prefixed) |
| `miniaddress` | string | Human-readable `MxG`-prefixed address |
| `simple` | boolean | Whether this is a simple SIGNEDBY address |
| `default` | boolean | Whether this is the default address |
| `publickey` | string | Associated public key |
| `track` | boolean | Whether this address is tracked for balance |

---

## maxima action:info

Get your Maxima identity and contact details.

```json
{ "status": true, "response": {
  "name": "PETER",
  "icon": "0x00",
  "publickey": "0x30819F300D...",
  "mxpublickey": "MxG18HGG6FJ038...",
  "staticmls": true,
  "mls": "MxG18HGG6FJ038...",
  "localidentity": "MxG18HGG6FJ038...@192.168.1.1:9001",
  "p2pidentity": "MxG18HGG6FJ038...@1.2.3.4:9001",
  "contact": "MxG18HGG6FJ038...",
  "logs": false,
  "poll": 0
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | Display name (set with `maxima action:setname`) |
| `icon` | string | Icon data (0x-prefixed hex) |
| `publickey` | string | Your Maxima RSA public key |
| `mxpublickey` | string | Mx-formatted public key |
| `staticmls` | boolean | Whether static MLS is configured |
| `mls` | string | MLS host address |
| `localidentity` | string | Local network identity |
| `p2pidentity` | string | Public network identity |
| `contact` | string | Full contact address for sharing |
| `logs` | boolean | Whether Maxima logging is enabled |
| `poll` | integer | Poll count |

> **AGENT WARNING:** `localidentity` vs `p2pidentity` — use `p2pidentity` for external/public contacts. `localidentity` is only reachable on the local network.

---

## maxcontacts action:list

List all Maxima contacts.

```json
{ "status": true, "response": [{
  "id": 0,
  "publickey": "0x3081...",
  "currentaddress": "Mx...@1.2.3.4:9001",
  "myaddress": "Mx...@1.2.3.4:9001",
  "lastseen": "1706900000000",
  "date": "Wed Feb 04 16:43:04 GMT 2026",
  "extradata": {
    "name": "Alice",
    "minimaaddress": "MxG08...",
    "topblock": "1931455",
    "checkblock": "1931400",
    "checkhash": "0xABC..."
  },
  "samechain": true
}]}
```

| Field | Type | Meaning |
|-------|------|---------|
| `id` | integer | Contact ID (use for send-by-ID) |
| `publickey` | string | Contact's Maxima public key |
| `currentaddress` | string | Contact's current reachable address |
| `lastseen` | string | Unix timestamp in millis (STRING) |
| `extradata.name` | string | Contact's display name |
| `samechain` | boolean | Whether contact is on same chain |

---

## block

Get current top block info.

```json
{ "status": true, "response": {
  "block": "1958640",
  "hash": "0x00000020243A9B0594EF3241CAE8412F7E422C209CF3507B47E939D773B31CC9",
  "timemilli": "1771585154119",
  "date": "Fri Feb 20 10:59:14 GMT 2026"
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `block` | string | Block number (**string** here, unlike `status.chain.block` which is int) |
| `hash` | string | Block hash (0x-prefixed) |
| `timemilli` | string | Unix timestamp in milliseconds |
| `date` | string | Human-readable date |

---

## coins

List coins (UTXOs). Use `relevant:true` to show only your coins.

```json
{ "status": true, "response": [{
  "coinid": "0x38EF6CA4AB67...",
  "amount": "1",
  "address": "0xF5A56FE8D41...",
  "miniaddress": "MxG087YKYNUHY...",
  "tokenid": "0x00",
  "token": null,
  "storestate": true,
  "state": [],
  "spent": false,
  "mmrentry": "1323658",
  "created": "1946515",
  "age": "12125"
}]}
```

| Field | Type | Meaning |
|-------|------|---------|
| `coinid` | string | Unique coin identifier |
| `amount` | string | Coin value |
| `address` | string | Owning address (hex) |
| `miniaddress` | string | Owning address (MxG format) |
| `tokenid` | string | Token this coin holds |
| `token` | null or object | Token details (null for native Minima) |
| `storestate` | boolean | Whether state is stored |
| `state` | array | State variables attached to this coin |
| `spent` | boolean | Whether coin has been spent |
| `mmrentry` | string | MMR tree entry index |
| `created` | string | Block number when created |
| `age` | string | Number of blocks since creation |

---

## network

Get network connection details.

```json
{ "status": true, "response": {
  "connections": [
    {
      "welcome": "Minima v1.0.46",
      "uid": "3M7O7UFNVR0EV",
      "incoming": false,
      "host": "89.117.60.213",
      "port": 9001,
      "minimaport": 9001,
      "isconnected": true,
      "valid": true,
      "connected": "Fri Feb 20 10:41:58 GMT 2026"
    }
  ],
  "details": {
    "host": "172.31.116.66",
    "hostset": false,
    "port": 9001,
    "connecting": 0,
    "connected": 5,
    "rpc": { "enabled": true, "port": 9005 },
    "p2p": {
      "address": "34.45.188.99:9001",
      "isAcceptingInLinks": true,
      "numInLinks": 0,
      "numOutLinks": 5
    }
  }
}}
```

---

## peers

Get known peers list.

```json
{ "status": true, "response": {
  "peerslist": "157.173.118.242:9001,185.244.181.58:9001,...",
  "size": 46,
  "havepeers": true,
  "p2penabled": true
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `peerslist` | string | Comma-separated list of peer addresses |
| `size` | integer | Number of known peers |
| `havepeers` | boolean | Whether any peers are known |
| `p2penabled` | boolean | Whether P2P is enabled |

---

## backup

Create a backup of the node.

**Parameters:** `(password:YourPassword)`

```json
{ "status": true, "response": {
  "backup": {
    "file": "/path/to/minima-backup-2026-02-04.bak",
    "size": "2.1MB"
  }
}}
```

> **AGENT WARNING:** Backups contain private keys. Always encrypt with a password. Never transmit unencrypted backups.

---

## vault action:seed

Show seed phrase and lock status.

```json
{ "status": true, "response": {
  "phrase": "word1 word2 word3 ... word24",
  "seed": "0xABCD...",
  "locked": false
}}
```

| Field | Type | Meaning |
|-------|------|---------|
| `phrase` | string | 24-word seed phrase |
| `seed` | string | Seed as hex |
| `locked` | boolean | Whether keys are password-locked |

> **AGENT WARNING:** This command exposes the seed phrase. **Never log, display, or transmit it.** This is the master key — if lost, funds are unrecoverable. Always require user confirmation before executing `vault`.
