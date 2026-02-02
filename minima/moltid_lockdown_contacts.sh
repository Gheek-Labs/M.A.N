#!/bin/bash
set -e

echo "== MoltID: Contact Lockdown =="

if ! command -v jq &> /dev/null; then
  echo "ERROR: jq is required but not installed."
  exit 1
fi

echo "Disabling automatic contact acceptance..."
RESPONSE=$(./minima/cli.sh maxextra action:allowallcontacts enable:false 2>/dev/null)

if ! echo "$RESPONSE" | jq -e '.status == true' > /dev/null 2>&1; then
  echo "ERROR: Failed to lock down contacts."
  exit 1
fi

echo ""
echo "Your node will now:"
echo "- Accept messages to your MAX# address"
echo "- Reject unsolicited contact requests"
echo ""
echo "You may whitelist trusted contacts using:"
echo "  maxextra action:addallowed publickey:<PUBKEY>"
echo ""
