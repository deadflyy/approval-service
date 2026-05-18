import { Router, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { authenticateToken, requireRole, AuthRequest } from '../middleware/auth';
import { buildPaginatedQuery, PaginationParams } from '../utils/pagination';
import { paginationValidation } from '../middleware/pagination';

const router = Router();
const UPLOAD_DIR = path.join(__dirname, '..', '..', 'data', 'templates');

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => cb(null, file.originalname)
});

const upload = multer({ storage });

router.use(authenticateToken);

router.get('/', paginationValidation, (req: AuthRequest, res: Response) => {
  const { category, keyword, page, pageSize } = req.query;
  const db = req.app.locals.db;

  const params: PaginationParams = {
    page: Number(page),
    pageSize: Number(pageSize),
    keyword: keyword as string
  };

  const filters: Record<string, any> = {};

  if (category) {
    filters['category'] = category;
  }

  const result = buildPaginatedQuery(
    db,
    'templates',
    'SELECT *',
    params,
    filters,
    ['category', 'step'],
    '',
    'category, step'
  );

  res.json(result);
});

router.post('/', requireRole('admin'), upload.single('file'), (req: AuthRequest, res: Response) => {
  const { category, step } = req.body;
  const file = req.file;
  const db = req.app.locals.db;

  if (!file || !category || !step) {
    return res.status(400).json({ error: '文件、类别和进度都是必填的' });
  }

  const JSZip = require('jszip');
  const content = fs.readFileSync(file.path);

  JSZip.loadAsync(content).then((zip: any) => {
    return zip.file('word/document.xml')?.async('string');
  }).then((xml: string) => {
    const regex = /\$\{(\w+)\}/g;
    const variables: string[] = [];
    let match;
    while ((match = regex.exec(xml)) !== null) {
      if (!variables.includes(match[1])) {
        variables.push(match[1]);
      }
    }

    const result = db.prepare('INSERT INTO templates (category, step, filename, variables) VALUES (?, ?, ?, ?)').run(category, step, file.originalname, JSON.stringify(variables));

    res.status(201).json({
      id: result.lastInsertRowid,
      category,
      step,
      filename: file.originalname,
      variables
    });
  }).catch((err: any) => {
    res.status(500).json({ error: '解析模板文件失败' });
  });
});

router.put('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { category, step } = req.body;
  const db = req.app.locals.db;

  const template = db.prepare('SELECT id FROM templates WHERE id = ?').get(id);
  if (!template) {
    return res.status(404).json({ error: '模板不存在' });
  }

  db.prepare('UPDATE templates SET category = ?, step = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(category, step, id);
  res.json({ message: '更新成功' });
});

router.delete('/:id', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  const template = db.prepare('SELECT filename FROM templates WHERE id = ?').get(id);
  if (!template) {
    return res.status(404).json({ error: '模板不存在' });
  }

  const filePath = path.join(UPLOAD_DIR, template.filename);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }

  db.prepare('DELETE FROM templates WHERE id = ?').run(id);
  res.json({ message: '删除成功' });
});

export default router;
