#!/bin/bash
set -e

echo "== MoltID: Permanent MAX# Registration =="

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required but not installed."
  exit 1
fi

RESPONSE=$(./minima/cli.sh maxima action:info 2>/dev/null)

if ! echo "$RESPONSE" | jq -e '.status == true' > /dev/null 2>&1; then
  echo "ERROR: Cannot fetch Maxima info. Is Maxima enabled?"
  exit 1
fi

echo "$RESPONSE" > /tmp/maxima.json

PUB=$(jq -r '.response.publickey' /tmp/maxima.json)
MLS=$(jq -r '.response.mls' /tmp/maxima.json)
STATIC=$(jq -r '.response.staticmls' /tmp/maxima.json)

if [ "$STATIC" != "true" ]; then
  echo "ERROR: Static MLS is not enabled."
  echo "Run moltid_setup_mls.sh first."
  exit 1
fi

echo ""
echo "Maxima Public Key:"
echo "$PUB"
echo ""
echo "Current Static MLS:"
echo "$MLS"
echo ""

echo "IMPORTANT:"
echo "You must now run the following command on your STATIC MLS NODE:"
echo ""
echo "  maxextra action:addpermanent publickey:$PUB"
echo ""
echo "This cannot be done from this node unless this node IS the MLS."
echo ""

read -p "Press ENTER once permanent registration is complete..."

echo ""
echo "Verifying registration..."

MAX_ADDR="MAX#$PUB#$MLS"

VERIFY=$(./minima/cli.sh maxextra action:getaddress maxaddress:$MAX_ADDR 2>/dev/null || true)

if echo "$VERIFY" | jq -e '.status == true' > /dev/null 2>&1; then
  echo "SUCCESS: Permanent MAX# verified!"
  echo ""
  echo "Permanent MAX# Address:"
  echo "$MAX_ADDR"
  echo "$MAX_ADDR" > /tmp/moltid_maxaddr.txt
else
  echo "WARNING: Could not verify permanent registration."
  echo "The MLS may need time to propagate, or registration may have failed."
  echo ""
  echo "Expected MAX# Address:"
  echo "$MAX_ADDR"
  echo "$MAX_ADDR" > /tmp/moltid_maxaddr.txt
fi
echo ""
