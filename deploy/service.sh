#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_help() {
    echo "党组织建设批复系统 - 综合服务管理"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令说明:"
    echo "  start    - 启动所有服务"
    echo "  stop     - 停止所有服务"
    echo "  restart  - 重启所有服务"
    echo "  status   - 查看所有服务状态"
    echo "  logs     - 查看所有服务日志"
    echo ""
}

# 启动所有服务
start_all() {
    echo "启动所有服务..."
    "$SCRIPT_DIR/backend.sh" start
    "$SCRIPT_DIR/frontend.sh" start
    echo -e "${GREEN}✓ 所有服务已启动${NC}"
}

# 停止所有服务
stop_all() {
    echo "停止所有服务..."
    "$SCRIPT_DIR/frontend.sh" stop
    "$SCRIPT_DIR/backend.sh" stop
    echo -e "${GREEN}✓ 所有服务已停止${NC}"
}

# 重启所有服务
restart_all() {
    echo "重启所有服务..."
    "$SCRIPT_DIR/backend.sh" restart
    "$SCRIPT_DIR/frontend.sh" restart
    echo -e "${GREEN}✓ 所有服务已重启${NC}"
}

# 查看所有服务状态
show_status() {
    echo "服务状态:"
    echo ""
    echo "后端:"
    "$SCRIPT_DIR/backend.sh" status
    echo ""
    echo "前端:"
    "$SCRIPT_DIR/frontend.sh" status
    echo ""
}

# 查看所有服务日志
show_logs() {
    pm2 logs
}

# 主逻辑
case "$1" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        show_status
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
