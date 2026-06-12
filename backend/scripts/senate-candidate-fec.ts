/**
 * senate-candidate-fec.ts
 *
 * FEC finance summary lookup for 2026 Senate challengers not in the
 * congress-legislators YAML (non-incumbents). Uses the FEC candidates API
 * with office=S + state filtering to resolve FEC candidate IDs, then
 * fetches finance data using the same three-step pattern as
 * fix-fec-name-mismatches.ts.
 *
 * Also writes not_applicable politician_sources rows for DC Shadow Senators
 * (Paul Strauss and Ankit Jain) who have no FEC presence.
 *
 * Rate limit: 2000ms between every FEC API call -- stays well under 1000 req/hr.
 *
 * Usage: tsx scripts/senate-candidate-fec.ts [--dry-run]
 *   --dry-run  Show matches without writing to DB or calling FEC API
 */

import 'dotenv/config';
import { pool } from '../src/lib/db.js';

const DRY_RUN = process.argv.includes('--dry-run');
const SLEEP_MS = 2000;
const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
const FEC_BASE = 'https://api.open.fec.gov/v1';

// ---------------------------------------------------------------------------
// FIPS -> state abbreviation map (inverted from STATE_ABBR_TO_FIPS in treasuryService.ts)
// NOTE: essentials.districts.state may store either FIPS codes (e.g. '26') or 2-letter
// abbreviations (e.g. 'MI'). resolveStateAbbr() handles both cases.
// ---------------------------------------------------------------------------
const FIPS_TO_ABBR: Record<string, string> = {
  '01': 'AL', '02': 'AK', '04': 'AZ', '05': 'AR', '06': 'CA', '08': 'CO',
  '09': 'CT', '10': 'DE', '11': 'DC', '12': 'FL', '13': 'GA', '15': 'HI',
  '16': 'ID', '17': 'IL', '18': 'IN', '19': 'IA', '20': 'KS', '21': 'KY',
  '22': 'LA', '23': 'ME', '24': 'MD', '25': 'MA', '26': 'MI', '27': 'MN',
  '28': 'MS', '29': 'MO', '30': 'MT', '31': 'NE', '32': 'NV', '33': 'NH',
  '34': 'NJ', '35': 'NM', '36': 'NY', '37': 'NC', '38': 'ND', '39': 'OH',
  '40': 'OK', '41': 'OR', '42': 'PA', '44': 'RI', '45': 'SC', '46': 'SD',
  '47': 'TN', '48': 'TX', '49': 'UT', '50': 'VT', '51': 'VA', '53': 'WA',
  '54': 'WV', '55': 'WI', '56': 'WY',
};

/**
 * Resolve a 2-letter uppercase state abbreviation from either:
 *   - a 2-letter abbreviation (e.g. 'MI', 'AK') -- returned uppercased as-is
 *   - a FIPS code string (e.g. '26', '02') -- mapped via FIPS_TO_ABBR
 * Returns null if unrecognised.
 */
function resolveStateAbbr(stateVal: string): string | null {
  if (!stateVal) return null;
  const upper = stateVal.toUpperCase();
  // Already a 2-letter abbreviation
  if (/^[A-Z]{2}$/.test(upper)) return upper;
  // FIPS code (1 or 2 digits)
  const padded = stateVal.padStart(2, '0');
  return FIPS_TO_ABBR[padded] ?? null;
}

// ---------------------------------------------------------------------------
// DC Shadow Senators -- permanent not_applicable entries
// ---------------------------------------------------------------------------
const NOT_APPLICABLE = new Set<string>(['paul strauss', 'ankit jain']);

const NOT_APPLICABLE_NOTE =
  'DC Shadow Senators are not registered candidates with the FEC and do not file campaign finance reports. This seat has no FEC candidate ID.';

// ---------------------------------------------------------------------------
// Name normalization helpers (inlined from fecResearch.ts -- do NOT import)
// ---------------------------------------------------------------------------

// Unicode escape sequences to avoid encoding issues with accented chars
const ACCENT_MAP: Record<string, string> = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c',
};

function normalize(s: string): string {
  return s
    .toLowerCase()
    .split('')
    .map(c => ACCENT_MAP[c] ?? c)
    .join('')
    .replace(/[^a-z\s]/g, '')
    .trim();
}

/** Parse FEC-format name "LAST, FIRST MIDDLE" -> { first, last } */
function parseFecName(fecName: string): { first: string; last: string } {
  const commaIdx = fecName.indexOf(',');
  if (commaIdx === -1) {
    return { first: '', last: normalize(fecName) };
  }
  const last = normalize(fecName.slice(0, commaIdx).trim());
  const firstPart = fecName.slice(commaIdx + 1).trim().split(/\s+/)[0] ?? '';
  const first = normalize(firstPart);
  return { first, last };
}

/** Parse DB full_name "First [Middle] Last" -> { first, last } */
function parseDbName(fullName: string): { first: string; last: string } {
  const tokens = normalize(fullName).split(/\s+/).filter(Boolean);
  if (tokens.length === 0) return { first: '', last: '' };
  if (tokens.length === 1) return { first: '', last: tokens[0]! };
  return { first: tokens[0]!, last: tokens[tokens.length - 1]! };
}

/** Score a DB name against a FEC candidate name. Returns 0-1. */
function scoreMatch(dbFullName: string, fecName: string): number {
  const db = parseDbName(dbFullName);
  const fec = parseFecName(fecName);

  if (!db.last || !fec.last) return 0;

  const lastMatch = db.last === fec.last;
  if (!lastMatch) return 0;

  if (db.first && fec.first) {
    if (db.first === fec.first) return 0.9;
    if (fec.first.startsWith(db.first) || db.first.startsWith(fec.first)) return 0.85;
  }

  return 0.6;
}

// ---------------------------------------------------------------------------
// Utility
// ---------------------------------------------------------------------------

function sleep(ms: number) {
  return new Promise<void>(r => setTimeout(r, ms));
}

// ---------------------------------------------------------------------------
// FEC API -- candidate search
// ---------------------------------------------------------------------------

interface FecCandidateResult {
  candidate_id: string;
  name: string;
  state: string;
  office: string;
}

async function candidateSearch(
  lastName: string,
  stateAbbr: string,
  apiKey: string,
): Promise<FecCandidateResult[]> {
  await sleep(SLEEP_MS);
  const url = `${FEC_BASE}/candidates/?api_key=${apiKey}&q=${encodeURIComponent(lastName)}&office=S&state=${stateAbbr}&per_page=20`;
  const resp = await fetch(url, { signal: AbortSignal.timeout(30_000) });
  if (!resp.ok) throw new Error(`FEC candidates search HTTP ${resp.status} for "${lastName}" ${stateAbbr}`);
  const data = await resp.json() as { results?: FecCandidateResult[] };
  return data.results ?? [];
}

// ---------------------------------------------------------------------------
// FEC API -- fetch finance data (copied verbatim from fix-fec-name-mismatches.ts)
// ---------------------------------------------------------------------------

async function fetchFecData(fecId: string, apiKey: string): Promise<object | null> {
  // Step 1: get committee_id
  const searchUrl = `${FEC_BASE}/candidates/search/?api_key=${apiKey}&candidate_id=${fecId}&per_page=1`;
  await sleep(SLEEP_MS);
  const searchResp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!searchResp.ok) throw new Error(`FEC search HTTP ${searchResp.status}`);
  // NOTE: the /candidates/search/ endpoint returns principal_committees[].committee_id (not .id)
  const searchData = await searchResp.json() as {
    results?: Array<{ principal_committees?: Array<{ committee_id: string }> }>
  };
  let committeeId: string | undefined =
    searchData.results?.[0]?.principal_committees?.[0]?.committee_id;

  if (!committeeId) {
    await sleep(SLEEP_MS);
    const fbUrl = `${FEC_BASE}/candidate/${fecId}/committees/?api_key=${apiKey}&per_page=5`;
    const fbResp = await fetch(fbUrl, { signal: AbortSignal.timeout(30_000) });
    if (fbResp.ok) {
      const fbData = await fbResp.json() as { results?: Array<{ committee_id: string }> };
      committeeId = fbData.results?.[0]?.committee_id ?? undefined;
    }
  }
  if (!committeeId) {
    console.log(`  [skip] No committee for ${fecId}`);
    return null;
  }

  // Step 2: total raised (multi-cycle fallback for non-2026-ballot candidates)
  let totalRaised = 0;
  let usedCycle = FEC_CYCLE;
  for (const cycle of [FEC_CYCLE, '2024', '2022']) {
    const totalsUrl = `${FEC_BASE}/candidates/totals/?api_key=${apiKey}&candidate_id=${fecId}&cycle=${cycle}&per_page=1`;
    await sleep(SLEEP_MS);
    const totalsResp = await fetch(totalsUrl, { signal: AbortSignal.timeout(30_000) });
    if (!totalsResp.ok) throw new Error(`FEC totals HTTP ${totalsResp.status}`);
    const totalsData = await totalsResp.json() as { results?: Array<{ receipts?: number }> };
    const receipts = totalsData.results?.[0]?.receipts ?? 0;
    if (receipts > 0) { totalRaised = receipts; usedCycle = cycle; break; }
  }

  // Step 3: top donors
  const donorsUrl = `${FEC_BASE}/schedules/schedule_a/by_employer/?api_key=${apiKey}&committee_id=${committeeId}&cycle=${usedCycle}&per_page=${TOP_DONORS_LIMIT}&sort=-total`;
  await sleep(SLEEP_MS);
  const donorsResp = await fetch(donorsUrl, { signal: AbortSignal.timeout(30_000) });
  if (!donorsResp.ok) throw new Error(`FEC donors HTTP ${donorsResp.status}`);
  const donorsData = await donorsResp.json() as {
    results?: Array<{ employer: string; total: number; count: number }>
  };
  const topDonors = (donorsData.results ?? []).map(r => ({
    employer: r.employer,
    amount: r.total,
    count: r.count,
  }));

  return { total_raised: totalRaised, top_donors: topDonors, cycle: usedCycle, source: 'FEC' };
}

// ---------------------------------------------------------------------------
// DB row type
// ---------------------------------------------------------------------------

interface SenateCandidate {
  id: string;
  full_name: string;
  fips_code: string;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY not set');

  console.log(DRY_RUN ? '[dry-run] No DB writes or FEC calls' : '[live] Writing to DB');

  // Query NATIONAL_UPPER politicians with NULL finance_summary
  const { rows } = await pool.query<SenateCandidate>(`
    SELECT DISTINCT p.id, p.full_name, d.state AS fips_code
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'NATIONAL_UPPER'
      AND p.is_active = true
      AND p.finance_summary IS NULL
    ORDER BY p.full_name
  `);

  console.log(`Found ${rows.length} NATIONAL_UPPER politicians with NULL finance_summary`);

  const stats = {
    confirmed: 0,
    written: 0,
    no_committee: 0,
    no_match: 0,
    not_applicable: 0,
    error: 0,
  };

  for (const pol of rows) {
    const nameLower = pol.full_name.toLowerCase();

    // --- not_applicable (DC Shadow Senators) ---
    if (NOT_APPLICABLE.has(nameLower)) {
      console.log(`NOT_APPLICABLE  ${pol.full_name}`);
      if (!DRY_RUN) {
        await pool.query(
          `DELETE FROM transparent_motivations.politician_sources
           WHERE essentials_politician_id = $1 AND source_system = 'fec_senate'`,
          [pol.id],
        );
        await pool.query(
          `INSERT INTO transparent_motivations.politician_sources
             (essentials_politician_id, source_system, external_id, research_status, source_type, notes)
           VALUES ($1, 'fec_senate', '', 'not_applicable', 'candidate_committee', $2)`,
          [pol.id, NOT_APPLICABLE_NOTE],
        );
      }
      stats.not_applicable++;
      continue;
    }

    // --- derive state abbreviation (d.state may be abbreviation OR FIPS code) ---
    const stateAbbr = resolveStateAbbr(pol.fips_code);
    if (!stateAbbr) {
      console.log(`SKIP  ${pol.full_name} -- unknown state value '${pol.fips_code}'`);
      continue;
    }

    // --- FEC candidate search (skip in dry-run -- no FEC calls) ---
    const { last: lastName } = parseDbName(pol.full_name);

    let results: FecCandidateResult[] = [];
    if (!DRY_RUN) {
      try {
        results = await candidateSearch(lastName, stateAbbr, apiKey);
      } catch (err) {
        console.error(`  [ERR] candidateSearch for ${pol.full_name}: ${(err as Error).message}`);
        stats.error++;
        continue;
      }
    }

    // --- score candidates ---
    let bestScore = 0;
    let bestCandidate: FecCandidateResult | null = null;

    for (const candidate of results) {
      const score = scoreMatch(pol.full_name, candidate.name);
      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    // --- no match (or dry-run where results is always empty) ---
    if (!bestCandidate || bestScore < 0.8) {
      const top3 = results
        .map(c => ({
          candidate_id: c.candidate_id,
          name: c.name,
          score: scoreMatch(pol.full_name, c.name),
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, 3);

      const notesJson = top3.length > 0 ? JSON.stringify(top3) : 'No candidates found';
      const scoreStr = bestCandidate ? bestScore.toFixed(2) : 'n/a';

      if (DRY_RUN) {
        console.log(`NO_MATCH  ${pol.full_name} (${stateAbbr}) -- dry-run (no FEC call made)`);
      } else {
        console.log(`NO_MATCH  ${pol.full_name} (${stateAbbr}) -- best score ${scoreStr}`);
        await pool.query(
          `DELETE FROM transparent_motivations.politician_sources
           WHERE essentials_politician_id = $1 AND source_system = 'fec_senate'`,
          [pol.id],
        );
        await pool.query(
          `INSERT INTO transparent_motivations.politician_sources
             (essentials_politician_id, source_system, external_id, research_status, source_type, notes)
           VALUES ($1, 'fec_senate', '', 'needs_research', 'candidate_committee', $2)`,
          [pol.id, notesJson],
        );
      }
      stats.no_match++;
      continue;
    }

    // --- match found ---
    const fecId = bestCandidate.candidate_id;
    console.log(`MATCH  ${pol.full_name} -> ${fecId} (score ${bestScore.toFixed(2)})`);
    stats.confirmed++;

    // Write politician_sources row
    await pool.query(
      `DELETE FROM transparent_motivations.politician_sources
       WHERE essentials_politician_id = $1 AND source_system = 'fec_senate'`,
      [pol.id],
    );
    await pool.query(
      `INSERT INTO transparent_motivations.politician_sources
         (essentials_politician_id, source_system, external_id, research_status, source_type, notes)
       VALUES ($1, 'fec_senate', $2, 'confirmed', 'candidate_committee', '')`,
      [pol.id, fecId],
    );

    // Fetch and write finance data
    try {
      const summary = await fetchFecData(fecId, apiKey);
      if (!summary) {
        stats.no_committee++;
        continue;
      }

      await pool.query(
        `UPDATE essentials.politicians SET finance_summary = $1::jsonb WHERE id = $2`,
        [JSON.stringify(summary), pol.id],
      );
      const raised = (summary as { total_raised: number }).total_raised;
      console.log(`  [OK] $${raised.toLocaleString()} written`);
      stats.written++;
    } catch (err) {
      console.error(`  [ERR] ${pol.full_name}: ${(err as Error).message}`);
      stats.error++;
    }
  }

  // ---------------------------------------------------------------------------
  // Handle DC Shadow Senators explicitly (not in NATIONAL_UPPER query above —
  // they are stored as NATIONAL_LOWER in the DB since DC has no Senate seats)
  // ---------------------------------------------------------------------------
  const shadowSenators = await pool.query<{ id: string; full_name: string }>(`
    SELECT p.id, p.full_name
    FROM essentials.politicians p
    WHERE LOWER(p.full_name) IN ('paul strauss', 'ankit jain')
      AND p.is_active = true
  `);

  for (const pol of shadowSenators.rows) {
    console.log(`NOT_APPLICABLE  ${pol.full_name}`);
    if (!DRY_RUN) {
      await pool.query(
        `DELETE FROM transparent_motivations.politician_sources
         WHERE essentials_politician_id = $1 AND source_system = 'fec_senate'`,
        [pol.id],
      );
      await pool.query(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, source_type, notes)
         VALUES ($1, 'fec_senate', '', 'not_applicable', 'candidate_committee', $2)`,
        [pol.id, NOT_APPLICABLE_NOTE],
      );
    }
    stats.not_applicable++;
  }

  console.log('\n=== DONE ===');
  console.log(JSON.stringify(stats, null, 2));
  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
