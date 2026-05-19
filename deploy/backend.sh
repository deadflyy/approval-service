#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

PM2_NAME="approval-backend"

show_help() {
    echo "后端服务管理"
    echo ""
    echo "用法: $0 {start|stop|restart|status|logs}"
    echo ""
    echo "命令:"
    echo "  start    启动后端服务"
    echo "  stop     停止后端服务"
    echo "  restart  重启后端服务"
    echo "  status   查看服务状态"
    echo "  logs     查看服务日志"
}

start_service() {
    info "启动后端服务..."
    cd "$BACKEND_DIR"

    [ -d "node_modules" ] || {
        info "安装后端依赖..."
        npm install || { fail "依赖安装失败"; return 1; }
    }

    pm2 start "npm run start" --name "$PM2_NAME" --cwd "$BACKEND_DIR"
    pm2 save 2>/dev/null

    # 等待 2 秒后检查状态
    sleep 2
    local status
    status=$(pm2_get_status "$PM2_NAME")
    if [ "$status" = "online" ]; then
        success "后端服务启动成功"
        echo "  地址: http://localhost:3000"
    else
        fail "后端服务启动异常 (状态: $status)"
        echo ""
        echo "  查看日志: $0 logs"
        return 1
    fi
}

stop_service() {
    info "停止后端服务..."
    pm2_stop_safe "$PM2_NAME"
    pm2 save 2>/dev/null || true
    success "后端服务已停止"
}

restart_service() {
    info "重启后端服务..."
    if pm2 describe "$PM2_NAME" &> /dev/null; then
        pm2 restart "$PM2_NAME"
        sleep 2
        local status
        status=$(pm2_get_status "$PM2_NAME")
        if [ "$status" = "online" ]; then
            success "后端服务已重启"
        else
            fail "重启后服务异常 (状态: $status)"
            echo "  查看日志: $0 logs"
            return 1
        fi
    else
        warn "服务未部署，执行启动..."
        start_service
    fi
}

show_logs() {
    pm2 logs "$PM2_NAME" --lines 50
}

case "${1:-}" in
    start)   start_service ;;
    stop)    stop_service ;;
    restart) restart_service ;;
    status)
        echo "后端服务状态:"
        pm2_show_status "$PM2_NAME" "后端"
        ;;
    logs)    show_logs ;;
    *)       show_help; exit 1 ;;
esac
