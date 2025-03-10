#!/usr/bin/env bash
#
# SpinupWP API Debug Script
# Use this to test your SpinupWP API connection
#

# Set your API token here
API_TOKEN=""

# Check if token is provided
if [ -z "$API_TOKEN" ]; then
    echo "Please enter your SpinupWP API token: "
    read -r API_TOKEN
fi

echo "Testing SpinupWP API connection..."

# Test the official documented endpoint
echo "Testing documented endpoint https://api.spinupwp.app/v1/servers"
curl -v -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://api.spinupwp.app/v1/servers" | jq

# Try without www
echo "Testing without www https://spinupwp.app/v1/servers"
curl -v -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://spinupwp.app/v1/servers" | jq

# Try alternative formats
echo "Testing API format https://api.spinupwp.com/v1/servers"
curl -v -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://api.spinupwp.com/v1/servers" | jq

echo "Testing complete."