#!/usr/bin/env bash

# Path to configuration files
SERVERS_FILE="$HOME/.ssh-connect/servers.json"
SITE_USERS_FILE="$HOME/.ssh-connect/site_users.json"
TMP_FILE="/tmp/servers.json"

# Create a backup
cp "$SERVERS_FILE" "$SERVERS_FILE.bak"
echo "Created backup at $SERVERS_FILE.bak"

# Get the list of servers
SERVERS=$(jq -r 'keys[]' "$SITE_USERS_FILE")

# Process each server
for SERVER in $SERVERS; do
  echo "Processing server: $SERVER"
  
  # Find the server index in servers.json
  SERVER_INDEX=$(jq -r "map(.name == \"$SERVER\") | index(true)" "$SERVERS_FILE")
  
  if [ "$SERVER_INDEX" = "null" ]; then
    echo "Server $SERVER not found in servers.json, skipping..."
    continue
  fi
  
  # Get sites for this server
  SITES=$(jq -r ".[\"$SERVER\"] | keys[]" "$SITE_USERS_FILE")
  
  # Create sites array
  SITES_JSON="["
  
  for SITE in $SITES; do
    USERNAME=$(jq -r ".[\"$SERVER\"][\"$SITE\"]" "$SITE_USERS_FILE")
    PATH="/sites/$SITE/files" # Using the path format you specified
    
    # Only add comma if not the first entry
    if [ "$SITES_JSON" != "[" ]; then
      SITES_JSON="$SITES_JSON,"
    fi
    
    # Add site to array
    SITES_JSON="$SITES_JSON{\"domain\":\"$SITE\",\"id\":1000,\"username\":\"$USERNAME\",\"path\":\"$PATH\"}"
  done
  
  SITES_JSON="$SITES_JSON]"
  
  # Update server with sites array
  jq --argjson index "$SERVER_INDEX" --argjson sites "$SITES_JSON" '.[$index].sites = $sites' "$SERVERS_FILE" > "$TMP_FILE"
  cp "$TMP_FILE" "$SERVERS_FILE"
  
  echo "Added $(echo "$SITES_JSON" | jq 'length') sites to $SERVER"
done

echo "Done! All sites have been added to servers.json"