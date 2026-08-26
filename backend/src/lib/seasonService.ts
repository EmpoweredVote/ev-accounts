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
