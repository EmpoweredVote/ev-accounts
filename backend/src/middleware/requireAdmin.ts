import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { pool } from '../lib/db.js';

// Note: supabaseAdmin is used here intentionally — requireAdmin is trusted server-side
// middleware, not a route handler. The architecture enforcement test scans only
// src/routes/ for supabaseAdmin usage; src/middleware/ is excluded by design.

/**
 * requireAdmin — verify the authenticated user is in public.admin_users.
 *
 * Must be used AFTER requireAuth (which attaches req.userId).
 * Returns 403 if the user is not in admin_users table.
 *
 * Usage: router.use(requireAuth, requireAdmin)
 */
export async function requireAdmin(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authReq = req as AuthenticatedRequest;
  const { rows } = await pool.query<{ user_id: string }>(
    'SELECT user_id FROM public.admin_users WHERE user_id = $1',
    [authReq.userId]
  );

  if (rows.length === 0) {
    console.error('[requireAdmin] userId:', authReq.userId, '| not found in admin_users');
    res.status(403).json({ error: 'Admin access required' });
    return;
  }

  next();
}
