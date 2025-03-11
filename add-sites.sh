#!/usr/bin/env bash
#
# Script to manually add sites to your server configuration
#

CONFIG_DIR="$HOME/.ssh-connect"
SERVERS_FILE="$CONFIG_DIR/servers.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Make sure servers file exists
if [ ! -f "$SERVERS_FILE" ]; then
    echo -e "${RED}Error: Server configuration file not found at $SERVERS_FILE${NC}"
    echo "Please run ssh-connect --import first to create your server configuration."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Function to list servers
list_servers() {
    local count=$(jq 'length' "$SERVERS_FILE")
    if [ "$count" -eq 0 ]; then
        echo "No servers configured."
        return 1
    fi
    
    echo -e "\n${YELLOW}Configured Servers:${NC}"
    echo "---------------------------------------------------------------------------------------------------------"
    printf "%-4s %-30s %-20s %-15s\n" "ID" "Name" "IP" "User"
    echo "---------------------------------------------------------------------------------------------------------"
    
    for i in $(seq 0 $(($count - 1))); do
        local name=$(jq -r ".[$i].name" "$SERVERS_FILE")
        local ip=$(jq -r ".[$i].ip" "$SERVERS_FILE")
        local user=$(jq -r ".[$i].user // \"root\"" "$SERVERS_FILE")
        
        printf "%-4s %-30s %-20s %-15s\n" "$i" "${name:0:30}" "${ip:0:20}" "${user:0:15}"
    done
    
    return 0
}

# List existing servers
list_servers

# Select server to add sites to
echo -e "\n${YELLOW}Select a server (ID) to add sites to:${NC} "
read -r server_id

# Validate server ID
server_count=$(jq 'length' "$SERVERS_FILE")
if ! [[ "$server_id" =~ ^[0-9]+$ ]] || [ "$server_id" -ge "$server_count" ]; then
    echo -e "${RED}Error: Invalid server ID${NC}"
    exit 1
fi

# Get server name for reference
server_name=$(jq -r ".[$server_id].name" "$SERVERS_FILE")

echo -e "\n${GREEN}Adding sites to server:${NC} $server_name"
echo "Enter site information (leave blank to finish adding sites):"

# Temporary file to store the updated JSON
tmp_file=$(mktemp)

# Initial sites array (preserve existing sites if any)
sites=$(jq -r ".[$server_id].sites" "$SERVERS_FILE")

# Loop to add sites
while true; do
    echo -e "\n${BLUE}Enter site domain (or press Enter to finish):${NC} "
    read -r domain
    
    # Exit loop if domain is empty
    if [ -z "$domain" ]; then
        break
    fi
    
    echo -e "${BLUE}Enter site username (default: www-data):${NC} "
    read -r username
    if [ -z "$username" ]; then
        username="www-data"
    fi
    
    echo -e "${BLUE}Enter site path (default: /var/www/$domain):${NC} "
    read -r path
    if [ -z "$path" ]; then
        path="/var/www/$domain"
    fi
    
    echo -e "${BLUE}Enter site ID (any number, just for reference):${NC} "
    read -r site_id
    if [ -z "$site_id" ] || ! [[ "$site_id" =~ ^[0-9]+$ ]]; then
        site_id="1000"  # Default ID if not provided or not a number
    fi
    
    # Add site to sites array
    sites=$(echo "$sites" | jq ". += [{\"domain\": \"$domain\", \"id\": $site_id, \"username\": \"$username\", \"path\": \"$path\"}]")
    
    echo -e "${GREEN}Site added:${NC} $domain (Username: $username, Path: $path)"
done

# Update the server's sites array
jq --argjson server_id "$server_id" --argjson sites "$sites" \
   'map(if .==$server_id then .sites=$sites else . end)' "$SERVERS_FILE" > "$tmp_file"

# Only update if jq didn't produce an error
if [ $? -eq 0 ] && [ -s "$tmp_file" ]; then
    cp "$tmp_file" "$SERVERS_FILE"
    echo -e "\n${GREEN}Server configuration updated successfully!${NC}"
    
    # Count how many sites were added
    site_count=$(echo "$sites" | jq 'length')
    echo -e "Added/updated $site_count sites for server $server_name."
else
    echo -e "${RED}Error updating server configuration.${NC}"
    echo "Please check the JSON structure or permissions."
fi

# Clean up temporary file
rm "$tmp_file"

echo -e "\n${GREEN}Done! You can now use ssh-connect to manage your sites.${NC}"