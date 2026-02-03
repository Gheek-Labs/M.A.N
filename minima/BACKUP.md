# Backup, Restore & Resync

Complete guide to backing up, restoring, and resyncing your Minima node.

**Prerequisites:** Node running, RPC accessible via `./minima/cli.sh`

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `backup` | Create encrypted backup |
| `restore` | Restore from backup |
| `restoresync` | Restore + archive sync (old backups) |
| `decryptbackup` | Decrypt backup file |
| `vault` | Key management (seed, wipe, restore) |
| `megammrsync` | Restore from MegaMMR node |
| `reset` | Full system reset with archive |

---

## 1. Backup

Create a backup of your node's state, wallet keys, and chain data.

```bash
./minima/cli.sh backup
```

**With password encryption:**
```bash
./minima/cli.sh backup password:MySecretPass123
```

**Custom filename:**
```bash
./minima/cli.sh backup file:my_backup.bak
```

**Full options:**
```bash
./minima/cli.sh backup password:MySecretPass123 file:backup_2024.bak auto:true maxhistory:10
```

| Parameter | Description |
|-----------|-------------|
| `password:` | Encrypt backup with password (recommended) |
| `file:` | Custom output filename (default: timestamped) |
| `auto:` | Enable automatic backups (`true`/`false`) |
| `maxhistory:` | Max number of auto-backups to keep |

**Best practices:**
- Always use password encryption for production backups
- Store backups offsite (not just on the same machine)
- Test restore process periodically

---

## 2. Restore

Restore from a backup file. This replaces the current node state.

```bash
./minima/cli.sh restore file:my_backup.bak
```

**With password (if encrypted):**
```bash
./minima/cli.sh restore file:my_backup.bak password:MySecretPass123
```

| Parameter | Description |
|-----------|-------------|
| `file:` | Path to backup file (required) |
| `password:` | Decryption password (if encrypted) |

**Warning:** Restore overwrites your current node state. Make a backup first if needed.

---

## 3. RestoreSync

Restore from an **old backup** and sync with the current chain state. Use this when your backup is significantly behind the current block height.

```bash
./minima/cli.sh restoresync file:old_backup.bak
```

**With password and custom sync host:**
```bash
./minima/cli.sh restoresync file:old_backup.bak password:MySecretPass123 host:archive.minima.global:9001
```

| Parameter | Description |
|-----------|-------------|
| `file:` | Path to backup file (required) |
| `password:` | Decryption password (if encrypted) |
| `host:` | Archive sync host (default: Minima archive node) |
| `keyuses:` | Number of key uses to restore |

**When to use:**
- Backup is more than a few days old
- Node was offline for extended period
- Regular restore fails due to chain divergence

---

## 4. DecryptBackup

Decrypt an encrypted backup file to inspect or migrate.

```bash
./minima/cli.sh decryptbackup file:encrypted_backup.bak password:MySecretPass123 output:decrypted.bak
```

| Parameter | Description |
|-----------|-------------|
| `file:` | Encrypted backup file (required) |
| `password:` | Decryption password (required) |
| `output:` | Output filename for decrypted backup |

---

## 5. Vault (Key Management)

Manage your wallet seed phrase and private keys. **Use with extreme caution.**

### View Seed Phrase
```bash
./minima/cli.sh vault action:seed
```

### Wipe Keys (Dangerous)
Removes all private keys from the node:
```bash
./minima/cli.sh vault action:wipekeys
```

### Restore Keys from Seed
```bash
./minima/cli.sh vault action:restorekeys seed:"your 24 word seed phrase here"
```

### Password Lock Keys
Encrypt keys at rest with a password:
```bash
./minima/cli.sh vault action:passwordlock
```

### Password Unlock Keys
Decrypt keys for use:
```bash
./minima/cli.sh vault action:passwordunlock
```

| Action | Description |
|--------|-------------|
| `seed` | Display seed phrase |
| `wipekeys` | Delete all private keys |
| `restorekeys` | Restore keys from seed phrase |
| `passwordlock` | Encrypt keys with password |
| `passwordunlock` | Decrypt keys |

**Security notes:**
- Never share your seed phrase
- Store seed phrase offline in a secure location
- Password lock is for at-rest encryption only

---

## 6. MegaMMRSync

Restore or sync from a MegaMMR node. Useful for fast bootstrap or recovery.

```bash
./minima/cli.sh megammrsync action:resync host:megammr.minima.global:9001
```

**Full restore with seed:**
```bash
./minima/cli.sh megammrsync action:restore host:megammr.minima.global:9001 phrase:"your 24 word seed" keys:20 keyuses:1000
```

| Parameter | Description |
|-----------|-------------|
| `action:` | `resync` or `restore` |
| `host:` | MegaMMR node address (required) |
| `phrase:` | Seed phrase for key restoration |
| `keys:` | Number of keys to generate |
| `keyuses:` | Number of key uses to scan |
| `file:` | Backup file for hybrid restore |
| `password:` | Backup file password |

**Use cases:**
- Fast initial sync (instead of syncing from genesis)
- Disaster recovery when backup is unavailable
- Key recovery with seed phrase only

---

## 7. Reset

Full system reset using an archive backup file. Nuclear option for complete node rebuild.

```bash
./minima/cli.sh reset action:chainsync archivefile:archive.dat
```

**With key restoration:**
```bash
./minima/cli.sh reset action:restore archivefile:archive.dat file:backup.bak password:MyPass keys:20 keyuses:1000
```

| Parameter | Description |
|-----------|-------------|
| `action:` | `chainsync` or `restore` |
| `archivefile:` | Archive backup file (required) |
| `file:` | Regular backup for key data |
| `password:` | Backup password |
| `keys:` | Number of keys to generate |
| `keyuses:` | Key uses to scan |

**Warning:** This completely resets your node. Only use as last resort.

---

## Agent Backup Strategy

For autonomous agents, implement this backup schedule:

### Daily Automatic Backup
```bash
./minima/cli.sh backup password:"$BACKUP_PASSWORD" auto:true maxhistory:7
```

### Weekly Offsite Copy
```bash
cp ./minima/data/backups/latest.bak /offsite/storage/minima_weekly_$(date +%Y%m%d).bak
```

### Recovery Script Example
```bash
#!/bin/bash
BACKUP_FILE="$1"
BACKUP_PASSWORD="$2"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "Usage: recover.sh <backup_file> [password]"
  exit 1
fi

if [[ -n "$BACKUP_PASSWORD" ]]; then
  ./minima/cli.sh restoresync file:"$BACKUP_FILE" password:"$BACKUP_PASSWORD"
else
  ./minima/cli.sh restoresync file:"$BACKUP_FILE"
fi
```

---

## Troubleshooting

### Backup fails
- Check disk space: `df -h`
- Verify node is running: `./minima/cli.sh status`
- Check data directory permissions

### Restore fails with "chain mismatch"
Use `restoresync` instead of `restore` - your backup is behind current chain.

### Forgot backup password
Backups cannot be recovered without the password. This is by design for security.

### Keys not appearing after restore
Run `vault action:restorekeys` with your seed phrase, or use `megammrsync` with the `phrase:` parameter.

---

## See Also

- [Agent Quickstart](AGENT_QUICKSTART.md) - Essential operations
- [Commands Reference](COMMANDS.md) - Full RPC command list
- [MoltID Specification](MOLTID.md) - Stable identity system
