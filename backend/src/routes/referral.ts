import { Router } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { getReferralState } from '../lib/referralService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/referral
// Auth: requireAuth + requireConnected
//
// Returns the authenticated user's referral code state:
//   unlocked      — true once user has reached level 2
//   code          — current active referral code (null if not yet unlocked)
//   inviteeJoined — true if someone has used the code
//   inviteeLevel  — current level of the person who used the code (null if none)
// ---------------------------------------------------------------------------

router.get(
  '/',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const state = await getReferralState(authReq.userId);
      if (!state) {
        res.status(404).json({ error: 'Profile not found' });
        return;
      }
      res.status(200).json(state);
    } catch (err) {
      console.error('[GET /api/referral] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch referral state' });
    }
  }
);

export default router;
