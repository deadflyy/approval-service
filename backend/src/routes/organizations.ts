import { Router, Response } from 'express';
import { authenticateToken, requireRole, AuthRequest } from '../middleware/auth';
import { buildPaginatedQuery, PaginationParams } from '../utils/pagination';
import { paginationValidation } from '../middleware/pagination';

const router = Router();

router.use(authenticateToken);

router.get('/', paginationValidation, (req: AuthRequest, res: Response) => {
  const { level, keyword, page, pageSize } = req.query;
  const db = req.app.locals.db;

  const params: PaginationParams = {
    page: Number(page),
    pageSize: Number(pageSize),
    keyword: keyword as string
  };

  const filters: Record<string, any> = {};

  if (level) {
    filters['level'] = level;
  }

  const result = buildPaginatedQuery(
    db,
    'organizations',
    'SELECT *',
    params,
    filters,
    ['name'],
    '',
    'id'
  );

  res.json(result);
});

router.post('/', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { name, parent_id, level } = req.body;
  const db = req.app.locals.db;

  if (!name || !level) {
    return res.status(400).json({ error: '名称和层级是必填的' });
  }

  const result = db.prepare('INSERT INTO organizations (name, parent_id, level) VALUES (?, ?, ?)').run(name, parent_id || null, level);
  res.status(201).json({ id: result.lastInsertRowid, name, parent_id, level });
});

router.put('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { name, parent_id, level } = req.body;
  const db = req.app.locals.db;

  const org = db.prepare('SELECT id FROM organizations WHERE id = ?').get(id);
  if (!org) {
    return res.status(404).json({ error: '组织不存在' });
  }

  db.prepare('UPDATE organizations SET name = ?, parent_id = ?, level = ? WHERE id = ?').run(name, parent_id || null, level, id);
  res.json({ message: '更新成功' });
});

router.delete('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  const org = db.prepare('SELECT id FROM organizations WHERE id = ?').get(id);
  if (!org) {
    return res.status(404).json({ error: '组织不存在' });
  }

  db.prepare('DELETE FROM organizations WHERE id = ?').run(id);
  res.json({ message: '删除成功' });
});

export default router;
