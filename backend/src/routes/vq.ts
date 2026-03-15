import { Router } from 'express';
import { z } from 'zod';
import { requireGemServiceKey, type GemServiceKeyRequest } from '../middleware/gemServiceKeyAuth.js';
import { confirmVqStance } from '../lib/vqService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const ConfirmStanceBodySchema = z.object({
  politician_id: z.string().uuid(),
  topic_id: z.string().uuid(),
  confirmed_value: z.number().int().min(1).max(5),
  correct_user_ids: z.array(z.string().uuid()).default([]),
  incorrect_user_ids: z.array(z.string().uuid()).default([]),
  idempotency_key: z.string().min(1).max(255),
  gems_amount: z.number().int().positive().default(1),
});

// ---------------------------------------------------------------------------
// POST /api/vq/confirm-stance
// Auth: requireGemServiceKey (Bearer token from GEMS_SERVICE_KEYS map)
//
// Resolves a Validation Quest question. Atomically awards Red Gems and
// adjusts verification_ratings for all participants, then upserts the
// confirmed politician stance.
//
// Idempotent: duplicate idempotency_key returns 200 with replayed: true
// and no side effects (RPC handles caching).
//
// Per-key gem_type enforcement: the calling service key must be permitted
// to award 'red' gems (same pattern as POST /api/gems/award).
// ---------------------------------------------------------------------------

router.post(
  '/confirm-stance',
  requireGemServiceKey,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = ConfirmStanceBodySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        error: 'VALIDATION_ERROR',
        issues: parsed.error.issues,
      });
      return;
    }

    const body = parsed.data;
    const serviceReq = req as GemServiceKeyRequest;

    // Per-key gem_type permission check — VQ confirm-stance always awards red
    if (!serviceReq.permittedGemTypes.includes('red')) {
      res.status(422).json({
        error: 'FORBIDDEN_GEM_TYPE',
        permitted: serviceReq.permittedGemTypes,
      });
      return;
    }

    try {
      const result = await confirmVqStance({
        politicianId:    body.politician_id,
        topicId:         body.topic_id,
        confirmedValue:  body.confirmed_value,
        correctUserIds:  body.correct_user_ids,
        incorrectUserIds: body.incorrect_user_ids,
        idempotencyKey:  body.idempotency_key,
        gemsAmount:      body.gems_amount,
      });

      res.status(200).json(result);
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'QUESTION_NOT_FOUND') {
        res.status(404).json({ error: 'QUESTION_NOT_FOUND' });
        return;
      }
      if (code === 'INVALID_VALUE') {
        res.status(422).json({ error: 'INVALID_VALUE' });
        return;
      }
      console.error('[POST /vq/confirm-stance] error:', err);
      res.status(500).json({ error: 'INTERNAL_ERROR' });
    }
  }
);

export default router;
