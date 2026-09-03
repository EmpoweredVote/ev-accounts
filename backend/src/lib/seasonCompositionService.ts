import { pool } from './db.js';
import { adminRpc } from './supabase.js';

/**
 * Season composition — the surface behind the admin compose/presentation
 * screen (ADR 0005's deferred "how a season is authored", national set only).
 *
 * Reads return FACTS ONLY. carried/changed/dropped/added is a presentation
 * judgement, derived once in the admin UI so the compose grid and the board
 * view cannot disagree. This module answers: which seasons exist, what does
 * each pin say, what is current, and how did politicians answer in the open
 * season.
 *
 * Reads use pool.query directly: seasons, season_questions and the revision
 * tables are not in the generated PostgREST types (matches getCompassLenses).
 * Writes go through the CA_0022 SECURITY DEFINER RPCs via adminRpc — never
 * through pool, which works on a superuser connection and 500s as ev_api.
 */

export interface SeasonRow {
  id: string;
  number: number;
  name: string;
  status: 'draft' | 'open' | 'closed';
  opened_at: string | null;
  closed_at: string | null;
  public_note: string;
  question_count: number;
}

export interface RevisionContent {
  revision_id: string;
  revision: number;
  title: string;
  short_title: string;
  question_text: string;
  ladder: { value: number; text: string }[];
}

export interface CompositionTopic {
  topic_id: string;
  topic_key: string;
  current: RevisionContent | null;
  in_open: { question_number: number; display_order: number; pin: RevisionContent } | null;
  in_draft: { question_number: number; display_order: number; pin: RevisionContent } | null;
  distribution: Record<number, number>;
  answer_total: number;
}

export interface CompositionPayload {
  open_season: SeasonRow | null;
  draft_season: SeasonRow | null;
  topics: CompositionTopic[];
}

const SEASONS_SQL = `
  SELECT s.id, s.number, s.name, s.status, s.opened_at, s.closed_at, s.public_note,
         (SELECT count(*) FROM inform.season_questions sq WHERE sq.season_id = s.id) AS question_count
    FROM inform.seasons s
   ORDER BY s.number`;

export async function listSeasons(): Promise<SeasonRow[]> {
  const { rows } = await pool.query(SEASONS_SQL);
  return rows.map((r: Record<string, unknown>) => ({
    ...(r as unknown as SeasonRow),
    question_count: Number(r.question_count ?? 0),
  }));
}

/**
 * One row per topic that has a current published revision OR sits in the open
 * or draft season. LEFT JOINs against a NULL season id never match, so "no
 * draft yet" needs no special casing.
 */
const TOPIC_MATRIX_SQL = `
  SELECT t.id AS topic_id, t.topic_key,
         cur.id  AS current_revision_id, cur.revision AS current_revision,
         cur.title AS current_title, cur.short_title AS current_short_title,
         cur.question_text AS current_question,
         osq.question_number AS open_qn, osq.display_order AS open_do,
         opr.id AS open_pin_id, opr.revision AS open_pin_revision,
         opr.title AS open_pin_title, opr.short_title AS open_pin_short_title,
         opr.question_text AS open_pin_question,
         dsq.question_number AS draft_qn, dsq.display_order AS draft_do,
         dpr.id AS draft_pin_id, dpr.revision AS draft_pin_revision,
         dpr.title AS draft_pin_title, dpr.short_title AS draft_pin_short_title,
         dpr.question_text AS draft_pin_question
    FROM inform.compass_topics t
    LEFT JOIN inform.compass_topic_revisions cur
      ON cur.topic_id = t.id AND cur.is_current AND cur.status = 'published'
    LEFT JOIN inform.season_questions osq
      ON osq.season_id = $1::uuid AND osq.topic_id = t.id
    LEFT JOIN inform.compass_topic_revisions opr ON opr.id = osq.topic_revision_id
    LEFT JOIN inform.season_questions dsq
      ON dsq.season_id = $2::uuid AND dsq.topic_id = t.id
    LEFT JOIN inform.compass_topic_revisions dpr ON dpr.id = dsq.topic_revision_id
   WHERE cur.id IS NOT NULL OR osq.topic_id IS NOT NULL OR dsq.topic_id IS NOT NULL
   ORDER BY COALESCE(osq.display_order, dsq.display_order, 2147483647), t.topic_key`;

const LADDERS_SQL = `
  SELECT sr.topic_revision_id, sr.value::int AS value, sr.text
    FROM inform.compass_stance_revisions sr
   WHERE sr.topic_revision_id = ANY($1::uuid[])
   ORDER BY sr.value`;

/**
 * Answer distribution: each politician's NEWEST answer per topic, resolved by
 * season number — the set form of seasonService.newestAnswerLateral. Reads
 * follow the person, not the calendar (ADR 0005 §1.4): the first composition
 * load after a changeover must show the answers politicians actually hold,
 * not the empty set of a season nobody has been researched in yet. The
 * DISTINCT ON names the season for each row, so a second season cannot fan
 * this out (ADR 0005 §1.2).
 */
// 🔴 A BLANKED ANSWER IS NOT A RUNG. value 0 means the politician was researched
// and the ladder moved out from under them, leaving no rung that states what
// they hold. `distribution` is keyed on the value and LADDERS_SQL has no rung 0,
// so an unfiltered blank arrives at the compose grid as a bucket the UI cannot
// label — on the one screen an editor uses to judge whether a ladder change is
// safe to publish. It would also inflate `answer_total`.
//
// The guard is OUTSIDE the collapse: a blank in the newest season suppresses the
// answer, it does not fall through to the previous season's rung.
//
// ⚠ How many were blanked is a number an editor genuinely wants, and it is NOT
// in this payload. Surfacing it needs a field here, in the admin's mirrored type
// and in the grid itself, so it is left for the change that also renders it —
// shipping a field nothing displays would not answer the question.
// 🔴 @draft-scope: INCLUDES-DRAFT — the one deliberate exception to
//   seasonService.SEASON_IS_PUBLISHED, which every other season collapse in
//   backend/src now carries. This is the ADMIN COMPOSE SCREEN, and its entire
//   job is to show an editor what the DRAFT season would look like before they
//   publish it. Hiding draft rows here would blank the one view that exists to
//   inspect them — an editor would re-point 2,685 answers and see no change.
//   Every OTHER consumer must not see them, because the ladder text they are
//   rendered beside follows the OPEN season and would disagree.
const DISTRIBUTION_SQL = `
  SELECT x.topic_id, x.value::int AS value, count(*)::int AS n
    FROM (
      SELECT DISTINCT ON (a.politician_id, a.topic_id) a.topic_id, a.value
        FROM inform.politician_answers a
        JOIN inform.seasons s ON s.id = a.season_id
       ORDER BY a.politician_id, a.topic_id, s.number DESC
    ) x
   WHERE x.value <> 0
   GROUP BY x.topic_id, x.value`;

export async function getComposition(): Promise<CompositionPayload> {
  const seasons = await listSeasons();
  const open = seasons.find((s) => s.status === 'open') ?? null;
  const draft = seasons.find((s) => s.status === 'draft') ?? null;

  // Independent reads; the distribution aggregate is the heavy one, so let it
  // overlap the matrix instead of queueing behind it.
  const [{ rows: matrix }, { rows: distRows }] = await Promise.all([
    pool.query(TOPIC_MATRIX_SQL, [open?.id ?? null, draft?.id ?? null]),
    pool.query(DISTRIBUTION_SQL),
  ]);

  const revisionIds = new Set<string>();
  for (const r of matrix) {
    for (const id of [r.current_revision_id, r.open_pin_id, r.draft_pin_id]) {
      if (id) revisionIds.add(id as string);
    }
  }
  const { rows: ladderRows } = await pool.query(LADDERS_SQL, [[...revisionIds]]);
  const ladders = new Map<string, { value: number; text: string }[]>();
  for (const row of ladderRows) {
    const list = ladders.get(row.topic_revision_id) ?? [];
    list.push({ value: row.value, text: row.text });
    ladders.set(row.topic_revision_id, list);
  }

  const dist = new Map<string, Record<number, number>>();
  for (const row of distRows) {
    const d = dist.get(row.topic_id) ?? {};
    d[row.value] = row.n;
    dist.set(row.topic_id, d);
  }

  const content = (
    id: string | null,
    revision: number | null,
    title: string | null,
    shortTitle: string | null,
    question: string | null,
  ): RevisionContent | null =>
    id == null
      ? null
      : {
          revision_id: id,
          revision: revision ?? 0,
          title: title ?? '',
          short_title: shortTitle ?? '',
          question_text: question ?? '',
          ladder: ladders.get(id) ?? [],
        };

  const topics: CompositionTopic[] = matrix.map((r) => {
    const d = dist.get(r.topic_id) ?? {};
    const openPin = content(r.open_pin_id, r.open_pin_revision, r.open_pin_title,
      r.open_pin_short_title, r.open_pin_question);
    const draftPin = content(r.draft_pin_id, r.draft_pin_revision, r.draft_pin_title,
      r.draft_pin_short_title, r.draft_pin_question);
    return {
      topic_id: r.topic_id,
      topic_key: r.topic_key,
      current: content(r.current_revision_id, r.current_revision, r.current_title,
        r.current_short_title, r.current_question),
      in_open: openPin == null
        ? null
        : { question_number: r.open_qn, display_order: r.open_do, pin: openPin },
      in_draft: draftPin == null
        ? null
        : { question_number: r.draft_qn, display_order: r.draft_do, pin: draftPin },
      distribution: d,
      answer_total: Object.values(d).reduce((a, b) => a + b, 0),
    };
  });

  return { open_season: open, draft_season: draft, topics };
}

/** Rethrow contract: the RPC's own 'NAMED_CODE: sentence' message, unchanged. */
async function seasonRpc<T>(fn: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await adminRpc(fn, args, 'inform');
  if (error) throw new Error(error.message);
  return data as T;
}

export async function createDraftSeason(
  actorId: string,
  name: string,
  publicNote: string,
  carryFromOpen: boolean,
): Promise<{ season_id: string; number: number; question_count: number }> {
  return seasonRpc('admin_create_draft_season', {
    p_actor_id: actorId,
    p_name: name,
    p_public_note: publicNote,
    p_carry_from_open: carryFromOpen,
  });
}

export async function updateDraftSeason(
  seasonId: string,
  actorId: string,
  name: string | null,
  publicNote: string | null,
): Promise<{ season_id: string }> {
  return seasonRpc('admin_update_draft_season', {
    p_season_id: seasonId,
    p_actor_id: actorId,
    p_name: name,
    p_public_note: publicNote,
  });
}

export async function deleteDraftSeason(
  seasonId: string,
  actorId: string,
): Promise<{ deleted_season_id: string; question_count: number }> {
  return seasonRpc('admin_delete_draft_season', {
    p_season_id: seasonId,
    p_actor_id: actorId,
  });
}

export async function addTopicToSeason(
  seasonId: string,
  topicId: string,
  actorId: string,
): Promise<{ topic_id: string; topic_revision_id: string; question_number: number }> {
  return seasonRpc('admin_season_add_topic', {
    p_season_id: seasonId,
    p_topic_id: topicId,
    p_actor_id: actorId,
  });
}

export async function removeTopicFromSeason(
  seasonId: string,
  topicId: string,
  actorId: string,
): Promise<{ removed_topic_id: string }> {
  return seasonRpc('admin_season_remove_topic', {
    p_season_id: seasonId,
    p_topic_id: topicId,
    p_actor_id: actorId,
  });
}

export async function repinTopic(
  seasonId: string,
  topicId: string,
  actorId: string,
): Promise<{ repinned: boolean; from_revision_id: string; to_revision_id: string }> {
  return seasonRpc('admin_season_repin_topic', {
    p_season_id: seasonId,
    p_topic_id: topicId,
    p_actor_id: actorId,
  });
}

export async function openSeason(
  seasonId: string,
  actorId: string,
): Promise<{ opened_season_id: string; closed_season_id: string | null; question_count: number }> {
  return seasonRpc('admin_open_season', {
    p_season_id: seasonId,
    p_actor_id: actorId,
  });
}
