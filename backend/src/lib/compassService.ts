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
 * The promoted set is empty — no season is open, or the open season asks
 * nothing.
 *
 * 🔴 A SERVER STATE PROBLEM WEARING A CALLER'S CLOTHES. Every read of the
 * promoted set turns this into "there are no topics", and every validator
 * built on it turns it into "all of your topic ids are invalid". Both are
 * false and both send the wrong person to debug the wrong thing. It carries a
 * `code` so the routes can answer 503 — the request was fine; the service
 * cannot serve it until a season is opened.
 */
export class NoPromotedTopicsError extends Error {
  readonly code = 'NO_PROMOTED_TOPICS' as const;
  constructor(message: string) {
    super(message);
    this.name = 'NoPromotedTopicsError';
  }
}

export function isNoPromotedTopicsError(e: unknown): e is NoPromotedTopicsError {
  return e instanceof NoPromotedTopicsError;
}

export interface PromotedTopic {
  id: string;
  topic_key: string;
  title: string;
  short_title: string | null;
  question_text: string;
  is_live: boolean;
  version: number;
  // ADR 0006 (Option Y): the revision whose ladder this season serves — the latest
  // published/superseded revision of the pinned version. Stances are fetched by it.
  effective_revision_id: string;
  office_scope: string[] | null;
  fc_community_slug: string | null;
  judicial_role: string | null;
}

/**
 * The promoted set: the topics the OPEN season asks, with the wording of the
 * revision that season pinned.
 *
 * PROMOTION, not content and not answerability (ADR 0004 §12 as corrected).
 * This replaced `compass_topics WHERE is_live = true`, which gave the right 44
 * rows for the wrong reason — `is_live` is a global boolean that cannot notice a
 * season dropping a topic, and cannot ever say *promoted where*.
 *
 * `is_live` and `office_scope` still come from `compass_topics`, because they are
 * not in the view and both are still in this endpoint's response contract.
 * `office_scope` is NULL on all 44 rows and ADR 0005 marks it dead; it is kept
 * here rather than dropped silently, because removing a field is a change to the
 * API's shape and belongs in its own commit.
 *
 * 🔴 IT THROWS ON AN EMPTY RESULT, AND THAT IS THE POINT. The old query could
 * only return zero rows if someone had un-lived all 44 topics by hand. This one
 * returns zero whenever no season is open — a state that really happened, for a
 * day, in August 2026. Returning `[]` would render an empty compass to every
 * voter and report success while doing it. Zero promoted topics is never a
 * legitimate answer; it is a misconfiguration, and it must say so.
 */
export async function getPromotedTopics(): Promise<PromotedTopic[]> {
  const { rows } = await pool.query<PromotedTopic>(
    // pool.query, not supabaseAnon — the §12 views are not in the generated
    // PostgREST types, matching getCompassLenses below.
    //
    // ADR 0006 (Option Y): a season serves the wording of the VERSION it pinned,
    // NOT the global is_current revision. The promoted view exposes the pin as
    // p.season_revision_id; `eff` resolves it to the latest published/superseded
    // revision of that pin's version. So title/short_title/question_text/version
    // and the stance ladder (keyed on effective_revision_id below) all follow the
    // season, not is_current. A minor update (same version, higher revision) is
    // picked up here with no write to the pin; a major (new version) stays
    // invisible until a season pins it. See ADR 0006 §3.
    `SELECT p.id::text AS id, p.topic_key, eff.title, eff.short_title, eff.question_text,
            eff.version, eff.id::text AS effective_revision_id,
            p.fc_community_slug, p.judicial_role,
            t.is_live, t.office_scope
       FROM inform.compass_topics_promoted p
       JOIN inform.compass_topics t ON t.id = p.id
       JOIN LATERAL (
         SELECT e.id, e.title, e.short_title, e.question_text, e.version
           FROM inform.compass_topic_revisions pin
           JOIN inform.compass_topic_revisions e
             ON e.topic_id = pin.topic_id
            AND e.version  = pin.version
            AND e.status IN ('published', 'superseded')
          WHERE pin.id = p.season_revision_id
          ORDER BY e.revision DESC
          LIMIT 1
       ) eff ON true
      -- ⚠ created_at, NOT p.display_order, and this is deliberate. display_order
      -- is the season's own ordering and is the obviously "right" column to reach
      -- for — but CA_0019 seeded it as row_number() OVER (ORDER BY topic_key),
      -- which is not the order voters see today. Measured 2026-08-27: 43 of 44
      -- positions differ. Switching would reorder the entire compass for every
      -- voter as a side effect of a promotion repoint. Adopting display_order is
      -- a product decision and needs its own change.
      --
      -- 🔴 topic_key IS A TIEBREAKER, NOT DECORATION. created_at is not unique:
      -- 44 topics hold only 28 distinct values, and two timestamps cover 10 and 8
      -- topics each (measured 2026-08-27). Ordering by it alone leaves those 18
      -- rows in whatever order the plan happens to emit, so the compass could
      -- present them differently between two requests. That was already true
      -- before this repoint; it is fixed here because an unstable order makes
      -- "did the repoint change anything?" unanswerable.
      ORDER BY p.created_at, p.topic_key`
  );

  if (rows.length === 0) {
    throw new NoPromotedTopicsError(
      'no promoted compass topics — the open season asks nothing, or no season ' +
      "is open. Check inform.seasons for a row with status='open' and its " +
      'inform.season_questions rows. Refusing to report an empty compass as success.');
  }
  return rows;
}

/**
 * getCompassTopics
 * Returns the promoted topics with nested stances, categories, and role scopes.
 */
export async function getCompassTopics() {
  const topics = await getPromotedTopics();

  const topicIds = topics.map(t => t.id);
  // ADR 0006 (Option Y): stances follow the season's bound version, so they are
  // keyed on each topic's effective revision (resolved in getPromotedTopics), not
  // on topic_id / is_current. Categories and roles below stay keyed on topic_id.
  const effIds = topics.map(t => t.effective_revision_id);

  const [stancesRes, catsRes, rolesRes] = await Promise.all([
    // The five rungs of the season-bound revision. `upper(left(text,1)) ||
    // substr(text,2)` renders the lowercase, verb-first corpus text with a capital
    // first letter: a voter-facing presentation rule applied at the read boundary,
    // with no data migration and no stem to break (stance text is standalone).
    pool.query<{ effective_revision_id: string; id: string; value: number; text: string }>(
      `SELECT topic_revision_id::text AS effective_revision_id, id::text AS id, value,
              upper(left(text, 1)) || substr(text, 2) AS text
         FROM inform.compass_stance_revisions
        WHERE topic_revision_id = ANY($1::uuid[])
        ORDER BY value ASC`,
      [effIds],
    ),
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
      stances: stancesRes.rows
        .filter(s => s.effective_revision_id === topic.effective_revision_id)
        .map(({ effective_revision_id: _e, ...s }) => s),
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
    `SELECT l.key, l.name, l.description, l.color, l.icon, l.sort_order,
            COALESCE(l.auto_district_types, ARRAY[]::text[]) AS auto_district_types,
            COALESCE(
              array_agg(lt.topic_id::text ORDER BY lt.sort_order)
                FILTER (WHERE lt.topic_id IS NOT NULL),
              ARRAY[]::text[]
            ) AS topic_ids
     FROM inform.compass_lenses l
     LEFT JOIN inform.compass_lens_topics lt ON lt.lens_id = l.id
     WHERE l.is_active = true
     GROUP BY l.id, l.key, l.name, l.description, l.color, l.icon, l.sort_order, l.auto_district_types
     -- ⚠ sort_order, NOT key. This used to be ORDER BY l.key — alphabetical,
     -- which is not an order anyone chose. It happened to read federal,
     -- judicial, local, and the moment the Education Lens row was added it led
     -- the row, ahead of the three chips users already know. CC_0043 added the
     -- column so the decision lives here, in the one place both Compass and
     -- Essentials already read, instead of being repeated as a constant in each.
     --
     -- 🔴 key IS A TIEBREAKER, NOT DECORATION. sort_order is not unique and
     -- defaults to 100, so every lens added without an explicit value collides.
     -- Ordering on it alone would let two lenses swap places between requests.
     -- Same reasoning as the p.created_at, p.topic_key tiebreak above.
     ORDER BY l.sort_order, l.key`
  );

  return rows.map((r: any) => ({
    key: r.key,
    name: r.name,
    description: r.description,
    color: r.color,
    icon: r.icon,
    // Exposed as well as applied. The array already arrives in order, but a
    // consumer that MERGES this list with another (Compass splices in user
    // lenses and Best Match) has to re-sort, and re-sorting needs the number.
    sortOrder: r.sort_order,
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
  const [promotedTopics, [catRes, topicCatRes, rolesRes]] = await Promise.all([
    getPromotedTopics(),
    Promise.all([
      supabaseAnon
        .schema('inform')
        .from('compass_categories')
        .select('id,title')
        .order('title', { ascending: true }),
      // The topic fields used to be embedded here as
      // `compass_topics!inner(...)` filtered on is_live. Both halves had to go.
      //
      // PROMOTION: the filter is now the open season's question set, resolved by
      // getPromotedTopics() above and applied as a Map lookup below.
      // CONTENT: the embedded columns came from compass_topics, whose text
      // CA_0012 froze — so this endpoint would never have shown a published
      // revision.
      //
      // It also cannot be an embed any more: PostgREST infers embedding from a
      // foreign key, and compass_topics_promoted is a VIEW with no FK to point
      // at. So this query fetches the join rows only, and the topic body comes
      // from the promoted set.
      supabaseAnon
        .schema('inform')
        .from('compass_topic_categories')
        .select('category_id,topic_id'),
      supabaseAnon
        .schema('inform')
        .from('compass_topic_roles')
        .select('topic_id,role_scope'),
    ]),
  ]);

  if (catRes.error) throw catRes.error;
  if (topicCatRes.error) throw topicCatRes.error;
  if (rolesRes.error) throw rolesRes.error;

  // The promoted set, by id. A compass_topic_categories row naming a topic the
  // open season does not ask resolves to undefined here and is dropped — which
  // is how "retired" is expressed now that it is season non-membership rather
  // than an is_live flag.
  const promotedById = new Map(promotedTopics.map(t => [t.id, t]));

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
        // Was an embedded compass_topics row; now a lookup into the promoted set.
        // undefined means this topic is not in the open season — drop it.
        const t = promotedById.get(tc.topic_id);
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
            -- Collapsed to the newest season per topic before counting. A plain
            -- COUNT(*) would double a re-researched politician's answer_count and
            -- array_agg would repeat each topic id once per season.
            (SELECT COUNT(*)::int FROM (
               SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
                 FROM inform.politician_answers a
                 JOIN inform.seasons s ON s.id = a.season_id
                WHERE a.politician_id = p.id
                ORDER BY a.topic_id, s.number DESC
             ) l WHERE l.value != 0) AS answer_count,
            (SELECT array_agg(l.topic_id) FROM (
               SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
                 FROM inform.politician_answers a
                 JOIN inform.seasons s ON s.id = a.season_id
                WHERE a.politician_id = p.id
                ORDER BY a.topic_id, s.number DESC
             ) l WHERE l.value != 0) AS answered_topic_ids
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
          -- compass_responses_current collapses to the newest season the user
          -- answered each topic in (CC_0046). The base table would count an
          -- Empowered candidate who re-answered in a new season twice.
          SELECT COUNT(*)::int FROM inform.compass_responses_current cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          -- Newest season per topic before counting; a plain COUNT(*) doubles a
          -- re-researched candidate's answer_count.
          SELECT COUNT(*)::int FROM (
            SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
              FROM inform.politician_answers a
              JOIN inform.seasons s ON s.id = a.season_id
             WHERE a.politician_id = rc.politician_id
             ORDER BY a.topic_id, s.number DESC
          ) l WHERE l.value != 0
        )
      END AS answer_count,
      CASE
        WHEN EXISTS (
          SELECT 1 FROM empower.empowered_profiles ep WHERE ep.politician_id = rc.politician_id
        ) THEN (
          -- Same collapse; otherwise a topic id repeats once per season answered.
          SELECT array_agg(cr.topic_id) FROM inform.compass_responses_current cr
          JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
          WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
        )
        ELSE (
          -- Same collapse; otherwise each topic id repeats once per season.
          SELECT array_agg(l.topic_id) FROM (
            SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
              FROM inform.politician_answers a
              JOIN inform.seasons s ON s.id = a.season_id
             WHERE a.politician_id = rc.politician_id
             ORDER BY a.topic_id, s.number DESC
          ) l WHERE l.value != 0
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
        -- ⚠ The base table is fine here and the collapse is not needed: EXISTS
        -- asks only whether any row qualifies, and duplicates across seasons
        -- cannot change a boolean. Left as-is so the planner can short-circuit.
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
      // Newest season per topic (CC_0046). deleted_at is filtered by the view's
      // consumer rather than inside the collapse, so a tombstone in a newer
      // season correctly hides the older answer instead of being skipped over.
      `SELECT topic_id, value
       FROM inform.compass_responses_current
       WHERE user_id = $1 AND deleted_at IS NULL AND value != 0
       ORDER BY topic_id ASC`,
      [userId]
    );
    if (answersRes.rows.length > 0) return answersRes.rows;
  }

  // Step 3: fall back to Path B — politician_answers (researched stances)
  const researchedRes = await pool.query<{ topic_id: string; value: number }>(
    // Newest season this person answered each topic in — DISTINCT ON collapses
    // the per-season rows. Without it a re-researched politician returns each
    // topic once per season, and the compass renders duplicate spokes.
    // Filtering value != 0 AFTER the collapse is deliberate: if their newest
    // answer is 0 they have no current position, even if an older season did.
    `SELECT topic_id, value FROM (
       SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
         FROM inform.politician_answers a
         JOIN inform.seasons s ON s.id = a.season_id
        WHERE a.politician_id = $1
        ORDER BY a.topic_id, s.number DESC
     ) latest
     WHERE value != 0
     ORDER BY topic_id ASC`,
    [politicianId]
  );
  if (researchedRes.rows.length > 0) return researchedRes.rows;

  return null;
}

/**
 * getPoliticianAnswers
 * Returns a politician's stances on all topics they have answered — one row per
 * topic, from the newest season they answered it in.
 *
 * 🔴 THIS WAS A POSTGREST BUILDER CALL AND NAMED NO SEASON AT ALL. It filtered
 * `value != 0` and nothing else, so the day a second season exists it returns a
 * row per season per topic. Two failures, both on a public route:
 *
 *   · THE BLANK FAILS TO BLANK. A blanked answer is value 0 in the NEW season.
 *     Filtered at the table, that row disappears and the OLD season's rung
 *     survives — so the politician keeps showing a position, now read against a
 *     ladder on which that rung means something they never said. Collapsing
 *     FIRST and filtering after is what makes a newer blank beat an older answer.
 *   · THE WRONG SEASON CAN WIN. The rows go into `polValues[a.topic_id] = v` in
 *     CombinedPage, so with two rows per topic the last one the planner emits
 *     decides what the voter sees. Not a duplicate spoke — a non-deterministic
 *     one.
 *
 * PostgREST cannot express the fix: there is no `DISTINCT ON`, so the read has
 * to be SQL. pool.query is also what every other politician-answer read in this
 * file already uses (getCandidateAnswers, getBatchPoliticianAnswers,
 * getPoliticianCitations) — this call was the odd one out.
 *
 * Leaving supabaseAnon EXPOSES NOTHING NEW, which is the question a reviewer
 * should ask. Both tables carry an unrestricted `public read` RLS policy granted
 * to anon, so every row was already readable on the anon key, and the three
 * routes are `optionalAuth` — public by design. The move changes which client
 * runs the query, not who may see the answer.
 *
 * `value::text` then parseFloat, not `value::float8`: the builder call emitted
 * JSON numbers and the route serves this array straight to the client, so the
 * wire contract has to survive the move.
 */
export async function getPoliticianAnswers(
  politicianId: string
): Promise<PoliticianAnswer[]> {
  const { rows } = await pool.query<{ topic_id: string; value: string }>(
    `SELECT topic_id, value::text FROM (
       SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
         FROM inform.politician_answers a
         JOIN inform.seasons s ON s.id = a.season_id
        WHERE a.politician_id = $1
        ORDER BY a.topic_id, s.number DESC
     ) latest
     WHERE value <> 0
     ORDER BY topic_id ASC`,
    [politicianId]
  );
  return rows.map(r => ({
    topic_id: r.topic_id,
    value: parseFloat(r.value),
  }));
}

/**
 * getPoliticianContext
 * Returns reasoning and sources for a politician's newest-season stance on a
 * topic, or null if absent.
 *
 * 🔴 THIS ONE DID NOT DEGRADE QUIETLY — IT 500s. It was a builder call ending in
 * `.maybeSingle()`, which THROWS when more than one row comes back, against a
 * table whose primary key is (politician_id, topic_id, season_id). The moment a
 * pair has context in two seasons there are two rows and the call raises; the
 * route catches it and serves INTERNAL_ERROR to `ComparePanel`, the voter-facing
 * "why this position?" panel.
 *
 * Carrying context forward is step 1 of the Season 2 rollout, so this would have
 * fired for every carried pair on the first write, not gradually.
 *
 * The season order is the point of the query, not decoration: reasoning is
 * written against one season's ladder text, so serving the older one under the
 * newer one's stance argues a position the politician was never recorded as
 * holding.
 */
export async function getPoliticianContext(politicianId: string, topicId: string) {
  const { rows } = await pool.query<{ reasoning: string; sources: string[] }>(
    `SELECT c.reasoning, c.sources
       FROM inform.politician_context c
       JOIN inform.seasons s ON s.id = c.season_id
      WHERE c.politician_id = $1 AND c.topic_id = $2
      ORDER BY s.number DESC
      LIMIT 1`,
    [politicianId, topicId]
  );
  // The route turns null into a 404 — the documented contract for "no context on
  // this topic". rows[0] is undefined when empty, so the coalesce is load-bearing.
  return rows[0] ?? null;
}

/**
 * getPoliticianContextAll
 * Returns all context rows for a politician (topic_id → { sources, reasoning }).
 * Used by contributor editors to pre-populate source URL fields.
 */
export async function getPoliticianContextAll(
  politicianId: string
): Promise<{ topic_id: string; reasoning: string; sources: string[] }[]> {
  // Same missing season predicate as getPoliticianContext, without the
  // maybeSingle() that made that one loud: this returned a row per season per
  // topic and the contributor editor pre-filled from whichever arrived first.
  const { rows } = await pool.query<{ topic_id: string; reasoning: string; sources: string[] }>(
    `SELECT DISTINCT ON (c.topic_id) c.topic_id, c.reasoning, c.sources
       FROM inform.politician_context c
       JOIN inform.seasons s ON s.id = c.season_id
      WHERE c.politician_id = $1
      ORDER BY c.topic_id, s.number DESC`,
    [politicianId]
  );
  return rows;
}

/**
 * validateTopicIds
 * Checks that every submitted topic ID is one the voter may actually choose.
 * Returns the array of invalid IDs (empty array = all valid).
 *
 * PROMOTION, not answerability. This gates a VOTER'S SELECTION —
 * `selected_topic_ids` — so the question is "do we ask this?", which is exactly
 * what the promoted set means. It is NOT the politician-answer write gate; that
 * one is `seasonService.writableTopicIds`, and the two must not be merged. They
 * happen to resolve to the same 44 topics today and will diverge the first time
 * a season retires a topic that still holds answers.
 *
 * It used to check `is_live = true`. That was the same defect as
 * compassContributor's old pre-flight: a global boolean standing in for a
 * per-season, eventually per-jurisdiction question, right for the wrong reason
 * while 44/44 topics are live.
 *
 * 🔴 DERIVED FROM getPromotedTopics() RATHER THAN QUERYING SEPARATELY, on
 * purpose. A voter must be allowed to select exactly what getCompassTopics
 * offered them. Two queries answering that from different places is how a UI
 * ends up showing a topic that the save endpoint then rejects. Sharing the
 * resolver makes that impossible rather than merely unlikely, and it inherits
 * the empty-set guard — so "no season is open" surfaces as NO_PROMOTED_TOPICS
 * instead of reporting every id the caller sent as invalid.
 *
 * Reading all promoted rows to check a handful of ids is deliberate and cheap:
 * the set is 44 rows, and correctness here is worth more than a narrower query.
 */
export async function validateTopicIds(topicIds: string[]): Promise<string[]> {
  if (topicIds.length === 0) return [];

  const promoted = await getPromotedTopics();
  const promotedIds = new Set(promoted.map(t => t.id));
  return topicIds.filter(id => !promotedIds.has(id));
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
 * Saves validated topic IDs into inform.inform_profiles.selected_topic_ids.
 *
 * 🔴 inform_profiles, NOT connect.connected_profiles — see migration 1850. The
 * compass used to be stored on the Connected-tier profile, which an Inform-tier
 * user does not have (`Profile absence = Inform tier`, middleware/auth.ts), so
 * their compass was silently discarded on every save. inform_profiles has a row
 * for every user via migration 084's trigger, and sits in the same schema as the
 * answers the selection belongs with.
 *
 * Upserts rather than updates. The trigger guarantees the row, but creating one
 * here is harmless if it is ever missing — unlike connected_profiles, an
 * inform_profiles row is not a tier marker, which is exactly why the storage
 * moved here. account.ts already uses this idiom for location hints.
 *
 * Returns false only if the write somehow affected no row. With the upsert that
 * should not happen; the route still answers 409 on false rather than assuming.
 *
 * Uses pool.query with explicit `WHERE user_id`/`user_id = $1` scoping, NOT
 * createUserClient — this runs as the service role with no RLS, so the scoping is
 * the enforcement.
 */
export async function saveSelectedTopics(
  userId: string,
  topicIds: string[]
): Promise<boolean> {
  const { rows } = await pool.query<{ user_id: string }>(
    `INSERT INTO inform.inform_profiles (user_id, selected_topic_ids)
     VALUES ($1, $2::jsonb)
     ON CONFLICT (user_id) DO UPDATE
       SET selected_topic_ids = EXCLUDED.selected_topic_ids
     RETURNING user_id`,
    [userId, JSON.stringify(topicIds)]
  );
  return rows.length > 0;
}

/**
 * getSelectedTopics
 * The user's chosen compass, from inform.inform_profiles (migration 1850).
 * Returns [] for a user with no row — they have made no selection.
 */
export async function getSelectedTopics(userId: string): Promise<string[]> {
  const { rows } = await pool.query<{ selected_topic_ids: string[] | null }>(
    `SELECT selected_topic_ids FROM inform.inform_profiles WHERE user_id = $1`,
    [userId]
  );
  const value = rows[0]?.selected_topic_ids;
  return Array.isArray(value) ? value : [];
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
    // 🔴 THE COLLAPSE MATTERS MOST HERE. These rows go straight into a Map keyed
    // on topic_id, so two season rows for one topic would silently let whichever
    // the planner returned last decide the user's position in every alignment
    // score. Not a double-count — a wrong answer, non-deterministically.
    `SELECT topic_id, value::text
     FROM inform.compass_responses_current
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
        // One row per topic — their newest season. This feeds the match score,
        // so a duplicated topic would weight it twice.
        `SELECT latest.topic_id, latest.value::text, ep.full_name
         FROM (
           SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value, a.politician_id
             FROM inform.politician_answers a
             JOIN inform.seasons s ON s.id = a.season_id
            WHERE a.politician_id = $1
            ORDER BY a.topic_id, s.number DESC
         ) latest
         JOIN essentials.politicians ep ON ep.id = latest.politician_id`,
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
    // Newest season per topic; see getCandidateAnswers for why the value <> 0
    // filter is applied after the collapse rather than inside it.
    `SELECT topic_id, value::text FROM (
       SELECT DISTINCT ON (a.topic_id) a.topic_id, a.value
         FROM inform.politician_answers a
         JOIN inform.seasons s ON s.id = a.season_id
        WHERE a.politician_id = $1 AND a.topic_id = ANY($2::uuid[])
        ORDER BY a.topic_id, s.number DESC
     ) latest
     WHERE value <> 0`,
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
     -- 🔴 THESE MUST BE LATERALs, AND pc MUST SHARE pa'S SEASON.
     -- This query is voter-facing (essentials Citations.jsx renders the reasoning
     -- under "Why this position?"). As plain bare-pair LEFT JOINs, each evidence
     -- row multiplied out to one row per answer-season TIMES one per
     -- context-season, and the cross terms paired a stance value from one season
     -- with reasoning written against a DIFFERENT season's ladder text. That
     -- displays a position the cited reasoning never argued for — the
     -- confabulation failure mode, produced mechanically by a join.
     LEFT JOIN LATERAL (
       SELECT a.value, a.season_id, a.topic_revision_id
         FROM inform.politician_answers a
         JOIN inform.seasons s ON s.id = a.season_id
        WHERE a.politician_id = pce.politician_id AND a.topic_id = pce.topic_id
        ORDER BY s.number DESC
        LIMIT 1
     ) pa ON true
     -- ADR 0006 (Option Y): the displayed stance is the ladder of the revision the
     -- ANSWER was recorded against — the latest published/superseded revision of the
     -- version pinned when the answer was written (pa.topic_revision_id), not
     -- is_current. A null pa (has_stance = false) yields a null stance_text.
     LEFT JOIN LATERAL (
       SELECT upper(left(sr.text, 1)) || substr(sr.text, 2) AS text
         FROM inform.compass_topic_revisions pin
         JOIN inform.compass_topic_revisions eff
           ON eff.topic_id = pin.topic_id AND eff.version = pin.version
          AND eff.status IN ('published', 'superseded')
         JOIN inform.compass_stance_revisions sr
           ON sr.topic_revision_id = eff.id AND sr.value = pa.value
        WHERE pin.id = pa.topic_revision_id
        ORDER BY eff.revision DESC
        LIMIT 1
     ) cs ON true
     LEFT JOIN LATERAL (
       SELECT c.reasoning, c.sources
         FROM inform.politician_context c
         JOIN inform.seasons s ON s.id = c.season_id
        WHERE c.politician_id = pce.politician_id AND c.topic_id = pce.topic_id
          -- Same season as the value when there is one. When there is no answer
          -- at all (the has_stance = false case) fall back to the newest
          -- context, which is what this query showed before seasons existed.
          AND (pa.season_id IS NULL OR c.season_id = pa.season_id)
        ORDER BY s.number DESC
        LIMIT 1
     ) pc ON true
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
    // ADR 0006 (Option Y): the full ladder shown under a citation must match the
    // version the answer was recorded against, so the highlighted stance_value
    // indexes the same rungs as stance_text above. Resolve, per topic, the version
    // of this politician's latest-season answer; with no answer, fall back to the
    // topic's current revision (the pre-seasons behavior).
    `SELECT ct.topic_key, sr.value,
            upper(left(sr.text, 1)) || substr(sr.text, 2) AS text
     FROM inform.compass_topics ct
     JOIN LATERAL (
       SELECT eff.id
         FROM inform.compass_topic_revisions eff
        WHERE eff.topic_id = ct.id
          AND eff.status IN ('published', 'superseded')
          AND eff.version = COALESCE(
            (SELECT pin.version
               FROM inform.politician_answers a
               JOIN inform.seasons s ON s.id = a.season_id
               JOIN inform.compass_topic_revisions pin ON pin.id = a.topic_revision_id
              WHERE a.politician_id = $2 AND a.topic_id = ct.id
              ORDER BY s.number DESC LIMIT 1),
            (SELECT cur.version FROM inform.compass_topic_revisions cur
              WHERE cur.topic_id = ct.id AND cur.is_current))
        ORDER BY eff.revision DESC LIMIT 1
     ) eff ON true
     JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id
     WHERE ct.topic_key = ANY($1)
     ORDER BY ct.topic_key, sr.value ASC`,
    [topicKeys, politicianId],
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
