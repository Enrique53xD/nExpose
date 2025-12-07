#!/bin/bash

# --- Configuration ---
DEFAULT_PORT=8080
TUNNEL_NAME="" 

# --- Colors (Fixed for macOS) ---
# We use $'\033...' to force the shell to interpret the escape code
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m' # No Color

PORT="${1:-$DEFAULT_PORT}"

# 1. Check for blocking processes
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

# 2. Start File Server
echo "${GREEN}Starting server on port $PORT...${NC}"

if [ -f "index.html" ]; then
  echo "${BLUE}Mode: Website (index.html detected)${NC}"
  miniserve . --index index.html --interfaces 127.0.0.1 -p $PORT > /dev/null 2>&1 &
else
  echo "${BLUE}Mode: File Browser${NC}"
  miniserve . --interfaces 127.0.0.1 -p $PORT > /dev/null 2>&1 &
fi

PID=$!
trap "kill $PID 2>/dev/null" EXIT INT TERM

# 3. Health Check
sleep 1
if ! ps -p $PID > /dev/null; then
    echo "${RED}Error: Server failed to start.${NC}"
    exit 1
fi

# 4. Start Tunnel
if [ -z "$TUNNEL_NAME" ]; then
    echo "${GREEN}Establishing secure tunnel...${NC}"
    echo "${YELLOW}Use the link below to access your files:${NC}"
    cloudflared tunnel --url http://127.0.0.1:$PORT 2>&1 | grep --color=never "trycloudflare.com"
else
    echo "${GREEN}Live at your custom domain.${NC}"
    cloudflared tunnel run --protocol http2 --url http://127.0.0.1:$PORT $TUNNEL_NAME
fi
