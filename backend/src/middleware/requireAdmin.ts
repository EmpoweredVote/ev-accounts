import { Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

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
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .from('admin_users')
    .select('user_id')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }

  next();
}
