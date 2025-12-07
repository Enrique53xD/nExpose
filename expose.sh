#!/bin/bash

# --- File Locations ---
CONFIG_FILE="$HOME/.nexpose_config"
REPO_URL="https://raw.githubusercontent.com/Enrique53xD/nExpose/main/expose.sh"

# --- ANSI Color Definitions ---
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color

# ==========================================
# CORE LOGIC: SETUP & RECOVERY
# ==========================================

function check_dependencies() {
    # Check if miniserve is installed; install via Homebrew if missing
    if ! command -v miniserve &> /dev/null; then
        echo "${YELLOW}[WARN] Missing dependency: miniserve${NC}"
        echo "${BLUE}Installing...${NC}"
        brew install miniserve -q
    fi

    # Check if cloudflared is installed; install via Homebrew if missing
    if ! command -v cloudflared &> /dev/null; then
        echo "${YELLOW}[WARN] Missing dependency: cloudflared${NC}"
        echo "${BLUE}Installing...${NC}"
        brew install cloudflared -q
    fi
}

function verify_config() {
    # Check for existence of configuration file
    if [ ! -f "$CONFIG_FILE" ]; then
        echo ""
        echo "${YELLOW}--- nExpose Configuration ---${NC}"
        echo "Select tunneling mode:"
        echo "  y: Configure Custom Domain (requires Cloudflare account)"
        echo "  n: Use Quick Tunnels (random temporary URLs)"
        echo -n "${BLUE}Setup Custom Domain? (y/n): ${NC}"
        read -k 1 REPLY 2>/dev/null || read -n 1 REPLY
        echo ""

        if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
            echo ""
            echo "${BLUE}Enter Tunnel Name (e.g., mbpro):${NC}"
            read INPUT_NAME
            echo "TUNNEL_NAME=\"$INPUT_NAME\"" > "$CONFIG_FILE"
        else
            echo "TUNNEL_NAME=\"\"" > "$CONFIG_FILE"
        fi
        echo "${GREEN}Configuration saved.${NC}"
    fi

    # Load configuration variables
    source "$CONFIG_FILE"

    # Validate environment if Custom Domain is active
    if [ ! -z "$TUNNEL_NAME" ]; then
        
        # Verify Cloudflare authentication status
        if [ ! -f "$HOME/.cloudflared/cert.pem" ]; then
            echo "${RED}[ERR] Cloudflare authentication missing.${NC}"
            echo "Press any key to open browser login..."
            read -k 1 -s 2>/dev/null || read -n 1 -s
            cloudflared tunnel login
        fi

        # Attempt to create tunnel if it does not exist (Self-Healing)
        # Suppress output; command fails silently if tunnel already exists
        cloudflared tunnel create "$TUNNEL_NAME" > /dev/null 2>&1
    fi
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

# Perform dependency and configuration checks
check_dependencies
verify_config

# Handle 'update' command to fetch latest script version
if [[ "$1" == "update" ]]; then
    if [[ "$(command -v expose)" == *"/Cellar/"* ]]; then
        echo "${YELLOW}[INFO] Installed via Homebrew. Run: brew upgrade nexpose${NC}"
    else
        echo "${BLUE}Updating...${NC}"
        curl -sL "$REPO_URL" -o "$0"
        chmod +x "$0"
        echo "${GREEN}Update complete.${NC}"
    fi
    exit 0
fi

# Handle 'config' command to reset local settings
if [[ "$1" == "config" ]]; then
    rm "$CONFIG_FILE"
    echo "${YELLOW}[INFO] Configuration cleared. Run 'expose' to re-initialize.${NC}"
    exit 0
fi

# --- Argument Parsing ---
DEFAULT_PORT=8080
PORT=$DEFAULT_PORT
TARGET="."
AUTH_FLAG=""
SHOW_QR=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --secure|-s)
            # Generate random 4-digit PIN for basic authentication
            PASS=$((1000 + RANDOM % 8999))
            AUTH_FLAG="--auth admin:$PASS"
            IS_SECURE=true
            ;;
        --qr|-q) 
            SHOW_QR=true 
            ;;
        *)
            # Determine if argument is a path or a port number
            if [[ -f "$1" || -d "$1" ]]; then TARGET="$1"
            elif [[ "$1" =~ ^[0-9]+$ ]]; then PORT="$1"
            fi
            ;;
    esac
    shift
done

# --- Port Conflict Resolution ---
# Identify process ID blocking the target port
BLOCKING_PID=$(lsof -ti :$PORT)
if [ ! -z "$BLOCKING_PID" ]; then
  PROC_NAME=$(ps -p $BLOCKING_PID -o comm= | xargs basename)
  
  # Automatically kill old miniserve instances
  if [[ "$PROC_NAME" == "miniserve" ]]; then
      kill -9 $BLOCKING_PID
  else
      # Prompt user before killing non-miniserve processes
      echo "${YELLOW}[WARN] Port $PORT is busy.${NC}"
      echo -n "${RED}Kill blocking process? (y/n): ${NC}"
      read -k 1 REPLY 2>/dev/null || read -n 1 REPLY
      [[ "$REPLY" == "y" ]] && kill -9 $BLOCKING_PID || exit 1
  fi
fi

# --- Server Initialization ---
echo "${GREEN}Starting server on port $PORT...${NC}"
CMD="miniserve \"$TARGET\" --interfaces 127.0.0.1 -p $PORT $AUTH_FLAG"

# Determine serving mode based on target type
if [[ -f "index.html" && "$TARGET" == "." ]]; then 
    CMD="$CMD --index index.html"
    echo "${BLUE}Mode: Website${NC}"
elif [[ -f "$TARGET" ]]; then
    echo "${BLUE}Mode: Single File${NC}"
else
    echo "${BLUE}Mode: File Browser${NC}"
fi

# Execute server command (backgrounded)
if [ "$SHOW_QR" = true ]; then 
    eval "$CMD --qrcode" &
else 
    eval "$CMD" > /dev/null 2>&1 &
fi

PID=$!
# Ensure background process termination on script exit
trap "kill $PID 2>/dev/null" EXIT INT TERM

# Verify server startup stability
sleep 1
if ! ps -p $PID > /dev/null; then echo "${RED}[ERR] Server failed to start.${NC}"; exit 1; fi

# --- Tunnel Initialization ---
if [ -z "$TUNNEL_NAME" ]; then
    # Quick Tunnel Mode (No Authentication)
    echo "${GREEN}Quick Tunnel Active:${NC}"
    cloudflared tunnel --url http://127.0.0.1:$PORT 2>&1 | grep --color=never "trycloudflare.com"
else
    # Custom Domain Mode (Authenticated)
    echo "${GREEN}Live at Custom Domain.${NC}"
    cloudflared tunnel run --protocol http2 --url http://127.0.0.1:$PORT $TUNNEL_NAME > /dev/null 2>&1
fi

# Display credentials if secure mode is active
if [ "$IS_SECURE" = true ]; then
    echo "${CYAN}[SECURE] User: admin | Pass: $PASS${NC}"
fi

# Keep script running to maintain child processes
wait $PID
