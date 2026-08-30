import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { getBalance, getTransactionHistory, awardGems, type GemType } from '../lib/gemService.js';
import { requireGemServiceKey, type GemServiceKeyRequest } from '../middleware/gemServiceKeyAuth.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const AwardGemsBodySchema = z.object({
  user_id: z.string().uuid(),
  gem_type: z.enum(['yellow', 'blue', 'red']),
  amount: z.number().int().positive(),
  idempotency_key: z.string().min(1).max(255),
});

const TransactionQuerySchema = z.object({
  gem_type: z.enum(['red', 'blue', 'yellow']).optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

// ---------------------------------------------------------------------------
// POST /api/gems/award
// Auth: requireGemServiceKey (X-Service-Key header from GEMS_SERVICE_KEYS map)
//
// Awards gems to a user on behalf of an external service (CTC, VQ, etc.).
// Idempotent: duplicate idempotency_key returns 200 with is_duplicate: true.
// Per-key gem_type enforcement: returns 422 FORBIDDEN_GEM_TYPE if the service
// key is not permitted to award the requested gem_type.
// ---------------------------------------------------------------------------

router.post(
  '/award',
  requireGemServiceKey,
  async (req: Request, res: Response): Promise<void> => {
    const parsed = AwardGemsBodySchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({
        error: 'VALIDATION_ERROR',
        issues: parsed.error.issues,
      });
      return;
    }

    const body = parsed.data;
    const serviceReq = req as GemServiceKeyRequest;

    // Per-key gem_type permission check
    if (!serviceReq.permittedGemTypes.includes(body.gem_type)) {
      res.status(422).json({
        error: 'FORBIDDEN_GEM_TYPE',
        permitted: serviceReq.permittedGemTypes,
      });
      return;
    }

    try {
      const result = await awardGems({
        userId: body.user_id,
        gemType: body.gem_type as GemType,
        amount: body.amount,
        idempotencyKey: body.idempotency_key,
      });

      res.status(200).json({
        gem_type: result.gem_type,
        amount: result.amount,
        new_balance: result.new_balance,
        is_duplicate: result.is_duplicate,
      });
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'INFORM_TIER_NO_BLUE_RED') {
        res.status(422).json({ error: 'INFORM_TIER_NO_BLUE_RED' });
        return;
      }
      if (code === 'NOT_CONNECTED') {
        res.status(404).json({ error: 'User has no connected profile' });
        return;
      }
      if (code === 'ACCOUNT_DELETED') {
        res.status(404).json({ error: 'ACCOUNT_DELETED' });
        return;
      }
      if (code === 'INVALID_AMOUNT') {
        res.status(422).json({ error: 'INVALID_AMOUNT' });
        return;
      }
      console.error('[POST /gems/award] error:', err);
      res.status(500).json({ error: 'INTERNAL_ERROR' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/gems/balance
// Auth: requireAuth + requireConnected
//
// Returns the authenticated user's current gem balances per type.
// ---------------------------------------------------------------------------

router.get(
  '/balance',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const balance = await getBalance(authReq.userId);
      res.status(200).json(balance);
    } catch (err) {
      console.error('[GET /gems/balance] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch gem balance' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/gems/transactions
// Auth: requireAuth + requireConnected
//
// Returns paginated gem transaction history for the authenticated user.
// Query params: gem_type (optional), limit (default 50, max 100), offset (default 0)
// ---------------------------------------------------------------------------

router.get(
  '/transactions',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = TransactionQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid query parameters',
      });
      return;
    }

    const { gem_type, limit, offset } = parsed.data;

    try {
      const result = await getTransactionHistory(authReq.userId, {
        limit,
        offset,
        gemType: gem_type as GemType | undefined,
      });
      res.status(200).json({ ...result, limit, offset });
    } catch (err) {
      console.error('[GET /gems/transactions] error:', err);
      res
        .status(500)
        .json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch transaction history' });
    }
  }
);

export default router;
