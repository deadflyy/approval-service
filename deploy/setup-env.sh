#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

header "环境检测与安装"

check_command() {
    if command -v "$1" &> /dev/null; then
        info "$1 已安装 ($("$1" --version 2>/dev/null | head -1))"
        return 0
    else
        warn "$1 未安装"
        return 1
    fi
}

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt-get install -y"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
    else
        PKG_MANAGER=""
        warn "未检测到支持的包管理器 (apt/yum/dnf)"
    fi
}

# ─── 检测操作系统 ───
step "1/5" "检查操作系统"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    info "操作系统: $PRETTY_NAME"
else
    warn "无法检测操作系统信息"
fi

detect_package_manager

# ─── 检查 Node.js ───
step "2/5" "检查 Node.js"
NEED_INSTALL_NODE=false
if check_command node; then
    NODE_MAJOR=$(node --version | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -lt 18 ] 2>/dev/null; then
        warn "Node.js 版本过低 (需要 >= 18.x)，当前: v$NODE_MAJOR"
        NEED_INSTALL_NODE=true
    else
        success "Node.js 版本兼容"
    fi
else
    NEED_INSTALL_NODE=true
fi

check_command npm || NEED_INSTALL_NODE=true

# ─── 检查编译工具 (node-gyp 编译 better-sqlite3 依赖) ───
step "3/5" "检查编译工具"
NEED_INSTALL_BUILD=false
command -v make &> /dev/null    && info "make 已安装"    || { warn "make 未安装";    NEED_INSTALL_BUILD=true; }
command -v g++ &> /dev/null     && info "g++ 已安装"     || { warn "g++ 未安装";     NEED_INSTALL_BUILD=true; }
command -v python3 &> /dev/null && info "python3 已安装" || { warn "python3 未安装"; NEED_INSTALL_BUILD=true; }

if [ "$PKG_MANAGER" = "apt" ]; then
    dpkg -s build-essential &> /dev/null && info "build-essential 已安装" || { warn "build-essential 未安装"; NEED_INSTALL_BUILD=true; }
    dpkg -s libsqlite3-dev &> /dev/null  && info "libsqlite3-dev 已安装"  || { warn "libsqlite3-dev 未安装";  NEED_INSTALL_BUILD=true; }
fi

# ─── 检查 git ───
step "4/5" "检查 git"
NEED_INSTALL_GIT=false
check_command git || NEED_INSTALL_GIT=true

# ─── 检查 pm2 ───
step "5/5" "检查 pm2"
NEED_INSTALL_PM2=false
check_command pm2 || NEED_INSTALL_PM2=true

# ─── 汇总结果 ───
echo ""
if ! $NEED_INSTALL_NODE && ! $NEED_INSTALL_GIT && ! $NEED_INSTALL_BUILD && ! $NEED_INSTALL_PM2; then
    success "所有环境已就绪！"
    exit 0
fi

echo -n "需要安装:"
$NEED_INSTALL_NODE  && echo -n " Node.js"
$NEED_INSTALL_BUILD && echo -n " 编译工具链"
$NEED_INSTALL_GIT   && echo -n " Git"
$NEED_INSTALL_PM2   && echo -n " PM2"
echo ""

read -p "是否继续安装？(y/n): " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && { info "安装已取消"; exit 1; }

echo ""
header "开始安装"

$NEED_INSTALL_BUILD && {
    info "安装编译工具..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        apt-get update -y
        apt-get install -y build-essential libsqlite3-dev python3 make g++
    elif [ "$PKG_MANAGER" = "yum" ]; then
        yum install -y make gcc gcc-c++ python3 sqlite-devel
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        dnf install -y make gcc gcc-c++ python3 sqlite-devel
    fi
    success "编译工具安装完成"
}

$NEED_INSTALL_NODE && {
    info "安装 Node.js LTS..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
        apt-get install -y nodejs
    elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
        $PKG_INSTALL nodejs
    fi
    success "Node.js 安装完成 ($(node --version))"
}

$NEED_INSTALL_GIT && {
    $PKG_INSTALL git
    success "Git 安装完成"
}

$NEED_INSTALL_PM2 && {
    npm install -g pm2
    success "PM2 安装完成"
}

echo ""
success "环境安装完成！"
