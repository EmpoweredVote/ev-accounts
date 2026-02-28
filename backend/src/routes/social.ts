import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import {
  sendPeerRequest,
  acceptPeerRequest,
  declinePeerRequest,
  blockUser,
  follow,
  unfollow,
  getConnections,
  getFollowing,
  getFollowerCount,
} from '../lib/socialService.js';
import { supabaseAdmin } from '../lib/supabase.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const TargetIdSchema = z.object({ target_id: z.string().uuid() });

// ---------------------------------------------------------------------------
// POST /api/social/peers/request
// Auth: requireAuth + requireConnected
//
// Send a peer connection request to another Connected+ user.
// ---------------------------------------------------------------------------

router.post(
  '/peers/request',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = TargetIdSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'target_id must be a valid UUID' });
      return;
    }

    try {
      const request = await sendPeerRequest(authReq.userId, parsed.data.target_id);
      res.status(201).json({ request });
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'SELF_REQUEST') {
        res.status(422).json({ code, message: 'Cannot send a peer request to yourself' });
      } else if (code === 'BLOCKED') {
        res.status(403).json({ code, message: 'A block exists between these users' });
      } else if (code === 'ALREADY_CONNECTED') {
        res.status(409).json({ code, message: 'Users are already connected' });
      } else if (code === 'PENDING') {
        res.status(409).json({ code, message: 'A pending request already exists' });
      } else {
        console.error('[POST /social/peers/request] error:', err);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to send peer request' });
      }
    }
  }
);

// ---------------------------------------------------------------------------
// PATCH /api/social/peers/:id/accept
// Auth: requireAuth + requireConnected
//
// Accept a pending peer connection request. Only the target (addressee) can accept.
// ---------------------------------------------------------------------------

router.patch(
  '/peers/:id/accept',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      await acceptPeerRequest(req.params.id as string, authReq.userId);
      res.status(200).json({ accepted: true });
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'REQUEST_NOT_FOUND') {
        res.status(404).json({ code, message: 'Request not found or not pending' });
      } else {
        console.error('[PATCH /social/peers/:id/accept] error:', err);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to accept request' });
      }
    }
  }
);

// ---------------------------------------------------------------------------
// PATCH /api/social/peers/:id/decline
// Auth: requireAuth + requireConnected
//
// Decline a pending peer connection request. Only the target (addressee) can decline.
// A declined request can be re-sent by the original actor.
// ---------------------------------------------------------------------------

router.patch(
  '/peers/:id/decline',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      await declinePeerRequest(req.params.id as string, authReq.userId);
      res.status(200).json({ declined: true });
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'REQUEST_NOT_FOUND') {
        res.status(404).json({ code, message: 'Request not found or not pending' });
      } else {
        console.error('[PATCH /social/peers/:id/decline] error:', err);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to decline request' });
      }
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/social/peers/block
// Auth: requireAuth + requireConnected
//
// Block another user. Converts any existing peer relationship to blocked
// (blocker recorded as actor_id). Removes follow relationships in both directions.
// ---------------------------------------------------------------------------

router.post(
  '/peers/block',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = TargetIdSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'target_id must be a valid UUID' });
      return;
    }

    try {
      await blockUser(authReq.userId, parsed.data.target_id);
      res.status(200).json({ blocked: true });
    } catch (err) {
      console.error('[POST /social/peers/block] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to block user' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/social/peers
// Auth: requireAuth + requireConnected
//
// Return the authenticated user's peer connections (pending and accepted).
// ---------------------------------------------------------------------------

router.get(
  '/peers',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const connections = await getConnections(authReq.userId);
      res.status(200).json({ connections });
    } catch (err) {
      console.error('[GET /social/peers] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch connections' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/social/follow
// Auth: requireAuth + requireConnected
//
// Follow an Empowered account. Connected users cannot follow Connected users
// (must use peer connection flow). Follow is idempotent.
// ---------------------------------------------------------------------------

router.post(
  '/follow',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    const parsed = TargetIdSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'target_id must be a valid UUID' });
      return;
    }

    try {
      await follow(authReq.userId, parsed.data.target_id);
      res.status(201).json({ following: true });
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'NOT_EMPOWERED') {
        res.status(422).json({ code, message: 'Can only follow Empowered accounts' });
      } else if (code === 'BLOCKED') {
        res.status(403).json({ code, message: 'A block exists between these users' });
      } else {
        console.error('[POST /social/follow] error:', err);
        res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to follow user' });
      }
    }
  }
);

// ---------------------------------------------------------------------------
// DELETE /api/social/follow/:target_id
// Auth: requireAuth + requireConnected
//
// Unfollow an account. Idempotent — no error if not currently following.
// ---------------------------------------------------------------------------

router.delete(
  '/follow/:target_id',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      await unfollow(authReq.userId, req.params.target_id as string);
      res.status(200).json({ unfollowed: true });
    } catch (err) {
      console.error('[DELETE /social/follow/:target_id] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to unfollow user' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/social/following
// Auth: requireAuth + requireConnected
//
// Return the list of Empowered accounts the authenticated user is following.
// ---------------------------------------------------------------------------

router.get(
  '/following',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const following = await getFollowing(authReq.userId);
      res.status(200).json({ following });
    } catch (err) {
      console.error('[GET /social/following] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch following list' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/social/followers/count/:user_id
// Auth: requireAuth (any authenticated user can see an Empowered user's follower count)
//
// Validates the target is an active Empowered account before returning count.
// Follower count is public for Empowered profiles.
// ---------------------------------------------------------------------------

router.get(
  '/followers/count/:user_id',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const userId = req.params.user_id as string;

    // Validate target is an Empowered account
    const { data: empProfile, error: empError } = await supabaseAdmin
      .schema('empower')
      .from('empowered_profiles')
      .select('id')
      .eq('user_id', userId)
      .eq('is_active', true)
      .maybeSingle();

    if (empError) {
      console.error('[GET /social/followers/count/:user_id] error:', empError);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch follower count' });
      return;
    }

    if (!empProfile) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Empowered profile not found' });
      return;
    }

    try {
      const follower_count = await getFollowerCount(userId);
      res.status(200).json({ user_id: userId, follower_count });
    } catch (err) {
      console.error('[GET /social/followers/count/:user_id] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch follower count' });
    }
  }
);

export default router;
