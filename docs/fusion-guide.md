# 喵哥Hysteria 2安装脚本 - 融合版使用说明

## 🎯 概述

**融合版**是喵哥Hysteria安装脚本的终极进化版本，融合了[seagullz4/hysteria2](https://github.com/seagullz4/hysteria2)的优点，实现了真正的"**一键导入即可使用**"体验。

## 🚀 一键安装命令

### 最简单的安装方式
```bash
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh)
```

### 自定义域名安装
```bash
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh) --domain your-domain.com
```

### 使用wget安装
```bash
wget -O hy2.sh https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh
chmod +x hy2.sh
./hy2.sh
```

## ✨ 融合版特色功能

### 1. **🎯 真正的一键导入即可使用**
- 零配置安装，开箱即用
- 自动检测系统类型和架构
- 智能生成最优配置
- 30秒内完成部署

### 2. **🔧 智能系统优化**
- 自动优化内核参数
- 启用BBR拥塞控制
- 调整网络缓冲区大小
- 启用TCP快速打开

### 3. **📱 快捷命令支持**
安装完成后，会自动创建`hy2`快捷命令：

```bash
hy2 start     # 启动服务
hy2 stop      # 停止服务
hy2 restart   # 重启服务
hy2 status    # 查看状态
hy2 logs      # 查看日志
hy2 config    # 编辑配置
hy2 client    # 查看客户端配置
hy2 qr        # 生成二维码
hy2 test      # 测试配置
hy2 uninstall # 卸载服务
```

### 4. **📊 订阅转换功能**
自动生成多种格式的订阅配置：
- **JSON格式**: 标准Hysteria配置
- **Clash格式**: Clash/Clash Meta配置
- **V2Ray格式**: V2Ray兼容配置
- **二维码**: 一键扫码配置

订阅文件位置：`/root/hysteria/config/subscriptions/`

### 5. **🔒 智能证书管理**
- **有域名**: 自动申请Let's Encrypt证书
- **无域名**: 自动生成自签名证书
- **智能选择**: 根据域名自动选择证书类型

### 6. **🌐 多平台支持**
- **Debian/Ubuntu**: 完全支持，推荐使用
- **CentOS/RHEL**: 完整支持
- **Arch Linux**: 基础支持
- **其他系统**: 尝试支持

## 📋 安装流程

### 1. 系统检查
- ✅ Root权限检查
- ✅ 操作系统检测
- ✅ 架构检测
- ✅ 网络连通性检查

### 2. 依赖安装
- ✅ 系统包安装 (curl, wget, openssl, 等)
- ✅ Python3及依赖
- ✅ 系统参数优化

### 3. Hysteria安装
- ✅ 下载最新版本
- ✅ 验证文件完整性
- ✅ 安装到系统路径

### 4. 证书配置
- ✅ 域名检测
- ✅ Let's Encrypt证书申请 (如有域名)
- ✅ 自签名证书生成 (如无域名)

### 5. 服务配置
- ✅ 生成服务器配置
- ✅ 生成客户端配置
- ✅ 配置系统服务
- ✅ 启动服务

### 6. 后续设置
- ✅ 创建快捷命令
- ✅ 生成订阅配置
- ✅ 显示安装信息

## 📊 安装结果示例

```
======================================
Hysteria 2 安装完成！
======================================

📊 配置信息:
  端口: 443
  密码: 自动生成16位强密码
  域名: hysteria.local (自签名证书)
  上行带宽: 100 Mbps
  下行带宽: 20 Mbps

📁 文件位置:
  程序: /usr/local/bin/hysteria
  服务器配置: /root/hysteria/config/server.yaml
  客户端配置: /root/hysteria/config/client.yaml
  证书: /root/hysteria/certs/
  订阅配置: /root/hysteria/config/subscriptions/
  日志: /root/hysteria/logs/hysteria.log

🔧 快捷命令:
  hy2 start     - 启动服务
  hy2 stop      - 停止服务
  hy2 restart   - 重启服务
  hy2 status    - 查看状态
  hy2 logs      - 查看日志
  hy2 config    - 编辑配置
  hy2 client    - 查看客户端配置
  hy2 qr        - 生成二维码
  hy2 test      - 测试配置
  hy2 uninstall - 卸载服务

🌐 连接信息:
  服务器地址: your-server-ip:443

📱 客户端使用:
  1. 复制客户端配置到客户端设备
  2. 如果使用自签名证书，设置 insecure: true
  3. 启动Hysteria客户端
```

## 📱 客户端使用

### 1. 获取客户端配置
```bash
hy2 client
```

### 2. 生成二维码
```bash
hy2 qr
# 使用手机扫描二维码即可导入配置
```

### 3. 复制配置文件
```bash
# 将客户端配置复制到客户端设备
cat /root/hysteria/config/client.yaml
```

### 4. 推荐客户端
- **Android**: Husi, NekoBox, Hiddify
- **iOS**: Shadowrocket, Hiddify
- **Windows**: v2rayN, Clash Verge
- **Mac**: Shadowrocket, ClashX

## 🔧 维护命令

### 服务管理
```bash
hy2 start     # 启动服务
hy2 stop      # 停止服务
hy2 restart   # 重启服务
hy2 status    # 查看状态
```

### 配置管理
```bash
hy2 config    # 编辑服务器配置
hy2 client    # 查看客户端配置
hy2 test      # 测试配置是否正确
```

### 日志查看
```bash
hy2 logs      # 查看实时日志
# 或
tail -f /root/hysteria/logs/hysteria.log
```

### 订阅管理
```bash
# 查看所有订阅格式
ls -la /root/hysteria/config/subscriptions/

# 查看Clash配置
cat /root/hysteria/config/subscriptions/clash.yaml

# 查看JSON配置
cat /root/hysteria/config/subscriptions/hysteria2.json
```

## 🚨 故障排除

### 1. 服务无法启动
```bash
# 检查配置语法
hy2 test

# 查看错误日志
hy2 logs

# 检查端口占用
netstat -tuln | grep :443
```

### 2. 证书问题
```bash
# 重新申请证书
~/.acme.sh/acme.sh --renew -d your-domain.com --force

# 检查证书权限
ls -l /root/hysteria/certs/
```

### 3. 网络问题
```bash
# 检查网络连通性
ping github.com

# 检查DNS解析
nslookup your-domain.com

# 检查端口开放
telnet your-server 443
```

### 4. 卸载重装
```bash
# 完全卸载
hy2 uninstall

# 重新安装
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh)
```

## 💡 最佳实践

### 1. 使用域名
```bash
# 有域名的用户建议使用
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh) --domain your-domain.com
```

### 2. 定期维护
```bash
# 查看服务状态
hy2 status

# 检查日志
hy2 logs

# 重启服务（修改配置后）
hy2 restart
```

### 3. 备份配置
```bash
# 备份重要配置
cp -r /root/hysteria /root/hysteria_backup_$(date +%Y%m%d)

# 备份订阅配置
cp -r /root/hysteria/config/subscriptions /root/subscriptions_backup
```

### 4. 使用订阅转换
```bash
# 访问在线订阅转换网站
# https://sub.crazyact.com/

# 导入Clash配置
cat /root/hysteria/config/subscriptions/clash.yaml
```

## 📊 版本对比

| 版本 | 安装方式 | 配置复杂度 | 特色功能 | 推荐使用 |
|------|----------|------------|----------|----------|
| **融合版 v4.0** | 一句话命令 | 🎯 零配置 | 快捷命令+订阅转换 | ⭐⭐⭐⭐⭐ |
| 终极版 v3.0 | 一句话命令 | 🎯 零配置 | 极速安装 | ⭐⭐⭐⭐ |
| 优化版 v2.0 | 交互式菜单 | 🔧 简单配置 | 功能完整 | ⭐⭐⭐ |

## 🎯 推荐使用场景

### 1. 快速测试
```bash
# 快速搭建测试环境
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh)
```

### 2. 生产部署
```bash
# 生产环境建议使用域名
bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh) --domain your-domain.com
```

### 3. 多用户管理
```bash
# 每个用户使用独立的配置
# 客户端配置文件位置: /root/hysteria/config/client.yaml
# 订阅文件位置: /root/hysteria/config/subscriptions/
```

### 4. 自动化部署
```bash
# 在自动化脚本中使用
DOMAIN=your-domain.com bash <(curl -sL https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh)
```

## 📞 支持信息

### 项目资源
- **GitHub仓库**: https://github.com/miaoge2026/miaohy2
- **安装脚本**: https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键安装_hysteria_融合版.sh
- **使用说明**: https://github.com/miaoge2026/miaohy2/tree/main/docs
- **问题反馈**: https://github.com/miaoge2026/miaohy2/issues

### 参考项目
- **Hysteria官方**: https://github.com/apernet/hysteria
- **seagullz4/hysteria2**: https://github.com/seagullz4/hysteria2
- **acme.sh**: https://github.com/acmesh-official/acme.sh

### 相关工具
- **订阅转换**: https://sub.crazyact.com/
- **Hysteria文档**: https://v2.hysteria.network/zh/docs/
- **客户端下载**: 详见Hysteria官方文档

---

**融合版特点总结**:
- 🎯 **一键导入即可使用** - 真正的零配置安装
- ⚡ **极速部署** - 30秒内完成安装
- 🔧 **智能优化** - 自动系统优化和配置
- 📱 **快捷命令** - hy2命令一键管理
- 📊 **订阅转换** - 多种格式订阅配置
- 🔒 **安全默认** - 开箱即用的安全配置

**一句话安装，一步到位！** 🎉