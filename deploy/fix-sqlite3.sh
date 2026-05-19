#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

header "修复 better-sqlite3"

# ─── 检查编译工具 ───
step "1/4" "检查编译环境"
NEED_INSTALL=false
command -v make &> /dev/null    && info "make 已安装"    || { warn "make 未安装";    NEED_INSTALL=true; }
command -v g++ &> /dev/null     && info "g++ 已安装"     || { warn "g++ 未安装";     NEED_INSTALL=true; }
command -v python3 &> /dev/null && info "python3 已安装" || { warn "python3 未安装"; NEED_INSTALL=true; }

if [ "$NEED_INSTALL" = true ]; then
    echo ""
    read -p "需要安装编译工具，是否继续？(y/n): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { info "操作已取消"; exit 1; }

    step "2/4" "安装编译工具"
    if command -v apt-get &> /dev/null; then
        apt-get update -y
        apt-get install -y build-essential libsqlite3-dev python3 make g++
    elif command -v yum &> /dev/null; then
        yum install -y make gcc gcc-c++ python3 sqlite-devel
    elif command -v dnf &> /dev/null; then
        dnf install -y make gcc gcc-c++ python3 sqlite-devel
    fi
    success "编译工具安装完成"
else
    step "2/4" "编译环境就绪"
    success "编译工具已就绪"
fi

# ─── 清理并重新编译 ───
step "3/4" "清理并重新编译 better-sqlite3"
cd "$BACKEND_DIR"

info "清理旧依赖..."
rm -rf node_modules package-lock.json
npm cache clean --force 2>/dev/null || true

info "重新安装依赖..."
npm install || { fail "npm install 失败"; exit 1; }

info "编译 better-sqlite3..."
npx --yes node-gyp rebuild --directory=node_modules/better-sqlite3 || {
    fail "better-sqlite3 编译失败"
    echo ""
    echo "  当前环境: Node.js $(node --version), $(uname -s) $(uname -m)"
    exit 1
}
success "better-sqlite3 编译完成"

# ─── 验证 ───
step "4/4" "验证安装"
if verify_better_sqlite3; then
    success "better-sqlite3 工作正常"
else
    fail "better-sqlite3 验证失败"
    exit 1
fi

# ─── 初始化数据库 ───
echo ""
read -p "是否重新初始化数据库？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/init-db.sh"
fi

echo ""
success "修复完成！可执行 ./backend.sh start 启动服务"
