#!/bin/bash

# 喵哥一键Hysteria 2安装脚本 v2.0
# 优化完善的Hysteria 2一键安装脚本
# 作者：喵哥AI助手

set -e

# ==================== 全局配置 ====================
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="喵哥一键Hysteria安装脚本"
HYSTERIA_DIR="/root/hysteria"
BACKUP_DIR="/root/hysteria_backup"
LOG_FILE="/var/log/hysteria_install.log"
CONFIG_FILE="${HYSTERIA_DIR}/config.yaml"
CLIENT_CONFIG_FILE="${HYSTERIA_DIR}/client_config.yaml"

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==================== 日志系统 ====================
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        INFO)
            echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        DEBUG)
            echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
        *)
            echo "[$level] ${timestamp} - $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

log_info() { log "INFO" "$1"; }
log_warn() { log "WARN" "$1"; }
log_error() { log "ERROR" "$1"; }
log_debug() { log "DEBUG" "$1"; }

# ==================== 工具函数 ====================
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root权限运行此脚本"
        exit 1
    fi
}

# 增强的输入验证函数
validate_port() {
    local port=$1
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        log_error "端口必须是数字"
        return 1
    fi
    
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "端口必须在1-65535范围内"
        return 1
    fi
    
    return 0
}

validate_password() {
    local password=$1
    local min_length=${2:-12}
    
    if [ ${#password} -lt "$min_length" ]; then
        log_error "密码长度至少需要${min_length}个字符"
        return 1
    fi
    
    if ! [[ "$password" =~ [0-9] ]] || ! [[ "$password" =~ [a-zA-Z] ]]; then
        log_error "密码必须包含数字和字母"
        return 1
    fi
    
    return 0
}

validate_domain() {
    local domain=$1
    
    if [ -n "$domain" ]; then
        if ! [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            log_error "域名格式无效"
            return 1
        fi
    fi
    
    return 0
}

validate_bandwidth() {
    local bandwidth=$1
    local direction=$2
    
    if ! [[ "$bandwidth" =~ ^[0-9]+$ ]]; then
        log_error "$direction 带宽必须是数字"
        return 1
    fi
    
    if [ "$bandwidth" -lt 1 ] || [ "$bandwidth" -gt 10000 ]; then
        log_error "$direction 带宽必须在1-10000范围内"
        return 1
    fi
    
    return 0
}

# 增强的网络检测功能
check_network() {
    log_info "检查网络连接..."
    
    local max_retries=3
    local retry_count=0
    local network_ok=false
    
    while [ $retry_count -lt $max_retries ] && [ "$network_ok" = false ]; do
        # 测试GitHub连接
        log_debug "测试GitHub连接..."
        if curl -s --connect-timeout 10 --max-time 15 https://api.github.com > /dev/null 2>&1; then
            log_info "GitHub连接正常"
        else
            log_warn "GitHub连接失败，尝试重试..."
            retry_count=$((retry_count + 1))
            sleep 2
            continue
        fi
        
        # 测试Let's Encrypt连接
        log_debug "测试Let's Encrypt连接..."
        if curl -s --connect-timeout 10 --max-time 15 https://acme-v02.api.letsencrypt.org/directory > /dev/null 2>&1; then
            log_info "Let's Encrypt连接正常"
        else
            log_warn "Let's Encrypt连接失败，证书申请可能受影响"
        fi
        
        # 测试DNS解析
        log_debug "测试DNS解析..."
        if nslookup google.com > /dev/null 2>&1 || dig google.com > /dev/null 2>&1; then
            log_info "DNS解析正常"
        else
            log_warn "DNS解析可能有问题"
        fi
        
        # 测试端口连通性
        log_debug "测试常用端口连通性..."
        if nc -zv -w 5 1.1.1.1 443 2>/dev/null || timeout 5 bash -c 'cat < /dev/null > /dev/tcp/1.1.1/443' 2>/dev/null; then
            log_info "HTTPS端口连通性正常"
        else
            log_warn "HTTPS端口连通性可能有问题"
        fi
        
        network_ok=true
    done
    
    if [ "$network_ok" = false ]; then
        log_error "网络连接检查失败，请检查网络设置"
        return 1
    fi
    
    log_info "网络连接检查完成"
    return 0
}

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
    
    # 检查系统资源
    MEMORY=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    DISK=$(df / | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    
    if [ "$MEMORY" -lt 1 ]; then
        log_warn "系统内存较低: ${MEMORY}GB，建议至少1GB内存"
    fi
    
    if [ "$DISK" -lt 5 ]; then
        log_warn "系统磁盘空间较小: ${DISK}GB，建议至少5GB空间"
    fi
}

install_dependencies() {
    log_info "安装必要依赖..."
    
    case $PACKAGE_MANAGER in
        apt)
            apt update > /dev/null 2>&1
            apt install -y curl wget unzip socat cron iptables-persistent > /dev/null 2>&1
            ;;
        yum)
            yum update -y > /dev/null 2>&1
            yum install -y curl wget unzip socat cronie iptables-services > /dev/null 2>&1
            ;;
        pacman)
            pacman -Sy --noconfirm curl wget unzip socat cronie > /dev/null 2>&1
            ;;
    esac
    
    log_info "依赖安装完成"
}

# 获取最新版本
get_latest_version() {
    local max_retries=3
    local retry_count=0
    local version=""
    
    while [ $retry_count -lt $max_retries ]; do
        version=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4)
        if [ -n "$version" ]; then
            echo "${version#v}"  # 移除v前缀
            return 0
        fi
        retry_count=$((retry_count + 1))
        sleep 2
    done
    
    log_error "无法获取Hysteria最新版本，请检查网络连接"
    return 1
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

# 检查端口是否可用
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":${port} "; then
        return 1
    fi
    return 0
}

# 生成随机密码
generate_password() {
    local length=${1:-16}
    openssl rand -base64 "$length" | tr -d '=' | tr -d '+' | tr -d '/' | head -c "$length"
}

# 获取公网IP
get_public_ip() {
    curl -s http://ipv4.icanhazip.com
}

# 备份配置文件
backup_config() {
    if [ -f "$CONFIG_FILE" ]; then
        mkdir -p "$BACKUP_DIR"
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        cp "$CONFIG_FILE" "${BACKUP_DIR}/config_${timestamp}.yaml"
        log_info "配置文件已备份到: ${BACKUP_DIR}/config_${timestamp}.yaml"
    fi
}

# 恢复配置文件
restore_config() {
    if [ -d "$BACKUP_DIR" ]; then
        local latest_backup=$(ls -t "$BACKUP_DIR"/config_*.yaml 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            cp "$latest_backup" "$CONFIG_FILE"
            log_info "配置文件已恢复到: $latest_backup"
            return 0
        fi
    fi
    log_error "没有找到可恢复的配置文件"
    return 1
}

# ==================== Hysteria安装功能 ====================
download_hysteria() {
    local version=$1
    local arch=$2
    
    log_info "下载Hysteria ${version} for ${arch}..."
    
    DOWNLOAD_URL="https://github.com/apernet/hysteria/releases/download/v${version}/hysteria-linux-${arch}"
    
    # 检查是否已安装相同版本
    if [ -f "/usr/local/bin/hysteria" ]; then
        local installed_version=$(/usr/local/bin/hysteria version 2>/dev/null | head -1)
        if [ "$installed_version" = "v${version}" ]; then
            log_info "已安装相同版本: $installed_version"
            read -p "是否重新安装? [y/N]: " REINSTALL
            if [[ ! "$REINSTALL" =~ ^[Yy]$ ]]; then
                return 0
            fi
        fi
    fi
    
    # 下载并重试机制
    local max_retries=3
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        if curl -Lo /tmp/hysteria "${DOWNLOAD_URL}" && [ -f /tmp/hysteria ]; then
            chmod +x /tmp/hysteria
            
            # 验证文件完整性
            if file /tmp/hysteria | grep -q "ELF"; then
                mv -f /tmp/hysteria /usr/local/bin/hysteria
                
                if ! hysteria version > /dev/null 2>&1; then
                    log_error "Hysteria安装失败，程序无法运行"
                    return 1
                fi
                
                log_info "Hysteria安装成功: $(hysteria version)"
                return 0
            else
                rm -f /tmp/hysteria
                log_error "下载文件不是有效的可执行文件"
            fi
        fi
        
        retry_count=$((retry_count + 1))
        log_warn "下载失败，第${retry_count}次重试..."
        sleep 3
    done
    
    log_error "Hysteria下载失败，请检查网络连接"
    return 1
}

# ==================== 配置功能 ====================
interactive_config() {
    log_info "开始交互式配置..."
    
    # 备份现有配置
    backup_config
    
    # 端口配置
    while true; do
        read -p "请输入监听端口 [默认: 443]: " PORT
        PORT=${PORT:-443}
        
        if ! validate_port "$PORT"; then
            continue
        fi
        
        if ! check_port "$PORT"; then
            log_error "端口 $PORT 已被占用"
            read -p "是否继续使用此端口? [y/N]: " FORCE_PORT
            if [[ ! "$FORCE_PORT" =~ ^[Yy]$ ]]; then
                continue
            fi
        fi
        
        break
    done
    
    # 密码配置
    read -p "是否自动生成强密码? [Y/n]: " AUTO_PASSWORD
    if [[ "$AUTO_PASSWORD" =~ ^[Nn]$ ]]; then
        while true; do
            read -p "请设置认证密码: " PASSWORD
            if validate_password "$PASSWORD" 8; then
                break
            fi
        done
    else
        PASSWORD=$(generate_password 16)
        log_info "已生成随机密码: $PASSWORD"
        log_info "请保存好此密码，用于客户端连接"
    fi
    
    # 带宽配置
    while true; do
        read -p "请输入上行带宽 [默认: 100 mbps]: " BANDWIDTH_UP
        BANDWIDTH_UP=${BANDWIDTH_UP:-100}
        
        if validate_bandwidth "$BANDWIDTH_UP" "上行"; then
            break
        fi
    done
    
    while true; do
        read -p "请输入下行带宽 [默认: 20 mbps]: " BANDWIDTH_DOWN
        BANDWIDTH_DOWN=${BANDWIDTH_DOWN:-20}
        
        if validate_bandwidth "$BANDWIDTH_DOWN" "下行"; then
            break
        fi
    done
    
    # DNS配置
    read -p "请输入DNS服务器 [默认: 1.1.1.1]: " DNS_SERVER
    DNS_SERVER=${DNS_SERVER:-1.1.1.1}
    
    # 域名配置
    while true; do
        read -p "请输入域名（用于SSL证书，可选）: " DOMAIN
        
        if validate_domain "$DOMAIN"; then
            break
        fi
    done
    
    # 高级选项
    read -p "是否配置高级选项? [y/N]: " ADVANCED
    if [[ "$ADVANCED" =~ ^[Yy]$ ]]; then
        read -p "是否启用流量混淆? [y/N]: " ENABLE_OBFUSCATION
        read -p "是否启用访问控制列表? [y/N]: " ENABLE_ACL
    fi
    
    # 创建配置目录
    mkdir -p "$HYSTERIA_DIR"
    
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

generate_server_config() {
    local port=$1
    local password=$2
    local bandwidth_up=$3
    local bandwidth_down=$4
    local dns_server=$5
    local domain=$6
    
    cat > "$CONFIG_FILE" << EOF
# Hysteria 2 Server Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

listen: :${port}

tls:
  cert: ${HYSTERIA_DIR}/fullchain.cer
  key: ${HYSTERIA_DIR}/private.key

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
  file: ${HYSTERIA_DIR}/hysteria.log
EOF

    chmod 600 "$CONFIG_FILE"
    log_info "服务端配置文件已生成: $CONFIG_FILE"
}

generate_client_config() {
    local port=$1
    local password=$2
    local domain=$3
    
    if [ -z "$domain" ]; then
        # 如果没有域名，使用服务器IP
        SERVER_IP=$(get_public_ip)
        domain="$SERVER_IP"
    fi
    
    cat > "$CLIENT_CONFIG_FILE" << EOF
# Hysteria 2 Client Configuration
# Generated by $SCRIPT_NAME v$SCRIPT_VERSION
# $(date)

server: "${domain}:${port}"

auth: ${password}

tls:
  sni: ${domain}
  insecure: false
  ca: ${HYSTERIA_DIR}/ca.cer

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

    chmod 600 "$CLIENT_CONFIG_FILE"
    log_info "客户端配置文件已生成: $CLIENT_CONFIG_FILE"
    log_info "请将客户端配置文件复制到客户端使用"
}

# ==================== SSL证书管理 ====================
install_acme() {
    if [ ! -f ~/.acme.sh/acme.sh ]; then
        log_info "安装acme.sh..."
        curl https://get.acme.sh | sh
        source ~/.bashrc
        # 设置默认CA为Let's Encrypt
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    fi
}

renew_certificates() {
    log_info "检查SSL证书更新..."
    if [ -f ~/.acme.sh/acme.sh ]; then
        ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null 2>&1
        log_info "证书更新检查完成"
    fi
}

setup_ssl_cert() {
    local domain=$1
    
    log_info "开始申请SSL证书 for ${domain}..."
    
    install_acme
    
    # 创建证书目录
    mkdir -p "$HYSTERIA_DIR"
    
    # 停止可能占用80端口的服务
    if systemctl is-active --quiet nginx; then
        systemctl stop nginx
        log_info "已临时停止Nginx服务"
    fi
    
    if systemctl is-active --quiet httpd; then
        systemctl stop httpd
        log_info "已临时停止Apache服务"
    fi
    
    # 申请证书（重试机制）
    local max_retries=3
    local retry_count=0
    local success=false
    
    while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
        if ~/.acme.sh/acme.sh --issue -d "$domain" --standalone -k ec-256 --server letsencrypt --log "$LOG_FILE"; then
            # 安装证书
            if ~/.acme.sh/acme.sh --install-cert -d "$domain" \
                --key-file "${HYSTERIA_DIR}/private.key" \
                --fullchain-file "${HYSTERIA_DIR}/fullchain.cer" \
                --ecc; then
                # 设置权限
                chmod 600 "${HYSTERIA_DIR}/private.key"
                chmod 644 "${HYSTERIA_DIR}/fullchain.cer"
                success=true
                log_info "SSL证书申请成功"
            else
                log_error "证书安装失败"
            fi
        else
            log_error "证书申请失败，第$((retry_count + 1))次重试..."
        fi
        
        retry_count=$((retry_count + 1))
        sleep 5
    done
    
    # 重启之前停止的服务
    if ! systemctl is-active --quiet nginx && [ -f /etc/systemd/system/nginx.service ]; then
        systemctl start nginx
    fi
    
    if ! systemctl is-active --quiet httpd && [ -f /etc/systemd/system/httpd.service ]; then
        systemctl start httpd
    fi
    
    if [ "$success" = false ]; then
        log_error "SSL证书申请失败，将使用自签名证书"
        generate_self_signed_cert
    fi
}

generate_self_signed_cert() {
    log_info "生成自签名证书..."
    
    mkdir -p "$HYSTERIA_DIR"
    
    # 生成CA
    openssl req -x509 -newkey rsa:4096 -keyout "${HYSTERIA_DIR}/ca.key" \
        -out "${HYSTERIA_DIR}/ca.cer" -days 3650 -nodes \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=Hysteria CA" > /dev/null 2>&1
    
    # 生成服务器证书
    openssl req -newkey rsa:4096 -keyout "${HYSTERIA_DIR}/private.key" \
        -out "${HYSTERIA_DIR}/server.csr" -nodes \
        -subj "/C=CN/ST=State/L=City/O=Organization/CN=hysteria.local" > /dev/null 2>&1
    
    openssl x509 -req -in "${HYSTERIA_DIR}/server.csr" -CA "${HYSTERIA_DIR}/ca.cer" \
        -CAkey "${HYSTERIA_DIR}/ca.key" -CAcreateserial \
        -out "${HYSTERIA_DIR}/fullchain.cer" -days 365 > /dev/null 2>&1
    
    # 清理临时文件
    rm -f "${HYSTERIA_DIR}/server.csr" "${HYSTERIA_DIR}/ca.srl"
    
    # 设置权限
    chmod 600 "${HYSTERIA_DIR}/private.key"
    chmod 644 "${HYSTERIA_DIR}/fullchain.cer" "${HYSTERIA_DIR}/ca.cer"
    
    log_warn "已生成自签名证书，请注意客户端需要设置 insecure: true"
}

# ==================== 系统服务管理 ====================
setup_systemd_service() {
    log_info "配置系统服务..."
    
    # 检查是否已存在服务
    if [ -f /etc/systemd/system/hysteria.service ]; then
        log_info "检测到已存在的服务配置，正在更新..."
    fi
    
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
    log_info "系统服务配置完成"
}

start_service() {
    log_info "启动Hysteria服务..."
    
    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        return 1
    fi
    
    # 检查证书
    if [ ! -f "${HYSTERIA_DIR}/fullchain.cer" ] || [ ! -f "${HYSTERIA_DIR}/private.key" ]; then
        log_error "SSL证书不存在，请检查证书配置"
        return 1
    fi
    
    # 启用并启动服务
    systemctl enable hysteria
    systemctl start hysteria
    
    # 等待服务启动
    sleep 3
    
    if systemctl is-active --quiet hysteria; then
        log_info "Hysteria服务启动成功"
        log_info "服务状态: systemctl status hysteria"
        log_info "查看日志: journalctl -u hysteria -f"
        
        # 测试服务
        test_service
        return 0
    else
        log_error "Hysteria服务启动失败"
        log_error "错误日志:"
        journalctl -u hysteria -n 50 --no-pager | tee -a "$LOG_FILE"
        
        # 尝试手动启动以获取更多信息
        log_info "尝试手动启动以获取更多信息..."
        /usr/local/bin/hysteria server -c "$CONFIG_FILE" --log-level debug &
        local PID=$!
        sleep 3
        if kill -0 $PID 2>/dev/null; then
            log_info "手动启动成功，PID: $PID"
            kill $PID
        else
            log_error "手动启动也失败，请检查配置"
        fi
        
        return 1
    fi
}

test_service() {
    log_info "测试Hysteria服务..."
    
    # 等待服务完全启动
    sleep 5
    
    # 检查端口监听
    local port=$(grep "listen:" "$CONFIG_FILE" | awk '{print $2}' | cut -d: -f2)
    if netstat -tuln | grep -q ":${port} "; then
        log_info "端口 ${port} 监听正常"
    else
        log_warn "端口 ${port} 未监听，服务可能未正常运行"
    fi
    
    # 检查日志文件
    if [ -f "${HYSTERIA_DIR}/hysteria.log" ]; then
        log_info "日志文件已创建: ${HYSTERIA_DIR}/hysteria.log"
    else
        log_warn "日志文件未创建"
    fi
    
    log_info "服务测试完成"
}

# ==================== 更新功能 ====================
update_hysteria() {
    log_info "检查Hysteria更新..."
    
    if [ ! -f /usr/local/bin/hysteria ]; then
        log_error "Hysteria未安装，请先安装"
        return 1
    fi
    
    local current_version=$(/usr/local/bin/hysteria version 2>/dev/null | head -1)
    local latest_version=$(get_latest_version)
    
    if [ "$current_version" = "v${latest_version}" ]; then
        log_info "当前已是最新版本: $current_version"
        return 0
    fi
    
    log_info "发现新版本: $latest_version (当前: $current_version)"
    read -p "是否更新到最新版本? [y/N]: " UPDATE_CONFIRM
    
    if [[ ! "$UPDATE_CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "取消更新"
        return 0
    fi
    
    # 备份当前配置
    backup_config
    
    # 停止服务
    log_info "停止Hysteria服务..."
    systemctl stop hysteria
    
    # 下载新版本
    local arch=$(detect_arch)
    if download_hysteria "$latest_version" "$arch"; then
        # 重启服务
        log_info "重启Hysteria服务..."
        systemctl start hysteria
        
        if systemctl is-active --quiet hysteria; then
            log_info "Hysteria更新成功到版本: $latest_version"
            return 0
        else
            log_error "服务启动失败，更新回滚"
            restore_config
            systemctl start hysteria
            return 1
        fi
    else
        # 恢复服务
        log_info "恢复原服务..."
        systemctl start hysteria
        return 1
    fi
}

# ==================== 卸载功能 ====================
uninstall() {
    log_warn "准备卸载Hysteria..."
    
    read -p "确定要卸载Hysteria吗? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        log_info "取消卸载"
        return 0
    fi
    
    read -p "是否保留配置文件? [Y/n]: " KEEP_CONFIG
    read -p "是否保留SSL证书? [Y/n]: " KEEP_CERT
    
    log_info "停止并禁用服务..."
    systemctl stop hysteria 2>/dev/null || true
    systemctl disable hysteria 2>/dev/null || true
    
    log_info "删除文件..."
    rm -f /usr/local/bin/hysteria
    rm -f /etc/systemd/system/hysteria.service
    
    if [[ ! "$KEEP_CONFIG" =~ ^[Nn]$ ]]; then
        log_info "保留配置文件"
    else
        rm -rf "$HYSTERIA_DIR"
        rm -rf "$BACKUP_DIR"
    fi
    
    if [[ "$KEEP_CERT" =~ ^[Nn]$ ]] && [ -d "$HYSTERIA_DIR" ]; then
        rm -f "${HYSTERIA_DIR}/fullchain.cer" "${HYSTERIA_DIR}/private.key"
        log_info "删除SSL证书"
    fi
    
    rm -rf ~/.acme.sh
    
    systemctl daemon-reload
    
    log_info "Hysteria卸载完成"
}

# ==================== 状态查看 ====================
show_status() {
    log_info "Hysteria服务状态:"
    
    if [ -f /usr/local/bin/hysteria ]; then
        echo "程序版本: $(hysteria version)"
        echo "程序位置: $(which hysteria)"
    else
        log_error "Hysteria未安装"
        return 1
    fi
    
    echo ""
    echo "服务状态:"
    systemctl status hysteria --no-pager
    
    echo ""
    echo "配置信息:"
    echo "配置文件: $CONFIG_FILE"
    if [ -f "$CONFIG_FILE" ]; then
        echo "配置权限: $(stat -c "%a" "$CONFIG_FILE")"
        local port=$(grep "listen:" "$CONFIG_FILE" | awk '{print $2}' | cut -d: -f2)
        echo "监听端口: $port"
    fi
    
    echo "客户端配置: $CLIENT_CONFIG_FILE"
    
    echo ""
    echo "证书信息:"
    if [ -f "${HYSTERIA_DIR}/fullchain.cer" ]; then
        local cert_expire=$(openssl x509 -in "${HYSTERIA_DIR}/fullchain.cer" -enddate -noout 2>/dev/null | cut -d= -f2)
        echo "证书到期: $cert_expire"
    else
        echo "证书文件: 不存在"
    fi
    
    echo ""
    echo "网络信息:"
    local public_ip=$(get_public_ip)
    echo "公网IP: $public_ip"
    echo "连接地址: ${public_ip}:${port:-443}"
    
    echo ""
    echo "最近日志:"
    journalctl -u hysteria -n 20 --no-pager
}

show_menu() {
    clear
    echo -e "${GREEN}$SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo "================================"
    echo -e "${CYAN}1.${NC} 安装Hysteria 2"
    echo -e "${CYAN}2.${NC} 查看服务状态"
    echo -e "${CYAN}3.${NC} 重启服务"
    echo -e "${CYAN}4.${NC} 查看日志"
    echo -e "${CYAN}5.${NC} 重新配置"
    echo -e "${CYAN}6.${NC} 更新Hysteria"
    echo -e "${CYAN}7.${NC} 更新SSL证书"
    echo -e "${CYAN}8.${NC} 备份配置"
    echo -e "${CYAN}9.${NC} 恢复配置"
    echo -e "${CYAN}10.${NC} 卸载Hysteria"
    echo -e "${CYAN}11.${NC} 退出"
    echo "================================"
    echo -e "${YELLOW}提示: 使用上下箭头选择，按Enter确认${NC}"
}

# ==================== 主函数 ====================
main() {
    check_root
    check_system
    
    # 创建必要的目录
    mkdir -p "$HYSTERIA_DIR" "$BACKUP_DIR"
    
    # 检查日志文件
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    
    log_info "脚本启动: $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # 自动检查证书更新
    if command -v ~/.acme.sh/acme.sh > /dev/null 2>&1; then
        renew_certificates
    fi
    
    # 检查网络连接
    if ! check_network; then
        log_warn "网络连接检查未通过，某些功能可能无法正常使用"
        read -p "是否继续? [y/N]: " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            log_info "用户取消操作"
            exit 1
        fi
    fi
    
    while true; do
        show_menu
        if ! read -p "请选择操作 [1-11]: " CHOICE 2>/dev/null; then
            log_error "输入读取失败，请重试"
            sleep 1
            continue
        fi
        
        # 验证输入
        if ! [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
            log_error "无效输入，请输入数字"
            continue
        fi
        
        case $CHOICE in
            1)
                log_info "开始安装Hysteria 2..."
                if check_network && \
                   install_dependencies && \
                   download_hysteria "$(get_latest_version)" "$(detect_arch)" && \
                   interactive_config && \
                   setup_systemd_service && \
                   start_service; then
                    log_info "安装完成！"
                    show_status
                else
                    log_error "安装过程中出现错误，请检查日志: $LOG_FILE"
                fi
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
                if check_network && \
                   interactive_config && \
                   systemctl restart hysteria; then
                    log_info "配置已更新并重启服务"
                    show_status
                else
                    log_error "重新配置失败，请检查网络连接和配置"
                fi
                ;;
            6)
                update_hysteria
                ;;
            7)
                log_info "更新SSL证书..."
                if [ -f "$CONFIG_FILE" ]; then
                    local domain=$(grep "sni:" "$CLIENT_CONFIG_FILE" 2>/dev/null | awk '{print $2}' | head -1)
                    if [ -n "$domain" ] && [ "$domain" != "hysteria.local" ]; then
                        setup_ssl_cert "$domain"
                        systemctl restart hysteria
                    else
                        log_info "未配置域名，无法自动更新证书"
                        generate_self_signed_cert
                    fi
                fi
                ;;
            8)
                backup_config
                ;;
            9)
                restore_config
                systemctl restart hysteria
                ;;
            10)
                uninstall
                ;;
            11)
                log_info "感谢使用$SCRIPT_NAME！"
                log_info "日志文件: $LOG_FILE"
                exit 0
                ;;
            *)
                log_error "无效选择，请重新输入"
                ;;
        esac
        
        echo ""
        read -p "按Enter键继续..."
    done
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi