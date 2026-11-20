/**
 * The county banner review surface's only way into the database.
 *
 * 🔴 SAVING IS REPORTED, NEVER ASSUMED. On 2026-11-19 a crop editor's write path failed on its
 * first call and every subsequent save returned early in silence. The page looked correct the
 * whole time, and 73 counties of cropping were recovered only because the page still held them
 * in memory. Three things here exist because of that hour:
 *   - `recordDecision` returns THE ROW THE DATABASE PRODUCED, so the save stamp the page shows
 *     is what was stored and not what the client hoped.
 *   - A write that returns no row throws. "No rows updated" is a failure that looks exactly
 *     like a success to anyone who only checks for an exception.
 *   - `isWritable` lets the page say, from load, whether saving is switched on at all, rather
 *     than discovering it on the operator's twentieth county.
 *
 * 🔴 THE GATES LIVE HERE BECAUSE THE PAGE IS NOT THE ONLY CALLER. Two of them are also CHECK
 * constraints and are repeated deliberately: a database error reaches the operator as a
 * constraint name, and these reach them as a sentence. The third — caption_sighted — CANNOT be
 * a CHECK, because whether it is required depends on the chosen candidate's `located_by`, which
 * lives in another table.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import type { Queryable } from './seasonService.js';

export interface Decision {
  status: 'keep' | 'needs_another_look';
  chosenTitle: string | null;
  verticalAnchor: number | null;
  /** A CSS object-position string, e.g. '50% 30%'. Stored and returned verbatim. */
  focus: string | null;
  captionSighted: boolean;
}

export interface CandidateRow {
  commonsTitle: string;
  rankPosition: number;
  frameUrl: string;
  sourcePageUrl: string;
  width: number;
  height: number;
  licence: string;
  author: string;
  locatedBy: 'geometry' | 'caption';
  captionText: string | null;
  captionSourceUrl: string | null;
  confirmingSourceUrl: string | null;
  placeListAvailable: boolean | null;
}

export interface CountyReviewRow {
  geoid: string;
  stateUsps: string;
  countyName: string;
  status: 'pending' | 'keep' | 'needs_another_look';
  chosenTitle: string | null;
  verticalAnchor: number | null;
  focus: string | null;
  captionSighted: boolean;
  swept: boolean;
  filesSwept: number;
  categoriesFound: number;
  categoryErrors: number;
  geometryCandidates: number;
  captionCandidates: number;
  rejected: Record<string, number>;
  decidedAt: string | null;
  decidedBy: string | null;
  candidates: CandidateRow[];
}

export interface StateSummary {
  stateUsps: string;
  counties: number;
  pending: number;
  keep: number;
  needsAnotherLook: number;
}

/** A refusal the operator is meant to read. Routes turn this into a 400, never a 500. */
export class CountyBannerDecisionError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CountyBannerDecisionError';
  }
}

/** `50% 30%` -> two percentages. Anything else is not an object-position. */
const FOCUS_RE = /^\s*(\d{1,3}(?:\.\d+)?)%\s+(\d{1,3}(?:\.\d+)?)%\s*$/;

async function runner(db?: Queryable): Promise<Queryable> {
  // Imported lazily so this module can be unit-tested without a database.
  return db ?? (await import('./db.js')).pool;
}

const STATES_SQL = `
  SELECT state_usps,
         count(*)                                              AS counties,
         count(*) FILTER (WHERE status = 'pending')            AS pending,
         count(*) FILTER (WHERE status = 'keep')               AS keep,
         count(*) FILTER (WHERE status = 'needs_another_look') AS needs_another_look
    FROM essentials.county_banner_review
   GROUP BY state_usps
   ORDER BY state_usps`;

const STATE_COUNTIES_SQL = `
  SELECT r.*,
         (SELECT json_agg(c ORDER BY c.rank_position)
            FROM essentials.county_banner_candidates c
           WHERE c.geoid = r.geoid) AS candidates
    FROM essentials.county_banner_review r
   WHERE r.state_usps = $1
   ORDER BY r.county_name`;

const CHOSEN_SQL = `
  SELECT located_by FROM essentials.county_banner_candidates
   WHERE geoid = $1 AND commons_title = $2`;

const DECIDE_SQL = `
  UPDATE essentials.county_banner_review
     SET status          = $2,
         chosen_title    = $3,
         vertical_anchor = $4,
         focus           = $5,
         caption_sighted = $6,
         decided_at      = now(),
         decided_by      = $7
   WHERE geoid = $1
   RETURNING *`;

const WRITABLE_SQL = `
  SELECT has_table_privilege('essentials.county_banner_review', 'UPDATE') AS writable`;

function num(v: unknown): number {
  return v === null || v === undefined ? 0 : Number(v);
}

function toCandidate(r: Record<string, unknown>): CandidateRow {
  return {
    commonsTitle: String(r.commons_title),
    rankPosition: num(r.rank_position),
    frameUrl: String(r.frame_url ?? ''),
    sourcePageUrl: String(r.source_page_url ?? ''),
    width: num(r.width),
    height: num(r.height),
    licence: String(r.licence ?? ''),
    author: String(r.author ?? ''),
    locatedBy: r.located_by === 'caption' ? 'caption' : 'geometry',
    captionText: (r.caption_text as string | null) ?? null,
    captionSourceUrl: (r.caption_source_url as string | null) ?? null,
    confirmingSourceUrl: (r.confirming_source_url as string | null) ?? null,
    placeListAvailable: (r.place_list_available as boolean | null) ?? null,
  };
}

function toRow(r: Record<string, unknown>): CountyReviewRow {
  const raw = (r.candidates ?? []) as Array<Record<string, unknown>> | null;
  return {
    geoid: String(r.geoid),
    stateUsps: String(r.state_usps),
    countyName: String(r.county_name),
    status: r.status as CountyReviewRow['status'],
    chosenTitle: (r.chosen_title as string | null) ?? null,
    // numeric comes back from pg as a string; the page needs a number to drive a slider.
    verticalAnchor: r.vertical_anchor === null || r.vertical_anchor === undefined
      ? null : Number(r.vertical_anchor),
    // 🔴 focus is NOT parsed. It is stored and returned as the exact string the operator made.
    focus: (r.focus as string | null) ?? null,
    captionSighted: Boolean(r.caption_sighted),
    swept: Boolean(r.swept),
    filesSwept: num(r.files_swept),
    categoriesFound: num(r.categories_found),
    categoryErrors: num(r.category_errors),
    geometryCandidates: num(r.geometry_candidates),
    captionCandidates: num(r.caption_candidates),
    rejected: (r.rejected as Record<string, number>) ?? {},
    decidedAt: r.decided_at === null || r.decided_at === undefined
      ? null : new Date(r.decided_at as string).toISOString(),
    decidedBy: (r.decided_by as string | null) ?? null,
    candidates: (raw ?? []).map(toCandidate),
  };
}

export async function listStates(db?: Queryable): Promise<StateSummary[]> {
  const { rows } = await (await runner(db)).query<Record<string, unknown>>(STATES_SQL);
  return rows.map((r) => ({
    stateUsps: String(r.state_usps),
    counties: num(r.counties),
    pending: num(r.pending),
    keep: num(r.keep),
    needsAnotherLook: num(r.needs_another_look),
  }));
}

export async function getStateCounties(stateUsps: string, db?: Queryable): Promise<CountyReviewRow[]> {
  const { rows } = await (await runner(db))
    .query<Record<string, unknown>>(STATE_COUNTIES_SQL, [stateUsps.toUpperCase()]);
  return rows.map(toRow);
}

export async function isWritable(db?: Queryable): Promise<boolean> {
  const { rows } = await (await runner(db)).query<Record<string, unknown>>(WRITABLE_SQL);
  return Boolean(rows[0]?.writable);
}

export async function recordDecision(
  geoid: string, decision: Decision, actor: string, db?: Queryable,
): Promise<CountyReviewRow> {
  const r = await runner(db);
  const { status, chosenTitle, verticalAnchor, focus, captionSighted } = decision;

  if (status === 'needs_another_look' && chosenTitle !== null) {
    throw new CountyBannerDecisionError(
      'A county that needs another look ships blank. Clear the chosen option, or mark it a keep.',
    );
  }

  if (status === 'keep') {
    if (!chosenTitle) {
      throw new CountyBannerDecisionError('A keep must name the chosen candidate.');
    }
    if (!focus || !FOCUS_RE.test(focus)) {
      throw new CountyBannerDecisionError(
        `A keep needs a focus as two percentages, e.g. '50% 30%'. Got ${focus === null ? 'nothing' : `'${focus}'`}.`,
      );
    }
    if (verticalAnchor === null || verticalAnchor < 0 || verticalAnchor > 1) {
      throw new CountyBannerDecisionError(
        `A keep needs a vertical anchor between 0 and 1. Got ${verticalAnchor === null ? 'nothing' : verticalAnchor}.`,
      );
    }

    // 🔴 Read how this candidate was located IN THE SAME CALL that is about to write, so a row
    // flipped to 'caption' between page load and save cannot slip past a stale client check.
    const { rows } = await r.query<Record<string, unknown>>(CHOSEN_SQL, [geoid, chosenTitle]);
    if (rows.length === 0) {
      throw new CountyBannerDecisionError(`'${chosenTitle}' is not a candidate for county ${geoid}.`);
    }
    if (rows[0].located_by === 'caption' && !captionSighted) {
      throw new CountyBannerDecisionError(
        'This option was located by its caption, not by coordinates. Look at it and confirm it is the place before keeping it.',
      );
    }
  }

  const { rows: saved } = await r.query<Record<string, unknown>>(DECIDE_SQL, [
    geoid, status, chosenTitle, verticalAnchor, focus, captionSighted, actor,
  ]);
  if (saved.length === 0) {
    // "0 rows updated" looks exactly like success to a caller that only catches exceptions.
    throw new CountyBannerDecisionError(`County ${geoid} was NOT SAVED: no such county in the review table.`);
  }
  return toRow(saved[0]);
}
