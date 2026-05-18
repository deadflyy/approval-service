import { Router, Response } from 'express';
import bcrypt from 'bcryptjs';
import { generateToken, AuthRequest } from '../middleware/auth';

const router = Router();

router.post('/login', (req: AuthRequest, res: Response) => {
  const { username, password } = req.body;
  const db = req.app.locals.db;

  if (!username || !password) {
    return res.status(400).json({ error: '用户名和密码不能为空' });
  }

  const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username);
  if (!user) {
    return res.status(401).json({ error: '用户名或密码错误' });
  }

  const validPassword = bcrypt.compareSync(password, user.password_hash);
  if (!validPassword) {
    return res.status(401).json({ error: '用户名或密码错误' });
  }

  const token = generateToken({
    id: user.id,
    username: user.username,
    role: user.role,
    name: user.name
  });

  res.json({
    token,
    user: {
      id: user.id,
      username: user.username,
      role: user.role,
      name: user.name
    }
  });
});

router.get('/me', (req: AuthRequest, res: Response) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '未提供认证令牌' });
  }

  const jwt = require('jsonwebtoken');
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'approval-service-secret-key');
    res.json({ user: decoded });
  } catch (err) {
    res.status(403).json({ error: '令牌无效' });
  }
});

export default router;
