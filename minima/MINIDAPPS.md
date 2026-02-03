# MiniDapps - Serverless Dapp Infrastructure

MiniDapps are decentralized applications that run locally on your Minima node. They provide serverless, censorship-resistant functionality without relying on external servers.

**Key Properties:**
- Run entirely on your node (no external servers)
- Access blockchain state and Maxima messaging
- Persistent storage via node's SQL database
- SSL-encrypted MDS interface (port 9003)

---

## Quick Reference

| Script | Purpose |
|--------|---------|
| `mds_list.sh` | List installed MiniDapps |
| `mds_install.sh` | Install from URL or file |
| `mds_api.sh` | Call MiniDapp APIs |

---

## Core MiniDapps for Agents

### Wallet (v3.0.17)
**Purpose:** Manage Minima funds and tokens.

**Agent Use Cases:**
- Check balances programmatically
- Send/receive payments
- Track transaction history

**API Examples:**
```bash
./minima/mds_api.sh wallet /service.js '{"action":"balance"}'
./minima/mds_api.sh wallet /service.js '{"action":"send","address":"Mx...","amount":"1"}'
```

---

### Soko (v1.0.1)
**Purpose:** Decentralized NFT marketplace.

**Agent Use Cases:**
- List NFTs for sale
- Browse and purchase NFTs
- Manage digital collectibles

**API Examples:**
```bash
./minima/mds_api.sh soko /service.js '{"action":"getorders"}'
./minima/mds_api.sh soko /service.js '{"action":"list","tokenid":"0x..."}'
```

---

### Miniswap (v2.20.0)
**Purpose:** Decentralized exchange (DEX) for token swaps.

**Agent Use Cases:**
- Swap tokens OTC
- Provide liquidity
- Check order book

**API Examples:**
```bash
./minima/mds_api.sh miniswap /service.js '{"action":"getpairs"}'
./minima/mds_api.sh miniswap /service.js '{"action":"getorders"}'
```

---

### Token Studio (v1.5.0)
**Purpose:** Create custom tokens and NFTs.

**Agent Use Cases:**
- Mint new tokens
- Create NFT collections
- Define token properties

**API Examples:**
```bash
./minima/mds_api.sh "token studio" /service.js '{"action":"create","name":"MyToken","amount":"1000"}'
```

---

### MaxSolo (v2.7.2)
**Purpose:** P2P encrypted chat over Maxima.

**Agent Use Cases:**
- Agent-to-agent messaging
- Encrypted communications
- Contact management

**API Examples:**
```bash
./minima/mds_api.sh maxsolo /service.js '{"action":"getcontacts"}'
./minima/mds_api.sh maxsolo /service.js '{"action":"send","to":"0x...","message":"hello"}'
```

---

### ChainMail (v1.12.5)
**Purpose:** Encrypted on-chain messaging.

**Agent Use Cases:**
- Send permanent on-chain messages
- Retrieve message history
- Encrypted correspondence

**API Examples:**
```bash
./minima/mds_api.sh chainmail /service.js '{"action":"inbox"}'
./minima/mds_api.sh chainmail /service.js '{"action":"send","to":"Mx...","message":"..."}'
```

---

### MaxContacts (v1.14.0)
**Purpose:** Manage Maxima contacts.

**Agent Use Cases:**
- Add/remove contacts
- View contact list
- Sync contact info

**API Examples:**
```bash
./minima/mds_api.sh maxcontacts /service.js '{"action":"list"}'
```

---

### MiniFS (v1.4.4)
**Purpose:** Decentralized file storage (broadcast system).

**Agent Use Cases:**
- Store files on-chain
- Share data publicly
- Retrieve shared files

**API Examples:**
```bash
./minima/mds_api.sh minifs /service.js '{"action":"list"}'
./minima/mds_api.sh minifs /service.js '{"action":"upload","file":"..."}'
```

---

### MiniWEB (v1.6.1)
**Purpose:** Browse decentralized websites stored on MiniFS.

**Agent Use Cases:**
- Access decentralized content
- Host static websites
- Browse MiniFS files

---

### Terminal (v3.1.8)
**Purpose:** CLI interface for Minima commands.

**Agent Use Cases:**
- Execute raw commands via UI
- Debug and explore
- Interactive development

---

### Script IDE (v3.1.4)
**Purpose:** Development environment for KISSVM smart contracts.

**Agent Use Cases:**
- Write and test scripts
- Debug contract logic
- Deploy smart contracts

---

### Block (v3.3.4)
**Purpose:** Blockchain explorer.

**Agent Use Cases:**
- View block data
- Track transactions
- Monitor chain state

---

### Future Cash (v2.7.1)
**Purpose:** Time-locked payments.

**Agent Use Cases:**
- Schedule future payments
- Create vesting schedules
- Delayed fund release

---

### Vestr (v1.8.1)
**Purpose:** Token vesting schedules.

**Agent Use Cases:**
- Create vesting contracts
- Track vesting progress
- Collect vested tokens

---

### The Safe (v1.7.0)
**Purpose:** Secure coin storage with multisig.

**Agent Use Cases:**
- Cold storage
- Multi-signature security
- Protected funds

---

### Ethwallet (v1.11.0)
**Purpose:** Wrapped Minima (wMINIMA) ERC-20 wallet.

**Agent Use Cases:**
- Bridge to Ethereum
- Manage wMINIMA
- Cross-chain operations

---

### Filez (v1.9.4)
**Purpose:** File manager for node storage.

**Agent Use Cases:**
- Browse node files
- Upload/download files
- Manage backups

---

### Health (v1.3.2)
**Purpose:** Node network health status.

**Agent Use Cases:**
- Monitor node status
- Check connectivity
- Diagnose issues

---

### Logs (v1.0.4)
**Purpose:** View node logs.

**Agent Use Cases:**
- Debug issues
- Monitor activity
- Audit trail

---

### Security (v1.14.3)
**Purpose:** Node security settings.

**Agent Use Cases:**
- Manage passwords
- Security configuration
- Access control

---

### Pending (v1.2.0)
**Purpose:** Approve/deny pending MiniDapp actions.

**Agent Use Cases:**
- Review pending commands
- Approve operations
- Deny suspicious actions

---

### Dapp Store (v1.5.1)
**Purpose:** Browse and install MiniDapps from stores.

**Agent Use Cases:**
- Discover new MiniDapps
- Add community stores
- Install applications

---

## Utility MiniDapps

| MiniDapp | Description |
|----------|-------------|
| **Linux** (v0.9.5) | Embedded Linux with multiple languages |
| **SQL Bench** (v0.6.1) | SQL workbench for MiniDapp databases |
| **Lotto** (v1.0.0) | Fair, unstoppable lottery game |
| **Chatter** (v1.12.0) | Social messaging web |
| **Shout Out** (v1.4.1) | Public chat rooms |
| **Axe S3** (v1.0.0) | Prove digital asset ownership |
| **Maximize** (v1.3.0) | Yield product |
| **Docs** (v2.1.0) | Minima documentation |
| **News Feed** (v2.0.1) | Minima news updates |
| **MiniHUB** (v0.24.3) | MinimaOS home screen |

---

## MiniDapp Stores

MiniDapp stores are collections of apps that can be added to your Dapp Store MiniDapp.

### Add a Store
Use the Dapp Store MiniDapp UI or add programmatically:

```bash
./minima/mds_api.sh "dapp store" /service.js '{"action":"addstore","url":"https://example.com/store.json"}'
```

### Community Store Directory

| Store | URL |
|-------|-----|
| **Spartacus Rex** | `https://spartacusrex.com/dappstore/dapps.json` |
| **Panda Dapps** | `https://eurobuddha.com/pandadapps.json` |
| **KISS Labs** | `https://eliasnemr.github.io/kisslabsstore/kiss_labs.json` |
| **Dynamite Sush** | `https://dynamitesush.vps.webdock.cloud/store/store.json` |
| **Jazminima** | `https://jazminima.github.io/dappstore/dapps.json` |
| **Monthrie** | `https://monthrie.github.io/minidapp-store/store.json` |
| **IPFS Store** | `https://ipfs.io/ipns/k51qzi5uqu5dm2n69mh0tkdtg21zpzo77nc2l1t8l8yyyksrxo8skh0z85fo0v` |
| **MiniNFTs** | `https://minimanfts.com/dappstore/dapps.json` |

### Store JSON Format

Create your own store with this format:

```json
{
  "name": "My Store",
  "description": "Collection of useful MiniDapps",
  "icon": "https://example.com/icon.png",
  "version": "1.0",
  "dapps": [
    {
      "file": "https://example.com/myapp.mds.zip",
      "icon": "https://example.com/myapp-icon.png",
      "name": "My App",
      "description": "What my app does",
      "version": "1.0.0"
    }
  ]
}
```

Host this JSON file on any web server (even a Raspberry Pi with a public IP).

---

## Trust Levels

MiniDapps have two trust levels:

| Trust | Description | Risk |
|-------|-------------|------|
| **read** | Can read data, pending commands require approval | Low |
| **write** | Can execute commands directly | High |

**Security Warning:** Only grant `write` permission to MiniDapps you fully trust.

```bash
./minima/cli.sh mds action:permission uid:0x... trust:write
./minima/cli.sh mds action:permission uid:0x... trust:read
```

---

## Pending Actions

MiniDapps with `read` permission require approval for sensitive operations:

```bash
./minima/cli.sh mds action:pending           # View pending
./minima/cli.sh mds action:accept uid:0x...  # Approve
./minima/cli.sh mds action:deny uid:0x...    # Reject
```

---

## Creating MiniDapps

MiniDapps use standard web technologies:
- **Frontend:** HTML, CSS, JavaScript
- **Smart Contracts:** KISSVM scripting language
- **Package:** ZIP file with `.mds.zip` extension

**Development Resources:**
- Script IDE MiniDapp for KISSVM development
- Minima docs: https://docs.minima.global/docs/learn/minidapps-about
- GitHub: https://github.com/minima-global/MiniDAPP

---

## API Access Pattern

All MiniDapps expose APIs through their session ID:

```bash
# 1. Get session ID
SESSION=$(./minima/mds_list.sh | jq -r '.response.minidapps[] | select(.conf.name | ascii_downcase | contains("wallet")) | .sessionid')

# 2. Call API directly
curl -sk -u "minima:$MDS_PASSWORD" "https://127.0.0.1:9003/$SESSION/service.js?action=balance"

# Or use the helper script
./minima/mds_api.sh wallet /service.js '{"action":"balance"}'
```

---

## See Also

- [Agent Quickstart](AGENT_QUICKSTART.md) - Section 11: MDS Agent Access
- [Commands Reference](COMMANDS.md) - `mds` command details
- [Backup Guide](BACKUP.md) - Backing up MiniDapp data
