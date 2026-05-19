#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "$SCRIPT_DIR/common.sh"

header "数据库初始化"

ensure_dir "$DB_DIR"

# ─── 备份现有数据库 ───
if [ -f "$DB_DIR/approval.db" ]; then
    step "1/3" "备份现有数据库"
    BACKUP_FILE="$DB_DIR/approval.db.$(date +%Y%m%d_%H%M%S).backup"
    cp "$DB_DIR/approval.db" "$BACKUP_FILE"
    success "已备份到: $BACKUP_FILE"
else
    step "1/3" "首次初始化"
fi

# ─── 创建表结构 ───
step "2/3" "初始化数据库表结构"
cd "$BACKEND_DIR"

# 验证 better-sqlite3 原生模块可用
if ! verify_better_sqlite3; then
    fail "better-sqlite3 原生模块不可用"
    echo ""
    echo "  请先运行修复脚本: ./fix-sqlite3.sh"
    echo "  或重新部署: ./deploy.sh"
    exit 1
fi

node -e "
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const path = require('path');

const dbPath = path.join(__dirname, 'data', 'approval.db');
console.log('  数据库路径:', dbPath);

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(\`
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('applicant', 'approver', 'liaison', 'admin')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS organizations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        level TEXT CHECK(level IN ('party_committee', 'general_branch', 'branch')),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (parent_id) REFERENCES organizations(id)
    );

    CREATE TABLE IF NOT EXISTS user_org_auth (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        org_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (org_id) REFERENCES organizations(id),
        UNIQUE(user_id, org_id)
    );

    CREATE TABLE IF NOT EXISTS templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        step TEXT NOT NULL,
        filename TEXT NOT NULL,
        variables TEXT NOT NULL DEFAULT '[]',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

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

    CREATE TABLE IF NOT EXISTS batch_number_seq (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        year INTEGER NOT NULL,
        prefix TEXT NOT NULL DEFAULT '沪张江科综委',
        current_seq INTEGER NOT NULL DEFAULT 0,
        UNIQUE(year, prefix)
    );
\`);

const existingAdmin = db.prepare('SELECT id FROM users WHERE username = ?').get('admin');
if (!existingAdmin) {
    const hash = bcrypt.hashSync('admin123', 10);
    db.prepare('INSERT INTO users (username, password_hash, name, role) VALUES (?, ?, ?, ?)')
      .run('admin', hash, '系统管理员', 'admin');
    console.log('  ✓ 默认管理员已创建 (admin / admin123)');
} else {
    console.log('  - 管理员已存在，跳过');
}

db.close();
console.log('  ✓ 表结构初始化完成');
" || { fail "数据库初始化失败"; exit 1; }

success "数据库初始化完成"

# ─── 导入模板 ───
step "3/3" "导入模板文件"
if [ -d "$TEMPLATES_DIR" ] && [ "$(ls -A "$TEMPLATES_DIR"/*.docx 2>/dev/null)" ]; then
    ensure_dir "$DB_DIR/templates"
    cp -r "$TEMPLATES_DIR"/*.docx "$DB_DIR/templates/" 2>/dev/null || true
    node "$SCRIPT_DIR/import-templates.js" || warn "模板导入失败，可稍后重试"
    success "模板导入完成"
else
    warn "模板目录为空或不存在，跳过导入"
fi

echo ""
success "数据库初始化全部完成"
