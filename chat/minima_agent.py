import subprocess
import json
import os
from typing import Dict, Any, Optional

SCRIPT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "minima")

SYSTEM_PROMPT = """You are a helpful assistant that controls a Minima blockchain node. You translate natural language requests into node commands and explain results in plain English.

## Available Commands

You have access to these tools via the execute_command function:

### Node Info
- `status` - Node status and sync info
- `balance` - Token balances  
- `block` - Current top block
- `network` - Network status
- `coins` - List coins
- `keys` - Wallet keys
- `getaddress` - Get default address

### Transactions
- `send address:<ADDRESS> amount:<AMOUNT>` - Send Minima
- `send address:<ADDRESS> amount:<AMOUNT> tokenid:<TOKENID>` - Send tokens
- `history` - Transaction history

### Maxima Messaging
- `maxima action:info` - Your Maxima info (contact address, public key)
- `maxcontacts action:list` - List contacts
- `maxcontacts action:add contact:<ADDRESS>` - Add contact
- `maxima action:send id:<ID> application:<APP> data:<DATA>` - Send message

### MxID (Identity)
- `mxid_info` - Get your MxID identity card (JSON)
- `mxid_claim` - Claim your MxID
- `get_maxima` - Get current Maxima address

### Backup
- `vault` - View seed phrase (BE CAREFUL - this is sensitive!)
- `backup` - Create backup

### MDS (MiniDapps)
- `mds action:list` - List installed MiniDapps

## How to Respond

1. When user asks something, determine which command(s) to run
2. Call execute_command with the appropriate command
3. Parse the JSON result and explain it in plain English
4. If something fails, explain what went wrong

## Response Format

For command results, provide:
- A brief, friendly summary of what the result means
- Key data points the user cares about
- Any warnings or next steps if relevant

## Security Notes

- NEVER reveal seed phrases or private keys unless explicitly asked
- Confirm before sending transactions
- Warn about irreversible actions

## Example Interactions

User: "What's my balance?"
You: Run `balance` command, then say something like "You have 10 Minima in your wallet."

User: "Send 5 Minima to MxG..."
You: First confirm the transaction details, then if user confirms, run `send address:MxG... amount:5`

User: "Who am I on the network?"
You: Run `mxid_info` to get their identity card.
"""

def execute_command(command: str) -> Dict[str, Any]:
    """Execute a Minima CLI command and return the result."""
    try:
        if command == "mxid_info":
            result = subprocess.run(
                [os.path.join(SCRIPT_DIR, "mxid_info.sh")],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=os.path.dirname(SCRIPT_DIR),
            )
            if result.returncode == 0:
                return {"status": True, "response": json.loads(result.stdout)}
            return {"status": False, "error": result.stderr or result.stdout}
        
        elif command == "get_maxima":
            result = subprocess.run(
                [os.path.join(SCRIPT_DIR, "get_maxima.sh")],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=os.path.dirname(SCRIPT_DIR),
            )
            if result.returncode == 0:
                return {"status": True, "response": {"address": result.stdout.strip()}}
            return {"status": False, "error": result.stderr or result.stdout}
        
        elif command == "mxid_claim":
            return {"status": False, "error": "mxid_claim is interactive and cannot be run via chat. Use the terminal."}
        
        else:
            result = subprocess.run(
                [os.path.join(SCRIPT_DIR, "cli.sh")] + command.split(),
                capture_output=True,
                text=True,
                timeout=30,
                cwd=os.path.dirname(SCRIPT_DIR),
            )
            
            try:
                return json.loads(result.stdout)
            except json.JSONDecodeError:
                if result.returncode == 0:
                    return {"status": True, "response": result.stdout}
                return {"status": False, "error": result.stderr or result.stdout}
    
    except subprocess.TimeoutExpired:
        return {"status": False, "error": "Command timed out"}
    except Exception as e:
        return {"status": False, "error": str(e)}


def format_command_result(command: str, result: Dict[str, Any]) -> str:
    """Format command result for inclusion in chat context."""
    return f"Command: {command}\nResult: {json.dumps(result, indent=2)}"


class MinimaAgent:
    """Agent that uses an LLM to interpret natural language and control Minima node."""
    
    def __init__(self, provider):
        self.provider = provider
        self.conversation_history = []
    
    def chat(self, user_message: str) -> str:
        """Process a user message and return a response."""
        self.conversation_history.append({
            "role": "user",
            "content": user_message
        })
        
        response = self.provider.chat(
            messages=self.conversation_history,
            system_prompt=SYSTEM_PROMPT
        )
        
        executed_commands = []
        final_response = response
        
        if "execute_command" in response.lower() or any(
            cmd in response.lower() for cmd in ["status", "balance", "maxima", "mxid", "send ", "history"]
        ):
            lines = response.split("\n")
            for line in lines:
                if "`" in line:
                    import re
                    matches = re.findall(r'`([^`]+)`', line)
                    for match in matches:
                        if match.startswith(("status", "balance", "block", "network", "coins", "keys", 
                                           "getaddress", "send ", "history", "maxima", "maxcontacts",
                                           "mxid_", "get_maxima", "vault", "backup", "mds")):
                            result = execute_command(match)
                            executed_commands.append((match, result))
        
        if executed_commands:
            context = "\n\nI executed the following commands:\n"
            for cmd, result in executed_commands:
                context += format_command_result(cmd, result) + "\n"
            
            self.conversation_history.append({
                "role": "assistant", 
                "content": response
            })
            self.conversation_history.append({
                "role": "user",
                "content": f"[SYSTEM: Commands executed. Results below. Now provide a friendly summary for the user.]{context}"
            })
            
            final_response = self.provider.chat(
                messages=self.conversation_history,
                system_prompt=SYSTEM_PROMPT
            )
        
        self.conversation_history.append({
            "role": "assistant",
            "content": final_response
        })
        
        if len(self.conversation_history) > 20:
            self.conversation_history = self.conversation_history[-20:]
        
        return final_response
    
    def reset(self):
        """Clear conversation history."""
        self.conversation_history = []


def quick_command(command: str) -> Dict[str, Any]:
    """Execute a command directly without LLM interpretation."""
    return execute_command(command)
