#!/bin/bash

echo "=============================================="
echo "  Minima Node One-Click Bootstrap"
echo "  Agent-Friendly Headless Setup"
echo "=============================================="
echo ""

MINIMA_DIR="$(dirname "$0")/minima"

if [ ! -f "$MINIMA_DIR/minima.jar" ]; then
    echo "Error: minima.jar not found in $MINIMA_DIR"
    exit 1
fi

chmod +x "$MINIMA_DIR/start.sh"
chmod +x "$MINIMA_DIR/cli.sh"

echo "Bootstrap complete!"
echo ""
echo "To start the node:"
echo "  ./minima/start.sh"
echo ""
echo "To interact with the node (RPC):"
echo "  ./minima/cli.sh status"
echo "  ./minima/cli.sh help"
echo "  ./minima/cli.sh balance"
echo ""
echo "RPC endpoint: http://localhost:9005/<command>"
echo ""
