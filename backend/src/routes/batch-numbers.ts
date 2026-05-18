import { Router, Response } from 'express';
import { authenticateToken, requireRole, AuthRequest } from '../middleware/auth';

const router = Router();

router.use(authenticateToken);
router.use(requireRole('admin'));

router.get('/', (req: AuthRequest, res: Response) => {
  const db = req.app.locals.db;
  const year = new Date().getFullYear();

  const seq = db.prepare('SELECT * FROM batch_number_seq WHERE year = ?').get(year);
  res.json(seq || { year, prefix: '沪张江科综委', current_seq: 0 });
});

router.put('/', (req: AuthRequest, res: Response) => {
  const { prefix, current_seq } = req.body;
  const db = req.app.locals.db;
  const year = new Date().getFullYear();

  const existing = db.prepare('SELECT id FROM batch_number_seq WHERE year = ? AND prefix = ?').get(year, prefix);

  if (existing) {
    db.prepare('UPDATE batch_number_seq SET current_seq = ? WHERE year = ? AND prefix = ?').run(current_seq, year, prefix);
  } else {
    db.prepare('INSERT INTO batch_number_seq (year, prefix, current_seq) VALUES (?, ?, ?)').run(year, prefix, current_seq);
  }

  res.json({ message: '更新成功' });
});

export default router;
