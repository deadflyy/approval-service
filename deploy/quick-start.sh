#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "=========================================="
echo "    党组织建设批复系统 - 快速启动"
echo "=========================================="
echo ""

# 赋予脚本执行权限
chmod +x "$SCRIPT_DIR"/*.sh

echo "可用命令:"
echo ""
echo "  部署:"
echo "    ./deploy.sh          一键部署（首次使用）"
echo "    ./setup-env.sh       仅安装环境依赖"
echo "    ./init-db.sh         仅初始化数据库"
echo ""
echo "  服务管理:"
echo "    ./service.sh start|stop|restart|status|logs"
echo "    ./backend.sh start|stop|restart|status|logs"
echo "    ./frontend.sh start|stop|restart|status|logs|build"
echo ""
echo "  故障修复:"
echo "    ./fix-sqlite3.sh     修复 better-sqlite3 (node-gyp 编译)"
echo ""
echo "详细说明请查看 README.md"
