#!/bin/bash

# Path to configuration files
SERVERS_FILE="$HOME/.ssh-connect/servers.json"
SITE_USERS_FILE="$HOME/.ssh-connect/site_users.json"
TMP_FILE="/tmp/servers.json"

# Create a backup
cp "$SERVERS_FILE" "$SERVERS_FILE.bak"
echo "Created backup at $SERVERS_FILE.bak"

# Het1 sites
HET1_SITES='[
  {"domain": "groundtechsussex.co.uk", "id": 1001, "username": "groundtechsussex", "path": "/sites/groundtechsussex.co.uk/files"},
  {"domain": "lohsg.co.uk", "id": 1002, "username": "lohsg", "path": "/sites/lohsg.co.uk/files"},
  {"domain": "meonvalleyguide.com", "id": 1003, "username": "meonvalleyguide", "path": "/sites/meonvalleyguide.com/files"},
  {"domain": "meonvalleyweb.com", "id": 1004, "username": "meonvalleyweb", "path": "/sites/meonvalleyweb.com/files"},
  {"domain": "meonwebhosting.com", "id": 1005, "username": "meonwebhosting", "path": "/sites/meonwebhosting.com/files"},
  {"domain": "saintsdsa.org.uk", "id": 1006, "username": "saintsdsa", "path": "/sites/saintsdsa.org.uk/files"},
  {"domain": "twodogsandanawning.co.uk", "id": 1007, "username": "twodogsandanawning", "path": "/sites/twodogsandanawning.co.uk/files"}
]'

# Het2 sites
HET2_SITES='[
  {"domain": "fireflymediaserver.net", "id": 2001, "username": "fireflymediaserver", "path": "/sites/fireflymediaserver.net/files"},
  {"domain": "landing.meonvalleyhub.com", "id": 2002, "username": "landing", "path": "/sites/landing.meonvalleyhub.com/files"},
  {"domain": "lohsg.meonvalleyhub.com", "id": 2003, "username": "lohsg", "path": "/sites/lohsg.meonvalleyhub.com/files"},
  {"domain": "packages.meonvalleyweb.com", "id": 2004, "username": "packages", "path": "/sites/packages.meonvalleyweb.com/files"},
  {"domain": "sdsa.meonvalleyhub.com", "id": 2005, "username": "sdsa", "path": "/sites/sdsa.meonvalleyhub.com/files"},
  {"domain": "twodogs.meonvalleyhub.com", "id": 2006, "username": "twodogs", "path": "/sites/twodogs.meonvalleyhub.com/files"}
]'

# Phil sites
PHIL_SITES='[
  {"domain": "twodogsandanawning.co.uk", "id": 3001, "username": "twodogsandanawning", "path": "/sites/twodogsandanawning.co.uk/files"}
]'

# Step 1: Update het1.meonvalleyhub.com (index 0)
echo "Updating het1.meonvalleyhub.com..."
/opt/homebrew/bin/jq '.[0].sites = '"$HET1_SITES" "$SERVERS_FILE" > "$TMP_FILE"
cp "$TMP_FILE" "$SERVERS_FILE"
echo "Added 7 sites to het1.meonvalleyhub.com"

# Step 2: Update het2.meonvalleyhub.com (index 1)
echo "Updating het2.meonvalleyhub.com..."
/opt/homebrew/bin/jq '.[1].sites = '"$HET2_SITES" "$SERVERS_FILE" > "$TMP_FILE"
cp "$TMP_FILE" "$SERVERS_FILE"
echo "Added 6 sites to het2.meonvalleyhub.com"

# Step 3: Update phil.meonvalleyweb.com (index 2)
echo "Updating phil.meonvalleyweb.com..."
/opt/homebrew/bin/jq '.[2].sites = '"$PHIL_SITES" "$SERVERS_FILE" > "$TMP_FILE"
cp "$TMP_FILE" "$SERVERS_FILE"
echo "Added 1 site to phil.meonvalleyweb.com"

echo "Done! All sites have been added to servers.json"