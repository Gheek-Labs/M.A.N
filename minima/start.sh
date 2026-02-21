#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
JAR_PATH="$SCRIPT_DIR/minima.jar"
JAR_URL="https://github.com/minima-global/Minima/raw/master/jar/minima.jar"
RPC_PORT=9005
P2P_PORT=9001
MDS_PORT=9003

mkdir -p "$DATA_DIR"

if ! command -v java &> /dev/null; then
    echo "ERROR: Java is not installed. Minima requires OpenJDK 17+."
    echo "Run ./bootstrap.sh first — it will check all prerequisites."
    echo "Or install manually: nix package 'jdk' on Replit, or 'apt install openjdk-17-jre-headless' on Debian/Ubuntu."
    exit 1
fi

if [ ! -f "$JAR_PATH" ]; then
    echo "minima.jar not found. Downloading from GitHub..."
    if command -v curl &> /dev/null; then
        curl -L -o "$JAR_PATH" "$JAR_URL"
    elif command -v wget &> /dev/null; then
        wget -O "$JAR_PATH" "$JAR_URL"
    else
        echo "Error: Neither curl nor wget found. Please install one."
        exit 1
    fi
    
    if [ ! -f "$JAR_PATH" ]; then
        echo "Error: Failed to download minima.jar"
        exit 1
    fi
    echo "Download complete!"

    CHECKSUM_FILE="$SCRIPT_DIR/minima.jar.sha256"
    if [ -f "$CHECKSUM_FILE" ]; then
        EXPECTED=$(awk '{print $1}' "$CHECKSUM_FILE")
        ACTUAL=$(sha256sum "$JAR_PATH" | awk '{print $1}')
        if [ "$EXPECTED" != "$ACTUAL" ]; then
            echo "ERROR: SHA256 checksum mismatch for minima.jar!"
            echo "  Expected: $EXPECTED"
            echo "  Got:      $ACTUAL"
            echo "The downloaded file may be corrupted or tampered with."
            echo "Delete minima.jar and update minima.jar.sha256 if upgrading."
            rm -f "$JAR_PATH"
            exit 1
        fi
        echo "SHA256 checksum verified."
    else
        echo "WARNING: No checksum file found. Skipping integrity verification."
        echo "  Create minima/minima.jar.sha256 for download verification."
    fi
    echo ""
fi

# ============================================
# MDS Password Security
# ============================================

validate_password_entropy() {
    local password="$1"
    local errors=()
    
    # Minimum 16 characters
    if [[ ${#password} -lt 16 ]]; then
        errors+=("- Must be at least 16 characters (currently ${#password})")
    fi
    
    # Must contain lowercase
    if ! [[ "$password" =~ [a-z] ]]; then
        errors+=("- Must contain at least one lowercase letter")
    fi
    
    # Must contain uppercase
    if ! [[ "$password" =~ [A-Z] ]]; then
        errors+=("- Must contain at least one uppercase letter")
    fi
    
    # Must contain number
    if ! [[ "$password" =~ [0-9] ]]; then
        errors+=("- Must contain at least one number")
    fi
    
    # Must contain symbol
    if ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        errors+=("- Must contain at least one symbol (!@#$%^&* etc.)")
    fi
    
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "ERROR: MDS_PASSWORD does not meet security requirements:"
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    return 0
}

generate_secure_password() {
    # Generate 28-char password with guaranteed high entropy
    # 24 random chars + !Aa1 for guaranteed complexity
    printf '%s!Aa1' "$(openssl rand -base64 32 | tr -d '/+=' | head -c 24)"
}

# Check if MDS_PASSWORD is set
MDS_PASS_FILE="$SCRIPT_DIR/.mds_password"

if [[ -z "$MDS_PASSWORD" ]]; then
    if [[ -f "$MDS_PASS_FILE" ]]; then
        MDS_PASSWORD="$(cat "$MDS_PASS_FILE")"
        echo "MDS password loaded from $MDS_PASS_FILE"
    else
        echo ""
        echo "WARNING: MDS_PASSWORD not set. Generating secure password..."
        MDS_PASSWORD="$(generate_secure_password)"
        echo "$MDS_PASSWORD" > "$MDS_PASS_FILE"
        chmod 600 "$MDS_PASS_FILE"
        echo ""
        echo "============================================"
        echo "MDS password saved to: $MDS_PASS_FILE"
        echo "(file is permissions-restricted to owner only)"
        echo "To view:  cat $MDS_PASS_FILE"
        echo "To set permanently, add MDS_PASSWORD to your secrets."
        echo "============================================"
        echo ""
    fi
fi

# Validate password entropy
if ! validate_password_entropy "$MDS_PASSWORD"; then
    echo ""
    echo "FATAL: MDS_PASSWORD failed security validation. Node will not start."
    echo "Please set a strong password with: 16+ chars, uppercase, lowercase, number, symbol"
    exit 1
fi

echo "Starting Minima Node (Headless Mode)"
echo "======================================"
echo "Data Directory: $DATA_DIR"
echo "RPC Port:       $RPC_PORT"
echo "P2P Port:       $P2P_PORT"
echo "MDS Port:       $MDS_PORT (SSL, password-protected)"
echo "MDS Password:   [SET - validated]"
echo ""

PEERS_URL="https://www.spartacusrex.com/minimapeers.txt"

import_peers() {
    echo ""
    echo "Waiting for RPC to become available before importing peers..."
    local attempts=0
    while [ $attempts -lt 30 ]; do
        if curl -s "http://localhost:${RPC_PORT}/status" >/dev/null 2>&1; then
            echo "RPC is ready. Downloading peer list from $PEERS_URL ..."
            local peers
            peers=$(curl -s "$PEERS_URL" 2>/dev/null)
            if [ -n "$peers" ]; then
                local encoded
                encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=''))" "peers action:addpeers peerslist:${peers}" 2>/dev/null)
                local result
                result=$(curl -s "http://localhost:${RPC_PORT}/${encoded}" 2>/dev/null)
                echo "Peer import result: $result"
            else
                echo "WARNING: Could not download peers list. Node will rely on default bootstrap peer."
            fi
            return
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    echo "WARNING: RPC did not become available within 60s. Skipping peer import."
}

import_peers &

exec java -Xmx1G -jar "$JAR_PATH" \
    -data "$DATA_DIR" \
    -basefolder "$DATA_DIR" \
    -rpcenable \
    -rpc $RPC_PORT \
    -port $P2P_PORT \
    -mdsenable \
    -mdspassword "$MDS_PASSWORD" \
    -p2pnodes megammr.minima.global:9001
