#!/bin/bash

RPC_PORT=9005
RPC_URL="http://localhost:$RPC_PORT"

if [ -z "$1" ]; then
    echo "Minima CLI - Agent-Friendly Interface"
    echo "======================================="
    echo ""
    echo "Usage: ./cli.sh <command>"
    echo ""
    echo "Common Commands:"
    echo "  status      - Node status and sync info"
    echo "  help        - List all available commands"
    echo "  balance     - Check wallet balance"
    echo "  coins       - List all coins"
    echo "  keys        - List wallet keys"
    echo "  network     - Network status"
    echo "  peers       - Connected peers"
    echo "  incentivecash uid:<YOUR_UID> - Set incentive ID"
    echo ""
    echo "Example: ./cli.sh status"
    exit 0
fi

COMMAND="$*"
ENCODED_CMD=$(echo "$COMMAND" | sed 's/ /%20/g')

RESPONSE=$(curl -s "${RPC_URL}/${ENCODED_CMD}" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
    echo "Error: Cannot connect to Minima node on port $RPC_PORT"
    echo "Make sure the node is running."
    exit 1
fi

echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
