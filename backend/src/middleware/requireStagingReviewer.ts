import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { pool } from '../lib/db.js';

/**
 * requireStagingReviewer — verify the authenticated user is either:
 *   1. An admin (in public.admin_users), OR
 *   2. Holds the active 'staging_reviewer' role (public.user_roles + public.roles)
 *
 * Must be used AFTER requireAuth (which attaches req.userId).
 * Returns 403 if the user has neither admin nor staging_reviewer access.
 */
export async function requireStagingReviewer(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const userId = authReq.userId;

  // Fast path: check admin_users first
  const adminCheck = await pool.query(
    `SELECT 1 FROM public.admin_users WHERE user_id = $1 LIMIT 1`,
    [userId]
  );
  if (adminCheck.rowCount && adminCheck.rowCount > 0) {
    return next();
  }

  // Check staging_reviewer role
  const roleCheck = await pool.query(
    `SELECT 1 FROM public.user_roles ur
     JOIN public.roles r ON r.id = ur.role_id
     WHERE ur.user_id = $1
       AND r.slug = 'staging_reviewer'
       AND ur.revoked_at IS NULL
     LIMIT 1`,
    [userId]
  );
  if (roleCheck.rowCount && roleCheck.rowCount > 0) {
    return next();
  }

  res.status(403).json({ error: 'Staging reviewer access required' });
}
