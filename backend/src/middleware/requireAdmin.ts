import { Request, Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

// Note: supabaseAdmin is used here intentionally — requireAdmin is trusted server-side
// middleware, not a route handler. The result of this lookup decides a 403; it never
// reaches the response body, which is what the dual-client rule exists to prevent.
//
// ⚠ src/middleware/ IS NOT EXCLUDED from the architecture test. This comment used to say
// it was, and that was wrong: `supabaseAdmin exists only in expected files` scans ALL of
// backend/src, so every middleware file using this client must be listed in ALLOWED in
// tests/integration/architecture.test.ts. Only the FIRST of the two tests there is
// routes-only. Believing this comment left requireCompassReviewer.ts off that list on
// 2026-08-24 and master's test suite was red for three days. Add the entry.

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
  const { data, error } = await supabaseAdmin
    .from('admin_users')
    .select('user_id')
    .eq('user_id', authReq.userId)
    .maybeSingle();

  if (error || !data) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }

  next();
}
