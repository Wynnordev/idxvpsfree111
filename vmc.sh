#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# VNC WEB DESKTOP FOR TERMUX - SIMPLE VERSION
# Password: 123456 (Auto)
# ═══════════════════════════════════════════════════════════════

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Cấu hình
VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
VNC_RESOLUTION="1280x720"
PASSWORD="123456"
VNC_DIR="$HOME/.vnc"
NOVNC_DIR="$HOME/noVNC"

# ═══════════════════════════════════════════════════════════════
# HÀM TIỆN ÍCH
# ═══════════════════════════════════════════════════════════════

get_ip() {
    ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}' | head -1
    if [ -z "$ip" ]; then echo "localhost"; fi
}

print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║     🖥️  VNC WEB DESKTOP FOR TERMUX          ║"
    echo "║     🔑 Password: 123456                      ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════
# CÀI ĐẶT
# ═══════════════════════════════════════════════════════════════

install_packages() {
    echo -e "${CYAN}[*] Đang cài đặt packages...${NC}"
    pkg update -y
    pkg install -y x11-repo
    pkg install -y tigervnc xfce4 xfce4-goodies websockify git
    
    # Clone noVNC nếu chưa có
    if [ ! -d "$NOVNC_DIR" ]; then
        git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR"
        cp "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/index.html" 2>/dev/null
    fi
    
    echo -e "${GREEN}[✓] Cài đặt hoàn tất!${NC}"
}

# ═══════════════════════════════════════════════════════════════
# THIẾT LẬP MẬT KHẨU TỰ ĐỘNG (123456)
# ═══════════════════════════════════════════════════════════════

setup_password() {
    mkdir -p "$VNC_DIR"
    
    # Đặt mật khẩu 123456 tự động
    echo "$PASSWORD" | vncpasswd -f > "$VNC_DIR/passwd" 2>/dev/null
    chmod 600 "$VNC_DIR/passwd"
    
    # Tạo xstartup
    cat > "$VNC_DIR/xstartup" << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
xfce4-session &
EOF
    chmod +x "$VNC_DIR/xstartup"
    
    echo -e "${GREEN}[✓] Mật khẩu đã đặt: ${WHITE}123456${NC}"
}

# ═══════════════════════════════════════════════════════════════
# KHỞI ĐỘNG / DỪNG
# ═══════════════════════════════════════════════════════════════

start_vnc() {
    echo -e "${CYAN}[*] Khởi động VNC Server...${NC}"
    
    # Đảm bảo có mật khẩu
    [ ! -f "$VNC_DIR/passwd" ] && setup_password
    
    # Dừng VNC cũ
    vncserver -kill "$VNC_DISPLAY" 2>/dev/null
    pkill -f "Xvnc" 2>/dev/null
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null
    sleep 1
    
    # Khởi động VNC
    vncserver "$VNC_DISPLAY" -geometry "$VNC_RESOLUTION" -depth 24 -localhost no
    sleep 2
    
    if pgrep -x "Xvnc" > /dev/null; then
        echo -e "${GREEN}[✓] VNC Server đang chạy trên port $VNC_PORT${NC}"
    else
        echo -e "${RED}[✗] Lỗi khởi động VNC!${NC}"
    fi
}

start_novnc() {
    echo -e "${CYAN}[*] Khởi động noVNC Web...${NC}"
    
    # Dừng websockify cũ
    pkill -f "websockify" 2>/dev/null
    sleep 1
    
    # Khởi động websockify
    if [ -d "$NOVNC_DIR" ]; then
        websockify --web="$NOVNC_DIR" "$NOVNC_PORT" "localhost:$VNC_PORT" &
    else
        websockify "$NOVNC_PORT" "localhost:$VNC_PORT" &
    fi
    sleep 2
    
    if pgrep -f "websockify" > /dev/null; then
        echo -e "${GREEN}[✓] noVNC đang chạy trên port $NOVNC_PORT${NC}"
    else
        echo -e "${RED}[✗] Lỗi khởi động noVNC!${NC}"
    fi
}

start_all() {
    setup_password
    start_vnc
    start_novnc
    show_info
}

stop_all() {
    echo -e "${CYAN}[*] Đang dừng tất cả...${NC}"
    vncserver -kill "$VNC_DISPLAY" 2>/dev/null
    pkill -f "Xvnc" 2>/dev/null
    pkill -f "websockify" 2>/dev/null
    pkill -f "xfce" 2>/dev/null
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null
    echo -e "${GREEN}[✓] Đã dừng tất cả!${NC}"
}

# ═══════════════════════════════════════════════════════════════
# HIỂN THỊ THÔNG TIN
# ═══════════════════════════════════════════════════════════════

show_info() {
    local ip=$(get_ip)
    local vnc_ok=$(pgrep -x "Xvnc" > /dev/null && echo "1" || echo "0")
    local web_ok=$(pgrep -f "websockify" > /dev/null && echo "1" || echo "0")
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        🖥️  VNC WEB DESKTOP ĐÃ SẴN SÀNG!             ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    
    if [ "$vnc_ok" = "1" ]; then
        echo -e "${GREEN}║${NC}  ✅ VNC Server: ${WHITE}Đang chạy${NC} (Port: $VNC_PORT)          ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ VNC Server: ${RED}Không chạy${NC}                        ${GREEN}║${NC}"
    fi
    
    if [ "$web_ok" = "1" ]; then
        echo -e "${GREEN}║${NC}  ✅ noVNC Web:  ${WHITE}Đang chạy${NC} (Port: $NOVNC_PORT)          ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ noVNC Web:  ${RED}Không chạy${NC}                        ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  🔑 Mật khẩu:   ${YELLOW}123456${NC}                              ${GREEN}║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  🌐 ${WHITE}http://$ip:$NOVNC_PORT/vnc.html${NC}"
    echo -e "${GREEN}║${NC}  🌐 ${WHITE}http://localhost:$NOVNC_PORT/vnc.html${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_status() {
    local vnc_ok=$(pgrep -x "Xvnc" > /dev/null && echo "${GREEN}● ON${NC}" || echo "${RED}● OFF${NC}")
    local web_ok=$(pgrep -f "websockify" > /dev/null && echo "${GREEN}● ON${NC}" || echo "${RED}● OFF${NC}")
    echo -e "VNC: $vnc_ok | Web: $web_ok | Pass: ${YELLOW}123456${NC}"
}

# ═══════════════════════════════════════════════════════════════
# MENU CHÍNH
# ═══════════════════════════════════════════════════════════════

show_menu() {
    print_banner
    show_status
    echo ""
    echo -e "  ${WHITE}1)${NC} 🚀 Khởi động"
    echo -e "  ${WHITE}2)${NC} ⏹️  Dừng"
    echo -e "  ${WHITE}3)${NC} 🔄 Khởi động lại"
    echo -e "  ${WHITE}4)${NC} 📊 Trạng thái"
    echo -e "  ${WHITE}5)${NC} 📦 Cài đặt packages"
    echo -e "  ${WHITE}0)${NC} 🚪 Thoát"
    echo ""
    read -p "  Chọn: " choice
    
    case "$choice" in
        1) start_all ;;
        2) stop_all ;;
        3) stop_all; sleep 2; start_all ;;
        4) show_info ;;
        5) install_packages ;;
        0) echo -e "${CYAN}Tạm biệt! Pass: 123456${NC}"; exit 0 ;;
        *) echo -e "${RED}Lựa chọn không hợp lệ!${NC}" ;;
    esac
    
    echo ""
    read -p "  Nhấn Enter để tiếp tục..."
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

case "$1" in
    start)   setup_password; start_vnc; start_novnc; show_info ;;
    stop)    stop_all ;;
    restart) stop_all; sleep 2; start_all ;;
    status)  show_info ;;
    install) install_packages ;;
    *)       while true; do show_menu; done ;;
esac
