// Source: empowered-accounts-integration-guide.md (v1.0, 2026-02-28)
import { supabaseService } from '../lib/supabase.js';

/**
 * requireConnected — blocks requests from users without a verified Connected account.
 * Queries connect.connected_profiles for verification_status = 'verified'.
 * Returns 403 if not Connected.
 */
export async function requireConnected(req: any, res: any, next: any) {
  const { data } = await supabaseService
    .schema('connect')
    .from('connected_profiles')
    .select('verification_status')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (!data || data.verification_status !== 'verified') {
    return res.status(403).json({ error: 'Connected account required' });
  }
  next();
}

/**
 * requireNotSuspended — blocks requests from suspended or quarantined accounts.
 * Queries connect.connected_profiles for account_standing = 'active'.
 * Fails CLOSED — if the row is missing, DB errors, or standing != 'active', returns 403.
 * Both 'suspended' and 'quarantined' are blocked (only 'active' passes).
 */
export async function requireNotSuspended(req: any, res: any, next: any) {
  const { data } = await supabaseService
    .schema('connect')
    .from('connected_profiles')
    .select('account_standing')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (!data || data.account_standing !== 'active') {
    return res.status(403).json({ error: 'Account suspended' });
  }

  next();
}

/**
 * requireStaff — admits a user who has a row in public.admin_users.
 * Must run after requireAuth, which sets req.userId to the internal user UUID for
 * both issuers (Supabase `sub`, WorkOS `external_id`).
 *
 * Staff is decided from the database, not the token (ev-cto decision 0041). This used to
 * read `req.jwtPayload.app_metadata.role === 'admin'`, but that claim exists only on
 * Supabase-issued tokens: WorkOS AuthKit tokens (decision 0002, live since 2026-08-27)
 * carry no app_metadata, so every staff member who signed in through WorkOS was refused.
 * public.admin_users is the same table the platform's own requireAdmin reads
 * (src/middleware/requireAdmin.ts) and the CTC fold's requireAdmin reads.
 *
 * Grant access by adding the user to public.admin_users (the admin console does this).
 * Do NOT edit auth.users.raw_app_meta_data — nothing reads it any more.
 *
 * "Not staff" (403) and "could not ask" (503) are separate answers: `.maybeSingle()`
 * returns `data: null, error: null` for zero rows, so a non-null error means the lookup
 * itself failed. Both refuse the request.
 */
export async function requireStaff(req: any, res: any, next: any) {
  if (!req.userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }

  const { data, error } = await supabaseService
    .from('admin_users')
    .select('user_id')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error) {
    console.error('[vq requireStaff] admin_users lookup failed:', error.message);
    return res.status(503).json({ error: 'Could not verify staff access' });
  }
  if (!data) {
    return res.status(403).json({ error: 'Staff access required' });
  }
  next();
}
