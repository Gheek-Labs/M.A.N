# Minima Node - One-Click Bootstrap

Agent-friendly, headless Minima blockchain node setup.

## Quick Start

```bash
./bootstrap.sh
./minima/start.sh
```

## RPC Interface

Once running, interact via CLI or HTTP:

### CLI Commands
```bash
./minima/cli.sh status     # Node status
./minima/cli.sh help       # All commands
./minima/cli.sh balance    # Wallet balance
./minima/cli.sh peers      # Connected peers
./minima/cli.sh network    # Network info
```

### HTTP API
```bash
curl http://localhost:9005/status
curl http://localhost:9005/balance
curl http://localhost:9005/help
```

## Configuration

| Setting | Value |
|---------|-------|
| RPC Port | 9005 |
| P2P Port | 9001 |
| Data Dir | ./minima/data |

## Agent Integration

For programmatic access, use the RPC endpoint:

```python
import requests

def minima_cmd(cmd):
    return requests.get(f"http://localhost:9005/{cmd}").json()

status = minima_cmd("status")
balance = minima_cmd("balance")
```

## Ports

- **9001**: P2P network connections
- **9005**: RPC interface (agent commands)
