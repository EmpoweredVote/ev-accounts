import { Router } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireConnected } from '../middleware/tierGuards.js';
import { getUserRoles, getAllActiveRoles, getCachedUserRoles, checkRole } from '../lib/roleService.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/roles
// Auth: requireAuth (any authenticated user can see available roles)
//
// Returns all active roles in the system. Used by clients to display available
// roles and their tier requirements.
//
// Note: Grant and revoke endpoints are not exposed in Phase 6.
// They are admin-only operations exposed in Phase 7 at /api/admin/roles/*.
// ---------------------------------------------------------------------------

router.get(
  '/',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    try {
      const roles = await getAllActiveRoles();
      res.status(200).json({ roles });
    } catch (err) {
      console.error('[GET /roles] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch roles' });
    }
  }
);

// ---------------------------------------------------------------------------
// GET /api/roles/me
// Auth: requireAuth + requireConnected
//
// Returns the authenticated user's active (non-revoked) role grants.
// Only Connected+ users can hold roles.
// ---------------------------------------------------------------------------

router.get(
  '/me',
  requireAuth,
  requireConnected,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;

    try {
      const roles = await getUserRoles(authReq.userId);
      res.status(200).json({ roles });
    } catch (err) {
      console.error('[GET /roles/me] error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch user roles' });
    }
  }
);

// ---------------------------------------------------------------------------
// POST /api/roles/check
// Auth: requireAuth
//
// Checks whether the authenticated user holds a role matching the given slug
// and optional scope constraints.
//
// Body: { feature_scope: string, jurisdiction_geoid?: string, resource_id?: string }
// Note: "feature_scope" in the request body is the role slug to check.
//
// Response: { permitted: boolean }
// ---------------------------------------------------------------------------

router.post(
  '/check',
  requireAuth,
  async (req: Request, res: Response): Promise<void> => {
    const authReq = req as AuthenticatedRequest;
    const body = req.body as {
      feature_scope?: string;
      jurisdiction_geoid?: string;
      resource_id?: string;
    };

    if (!body.feature_scope || body.feature_scope.trim() === '') {
      res.status(400).json({ error: 'feature_scope is required' });
      return;
    }

    try {
      const grants = await getCachedUserRoles(authReq.userId);

      const scope: { geoid?: string; resourceId?: string } = {};
      if (body.jurisdiction_geoid !== undefined) scope.geoid = body.jurisdiction_geoid;
      if (body.resource_id !== undefined) scope.resourceId = body.resource_id;

      const result = checkRole(grants, body.feature_scope, scope);
      res.status(200).json({ permitted: result });
    } catch (err) {
      console.error('[POST /roles/check] error:', err);
      res.status(500).json({ error: 'Failed to check role' });
    }
  }
);

export default router;
