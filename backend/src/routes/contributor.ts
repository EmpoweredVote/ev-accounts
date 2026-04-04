import { Router } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { getCachedUserRoles } from '../lib/roleService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/contributor/me
// Auth: requireAuth
//
// Returns the authenticated user's active role grants as a bare array.
// Used by CTC, Civic Spaces, and the Contributor Portal to determine
// which features the caller is permitted to access.
//
// Response: [{ role_slug, feature_scope, jurisdiction_geoid, resource_id, granted_at }]
// ---------------------------------------------------------------------------

router.get(
  '/me',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const grants = await getCachedUserRoles(authReq.userId);
      const mapped = grants.map((g) => ({
        role_slug: g.slug,
        feature_scope: g.feature_scope,
        jurisdiction_geoid: g.jurisdiction_geoid,
        resource_id: g.resource_id,
        granted_at: g.granted_at,
      }));
      res.status(200).json(mapped);
    } catch (err) {
      console.error('[GET /contributor/me] error:', err);
      res.status(500).json({ error: 'Failed to fetch contributor roles' });
    }
  }
);

export default router;
