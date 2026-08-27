/**
 * workosProvisionService — links a WorkOS-native signup to an internal user id.
 *
 * WHY THIS FILE EXISTS:
 * During the Supabase → WorkOS migration (decision 0002), imported users carry
 * `external_id` = their auth.users UUID, so their tokens resolve in
 * tokenIdentity.ts. A user who signs UP through AuthKit has no external_id —
 * their token cannot resolve to an internal id until this service mints one:
 * find-or-create the internal auth.users row, then write its UUID back to
 * WorkOS as external_id. tokenIdentity.ts stays the only READER of the join
 * key; this service is its only WRITER.
 *
 * Idempotent and race-safe: an already-linked WorkOS user returns immediately;
 * a concurrent duplicate create falls back to the email lookup. Email matching
 * is allowed only for WorkOS-verified emails — an unverified email must never
 * capture an existing account.
 *
 * Lives in lib/ because it needs supabaseAdmin (architecture rule: no admin
 * client in routes/).
 */

import { supabaseAdmin } from './supabase.js';
import { pool } from './db.js';
import { env } from './env.js';

const WORKOS_API = 'https://api.workos.com';

interface WorkosUser {
  id: string;
  email: string;
  email_verified: boolean;
  first_name: string | null;
  last_name: string | null;
  external_id: string | null;
}

export type ProvisionResult =
  | { ok: true; userId: string; created: boolean }
  | { ok: false; code: 'NOT_CONFIGURED' | 'EMAIL_UNVERIFIED' | 'WORKOS_ERROR' | 'INTERNAL_ERROR' };

async function findInternalUserByEmail(email: string): Promise<string | null> {
  const { rows } = await pool.query<{ id: string }>(
    `SELECT id FROM auth.users WHERE lower(email) = lower($1) AND deleted_at IS NULL`,
    [email]
  );
  return rows[0]?.id ?? null;
}

export async function provisionWorkosUser(workosUserId: string): Promise<ProvisionResult> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  const headers = {
    Authorization: `Bearer ${env.WORKOS_API_KEY}`,
    'Content-Type': 'application/json',
  };

  const userRes = await fetch(`${WORKOS_API}/user_management/users/${workosUserId}`, { headers });
  if (!userRes.ok) {
    console.error('[workosProvision] user fetch failed:', userRes.status, await userRes.text());
    return { ok: false, code: 'WORKOS_ERROR' };
  }
  const workosUser = (await userRes.json()) as WorkosUser;

  // Already linked — idempotent fast path (also covers a concurrent provision
  // that finished between the client's token check and this call).
  if (workosUser.external_id) return { ok: true, userId: workosUser.external_id, created: false };

  if (!workosUser.email_verified) return { ok: false, code: 'EMAIL_UNVERIFIED' };

  let userId = await findInternalUserByEmail(workosUser.email);
  let created = false;

  if (!userId) {
    // Shadow auth.users row: no password (login happens at WorkOS), email
    // pre-confirmed (WorkOS verified it). The on_auth_user_created trigger
    // creates the public.users row, same as a Supabase signup.
    const { data, error } = await supabaseAdmin.auth.admin.createUser({
      email: workosUser.email,
      email_confirm: true,
    });
    if (error?.code === 'email_exists') {
      // Concurrent provision created it first — link to that row.
      userId = await findInternalUserByEmail(workosUser.email);
    } else if (error || !data.user) {
      console.error('[workosProvision] createUser failed:', error?.code, error?.message);
      return { ok: false, code: 'INTERNAL_ERROR' };
    } else {
      userId = data.user.id;
      created = true;
    }
    if (!userId) return { ok: false, code: 'INTERNAL_ERROR' };

    if (created) {
      // Best-effort display name from the AuthKit signup form. Non-fatal —
      // the profile page can set it later (same policy as the signup route).
      const displayName = [workosUser.first_name, workosUser.last_name]
        .filter(Boolean)
        .join(' ')
        .trim();
      if (displayName) {
        try {
          await pool.query(
            `UPDATE public.users SET display_name = $2, updated_at = now()
             WHERE id = $1 AND display_name IS NULL`,
            [userId, displayName]
          );
        } catch (err) {
          console.error('[workosProvision] display_name update failed (non-fatal):', err);
        }
      }
    }
  }

  // Write the join key back to WorkOS. The client must refresh its access
  // token afterwards so the external_id claim appears (JWT template).
  // If this PUT fails after a create, the shadow row is not orphaned for
  // long: the next provision attempt links it via the email lookup.
  const putRes = await fetch(`${WORKOS_API}/user_management/users/${workosUserId}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ external_id: userId }),
  });
  if (!putRes.ok) {
    console.error('[workosProvision] external_id write failed:', putRes.status, await putRes.text());
    return { ok: false, code: 'WORKOS_ERROR' };
  }

  return { ok: true, userId, created };
}
