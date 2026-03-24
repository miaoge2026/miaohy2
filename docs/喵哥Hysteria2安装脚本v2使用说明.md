# 喵哥一键Hysteria 2安装脚本 v2.0 使用说明

## 📋 脚本介绍

**脚本名称**: 喵哥一键hy安装脚本_v2.0.sh  
**版本**: v2.0.0  
**功能**: 自动化安装、配置和管理Hysteria 2服务器  
**特点**: 交互式配置、自动SSL证书申请、完整的系统服务管理、备份恢复、自动更新

## ✨ v2.0 新功能特性

### 🚀 新增功能
- **自动更新检测** - 检测并更新到最新Hysteria版本
- **配置备份恢复** - 自动备份和恢复配置文件
- **SSL证书管理** - 自动续期Let's Encrypt证书
- **日志系统** - 详细的安装和操作日志记录
- **错误处理** - 完善的错误检测和重试机制
- **系统资源检查** - 自动检查内存和磁盘空间
- **端口冲突检测** - 自动检测端口占用情况
- **服务健康检查** - 自动测试服务启动状态

### 🔧 优化改进
- **模块化设计** - 代码结构更清晰，易于维护
- **交互体验** - 更友好的中文交互界面
- **安全性增强** - 更好的权限管理和密码策略
- **兼容性提升** - 支持更多Linux发行版
- **性能优化** - 减少不必要的下载和安装

## 🚀 安装要求

- **系统**: Ubuntu/Debian/CentOS/RHEL/Fedora/Arch Linux
- **权限**: root用户
- **网络**: 可访问GitHub和Let's Encrypt
- **端口**: 需要可用的443端口（可自定义）
- **资源**: 至少1GB内存，5GB磁盘空间

## 📦 安装步骤

### 1. 下载脚本
```bash
wget https://raw.githubusercontent.com/your-repo/喵哥一键hy安装脚本/main/喵哥一键hy安装脚本_v2.0.sh
# 或
curl -O https://raw.githubusercontent.com/your-repo/喵哥一键hy安装脚本/main/喵哥一键hy安装脚本_v2.0.sh
```

### 2. 添加执行权限
```bash
chmod +x 喵哥一键hy安装脚本_v2.0.sh
```

### 3. 运行脚本
```bash
./喵哥一键hy安装脚本_v2.0.sh
```

## 🎯 使用指南

### 首次安装
1. 运行脚本后选择 **1. 安装Hysteria 2**
2. 按照提示配置：
   - **端口**: 默认443（推荐）
   - **密码**: 自动生成强密码或手动设置
   - **带宽**: 根据你的网络情况设置
   - **DNS**: 默认1.1.1.1（推荐）
   - **域名**: 用于SSL证书申请（可选）
   - **高级选项**: 可选择配置流量混淆和访问控制

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
- **更新Hysteria**: 检查并更新到最新版本
- **更新SSL证书**: 手动更新Let's Encrypt证书
- **备份配置**: 手动备份当前配置
- **恢复配置**: 从备份恢复配置
- **卸载**: 完全移除Hysteria

## 📁 文件结构

安装完成后，相关文件位置：

```
/usr/local/bin/hysteria           # Hysteria程序
/root/hysteria/config.yaml         # 服务器配置文件
/root/hysteria/client_config.yaml  # 客户端配置文件
/root/hysteria/fullchain.cer       # SSL证书
/root/hysteria/private.key         # SSL私钥
/root/hysteria/ca.cer              # CA证书（自签名时）
/root/hysteria/hysteria.log        # 服务日志
/root/hysteria_backup/             # 配置备份目录
/etc/systemd/system/hysteria.service # 系统服务
/var/log/hysteria_install.log      # 安装日志
~/.acme.sh/                        # ACME.sh目录
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

# 查看安装日志
tail -f /var/log/hysteria_install.log
```

### 证书管理
```bash
# 手动更新证书
./喵哥一键hy安装脚本_v2.0.sh
# 选择: 7. 更新SSL证书

# 查看证书状态
openssl x509 -in /root/hysteria/fullchain.cer -text -noout
```

### 配置备份
```bash
# 手动备份
./喵哥一键hy安装脚本_v2.0.sh
# 选择: 8. 备份配置

# 查看备份
ls -la /root/hysteria_backup/
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
  ca: /path/to/ca.cer  # 自签名证书需要
bandwidth:
  up: 20 mbps
  down: 100 mbps
socks5:
  listen: 127.0.0.1:50000
http:
  listen: 127.0.0.1:50001
```

### 客户端启动
```bash
./hysteria client -c client_config.yaml
```

## 🔒 安全建议

1. **密码强度**: 使用脚本生成的随机密码（16位强密码）
2. **证书管理**: 建议使用Let's Encrypt免费证书
3. **端口选择**: 443端口最不容易被封锁
4. **访问控制**: 配置ACL规则限制访问
5. **定期更新**: 定期更新Hysteria程序和证书
6. **日志监控**: 定期检查日志文件
7. **备份策略**: 定期备份配置文件

## 🚨 故障排除

### 服务无法启动
```bash
# 检查配置文件语法
hysteria server -c /root/hysteria/config.yaml --log-level debug

# 查看错误日志
journalctl -u hysteria -n 100 --no-pager
tail -n 100 /root/hysteria/hysteria.log
```

### SSL证书问题
```bash
# 重新申请证书
~/.acme.sh/acme.sh --renew -d your-domain.com --force

# 检查证书权限
ls -l /root/hysteria/
chmod 600 /root/hysteria/private.key
chmod 644 /root/hysteria/fullchain.cer
```

### 端口占用
```bash
# 检查端口是否被占用
ss -tuln | grep :443
lsof -i :443

# 如果被占用，可以：
# 1. 停止占用端口的服务
# 2. 或修改Hysteria监听端口
```

### 更新失败
```bash
# 手动下载最新版本
LATEST=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
wget https://github.com/apernet/hysteria/releases/download/${LATEST}/hysteria-linux-amd64
chmod +x hysteria-linux-amd64
mv hysteria-linux-amd64 /usr/local/bin/hysteria
```

## 📊 性能调优

### 带宽优化
在配置文件中调整带宽设置：
```yaml
bandwidth:
  up: 100 mbps   # 根据实际网络调整
  down: 20 mbps  # 根据实际网络调整
```

### 连接优化
```yaml
# 增加超时时间
resolver:
  type: https
  https:
    addr: 1.1.1.1:443
    timeout: 10s

sniff:
  enable: true
  timeout: 2s
```

## 📝 更新日志

### v2.0.0 (2026-03-24)
- 🎉 完整重构，模块化设计
- 🔄 自动更新检测和更新功能
- 💾 配置备份和恢复功能
- 📝 完善的日志系统
- 🛡️ 增强的错误处理和重试机制
- 🔍 系统资源检查和端口冲突检测
- 🌐 更好的SSL证书管理
- 💻 改进的用户界面和交互体验

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
**项目地址: https://github.com/your-repo/喵哥一键hy安装脚本**