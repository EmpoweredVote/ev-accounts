/**
 * seed-la-county-cal-access.ts — Verify confirmed Cal-Access source rows for 8 LA County
 * officeholders and trigger runAdapterForAll('cal_access') to ingest contribution data.
 *
 * Purpose: Closes LCTY-03 — all 8 LA County officeholders have confirmed Cal-Access source
 * linkage (confirmed by Phase 20 auto-match); this script verifies and triggers ingest.
 *
 * Note: All 8 officials were auto-confirmed during Phase 20's global Cal-Access confirmation
 * pass. No new seeding is needed — this script verifies the confirmed state and triggers
 * a fresh Cal-Access ingest to populate contribution data for officials with 0 contributions.
 *
 * Usage:
 *   npx tsx scripts/seed-la-county-cal-access.ts --dry-run   # verify, no ingest trigger
 *   npx tsx scripts/seed-la-county-cal-access.ts             # verify + trigger ingest
 *
 * IMPORTANT: NEVER trigger ingest via HTTP POST. Cloudflare blocks POST to
 * accounts.empowered.vote. Use runAdapterForAll direct function call.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ──────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');

// ─── DB Pool ──────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface TargetPolitician {
  fullName: string;           // exact essentials.politicians.full_name
  searchTerms: string[];      // normalized terms to search in committee names
  office: string;             // for logging only
  requireAllTerms: boolean;   // true for all 8 — AND logic for disambiguation
  alreadyConfirmed: boolean;  // all 8 already confirmed by Phase 20
}

type SeedResult = 'already_confirmed';

interface PoliticianResult {
  fullName: string;
  office: string;
  politicianId: string | null;
  confirmedFilerIds: string[];
  seedResults: Array<{ filerId: string; result: SeedResult }>;
  status: 'already_confirmed' | 'no_match' | 'no_uuid';
  note?: string;
}

// ─── Target politicians ───────────────────────────────────────────────────────
// All 8 LA County officials were auto-confirmed by Phase 20's global Cal-Access
// confirmation pass. alreadyConfirmed=true for all — script verifies, does not seed.

const TARGET_POLITICIANS: TargetPolitician[] = [
  {
    fullName: 'Hilda L. Solis',
    office: 'Supervisor District 1',
    searchTerms: ['hilda', 'solis'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Holly J. Mitchell',
    office: 'Supervisor District 2',
    searchTerms: ['holly', 'mitchell'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Lindsey P. Horvath',
    office: 'Supervisor District 3',
    searchTerms: ['lindsey', 'horvath'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Janice Hahn',
    office: 'Supervisor District 4',
    searchTerms: ['janice', 'hahn'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Kathryn Barger',
    office: 'Supervisor District 5',
    searchTerms: ['kathryn', 'barger'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Nathan Hochman',
    office: 'District Attorney',
    searchTerms: ['nathan', 'hochman'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Robert Luna',
    office: 'Sheriff',
    searchTerms: ['robert', 'luna'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
  {
    fullName: 'Jeff Prang',
    office: 'Assessor',
    searchTerms: ['jeff', 'prang'],
    requireAllTerms: true,
    alreadyConfirmed: true,
  },
];

// ─── DB queries ───────────────────────────────────────────────────────────────

async function lookupPoliticianUUIDs(
  fullNames: string[]
): Promise<Map<string, string>> {
  const res = await pool.query<{ id: string; full_name: string }>(
    `SELECT id, full_name FROM essentials.politicians WHERE full_name = ANY($1::text[])`,
    [fullNames]
  );
  const map = new Map<string, string>();
  for (const row of res.rows) {
    map.set(row.full_name, row.id);
  }
  return map;
}

async function fetchExistingConfirmedSources(
  politicianIds: string[]
): Promise<Map<string, string[]>> {
  // Returns Map<politicianId, filerIds[]> for all confirmed cal_access rows
  const res = await pool.query<{
    essentials_politician_id: string;
    external_id: string;
  }>(
    `SELECT ps.essentials_politician_id, ps.external_id
     FROM transparent_motivations.politician_sources ps
     WHERE ps.source_system = 'cal_access'
       AND ps.research_status = 'confirmed'
       AND ps.essentials_politician_id = ANY($1::uuid[])`,
    [politicianIds]
  );

  const map = new Map<string, string[]>();
  for (const row of res.rows) {
    if (!map.has(row.essentials_politician_id)) {
      map.set(row.essentials_politician_id, []);
    }
    map.get(row.essentials_politician_id)!.push(row.external_id);
  }
  return map;
}

// ─── Summary table printer ───────────────────────────────────────────────────

function printSummaryTable(results: PoliticianResult[]): void {
  console.log('\n=== LA COUNTY CAL-ACCESS CONFIRMED SOURCE SEEDING SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no ingest triggered)\n');
  }

  const col1 = 26;
  const col2 = 26;
  const col3 = 20;
  const col4 = 18;

  const header =
    '  ' +
    'POLITICIAN'.padEnd(col1) +
    '| ' +
    'OFFICE'.padEnd(col2) +
    '| ' +
    'CONFIRMED_SOURCES'.padEnd(col3) +
    '| STATUS';

  const divider = '-'.repeat(header.length);
  console.log(header);
  console.log(divider);

  for (const r of results) {
    const sourcesStr = r.confirmedFilerIds.length > 0
      ? String(r.confirmedFilerIds.length)
      : '0';

    const statusStr = r.note ? `${r.status} (${r.note})` : r.status;

    console.log(
      '  ' +
      r.fullName.padEnd(col1) +
      '| ' +
      r.office.padEnd(col2) +
      '| ' +
      sourcesStr.padEnd(col3) +
      '| ' +
      statusStr
    );
  }

  console.log(divider);

  const alreadyConfirmed = results.filter(r => r.status === 'already_confirmed').length;
  const noMatch = results.filter(r => r.status === 'no_match').length;
  const noUuid = results.filter(r => r.status === 'no_uuid').length;

  console.log(`\nTotals: ${alreadyConfirmed}/8 confirmed, 0 new inserts needed`);
  if (noMatch > 0) {
    console.log(`WARNING: ${noMatch} officials have no confirmed sources — manual action needed`);
  }
  if (noUuid > 0) {
    console.log(`ERROR: ${noUuid} officials not found in essentials.politicians`);
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log('[seed-la-county-cal-access] Mode: ' + (isDryRun ? 'DRY-RUN (no ingest)' : 'LIVE'));

  // Step 1: Look up UUIDs for all 8 officials
  console.log('\n[Step 1] Looking up politician UUIDs from essentials.politicians...');
  const fullNames = TARGET_POLITICIANS.map(p => p.fullName);
  const uuidMap = await lookupPoliticianUUIDs(fullNames);

  for (const p of TARGET_POLITICIANS) {
    const uuid = uuidMap.get(p.fullName);
    if (!uuid) {
      console.warn(`  [WARNING] UUID not found for: "${p.fullName}"`);
    } else {
      console.log(`  [OK] ${p.fullName} → ${uuid}`);
    }
  }

  // Step 2: Check existing confirmed cal_access sources
  console.log('\n[Step 2] Checking existing confirmed cal_access sources in politician_sources...');
  const allUUIDs = [...uuidMap.values()];
  const existingConfirmedMap = await fetchExistingConfirmedSources(allUUIDs);

  for (const [politicianId, filerIds] of existingConfirmedMap.entries()) {
    const name = [...uuidMap.entries()].find(([, id]) => id === politicianId)?.[0] ?? politicianId;
    console.log(`  [CONFIRMED] ${name}: ${filerIds.length} confirmed filer_id(s)`);
  }

  // Step 3: Build results — all officials are alreadyConfirmed from Phase 20
  console.log('\n[Step 3] Verifying confirmed state for all 8 officials...');
  const results: PoliticianResult[] = [];

  for (const politician of TARGET_POLITICIANS) {
    const politicianId = uuidMap.get(politician.fullName) ?? null;
    const result: PoliticianResult = {
      fullName: politician.fullName,
      office: politician.office,
      politicianId,
      confirmedFilerIds: [],
      seedResults: [],
      status: 'no_match',
    };

    if (!politicianId) {
      result.status = 'no_uuid';
      result.note = 'UUID not found — check full_name spelling';
      console.warn(`  [ERROR] UUID not found for: "${politician.fullName}"`);
      results.push(result);
      continue;
    }

    const confirmedFilerIds = existingConfirmedMap.get(politicianId) ?? [];
    result.confirmedFilerIds = confirmedFilerIds;

    if (confirmedFilerIds.length > 0) {
      result.status = 'already_confirmed';
      console.log(
        `  [ALREADY_CONFIRMED] ${politician.fullName}: ` +
        `${confirmedFilerIds.length} confirmed filer_id(s): ${confirmedFilerIds.slice(0, 5).join(', ')}` +
        (confirmedFilerIds.length > 5 ? ` ... (+${confirmedFilerIds.length - 5} more)` : '')
      );
    } else {
      result.status = 'no_match';
      result.note = 'expected confirmed but found none — Phase 20 may not have matched this official';
      console.warn(
        `  [WARNING] ${politician.fullName} marked alreadyConfirmed ` +
        `but has no confirmed cal_access rows in politician_sources!`
      );
    }

    results.push(result);
  }

  // Print summary table
  printSummaryTable(results);

  // Step 4: Trigger ingest (live mode only)
  if (!isDryRun) {
    console.log('\n[Step 4] Triggering runAdapterForAll("cal_access")...');
    console.log(
      '[seed-la-county-cal-access] NOTE: Cal-Access ZIP is ~500MB — download may take several minutes.'
    );
    console.log(
      '[seed-la-county-cal-access] ETag caching means subsequent runs skip download if ZIP unchanged.'
    );
    await runAdapterForAll('cal_access');
    console.log('[seed-la-county-cal-access] Cal-Access ingest complete.');
  } else {
    console.log(
      '\n[DRY-RUN] Skipping runAdapterForAll("cal_access") — pass without --dry-run to trigger ingest.'
    );
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-county-cal-access] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

main()
  .then(async () => {
    await pool.end();
    process.exit(0);
  })
  .catch(async err => {
    console.error('[seed-la-county-cal-access] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
