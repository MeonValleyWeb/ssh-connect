#!/bin/bash
#
# Debug script to test Bedrock detection for a specific site
# With improved SSH key handling
#

CONFIG_DIR="$HOME/.ssh-connect"
SERVERS_FILE="$CONFIG_DIR/servers.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default SSH identity file
DEFAULT_IDENTITY="$HOME/.ssh/id_rsa"

# Ask for SSH key file
echo -e "${YELLOW}SSH Key File (leave empty for default: $DEFAULT_IDENTITY):${NC} "
read -r ssh_key

if [ -z "$ssh_key" ]; then
    ssh_key="$DEFAULT_IDENTITY"
fi

if [ ! -f "$ssh_key" ]; then
    echo -e "${RED}SSH key file not found: $ssh_key${NC}"
    echo -e "Available keys in ~/.ssh:"
    ls -l ~/.ssh | grep -E "id_.*$"
    exit 1
fi

echo -e "${GREEN}Using SSH key: $ssh_key${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    exit 1
fi

# List servers
echo -e "${YELLOW}Available Servers:${NC}"
echo "-------------------------------------"
server_count=$(jq 'length' "$SERVERS_FILE")
for i in $(seq 0 $(($server_count - 1))); do
    name=$(jq -r ".[$i].name" "$SERVERS_FILE")
    echo "$i: $name"
done

# Select server
echo -e "\n${YELLOW}Select server (number):${NC} "
read -r server_id

# Validate server ID
if ! [[ "$server_id" =~ ^[0-9]+$ ]] || [ "$server_id" -ge "$server_count" ]; then
    echo -e "${RED}Invalid server ID${NC}"
    exit 1
fi

# List sites for the server
echo -e "\n${YELLOW}Sites on selected server:${NC}"
echo "-------------------------------------"
sites=$(jq -r ".[$server_id].sites" "$SERVERS_FILE")
site_count=$(echo "$sites" | jq 'length')

if [ "$site_count" -eq 0 ]; then
    echo -e "${RED}No sites found for this server.${NC}"
    exit 1
fi

for i in $(seq 0 $(($site_count - 1))); do
    domain=$(echo "$sites" | jq -r ".[$i].domain")
    path=$(echo "$sites" | jq -r ".[$i].path")
    echo "$i: $domain ($path)"
done

# Select site
echo -e "\n${YELLOW}Select site to test (number):${NC} "
read -r site_id

# Validate site ID
if ! [[ "$site_id" =~ ^[0-9]+$ ]] || [ "$site_id" -ge "$site_count" ]; then
    echo -e "${RED}Invalid site ID${NC}"
    exit 1
fi

# Get site details
domain=$(echo "$sites" | jq -r ".[$site_id].domain")
username=$(echo "$sites" | jq -r ".[$site_id].username")
path=$(echo "$sites" | jq -r ".[$site_id].path")
ip=$(jq -r ".[$server_id].ip" "$SERVERS_FILE")

echo -e "\n${YELLOW}Testing Bedrock detection for:${NC}"
echo "Domain: $domain"
echo "Path: $path"
echo "Username: $username"
echo "Server IP: $ip"

# Test basic SSH connectivity first
echo -e "\n${YELLOW}Testing basic SSH connectivity...${NC}"
if ssh -i "$ssh_key" -o BatchMode=no -o ConnectTimeout=5 "$username@$ip" "echo 'Connection successful'"; then
    echo -e "${GREEN}SSH connection successful!${NC}"
else
    echo -e "${RED}SSH connection failed. Check your SSH key and server configuration.${NC}"
    exit 1
fi

# Try different paths to check
possible_paths=(
    "$path"
    "$path/.."
    "${path%/files}"
    "/sites/$domain"
    "/var/www/$domain"
    "/home/$username/$domain"
)

echo -e "\n${YELLOW}Testing multiple possible paths:${NC}"

for test_path in "${possible_paths[@]}"; do
    echo -e "\n${BLUE}Testing path: $test_path${NC}"
    
    # Build check commands for Bedrock indicators
    check_cmd="cd $test_path 2>/dev/null && "
    check_cmd+="(test -f composer.json && echo 'COMPOSER:YES' || echo 'COMPOSER:NO') && "
    check_cmd+="(test -f composer.json && grep -q 'roots/bedrock' composer.json && echo 'BEDROCK_MENTION:YES' || echo 'BEDROCK_MENTION:NO') && "
    check_cmd+="(test -d web/wp && echo 'WEB_WP:YES' || echo 'WEB_WP:NO') && "
    check_cmd+="(test -d web/app && echo 'WEB_APP:YES' || echo 'WEB_APP:NO') && "
    check_cmd+="(test -f .env && echo 'ENV:YES' || echo 'ENV:NO') && "
    check_cmd+="(ls -la 2>/dev/null)"
    
    # Run the command with the specified SSH key
    echo -e "${YELLOW}Running check command...${NC}"
    ssh -i "$ssh_key" -o BatchMode=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$username@$ip" "$check_cmd"
    
    echo -e "\n${BLUE}---------------------------${NC}"
done

echo -e "\n${GREEN}Testing complete.${NC}"