/**
 * fix-fec-name-mismatches.ts
 *
 * Targeted FEC finance summary fix for sitting members whose names in our DB
 * don't match the congress-legislators YAML (e.g. "Chuck Schumer" vs "Charles E. Schumer").
 *
 * Strategy:
 *   1. Fetch YAML — same source as run-fec-finance-summary.ts
 *   2. Build extended name map including nickname → formal variants
 *   3. For each active federal politician with NULL finance_summary, try all name variants
 *   4. On match: insert politician_sources row + run FEC API fetch (3 calls)
 *   5. On no match: print NO_MATCH line for manual follow-up
 *
 * Rate limit: 2000ms between every FEC API call (conservative — stays well under 1000 req/hr).
 *
 * Usage: tsx scripts/fix-fec-name-mismatches.ts [--dry-run]
 *   --dry-run  Show matches without writing to DB or calling FEC API
 */

import 'dotenv/config';
import { load as yamlLoad } from 'js-yaml';
import { pool } from '../src/lib/db.js';

const DRY_RUN = process.argv.includes('--dry-run');
const SLEEP_MS = 2000;
const FEC_CYCLE = '2026';
const TOP_DONORS_LIMIT = 10;
const LEGISLATORS_YAML_URL =
  'https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml';
const FEC_BASE = 'https://api.open.fec.gov/v1';

// ---------------------------------------------------------------------------
// Known nickname → formal name mappings (extend as needed)
// ---------------------------------------------------------------------------
const NICKNAME_MAP: Record<string, string[]> = {
  'chuck schumer':    ['charles schumer', 'charles e. schumer'],
  'bernie sanders':   ['bernard sanders', 'bernard sanders'],
  'chris coons':      ['christopher coons', 'christopher a. coons'],
  'maggie hassan':    ['margaret hassan', 'margaret wood hassan'],
  'doug lamalfa':     ['douglas lamalfa', 'doug lamalfa'],
  'bill keating':     ['william keating', 'william r. keating'],
  'jim mcgovern':     ['james mcgovern', 'james p. mcgovern'],
  'lou correa':       ['j. correa', 'jose correa', 'j. luis correa'],
  'val hoyle':        ['valerie hoyle'],
  'eric swalwell':    ['eric michael swalwell'],
  'keith self':       ['keith self'],
  'raphael warnock':  ['raphael g. warnock'],
  'ted cruz':         ['rafael cruz', 'rafael edward cruz'],
};

interface Legislator {
  id: { bioguide: string; fec?: string[] };
  name: { first: string; last: string; official_full?: string };
  terms: Array<{ type: 'sen' | 'rep'; start: string; end: string; state: string }>;
}

interface FedPolitician {
  id: string;
  full_name: string;
  chamber_short: 'S' | 'H';
}

function sleep(ms: number) {
  return new Promise(r => setTimeout(r, ms));
}

async function buildNameMap(): Promise<Map<string, string>> {
  console.log('[yaml] Fetching congress-legislators YAML...');
  const resp = await fetch(LEGISLATORS_YAML_URL, { signal: AbortSignal.timeout(60_000) });
  if (!resp.ok) throw new Error(`YAML fetch failed: HTTP ${resp.status}`);
  const legislators = yamlLoad(await resp.text()) as Legislator[];

  const nameMap = new Map<string, string>();
  for (const leg of legislators) {
    if (!leg.id.fec?.length) continue;
    const lastTerm = leg.terms[leg.terms.length - 1];
    if (!lastTerm) continue;
    const isSenate = lastTerm.type === 'sen';
    const fecId =
      leg.id.fec.find(id => (isSenate ? id.startsWith('S') : id.startsWith('H'))) ??
      leg.id.fec[0];
    if (!fecId) continue;

    const variants = [
      `${leg.name.first} ${leg.name.last}`,
      leg.name.official_full,
    ].filter(Boolean) as string[];

    for (const v of variants) {
      nameMap.set(v.toLowerCase(), fecId);
    }
  }
  console.log(`[yaml] Built name map: ${nameMap.size} entries`);
  return nameMap;
}

function resolveFecId(fullName: string, nameMap: Map<string, string>): string | null {
  const key = fullName.toLowerCase();
  // Direct match
  if (nameMap.has(key)) return nameMap.get(key)!;
  // Nickname variants
  const variants = NICKNAME_MAP[key] ?? [];
  for (const v of variants) {
    if (nameMap.has(v)) return nameMap.get(v)!;
  }
  // Last-name-first match: try splitting and recombining
  const parts = key.split(' ');
  if (parts.length >= 2) {
    const lastFirst = `${parts[parts.length - 1]} ${parts[0]}`;
    if (nameMap.has(lastFirst)) return nameMap.get(lastFirst)!;
  }
  return null;
}

async function fetchFecData(fecId: string, apiKey: string): Promise<object | null> {
  // Step 1: get committee_id
  const searchUrl = `${FEC_BASE}/candidates/search/?api_key=${apiKey}&candidate_id=${fecId}&per_page=1`;
  await sleep(SLEEP_MS);
  const searchResp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!searchResp.ok) throw new Error(`FEC search HTTP ${searchResp.status}`);
  const searchData = await searchResp.json() as { results?: Array<{ principal_committees?: Array<{ id: string }> }> };
  let committeeId: string | undefined = searchData.results?.[0]?.principal_committees?.[0]?.id;

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

  // Step 2: total raised (multi-cycle fallback for non-2026-ballot senators)
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
  const donorsData = await donorsResp.json() as { results?: Array<{ employer: string; total: number; count: number }> };
  const topDonors = (donorsData.results ?? []).map(r => ({
    employer: r.employer,
    amount: r.total,
    count: r.count,
  }));

  return { total_raised: totalRaised, top_donors: topDonors, cycle: usedCycle, source: 'FEC' };
}

async function resolveViaDirectSearch(
  pol: FedPolitician,
  apiKey: string,
): Promise<string | null> {
  // LaMalfa (CA-01) and Swalwell (CA-14) are both California House members
  const state = 'CA';
  const searchUrl = `${FEC_BASE}/candidates/?api_key=${apiKey}&q=${encodeURIComponent(pol.full_name)}&state=${state}&office=H&per_page=20`;
  await sleep(SLEEP_MS);
  const resp = await fetch(searchUrl, { signal: AbortSignal.timeout(30_000) });
  if (!resp.ok) throw new Error(`FEC direct search HTTP ${resp.status}`);
  const data = await resp.json() as {
    results?: Array<{ candidate_id: string; name: string; state: string; office: string }>
  };
  if (!data.results?.length) return null;
  const lastName = pol.full_name.toLowerCase().split(' ').pop()!;
  const best = data.results.find(r => r.name.toLowerCase().includes(lastName));
  return best?.candidate_id ?? null;
}

async function main() {
  const apiKey = process.env.FEC_API_KEY;
  if (!apiKey) throw new Error('FEC_API_KEY not set');

  console.log(DRY_RUN ? '[dry-run] No DB writes or FEC calls' : '[live] Writing to DB');

  const nameMap = await buildNameMap();

  // Fetch null-finance federal politicians from DB
  const { rows } = await pool.query<FedPolitician>(`
    SELECT DISTINCT p.id, p.full_name,
      CASE WHEN d.district_type = 'NATIONAL_UPPER' THEN 'S' ELSE 'H' END AS chamber_short
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
      AND p.is_active = true
      AND p.finance_summary IS NULL
    ORDER BY p.full_name
  `);

  console.log(`\nFound ${rows.length} federal politicians with NULL finance_summary\n`);

  const stats = { matched: 0, written: 0, no_committee: 0, no_match: 0, error: 0 };
  const noMatchList: string[] = [];

  for (const pol of rows) {
    let fecId = resolveFecId(pol.full_name, nameMap);

    if (!fecId) {
      if (DRY_RUN) {
        console.log(`NO_MATCH  ${pol.full_name} (${pol.chamber_short}) — would attempt direct search`);
        stats.no_match++;
        continue;
      }
      const directId = await resolveViaDirectSearch(pol, apiKey);
      if (!directId) {
        console.log(`NO_MATCH  ${pol.full_name} (${pol.chamber_short})`);
        noMatchList.push(pol.full_name);
        stats.no_match++;
        continue;
      }
      console.log(`DIRECT    ${pol.full_name} → ${directId}`);
      stats.matched++;
      // Use DO UPDATE to overwrite any prior partial run that left an empty external_id
      await pool.query(`
        INSERT INTO transparent_motivations.politician_sources
          (essentials_politician_id, source_system, external_id, research_status, source_type)
        VALUES ($1, $2, $3, 'confirmed', 'candidate_committee')
        ON CONFLICT (essentials_politician_id, source_system)
        DO UPDATE SET external_id = EXCLUDED.external_id,
                      research_status = EXCLUDED.research_status
      `, [pol.id, 'fec_house', directId]);
      fecId = directId; // fall through to DB write path (fetchFecData + finance_summary UPDATE)
    } else {
      console.log(`MATCH     ${pol.full_name} → ${fecId}`);
      stats.matched++;
    }

    if (DRY_RUN) continue;

    // Upsert politician_sources row so future runs of the main script also catch it
    await pool.query(`
      INSERT INTO transparent_motivations.politician_sources
        (essentials_politician_id, source_system, external_id, research_status, source_type)
      VALUES ($1, $2, $3, 'confirmed', 'candidate_committee')
      ON CONFLICT DO NOTHING
    `, [pol.id, pol.chamber_short === 'S' ? 'fec_senate' : 'fec_house', fecId]);

    try {
      const summary = await fetchFecData(fecId, apiKey);
      if (!summary) { stats.no_committee++; continue; }

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

  console.log('\n=== DONE ===');
  console.log(JSON.stringify({ ...stats, no_match_list: noMatchList }, null, 2));
  await pool.end();
}

main().catch(err => { console.error(err); process.exit(1); });
