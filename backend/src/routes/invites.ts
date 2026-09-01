import { Router } from 'express';
import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { createSharedRateLimitStore } from '../lib/rateLimitStore.js';
import { z } from 'zod';
import { createInviteCodes, getMyInviteCodes, claimInviteCode } from '../lib/inviteService.js';
import { generateInviteCodeIfAllowed, getMyInvitees } from '../lib/inviteQuotaService.js';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import type { Request, Response } from 'express';

const router = Router();

/**
 * Rate limiter for POST /api/invites/send.
 * 10 invite sends per user per 24-hour window.
 * Key is userId (not IP) — a single user on shared WiFi should not
 * have their send limit reduced by other users on the same IP.
 */
const inviteRateLimitStore = createSharedRateLimitStore('invite');
const inviteSendLimiter = rateLimit({
  windowMs: 24 * 60 * 60 * 1000, // 24 hours
  max: 10,
  keyGenerator: (req) =>
    (req as AuthenticatedRequest).userId ?? (req.ip ? ipKeyGenerator(req.ip) : 'unknown'),
  ...(inviteRateLimitStore ? { store: inviteRateLimitStore } : {}),
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Invite limit reached for today' },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Zod schema for POST /api/invites/claim request body.
 * Code format: XXXX-XXXX — exactly 9 characters including the hyphen.
 */
const claimBodySchema = z.object({
  code: z.string().min(9).max(9),
});

// ---------------------------------------------------------------------------
// POST /api/invites/send
// ---------------------------------------------------------------------------

/**
 * Connected user generates a new invite code to share.
 *
 * Guards:
 * - requireAuth: valid JWT required
 * - requireConnected: caller must have a verified Connected profile
 * - inviteSendLimiter: max 10 sends per user per day
 *
 * Business rule: a user may not hold more than 5 unclaimed codes at once.
 * If they already have 5 pending, they must wait for some to be claimed
 * before generating more.
 *
 * Returns 201 with the generated code on success.
 */
router.post(
  '/send',
  requireAuth,
  requireConnected,
  inviteSendLimiter,
  async (req: Request, res: Response): Promise<void> => {
    const { userId } = req as AuthenticatedRequest;

    // Check current pending (unclaimed) invite count
    let existingCodes;
    try {
      existingCodes = await getMyInviteCodes(userId);
    } catch (err) {
      console.error('[invites/send] Failed to fetch existing codes:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    const unclaimedCount = existingCodes.filter((c) => !c.is_claimed).length;
    if (unclaimedCount >= 5) {
      res.status(409).json({
        code: 'INVITE_LIMIT_REACHED',
        message: 'You already have 5 pending invite codes',
      });
      return;
    }

    // Generate 1 new code
    let codes: string[];
    try {
      codes = await createInviteCodes(userId, 1);
    } catch (err) {
      console.error('[invites/send] Failed to create invite code:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    res.status(201).json({ code: codes[0] });
  },
);

// ---------------------------------------------------------------------------
// POST /api/invites/claim
// ---------------------------------------------------------------------------

/**
 * Any authenticated user claims an invite code.
 *
 * Intentionally does NOT require requireConnected — the user is claiming
 * an invite as the first step toward BECOMING Connected. Requiring
 * Connected here would create a chicken-and-egg impossibility.
 *
 * The code is normalized to uppercase before lookup so that users who
 * type codes in lowercase (e.g. from a printed invite) are not rejected.
 *
 * On success, returns the inviter_id so the client can display a
 * "you were invited by X" message if desired.
 */
router.post('/claim', requireAuth, async (req: Request, res: Response): Promise<void> => {
  const { userId } = req as AuthenticatedRequest;

  const parsed = claimBodySchema.safeParse(req.body);
  if (!parsed.success) {
    const firstIssue = parsed.error.issues[0];
    res.status(422).json({
      code: 'VALIDATION_ERROR',
      message: firstIssue?.message ?? 'Invalid request body',
    });
    return;
  }

  // Normalize: uppercase + trim to tolerate user input variations
  const normalizedCode = parsed.data.code.toUpperCase().trim();

  let result;
  try {
    result = await claimInviteCode(normalizedCode, userId);
  } catch (err) {
    console.error('[invites/claim] Unexpected error during claim:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    return;
  }

  if (!result.success) {
    switch (result.error) {
      case 'INVALID_CODE':
        res.status(404).json({ code: 'INVALID_CODE', message: 'Invite code not found' });
        break;
      case 'CODE_ALREADY_CLAIMED':
        res.status(409).json({
          code: 'CODE_ALREADY_CLAIMED',
          message: 'This invite code has already been used',
        });
        break;
      case 'CODE_EXPIRED':
        res.status(410).json({ code: 'CODE_EXPIRED', message: 'This invite code has expired' });
        break;
      case 'SELF_INVITE_BLOCKED':
        res
          .status(403)
          .json({ code: 'SELF_INVITE_BLOCKED', message: 'You cannot claim your own invite code' });
        break;
      default: {
        // TypeScript exhaustiveness guard
        const _exhaustive: never = result.error;
        void _exhaustive;
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      }
    }
    return;
  }

  res.status(200).json({ claimed: true, inviter_id: result.inviterId });
});

// ---------------------------------------------------------------------------
// GET /api/invites/mine
// ---------------------------------------------------------------------------

/**
 * Connected user retrieves their own invite codes.
 *
 * Response is whitelist-serialized: only safe fields are returned.
 * created_by and claimed_by are UUID columns that would leak user IDs
 * to the caller — they are intentionally omitted.
 */
router.get(
  '/mine',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const { userId } = req as AuthenticatedRequest;

    let codes;
    try {
      codes = await getMyInviteCodes(userId);
    } catch (err) {
      console.error('[invites/mine] Failed to fetch invite codes:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
      return;
    }

    // Whitelist-serialize: omit created_by and claimed_by UUIDs
    const safeResponse = codes.map((c) => ({
      id: c.id,
      code: c.code,
      is_claimed: c.is_claimed,
      claimed_at: c.claimed_at,
      expires_at: c.expires_at,
      created_at: c.created_at,
    }));

    res.status(200).json(safeResponse);
  },
);

// ---------------------------------------------------------------------------
// POST /api/invites/generate — quota-aware code generation (Phase 59)
// ---------------------------------------------------------------------------

/**
 * Connected user generates an invite code against their level-based quota.
 *
 * Unlike /send (which checks unclaimed pending codes), /generate uses the
 * connect.generate_invite_code_if_allowed RPC which enforces the active-invitee
 * cap (Level 1 = 3, Level 2 = 5, etc.) and respects invite_cap_override.
 *
 * Returns 409 with code=CAP_REACHED when the user is at their cap.
 */
router.post(
  '/generate',
  requireAuth,
  requireConnected,
  inviteSendLimiter,
  async (req: Request, res: Response): Promise<void> => {
    const { userId } = req as AuthenticatedRequest;
    try {
      const { label } = req.body as { label?: string };
      const result = await generateInviteCodeIfAllowed(userId, label?.trim() || null);
      if (!result.ok) {
        const status = result.error === 'NOT_CONNECTED' ? 403 : 409;
        res
          .status(status)
          .json({ code: result.error, active_count: result.active_count, cap: result.cap });
        return;
      }
      res.status(201).json({ code: result.code, active_count: result.active_count, cap: result.cap });
    } catch (err) {
      console.error('[invites/generate] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  },
);

// ---------------------------------------------------------------------------
// GET /api/invites/my-invitees — invitee list with quota summary (Phase 59)
// ---------------------------------------------------------------------------

/**
 * Connected user retrieves their invitees with quota context.
 *
 * Response includes:
 *   - active_count: number of active (non-locked) invitees consuming quota
 *   - cap: effective cap for the user (level cap or override, whichever is larger)
 *   - can_generate: whether the user may generate another code right now
 *   - invitees[]: per-invitee standing, level, graduated flag, lock status
 */
router.get(
  '/my-invitees',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const { userId } = req as AuthenticatedRequest;
    try {
      const data = await getMyInvitees(userId);
      res.json(data);
    } catch (err) {
      console.error('[invites/my-invitees] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
    }
  },
);

export default router;
