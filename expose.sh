#!/bin/bash

# --- Defaults ---
DEFAULT_PORT=8080
TARGET="."    # Default to current folder
PORT=$DEFAULT_PORT
TUNNEL_NAME="mbpro" # Make sure this matches your tunnel name

# --- Colors ---
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
BLUE=$'\033[0;34m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

# --- 1. SMART ARGUMENT PARSING ---
# Check if the first argument is a specific file
if [[ -f "$1" ]]; then
    TARGET="$1"
    # If the second argument is a number, use it as the port
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        PORT="$2"
    fi
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    # If first argument is just a number, it's the port, target stays "."
    PORT="$1"
fi

# --- 2. Check for blocking processes ---
BLOCKING_PID=$(lsof -ti :$PORT)
if [ ! -z "$BLOCKING_PID" ]; then
  PROC_NAME=$(ps -p $BLOCKING_PID -o comm= | xargs basename)
  
  if [[ "$PROC_NAME" == "miniserve" ]]; then
      echo "${YELLOW}Found old miniserve session. Restarting...${NC}"
      kill -9 $BLOCKING_PID
      sleep 0.5
  else
      echo "${YELLOW}Port $PORT is busy. Used by:${NC}"
      lsof -i :$PORT | grep LISTEN
      echo ""
      echo -n "${RED}Do you want to kill this process? (y/n): ${NC}"
      read -k 1 REPLY 2>/dev/null || read -n 1 REPLY
      echo "" 
      if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
         echo "${RED}Killing process...${NC}"
         kill -9 $BLOCKING_PID
         sleep 0.5
      else
         echo "${RED}Aborted.${NC}"
         exit 1
      fi
  fi
fi

# --- 3. Start Server ---
echo "${GREEN}Starting server on port $PORT...${NC}"

if [[ -f "$TARGET" ]]; then
    # FILE MODE: Expose a single file (Direct Download)
    echo "${BLUE}Mode: Single File ($TARGET)${NC}"
    # We point miniserve directly at the file
    miniserve "$TARGET" --interfaces 127.0.0.1 -p $PORT > /dev/null 2>&1 &

elif [[ -f "index.html" && "$TARGET" == "." ]]; then
    # WEBSITE MODE: index.html found in current folder
    echo "${BLUE}Mode: Website (index.html detected)${NC}"
    miniserve . --index index.html --interfaces 127.0.0.1 -p $PORT > /dev/null 2>&1 &

else
    # FOLDER MODE: Standard file browser
    echo "${BLUE}Mode: File Browser${NC}"
    miniserve "$TARGET" --interfaces 127.0.0.1 -p $PORT > /dev/null 2>&1 &
fi

PID=$!
trap "kill $PID 2>/dev/null" EXIT INT TERM

# --- 4. Health Check ---
sleep 1
if ! ps -p $PID > /dev/null; then
    echo "${RED}Error: Server failed to start.${NC}"
    exit 1
fi

# --- 5. Start Tunnel ---
if [ -z "$TUNNEL_NAME" ]; then
    echo "${GREEN}Establishing secure tunnel...${NC}"
    echo "${YELLOW}Use the link below to access your file:${NC}"
    cloudflared tunnel --url http://127.0.0.1:$PORT 2>&1 | grep --color=never "trycloudflare.com"
else
    echo "${GREEN}Live at your custom domain.${NC}"
    cloudflared tunnel run --protocol http2 --url http://127.0.0.1:$PORT $TUNNEL_NAME
fi
