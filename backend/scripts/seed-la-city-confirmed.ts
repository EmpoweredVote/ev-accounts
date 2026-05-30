/**
 * seed-la-city-confirmed.ts — Look up cmt_id values for all 15 remaining LA City
 * officeholders from the Socrata API, seed confirmed politician_sources rows, and
 * trigger runAdapterForAll('la_socrata') to ingest contribution data.
 *
 * Purpose: Closes CITY-01 — all 18 LA City officeholders get confirmed source
 * linkage so the Socrata adapter can ingest their contribution data.
 *
 * Usage:
 *   npx tsx scripts/seed-la-city-confirmed.ts --dry-run   # print matches, no DB writes
 *   npx tsx scripts/seed-la-city-confirmed.ts             # seed + trigger ingest
 *
 * Edge cases handled:
 *   - Feldstein Soto: compound last name — uses 'feldstein soto' / 'feldstein' (not 'soto')
 *   - Price Jr.: suffix stripping — uses 'price' directly (extractLastName returns "Jr.")
 *   - Harris-Dawson: hyphenated — tries both 'harris-dawson' and 'harris dawson'
 *   - Nazarian: dual committees — knownCmtIds pre-seeded
 *   - Traci Park: may already have confirmed rows — checks existing status and skips
 *   - John Lee: extremely common name — requires BOTH "john" AND "lee" in cmt_nm
 *   - Monica Rodriguez: common name — requires "monica" AND "rodriguez" in cmt_nm
 *   - Jurado: newer councilmember — zero contributions after ingest is acceptable
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
  searchTerms: string[];      // normalized terms to search in cmt_nm
  office: string;             // for logging only
  knownCmtIds?: string[];     // pre-researched cmt_ids — skip Socrata name matching
  alreadyConfirmed?: boolean; // skip entirely — just verify
  requireAllTerms?: boolean;  // if true, ALL searchTerms must appear in cmt_nm (AND logic)
}

interface MatchedCommittee {
  cmtId: string;
  cmtNm: string;
}

type SeedResult = 'inserted' | 'promoted' | 'already_confirmed' | 'skipped_dry_run';

interface PoliticianResult {
  fullName: string;
  office: string;
  politicianId: string | null;
  matches: MatchedCommittee[];
  seedResults: Array<{ cmtId: string; result: SeedResult }>;
  status: 'confirmed' | 'already_confirmed' | 'no_match' | 'ambiguous' | 'dry_run' | 'no_uuid';
  note?: string;
}

// ─── Target politicians ───────────────────────────────────────────────────────

const TARGET_POLITICIANS: TargetPolitician[] = [
  {
    // DB full_name: "Karen Ruth Bass"
    fullName: 'Karen Ruth Bass',
    searchTerms: ['bass'],
    office: 'Mayor',
    alreadyConfirmed: true,
  },
  {
    fullName: 'Nithya Raman',
    searchTerms: ['raman'],
    office: 'CD-4',
    alreadyConfirmed: true,
  },
  {
    fullName: 'Hugo Soto-Martinez',
    searchTerms: ['soto-martinez', 'soto martinez'],
    office: 'CD-13',
    alreadyConfirmed: true,
  },
  {
    // Compound last name: extractLastName returns "Soto" — wrong (collides with Soto-Martinez)
    // Use 'feldstein' + require all terms for disambiguation
    fullName: 'Hydee Feldstein Soto',
    searchTerms: ['feldstein'],
    office: 'City Attorney',
  },
  {
    fullName: 'Kenneth Mejia',
    searchTerms: ['mejia'],
    office: 'City Controller',
  },
  {
    // "Hernandez" is common — require BOTH "eunisses" AND "hernandez" in cmt_nm
    fullName: 'Eunisses Hernandez',
    searchTerms: ['eunisses', 'hernandez'],
    requireAllTerms: true,
    office: 'CD-1',
  },
  {
    // Two committees confirmed from prior research
    fullName: 'Adrin Nazarian',
    searchTerms: ['nazarian'],
    office: 'CD-2',
    knownCmtIds: ['1453755', '1468093'],
  },
  {
    fullName: 'Bob Blumenfield',
    searchTerms: ['blumenfield'],
    office: 'CD-3',
  },
  {
    // DB full_name: "Katy Yaroslavsky" (not "Katy Young Yaroslavsky" — middle name absent)
    // Use 'katy' + 'yaroslavsky' to exclude Zev Yaroslavsky (former Supervisor) committees
    fullName: 'Katy Yaroslavsky',
    searchTerms: ['katy', 'yaroslavsky'],
    requireAllTerms: true,
    office: 'CD-5',
  },
  {
    // Require BOTH "imelda" AND "padilla" to exclude other Padilla candidates
    fullName: 'Imelda Padilla',
    searchTerms: ['imelda', 'padilla'],
    requireAllTerms: true,
    office: 'CD-6',
  },
  {
    // Common name — require BOTH "monica" AND "rodriguez" in cmt_nm
    fullName: 'Monica Rodriguez',
    searchTerms: ['monica', 'rodriguez'],
    requireAllTerms: true,
    office: 'CD-7',
  },
  {
    // Hyphenated — try both forms; requireAllTerms: true ensures "harris" AND "dawson" both present
    fullName: 'Marqueece Harris-Dawson',
    searchTerms: ['harris', 'dawson'],
    requireAllTerms: true,
    office: 'CD-8',
  },
  {
    // CRITICAL: extractLastName("Curren D. Price Jr.") returns "Jr." — suffix issue
    // Require BOTH "curren" AND "price" to avoid matching other Price candidates
    fullName: 'Curren D. Price Jr.',
    searchTerms: ['curren', 'price'],
    requireAllTerms: true,
    office: 'CD-9',
  },
  {
    fullName: 'Heather Hutt',
    searchTerms: ['hutt'],
    office: 'CD-10',
  },
  {
    // May already have confirmed rows from seed-traci-park-committees.ts
    // Require BOTH "traci" AND "park" to exclude "Bernard Parks" committees
    fullName: 'Traci Park',
    searchTerms: ['traci', 'park'],
    requireAllTerms: true,
    office: 'CD-11',
  },
  {
    // CRITICAL: "Lee" is extremely common — require BOTH "john" AND "lee" in cmt_nm
    fullName: 'John Lee',
    searchTerms: ['john', 'lee'],
    requireAllTerms: true,
    office: 'CD-12',
  },
  {
    // DB full_name: "Ysabel J. Jurado" — newer councilmember, zero contributions acceptable
    fullName: 'Ysabel J. Jurado',
    searchTerms: ['jurado'],
    office: 'CD-14',
  },
  {
    // Require BOTH "tim" AND "mcosker" to exclude "Pat McOsker for City Council 2011" (different person)
    fullName: 'Tim McOsker',
    searchTerms: ['tim', 'mcosker'],
    requireAllTerms: true,
    office: 'CD-15',
  },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

function normalize(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

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
): Promise<Map<string, Set<string>>> {
  // Returns Map<politicianId, Set<cmtId>> for all confirmed la_socrata rows
  const res = await pool.query<{
    essentials_politician_id: string;
    external_id: string;
    research_status: string;
  }>(
    `SELECT ps.essentials_politician_id, ps.external_id, ps.research_status
     FROM transparent_motivations.politician_sources ps
     WHERE ps.source_system = 'la_socrata'
       AND ps.essentials_politician_id = ANY($1::uuid[])`,
    [politicianIds]
  );

  const map = new Map<string, Set<string>>();
  for (const row of res.rows) {
    if (!map.has(row.essentials_politician_id)) {
      map.set(row.essentials_politician_id, new Set());
    }
    if (row.research_status === 'confirmed') {
      map.get(row.essentials_politician_id)!.add(row.external_id);
    }
  }
  return map;
}

// ─── Socrata fetch ────────────────────────────────────────────────────────────

async function fetchSocrataCandidateCommittees(): Promise<Map<string, string>> {
  // Returns Map<cmt_id, cmt_nm> for all candidate committees (cmt_type='C')
  const url =
    'https://data.lacity.org/resource/m6g2-gc6c.json' +
    "?$select=cmt_id,cmt_nm&$group=cmt_id,cmt_nm&$where=cmt_type=%27C%27&$limit=10000";

  const headers: Record<string, string> = { Accept: 'application/json' };
  if (process.env.SOCRATA_APP_TOKEN) {
    headers['X-App-Token'] = process.env.SOCRATA_APP_TOKEN;
  } else {
    console.warn('[seed-la-city-confirmed] SOCRATA_APP_TOKEN not set — requests may be rate-limited');
  }

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Socrata API returned ${response.status}: ${await response.text()}`);
  }

  const data = (await response.json()) as Array<{ cmt_id: string; cmt_nm: string }>;
  const map = new Map<string, string>();
  for (const row of data) {
    if (row.cmt_id) {
      map.set(row.cmt_id, row.cmt_nm ?? '');
    }
  }
  return map;
}

// ─── Matching logic ───────────────────────────────────────────────────────────

function matchCommittees(
  politician: TargetPolitician,
  socrataMap: Map<string, string>
): MatchedCommittee[] {
  const matches: MatchedCommittee[] = [];

  for (const [cmtId, cmtNm] of socrataMap.entries()) {
    const normalizedCmtNm = normalize(cmtNm);

    if (politician.requireAllTerms) {
      // ALL search terms must appear (AND logic)
      const allMatch = politician.searchTerms.every(term =>
        normalizedCmtNm.includes(normalize(term))
      );
      if (allMatch) {
        matches.push({ cmtId, cmtNm });
      }
    } else {
      // ANY search term matches (OR logic) — use first match
      const anyMatch = politician.searchTerms.some(term =>
        normalizedCmtNm.includes(normalize(term))
      );
      if (anyMatch) {
        matches.push({ cmtId, cmtNm });
      }
    }
  }

  return matches;
}

// ─── DB seed function ─────────────────────────────────────────────────────────

async function seedConfirmedSource(
  politicianId: string,
  cmtId: string,
  cmtNm: string
): Promise<'inserted' | 'already_confirmed' | 'promoted'> {
  const notes = JSON.stringify({ cmt_nm: cmtNm, linked_by: 'seed-la-city-confirmed.ts' });

  const insertRes = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'la_socrata', $2, 'confirmed', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [politicianId, cmtId, notes]
  );

  if ((insertRes.rowCount ?? 0) > 0) return 'inserted';

  // Row already existed — try to promote if not already confirmed
  const updateRes = await pool.query(
    `UPDATE transparent_motivations.politician_sources
     SET research_status = 'confirmed', updated_at = NOW()
     WHERE essentials_politician_id = $1
       AND source_system = 'la_socrata'
       AND external_id = $2
       AND research_status != 'confirmed'`,
    [politicianId, cmtId]
  );

  if ((updateRes.rowCount ?? 0) > 0) return 'promoted';

  return 'already_confirmed';
}

// ─── Summary table printer ───────────────────────────────────────────────────

function printSummaryTable(results: PoliticianResult[]): void {
  console.log('\n=== LA CITY CONFIRMED SOURCE SEEDING SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no DB writes, no ingest triggered)\n');
  }

  const col1 = 26;
  const col2 = 21;
  const col3 = 40;
  const col4 = 18;

  const header =
    ' ' +
    'POLITICIAN'.padEnd(col1) +
    '| ' +
    'OFFICE'.padEnd(col2) +
    '| ' +
    'CMT_IDS'.padEnd(col3) +
    '| STATUS';

  const divider = '-'.repeat(header.length);
  console.log(header);
  console.log(divider);

  for (const r of results) {
    const cmtidsStr =
      r.matches.length === 0
        ? '(none)'
        : r.matches
            .map(m => {
              const seedEntry = r.seedResults.find(s => s.cmtId === m.cmtId);
              const tag = seedEntry ? ` [${seedEntry.result}]` : '';
              return `${m.cmtId}${tag}`;
            })
            .join(', ');

    const statusStr =
      r.note ? `${r.status} (${r.note})` : r.status;

    console.log(
      ' ' +
      r.fullName.padEnd(col1) +
      '| ' +
      r.office.padEnd(col2) +
      '| ' +
      cmtidsStr.padEnd(col3) +
      '| ' +
      statusStr
    );
  }

  console.log(divider);

  const inserted = results.reduce(
    (sum, r) => sum + r.seedResults.filter(s => s.result === 'inserted').length,
    0
  );
  const promoted = results.reduce(
    (sum, r) => sum + r.seedResults.filter(s => s.result === 'promoted').length,
    0
  );
  const alreadyConfirmed = results.filter(r => r.status === 'already_confirmed').length;
  const noMatch = results.filter(r => r.status === 'no_match').length;
  const ambiguous = results.filter(r => r.status === 'ambiguous').length;

  console.log(`\nInserted:          ${inserted} new rows`);
  console.log(`Promoted:          ${promoted} rows (needs_research → confirmed)`);
  console.log(`Already confirmed: ${alreadyConfirmed} politicians`);
  console.log(`No match:          ${noMatch} politicians (manual action needed)`);
  console.log(`Ambiguous:         ${ambiguous} politicians (manual action needed)`);
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log('[seed-la-city-confirmed] Mode: ' + (isDryRun ? 'DRY-RUN (no DB updates, no ingest)' : 'LIVE'));

  // Step 1: Gather all full names and look up UUIDs
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

  // Step 2: Check existing politician_sources state
  console.log('\n[Step 2] Checking existing politician_sources rows...');
  const allUUIDs = [...uuidMap.values()];
  const existingConfirmedMap = await fetchExistingConfirmedSources(allUUIDs);

  for (const [politicianId, confirmedSet] of existingConfirmedMap.entries()) {
    if (confirmedSet.size > 0) {
      const name = [...uuidMap.entries()].find(([, id]) => id === politicianId)?.[0] ?? politicianId;
      console.log(`  [EXISTS] ${name}: ${confirmedSet.size} confirmed cmt_id(s): ${[...confirmedSet].join(', ')}`);
    }
  }

  // Step 3: Fetch all Socrata candidate committees
  console.log('\n[Step 3] Fetching Socrata candidate committees (cmt_type=C)...');
  const socrataMap = await fetchSocrataCandidateCommittees();
  console.log(`  Loaded ${socrataMap.size} candidate committees from Socrata.`);

  // Step 4: Process each politician
  console.log('\n[Step 4] Matching politicians to committees and seeding...');
  const results: PoliticianResult[] = [];

  for (const politician of TARGET_POLITICIANS) {
    const politicianId = uuidMap.get(politician.fullName) ?? null;
    const result: PoliticianResult = {
      fullName: politician.fullName,
      office: politician.office,
      politicianId,
      matches: [],
      seedResults: [],
      status: 'no_match',
    };

    // No UUID — can't proceed
    if (!politicianId) {
      result.status = 'no_uuid';
      result.note = 'UUID not found — manual action needed';
      results.push(result);
      continue;
    }

    // Already confirmed politicians — verify and skip
    if (politician.alreadyConfirmed) {
      const confirmedSet = existingConfirmedMap.get(politicianId);
      if (confirmedSet && confirmedSet.size > 0) {
        const existingCmtIds = [...confirmedSet];
        result.matches = existingCmtIds.map(id => ({
          cmtId: id,
          cmtNm: socrataMap.get(id) ?? '(cmt_nm not in Socrata)',
        }));
        result.status = 'already_confirmed';
      } else {
        result.status = 'no_match';
        result.note = 'marked alreadyConfirmed but no confirmed row found!';
        console.warn(`  [WARNING] ${politician.fullName} is marked alreadyConfirmed but has no confirmed row.`);
      }
      results.push(result);
      continue;
    }

    // knownCmtIds — use pre-researched values, skip Socrata name matching
    if (politician.knownCmtIds && politician.knownCmtIds.length > 0) {
      result.matches = politician.knownCmtIds.map(id => ({
        cmtId: id,
        cmtNm: socrataMap.get(id) ?? '(cmt_nm not in Socrata)',
      }));
      console.log(
        `  [KNOWN] ${politician.fullName}: using pre-researched cmt_ids: ` +
          politician.knownCmtIds.join(', ')
      );
    } else {
      // Socrata name matching
      const matched = matchCommittees(politician, socrataMap);
      result.matches = matched;

      if (matched.length === 0) {
        console.warn(`  [NO MATCH] ${politician.fullName} (${politician.office}): no committees matched.`);
      } else {
        for (const m of matched) {
          console.log(`  [MATCH] ${politician.fullName} -> cmt_id ${m.cmtId} "${m.cmtNm}"`);
        }
        if (matched.length > 1) {
          console.log(`  [INFO] ${politician.fullName}: ${matched.length} matching committees (multiple election cycles — all will be seeded)`);
        }
      }
    }

    // Seed confirmed rows (skip if dry-run)
    if (result.matches.length === 0) {
      result.status = 'no_match';
      results.push(result);
      continue;
    }

    // Check if politician already has all these cmt_ids confirmed (e.g. Traci Park)
    const confirmedSet = existingConfirmedMap.get(politicianId) ?? new Set<string>();
    const unconfirmedMatches = result.matches.filter(m => !confirmedSet.has(m.cmtId));

    if (unconfirmedMatches.length === 0 && result.matches.length > 0) {
      // All matched cmt_ids already confirmed
      result.status = 'already_confirmed';
      results.push(result);
      continue;
    }

    if (isDryRun) {
      result.status = 'dry_run';
      result.seedResults = result.matches.map(m => ({
        cmtId: m.cmtId,
        result: 'skipped_dry_run' as SeedResult,
      }));
      results.push(result);
      continue;
    }

    // Live mode: seed each matched committee
    let anySeeded = false;
    for (const m of result.matches) {
      if (confirmedSet.has(m.cmtId)) {
        result.seedResults.push({ cmtId: m.cmtId, result: 'already_confirmed' });
        console.log(`  [ALREADY_CONFIRMED] ${politician.fullName} cmt_id=${m.cmtId}`);
        continue;
      }

      const seedResult = await seedConfirmedSource(politicianId, m.cmtId, m.cmtNm);
      result.seedResults.push({ cmtId: m.cmtId, result: seedResult });
      console.log(`  [${seedResult.toUpperCase()}] ${politician.fullName} cmt_id=${m.cmtId} "${m.cmtNm}"`);

      if (seedResult === 'inserted' || seedResult === 'promoted') {
        anySeeded = true;
      }
    }

    result.status = anySeeded ? 'confirmed' : 'already_confirmed';
    results.push(result);
  }

  // Print summary table
  printSummaryTable(results);

  // Step 5: Trigger ingest (live mode only)
  if (!isDryRun) {
    console.log('\n[Step 5] Triggering runAdapterForAll("la_socrata")...');
    await runAdapterForAll('la_socrata');
    console.log('[seed-la-city-confirmed] Ingest complete.');
  }

  const durationMs = Date.now() - startMs;
  console.log(`\n[seed-la-city-confirmed] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

main()
  .then(async () => {
    await pool.end();
    process.exit(0);
  })
  .catch(async err => {
    console.error('[seed-la-city-confirmed] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
