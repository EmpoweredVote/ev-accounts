import { Router } from 'express';
import { z } from 'zod';
import { requireServiceKey, type ServiceKeyRequest } from '../middleware/serviceKeyAuth.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { awardXp, getXpHistory, getPublicXpProfile, getXpLeaderboard, getMyXpRank, XP_SOURCES, type LeaderboardWindow } from '../lib/xpService.js';
import { unlockReferralCode, maybeRefreshReferralForInvitee } from '../lib/referralService.js';
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
  metadata: z.record(z.string(), z.unknown()).optional(),
});

// Validation schema for GET /api/xp/me/history query params
const HistoryQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(100).default(50),
  offset: z.coerce.number().int().min(0).default(0),
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

      // Fire referral side-effects after the response is sent.
      // Both RPCs are idempotent — safe to call on every award for level-2+ users.
      if (!result.is_duplicate && result.level >= 2) {
        void unlockReferralCode(user_id).catch((err) =>
          console.error('[xp/award] referral unlock failed:', err)
        );
        void maybeRefreshReferralForInvitee(user_id).catch((err) =>
          console.error('[xp/award] referral refresh check failed:', err)
        );
      }
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

// ---------------------------------------------------------------------------
// GET /api/xp/leaderboard
// Auth: none (public)
//
// Returns top 25 Connected users ranked by CTC XP.
// ?window=alltime (default) — ranked by all-time CTC XP
// ?window=week              — ranked by rolling 168-hour CTC XP
// Only users who have earned civic_trivia_championship_score XP appear.
// MUST be registered before GET /:userId to avoid param route shadowing.
// ---------------------------------------------------------------------------

const LeaderboardQuerySchema = z.object({
  window: z.enum(['alltime', 'week']).default('alltime'),
});

router.get('/leaderboard', async (req: Request, res: Response): Promise<void> => {
  const parsed = LeaderboardQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'window must be alltime or week' });
    return;
  }

  try {
    const entries = await getXpLeaderboard(parsed.data.window as LeaderboardWindow);
    res.status(200).json({ mode: parsed.data.window, leaderboard: entries });
  } catch (err) {
    console.error('[GET /api/xp/leaderboard] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch leaderboard' });
  }
});

// ---------------------------------------------------------------------------
// GET /api/xp/leaderboard/me
// Auth: requireAuth + requireConnected
//
// Returns the calling user's rank, XP totals, and XP gap to the player above.
// Returns 404 if the user has never earned CTC XP (not yet ranked).
// ?window=alltime (default) or ?window=week
// MUST be registered before GET /:userId.
// ---------------------------------------------------------------------------

router.get(
  '/leaderboard/me',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = LeaderboardQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'window must be alltime or week' });
      return;
    }

    try {
      const entry = await getMyXpRank(authReq.userId, parsed.data.window as LeaderboardWindow);
      if (!entry) {
        res.status(404).json({ code: 'NOT_RANKED', message: 'No CTC XP earned yet' });
        return;
      }
      res.status(200).json({ mode: parsed.data.window, ...entry });
    } catch (err) {
      console.error('[GET /api/xp/leaderboard/me] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch rank' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/xp/me/history
// Auth: requireAuth + requireConnected
//
// Returns paginated XP transaction history for the authenticated user.
// MUST be registered BEFORE GET /:userId to prevent Express from matching
// the literal "me" as a :userId param.
// ---------------------------------------------------------------------------

router.get(
  '/me/history',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = HistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(422).json({
        code: 'VALIDATION_ERROR',
        message: parsed.error.issues[0]?.message ?? 'Invalid query parameters',
      });
      return;
    }

    const { limit, offset } = parsed.data;

    try {
      const result = await getXpHistory(authReq.userId, { limit, offset });
      res.status(200).json({ ...result, limit, offset });
    } catch (err) {
      console.error('[GET /api/xp/me/history] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch XP history' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/xp/:userId
// Auth: none (public endpoint)
//
// Returns public XP profile: level, total_xp, xp_in_level, xp_to_next_level.
// Full ledger is NOT exposed. Returns 404 for non-Connected users.
// MUST be registered AFTER GET /me/history (param route always last).
// ---------------------------------------------------------------------------

router.get(
  '/:userId',
  async (req: Request, res: Response): Promise<void> => {
    const userId = req.params['userId'] as string;

    // Basic UUID validation
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(userId)) {
      res.status(400).json({ error: 'Invalid userId format' });
      return;
    }

    try {
      const profile = await getPublicXpProfile(userId);
      if (!profile) {
        res.status(404).json({ error: 'User not found or not Connected tier' });
        return;
      }
      res.status(200).json(profile);
    } catch (err) {
      console.error('[GET /api/xp/:userId] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch XP profile' });
    }
  }
);

export default router;
