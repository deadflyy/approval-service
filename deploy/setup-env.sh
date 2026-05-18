#!/bin/bash

set -e

echo "=========================================="
echo "    党组织建设批复系统 - 环境检测与安装"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检测函数
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓ $1 已安装${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ $1 未安装${NC}"
        return 1
    fi
}

# 检查操作系统
echo "[1/6] 检查操作系统..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo -e "${GREEN}✓ 操作系统: $PRETTY_NAME${NC}"
else
    echo -e "${RED}✗ 无法检测操作系统${NC}"
    exit 1
fi

# 检查 Node.js
echo ""
echo "[2/6] 检查 Node.js..."
if check_command node; then
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    echo "  版本: $(node --version)"
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${YELLOW}⚠ Node.js 版本过低，需要升级${NC}"
        NEED_INSTALL_NODE=true
    fi
else
    NEED_INSTALL_NODE=true
fi

# 检查 npm
echo ""
echo "[3/6] 检查 npm..."
check_command npm
if [ $? -eq 0 ]; then
    echo "  版本: $(npm --version)"
fi

# 检查 git
echo ""
echo "[4/6] 检查 git..."
check_command git
if [ $? -eq 1 ]; then
    NEED_INSTALL_GIT=true
fi

# 检查 build-essential
echo ""
echo "[5/6] 检查 build-essential..."
if dpkg -s build-essential &> /dev/null; then
    echo -e "${GREEN}✓ build-essential 已安装${NC}"
else
    echo -e "${YELLOW}⚠ build-essential 未安装${NC}"
    NEED_INSTALL_BUILD=true
fi

# 检查 pm2
echo ""
echo "[6/6] 检查 pm2..."
if check_command pm2; then
    echo "  版本: $(pm2 --version)"
else
    NEED_INSTALL_PM2=true
fi

echo ""
echo "=========================================="
echo "检查完成！"
echo ""

# 汇总需要安装的组件
INSTALL_LIST=""
if [ "$NEED_INSTALL_NODE" = true ]; then
    INSTALL_LIST="$INSTALL_LIST Node.js"
fi
if [ "$NEED_INSTALL_GIT" = true ]; then
    INSTALL_LIST="$INSTALL_LIST Git"
fi
if [ "$NEED_INSTALL_BUILD" = true ]; then
    INSTALL_LIST="$INSTALL_LIST build-essential"
fi
if [ "$NEED_INSTALL_PM2" = true ]; then
    INSTALL_LIST="$INSTALL_LIST PM2"
fi

if [ -z "$INSTALL_LIST" ]; then
    echo -e "${GREEN}所有环境已就绪！${NC}"
    exit 0
fi

echo -e "${YELLOW}需要安装以下组件:$INSTALL_LIST${NC}"
echo ""

# 询问用户是否继续
read -p "是否继续安装？(y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "安装已取消"
    exit 1
fi

# 开始安装
echo ""
echo "=========================================="
echo "开始安装..."
echo "=========================================="
echo ""

# 更新包列表
echo "更新软件包列表..."
apt update -y

# 安装 Node.js
if [ "$NEED_INSTALL_NODE" = true ]; then
    echo ""
    echo "安装 Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    echo -e "${GREEN}✓ Node.js 安装完成${NC}"
fi

# 安装 Git
if [ "$NEED_INSTALL_GIT" = true ]; then
    echo ""
    echo "安装 Git..."
    apt install -y git
    echo -e "${GREEN}✓ Git 安装完成${NC}"
fi

# 安装 build-essential
if [ "$NEED_INSTALL_BUILD" = true ]; then
    echo ""
    echo "安装 build-essential..."
    apt install -y build-essential
    echo -e "${GREEN}✓ build-essential 安装完成${NC}"
fi

# 安装 pm2
if [ "$NEED_INSTALL_PM2" = true ]; then
    echo ""
    echo "安装 PM2..."
    npm install -g pm2
    pm2 startup
    echo -e "${GREEN}✓ PM2 安装完成${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}环境安装完成！${NC}"
echo "=========================================="
