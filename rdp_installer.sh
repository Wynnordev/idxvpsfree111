#!/usr/bin/env bash
# ==========================================================
#  RDP Installer 🚀
#  SUBSCRIBE TO NotGamerPie
# ==========================================================

set -euo pipefail

# ---------------- ANSI COLORS (SAFE) ----------------
G=$'\033[32m'
B=$'\033[34m'
Y=$'\033[33m'
R=$'\033[31m'
C=$'\033[36m'
W=$'\033[97m'
N=$'\033[0m'

# ---------------- ROOT CHECK ----------------
if [[ "$EUID" -ne 0 ]]; then
  printf "%b\n" "${R}❌ Please run with sudo${N}"
  exit 1
fi

USER_NAME="${SUDO_USER:-root}"
USER_HOME="$(eval echo ~${USER_NAME})"

# ---------------- UTIL FUNCTIONS ----------------
divider() {
  printf "%b\n" "${B}==============================================================${N}"
}

typewriter() {
  local text="$1"
  local delay="${2:-0.015}"
  for ((i=0; i<${#text}; i++)); do
    printf "%s" "${text:i:1}"
    sleep "$delay"
  done
  printf "\n"
}

spinner() {
  local pid=$!
  local frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while kill -0 "$pid" 2>/dev/null; do
    for ((i=0;i<${#frames};i++)); do
      printf "\r%b" "${C}${frames:i:1} Working...${N}"
      sleep 0.08
    done
  done
  printf "\r%b\n" "${G}✔ Done${N}"
}

progress_bar() {
  local percent=$1 width=40
  local filled=$((percent*width/100))
  local empty=$((width-filled))
  printf "%b[" "${Y}"
  printf "%0.s█" $(seq 1 "$filled")
  printf "%0.s░" $(seq 1 "$empty")
  printf "] %d%%%b\n" "$percent" "${N}"
}

run_step() {
  local label="$1"; shift
  printf "%b\n" "${G}🔹 ${label}${N}"
  ( "$@" ) & spinner
}

# ---------------- INTRO ----------------
clear
printf "%b\n" "${C}"
cat <<'EOF'
  ____      _               ____  _      
 / ___|   _| |__   ___ _ __|  _ \(_) ___ 
| |  | | | | '_ \ / _ \ '__| |_) | |/ _ \
| |__| |_| | |_) |  __/ |  |  __/| |  __/
 \____\__, |_.__/ \___|_|  |_|   |_|\___|
      |___/          By NotGamerPie
EOF
printf "%b\n" "${N}"

divider
printf "%b" "${W}"; typewriter "🚀 RDP Installer"; printf "%b" "${N}"
printf "%b" "${Y}"; typewriter "SUBSCRIBE TO Sagar Gaming 2X"; printf "%b" "${N}"
divider
sleep 0.6

# ---------------- SYSTEM CHECK ----------------
RAM_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
printf "%b\n" "${B}🧠 RAM Detected: ${RAM_MB} MB${N}"
if [[ "$RAM_MB" -lt 2000 ]]; then
  printf "%b\n" "${Y}⚠️ Low RAM detected — optimized defaults enabled${N}"
fi
sleep 0.4

# ---------------- STEPS ----------------
STEP=0; TOTAL=8
step() {
  STEP=$((STEP+1))
  local percent=$((STEP*100/TOTAL))
  printf "%b\n" "${W}➡️  Step ${STEP}/${TOTAL}${N}"
  progress_bar "$percent"
}

step
run_step "Updating system" apt update -y

step
run_step "Upgrading packages" apt upgrade -y

step
run_step "Installing XFCE & XRDP" apt install -y xfce4 xfce4-goodies xrdp

step
run_step "Installing Firefox ESR" apt install -y firefox-esr

step
printf "%b\n" "${G}🔹 Configuring XFCE session${N}"
(
  printf "startxfce4\n" > "${USER_HOME}/.xsession"
  chown "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.xsession"
) & spinner

step
printf "%b\n" "${G}🔹 Enabling XRDP service${N}"
(systemctl enable xrdp && systemctl restart xrdp) & spinner

step
printf "%b\n" "${G}🔹 Applying XRDP black-screen fix${N}"
(
  sed -i.bak 's/^test -x/#test -x/' /etc/xrdp/startwm.sh || true
  {
    printf "unset DBUS_SESSION_BUS_ADDRESS\n"
    printf "unset XDG_RUNTIME_DIR\n"
  } >> /etc/xrdp/startwm.sh
  systemctl restart xrdp
) & spinner

step
printf "%b\n" "${G}🔹 Firewall: allowing RDP (3389)${N}"
(
  if command -v ufw >/dev/null 2>&1; then
    ufw allow 3389/tcp
    ufw reload
  else
    printf "UFW not installed — skipped\n"
  fi
) & spinner

# ---------------- FINISH ----------------
divider
printf "%b" "${G}"; typewriter "✅ Installation Completed Successfully!"; printf "%b" "${N}"
printf "%b" "${Y}"; typewriter "💻 Connect via RDP → Port 3389"; printf "%b" "${N}"
printf "%b" "${G}"; typewriter "🔥 Powered by NotGamerPie"; printf "%b" "${N}"
divider
