import { Router } from 'express';
import { z } from 'zod';
import { requireServiceKey, type ServiceKeyRequest } from '../middleware/serviceKeyAuth.js';
import { awardXp, XP_SOURCES } from '../lib/xpService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

// Validation schema for POST /api/xp/award body
const AwardXpBodySchema = z.object({
  user_id: z.string().uuid(),
  source: z.enum(XP_SOURCES),
  amount: z.number().int().positive(),
  idempotency_key: z.string().min(1).max(255),
  metadata: z.record(z.unknown()).optional(),
});

// ---------------------------------------------------------------------------
// POST /api/xp/award
// Auth: requireServiceKey (X-Service-Key header)
//
// Server-to-server endpoint for feature repos (Validation Quests, Civic Trivia
// Championship) to award XP to Connected users. Each service key is authorized
// only for specific source types — a valid key + unauthorized source → 422.
//
// Idempotency is enforced at the DB layer: the same idempotency_key always
// returns 200 with is_duplicate: true and no second ledger row.
// ---------------------------------------------------------------------------

router.post(
  '/award',
  requireServiceKey,
  async (req: Request, res: Response): Promise<void> => {
    const serviceReq = req as ServiceKeyRequest;

    // 1. Validate body
    const parsed = AwardXpBodySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid request body',
      });
      return;
    }

    const { user_id, source, amount, idempotency_key, metadata } = parsed.data;

    // 2. Check per-key source authorization.
    // Each service key is authorized for specific source types only.
    // A valid key using an unauthorized source → 422 (per CONTEXT.md spec).
    if (!serviceReq.permittedSources.includes(source)) {
      res.status(422).json({
        code: 'SOURCE_NOT_PERMITTED',
        message: `This service key is not authorized to award source '${source}'`,
      });
      return;
    }

    // 3. Call xpService — delegates to award_xp RPC
    try {
      const result = await awardXp({
        userId: user_id,
        source,
        amount,
        idempotencyKey: idempotency_key,
        metadata,
      });
      res.status(200).json(result);
    } catch (err: unknown) {
      const error = err as Error & { code?: string };
      if (error.code === 'NOT_CONNECTED') {
        res.status(404).json({ error: 'User not found or not Connected tier' });
        return;
      }
      if (error.code === 'INVALID_AMOUNT') {
        res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Amount must be positive' });
        return;
      }
      console.error('[POST /api/xp/award] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to award XP' });
    }
  }
);

export default router;
