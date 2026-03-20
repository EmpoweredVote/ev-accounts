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

import { pool } from './db.js';

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
      SELECT lb.session_id, COUNT(DISTINCT lb.id)::int AS bill_count
      FROM essentials.legislative_bills lb
      LEFT JOIN essentials.legislative_bill_cosponsors lbc ON lbc.bill_id = lb.id AND lbc.politician_id = $1
      WHERE lb.sponsor_id = $1 OR lbc.politician_id = $1
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
    bill_count: Number(row.bill_count) ?? 0,
    vote_count: Number(row.vote_count) ?? 0,
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
  limit = 50
): Promise<Bill[]> {
  // Clamp limit to 1-100 range
  const clampedLimit = Math.min(100, Math.max(1, limit));

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
    WHERE b.sponsor_id = $1
       OR EXISTS (
         SELECT 1
         FROM essentials.legislative_bill_cosponsors lbc
         WHERE lbc.bill_id = b.id AND lbc.politician_id = $1
       )
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
      v.session_id
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
  }));
}
