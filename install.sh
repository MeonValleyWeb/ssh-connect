#!/usr/bin/env bash
#
# Installation script for SSH Connect
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Installing SSH Connect...${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Would you like to install jq using Homebrew? (y/n)"
    read -r install_jq
    
    if [[ "$install_jq" =~ ^[Yy]$ ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "${RED}Error: Homebrew is not installed.${NC}"
            echo "Please install Homebrew first: https://brew.sh/"
            exit 1
        fi
        
        echo "Installing jq..."
        brew install jq
    else
        echo "Please install jq manually and try again."
        exit 1
    fi
fi

# Determine the best installation directory
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
elif [ -d "/opt/homebrew/bin" ] && [ -w "/opt/homebrew/bin" ]; then
    INSTALL_DIR="/opt/homebrew/bin"
else
    # Fall back to user's bin directory
    INSTALL_DIR="$HOME/bin"
    
    # Create it if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR"
        
        # Add to PATH if not already there
        if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            echo "Adding $INSTALL_DIR to your PATH..."
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
            export PATH="$HOME/bin:$PATH"
        fi
    fi
fi

# Download the script
echo "Downloading SSH Connect to $INSTALL_DIR/ssh-connect..."
curl -s -o "$INSTALL_DIR/ssh-connect" https://raw.githubusercontent.com/MeonValleyWeb/ssh-connect/main/ssh-connect

# Make it executable
chmod +x "$INSTALL_DIR/ssh-connect"

echo -e "${GREEN}SSH Connect has been installed successfully!${NC}"
echo 
echo -e "Next steps:"
echo -e "1. Configure your SpinupWP API token:"
echo -e "   ${BLUE}mkdir -p ~/.ssh-connect${NC}"
echo -e "   ${BLUE}echo 'SPINUPWP_API_TOKEN=\"your-token-here\"' > ~/.ssh-connect/spinupwp${NC}"
echo
echo -e "2. Set your preferred sudo username:"
echo -e "   ${BLUE}echo 'SUDO_USER=\"your-username\"' > ~/.ssh-connect/config${NC}"
echo
echo -e "3. Import your servers:"
echo -e "   ${BLUE}ssh-connect --import${NC}"
echo
echo -e "4. Start using SSH Connect:"
echo -e "   ${BLUE}ssh-connect${NC}"
echo
echo -e "${YELLOW}For more information, run:${NC} ssh-connect --help"