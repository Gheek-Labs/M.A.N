#!/bin/bash

echo "=============================================="
echo "  Minima Node One-Click Bootstrap"
echo "  Agent-Friendly Headless Setup"
echo "=============================================="
echo ""

MINIMA_DIR="$(dirname "$0")/minima"
JAR_PATH="$MINIMA_DIR/minima.jar"
JAR_URL="https://github.com/minima-global/Minima/raw/master/jar/minima.jar"

echo "Checking prerequisites..."

MISSING=()

if ! command -v java &> /dev/null; then
    MISSING+=("java (OpenJDK 17+)")
fi

if ! command -v jq &> /dev/null; then
    MISSING+=("jq (needed for MxID)")
fi

if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    MISSING+=("curl or wget (needed to download JAR)")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "ERROR: Missing required system dependencies:"
    for dep in "${MISSING[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Install them before continuing. On Replit, use the packager tool."
    echo "On Debian/Ubuntu: apt install -y openjdk-17-jre-headless jq curl"
    echo "On NixOS/Replit: nix packages jdk jq"
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | head -1)
echo "  Java:  OK ($JAVA_VER)"
echo "  jq:    OK ($(jq --version 2>&1))"
echo "  curl:  OK"
echo ""

if [ ! -f "$JAR_PATH" ]; then
    echo "Downloading minima.jar from GitHub..."
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
    echo ""
fi

chmod +x "$MINIMA_DIR/start.sh"
chmod +x "$MINIMA_DIR/cli.sh"
chmod +x "$MINIMA_DIR/get_maxima.sh"
chmod +x "$MINIMA_DIR/mxid_"*.sh
chmod +x "$MINIMA_DIR/mds_"*.sh

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
