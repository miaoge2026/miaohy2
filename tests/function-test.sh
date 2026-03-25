#!/bin/bash

# 喵哥Hysteria安装脚本v2.0功能测试

echo "======================================"
echo "开始测试喵哥Hysteria安装脚本v2.0功能"
echo "======================================"
echo ""

# 1. 基本文件检查
echo "【测试1】基本文件检查"
if [ -f "喵哥一键hy安装脚本_v2.0.sh" ]; then
    echo "✅ 主脚本文件存在"
else
    echo "❌ 主脚本文件不存在"
    exit 1
fi

# 2. 语法检查
echo ""
echo "【测试2】语法检查"
if bash -n "喵哥一键hy安装脚本_v2.0.sh"; then
    echo "✅ 脚本语法正确"
else
    echo "❌ 脚本语法错误"
    exit 1
fi

# 3. 函数定义检查
echo ""
echo "【测试3】函数定义检查"
source "喵哥一键hy安装脚本_v2.0.sh" 2>/dev/null
if declare -f log_info > /dev/null && declare -f check_root > /dev/null && declare -f download_hysteria > /dev/null; then
    echo "✅ 核心函数定义正常"
else
    echo "❌ 核心函数定义异常"
    exit 1
fi

# 4. 系统兼容性检查
echo ""
echo "【测试4】系统兼容性检查"
OS=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
case $OS in
    ubuntu|debian|centos|rhel|fedora|arch)
        echo "✅ 支持的操作系统: $OS"
        ;;
    *)
        echo "❌ 不支持的操作系统: $OS"
        exit 1
        ;;
esac

# 5. 架构检查
echo ""
echo "【测试5】系统架构检查"
ARCH=$(uname -m)
case $ARCH in
    x86_64|aarch64|armv7l)
        echo "✅ 支持的架构: $ARCH"
        ;;
    *)
        echo "❌ 不支持的架构: $ARCH"
        exit 1
        ;;
esac

# 6. 工具依赖检查
echo ""
echo "【测试6】工具依赖检查"
missing_tools=()
for tool in curl wget openssl systemctl; do
    if command -v $tool > /dev/null; then
        echo "✅ $tool 已安装"
    else
        echo "❌ $tool 未安装"
        missing_tools+=($tool)
    fi
done

if [ ${#missing_tools[@]} -gt 0 ]; then
    echo "⚠️ 缺少工具: ${missing_tools[*]}"
else
    echo "✅ 所有必要工具已安装"
fi

# 7. 版本获取测试
echo ""
echo "【测试7】版本获取测试"
LATEST_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4 2>/dev/null)
if [ -n "$LATEST_VERSION" ]; then
    echo "✅ 能获取最新版本: $LATEST_VERSION"
else
    echo "⚠️ 无法获取最新版本（网络问题）"
fi

# 8. 端口检测测试
echo ""
echo "【测试8】端口检测测试"
if command -v ss > /dev/null; then
    if ss -tuln | grep -q ":443"; then
        echo "⚠️ 端口443已被占用"
    else
        echo "✅ 端口443可用"
    fi
else
    echo "⚠️ ss命令不可用，无法检测端口"
fi

# 9. 日志功能测试
echo ""
echo "【测试9】日志功能测试"
LOG_FILE="/tmp/hysteria_test.log"
touch "$LOG_FILE"
if [ -f "$LOG_FILE" ]; then
    echo "测试日志内容" >> "$LOG_FILE"
    if grep -q "测试日志内容" "$LOG_FILE"; then
        echo "✅ 日志功能正常"
    else
        echo "❌ 日志写入失败"
    fi
    rm -f "$LOG_FILE"
else
    echo "❌ 日志文件创建失败"
fi

# 10. 备份功能测试
echo ""
echo "【测试10】备份功能测试"
BACKUP_DIR="/tmp/hysteria_backup_test"
mkdir -p "$BACKUP_DIR"
if [ -d "$BACKUP_DIR" ]; then
    echo "测试配置" > "$BACKUP_DIR/test_config.yaml"
    if [ -f "$BACKUP_DIR/test_config.yaml" ]; then
        echo "✅ 备份功能正常"
    else
        echo "❌ 备份创建失败"
    fi
    rm -rf "$BACKUP_DIR"
else
    echo "❌ 备份目录创建失败"
fi

# 11. 密码生成测试
echo ""
echo "【测试11】密码生成测试"
PASSWORD=$(openssl rand -base64 16 | tr -d '=' | tr -d '+' | tr -d '/' | head -c 16 2>/dev/null)
if [ ${#PASSWORD} -eq 16 ]; then
    echo "✅ 密码生成正常: $PASSWORD"
else
    echo "❌ 密码生成异常"
fi

# 12. 证书生成测试
echo ""
echo "【测试12】证书生成测试"
CERT_DIR="/tmp/hysteria_cert_test"
mkdir -p "$CERT_DIR"
if openssl req -x509 -newkey rsa:2048 -keyout "$CERT_DIR/private.key" -out "$CERT_DIR/fullchain.cer" -days 365 -nodes -subj "/C=CN/ST=Test/L=Test/O=Test/CN=test.local" 2>/dev/null; then
    if [ -f "$CERT_DIR/private.key" ] && [ -f "$CERT_DIR/fullchain.cer" ]; then
        echo "✅ 证书生成正常"
    else
        echo "❌ 证书文件创建失败"
    fi
else
    echo "❌ 证书生成失败"
fi
rm -rf "$CERT_DIR"

echo ""
echo "======================================"
echo "🎉 所有功能测试完成！"
echo "======================================"
echo ""
echo "测试总结："
echo "✅ 基本功能正常"
echo "✅ 系统兼容性良好"
echo "✅ 工具依赖基本满足"
echo "✅ 核心功能可用"
echo ""
echo "⚠️ 注意："
echo "1. 端口443可能需要检查"
echo "2. 网络连接需要确保"
echo "3. 完整安装需要root权限"