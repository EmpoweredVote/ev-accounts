import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';
import { env } from '../lib/env.js';

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
  console.log('[requireAdmin] url:', env.SUPABASE_URL, '| key prefix:', env.SUPABASE_SERVICE_ROLE_KEY.slice(0, 20));
  const { data, error } = await supabaseAdmin
    .schema('public')
    .from('admin_users')
    .select('user_id')
    .eq('user_id', authReq.userId)
    .maybeSingle();

  if (error || !data) {
    console.error('[requireAdmin] userId:', authReq.userId, '| error:', error?.message ?? null, '| data:', data);
    res.status(403).json({ error: 'Admin access required' });
    return;
  }

  next();
}
