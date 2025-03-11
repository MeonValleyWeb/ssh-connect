# SSH Connect

A modern, menu-driven SSH connection manager for SpinupWP servers and sites.

## Features

- Interactive menu system for easy SSH management
- Connect to servers as sudo user
- Connect to individual sites with the correct permissions
- Run commands across all sites on a server
- Run composer commands across all sites on a server
- SpinupWP API integration for server and site import
- Custom site username support

## Installation

```bash
# Download the script
sudo curl -o /usr/local/bin/ssh-connect https://raw.githubusercontent.com/MeonValleyWeb/ssh-connect/main/ssh-connect
sudo chmod +x /usr/local/bin/ssh-connect
```

## Configuration

SSH Connect automatically creates configuration files in `~/.ssh-connect/`:

1. Set your SpinupWP API token (if using API integration):
   ```bash
   echo 'SPINUPWP_API_TOKEN="your-token-here"' > ~/.ssh-connect/spinupwp
   ```

2. Set your preferred sudo username:
   ```bash
   echo 'SUDO_USER="your-username"' > ~/.ssh-connect/config
   ```

3. Custom site usernames can be defined in `~/.ssh-connect/site_users.json`:
   ```json
   {
     "server.example.com": {
       "site1.com": "site1_user",
       "site2.com": "site2_user"
     }
   }
   ```

## Usage

### Interactive Mode

Simply run:
```bash
ssh-connect
```

This will present an interactive menu to:
- Select and connect to servers
- Connect to specific sites
- Run commands on specific sites
- Run commands on all sites
- Run composer commands on all sites

### Command-Line Mode

```bash
# Import servers from SpinupWP API
ssh-connect --import

# Connect to a specific server
ssh-connect -s 1

# Run a command on all sites on server 1
ssh-connect -a "wp plugin update --all" -s 1

# Run composer update on all sites on server 2
ssh-connect -c "update" -s 2
```

## Commands

- `-h, --help` - Display help information
- `-v, --version` - Display version information
- `-i, --import` - Import servers from SpinupWP API
- `-s, --server ID` - Connect directly to server ID
- `-a, --all-sites CMD` - Run command on all sites
- `-c, --composer CMD` - Run composer command on all sites

## Requirements

- macOS or Linux
- `jq` utility for JSON processing (install with `brew install jq`)
- SSH key access to your servers

## License

MIT License