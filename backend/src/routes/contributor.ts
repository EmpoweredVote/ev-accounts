import { Router } from 'express';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { getCachedUserRoles } from '../lib/roleService.js';
import { pool } from '../lib/db.js';
import type { Request, Response } from 'express';

const router = Router();

// ---------------------------------------------------------------------------
// GET /api/contributor/me
// Auth: requireAuth
//
// Feed for the Contributor Portal dashboard. Returns the authenticated user's
// active grants as a bare array, filtered to the three contributor roles below
// (d9a4a55c) — it is NOT a general "which roles do I hold" endpoint.
//
// Consumers needing every grant (CTC's ctc_content_editor, Civic Spaces, etc.)
// must use GET /api/roles/me, which returns all active grants unfiltered.
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

      // Batch-fetch politician names for any resource_id values so the dashboard
      // can display "Karen Bass" instead of "Single Politician".
      const politicianIds = [...new Set(
        grants.map((g) => g.resource_id).filter((id): id is string => id !== null)
      )];

      const nameMap = new Map<string, string>();
      if (politicianIds.length > 0) {
        const { rows } = await pool.query<{ id: string; full_name: string | null; first_name: string | null; last_name: string | null }>(
          `SELECT id, full_name, first_name, last_name
           FROM essentials.politicians
           WHERE id = ANY($1)`,
          [politicianIds]
        );
        for (const row of rows) {
          const name = (row.full_name
            ?? [row.first_name, row.last_name].filter(Boolean).join(' '))
            || null;
          if (name) nameMap.set(row.id, name);
        }
      }

      const CONTRIBUTOR_ROLES = new Set(['compass_stance_editor', 'campaign_manager', 'essentials_data_editor']);
      const mapped = grants.filter((g) => CONTRIBUTOR_ROLES.has(g.slug)).map((g) => ({
        role_slug: g.slug,
        feature_scope: g.feature_scope,
        jurisdiction_geoid: g.jurisdiction_geoid,
        resource_id: g.resource_id,
        resource_display_name: g.resource_id ? (nameMap.get(g.resource_id) ?? null) : null,
        granted_at: g.granted_at,
        granted_by_display_name: g.granted_by_display_name ?? null,
      }));
      res.status(200).json(mapped);
    } catch (err) {
      console.error('[GET /contributor/me] error:', err);
      res.status(500).json({ error: 'Failed to fetch contributor roles' });
    }
  }
);

export default router;
