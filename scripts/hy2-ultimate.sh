#!/bin/bash

# 喵哥Hysteria 2一键安装脚本 - 终极简化版
# 一句话安装：wget -O hy.sh https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键hy安装脚本_v2.0.sh && bash hy.sh

# 快速安装命令（推荐）
# bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_终极版.sh)

# 带参数安装示例
# bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_终极版.sh) \
#   --port 443 --password auto --domain your-domain.com --auto

set -e

# ==================== 配置变量 ====================
SCRIPT_NAME="喵哥Hysteria一键安装"
SCRIPT_VERSION="3.0.0"
HYSTERIA_DIR="/root/hysteria"
CONFIG_FILE="${HYSTERIA_DIR}/config.yaml"
CLIENT_CONFIG="${HYSTERIA_DIR}/client.yaml"
LOG_FILE="/var/log/hysteria_install.log"
BACKUP_DIR="/root/hysteria_backup"

# 默认配置
DEFAULT_PORT=443
DEFAULT_PASSWORD=$(openssl rand -base64 16 | tr -d '=' | tr -d '+' | tr -d '/' | head -c 16)
DEFAULT_BW_UP=100
DEFAULT_BW_DOWN=20
DEFAULT_DNS="1.1.1.1"

# ==================== 颜色输出 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✅${NC} $1"; }
log_info() { echo -e "${BLUE}ℹ️${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠️${NC} $1"; }
log_error() { echo -e "${RED}❌${NC} $1"; }

# ==================== 参数解析 ====================
parse_args() {
    # 支持环境变量配置
    PORT=${PORT:-$DEFAULT_PORT}
    PASSWORD=${PASSWORD:-$DEFAULT_PASSWORD}
    BANDWIDTH_UP=${BANDWIDTH_UP:-$DEFAULT_BW_UP}
    BANDWIDTH_DOWN=${BANDWIDTH_DOWN:-$DEFAULT_BW_DOWN}
    DNS=${DNS:-$DEFAULT_DNS}
    DOMAIN=${DOMAIN:-""}
    AUTO=${AUTO:-false}
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --port)
                PORT="$2"
                shift 2
                ;;
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --domain)
                DOMAIN="$2"
                shift 2
                ;;
            --up-bw)
                BANDWIDTH_UP="$2"
                shift 2
                ;;
            --down-bw)
                BANDWIDTH_DOWN="$2"
                shift 2
                ;;
            --dns)
                DNS="$2"
                shift 2
                ;;
            --auto)
                AUTO=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果是自动模式，使用默认值
    if [ "$AUTO" = true ]; then
        log_info "自动模式：使用默认配置"
        PASSWORD=$DEFAULT_PASSWORD
        if [ -z "$DOMAIN" ]; then
            # 尝试获取服务器IP作为域名
            DOMAIN=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "hysteria.local")
        fi
    fi
}

show_help() {
    echo "使用说明:"
    echo "  bash $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --port PORT           监听端口 (默认: 443)"
    echo "  --password PASSWORD   认证密码 (默认: 自动生成)"
    echo "  --domain DOMAIN       SSL证书域名 (可选)"
    echo "  --up-bw MBPS          上行带宽 (默认: 100)"
    echo "  --down-bw MBPS        下行带宽 (默认: 20)"
    echo "  --dns DNS             DNS服务器 (默认: 1.1.1.1)"
    echo "  --auto                自动模式 (使用所有默认值)"
    echo "  --help                显示帮助信息"
    echo ""
    echo "环境变量配置:"
    echo "  PORT=443 PASSWORD=auto DOMAIN=your.com bash $0"
    echo ""
    echo "示例:"
    echo "  # 一键自动安装"
    echo "  bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_终极版.sh) --auto"
    echo ""
    echo "  # 自定义安装"
    echo "  bash $0 --port 443 --password mypass --domain your-domain.com"
    echo ""
    echo "  # 使用环境变量"
    echo "  PORT=443 PASSWORD=auto DOMAIN=your-domain.com AUTO=true bash $0"
}

# ==================== 核心功能 ====================
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查root权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        log_info "使用方法: sudo bash $0"
        exit 1
    fi
    
    # 检查系统类型
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        case $OS in
            ubuntu|debian|centos|rhel|fedora|arch)
                log_success "支持的系统: $OS"
                ;;
            *)
                log_warn "可能不支持的系统: $OS"
                ;;
        esac
    fi
    
    # 检查架构
    case $(uname -m) in
        x86_64|aarch64|armv7l)
            log_success "支持的架构: $(uname -m)"
            ;;
        *)
            log_error "不支持的架构: $(uname -m)"
            exit 1
            ;;
    esac
    
    # 检查网络
    if ! check_network_quick; then
        log_warn "网络连接可能有问题，继续安装..."
    fi
    
    log_success "系统要求检查通过"
}

check_network_quick() {
    # 快速网络检查
    if ! curl -s --connect-timeout 5 https://api.github.com > /dev/null; then
        log_warn "GitHub连接失败"
        return 1
    fi
    
    if ! curl -s --connect-timeout 5 https://acme-v02.api.letsencrypt.org/directory > /dev/null; then
        log_warn "Let's Encrypt连接失败"
        return 1
    fi
    
    return 0
}

install_dependencies() {
    log_info "安装系统依赖..."
    
    case $OS in
        ubuntu|debian)
            apt update > /dev/null 2>&1
            apt install -y curl wget unzip socat cron > /dev/null 2>&1
            ;;
        centos|rhel|fedora)
            yum update -y > /dev/null 2>&1
            yum install -y curl wget unzip socat cronie > /dev/null 2>&1
            ;;
        arch)
            pacman -Sy --noconfirm curl wget unzip socat cronie > /dev/null 2>&1
            ;;
    esac
    
    log_success "系统依赖安装完成"
}

get_latest_version() {
    local version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
    echo "${version#v}"
}

download_hysteria() {
    local version=$(get_latest_version)
    local arch=$(uname -m)
    
    case $arch in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="arm" ;;
    esac
    
    log_info "下载Hysteria v${version} for ${arch}..."
    
    local url="https://github.com/apernet/hysteria/releases/download/v${version}/hysteria-linux-${arch}"
    
    if ! curl -Lo /tmp/hysteria "$url" > /dev/null 2>&1; then
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

setup_directory() {
    log_info "创建配置目录..."
    
    mkdir -p "$HYSTERIA_DIR"
    mkdir -p "$BACKUP_DIR"
    
    log_success "目录创建完成: $HYSTERIA_DIR"
}

generate_server_config() {
    log_info "生成服务器配置..."
    
    # 验证端口
    if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
        log_error "无效的端口: $PORT"
        exit 1
    fi
    
    # 验证密码
    if [ ${#PASSWORD} -lt 8 ]; then
        log_error "密码长度至少8个字符"
        exit 1
    fi
    
    cat > "$CONFIG_FILE" << EOF
# Hysteria 2 Server Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

listen: :${PORT}

tls:
  cert: ${HYSTERIA_DIR}/fullchain.cer
  key: ${HYSTERIA_DIR}/private.key

bandwidth:
  up: ${BANDWIDTH_UP} mbps
  down: ${BANDWIDTH_DOWN} mbps

auth:
  type: password
  password: ${PASSWORD}

resolver:
  type: https
  https:
    addr: ${DNS}:443
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
  file: ${HYSTERIA_DIR}/hysteria.log
EOF
    
    chmod 600 "$CONFIG_FILE"
    log_success "服务器配置已生成"
}

generate_client_config() {
    log_info "生成客户端配置..."
    
    # 如果没有域名，使用服务器IP
    if [ -z "$DOMAIN" ]; then
        DOMAIN=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "hysteria.local")
    fi
    
    cat > "$CLIENT_CONFIG" << EOF
# Hysteria 2 Client Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

server: "${DOMAIN}:${PORT}"

auth: ${PASSWORD}

tls:
  sni: ${DOMAIN}
  insecure: false

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
    
    chmod 600 "$CLIENT_CONFIG"
    log_success "客户端配置已生成"
    log_info "请保存好客户端配置: $CLIENT_CONFIG"
}

setup_ssl_certificate() {
    if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "hysteria.local" ]; then
        log_warn "未配置域名，生成自签名证书"
        generate_self_signed_cert
        return
    fi
    
    log_info "申请Let's Encrypt证书 for $DOMAIN..."
    
    # 检查是否已安装acme.sh
    if [ ! -f ~/.acme.sh/acme.sh ]; then
        log_info "安装acme.sh..."
        curl https://get.acme.sh | sh > /dev/null 2>&1
        source ~/.bashrc
    fi
    
    # 停止可能占用80端口的服务
    systemctl stop nginx 2>/dev/null || true
    systemctl stop httpd 2>/dev/null || true
    
    # 申请证书
    if ~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone -k ec-256 --server letsencrypt > /dev/null 2>&1; then
        # 安装证书
        if ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
            --key-file "${HYSTERIA_DIR}/private.key" \
            --fullchain-file "${HYSTERIA_DIR}/fullchain.cer" \
            --ecc > /dev/null 2>&1; then
            chmod 600 "${HYSTERIA_DIR}/private.key"
            chmod 644 "${HYSTERIA_DIR}/fullchain.cer"
            log_success "SSL证书申请成功"
            return 0
        fi
    fi
    
    # 证书申请失败，使用自签名证书
    log_warn "SSL证书申请失败，使用自签名证书"
    generate_self_signed_cert
}

generate_self_signed_cert() {
    log_info "生成自签名证书..."
    
    openssl req -x509 -newkey rsa:4096 -keyout "${HYSTERIA_DIR}/private.key" \
        -out "${HYSTERIA_DIR}/fullchain.cer" -days 365 -nodes \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=${DOMAIN:-hysteria.local}" > /dev/null 2>&1
    
    chmod 600 "${HYSTERIA_DIR}/private.key"
    chmod 644 "${HYSTERIA_DIR}/fullchain.cer"
    
    log_warn "已生成自签名证书，客户端需要设置 insecure: true"
}

setup_systemd_service() {
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

ExecStart=/usr/local/bin/hysteria server -c /root/hysteria/config.yaml --log-level debug
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
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet hysteria; then
        log_success "Hysteria服务启动成功"
        
        # 检查端口监听
        if netstat -tuln | grep -q ":${PORT} "; then
            log_success "端口 ${PORT} 监听正常"
        else
            log_warn "端口 ${PORT} 可能未监听，请检查配置"
        fi
        
        return 0
    else
        log_error "Hysteria服务启动失败"
        log_error "请检查日志: journalctl -u hysteria -n 50"
        return 1
    fi
}

show_installation_summary() {
    echo ""
    echo "======================================"
    echo "Hysteria 2 安装完成！"
    echo "======================================"
    echo ""
    echo "📊 配置信息:"
    echo "  端口: ${PORT}"
    echo "  密码: ${PASSWORD}"
    if [ -n "$DOMAIN" ] && [ "$DOMAIN" != "hysteria.local" ]; then
        echo "  域名: $DOMAIN"
    else
        echo "  证书: 自签名 (客户端需设置 insecure: true)"
    fi
    echo "  上行带宽: ${BANDWIDTH_UP} Mbps"
    echo "  下行带宽: ${BANDWIDTH_DOWN} Mbps"
    echo ""
    echo "📁 文件位置:"
    echo "  程序: /usr/local/bin/hysteria"
    echo "  服务器配置: $CONFIG_FILE"
    echo "  客户端配置: $CLIENT_CONFIG"
    echo "  证书: $HYSTERIA_DIR/fullchain.cer"
    echo "  私钥: $HYSTERIA_DIR/private.key"
    echo ""
    echo "🔧 常用命令:"
    echo "  启动服务: systemctl start hysteria"
    echo "  停止服务: systemctl stop hysteria"
    echo "  重启服务: systemctl restart hysteria"
    echo "  查看状态: systemctl status hysteria"
    echo "  查看日志: journalctl -u hysteria -f"
    echo ""
    echo "🌐 连接信息:"
    local PUBLIC_IP=$(curl -s http://ipv4.icanhazip.com 2>/dev/null || echo "获取失败")
    echo "  服务器地址: ${PUBLIC_IP}:${PORT}"
    echo ""
    echo "💡 温馨提示:"
    echo "  1. 请保存好客户端配置文件"
    echo "  2. 如果使用自签名证书，客户端需要设置 insecure: true"
    echo "  3. 如需修改配置，请编辑 $CONFIG_FILE 后重启服务"
    echo "  4. 查看实时日志: tail -f $HYSTERIA_DIR/hysteria.log"
    echo ""
    echo "======================================"
}

# ==================== 主安装流程 ====================
main() {
    echo "🚀 开始安装Hysteria 2 - 终极简化版"
    echo ""
    
    # 解析参数
    parse_args "$@"
    
    # 检查要求
    check_requirements
    
    # 安装依赖
    install_dependencies
    
    # 创建目录
    setup_directory
    
    # 下载Hysteria
    download_hysteria
    
    # 生成配置
    generate_server_config
    generate_client_config
    
    # 设置证书
    setup_ssl_certificate
    
    # 配置服务
    setup_systemd_service
    
    # 启动服务
    if start_service; then
        show_installation_summary
        
        echo ""
        log_success "安装完成！"
        log_info "现在你可以使用Hysteria 2了！"
        echo ""
        log_info "如果遇到问题，请查看日志: journalctl -u hysteria"
    else
        log_error "安装失败，请检查错误信息"
        exit 1
    fi
}

# ==================== 卸载功能 ====================
uninstall() {
    echo "🔄 开始卸载Hysteria 2..."
    
    read -p "确定要卸载Hysteria吗? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "取消卸载"
        exit 0
    fi
    
    log_info "停止服务..."
    systemctl stop hysteria 2>/dev/null || true
    systemctl disable hysteria 2>/dev/null || true
    
    log_info "删除文件..."
    rm -f /usr/local/bin/hysteria
    rm -f /etc/systemd/system/hysteria.service
    
    read -p "是否删除配置文件? [y/N]: " DEL_CONFIG
    if [[ "$DEL_CONFIG" =~ ^[Yy]$ ]]; then
        rm -rf "$HYSTERIA_DIR"
        rm -rf "$BACKUP_DIR"
        log_info "配置文件已删除"
    fi
    
    systemctl daemon-reload
    
    log_success "卸载完成"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 检查是否是卸载模式
    if [ "$1" = "--uninstall" ]; then
        uninstall
    else
        main "$@"
    fi
fi