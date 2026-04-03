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
 * Conflict enforcement is handled server-side in the grant_role SQL function.
 */

import { supabaseAdmin, adminRpc } from './supabase.js';
import { cache } from './cache.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface UserRoleGrant {
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}

export interface CheckRoleScope {
  geoid?: string;
  resourceId?: string;
}

// ---------------------------------------------------------------------------
// checkRole
// ---------------------------------------------------------------------------

/**
 * Pure function — checks whether any of the provided grants match the given
 * role slug and optional scope constraints.
 *
 * NULL-safe scope semantics:
 * - A grant with `jurisdiction_geoid = null` is unrestricted — it passes any
 *   geoid check. Only a non-null grant geoid that differs from the requested
 *   geoid causes a skip.
 * - The same logic applies to `resource_id`.
 *
 * If `roleSlug` is an array, OR logic is applied: returns true if ANY slug
 * matches.
 */
export function checkRole(
  grants: UserRoleGrant[],
  roleSlug: string | string[],
  scope?: CheckRoleScope
): boolean {
  const slugs = Array.isArray(roleSlug) ? roleSlug : [roleSlug];

  for (const grant of grants) {
    if (!slugs.includes(grant.slug)) continue;

    // NULL-safe geoid check: skip only if grant has a non-null geoid that
    // does not match the requested geoid.
    if (scope?.geoid !== undefined) {
      if (grant.jurisdiction_geoid !== null && grant.jurisdiction_geoid !== scope.geoid) {
        continue;
      }
    }

    // NULL-safe resourceId check: skip only if grant has a non-null resource_id
    // that does not match the requested resourceId.
    if (scope?.resourceId !== undefined) {
      if (grant.resource_id !== null && grant.resource_id !== scope.resourceId) {
        continue;
      }
    }

    return true;
  }

  return false;
}

// ---------------------------------------------------------------------------
// getCachedUserRoles
// ---------------------------------------------------------------------------

/**
 * Return active role grants for a user, served from Redis cache when available.
 *
 * Cache key: `roles:uid:{userId}` with 90s TTL.
 * Redis is an optimization — all cache errors fall through to DB.
 */
export async function getCachedUserRoles(userId: string): Promise<UserRoleGrant[]> {
  const key = `roles:uid:${userId}`;

  try {
    const cached = await cache.get<UserRoleGrant[]>(key);
    if (cached !== null) return cached;
  } catch (err) {
    console.error('[roleService] cache error (get):', err);
  }

  const grants = await getUserRoles(userId);

  try {
    await cache.set(key, grants, 90);
  } catch (err) {
    console.error('[roleService] cache error (set):', err);
  }

  return grants;
}

// ---------------------------------------------------------------------------
// invalidateRoleCache
// ---------------------------------------------------------------------------

/**
 * Remove the cached role grants for a user. Call after grant or revoke.
 * Safe to call even if Redis is unavailable — errors are swallowed.
 */
export async function invalidateRoleCache(userId: string): Promise<void> {
  try {
    await cache.del(`roles:uid:${userId}`);
  } catch (err) {
    console.error('[roleService] cache error (del):', err);
  }
}

// ---------------------------------------------------------------------------
// grantRole
// ---------------------------------------------------------------------------

/**
 * Grant a role to a user.
 *
 * Delegates to the grant_role SECURITY DEFINER RPC which enforces:
 * 1. Role exists and is active
 * 2. User meets the required tier
 * 3. No conflicting active roles (CIVIC-04 — empty for Alpha)
 * 4. Role not already actively granted
 */
export async function grantRole(userId: string, roleSlug: string): Promise<void> {
  const { error } = await adminRpc('grant_role', {
    p_user_id: userId,
    p_role_slug: roleSlug,
  });

  if (error) {
    const msg = error.message;
    if (msg === 'ROLE_NOT_FOUND') {
      throw Object.assign(new Error(`Role '${roleSlug}' not found`), { code: 'ROLE_NOT_FOUND' });
    }
    if (msg === 'ROLE_INACTIVE') {
      throw Object.assign(new Error(`Role '${roleSlug}' is not active`), { code: 'ROLE_INACTIVE' });
    }
    if (msg === 'TIER_INELIGIBLE') {
      throw Object.assign(new Error(`Role '${roleSlug}' requires a higher tier`), { code: 'TIER_INELIGIBLE' });
    }
    if (msg === 'ROLE_ALREADY_GRANTED') {
      throw Object.assign(new Error(`Role '${roleSlug}' already granted`), { code: 'ROLE_ALREADY_GRANTED' });
    }
    if (msg === 'ROLE_CONFLICT') {
      throw Object.assign(new Error(`Role '${roleSlug}' conflicts with an existing active role`), { code: 'ROLE_CONFLICT' });
    }
    throw new Error(msg);
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
  const { error } = await adminRpc('revoke_role', {
    p_user_id: userId,
    p_role_slug: roleSlug,
  });

  if (error) throw new Error(error.message);
}

// ---------------------------------------------------------------------------
// getUserRoles
// ---------------------------------------------------------------------------

/**
 * Return all active (non-revoked) roles for a user.
 */
export async function getUserRoles(
  userId: string
): Promise<Array<{
  role_id: string;
  slug: string;
  name: string;
  granted_at: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
}>> {
  const { data, error } = await adminRpc('get_user_roles', {
    p_user_id: userId,
  });

  if (error) throw new Error(error.message);

  return ((data ?? []) as Array<{
    role_id: string;
    slug: string;
    name: string;
    granted_at: string;
    feature_scope: string;
    jurisdiction_geoid: string | null;
    resource_id: string | null;
  }>);
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
  const { data, error } = await supabaseAdmin
    .from('roles')
    .select('id,name,slug,required_tier,description')
    .eq('is_active', true)
    .order('name');

  if (error) throw new Error(error.message);

  return (data ?? []) as Array<{
    id: string;
    name: string;
    slug: string;
    required_tier: string | null;
    description: string | null;
  }>;
}
