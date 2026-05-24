#!/bin/bash
# 家庭健康 App - 一键启动脚本
# 自动启动后端服务并打开 App

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
APP_PATH="$SCRIPT_DIR/app/build/macos/Build/Products/Release/family_health.app"
DB_DIR="$HOME/.family-health"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    家庭健康 App - 一键启动              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Ensure backend binary exists
if [ ! -f "$BACKEND_DIR/bin/server" ]; then
    echo -e "${YELLOW}后端正在编译...${NC}"
    cd "$BACKEND_DIR"
    go build -o bin/server ./cmd/server
fi

# Ensure DB directory exists
mkdir -p "$DB_DIR"

# Start backend
echo -e "${GREEN}▶ 启动后端服务...${NC}"
cd "$BACKEND_DIR"
./bin/server &
BACKEND_PID=$!
echo -e "${GREEN}  后端已启动 (PID: $BACKEND_PID)${NC}"

# Wait for backend to be ready
for i in $(seq 1 10); do
    if curl -s -o /dev/null http://localhost:8080/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{"phone":"","password":""}' 2>/dev/null; then
        break
    fi
    sleep 0.5
done

echo -e "${GREEN}▶ 启动 App...${NC}"
open "$APP_PATH"

echo ""
echo -e "${GREEN}✅ 启动完成！${NC}"
echo -e "  后端: http://localhost:8080"
echo -e "  数据: $DB_DIR/data.db"
echo ""
echo -e "按 Ctrl+C 停止后端服务"

# Wait and cleanup on exit
trap "echo ''; echo -e '${GREEN}正在关闭后端...${NC}'; kill $BACKEND_PID 2>/dev/null; echo -e '${GREEN}已关闭${NC}'" EXIT
wait $BACKEND_PID
