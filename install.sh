#!/bin/bash

# --- Colors ---
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

echo "${BLUE}Installing nExpose...${NC}"

# 1. Install Dependencies
if ! command -v brew &> /dev/null; then
    echo "${RED}Error: Homebrew is not installed.${NC}"
    exit 1
fi
echo "${BLUE}Checking dependencies...${NC}"
brew install cloudflared miniserve -q

# 2. Setup Install Directory
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Repo URL
REPO_URL="https://raw.githubusercontent.com/Enrique53xD/nExpose/main/expose.sh"

echo "${BLUE}Downloading script...${NC}"
curl -sL "$REPO_URL" -o "$INSTALL_DIR/expose"
chmod +x "$INSTALL_DIR/expose"

# 3. Add to PATH
SHELL_CONFIG=""
case "$SHELL" in
  */zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
  */bash) SHELL_CONFIG="$HOME/.bashrc" ;;
  *) SHELL_CONFIG="$HOME/.profile" ;;
esac

if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Added by nExpose" >> "$SHELL_CONFIG"
    echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
fi

# --- 4. THE SMART SETUP WIZARD ---

echo ""
echo "${YELLOW}--- Configuration Setup ---${NC}"
echo "Do you want to setup a Custom Domain (e.g. dev.yourname.com)?"
echo -n "${BLUE}Setup Cloudflare Tunnel? (y/n): ${NC}"
read -n 1 REPLY < /dev/tty
echo ""

if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
    
    # A. Check Login Status
    if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
        echo ""
        echo "${RED}You are not logged in to Cloudflare.${NC}"
        echo "Press any key to open the login page in your browser..."
        read -n 1 -s < /dev/tty
        cloudflared tunnel login
    fi

    echo ""
    echo "${BLUE}What do you want to name this computer/tunnel?${NC}"
    echo "(Example: mbpro, imac, work-laptop)"
    echo -n "${YELLOW}> ${NC}"
    read TUNNEL_NAME < /dev/tty

    if [ ! -z "$TUNNEL_NAME" ]; then
        echo "${BLUE}Creating tunnel '${TUNNEL_NAME}'...${NC}"
        
        # B. Create the tunnel (Ignore error if it already exists)
        cloudflared tunnel create "$TUNNEL_NAME" 2>/dev/null || echo "${GREEN}Tunnel '$TUNNEL_NAME' already exists. Using it.${NC}"
        
        # C. Update the script
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/TUNNEL_NAME=\"\"/TUNNEL_NAME=\"$TUNNEL_NAME\"/" "$INSTALL_DIR/expose"
        else
            sed -i "s/TUNNEL_NAME=\"\"/TUNNEL_NAME=\"$TUNNEL_NAME\"/" "$INSTALL_DIR/expose"
        fi
        
        echo ""
        echo "${GREEN}Success! nExpose is linked to tunnel: $TUNNEL_NAME${NC}"
        echo "${YELLOW}⚠️  IMPORTANT FINAL STEP:${NC}"
        echo "You must route a URL to this tunnel. Run this command now:"
        echo "${BLUE}cloudflared tunnel route dns $TUNNEL_NAME dev.yourdomain.com${NC}"
    else
        echo "${RED}Skipping. No name provided.${NC}"
    fi
else
    echo "${GREEN}Keeping default settings (Random URLs).${NC}"
fi

echo ""
echo "${GREEN}Installation Complete!${NC}"
echo "${YELLOW}Please restart your terminal or run: source $SHELL_CONFIG${NC}"
