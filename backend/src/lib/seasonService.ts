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
       JOIN inform.seasons s ON s.id = a.season_id
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
 * Read the row a write is about to replace, in the OPEN season.
 *
 * 🔴 NOT the newest answered season. This feeds audit diffs, and the write lands
 * in the open season — so "previous value" must mean that season's value, or
 * nothing if this is the first answer of the season. Diffing against season 1
 * while writing season 2 reports "changed 3 → 3" for what is actually a new row.
 *
 * Param order: $1 politician_id, $2 topic_id(s).
 */
export const OPEN_SEASON_ANSWER_SQL = `
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
    throw new Error(
      'no open season — nothing can be written until one is opened. ' +
      "Set a row in inform.seasons to status='open' with an opened_at, and give " +
      'it a season_questions row per topic pinning the ladder revision it asks.');
  }
  if (Number(rows[0]?.pinned ?? 0) === 0) {
    throw new Error(
      `topic ${topicId} is not in the open season's question set, so there is no ` +
      'pinned ladder revision to record this answer against. Add an ' +
      'inform.season_questions row for it, or write to a season that asks it.');
  }
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
      JOIN inform.seasons s ON s.id = a.season_id
     WHERE a.politician_id = ${politicianExpr}
       AND a.topic_id = ${topicExpr}
     ORDER BY s.number DESC
     LIMIT 1
  ) ${alias} ON true`;
}
