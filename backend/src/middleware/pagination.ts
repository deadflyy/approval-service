import { Request, Response, NextFunction } from 'express';
import { validatePaginationParams } from '../utils/pagination';

export function paginationValidation(req: Request, res: Response, next: NextFunction) {
  const { valid, errors } = validatePaginationParams(req.query);

  if (!valid) {
    return res.status(400).json({ error: errors.join(', ') });
  }

  // Parse and normalize pagination params
  req.query.page = String(Math.max(1, Number(req.query.page) || 1));
  req.query.pageSize = String([10, 20, 50, 100].includes(Number(req.query.pageSize)) ? Number(req.query.pageSize) : 20);

  next();
}
