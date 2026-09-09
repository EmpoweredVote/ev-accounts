import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { getBalance, getTransactionHistory, type GemType } from '../lib/gemService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const TransactionQuerySchema = z.object({
  gem_type: z.enum(['red', 'blue', 'yellow']).optional(),
  limit: z.coerce.number().min(1).max(100).default(50),
  offset: z.coerce.number().min(0).default(0),
});

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
