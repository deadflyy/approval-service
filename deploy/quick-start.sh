#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "=========================================="
echo "    党组织建设批复系统 - 快速启动"
echo "=========================================="
echo ""

# 赋予脚本执行权限
chmod +x "$SCRIPT_DIR"/*.sh

echo "脚本权限已设置！"
echo ""
echo "可用命令："
echo "  ./deploy.sh          - 一键部署"
echo "  ./setup-env.sh       - 环境检测与安装"
echo "  ./init-db.sh         - 数据库初始化"
echo "  ./backend.sh         - 后端服务管理"
echo "  ./frontend.sh        - 前端服务管理"
echo ""
echo "详细说明请查看 README.md"
echo ""
