/**
 * d11-probe.ts — shared D-11 sentinel probe for 1641/1642-coordinate-smoke.ts.
 *
 * WHY THIS EXISTS. The probe used to run entirely over the raw Postgres pool: it did
 * `INSERT INTO auth.users`, then called connect.upsert_user_location and
 * connect.resolve_congressional_2026 as the connection role, all inside a BEGIN/ROLLBACK.
 * That stopped working when `backend/.env`'s DATABASE_URL became the least-privileged app role
 * `ev_api`, which has no USAGE on schema `auth` AND no EXECUTE on either SECURITY DEFINER
 * function (both owned by `postgres`). Granting ev_api those rights is NOT the fix — an
 * application role able to mint auth users is a privilege-escalation risk, and `backend/.env`
 * was one of the files caught in the 2026-07-26 key exposure.
 *
 * The deeper problem the outage exposed: the old probe never matched production anyway.
 * Production calls this through PostgREST as `service_role`:
 *     src/routes/essentials.ts:74 -> adminRpc('resolve_congressional_2026', …, 'connect')
 * while the probe called it over a direct pg connection as whatever role .env held. Same SQL
 * function, different invocation path — so its "actual RPC code path" claim was only half true.
 *
 * This version uses the credentials the app ALREADY holds and matches production's path:
 *   - the sentinel auth user is minted with supabaseAdmin.auth.admin.createUser() — exactly what
 *     the service-role key is for;
 *   - connect.connected_profiles is seeded over the pg pool, which ev_api IS permitted to write;
 *   - BOTH RPCs go through adminRpc(), i.e. PostgREST as service_role — the production path;
 *   - cleanup is an explicit auth.admin.deleteUser(), and public.users.id -> auth.users.id is
 *     ON DELETE CASCADE, so removing the auth user removes the profile and location rows with it.
 *
 * TRADE-OFF, stated plainly: this gives up the old BEGIN/ROLLBACK guarantee. A hard crash between
 * createUser and deleteUser can strand a sentinel row. Mitigated by (a) a deterministic per-state
 * email so a stranded row is findable, and (b) reapSentinel() below, which deletes a leftover
 * before each run. Anything stranded is inert: the account has no password and no confirmed email.
 */
import { supabaseAdmin, adminRpc } from '../src/lib/supabase.js';
import { pool } from '../src/lib/db.js';

export type D11Result =
  | { status: 'pass'; message: string }
  | { status: 'fail'; message: string }
  | { status: 'skip'; message: string };

/** Deterministic, obviously-fake address so a stranded sentinel is greppable. `.invalid` is RFC 2606. */
const sentinelEmail = (abbr: string) => `d11-sentinel-${abbr.toLowerCase()}@coordinate-smoke.invalid`;

/** Delete any sentinel left behind by a crashed earlier run. Best-effort. */
async function reapSentinel(abbr: string): Promise<void> {
  const email = sentinelEmail(abbr);
  // listUsers has no server-side email filter in this SDK version; the sentinel is always on
  // page 1 of a freshly-created account set only in the pathological case, so scan a bounded page.
  const { data } = await supabaseAdmin.auth.admin.listUsers({ page: 1, perPage: 1000 });
  const stale = data?.users?.find((u) => u.email === email);
  if (stale) await supabaseAdmin.auth.admin.deleteUser(stale.id);
}

/**
 * Exercise connect.resolve_congressional_2026 end to end for one differential point.
 * Returns 'skip' only when the service-role credential is unusable — never on a wrong answer.
 */
export async function probeD11(
  abbr: string,
  lat: number,
  lng: number,
  expectedGeoId: string
): Promise<D11Result> {
  let userId: string | null = null;
  try {
    await reapSentinel(abbr);

    const { data: created, error: createErr } = await supabaseAdmin.auth.admin.createUser({
      email: sentinelEmail(abbr),
      email_confirm: false,
      user_metadata: { purpose: 'D-11 coordinate smoke sentinel; safe to delete' },
    });
    if (createErr || !created?.user?.id) {
      return {
        status: 'skip',
        message:
          `service-role credential could not mint the sentinel auth user ` +
          `(${createErr?.message ?? 'no user returned'}). D-11 IS NOT PROVEN for ${abbr}.`,
      };
    }
    userId = created.user.id;

    // A trigger on auth.users creates public.users; connected_profiles is ours to add. ev_api is
    // permitted to write both, so this stays on the pg pool rather than needing `connect` exposed
    // as a PostgREST table route.
    await pool.query(`INSERT INTO public.users (id) VALUES ($1) ON CONFLICT (id) DO NOTHING`, [userId]);
    await pool.query(
      `INSERT INTO connect.connected_profiles (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );

    // Both RPCs over PostgREST as service_role — production's exact invocation path.
    const up = await adminRpc('upsert_user_location', { p_user_id: userId, p_lat: lat, p_lng: lng }, 'connect');
    if (up.error) {
      return { status: 'fail', message: `upsert_user_location failed: ${up.error.message}` };
    }

    const res = await adminRpc('resolve_congressional_2026', { p_user_id: userId }, 'connect');
    if (res.error) {
      return { status: 'fail', message: `resolve_congressional_2026 errored: ${res.error.message}` };
    }

    const got = (res.data ?? null) as string | null;
    if (got !== expectedGeoId) {
      return {
        status: 'fail',
        message:
          `resolve_congressional_2026 returned ${got === null ? 'NULL' : got} ` +
          `(expected ${expectedGeoId}) — decrypt/ST_Covers/FIPS-filter/search_path bug`,
      };
    }
    return {
      status: 'pass',
      message: `resolve_congressional_2026(sentinel) = ${got} (production adminRpc path, sentinel deleted)`,
    };
  } finally {
    // CASCADE from auth.users removes public.users, connected_profiles and the location row.
    if (userId) {
      try {
        await supabaseAdmin.auth.admin.deleteUser(userId);
      } catch {
        console.error(
          `⚠ D-11 ${abbr}: failed to delete sentinel ${userId} (${sentinelEmail(abbr)}). ` +
            `It is inert — no password, unconfirmed email — and the next run reaps it.`
        );
      }
    }
  }
}
