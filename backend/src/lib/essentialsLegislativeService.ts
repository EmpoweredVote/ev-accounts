/**
 * essentialsLegislativeService — legislative data lookups for politician profiles.
 *
 * WHY THIS FILE EXISTS:
 * Legislative tables are large (19,622 bills, 121,178 votes, 44,021 bill cosponsors).
 * Keeping them separate from essentialsService.ts makes both files manageable and
 * allows independent testing of the legislative domain.
 *
 * ALL queries use pool.query() — essentials schema is NOT in the PostgREST exposed
 * schema list. supabaseAdmin.schema('essentials') fails at runtime. See MEMORY.md.
 *
 * Schema overview (queried from live DB 2026-03-20):
 *   legislative_sessions:            id, jurisdiction, name, start_date, end_date,
 *                                    is_current, external_id, source
 *   legislative_bills:               id, session_id, external_id, jurisdiction, number,
 *                                    title, summary, raw_status, status_label,
 *                                    sponsor_id → politicians.id, introduced_at,
 *                                    passed_at, signed_at, topic_tags, url, source
 *   legislative_bill_cosponsors:     id, bill_id, politician_id
 *   legislative_committee_memberships: id, committee_id, politician_id, congress_number,
 *                                    role, is_current, session_id
 *   legislative_committees:          id, session_id, parent_id, external_id,
 *                                    jurisdiction, name, type, chamber, is_current, source
 *   legislative_votes:               id, politician_id, bill_id, session_id,
 *                                    external_vote_id, vote_question, position,
 *                                    vote_date, result, yea_count, nay_count, source
 *
 * FK patterns (all by convention — no FK constraints defined):
 *   legislative_bills.sponsor_id → essentials.politicians.id
 *   legislative_bill_cosponsors.politician_id → essentials.politicians.id
 *   legislative_committee_memberships.politician_id → essentials.politicians.id
 *   legislative_votes.politician_id → essentials.politicians.id
 *
 * NOTE: legislative_sessions has NO direct politician_id column.
 * Sessions are linked to politicians via the bills they sponsored/cosponsored.
 * getLegislativeByPolitician queries sessions reachable from a politician's bills.
 */

import { readFileSync } from 'node:fs';
import { pool } from './db.js';

/**
 * Ids of every bill the politician ($1) sponsored or cosponsored, for `b.id IN (...)`.
 *
 * Written as a UNION, not `sponsor_id = $1 OR EXISTS (cosponsor)`: Postgres cannot drive an
 * OR across two tables from indexes, so that form seq-scanned all of legislative_bills
 * (222k rows, ~70 MB) on every profile view. When the disk-read budget ran low those pages
 * came off disk and legislative-summary took 3-16 s for a politician with no bills at all.
 * Each UNION arm reads one index instead: (sponsor_id, introduced_at) on bills and
 * (politician_id, bill_id) on cosponsors, both from migration CA_0321. Without those indexes
 * this form is no slower than the OR form, so the code can ship first.
 */
const BILL_IDS_FOR_POLITICIAN = `
  SELECT id FROM essentials.legislative_bills WHERE sponsor_id = $1
  UNION
  SELECT bill_id FROM essentials.legislative_bill_cosponsors WHERE politician_id = $1
`;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface LegislativeSession {
  id: string;
  name: string;
  jurisdiction: string;
  start_date: string | null;
  end_date: string | null;
  is_current: boolean;
  external_id: string;
  bill_count: number;
  vote_count: number;
}

export interface CommitteeMembership {
  id: string;
  committee_id: string;
  committee_name: string;
  committee_type: string;
  chamber: string;
  jurisdiction: string;
  role: string;
  is_current: boolean;
  congress_number: number | null;
  session_id: string | null;
}

export interface Bill {
  id: string;
  number: string;
  title: string;
  summary: string;
  status_label: string;
  raw_status: string;
  jurisdiction: string;
  session_name: string;
  session_id: string | null;
  introduced_at: string | null;
  passed_at: string | null;
  signed_at: string | null;
  topic_tags: string[] | null;
  url: string;
  is_sponsor: boolean;
}

export interface Vote {
  id: string;
  bill_id: string;
  bill_number: string;
  bill_title: string;
  vote_question: string;
  position: string;
  vote_date: string | null;
  result: string;
  yea_count: number | null;
  nay_count: number | null;
  session_id: string | null;
  /** Bill page URL (LegiScan rows link to legiscan.com; used for CC BY credit + Source link). */
  bill_url: string | null;
}

// ---------------------------------------------------------------------------
// getLegislativeByPolitician
// ---------------------------------------------------------------------------

/**
 * Fetch legislative sessions for a politician.
 *
 * Since legislative_sessions has no direct politician_id column, sessions are
 * retrieved via bills the politician sponsored or cosponsored. This gives the
 * sessions the politician was active in — the meaningful definition of
 * "legislative sessions for a politician".
 *
 * Returns sessions with bill_count (number of bills the politician sponsored
 * or cosponsored in that session) and vote_count (number of votes cast).
 *
 * Returns [] when no bills or votes exist for this politician.
 * Uses pool.query() — essentials schema is not PostgREST-exposed.
 */
export async function getLegislativeByPolitician(
  politicianId: string
): Promise<LegislativeSession[]> {
  // Get distinct sessions from bills the politician sponsored or cosponsored,
  // plus sessions from their votes, aggregated with counts.
  const queryText = `
    SELECT
      s.id,
      s.name,
      s.jurisdiction,
      s.start_date,
      s.end_date,
      s.is_current,
      COALESCE(s.external_id, '') AS external_id,
      COALESCE(bill_counts.bill_count, 0)::int AS bill_count,
      COALESCE(vote_counts.vote_count, 0)::int AS vote_count
    FROM essentials.legislative_sessions s
    JOIN (
      -- Sessions from sponsored bills
      SELECT DISTINCT session_id
      FROM essentials.legislative_bills
      WHERE sponsor_id = $1

      UNION

      -- Sessions from cosponsored bills
      SELECT DISTINCT lb.session_id
      FROM essentials.legislative_bill_cosponsors lbc
      JOIN essentials.legislative_bills lb ON lb.id = lbc.bill_id
      WHERE lbc.politician_id = $1

      UNION

      -- Sessions from votes (politician may vote without sponsoring)
      SELECT DISTINCT session_id
      FROM essentials.legislative_votes
      WHERE politician_id = $1
    ) active_sessions ON active_sessions.session_id = s.id
    LEFT JOIN (
      -- Bill count: sponsored + cosponsored
      SELECT lb.session_id, COUNT(*)::int AS bill_count
      FROM essentials.legislative_bills lb
      WHERE lb.id IN (${BILL_IDS_FOR_POLITICIAN})
      GROUP BY lb.session_id
    ) bill_counts ON bill_counts.session_id = s.id
    LEFT JOIN (
      -- Vote count
      SELECT session_id, COUNT(*)::int AS vote_count
      FROM essentials.legislative_votes
      WHERE politician_id = $1
      GROUP BY session_id
    ) vote_counts ON vote_counts.session_id = s.id
    ORDER BY s.is_current DESC, s.start_date DESC NULLS FIRST, s.name ASC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    id: row.id as string,
    name: row.name ?? '',
    jurisdiction: row.jurisdiction ?? '',
    start_date: row.start_date ? (row.start_date as Date).toISOString() : null,
    end_date: row.end_date ? (row.end_date as Date).toISOString() : null,
    is_current: row.is_current ?? false,
    external_id: row.external_id ?? '',
    bill_count: Number(row.bill_count) || 0,
    vote_count: Number(row.vote_count) || 0,
  }));
}

// ---------------------------------------------------------------------------
// getCommitteesByPolitician
// ---------------------------------------------------------------------------

/**
 * Fetch committee memberships for a politician.
 *
 * JOINs legislative_committee_memberships → legislative_committees to include
 * committee details (name, type, chamber, jurisdiction).
 *
 * Returns [] when no committee memberships exist.
 * Uses pool.query() — essentials schema is not PostgREST-exposed.
 */
export async function getCommitteesByPolitician(
  politicianId: string
): Promise<CommitteeMembership[]> {
  const queryText = `
    SELECT
      m.id,
      m.committee_id,
      COALESCE(c.name, '') AS committee_name,
      COALESCE(c.type, '') AS committee_type,
      COALESCE(c.chamber, '') AS chamber,
      COALESCE(c.jurisdiction, '') AS jurisdiction,
      COALESCE(m.role, '') AS role,
      COALESCE(m.is_current, false) AS is_current,
      m.congress_number,
      m.session_id
    FROM essentials.legislative_committee_memberships m
    JOIN essentials.legislative_committees c ON c.id = m.committee_id
    WHERE m.politician_id = $1
    ORDER BY m.is_current DESC, c.name ASC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    id: row.id as string,
    committee_id: row.committee_id as string,
    committee_name: row.committee_name ?? '',
    committee_type: row.committee_type ?? '',
    chamber: row.chamber ?? '',
    jurisdiction: row.jurisdiction ?? '',
    role: row.role ?? '',
    is_current: row.is_current ?? false,
    congress_number: row.congress_number != null ? Number(row.congress_number) : null,
    session_id: row.session_id ?? null,
  }));
}

// ---------------------------------------------------------------------------
// getBillsByPolitician
// ---------------------------------------------------------------------------

/**
 * Fetch bills sponsored or cosponsored by a politician.
 *
 * Returns bills where the politician is either the primary sponsor (sponsor_id)
 * or a cosponsor (legislative_bill_cosponsors). The is_sponsor field distinguishes
 * between the two roles.
 *
 * Large table: 19,622 bills. Default limit 50, max 100.
 * Ordered by introduced_at DESC (most recent first).
 *
 * Returns [] when no bills exist for this politician.
 * Uses pool.query() — essentials schema is not PostgREST-exposed.
 */
export async function getBillsByPolitician(
  politicianId: string,
  limit = 50,
  includeIntroduced = false
): Promise<Bill[]> {
  // Clamp limit to 1-250 range (Go backend allows up to 250)
  const clampedLimit = Math.min(250, Math.max(1, limit));

  // By default, exclude "Introduced" status bills (matches Go backend behavior)
  const statusFilter = includeIntroduced ? '' : `AND COALESCE(b.status_label, '') != 'Introduced'`;

  const queryText = `
    SELECT
      b.id,
      COALESCE(b.number, '') AS number,
      COALESCE(b.title, '') AS title,
      COALESCE(b.summary, '') AS summary,
      COALESCE(b.status_label, '') AS status_label,
      COALESCE(b.raw_status, '') AS raw_status,
      COALESCE(b.jurisdiction, '') AS jurisdiction,
      COALESCE(s.name, '') AS session_name,
      b.session_id,
      b.introduced_at,
      b.passed_at,
      b.signed_at,
      b.topic_tags,
      COALESCE(b.url, '') AS url,
      (b.sponsor_id = $1) AS is_sponsor
    FROM essentials.legislative_bills b
    LEFT JOIN essentials.legislative_sessions s ON s.id = b.session_id
    WHERE b.id IN (${BILL_IDS_FOR_POLITICIAN})
    ${statusFilter}
    ORDER BY b.introduced_at DESC NULLS LAST
    LIMIT $2
  `;

  const { rows } = await pool.query(queryText, [politicianId, clampedLimit]);

  return rows.map((row) => ({
    id: row.id as string,
    number: row.number ?? '',
    title: row.title ?? '',
    summary: row.summary ?? '',
    status_label: row.status_label ?? '',
    raw_status: row.raw_status ?? '',
    jurisdiction: row.jurisdiction ?? '',
    session_name: row.session_name ?? '',
    session_id: row.session_id ?? null,
    introduced_at: row.introduced_at ? (row.introduced_at as Date).toISOString() : null,
    passed_at: row.passed_at ? (row.passed_at as Date).toISOString() : null,
    signed_at: row.signed_at ? (row.signed_at as Date).toISOString() : null,
    topic_tags: Array.isArray(row.topic_tags) ? row.topic_tags : null,
    url: row.url ?? '',
    is_sponsor: row.is_sponsor ?? false,
  }));
}

// ---------------------------------------------------------------------------
// getVotesByPolitician
// ---------------------------------------------------------------------------

/**
 * Fetch voting record for a politician.
 *
 * JOINs legislative_votes → legislative_bills to include bill number and title
 * alongside each vote record.
 *
 * Large table: 121,178 votes. Default limit 50, max 100.
 * Ordered by vote_date DESC (most recent first).
 *
 * Returns [] when no votes exist for this politician.
 * Uses pool.query() — essentials schema is not PostgREST-exposed.
 */
export async function getVotesByPolitician(
  politicianId: string,
  limit = 50
): Promise<Vote[]> {
  // Clamp limit to 1-100 range
  const clampedLimit = Math.min(100, Math.max(1, limit));

  const queryText = `
    SELECT
      v.id,
      v.bill_id,
      COALESCE(b.number, '') AS bill_number,
      COALESCE(b.title, '') AS bill_title,
      COALESCE(v.vote_question, '') AS vote_question,
      COALESCE(v.position, '') AS position,
      v.vote_date,
      COALESCE(v.result, '') AS result,
      v.yea_count,
      v.nay_count,
      v.session_id,
      b.url AS bill_url
    FROM essentials.legislative_votes v
    LEFT JOIN essentials.legislative_bills b ON b.id = v.bill_id
    WHERE v.politician_id = $1
    ORDER BY v.vote_date DESC NULLS LAST
    LIMIT $2
  `;

  const { rows } = await pool.query(queryText, [politicianId, clampedLimit]);

  return rows.map((row) => ({
    id: row.id as string,
    bill_id: row.bill_id ?? '',
    bill_number: row.bill_number ?? '',
    bill_title: row.bill_title ?? '',
    vote_question: row.vote_question ?? '',
    position: row.position ?? '',
    vote_date: row.vote_date ? (row.vote_date as Date).toISOString() : null,
    result: row.result ?? '',
    yea_count: row.yea_count != null ? Number(row.yea_count) : null,
    nay_count: row.nay_count != null ? Number(row.nay_count) : null,
    session_id: row.session_id ?? null,
    bill_url: row.bill_url ?? null,
  }));
}

// ---------------------------------------------------------------------------
// getLegislativeSummary
// ---------------------------------------------------------------------------

/**
 * Fetch recent bills (5) and recent votes (10) for profile rendering.
 * Matches Go server /politician/{id}/legislative-summary response shape.
 */
export async function getLegislativeSummary(
  politicianId: string
): Promise<{ recent_bills: Bill[]; recent_votes: Vote[] }> {
  const [bills, votes] = await Promise.all([
    getBillsByPolitician(politicianId, 5),
    getVotesByPolitician(politicianId, 10),
  ]);
  return { recent_bills: bills, recent_votes: votes };
}

// ---------------------------------------------------------------------------
// getLeadershipByPolitician
// ---------------------------------------------------------------------------

export interface LeadershipPosition {
  title: string;
  chamber: string;
  is_current: boolean;
  start_date: string | null;
  end_date: string | null;
}

/**
 * Fetch leadership positions for a politician.
 * Matches Go server /politician/{id}/leadership response shape.
 */
export async function getLeadershipByPolitician(
  politicianId: string
): Promise<LeadershipPosition[]> {
  const queryText = `
    SELECT
      COALESCE(title, '') AS title,
      COALESCE(chamber, '') AS chamber,
      COALESCE(is_current, false) AS is_current,
      start_date,
      end_date
    FROM essentials.legislative_leadership_roles
    WHERE politician_id = $1
    ORDER BY is_current DESC, start_date DESC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    title: row.title ?? '',
    chamber: row.chamber ?? '',
    is_current: row.is_current ?? false,
    start_date: row.start_date ? (row.start_date as Date).toISOString().split('T')[0] : null,
    end_date: row.end_date ? (row.end_date as Date).toISOString().split('T')[0] : null,
  }));
}

// ---------------------------------------------------------------------------
// getCouncilRecordByPolitician — a city council member's roll-call record
// ---------------------------------------------------------------------------

export type CouncilPosition = 'yea' | 'nay' | 'present' | 'absent' | 'not_voting';

export interface CouncilRecordVote {
  roll_call_id: string;
  question: string;
  question_order: number;
  meeting_date: string;
  position: CouncilPosition;
  worked_out: boolean;
  outcome: string;
  yes: number;
  no: number;
  abstain: number;
  /** Public source_url of the confirming document (the clerk's Memorandum or the formal Minutes), no #fragment. */
  minutes_url: string;
  source_kind: 'memorandum' | 'minutes';
  feed_disagreement: string | null;
  seat_label: string | null;
  sponsors: CouncilSponsor[];
}

export interface CouncilRecordPending {
  meeting_date: string;
  outcome: 'passed' | 'failed' | 'vetoed';
  yes: number;
  no: number;
  abstain: number;
}

export interface CouncilSponsor {
  politician_id: string;
  name: string;
  role: 'sponsor' | 'cosponsor';
}

export interface CouncilRecordItem {
  bill_id: string;
  sponsors: CouncilSponsor[];
  number: string;
  title: string;
  url: string;
  status_label: string;
  pending: CouncilRecordPending | null;
  votes: CouncilRecordVote[];
}

export interface CouncilRecord {
  total: number;
  items: CouncilRecordItem[];
}

export interface CouncilCity {
  scope: string;
  chamberSlug: string;
  /** offices.normalized_position_name of the council's seats; the chamber slug also covers the City Clerk. */
  seatPositionName: string;
}

interface CouncilTerm {
  title: string;
  slug: string;
  start: string;
  end: string | null;
}

/** The cities that have a council record, from the same file the weekly job reads. */
let councilCitiesCache: CouncilCity[] | null = null;
/** A city without seatPositionName would match no office (NULL), so it fails loudly instead. */
export function parseCouncilCities(raw: unknown): CouncilCity[] {
  return (raw as CouncilCity[]).map((c) => {
    if (typeof c.seatPositionName !== 'string' || c.seatPositionName === '') {
      throw new Error(`cities.json: city ${c.scope} has no seatPositionName`);
    }
    return { scope: c.scope, chamberSlug: c.chamberSlug, seatPositionName: c.seatPositionName };
  });
}

export function loadCouncilCities(): CouncilCity[] {
  if (!councilCitiesCache) {
    councilCitiesCache = parseCouncilCities(
      JSON.parse(readFileSync(new URL('../../data/local-record/cities.json', import.meta.url), 'utf8')),
    );
  }
  return councilCitiesCache;
}

/** The seat held on `date` (YYYY-MM-DD). Date containment, never `term_end IS NULL`. Latest start wins a tie. */
function seatOn(terms: CouncilTerm[], date: string): string | null {
  const held = terms
    .filter((t) => t.start <= date && (t.end == null || date <= t.end))
    .sort((a, b) => (a.start < b.start ? 1 : a.start > b.start ? -1 : a.title.localeCompare(b.title)));
  return held.length ? held[0].title : null;
}

function inAnyTerm(terms: CouncilTerm[], date: string, slug: string): boolean {
  return terms.some((t) => t.slug === slug && t.start <= date && (t.end == null || date <= t.end));
}

/** Postgres undefined_table: the sponsorships table is not there yet (code deployed before its migration). */
function isUndefinedTable(err: unknown): boolean {
  return typeof err === 'object' && err !== null && (err as { code?: string }).code === '42P01';
}

/**
 * Amendment key shared by sponsorships and roll-call questions. Sponsorship labels read "Amendment 01" or
 * "Reasonable Condition 2"; roll-call questions are stored "Amendment 01" and "Reasonable Condition 04". Both are
 * mapped to type + number, so zero padding never decides a match. Other questions ("Final passage") have no key.
 */
export function amendmentKey(label: string | null | undefined): string | null {
  const m = /^(Amendment|Reasonable Condition) (\d+)$/.exec(label ?? '');
  return m ? `${m[1]} ${Number(m[2])}` : null;
}

/** Council sponsorships for these bills, in one query. A missing table (42P01) reads as no sponsorships. */
async function loadSponsorships(
  billIds: string[],
): Promise<Map<string, { label: string | null; sponsor: CouncilSponsor }[]>> {
  const out = new Map<string, { label: string | null; sponsor: CouncilSponsor }[]>();
  if (!billIds.length) return out;
  let rows: any[];
  try {
    rows = (
      await pool.query(
        `SELECT s.bill_id, s.amendment_label, s.politician_id, s.role,
                COALESCE(NULLIF(p.full_name, ''), btrim(COALESCE(p.first_name, '') || ' ' || COALESCE(p.last_name, ''))) AS name
         FROM essentials.legislative_sponsorships s
         JOIN essentials.politicians p ON p.id = s.politician_id
         WHERE s.bill_id = ANY($1::uuid[])
         ORDER BY s.bill_id, (s.role = 'sponsor') DESC, name, s.politician_id`,
        [billIds],
      )
    ).rows;
  } catch (err) {
    if (isUndefinedTable(err)) return out;
    throw err;
  }
  for (const r of rows) {
    const list = out.get(r.bill_id) ?? [];
    list.push({
      label: r.amendment_label ?? null,
      sponsor: { politician_id: r.politician_id, name: r.name, role: r.role },
    });
    out.set(r.bill_id, list);
  }
  return out;
}

/**
 * Roll-call record for one council member, grouped by legislation item.
 *
 * Three queries, none fanning out: (1) the member's council terms, DISTINCT (a member may hold two offices, and
 * office_terms cannot see that); (2) the roll calls the member voted in, one row per roll call; (3) pending roll
 * calls (seen in the city feed, not yet confirmed) for the member's city. Pending items are filtered here by
 * date containment against the member's terms, and carry counts only, never names. The private
 * local_record_source_documents table is read through the backend's own pool and only its kind and public
 * source_url leave this function.
 */
export async function getCouncilRecordByPolitician(
  politicianId: string,
  limit = 50,
  offset = 0,
  deps: { cities?: CouncilCity[]; today?: string } = {},
): Promise<CouncilRecord> {
  const clampedLimit = Math.min(200, Math.max(1, Math.floor(limit) || 50));
  const clampedOffset = Math.max(0, Math.floor(offset) || 0);
  const cities = deps.cities ?? loadCouncilCities();
  const today = deps.today ?? new Date().toISOString().slice(0, 10);

  const termRows = (
    await pool.query(
      `SELECT DISTINCT o.title AS title, ch.slug AS slug, o.normalized_position_name AS position,
              to_char(ot.term_start, 'YYYY-MM-DD') AS start,
              to_char(ot.term_end, 'YYYY-MM-DD') AS "end"
       FROM essentials.office_terms ot
       JOIN essentials.offices o ON o.id = ot.office_id
       JOIN essentials.chambers ch ON ch.id = o.chamber_id
       WHERE ot.politician_id = $1 AND ot.term_start IS NOT NULL
         AND (ch.slug, o.normalized_position_name) IN (SELECT * FROM unnest($2::text[], $3::text[]))`,
      [politicianId, cities.map((c) => c.chamberSlug), cities.map((c) => c.seatPositionName)],
    )
  ).rows;
  // The chamber slug also covers the City Clerk; only the council's own position name is a seat. The SQL says so,
  // and this keeps the rule even if a row slips through.
  const terms: CouncilTerm[] = termRows
    .filter((r) => cities.some((c) => c.chamberSlug === r.slug && c.seatPositionName === r.position))
    .map((r) => ({ title: r.title ?? '', slug: r.slug, start: r.start, end: r.end ?? null }));

  const ROLL_COLUMNS = `
      r.id AS roll_call_id, r.city_scope, r.question, r.question_order, r.outcome,
      to_char(r.meeting_date, 'YYYY-MM-DD') AS meeting_date,
      COALESCE(r.yes_count, 0) AS yes, COALESCE(r.no_count, 0) AS no, COALESCE(r.abstain_count, 0) AS abstain,
      r.feed_disagreement,
      b.id AS bill_id, COALESCE(b.number, '') AS number, COALESCE(b.title, '') AS title,
      COALESCE(b.url, '') AS url, COALESCE(b.status_label, '') AS status_label`;

  const voted = (
    await pool.query(
      `SELECT DISTINCT ON (r.id) ${ROLL_COLUMNS},
              v.position, COALESCE(v.worked_out, false) AS worked_out,
              sd.kind AS source_kind, split_part(sd.source_url, '#', 1) AS minutes_url
       FROM essentials.legislative_votes v
       JOIN essentials.legislative_roll_calls r ON r.id = v.roll_call_id
       JOIN essentials.legislative_bills b ON b.id = r.bill_id
       LEFT JOIN essentials.local_record_source_documents sd ON sd.id = r.confirmed_from
       WHERE v.politician_id = $1 AND r.state = 'confirmed'
       ORDER BY r.id`,
      [politicianId],
    )
  ).rows;

  const scopes = cities.filter((c) => terms.some((t) => t.slug === c.chamberSlug)).map((c) => c.scope);
  const pendingRows = scopes.length
    ? (
        await pool.query(
          `SELECT ${ROLL_COLUMNS}
           FROM essentials.legislative_roll_calls r
           JOIN essentials.legislative_bills b ON b.id = r.bill_id
           WHERE r.state = 'pending_minutes' AND r.city_scope = ANY($1::text[])`,
          [scopes],
        )
      ).rows
    : [];

  // Confirmed roll calls in the member's city scopes, whether or not this member has a vote row on them.
  const confirmedRows: any[] = pendingRows.length
    ? (
        await pool.query(
          `SELECT DISTINCT r.city_scope, r.bill_id, to_char(r.meeting_date, 'YYYY-MM-DD') AS meeting_date, r.question
           FROM essentials.legislative_roll_calls r
           WHERE r.state = 'confirmed' AND r.city_scope = ANY($1::text[]) AND r.bill_id = ANY($2::uuid[])`,
          [scopes, [...new Set(pendingRows.map((r: any) => r.bill_id))]],
        )
      ).rows
    : [];
  const confirmedKeys = new Set<string>(confirmedRows.map((r) => `${r.city_scope}|${r.bill_id}|${r.meeting_date}`));
  // Bills with a confirmed Final passage on any date: a pending Final passage beside one is stale (the feed's Final
  // date differs from the vote document's) and is never shown; the weekly job logs it as feed_missing_final.
  const confirmedFinal = new Set<string>(
    confirmedRows.filter((r) => r.question === 'Final passage').map((r) => `${r.city_scope}|${r.bill_id}`),
  );

  const items = new Map<string, CouncilRecordItem & { latest: string }>();
  const itemFor = (row: any) => {
    let it = items.get(row.bill_id);
    if (!it) {
      it = {
        bill_id: row.bill_id, sponsors: [], number: row.number, title: row.title, url: row.url,
        status_label: row.status_label, pending: null, votes: [], latest: '',
      };
      items.set(row.bill_id, it);
    }
    if (row.meeting_date > it.latest) it.latest = row.meeting_date;
    return it;
  };

  const currentSeat = seatOn(terms, today);
  for (const row of voted) {
    // A vote must name the document it was confirmed from (Memorandum or Minutes); never guess a source.
    if ((row.source_kind !== 'memorandum' && row.source_kind !== 'minutes') || !row.minutes_url) continue;
    const seat = seatOn(terms, row.meeting_date);
    itemFor(row).votes.push({
      roll_call_id: row.roll_call_id,
      question: row.question,
      question_order: Number(row.question_order),
      meeting_date: row.meeting_date,
      position: row.position,
      worked_out: row.worked_out === true,
      outcome: row.outcome,
      yes: Number(row.yes),
      no: Number(row.no),
      abstain: Number(row.abstain),
      minutes_url: row.minutes_url,
      source_kind: row.source_kind,
      feed_disagreement: row.feed_disagreement ?? null,
      seat_label: seat != null && currentSeat != null && seat !== currentSeat ? seat : null,
      sponsors: [],
    });
  }

  for (const row of pendingRows) {
    const slug = cities.find((c) => c.scope === row.city_scope)?.chamberSlug;
    // Pending states the meeting's outcome and counts, never the member's vote, so it shows for any meeting
    // inside the member's term regardless of attendance.
    if (!slug || !inAnyTerm(terms, row.meeting_date, slug)) continue;
    // A confirmed roll call for the same bill and meeting supersedes the pending one.
    if (confirmedKeys.has(`${row.city_scope}|${row.bill_id}|${row.meeting_date}`)) continue;
    if (row.question === 'Final passage' && confirmedFinal.has(`${row.city_scope}|${row.bill_id}`)) continue;
    const it = itemFor(row);
    if (!it.pending || row.meeting_date > it.pending.meeting_date) {
      it.pending = {
        meeting_date: row.meeting_date, outcome: row.outcome,
        yes: Number(row.yes), no: Number(row.no), abstain: Number(row.abstain),
      };
    }
  }

  const all = [...items.values()].sort((a, b) =>
    a.latest < b.latest ? 1 : a.latest > b.latest ? -1 : a.bill_id.localeCompare(b.bill_id),
  );
  const pageItems = all.slice(clampedOffset, clampedOffset + clampedLimit);
  const sponsorships = await loadSponsorships(pageItems.map((it) => it.bill_id));
  const page = pageItems.map(({ latest: _latest, ...it }) => {
    const rows = sponsorships.get(it.bill_id) ?? [];
    return {
      ...it,
      sponsors: rows.filter((r) => r.label === null).map((r) => r.sponsor),
      votes: it.votes
        .map((v) => {
          const key = amendmentKey(v.question);
          return {
            ...v,
            sponsors: key === null ? [] : rows.filter((r) => amendmentKey(r.label) === key).map((r) => r.sponsor),
          };
        })
        .sort((a, b) =>
          a.meeting_date < b.meeting_date ? -1 : a.meeting_date > b.meeting_date ? 1 : a.question_order - b.question_order,
        ),
    };
  });
  return { total: all.length, items: page };
}

export interface CouncilSponsorshipItem {
  bill_id: string;
  number: string;
  title: string;
  url: string;
  amendment_label: string | null;
  role: 'sponsor' | 'cosponsor';
  co_sponsors: CouncilSponsor[];
  sentence: string;
  document_url: string;
  status: string;
}

export interface CouncilSponsorships {
  total: number;
  items: CouncilSponsorshipItem[];
}

/** Feed statuses that stand in for a vote. Anything else (Passed, Introduced) is not proof of a vote. */
const FEED_STATUSES: Record<string, string> = { withdrawn: 'Withdrawn', pending: 'Pending' };

/**
 * What a member sponsored or co-sponsored, newest first by the item's latest meeting date. Reads only
 * legislative_sponsorships (never the old sponsor_id or cosponsor tables). Status, first match wins: the
 * amendment's own roll-call outcome; the item's Final passage outcome; the feed status Withdrawn or Pending; else
 * "No recorded vote". Outcomes are the stored words ("passed", "failed", "vetoed"), as the council record returns
 * them. Three queries: the member's rows, the roll calls of those bills, and the other sponsors on the page's rows.
 * document_url is the city's public URL; the private storage path is never selected.
 */
export async function getCouncilSponsorshipsByPolitician(
  politicianId: string,
  limit = 50,
  offset = 0,
): Promise<CouncilSponsorships> {
  const clampedLimit = Math.min(200, Math.max(1, Math.floor(limit) || 50));
  const clampedOffset = Math.max(0, Math.floor(offset) || 0);

  let own: any[];
  try {
    own = (
      await pool.query(
        `SELECT s.bill_id, s.amendment_label, s.role, s.sentence,
                split_part(sd.source_url, '#', 1) AS document_url,
                COALESCE(b.number, '') AS number, COALESCE(b.title, '') AS title,
                COALESCE(b.url, '') AS url, COALESCE(b.status_label, '') AS status_label
         FROM essentials.legislative_sponsorships s
         JOIN essentials.legislative_bills b ON b.id = s.bill_id
         JOIN essentials.local_record_source_documents sd ON sd.id = s.source_document_id
         WHERE s.politician_id = $1`,
        [politicianId],
      )
    ).rows;
  } catch (err) {
    if (isUndefinedTable(err)) return { total: 0, items: [] };
    throw err;
  }
  if (!own.length) return { total: 0, items: [] };

  const billIds = [...new Set(own.map((r) => r.bill_id as string))];
  const rolls: any[] = (
    await pool.query(
      `SELECT r.bill_id, r.question, r.outcome, r.state, to_char(r.meeting_date, 'YYYY-MM-DD') AS meeting_date
       FROM essentials.legislative_roll_calls r
       WHERE r.bill_id = ANY($1::uuid[]) AND r.state IN ('confirmed', 'pending_minutes')`,
      [billIds],
    )
  ).rows;

  const latest = new Map<string, string>();
  for (const r of rolls) if (r.meeting_date > (latest.get(r.bill_id) ?? '')) latest.set(r.bill_id, r.meeting_date);

  const outcomeFor = (billId: string, question: (q: string) => boolean): string | null => {
    const hits = rolls
      .filter((r) => r.bill_id === billId && question(r.question))
      // A confirmed roll call outranks a pending one; then the latest meeting.
      .sort((a, b) =>
        a.state !== b.state ? (a.state === 'confirmed' ? -1 : 1) : a.meeting_date < b.meeting_date ? 1 : a.meeting_date > b.meeting_date ? -1 : 0,
      );
    return hits.length ? (hits[0].outcome as string) : null;
  };

  const sorted = [...own].sort((a, b) => {
    const la = latest.get(a.bill_id) ?? '';
    const lb = latest.get(b.bill_id) ?? '';
    if (la !== lb) return la < lb ? 1 : -1;
    return (
      String(a.bill_id).localeCompare(String(b.bill_id)) ||
      String(a.amendment_label ?? '').localeCompare(String(b.amendment_label ?? ''))
    );
  });
  const pageRows = sorted.slice(clampedOffset, clampedOffset + clampedLimit);
  const others = await loadSponsorships([...new Set(pageRows.map((r) => r.bill_id as string))]);

  const items = pageRows.map((r): CouncilSponsorshipItem => {
    const label: string | null = r.amendment_label ?? null;
    const key = amendmentKey(label);
    const own_ = key === null ? null : outcomeFor(r.bill_id, (q) => amendmentKey(q) === key);
    const final = outcomeFor(r.bill_id, (q) => q === 'Final passage');
    const feed = FEED_STATUSES[String(r.status_label).trim().toLowerCase()] ?? null;
    return {
      bill_id: r.bill_id,
      number: r.number,
      title: r.title,
      url: r.url,
      amendment_label: label,
      role: r.role,
      co_sponsors: (others.get(r.bill_id) ?? [])
        .filter((o) => o.label === label || (key !== null && amendmentKey(o.label) === key))
        .map((o) => o.sponsor)
        .filter((sp) => sp.politician_id !== politicianId),
      sentence: r.sentence,
      document_url: r.document_url,
      status: own_ ?? final ?? feed ?? 'No recorded vote',
    };
  });
  return { total: sorted.length, items };
}
