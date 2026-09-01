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

export type WorkosSignupResult =
  | { ok: true; userId: string }
  | {
      ok: false;
      code: 'NOT_CONFIGURED' | 'EMAIL_EXISTS' | 'WEAK_PASSWORD' | 'WORKOS_ERROR' | 'INTERNAL_ERROR';
    };

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

/**
 * signUpWorkosFirst — create an account whose usable credential lives in
 * WorkOS (decision 0002 cutover, gated on env.AUTHKIT_PRIMARY).
 *
 * Order is deliberate: WorkOS user → Supabase shadow row → external_id
 * write-back. Every partial failure is self-healing, because
 * provisionWorkosUser() links by verified email on first sign-in:
 *   - shadow-row creation fails  → the WorkOS user is deleted again, so signup
 *                                  leaves nothing behind and can be retried.
 *   - external_id write fails    → first sign-in links by email instead.
 *
 * ⚠ THE SHADOW ROW IS NOT LITERALLY PASSWORDLESS. Supabase's admin createUser
 * auto-generates a RANDOM bcrypt hash even when we pass no password (same for
 * the imported-user provisioning path above). That hash is unknowable, so it
 * is not a usable credential — but it is credential material, and the
 * separation goal is only fully met once it is nulled. Nulling auth.users is
 * not reachable from this runtime (the app connects as the least-privilege
 * `ev_api` role, which has no write on the auth schema, and widening that role
 * would defeat its purpose). The null is therefore delivered by the gated
 * batch step at cutover — see backend/scripts (null-shadow-passwords) — which
 * MUST cover every WorkOS-linked row, not only the original 21 imports.
 *
 * WHAT WE DO NOT SEND TO WORKOS: display_name. For a Connected account that is
 * the user's ON-PLATFORM PSEUDONYM, and putting it beside their email in the
 * identity store is exactly the linkage PRIVACY-ARCHITECTURE properties A and B
 * exist to prevent. Same reasoning for legal_name, which stays in `connect`.
 * WorkOS holds email + credential only.
 *
 * email_verified is false: AuthKit owns the verification challenge from here.
 * WorkOS refuses a sign-in until the address is verified (its hosted flow
 * prompts for a code at first sign-in), which preserves the confirm-before-
 * login gate the Supabase path had, and Supabase sends no mail for these
 * accounts.
 */
export async function signUpWorkosFirst(
  email: string,
  password: string,
  opts?: { sendVerificationEmail?: boolean }
): Promise<WorkosSignupResult> {
  if (!env.WORKOS_API_KEY) return { ok: false, code: 'NOT_CONFIGURED' };
  const headers = {
    Authorization: `Bearer ${env.WORKOS_API_KEY}`,
    'Content-Type': 'application/json',
  };

  const createRes = await fetch(`${WORKOS_API}/user_management/users`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ email, password, email_verified: false }),
  });

  if (!createRes.ok) {
    const body = await createRes.text();
    // WorkOS reports these as 4xx with a machine-readable code; match on the
    // code substring rather than the prose, which is not contractual.
    if (/email_not_available|email_already|user_creation_error/i.test(body)) {
      return { ok: false, code: 'EMAIL_EXISTS' };
    }
    if (/password/i.test(body)) return { ok: false, code: 'WEAK_PASSWORD' };
    console.error('[workosSignup] create failed:', createRes.status, body);
    return { ok: false, code: 'WORKOS_ERROR' };
  }
  const workosUser = (await createRes.json()) as { id: string };

  // Shadow row. We pass no password, but Supabase writes a random unknowable
  // bcrypt hash anyway (see the ⚠ note above — cleared by the batch step).
  // email_confirm:true marks the INTERNAL row's email confirmed; WorkOS runs
  // its own verification separately.
  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email,
    email_confirm: true,
  });

  let userId = data?.user?.id ?? null;
  if (error) {
    if (error.code === 'email_exists') {
      // An internal row already exists for this address (e.g. a migrated user
      // signing up again). Link to it rather than duplicating.
      userId = await findInternalUserByEmail(email);
    }
    if (!userId) {
      // Leave nothing behind — roll the WorkOS user back so a retry is clean.
      const del = await fetch(`${WORKOS_API}/user_management/users/${workosUser.id}`, {
        method: 'DELETE',
        headers,
      });
      if (!del.ok) {
        console.error(
          '[workosSignup] shadow row failed AND WorkOS rollback failed; orphan WorkOS user',
          workosUser.id,
          '— first sign-in will self-heal via provisioning'
        );
      }
      if (error.code === 'email_exists') return { ok: false, code: 'EMAIL_EXISTS' };
      console.error('[workosSignup] shadow row creation failed:', error.code, error.message);
      return { ok: false, code: 'INTERNAL_ERROR' };
    }
  }
  if (!userId) return { ok: false, code: 'INTERNAL_ERROR' };

  const putRes = await fetch(`${WORKOS_API}/user_management/users/${workosUser.id}`, {
    method: 'PUT',
    headers,
    body: JSON.stringify({ external_id: userId }),
  });
  if (!putRes.ok) {
    // Not fatal: provisionWorkosUser() links by email on first sign-in.
    console.error(
      '[workosSignup] external_id write failed:',
      putRes.status,
      await putRes.text(),
      '— will self-heal on first sign-in'
    );
  }

  // Send the verification email at signup — but ONLY for flows that will not
  // immediately call the headless authenticate grant. WorkOS does not auto-send
  // for a management-API create, so without this a HOSTED-flow user gets nothing
  // until they reach AuthKit sign-in (which surprised testers — it read as
  // "signup failed"). The EMBEDDED flow, however, calls /workos/authenticate
  // right after signup, and WorkOS emails a code as part of that
  // `email_verification_required` step. Sending here as well would produce TWO
  // codes — the newer one invalidates the older, so a user who enters the first
  // email's code gets `invalid_one_time_code`. So the embedded signup passes
  // sendVerificationEmail:false and lets authenticate be the single sender.
  // Non-fatal either way.
  if (opts?.sendVerificationEmail !== false) {
    const verifyRes = await fetch(
      `${WORKOS_API}/user_management/users/${workosUser.id}/email_verification/send`,
      { method: 'POST', headers }
    );
    if (!verifyRes.ok) {
      console.error(
        '[workosSignup] verification email send failed (non-fatal):',
        verifyRes.status,
        await verifyRes.text()
      );
    }
  }

  return { ok: true, userId };
}
