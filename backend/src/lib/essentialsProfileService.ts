/**
 * essentialsProfileService — profile detail endpoints (endorsements, elections,
 * judicial records) that mirror the Go server's response shapes.
 *
 * All queries use pool.query() — essentials schema is NOT in the PostgREST
 * exposed schema list.
 */

import { pool } from './db.js';

// ---------------------------------------------------------------------------
// Endorsements
// ---------------------------------------------------------------------------

export interface Endorsement {
  endorser_string: string;
  recommendation: string;
  status: string;
  election_date: string | null;
  organization_name: string;
  organization_description: string;
  organization_logo_url: string;
  organization_issue: string;
}

/**
 * Fetch endorsements for a politician, joined with endorser organizations.
 * Matches Go server /politician/{id}/endorsements response shape.
 */
export async function getEndorsementsByPolitician(
  politicianId: string
): Promise<Endorsement[]> {
  const queryText = `
    SELECT
      COALESCE(e.endorser_string, '') AS endorser_string,
      COALESCE(e.recommendation, '') AS recommendation,
      COALESCE(e.status, '') AS status,
      e.election_date,
      COALESCE(org.name, '') AS organization_name,
      COALESCE(org.description, '') AS organization_description,
      COALESCE(org.logo_url, '') AS organization_logo_url,
      COALESCE(org.issue, '') AS organization_issue
    FROM essentials.endorsements e
    LEFT JOIN essentials.endorser_organizations org ON org.id = e.organization_id
    WHERE e.politician_id = $1
    ORDER BY e.election_date DESC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    endorser_string: row.endorser_string ?? '',
    recommendation: row.recommendation ?? '',
    status: row.status ?? '',
    election_date: row.election_date ? (row.election_date as Date).toISOString().split('T')[0] : null,
    organization_name: row.organization_name ?? '',
    organization_description: row.organization_description ?? '',
    organization_logo_url: row.organization_logo_url ?? '',
    organization_issue: row.organization_issue ?? '',
  }));
}

// ---------------------------------------------------------------------------
// Elections
// ---------------------------------------------------------------------------

export interface ElectionRecord {
  election_name: string;
  election_date: string | null;
  position_name: string;
  result: string;
  withdrawn: boolean;
  party_name: string;
  is_primary: boolean;
  is_runoff: boolean;
  is_unexpired_term: boolean;
  is_active: boolean;
}

/**
 * Fetch election history for a politician.
 * Matches Go server /politician/{id}/elections response shape.
 */
export async function getElectionsByPolitician(
  politicianId: string
): Promise<ElectionRecord[]> {
  const queryText = `
    SELECT
      COALESCE(election_name, '') AS election_name,
      election_date,
      COALESCE(position_name, '') AS position_name,
      COALESCE(result, '') AS result,
      COALESCE(withdrawn, false) AS withdrawn,
      COALESCE(party_name, '') AS party_name,
      COALESCE(is_primary, false) AS is_primary,
      COALESCE(is_runoff, false) AS is_runoff,
      COALESCE(is_unexpired_term, false) AS is_unexpired_term,
      COALESCE(is_active, false) AS is_active
    FROM essentials.election_records
    WHERE politician_id = $1
    ORDER BY election_date DESC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    election_name: row.election_name ?? '',
    election_date: row.election_date ? (row.election_date as Date).toISOString().split('T')[0] : null,
    position_name: row.position_name ?? '',
    result: row.result ?? '',
    withdrawn: row.withdrawn ?? false,
    party_name: row.party_name ?? '',
    is_primary: row.is_primary ?? false,
    is_runoff: row.is_runoff ?? false,
    is_unexpired_term: row.is_unexpired_term ?? false,
    is_active: row.is_active ?? false,
  }));
}

// ---------------------------------------------------------------------------
// Judicial Record
// ---------------------------------------------------------------------------

export interface JudicialRecordResult {
  judge_detail: {
    appointed_by: string;
    appointing_president_party: string;
    confirmation_vote: string;
    court_role: string;
    election_type: string;
    areas_of_focus: string[];
    date_seated: string | null;
  } | null;
  evaluations: Array<{
    source: string;
    rating: string;
    rating_date: string | null;
    source_url: string;
  }>;
  metrics: Array<{
    metric_type: string;
    value: number | null;
    context_label: string;
    comparison_baseline: string;
    time_period: string;
  }>;
  disciplinary_records: Array<{
    record_type: string;
    record_date: string | null;
    description: string;
    source_url: string;
  }>;
}

/**
 * Fetch judicial record for a politician (judge).
 * Matches Go server /politician/{id}/judicial-record response shape.
 * Returns partial data on individual query failures (non-fatal).
 */
export async function getJudicialRecord(
  politicianId: string
): Promise<JudicialRecordResult> {
  const result: JudicialRecordResult = {
    judge_detail: null,
    evaluations: [],
    metrics: [],
    disciplinary_records: [],
  };

  // Judge details
  try {
    const { rows } = await pool.query(
      `SELECT appointed_by, appointing_president_party, confirmation_vote,
              court_role, election_type, areas_of_focus, date_seated
       FROM essentials.judge_details WHERE politician_id = $1`,
      [politicianId]
    );
    if (rows.length > 0) {
      const r = rows[0];
      result.judge_detail = {
        appointed_by: r.appointed_by ?? '',
        appointing_president_party: r.appointing_president_party ?? '',
        confirmation_vote: r.confirmation_vote ?? '',
        court_role: r.court_role ?? '',
        election_type: r.election_type ?? '',
        areas_of_focus: Array.isArray(r.areas_of_focus) ? r.areas_of_focus : [],
        date_seated: r.date_seated ? (r.date_seated as Date).toISOString().split('T')[0] : null,
      };
    }
  } catch (err) {
    console.warn('[getJudicialRecord] judge_details error:', err);
  }

  // Evaluations
  try {
    const { rows } = await pool.query(
      `SELECT source, rating, rating_date, source_url
       FROM essentials.judicial_evaluations
       WHERE politician_id = $1 ORDER BY rating_date DESC`,
      [politicianId]
    );
    result.evaluations = rows.map((r) => ({
      source: r.source ?? '',
      rating: r.rating ?? '',
      rating_date: r.rating_date ? (r.rating_date as Date).toISOString().split('T')[0] : null,
      source_url: r.source_url ?? '',
    }));
  } catch (err) {
    console.warn('[getJudicialRecord] evaluations error:', err);
  }

  // Metrics
  try {
    const { rows } = await pool.query(
      `SELECT metric_type, value, context_label, comparison_baseline, time_period
       FROM essentials.judicial_metrics WHERE politician_id = $1`,
      [politicianId]
    );
    result.metrics = rows.map((r) => ({
      metric_type: r.metric_type ?? '',
      value: r.value != null ? Number(r.value) : null,
      context_label: r.context_label ?? '',
      comparison_baseline: r.comparison_baseline ?? '',
      time_period: r.time_period ?? '',
    }));
  } catch (err) {
    console.warn('[getJudicialRecord] metrics error:', err);
  }

  // Disciplinary records
  try {
    const { rows } = await pool.query(
      `SELECT record_type, record_date, description, source_url
       FROM essentials.judicial_disciplinary_records
       WHERE politician_id = $1 ORDER BY record_date DESC`,
      [politicianId]
    );
    result.disciplinary_records = rows.map((r) => ({
      record_type: r.record_type ?? '',
      record_date: r.record_date ? (r.record_date as Date).toISOString().split('T')[0] : null,
      description: r.description ?? '',
      source_url: r.source_url ?? '',
    }));
  } catch (err) {
    console.warn('[getJudicialRecord] disciplinary_records error:', err);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Stances
// ---------------------------------------------------------------------------

export interface Stance {
  statement: string;
  reference_url: string;
  election_date: string;
  issue_name: string;
  issue_key: string;
  issue_expanded: string;
  parent_issue_name: string;
}

/**
 * Fetch policy stances for a politician from BallotReady data.
 * Matches Go server /politician/{id}/stances response shape.
 *
 * Joins politician_stances → issues (with optional parent issue for sub-topics).
 * Ordered by election_date DESC.
 */
export async function getStancesByPolitician(
  politicianId: string
): Promise<Stance[]> {
  const queryText = `
    SELECT
      COALESCE(ps.statement, '') AS statement,
      COALESCE(ps.reference_url, '') AS reference_url,
      COALESCE(ps.election_date, '') AS election_date,
      COALESCE(i.name, '') AS issue_name,
      COALESCE(i.key, '') AS issue_key,
      COALESCE(i.expanded_text, '') AS issue_expanded,
      COALESCE(parent.name, '') AS parent_issue_name
    FROM essentials.politician_stances ps
    LEFT JOIN essentials.issues i ON i.id = ps.issue_id
    LEFT JOIN essentials.issues parent ON parent.id = i.parent_id
    WHERE ps.politician_id = $1
    ORDER BY ps.election_date DESC
  `;

  const { rows } = await pool.query(queryText, [politicianId]);

  return rows.map((row) => ({
    statement: row.statement ?? '',
    reference_url: row.reference_url ?? '',
    election_date: row.election_date ?? '',
    issue_name: row.issue_name ?? '',
    issue_key: row.issue_key ?? '',
    issue_expanded: row.issue_expanded ?? '',
    parent_issue_name: row.parent_issue_name ?? '',
  }));
}
