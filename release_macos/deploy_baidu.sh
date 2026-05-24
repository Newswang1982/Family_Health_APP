#!/bin/bash
# 家庭健康 App - 全量部署到百度云
# 用法: bash deploy_baidu.sh <服务器IP> [ssh用户]

set -e

if [ -z "$1" ]; then
    echo "用法: bash deploy_baidu.sh <服务器IP> [ssh用户]"
    echo "示例: bash deploy_baidu.sh 123.45.67.89 root"
    exit 1
fi

SERVER_IP=$1
SSH_USER=${2:-root}
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  家庭健康 App - 部署到 $SERVER_IP"
echo "========================================"

# 1. 生成随机 JWT 密钥
JWT_SECRET=$(openssl rand -hex 32)
echo ""
echo "[1/4] 生成安全配置..."

# 2. 上传后端源码到服务器
echo "[2/4] 上传后端源码到百度云..."
ssh "$SSH_USER@$SERVER_IP" "mkdir -p ~/family-health/backend"
scp -r "$SCRIPT_DIR/backend/" "$SSH_USER@$SERVER_IP:~/family-health/"

# 3. 远程执行部署
echo "[3/4] 在服务器上编译并启动..."
ssh "$SSH_USER@$SERVER_IP" bash -s -- "$JWT_SECRET" << 'REMOTE'
set -e
JWT_SECRET=$1

# 安装 Go（如果没有）
if ! command -v go &>/dev/null; then
    echo "  安装 Go..."
    wget -q https://go.dev/dl/go1.22.5.linux-amd64.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
fi

# 编译后端
cd ~/family-health/backend
echo "  编译后端..."
go build -o server ./cmd/server

# 写入 .env
cat > .env << EOF
SERVER_PORT=8080
JWT_SECRET=$JWT_SECRET
WECHAT_APP_ID=
WECHAT_APP_SECRET=
WECHAT_REDIRECT_URI=
QQ_APP_ID=
QQ_APP_KEY=
EOF

# 停止旧服务
systemctl stop family-health 2>/dev/null || true

# 创建 systemd 服务
cat > /etc/systemd/system/family-health.service << 'SVC'
[Unit]
Description=Family Health App Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/family-health/backend
ExecStart=/root/family-health/backend/server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable family-health
systemctl start family-health

echo "  后端已启动!"
REMOTE

# 4. 验证
echo "[4/4] 验证部署..."
sleep 2
RESULT=$(ssh "$SSH_USER@$SERVER_IP" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/api/v1/auth/wechat/auth-url" 2>/dev/null || echo "failed")

echo ""
echo "========================================"
echo "  部署结果"
echo "========================================"
if [ "$RESULT" = "200" ]; then
    echo "  ✅ 后端运行正常 (HTTP 200)"
    echo ""
    echo "  📱 App 设置页 → 服务器设置："
    echo "  http://$SERVER_IP:8080/api/v1"
    echo ""
    echo "  或者在编译时内置地址："
    echo "  cd app && flutter build macos --release --dart-define=API_BASE_URL=http://$SERVER_IP:8080/api/v1"
else
    echo "  ⚠️ 部署可能有问题，请检查:"
    echo "  ssh $SSH_USER@$SERVER_IP"
    echo "  systemctl status family-health"
    echo "  journalctl -u family-health -f"
fi
echo ""
echo "管理命令:"
echo "  systemctl status family-health    # 查看状态"
echo "  journalctl -u family-health -f    # 查看日志"
echo "  systemctl restart family-health    # 重启"
echo "========================================"
