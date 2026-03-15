import { adminRpc, supabaseAnon, createUserClient } from './supabase.js';

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
 */
export async function getCompassPoliticians() {
  const { data, error } = await supabaseAnon
    .schema('inform')
    .from('politicians')
    .select('id,first_name,last_name,preferred_name,full_name,office_title,photo_origin_url,is_active')
    .eq('is_active', true)
    .order('last_name', { ascending: true })
    .order('first_name', { ascending: true });

  if (error) throw error;
  return data ?? [];
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
  const db = createUserClient(accessToken);
  const { data: updatedRows, error } = await db
    .schema('connect')
    .from('connected_profiles')
    .update({
      selected_topic_ids: JSON.stringify(topicIds),
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
    .select('id');

  if (error) throw error;
  return !!(updatedRows && updatedRows.length > 0);
}
