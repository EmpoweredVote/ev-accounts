import { pool } from './db.js';

/**
 * Season resolution. Two questions, and they have different answers — mixing
 * them up is the bug this module exists to prevent.
 *
 *   WHERE DO I WRITE?  `currentSeasonId()` — the one OPEN season.
 *   WHAT DID THEY SAY? `latestAnsweredSeason()` — the newest season in which
 *                      this person actually answered this topic.
 *
 * A read must not use the open season. A person may not have been researched
 * this season, and asking "what is their stance in season 3" of someone last
 * researched in season 1 returns nothing — blanking a compass that has real
 * content. Reads follow the person; writes follow the calendar.
 */

/**
 * The id of the open season. Resolved at read time, never cached in a column
 * and never memoised in this process — no trigger fires because the calendar
 * advanced (CLAUDE.md).
 *
 * Throws rather than falling back to the highest-numbered season. A closed
 * season is not a place to write answers, and silently choosing one would
 * reintroduce exactly the ambiguity seasons exist to remove.
 *
 * ⚠ OPERATIONAL NOTE, true as of 2026-08-25: season 1 is CLOSED and no season
 * is open, so this throws in production right now. That is not a defect in this
 * function — it is the honest state of the data. Every write path that calls it
 * is blocked until someone opens a season, which is a deliberate editorial act
 * (a season pins a question set to specific ladder revisions) and has no
 * migration in the compass-seasons plan. The error names the fix.
 */
export async function currentSeasonId(): Promise<string> {
  const { rows } = await pool.query<{ id: string }>(
    `SELECT id FROM inform.seasons WHERE status = 'open'`);
  if (rows.length > 1) {
    // Unreachable while the seasons_one_open partial unique index exists.
    // Loud on purpose: an arbitrary pick would be worse than a failure.
    throw new Error(
      `more than one open season (${rows.length}) — inform.seasons.seasons_one_open ` +
      `should make this impossible; check whether that index was dropped`);
  }
  if (rows.length === 0) {
    throw new Error(
      'no open season — nothing can be written until one is opened. ' +
      "Set a row in inform.seasons to status='open' with an opened_at, and give " +
      'it a season_questions row per topic pinning the ladder revision it asks.');
  }
  return rows[0].id;
}

export interface AnsweredSeason {
  seasonId: string;
  number: number;
}

/**
 * A DRAFT SEASON'S ROWS ARE NOT PUBLISHED DATA.
 *
 * 🔴 WHY THIS EXISTS, AND IT IS NOT THEORETICAL. Every season-aware read
 * collapses to the newest season by `s.number DESC`. Nothing in that ordering
 * asks whether the season is open — so the moment a draft season holds a row it
 * wins the collapse and reaches the public API.
 *
 * That would be survivable if the rest of the product followed it. It does not.
 * The ladder TEXT comes from `inform.compass_topics_promoted`, which follows the
 * OPEN season's pin. So the value jumps to the draft season while the words stay
 * on the open one: a politician stored on Housing rung 2 renders as rung 3
 * against Season 1's wording. Measured on prod 2026-09-03 against a rolled-back
 * copy of the Season 2 re-pointing — 2,685 answers would have changed what they
 * display while the ladder beside them did not move, and the 757 shown on
 * Housing rung 2 would have dropped to 0 on the public distribution.
 *
 * It breaks citations the same way. `getPoliticianCitations` resolves stance text
 * through the answer's pinned revision, and a draft season pins a revision that
 * is still `approved`; the LATERAL requires `published` or `superseded`, finds
 * nothing, and the block renders a stance with no text.
 *
 * WHY `<> 'draft'` AND NOT `= 'open'`. A CLOSED season must still show through —
 * that is ADR 0005 §1.4's "reads follow the person, not the calendar": after a
 * changeover, someone answered only in Season 1 must still display that answer
 * rather than vanish. Draft is the one status that was never published.
 *
 * ⚠ THIS IS THE READ GATE. `s.status = 'open'` is the WRITE gate (see
 * UPSERT_ANSWER_SQL) and they answer different questions: a write must land in
 * the season being researched; a read must not show a season nobody published.
 *
 * ⚠ ONE DELIBERATE EXCEPTION, in seasonCompositionService — the admin compose
 * screen exists to show what the draft season would look like. It says so.
 *
 * ⚠ NOT FIXED HERE, AND KNOWN: `inform.compass_responses_current` is the same
 * shape — DISTINCT ON (user_id, topic_id) ORDER BY s.number DESC, no status
 * filter. It cannot bite today, because nothing can put a USER answer in a draft
 * season: `compass_responses_assign_season` fills season_id from the OPEN season
 * and all four write RPCs go through it. Fixing it means a migration to redefine
 * the view, which does not belong in a code-only change. Do it if the user side
 * ever gains a path that writes into a draft season.
 */
export const SEASON_IS_PUBLISHED = `s.status <> 'draft'`;

/**
 * The newest season in which this person answered this topic, or null if they
 * never have.
 *
 * Null is an absence, not an error: not everyone is researched every season.
 *
 * ⚠ In SQL, prefer the `LATERAL … ORDER BY s.number DESC LIMIT 1` form inline
 * (see `newestAnswerLateral`) over calling this per row. This function is for
 * the one-politician-one-topic case; in a list query it would be an N+1.
 */
export async function latestAnsweredSeason(
  politicianId: string,
  topicId: string,
): Promise<AnsweredSeason | null> {
  const { rows } = await pool.query<{ season_id: string; number: number }>(
    `SELECT a.season_id, s.number
       FROM inform.politician_answers a
       JOIN inform.seasons s ON s.id = a.season_id AND ${SEASON_IS_PUBLISHED}
      WHERE a.politician_id = $1 AND a.topic_id = $2
      ORDER BY s.number DESC
      LIMIT 1`,
    [politicianId, topicId],
  );
  if (rows.length === 0) return null;
  return { seasonId: rows[0].season_id, number: rows[0].number };
}

/**
 * THE WRITE SHAPE, defined once.
 *
 * Every season-aware write needs three things the caller does not have: the open
 * season, the ladder revision that season pins for this topic, and a matching
 * `ON CONFLICT` target. Resolving those at each of the six call sites invites
 * six slightly different answers, so they are defined here and imported.
 *
 * It is ONE statement on purpose. Reading the open season and then inserting
 * would leave a window in which the season closes between the two, writing an
 * answer into a season that is no longer open. Sourcing the INSERT from
 * `season_questions JOIN seasons ... status='open'` closes that window: if no
 * season is open the SELECT yields no rows and NOTHING is written.
 *
 * 🔴 Which means a caller MUST check that a row came back. Zero rows is not
 * success, it is "no open season" or "this topic is not in the season's question
 * set" — use `assertWritten`, which distinguishes them.
 *
 * `topic_revision_id` comes from the season's pin, never from the caller and
 * never from "whatever is current". That is the entire point of the pin: the
 * answer records which ladder text it was an answer to.
 *
 * Param order: $1 politician_id, $2 topic_id, $3 value, $4 editor_id.
 */
export const UPSERT_ANSWER_SQL = `
  INSERT INTO inform.politician_answers
    (politician_id, topic_id, season_id, topic_revision_id, value, editor_id, updated_at)
  SELECT $1::uuid, $2::uuid, sq.season_id, sq.topic_revision_id, $3::numeric, $4::uuid, now()
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = $2::uuid
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET value = EXCLUDED.value, editor_id = EXCLUDED.editor_id, updated_at = now()`;

/** Param order: $1 politician_id, $2 topic_id, $3 reasoning, $4 sources, $5 editor_id. */
export const UPSERT_CONTEXT_SQL = `
  INSERT INTO inform.politician_context
    (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
  SELECT $1::uuid, $2::uuid, sq.season_id, sq.topic_revision_id, $3::text, $4::text[], $5::uuid, now()
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = $2::uuid
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources,
        editor_id = EXCLUDED.editor_id, updated_at = now()`;

/**
 * As UPSERT_ANSWER_SQL, plus `write_in_text`.
 *
 * A SEPARATE constant on purpose, rather than a fifth parameter on the other
 * one. Its DO UPDATE overwrites `write_in_text`, and the contributor surface is
 * the only caller that owns that column — folding it in would make a staging
 * approval or a research resolution blank an existing write-in as a side effect
 * of setting a value. Prod holds 0 write-ins today, so that would have been an
 * invisible change waiting for the first one.
 *
 * Param order: $1 politician_id, $2 topic_id, $3 value, $4 editor_id, $5 write_in_text.
 */
export const UPSERT_ANSWER_WITH_WRITE_IN_SQL = `
  INSERT INTO inform.politician_answers
    (politician_id, topic_id, season_id, topic_revision_id, value, editor_id, write_in_text, updated_at)
  SELECT $1::uuid, $2::uuid, sq.season_id, sq.topic_revision_id, $3::numeric, $4::uuid, $5::text, now()
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = $2::uuid
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET value = EXCLUDED.value, write_in_text = EXCLUDED.write_in_text,
        editor_id = EXCLUDED.editor_id, updated_at = now()`;

/**
 * Sources only — it does NOT touch `reasoning`.
 *
 * The contributor source form supplies a URL and no prose. Reusing
 * UPSERT_CONTEXT_SQL would set reasoning to '' and erase an editor's existing
 * argument, and `reasoning` is voter-facing (essentials Citations.jsx).
 *
 * Param order: $1 politician_id, $2 topic_id, $3 sources, $4 editor_id.
 */
export const UPSERT_CONTEXT_SOURCES_SQL = `
  INSERT INTO inform.politician_context
    (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
  SELECT $1::uuid, $2::uuid, sq.season_id, sq.topic_revision_id, '', $3::text[], $4::uuid, now()
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = $2::uuid
  ON CONFLICT (politician_id, topic_id, season_id) DO UPDATE
    SET sources = EXCLUDED.sources, editor_id = EXCLUDED.editor_id, updated_at = now()`;

/**
 * THE PRE-FLIGHT FORM OF THE WRITE GATE.
 *
 * 🔴 IT IS DEFINED HERE, BESIDE `UPSERT_ANSWER_SQL`, ON PURPOSE. A validator
 * that answers "may I write this?" differently from the statement that does the
 * writing is worse than no validator at all: it either rejects writes that would
 * have succeeded, or waves through writes that then fail deeper down, past the
 * point where the caller can be told anything useful. Its `FROM` clause is the
 * same `season_questions JOIN seasons … status = 'open'` the upsert sources its
 * INSERT from. Change one and you must change the other.
 *
 * ⚠ NOT `compass_topics_promoted`, and the difference is small but real. That
 * view additionally inner-joins `compass_topics_current`, so a topic in the open
 * season that somehow lacked a current revision would be missing from the view
 * while remaining perfectly writable — a validator rejecting a write the
 * database would have accepted. The view answers "what do we ASK"; this answers
 * "what may be RECORDED". ADR 0004 §12, as corrected, is about exactly this.
 *
 * Param order: $1 topic_ids (uuid[]).
 */
export const WRITABLE_TOPIC_IDS_SQL = `
  SELECT sq.topic_id::text AS id
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
   WHERE sq.topic_id = ANY($1::uuid[])`;

/** Anything that can run a parameterised query — `pool`, or a transaction client. */
export interface Queryable {
  query<R extends import('pg').QueryResultRow = never>(
    sql: string, params?: unknown[]): Promise<{ rows: R[]; rowCount: number | null }>;
}

/**
 * Which of these topics may currently hold an answer.
 *
 * 🔴 Throws `SeasonWriteError` when NO season is open, rather than reporting
 * every topic as invalid. Those are different failures and they read completely
 * differently to whoever hit them: "these 3 topic ids are not in this season"
 * is a caller problem, while "all 44 of your topic ids are invalid" is what a
 * server misconfiguration looks like when a validator refuses to admit it is the
 * one at fault. The second is what this code did before.
 *
 * Pass the transaction client when inside one, so the check sees the same
 * snapshot as the write that follows it.
 */
export async function writableTopicIds(
  runner: Queryable, topicIds: string[],
): Promise<Set<string>> {
  if (topicIds.length === 0) return new Set();

  const { rows } = await runner.query<{ id: string }>(WRITABLE_TOPIC_IDS_SQL, [topicIds]);
  if (rows.length > 0) return new Set(rows.map(r => r.id));

  // Nothing came back. Distinguish "no season is open" from "none of these
  // topics is in the open season's set" before blaming the caller.
  const { rows: state } = await runner.query<{ open_seasons: string }>(
    `SELECT count(*)::text AS open_seasons FROM inform.seasons WHERE status = 'open'`);
  if (Number(state[0]?.open_seasons ?? 0) === 0) {
    throw new SeasonWriteError('NO_OPEN_SEASON', topicIds[0] ?? '',
      'no open season — no stance can be recorded until one is opened. ' +
      "Set a row in inform.seasons to status='open' with an opened_at, and give " +
      'it a season_questions row per topic pinning the ladder revision it asks.');
  }
  return new Set();
}

/**
 * Read the row a write is about to replace, in the OPEN season.
 *
 * 🔴 NOT the newest answered season. This feeds audit diffs, and the write lands
 * in the open season — so "previous value" must mean that season's value, or
 * nothing if this is the first answer of the season. Diffing against season 1
 * while writing season 2 reports "changed 3 → 3" for what is actually a new row.
 *
 * Param order: $1 politician_id, $2 topic_id(s).
 *
 * 🔴 CALLERS APPEND TO THIS STRING (`${OPEN_SEASON_ANSWER_SQL} AND a.topic_id =
 * ANY($2)`), so nothing may be added after the WHERE clause — a trailing `--`
 * comment would swallow the caller's predicate. The zero note below sits at the
 * top of the literal for that reason.
 */
export const OPEN_SEASON_ANSWER_SQL = `
  -- @zero-scope: counts-blanks — a 0 MUST come back, and this is the one site
  --   where filtering it would be actively destructive. These rows are the
  --   "previous value" for the audit diff, so a blank is precisely the state the
  --   next write needs to see. Hide it and re-seating a blanked politician logs
  --   as a first-time answer, erasing the fact that an editor had blanked the
  --   row — the audit trail would show the position appearing from nowhere.
  SELECT a.topic_id, a.value, a.write_in_text
    FROM inform.politician_answers a
    JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
   WHERE a.politician_id = $1`;

/**
 * Clear an answer in the OPEN season only.
 *
 * Unconstrained, this DELETE removes the person's answer to that topic in EVERY
 * season — destroying a closed season's record, which is the one thing seasons
 * exist to make impossible.
 *
 * ⚠ It leaves any `politician_context` row for the pair in place. That is
 * pre-existing behaviour, not introduced here, and it is how gate-visible
 * ORPHAN_CONTEXT rows appear at runtime rather than via a migration. CLAUDE.md
 * requires a migration deleting answers to decide the context's fate; this code
 * path never did. Worth fixing, but not silently and not as a side effect of
 * making it season-aware — see the plan's open questions.
 *
 * Param order: $1 politician_id, $2 topic_id.
 */
export const DELETE_ANSWER_OPEN_SEASON_SQL = `
  DELETE FROM inform.politician_answers a
   USING inform.seasons s
   WHERE s.id = a.season_id AND s.status = 'open'
     AND a.politician_id = $1 AND a.topic_id = $2`;

/**
 * Why a season-aware write wrote nothing.
 *
 *   NO_OPEN_SEASON — no season is open, so nothing may be written at all.
 *   TOPIC_NOT_IN_SEASON — a season is open but does not ask this topic, so there
 *                         is no pinned revision to record the answer against.
 */
export type SeasonWriteReason = 'NO_OPEN_SEASON' | 'TOPIC_NOT_IN_SEASON';

/**
 * A write refused by the season gate.
 *
 * 🔴 THIS IS NOT AN INTERNAL ERROR AND MUST NOT BE SERVED AS ONE. It means the
 * editorial calendar is not ready for this write — a state an operator can fix
 * (open a season, or add the topic to the open season's question set), and one
 * they cannot fix if the API answers "an unexpected error occurred" and puts the
 * only useful sentence in a server log they cannot read.
 *
 * Route handlers should map it to 409 and pass `message` through. It carries no
 * user data — just the season state and the topic id — so it is safe to return.
 */
export class SeasonWriteError extends Error {
  readonly reason: SeasonWriteReason;
  readonly topicId: string;
  constructor(reason: SeasonWriteReason, topicId: string, message: string) {
    super(message);
    this.name = 'SeasonWriteError';
    this.reason = reason;
    this.topicId = topicId;
  }
}

/** Narrowing helper, so routes do not have to `instanceof` an imported class. */
export function isSeasonWriteError(e: unknown): e is SeasonWriteError {
  return e instanceof SeasonWriteError;
}

/**
 * Turn "no rows written" into an error that says which of the two causes it was.
 *
 * Both are silent no-ops without this, and they need different fixes: open a
 * season, versus add the topic to the open season's question set.
 */
export async function assertWritten(rowCount: number, topicId: string): Promise<void> {
  if (rowCount > 0) return;
  const { rows } = await pool.query<{ open_seasons: string; pinned: string }>(
    `SELECT (SELECT count(*) FROM inform.seasons WHERE status = 'open')      AS open_seasons,
            (SELECT count(*) FROM inform.season_questions sq
               JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
              WHERE sq.topic_id = $1)                                        AS pinned`,
    [topicId],
  );
  const openSeasons = Number(rows[0]?.open_seasons ?? 0);
  if (openSeasons === 0) {
    throw new SeasonWriteError('NO_OPEN_SEASON', topicId,
      'no open season — nothing can be written until one is opened. ' +
      "Set a row in inform.seasons to status='open' with an opened_at, and give " +
      'it a season_questions row per topic pinning the ladder revision it asks.');
  }
  if (Number(rows[0]?.pinned ?? 0) === 0) {
    throw new SeasonWriteError('TOPIC_NOT_IN_SEASON', topicId,
      `topic ${topicId} is not in the open season's question set, so there is no ` +
      'pinned ladder revision to record this answer against. Add an ' +
      'inform.season_questions row for it, or write to a season that asks it.');
  }
  // Deliberately a plain Error. The two known causes are above; anything else
  // really is unexpected, and dressing it as a SeasonWriteError would tell an
  // operator to go open a season when a season is already open.
  throw new Error(`write affected 0 rows for topic ${topicId} for an unknown reason`);
}

/**
 * The read shape, as a SQL fragment: newest answered season for one
 * politician/topic pair, as a LATERAL subquery.
 *
 * 🔴 IT MUST BE A `LATERAL … LIMIT 1`, NOT A PLAIN JOIN. Joining
 * `politician_answers` on `(politician_id, topic_id)` returns one row per season
 * the moment a second season exists, so a plain join fans the result set out —
 * inflating counts and duplicating `array_agg` output with nothing to catch it.
 * Same trap CLAUDE.md documents for `office_current_holder`, where joining a
 * one-row-per-office view on `politician_id` doubles a dual-office holder.
 *
 * @param politicianExpr SQL expression for the politician id (e.g. `p.id`)
 * @param topicExpr      SQL expression for the topic id (e.g. `t.id`)
 * @param alias          alias for the lateral
 */
export function newestAnswerLateral(
  politicianExpr: string,
  topicExpr: string,
  alias = 'ans',
): string {
  return `LEFT JOIN LATERAL (
    SELECT a.value, a.season_id, a.topic_revision_id, s.number AS season_number
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id AND ${SEASON_IS_PUBLISHED}
     WHERE a.politician_id = ${politicianExpr}
       AND a.topic_id = ${topicExpr}
     ORDER BY s.number DESC
     LIMIT 1
  ) ${alias} ON true`;
}
