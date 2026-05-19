#!/bin/bash
# 公共函数库 - 供所有部署脚本引用

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

_COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
SCRIPT_DIR="${SCRIPT_DIR:-$_COMMON_DIR}"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$_COMMON_DIR/.." && pwd)}"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
DB_DIR="$BACKEND_DIR/data"
TEMPLATES_DIR="$PROJECT_DIR/templates"

info()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
success() { echo -e "${GREEN}  ✓ $*${NC}"; }
fail()    { echo -e "${RED}  ✗ $*${NC}"; }

header() {
    local title="$1"
    local len=${#title}
    local border
    border=$(printf '=%.0s' $(seq 1 $((len + 8))))
    echo ""
    echo "$border"
    echo "    $title"
    echo "$border"
    echo ""
}

step() {
    local num="$1"
    local desc="$2"
    echo ""
    echo -e "${CYAN}[$num]${NC} $desc"
}

# 确保目录存在
ensure_dir() {
    [ -d "$1" ] || mkdir -p "$1"
}

# 安全停止 pm2 应用
pm2_stop_safe() {
    local name="$1"
    pm2 describe "$name" &> /dev/null && {
        pm2 stop "$name" 2>/dev/null || true
        pm2 delete "$name" 2>/dev/null || true
    }
}

# 获取 pm2 应用状态
pm2_get_status() {
    local name="$1"
    if pm2 describe "$name" &> /dev/null; then
        local status
        status=$(pm2 jlist 2>/dev/null | python3 -c "
import sys,json
try:
    apps=json.load(sys.stdin)
    for a in apps:
        if a['name']=='$name':
            print(a['pm2_env']['status'])
            break
except: print('unknown')
" 2>/dev/null || echo "unknown")
        echo "$status"
    else
        echo "not_deployed"
    fi
}

# 打印 pm2 应用状态
pm2_show_status() {
    local name="$1"
    local label="$2"
    local status
    status=$(pm2_get_status "$name")
    case "$status" in
        online)        echo -e "  $label: ${GREEN}● 运行中${NC}" ;;
        stopped)       echo -e "  $label: ${YELLOW}● 已停止${NC}" ;;
        not_deployed)  echo -e "  $label: ${RED}● 未部署${NC}" ;;
        *)             echo -e "  $label: ${YELLOW}● $status${NC}" ;;
    esac
}

# 检查命令是否存在
require_command() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! command -v "$cmd" &> /dev/null; then
        error "$cmd 未安装，请先运行: ./setup-env.sh"
        exit 1
    fi
}

# 安全执行命令，失败时打印错误并退出
safe_run() {
    local desc="$1"
    shift
    info "$desc ..."
    if ! "$@"; then
        fail "$desc 失败"
        exit 1
    fi
    success "$desc 完成"
}

# 验证 better-sqlite3 原生模块是否可用
# 返回 0 = 可用, 1 = 不可用
verify_better_sqlite3() {
    cd "$BACKEND_DIR"
    node -e "
const Database = require('better-sqlite3');
const db = new Database(':memory:');
db.exec('CREATE TABLE _t (id INT)');
db.close();
console.log('OK');
" 2>&1 | grep -q "OK"
}
