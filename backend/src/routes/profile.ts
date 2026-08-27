/**
 * profile.ts — /api/account/profile route handlers.
 *
 * Two endpoints:
 *   GET /me         — authenticated owner view (includes gems, email, location_consent)
 *   GET /:userId    — public view (no auth required)
 *
 * CRITICAL ORDERING: /me is registered BEFORE /:userId to prevent Express from
 * treating the literal string "me" as a userId param.
 *
 * All data access delegates to profileService.ts (lib/).
 * This file contains no direct DB calls.
 */

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';
import { getRequestAuthUser } from '../lib/authService.js';
import { getPublicProfile, getOwnerProfile, isValidUuid } from '../lib/profileService.js';

const router = Router();

// ---------------------------------------------------------------------------
// GET /me — authenticated owner profile
// ---------------------------------------------------------------------------
// Returns full profile with gems, email, and location_consent.
// requireAuth ensures userId and email are present on the request.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
router.get('/me', requireAuth as any, async (req, res) => {
  try {
    const authedReq = req as AuthenticatedRequest;
    const userId = authedReq.userId;

    // Resolve email for the request's user — issuer-aware during the
    // decision-0002 transition. This mirrors the pattern in account.ts GET /me.
    const { user: authUser, error: authError } = await getRequestAuthUser(
      authedReq.accessToken,
      userId
    );

    if (authError || !authUser) {
      res.status(401).json({ error: 'Unable to verify identity' });
      return;
    }

    const email = authUser.email ?? '';
    const profile = await getOwnerProfile(userId, email);
    if (!profile) {
      res.status(404).json({ error: 'Profile not found' });
      return;
    }

    res.json(profile);
  } catch (err) {
    console.error('[profile/me] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ---------------------------------------------------------------------------
// GET /:userId — public profile (no auth required)
// ---------------------------------------------------------------------------
// Returns tier-conditional public profile without sensitive fields.
// Validate UUID format to avoid leaking Postgres errors on invalid IDs.

router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    if (!isValidUuid(userId)) {
      res.status(400).json({ error: 'Invalid user ID format' });
      return;
    }

    const profile = await getPublicProfile(userId);
    if (!profile) {
      res.status(404).json({ error: 'Profile not found' });
      return;
    }

    res.json(profile);
  } catch (err) {
    console.error('[profile/:userId] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
