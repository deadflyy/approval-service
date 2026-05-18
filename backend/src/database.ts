import Database from 'better-sqlite3';
import path from 'path';
import bcrypt from 'bcryptjs';

const DB_PATH = path.join(__dirname, '..', 'data', 'approval.db');

export function initDatabase(): Database.Database {
  const fs = require('fs');
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  const db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

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
  `);

  const existingAdmin = db.prepare('SELECT * FROM users WHERE username = ?').get('admin');
  if (!existingAdmin) {
    const passwordHash = bcrypt.hashSync('admin123', 10);
    db.prepare(`
      INSERT INTO users (username, password_hash, name, role)
      VALUES (?, ?, ?, ?)
    `).run('admin', passwordHash, '系统管理员', 'admin');
  }

  return db;
}
