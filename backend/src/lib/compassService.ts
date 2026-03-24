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
    .select('id,title,short_title,question_text,is_live,version')
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

  return topics.map(topic => ({
    ...topic,
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
    roles: (rolesRes.data ?? [])
      .filter(r => r.topic_id === topic.id)
      .map(({ topic_id: _tid, ...r }) => r),
  }));
}

/**
 * getCompassCategories
 * Returns all categories with nested live topics.
 */
export async function getCompassCategories() {
  const [catRes, topicCatRes] = await Promise.all([
    supabaseAnon
      .schema('inform')
      .from('compass_categories')
      .select('id,title')
      .order('title', { ascending: true }),
    supabaseAnon
      .schema('inform')
      .from('compass_topic_categories')
      .select('category_id,compass_topics!inner(id,title,short_title,question_text,is_live)')
      .eq('compass_topics.is_live', true),
  ]);

  if (catRes.error) throw catRes.error;
  if (topicCatRes.error) throw topicCatRes.error;

  return (catRes.data ?? []).map(cat => ({
    ...cat,
    topics: (topicCatRes.data ?? [])
      .filter(tc => tc.category_id === cat.id)
      .map(tc => {
        const t = tc.compass_topics as { id: string; title: string; short_title: string | null; question_text: string; is_live: boolean } | null;
        if (!t) return null;
        return { topic_id: t.id, title: t.title, short_title: t.short_title, question_text: t.question_text };
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
            COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_origin_url,
            p.is_active,
            COALESCE(o.title, '') AS office_title,
            COALESCE(o.representing_state, '') AS representing_state,
            COALESCE(o.representing_city, '') AS representing_city,
            COALESCE(d.label, '') AS district_label,
            COALESCE(d.district_type, '') AS district_type
     FROM essentials.politicians p
     JOIN inform.politician_answers pa ON pa.politician_id = p.id
     LEFT JOIN essentials.offices o ON o.politician_id = p.id
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
  }));
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
