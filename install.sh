#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}Installing Expose Tool...${NC}"

# 1. Check Homebrew
if ! command -v brew &> /dev/null; then
    echo "${RED}Error: Homebrew is not installed.${NC}"
    exit 1
fi

# 2. Install Dependencies
echo "${BLUE}Checking dependencies (cloudflared, miniserve)...${NC}"
brew install cloudflared miniserve -q

# 3. Setup Install Directory
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# CHANGE THIS URL TO YOUR GITHUB RAW LINK
REPO_URL="https://raw.githubusercontent.com/enrique53xd/expose/main/expose.sh"

echo "${BLUE}Downloading script...${NC}"
curl -sL "$REPO_URL" -o "$INSTALL_DIR/expose"
chmod +x "$INSTALL_DIR/expose"

# 4. Add to PATH if needed
SHELL_CONFIG=""
case "$SHELL" in
  */zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
  */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
  *) SHELL_CONFIG="$HOME/.profile" ;;
esac

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Added by Expose Tool" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
    echo "${GREEN}Added install dir to $SHELL_CONFIG${NC}"
    echo "${YELLOW}Please restart your terminal or run: source $SHELL_CONFIG${NC}"
else
    echo "${GREEN}Path already configured.${NC}"
fi

echo "${GREEN}Installation Complete.${NC}"
echo "Usage: expose [port]"
