#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "    党组织建设批复系统 - 一键部署"
echo "=========================================="
echo ""
echo "项目目录: $PROJECT_DIR"
echo ""

# 检查是否 root 用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}警告: 建议使用 root 用户或 sudo 运行此脚本${NC}"
    echo ""
fi

# 步骤1: 环境检测与安装
echo "[1/6] 环境检测与安装..."
"$SCRIPT_DIR/setup-env.sh"

# 步骤2: 安装后端依赖
echo ""
echo "[2/6] 安装后端依赖..."
cd "$PROJECT_DIR/backend"
if [ ! -d "node_modules" ]; then
    npm install
fi
echo -e "${GREEN}✓ 后端依赖安装完成${NC}"

# 步骤3: 数据库初始化
echo ""
echo "[3/6] 数据库初始化..."
"$SCRIPT_DIR/init-db.sh"

# 步骤4: 启动后端服务
echo ""
echo "[4/6] 启动后端服务..."
"$SCRIPT_DIR/backend.sh" stop 2>/dev/null || true
"$SCRIPT_DIR/backend.sh" start

# 步骤5: 安装前端依赖并构建
echo ""
echo "[5/6] 安装前端依赖并构建..."
cd "$PROJECT_DIR/frontend"
if [ ! -d "node_modules" ]; then
    npm install
fi
"$SCRIPT_DIR/frontend.sh" build

# 步骤6: 启动前端服务
echo ""
echo "[6/6] 启动前端服务..."
"$SCRIPT_DIR/frontend.sh" stop 2>/dev/null || true
"$SCRIPT_DIR/frontend.sh" start

echo ""
echo "=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "服务信息:"
"$SCRIPT_DIR/backend.sh" status
"$SCRIPT_DIR/frontend.sh" status
echo ""
echo "访问地址:"
echo "  前端: http://$(hostname -I | awk '{print $1}'):4173"
echo "  后端: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "默认管理员账号:"
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
echo "服务管理命令:"
echo "  后端: $SCRIPT_DIR/backend.sh {start|stop|restart|status|logs}"
echo "  前端: $SCRIPT_DIR/frontend.sh {start|stop|restart|status|logs|build}"
echo ""
echo "注意: 请及时修改默认管理员密码！"
echo ""
