#!/bin/bash

# 喵哥一键Hysteria 2安装脚本
# 优化完善的Hysteria 2一键安装脚本
# 作者：喵哥AI助手

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# 检查root权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        log_error "无法检测操作系统类型"
        exit 1
    fi

    case $OS in
        ubuntu|debian)
            PACKAGE_MANAGER="apt"
            ;;
        centos|rhel|fedora)
            PACKAGE_MANAGER="yum"
            ;;
        arch)
            PACKAGE_MANAGER="pacman"
            ;;
        *)
            log_error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac

    log_info "检测到操作系统: $OS $VER"
}

# 安装依赖
install_dependencies() {
    log_info "安装必要依赖..."
    
    case $PACKAGE_MANAGER in
        apt)
            apt update
            apt install -y curl wget unzip socat cron
            ;;
        yum)
            yum update -y
            yum install -y curl wget unzip socat cronie
            ;;
        pacman)
            pacman -Sy --noconfirm curl wget unzip socat cronie
            ;;
    esac
    
    log_info "依赖安装完成"
}

# 获取最新版本
get_latest_version() {
    LATEST_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "${LATEST_VERSION#v}"  # 移除v前缀
}

# 检测系统架构
detect_arch() {
    case $(uname -m) in
        x86_64)
            echo "amd64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            log_error "不支持的架构: $(uname -m)"
            exit 1
            ;;
    esac
}

# 下载Hysteria
download_hysteria() {
    local version=$1
    local arch=$2
    
    log_info "下载Hysteria ${version} for ${arch}..."
    
    DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/v${version}/hysteria-linux-${arch}"
    
    if ! curl -Lo /tmp/hysteria "${DOWNLOAD_URL}"; then
        log_error "下载失败，请检查网络连接"
        exit 1
    fi
    
    chmod +x /tmp/hysteria
    mv -f /tmp/hysteria /usr/local/bin/hysteria
    
    if ! hysteria version > /dev/null 2>&1; then
        log_error "Hysteria安装失败"
        exit 1
    fi
    
    log_info "Hysteria安装成功: $(hysteria version)"
}

# 生成随机密码
generate_password() {
    openssl rand -base64 16
}

# 交互式配置
interactive_config() {
    log_info "开始交互式配置..."
    
    # 端口配置
    read -p "请输入监听端口 [默认: 443]: " PORT
    PORT=${PORT:-443}
    
    # 密码配置
    read -p "是否自动生成密码? [Y/n]: " AUTO_PASSWORD
    if [[ "$AUTO_PASSWORD" =~ ^[Nn]$ ]]; then
        read -p "请设置认证密码: " PASSWORD
    else
        PASSWORD=$(generate_password)
        log_info "已生成随机密码: $PASSWORD"
    fi
    
    # 带宽配置
    read -p "请输入上行带宽 [默认: 100 mbps]: " BANDWIDTH_UP
    BANDWIDTH_UP=${BANDWIDTH_UP:-100}
    
    read -p "请输入下行带宽 [默认: 20 mbps]: " BANDWIDTH_DOWN
    BANDWIDTH_DOWN=${BANDWIDTH_DOWN:-20}
    
    # DNS配置
    read -p "请输入DNS服务器 [默认: 1.1.1.1]: " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-1.1.1.1}
    
    # 域名配置（用于SNI）
    read -p "请输入域名（用于SSL证书）: " DOMAIN
    
    # 创建配置目录
    mkdir -p /root/hysteria
    
    # 生成配置文件
    generate_server_config "$PORT" "$PASSWORD" "$BANDWIDTH_UP" "$BANDWIDTH_DOWN" "$DNS_SERVER" "$DOMAIN"
    
    # SSL证书处理
    if [ -n "$DOMAIN" ]; then
        setup_ssl_cert "$DOMAIN"
    else
        log_warn "未设置域名，将使用自签名证书"
        generate_self_signed_cert
    fi
    
    # 生成客户端配置
    generate_client_config "$PORT" "$PASSWORD" "$DOMAIN"
    
    log_info "配置完成"
}

# 生成服务端配置
generate_server_config() {
    local port=$1
    local password=$2
    local bandwidth_up=$3
    local bandwidth_down=$4
    local dns_server=$5
    local domain=$6
    
    cat > /root/hysteria/config.yaml << EOF
listen: :${port}

tls:
  cert: /root/hysteria/fullchain.cer
  key: /root/hysteria/private.key

bandwidth:
  up: ${bandwidth_up} mbps
  down: ${bandwidth_down} mbps

auth:
  type: password
  password: ${password}

resolver:
  type: https
  https:
    addr: ${dns_server}:443
    timeout: 10s

sniff:
  enable: true
  timeout: 2s

acl:
  inline:
    - reject(all, udp/443)
    - allow(any)

log:
  level: debug
  format: text
EOF

    log_info "服务端配置文件已生成: /root/hysteria/config.yaml"
}

# 生成客户端配置
generate_client_config() {
    local port=$1
    local password=$2
    local domain=$3
    
    if [ -z "$domain" ]; then
        # 如果没有域名，使用服务器IP
        SERVER_IP=$(curl -s http://ipv4.icanhazip.com)
        domain="$SERVER_IP"
    fi
    
    cat > /root/hysteria/client_config.yaml << EOF
server: "${domain}:${port}"

auth: ${password}

tls:
  sni: ${domain}
  insecure: false

bandwidth:
  up: 20 mbps
  down: 100 mbps

socks5:
  listen: 127.0.0.1:50000

log:
  level: info
  format: text
EOF

    log_info "客户端配置文件已生成: /root/hysteria/client_config.yaml"
    log_info "请将客户端配置文件复制到客户端使用"
}

# 安装acme.sh
install_acme() {
    if [ ! -f ~/.acme.sh/acme.sh ]; then
        log_info "安装acme.sh..."
        curl https://get.acme.sh | sh
        source ~/.bashrc
    fi
}

# 申请SSL证书
setup_ssl_cert() {
    local domain=$1
    
    log_info "开始申请SSL证书 for ${domain}..."
    
    install_acme
    
    # 创建证书目录
    mkdir -p /root/hysteria
    
    # 申请证书
    if ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --server letsencrypt; then
        # 安装证书
        ~/.acme.sh/acme.sh --install-cert -d "$domain" \
            --key-file /root/hysteria/private.key \
            --fullchain-file /root/hysteria/fullchain.cer \
            --ecc
        
        log_info "SSL证书申请成功"
    else
        log_error "SSL证书申请失败，将使用自签名证书"
        generate_self_signed_cert
    fi
}

# 生成自签名证书
generate_self_signed_cert() {
    log_info "生成自签名证书..."
    
    mkdir -p /root/hysteria
    
    openssl req -x509 -newkey rsa:4096 -keyout /root/hysteria/private.key \
        -out /root/hysteria/fullchain.cer -days 365 -nodes \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=hysteria.local"
    
    log_warn "已生成自签名证书，请注意客户端需要设置insecure: true"
}

# 配置系统服务
setup_systemd_service() {
    log_info "配置系统服务..."
    
    cat > /etc/systemd/system/hysteria.service << 'EOF'
[Unit]
Description=Hysteria 2 Server
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/hysteria
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/hysteria server -c /root/hysteria/config.yaml --log-level debug
Restart=on-failure
RestartSec=10
LimitNPROC=512
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_info "系统服务配置完成"
}

# 启动服务
start_service() {
    log_info "启动Hysteria服务..."
    
    systemctl enable hysteria
    systemctl start hysteria
    
    if systemctl is-active --quiet hysteria; then
        log_info "Hysteria服务启动成功"
        log_info "服务状态: systemctl status hysteria"
        log_info "查看日志: journalctl -u hysteria -f"
    else
        log_error "Hysteria服务启动失败"
        journalctl -u hysteria -n 50 --no-pager
        exit 1
    fi
}

# 查看服务状态
show_status() {
    log_info "Hysteria服务状态:"
    systemctl status hysteria --no-pager
    
    log_info "最近日志:"
    journalctl -u hysteria -n 20 --no-pager
    
    log_info "配置信息:"
    echo "配置文件: /root/hysteria/config.yaml"
    echo "客户端配置: /root/hysteria/client_config.yaml"
    echo "程序位置: $(which hysteria)"
    echo "版本: $(hysteria version)"
}

# 卸载功能
uninstall() {
    log_warn "准备卸载Hysteria..."
    
    read -p "确定要卸载Hysteria吗? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        return
    fi
    
    log_info "停止并禁用服务..."
    systemctl stop hysteria 2>/dev/null || true
    systemctl disable hysteria 2>/dev/null || true
    
    log_info "删除文件..."
    rm -f /usr/local/bin/hysteria
    rm -f /etc/systemd/system/hysteria.service
    rm -rf /root/hysteria
    rm -rf ~/.acme.sh
    
    systemctl daemon-reload
    
    log_info "Hysteria卸载完成"
}

# 显示菜单
show_menu() {
    clear
    echo -e "${GREEN}喵哥一键Hysteria 2管理脚本${NC}"
    echo "================================"
    echo "1. 安装Hysteria 2"
    echo "2. 查看服务状态"
    echo "3. 重启服务"
    echo "4. 查看日志"
    echo "5. 重新配置"
    echo "6. 卸载Hysteria"
    echo "7. 退出"
    echo "================================"
}

# 主函数
main() {
    check_root
    check_system
    
    while true; do
        show_menu
        read -p "请选择操作 [1-7]: " CHOICE
        
        case $CHOICE in
            1)
                log_info "开始安装Hysteria 2..."
                install_dependencies
                
                VERSION=$(get_latest_version)
                ARCH=$(detect_arch)
                
                download_hysteria "$VERSION" "$ARCH"
                interactive_config
                setup_systemd_service
                start_service
                
                log_info "安装完成！"
                show_status
                ;;
            2)
                show_status
                ;;
            3)
                log_info "重启Hysteria服务..."
                systemctl restart hysteria
                log_info "服务已重启"
                show_status
                ;;
            4)
                log_info "查看实时日志 (按Ctrl+C退出)..."
                journalctl -u hysteria -f
                ;;
            5)
                log_info "重新配置..."
                interactive_config
                systemctl restart hysteria
                log_info "配置已更新并重启服务"
                show_status
                ;;
            6)
                uninstall
                ;;
            7)
                log_info "感谢使用喵哥一键Hysteria安装脚本！"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                ;;
        esac
        
        echo
        read -p "按Enter键继续..."
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi