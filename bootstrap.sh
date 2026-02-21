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

install_missing_deps() {
    local need_java="$1"
    local need_jq="$2"
    local need_curl="$3"

    if command -v apt-get &> /dev/null; then
        echo "  Detected Debian/Ubuntu — installing via apt..."
        local pkgs=()
        [ "$need_java" = "1" ] && pkgs+=("openjdk-17-jre-headless")
        [ "$need_jq" = "1" ] && pkgs+=("jq")
        [ "$need_curl" = "1" ] && pkgs+=("curl")
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update -qq && apt-get install -y -qq "${pkgs[@]}"
        else
            sudo apt-get update -qq && sudo apt-get install -y -qq "${pkgs[@]}"
        fi
    elif command -v brew &> /dev/null; then
        echo "  Detected macOS/Homebrew — installing via brew..."
        [ "$need_java" = "1" ] && brew install openjdk@17
        [ "$need_jq" = "1" ] && brew install jq
        [ "$need_curl" = "1" ] && brew install curl
    elif command -v pacman &> /dev/null; then
        echo "  Detected Arch — installing via pacman..."
        local pkgs=()
        [ "$need_java" = "1" ] && pkgs+=("jre-openjdk")
        [ "$need_jq" = "1" ] && pkgs+=("jq")
        [ "$need_curl" = "1" ] && pkgs+=("curl")
        sudo pacman -Sy --noconfirm "${pkgs[@]}"
    elif command -v dnf &> /dev/null; then
        echo "  Detected Fedora/RHEL — installing via dnf..."
        local pkgs=()
        [ "$need_java" = "1" ] && pkgs+=("java-17-openjdk-headless")
        [ "$need_jq" = "1" ] && pkgs+=("jq")
        [ "$need_curl" = "1" ] && pkgs+=("curl")
        sudo dnf install -y "${pkgs[@]}"
    elif command -v apk &> /dev/null; then
        echo "  Detected Alpine — installing via apk..."
        local pkgs=()
        [ "$need_java" = "1" ] && pkgs+=("openjdk17-jre-headless")
        [ "$need_jq" = "1" ] && pkgs+=("jq")
        [ "$need_curl" = "1" ] && pkgs+=("curl")
        apk add --no-cache "${pkgs[@]}"
    else
        return 1
    fi
    return 0
}

NEED_JAVA=0
NEED_JQ=0
NEED_CURL=0

if ! command -v java &> /dev/null; then
    NEED_JAVA=1
fi

if ! command -v jq &> /dev/null; then
    NEED_JQ=1
fi

if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    NEED_CURL=1
fi

if [ "$NEED_JAVA" = "1" ] || [ "$NEED_JQ" = "1" ] || [ "$NEED_CURL" = "1" ]; then
    echo ""
    echo "Missing dependencies detected:"
    [ "$NEED_JAVA" = "1" ] && echo "  - java (OpenJDK 17+)"
    [ "$NEED_JQ" = "1" ] && echo "  - jq (needed for MxID)"
    [ "$NEED_CURL" = "1" ] && echo "  - curl (needed to download JAR)"
    echo ""
    echo "Attempting auto-install..."

    if install_missing_deps "$NEED_JAVA" "$NEED_JQ" "$NEED_CURL"; then
        echo ""
        echo "Auto-install completed. Re-checking..."
        STILL_MISSING=()
        if [ "$NEED_JAVA" = "1" ] && ! command -v java &> /dev/null; then
            STILL_MISSING+=("java (OpenJDK 17+)")
        fi
        if [ "$NEED_JQ" = "1" ] && ! command -v jq &> /dev/null; then
            STILL_MISSING+=("jq")
        fi
        if [ "$NEED_CURL" = "1" ] && ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
            STILL_MISSING+=("curl or wget")
        fi
        if [ ${#STILL_MISSING[@]} -gt 0 ]; then
            echo "ERROR: Auto-install did not fully succeed. Still missing:"
            for dep in "${STILL_MISSING[@]}"; do
                echo "  - $dep"
            done
            echo ""
            echo "Please install manually and re-run ./bootstrap.sh"
            exit 1
        fi
    else
        echo "ERROR: Could not detect a supported package manager."
        echo ""
        echo "Please install these manually and re-run ./bootstrap.sh:"
        echo "  Debian/Ubuntu:  apt install -y openjdk-17-jre-headless jq curl"
        echo "  macOS:          brew install openjdk@17 jq curl"
        echo "  Fedora/RHEL:    dnf install -y java-17-openjdk-headless jq curl"
        echo "  Alpine:         apk add openjdk17-jre-headless jq curl"
        echo "  Arch:           pacman -S jre-openjdk jq curl"
        echo "  Replit (Nix):   Add jdk and jq to system packages"
        exit 1
    fi
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
