#!/usr/bin/env bash
# ==========================================
#    Auto-Restarter Installer 🚀
#    (Safe Mode: Asks First)
# ==========================================

set -euo pipefail

# --- ANSI COLORS ---
G=$'\033[32m'  # Green
B=$'\033[34m'  # Blue
R=$'\033[31m'  # Red
C=$'\033[36m'  # Cyan
W=$'\033[97m'  # White
N=$'\033[0m'   # Reset
Y=$'\033[33m'  # Yellow

# --- CONFIGURATION ---
BOT_FILE="/root/app.js"    # Your bot file path
SERVICE_NAME="mybot"       # Name of the background service

# --- UTILS ---
typewriter() {
  local text="$1"
  local delay="${2:-0.005}"
  for ((i=0; i<${#text}; i++)); do
    printf "%s" "${text:i:1}"
    sleep "$delay"
  done
  printf "\n"
}

spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# --- ROOT CHECK ---
if [[ "$EUID" -ne 0 ]]; then
  printf "%b\n" "${R}❌ Error: Please run with sudo or as root${N}"
  exit 1
fi

# --- MAIN SCRIPT ---
clear
printf "%b\n" "${B}=========================================${N}"
printf "%b\n" "${C}    🤖  NODE.JS BOT AUTO-RESTARTER       ${N}"
printf "%b\n" "${B}=========================================${N}"
echo ""

# 1. CHECK DEPENDENCIES
NODE_PATH=$(which node)
if [[ -z "$NODE_PATH" ]]; then
    printf "%b\n" "${R}❌ Error: Node.js not found! Install it first.${N}"
    exit 1
fi

if [[ ! -f "$BOT_FILE" ]]; then
    printf "%b\n" "${R}❌ Error: Bot file $BOT_FILE not found!${N}"
    exit 1
fi

# 2. ASK FOR PERMISSION FIRST (Before doing anything)
while true; do
    echo "${Y}[?] This will STOP any old bot service and create a new one.${N}"
    read -p "👉 Do you want to proceed? (y/n): " yn < /dev/tty
    case $yn in
        [Yy]* ) 
            echo ""
            break  # Break loop and continue to installation
            ;;
        [Nn]* ) 
            echo ""
            echo "${C}🚫 Operation cancelled. Nothing was changed.${N}"
            exit 0
            ;;
        * ) echo "Please answer yes (y) or no (n).";;
    esac
done

# 3. CLEANUP (Only runs if user said YES)
typewriter "${R}🧹 Cleaning up old services...${N}"
(
  systemctl stop $SERVICE_NAME 2>/dev/null || true
  systemctl disable $SERVICE_NAME 2>/dev/null || true
  rm -f /etc/systemd/system/${SERVICE_NAME}.service
  systemctl daemon-reload
) & spinner

printf "%b\n" "${G}✔ Old services stopped & deleted.${N}"
echo ""

# 4. CREATE NEW SERVICE
typewriter "${W}⚙️  Creating new service configuration...${N}"

cat <<EOF > /etc/systemd/system/${SERVICE_NAME}.service
[Unit]
Description=NodeJS Minecraft Bot
After=network.target

[Service]
User=root
WorkingDirectory=$(dirname $BOT_FILE)
ExecStart=$NODE_PATH $BOT_FILE
Restart=always
RestartSec=10
SyslogIdentifier=$SERVICE_NAME

[Install]
WantedBy=multi-user.target
EOF

# 5. START SERVICE
typewriter "${W}🚀 Starting bot service...${N}"
(
    systemctl daemon-reload
    systemctl enable $SERVICE_NAME
    systemctl start $SERVICE_NAME
) & spinner

echo ""
printf "%b\n" "${G}✅ SUCCESS: Bot is now running with Auto-Restarter!${N}"
echo "-----------------------------------------------"
echo " • Check Logs:  journalctl -u $SERVICE_NAME -f"
echo " • Stop Bot:    systemctl stop $SERVICE_NAME"
echo "-----------------------------------------------"
