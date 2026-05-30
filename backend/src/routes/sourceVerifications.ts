// ev-accounts/backend/src/routes/sourceVerifications.ts
/**
 * /api/admin/source-verifications/* — admin-only verification queue routes.
 *
 * Pattern (matches admin.ts):
 *   router.use(requireAuth, requireAdmin) applies both globally.
 *   Every mutation calls logAdminAction() before returning 200.
 */

import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import {
  listSourceVerifications,
  approveSourceVerification,
  markUnfixable,
} from '../lib/sourceVerificationService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/source-verifications
const listQuerySchema = z.object({
  status: z.enum(['unverified', 'verified', 'needs_review']).optional(),
  entity_type: z.enum(['compass_stance', 'readrank_quote']).optional(),
  limit: z.coerce.number().int().min(1).max(200).optional(),
  offset: z.coerce.number().int().min(0).optional(),
  include_unfixable: z
    .enum(['true', 'false'])
    .optional()
    .transform((v) => v === 'true'),
});

router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = listQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const result = await listSourceVerifications(parsed.data);
  res.json(result);
});

// POST /api/admin/source-verifications/:id/approve
const approveBodySchema = z.object({
  url: z.string().url().optional(),
});

router.post('/:id/approve', async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  const parsed = approveBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const id = req.params['id'] as string | undefined;
  if (!id) { res.status(400).json({ error: 'id required' }); return; }

  try {
    const updated = await approveSourceVerification(id, authReq.userId, parsed.data.url);
    await logAdminAction(
      authReq.userId,
      'source_verification.approve',
      null,
      { verification_id: id, new_url: parsed.data.url ?? null }
    );
    res.json(updated);
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'internal error';
    res.status(msg.includes('not found') ? 404 : 500).json({ error: msg });
  }
});

// POST /api/admin/source-verifications/:id/unfixable
const unfixableBodySchema = z.object({
  note: z.string().max(1000).optional(),
});

router.post('/:id/unfixable', async (req: Request, res: Response): Promise<void> => {
  const authReq = req as AuthenticatedRequest;
  const parsed = unfixableBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues });
    return;
  }
  const id = req.params['id'] as string | undefined;
  if (!id) { res.status(400).json({ error: 'id required' }); return; }

  try {
    const updated = await markUnfixable(id, authReq.userId, parsed.data.note);
    await logAdminAction(
      authReq.userId,
      'source_verification.unfixable',
      null,
      { verification_id: id, note: parsed.data.note ?? null }
    );
    res.json(updated);
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'internal error';
    res.status(msg.includes('not found') ? 404 : 500).json({ error: msg });
  }
});

export default router;
