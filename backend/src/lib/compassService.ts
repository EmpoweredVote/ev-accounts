import { adminRpc, supabaseAnon, createUserClient } from './supabase.js';
import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Types for compare and verdicts service functions
// ---------------------------------------------------------------------------

interface CompareTopic {
  topic_id: string;
  user_value: number;
  politician_value: number;
}

interface CompareResult {
  id: string;
  name: string | null;
  alignment_score: number;
  topics: CompareTopic[];
}

interface Verdict {
  quote_id: string;
  supported: boolean;
  rank: number | null;
  session_size: number;
  created_at: string;
  updated_at: string;
}

interface PoliticianAnswer {
  topic_id: string;
  value: number;
}

/**
 * promoteCompassImportDraft
 *
 * Lazy promotion: moves Phase 3 calibration data stored in
 * connect.verification_sessions.compass_import_draft into the live
 * inform.compass_responses table.
 *
 * Called on the first GET /compass/answers for a user. If the draft is
 * already NULL (already promoted or never set), the function exits
 * immediately without touching the database.
 *
 * Non-fatal: if any error occurs the transaction is rolled back, the draft
 * is preserved (so the next GET /answers will retry), and the error is
 * logged but NOT re-thrown. Callers should never surface this failure to
 * the end user.
 *
 * ON CONFLICT (user_id, topic_id) DO NOTHING ensures manual calibrations
 * already saved by the user are never overwritten by an imported draft.
 *
 * Delegates to the promote_compass_import_draft SECURITY DEFINER RPC which
 * handles the transactional multi-step promotion atomically.
 */
export async function promoteCompassImportDraft(userId: string): Promise<void> {
  const { error } = await adminRpc('promote_compass_import_draft', {
    p_user_id: userId,
  });

  if (error) {
    // Non-fatal — log but do not re-throw. Draft is preserved for retry.
    console.error('[promoteCompassImportDraft] error — draft preserved for retry:', error.message);
  }
}

/**
 * getCompassCompleteness
 *
 * Calculates how many live compass topics a user has answered, optionally
 * filtered by the topics required for a specific role scope.
 *
 * When roleScope is provided, only topics with a matching compass_topic_roles
 * row where is_required=true are counted as "required". All other live topics
 * are ignored for that scope.
 *
 * Returns { required, answered, percent, complete }:
 *   - required: total topics the user should answer (0 when none)
 *   - answered:  topics for which the user has a compass_responses row
 *   - percent:   Math.round((answered / required) * 100); 100 when required === 0
 *   - complete:  true when answered >= required
 */
export async function getCompassCompleteness(
  userId: string,
  roleScope?: string
): Promise<{ required: number; answered: number; percent: number; complete: boolean }> {
  const { data, error } = await adminRpc('get_compass_completeness', {
    p_user_id: userId,
    p_role_scope: roleScope ?? null,
  });

  if (error) throw new Error(error.message);

  const result = data as { required: number; answered: number; percent: number; complete: boolean };
  return result;
}

// ---------------------------------------------------------------------------
// Public reference data reads — use supabaseAnon (inform tables: public-read RLS)
// ---------------------------------------------------------------------------

/**
 * getCompassTopics
 * Returns all live topics with nested stances, categories, and role scopes.
 */
export async function getCompassTopics() {
  const { data: topics, error: topicsError } = await supabaseAnon
    .schema('inform')
    .from('compass_topics')
    .select('id,topic_key,title,short_title,question_text,is_live,version,office_scope,fc_community_slug,judicial_role')
    .eq('is_live', true)
    .order('created_at', { ascending: true });

  if (topicsError) throw topicsError;
  if (!topics || topics.length === 0) return [];

  const topicIds = topics.map(t => t.id);

  const [stancesRes, catsRes, rolesRes] = await Promise.all([
    supabaseAnon
      .schema('inform')
      .from('compass_stances')
      .select('topic_id,id,value,text')
      .in('topic_id', topicIds)
      .order('value', { ascending: true }),
    supabaseAnon
      .schema('inform')
      .from('compass_topic_categories')
      .select('topic_id,compass_categories(id,title)')
      .in('topic_id', topicIds),
    supabaseAnon
      .schema('inform')
      .from('compass_topic_roles')
      .select('topic_id,role_scope,is_required')
      .in('topic_id', topicIds),
  ]);

  if (stancesRes.error) throw stancesRes.error;
  if (catsRes.error) throw catsRes.error;
  if (rolesRes.error) throw rolesRes.error;

  return topics.map(topic => {
    const topicRoles = (rolesRes.data ?? []).filter(r => r.topic_id === topic.id);

    // Normalize tier rows into three booleans at the API boundary.
    // A topic with no rows defaults to all three tiers = true (cross-cutting).
    const hasAnyRoleRows = topicRoles.length > 0;
    const applies_federal = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'federal')
      : true;
    const applies_state = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'state')
      : true;
    const applies_local = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'local')
      : true;
    // CRITICAL: fallback is false (not true) — existing cross-cutting topics must NOT appear on judicial profiles
    const applies_judicial = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'judicial')
      : false;

    return {
      ...topic,
      applies_federal,
      applies_state,
      applies_local,
      applies_judicial,
      stances: (stancesRes.data ?? [])
        .filter(s => s.topic_id === topic.id)
        .map(({ topic_id: _tid, ...s }) => s),
      categories: (catsRes.data ?? [])
        .filter(c => c.topic_id === topic.id)
        .map(c => {
          const cat = c.compass_categories as { id: string; title: string } | null;
          return cat ? { category_id: cat.id, title: cat.title } : null;
        })
        .filter(Boolean),
      roles: topicRoles.map(({ topic_id: _tid, ...r }) => r),
    };
  });
}

/**
 * getCompassLenses
 * Returns active compass lenses with their ordered topic IDs and per-office
 * auto-apply scope (auto_district_types). Shared source of truth consumed by
 * both the Compass and Essentials apps, replacing hardcoded lens constants.
 */
export async function getCompassLenses() {
  // Raw SQL (pool.query) — compass_lenses/compass_lens_topics are not in the
  // generated PostgREST types, matching how essentials-schema reads work here.
  const { rows } = await pool.query(
    `SELECT l.key, l.name, l.description, l.color, l.icon,
            COALESCE(l.auto_district_types, ARRAY[]::text[]) AS auto_district_types,
            COALESCE(
              array_agg(lt.topic_id::text ORDER BY lt.sort_order)
                FILTER (WHERE lt.topic_id IS NOT NULL),
              ARRAY[]::text[]
            ) AS topic_ids
     FROM inform.compass_lenses l
     LEFT JOIN inform.compass_lens_topics lt ON lt.lens_id = l.id
     WHERE l.is_active = true
     GROUP BY l.id, l.key, l.name, l.description, l.color, l.icon, l.auto_district_types
     ORDER BY l.key`
  );

  return rows.map((r: any) => ({
    key: r.key,
    name: r.name,
    description: r.description,
    color: r.color,
    icon: r.icon,
    autoDistrictTypes: r.auto_district_types ?? [],
    topicIds: r.topic_ids ?? [],
  }));
}

/**
 * getCompassCategories
 * Returns all categories with nested live topics. Each nested topic carries
 * the same tier flag fields (applies_federal/state/local + office_scope) as
 * getCompassTopics, so consumers can render tier badges without needing a
 * second flat-topics lookup.
 */
export async function getCompassCategories() {
  const [catRes, topicCatRes, rolesRes] = await Promise.all([
    supabaseAnon
      .schema('inform')
      .from('compass_categories')
      .select('id,title')
      .order('title', { ascending: true }),
    supabaseAnon
      .schema('inform')
      .from('compass_topic_categories')
      .select('category_id,compass_topics!inner(id,topic_key,title,short_title,question_text,is_live,office_scope)')
      .eq('compass_topics.is_live', true),
    supabaseAnon
      .schema('inform')
      .from('compass_topic_roles')
      .select('topic_id,role_scope'),
  ]);

  if (catRes.error) throw catRes.error;
  if (topicCatRes.error) throw topicCatRes.error;
  if (rolesRes.error) throw rolesRes.error;

  // Build a per-topic tier map so we can attach booleans without an extra join.
  // A topic with no rows defaults to all three tiers = true (cross-cutting),
  // matching the fallback behavior in getCompassTopics.
  const rolesByTopicId = new Map<string, Set<string>>();
  for (const r of rolesRes.data ?? []) {
    const set = rolesByTopicId.get(r.topic_id) ?? new Set<string>();
    set.add(r.role_scope);
    rolesByTopicId.set(r.topic_id, set);
  }

  const tierFlagsFor = (topicId: string) => {
    const scopes = rolesByTopicId.get(topicId);
    if (!scopes || scopes.size === 0) {
      // CRITICAL: applies_judicial defaults to false — cross-cutting topics must NOT appear on judicial profiles
      return { applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false };
    }
    return {
      applies_federal:  scopes.has('federal'),
      applies_state:    scopes.has('state'),
      applies_local:    scopes.has('local'),
      applies_judicial: scopes.has('judicial'),
    };
  };

  return (catRes.data ?? []).map(cat => ({
    ...cat,
    topics: (topicCatRes.data ?? [])
      .filter(tc => tc.category_id === cat.id)
      .map(tc => {
        const t = tc.compass_topics as {
          id: string;
          topic_key: string;
          title: string;
          short_title: string | null;
          question_text: string;
          is_live: boolean;
          office_scope: string[] | null;
        } | null;
        if (!t) return null;
        return {
          id: t.id,
          topic_key: t.topic_key,
          title: t.title,
          short_title: t.short_title,
          question_text: t.question_text,
          office_scope: t.office_scope,
          ...tierFlagsFor(t.id),
        };
      })
      .filter(Boolean)
      .sort((a, b) => (a as { title: string }).title.localeCompare((b as { title: string }).title)),
  }));
}

/**
 * getCompassPoliticians
 * Returns all active politicians ordered by name.
 * Queries essentials.politicians (unified table after Phase 35 deduplication).
 * Uses pool.query() — essentials schema is not exposed via PostgREST.
 * Note: essentials.politicians does not have office_title; full_name is a regular column.
 */
export async function getCompassPoliticians() {
  // Only return politicians that have at least one compass answer
  // (matches Go backend behavior — prevents every card from showing compass icon)
  const { rows } = await pool.query(
    `SELECT DISTINCT ON (p.id)
            p.id, p.first_name, p.last_name, p.preferred_name, p.full_name,
            COALESCE(NULLIF(p.photo_custom_url, ''), pi.url, NULLIF(p.photo_origin_url, ''), '') AS photo_origin_url,
            p.is_active,
            COALESCE(o.title, '') AS office_title,
            COALESCE(o.representing_state, '') AS representing_state,
            COALESCE(o.representing_city, '') AS representing_city,
            COALESCE(d.label, '') AS district_label,
            COALESCE(d.district_type, '') AS district_type,
            (SELECT COUNT(*)::int FROM inform.politician_answers
             WHERE politician_id = p.id AND value != 0) AS answer_count,
            (SELECT array_agg(topic_id) FROM inform.politician_answers
             WHERE politician_id = p.id AND value != 0) AS answered_topic_ids
     FROM essentials.politicians p
     JOIN inform.politician_answers pa ON pa.politician_id = p.id
     -- ADR 0002 phase 5: occupancy resolves via office_current_holder, not offices.politician_id.
     LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
     LEFT JOIN essentials.offices o ON o.id = och.office_id
     LEFT JOIN essentials.districts d ON d.id = o.district_id
     LEFT JOIN LATERAL (
       SELECT url FROM essentials.politician_images
       WHERE politician_id = p.id AND type = 'default' LIMIT 1
     ) pi ON true
     WHERE p.is_active = true
     ORDER BY p.id, o.id DESC`
  );

  return rows.map((r) => ({
    id: r.id as string,
    first_name: r.first_name ?? null,
    last_name: r.last_name ?? null,
    preferred_name: r.preferred_name ?? null,
    full_name: r.full_name ?? null,
    photo_origin_url: r.photo_origin_url ?? '',
    is_active: r.is_active ?? true,
    office_title: r.office_title ?? '',
    representing_state: r.representing_state ?? '',
    representing_city: r.representing_city ?? '',
    district_label: r.district_label ?? '',
    district_type: r.district_type ?? '',
    answer_count: r.answer_count ?? 0,
    answered_topic_ids: (r.answered_topic_ids ?? []) as string[],
  }));
}

/**
 * getCandidates
 * Returns active election candidates that have at least one compass answer via
 * either their empowered_profile (Path A: compass_responses) or researched stances
 * (Path B: politician_answers). Rows include stance_source: 'empowered' | 'researched'.
 * Uses pool.query() — essentials and empower are not in the PostgREST exposed schema list.
 */
export async function getCandidates() {
  const { rows } = await pool.query(
    `SELECT
      rc.id,
      rc.first_name,
      rc.last_name,
      NULL::text AS preferred_name,
      rc.full_name,
      COALESCE(NULLIF(p.photo_custom_url, ''), pi.url, NULLIF(p.photo_origin_url, ''), NULLIF(rc.photo_url, ''), '') AS photo_origin_url,
      NULL::text AS photo_custom_url,
      r.position_name AS office_title,
      COALESCE(o.representing_state, e.state::text, '') AS representing_state,
      COALESCE(o.representing_city, '') AS representing_city,
      COALESCE(d.label, '') AS district_label,
      COALESCE(d.district_type, '') AS district_type,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN (
          SELECT COUNT(*)::int FROM inform.compass_responses cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          SELECT COUNT(*)::int FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      END AS answer_count,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN (
          SELECT array_agg(cr.topic_id) FROM inform.compass_responses cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          SELECT array_agg(pa.topic_id) FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      END AS answered_topic_ids,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN 'empowered'
        ELSE 'researched'
      END AS stance_source,
      true AS is_candidate,
      rc.is_incumbent
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN essentials.offices o ON o.id = r.office_id
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.politicians p ON p.id = rc.politician_id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = rc.politician_id AND type = 'default' LIMIT 1
    ) pi ON true
    -- The candidate_status = 'active' test is stricter than the shared predicate: it also excludes
    -- 'filed'. That is pre-existing behaviour and whether 'filed' should count here is an open
    -- product question, so it stays. is_live_candidate is added on top to pick up the
    -- not_nominated rule (migration 1582).
    WHERE rc.candidate_status = 'active'
      AND essentials.is_live_candidate(rc.candidate_status, rc.result)
      AND e.election_date >= CURRENT_DATE
      AND rc.politician_id IS NOT NULL
      AND rc.is_incumbent = false
      AND (
        EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep
          JOIN inform.compass_responses cr ON cr.user_id = ep.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        OR EXISTS (
          SELECT 1 FROM inform.politician_answers pa
          WHERE pa.politician_id = rc.politician_id AND pa.value != 0
        )
      )`
  );

  return rows.map((r) => ({
    id: r.id as string,
    first_name: r.first_name ?? null,
    last_name: r.last_name ?? null,
    preferred_name: (r.preferred_name ?? null) as string | null,
    full_name: r.full_name ?? null,
    photo_origin_url: (r.photo_origin_url ?? '') as string,
    is_active: true,
    office_title: (r.office_title ?? '') as string,
    representing_state: (r.representing_state ?? '') as string,
    representing_city: (r.representing_city ?? '') as string,
    district_label: (r.district_label ?? '') as string,
    district_type: (r.district_type ?? '') as string,
    answer_count: (r.answer_count ?? 0) as number,
    answered_topic_ids: ((r.answered_topic_ids ?? []) as string[]),
    stance_source: (r.stance_source ?? 'researched') as 'empowered' | 'researched',
    is_candidate: true as const,
    is_incumbent: (r.is_incumbent ?? false) as boolean,
  }));
}

/**
 * getCandidateAnswers
 * Dual-path lookup: tries empowered_profiles → compass_responses (Path A),
 * falls back to politician_answers (Path B).
 * Returns null if the candidate is not found or has no answers on either path.
 * Uses pool.query() exclusively.
 */
export async function getCandidateAnswers(
  candidateId: string
): Promise<Array<{ topic_id: string; value: number }> | null> {
  // Step 1: resolve politician_id from race_candidates
  const candidateRes = await pool.query<{ politician_id: string }>(
    `SELECT politician_id FROM essentials.race_candidates WHERE id = $1`,
    [candidateId]
  );
  if (candidateRes.rows.length === 0 || !candidateRes.rows[0].politician_id) return null;
  const politicianId = candidateRes.rows[0].politician_id;

  // Step 2: try Path A — empowered_profiles → compass_responses
  const profileRes = await pool.query<{ user_id: string }>(
    `SELECT user_id FROM empower.empowered_profiles WHERE politician_id = $1`,
    [politicianId]
  );
  if (profileRes.rows.length > 0) {
    const userId = profileRes.rows[0].user_id;
    const answersRes = await pool.query<{ topic_id: string; value: number }>(
      `SELECT topic_id, value
       FROM inform.compass_responses
       WHERE user_id = $1 AND deleted_at IS NULL AND value != 0
       ORDER BY topic_id ASC`,
      [userId]
    );
    if (answersRes.rows.length > 0) return answersRes.rows;
  }

  // Step 3: fall back to Path B — politician_answers (researched stances)
  const researchedRes = await pool.query<{ topic_id: string; value: number }>(
    `SELECT topic_id, value
     FROM inform.politician_answers
     WHERE politician_id = $1 AND value != 0
     ORDER BY topic_id ASC`,
    [politicianId]
  );
  if (researchedRes.rows.length > 0) return researchedRes.rows;

  return null;
}

/**
 * getPoliticianAnswers
 * Returns a politician's stances on all topics they have answered.
 */
export async function getPoliticianAnswers(politicianId: string) {
  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('politician_answers')
    .select('topic_id,value')
    .eq('politician_id', politicianId)
    .neq('value', 0)
    .order('topic_id', { ascending: true });

  if (error) throw error;
  return data ?? [];
}

/**
 * getPoliticianContext
 * Returns reasoning and sources for a politician's stance on a topic, or null if absent.
 */
export async function getPoliticianContext(politicianId: string, topicId: string) {
  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('politician_context')
    .select('reasoning,sources')
    .eq('politician_id', politicianId)
    .eq('topic_id', topicId)
    .maybeSingle();

  if (error) throw error;
  return data ?? null;
}

/**
 * getPoliticianContextAll
 * Returns all context rows for a politician (topic_id → { sources, reasoning }).
 * Used by contributor editors to pre-populate source URL fields.
 */
export async function getPoliticianContextAll(
  politicianId: string
): Promise<{ topic_id: string; reasoning: string; sources: string[] }[]> {
  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('politician_context')
    .select('topic_id,reasoning,sources')
    .eq('politician_id', politicianId);

  if (error) throw error;
  return (data ?? []) as { topic_id: string; reasoning: string; sources: string[] }[];
}

/**
 * validateTopicIds
 * Checks that all submitted topic IDs exist and are live.
 * Returns the array of invalid IDs (empty array = all valid).
 */
export async function validateTopicIds(topicIds: string[]): Promise<string[]> {
  if (topicIds.length === 0) return [];

  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('compass_topics')
    .select('id')
    .in('id', topicIds)
    .eq('is_live', true);

  if (error) throw error;

  const validIds = new Set((data ?? []).map(t => t.id));
  return topicIds.filter(id => !validIds.has(id));
}

/**
 * resetCompassAnswers
 *
 * Soft-deletes all of a user's compass responses and clears their
 * selected_topic_ids in a single atomic operation.
 *
 * Delegates to the reset_compass_answers SECURITY DEFINER RPC which handles
 * the multi-table atomic update. Idempotent — safe to call when the user has
 * no responses (RPC exits cleanly).
 *
 * When fullReset is true (admin-only flag), also sets completed_onboarding =
 * false on connected_profiles, returning the user to pre-calibration state.
 */
export async function resetCompassAnswers(
  userId: string,
  fullReset: boolean = false
): Promise<void> {
  const { error } = await adminRpc('reset_compass_answers', {
    p_user_id: userId,
    p_full_reset: fullReset,
  });

  if (error) throw new Error(error.message);
}

/**
 * saveSelectedTopics
 * Saves validated topic IDs into connected_profiles.selected_topic_ids.
 * Uses createUserClient — RLS enforces owner-only update.
 * Returns false if the user has no connected_profiles row (NOT_CONNECTED).
 */
export async function saveSelectedTopics(
  accessToken: string,
  userId: string,
  topicIds: string[]
): Promise<boolean> {
  const { rows } = await pool.query<{ id: string }>(
    `UPDATE connect.connected_profiles
     SET selected_topic_ids = $2::jsonb, updated_at = now()
     WHERE user_id = $1
     RETURNING id`,
    [userId, JSON.stringify(topicIds)]
  );
  return rows.length > 0;
}

// ---------------------------------------------------------------------------
// Compare and verdicts service functions (Phase 39)
// All use pool.query() — inform and essentials schemas not fully in PostgREST
// ---------------------------------------------------------------------------

/**
 * compareWithPoliticians
 *
 * Computes proximity-based alignment scores between a user and one or more
 * politicians. Only topics where BOTH the user AND the politician have an
 * answer are included in scoring.
 *
 * Scoring formula per shared topic:
 *   score = 1 - (|user_value - politician_value| / 5)
 * Alignment score = average(scores) * 100, rounded to nearest integer.
 * When no shared topics exist, alignment_score = 0.
 *
 * Uses pool.query() for both user answers (inform.compass_responses) and
 * politician answers (inform.politician_answers + essentials.politicians).
 * supabaseAnon must NOT be used — it has no auth context for user reads.
 */
export async function compareWithPoliticians(
  userId: string,
  politicianIds: string[]
): Promise<CompareResult[]> {
  // Fetch user's non-deleted answers once; reuse across all politicians
  const { rows: userAnswerRows } = await pool.query<{ topic_id: string; value: string }>(
    `SELECT topic_id, value::text
     FROM inform.compass_responses
     WHERE user_id = $1 AND deleted_at IS NULL`,
    [userId]
  );
  const userMap = new Map<string, number>(
    userAnswerRows.map(r => [r.topic_id, parseFloat(r.value)])
  );

  // Fetch all politician answers in parallel
  const politicianResults = await Promise.all(
    politicianIds.map(async (pid) => {
      const { rows } = await pool.query<{
        topic_id: string;
        value: string;
        full_name: string | null;
      }>(
        `SELECT pa.topic_id, pa.value::text, ep.full_name
         FROM inform.politician_answers pa
         JOIN essentials.politicians ep ON ep.id = pa.politician_id
         WHERE pa.politician_id = $1`,
        [pid]
      );
      return { id: pid, rows };
    })
  );

  // Score each politician against the user's answers (intersection of shared topics)
  return politicianResults.map(({ id, rows }) => {
    const sharedTopics = rows.filter(r => userMap.has(r.topic_id));
    const topics: CompareTopic[] = sharedTopics.map(r => ({
      topic_id: r.topic_id,
      user_value: userMap.get(r.topic_id)!,
      politician_value: parseFloat(r.value),
    }));

    const alignmentScore =
      topics.length === 0
        ? 0
        : Math.round(
            (topics.reduce(
              (sum, t) => sum + (1 - Math.abs(t.user_value - t.politician_value) / 5),
              0
            ) /
              topics.length) *
              100
          );

    return {
      id,
      name: rows[0]?.full_name ?? null,
      alignment_score: alignmentScore,
      topics,
    };
  });
}

/**
 * getUserVerdicts
 *
 * Returns a user's compass verdicts (Read & Rank judgments on politician quotes).
 * When politicianId is provided, results are filtered to quotes by that politician.
 *
 * The politician filter requires a JOIN to essentials.quotes. The FK column on
 * essentials.quotes was verified to be `politician_id` via information_schema
 * discovery (essentials schema created by Go server; not in any ev-accounts migration).
 *
 * All queries use pool.query() — essentials schema is NOT in PostgREST exposed list.
 */
export async function getUserVerdicts(userId: string, politicianId?: string): Promise<Verdict[]> {
  if (!politicianId) {
    const { rows } = await pool.query<Verdict>(
      `SELECT quote_id, supported, rank, session_size, created_at, updated_at
       FROM inform.compass_verdicts
       WHERE user_id = $1
       ORDER BY updated_at DESC`,
      [userId]
    );
    return rows;
  }

  // Filtered by politician: JOIN to essentials.quotes to find politician FK column.
  // Discovery query (run once to confirm column name):
  //   SELECT column_name FROM information_schema.columns
  //   WHERE table_schema='essentials' AND table_name='quotes'
  // Expected FK column: politician_id
  const { rows } = await pool.query<Verdict>(
    `SELECT cv.quote_id, cv.supported, cv.rank, cv.session_size, cv.created_at, cv.updated_at
     FROM inform.compass_verdicts cv
     JOIN essentials.quotes q ON q.id = cv.quote_id
     WHERE cv.user_id = $1 AND q.politician_id = $2
     ORDER BY cv.updated_at DESC`,
    [userId, politicianId]
  );
  return rows;
}

/**
 * getBatchPoliticianAnswers
 *
 * Returns a politician's answers filtered to a specific list of topic IDs.
 * Efficient for fetching only the topics the client cares about (e.g., the user's
 * selected topics) without fetching the full answer set.
 *
 * Uses pool.query() — inform schema writes require direct SQL; keeping reads
 * consistent with the write path.
 */
export async function getBatchPoliticianAnswers(
  politicianId: string,
  topicIds: string[]
): Promise<PoliticianAnswer[]> {
  const { rows } = await pool.query<{ topic_id: string; value: string }>(
    `SELECT topic_id, value::text
     FROM inform.politician_answers
     WHERE politician_id = $1 AND topic_id = ANY($2::uuid[]) AND value <> 0`,
    [politicianId, topicIds]
  );
  return rows.map(r => ({
    topic_id: r.topic_id,
    value: parseFloat(r.value),
  }));
}

// ---------------------------------------------------------------------------
// Citations library — types and service functions
// ---------------------------------------------------------------------------

export interface CitationEntry {
  source_url: string;
  domain: string;
  snippet: string;
  verified_at: string;
  is_primary: boolean;
}

export interface StanceOption {
  value: number;
  text: string;
}

export interface TopicCitationBlock {
  topic_key: string;
  topic_title: string;
  topic_tension_name: string;
  has_stance: boolean;
  stance_value: number | null;
  stance_text: string | null;
  all_stances: StanceOption[];
  reasoning: string | null;
  last_verified_at: string;
  citations: CitationEntry[];
}

interface RawCitationRow {
  topic_key: string;
  topic_title: string;
  topic_tension_name: string;
  stance_value: number | null;
  stance_text: string | null;
  reasoning: string | null;
  source_url: string;
  snippet: string;
  verified_at: string;
  is_primary: boolean;
}

/**
 * Pure grouping helper — exported for unit testing.
 * Takes flat DB rows (one per snippet) and groups them into TopicCitationBlocks.
 */
export function groupCitationRows(rows: RawCitationRow[]): TopicCitationBlock[] {
  const blockMap = new Map<string, TopicCitationBlock>();
  for (const r of rows) {
    if (!blockMap.has(r.topic_key)) {
      blockMap.set(r.topic_key, {
        topic_key: r.topic_key,
        topic_title: r.topic_title,
        topic_tension_name: r.topic_tension_name,
        has_stance: r.stance_value != null,
        stance_value: r.stance_value ?? null,
        stance_text: r.stance_text ?? null,
        all_stances: [],
        reasoning: r.reasoning ?? null,
        last_verified_at: r.verified_at,
        citations: [],
      });
    }
    const block = blockMap.get(r.topic_key)!;
    if (r.verified_at > block.last_verified_at) block.last_verified_at = r.verified_at;
    let domain = r.source_url;
    try { domain = new URL(r.source_url).hostname; } catch { /* keep raw url as fallback */ }
    block.citations.push({
      source_url: r.source_url,
      domain,
      snippet: r.snippet,
      verified_at: r.verified_at,
      is_primary: Boolean(r.is_primary),
    });
  }
  return [...blockMap.values()];
}

/**
 * Returns all verified citation blocks for a politician, grouped by topic.
 * Only includes topics where at least one verified snippet exists.
 * Topics with evidence but no published answer have has_stance = false.
 */
export async function getPoliticianCitations(politicianId: string): Promise<TopicCitationBlock[]> {
  const { rows } = await pool.query<RawCitationRow>(
    `SELECT
       ct.topic_key                                                   AS topic_key,
       COALESCE(ct.question_text, ct.short_title)                    AS topic_title,
       ct.short_title                                                 AS topic_tension_name,
       pa.value                                                       AS stance_value,
       cs.text                                                        AS stance_text,
       pc.reasoning,
       pce.source_url,
       pce.snippet,
       pce.verified_at::text AS verified_at,
       (pce.source_url = ANY(COALESCE(pc.sources, ARRAY[]::text[]))) AS is_primary
     FROM inform.politician_context_evidence pce
     JOIN inform.compass_topics ct
       ON ct.id = pce.topic_id AND ct.is_live = true
     LEFT JOIN inform.politician_answers pa
       ON pa.politician_id = pce.politician_id AND pa.topic_id = pce.topic_id
     LEFT JOIN inform.compass_stances cs
       ON cs.topic_id = pce.topic_id AND cs.value = pa.value
     LEFT JOIN inform.politician_context pc
       ON pc.politician_id = pce.politician_id AND pc.topic_id = pce.topic_id
     WHERE pce.politician_id = $1
     ORDER BY ct.topic_key ASC,
              (pce.source_url = ANY(COALESCE(pc.sources, ARRAY[]::text[]))) DESC,
              pce.verified_at DESC`,
    [politicianId],
  );
  const blocks = groupCitationRows(rows);
  if (blocks.length === 0) return blocks;

  const topicKeys = blocks.map((b) => b.topic_key);
  const { rows: stanceRows } = await pool.query<{ topic_key: string; value: number; text: string }>(
    `SELECT ct.topic_key, cs.value, cs.text
     FROM inform.compass_stances cs
     JOIN inform.compass_topics ct ON ct.id = cs.topic_id
     WHERE ct.topic_key = ANY($1)
     ORDER BY ct.topic_key, cs.value ASC`,
    [topicKeys],
  );
  const stancesByTopic = new Map<string, StanceOption[]>();
  for (const s of stanceRows) {
    if (!stancesByTopic.has(s.topic_key)) stancesByTopic.set(s.topic_key, []);
    stancesByTopic.get(s.topic_key)!.push({ value: Number(s.value), text: s.text });
  }
  for (const block of blocks) {
    block.all_stances = stancesByTopic.get(block.topic_key) ?? [];
  }
  return blocks;
}
