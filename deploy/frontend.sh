#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_DIR/frontend"
PM2_NAME="approval-frontend"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 打印帮助
show_help() {
    echo "党组织建设批复系统 - 前端服务管理"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs|build}"
    echo ""
    echo "命令说明:"
    echo "  start    - 启动前端服务"
    echo "  stop     - 停止前端服务"
    echo "  restart  - 重启前端服务"
    echo "  status   - 查看服务状态"
    echo "  logs     - 查看服务日志"
    echo "  build    - 构建前端静态文件"
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

# 构建前端
build_frontend() {
    echo "构建前端静态文件..."
    cd "$FRONTEND_DIR"
    
    if [ ! -d "node_modules" ]; then
        echo "安装前端依赖..."
        npm install
    fi
    
    npm run build
    echo -e "${GREEN}✓ 前端构建完成${NC}"
}

# 启动服务
start_service() {
    echo "启动前端服务..."
    cd "$FRONTEND_DIR"
    
    # 检查是否已安装依赖
    if [ ! -d "node_modules" ]; then
        echo "安装前端依赖..."
        npm install
    fi
    
    # 检查是否已构建
    if [ ! -d "dist" ]; then
        build_frontend
    fi
    
    # 使用 pm2 启动 preview
    pm2 start "npm run preview" --name "$PM2_NAME" --cwd "$FRONTEND_DIR"
    
    # 保存 pm2 进程列表
    pm2 save
    
    echo -e "${GREEN}✓ 前端服务启动成功${NC}"
    echo "  服务名: $PM2_NAME"
    echo "  地址: http://localhost:4173"
}

# 停止服务
stop_service() {
    echo "停止前端服务..."
    pm2 stop "$PM2_NAME"
    pm2 delete "$PM2_NAME"
    pm2 save
    echo -e "${GREEN}✓ 前端服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo "重启前端服务..."
    pm2 restart "$PM2_NAME"
    echo -e "${GREEN}✓ 前端服务已重启${NC}"
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
        echo "前端服务状态:"
        check_status
        pm2 list | grep -E "(PM2|name|$PM2_NAME)"
        ;;
    logs)
        show_logs
        ;;
    build)
        build_frontend
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
