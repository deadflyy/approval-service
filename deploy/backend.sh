#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
PM2_NAME="approval-backend"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印帮助
show_help() {
    echo "党组织建设批复系统 - 后端服务管理"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令说明:"
    echo "  start    - 启动后端服务"
    echo "  stop     - 停止后端服务"
    echo "  restart  - 重启后端服务"
    echo "  status   - 查看服务状态"
    echo "  logs     - 查看服务日志"
    echo ""
}

# 检查服务状态
check_status() {
    if pm2 describe "$PM2_NAME" &> /dev/null; then
        STATUS=$(pm2 jlist | grep -A 10 "$PM2_NAME" | grep "status" | cut -d'"' -f4)
        if [ "$STATUS" = "online" ]; then
            echo -e "${GREEN}● 运行中${NC}"
        else
            echo -e "${YELLOW}● 已停止${NC}"
        fi
    else
        echo -e "${RED}● 未部署${NC}"
    fi
}

# 启动服务
start_service() {
    echo "启动后端服务..."
    cd "$BACKEND_DIR"
    
    # 检查是否已安装依赖
    if [ ! -d "node_modules" ]; then
        echo "安装后端依赖..."
        npm install
    fi
    
    # 使用 pm2 启动
    pm2 start "npm run dev" --name "$PM2_NAME" --cwd "$BACKEND_DIR"
    
    # 保存 pm2 进程列表
    pm2 save
    
    echo -e "${GREEN}✓ 后端服务启动成功${NC}"
    echo "  服务名: $PM2_NAME"
    echo "  地址: http://localhost:3000"
}

# 停止服务
stop_service() {
    echo "停止后端服务..."
    pm2 stop "$PM2_NAME"
    pm2 delete "$PM2_NAME"
    pm2 save
    echo -e "${GREEN}✓ 后端服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo "重启后端服务..."
    pm2 restart "$PM2_NAME"
    echo -e "${GREEN}✓ 后端服务已重启${NC}"
}

# 查看日志
show_logs() {
    pm2 logs "$PM2_NAME"
}

# 主逻辑
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        echo "后端服务状态:"
        check_status
        pm2 list | grep -E "(PM2|name|$PM2_NAME)"
        ;;
    logs)
        show_logs
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
