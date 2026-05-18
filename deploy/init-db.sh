#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
DB_DIR="$BACKEND_DIR/data"
TEMPLATES_DIR="$PROJECT_DIR/templates"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "    党组织建设批复系统 - 数据库初始化"
echo "=========================================="
echo ""

# 创建数据目录
echo "[1/4] 创建数据目录..."
mkdir -p "$DB_DIR"
mkdir -p "$DB_DIR/templates"
echo -e "${GREEN}✓ 数据目录创建完成${NC}"

# 备份现有数据库（如果存在）
if [ -f "$DB_DIR/approval.db" ]; then
    echo ""
    echo "[2/4] 备份现有数据库..."
    BACKUP_FILE="$DB_DIR/approval.db.$(date +%Y%m%d_%H%M%S).backup"
    cp "$DB_DIR/approval.db" "$BACKUP_FILE"
    echo -e "${GREEN}✓ 数据库已备份到: $BACKUP_FILE${NC}"
fi

# 创建数据库初始化脚本
echo ""
echo "[3/4] 初始化数据库..."
node << 'EOF'
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');

const projectDir = path.dirname(path.dirname(__dirname));
const dbPath = path.join(projectDir, 'backend', 'data', 'approval.db');

console.log('  数据库路径:', dbPath);

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

console.log('  创建表结构...');

// 创建用户表
db.exec(`
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('applicant', 'approver', 'liaison', 'admin')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
`);

// 创建组织表
db.exec(`
    CREATE TABLE IF NOT EXISTS organizations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        level TEXT CHECK(level IN ('party_committee', 'general_branch', 'branch')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES organizations(id)
    );
`);

// 创建用户-组织关联表
db.exec(`
    CREATE TABLE IF NOT EXISTS user_org_auth (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        org_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (org_id) REFERENCES organizations(id),
        UNIQUE(user_id, org_id)
    );
`);

// 创建模板表
db.exec(`
    CREATE TABLE IF NOT EXISTS templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        step TEXT NOT NULL,
        filename TEXT NOT NULL,
        variables TEXT NOT NULL DEFAULT '[]',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
`);

// 创建请示表
db.exec(`
    CREATE TABLE IF NOT EXISTS requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        org_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        step TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('draft', 'pending', 'approved', 'rejected', 'signed', 'printed', 'collected')),
        page_count INTEGER,
        attachment_count INTEGER,
        involved_orgs TEXT,
        involved_org_count INTEGER DEFAULT 0,
        new_org_info TEXT,
        meeting_time TEXT,
        secretary_candidate TEXT,
        deputy_secretary_candidate TEXT,
        committee_members TEXT,
        reject_reason TEXT,
        liaison_id INTEGER,
        batch_number TEXT,
        approval_doc_path TEXT,
        has_senior_leader INTEGER DEFAULT 0,
        branch_count INTEGER DEFAULT 0,
        general_branch_count INTEGER DEFAULT 0,
        committee_count INTEGER DEFAULT 0,
        party_committee_secretary_count INTEGER DEFAULT 0,
        party_committee_deputy_count INTEGER DEFAULT 0,
        party_committee_member_count INTEGER DEFAULT 0,
        general_branch_secretary_count INTEGER DEFAULT 0,
        general_branch_deputy_count INTEGER DEFAULT 0,
        general_branch_member_count INTEGER DEFAULT 0,
        branch_secretary_count INTEGER DEFAULT 0,
        branch_deputy_count INTEGER DEFAULT 0,
        branch_member_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (org_id) REFERENCES organizations(id),
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (liaison_id) REFERENCES users(id)
    );
`);

// 创建批复表
db.exec(`
    CREATE TABLE IF NOT EXISTS approvals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_id INTEGER NOT NULL,
        batch_number TEXT NOT NULL,
        content TEXT,
        doc_path TEXT,
        approver_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (request_id) REFERENCES requests(id),
        FOREIGN KEY (approver_id) REFERENCES users(id)
    );
`);

// 创建批次号序列表
db.exec(`
    CREATE TABLE IF NOT EXISTS batch_number_seq (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        prefix TEXT NOT NULL DEFAULT '沪张江科综委',
        current_seq INTEGER NOT NULL DEFAULT 0,
        UNIQUE(year, prefix)
    );
`);

console.log('  表结构创建完成');

// 插入默认管理员
console.log('  创建默认管理员账号...');
const existingAdmin = db.prepare('SELECT * FROM users WHERE username = ?').get('admin');
if (!existingAdmin) {
    const passwordHash = bcrypt.hashSync('admin123', 10);
    db.prepare(`
        INSERT INTO users (username, password_hash, name, role)
        VALUES (?, ?, ?, ?)
    `).run('admin', passwordHash, '系统管理员', 'admin');
    console.log('  ✓ 默认管理员创建成功');
    console.log('    用户名: admin');
    console.log('    密码: admin123');
    console.log('    角色: 系统管理员');
} else {
    console.log('  - 管理员已存在，跳过创建');
}

db.close();
console.log('  数据库初始化完成');
EOF

echo -e "${GREEN}✓ 数据库初始化完成${NC}"

# 导入模板
echo ""
echo "[4/4] 导入模板文件..."
if [ -d "$TEMPLATES_DIR" ]; then
    cp -r "$TEMPLATES_DIR"/* "$DB_DIR/templates/" 2>/dev/null || true
    
    node "$SCRIPT_DIR/import-templates.js"

    echo -e "${GREEN}✓ 模板导入完成${NC}"
else
    echo -e "${YELLOW}⚠ 模板目录不存在，跳过导入${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}数据库初始化完成！${NC}"
echo "=========================================="
echo ""
echo "默认管理员账号："
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
