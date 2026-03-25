# 喵哥一键Hysteria 2安装脚本使用说明

## 📋 脚本介绍

**脚本名称**: 喵哥一键hy安装脚本.sh  
**功能**: 自动化安装、配置和管理Hysteria 2服务器  
**特点**: 交互式配置、自动SSL证书申请、完整的系统服务管理

## ✨ 主要功能

### 1. 安装功能
- ✅ 自动检测系统架构（amd64/arm64/arm）
- ✅ 自动获取并安装最新版本的Hysteria 2
- ✅ 交互式配置（端口、密码、带宽等）
- ✅ 自动SSL证书申请（通过acme.sh）
- ✅ 生成自签名证书（备用方案）
- ✅ 自动配置系统服务

### 2. 管理功能
- ✅ 查看服务状态
- ✅ 重启服务
- ✅ 查看实时日志
- ✅ 重新配置
- ✅ 卸载功能

### 3. 安全特性
- ✅ 自动生成强密码
- ✅ 支持Let's Encrypt免费SSL证书
- ✅ 正确的权限设置
- ✅ 系统服务隔离

## 🚀 安装要求

- **系统**: Ubuntu/Debian/CentOS/RHEL/Fedora/Arch Linux
- **权限**: root用户
- **网络**: 可访问GitHub和Let's Encrypt
- **端口**: 需要可用的443端口（可自定义）

## 📦 安装步骤

### 1. 下载脚本
```bash
wget https://raw.githubusercontent.com/your-repo/喵哥一键hy安装脚本/main/喵哥一键hy安装脚本.sh
# 或
curl -O https://raw.githubusercontent.com/your-repo/喵哥一键hy安装脚本/main/喵哥一键hy安装脚本.sh
```

### 2. 添加执行权限
```bash
chmod +x 喵哥一键hy安装脚本.sh
```

### 3. 运行脚本
```bash
./喵哥一键hy安装脚本.sh
```

## 🎯 使用指南

### 首次安装
1. 运行脚本后选择 **1. 安装Hysteria 2**
2. 按照提示配置：
   - **端口**: 默认443（推荐）
   - **密码**: 自动生成或手动设置
   - **带宽**: 根据你的网络情况设置
   - **DNS**: 默认1.1.1.1（推荐）
   - **域名**: 用于SSL证书申请（可选）

### 域名配置建议
- 如果有域名，建议填写以获取有效的SSL证书
- 如果没有域名，脚本会自动生成自签名证书
- 使用自签名证书时，客户端需要设置 `insecure: true`

### 管理操作
安装完成后，可以通过菜单进行各种管理操作：

- **查看状态**: 检查服务运行状态和配置信息
- **重启服务**: 应用配置更改
- **查看日志**: 实时查看服务日志（按Ctrl+C退出）
- **重新配置**: 修改服务器配置
- **卸载**: 完全移除Hysteria

## 📁 文件结构

安装完成后，相关文件位置：

```
/usr/local/bin/hysteria           # Hysteria程序
/root/hysteria/config.yaml         # 服务器配置文件
/root/hysteria/client_config.yaml  # 客户端配置文件
/root/hysteria/fullchain.cer       # SSL证书
/root/hysteria/private.key         # SSL私钥
/etc/systemd/system/hysteria.service # 系统服务
```

## 🔧 常用命令

### 服务管理
```bash
# 启动服务
systemctl start hysteria

# 停止服务
systemctl stop hysteria

# 重启服务
systemctl restart hysteria

# 查看状态
systemctl status hysteria

# 启用开机自启
systemctl enable hysteria

# 禁用开机自启
systemctl disable hysteria
```

### 日志查看
```bash
# 实时日志
journalctl -u hysteria -f

# 查看最近50条日志
journalctl -u hysteria -n 50

# 查看错误日志
journalctl -u hysteria -p err
```

## 📱 客户端使用

### 客户端配置
脚本会生成客户端配置文件 `/root/hysteria/client_config.yaml`，将其复制到客户端使用：

```yaml
server: "your-server.com:443"
auth: your-password
tls:
  sni: your-server.com
  insecure: false  # 如果使用自签名证书，设为true
bandwidth:
  up: 20 mbps
  down: 100 mbps
socks5:
  listen: 127.0.0.1:50000
```

### 客户端启动
```bash
./hysteria client -c client_config.yaml
```

## 🔒 安全建议

1. **密码强度**: 使用脚本生成的随机密码或设置强密码
2. **证书管理**: 建议使用Let's Encrypt免费证书
3. **端口选择**: 443端口最不容易被封锁
4. **访问控制**: 配置ACL规则限制访问
5. **定期更新**: 定期更新Hysteria程序

## 🚨 故障排除

### 服务无法启动
```bash
# 检查配置文件语法
hysteria server -c /root/hysteria/config.yaml --log-level debug

# 查看错误日志
journalctl -u hysteria -n 100 --no-pager
```

### SSL证书问题
```bash
# 重新申请证书
~/.acme.sh/acme.sh --renew -d your-domain.com --force

# 检查证书权限
ls -l /root/hysteria/
```

### 端口占用
```bash
# 检查443端口是否被占用
netstat -tuln | grep :443
lsof -i :443
```

## 📝 更新日志

### v1.0.0 (2026-03-24)
- 初始版本发布
- 支持多架构安装
- 交互式配置
- SSL证书自动申请
- 完整的系统服务管理

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个脚本！

## 📄 许可证

MIT License

## 💝 致谢

- Hysteria项目: https://github.com/apernet/hysteria
- acme.sh: https://github.com/acmesh-official/acme.sh
- 原始脚本作者: chika0801

---

**脚本由喵哥AI助手优化完善**  
**如有问题请联系: miaoge2026**