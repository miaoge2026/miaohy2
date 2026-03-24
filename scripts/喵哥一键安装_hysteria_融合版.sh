#!/bin/bash

# 喵哥Hysteria 2一键安装脚本 - 融合版
# 融合seagullz4/hysteria2的优点，真正的"一键导入即可使用"
# 参考: https://github.com/seagullz4/hysteria2

# 快速安装命令
# bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh)

set -e

# ==================== 配置变量 ====================
SCRIPT_NAME="喵哥Hysteria2融合版"
SCRIPT_VERSION="4.0.0"
HYSTERIA_DIR="/root/hysteria"
CONFIG_DIR="${HYSTERIA_DIR}/config"
CERT_DIR="${HYSTERIA_DIR}/certs"
BACKUP_DIR="${HYSTERIA_DIR}/backup"
LOG_DIR="${HYSTERIA_DIR}/logs"

# 默认配置
DEFAULT_PORT=443
DEFAULT_PASSWORD=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 16)
DEFAULT_BW_UP=100
DEFAULT_BW_DOWN=20
DEFAULT_DNS="1.1.1.1"

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_info() { echo -e "${BLUE}ℹ️${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }
log_debug() { echo -e "${MAGENTA}🔍${NC} $1"; }

# ==================== 系统检测 ====================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        log_info "可以使用: sudo -i 进入root模式"
        exit 1
    fi
    log_success "root权限检查通过"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_TYPE=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "无法确定操作系统类型"
        exit 1
    fi
    
    case $OS_TYPE in
        ubuntu|debian)
            PKG_MANAGER="apt"
            ;;
        centos|rhel|fedora|rocky)
            PKG_MANAGER="yum"
            ;;
        arch)
            PKG_MANAGER="pacman"
            ;;
        *)
            log_warn "可能不支持的操作系统: $OS_TYPE，继续尝试..."
            PKG_MANAGER="apt"
            ;;
    esac
    
    log_success "检测到系统: $OS_TYPE $OS_VERSION"
}

# ==================== 依赖安装 ====================
install_dependencies() {
    log_info "安装系统依赖..."
    
    local packages=()
    case $PKG_MANAGER in
        apt)
            packages=(curl wget openssl qrencode net-tools procps iptables ca-certificates python3 python3-pip)
            apt update > /dev/null 2>&1
            apt install -y "${packages[@]}" > /dev/null 2>&1
            ;;
        yum)
            packages=(curl wget openssl qrencode net-tools procps iptables ca-certificates python3 python3-pip)
            yum install -y epel-release > /dev/null 2>&1
            yum install -y "${packages[@]}" > /dev/null 2>&1
            ;;
        pacman)
            packages=(curl wget openssl qrencode net-tools procps iptables ca-certificates python3)
            pacman -Sy --noconfirm "${packages[@]}" > /dev/null 2>&1
            ;;
    esac
    
    # 安装Python依赖
    if command -v pip3 > /dev/null 2>&1; then
        pip3 install --break-system-packages -q requests 2>/dev/null || true
    fi
    
    log_success "依赖安装完成"
}

# ==================== 系统优化 ====================
optimize_system() {
    log_info "优化系统设置..."
    
    # 优化网络参数
    cat >> /etc/sysctl.conf << 'EOF'
# Hysteria优化参数
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
EOF
    
    sysctl -p > /dev/null 2>&1 || true
    
    log_success "系统优化完成"
}

# ==================== Hysteria安装 ====================
download_hysteria() {
    log_info "下载Hysteria 2..."
    
    local latest_version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r '.tag_name' 2>/dev/null)
    if [ -z "$latest_version" ]; then
        latest_version="v2.7.1"
    fi
    
    local arch=$(uname -m)
    case $arch in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="arm" ;;
        i386|i686) arch="386" ;;
        *)
            log_error "不支持的架构: $arch"
            exit 1
            ;;
    esac
    
    local download_url="https://github.com/apernet/hysteria/releases/download/${latest_version}/hysteria-linux-${arch}"
    
    if ! curl -Lo /tmp/hysteria "$download_url" > /dev/null 2>&1; then
        log_error "下载失败，请检查网络连接"
        exit 1
    fi
    
    chmod +x /tmp/hysteria
    mv -f /tmp/hysteria /usr/local/bin/hysteria
    
    if ! hysteria version > /dev/null 2>&1; then
        log_error "Hysteria安装验证失败"
        exit 1
    fi
    
    log_success "Hysteria安装成功: $(hysteria version)"
}

# ==================== 证书管理 ====================
setup_certificates() {
    local domain=${1:-""}
    
    mkdir -p "$CERT_DIR"
    
    if [ -z "$domain" ] || [ "$domain" = "auto" ]; then
        # 尝试获取服务器IP
        domain=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "hysteria.local")
    fi
    
    if [ -n "$domain" ] && [ "$domain" != "hysteria.local" ] && [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        # 使用acme申请证书
        log_info "申请Let's Encrypt证书: $domain"
        
        if [ ! -f ~/.acme.sh/acme.sh ]; then
            curl https://get.acme.sh | sh > /dev/null 2>&1
            source ~/.bashrc
        fi
        
        # 停止可能占用80端口的服务
        systemctl stop nginx 2>/dev/null || true
        systemctl stop httpd 2>/dev/null || true
        
        if ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --server letsencrypt > /dev/null 2>&1; then
            ~/.acme.sh/acme.sh --install-cert -d "$domain" \
                --key-file "${CERT_DIR}/private.key" \
                --fullchain-file "${CERT_DIR}/fullchain.cer" \
                --ecc > /dev/null 2>&1
            
            chmod 600 "${CERT_DIR}/private.key"
            chmod 644 "${CERT_DIR}/fullchain.cer"
            
            log_success "SSL证书申请成功: $domain"
            echo "$domain"
            return 0
        else
            log_warn "SSL证书申请失败，使用自签名证书"
        fi
    fi
    
    # 生成自签名证书
    log_info "生成自签名证书..."
    
    openssl req -x509 -newkey rsa:4096 -keyout "${CERT_DIR}/private.key" \
        -out "${CERT_DIR}/fullchain.cer" -days 365 -nodes \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=${domain}" > /dev/null 2>&1
    
    chmod 600 "${CERT_DIR}/private.key"
    chmod 644 "${CERT_DIR}/fullchain.cer"
    
    log_warn "已生成自签名证书，客户端需要设置 insecure: true"
    echo "${domain:-hysteria.local}"
}

# ==================== 配置生成 ====================
generate_config() {
    local port=${1:-$DEFAULT_PORT}
    local password=${2:-$DEFAULT_PASSWORD}
    local domain=${3:-""}
    local up_bw=${4:-$DEFAULT_BW_UP}
    local down_bw=${5:-$DEFAULT_BW_DOWN}
    local dns=${6:-$DEFAULT_DNS}
    
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    
    # 生成服务器配置
    cat > "${CONFIG_DIR}/server.yaml" << EOF
# Hysteria 2 Server Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

listen: :${port}

tls:
  cert: ${CERT_DIR}/fullchain.cer
  key: ${CERT_DIR}/private.key

bandwidth:
  up: ${up_bw} mbps
  down: ${down_bw} mbps

auth:
  type: password
  password: ${password}

resolver:
  type: https
  https:
    addr: ${dns}:443
    timeout: 10s

sniff:
  enable: true
  timeout: 2s

acl:
  inline:
    - reject(all, udp/443)
    - allow(any)

log:
  level: info
  format: text
  file: ${LOG_DIR}/hysteria.log
EOF
    
    # 生成客户端配置
    if [ -z "$domain" ]; then
        domain=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "hysteria.local")
    fi
    
    local insecure="false"
    if [[ "$domain" == *"local"* ]] || [[ "$domain" == *"hysteria"* ]]; then
        insecure="true"
    fi
    
    cat > "${CONFIG_DIR}/client.yaml" << EOF
# Hysteria 2 Client Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

server: "${domain}:${port}"

auth: ${password}

tls:
  sni: ${domain}
  insecure: ${insecure}
  # ca: ${CERT_DIR}/ca.cer  # 自签名证书需要

bandwidth:
  up: 20 mbps
  down: 100 mbps

socks5:
  listen: 127.0.0.1:50000
  timeout: 30s

http:
  listen: 127.0.0.1:50001

log:
  level: info
  format: text
EOF
    
    chmod 600 "${CONFIG_DIR}/server.yaml"
    chmod 600 "${CONFIG_DIR}/client.yaml"
    
    log_success "配置文件生成完成"
}

# ==================== 服务管理 ====================
setup_service() {
    log_info "配置系统服务..."
    
    cat > /etc/systemd/system/hysteria.service << 'EOF'
[Unit]
Description=Hysteria 2 Server
After=network.target nss-lookup.target
Wants=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/hysteria
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=false

ExecStart=/usr/local/bin/hysteria server -c /root/hysteria/config/server.yaml --log-level info
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10
RestartPreventExitStatus=255

LimitNPROC=512
LimitNOFILE=infinity
LimitMEMLOCK=infinity
LimitSTACK=infinity
LimitCORE=infinity

StandardOutput=journal
StandardError=journal
SyslogIdentifier=hysteria

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    log_success "系统服务配置完成"
}

start_service() {
    log_info "启动Hysteria服务..."
    
    systemctl enable hysteria > /dev/null 2>&1
    systemctl start hysteria
    
    sleep 3
    
    if systemctl is-active --quiet hysteria; then
        log_success "Hysteria服务启动成功"
        
        # 检查端口监听
        local port=$(grep "listen:" "${CONFIG_DIR}/server.yaml" | awk '{print $2}' | cut -d: -f2)
        if netstat -tuln | grep -q ":${port} "; then
            log_success "端口 ${port} 监听正常"
        else
            log_warn "端口 ${port} 可能未监听，请检查配置"
        fi
        
        return 0
    else
        log_error "Hysteria服务启动失败"
        log_error "请检查日志: journalctl -u hysteria -n 50"
        return 1
    fi
}

# ==================== 快捷命令 ====================
setup_shortcut() {
    log_info "配置快捷命令..."
    
    # 创建快捷命令 hy2
    cat > /usr/local/bin/hy2 << 'EOF'
#!/bin/bash

HYSTERIA_DIR="/root/hysteria"
CONFIG_DIR="${HYSTERIA_DIR}/config"
LOG_DIR="${HYSTERIA_DIR}/logs"

case $1 in
    start)
        systemctl start hysteria
        ;;
    stop)
        systemctl stop hysteria
        ;;
    restart)
        systemctl restart hysteria
        ;;
    status)
        systemctl status hysteria
        ;;
    logs)
        journalctl -u hysteria -f
        ;;
    config)
        nano "${CONFIG_DIR}/server.yaml"
        ;;
    client)
        echo "客户端配置:"
        cat "${CONFIG_DIR}/client.yaml"
        ;;
    qr)
        if [ -f "${CONFIG_DIR}/client.yaml" ]; then
            qrencode -t ANSIUTF8 < "${CONFIG_DIR}/client.yaml"
        else
            echo "客户端配置不存在"
        fi
        ;;
    test)
        hysteria server -c "${CONFIG_DIR}/server.yaml" --log-level debug
        ;;
    uninstall)
        systemctl stop hysteria 2>/dev/null || true
        systemctl disable hysteria 2>/dev/null || true
        rm -f /usr/local/bin/hysteria
        rm -f /etc/systemd/system/hysteria.service
        rm -rf /root/hysteria
        rm -f /usr/local/bin/hy2
        systemctl daemon-reload
        echo "Hysteria已卸载"
        ;;
    *)
        echo "用法: hy2 {start|stop|restart|status|logs|config|client|qr|test|uninstall}"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/hy2
    
    log_success "快捷命令配置完成: hy2"
}

# ==================== 订阅转换 ====================
generate_subscription() {
    local port=${1:-$DEFAULT_PORT}
    local password=${2:-$DEFAULT_PASSWORD}
    local domain=${3:-""}
    
    if [ -z "$domain" ]; then
        domain=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "hysteria.local")
    fi
    
    mkdir -p "${CONFIG_DIR}/subscriptions"
    
    # 生成多种格式的订阅
    cat > "${CONFIG_DIR}/subscriptions/hysteria2.json" << EOF
{
  "server": "${domain}:${port}",
  "auth": "${password}",
  "tls": {
    "sni": "${domain}",
    "insecure": true
  },
  "bandwidth": {
    "up": "20 mbps",
    "down": "100 mbps"
  }
}
EOF
    
    # 生成Clash配置
    cat > "${CONFIG_DIR}/subscriptions/clash.yaml" << EOF
proxies:
  - name: Hysteria2
    type: hysteria
    server: ${domain}
    port: ${port}
    auth_str: ${password}
    up: "20 Mbps"
    down: "100 Mbps"
    tls:
      sni: ${domain}
      insecure: true
EOF
    
    # 生成V2Ray配置
    cat > "${CONFIG_DIR}/subscriptions/v2ray.json" << EOF
{
  "v": "2",
  "ps": "Hysteria2",
  "add": "${domain}",
  "port": "${port}",
  "id": "${password}",
  "aid": "0",
  "net": "hysteria",
  "type": "none",
  "host": "",
  "path": "",
  "tls": "tls",
  "sni": "${domain}",
  "allowInsecure": true
}
EOF
    
    log_success "订阅配置生成完成"
    log_info "订阅文件位置: ${CONFIG_DIR}/subscriptions/"
}

# ==================== 安装主流程 ====================
install_hysteria() {
    local domain=${1:-""}
    
    log_info "开始安装Hysteria 2 (融合版)..."
    
    # 检查系统
    check_root
    detect_os
    
    # 安装依赖
    install_dependencies
    
    # 系统优化
    optimize_system
    
    # 创建目录
    mkdir -p "$HYSTERIA_DIR" "$CONFIG_DIR" "$CERT_DIR" "$BACKUP_DIR" "$LOG_DIR"
    
    # 下载Hysteria
    download_hysteria
    
    # 设置证书
    domain=$(setup_certificates "$domain")
    
    # 生成配置
    generate_config "$DEFAULT_PORT" "$DEFAULT_PASSWORD" "$domain" "$DEFAULT_BW_UP" "$DEFAULT_BW_DOWN" "$DEFAULT_DNS"
    
    # 设置服务
    setup_service
    
    # 启动服务
    if start_service; then
        # 设置快捷命令
        setup_shortcut
        
        # 生成订阅
        generate_subscription "$DEFAULT_PORT" "$DEFAULT_PASSWORD" "$domain"
        
        # 显示安装信息
        show_installation_info "$domain"
        
        log_success "安装完成！"
        log_info "现在你可以使用 'hy2' 命令管理Hysteria服务"
    else
        log_error "安装失败，请检查错误信息"
        exit 1
    fi
}

# ==================== 安装信息 ====================
show_installation_info() {
    local domain=${1:-hysteria.local}
    local port=${DEFAULT_PORT}
    local password=${DEFAULT_PASSWORD}
    
    echo ""
    echo "======================================"
    echo "Hysteria 2 安装完成！"
    echo "======================================"
    echo ""
    echo "📊 配置信息:"
    echo "  端口: ${port}"
    echo "  密码: ${password}"
    echo "  域名: $domain"
    if [[ "$domain" == *"local"* ]]; then
        echo "  证书: 自签名 (客户端需设置 insecure: true)"
    else
        echo "  证书: Let's Encrypt"
    fi
    echo "  上行带宽: ${DEFAULT_BW_UP} Mbps"
    echo "  下行带宽: ${DEFAULT_BW_DOWN} Mbps"
    echo ""
    echo "📁 文件位置:"
    echo "  程序: /usr/local/bin/hysteria"
    echo "  服务器配置: ${CONFIG_DIR}/server.yaml"
    echo "  客户端配置: ${CONFIG_DIR}/client.yaml"
    echo "  证书: ${CERT_DIR}/"
    echo "  订阅配置: ${CONFIG_DIR}/subscriptions/"
    echo "  日志: ${LOG_DIR}/hysteria.log"
    echo ""
    echo "🔧 快捷命令:"
    echo "  hy2 start     - 启动服务"
    echo "  hy2 stop      - 停止服务"
    echo "  hy2 restart   - 重启服务"
    echo "  hy2 status    - 查看状态"
    echo "  hy2 logs      - 查看日志"
    echo "  hy2 config    - 编辑配置"
    echo "  hy2 client    - 查看客户端配置"
    echo "  hy2 qr        - 生成二维码"
    echo "  hy2 test      - 测试配置"
    echo "  hy2 uninstall - 卸载服务"
    echo ""
    echo "🌐 连接信息:"
    local PUBLIC_IP=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "获取失败")
    echo "  服务器地址: ${PUBLIC_IP}:${port}"
    echo ""
    echo "📱 客户端使用:"
    echo "  1. 复制客户端配置到客户端设备"
    echo "  2. 如果使用自签名证书，设置 insecure: true"
    echo "  3. 启动Hysteria客户端"
    echo ""
    echo "💡 小贴士:"
    echo "  - 查看实时日志: hy2 logs"
    echo "  - 修改配置: hy2 config"
    echo "  - 生成二维码: hy2 qr"
    echo "  - 测试配置: hy2 test"
    echo "  - 卸载服务: hy2 uninstall"
    echo ""
    echo "======================================"
}

# ==================== 卸载功能 ====================
uninstall_hysteria() {
    log_info "开始卸载Hysteria 2..."
    
    read -p "确定要卸载Hysteria吗? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        exit 0
    fi
    
    log_info "停止服务..."
    systemctl stop hysteria 2>/dev/null || true
    systemctl disable hysteria 2>/dev/null || true
    
    log_info "删除文件..."
    rm -f /usr/local/bin/hysteria
    rm -f /etc/systemd/system/hysteria.service
    rm -f /usr/local/bin/hy2
    rm -rf "$HYSTERIA_DIR"
    
    systemctl daemon-reload
    
    log_success "卸载完成"
}

# ==================== 主函数 ====================
main() {
    # 解析参数
    local domain=""
    local uninstall=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --domain)
                domain="$2"
                shift 2
                ;;
            --uninstall)
                uninstall=true
                shift
                ;;
            --help)
                echo "使用说明:"
                echo "  bash $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --domain DOMAIN    SSL证书域名 (可选)"
                echo "  --uninstall        卸载Hysteria"
                echo "  --help             显示帮助信息"
                echo ""
                echo "示例:"
                echo "  # 一键安装"
                echo "  bash $0"
                echo ""
                echo "  # 自定义域名安装"
                echo "  bash $0 --domain your-domain.com"
                echo ""
                echo "  # 卸载"
                echo "  bash $0 --uninstall"
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$uninstall" = true ]; then
        uninstall_hysteria
    else
        install_hysteria "$domain"
    fi
}

# ==================== 脚本入口 ====================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi