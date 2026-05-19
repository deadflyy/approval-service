#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

header "党组织建设批复系统 - 一键部署"

info "项目目录: $PROJECT_DIR"

if [ "$EUID" -ne 0 ]; then
    warn "建议使用 root 用户或 sudo 运行此脚本"
fi

# ─── 检查已有服务 ───
BACKEND_STATUS=$(pm2_get_status "approval-backend")
FRONTEND_STATUS=$(pm2_get_status "approval-frontend")

if [ "$BACKEND_STATUS" != "not_deployed" ] || [ "$FRONTEND_STATUS" != "not_deployed" ]; then
    echo ""
    warn "检测到已有服务在运行："
    [ "$BACKEND_STATUS" != "not_deployed" ]  && pm2_show_status "approval-backend"  "后端"
    [ "$FRONTEND_STATUS" != "not_deployed" ] && pm2_show_status "approval-frontend" "前端"
    echo ""
    echo "  重新部署将停止现有服务并重新安装所有依赖。"
    echo ""
    read -p "是否继续重新部署？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "部署已取消"
        exit 0
    fi
fi

# ─── 1. 环境检测 ───
step "1/7" "环境检测与安装"
"$SCRIPT_DIR/setup-env.sh"

# ─── 2. 安装后端依赖 ───
step "2/7" "安装后端依赖"
cd "$BACKEND_DIR"
rm -rf node_modules package-lock.json
npm install || { fail "npm install 失败"; exit 1; }
success "后端依赖安装完成"

# ─── 3. 编译 better-sqlite3 原生模块 ───
step "3/7" "编译 better-sqlite3"
cd "$BACKEND_DIR"
npx --yes node-gyp rebuild --directory=node_modules/better-sqlite3 || {
    fail "better-sqlite3 编译失败"
    echo ""
    echo "  请确认编译工具已安装: ./setup-env.sh"
    exit 1
}
success "better-sqlite3 编译完成"

# ─── 4. 验证 better-sqlite3 ───
step "4/7" "验证 better-sqlite3"
if verify_better_sqlite3; then
    success "better-sqlite3 可用"
else
    fail "better-sqlite3 不可用"
    echo ""
    echo "  运行修复脚本: ./fix-sqlite3.sh"
    exit 1
fi

# ─── 5. 数据库初始化 ───
step "5/7" "数据库初始化"
"$SCRIPT_DIR/init-db.sh"

# ─── 6. 启动后端服务 ───
step "6/7" "启动后端服务"
pm2_stop_safe "approval-backend"
"$SCRIPT_DIR/backend.sh" start

# ─── 7. 构建并启动前端 ───
step "7/7" "构建并启动前端"
cd "$FRONTEND_DIR"
rm -rf node_modules package-lock.json
npm install || { fail "前端 npm install 失败"; exit 1; }
npm run build || { fail "前端构建失败"; exit 1; }
pm2_stop_safe "approval-frontend"
"$SCRIPT_DIR/frontend.sh" start

# ─── 输出部署结果 ───
echo ""
header "部署完成"
echo ""

LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig 2>/dev/null | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -1 || echo "localhost")

pm2_show_status "approval-backend"  "后端服务"
pm2_show_status "approval-frontend" "前端服务"
echo ""
echo "  前端访问: http://${LOCAL_IP}:4173"
echo "  后端 API: http://${LOCAL_IP}:3000"
echo ""
echo "  默认管理员: admin / admin123"
echo ""
warn "请及时修改默认管理员密码！"
echo ""
echo "  服务管理:"
echo "    所有服务: $SCRIPT_DIR/service.sh {start|stop|restart|status|logs}"
echo "    后端:     $SCRIPT_DIR/backend.sh {start|stop|restart|status|logs}"
echo "    前端:     $SCRIPT_DIR/frontend.sh {start|stop|restart|status|logs|build}"
echo ""
