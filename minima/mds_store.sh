#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << 'EOF'
Manage MiniDapp stores programmatically.

Usage:
  ./mds_store.sh list                    List added stores
  ./mds_store.sh add <url>               Add a store by URL
  ./mds_store.sh remove <name>           Remove a store by name
  ./mds_store.sh browse <store_name>     List apps in a store
  ./mds_store.sh community               Show community store URLs

Community Stores:
  spartacusrex     https://spartacusrex.com/dappstore/dapps.json
  panda            https://eurobuddha.com/pandadapps.json
  kisslabs         https://eliasnemr.github.io/kisslabsstore/kiss_labs.json
  dynamitesush     https://dynamitesush.vps.webdock.cloud/store/store.json
  jazminima        https://jazminima.github.io/dappstore/dapps.json
  monthrie         https://monthrie.github.io/minidapp-store/store.json
  ipfs             https://ipfs.io/ipns/k51qzi5uqu5dm2n69mh0tkdtg21zpzo77nc2l1t8l8yyyksrxo8skh0z85fo0v
  mininft          https://minimanfts.com/dappstore/dapps.json

Examples:
  ./mds_store.sh community              # Show all community store URLs
  ./mds_store.sh add spartacusrex       # Add by shortname
  ./mds_store.sh add https://example.com/store.json  # Add by URL
EOF
}

declare -A COMMUNITY_STORES=(
    ["spartacusrex"]="https://spartacusrex.com/dappstore/dapps.json"
    ["panda"]="https://eurobuddha.com/pandadapps.json"
    ["kisslabs"]="https://eliasnemr.github.io/kisslabsstore/kiss_labs.json"
    ["dynamitesush"]="https://dynamitesush.vps.webdock.cloud/store/store.json"
    ["jazminima"]="https://jazminima.github.io/dappstore/dapps.json"
    ["monthrie"]="https://monthrie.github.io/minidapp-store/store.json"
    ["ipfs"]="https://ipfs.io/ipns/k51qzi5uqu5dm2n69mh0tkdtg21zpzo77nc2l1t8l8yyyksrxo8skh0z85fo0v"
    ["mininft"]="https://minimanfts.com/dappstore/dapps.json"
)

resolve_url() {
    local input="$1"
    if [[ "$input" =~ ^https?:// ]]; then
        echo "$input"
    elif [[ -n "${COMMUNITY_STORES[$input]:-}" ]]; then
        echo "${COMMUNITY_STORES[$input]}"
    else
        echo ""
    fi
}

cmd_community() {
    echo "Community MiniDapp Stores:"
    echo ""
    printf "%-15s %s\n" "SHORTNAME" "URL"
    printf "%-15s %s\n" "---------------" "---"
    for name in "${!COMMUNITY_STORES[@]}"; do
        printf "%-15s %s\n" "$name" "${COMMUNITY_STORES[$name]}"
    done | sort
}

cmd_list() {
    "$SCRIPT_DIR/mds_api.sh" "dapp store" /service.js '{"action":"liststores"}' 2>/dev/null || \
        echo '{"error":"Could not list stores. Dapp Store may not be installed or MDS_PASSWORD not set."}'
}

cmd_add() {
    local url
    url=$(resolve_url "$1")
    
    if [[ -z "$url" ]]; then
        echo "Error: Unknown store '$1'. Use a URL or shortname from: ${!COMMUNITY_STORES[*]}" >&2
        exit 1
    fi
    
    echo "Adding store: $url" >&2
    "$SCRIPT_DIR/mds_api.sh" "dapp store" /service.js "{\"action\":\"addstore\",\"url\":\"$url\"}" 2>/dev/null || \
        echo '{"error":"Could not add store. Check MDS_PASSWORD is set."}'
}

cmd_remove() {
    local name="$1"
    echo "Removing store: $name" >&2
    "$SCRIPT_DIR/mds_api.sh" "dapp store" /service.js "{\"action\":\"removestore\",\"name\":\"$name\"}" 2>/dev/null || \
        echo '{"error":"Could not remove store."}'
}

cmd_browse() {
    local name="$1"
    "$SCRIPT_DIR/mds_api.sh" "dapp store" /service.js "{\"action\":\"getstore\",\"name\":\"$name\"}" 2>/dev/null || \
        echo '{"error":"Could not browse store."}'
}

if [[ $# -lt 1 ]]; then
    show_help
    exit 0
fi

case "$1" in
    -h|--help)
        show_help
        ;;
    list)
        cmd_list
        ;;
    add)
        if [[ $# -lt 2 ]]; then
            echo "Error: URL or shortname required" >&2
            exit 1
        fi
        cmd_add "$2"
        ;;
    remove)
        if [[ $# -lt 2 ]]; then
            echo "Error: Store name required" >&2
            exit 1
        fi
        cmd_remove "$2"
        ;;
    browse)
        if [[ $# -lt 2 ]]; then
            echo "Error: Store name required" >&2
            exit 1
        fi
        cmd_browse "$2"
        ;;
    community)
        cmd_community
        ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
