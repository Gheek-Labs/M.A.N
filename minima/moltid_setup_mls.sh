#!/bin/bash
set -e

echo "== MoltID: Static MLS Setup =="

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required but not installed."
  exit 1
fi

echo "Fetching Maxima info..."
RESPONSE=$(./minima/cli.sh maxima action:info 2>/dev/null)

if ! echo "$RESPONSE" | jq -e '.status == true' > /dev/null 2>&1; then
  echo "ERROR: Cannot fetch Maxima info. Is Maxima enabled?"
  echo "Maxima should be enabled by default on node startup."
  exit 1
fi

echo "$RESPONSE" > /tmp/maxima.json

MLS=$(jq -r '.response.mls' /tmp/maxima.json)
STATIC=$(jq -r '.response.staticmls' /tmp/maxima.json)

if [ "$STATIC" = "true" ]; then
  echo "Static MLS already set:"
  echo "$MLS"
  exit 0
fi

echo ""
echo "Static MLS is NOT set."
echo "You must provide a server-based Minima P2P identity to act as your Static MLS."
echo ""
echo "Example format:"
echo "Mx...@ip:port"
echo ""

read -p "Enter Static MLS host: " HOST

./minima/cli.sh maxextra action:staticmls host:$HOST

echo ""
echo "Static MLS configured successfully."
