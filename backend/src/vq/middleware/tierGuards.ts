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
 * requireStaff — verifies the user has role='admin' in their JWT app_metadata.
 * Reads req.jwtPayload (set by requireAuth) — faster than a DB query and correct,
 * since public.user_roles uses UUID role_id FKs, not a simple 'admin' string column.
 * Grant access via: UPDATE auth.users SET raw_app_meta_data = raw_app_meta_data || '{"role":"admin"}' WHERE email = '...'
 */
export function requireStaff(req: any, res: any, next: any) {
  const appMetadata = req.jwtPayload?.app_metadata as { role?: string } | undefined;
  if (appMetadata?.role !== 'admin') {
    return res.status(403).json({ error: 'Staff access required' });
  }
  next();
}
