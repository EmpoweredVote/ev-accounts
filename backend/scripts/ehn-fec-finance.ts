/**
 * ehn-fec-finance.ts — Targeted FEC finance ingestion for Eleanor Holmes Norton.
 *
 * Populates `essentials.politicians.finance_summary` for EHN (DC non-voting delegate)
 * using the FEC API. Single-politician script — does NOT process the full federal roster.
 *
 * Usage: npx tsx backend/scripts/ehn-fec-finance.ts
 *
 * Requires environment variables (from backend/.env):
 *   DATABASE_URL   — PostgreSQL connection string
 *   FEC_API_KEY    — FEC API key (register at api.data.gov/signup/)
 *
 * Crosswalk strategy:
 *   Fetches congress-legislators YAML (unitedstates/congress-legislators), finds the
 *   entry with id.bioguide === EHN_BIOGUIDE_ID ('N000147'), and extracts the H-prefix
 *   FEC candidate ID.
 *
 * FEC API calls:
 *   1. GET /v1/candidates/search/?candidate_id=X  -> committee_id
 *      Fallback: GET /v1/candidate/{id}/committees/?per_page=5 (delegates may lack principal_committees)
 *   2. GET /v1/candidates/totals/?candidate_id=X&cycle=2026 -> total_raised (receipts)
 *   3. GET /v1/schedules/schedule_a/by_employer/?committee_id=Y&cycle=2026 -> top donors
 *
 * Rate limit: 1500ms sleep before every FEC API call.
 */

import 'dotenv/config';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const EHN_POLITICIAN_UUID = '4dbc8de1-9984-42a5-b2aa-5445bf0619b9';
const EHN_BIOGUIDE_ID = 'N000147';

const SLEEP_BETWEEN_FEC_CALLS_MS = 1500; // stay well under 1000 req/hr
const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
const LEGISLATORS_YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';

const FEC_BASE = 'https://api.open.fec.gov/v1';
const FEC_SEARCH_URL = `${FEC_BASE}/candidates/search/`;
const FEC_TOTALS_URL = `${FEC_BASE}/candidates/totals/`;
const FEC_BY_EMPLOYER_URL = `${FEC_BASE}/schedules/schedule_a/by_employer/`;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface FecEmployerRow {
  committee_id: string;
  employer: string | null;
  total: number;
  count: number;
  cycle: number;
}

interface FinanceSummary {
  /** Omitted entirely when FEC has no totals row — absent means unknown, never $0. */
  total_raised?: number;
  top_donors: Array<{ employer: string; amount: number; count: number }>;
  cycle: string;
  source: 'FEC';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// YAML crosswalk — EHN-specific lookup
// ---------------------------------------------------------------------------

/**
 * Resolves EHN's FEC candidate ID from the congress-legislators YAML.
 * Finds the entry with id.bioguide === 'N000147' and returns the H-prefix FEC ID.
 * Throws if not found.
 */
async function resolveEhnFecId(): Promise<string> {
  console.log('[ehn-fec-finance] Fetching congress-legislators YAML from GitHub...');
  const resp = await fetch(LEGISLATORS_YAML_URL, {
    signal: AbortSignal.timeout(60_000),
  });
  if (!resp.ok) {
    throw new Error(`Failed to fetch legislators-current.yaml: HTTP ${resp.status}`);
  }
  const legislators = yamlLoad(await resp.text()) as Array<{
    id: { bioguide: string; fec?: string[] };
    terms: Array<{ type: string }>;
  }>;
  const leg = legislators.find(l => l.id.bioguide === EHN_BIOGUIDE_ID);
  if (!leg?.id.fec?.length) {
    throw new Error(`No FEC ID found in congress-legislators for bioguide_id ${EHN_BIOGUIDE_ID}`);
  }
  // EHN is a House delegate — prefer H-prefix FEC ID
  return leg.id.fec.find(id => id.startsWith('H')) ?? leg.id.fec[0];
}

// ---------------------------------------------------------------------------
// FEC API calls
// ---------------------------------------------------------------------------

/**
 * Step 1: Fetches the principal committee ID from candidates/search.
 * Returns null if principal_committees is empty (delegates sometimes have none).
 */
async function fetchCommitteeId(fecCandidateId: string, apiKey: string): Promise<string | null> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    per_page: '1',
  });
  const resp = await fetch(`${FEC_SEARCH_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC candidates/search HTTP ${resp.status} for ${fecCandidateId}`);
  }
  const data = (await resp.json()) as {
    results: Array<{ principal_committees: Array<{ committee_id: string }> }>;
  };
  return data.results[0]?.principal_committees?.[0]?.committee_id ?? null;
}

/**
 * Step 1 fallback: GET /v1/candidate/{id}/committees/?per_page=5
 * Returns all committees regardless of cycle — for delegates who lack principal_committees
 * in the candidates/search response.
 */
async function fetchCommitteeIdFallback(fecCandidateId: string, apiKey: string): Promise<string | null> {
  const params = new URLSearchParams({ api_key: apiKey, per_page: '5' });
  const resp = await fetch(
    `${FEC_BASE}/candidate/${fecCandidateId}/committees/?${params}`,
    { signal: AbortSignal.timeout(30_000) },
  );
  if (!resp.ok) return null;
  const data = (await resp.json()) as { results: Array<{ committee_id: string }> };
  return data.results[0]?.committee_id ?? null;
}

/**
 * Step 2: Fetches total raised (receipts) for the FEC candidate in the given cycle.
 *
 * Returns null — NOT 0 — when FEC has no totals row for this candidate+cycle.
 * "Unknown" and "raised nothing" must not collapse onto the same value.
 *
 * ⚠ election_full=false is REQUIRED; it defaults to TRUE, which asks for the full
 * ELECTION cycle rather than the two-year period. A member not on the 2026 ballot
 * has no 2026 election cycle, so the call returns zero results and the old `?? 0`
 * recorded that absence as a real $0. See run-fec-finance-summary.ts for the same
 * fix and migration 1657 for the 65 rows it silently zeroed.
 */
async function fetchTotalRaised(fecCandidateId: string, apiKey: string): Promise<number | null> {
  const params = new URLSearchParams({
    api_key: apiKey,
    candidate_id: fecCandidateId,
    cycle: FEC_CYCLE,
    election_full: 'false',
    per_page: '1',
  });
  const resp = await fetch(`${FEC_TOTALS_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC candidates/totals HTTP ${resp.status} for ${fecCandidateId}`);
  }
  const data = (await resp.json()) as { results?: Array<{ receipts?: unknown }> };
  const row = data.results?.[0];
  if (!row || row.receipts == null) return null;
  const receipts = Number(row.receipts); // always coerce — never store raw string
  return Number.isFinite(receipts) ? receipts : null;
}

/**
 * Step 3: Fetches top donors by employer for the FEC committee.
 * Filters out null/empty employer strings. Caps at TOP_DONORS_LIMIT entries.
 */
async function fetchTopDonorsByEmployer(
  committeeId: string,
  apiKey: string,
): Promise<Array<{ employer: string; amount: number; count: number }>> {
  const params = new URLSearchParams({
    api_key: apiKey,
    committee_id: committeeId,
    cycle: FEC_CYCLE,
    per_page: String(TOP_DONORS_LIMIT + 5), // fetch extra to account for null filtering
    sort: '-total',
  });
  const resp = await fetch(`${FEC_BY_EMPLOYER_URL}?${params}`, {
    signal: AbortSignal.timeout(30_000),
  });
  if (!resp.ok) {
    throw new Error(`FEC schedule_a/by_employer HTTP ${resp.status} for ${committeeId}`);
  }
  const data = (await resp.json()) as { results: FecEmployerRow[] };
  const rows = data.results ?? [];
  return rows
    .filter((r): r is FecEmployerRow & { employer: string } =>
      r.employer != null && r.employer.trim() !== '',
    )
    .slice(0, TOP_DONORS_LIMIT)
    .map(r => ({
      employer: r.employer,
      amount: Number(r.total),
      count: Number(r.count),
    }));
}

/**
 * Writes the finance_summary JSONB to essentials.politicians for EHN.
 * Uses parameterized UPDATE with explicit ::jsonb cast — never string concatenation.
 */
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  const result = await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
  if (result.rowCount === 0) {
    throw new Error(
      `UPDATE matched 0 rows — politician UUID ${politicianId} not found in essentials.politicians`,
    );
  }
}

// ---------------------------------------------------------------------------
// Main orchestration
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  // Env guards — both must be present before any I/O
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set. Register at https://api.data.gov/signup/');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  const apiKey = process.env.FEC_API_KEY;
  console.log(`[ehn-fec-finance] FEC API key: ${apiKey.slice(0, 8)}...`);
  console.log('[ehn-fec-finance] EHN FEC finance ingestion');
  console.log(`[ehn-fec-finance] Politician UUID: ${EHN_POLITICIAN_UUID}`);
  console.log(`[ehn-fec-finance] Bioguide ID: ${EHN_BIOGUIDE_ID}`);
  console.log(`[ehn-fec-finance] Cycle: ${FEC_CYCLE}`);

  // Resolve FEC candidate ID via YAML crosswalk
  const fecId = await resolveEhnFecId();
  console.log(`[ehn-fec-finance] FEC candidate ID: ${fecId}`);

  // Step 1: Get committee ID (with fallback for delegates)
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  let committeeId = await fetchCommitteeId(fecId, apiKey);
  if (!committeeId) {
    console.log('[ehn-fec-finance] principal_committees empty — trying fallback endpoint...');
    await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
    committeeId = await fetchCommitteeIdFallback(fecId, apiKey);
  }
  if (!committeeId) {
    throw new Error(`No committee found for FEC candidate ID ${fecId}`);
  }
  console.log(`[ehn-fec-finance] Committee ID: ${committeeId}`);

  // Step 2: Get total raised
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  const totalRaised = await fetchTotalRaised(fecId, apiKey);
  if (totalRaised === null) {
    console.warn(
      `[ehn-fec-finance] FEC has no ${FEC_CYCLE} totals row for ${fecId} — ` +
        `writing finance_summary WITHOUT total_raised (unknown, not $0).`,
    );
  } else {
    console.log(`[ehn-fec-finance] Total raised: $${totalRaised.toLocaleString()}`);
  }

  // Step 3: Get top donors by employer
  await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
  const topDonors = await fetchTopDonorsByEmployer(committeeId, apiKey);
  console.log(`[ehn-fec-finance] Top donors: ${topDonors.length} entries`);

  // Build finance_summary — never spread raw FEC response.
  // total_raised is omitted rather than zeroed when FEC has no totals row.
  const summary: FinanceSummary = {
    ...(totalRaised !== null ? { total_raised: totalRaised } : {}),
    top_donors: topDonors,
    cycle: FEC_CYCLE,
    source: 'FEC',
  };

  // Write to DB
  await updateFinanceSummary(EHN_POLITICIAN_UUID, summary);
  console.log('[ehn-fec-finance] finance_summary written.');
  console.log(JSON.stringify(summary, null, 2));

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[ehn-fec-finance] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
