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

# Test the sites endpoint
echo "Testing /api/sites endpoint..."
curl -s -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://spinupwp.app/api/sites" | jq

# Test the servers endpoint
echo "Testing /api/servers endpoint..."
curl -s -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://spinupwp.app/api/servers" | jq

# Test without version prefix
echo "Testing /api/v1/servers endpoint..."
curl -s -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://spinupwp.app/api/v1/servers" | jq

echo "Testing /api/v1/sites endpoint..."
curl -s -H "Authorization: Bearer $API_TOKEN" -H "Accept: application/json" "https://spinupwp.app/api/v1/sites" | jq

echo "Testing complete."