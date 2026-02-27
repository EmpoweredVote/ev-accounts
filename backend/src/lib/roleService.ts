/**
 * roleService — role grant, revocation, and query operations.
 *
 * WHY THIS FILE EXISTS:
 * Role operations require reading and writing to public.roles and public.user_roles.
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. Grant/revoke operations that call SECURITY DEFINER
 * functions or bypass RLS live here in src/lib/.
 *
 * ROLE HISTORY:
 * Revoked role rows are never reused. Revocation sets revoked_at timestamp on the
 * existing row (audit trail preserved). Re-grant after revocation creates a new row.
 * The partial unique index on (user_id, role_id) WHERE revoked_at IS NULL prevents
 * duplicate active grants while allowing re-grant after revocation.
 *
 * CIVIC-04 CONFLICT ENFORCEMENT:
 * ROLE_CONFLICT_GROUPS defines which roles cannot be held simultaneously.
 * Empty for Alpha — populated as roles are defined with conflict rules.
 * The enforcement code path is exercised regardless of map contents.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Role conflict groups (CIVIC-04)
// ---------------------------------------------------------------------------

// Role conflict groups: roles in the same group cannot be held simultaneously.
// Empty for Alpha — populated as roles are defined with conflict rules.
// Example future entry: { 'arbiter': 'judicial', 'juror': 'judicial' }
const ROLE_CONFLICT_GROUPS: Record<string, string> = {};

// ---------------------------------------------------------------------------
// grantRole
// ---------------------------------------------------------------------------

/**
 * Grant a role to a user.
 *
 * Enforces:
 * 1. Role exists and is active
 * 2. User meets the required tier
 * 3. No conflicting active roles (CIVIC-04)
 * 4. Role not already actively granted (partial unique index prevents duplicates)
 */
export async function grantRole(userId: string, roleSlug: string): Promise<void> {
  const client = await pool.connect();
  try {
    // 1. Fetch role by slug
    const { rows: roleRows } = await client.query<{
      id: string;
      required_tier: string | null;
      is_active: boolean;
    }>('SELECT id, required_tier, is_active FROM public.roles WHERE slug = $1', [roleSlug]);

    if (roleRows.length === 0) {
      throw Object.assign(new Error(`Role '${roleSlug}' not found`), { code: 'ROLE_NOT_FOUND' });
    }

    const role = roleRows[0]!;

    if (!role.is_active) {
      throw Object.assign(new Error(`Role '${roleSlug}' is not active`), {
        code: 'ROLE_INACTIVE',
      });
    }

    // 2. Enforce tier eligibility
    if (role.required_tier === 'empowered') {
      const { rows: empRows } = await client.query(
        'SELECT id FROM empower.empowered_profiles WHERE user_id = $1 AND is_active = true',
        [userId]
      );
      if (empRows.length === 0) {
        throw Object.assign(
          new Error(`Role '${roleSlug}' requires Empowered tier`),
          { code: 'TIER_INELIGIBLE' }
        );
      }
    } else if (role.required_tier === 'connected') {
      const { rows: connRows } = await client.query(
        "SELECT id FROM connect.connected_profiles WHERE user_id = $1 AND verification_status = 'verified'",
        [userId]
      );
      if (connRows.length === 0) {
        throw Object.assign(
          new Error(`Role '${roleSlug}' requires Connected tier`),
          { code: 'TIER_INELIGIBLE' }
        );
      }
    }

    // 3. CIVIC-04: Check for conflicting active roles
    const conflictGroup = ROLE_CONFLICT_GROUPS[roleSlug];
    if (conflictGroup) {
      // Find all role slugs in the same conflict group
      const conflictingSlugs = Object.entries(ROLE_CONFLICT_GROUPS)
        .filter(([, group]) => group === conflictGroup)
        .map(([slug]) => slug)
        .filter((slug) => slug !== roleSlug);

      if (conflictingSlugs.length > 0) {
        const { rows: conflictRows } = await client.query(
          `SELECT r.slug FROM public.user_roles ur
           JOIN public.roles r ON r.id = ur.role_id
           WHERE ur.user_id = $1 AND ur.revoked_at IS NULL AND r.slug = ANY($2)`,
          [userId, conflictingSlugs]
        );
        if (conflictRows.length > 0) {
          throw Object.assign(
            new Error(
              `Role '${roleSlug}' conflicts with active role '${conflictRows[0].slug}'`
            ),
            { code: 'ROLE_CONFLICT' }
          );
        }
      }
    }

    // 4. INSERT new row — NEVER reuse/update revoked rows (preserves full history)
    try {
      await client.query(
        'INSERT INTO public.user_roles (user_id, role_id) VALUES ($1, $2)',
        [userId, role.id]
      );
    } catch (err) {
      const pgErr = err as { code?: string };
      if (pgErr.code === '23505') {
        // unique_violation — user already has an active grant for this role
        throw Object.assign(new Error(`Role '${roleSlug}' already granted`), {
          code: 'ROLE_ALREADY_GRANTED',
        });
      }
      throw err;
    }
  } finally {
    client.release();
  }
}

// ---------------------------------------------------------------------------
// revokeRole
// ---------------------------------------------------------------------------

/**
 * Soft-revoke a role by setting revoked_at on the active grant row.
 *
 * Idempotent — no error if no matching active grant.
 */
export async function revokeRole(userId: string, roleSlug: string): Promise<void> {
  await pool.query(
    `UPDATE public.user_roles ur
     SET revoked_at = now()
     FROM public.roles r
     WHERE ur.role_id = r.id
       AND ur.user_id = $1
       AND r.slug = $2
       AND ur.revoked_at IS NULL`,
    [userId, roleSlug]
  );
}

// ---------------------------------------------------------------------------
// getUserRoles
// ---------------------------------------------------------------------------

/**
 * Return all active (non-revoked) roles for a user.
 */
export async function getUserRoles(
  userId: string
): Promise<Array<{ role_id: string; slug: string; name: string; granted_at: string }>> {
  const { rows } = await pool.query(
    `SELECT ur.role_id, r.slug, r.name, ur.granted_at
     FROM public.user_roles ur
     JOIN public.roles r ON r.id = ur.role_id
     WHERE ur.user_id = $1 AND ur.revoked_at IS NULL
     ORDER BY ur.granted_at DESC`,
    [userId]
  );
  return rows;
}

// ---------------------------------------------------------------------------
// getAllActiveRoles
// ---------------------------------------------------------------------------

/**
 * Return all active roles in the system (reference list for UI).
 */
export async function getAllActiveRoles(): Promise<
  Array<{
    id: string;
    name: string;
    slug: string;
    required_tier: string | null;
    description: string | null;
  }>
> {
  const { rows } = await pool.query(
    `SELECT id, name, slug, required_tier, description
     FROM public.roles
     WHERE is_active = true
     ORDER BY name`
  );
  return rows;
}
