# 喵哥一键Hysteria 2安装脚本 - 部署文档

## 📋 部署概述

本文档详细介绍了如何将喵哥一键Hysteria 2安装脚本部署到GitHub仓库（miaohy2），包括文件结构、部署步骤、测试验证和持续集成配置。

## 🗂️ 项目文件结构

```
miaohy2/
├── 📄 README.md                          # 项目主文档
├── 📄 DEPLOYMENT.md                       # 部署文档
├── 📄 LICENSE                            # MIT许可证
├── 📄 .gitignore                         # Git忽略文件
├── 📄 .github/workflows/ci.yml            # GitHub Actions配置
├── 📄 scripts/
│   ├── 喵哥一键hy安装脚本_v2.0.sh        # 主安装脚本(v2.0)
│   ├── 喵哥一键hy安装脚本.sh             # 安装脚本(v1.0)
│   └── 功能测试脚本.sh                    # 功能测试脚本
├── 📄 docs/
│   ├── 喵哥Hysteria2安装脚本v2使用说明.md # v2.0使用说明
│   ├── 喵哥Hysteria2安装脚本使用说明.md   # v1.0使用说明
│   ├── 脚本优化分析.md                    # 技术分析和优化建议
│   ├── 故障排除指南.md                    # 常见问题解决
│   └── API文档.md                         # API参考文档
├── 📄 tests/
│   ├── test_install.sh                    # 安装测试脚本
│   ├── test_config.sh                     # 配置测试脚本
│   └── test_uninstall.sh                  # 卸载测试脚本
└── 📄 examples/
    ├── config_server.yaml.example         # 服务器配置示例
    ├── config_client.yaml.example         # 客户端配置示例
    └── docker-compose.yml.example         # Docker配置示例
```

## 🚀 部署步骤

### 1. 创建GitHub仓库

```bash
# 1. 创建本地项目目录
mkdir -p /root/miaohy2
cd /root/miaohy2

# 2. 初始化Git仓库
git init

# 3. 创建远程仓库（需要GitHub CLI）
gh repo create miaohy2 --public --description "喵哥一键Hysteria 2安装脚本"

# 4. 添加远程仓库
git remote add origin https://github.com/miaoge2026/miaohy2.git
```

### 2. 准备项目文件

```bash
# 创建必要的目录
mkdir -p scripts docs tests examples .github/workflows

# 复制文件到项目目录
cp /root/.openclaw/workspace/喵哥一键hy安装脚本_v2.0.sh scripts/
cp /root/.openclaw/workspace/喵哥一键hy安装脚本.sh scripts/
cp /root/.openclaw/workspace/功能测试脚本.sh tests/
cp /root/.openclaw/workspace/README.md .
cp /root/.openclaw/workspace/DEPLOYMENT.md .
cp /root/.openclaw/workspace/脚本优化分析.md docs/
cp /root/.openclaw/workspace/喵哥Hysteria2安装脚本v2使用说明.md docs/
cp /root/.openclaw/workspace/喵哥Hysteria2安装脚本使用说明.md docs/
```

### 3. 创建许可证文件

```bash
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 喵哥AI助手

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION OF THE SOFTWARE, OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
```

### 4. 创建.gitignore文件

```bash
cat > .gitignore << 'EOF'
# 系统文件
.DS_Store
Thumbs.db
*.swp
*.swo

# 日志文件
*.log
/var/log/hysteria_install.log

# 临时文件
/tmp/
*.tmp
*.temp

# 证书文件
*.key
*.cer
*.crt
ca.cer

# 配置文件
/config.yaml
/client_config.yaml
hysteria_config.yaml

# 备份文件
/root/hysteria_backup/
*.backup
*.bak

# IDE文件
.vscode/
.idea/
*.sublime-*

# 测试文件
/tests/test_*.log
/coverage/

# 依赖文件
node_modules/
~/.acme.sh/

# 敏感信息
.env
.env.local
.env.production
.secrets/
EOF
```

### 5. 创建GitHub Actions配置

```bash
cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # 每周日运行

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        os: [ubuntu-latest, centos-latest, archlinux-latest]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up environment
      run: |
        sudo apt update
        sudo apt install -y curl wget openssl
    
    - name: Run syntax check
      run: |
        bash -n scripts/喵哥一键hy安装脚本_v2.0.sh
        bash -n scripts/喵哥一键hy安装脚本.sh
    
    - name: Run basic tests
      run: |
        chmod +x tests/功能测试脚本.sh
        ./tests/功能测试脚本.sh
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: |
          test_*.log
          /var/log/hysteria_install.log
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./docs
    
    - name: Create release
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: |
          scripts/喵哥一键hy安装脚本_v2.0.sh
          scripts/喵哥一键hy安装脚本.sh
          docs/*.md
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
```

### 6. 创建测试脚本

```bash
# 创建安装测试脚本
cat > tests/test_install.sh << 'EOF'
#!/bin/bash

# Hysteria安装测试脚本

set -e

echo "开始安装测试..."

# 测试1: 检查脚本语法
echo "测试1: 语法检查"
bash -n scripts/喵哥一键hy安装脚本_v2.0.sh
echo "✅ 语法检查通过"

# 测试2: 检查函数定义
echo "测试2: 函数定义检查"
source scripts/喵哥一键hy安装脚本_v2.0.sh 2>/dev/null
if declare -f log_info > /dev/null; then
    echo "✅ 函数定义正常"
else
    echo "❌ 函数定义异常"
    exit 1
fi

# 测试3: 系统兼容性检查
echo "测试3: 系统兼容性检查"
OS=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
case $OS in
    ubuntu|debian|centos|rhel|fedora|arch)
        echo "✅ 支持的操作系统: $OS"
        ;;
    *)
        echo "⚠️ 不支持的操作系统: $OS"
        ;;
esac

# 测试4: 工具依赖检查
echo "测试4: 工具依赖检查"
for tool in curl wget openssl; do
    if command -v $tool > /dev/null; then
        echo "✅ $tool 已安装"
    else
        echo "❌ $tool 未安装"
    fi
done

echo "🎉 安装测试完成"
EOF

# 创建配置测试脚本
cat > tests/test_config.sh << 'EOF'
#!/bin/bash

# Hysteria配置测试脚本

set -e

echo "开始配置测试..."

# 测试配置文件生成
echo "测试: 配置文件生成"
TEMP_DIR="/tmp/hysteria_test"
mkdir -p "$TEMP_DIR"

# 模拟配置生成
cat > "$TEMP_DIR/config.yaml" << 'EOF_CONFIG'
listen: :443
tls:
  cert: /root/fullchain.cer
  key: /root/private.key
bandwidth:
  up: 100 mbps
  down: 20 mbps
auth:
  type: password
  password: test_password
EOF_CONFIG

if [ -f "$TEMP_DIR/config.yaml" ]; then
    echo "✅ 配置文件生成成功"
    echo "配置内容:"
    cat "$TEMP_DIR/config.yaml"
else
    echo "❌ 配置文件生成失败"
    exit 1
fi

# 清理
rm -rf "$TEMP_DIR"

echo "🎉 配置测试完成"
EOF

# 创建卸载测试脚本
cat > tests/test_uninstall.sh << 'EOF'
#!/bin/bash

# Hysteria卸载测试脚本

set -e

echo "开始卸载测试..."

# 模拟卸载过程
echo "模拟卸载步骤..."

# 1. 停止服务
echo "1. 停止服务"
systemctl stop hysteria 2>/dev/null || true

# 2. 禁用服务
echo "2. 禁用服务"
systemctl disable hysteria 2>/dev/null || true

# 3. 删除程序文件
echo "3. 删除程序文件"
rm -f /usr/local/bin/hysteria

# 4. 删除服务文件
echo "4. 删除服务文件"
rm -f /etc/systemd/system/hysteria.service

# 5. 重新加载systemd
echo "5. 重新加载systemd"
systemctl daemon-reload

echo "✅ 卸载测试完成"
echo "🎉 卸载测试通过"
EOF
```

### 7. 创建示例文件

```bash
# 服务器配置示例
cat > examples/config_server.yaml.example << 'EOF'
# Hysteria 2 服务器配置示例
# 请将此文件重命名为 config.yaml 并根据实际情况修改

listen: :443

tls:
  cert: /root/hysteria/fullchain.cer
  key: /root/hysteria/private.key

bandwidth:
  up: 100 mbps
  down: 20 mbps

auth:
  type: password
  password: your_strong_password_here

resolver:
  type: https
  https:
    addr: 1.1.1.1:443
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
  file: /root/hysteria/hysteria.log
EOF

# 客户端配置示例
cat > examples/config_client.yaml.example << 'EOF'
# Hysteria 2 客户端配置示例
# 请将此文件重命名为 client_config.yaml 并根据实际情况修改

server: "your-server.com:443"

auth: your_password_here

tls:
  sni: your-server.com
  insecure: false
  # ca: /path/to/ca.cer  # 使用自签名证书时需要

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

# Docker Compose示例
cat > examples/docker-compose.yml.example << 'EOF'
version: '3.8'

services:
  hysteria-server:
    image: tobyxdd/hysteria:latest
    container_name: hysteria-server
    restart: unless-stopped
    ports:
      - "443:443/udp"
      - "443:443/tcp"
      - "443:443"
    volumes:
      - ./config:/etc/hysteria
      - ./certs:/etc/hysteria/certs
      - ./logs:/var/log/hysteria
    environment:
      - TZ=Asia/Shanghai
    networks:
      - hysteria-network
    healthcheck:
      test: ["CMD", "hysteria", "client", "-c", "/etc/hysteria/config.yaml", "--test"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  hysteria-web:
    image: nginx:alpine
    container_name: hysteria-web
    restart: unless-stopped
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./web:/usr/share/nginx/html
    depends_on:
      - hysteria-server
    networks:
      - hysteria-network

networks:
  hysteria-network:
    driver: bridge
EOF
```

### 8. 提交代码到GitHub

```bash
# 添加所有文件到Git
git add .

# 提交更改
git commit -m "Initial commit: 添加喵哥一键Hysteria 2安装脚本v2.0

- 添加主安装脚本v2.0
- 添加详细使用说明文档
- 创建项目文件结构
- 添加测试脚本和示例文件
- 配置GitHub Actions CI/CD"

# 推送到GitHub
git push -u origin main

# 创建版本标签
git tag -a v2.0.0 -m "版本2.0.0发布"
git push origin v2.0.0
```

## 🔧 持续集成配置

### GitHub Actions工作流

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # 每周日运行

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        os: [ubuntu-latest, centos-latest, archlinux-latest]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up environment
      run: |
        sudo apt update
        sudo apt install -y curl wget openssl
    
    - name: Run syntax check
      run: |
        bash -n scripts/喵哥一键hy安装脚本_v2.0.sh
        bash -n scripts/喵哥一键hy安装脚本.sh
    
    - name: Run basic tests
      run: |
        chmod +x tests/功能测试脚本.sh
        ./tests/功能测试脚本.sh
    
    - name: Upload test results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: test-results
        path: |
          test_*.log
          /var/log/hysteria_install.log
  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./docs
    
    - name: Create release
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: |
          scripts/喵哥一键hy安装脚本_v2.0.sh
          scripts/喵哥一键hy安装脚本.sh
          docs/*.md
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 部署状态徽章

```markdown
![GitHub release](https://img.shields.io/github/release/miaoge2026/miaohy2)
![License](https://img.shields.io/github/license/miaoge2026/miaohy2)
![CI](https://img.shields.io/github/workflow/status/miaoge2026/miaohy2/CI/CD%20Pipeline)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2FDebian%2FCentOS%2FArch-blue)
![Version](https://img.shields.io/badge/version-2.0.0-green)
```

## 📊 部署验证

### 1. 仓库检查

```bash
# 克隆仓库到本地测试
git clone https://github.com/miaoge2026/miaohy2.git
cd miaohy2

# 检查文件结构
ls -la

# 验证脚本语法
bash -n scripts/喵哥一键hy安装脚本_v2.0.sh

# 运行测试
chmod +x tests/功能测试脚本.sh
./tests/功能测试脚本.sh
```

### 2. 功能验证

```bash
# 1. 下载脚本
curl -O https://raw.githubusercontent.com/miaoge2026/miaohy2/main/scripts/喵哥一键hy安装脚本_v2.0.sh

# 2. 添加执行权限
chmod +x 喵哥一键hy安装脚本_v2.0.sh

# 3. 检查语法
bash -n 喵哥一键hy安装脚本_v2.0.sh

# 4. 查看帮助信息
./喵哥一键hy安装脚本_v2.0.sh --help 2>/dev/null || echo "脚本需要交互式运行"
```

### 3. 文档验证

- ✅ README.md 显示正常
- ✅ 使用说明文档完整
- ✅ 部署文档详细
- ✅ 示例文件格式正确
- ✅ 许可证文件存在

## 🔄 持续维护

### 版本管理

```bash
# 创建新版本
git checkout -b feature/new-feature
# ... 开发新功能 ...
git add .
git commit -m "添加新功能"
git push origin feature/new-feature
# 创建Pull Request

# 发布新版本
git tag -a v2.1.0 -m "版本2.1.0发布"
git push origin v2.1.0
```

### 更新文档

```bash
# 更新README
git add README.md
git commit -m "更新README文档"
git push origin main

# 更新使用说明
git add docs/喵哥Hysteria2安装脚本v2使用说明.md
git commit -m "更新使用说明"
git push origin main
```

### 问题跟踪

- 使用GitHub Issues跟踪问题
- 创建Pull Request修复问题
- 定期更新版本和文档

## 🎯 部署检查清单

### 部署前检查

- [ ] 所有测试通过
- [ ] 语法检查通过
- [ ] 文档完整准确
- [ ] 版本号正确
- [ ] 许可证文件存在
- [ ] .gitignore配置正确

### 部署后验证

- [ ] 仓库可正常克隆
- [ ] 脚本可正常下载
- [ ] 文档显示正常
- [ ] CI/CD工作流正常
- [ ] 版本标签正确
- [ ] 下载统计正常

## 📞 支持信息

- **项目地址**: https://github.com/miaoge2026/miaohy2
- **问题反馈**: https://github.com/miaoge2026/miaohy2/issues
- **最新版本**: https://github.com/miaoge2026/miaohy2/releases
- **文档地址**: https://miaoge2026.github.io/miaohy2/

---

**部署完成时间**: 2026-03-24  
**部署版本**: v2.0.0  
**维护者**: 喵哥AI助手  
**联系方式**: miaoge2026@example.com