#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# VNC WEB DESKTOP FOR TERMUX - FIXED VERSION
# Password: 123456 (Auto)
# ═══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

VNC_DISPLAY=":1"
VNC_PORT="5901"
NOVNC_PORT="6080"
VNC_RESOLUTION="1280x720"
PASSWORD="123456"
VNC_DIR="$HOME/.vnc"
NOVNC_DIR="$HOME/noVNC"

# ═══════════════════════════════════════════════════════════════
get_ip() {
    local ip=$(ip route get 1 2>/dev/null | awk '{for(i=1;i<=NF;i++)if($i=="src")print $(i+1)}' | head -1)
    [ -z "$ip" ] && ip="localhost"
    echo "$ip"
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
# CÀI ĐẶT - BẮT BUỘC CHẠY TRƯỚC
# ═══════════════════════════════════════════════════════════════
install_packages() {
    echo -e "${CYAN}[*] Cập nhật packages...${NC}"
    apt update -y && apt upgrade -y
    
    echo -e "${CYAN}[*] Cài đặt x11-repo...${NC}"
    apt install -y x11-repo
    
    echo -e "${CYAN}[*] Cài đặt VNC và Desktop...${NC}"
    apt install -y tigervnc xfce4 xfce4-goodies xfce4-terminal
    
    echo -e "${CYAN}[*] Cài đặt công cụ...${NC}"
    apt install -y python git wget curl dbus at-spi2-core
    
    echo -e "${CYAN}[*] Cài đặt websockify...${NC}"
    pip install websockify 2>/dev/null || apt install -y python-pip && pip install websockify
    
    echo -e "${CYAN}[*] Clone noVNC...${NC}"
    rm -rf "$NOVNC_DIR"
    git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR"
    [ -f "$NOVNC_DIR/vnc.html" ] && cp "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/index.html"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        ✅ CÀI ĐẶT HOÀN TẤT!                  ║${NC}"
    echo -e "${GREEN}║   Bây giờ chọn '1' để khởi động VNC          ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
}

# ═══════════════════════════════════════════════════════════════
# KIỂM TRA CÀI ĐẶT
# ═══════════════════════════════════════════════════════════════
check_installed() {
    if ! command -v vncserver &> /dev/null; then
        echo -e "${RED}[!] Chưa cài đặt VNC!${NC}"
        echo -e "${YELLOW}[*] Chọn '5' để cài đặt trước.${NC}"
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════
# THIẾT LẬP MẬT KHẨU 123456
# ═══════════════════════════════════════════════════════════════
setup_password() {
    mkdir -p "$VNC_DIR"
    
    # Tạo mật khẩu 123456
    printf "$PASSWORD\n$PASSWORD\nn\n" | vncpasswd 2>/dev/null
    
    # Nếu không được thì dùng cách khác
    if [ ! -f "$VNC_DIR/passwd" ]; then
        echo "$PASSWORD" | vncpasswd -f > "$VNC_DIR/passwd" 2>/dev/null
    fi
    
    chmod 600 "$VNC_DIR/passwd" 2>/dev/null
    
    # Tạo xstartup cho XFCE4
    cat > "$VNC_DIR/xstartup" << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
dbus-launch --exit-with-session xfce4-session &
EOF
    chmod +x "$VNC_DIR/xstartup"
    
    echo -e "${GREEN}[✓] Mật khẩu: ${WHITE}123456${NC}"
}

# ═══════════════════════════════════════════════════════════════
# KHỞI ĐỘNG VNC SERVER
# ═══════════════════════════════════════════════════════════════
start_vnc() {
    check_installed || return 1
    
    echo -e "${CYAN}[*] Khởi động VNC Server...${NC}"
    
    # Dừng VNC cũ
    vncserver -kill "$VNC_DISPLAY" 2>/dev/null
    pkill -9 Xvnc 2>/dev/null
    pkill -9 Xtightvnc 2>/dev/null
    rm -f /tmp/.X1-lock /tmp/.X11-unix/X1 2>/dev/null
    sleep 2
    
    # Khởi động VNC mới
    export USER=$(whoami)
    vncserver "$VNC_DISPLAY" \
        -geometry "$VNC_RESOLUTION" \
        -depth 24 \
        -localhost no \
        -name "VNC-Desktop" 2>&1
    
    sleep 3
    
    # Kiểm tra
    if pgrep -f "Xvnc.*$VNC_DISPLAY" > /dev/null || pgrep -f "Xtightvnc.*$VNC_DISPLAY" > /dev/null; then
        echo -e "${GREEN}[✓] VNC Server đang chạy - Port: $VNC_PORT${NC}"
        return 0
    else
        echo -e "${RED}[✗] Lỗi khởi động VNC!${NC}"
        echo -e "${YELLOW}[*] Thử: vncserver $VNC_DISPLAY${NC}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# KHỞI ĐỘNG NOVNC WEB
# ═══════════════════════════════════════════════════════════════
start_novnc() {
    echo -e "${CYAN}[*] Khởi động noVNC Web...${NC}"
    
    # Dừng cũ
    pkill -9 -f websockify 2>/dev/null
    sleep 1
    
    # Kiểm tra websockify
    if ! command -v websockify &> /dev/null; then
        echo -e "${YELLOW}[*] Cài websockify...${NC}"
        pip install websockify 2>/dev/null
    fi
    
    # Khởi động
    if [ -d "$NOVNC_DIR" ]; then
        nohup websockify --web="$NOVNC_DIR" "$NOVNC_PORT" "localhost:$VNC_PORT" > /dev/null 2>&1 &
    else
        nohup websockify "$NOVNC_PORT" "localhost:$VNC_PORT" > /dev/null 2>&1 &
    fi
    
    sleep 2
    
    if pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
        echo -e "${GREEN}[✓] noVNC Web đang chạy - Port: $NOVNC_PORT${NC}"
        return 0
    else
        echo -e "${RED}[✗] Lỗi khởi động noVNC!${NC}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# KHỞI ĐỘNG TẤT CẢ
# ═══════════════════════════════════════════════════════════════
start_all() {
    check_installed || return 1
    
    setup_password
    
    if start_vnc; then
        start_novnc
        show_info
    fi
}

# ═══════════════════════════════════════════════════════════════
# DỪNG TẤT CẢ
# ═══════════════════════════════════════════════════════════════
stop_all() {
    echo -e "${CYAN}[*] Đang dừng...${NC}"
    
    vncserver -kill "$VNC_DISPLAY" 2>/dev/null
    pkill -9 Xvnc 2>/dev/null
    pkill -9 Xtightvnc 2>/dev/null
    pkill -9 -f websockify 2>/dev/null
    pkill -9 -f xfce 2>/dev/null
    pkill -9 -f dbus 2>/dev/null
    
    rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null
    
    echo -e "${GREEN}[✓] Đã dừng tất cả!${NC}"
}

# ═══════════════════════════════════════════════════════════════
# HIỂN THỊ THÔNG TIN
# ═══════════════════════════════════════════════════════════════
show_info() {
    local ip=$(get_ip)
    local vnc_running=0
    local web_running=0
    
    pgrep -f "Xvnc.*$VNC_DISPLAY" > /dev/null && vnc_running=1
    pgrep -f "Xtightvnc.*$VNC_DISPLAY" > /dev/null && vnc_running=1
    pgrep -f "websockify.*$NOVNC_PORT" > /dev/null && web_running=1
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        🖥️  VNC WEB DESKTOP                           ║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    
    if [ "$vnc_running" = "1" ]; then
        echo -e "${GREEN}║${NC}  ✅ VNC Server:  ${WHITE}Đang chạy${NC} (Port: $VNC_PORT)         ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ VNC Server:  ${RED}Không chạy${NC}                       ${GREEN}║${NC}"
    fi
    
    if [ "$web_running" = "1" ]; then
        echo -e "${GREEN}║${NC}  ✅ noVNC Web:   ${WHITE}Đang chạy${NC} (Port: $NOVNC_PORT)         ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ noVNC Web:   ${RED}Không chạy${NC}                       ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  🔑 Mật khẩu:    ${YELLOW}123456${NC}                             ${GREEN}║${NC}"
    echo -e "${GREEN}╠═══════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  🌐 http://${ip}:${NOVNC_PORT}/vnc.html"
    echo -e "${GREEN}║${NC}  🌐 http://localhost:${NOVNC_PORT}/vnc.html"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$vnc_running" = "0" ]; then
        echo -e "${RED}⚠️  VNC chưa chạy! Web sẽ không kết nối được.${NC}"
        echo -e "${YELLOW}   Chọn '5' để cài đặt, sau đó '1' để khởi động.${NC}"
    fi
}

show_status() {
    local vnc_st="${RED}OFF${NC}"
    local web_st="${RED}OFF${NC}"
    
    (pgrep -f "Xvnc.*$VNC_DISPLAY" > /dev/null || pgrep -f "Xtightvnc.*$VNC_DISPLAY" > /dev/null) && vnc_st="${GREEN}ON${NC}"
    pgrep -f "websockify.*$NOVNC_PORT" > /dev/null && web_st="${GREEN}ON${NC}"
    
    echo -e "VNC: $vnc_st | Web: $web_st | Pass: ${YELLOW}123456${NC}"
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
    echo -e "  ${WHITE}5)${NC} 📦 Cài đặt (CHẠY TRƯỚC)"
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
        *) echo -e "${RED}Không hợp lệ!${NC}" ;;
    esac
    
    echo ""
    read -p "  Nhấn Enter..."
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════
case "$1" in
    start)   start_all ;;
    stop)    stop_all ;;
    restart) stop_all; sleep 2; start_all ;;
    status)  show_info ;;
    install) install_packages ;;
    *)       while true; do show_menu; done ;;
esac
