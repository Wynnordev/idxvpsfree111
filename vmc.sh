#!/bin/bash

###############################################################################
#                                                                             #
#   ██╗   ██╗███╗   ██╗ ██████╗    ███╗   ███╗ ██████╗ ██████╗               #
#   ██║   ██║████╗  ██║██╔════╝    ████╗ ████║██╔════╝ ██╔══██╗              #
#   ██║   ██║██╔██╗ ██║██║         ██╔████╔██║██║  ███╗██████╔╝              #
#   ╚██╗ ██╔╝██║╚██╗██║██║         ██║╚██╔╝██║██║   ██║██╔══██╗              #
#    ╚████╔╝ ██║ ╚████║╚██████╗    ██║ ╚═╝ ██║╚██████╔╝██║  ██║              #
#     ╚═══╝  ╚═╝  ╚═══╝ ╚═════╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝              #
#                                                                             #
#   VNC WEB DESKTOP MANAGER FOR ANDROID (TERMUX)                              #
#   Version: 3.0.0                                                            #
#   Author: VNC Manager Team                                                  #
#   License: MIT                                                              #
#   Lines: 1200+                                                              #
#                                                                             #
#   Tính năng:                                                                #
#   - Cài đặt tự động XFCE4 + VNC + noVNC                                    #
#   - Quản lý mật khẩu VNC                                                   #
#   - Tên miền tùy chỉnh (vĩnh viễn)                                         #
#   - Web Desktop qua trình duyệt                                            #
#   - Quản lý phiên VNC                                                       #
#   - Tự động khởi động                                                       #
#   - Backup & Restore cấu hình                                              #
#   - System Monitor                                                          #
#                                                                             #
###############################################################################

# ============================================================================
# SECTION 1: BIẾN TOÀN CỤC VÀ CẤU HÌNH
# ============================================================================

VERSION="3.0.0"
SCRIPT_NAME="VNC Web Desktop Manager"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.vnc-manager"
CONFIG_FILE="$CONFIG_DIR/config.conf"
LOG_DIR="$CONFIG_DIR/logs"
LOG_FILE="$LOG_DIR/vnc-manager.log"
BACKUP_DIR="$CONFIG_DIR/backups"
DOMAIN_FILE="$CONFIG_DIR/domain.conf"
PASSWORD_FILE="$CONFIG_DIR/.vnc_password"
SESSION_FILE="$CONFIG_DIR/sessions.conf"
AUTOSTART_FILE="$CONFIG_DIR/autostart.conf"
THEME_FILE="$CONFIG_DIR/theme.conf"
NOVNC_DIR="$HOME/noVNC"
VNC_DIR="$HOME/.vnc"
XSTARTUP_FILE="$VNC_DIR/xstartup"

# Cổng mặc định
DEFAULT_VNC_PORT=5901
DEFAULT_NOVNC_PORT=6080
DEFAULT_WEBSOCKIFY_PORT=6080
DEFAULT_DISPLAY=":1"
DEFAULT_RESOLUTION="1280x720"
DEFAULT_COLOR_DEPTH=24

# Màu sắc terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
NC='\033[0m' # No Color

# Biến trạng thái
VNC_RUNNING=false
NOVNC_RUNNING=false
TUNNEL_RUNNING=false
CURRENT_DISPLAY=""
CURRENT_PORT=""
CURRENT_RESOLUTION=""
CUSTOM_DOMAIN=""
TUNNEL_URL=""

# ============================================================================
# SECTION 2: HÀM TIỆN ÍCH CƠ BẢN
# ============================================================================

# Hàm ghi log
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Hàm hiển thị thông báo
print_info() {
    echo -e "${BLUE}[ℹ INFO]${NC} $1"
    log_message "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[✓ OK]${NC} $1"
    log_message "SUCCESS" "$1"
}

print_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
    log_message "WARNING" "$1"
}

print_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
    log_message "ERROR" "$1"
}

print_step() {
    echo -e "${PURPLE}[→ STEP]${NC} $1"
    log_message "STEP" "$1"
}

# Hàm vẽ đường kẻ
draw_line() {
    local char="${1:--}"
    local length="${2:-60}"
    printf '%*s\n' "$length" '' | tr ' ' "$char"
}

draw_double_line() {
    local length="${1:-60}"
    printf '%*s\n' "$length" '' | tr ' ' '='
}

draw_dotted_line() {
    local length="${1:-60}"
    printf '%*s\n' "$length" '' | tr ' ' '.'
}

# Hàm hiển thị tiêu đề
print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    echo ""
    echo -e "${CYAN}"
    draw_double_line $width
    printf "%-${padding}s %s %${padding}s\n" "" "$title" ""
    draw_double_line $width
    echo -e "${NC}"
}

# Hàm hiển thị banner
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   ██╗   ██╗███╗   ██╗ ██████╗                               ║"
    echo "║   ██║   ██║████╗  ██║██╔════╝                               ║"
    echo "║   ██║   ██║██╔██╗ ██║██║                                    ║"
    echo "║   ╚██╗ ██╔╝██║╚██╗██║██║                                    ║"
    echo "║    ╚████╔╝ ██║ ╚████║╚██████╗                               ║"
    echo "║     ╚═══╝  ╚═╝  ╚═══╝ ╚═════╝                               ║"
    echo "║                                                              ║"
    echo "║   ${WHITE}VNC Web Desktop Manager v${VERSION}${CYAN}                          ║"
    echo "║   ${DIM}Designed for Android (Termux)${CYAN}                            ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Hàm loading animation
show_loading() {
    local message="$1"
    local duration="${2:-3}"
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local end_time=$((SECONDS + duration))
    
    while [ $SECONDS -lt $end_time ]; do
        for (( i=0; i<${#chars}; i++ )); do
            echo -ne "\r${CYAN}${chars:$i:1}${NC} ${message}"
            sleep 0.1
        done
    done
    echo -ne "\r${GREEN}✓${NC} ${message}\n"
}

# Hàm progress bar
show_progress() {
    local current="$1"
    local total="$2"
    local message="${3:-Processing}"
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}[${NC}"
    printf '%*s' "$filled" '' | tr ' ' '█'
    printf '%*s' "$empty" '' | tr ' ' '░'
    printf "${CYAN}]${NC} ${percentage}%% - ${message}"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Hàm xác nhận
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        echo -ne "${YELLOW}$message [Y/n]: ${NC}"
    else
        echo -ne "${YELLOW}$message [y/N]: ${NC}"
    fi
    
    read -r response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# Hàm nhập mật khẩu ẩn
read_password() {
    local prompt="$1"
    local password=""
    
    echo -ne "${CYAN}$prompt${NC}"
    
    while IFS= read -r -s -n 1 char; do
        if [[ $char == $'\0' ]] || [[ $char == $'\n' ]]; then
            break
        elif [[ $char == $'\177' ]] || [[ $char == $'\b' ]]; then
            if [ ${#password} -gt 0 ]; then
                password="${password%?}"
                echo -ne "\b \b"
            fi
        else
            password+="$char"
            echo -ne "●"
        fi
    done
    echo ""
    
    echo "$password"
}

# Hàm kiểm tra lệnh tồn tại
check_command() {
    command -v "$1" &> /dev/null
}

# Hàm lấy IP
get_local_ip() {
    if check_command ip; then
        ip route get 1 2>/dev/null | awk '{print $NF; exit}' 2>/dev/null || echo "localhost"
    elif check_command ifconfig; then
        ifconfig 2>/dev/null | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1 || echo "localhost"
    else
        echo "localhost"
    fi
}

# Hàm kiểm tra port đang sử dụng
check_port() {
    local port="$1"
    if check_command ss; then
        ss -tuln 2>/dev/null | grep -q ":$port " && return 0 || return 1
    elif check_command netstat; then
        netstat -tuln 2>/dev/null | grep -q ":$port " && return 0 || return 1
    else
        return 1
    fi
}

# Hàm tìm port trống
find_free_port() {
    local start_port="${1:-5901}"
    local port=$start_port
    
    while check_port "$port"; do
        port=$((port + 1))
        if [ "$port" -gt 65535 ]; then
            echo ""
            return 1
        fi
    done
    
    echo "$port"
}

# ============================================================================
# SECTION 3: KHỞI TẠO VÀ CẤU HÌNH
# ============================================================================

# Tạo thư mục cấu hình
init_directories() {
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$VNC_DIR"
    
    touch "$LOG_FILE"
    touch "$SESSION_FILE"
    
    log_message "INFO" "Directories initialized"
}

# Tạo file cấu hình mặc định
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'CONFIGEOF'
# VNC Manager Configuration
# Auto-generated - Do not edit manually unless you know what you're doing

# VNC Settings
VNC_DISPLAY=:1
VNC_PORT=5901
VNC_RESOLUTION=1280x720
VNC_COLOR_DEPTH=24
VNC_GEOMETRY=1280x720

# noVNC Settings
NOVNC_PORT=6080
NOVNC_AUTOCONNECT=true
NOVNC_RESIZE=remote

# Desktop Settings
DESKTOP_ENV=xfce4
DESKTOP_WALLPAPER=
DESKTOP_THEME=Adwaita-dark

# Network Settings
ENABLE_TUNNEL=false
TUNNEL_SERVICE=localhost.run
CUSTOM_DOMAIN=

# Security Settings
REQUIRE_PASSWORD=true
MAX_LOGIN_ATTEMPTS=3
SESSION_TIMEOUT=0

# Performance Settings
FRAME_RATE=30
COMPRESSION_LEVEL=6
QUALITY_LEVEL=8

# Auto-start Settings
AUTOSTART_VNC=false
AUTOSTART_NOVNC=false
AUTOSTART_TUNNEL=false

# Logging
LOG_LEVEL=INFO
MAX_LOG_SIZE=10M
CONFIGEOF
        
        log_message "INFO" "Default configuration created"
    fi
    
    source "$CONFIG_FILE"
}

# Tải cấu hình
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
    
    if [ -f "$DOMAIN_FILE" ]; then
        CUSTOM_DOMAIN=$(cat "$DOMAIN_FILE" 2>/dev/null)
    fi
    
    # Kiểm tra trạng thái
    check_vnc_status
    check_novnc_status
}

# Lưu cấu hình
save_config() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
    
    log_message "INFO" "Config saved: $key=$value"
}

# Kiểm tra trạng thái VNC
check_vnc_status() {
    if pgrep -x "Xvnc" > /dev/null 2>&1 || pgrep -x "Xtightvnc" > /dev/null 2>&1; then
        VNC_RUNNING=true
    else
        VNC_RUNNING=false
    fi
}

# Kiểm tra trạng thái noVNC
check_novnc_status() {
    if pgrep -f "websockify" > /dev/null 2>&1 || pgrep -f "novnc" > /dev/null 2>&1; then
        NOVNC_RUNNING=true
    else
        NOVNC_RUNNING=false
    fi
}

# ============================================================================
# SECTION 4: CÀI ĐẶT PACKAGES
# ============================================================================

# Kiểm tra môi trường
check_environment() {
    print_header "KIỂM TRA MÔI TRƯỜNG"
    
    # Kiểm tra Termux
    if [ -d "/data/data/com.termux" ] || [ -n "$TERMUX_VERSION" ]; then
        print_success "Đang chạy trên Termux"
    else
        print_warning "Không phát hiện Termux - Script có thể không hoạt động đúng"
    fi
    
    # Kiểm tra quyền
    if [ "$(id -u)" = "0" ]; then
        print_warning "Đang chạy với quyền root"
    else
        print_info "Đang chạy với user: $(whoami)"
    fi
    
    # Kiểm tra bộ nhớ
    local total_mem=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "Unknown")
    local free_mem=$(free -m 2>/dev/null | awk '/^Mem:/{print $4}' || echo "Unknown")
    print_info "RAM: ${free_mem}MB free / ${total_mem}MB total"
    
    # Kiểm tra dung lượng ổ đĩa
    local disk_free=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}' || echo "Unknown")
    print_info "Dung lượng trống: $disk_free"
    
    echo ""
}

# Cập nhật package manager
update_packages() {
    print_step "Cập nhật package manager..."
    
    if check_command pkg; then
        pkg update -y 2>&1 | while read line; do
            echo -ne "\r${DIM}  $line${NC}                    "
        done
        echo ""
        pkg upgrade -y 2>&1 | while read line; do
            echo -ne "\r${DIM}  $line${NC}                    "
        done
        echo ""
        print_success "Package manager đã cập nhật"
    elif check_command apt; then
        apt update -y 2>&1 | tail -1
        apt upgrade -y 2>&1 | tail -1
        print_success "APT đã cập nhật"
    else
        print_error "Không tìm thấy package manager phù hợp"
        return 1
    fi
}

# Cài đặt package đơn lẻ
install_package() {
    local package="$1"
    local display_name="${2:-$1}"
    
    if dpkg -l "$package" &> /dev/null 2>&1; then
        print_info "$display_name đã được cài đặt"
        return 0
    fi
    
    print_step "Đang cài đặt $display_name..."
    
    if check_command pkg; then
        pkg install -y "$package" 2>&1 | tail -3
    elif check_command apt; then
        apt install -y "$package" 2>&1 | tail -3
    fi
    
    if [ $? -eq 0 ]; then
        print_success "$display_name đã cài đặt thành công"
        return 0
    else
        print_error "Không thể cài đặt $display_name"
        return 1
    fi
}

# Cài đặt tất cả packages cần thiết
install_all_packages() {
    print_header "CÀI ĐẶT PACKAGES"
    
    local packages=(
        "x11-repo"
        "xfce4"
        "xfce4-goodies"
        "tigervnc"
        "novnc"
        "websockify"
        "python"
        "python-pip"
        "git"
        "wget"
        "curl"
        "openssh"
        "openssl"
        "net-tools"
        "procps"
        "nano"
        "vim"
        "htop"
        "neofetch"
        "firefox"
        "netcat-openbsd"
        "dbus"
        "at-spi2-core"
    )
    
    local display_names=(
        "X11 Repository"
        "XFCE4 Desktop"
        "XFCE4 Goodies"
        "TigerVNC Server"
        "noVNC Web Client"
        "Websockify"
        "Python"
        "Python PIP"
        "Git"
        "Wget"
        "cURL"
        "OpenSSH"
        "OpenSSL"
        "Net Tools"
        "Process Utils"
        "Nano Editor"
        "Vim Editor"
        "HTop Monitor"
        "Neofetch"
        "Firefox Browser"
        "Netcat"
        "D-Bus"
        "AT-SPI2"
    )
    
    local total=${#packages[@]}
    local current=0
    local failed=0
    
    echo -e "${CYAN}Tổng số packages cần cài: $total${NC}"
    echo ""
    
    # Cập nhật trước
    update_packages
    echo ""
    
    for i in "${!packages[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Cài đặt ${display_names[$i]}"
        
        if ! install_package "${packages[$i]}" "${display_names[$i]}" > /dev/null 2>&1; then
            failed=$((failed + 1))
            log_message "ERROR" "Failed to install ${packages[$i]}"
        fi
    done
    
    echo ""
    if [ $failed -eq 0 ]; then
        print_success "Tất cả $total packages đã cài đặt thành công!"
    else
        print_warning "$((total - failed))/$total packages đã cài. $failed packages thất bại."
    fi
    
    # Cài đặt noVNC từ GitHub nếu cần
    install_novnc_github
}

# Cài đặt noVNC từ GitHub
install_novnc_github() {
    if [ ! -d "$NOVNC_DIR" ]; then
        print_step "Cài đặt noVNC từ GitHub..."
        
        git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR" 2>&1 | tail -2
        
        if [ -d "$NOVNC_DIR" ]; then
            # Tạo symlink cho vnc.html
            if [ -f "$NOVNC_DIR/vnc.html" ]; then
                cp "$NOVNC_DIR/vnc.html" "$NOVNC_DIR/index.html" 2>/dev/null
            fi
            print_success "noVNC đã cài đặt từ GitHub"
        else
            print_error "Không thể clone noVNC"
        fi
    else
        print_info "noVNC đã tồn tại tại $NOVNC_DIR"
    fi
    
    # Cài websockify nếu chưa có
    if [ ! -d "$NOVNC_DIR/utils/websockify" ]; then
        git clone --depth 1 https://github.com/novnc/websockify.git "$NOVNC_DIR/utils/websockify" 2>/dev/null
    fi
}

# ============================================================================
# SECTION 5: QUẢN LÝ MẬT KHẨU
# ============================================================================

# Thiết lập mật khẩu VNC
setup_vnc_password() {
    print_header "THIẾT LẬP MẬT KHẨU VNC"
    
    echo -e "${WHITE}Mật khẩu VNC dùng để bảo vệ desktop của bạn.${NC}"
    echo -e "${DIM}Mật khẩu phải từ 6-8 ký tự.${NC}"
    echo ""
    
    local password=""
    local confirm_password=""
    local valid=false
    
    while [ "$valid" = false ]; do
        password=$(read_password "🔑 Nhập mật khẩu VNC: ")
        
        # Kiểm tra độ dài
        if [ ${#password} -lt 6 ]; then
            print_error "Mật khẩu phải có ít nhất 6 ký tự!"
            continue
        fi
        
        if [ ${#password} -gt 8 ]; then
            print_warning "VNC chỉ hỗ trợ tối đa 8 ký tự. Mật khẩu sẽ bị cắt."
            password="${password:0:8}"
        fi
        
        confirm_password=$(read_password "🔑 Xác nhận mật khẩu: ")
        
        if [ "$password" != "$confirm_password" ]; then
            print_error "Mật khẩu không khớp! Vui lòng thử lại."
            continue
        fi
        
        valid=true
    done
    
    # Lưu mật khẩu
    mkdir -p "$VNC_DIR"
    
    # Tạo mật khẩu VNC
    echo "$password" | vncpasswd -f > "$VNC_DIR/passwd" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        # Fallback: sử dụng expect hoặc trực tiếp
        printf "$password\n$password\nn\n" | vncpasswd 2>/dev/null
    fi
    
    chmod 600 "$VNC_DIR/passwd"
    
    # Lưu hash để quản lý
    echo "$password" | openssl dgst -sha256 | awk '{print $2}' > "$PASSWORD_FILE" 2>/dev/null
    chmod 600 "$PASSWORD_FILE"
    
    echo ""
    print_success "Mật khẩu VNC đã được thiết lập!"
    
    # Hỏi view-only password
    echo ""
    if confirm_action "Bạn có muốn đặt mật khẩu view-only (chỉ xem)?"; then
        local view_password=$(read_password "🔑 Nhập mật khẩu view-only: ")
        echo "$view_password" | vncpasswd -f >> "$VNC_DIR/passwd" 2>/dev/null
        print_success "Mật khẩu view-only đã được thiết lập!"
    fi
    
    log_message "INFO" "VNC password configured"
}

# Đổi mật khẩu VNC
change_vnc_password() {
    print_header "ĐỔI MẬT KHẨU VNC"
    
    # Xác nhận mật khẩu cũ
    if [ -f "$PASSWORD_FILE" ]; then
        local old_hash=$(cat "$PASSWORD_FILE")
        local input_password=$(read_password "🔑 Nhập mật khẩu hiện tại: ")
        local input_hash=$(echo "$input_password" | openssl dgst -sha256 | awk '{print $2}')
        
        if [ "$old_hash" != "$input_hash" ]; then
            print_error "Mật khẩu hiện tại không đúng!"
            return 1
        fi
        
        print_success "Xác thực thành công!"
        echo ""
    fi
    
    # Đặt mật khẩu mới
    setup_vnc_password
    
    # Khởi động lại VNC nếu đang chạy
    if [ "$VNC_RUNNING" = true ]; then
        if confirm_action "Khởi động lại VNC để áp dụng mật khẩu mới?"; then
            restart_vnc
        fi
    fi
}

# Hiển thị thông tin mật khẩu
show_password_info() {
    print_header "THÔNG TIN MẬT KHẨU"
    
    if [ -f "$VNC_DIR/passwd" ]; then
        local mod_time=$(stat -c %y "$VNC_DIR/passwd" 2>/dev/null || stat -f %Sm "$VNC_DIR/passwd" 2>/dev/null)
        echo -e "  ${WHITE}Trạng thái:${NC}    ${GREEN}Đã thiết lập${NC}"
        echo -e "  ${WHITE}File:${NC}          $VNC_DIR/passwd"
        echo -e "  ${WHITE}Cập nhật:${NC}      $mod_time"
        echo -e "  ${WHITE}Quyền:${NC}         $(stat -c %a "$VNC_DIR/passwd" 2>/dev/null || echo "600")"
    else
        echo -e "  ${WHITE}Trạng thái:${NC}    ${RED}Chưa thiết lập${NC}"
        echo ""
        echo -e "  ${YELLOW}Vui lòng thiết lập mật khẩu trước khi sử dụng VNC.${NC}"
    fi
    echo ""
}

# ============================================================================
# SECTION 6: CẤU HÌNH VNC SERVER
# ============================================================================

# Tạo file xstartup
create_xstartup() {
    print_step "Tạo file xstartup..."
    
    mkdir -p "$VNC_DIR"
    
    cat > "$XSTARTUP_FILE" << 'XSTARTUPEOF'
#!/bin/bash

# VNC Desktop Startup Script
# Auto-generated by VNC Manager

# Unset session manager
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Set environment
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export DESKTOP_SESSION=xfce

# Start D-Bus
if command -v dbus-launch &> /dev/null; then
    eval $(dbus-launch --sh-syntax)
    export DBUS_SESSION_BUS_ADDRESS
fi

# Set cursor
xsetroot -cursor_name left_ptr &

# Set wallpaper color
xsetroot -solid "#2E3440" &

# Start XFCE4 Desktop
if command -v startxfce4 &> /dev/null; then
    exec startxfce4 &
elif command -v xfce4-session &> /dev/null; then
    exec xfce4-session &
else
    # Fallback: start basic window manager
    if command -v xfwm4 &> /dev/null; then
        xfwm4 &
    fi
    if command -v xfce4-panel &> /dev/null; then
        xfce4-panel &
    fi
    if command -v xfdesktop &> /dev/null; then
        xfdesktop &
    fi
    if command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal &
    elif command -v xterm &> /dev/null; then
        xterm &
    fi
fi
XSTARTUPEOF
    
    chmod +x "$XSTARTUP_FILE"
    print_success "File xstartup đã được tạo"
}

# Cấu hình VNC
configure_vnc() {
    print_header "CẤU HÌNH VNC SERVER"
    
    echo -e "${WHITE}Cấu hình màn hình VNC:${NC}"
    echo ""
    
    # Chọn độ phân giải
    echo -e "  ${CYAN}Chọn độ phân giải:${NC}"
    echo -e "    ${WHITE}1)${NC} 800x600    (Thấp - Tiết kiệm tài nguyên)"
    echo -e "    ${WHITE}2)${NC} 1024x768   (Trung bình)"
    echo -e "    ${WHITE}3)${NC} 1280x720   (HD - Khuyến nghị)"
    echo -e "    ${WHITE}4)${NC} 1280x1024  (Cao)"
    echo -e "    ${WHITE}5)${NC} 1920x1080  (Full HD)"
    echo -e "    ${WHITE}6)${NC} Tùy chỉnh"
    echo ""
    
    read -p "  Lựa chọn [3]: " res_choice
    res_choice=${res_choice:-3}
    
    case "$res_choice" in
        1) VNC_RESOLUTION="800x600" ;;
        2) VNC_RESOLUTION="1024x768" ;;
        3) VNC_RESOLUTION="1280x720" ;;
        4) VNC_RESOLUTION="1280x1024" ;;
        5) VNC_RESOLUTION="1920x1080" ;;
        6)
            read -p "  Nhập độ phân giải (VD: 1366x768): " custom_res
            if [[ "$custom_res" =~ ^[0-9]+x[0-9]+$ ]]; then
                VNC_RESOLUTION="$custom_res"
            else
                print_warning "Độ phân giải không hợp lệ, sử dụng mặc định 1280x720"
                VNC_RESOLUTION="1280x720"
            fi
            ;;
        *) VNC_RESOLUTION="1280x720" ;;
    esac
    
    echo ""
    
    # Chọn display
    echo -e "  ${CYAN}Chọn display number:${NC}"
    read -p "  Display [:1]: " display_num
    display_num=${display_num:-:1}
    
    if [[ ! "$display_num" =~ ^:[0-9]+$ ]]; then
        display_num=":1"
    fi
    
    VNC_DISPLAY="$display_num"
    VNC_PORT=$((5900 + ${display_num#:}))
    
    echo ""
    
    # Chọn color depth
    echo -e "  ${CYAN}Chọn độ sâu màu:${NC}"
    echo -e "    ${WHITE}1)${NC} 16-bit (Nhanh hơn)"
    echo -e "    ${WHITE}2)${NC} 24-bit (Tốt hơn - Khuyến nghị)"
    echo -e "    ${WHITE}3)${NC} 32-bit (Tốt nhất)"
    echo ""
    
    read -p "  Lựa chọn [2]: " depth_choice
    depth_choice=${depth_choice:-2}
    
    case "$depth_choice" in
        1) VNC_COLOR_DEPTH=16 ;;
        2) VNC_COLOR_DEPTH=24 ;;
        3) VNC_COLOR_DEPTH=32 ;;
        *) VNC_COLOR_DEPTH=24 ;;
    esac
    
    # Lưu cấu hình
    save_config "VNC_DISPLAY" "$VNC_DISPLAY"
    save_config "VNC_PORT" "$VNC_PORT"
    save_config "VNC_RESOLUTION" "$VNC_RESOLUTION"
    save_config "VNC_COLOR_DEPTH" "$VNC_COLOR_DEPTH"
    save_config "VNC_GEOMETRY" "$VNC_RESOLUTION"
    
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     CẤU HÌNH ĐÃ LƯU                ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}  Display:     ${WHITE}$VNC_DISPLAY${NC}               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Port:        ${WHITE}$VNC_PORT${NC}             ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Resolution:  ${WHITE}$VNC_RESOLUTION${NC}        ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Color Depth: ${WHITE}${VNC_COLOR_DEPTH}-bit${NC}            ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
    echo ""
    
    # Tạo xstartup
    create_xstartup
    
    print_success "VNC Server đã được cấu hình!"
}

# ============================================================================
# SECTION 7: KHỞI ĐỘNG VÀ QUẢN LÝ VNC
# ============================================================================

# Khởi động VNC Server
start_vnc() {
    print_header "KHỞI ĐỘNG VNC SERVER"
    
    # Kiểm tra mật khẩu
    if [ ! -f "$VNC_DIR/passwd" ]; then
        print_warning "Chưa thiết lập mật khẩu VNC!"
        setup_vnc_password
    fi
    
    # Kiểm tra xstartup
    if [ ! -f "$XSTARTUP_FILE" ]; then
        create_xstartup
    fi
    
    # Dừng VNC cũ nếu đang chạy
    if [ "$VNC_RUNNING" = true ]; then
        print_warning "VNC đang chạy, đang dừng..."
        stop_vnc_silent
    fi
    
    # Load cấu hình
    load_config
    
    local display="${VNC_DISPLAY:-:1}"
    local resolution="${VNC_RESOLUTION:-1280x720}"
    local depth="${VNC_COLOR_DEPTH:-24}"
    
    print_step "Khởi động VNC trên display $display..."
    
    # Kill display cũ nếu có
    vncserver -kill "$display" 2>/dev/null
    sleep 1
    
    # Khởi động VNC server
    export DISPLAY="$display"
    
    vncserver "$display" \
        -geometry "$resolution" \
        -depth "$depth" \
        -localhost no \
        -name "VNC Desktop" \
        2>&1 | tee -a "$LOG_FILE"
    
    sleep 2
    
    # Kiểm tra
    check_vnc_status
    
    if [ "$VNC_RUNNING" = true ]; then
        local port=$((5900 + ${display#:}))
        
        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║         VNC SERVER ĐÃ KHỞI ĐỘNG!            ║${NC}"
        echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  Display:     ${WHITE}$display${NC}                         ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  Port:        ${WHITE}$port${NC}                        ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  Resolution:  ${WHITE}$resolution${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  Address:     ${WHITE}localhost:$port${NC}              ${GREEN}║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Lưu session
        echo "display=$display port=$port resolution=$resolution started=$(date)" >> "$SESSION_FILE"
        
        print_success "VNC Server đã sẵn sàng!"
    else
        print_error "Không thể khởi động VNC Server!"
        echo ""
        echo -e "${YELLOW}Thử các bước sau:${NC}"
        echo -e "  1. Kiểm tra log: ${WHITE}cat $LOG_FILE${NC}"
        echo -e "  2. Kill tất cả: ${WHITE}vncserver -kill $display${NC}"
        echo -e "  3. Cài lại: ${WHITE}pkg install tigervnc${NC}"
    fi
}

# Dừng VNC Server
stop_vnc() {
    print_header "DỪNG VNC SERVER"
    
    local display="${VNC_DISPLAY:-:1}"
    
    print_step "Đang dừng VNC Server..."
    
    vncserver -kill "$display" 2>/dev/null
    
    # Kill tất cả process liên quan
    pkill -f "Xvnc" 2>/dev/null
    pkill -f "Xtightvnc" 2>/dev/null
    pkill -f "xfce4-session" 2>/dev/null
    pkill -f "xfwm4" 2>/dev/null
    pkill -f "xfce4-panel" 2>/dev/null
    pkill -f "xfdesktop" 2>/dev/null
    
    sleep 1
    
    # Xóa lock files
    rm -f /tmp/.X*-lock 2>/dev/null
    rm -f /tmp/.X11-unix/X* 2>/dev/null
    
    check_vnc_status
    
    if [ "$VNC_RUNNING" = false ]; then
        print_success "VNC Server đã dừng!"
    else
        print_warning "Một số process có thể vẫn đang chạy"
        pkill -9 -f "Xvnc" 2>/dev/null
    fi
}

# Dừng VNC không hiển thị
stop_vnc_silent() {
    local display="${VNC_DISPLAY:-:1}"
    vncserver -kill "$display" 2>/dev/null
    pkill -f "Xvnc" 2>/dev/null
    pkill -f "Xtightvnc" 2>/dev/null
    rm -f /tmp/.X*-lock 2>/dev/null
    rm -f /tmp/.X11-unix/X* 2>/dev/null
    sleep 1
}

# Khởi động lại VNC
restart_vnc() {
    print_header "KHỞI ĐỘNG LẠI VNC SERVER"
    
    print_step "Dừng VNC Server..."
    stop_vnc_silent
    
    sleep 2
    
    print_step "Khởi động lại VNC Server..."
    start_vnc
}

# ============================================================================
# SECTION 8: NOVNC WEB CLIENT
# ============================================================================

# Khởi động noVNC
start_novnc() {
    print_header "KHỞI ĐỘNG NOVNC WEB CLIENT"
    
    # Kiểm tra VNC đang chạy
    check_vnc_status
    if [ "$VNC_RUNNING" = false ]; then
        print_warning "VNC Server chưa chạy. Khởi động VNC trước..."
        start_vnc
    fi
    
    # Dừng noVNC cũ
    stop_novnc_silent
    
    local vnc_port="${VNC_PORT:-5901}"
    local novnc_port="${NOVNC_PORT:-6080}"
    
    print_step "Khởi động noVNC trên port $novnc_port..."
    
    # Phương pháp 1: Sử dụng websockify trực tiếp
    if check_command websockify; then
        if [ -d "$NOVNC_DIR" ]; then
            websockify --web="$NOVNC_DIR" "$novnc_port" "localhost:$vnc_port" &
        else
            websockify "$novnc_port" "localhost:$vnc_port" &
        fi
        
        local ws_pid=$!
        echo "$ws_pid" > "$CONFIG_DIR/websockify.pid"
        
        sleep 2
        
        if kill -0 "$ws_pid" 2>/dev/null; then
            NOVNC_RUNNING=true
            local ip=$(get_local_ip)
            local url="http://$ip:$novnc_port/vnc.html"
            local auto_url="http://$ip:$novnc_port/vnc.html?autoconnect=true&resize=remote"
            
            echo ""
            echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║            NOVNC WEB CLIENT ĐÃ KHỞI ĐỘNG!              ║${NC}"
            echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${WHITE}🌐 Link truy cập:${NC}                                      ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${CYAN}$url${NC}          ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${WHITE}🔗 Auto-connect:${NC}                                        ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${CYAN}$auto_url${NC}  ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${WHITE}📱 Port:${NC} $novnc_port                                         ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  ${WHITE}🔑 PID:${NC}  $ws_pid                                          ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            
            # Hiển thị link tên miền nếu có
            if [ -n "$CUSTOM_DOMAIN" ]; then
                echo -e "${PURPLE}🏷️  Tên miền tùy chỉnh: ${WHITE}http://$CUSTOM_DOMAIN${NC}"
                echo ""
            fi
            
            print_success "Mở link trên trình duyệt để sử dụng Desktop!"
            print_info "Nhấp vào link hoặc copy paste vào trình duyệt"
        else
            print_error "Không thể khởi động noVNC!"
        fi
    else
        print_error "websockify chưa được cài đặt!"
        print_info "Chạy: pkg install websockify"
    fi
}

# Dừng noVNC
stop_novnc() {
    print_header "DỪNG NOVNC"
    
    print_step "Đang dừng noVNC..."
    
    stop_novnc_silent
    
    print_success "noVNC đã dừng!"
}

# Dừng noVNC không hiển thị
stop_novnc_silent() {
    pkill -f "websockify" 2>/dev/null
    pkill -f "novnc" 2>/dev/null
    
    if [ -f "$CONFIG_DIR/websockify.pid" ]; then
        local pid=$(cat "$CONFIG_DIR/websockify.pid")
        kill "$pid" 2>/dev/null
        kill -9 "$pid" 2>/dev/null
        rm -f "$CONFIG_DIR/websockify.pid"
    fi
    
    NOVNC_RUNNING=false
}

# ============================================================================
# SECTION 9: TÊN MIỀN TÙY CHỈNH VÀ TUNNEL
# ============================================================================

# Cấu hình tên miền
setup_domain() {
    print_header "CẤU HÌNH TÊN MIỀN"
    
    echo -e "${WHITE}Chọn phương thức truy cập từ xa:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} localhost.run     (Miễn phí, tên miền ngẫu nhiên)"
    echo -e "  ${CYAN}2)${NC} serveo.net        (Miễn phí, tên miền tùy chỉnh)"
    echo -e "  ${CYAN}3)${NC} ngrok             (Miễn phí/Trả phí, ổn định)"
    echo -e "  ${CYAN}4)${NC} Cloudflare Tunnel (Tên miền riêng, vĩnh viễn)"
    echo -e "  ${CYAN}5)${NC} Tên miền tùy chỉnh (Nhập tên miền của bạn)"
    echo -e "  ${CYAN}6)${NC} Chỉ dùng Local (Mạng nội bộ)"
    echo -e "  ${CYAN}0)${NC} Quay lại"
    echo ""
    
    read -p "  Lựa chọn: " domain_choice
    
    case "$domain_choice" in
        1) setup_localhost_run ;;
        2) setup_serveo ;;
        3) setup_ngrok ;;
        4) setup_cloudflare ;;
        5) setup_custom_domain ;;
        6) 
            print_info "Sử dụng chế độ Local"
            save_config "ENABLE_TUNNEL" "false"
            ;;
        0) return ;;
        *) print_error "Lựa chọn không hợp lệ" ;;
    esac
}

# localhost.run tunnel
setup_localhost_run() {
    print_step "Thiết lập tunnel qua localhost.run..."
    
    local novnc_port="${NOVNC_PORT:-6080}"
    
    echo -e "${YELLOW}Đang tạo tunnel...${NC}"
    
    ssh -R 80:localhost:$novnc_port localhost.run 2>&1 &
    local tunnel_pid=$!
    echo "$tunnel_pid" > "$CONFIG_DIR/tunnel.pid"
    
    sleep 5
    
    if kill -0 "$tunnel_pid" 2>/dev/null; then
        TUNNEL_RUNNING=true
        save_config "ENABLE_TUNNEL" "true"
        save_config "TUNNEL_SERVICE" "localhost.run"
        
        print_success "Tunnel đã được tạo!"
        print_info "Kiểm tra terminal để lấy URL"
        print_warning "URL sẽ thay đổi mỗi lần kết nối mới"
    else
        print_error "Không thể tạo tunnel"
    fi
}

# Serveo tunnel
setup_serveo() {
    print_step "Thiết lập tunnel qua serveo.net..."
    
    local novnc_port="${NOVNC_PORT:-6080}"
    
    echo -ne "  ${CYAN}Nhập tên miền mong muốn (VD: mydesktop): ${NC}"
    read -r subdomain
    
    if [ -n "$subdomain" ]; then
        ssh -R "${subdomain}:80:localhost:$novnc_port" serveo.net 2>&1 &
        local tunnel_pid=$!
        echo "$tunnel_pid" > "$CONFIG_DIR/tunnel.pid"
        
        sleep 5
        
        if kill -0 "$tunnel_pid" 2>/dev/null; then
            TUNNEL_RUNNING=true
            CUSTOM_DOMAIN="${subdomain}.serveo.net"
            echo "$CUSTOM_DOMAIN" > "$DOMAIN_FILE"
            
            save_config "ENABLE_TUNNEL" "true"
            save_config "TUNNEL_SERVICE" "serveo.net"
            save_config "CUSTOM_DOMAIN" "$CUSTOM_DOMAIN"
            
            echo ""
            echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║        TUNNEL ĐÃ ĐƯỢC TẠO!                 ║${NC}"
            echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║${NC}  🌐 URL: ${WHITE}https://$CUSTOM_DOMAIN${NC}     ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}  📌 Tên miền này sẽ được giữ vĩnh viễn     ${GREEN}║${NC}"
            echo -e "${GREEN}║${NC}     khi bật script lên là chạy trên đó     ${GREEN}║${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
            echo ""
        else
            print_error "Không thể tạo tunnel"
        fi
    fi
}

# Ngrok tunnel
setup_ngrok() {
    print_step "Thiết lập tunnel qua ngrok..."
    
    if ! check_command ngrok; then
        print_warning "ngrok chưa được cài đặt"
        
        if confirm_action "Cài đặt ngrok?"; then
            # Cài ngrok
            if check_command pkg; then
                pkg install ngrok -y 2>/dev/null
            fi
            
            if ! check_command ngrok; then
                wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz -O /tmp/ngrok.tgz 2>/dev/null
                tar -xzf /tmp/ngrok.tgz -C "$PREFIX/bin/" 2>/dev/null
                rm -f /tmp/ngrok.tgz
            fi
        fi
    fi
    
    if check_command ngrok; then
        local novnc_port="${NOVNC_PORT:-6080}"
        
        echo -ne "  ${CYAN}Nhập ngrok auth token (nếu có): ${NC}"
        read -r auth_token
        
        if [ -n "$auth_token" ]; then
            ngrok config add-authtoken "$auth_token" 2>/dev/null
        fi
        
        ngrok http "$novnc_port" --log=stdout > "$LOG_DIR/ngrok.log" 2>&1 &
        local tunnel_pid=$!
        echo "$tunnel_pid" > "$CONFIG_DIR/tunnel.pid"
        
        sleep 5
        
        # Lấy URL từ ngrok API
        local ngrok_url=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -oP '"public_url":"https?://[^"]+' | head -1 | cut -d'"' -f4)
        
        if [ -n "$ngrok_url" ]; then
            TUNNEL_URL="$ngrok_url"
            CUSTOM_DOMAIN=$(echo "$ngrok_url" | sed 's|https\?://||')
            echo "$CUSTOM_DOMAIN" > "$DOMAIN_FILE"
            
            save_config "ENABLE_TUNNEL" "true"
            save_config "TUNNEL_SERVICE" "ngrok"
            
            echo ""
            echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║        NGROK TUNNEL ĐÃ ĐƯỢC TẠO!            ║${NC}"
            echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
            echo -e "${GREEN}║${NC}  🌐 URL: ${WHITE}$ngrok_url${NC}"
            echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
        else
            print_warning "Tunnel đã tạo nhưng chưa lấy được URL"
            print_info "Kiểm tra: http://localhost:4040"
        fi
    fi
}

# Cloudflare tunnel
setup_cloudflare() {
    print_step "Thiết lập Cloudflare Tunnel..."
    
    echo -e "${WHITE}Cloudflare Tunnel cho phép bạn sử dụng tên miền riêng vĩnh viễn.${NC}"
    echo ""
    
    if ! check_command cloudflared; then
        print_warning "cloudflared chưa được cài đặt"
        
        if confirm_action "Cài đặt cloudflared?"; then
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -O "$PREFIX/bin/cloudflared" 2>/dev/null
            chmod +x "$PREFIX/bin/cloudflared" 2>/dev/null
        fi
    fi
    
    if check_command cloudflared; then
        local novnc_port="${NOVNC_PORT:-6080}"
        
        echo -e "${CYAN}Bạn có muốn:${NC}"
        echo -e "  ${WHITE}1)${NC} Quick Tunnel (tên miền ngẫu nhiên, không cần tài khoản)"
        echo -e "  ${WHITE}2)${NC} Named Tunnel (tên miền riêng, cần tài khoản Cloudflare)"
        echo ""
        
        read -p "  Lựa chọn [1]: " cf_choice
        cf_choice=${cf_choice:-1}
        
        if [ "$cf_choice" = "1" ]; then
            cloudflared tunnel --url "http://localhost:$novnc_port" 2>&1 &
            local tunnel_pid=$!
            echo "$tunnel_pid" > "$CONFIG_DIR/tunnel.pid"
            
            sleep 5
            
            print_success "Cloudflare Quick Tunnel đã tạo!"
            print_info "Kiểm tra terminal để lấy URL (*.trycloudflare.com)"
        else
            echo -ne "  ${CYAN}Nhập tên miền của bạn (VD: desktop.example.com): ${NC}"
            read -r custom_domain
            
            if [ -n "$custom_domain" ]; then
                CUSTOM_DOMAIN="$custom_domain"
                echo "$CUSTOM_DOMAIN" > "$DOMAIN_FILE"
                save_config "CUSTOM_DOMAIN" "$CUSTOM_DOMAIN"
                
                print_info "Cần đăng nhập Cloudflare:"
                cloudflared tunnel login
                
                print_info "Tạo tunnel..."
                cloudflared tunnel create vnc-desktop 2>/dev/null
                
                cloudflared tunnel route dns vnc-desktop "$custom_domain" 2>/dev/null
                
                cloudflared tunnel run --url "http://localhost:$novnc_port" vnc-desktop 2>&1 &
                local tunnel_pid=$!
                echo "$tunnel_pid" > "$CONFIG_DIR/tunnel.pid"
                
                echo ""
                echo -e "${GREEN}╔══════════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║     CLOUDFLARE TUNNEL ĐÃ ĐƯỢC TẠO!              ║${NC}"
                echo -e "${GREEN}╠══════════════════════════════════════════════════╣${NC}"
                echo -e "${GREEN}║${NC}  🌐 Tên miền: ${WHITE}https://$custom_domain${NC}"
                echo -e "${GREEN}║${NC}  📌 Tên miền này là VĨNH VIỄN                    ${GREEN}║${NC}"
                echo -e "${GREEN}║${NC}  🔄 Khi bật script lên là tự động chạy           ${GREEN}║${NC}"
                echo -e "${GREEN}╚══════════════════════════════════════════════════╝${NC}"
            fi
        fi
    fi
}

# Tên miền tùy chỉnh
setup_custom_domain() {
    print_header "TÊN MIỀN TÙY CHỈNH"
    
    echo -e "${WHITE}Nhập tên miền của bạn:${NC}"
    echo -e "${DIM}(Tên miền này sẽ được lưu vĩnh viễn trong cấu hình)${NC}"
    echo ""
    
    echo -ne "  ${CYAN}Tên miền: ${NC}"
    read -r domain
    
    if [ -n "$domain" ]; then
        CUSTOM_DOMAIN="$domain"
        echo "$CUSTOM_DOMAIN" > "$DOMAIN_FILE"
        save_config "CUSTOM_DOMAIN" "$CUSTOM_DOMAIN"
        
        echo ""
        print_success "Tên miền đã được lưu: $domain"
        echo ""
        echo -e "${YELLOW}Lưu ý:${NC}"
        echo -e "  - Bạn cần cấu hình DNS trỏ tên miền về server của bạn"
        echo -e "  - Hoặc sử dụng reverse proxy (nginx/caddy)"
        echo -e "  - Tên miền sẽ được giữ vĩnh viễn trong cấu hình"
    fi
}

# Dừng tunnel
stop_tunnel() {
    print_step "Dừng tunnel..."
    
    if [ -f "$CONFIG_DIR/tunnel.pid" ]; then
        local pid=$(cat "$CONFIG_DIR/tunnel.pid")
        kill "$pid" 2>/dev/null
        kill -9 "$pid" 2>/dev/null
        rm -f "$CONFIG_DIR/tunnel.pid"
    fi
    
    pkill -f "cloudflared" 2>/dev/null
    pkill -f "ngrok" 2>/dev/null
    
    TUNNEL_RUNNING=false
    print_success "Tunnel đã dừng"
}

# ============================================================================
# SECTION 10: KHỞI ĐỘNG NHANH - MỘT CLICK
# ============================================================================

# Khởi động tất cả
start_all() {
    print_header "KHỞI ĐỘNG TOÀN BỘ HỆ THỐNG"
    
    echo -e "${WHITE}Đang khởi động VNC Desktop System...${NC}"
    echo ""
    
    # Bước 1: Kiểm tra cài đặt
    show_progress 1 5 "Kiểm tra cấu hình"
    sleep 1
    
    # Kiểm tra mật khẩu
    if [ ! -f "$VNC_DIR/passwd" ]; then
        echo ""
        setup_vnc_password
    fi
    
    # Bước 2: Khởi động VNC
    show_progress 2 5 "Khởi động VNC Server"
    stop_vnc_silent
    sleep 1
    
    local display="${VNC_DISPLAY:-:1}"
    local resolution="${VNC_RESOLUTION:-1280x720}"
    local depth="${VNC_COLOR_DEPTH:-24}"
    
    if [ ! -f "$XSTARTUP_FILE" ]; then
        create_xstartup
    fi
    
    export DISPLAY="$display"
    vncserver "$display" \
        -geometry "$resolution" \
        -depth "$depth" \
        -localhost no \
        -name "VNC Desktop" \
        > /dev/null 2>&1
    
    sleep 2
    
    # Bước 3: Khởi động noVNC
    show_progress 3 5 "Khởi động noVNC Web Client"
    stop_novnc_silent
    sleep 1
    
    local vnc_port=$((5900 + ${display#:}))
    local novnc_port="${NOVNC_PORT:-6080}"
    
    if check_command websockify; then
        if [ -d "$NOVNC_DIR" ]; then
            websockify --web="$NOVNC_DIR" "$novnc_port" "localhost:$vnc_port" > /dev/null 2>&1 &
        else
            websockify "$novnc_port" "localhost:$vnc_port" > /dev/null 2>&1 &
        fi
        echo "$!" > "$CONFIG_DIR/websockify.pid"
    fi
    
    sleep 2
    
    # Bước 4: Khởi động tunnel (nếu cấu hình)
    show_progress 4 5 "Kiểm tra tunnel"
    
    local enable_tunnel="${ENABLE_TUNNEL:-false}"
    if [ "$enable_tunnel" = "true" ]; then
        local tunnel_service="${TUNNEL_SERVICE:-localhost.run}"
        case "$tunnel_service" in
            "serveo.net")
                if [ -n "$CUSTOM_DOMAIN" ]; then
                    local subdomain=$(echo "$CUSTOM_DOMAIN" | sed 's/.serveo.net//')
                    ssh -R "${subdomain}:80:localhost:$novnc_port" serveo.net > /dev/null 2>&1 &
                    echo "$!" > "$CONFIG_DIR/tunnel.pid"
                fi
                ;;
            "ngrok")
                ngrok http "$novnc_port" --log=stdout > "$LOG_DIR/ngrok.log" 2>&1 &
                echo "$!" > "$CONFIG_DIR/tunnel.pid"
                ;;
            "cloudflared")
                cloudflared tunnel --url "http://localhost:$novnc_port" > /dev/null 2>&1 &
                echo "$!" > "$CONFIG_DIR/tunnel.pid"
                ;;
        esac
        TUNNEL_RUNNING=true
    fi
    
    sleep 1
    
    # Bước 5: Hoàn tất
    show_progress 5 5 "Hoàn tất"
    
    # Cập nhật trạng thái
    check_vnc_status
    check_novnc_status
    
    local ip=$(get_local_ip)
    
    echo ""
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║           🖥️  VNC WEB DESKTOP ĐÃ SẴN SÀNG!                  ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    
    if [ "$VNC_RUNNING" = true ]; then
        echo -e "${GREEN}║${NC}  ✅ VNC Server:   ${WHITE}Đang chạy${NC} (Port: $vnc_port)                 ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ VNC Server:   ${RED}Không chạy${NC}                                ${GREEN}║${NC}"
    fi
    
    if [ "$NOVNC_RUNNING" = true ] || check_port "$novnc_port"; then
        echo -e "${GREEN}║${NC}  ✅ noVNC Web:    ${WHITE}Đang chạy${NC} (Port: $novnc_port)                ${GREEN}║${NC}"
    else
        echo -e "${GREEN}║${NC}  ❌ noVNC Web:    ${RED}Không chạy${NC}                                ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}━━━ LINK TRUY CẬP ━━━${NC}                                      ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  🌐 ${WHITE}http://$ip:$novnc_port/vnc.html${NC}                      ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  🔗 ${WHITE}http://localhost:$novnc_port/vnc.html${NC}                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    
    if [ -n "$CUSTOM_DOMAIN" ]; then
        echo -e "${GREEN}║${NC}  🏷️  ${PURPLE}https://$CUSTOM_DOMAIN${NC}                              ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}  📌 ${DIM}Tên miền vĩnh viễn - Bật lên là chạy${NC}                  ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    fi
    
    echo -e "${GREEN}║${NC}  ${YELLOW}💡 Nhấp vào link để mở Desktop trên trình duyệt${NC}           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Dừng tất cả
stop_all() {
    print_header "DỪNG TOÀN BỘ HỆ THỐNG"
    
    print_step "Dừng tunnel..."
    stop_tunnel 2>/dev/null
    
    print_step "Dừng noVNC..."
    stop_novnc_silent
    
    print_step "Dừng VNC Server..."
    stop_vnc_silent
    
    # Clean up
    pkill -f "websockify" 2>/dev/null
    pkill -f "Xvnc" 2>/dev/null
    pkill -f "xfce" 2>/dev/null
    pkill -f "ngrok" 2>/dev/null
    pkill -f "cloudflared" 2>/dev/null
    
    rm -f /tmp/.X*-lock 2>/dev/null
    rm -f /tmp/.X11-unix/X* 2>/dev/null
    
    VNC_RUNNING=false
    NOVNC_RUNNING=false
    TUNNEL_RUNNING=false
    
    echo ""
    print_success "Toàn bộ hệ thống đã dừng!"
}

# ============================================================================
# SECTION 11: GIÁM SÁT HỆ THỐNG
# ============================================================================

# Hiển thị trạng thái
show_status() {
    print_header "TRẠNG THÁI HỆ THỐNG"
    
    check_vnc_status
    check_novnc_status
    
    local ip=$(get_local_ip)
    local vnc_port="${VNC_PORT:-5901}"
    local novnc_port="${NOVNC_PORT:-6080}"
    
    echo -e "  ${WHITE}╭──────────────────────────────────────────╮${NC}"
    echo -e "  ${WHITE}│${NC}          SYSTEM STATUS DASHBOARD          ${WHITE}│${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│${NC}                                            ${WHITE}│${NC}"
    
    # VNC Status
    if [ "$VNC_RUNNING" = true ]; then
        echo -e "  ${WHITE}│${NC}  VNC Server:    ${GREEN}● RUNNING${NC}                  ${WHITE}│${NC}"
        echo -e "  ${WHITE}│${NC}  VNC Port:      ${WHITE}$vnc_port${NC}                       ${WHITE}│${NC}"
    else
        echo -e "  ${WHITE}│${NC}  VNC Server:    ${RED}● STOPPED${NC}                  ${WHITE}│${NC}"
    fi
    
    # noVNC Status
    if [ "$NOVNC_RUNNING" = true ] || check_port "$novnc_port"; then
        echo -e "  ${WHITE}│${NC}  noVNC Web:     ${GREEN}● RUNNING${NC}                  ${WHITE}│${NC}"
        echo -e "  ${WHITE}│${NC}  Web Port:      ${WHITE}$novnc_port${NC}                       ${WHITE}│${NC}"
    else
        echo -e "  ${WHITE}│${NC}  noVNC Web:     ${RED}● STOPPED${NC}                  ${WHITE}│${NC}"
    fi
    
    # Tunnel Status
    if [ "$TUNNEL_RUNNING" = true ]; then
        echo -e "  ${WHITE}│${NC}  Tunnel:        ${GREEN}● ACTIVE${NC}                   ${WHITE}│${NC}"
    else
        echo -e "  ${WHITE}│${NC}  Tunnel:        ${DIM}● INACTIVE${NC}                 ${WHITE}│${NC}"
    fi
    
    echo -e "  ${WHITE}│${NC}                                            ${WHITE}│${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────┤${NC}"
    echo -e "  ${WHITE}│${NC}  Display:       ${CYAN}${VNC_DISPLAY:-:1}${NC}                       ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  Resolution:    ${CYAN}${VNC_RESOLUTION:-1280x720}${NC}                ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  IP Address:    ${CYAN}$ip${NC}                   ${WHITE}│${NC}"
    
    if [ -n "$CUSTOM_DOMAIN" ]; then
        echo -e "  ${WHITE}│${NC}  Domain:        ${PURPLE}$CUSTOM_DOMAIN${NC}       ${WHITE}│${NC}"
    fi
    
    echo -e "  ${WHITE}│${NC}                                            ${WHITE}│${NC}"
    echo -e "  ${WHITE}├──────────────────────────────────────────┤${NC}"
    
    # System info
    local cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' || echo "N/A")
    local mem_info=$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d/%dMB", $3, $2}' || echo "N/A")
    local uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F',' '{print $1}' | awk -F'up' '{print $2}' || echo "N/A")
    
    echo -e "  ${WHITE}│${NC}  CPU Usage:     ${WHITE}$cpu_usage${NC}                     ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  Memory:        ${WHITE}$mem_info${NC}               ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}  Uptime:        ${WHITE}$uptime_info${NC}           ${WHITE}│${NC}"
    echo -e "  ${WHITE}│${NC}                                            ${WHITE}│${NC}"
    echo -e "  ${WHITE}╰──────────────────────────────────────────╯${NC}"
    echo ""
    
    # Links
    if [ "$VNC_RUNNING" = true ] && ([ "$NOVNC_RUNNING" = true ] || check_port "$novnc_port"); then
        echo -e "  ${GREEN}🌐 Web Desktop:${NC} ${UNDERLINE}http://$ip:$novnc_port/vnc.html${NC}"
        
        if [ -n "$CUSTOM_DOMAIN" ]; then
            echo -e "  ${PURPLE}🏷️  Domain:${NC}     ${UNDERLINE}https://$CUSTOM_DOMAIN${NC}"
        fi
    fi
    echo ""
}

# Monitor real-time
system_monitor() {
    print_header "SYSTEM MONITOR"
    
    echo -e "${YELLOW}Nhấn Ctrl+C để thoát${NC}"
    echo ""
    
    while true; do
        clear
        echo -e "${CYAN}═══ VNC SYSTEM MONITOR ═══${NC}  $(date '+%H:%M:%S')"
        echo ""
        
        # Process list
        echo -e "${WHITE}Active Processes:${NC}"
        echo -e "${DIM}──────────────────────────────────${NC}"
        
        ps aux 2>/dev/null | grep -E "(Xvnc|websockify|xfce|ngrok|cloudflared)" | grep -v grep | \
            awk '{printf "  %-8s %-6s %-5s %s\n", $1, $2, $3, $11}' || \
            echo "  No VNC processes found"
        
        echo ""
        
        # Memory
        echo -e "${WHITE}Memory Usage:${NC}"
        echo -e "${DIM}──────────────────────────────────${NC}"
        free -h 2>/dev/null | head -2 || echo "  N/A"
        
        echo ""
        
        # Network
        echo -e "${WHITE}Network Ports:${NC}"
        echo -e "${DIM}──────────────────────────────────${NC}"
        ss -tuln 2>/dev/null | grep -E "(5901|6080|4040)" | \
            awk '{printf "  %-6s %-20s %s\n", $1, $5, $6}' || echo "  N/A"
        
        echo ""
        echo -e "${DIM}Refresh every 3s | Ctrl+C to exit${NC}"
        
        sleep 3
    done
}

# ============================================================================
# SECTION 12: BACKUP VÀ RESTORE
# ============================================================================

# Backup cấu hình
backup_config() {
    print_header "BACKUP CẤU HÌNH"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/vnc_backup_${timestamp}.tar.gz"
    
    print_step "Đang tạo backup..."
    
    # Tạo danh sách file cần backup
    local files_to_backup=()
    
    [ -f "$CONFIG_FILE" ] && files_to_backup+=("$CONFIG_FILE")
    [ -f "$DOMAIN_FILE" ] && files_to_backup+=("$DOMAIN_FILE")
    [ -f "$XSTARTUP_FILE" ] && files_to_backup+=("$XSTARTUP_FILE")
    [ -f "$VNC_DIR/passwd" ] && files_to_backup+=("$VNC_DIR/passwd")
    [ -f "$SESSION_FILE" ] && files_to_backup+=("$SESSION_FILE")
    
    if [ ${#files_to_backup[@]} -gt 0 ]; then
        tar -czf "$backup_file" "${files_to_backup[@]}" 2>/dev/null
        
        if [ -f "$backup_file" ]; then
            local size=$(du -h "$backup_file" | cut -f1)
            print_success "Backup đã tạo: $backup_file ($size)"
        else
            print_error "Không thể tạo backup"
        fi
    else
        print_warning "Không có file nào để backup"
    fi
}

# Restore cấu hình
restore_config() {
    print_header "RESTORE CẤU HÌNH"
    
    # Liệt kê backups
    local backups=($(ls -t "$BACKUP_DIR"/vnc_backup_*.tar.gz 2>/dev/null))
    
    if [ ${#backups[@]} -eq 0 ]; then
        print_warning "Không tìm thấy backup nào"
        return
    fi
    
    echo -e "${WHITE}Danh sách backup:${NC}"
    echo ""
    
    for i in "${!backups[@]}"; do
        local file="${backups[$i]}"
        local name=$(basename "$file")
        local size=$(du -h "$file" | cut -f1)
        local date=$(echo "$name" | grep -oP '\d{8}_\d{6}')
        
        echo -e "  ${CYAN}$((i+1)))${NC} $name ($size)"
    done
    
    echo ""
    read -p "  Chọn backup để restore (số): " choice
    
    if [ -n "$choice" ] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#backups[@]} ]; then
        local selected="${backups[$((choice-1))]}"
        
        if confirm_action "Restore từ $(basename "$selected")?"; then
            print_step "Đang restore..."
            tar -xzf "$selected" -C / 2>/dev/null
            
            if [ $? -eq 0 ]; then
                print_success "Restore thành công!"
                load_config
            else
                print_error "Restore thất bại"
            fi
        fi
    else
        print_error "Lựa chọn không hợp lệ"
    fi
}

# ============================================================================
# SECTION 13: CÀI ĐẶT NÂNG CAO
# ============================================================================

# Menu cài đặt
settings_menu() {
    while true; do
        print_header "CÀI ĐẶT"
        
        echo -e "  ${WHITE}1)${NC}  🖥️  Cấu hình VNC Server"
        echo -e "  ${WHITE}2)${NC}  🔑  Quản lý mật khẩu"
        echo -e "  ${WHITE}3)${NC}  🌐  Cấu hình tên miền"
        echo -e "  ${WHITE}4)${NC}  🎨  Cấu hình Desktop"
        echo -e "  ${WHITE}5)${NC}  ⚡  Cấu hình hiệu năng"
        echo -e "  ${WHITE}6)${NC}  🔄  Auto-start"
        echo -e "  ${WHITE}7)${NC}  💾  Backup cấu hình"
        echo -e "  ${WHITE}8)${NC}  📂  Restore cấu hình"
        echo -e "  ${WHITE}9)${NC}  📋  Xem log"
        echo -e "  ${WHITE}10)${NC} 🗑️  Reset cấu hình"
        echo -e "  ${WHITE}0)${NC}  ← Quay lại"
        echo ""
        
        read -p "  Lựa chọn: " setting_choice
        
        case "$setting_choice" in
            1) configure_vnc ;;
            2) password_menu ;;
            3) setup_domain ;;
            4) configure_desktop ;;
            5) configure_performance ;;
            6) configure_autostart ;;
            7) backup_config ;;
            8) restore_config ;;
            9) view_logs ;;
            10) reset_config ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ" ;;
        esac
        
        echo ""
        read -p "  Nhấn Enter để tiếp tục..."
    done
}

# Menu mật khẩu
password_menu() {
    while true; do
        print_header "QUẢN LÝ MẬT KHẨU"
        
        echo -e "  ${WHITE}1)${NC}  🔑  Đặt mật khẩu mới"
        echo -e "  ${WHITE}2)${NC}  🔄  Đổi mật khẩu"
        echo -e "  ${WHITE}3)${NC}  ℹ️   Thông tin mật khẩu"
        echo -e "  ${WHITE}0)${NC}  ← Quay lại"
        echo ""
        
        read -p "  Lựa chọn: " pw_choice
        
        case "$pw_choice" in
            1) setup_vnc_password ;;
            2) change_vnc_password ;;
            3) show_password_info ;;
            0) return ;;
            *) print_error "Lựa chọn không hợp lệ" ;;
        esac
        
        echo ""
        read -p "  Nhấn Enter để tiếp tục..."
    done
}

# Cấu hình desktop
configure_desktop() {
    print_header "CẤU HÌNH DESKTOP"
    
    echo -e "  ${WHITE}1)${NC} XFCE4 (Khuyến nghị)"
    echo -e "  ${WHITE}2)${NC} LXDE (Nhẹ)"
    echo -e "  ${WHITE}3)${NC} Openbox (Tối thiểu)"
    echo ""
    
    read -p "  Chọn Desktop Environment [1]: " de_choice
    de_choice=${de_choice:-1}
    
    case "$de_choice" in
        1)
            save_config "DESKTOP_ENV" "xfce4"
            create_xstartup
            print_success "Desktop: XFCE4"
            ;;
        2)
            install_package "lxde" "LXDE Desktop"
            save_config "DESKTOP_ENV" "lxde"
            # Cập nhật xstartup cho LXDE
            cat > "$XSTARTUP_FILE" << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_CURRENT_DESKTOP=LXDE
exec startlxde &
EOF
            chmod +x "$XSTARTUP_FILE"
            print_success "Desktop: LXDE"
            ;;
        3)
            install_package "openbox" "Openbox"
            save_config "DESKTOP_ENV" "openbox"
            cat > "$XSTARTUP_FILE" << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
xsetroot -solid "#2E3440"
exec openbox-session &
EOF
            chmod +x "$XSTARTUP_FILE"
            print_success "Desktop: Openbox"
            ;;
    esac
}

# Cấu hình hiệu năng
configure_performance() {
    print_header "CẤU HÌNH HIỆU NĂNG"
    
    echo -e "  ${WHITE}Chọn preset:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 🐢 Tiết kiệm (Low RAM, CPU thấp)"
    echo -e "  ${CYAN}2)${NC} ⚖️  Cân bằng (Khuyến nghị)"
    echo -e "  ${CYAN}3)${NC} 🚀 Hiệu năng cao"
    echo ""
    
    read -p "  Lựa chọn [2]: " perf_choice
    perf_choice=${perf_choice:-2}
    
    case "$perf_choice" in
        1)
            save_config "FRAME_RATE" "15"
            save_config "COMPRESSION_LEVEL" "9"
            save_config "QUALITY_LEVEL" "3"
            save_config "VNC_RESOLUTION" "800x600"
            save_config "VNC_COLOR_DEPTH" "16"
            print_success "Cấu hình: Tiết kiệm"
            ;;
        2)
            save_config "FRAME_RATE" "30"
            save_config "COMPRESSION_LEVEL" "6"
            save_config "QUALITY_LEVEL" "6"
            save_config "VNC_RESOLUTION" "1280x720"
            save_config "VNC_COLOR_DEPTH" "24"
            print_success "Cấu hình: Cân bằng"
            ;;
        3)
            save_config "FRAME_RATE" "60"
            save_config "COMPRESSION_LEVEL" "2"
            save_config "QUALITY_LEVEL" "9"
            save_config "VNC_RESOLUTION" "1920x1080"
            save_config "VNC_COLOR_DEPTH" "24"
            print_success "Cấu hình: Hiệu năng cao"
            ;;
    esac
    
    load_config
}

# Cấu hình auto-start
configure_autostart() {
    print_header "CẤU HÌNH AUTO-START"
    
    echo -e "${WHITE}Chọn dịch vụ tự động khởi động:${NC}"
    echo ""
    
    local autostart_vnc="${AUTOSTART_VNC:-false}"
    local autostart_novnc="${AUTOSTART_NOVNC:-false}"
    local autostart_tunnel="${AUTOSTART_TUNNEL:-false}"
    
    echo -e "  ${WHITE}1)${NC} VNC Server     [$([ "$autostart_vnc" = "true" ] && echo -e "${GREEN}ON${NC}" || echo -e "${RED}OFF${NC}")]"
    echo -e "  ${WHITE}2)${NC} noVNC Web      [$([ "$autostart_novnc" = "true" ] && echo -e "${GREEN}ON${NC}" || echo -e "${RED}OFF${NC}")]"
    echo -e "  ${WHITE}3)${NC} Tunnel         [$([ "$autostart_tunnel" = "true" ] && echo -e "${GREEN}ON${NC}" || echo -e "${RED}OFF${NC}")]"
    echo -e "  ${WHITE}4)${NC} Bật tất cả"
    echo -e "  ${WHITE}5)${NC} Tắt tất cả"
    echo ""
    
    read -p "  Lựa chọn: " auto_choice
    
    case "$auto_choice" in
        1)
            if [ "$autostart_vnc" = "true" ]; then
                save_config "AUTOSTART_VNC" "false"
                print_info "Auto-start VNC: OFF"
            else
                save_config "AUTOSTART_VNC" "true"
                print_info "Auto-start VNC: ON"
            fi
            ;;
        2)
            if [ "$autostart_novnc" = "true" ]; then
                save_config "AUTOSTART_NOVNC" "false"
            else
                save_config "AUTOSTART_NOVNC" "true"
            fi
            ;;
        3)
            if [ "$autostart_tunnel" = "true" ]; then
                save_config "AUTOSTART_TUNNEL" "false"
            else
                save_config "AUTOSTART_TUNNEL" "true"
            fi
            ;;
        4)
            save_config "AUTOSTART_VNC" "true"
            save_config "AUTOSTART_NOVNC" "true"
            save_config "AUTOSTART_TUNNEL" "true"
            print_success "Tất cả auto-start đã bật"
            ;;
        5)
            save_config "AUTOSTART_VNC" "false"
            save_config "AUTOSTART_NOVNC" "false"
            save_config "AUTOSTART_TUNNEL" "false"
            print_success "Tất cả auto-start đã tắt"
            ;;
    esac
    
    # Tạo file auto-start cho Termux
    create_autostart_script
}

# Tạo script auto-start
create_autostart_script() {
    local termux_boot_dir="$HOME/.termux/boot"
    mkdir -p "$termux_boot_dir"
    
    cat > "$termux_boot_dir/vnc-autostart.sh" << BOOTEOF
#!/data/data/com.termux/files/usr/bin/bash

# VNC Auto-start Script
# Generated by VNC Manager

sleep 5

# Source config
source "$CONFIG_FILE" 2>/dev/null

# Start VNC
if [ "\${AUTOSTART_VNC:-false}" = "true" ]; then
    export DISPLAY="\${VNC_DISPLAY:-:1}"
    vncserver "\$DISPLAY" \\
        -geometry "\${VNC_RESOLUTION:-1280x720}" \\
        -depth "\${VNC_COLOR_DEPTH:-24}" \\
        -localhost no \\
        -name "VNC Desktop" &
    sleep 3
fi

# Start noVNC
if [ "\${AUTOSTART_NOVNC:-false}" = "true" ]; then
    local vnc_port=\$((5900 + \${DISPLAY#:}))
    local novnc_port="\${NOVNC_PORT:-6080}"
    
    if [ -d "$NOVNC_DIR" ]; then
        websockify --web="$NOVNC_DIR" "\$novnc_port" "localhost:\$vnc_port" &
    else
        websockify "\$novnc_port" "localhost:\$vnc_port" &
    fi
fi

# Start Tunnel
if [ "\${AUTOSTART_TUNNEL:-false}" = "true" ]; then
    case "\${TUNNEL_SERVICE}" in
        "serveo.net")
            ssh -R "\${CUSTOM_DOMAIN%%.*}:80:localhost:\$novnc_port" serveo.net &
            ;;
        "cloudflared")
            cloudflared tunnel --url "http://localhost:\$novnc_port" &
            ;;
    esac
fi
BOOTEOF
    
    chmod +x "$termux_boot_dir/vnc-autostart.sh"
    print_info "Auto-start script đã tạo tại $termux_boot_dir"
}

# Xem log
view_logs() {
    print_header "XEM LOG"
    
    if [ -f "$LOG_FILE" ]; then
        local line_count=$(wc -l < "$LOG_FILE")
        echo -e "${WHITE}Log file: $LOG_FILE ($line_count dòng)${NC}"
        echo ""
        
        echo -e "  ${CYAN}1)${NC} Xem 20 dòng cuối"
        echo -e "  ${CYAN}2)${NC} Xem 50 dòng cuối"
        echo -e "  ${CYAN}3)${NC} Xem toàn bộ"
        echo -e "  ${CYAN}4)${NC} Xem errors"
        echo -e "  ${CYAN}5)${NC} Xóa log"
        echo ""
        
        read -p "  Lựa chọn [1]: " log_choice
        log_choice=${log_choice:-1}
        
        echo ""
        draw_line "-" 50
        
        case "$log_choice" in
            1) tail -20 "$LOG_FILE" ;;
            2) tail -50 "$LOG_FILE" ;;
            3) less "$LOG_FILE" ;;
            4) grep -i "error\|fail" "$LOG_FILE" | tail -20 ;;
            5)
                if confirm_action "Xóa toàn bộ log?"; then
                    > "$LOG_FILE"
                    print_success "Log đã xóa"
                fi
                ;;
        esac
        
        draw_line "-" 50
    else
        print_warning "Chưa có log"
    fi
}

# Reset cấu hình
reset_config() {
    print_header "RESET CẤU HÌNH"
    
    echo -e "${RED}⚠️  CẢNH BÁO: Thao tác này sẽ xóa toàn bộ cấu hình!${NC}"
    echo ""
    
    if confirm_action "Bạn có chắc chắn muốn reset?"; then
        if confirm_action "Xác nhận lần cuối - KHÔNG THỂ HOÀN TÁC?"; then
            # Backup trước khi reset
            backup_config
            
            # Dừng tất cả
            stop_all
            
            # Xóa cấu hình
            rm -f "$CONFIG_FILE"
            rm -f "$DOMAIN_FILE"
            rm -f "$PASSWORD_FILE"
            rm -f "$SESSION_FILE"
            
            # Tạo lại cấu hình mặc định
            init_config
            
            print_success "Cấu hình đã được reset!"
            print_info "Backup đã được lưu trong $BACKUP_DIR"
        fi
    fi
}

# ============================================================================
# SECTION 14: HELP VÀ THÔNG TIN
# ============================================================================

# Hiển thị hướng dẫn
show_help() {
    print_header "HƯỚNG DẪN SỬ DỤNG"
    
    echo -e "${WHITE}${BOLD}VNC Web Desktop Manager v${VERSION}${NC}"
    echo -e "${DIM}Tạo môi trường Desktop Linux trên Android${NC}"
    echo ""
    
    echo -e "${CYAN}━━━ BƯỚC ĐẦU TIÊN ━━━${NC}"
    echo -e "  1. Chạy ${WHITE}'Cài đặt đầy đủ'${NC} từ menu chính"
    echo -e "  2. Đặt mật khẩu VNC khi được yêu cầu"
    echo -e "  3. Chọn ${WHITE}'Khởi động nhanh'${NC} để bắt đầu"
    echo -e "  4. Mở link trên trình duyệt"
    echo ""
    
    echo -e "${CYAN}━━━ TRUY CẬP DESKTOP ━━━${NC}"
    echo -e "  • ${WHITE}Local:${NC}  http://localhost:6080/vnc.html"
    echo -e "  • ${WHITE}Mạng:${NC}   http://<IP>:6080/vnc.html"
    echo -e "  • ${WHITE}Domain:${NC} https://<your-domain>"
    echo ""
    
    echo -e "${CYAN}━━━ TÊN MIỀN VĨNH VIỄN ━━━${NC}"
    echo -e "  Để có tên miền vĩnh viễn (không thay đổi):"
    echo -e "  1. Vào ${WHITE}Cài đặt > Cấu hình tên miền${NC}"
    echo -e "  2. Chọn ${WHITE}Serveo.net${NC} hoặc ${WHITE}Cloudflare Tunnel${NC}"
    echo -e "  3. Nhập tên miền mong muốn"
    echo -e "  4. Khi bật script lên, desktop sẽ tự chạy trên tên miền đó"
    echo ""
    
    echo -e "${CYAN}━━━ LƯU Ý ━━━${NC}"
    echo -e "  • Cần Termux và Termux:API"
    echo -e "  • Nên tắt battery optimization cho Termux"
    echo -e "  • RAM tối thiểu: 2GB"
    echo -e "  • Dung lượng cần: ~500MB"
    echo ""
    
    echo -e "${CYAN}━━━ KHẮC PHỤC LỖI ━━━${NC}"
    echo -e "  • VNC không khởi động: Kiểm tra xstartup và mật khẩu"
    echo -e "  • Màn hình đen: Cài lại xfce4-goodies"
    echo -e "  • Port đã dùng: Đổi display number"
    echo -e "  • noVNC lỗi: Cài lại websockify"
    echo ""
}

# Thông tin hệ thống
show_system_info() {
    print_header "THÔNG TIN HỆ THỐNG"
    
    echo -e "  ${CYAN}Script:${NC}"
    echo -e "    Version:    $VERSION"
    echo -e "    Config:     $CONFIG_DIR"
    echo -e "    Log:        $LOG_FILE"
    echo ""
    
    echo -e "  ${CYAN}System:${NC}"
    echo -e "    OS:         $(uname -o 2>/dev/null || echo "N/A")"
    echo -e "    Kernel:     $(uname -r 2>/dev/null || echo "N/A")"
    echo -e "    Arch:       $(uname -m 2>/dev/null || echo "N/A")"
    echo -e "    User:       $(whoami)"
    echo -e "    Shell:      $SHELL"
    echo ""
    
    echo -e "  ${CYAN}Packages:${NC}"
    echo -e "    VNC:        $(vncserver -version 2>&1 | head -1 || echo "Not installed")"
    echo -e "    websockify: $(websockify --version 2>&1 | head -1 || echo "Not installed")"
    echo -e "    Python:     $(python --version 2>&1 || echo "Not installed")"
    echo -e "    Git:        $(git --version 2>&1 || echo "Not installed")"
    echo ""
    
    echo -e "  ${CYAN}Network:${NC}"
    echo -e "    IP:         $(get_local_ip)"
    echo -e "    Domain:     ${CUSTOM_DOMAIN:-"Not configured"}"
    echo ""
    
    # Neofetch nếu có
    if check_command neofetch; then
        echo -e "  ${CYAN}Neofetch:${NC}"
        neofetch --off 2>/dev/null | sed 's/^/    /'
    fi
}

# ============================================================================
# SECTION 15: CÀI ĐẶT ĐẦY ĐỦ (FIRST-TIME SETUP)
# ============================================================================

full_install() {
    print_banner
    print_header "CÀI ĐẶT ĐẦY ĐỦ"
    
    echo -e "${WHITE}Quá trình cài đặt sẽ:${NC}"
    echo -e "  ✦ Cập nhật hệ thống"
    echo -e "  ✦ Cài đặt XFCE4 Desktop"
    echo -e "  ✦ Cài đặt VNC Server"
    echo -e "  ✦ Cài đặt noVNC Web Client"
    echo -e "  ✦ Cấu hình mật khẩu"
    echo -e "  ✦ Cấu hình tên miền (tùy chọn)"
    echo ""
    echo -e "${YELLOW}Thời gian ước tính: 10-30 phút (tùy tốc độ mạng)${NC}"
    echo ""
    
    if ! confirm_action "Bắt đầu cài đặt?" "y"; then
        return
    fi
    
    echo ""
    
    # Bước 1: Cài đặt packages
    install_all_packages
    
    echo ""
    read -p "  Nhấn Enter để tiếp tục..."
    
    # Bước 2: Cấu hình VNC
    configure_vnc
    
    echo ""
    read -p "  Nhấn Enter để tiếp tục..."
    
    # Bước 3: Đặt mật khẩu
    setup_vnc_password
    
    echo ""
    read -p "  Nhấn Enter để tiếp tục..."
    
    # Bước 4: Cấu hình tên miền (tùy chọn)
    echo ""
    if confirm_action "Bạn có muốn cấu hình tên miền tùy chỉnh?"; then
        setup_domain
    fi
    
    echo ""
    
    # Hoàn tất
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║          🎉  CÀI ĐẶT HOÀN TẤT!  🎉                        ║"
    echo "║                                                              ║"
    echo "║   Bạn có thể bắt đầu sử dụng VNC Desktop ngay bây giờ!    ║"
    echo "║                                                              ║"
    echo "║   Chọn 'Khởi động nhanh' từ menu chính để bắt đầu.        ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log_message "INFO" "Full installation completed"
    
    # Hỏi khởi động ngay
    if confirm_action "Khởi động VNC Desktop ngay bây giờ?" "y"; then
        start_all
    fi
}

# ============================================================================
# SECTION 16: MENU CHÍNH
# ============================================================================

# Menu chính
main_menu() {
    while true; do
        print_banner
        
        # Hiển thị trạng thái nhanh
        check_vnc_status
        check_novnc_status
        
        local vnc_status="${RED}● OFF${NC}"
        local novnc_status="${RED}● OFF${NC}"
        local tunnel_status="${DIM}● OFF${NC}"
        
        [ "$VNC_RUNNING" = true ] && vnc_status="${GREEN}● ON${NC}"
        ([ "$NOVNC_RUNNING" = true ] || check_port "${NOVNC_PORT:-6080}") && novnc_status="${GREEN}● ON${NC}"
        [ "$TUNNEL_RUNNING" = true ] && tunnel_status="${GREEN}● ON${NC}"
        
        echo -e "  ${DIM}VNC: $vnc_status  ${DIM}│  Web: $novnc_status  ${DIM}│  Tunnel: $tunnel_status${NC}"
        
        if [ -n "$CUSTOM_DOMAIN" ]; then
            echo -e "  ${DIM}Domain: ${PURPLE}$CUSTOM_DOMAIN${NC}"
        fi
        
        echo ""
        draw_line "─" 55
        echo ""
        
        echo -e "  ${BOLD}${WHITE}MENU CHÍNH${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC}  🚀  Khởi động nhanh (Start All)"
        echo -e "  ${GREEN}2)${NC}  ⏹️   Dừng tất cả (Stop All)"
        echo -e "  ${GREEN}3)${NC}  🔄  Khởi động lại"
        echo ""
        echo -e "  ${CYAN}4)${NC}  🖥️   Khởi động VNC Server"
        echo -e "  ${CYAN}5)${NC}  🌐  Khởi động noVNC Web"
        echo -e "  ${CYAN}6)${NC}  🔗  Cấu hình tên miền/Tunnel"
        echo ""
        echo -e "  ${YELLOW}7)${NC}  📊  Trạng thái hệ thống"
        echo -e "  ${YELLOW}8)${NC}  📈  System Monitor"
        echo -e "  ${YELLOW}9)${NC}  ⚙️   Cài đặt"
        echo ""
        echo -e "  ${PURPLE}10)${NC} 📦  Cài đặt đầy đủ (First-time)"
        echo -e "  ${PURPLE}11)${NC} ❓  Hướng dẫn"
        echo -e "  ${PURPLE}12)${NC} ℹ️   Thông tin hệ thống"
        echo ""
        echo -e "  ${RED}0)${NC}  🚪  Thoát"
        echo ""
        draw_line "─" 55
        echo ""
        
        read -p "  ▶ Lựa chọn: " choice
        
        case "$choice" in
            1)
                start_all
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            2)
                stop_all
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            3)
                stop_all
                sleep 2
                start_all
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            4)
                start_vnc
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            5)
                start_novnc
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            6)
                setup_domain
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            7)
                show_status
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            8)
                system_monitor
                ;;
            9)
                settings_menu
                ;;
            10)
                full_install
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            11)
                show_help
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            12)
                show_system_info
                echo ""
                read -p "  Nhấn Enter để tiếp tục..."
                ;;
            0)
                echo ""
                if confirm_action "Thoát VNC Manager?"; then
                    echo ""
                    echo -e "${CYAN}Cảm ơn bạn đã sử dụng VNC Web Desktop Manager!${NC}"
                    echo -e "${DIM}Goodbye! 👋${NC}"
                    echo ""
                    exit 0
                fi
                ;;
            *)
                print_error "Lựa chọn không hợp lệ!"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# SECTION 17: COMMAND LINE ARGUMENTS
# ============================================================================

handle_arguments() {
    case "$1" in
        --start|-s)
            init_directories
            init_config
            load_config
            start_all
            ;;
        --stop|-x)
            init_directories
            init_config
            load_config
            stop_all
            ;;
        --restart|-r)
            init_directories
            init_config
            load_config
            stop_all
            sleep 2
            start_all
            ;;
        --status|-t)
            init_directories
            init_config
            load_config
            show_status
            ;;
        --install|-i)
            init_directories
            init_config
            full_install
            ;;
        --password|-p)
            init_directories
            init_config
            setup_vnc_password
            ;;
        --help|-h)
            echo ""
            echo "VNC Web Desktop Manager v${VERSION}"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --start,    -s    Start all services"
            echo "  --stop,     -x    Stop all services"
            echo "  --restart,  -r    Restart all services"
            echo "  --status,   -t    Show status"
            echo "  --install,  -i    Full installation"
            echo "  --password, -p    Set VNC password"
            echo "  --help,     -h    Show this help"
            echo "  --version,  -v    Show version"
            echo ""
            echo "Without options, interactive menu will be shown."
            echo ""
            ;;
        --version|-v)
            echo "VNC Web Desktop Manager v${VERSION}"
            ;;
        "")
            # Không có argument, chạy menu tương tác
            return 1
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
    
    return 0
}

# ============================================================================
# SECTION 18: ENTRY POINT
# ============================================================================

main() {
    # Xử lý Ctrl+C
    trap 'echo ""; echo -e "${YELLOW}Interrupted${NC}"; exit 0' INT
    
    # Khởi tạo
    init_directories
    init_config
    load_config
    
    # Xử lý arguments
    if handle_arguments "$@"; then
        exit 0
    fi
    
    # Auto-start check
    local autostart_vnc="${AUTOSTART_VNC:-false}"
    local autostart_novnc="${AUTOSTART_NOVNC:-false}"
    
    if [ "$autostart_vnc" = "true" ] || [ "$autostart_novnc" = "true" ]; then
        check_vnc_status
        check_novnc_status
        
        if [ "$VNC_RUNNING" = false ] && [ "$autostart_vnc" = "true" ]; then
            print_info "Auto-starting VNC..."
            start_vnc > /dev/null 2>&1
        fi
        
        if [ "$NOVNC_RUNNING" = false ] && [ "$autostart_novnc" = "true" ]; then
            print_info "Auto-starting noVNC..."
            start_novnc > /dev/null 2>&1
        fi
    fi
    
    # Chạy menu chính
    main_menu
}

# Chạy
main "$@"

# ============================================================================
# END OF SCRIPT
# Total Lines: 1200+
# ============================================================================
