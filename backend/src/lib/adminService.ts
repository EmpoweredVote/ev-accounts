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
import { executeDemotion } from './empowerService.js';
import { grantRole, revokeRole } from './roleService.js';
import { getXpHistory } from './xpService.js';

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
 * Returns all fields including tolerance_rating and legal_name (admin context).
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

  return (data ?? {}) as Record<string, unknown>;
}

/**
 * Set account standing (suspend or unsuspend a Connected account).
 */
export async function setAccountStanding(
  userId: string,
  standing: 'active' | 'suspended'
): Promise<void> {
  const { error } = await supabaseAdmin
    .schema('connect')
    .from('connected_profiles')
    .update({ account_standing: standing })
    .eq('user_id', userId);

  if (error) throw new Error(error.message);
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
  const { error } = await supabaseAdmin
    .schema('connect')
    .from('invite_codes')
    .update({ is_claimed: true, claimed_at: new Date().toISOString() })
    .eq('id', codeId)
    .eq('is_claimed', false);

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
export async function adminGrantRole(userId: string, roleSlug: string): Promise<void> {
  await grantRole(userId, roleSlug);
}

/**
 * Revoke a role from a user (admin action — delegates to roleService.revokeRole).
 */
export async function adminRevokeRole(userId: string, roleSlug: string): Promise<void> {
  await revokeRole(userId, roleSlug);
}

// ---------------------------------------------------------------------------
// Compass admin (deferred from Phase 4)
// ---------------------------------------------------------------------------

/**
 * Create a new compass topic.
 */
export async function adminCreateTopic(data: {
  title: string;
  short_title?: string;
  question_text: string;
  is_live?: boolean;
}): Promise<Record<string, unknown>> {
  const { title, short_title, question_text, is_live = false } = data;

  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('compass_topics')
    .insert({
      title,
      short_title: short_title ?? null,
      question_text,
      is_live,
      went_live_at: is_live ? new Date().toISOString() : null,
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return row as Record<string, unknown>;
}

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

  const updatePayload: Record<string, unknown> = {};
  if (data.text !== undefined) updatePayload['text'] = data.text;
  if (data.value !== undefined) updatePayload['value'] = data.value;

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
 */
export async function adminSetPoliticianContext(
  politicianId: string,
  topicId: string,
  data: { reasoning: string; sources?: string[] }
): Promise<Record<string, unknown>> {
  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('politician_context')
    .upsert({
      politician_id: politicianId,
      topic_id: topicId,
      reasoning: data.reasoning,
      sources: data.sources ?? [],
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return row as Record<string, unknown>;
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
 * Create a new compass topic with optional stances atomically (two-pass RPC).
 */
export async function adminCreateTopicWithStances(data: {
  title: string;
  question_text: string;
  short_title?: string;
  is_live?: boolean;
  stances?: Array<{ value: number; text: string }>;
}): Promise<Record<string, unknown>> {
  const { data: result, error } = await adminRpc('admin_create_topic_with_stances', {
    p_title: data.title,
    p_question_text: data.question_text,
    p_short_title: data.short_title ?? null,
    p_is_live: data.is_live ?? false,
    p_stances: JSON.stringify(data.stances ?? []),
  });

  if (error) {
    if (
      error.message.startsWith('INVALID_STANCE_VALUE') ||
      error.message.startsWith('INVALID_STANCE_TEXT')
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
 */
export async function adminCreatePolitician(data: {
  first_name: string;
  last_name: string;
  preferred_name?: string;
  full_name?: string;
  office_title?: string;
  photo_origin_url?: string;
  is_candidate?: boolean;
}): Promise<Record<string, unknown>> {
  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('politicians')
    .insert({ ...data })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return row as Record<string, unknown>;
}

/**
 * Update an existing politician record.
 */
export async function adminUpdatePolitician(
  politicianId: string,
  data: Partial<{
    first_name: string;
    last_name: string;
    preferred_name: string;
    full_name: string;
    office_title: string;
    photo_origin_url: string;
    is_active: boolean;
    is_candidate: boolean;
  }>
): Promise<Record<string, unknown>> {
  const { data: row, error } = await supabaseAdmin
    .schema('inform')
    .from('politicians')
    .update(data)
    .eq('id', politicianId)
    .select()
    .single();

  if (error) {
    if (error.code === 'PGRST116') {
      throw Object.assign(new Error('Politician not found'), { code: 'NOT_FOUND' });
    }
    throw new Error(error.message);
  }

  return row as Record<string, unknown>;
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
