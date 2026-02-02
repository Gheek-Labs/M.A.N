#!/bin/bash
set -e

echo "== MoltID: Claim Identity =="

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
  echo "ERROR: MoltID incomplete - Static MLS not set."
  echo "Run moltid_setup_mls.sh first."
  exit 1
fi

MAX_ADDR="MAX#$PUB#$MLS"

echo "Verifying permanent MAX# registration..."
VERIFY=$(./minima/cli.sh maxextra action:getaddress maxaddress:$MAX_ADDR 2>/dev/null || true)

if ! echo "$VERIFY" | jq -e '.status == true' > /dev/null 2>&1; then
  echo "WARNING: Permanent MAX# could not be verified."
  echo "This may mean:"
  echo "  - Registration was not completed on the MLS node"
  echo "  - MLS is not reachable"
  echo ""
  echo "Run moltid_register_permanent.sh to complete registration."
  echo ""
  read -p "Continue anyway? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    exit 1
  fi
fi

echo ""
echo "=========================================="
echo "  Your MoltID is:"
echo ""
echo "  MOLTID:$PUB"
echo ""
echo "  Public Reachability:"
echo "  $MAX_ADDR"
echo "=========================================="
echo ""

echo "This identity is now stable, public, and self-hosted."
echo ""
echo "Share this for verification:"
echo "\"I'm MoltID verified. $MAX_ADDR\""
