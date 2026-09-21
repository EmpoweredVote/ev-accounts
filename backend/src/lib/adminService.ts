/**
 * adminService — all admin data access functions.
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. All admin data access — including queries that need
 * service role privileges — lives here in src/lib/, not in src/routes/.
 *
 * All SQL reads and writes use supabaseAdmin (HTTP/REST via PostgREST + RPC).
 * Complex queries (recursive CTEs, transactions, dynamic WHERE) are wrapped
 * in SECURITY DEFINER RPC functions in migration 025_rpc_pool_migration.sql.
 *
 * AUDIT REQUIREMENT (ADMN-05):
 * Every admin mutation route must call logAdminAction() before returning 200.
 * logAdminAction() writes to public.admin_audit_log via supabaseAdmin.
 */

import { supabaseAdmin, adminRpc } from './supabase.js';
import { pool } from './db.js';
import { executeDemotion } from './empowerService.js';
import { grantRole, revokeRole, getUserRoles } from './roleService.js';
import { getXpHistory } from './xpService.js';
import { UPSERT_CONTEXT_SQL, assertWritten } from './seasonService.js';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface AccountListParams {
  search?: string;
  tier?: string;
  standing?: string;
  page?: number;
}

export interface InviteListParams {
  page?: number;
}

export interface CronLogParams {
  page?: number;
}

// ---------------------------------------------------------------------------
// Audit
// ---------------------------------------------------------------------------

/**
 * Log an admin action to public.admin_audit_log (ADMN-05).
 * Called before every admin mutation returns 200.
 */
export async function logAdminAction(
  actorId: string,
  action: string,
  targetUserId: string | null,
  details: Record<string, unknown> = {}
): Promise<void> {
  const { error } = await supabaseAdmin
    .from('admin_audit_log')
    .insert({
      actor_id: actorId,
      action,
      target_user_id: targetUserId,
      // Cast through unknown: database.types.ts uses Json type for details,
      // but Record<string, unknown> is a valid jsonb-serializable value.
      details: details as unknown as import('../types/database.types.js').Json,
    });

  if (error) throw new Error(error.message);
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

/**
 * List accounts with optional search, tier, and standing filters.
 * Paginates at 25 accounts per page.
 *
 * Tier derivation (matches application logic):
 *   - empowered: has active empower.empowered_profiles row (is_active = true)
 *   - connected: has connect.connected_profiles row but no active empowered_profiles
 *   - inform:    no connect.connected_profiles row
 */
export async function listAccounts(
  params: AccountListParams
): Promise<{ accounts: unknown[]; total: number; page: number; pages: number }> {
  const { search, tier, standing, page = 1 } = params;

  const { data, error } = await adminRpc('admin_list_accounts', {
    p_search: search ?? null,
    p_tier: tier ?? null,
    p_standing: standing ?? null,
    p_page: page,
  });

  if (error) throw new Error(error.message);

  const result = data as { accounts: unknown[]; total: number; page: number; pages: number };
  return {
    accounts: result.accounts ?? [],
    total: result.total ?? 0,
    page: result.page ?? page,
    pages: result.pages ?? 1,
  };
}

/**
 * Get full account detail for a single user.
 * Returns all fields including tolerance_rating (admin context). The Connect
 * legal_name is NOT returned — it is vaulted (id_vault), readable only via
 * offline break-glass, never by the app or any admin; the underlying RPC
 * still computes it but this function strips it before it reaches the caller.
 * Includes active roles, recent audit log entries, and calibration lapse info.
 */
export async function getAccountDetail(userId: string): Promise<Record<string, unknown>> {
  const { data, error } = await adminRpc('admin_get_account_detail', {
    p_user_id: userId,
  });

  if (error) {
    if (error.message === 'NOT_FOUND') {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }

  const result = (data ?? {}) as Record<string, unknown>;

  // Enrich roles with scope columns from getUserRoles (get_user_roles RPC returns
  // feature_scope, jurisdiction_geoid, and resource_id which may be absent from
  // the admin_get_account_detail RPC result).
  try {
    const enrichedRoles = await getUserRoles(userId);
    result.roles = enrichedRoles;
  } catch {
    // Non-fatal: fall back to whatever admin_get_account_detail returned
  }

  // The real Connect name is vaulted (ev-cto 0022). The RPC nests it under
  // connected_profile (row_to_json of connect.connected_profiles), so strip it there.
  // Leave empowered_profile.legal_name — that name is public.
  const cp = (result as Record<string, unknown>).connected_profile;
  if (cp && typeof cp === 'object') {
    delete (cp as Record<string, unknown>).legal_name;
  }

  return result;
}

/**
 * Get jurisdiction geoids for a user from their connected_profile.
 * Used by the admin GrantRoleModal to surface clickable geoid hints.
 */
export async function getAccountJurisdictions(userId: string): Promise<{
  county_geo_id: string | null;
  county_name: string | null;
  congressional_geo_id: string | null;
  congressional_district_name: string | null;
  state_senate_geo_id: string | null;
  state_senate_district_name: string | null;
  state_house_geo_id: string | null;
  state_house_district_name: string | null;
} | null> {
  const result = await pool.query<{
    county_geo_id: string | null;
    county_name: string | null;
    congressional_geo_id: string | null;
    congressional_district_name: string | null;
    state_senate_geo_id: string | null;
    state_senate_district_name: string | null;
    state_house_geo_id: string | null;
    state_house_district_name: string | null;
  }>(
    `SELECT county_geo_id, county_name, congressional_geo_id, congressional_district_name,
            state_senate_geo_id, state_senate_district_name, state_house_geo_id, state_house_district_name
     FROM connect.connected_profiles WHERE user_id = $1`,
    [userId]
  );
  return result.rows[0] ?? null;
}

/**
 * Set account standing (suspend or unsuspend a Connected account).
 */
export async function setAccountStanding(
  userId: string,
  standing: 'active' | 'suspended'
): Promise<void> {
  await pool.query(
    `UPDATE connect.connected_profiles SET account_standing = $2 WHERE user_id = $1`,
    [userId, standing]
  );
}

/**
 * Manually override a user's verification_rating and/or clear vq_hold_until.
 * VR-05 admin capability.
 */
export async function updateVerificationRating(
  userId: string,
  opts: { rating?: number; clearHold?: boolean }
): Promise<void> {
  const setClauses: string[] = [];
  const params: unknown[] = [userId];

  if (opts.rating !== undefined) {
    params.push(opts.rating);
    setClauses.push(`verification_rating = $${params.length}`);
  }
  if (opts.clearHold === true) {
    setClauses.push(`vq_hold_until = NULL`);
  }

  if (setClauses.length === 0) return;

  await pool.query(
    `UPDATE connect.connected_profiles SET ${setClauses.join(', ')} WHERE user_id = $1`,
    params
  );
}

/**
 * Demote an Empowered user by calling executeDemotion from empowerService.
 */
export async function adminDemote(
  userId: string,
  reason: Record<string, unknown>
): Promise<void> {
  await executeDemotion(userId, reason);
}

// ---------------------------------------------------------------------------
// Invites
// ---------------------------------------------------------------------------

/**
 * List all invite codes with creator and claimer display names. Paginated.
 */
export async function listInvites(
  params: InviteListParams
): Promise<{ codes: unknown[]; total: number; page: number; pages: number }> {
  const { page = 1 } = params;

  const { data, error } = await adminRpc('admin_list_invites', {
    p_page: page,
  });

  if (error) throw new Error(error.message);

  const result = data as { invites: Array<Record<string, unknown>>; total: number };
  const total = result.total ?? 0;
  const pages = Math.max(1, Math.ceil(total / 25));

  // Rename display_name fields to match React component expectations
  const codes = (result.invites ?? []).map((invite) => ({
    ...invite,
    created_by_name: invite.created_by_display_name,
    claimed_by_name: invite.claimed_by_display_name,
  }));

  return { codes, total, page, pages };
}

/**
 * Generate and insert a new invite code (admin-created, no inviter).
 */
export async function adminCreateInvite(
  createdBy: string,
  recipientEmail?: string
): Promise<Record<string, unknown>> {
  const { data, error } = await adminRpc('admin_create_invite', {
    p_created_by: createdBy,
    p_recipient_email: recipientEmail ?? null,
  });

  if (error) throw new Error(error.message);

  return data as Record<string, unknown>;
}

/**
 * Revoke an active invite code by marking it as claimed.
 */
export async function revokeInvite(codeId: string): Promise<void> {
  const { error } = await adminRpc('revoke_invite_code', { p_code_id: codeId });
  if (error) throw new Error(error.message);
}

/**
 * Build React Flow-compatible invite tree using a recursive CTE.
 * If rootUserId is provided, returns the subtree rooted at that user.
 * Otherwise returns the full cohort tree.
 */
export async function getInviteTree(rootUserId?: string): Promise<{
  nodes: Record<string, unknown>[];
  edges: Record<string, unknown>[];
}> {
  const { data, error } = await adminRpc('admin_get_invite_tree', {
    p_root_user_id: rootUserId ?? null,
  });

  if (error) throw new Error(error.message);

  const result = data as { nodes: Record<string, unknown>[]; edges: Record<string, unknown>[] };
  return {
    nodes: result.nodes ?? [],
    edges: result.edges ?? [],
  };
}

// ---------------------------------------------------------------------------
// Roles (deferred from Phase 6)
// ---------------------------------------------------------------------------

/**
 * Grant a role to a user (admin action — delegates to roleService.grantRole).
 */
export async function adminGrantRole(
  userId: string,
  roleSlug: string,
  featureScope?: string,
  jurisdictionGeoid?: string | null,
  resourceId?: string | null,
  grantedById?: string | null
): Promise<void> {
  await grantRole(userId, roleSlug, featureScope, jurisdictionGeoid, resourceId, grantedById);
}

/**
 * Revoke a role from a user (admin action — delegates to roleService.revokeRole).
 */
export async function adminRevokeRole(
  userId: string,
  roleSlug: string,
  featureScope?: string,
  jurisdictionGeoid?: string | null,
  resourceId?: string | null
): Promise<void> {
  await revokeRole(userId, roleSlug, featureScope, jurisdictionGeoid, resourceId);
}

/**
 * Write an entry to public.role_audit_log after a grant or revoke action.
 *
 * Called from admin.ts after adminGrantRole/adminRevokeRole succeeds.
 * Uses pool.query (direct postgres) — public schema write.
 */
export async function writeRoleAuditLog(
  actorId: string,
  targetUserId: string,
  action: 'granted' | 'revoked',
  roleSlug: string,
  featureScope: string,
  jurisdictionGeoid: string | null,
  resourceId: string | null
): Promise<void> {
  await pool.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, action, feature_scope, jurisdiction_geoid, resource_id, snapshot_after)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      actorId,
      targetUserId,
      action,
      featureScope,
      jurisdictionGeoid,
      resourceId,
      JSON.stringify({ role_slug: roleSlug }),
    ]
  );
}

/**
 * List all active roles available to grant.
 */
export async function listRoles(): Promise<{ id: string; slug: string; name: string; required_tier: string; description: string | null; is_active: boolean }[]> {
  const result = await pool.query<{ id: string; slug: string; name: string; required_tier: string; description: string | null; is_active: boolean }>(
    `SELECT id, slug, name, required_tier, description, is_active FROM public.roles WHERE is_active = true ORDER BY name ASC`
  );
  return result.rows;
}

/**
 * Read paginated, filterable entries from public.role_audit_log.
 */
export async function getRoleAuditLog(filters: {
  feature_scope?: string;
  jurisdiction_geoid?: string;
  from_date?: string;
  to_date?: string;
  page: number;
  page_size: number;
}): Promise<{ entries: unknown[]; total: number; page: number; page_size: number }> {
  const { feature_scope, jurisdiction_geoid, from_date, to_date, page, page_size } = filters;

  const conditions: string[] = [];
  const params: unknown[] = [];

  if (feature_scope) {
    params.push(feature_scope);
    conditions.push(`ral.feature_scope = $${params.length}`);
  }
  if (jurisdiction_geoid) {
    params.push(jurisdiction_geoid);
    conditions.push(`ral.jurisdiction_geoid = $${params.length}`);
  }
  if (from_date) {
    params.push(from_date);
    conditions.push(`ral.created_at >= $${params.length}`);
  }
  if (to_date) {
    params.push(to_date);
    conditions.push(`ral.created_at <= $${params.length}`);
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const countResult = await pool.query<{ total: string }>(
    `SELECT COUNT(*) AS total FROM public.role_audit_log ral ${whereClause}`,
    params
  );
  const total = parseInt(countResult.rows[0]?.total ?? '0', 10);

  const offset = (page - 1) * page_size;
  params.push(page_size);
  const limitParam = params.length;
  params.push(offset);
  const offsetParam = params.length;

  const dataResult = await pool.query(
    `SELECT
       ral.id,
       ral.actor_id,
       ral.target_user_id,
       ral.action,
       ral.feature_scope,
       ral.jurisdiction_geoid,
       ral.resource_id,
       ral.created_at,
       ral.snapshot_after,
       actor_u.display_name  AS actor_display_name,
       target_u.display_name AS target_display_name
     FROM public.role_audit_log ral
     JOIN public.users actor_u  ON actor_u.id  = ral.actor_id
     JOIN public.users target_u ON target_u.id = ral.target_user_id
     ${whereClause}
     ORDER BY ral.created_at DESC
     LIMIT $${limitParam} OFFSET $${offsetParam}`,
    params
  );

  return {
    entries: dataResult.rows,
    total,
    page,
    page_size,
  };
}

// ---------------------------------------------------------------------------
// Compass admin (deferred from Phase 4)
// ---------------------------------------------------------------------------

/**
 * Update a compass topic.
 * CRITICAL: when is_live transitions to true, also set went_live_at = now().
 * Uses the admin_update_topic RPC which handles the COALESCE logic and
 * went_live_at transition atomically.
 */
export async function adminUpdateTopic(
  topicId: string,
  data: Partial<{
    title: string;
    short_title: string;
    question_text: string;
    is_live: boolean;
  }>
): Promise<Record<string, unknown>> {
  const { data: result, error } = await adminRpc('admin_update_topic', {
    p_topic_id: topicId,
    p_title: data.title ?? null,
    p_short_title: data.short_title ?? null,
    p_question_text: data.question_text ?? null,
    p_is_live: data.is_live ?? null,
  });

  if (error) {
    if (error.message === 'NOT_FOUND') {
      throw Object.assign(new Error('Topic not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }

  return result as Record<string, unknown>;
}

/**
 * Update a compass stance.
 */
export async function adminUpdateStance(
  stanceId: string,
  data: Partial<{ text: string; value: number }>
): Promise<Record<string, unknown>> {
  if (Object.keys(data).length === 0) {
    throw new Error('No fields to update');
  }

  // Typed concretely rather than as Record<string, unknown>: postgrest-js
  // guards .update() with RejectExcessProperties, which cannot prove an
  // open index signature has no excess columns.
  const updatePayload: { text?: string; value?: number } = {};
  if (data.text !== undefined) updatePayload.text = data.text;
  if (data.value !== undefined) updatePayload.value = data.value;

  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_stances')
    .update(updatePayload)
    .eq('id', stanceId)
    .select()
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw Object.assign(new Error('Stance not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }

  return row as Record<string, unknown>;
}

/**
 * List all stances for a topic. Used by GET /admin/compass/topics/:id/stances.
 */
export async function getTopicStances(
  topicId: string
): Promise<Record<string, unknown>[]> {
  const { data, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_stances')
    .select('id, topic_id, value, text')
    .eq('topic_id', topicId)
    .order('value', { ascending: true });

  if (error) throw new Error(error.message);
  return (data ?? []) as Record<string, unknown>[];
}

/**
 * Upsert politician answers (bulk replace for a politician).
 */
export async function adminUpdatePoliticianAnswers(
  politicianId: string,
  answers: Array<{ topic_id: string; value: number }>
): Promise<void> {
  if (answers.length === 0) return;

  const { error } = await adminRpc('admin_update_politician_answers', {
    p_politician_id: politicianId,
    p_answers: answers,
  });

  if (error) throw new Error(error.message);
}

/**
 * Upsert politician context (reasoning + sources for a politician/topic pair).
 * Uses pool.query() — PostgREST cannot write to non-public schemas reliably.
 * inform.politician_context stays in the inform schema (only inform.politicians
 * was moved to essentials in Phase 35).
 */
export async function adminSetPoliticianContext(
  politicianId: string,
  topicId: string,
  data: { reasoning: string; sources?: string[] },
  editorId?: string | null
): Promise<Record<string, unknown>> {
  // Season-aware write; shape defined once in seasonService. It writes into the
  // OPEN season and stamps that season's pinned ladder revision, so the stored
  // reasoning records which question text it was reasoning about.
  const { rows } = await pool.query<Record<string, unknown>>(
    `${UPSERT_CONTEXT_SQL} RETURNING *`,
    [politicianId, topicId, data.reasoning, data.sources ?? [], editorId ?? null]
  );
  // Zero rows means no open season, or this topic is not in its question set.
  // 'Upsert failed' would have hidden both behind one unhelpful string.
  await assertWritten(rows.length, topicId);
  return rows[0];
}

/**
 * List all politicians with their answer counts (admin view, includes inactive).
 */
export async function adminListPoliticians(): Promise<Record<string, unknown>[]> {
  const { data, error } = await adminRpc('admin_list_politicians');

  if (error) throw new Error(error.message);

  return (data as Record<string, unknown>[]) ?? [];
}

/**
 * Create a new compass topic on the REVISION model (ADR 0004 / ADR 0006).
 *
 * Calls inform.admin_create_topic_with_revision (CA_0026), which atomically
 * writes the identity row, the legacy 5-rung ladder, a published + is_current
 * v1 compass_topic_revisions row, its 5 compass_stance_revisions, and any
 * requested scope rows. That published/current v1 is exactly what the season
 * read path resolves display from and what inform.admin_season_add_topic
 * requires to pin the topic — the legacy admin_create_topic_with_stances RPC
 * (migration 029) wrote no revision, leaving new topics invisible and unpinnable.
 *
 * Editing an existing topic still goes through admin_propose_topic_revision, the
 * append-only review path; this function is create-only.
 */
export async function adminCreateTopicWithRevision(data: {
  title: string;
  question_text: string;
  short_title?: string;
  is_live?: boolean;
  stances?: Array<{ value: number; text: string }>;
  role_scopes?: string[];
  actorId?: string | null;
}): Promise<Record<string, unknown>> {
  const { data: result, error } = await adminRpc(
    'admin_create_topic_with_revision',
    {
      p_title: data.title,
      p_question_text: data.question_text,
      p_short_title: data.short_title ?? null,
      p_is_live: data.is_live ?? false,
      p_stances: JSON.stringify(data.stances ?? []),
      p_actor_id: data.actorId ?? null,
      p_role_scopes: data.role_scopes ? JSON.stringify(data.role_scopes) : null,
    },
    'inform',
  );

  if (error) {
    // Author-facing validation errors surface as 4xx; everything else is a 500.
    if (
      /^(BAD_LADDER|DUPLICATE_TOPIC_KEY|INVALID_TITLE|INVALID_QUESTION|INVALID_TOPIC_KEY|INVALID_ROLE_SCOPE)/.test(
        error.message,
      )
    ) {
      throw Object.assign(new Error(error.message), { code: 'VALIDATION_ERROR' });
    }
    throw new Error(error.message);
  }

  return result as Record<string, unknown>;
}

/**
 * List all compass topics (admin view, includes non-live drafts). Metadata only — no stances.
 */
export async function adminListTopics(): Promise<Record<string, unknown>[]> {
  const { data: rows, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_topics')
    .select('id, title, short_title, is_live, created_at, updated_at')
    .order('created_at', { ascending: false });

  if (error) throw new Error(error.message);
  return (rows ?? []) as Record<string, unknown>[];
}

/**
 * Create a new politician record.
 * Writes to essentials.politicians via pool.query() — PostgREST cannot write
 * to non-public schemas reliably.
 * full_name in essentials is a regular column (not GENERATED) — caller may provide it.
 */
export async function adminCreatePolitician(data: {
  first_name: string;
  last_name: string;
  preferred_name?: string;
  full_name?: string;
  photo_origin_url?: string;
  party?: string;
  party_short_name?: string;
  slug?: string;
  bio_text?: string;
  is_incumbent?: boolean;
}): Promise<Record<string, unknown>> {
  // Derive full_name from first/last if not provided
  const fullName = data.full_name ?? `${data.first_name} ${data.last_name}`.trim();

  const { rows } = await pool.query<Record<string, unknown>>(
    `INSERT INTO essentials.politicians
       (first_name, last_name, preferred_name, full_name, photo_origin_url,
        party, party_short_name, slug, bio_text, is_incumbent)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
     RETURNING *`,
    [
      data.first_name,
      data.last_name,
      data.preferred_name ?? null,
      fullName,
      data.photo_origin_url ?? null,
      data.party ?? null,
      data.party_short_name ?? null,
      data.slug ?? null,
      data.bio_text ?? null,
      data.is_incumbent ?? true,
    ]
  );
  if (rows.length === 0) throw new Error('Insert failed');
  return rows[0];
}

/**
 * Update an existing politician record.
 * Writes to essentials.politicians via pool.query() — PostgREST cannot write
 * to non-public schemas reliably.
 * Only essentials-native columns are accepted (inform-specific columns removed).
 */
export async function adminUpdatePolitician(
  politicianId: string,
  data: Partial<{
    first_name: string;
    last_name: string;
    preferred_name: string;
    full_name: string;
    photo_origin_url: string;
    party: string;
    party_short_name: string;
    slug: string;
    bio_text: string;
    is_active: boolean;
    is_incumbent: boolean;
    is_vacant: boolean;
  }>
): Promise<Record<string, unknown>> {
  const setClauses: string[] = [];
  const values: unknown[] = [];
  let paramIndex = 1;

  for (const [key, val] of Object.entries(data)) {
    if (val !== undefined) {
      setClauses.push(`${key} = $${paramIndex}`);
      values.push(val);
      paramIndex++;
    }
  }

  if (setClauses.length === 0) throw new Error('No fields to update');

  values.push(politicianId);
  const { rows } = await pool.query<Record<string, unknown>>(
    `UPDATE essentials.politicians SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
    values
  );

  if (rows.length === 0) {
    throw Object.assign(new Error('Politician not found'), { code: 'NOT_FOUND' });
  }
  return rows[0];
}

/**
 * List all compass categories ordered alphabetically.
 */
export async function adminListCategories(): Promise<Record<string, unknown>[]> {
  const { data: rows, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_categories')
    .select('id, title, created_at')
    .order('title', { ascending: true });

  if (error) throw new Error(error.message);
  return (rows ?? []) as Record<string, unknown>[];
}

/**
 * Create a new compass category.
 * Throws DUPLICATE_TITLE if the title already exists (unique constraint on title).
 */
export async function adminCreateCategory(data: {
  title: string;
}): Promise<Record<string, unknown>> {
  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_categories')
    .insert({ title: data.title })
    .select()
    .single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error('Category title already exists'), { code: 'DUPLICATE_TITLE' });
    }
    throw new Error(error.message);
  }

  return row as Record<string, unknown>;
}

/**
 * Atomically replace all category assignments for a topic (DELETE + INSERT via RPC).
 */
export async function adminAssignTopicCategories(
  topicId: string,
  categoryIds: string[]
): Promise<void> {
  const { error } = await adminRpc('admin_assign_topic_categories', {
    p_topic_id: topicId,
    p_category_ids: JSON.stringify(categoryIds),
  });

  if (error) {
    if (error.message === 'NOT_FOUND') {
      throw Object.assign(new Error('Topic not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }
}

// ---------------------------------------------------------------------------
// Admin email resolution
// ---------------------------------------------------------------------------

/**
 * Resolve the email address for an admin user via supabaseAdmin.auth.admin.getUserById.
 * This is the only permitted method for resolving admin email on the promote endpoint.
 * Returns null if the user cannot be found or if email is absent.
 *
 * Called from the promote route to denormalize admin_email into the promotion log
 * without requiring the caller to pass their own email (which would be spoofable).
 */
export async function getAdminEmailById(adminId: string): Promise<string | null> {
  const { data, error } = await supabaseAdmin.auth.admin.getUserById(adminId);
  if (error || !data.user) return null;
  return data.user.email ?? null;
}

// ---------------------------------------------------------------------------
// Tier promotion
// ---------------------------------------------------------------------------

const PROMOTION_PAGE_SIZE = 25;

/**
 * Promote an Inform-tier user to Connected via the promote_to_connected RPC.
 * The RPC is atomic: inserts connected_profiles and tier_promotion_log in one transaction.
 * Throws with code 'NOT_FOUND' if target user does not exist.
 * Throws with code 'ALREADY_CONNECTED' if target user already has a connected_profiles row.
 */
export async function promoteToConnected(
  adminId: string,
  adminEmail: string,
  targetUserId: string,
  note?: string
): Promise<{ display_name: string }> {
  const { data, error } = await adminRpc(
    'promote_to_connected',
    {
      p_admin_id: adminId,
      p_admin_email: adminEmail,
      p_target_user_id: targetUserId,
      p_note: note ?? null,
    },
    'connect'
  );

  if (error) {
    if (error.message === 'USER_NOT_FOUND') {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' });
    }
    if (error.message === 'ALREADY_CONNECTED_OR_HIGHER') {
      throw Object.assign(new Error('User is already Connected or Empowered'), {
        code: 'ALREADY_CONNECTED',
      });
    }
    throw new Error(error.message);
  }

  const result = data as { ok: boolean; display_name: string };
  return { display_name: result.display_name };
}

/**
 * Get paginated promotion history for a specific target user.
 * Returns entries in reverse chronological order (newest first).
 */
export async function getPromotionHistory(
  targetUserId: string,
  page: number = 1
): Promise<{ entries: unknown[]; total: number; page: number; pages: number }> {
  const from = (page - 1) * PROMOTION_PAGE_SIZE;

  const { data, error, count } = await supabaseAdmin
    .schema('connect')
    .from('tier_promotion_log')
    .select('*', { count: 'exact' })
    .eq('target_user_id', targetUserId)
    .order('created_at', { ascending: false })
    .range(from, from + PROMOTION_PAGE_SIZE - 1);

  if (error) throw new Error(error.message);

  const total = count ?? 0;
  const pages = Math.max(1, Math.ceil(total / PROMOTION_PAGE_SIZE));

  return {
    entries: (data ?? []) as unknown[],
    total,
    page,
    pages,
  };
}

/**
 * Get paginated global promotion log (all users, all admins).
 * Returns entries in reverse chronological order with target user display_names
 * batch-fetched and attached to each entry.
 */
export async function getGlobalPromotionLog(
  page: number = 1
): Promise<{ entries: unknown[]; total: number; page: number; pages: number }> {
  const from = (page - 1) * PROMOTION_PAGE_SIZE;

  const { data, error, count } = await supabaseAdmin
    .schema('connect')
    .from('tier_promotion_log')
    .select('*', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, from + PROMOTION_PAGE_SIZE - 1);

  if (error) throw new Error(error.message);

  const rows = (data ?? []) as Array<Record<string, unknown>>;
  const total = count ?? 0;
  const pages = Math.max(1, Math.ceil(total / PROMOTION_PAGE_SIZE));

  if (rows.length === 0) {
    return { entries: [], total, page, pages };
  }

  // Batch-fetch target user display_names to avoid N+1 queries
  const uniqueTargetIds = [...new Set(rows.map((r) => r.target_user_id as string))];

  const { data: users, error: usersError } = await supabaseAdmin
    .from('users')
    .select('id, display_name')
    .in('id', uniqueTargetIds);

  if (usersError) {
    console.error('[adminService] error fetching user display_names for promotion log:', usersError);
  }

  // Build id -> display_name lookup map
  const displayNameMap: Record<string, string | null> = {};
  for (const u of users ?? []) {
    displayNameMap[u.id] = u.display_name;
  }

  // Attach target_display_name to each log entry
  const entries = rows.map((row) => ({
    ...row,
    target_display_name: displayNameMap[row.target_user_id as string] ?? null,
  }));

  return { entries, total, page, pages };
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/**
 * Return cohort dashboard statistics.
 */
export async function getDashboardStats(): Promise<Record<string, unknown>> {
  const { data, error } = await adminRpc('admin_get_dashboard_stats');

  if (error) throw new Error(error.message);

  return data as Record<string, unknown>;
}

// ---------------------------------------------------------------------------
// Cron log
// ---------------------------------------------------------------------------

/**
 * Return calibration lapse run history. Paginated.
 */
export async function getCronLog(
  params: CronLogParams
): Promise<{ runs: unknown[]; total: number; page: number; pages: number }> {
  const { page = 1 } = params;

  const { data, error } = await adminRpc('admin_get_cron_log', {
    p_page: page,
  });

  if (error) throw new Error(error.message);

  const result = data as { runs: Array<Record<string, unknown>>; total: number };
  const total = result.total ?? 0;
  const pages = Math.max(1, Math.ceil(total / 25));

  // Remap SQL column names to React component field names
  const runs = (result.runs ?? []).map((run) => ({
    ...run,
    id: run.run_date, // run_date is PK — use as React key
    warned_25d: run.users_warned_25,
    warned_30d: run.users_warned_30,
    demoted_count: run.users_demoted,
    error: run.error_message ?? null,
  }));

  return { runs, total, page, pages };
}

// ---------------------------------------------------------------------------
// XP history (admin read — delegates to xpService)
// ---------------------------------------------------------------------------

/**
 * Return paginated XP transaction history for any user.
 * Delegates to getXpHistory from xpService — mirrors how adminDemote delegates
 * to executeDemotion from empowerService.
 * XPADM-02
 */
export async function getAdminXpHistory(
  userId: string,
  page: number = 1
): Promise<{ transactions: unknown[]; total: number; page: number; pages: number }> {
  const limit = 25;
  const offset = (page - 1) * limit;
  const { transactions, total } = await getXpHistory(userId, { limit, offset });
  return {
    transactions,
    total,
    page,
    pages: Math.max(1, Math.ceil(total / limit)),
  };
}

// ---------------------------------------------------------------------------
// Admin identity
// ---------------------------------------------------------------------------

/**
 * Confirm whether a user is an admin (used by GET /api/admin/me).
 * requireAdmin middleware handles the 403 for non-admins, so this always
 * returns { isAdmin: true } when called from within the admin router.
 */
export async function getAdminMe(userId: string): Promise<{ isAdmin: boolean; id: string; email: string }> {
  // If we reach this function, requireAdmin middleware already confirmed admin status
  const { data } = await supabaseAdmin.auth.admin.getUserById(userId);
  return { isAdmin: true, id: userId, email: data.user?.email ?? '' };
}

/**
 * Check if a user has admin flag. Used by GET /api/account/me to include
 * is_admin in the response without requiring a separate API call.
 * Simple PK lookup — negligible performance cost.
 * Fails closed: returns false if the check itself errors.
 */
export async function isUserAdmin(userId: string): Promise<boolean> {
  const { data, error } = await supabaseAdmin
    .from('admin_users')
    .select('user_id')
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    console.error('[adminService] isUserAdmin error:', error.message);
    return false; // Fail closed — not admin if check fails
  }

  return data !== null;
}

/**
 * Insert an email into public.access_requests for admin review.
 * Used by POST /api/auth/request-access.
 * Architecture rule: supabaseAdmin must not be used in route files;
 * this helper owns the service-role write.
 */
export async function insertAccessRequest(email: string): Promise<void> {
  const { error } = await supabaseAdmin
    .from('access_requests')
    .insert({ email });

  if (error) {
    throw new Error(error.message);
  }
}

export async function listAccessRequests(): Promise<
  { id: string; email: string; requested_at: string }[]
> {
  const { data, error } = await supabaseAdmin
    .from('access_requests')
    .select('id, email, requested_at')
    .order('requested_at', { ascending: false });

  if (error) throw new Error(error.message);
  return data ?? [];
}

// ---------------------------------------------------------------------------
// Account deletion
// ---------------------------------------------------------------------------

/**
 * Hard-delete a user account via Supabase auth admin API.
 * Deleting from auth.users cascades to public.users, which cascades to all
 * child records (connected_profiles, xp_transactions, etc.).
 *
 * Throws with code 'NOT_FOUND' if the user does not exist.
 * Throws with code 'SELF_DELETE' if admin tries to delete their own account.
 */
export async function deleteAccount(
  adminId: string,
  targetUserId: string
): Promise<void> {
  if (targetUserId === adminId) {
    throw Object.assign(new Error('Cannot delete your own account'), { code: 'SELF_DELETE' });
  }

  const { error } = await supabaseAdmin.auth.admin.deleteUser(targetUserId);

  if (error) {
    if (
      error.message.toLowerCase().includes('not found') ||
      error.message.toLowerCase().includes('user not found')
    ) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }
}
