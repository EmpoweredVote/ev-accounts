/**
 * seed-la-metro-new-politicians.ts — Seed confirmed Cal-Access source rows for 4 newly
 * added LA-metro politicians who have no campaign finance sources yet.
 *
 * Politicians:
 *   - Nikki Perez      (Burbank City Council)
 *   - Cindy Allen      (Long Beach City Council)
 *   - Joni Ricks-Oddie (Long Beach City Council)
 *   - Justin Jones     (Pasadena City Council)
 *
 * Filer IDs identified by searching transparent_motivations.politician_sources
 * needs_research committee names for name+city matches (2026-04-29).
 *
 * Usage:
 *   npx tsx scripts/seed-la-metro-new-politicians.ts --dry-run  # print matches, no DB writes
 *   npx tsx scripts/seed-la-metro-new-politicians.ts            # seed + trigger Cal-Access ingest
 *
 * IMPORTANT: NEVER trigger ingest via HTTP POST. Cloudflare blocks POST to
 * accounts.empowered.vote. Use runAdapterForAll direct function call.
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { runAdapterForSources } from '../src/lib/campaignFinanceScheduler.js';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const isDryRun = process.argv.includes('--dry-run');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Target politicians ───────────────────────────────────────────────────────

interface TargetPolitician {
  fullName: string;
  office: string;
  city: string;
  filerIds: Array<{
    id: string;
    committeeName: string;
  }>;
}

const TARGET_POLITICIANS: TargetPolitician[] = [
  {
    fullName: 'Nikki Perez',
    office: 'Council Member',
    city: 'Burbank',
    filerIds: [
      { id: '1448423', committeeName: 'PEREZ FOR CITY COUNCIL 2022; NIKKI' },
      { id: '1454616', committeeName: 'PEREZ FOR BURBANK CITY COUNCIL 2022; BURBANK NEIGHBORS FOR AFFORDABILITY SUPPORTING NIKKI' },
    ],
  },
  {
    fullName: 'Cindy Allen',
    office: 'Councilmember',
    city: 'Long Beach',
    filerIds: [
      { id: '1421740', committeeName: 'ALLEN FOR CITY COUNCIL 2020; CINDY' },
      { id: '1436981', committeeName: 'ALLEN CITY COUNCIL OFFICEHOLDER COMMITTEE 2020; CINDY' },
      { id: '1462179', committeeName: 'ALLEN FOR CITY COUNCIL 2024; RE-ELECT CINDY' },
    ],
  },
  {
    fullName: 'Joni Ricks-Oddie',
    office: 'Councilmember',
    city: 'Long Beach',
    filerIds: [
      { id: '1443373', committeeName: 'RICKS-ODDIE FOR COUNCIL 2022' },
      { id: '1458182', committeeName: 'RICKS-ODDIE FOR COUNCIL 2022 OFFICEHOLDER ACCOUNT' },
      { id: '1482367', committeeName: 'RICKS-ODDIE FOR CITY COUNCIL 2026' },
    ],
  },
  {
    fullName: 'Justin Jones',
    office: 'Councilmember',
    city: 'Pasadena',
    filerIds: [
      { id: '1461920', committeeName: 'JONES FOR PASADENA CITY COUNCIL 2024; JUSTIN' },
    ],
  },
];

// ─── DB helpers ───────────────────────────────────────────────────────────────

async function lookupUUIDs(fullNames: string[]): Promise<Map<string, string>> {
  const res = await pool.query<{ id: string; full_name: string }>(
    `SELECT id, full_name FROM essentials.politicians WHERE full_name = ANY($1::text[])`,
    [fullNames]
  );
  const map = new Map<string, string>();
  for (const row of res.rows) map.set(row.full_name, row.id);
  return map;
}

async function fetchExistingConfirmedSources(uuids: string[]): Promise<Map<string, string[]>> {
  const res = await pool.query<{ essentials_politician_id: string; external_id: string }>(
    `SELECT essentials_politician_id, external_id
     FROM transparent_motivations.politician_sources
     WHERE source_system = 'cal_access'
       AND research_status = 'confirmed'
       AND essentials_politician_id = ANY($1::uuid[])`,
    [uuids]
  );
  const map = new Map<string, string[]>();
  for (const row of res.rows) {
    if (!map.has(row.essentials_politician_id)) map.set(row.essentials_politician_id, []);
    map.get(row.essentials_politician_id)!.push(row.external_id);
  }
  return map;
}

async function seedConfirmedRow(
  politicianId: string,
  filerId: string,
  committeeName: string
): Promise<'inserted' | 'promoted' | 'already_confirmed'> {
  const insertRes = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'cal_access', $2, 'confirmed', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [
      politicianId,
      filerId,
      JSON.stringify({ committee_name: committeeName, confirmed_by: 'seed-la-metro-new-politicians.ts' }),
    ]
  );

  if (insertRes.rowCount && insertRes.rowCount > 0) return 'inserted';

  const updateRes = await pool.query(
    `UPDATE transparent_motivations.politician_sources
     SET research_status = 'confirmed', updated_at = NOW()
     WHERE essentials_politician_id = $1
       AND source_system = 'cal_access'
       AND external_id = $2
       AND research_status != 'confirmed'`,
    [politicianId, filerId]
  );

  if (updateRes.rowCount && updateRes.rowCount > 0) return 'promoted';
  return 'already_confirmed';
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();
  console.log('[seed-la-metro-new-politicians] Mode:', isDryRun ? 'DRY-RUN' : 'LIVE');

  console.log('\n[Step 1] Looking up politician UUIDs...');
  const fullNames = TARGET_POLITICIANS.map(p => p.fullName);
  const uuidMap = await lookupUUIDs(fullNames);
  for (const p of TARGET_POLITICIANS) {
    const uuid = uuidMap.get(p.fullName);
    if (uuid) {
      console.log(`  [OK] ${p.fullName} (${p.city}) → ${uuid}`);
    } else {
      console.error(`  [ERROR] UUID not found: "${p.fullName}" — check spelling`);
    }
  }

  console.log('\n[Step 2] Checking existing confirmed cal_access sources...');
  const allUUIDs = [...uuidMap.values()];
  const existingMap = await fetchExistingConfirmedSources(allUUIDs);
  if (existingMap.size === 0) {
    console.log('  (none — all 4 politicians have 0 confirmed cal_access sources)');
  }
  for (const [uuid, filerIds] of existingMap.entries()) {
    const name = [...uuidMap.entries()].find(([, id]) => id === uuid)?.[0] ?? uuid;
    console.log(`  [EXISTING] ${name}: ${filerIds.length} confirmed filer_id(s) already`);
  }

  console.log('\n[Step 3] Seeding confirmed rows...');
  const totals = { inserted: 0, promoted: 0, already_confirmed: 0, no_uuid: 0 };

  for (const politician of TARGET_POLITICIANS) {
    const uuid = uuidMap.get(politician.fullName);
    if (!uuid) {
      console.error(`  [SKIP] ${politician.fullName}: UUID not found`);
      totals.no_uuid++;
      continue;
    }

    for (const { id: filerId, committeeName } of politician.filerIds) {
      if (isDryRun) {
        const alreadyConfirmed = existingMap.get(uuid)?.includes(filerId) ?? false;
        const action = alreadyConfirmed ? '(already confirmed)' : '→ would INSERT';
        console.log(`  [DRY-RUN] ${politician.fullName} → ${filerId} "${committeeName}" ${action}`);
        if (!alreadyConfirmed) totals.inserted++;
        else totals.already_confirmed++;
      } else {
        const result = await seedConfirmedRow(uuid, filerId, committeeName);
        const label = result === 'inserted' ? '[INSERTED]'
          : result === 'promoted' ? '[PROMOTED]'
          : '[ALREADY_CONFIRMED]';
        console.log(`  ${label} ${politician.fullName} → ${filerId} "${committeeName}"`);
        totals[result]++;
      }
    }
  }

  console.log('\n=== SEEDING SUMMARY ===');
  console.log(`  Inserted:          ${totals.inserted}`);
  console.log(`  Promoted:          ${totals.promoted}`);
  console.log(`  Already confirmed: ${totals.already_confirmed}`);
  if (totals.no_uuid > 0) console.log(`  UUID not found:    ${totals.no_uuid}`);

  if (!isDryRun) {
    // Query the source row IDs for targeted ingest (run regardless of insert/already_confirmed)
    const sourceIdResult = await pool.query<{ id: string }>(
      `SELECT id FROM transparent_motivations.politician_sources
       WHERE source_system = 'cal_access'
         AND research_status = 'confirmed'
         AND essentials_politician_id = ANY($1::uuid[])`,
      [TARGET_POLITICIANS.map(p => uuidMap.get(p.fullName)).filter(Boolean)]
    );
    const sourceIds = sourceIdResult.rows.map(r => r.id);

    console.log(`\n[Step 4] Triggering targeted cal_access ingest for ${sourceIds.length} source(s)...`);
    console.log('NOTE: Cal-Access ZIP is ~500MB — download may take several minutes.');
    console.log('ETag caching means subsequent runs skip download if ZIP unchanged.');
    await runAdapterForSources(sourceIds);
    console.log('[seed-la-metro-new-politicians] Cal-Access ingest complete.');
  } else {
    console.log('\n[DRY-RUN] Skipping ingest — run without --dry-run to seed + trigger ingest.');
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-metro-new-politicians] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[seed-la-metro-new-politicians] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
