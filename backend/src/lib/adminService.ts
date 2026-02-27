/**
 * adminService — all admin data access functions.
 *
 * WHY THIS FILE EXISTS:
 * The architecture test enforces that no file in src/routes/ may reference
 * supabaseAdmin directly. All admin data access — including queries that need
 * service role privileges — lives here in src/lib/, not in src/routes/.
 *
 * supabaseAdmin is used ONLY for RPC calls (get_calibration_lapsed_users).
 * All SQL reads and writes use the pg pool.
 *
 * AUDIT REQUIREMENT (ADMN-05):
 * Every admin mutation route must call logAdminAction() before returning 200.
 * logAdminAction() writes to public.admin_audit_log via the pg pool.
 */

import { pool } from './db.js';
import { supabaseAdmin } from './supabase.js';
import { executeDemotion } from './empowerService.js';
import { grantRole, revokeRole } from './roleService.js';
import crypto from 'crypto';

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
  await pool.query(
    `INSERT INTO public.admin_audit_log (actor_id, action, target_user_id, details)
     VALUES ($1, $2, $3, $4)`,
    [actorId, action, targetUserId, JSON.stringify(details)]
  );
}

// ---------------------------------------------------------------------------
// Accounts
// ---------------------------------------------------------------------------

const PAGE_LIMIT = 25;

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
): Promise<{ accounts: unknown[]; total: number }> {
  const { search, tier, standing, page = 1 } = params;
  const offset = (page - 1) * PAGE_LIMIT;

  const conditions: string[] = ['u.deleted_at IS NULL'];
  const values: unknown[] = [];
  let idx = 1;

  if (search) {
    conditions.push(
      `(u.display_name ILIKE $${idx} OR u.email ILIKE $${idx})`
    );
    values.push(`%${search}%`);
    idx++;
  }

  if (standing) {
    conditions.push(`cp.account_standing = $${idx}`);
    values.push(standing);
    idx++;
  }

  // Tier filter via subquery / existence checks
  let tierJoin = '';
  if (tier === 'empowered') {
    tierJoin = `
      AND EXISTS (
        SELECT 1 FROM empower.empowered_profiles ep2
        WHERE ep2.user_id = u.id AND ep2.is_active = true
      )`;
  } else if (tier === 'connected') {
    tierJoin = `
      AND cp.user_id IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM empower.empowered_profiles ep2
        WHERE ep2.user_id = u.id AND ep2.is_active = true
      )`;
  } else if (tier === 'inform') {
    tierJoin = `AND cp.user_id IS NULL`;
  }

  const where = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

  const countQuery = `
    SELECT COUNT(*) AS total
    FROM public.users u
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    ${where}
    ${tierJoin}
  `;

  const dataQuery = `
    SELECT
      u.id,
      u.display_name,
      u.email,
      u.created_at,
      cp.account_standing,
      cp.verification_status,
      CASE
        WHEN ep.user_id IS NOT NULL THEN 'empowered'
        WHEN cp.user_id IS NOT NULL THEN 'connected'
        ELSE 'inform'
      END AS tier
    FROM public.users u
    LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
    LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    ${where}
    ${tierJoin}
    ORDER BY u.created_at DESC
    LIMIT ${PAGE_LIMIT} OFFSET $${idx}
  `;

  values.push(offset);

  const [countResult, dataResult] = await Promise.all([
    pool.query<{ total: string }>(countQuery, values.slice(0, -1)), // count doesn't need offset
    pool.query(dataQuery, values),
  ]);

  return {
    accounts: dataResult.rows,
    total: parseInt(countResult.rows[0]?.total ?? '0', 10),
  };
}

/**
 * Get full account detail for a single user.
 * Returns all fields including tolerance_rating and legal_name (admin context).
 * Includes active roles, recent audit log entries, and calibration lapse info.
 */
export async function getAccountDetail(userId: string): Promise<Record<string, unknown>> {
  const client = await pool.connect();
  try {
    // Base user record
    const { rows: userRows } = await client.query(
      `SELECT id, display_name, email, avatar_url, created_at, deleted_at
       FROM public.users WHERE id = $1`,
      [userId]
    );
    if (userRows.length === 0) {
      throw Object.assign(new Error('User not found'), { code: 'NOT_FOUND' });
    }
    const user = userRows[0];

    // Connected profile (including tolerance_rating and legal_name — admin only)
    const { rows: cpRows } = await client.query(
      `SELECT *
       FROM connect.connected_profiles
       WHERE user_id = $1`,
      [userId]
    );
    const connectedProfile = cpRows[0] ?? null;

    // Empowered profile
    const { rows: epRows } = await client.query(
      `SELECT *
       FROM empower.empowered_profiles
       WHERE user_id = $1`,
      [userId]
    );
    const empoweredProfile = epRows[0] ?? null;

    // Active user roles
    const { rows: roleRows } = await client.query(
      `SELECT ur.role_id, r.slug, r.name, ur.granted_at
       FROM public.user_roles ur
       JOIN public.roles r ON r.id = ur.role_id
       WHERE ur.user_id = $1 AND ur.revoked_at IS NULL
       ORDER BY ur.granted_at DESC`,
      [userId]
    );

    // Recent admin audit log entries targeting this user
    const { rows: auditRows } = await client.query(
      `SELECT id, actor_id, action, details, created_at
       FROM public.admin_audit_log
       WHERE target_user_id = $1
       ORDER BY created_at DESC
       LIMIT 20`,
      [userId]
    );

    // Calibration lapse info: count of live topics with went_live_at > 25 days ago
    // that this user has NOT calibrated
    const { rows: lapseRows } = await client.query(
      `SELECT
         COUNT(*) AS overdue_count,
         array_agg(ct.id) AS overdue_topic_ids,
         MIN((CURRENT_DATE - ct.went_live_at::date)::integer) AS min_days_overdue
       FROM inform.compass_topics ct
       WHERE ct.is_live = true
         AND ct.went_live_at IS NOT NULL
         AND ct.went_live_at <= now() - interval '25 days'
         AND NOT EXISTS (
           SELECT 1 FROM inform.compass_responses cr
           WHERE cr.user_id = $1 AND cr.topic_id = ct.id
         )`,
      [userId]
    );
    const lapseInfo = lapseRows[0] ?? { overdue_count: 0, overdue_topic_ids: null, min_days_overdue: null };

    // Tier derivation
    let tier: string;
    if (empoweredProfile?.is_active) {
      tier = 'empowered';
    } else if (connectedProfile) {
      tier = 'connected';
    } else {
      tier = 'inform';
    }

    return {
      ...user,
      tier,
      connected_profile: connectedProfile,
      empowered_profile: empoweredProfile,
      roles: roleRows,
      recent_audit_log: auditRows,
      calibration_lapse: {
        overdue_count: parseInt(String(lapseInfo.overdue_count), 10),
        overdue_topic_ids: lapseInfo.overdue_topic_ids ?? [],
        min_days_overdue: lapseInfo.min_days_overdue ?? null,
      },
    };
  } finally {
    client.release();
  }
}

/**
 * Set account standing (suspend or unsuspend a Connected account).
 */
export async function setAccountStanding(
  userId: string,
  standing: 'active' | 'suspended'
): Promise<void> {
  await pool.query(
    `UPDATE connect.connected_profiles
     SET account_standing = $2
     WHERE user_id = $1`,
    [userId, standing]
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
): Promise<{ invites: unknown[]; total: number }> {
  const { page = 1 } = params;
  const offset = (page - 1) * PAGE_LIMIT;

  const [countResult, dataResult] = await Promise.all([
    pool.query<{ total: string }>('SELECT COUNT(*) AS total FROM connect.invite_codes'),
    pool.query(
      `SELECT
         ic.id,
         ic.code,
         ic.is_claimed,
         ic.claimed_at,
         ic.expires_at,
         ic.created_at,
         creator.display_name AS created_by_display_name,
         ic.created_by        AS created_by_id,
         claimer.display_name AS claimed_by_display_name,
         ic.claimed_by        AS claimed_by_id
       FROM connect.invite_codes ic
       LEFT JOIN public.users creator ON creator.id = ic.created_by
       LEFT JOIN public.users claimer ON claimer.id = ic.claimed_by
       ORDER BY ic.created_at DESC
       LIMIT $1 OFFSET $2`,
      [PAGE_LIMIT, offset]
    ),
  ]);

  return {
    invites: dataResult.rows,
    total: parseInt(countResult.rows[0]?.total ?? '0', 10),
  };
}

/**
 * Generate and insert a new invite code (admin-created, no inviter).
 * Uses the same 32-character charset as inviteService.generateInviteCode().
 */
export async function adminCreateInvite(
  createdBy: string,
  recipientEmail?: string
): Promise<Record<string, unknown>> {
  const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  function generateCode(): string {
    const bytes = crypto.randomBytes(16);
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += CHARSET[bytes[i]! % 32];
    }
    return `${code.slice(0, 4)}-${code.slice(4, 8)}`;
  }

  let attempt = 0;
  while (attempt < 3) {
    attempt++;
    const code = generateCode();
    try {
      const { rows } = await pool.query(
        `INSERT INTO connect.invite_codes (code, created_by, expires_at)
         VALUES ($1, $2, now() + interval '30 days')
         RETURNING *`,
        [code, createdBy]
      );
      const row = rows[0] as Record<string, unknown>;
      if (recipientEmail) {
        row['recipient_email'] = recipientEmail;
      }
      return row;
    } catch (err) {
      const pgErr = err as { code?: string };
      if (pgErr.code === '23505' && attempt < 3) {
        continue; // Code collision — retry
      }
      throw err;
    }
  }
  throw new Error('Failed to generate invite code after 3 collision retries');
}

/**
 * Revoke an active invite code by marking it as claimed.
 */
export async function revokeInvite(codeId: string): Promise<void> {
  await pool.query(
    `UPDATE connect.invite_codes
     SET is_claimed = true, claimed_at = now()
     WHERE id = $1 AND is_claimed = false`,
    [codeId]
  );
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
  let query: string;
  let queryParams: unknown[];

  if (rootUserId) {
    // Subtree rooted at a specific user
    query = `
      WITH RECURSIVE tree AS (
        -- Anchor: the root user
        SELECT
          ic.inviter_id,
          ic.invitee_id
        FROM connect.invite_chains ic
        WHERE ic.inviter_id = $1

        UNION ALL

        -- Recursive: follow the chain down
        SELECT
          ic.inviter_id,
          ic.invitee_id
        FROM connect.invite_chains ic
        JOIN tree t ON t.invitee_id = ic.inviter_id
      )
      SELECT DISTINCT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        tree.inviter_id AS parent_id
      FROM tree
      JOIN public.users u ON u.id = tree.invitee_id
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true

      UNION ALL

      -- Include the root user itself
      SELECT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        NULL::uuid AS parent_id
      FROM public.users u
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
      WHERE u.id = $1
    `;
    queryParams = [rootUserId];
  } else {
    // Full cohort tree: all users that appear in invite_chains plus seed users
    query = `
      WITH RECURSIVE tree AS (
        -- Anchor: users who invited others (roots of chains)
        SELECT
          ic.inviter_id,
          ic.invitee_id
        FROM connect.invite_chains ic

        UNION ALL

        SELECT
          ic.inviter_id,
          ic.invitee_id
        FROM connect.invite_chains ic
        JOIN tree t ON t.invitee_id = ic.inviter_id
      )
      SELECT DISTINCT
        u.id,
        u.display_name,
        cp.account_standing,
        CASE
          WHEN ep.user_id IS NOT NULL THEN 'empowered'
          WHEN cp.user_id IS NOT NULL THEN 'connected'
          ELSE 'inform'
        END AS tier,
        (SELECT inviter_id FROM connect.invite_chains WHERE invitee_id = u.id LIMIT 1) AS parent_id
      FROM (
        SELECT invitee_id AS user_id FROM connect.invite_chains
        UNION
        SELECT inviter_id AS user_id FROM connect.invite_chains
      ) ids
      JOIN public.users u ON u.id = ids.user_id
      LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
      LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
    `;
    queryParams = [];
  }

  const { rows } = await pool.query(query, queryParams);

  // Build React Flow-compatible nodes and edges arrays
  const nodes: Record<string, unknown>[] = rows.map((row) => ({
    id: row.id as string,
    type: 'default',
    data: {
      label: row.display_name ?? 'Unknown',
      tier: row.tier,
      account_standing: row.account_standing,
    },
    position: { x: 0, y: 0 }, // Dagre layout applied client-side
  }));

  const edges: Record<string, unknown>[] = rows
    .filter((row) => row.parent_id != null)
    .map((row) => ({
      id: `${row.parent_id}-${row.id}`,
      source: row.parent_id as string,
      target: row.id as string,
    }));

  return { nodes, edges };
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

  // If creating as live, set went_live_at
  const { rows } = await pool.query(
    `INSERT INTO inform.compass_topics (title, short_title, question_text, is_live, went_live_at)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING *`,
    [
      title,
      short_title ?? null,
      question_text,
      is_live,
      is_live ? new Date().toISOString() : null,
    ]
  );
  return rows[0] as Record<string, unknown>;
}

/**
 * Update a compass topic.
 * CRITICAL: when is_live transitions to true, also set went_live_at = now().
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
  // Fetch current is_live state to detect transition
  const { rows: current } = await pool.query(
    'SELECT is_live, went_live_at FROM inform.compass_topics WHERE id = $1',
    [topicId]
  );
  if (current.length === 0) {
    throw Object.assign(new Error('Topic not found'), { code: 'NOT_FOUND' });
  }
  const wasLive = current[0].is_live as boolean;
  const isTransitioningToLive = data.is_live === true && !wasLive;

  const setClauses: string[] = ['updated_at = now()'];
  const values: unknown[] = [];
  let idx = 1;

  if (data.title !== undefined) {
    setClauses.push(`title = $${idx}`);
    values.push(data.title);
    idx++;
  }
  if (data.short_title !== undefined) {
    setClauses.push(`short_title = $${idx}`);
    values.push(data.short_title);
    idx++;
  }
  if (data.question_text !== undefined) {
    setClauses.push(`question_text = $${idx}`);
    values.push(data.question_text);
    idx++;
  }
  if (data.is_live !== undefined) {
    setClauses.push(`is_live = $${idx}`);
    values.push(data.is_live);
    idx++;
    // When transitioning to live, set went_live_at if not already set
    if (isTransitioningToLive) {
      setClauses.push(`went_live_at = COALESCE(went_live_at, now())`);
    }
  }

  values.push(topicId);
  const { rows } = await pool.query(
    `UPDATE inform.compass_topics SET ${setClauses.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  return rows[0] as Record<string, unknown>;
}

/**
 * Update a compass stance.
 */
export async function adminUpdateStance(
  stanceId: string,
  data: Partial<{ text: string; value: number }>
): Promise<Record<string, unknown>> {
  const setClauses: string[] = [];
  const values: unknown[] = [];
  let idx = 1;

  if (data.text !== undefined) {
    setClauses.push(`text = $${idx}`);
    values.push(data.text);
    idx++;
  }
  if (data.value !== undefined) {
    setClauses.push(`value = $${idx}`);
    values.push(data.value);
    idx++;
  }

  if (setClauses.length === 0) {
    throw new Error('No fields to update');
  }

  values.push(stanceId);
  const { rows } = await pool.query(
    `UPDATE inform.compass_stances SET ${setClauses.join(', ')} WHERE id = $${idx} RETURNING *`,
    values
  );
  if (rows.length === 0) {
    throw Object.assign(new Error('Stance not found'), { code: 'NOT_FOUND' });
  }
  return rows[0] as Record<string, unknown>;
}

/**
 * Upsert politician answers (bulk replace for a politician).
 */
export async function adminUpdatePoliticianAnswers(
  politicianId: string,
  answers: Array<{ topic_id: string; value: number }>
): Promise<void> {
  if (answers.length === 0) return;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const answer of answers) {
      await client.query(
        `INSERT INTO inform.politician_answers (politician_id, topic_id, value)
         VALUES ($1, $2, $3)
         ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value`,
        [politicianId, answer.topic_id, answer.value]
      );
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Upsert politician context (reasoning + sources for a politician/topic pair).
 */
export async function adminSetPoliticianContext(
  politicianId: string,
  topicId: string,
  data: { reasoning: string; sources?: string[] }
): Promise<Record<string, unknown>> {
  const { rows } = await pool.query(
    `INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (politician_id, topic_id)
     DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
     RETURNING *`,
    [politicianId, topicId, data.reasoning, data.sources ?? []]
  );
  return rows[0] as Record<string, unknown>;
}

/**
 * List all politicians with their answer counts (admin view, includes inactive).
 */
export async function adminListPoliticians(): Promise<Record<string, unknown>[]> {
  const { rows } = await pool.query(
    `SELECT
       p.id,
       p.first_name,
       p.last_name,
       p.preferred_name,
       p.full_name,
       p.office_title,
       p.photo_origin_url,
       p.is_active,
       p.created_at,
       COUNT(pa.topic_id) AS answer_count
     FROM inform.politicians p
     LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
     GROUP BY p.id
     ORDER BY p.last_name, p.first_name`
  );
  return rows as Record<string, unknown>[];
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

/**
 * Return cohort dashboard statistics.
 */
export async function getDashboardStats(): Promise<Record<string, unknown>> {
  const [tierCounts, standingCounts, pendingVerifications, recentInvites, activeInviteCodes] =
    await Promise.all([
      // Users by tier
      pool.query(`
        SELECT
          CASE
            WHEN ep.user_id IS NOT NULL THEN 'empowered'
            WHEN cp.user_id IS NOT NULL THEN 'connected'
            ELSE 'inform'
          END AS tier,
          COUNT(*) AS count
        FROM public.users u
        LEFT JOIN connect.connected_profiles cp ON cp.user_id = u.id
        LEFT JOIN empower.empowered_profiles ep ON ep.user_id = u.id AND ep.is_active = true
        WHERE u.deleted_at IS NULL
        GROUP BY 1
      `),
      // Users by account_standing
      pool.query(`
        SELECT account_standing, COUNT(*) AS count
        FROM connect.connected_profiles
        GROUP BY account_standing
      `),
      // Pending verifications
      pool.query(`
        SELECT COUNT(*) AS count
        FROM connect.verification_sessions
        WHERE step_reached != 'complete'
      `),
      // Recent invite activity (last 7 days)
      pool.query(`
        SELECT COUNT(*) AS count
        FROM connect.invite_codes
        WHERE created_at >= now() - interval '7 days'
      `),
      // Active (unclaimed) invite codes
      pool.query(`
        SELECT COUNT(*) AS count
        FROM connect.invite_codes
        WHERE is_claimed = false
          AND (expires_at IS NULL OR expires_at > now())
      `),
    ]);

  return {
    users_by_tier: tierCounts.rows,
    users_by_standing: standingCounts.rows,
    pending_verifications: parseInt(String(pendingVerifications.rows[0]?.count ?? 0), 10),
    recent_invites_7d: parseInt(String(recentInvites.rows[0]?.count ?? 0), 10),
    active_invite_codes: parseInt(String(activeInviteCodes.rows[0]?.count ?? 0), 10),
  };
}

// ---------------------------------------------------------------------------
// Cron log
// ---------------------------------------------------------------------------

/**
 * Return calibration lapse run history. Paginated.
 */
export async function getCronLog(
  params: CronLogParams
): Promise<{ runs: unknown[]; total: number }> {
  const { page = 1 } = params;
  const offset = (page - 1) * PAGE_LIMIT;

  const [countResult, dataResult] = await Promise.all([
    pool.query<{ total: string }>(
      'SELECT COUNT(*) AS total FROM public.calibration_lapse_runs'
    ),
    pool.query(
      `SELECT run_date, started_at, finished_at, users_warned_25, users_warned_30,
              users_demoted, error_message
       FROM public.calibration_lapse_runs
       ORDER BY run_date DESC
       LIMIT $1 OFFSET $2`,
      [PAGE_LIMIT, offset]
    ),
  ]);

  return {
    runs: dataResult.rows,
    total: parseInt(countResult.rows[0]?.total ?? '0', 10),
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
export async function getAdminMe(_userId: string): Promise<{ isAdmin: boolean }> {
  // If we reach this function, requireAdmin middleware already confirmed admin status
  return { isAdmin: true };
}
