import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { authenticateToken, requireRole, AuthRequest } from '../middleware/auth';
import { buildPaginatedQuery, PaginationParams } from '../utils/pagination';
import { paginationValidation } from '../middleware/pagination';

const router = Router();

router.use(authenticateToken);

router.get('/', requireRole('admin'), paginationValidation, (req: AuthRequest, res: Response) => {
  const { role, keyword, page, pageSize } = req.query;
  const db = req.app.locals.db;

  const params: PaginationParams = {
    page: Number(page),
    pageSize: Number(pageSize),
    keyword: keyword as string
  };

  const filters: Record<string, any> = {};

  if (role) {
    filters['role'] = role;
  }

  const result = buildPaginatedQuery(
    db,
    'users',
    'SELECT id, username, name, role, created_at',
    params,
    filters,
    ['username', 'name'],
    '',
    'id'
  );

  res.json(result);
});

router.post('/', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { username, password, name, role } = req.body;
  const db = req.app.locals.db;

  if (!username || !password || !name || !role) {
    return res.status(400).json({ error: '所有字段都是必填的' });
  }

  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) {
    return res.status(400).json({ error: '用户名已存在' });
  }

  const passwordHash = bcrypt.hashSync(password, 10);
  const result = db.prepare('INSERT INTO users (username, password_hash, name, role) VALUES (?, ?, ?, ?)').run(username, passwordHash, name, role);

  res.status(201).json({ id: result.lastInsertRowid, username, name, role });
});

router.put('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { name, role, password } = req.body;
  const db = req.app.locals.db;

  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(id);
  if (!user) {
    return res.status(404).json({ error: '用户不存在' });
  }

  if (password) {
    const passwordHash = bcrypt.hashSync(password, 10);
    db.prepare('UPDATE users SET name = ?, role = ?, password_hash = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(name, role, passwordHash, id);
  } else {
    db.prepare('UPDATE users SET name = ?, role = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(name, role, id);
  }

  res.json({ message: '更新成功' });
});

router.delete('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(id);
  if (!user) {
    return res.status(404).json({ error: '用户不存在' });
  }

  db.prepare('DELETE FROM users WHERE id = ?').run(id);
  res.json({ message: '删除成功' });
});

router.get('/:id/organizations', (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  if (!req.user) {
    return res.status(401).json({ error: '未认证' });
  }

  if (req.user.role !== 'admin' && Number(id) !== req.user.id) {
    return res.status(403).json({ error: '权限不足' });
  }

  const orgs = db.prepare(`
    SELECT o.* FROM organizations o
    JOIN user_org_auth uoa ON o.id = uoa.org_id
    WHERE uoa.user_id = ?
  `).all(id);

  res.json(orgs);
});

router.post('/:id/organizations', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { orgIds } = req.body;
  const db = req.app.locals.db;

  db.prepare('DELETE FROM user_org_auth WHERE user_id = ?').run(id);

  const insert = db.prepare('INSERT INTO user_org_auth (user_id, org_id) VALUES (?, ?)');
  for (const orgId of orgIds) {
    insert.run(id, orgId);
  }

  res.json({ message: '授权更新成功' });
});

export default router;
