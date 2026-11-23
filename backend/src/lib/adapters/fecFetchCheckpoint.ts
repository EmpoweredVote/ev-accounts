/**
 * fecFetchCheckpoint — where a FEC source's fetch stopped when its time limit cut it off, so the
 * next attempt continues from there instead of starting over (ev-cto watchlist #102).
 *
 * WHY (measured 2026-11-22). The burst gives each source 10 minutes. FEC's ~1,000 req/hr key and
 * our 5 s page spacing hold one source to ~12,000-15,000 rows in that time, and the biggest
 * campaigns had more than that waiting after a few missed days. Each attempt re-read the same
 * first ~15,000 rows (largest gifts first), was cut off, and the next attempt began again from
 * the top with a window one day longer, so those sources could never catch up.
 *
 * WHAT A CHECKPOINT IS. One row per (source, cycle, committee) of a CHAIN of attempts that share
 * one query: the same `min_load_date`. A committee row is either `done` (its main pull finished
 * in this chain) or carries FEC's keyset cursor (`last_indexes`) to continue from. A null cursor
 * on an unfinished committee means "restart this committee" (the cut came in the windowed
 * fallback, which keeps its own per-window progress, or before the first page).
 *
 * THE ONE SUBTLE PART: the cursor after a chain. A resumed query is keyset-paged by amount, so a
 * row FEC loaded AFTER the chain began, sorting above the saved cursor, is never seen by the
 * chain. So a chain that finishes by resuming leaves its rows behind, all `done`, and the next
 * fresh attempt reads from `chain_started_at - 2 days` (the usual safety lookback) instead of
 * the cursor the ingestion_runs history would give. That attempt is an ordinary unresumed run:
 * when it finishes, the rows are deleted and the history is the cursor again.
 */
import { pool } from '../db.js';

export type FecLastIndexes = Record<string, string | number | null>;

export interface FecCheckpointRow {
  committee_id: string;
  /** Date-only, or null for a whole-cycle first load. Shared by every row of one chain. */
  min_load_date: string | null;
  last_indexes: FecLastIndexes | null;
  rows_saved: number;
  done: boolean;
  chain_started_at: string;
}

/** How an attempt starts, decided from the rows a previous attempt left. */
export type FecFetchPlan =
  | { kind: 'fresh'; clearFirst: boolean; floorMinLoadDate: string | null; hasFloor: boolean }
  | { kind: 'resume'; minLoadDate: string | null; chainStartedAt: string; rows: Map<string, FecCheckpointRow> };

/** Date-only (YYYY-MM-DD) for `iso` minus `days` days, in UTC. */
export function dateMinusDays(iso: string, days: number): string {
  const d = new Date(iso);
  d.setUTCDate(d.getUTCDate() - days);
  return d.toISOString().slice(0, 10);
}

/**
 * Pure: what an attempt does given the checkpoint rows for its (source, cycle).
 *  - none                → fresh, cursor from ingestion_runs history;
 *  - any unfinished      → resume the chain with its own min_load_date;
 *  - all done            → the chain finished by resuming: fresh, from chain start - 2 days.
 */
export function planFecFetch(rows: FecCheckpointRow[]): FecFetchPlan {
  if (rows.length === 0) return { kind: 'fresh', clearFirst: false, floorMinLoadDate: null, hasFloor: false };
  const chainStartedAt = rows[0]!.chain_started_at;
  if (rows.some((r) => !r.done)) {
    return {
      kind: 'resume',
      minLoadDate: rows[0]!.min_load_date,
      chainStartedAt,
      rows: new Map(rows.map((r) => [r.committee_id, r])),
    };
  }
  return { kind: 'fresh', clearFirst: true, floorMinLoadDate: dateMinusDays(chainStartedAt, 2), hasFloor: true };
}

/** Pure: the cursor a fresh attempt uses — the earlier of the history's and the chain floor. */
export function freshMinLoadDate(history: string | null, plan: Extract<FecFetchPlan, { kind: 'fresh' }>): string | null {
  if (!plan.hasFloor) return history;
  // A null on either side means "whole cycle", which already covers the other.
  if (history === null || plan.floorMinLoadDate === null) return null;
  return history < plan.floorMinLoadDate ? history : plan.floorMinLoadDate;
}

export async function loadFecCheckpoints(psId: string, cycle: string): Promise<FecCheckpointRow[]> {
  const r = await pool.query<FecCheckpointRow & { chain_started_at: string | Date }>(
    `SELECT committee_id,
            to_char(min_load_date, 'YYYY-MM-DD') AS min_load_date,
            last_indexes, rows_saved, done, chain_started_at
       FROM transparent_motivations.fec_fetch_checkpoints
      WHERE politician_source_id = $1 AND election_cycle = $2
      ORDER BY committee_id`,
    [psId, cycle]
  );
  // committee_id is the primary key, so a row without one is not a checkpoint (a shared test
  // double answers every query with the same row).
  return r.rows.filter((row) => typeof row.committee_id === 'string').map((row) => ({
    ...row,
    rows_saved: Number(row.rows_saved),
    chain_started_at: new Date(row.chain_started_at).toISOString(),
  }));
}

export async function clearFecCheckpoints(psId: string, cycle: string): Promise<void> {
  await pool.query(
    `DELETE FROM transparent_motivations.fec_fetch_checkpoints
      WHERE politician_source_id = $1 AND election_cycle = $2`,
    [psId, cycle]
  );
}

/** Write the whole chain's state in one statement (one row per committee). */
export async function saveFecCheckpoints(
  psId: string,
  cycle: string,
  minLoadDate: string | null,
  chainStartedAt: string,
  rows: Array<{ committeeId: string; done: boolean; lastIndexes: FecLastIndexes | null; rowsSaved: number }>
): Promise<void> {
  if (rows.length === 0) return;
  await pool.query(
    `INSERT INTO transparent_motivations.fec_fetch_checkpoints
       (politician_source_id, election_cycle, committee_id, min_load_date, last_indexes,
        rows_saved, done, chain_started_at, updated_at)
     SELECT $1, $2, r.committee_id, $3::date, r.last_indexes, r.rows_saved, r.done, $4::timestamptz, now()
       FROM jsonb_to_recordset($5::jsonb)
            AS r(committee_id text, last_indexes jsonb, rows_saved integer, done boolean)
     ON CONFLICT (politician_source_id, election_cycle, committee_id) DO UPDATE
       SET min_load_date = EXCLUDED.min_load_date, last_indexes = EXCLUDED.last_indexes,
           rows_saved = EXCLUDED.rows_saved, done = EXCLUDED.done,
           chain_started_at = EXCLUDED.chain_started_at, updated_at = now()`,
    [
      psId,
      cycle,
      minLoadDate,
      chainStartedAt,
      JSON.stringify(rows.map((r) => ({
        committee_id: r.committeeId,
        last_indexes: r.lastIndexes,
        rows_saved: r.rowsSaved,
        done: r.done,
      }))),
    ]
  );
}
