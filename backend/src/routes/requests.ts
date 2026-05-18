import { Router, Response } from 'express';
import { authenticateToken, requireRole, AuthRequest } from '../middleware/auth';
import { generateApprovalDoc } from '../services/docx-generator';
import { buildPaginatedQuery, PaginationParams } from '../utils/pagination';
import { paginationValidation } from '../middleware/pagination';

const router = Router();

router.use(authenticateToken);

router.get('/', paginationValidation, (req: AuthRequest, res: Response) => {
  const { status, liaison, category, keyword, page, pageSize } = req.query;
  const db = req.app.locals.db;
  const user = req.user!;

  const params: PaginationParams = {
    page: Number(page),
    pageSize: Number(pageSize),
    keyword: keyword as string
  };

  const filters: Record<string, any> = {};
  const conditions: string[] = [];

  // Role-based filtering
  if (user.role === 'applicant') {
    conditions.push('r.user_id = ?');
    params[user.id] = user.id;
  } else if (user.role === 'liaison') {
    conditions.push('r.liaison_id = ?');
    params[user.id] = user.id;
  }

  // Status filter
  if (status) {
    filters['r.status'] = status;
  }

  // Liaison filter
  if (liaison === 'me') {
    filters['r.liaison_id'] = user.id;
  }

  // Category filter
  if (category) {
    filters['r.category'] = category;
  }

  const result = buildPaginatedQuery(
    db,
    'requests r',
    `SELECT r.*, o.name as org_name, u.name as user_name, l.name as liaison_name`,
    params,
    filters,
    ['r.title', 'o.name'],
    `LEFT JOIN organizations o ON r.org_id = o.id
     LEFT JOIN users u ON r.user_id = u.id
     LEFT JOIN users l ON r.liaison_id = l.id`,
    'r.created_at DESC'
  );

  res.json(result);
});

router.post('/', requireRole('applicant'), (req: AuthRequest, res: Response) => {
  const {
    org_id, title, category, step, page_count, attachment_count,
    involved_orgs, involved_org_count, new_org_info, meeting_time,
    secretary_candidate, deputy_secretary_candidate, committee_members,
    has_senior_leader, branch_count, general_branch_count, committee_count,
    party_committee_secretary_count, party_committee_deputy_count, party_committee_member_count,
    general_branch_secretary_count, general_branch_deputy_count, general_branch_member_count,
    branch_secretary_count, branch_deputy_count, branch_member_count
  } = req.body;
  const db = req.app.locals.db;
  const user = req.user!;

  if (!org_id || !title || !category || !step) {
    return res.status(400).json({ error: '组织、标题、类别和进度都是必填的' });
  }

  const auth = db.prepare('SELECT id FROM user_org_auth WHERE user_id = ? AND org_id = ?').get(user.id, org_id);
  if (!auth) {
    return res.status(403).json({ error: '无权为此组织提交请示' });
  }

  const result = db.prepare(`
    INSERT INTO requests (
      org_id, user_id, title, category, step, status, page_count, attachment_count,
      involved_orgs, involved_org_count, new_org_info, meeting_time,
      secretary_candidate, deputy_secretary_candidate, committee_members,
      has_senior_leader, branch_count, general_branch_count, committee_count,
      party_committee_secretary_count, party_committee_deputy_count, party_committee_member_count,
      general_branch_secretary_count, general_branch_deputy_count, general_branch_member_count,
      branch_secretary_count, branch_deputy_count, branch_member_count
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    org_id, user.id, title, category, step, 'pending', page_count || null, attachment_count || null,
    involved_orgs || null, involved_org_count || 0, new_org_info || null, meeting_time || null,
    secretary_candidate || null, deputy_secretary_candidate || null, committee_members || null,
    has_senior_leader || 0, branch_count || 0, general_branch_count || 0, committee_count || 0,
    party_committee_secretary_count || 0, party_committee_deputy_count || 0, party_committee_member_count || 0,
    general_branch_secretary_count || 0, general_branch_deputy_count || 0, general_branch_member_count || 0,
    branch_secretary_count || 0, branch_deputy_count || 0, branch_member_count || 0
  );

  res.status(201).json({ id: result.lastInsertRowid, message: '请示提交成功' });
});

router.get('/:id', (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  const request = db.prepare(`
    SELECT r.*, o.name as org_name, u.name as user_name, l.name as liaison_name
    FROM requests r
    LEFT JOIN organizations o ON r.org_id = o.id
    LEFT JOIN users u ON r.user_id = u.id
    LEFT JOIN users l ON r.liaison_id = l.id
    WHERE r.id = ?
  `).get(id);

  if (!request) {
    return res.status(404).json({ error: '请示不存在' });
  }

  res.json(request);
});

router.post('/:id/approve', requireRole('approver'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;
  const user = req.user!;

  const request = db.prepare(`
    SELECT r.*, o.name as org_name
    FROM requests r
    LEFT JOIN organizations o ON r.org_id = o.id
    WHERE r.id = ?
  `).get(id);
  if (!request) {
    return res.status(404).json({ error: '请示不存在' });
  }

  if (request.status !== 'pending' && request.status !== 'rejected') {
    return res.status(400).json({ error: '请示当前状态不允许审批' });
  }

  const year = new Date().getFullYear();
  const prefix = '沪张江科综委';
  let seq = db.prepare('SELECT current_seq FROM batch_number_seq WHERE year = ? AND prefix = ?').get(year, prefix);

  let newSeq = 1;
  if (seq) {
    newSeq = seq.current_seq + 1;
    db.prepare('UPDATE batch_number_seq SET current_seq = ? WHERE year = ? AND prefix = ?').run(newSeq, year, prefix);
  } else {
    db.prepare('INSERT INTO batch_number_seq (year, prefix, current_seq) VALUES (?, ?, ?)').run(year, prefix, newSeq);
  }

  const batchNumber = `${prefix}〔${year}〕${newSeq}号`;

  // Find matching template
  const template = db.prepare('SELECT filename FROM templates WHERE category = ? AND step = ?').get(request.category, request.step);

  let docPath = null;
  if (template) {
    try {
      const approvalData = {
        desttitle: batchNumber,
        name: request.org_name,
        title: request.title,
        ref_org: request.involved_orgs || request.org_name,
        ref_person: request.secretary_candidate || request.committee_members || '',
        meet_time: request.meeting_time || ''
      };
      docPath = generateApprovalDoc(template.filename, approvalData);
    } catch (err) {
      console.error('生成批复文档失败:', err);
    }
  }

  db.prepare('UPDATE requests SET status = ?, batch_number = ?, approval_doc_path = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run('approved', batchNumber, docPath, id);

  db.prepare('INSERT INTO approvals (request_id, batch_number, approver_id, doc_path) VALUES (?, ?, ?, ?)').run(id, batchNumber, user.id, docPath);

  res.json({ message: '审批通过', batch_number: batchNumber, doc_path: docPath });
});

router.post('/:id/reject', requireRole('approver'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { reason } = req.body;
  const db = req.app.locals.db;

  const request = db.prepare('SELECT * FROM requests WHERE id = ?').get(id);
  if (!request) {
    return res.status(404).json({ error: '请示不存在' });
  }

  if (request.status !== 'pending' && request.status !== 'approved') {
    return res.status(400).json({ error: '请示当前状态不允许退回' });
  }

  db.prepare('UPDATE requests SET status = ?, reject_reason = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run('rejected', reason || null, id);

  res.json({ message: '已退回修改' });
});

router.put('/:id/status', (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { status } = req.body;
  const db = req.app.locals.db;
  const user = req.user!;

  const request = db.prepare('SELECT * FROM requests WHERE id = ?').get(id);
  if (!request) {
    return res.status(404).json({ error: '请示不存在' });
  }

  if (user.role === 'liaison' && request.liaison_id !== user.id) {
    return res.status(403).json({ error: '无权更新此请示状态' });
  }

  const validTransitions: Record<string, string[]> = {
    'approved': ['signed'],
    'signed': ['printed'],
    'printed': ['collected']
  };

  if (!validTransitions[request.status]?.includes(status)) {
    return res.status(400).json({ error: '不允许的状态转换' });
  }

  db.prepare('UPDATE requests SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(status, id);

  res.json({ message: '状态更新成功' });
});

router.put('/:id/liaison', requireRole('admin'), (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const { liaison_id } = req.body;
  const db = req.app.locals.db;

  const request = db.prepare('SELECT id FROM requests WHERE id = ?').get(id);
  if (!request) {
    return res.status(404).json({ error: '请示不存在' });
  }

  db.prepare('UPDATE requests SET liaison_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(liaison_id || null, id);

  res.json({ message: '联络员分配成功' });
});

router.get('/:id/download', (req: AuthRequest, res: Response) => {
  const { id } = req.params;
  const db = req.app.locals.db;

  const request = db.prepare('SELECT approval_doc_path FROM requests WHERE id = ?').get(id);
  if (!request || !request.approval_doc_path) {
    return res.status(404).json({ error: '批复文档不存在' });
  }

  const fs = require('fs');
  if (!fs.existsSync(request.approval_doc_path)) {
    return res.status(404).json({ error: '批复文档文件不存在' });
  }

  res.download(request.approval_doc_path);
});

export default router;
