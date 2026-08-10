/**
 * run-fec-finance-summary.ts — standalone FEC finance summary ingestion script.
 *
 * Populates `essentials.politicians.finance_summary` for all federal politicians
 * (senators + declared 2026 House candidates) using the FEC API.
 *
 * Usage: tsx scripts/run-fec-finance-summary.ts
 *
 * Requires environment variables:
 *   DATABASE_URL   — PostgreSQL connection string (in .env)
 *   FEC_API_KEY    — FEC API key (register at api.data.gov/signup/ for 1000 req/hr limit)
 *
 * Crosswalk strategy (two-path lookup):
 *   Path 2 (primary): transparent_motivations.politician_sources WHERE source_system LIKE 'fec%'
 *                     AND research_status = 'confirmed'
 *   Path 1 (fallback): bioguide_id -> congress-legislators YAML -> id.fec[] filtered by chamber
 *                     (YAML source used: theunitedstates.io JSON returned 410 Gone)
 *
 * FEC API calls per politician:
 *   1. GET /v1/candidates/search/?candidate_id=X  -> committee_id
 *   2. GET /v1/candidates/totals/?candidate_id=X&cycle=2026 -> receipts
 *   3. GET /v1/schedules/schedule_a/by_employer/?committee_id=Y&cycle=2026 -> top donors
 *
 * Rate limit: 1500ms sleep between every FEC API call (~430 calls total, ~10 min runtime).
 */

import 'dotenv/config';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const SLEEP_BETWEEN_FEC_CALLS_MS = 1500; // stay well under 1000 req/hr (matches fecResearch.ts)
const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
// Note: theunitedstates.io/congress-legislators/legislators-current.json returned HTTP 410 (Gone) on 2026-06-04.
// Using YAML source from unitedstates/congress-legislators GitHub repo instead (same authoritative data).
// js-yaml is already in backend/package.json (^4.1.1) — no new dependency.
// RESEARCH.md fallback path A1: "Fall back to YAML + js-yaml package; same data, extra parsing step"
const LEGISLATORS_YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';

const FEC_BASE = 'https://api.open.fec.gov/v1';
const FEC_SEARCH_URL = `${FEC_BASE}/candidates/search/`;
const FEC_TOTALS_URL = `${FEC_BASE}/candidates/totals/`;
const FEC_BY_EMPLOYER_URL = `${FEC_BASE}/schedules/schedule_a/by_employer/`;

// ---------------------------------------------------------------------------
// Types (local only — not exported)
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

interface Legislator {
  id: { bioguide: string; fec?: string[] };
  name: { first: string; last: string; official_full?: string };
  terms: Array<{ type: 'sen' | 'rep'; start: string; end: string; state: string }>;
}

interface FederalPolitician {
  id: string;
  bioguide_id: string | null;
  full_name: string;
  chamber_short: 'S' | 'H';
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// ---------------------------------------------------------------------------
// Crosswalk builders
// ---------------------------------------------------------------------------

interface CrosswalkMaps {
  bioguideMap: Map<string, string>;
  /** Lowercase normalized full-name -> FEC ID. Covers senators without bioguide_id in our DB. */
  nameMap: Map<string, string>;
}

/**
 * Builds bioguide -> FEC candidate_id AND full-name -> FEC candidate_id maps from the
 * congress-legislators YAML source.
 *
 * Background: The theunitedstates.io JSON endpoint returned HTTP 410 Gone on 2026-06-04.
 * YAML from unitedstates/congress-legislators GitHub is the same authoritative data.
 *
 * Most Phase 73-added senators have NULL bioguide_id in the DB — the name map provides
 * a fallback so "Amy Klobuchar" in our DB can match "Amy Klobuchar" in YAML.
 *
 * Filters FEC IDs by chamber (S-prefix for senators, H-prefix for House members).
 * Per Pitfall 4: a legislator can have multiple FEC IDs across chambers — pick the chamber-correct one.
 */
async function buildCrosswalkMaps(): Promise<CrosswalkMaps> {
  console.log('[crosswalk] Fetching congress-legislators YAML from GitHub...');
  const resp = await fetch(LEGISLATORS_YAML_URL, {
    signal: AbortSignal.timeout(60_000),
  });
  if (!resp.ok) {
    throw new Error(`Failed to fetch legislators-current.yaml: HTTP ${resp.status}`);
  }
  const yamlText = await resp.text();
  const legislators = yamlLoad(yamlText) as Legislator[];
  if (!Array.isArray(legislators)) {
    throw new Error('legislators-current.yaml did not parse to an array');
  }
  const bioguideMap = new Map<string, string>();
  const nameMap = new Map<string, string>();
  for (const leg of legislators) {
    if (!leg.id.fec || leg.id.fec.length === 0) continue;
    const lastTerm = leg.terms[leg.terms.length - 1];
    if (!lastTerm) continue;
    const isSenate = lastTerm.type === 'sen';
    // Pick FEC ID matching current chamber (S-prefix for senators, H-prefix for House)
    const fecId =
      leg.id.fec.find(id => (isSenate ? id.startsWith('S') : id.startsWith('H'))) ??
      leg.id.fec[0];
    if (!fecId) continue;
    bioguideMap.set(leg.id.bioguide, fecId);
    // Also add name variants for senators and representatives without bioguide in DB
    const firstName = leg.name.first;
    const lastName = leg.name.last;
    const officialFull = leg.name.official_full;
    // Standard "First Last" format (covers most cases like "Amy Klobuchar")
    nameMap.set(`${firstName} ${lastName}`.toLowerCase(), fecId);
    // Official full name (e.g. "Bernard Sanders" for Bernie Sanders)
    if (officialFull) {
      nameMap.set(officialFull.toLowerCase(), fecId);
    }
  }
  console.log(
    `[crosswalk] Built maps: bioguide=${bioguideMap.size}, name=${nameMap.size} entries.`,
  );
  return { bioguideMap, nameMap };
}

// ---------------------------------------------------------------------------
// DB queries
// ---------------------------------------------------------------------------

/**
 * Returns all active federal politicians (senators + House members) from the DB.
 * Occupancy is resolved through essentials.office_current_holder -- essentials.offices is a SEAT
 * and holds no occupant (ADR 0002 phase 5 dropped offices.politician_id in migration 1463). The
 * view is exactly one row per office, so it cannot fan this result set out.
 *
 * The `Candidate for%` exclusion is load-bearing: candidate offices hang off the same
 * NATIONAL_UPPER / NATIONAL_LOWER districts, and without it 50 candidates join the roster of
 * sitting members -- e.g. Angie Craig under "Candidate for U.S. Senate - Minnesota" -- and their
 * campaign committees would be summarised as incumbent finances. With it: 100 senators + 434
 * representatives.
 */
async function getFederalPoliticiansFromDb(): Promise<FederalPolitician[]> {
  const sql = `
    SELECT DISTINCT
      p.id,
      p.bioguide_id,
      p.full_name,
      CASE
        WHEN d.district_type = 'NATIONAL_UPPER' THEN 'S'
        ELSE 'H'
      END AS chamber_short
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.is_active = true
      AND d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_LOWER')
      AND o.title NOT ILIKE 'Candidate for%'
    ORDER BY p.full_name
  `;
  const result = await pool.query<FederalPolitician>(sql);
  return result.rows;
}

/**
 * Path 2 crosswalk: look up confirmed FEC ID from transparent_motivations.politician_sources.
 * Returns null if no confirmed source found.
 */
async function lookupFecIdViaSources(politicianId: string): Promise<string | null> {
  const sql = `
    SELECT external_id
    FROM transparent_motivations.politician_sources
    WHERE essentials_politician_id = $1
      AND source_system LIKE 'fec%'
      AND research_status = 'confirmed'
      AND external_id IS NOT NULL
      AND external_id != ''
    ORDER BY created_at DESC
    LIMIT 1
  `;
  const result = await pool.query<{ external_id: string }>(sql, [politicianId]);
  return result.rows[0]?.external_id ?? null;
}

/**
 * Resolves FEC candidate ID using three-path lookup:
 *   Path 2 first (politician_sources confirmed rows — highest confidence)
 *   Path 1a (bioguide -> congress-legislators map, filtered by chamber prefix)
 *   Path 1b (full-name -> congress-legislators name map — for senators without bioguide_id in DB)
 * Returns null if all paths fail.
 */
async function resolveFecId(
  p: FederalPolitician,
  crosswalk: CrosswalkMaps,
): Promise<string | null> {
  // Path 2: politician_sources (primary — catches 2026 candidates already matched)
  const fromSources = await lookupFecIdViaSources(p.id);
  if (fromSources) return fromSources;

  // Path 1a: bioguide -> congress-legislators crosswalk (incumbents with bioguide in DB)
  if (p.bioguide_id && p.bioguide_id.trim() !== '') {
    const fromBioguide = crosswalk.bioguideMap.get(p.bioguide_id);
    if (fromBioguide) return fromBioguide;
  }

  // Path 1b: name-based match for senators/reps without bioguide_id in DB
  // Phase 73 inserted 100 senators without bioguide_id — this path covers them
  const fromName = crosswalk.nameMap.get(p.full_name.toLowerCase());
  if (fromName) return fromName;

  return null;
}

// ---------------------------------------------------------------------------
// FEC API calls
// ---------------------------------------------------------------------------

/**
 * Fetches the principal committee ID for an FEC candidate.
 * Required for the by_employer endpoint (committee_id, NOT candidate_id — Pitfall 2).
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
 * Fetches total raised (receipts) for an FEC candidate in the given cycle.
 *
 * Returns null — NOT 0 — when FEC has no totals row for this candidate+cycle.
 * "We don't know" and "they raised nothing" are different facts and must not
 * collapse onto the same value.
 *
 * ⚠ election_full=false is REQUIRED. It defaults to TRUE, which asks for totals
 * over a candidate's full ELECTION cycle rather than the two-year period. A
 * senator whose election_years are [2022, 2028] has no 2026 election cycle, so
 * cycle=2026 returned zero results and the old `?? 0` recorded that absence as a
 * real $0. That silently zeroed 65 sitting members — e.g. Padilla showed $0
 * against an actual $1,502,700.32, and Mark Kelly against $40,775,022.69.
 * With election_full=false the same call returns the 2025-26 period totals.
 *
 * Per Pitfall 5: always coerce to Number() — never store raw string.
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
  const receipts = Number(row.receipts);
  return Number.isFinite(receipts) ? receipts : null;
}

/**
 * Fetches top donors by employer for an FEC committee.
 * Filters out null/empty employer strings.
 * "NOT EMPLOYED" / "SELF EMPLOYED" are kept per RESEARCH.md open question #1.
 * Caps at TOP_DONORS_LIMIT entries.
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
  return data.results
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
 * Writes the finance_summary JSONB to essentials.politicians for the given politician ID.
 * Uses parameterized UPDATE with explicit ::jsonb cast.
 */
async function updateFinanceSummary(politicianId: string, summary: FinanceSummary): Promise<void> {
  await pool.query(
    `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
    [JSON.stringify(summary), politicianId],
  );
}

// ---------------------------------------------------------------------------
// Main orchestration
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  // Env guards (match run-fec-auto-match.ts pattern)
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set. Register at https://api.data.gov/signup/');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set');
    process.exit(1);
  }

  const apiKey = process.env.FEC_API_KEY;
  console.log('[run-fec-finance-summary] Starting FEC finance summary ingestion...');
  console.log(`[run-fec-finance-summary] FEC API key: ${apiKey.slice(0, 8)}...`);
  console.log(`[run-fec-finance-summary] Cycle: ${FEC_CYCLE}`);

  const startMs = Date.now();

  // Build crosswalk maps (Path 1a bioguide + Path 1b name-based)
  const crosswalk = await buildCrosswalkMaps();

  // Query federal politicians
  const politicians = await getFederalPoliticiansFromDb();
  console.log(`[run-fec-finance-summary] Found ${politicians.length} active federal politicians.`);

  // Counters
  let processed = 0;
  let succeeded = 0;
  let skipped_no_fec_id = 0;
  let errors = 0;
  const skippedNames: string[] = [];
  const errorDetails: Array<{ name: string; error: string }> = [];

  for (const p of politicians) {
    processed++;
    console.log(`\n[${processed}/${politicians.length}] ${p.full_name} (${p.chamber_short})`);

    try {
      // Resolve FEC ID
      const fecId = await resolveFecId(p, crosswalk);
      if (!fecId) {
        console.warn(
          `  [SKIP] No FEC ID found for ${p.full_name} (politician_sources + congress-legislators both empty)`,
        );
        skipped_no_fec_id++;
        skippedNames.push(p.full_name);
        continue;
      }
      console.log(`  FEC ID: ${fecId}`);

      // Step 1: Get committee ID
      await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
      const committeeId = await fetchCommitteeId(fecId, apiKey);
      if (!committeeId) {
        console.warn(`  [SKIP] No principal committee found for ${p.full_name} (${fecId})`);
        skipped_no_fec_id++;
        skippedNames.push(`${p.full_name} (no committee)`);
        continue;
      }
      console.log(`  Committee: ${committeeId}`);

      // Step 2: Get total raised
      await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
      const totalRaised = await fetchTotalRaised(fecId, apiKey);
      if (totalRaised === null) {
        console.warn(
          `  [WARN] FEC has no ${FEC_CYCLE} totals row for ${p.full_name} (${fecId}) — ` +
            `writing finance_summary WITHOUT total_raised (unknown, not $0).`,
        );
      } else {
        console.log(`  Total raised: $${totalRaised.toLocaleString()}`);
      }

      // Step 3: Get top donors by employer
      await sleep(SLEEP_BETWEEN_FEC_CALLS_MS);
      const topDonors = await fetchTopDonorsByEmployer(committeeId, apiKey);
      console.log(`  Top donors: ${topDonors.length} employer entries`);

      // Build strict finance_summary object (never spread raw FEC response — T-90-04)
      // total_raised is omitted rather than zeroed when FEC has no totals row.
      const summary: FinanceSummary = {
        ...(totalRaised !== null ? { total_raised: totalRaised } : {}),
        top_donors: topDonors,
        cycle: FEC_CYCLE,
        source: 'FEC',
      };

      // Write to DB
      await updateFinanceSummary(p.id, summary);
      console.log(`  [OK] finance_summary written.`);
      succeeded++;
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err);
      console.error(`  [ERROR] ${p.full_name}: ${errMsg}`);
      errors++;
      errorDetails.push({ name: p.full_name, error: errMsg });
    }
  }

  const durationSec = ((Date.now() - startMs) / 1000).toFixed(1);

  const runSummary = {
    processed,
    succeeded,
    skipped_no_fec_id,
    errors,
    durationSec: Number(durationSec),
  };

  console.log('\n=== FEC FINANCE SUMMARY RUN COMPLETE ===');
  console.log(JSON.stringify(runSummary));

  if (skippedNames.length > 0) {
    console.log('\n--- Skipped politicians (no FEC ID) ---');
    for (const name of skippedNames) {
      console.log(`  - ${name}`);
    }
  }

  if (errorDetails.length > 0) {
    console.log('\n--- Errored politicians ---');
    for (const e of errorDetails) {
      console.log(`  - ${e.name}: ${e.error}`);
    }
  }

  // Clean pool shutdown
  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[run-fec-finance-summary] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore pool close errors on fatal path */ }
  process.exit(1);
});
