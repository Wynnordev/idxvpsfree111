#!/usr/bin/env bash
set -e

# --- COLORS ---
G=$'\033[32m' # Green
Y=$'\033[33m' # Yellow
C=$'\033[36m' # Cyan
R=$'\033[31m' # Red
N=$'\033[0m'  # Reset

echo ""
echo "${Y}🛠️  Fixing Broken Packages first...${N}"
# Ye command pichle errors ko clean karegi
dpkg --configure -a || true
apt --fix-broken install -y || true
apt-get autoremove -y || true

echo ""
echo "${C}➜ Updating System...${N}"
apt update -y

# 1. CLEANUP (Purana Node Hatana)
echo ""
echo "${Y}🗑️  Removing old Node/NPM to prevent conflicts...${N}"
apt-get remove -y nodejs npm libnode72 || true

# 2. SETUP NODE v22
echo ""
echo "${C}➜ Adding Node.js v22 Source...${N}"
apt install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

# 3. INSTALL NODEJS (Isme NPM included hai!)
echo ""
echo "${C}➜ Installing Node.js & NPM...${N}"
apt install -y nodejs
apt install -y build-essential git

# 4. INSTALL MINEFLAYER
echo ""
echo "${C}➜ Installing Mineflayer...${N}"
cd /root
# Agar package.json nahi hai to banao
if [ ! -f "package.json" ]; then
    npm init -y
fi
# Mineflayer install karo
npm install mineflayer

echo ""
echo "${G}==============================================${N}"
echo "${G}   ✅  SUCCESS! EVERYTHING IS FIXED. ${N}"
echo "${G}==============================================${N}"
echo "Versions Installed:"
echo "👉 Node: $(node -v)"
echo "👉 NPM:  $(npm -v)"
echo ""
EOF
