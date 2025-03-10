#!/usr/bin/env bash
#
# SSH Connect - A modern SSH connection manager
# A standalone shell script for managing SSH connections on macOS
# Works with SpinupWP API and local configuration
#

# Constants
VERSION="1.0.0"
CONFIG_DIR="$HOME/.ssh-connect"
SERVERS_FILE="$CONFIG_DIR/servers.json"
CONFIG_FILE="$CONFIG_DIR/config"
SPINUPWP_CONFIG="$CONFIG_DIR/spinupwp"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default settings
DEFAULT_USER="root"
DEFAULT_PORT=22
DEFAULT_IDENTITY="$HOME/.ssh/id_rsa"
DEFAULT_PROTOCOL="ssh"

# Parse command line arguments
SFTP=false
CLIPBOARD=true
LIST=false
IMPORT=""
SPINUP=false

# Function to display help
display_help() {
    echo "SSH Connect - A modern SSH connection manager"
    echo "Version: $VERSION"
    echo
    echo "USAGE:"
    echo "  ssh-connect [options]"
    echo
    echo "OPTIONS:"
    echo "  -h, --help              Display this help"
    echo "  -v, --version           Display version information"
    echo "  -s, --sftp              Use SFTP instead of SSH"
    echo "  -c, --no-clipboard      Don't copy to clipboard"
    echo "  -l, --list              List all configured servers"
    echo "  -i, --import FILE       Import servers from legacy .servers file"
    echo "      --spinup            Import servers from SpinupWP API"
    echo
    echo "CONFIGURATION:"
    echo "  Configuration is stored in $CONFIG_DIR"
    echo "  Edit $CONFIG_FILE to change default settings"
    echo "  Servers are stored in $SERVERS_FILE"
}

# Parse arguments
while (( "$#" )); do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -v|--version)
            echo "SSH Connect - Version $VERSION"
            echo "Copyright (c) 2025 - MIT License"
            exit 0
            ;;
        -s|--sftp)
            SFTP=true
            shift
            ;;
        -c|--no-clipboard)
            CLIPBOARD=false
            shift
            ;;
        -l|--list)
            LIST=true
            shift
            ;;
        -i|--import)
            if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
                IMPORT="$2"
                shift 2
            else
                IMPORT="$HOME/.servers"
                shift 1
            fi
            ;;
        --spinup)
            SPINUP=true
            shift
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        -*|--*=) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            shift
            ;;
    esac
done

# Create config directory if it doesn't exist
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo "Created configuration directory at $CONFIG_DIR"
fi

# Create default config if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# SSH Connect Configuration

# Default SSH user
DEFAULT_USER="root"

# Default SSH port
DEFAULT_PORT=22

# Default SSH identity file
DEFAULT_IDENTITY="$HOME/.ssh/id_rsa"

# Default connection protocol (ssh or sftp)
DEFAULT_PROTOCOL="ssh"
EOF
    echo "Created default configuration at $CONFIG_FILE"
    echo "Please edit this file to set your preferences."
fi

# Create default SpinupWP config if it doesn't exist
if [ ! -f "$SPINUPWP_CONFIG" ]; then
    cat > "$SPINUPWP_CONFIG" << EOF
# SpinupWP API Configuration

# Your SpinupWP API key
SPINUPWP_API_KEY=""

# Your SpinupWP API secret
SPINUPWP_API_SECRET=""
EOF
    echo "Created SpinupWP configuration at $SPINUPWP_CONFIG"
    echo "Please edit this file to set your SpinupWP API credentials."
fi

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Load SpinupWP configuration if needed
if [ "$SPINUP" = true ]; then
    if [ -f "$SPINUPWP_CONFIG" ]; then
        source "$SPINUPWP_CONFIG"
    else
        echo "Error: SpinupWP configuration file not found."
        exit 1
    fi
fi

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed."
        echo "Install with: brew install jq"
        exit 1
    fi
}

# Function to handle JSON operations
ensure_servers_file() {
    if [ ! -f "$SERVERS_FILE" ]; then
        echo "[]" > "$SERVERS_FILE"
    fi
}

# Function to list servers
list_servers() {
    check_jq
    ensure_servers_file
    
    # Get server count
    local count=$(jq 'length' "$SERVERS_FILE")
    
    if [ "$count" -eq 0 ]; then
        echo "No servers configured."
        return 1
    fi
    
    echo -e "\n${YELLOW}Configured Servers:${NC}"
    echo "---------------------------------------------------------------------------------------------------------"
    printf "%-4s %-30s %-20s %-15s %-8s %-20s\n" "ID" "Name" "IP" "User" "Port" "Identity"
    echo "---------------------------------------------------------------------------------------------------------"
    
    for i in $(seq 0 $(($count - 1))); do
        local name=$(jq -r ".[$i].name" "$SERVERS_FILE")
        local ip=$(jq -r ".[$i].ip" "$SERVERS_FILE")
        local user=$(jq -r ".[$i].user // \"---\"" "$SERVERS_FILE")
        local port=$(jq -r ".[$i].port // 22" "$SERVERS_FILE")
        local id_file=$(jq -r ".[$i].id_file // \"---\"" "$SERVERS_FILE")
        
        printf "%-4s %-30s %-20s %-15s %-8s %-20s\n" "$i" "${name:0:30}" "${ip:0:20}" "${user:0:15}" "$port" "${id_file:0:20}"
    done
    
    return 0
}

# Function to import servers from legacy .servers file
import_from_legacy() {
    check_jq
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: File $file not found."
        exit 1
    fi
    
    # Create a new JSON array
    echo "[]" > "$SERVERS_FILE.tmp"
    
    # Read file line by line
    local index=0
    while IFS=, read -r name ip user port id_file; do
        # Skip empty lines
        if [ -z "$name" ] || [ -z "$ip" ]; then
            continue
        fi
        
        # Convert to proper JSON
        jq --arg name "$name" --arg ip "$ip" --arg user "$user" --arg port "$port" --arg id_file "$id_file" \
           '. += [{"name": $name, "ip": $ip, "user": $user, "port": ($port | if . == "" then "22" else . end), "id_file": $id_file}]' \
           "$SERVERS_FILE.tmp" > "$SERVERS_FILE.tmp2"
        
        mv "$SERVERS_FILE.tmp2" "$SERVERS_FILE.tmp"
        index=$((index + 1))
    done < "$file"
    
    # Sort by name
    jq 'sort_by(.name)' "$SERVERS_FILE.tmp" > "$SERVERS_FILE"
    rm "$SERVERS_FILE.tmp"
    
    echo "Imported $index servers from $file"
}

# Function to import servers from SpinupWP API
import_from_spinupwp() {
    check_jq
    
    # Check API credentials
    if [ -z "$SPINUPWP_API_KEY" ]; then
        echo "Error: SpinupWP API key not configured in $SPINUPWP_CONFIG"
        exit 1
    fi
    
    echo "Fetching servers from SpinupWP API..."
    
    # Make API request
    local response=$(curl -s -H "Authorization: Bearer $SPINUPWP_API_KEY" -H "Accept: application/json" "https://api.spinupwp.com/v1/servers")
    
    # Check for errors
    if ! echo "$response" | jq -e '.data' > /dev/null; then
        echo "Error: Failed to fetch servers from SpinupWP API"
        echo "Response: $response"
        exit 1
    fi
    
    # Process response
    echo "[]" > "$SERVERS_FILE.tmp"
    
    local count=$(echo "$response" | jq '.data | length')
    for i in $(seq 0 $(($count - 1))); do
        local name=$(echo "$response" | jq -r ".data[$i].name")
        local ip=$(echo "$response" | jq -r ".data[$i].ip_address")
        local provider=$(echo "$response" | jq -r ".data[$i].provider")
        local spinupwp_id=$(echo "$response" | jq -r ".data[$i].id")
        
        # Add to servers file
        jq --arg name "$name" --arg ip "$ip" --arg provider "$provider" --arg spinupwp_id "$spinupwp_id" \
           '. += [{"name": $name, "ip": $ip, "user": "root", "port": "22", "id_file": null, "provider": $provider, "spinupwp_id": $spinupwp_id}]' \
           "$SERVERS_FILE.tmp" > "$SERVERS_FILE.tmp2"
        
        mv "$SERVERS_FILE.tmp2" "$SERVERS_FILE.tmp"
    done
    
    # Sort by name
    jq 'sort_by(.name)' "$SERVERS_FILE.tmp" > "$SERVERS_FILE"
    rm "$SERVERS_FILE.tmp"
    
    echo "Imported $count servers from SpinupWP API"
}

# Function to select a server
select_server() {
    local count=$(jq 'length' "$SERVERS_FILE")
    
    if [ "$count" -eq 0 ]; then
        echo "No servers configured."
        return 1
    fi
    
    echo -e "\n${CYAN}Select a server (ID):${NC} "
    read -r server_id
    
    # Validate input
    if ! [[ "$server_id" =~ ^[0-9]+$ ]] || [ "$server_id" -ge "$count" ]; then
        echo "Error: Invalid server ID"
        return 1
    fi
    
    return 0
}

# Function to select a user
select_user() {
    local server_id="$1"
    local user=$(jq -r ".[$server_id].user" "$SERVERS_FILE")
    
    # If no user specified, use default
    if [ "$user" = "null" ] || [ -z "$user" ] || [ "$user" = "---" ]; then
        echo "$DEFAULT_USER"
        return 0
    fi
    
    # If only one user, use it
    if [[ ! "$user" =~ "," ]]; then
        echo "$user"
        return 0
    fi
    
    # If multiple users, let the user choose
    echo -e "\n${CYAN}Available users:${NC}"
    local i=0
    IFS=',' read -ra USERS <<< "$user"
    for u in "${USERS[@]}"; do
        echo "$i. $u"
        i=$((i + 1))
    done
    
    echo -e "\n${CYAN}Select a user (0-$((i-1))):${NC} "
    read -r user_id
    
    # Validate input
    if ! [[ "$user_id" =~ ^[0-9]+$ ]] || [ "$user_id" -ge "$i" ]; then
        echo "Invalid selection, using first user"
        echo "${USERS[0]}"
        return 0
    fi
    
    echo "${USERS[$user_id]}"
    return 0
}

# Function to build connection string
build_connection_string() {
    local server_id="$1"
    local user="$2"
    local protocol="$3"
    
    local ip=$(jq -r ".[$server_id].ip" "$SERVERS_FILE")
    local port=$(jq -r ".[$server_id].port // 22" "$SERVERS_FILE")
    local id_file=$(jq -r ".[$server_id].id_file // \"$DEFAULT_IDENTITY\"" "$SERVERS_FILE")
    
    # Build port string
    local port_str=""
    if [ "$port" != "22" ]; then
        port_str="-p $port "
    fi
    
    # Build identity string
    local identity_str=""
    if [ "$id_file" != "null" ] && [ -n "$id_file" ] && [ "$id_file" != "---" ]; then
        # Replace ~ with $HOME
        id_file="${id_file/#\~/$HOME}"
        identity_str="-i $id_file "
    fi
    
    # Build connection string
    echo "$protocol $identity_str$port_str$user@$ip"
}

# Function to copy to clipboard
copy_to_clipboard() {
    local string="$1"
    echo "$string" | pbcopy
    echo -e "${GREEN}Command copied to clipboard!${NC} Paste to connect."
}

# Main logic

# Import from legacy .servers file if requested
if [ -n "$IMPORT" ]; then
    import_from_legacy "$IMPORT"
    exit 0
fi

# Import from SpinupWP API if requested
if [ "$SPINUP" = true ]; then
    import_from_spinupwp
    exit 0
fi

# List all servers if requested
if [ "$LIST" = true ]; then
    list_servers
    exit 0
fi

# Check if servers file exists and has servers
check_jq
ensure_servers_file
if ! list_servers; then
    echo "Please add servers using --import or --spinup first."
    exit 1
fi

# Select a server
if ! select_server; then
    exit 1
fi

# Set protocol (ssh or sftp)
PROTOCOL="$DEFAULT_PROTOCOL"
if [ "$SFTP" = true ]; then
    PROTOCOL="sftp"
fi

# Get user
USER=$(select_user "$server_id")

# Build SSH connection command
SSH_CMD=$(build_connection_string "$server_id" "$USER" "$PROTOCOL")

# Display and copy to clipboard
echo -e "\n${GREEN}Connection:${NC} $SSH_CMD"

# Copy to clipboard if enabled
if [ "$CLIPBOARD" = true ]; then
    copy_to_clipboard "$SSH_CMD"
fi

# Connect directly if desired
echo -e "\n${CYAN}Press Enter to connect or Ctrl+C to exit${NC}"
read -r
$SSH_CMD