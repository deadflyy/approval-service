#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

show_help() {
    echo "综合服务管理"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令:"
    echo "  start    启动所有服务"
    echo "  stop     停止所有服务"
    echo "  restart  重启所有服务"
    echo "  status   查看所有服务状态"
    echo "  logs     查看所有服务日志"
}

start_all() {
    info "启动所有服务..."
    "$SCRIPT_DIR/backend.sh" start
    "$SCRIPT_DIR/frontend.sh" start
    echo ""
    success "所有服务已启动"
}

stop_all() {
    info "停止所有服务..."
    "$SCRIPT_DIR/frontend.sh" stop
    "$SCRIPT_DIR/backend.sh" stop
    echo ""
    success "所有服务已停止"
}

restart_all() {
    info "重启所有服务..."
    "$SCRIPT_DIR/backend.sh" restart
    "$SCRIPT_DIR/frontend.sh" restart
    echo ""
    success "所有服务已重启"
}

show_status() {
    echo "服务状态:"
    echo ""
    pm2_show_status "approval-backend"  "后端"
    pm2_show_status "approval-frontend" "前端"
    echo ""
}

show_logs() {
    pm2 logs --lines 100
}

case "${1:-}" in
    start)   start_all ;;
    stop)    stop_all ;;
    restart) restart_all ;;
    status)  show_status ;;
    logs)    show_logs ;;
    *)       show_help; exit 1 ;;
esac
