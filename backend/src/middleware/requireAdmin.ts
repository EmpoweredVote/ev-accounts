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
 *
 * 🔴 "NOT AN ADMIN" AND "COULD NOT ASK" ARE TWO ANSWERS, NOT ONE. postgrest-js RESOLVES on a
 * transport or query failure — it puts the fetch error in `error` rather than throwing, unless
 * throwOnError is set — so `if (error || !data)` used to collapse a Supabase outage into
 * `403 Admin access required`. That is fail-closed, so it was never a hole; it was a
 * misdiagnosis. An admin was told they are not one and sent to ask for a role they already
 * hold, at the exact moment the platform could least afford a second wrong turn.
 *
 * `.maybeSingle()` makes the split clean: zero rows is `data: null, error: null`, so a non-null
 * `error` really does mean the question could not be asked. That case is now 503 with its own
 * code, which says "try again" rather than "you do not have this".
 *
 * Callers that invoke this manually (src/routes/compass.ts, src/routes/connect.ts) branch on
 * `res.headersSent` and are unaffected. src/focused_communities/routes/claimCuration.ts reads
 * the STATUS back off a sink to tell the two apart — it is the one caller for which the
 * difference changes the answer, because its guard is "maven OR admin" and a 403 from this half
 * is an ordinary, expected outcome there.
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

  if (error) {
    console.error('[requireAdmin] admin_users lookup failed:', error.message);
    res.status(503).json({ error: 'Could not verify admin access' });
    return;
  }

  if (!data) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }

  next();
}
