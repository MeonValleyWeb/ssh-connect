#!/bin/bash

# Set these values
SERVER_IP="49.12.5.225"  # Change to your server's IP
USERNAME="fireflymediaserver"  # Change to a site username
SITE_PATH="/sites/fireflymediaserver.net/files"  # Path to test

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Testing Bedrock detection on:${NC}"
echo "Server: $SERVER_IP"
echo "Username: $USERNAME"
echo "Path: $SITE_PATH"

# Test SSH connectivity first
echo -e "\n${YELLOW}Testing basic SSH connectivity...${NC}"
ssh -v "$USERNAME@$SERVER_IP" "echo 'Connection successful'" 2>&1

# Now test Bedrock detection
echo -e "\n${YELLOW}Testing Bedrock detection...${NC}"
check_cmd="cd $SITE_PATH 2>/dev/null && "
check_cmd+="(test -f composer.json && echo 'COMPOSER:YES' || echo 'COMPOSER:NO') && "
check_cmd+="(test -f composer.json && grep -q 'roots/bedrock' composer.json && echo 'BEDROCK:YES' || echo 'BEDROCK:NO') && "
check_cmd+="(test -d web/wp && echo 'WEB_WP:YES' || echo 'WEB_WP:NO') && "
check_cmd+="(test -f .env && echo 'ENV:YES' || echo 'ENV:NO')"

echo -e "${BLUE}Running command:${NC} $check_cmd"
result=$(ssh "$USERNAME@$SERVER_IP" "$check_cmd" 2>&1)

echo -e "${BLUE}Results:${NC}"
echo "$result"

# Make a decision based on results
if echo "$result" | grep -q "YES"; then
    echo -e "\n${GREEN}✓ This appears to be a Bedrock site${NC}"
else
    echo -e "\n${RED}✗ Not detected as a Bedrock site${NC}"
    echo -e "Try running with SSH debugging to see authentication issues:"
    echo "ssh -v $USERNAME@$SERVER_IP \"cd $SITE_PATH && ls -la\""
fi