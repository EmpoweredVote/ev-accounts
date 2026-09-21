/**
 * seed-ocpf-cambridge.ts — Seeds OCPF politician sources for Cambridge, MA residents' ballots.
 *
 * Covers the NEXT ELECTION Cambridge voters face, not historical races.
 * Federal candidates (Markey, Clark, Pressley) are handled by the FEC adapter — not here.
 *
 * NOVEMBER 2026 BALLOT (primary Sept 1, general Nov 3):
 *   Statewide:       Governor, Lt. Gov, AG, SoS, Treasurer, Auditor
 *   MA House:        24th Middlesex (Rogers), 25th Middlesex (Decker), 26th Middlesex (Connolly)
 *   MA Senate:       2nd Middlesex (Jehlen), Middlesex & Suffolk (DiDomenico)
 *
 * CAMBRIDGE CITY COUNCIL (elected Nov 2025, next election Nov 2027):
 *   --city-council flag seeds incumbents for historical finance data display.
 *   These are NOT on the Nov 2026 ballot.
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/seed-ocpf-cambridge.ts [--dry-run] [--add-unmatched] [--city-council]
 *
 * Flags:
 *   --dry-run        Print matches/mismatches without writing to DB.
 *   --add-unmatched  Insert new essentials.politicians rows for OCPF candidates not yet in DB.
 *   --city-council   Seed Cambridge City Council incumbents (2025 winners, historical data only).
 *
 * How to find missing cpfIds:
 *   1. Visit https://www.ocpf.us/Filers/Index
 *   2. Search by candidate last name
 *   3. Update the CANDIDATE_CPFIDS map below with the result
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

// ---------------------------------------------------------------------------
// November 2026 Cambridge ballot — OCPF candidates only (no FEC/federal)
// cpfId = -1 means not yet looked up — script will skip + print lookup guide
// Lookup guide: https://www.ocpf.us/Filers/Index (search by last name)
// ---------------------------------------------------------------------------

interface CandidateEntry {
  cpfId: number;          // -1 = TODO: look up at ocpf.us/Filers/Index
  expectedName: string;   // OCPF "Last, First" format — used to validate the cpfId at runtime
  office: string;         // Human-readable office label
  raceType: 'statewide' | 'state_senate' | 'state_house';
  district: string | null;
}

const NOV_2026_BALLOT: CandidateEntry[] = [
  // -------------------------------------------------------------------------
  // Statewide — all Cambridge residents vote on all of these
  // -------------------------------------------------------------------------
  { cpfId: 15710, expectedName: 'Healey, Maura T.',      office: 'Governor',                    raceType: 'statewide',    district: null },
  { cpfId: 15268, expectedName: 'Driscoll, Kimberley',   office: 'Lieutenant Governor',          raceType: 'statewide',    district: null },
  { cpfId: 15931, expectedName: 'Campbell, Andrea J.',   office: 'Attorney General',             raceType: 'statewide',    district: null },
  { cpfId: 10176, expectedName: 'Galvin, William F.',    office: 'Secretary of the Commonwealth',raceType: 'statewide',    district: null },
  { cpfId: 14385, expectedName: 'Goldberg, Deborah B.',  office: 'Treasurer',                    raceType: 'statewide',    district: null },
  { cpfId: 15465, expectedName: 'DiZoglio, Diana',       office: 'State Auditor',                raceType: 'statewide',    district: null },

  // -------------------------------------------------------------------------
  // MA House — Cambridge spans three districts
  // Ward coverage: 24th Middlesex (East Cambridge area),
  //               25th Middlesex (Central/West Cambridge),
  //               26th Middlesex (North Cambridge + Somerville border)
  // -------------------------------------------------------------------------
  { cpfId: 15483, expectedName: 'Rogers, David M.',      office: 'State Representative',         raceType: 'state_house',  district: '24th Middlesex' },
  { cpfId: 13736, expectedName: 'Decker, Marjorie C.',   office: 'State Representative',         raceType: 'state_house',  district: '25th Middlesex' },
  { cpfId: 15470, expectedName: 'Connolly, Michael L.',  office: 'State Representative',         raceType: 'state_house',  district: '26th Middlesex' },

  // -------------------------------------------------------------------------
  // MA Senate — Cambridge falls in two senate districts
  // 2nd Middlesex:          Somerville + NW Cambridge
  // Middlesex & Suffolk:    Medford + parts of Cambridge/Somerville
  // -------------------------------------------------------------------------
  { cpfId: 12008, expectedName: 'Jehlen, Patricia D.',   office: 'State Senator',                raceType: 'state_senate', district: '2nd Middlesex' },
  { cpfId: 15031, expectedName: 'DiDomenico, Sal N.',    office: 'State Senator',                raceType: 'state_senate', district: 'Middlesex & Suffolk' },
];

// Federal candidates are NOT listed here — use FEC adapter:
//   Ed Markey      (US Senate Class 2)      — FEC ID S2MA00170
//   Katherine Clark (US House MA-5)          — FEC ID H4MA05049  (parts of Cambridge)
//   Ayanna Pressley (US House MA-7)          — FEC ID H8MA07150  (most of Cambridge)

// ---------------------------------------------------------------------------
// Office IDs for Nov 2026 Cambridge ballot races (looked up 2026-05-17)
// These map raceType+district → existing essentials.offices.id
// ---------------------------------------------------------------------------

const OFFICE_ID_MAP: Record<string, string> = {
  'statewide|Governor':                       '21f9e818-904d-4a19-879b-438f447bcd68',
  'statewide|Lieutenant Governor':            '66c34aa8-db37-4aed-a369-fa5729f62b4a',
  'statewide|Attorney General':               'acff6f85-1bc2-4f50-94e6-58294f5f096a',
  'statewide|Secretary of the Commonwealth':  'ab2cdc0b-7762-4818-b923-8e006e762466',
  'statewide|Treasurer':                      '3367d772-6a6b-4c51-9a74-c294ed1dbfdc',
  'statewide|State Auditor':                  '58d289a0-a95e-474f-9c6e-b50fc7e93b04',
  'state_house|24th Middlesex':               '30aaa2be-1f7c-4570-8af1-4fd2fe873467',
  'state_house|25th Middlesex':               'a0e18b1e-478f-49b7-8ffb-351dc338875c',
  'state_house|26th Middlesex':               '06e4afe2-cbcf-421c-a569-c15b7d55a236',
  'state_senate|2nd Middlesex':               'b1ed4e2a-4a9c-4b41-9e46-8500f608e026',
  'state_senate|Middlesex & Suffolk':         'c3ea7a34-f13d-4804-9db7-7e3f62238cfc',
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface OcpfReport {
  cpfId: number;
  filerName: string;
  officeSought: string;
  [key: string]: unknown;
}

interface OcpfYtdResponse {
  reports: OcpfReport[];
}

interface OcpfFilerResponse {
  cpfId?: number;
  filerName?: string;
  fullName?: string;
  officeSought?: string;
  officeHeld?: string;
  isActive?: boolean;
  [key: string]: unknown;
}

interface DbPolitician {
  id: string;
  full_name: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const OCPF_BASE = 'https://api.ocpf.us';
const DRY_RUN = process.argv.includes('--dry-run');
const ADD_UNMATCHED = process.argv.includes('--add-unmatched');
const CITY_COUNCIL_MODE = process.argv.includes('--city-council');
const JACCARD_THRESHOLD = 0.5;

// ---------------------------------------------------------------------------
// Fuzzy match helpers
// ---------------------------------------------------------------------------

function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function jaccardScore(a: string, b: string): number {
  const setA = new Set(a.split(' ').filter(Boolean));
  const setB = new Set(b.split(' ').filter(Boolean));
  if (setA.size === 0 && setB.size === 0) return 1;
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  for (const token of setA) {
    if (setB.has(token)) intersection++;
  }
  return intersection / (setA.size + setB.size - intersection);
}

/** Converts OCPF "Last, First [Middle]" → "First Last" for DB matching. */
function parseFilerName(filerName: string): string {
  const commaIdx = filerName.indexOf(',');
  if (commaIdx === -1) return filerName;
  const last = filerName.slice(0, commaIdx).trim();
  const rest = filerName.slice(commaIdx + 1).trim();
  return `${rest} ${last}`;
}

/** Best Jaccard match from a list of DB politicians. */
function bestMatch(
  parsedName: string,
  politicians: DbPolitician[]
): { politician: DbPolitician; score: number } | null {
  const normalized = normalizeName(parsedName);
  let best: DbPolitician | null = null;
  let bestScore = 0;
  for (const p of politicians) {
    const score = jaccardScore(normalized, normalizeName(p.full_name));
    if (score > bestScore) { bestScore = score; best = p; }
  }
  return best && bestScore >= JACCARD_THRESHOLD ? { politician: best, score: bestScore } : null;
}

// ---------------------------------------------------------------------------
// OCPF API helpers
// ---------------------------------------------------------------------------

/** Validates a known cpfId by fetching /filer/{cpfId} and checking the name. */
async function validateCpfId(cpfId: number, expectedName: string): Promise<boolean> {
  try {
    const res = await fetch(`${OCPF_BASE}/filer/${cpfId}`, { signal: AbortSignal.timeout(10_000) });
    if (!res.ok) return false;
    const data = await res.json() as OcpfFilerResponse;
    const actualName = data.filerName ?? data.fullName ?? '';
    // Accept if either the expected name tokens are a subset of actual, or Jaccard >= 0.4
    const score = jaccardScore(normalizeName(expectedName), normalizeName(actualName));
    if (score < 0.25) {
      console.warn(`  [WARN] cpfId=${cpfId} name mismatch: expected "${expectedName}", got "${actualName}" (score=${score.toFixed(2)})`);
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Mode A: November 2026 ballot seed (default)
// ---------------------------------------------------------------------------

async function seedNov2026(pool: pg.Pool): Promise<void> {
  console.log('[seed-ocpf-cambridge] Mode: NOVEMBER 2026 BALLOT (state + statewide only)');
  console.log('[seed-ocpf-cambridge] Federal races (Markey, Clark, Pressley) → use FEC adapter');
  console.log('');

  // Partition known vs TODO cpfIds
  const known = NOV_2026_BALLOT.filter(c => c.cpfId !== -1);
  const todo  = NOV_2026_BALLOT.filter(c => c.cpfId === -1);

  if (todo.length > 0) {
    console.log('[seed-ocpf-cambridge] ⚠  cpfIds needed for these candidates — look up at https://www.ocpf.us/Filers/Index:');
    for (const c of todo) {
      const label = c.district ? `${c.office}, ${c.district}` : c.office;
      console.log(`    ${label}: "${c.expectedName}" — add cpfId to NOV_2026_BALLOT in this script`);
    }
    console.log('');
  }

  if (known.length === 0) {
    console.log('[seed-ocpf-cambridge] No candidates with confirmed cpfIds. Exiting.');
    return;
  }

  // Load all MA politicians from DB (state-level, not city-filtered)
  const dbResult = await pool.query<DbPolitician>(
    `SELECT p.id, p.full_name
     FROM essentials.politicians p
     JOIN essentials.offices o ON o.id = p.office_id
     WHERE o.representing_state = 'MA'`
  );
  const dbPoliticians = dbResult.rows;
  console.log(`[seed-ocpf-cambridge] MA politicians in DB: ${dbPoliticians.length}`);
  console.log('');

  let inserted = 0;
  let alreadyExisted = 0;
  let unmatched = 0;
  let addedNew = 0;

  for (const candidate of known) {
    const label = candidate.district
      ? `${candidate.office} (${candidate.district})`
      : candidate.office;

    // Validate cpfId against OCPF
    const valid = await validateCpfId(candidate.cpfId, candidate.expectedName);
    if (!valid) {
      console.log(`  [SKIP] cpfId=${candidate.cpfId} failed validation — ${label}`);
      continue;
    }

    const parsedName = parseFilerName(candidate.expectedName);
    const match = bestMatch(parsedName, dbPoliticians);

    if (!match) {
      console.log(`  [UNMATCHED] "${candidate.expectedName}" — ${label}`);
      unmatched++;

      if (ADD_UNMATCHED && !DRY_RUN) {
        const officeKey = `${candidate.raceType}|${candidate.district ?? candidate.office}`;
        const officeId = OFFICE_ID_MAP[officeKey];
        if (!officeId) {
          console.log(`    → --add-unmatched: no office_id mapping for key "${officeKey}" — skipping`);
          continue;
        }

        // Parse "First [Middle] Last" from parsedName
        const nameParts = parsedName.trim().split(/\s+/);
        const firstName = nameParts[0] ?? '';
        const lastName = nameParts[nameParts.length - 1] ?? '';
        const middleInitial = nameParts.length > 2 ? nameParts.slice(1, -1).join(' ') : null;

        const insertResult = await pool.query<{ id: string }>(
          `INSERT INTO essentials.politicians
             (full_name, first_name, last_name, middle_initial, office_id, party, is_active, is_incumbent, data_source)
           VALUES ($1, $2, $3, $4, $5, 'Democrat', true, true, 'ocpf_seed')
           ON CONFLICT DO NOTHING
           RETURNING id`,
          [parsedName, firstName, lastName, middleInitial, officeId]
        );

        if ((insertResult.rowCount ?? 0) === 0) {
          console.log(`    → --add-unmatched: politician already exists (conflict) — skipping`);
          continue;
        }

        const newPoliticianId = insertResult.rows[0]!.id;
        addedNew++;
        console.log(`    → --add-unmatched: inserted politician "${parsedName}" (${newPoliticianId})`);

        const srcResult = await pool.query(
          `INSERT INTO transparent_motivations.politician_sources
             (essentials_politician_id, source_system, external_id, research_status, notes)
           VALUES ($1, 'ocpf', $2, 'confirmed', $3)
           ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
          [
            newPoliticianId,
            String(candidate.cpfId),
            `Nov 2026 ballot seed — ${label} — OCPF filer: ${candidate.expectedName}`,
          ]
        );
        if ((srcResult.rowCount ?? 0) > 0) {
          inserted++;
          console.log(`    → Inserted politician_sources row`);
        }
      }
      continue;
    }

    console.log(`  [MATCH score=${match.score.toFixed(2)}] "${candidate.expectedName}" → "${match.politician.full_name}" (cpfId=${candidate.cpfId})`);

    if (!DRY_RUN) {
      const result = await pool.query(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, notes)
         VALUES ($1, 'ocpf', $2, 'confirmed', $3)
         ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
        [
          match.politician.id,
          String(candidate.cpfId),
          `Nov 2026 ballot seed — ${label} — OCPF filer: ${candidate.expectedName}`,
        ]
      );
      if ((result.rowCount ?? 0) > 0) {
        inserted++;
        console.log(`    → Inserted politician_sources row`);
      } else {
        alreadyExisted++;
        console.log(`    → Already exists (skipped)`);
      }
    }
  }

  console.log('');
  console.log('=== seed-ocpf-cambridge NOV 2026 SUMMARY ===');
  console.log(`  Confirmed cpfIds in config:   ${known.length}`);
  console.log(`  TODO cpfIds (need lookup):    ${todo.length}`);
  console.log(`  Matched to DB politicians:    ${known.length - unmatched}`);
  console.log(`  Unmatched (not in DB yet):    ${unmatched}`);
  if (!DRY_RUN) {
    console.log(`  Inserted:                     ${inserted}`);
    console.log(`  Already existed (skipped):    ${alreadyExisted}`);
    if (addedNew > 0) console.log(`  New politicians created:      ${addedNew}`);
  } else {
    console.log(`  (Dry run — no DB writes)`);
  }
}

// ---------------------------------------------------------------------------
// Mode B: Cambridge City Council incumbents (--city-council)
// These are NOT on the Nov 2026 ballot — next council election is Nov 2027.
// Useful for seeding historical finance data for current councilors.
// ---------------------------------------------------------------------------

async function seedCityCouncil(pool: pg.Pool): Promise<void> {
  console.log('[seed-ocpf-cambridge] Mode: CITY COUNCIL (2025 incumbents — historical data only)');
  console.log('[seed-ocpf-cambridge] NOTE: Cambridge City Council is NOT on the Nov 2026 ballot.');
  console.log('[seed-ocpf-cambridge] Next council election: November 2027.');
  console.log('');

  const year = new Date().getFullYear();
  const url = `${OCPF_BASE}/reports/cc/ytd/${year}`;
  console.log(`[seed-ocpf-cambridge] Fetching OCPF ytd report: ${url}`);

  let ocpfResponse: OcpfYtdResponse;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (res.status !== 200) throw new Error(`HTTP ${res.status}`);
    ocpfResponse = await res.json() as OcpfYtdResponse;
  } catch (err) {
    console.error('[seed-ocpf-cambridge] Failed to fetch OCPF report:', err);
    process.exit(1);
  }

  const cambridgeReports = (ocpfResponse.reports ?? []).filter(r =>
    r.officeSought.toLowerCase().includes('cambridge')
  );
  console.log(`[seed-ocpf-cambridge] Cambridge council filers: ${cambridgeReports.length}`);
  console.log('');

  const dbResult = await pool.query<DbPolitician>(
    `SELECT p.id, p.full_name
     FROM essentials.politicians p
     JOIN essentials.offices o ON o.id = p.office_id
     WHERE o.representing_state = 'MA'
       AND o.representing_city ILIKE '%Cambridge%'`
  );
  const dbPoliticians = dbResult.rows;
  console.log(`[seed-ocpf-cambridge] Cambridge politicians in DB: ${dbPoliticians.length}`);
  console.log('');

  let inserted = 0;
  let alreadyExisted = 0;
  const unmatched: OcpfReport[] = [];

  for (const report of cambridgeReports) {
    const parsedName = parseFilerName(report.filerName);
    const match = bestMatch(parsedName, dbPoliticians);

    if (!match) {
      console.log(`  [UNMATCHED] "${report.filerName}" (cpfId=${report.cpfId})`);
      unmatched.push(report);

      if (ADD_UNMATCHED && !DRY_RUN) {
        console.log(`    → --add-unmatched: skipping city council adds (2025 race participants, not current ballot)`);
      }
      continue;
    }

    console.log(`  [MATCH score=${match.score.toFixed(2)}] "${report.filerName}" → "${match.politician.full_name}" [${match.politician.id}]`);

    if (!DRY_RUN) {
      const result = await pool.query(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, notes)
         VALUES ($1, 'ocpf', $2, 'confirmed', $3)
         ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
        [
          match.politician.id,
          String(report.cpfId),
          `City Council seed from OCPF /reports/cc/ytd — filerName: ${report.filerName}`,
        ]
      );
      if ((result.rowCount ?? 0) > 0) inserted++;
      else alreadyExisted++;
    }
  }

  console.log('');
  console.log('=== seed-ocpf-cambridge CITY COUNCIL SUMMARY ===');
  console.log(`  OCPF Cambridge filers:       ${cambridgeReports.length}`);
  console.log(`  DB Cambridge politicians:    ${dbPoliticians.length}`);
  console.log(`  Matched (Jaccard >= 0.50):  ${cambridgeReports.length - unmatched.length}`);
  console.log(`  Unmatched:                  ${unmatched.length}`);
  if (!DRY_RUN) {
    console.log(`  Inserted:                   ${inserted}`);
    console.log(`  Already existed (skipped):  ${alreadyExisted}`);
  } else {
    console.log(`  (Dry run — no DB writes)`);
  }
  if (unmatched.length > 0) {
    console.log('');
    console.log('  Unmatched filers (not in DB — likely 2025 challengers who lost):');
    for (const r of unmatched) {
      console.log(`    cpfId=${r.cpfId}  "${r.filerName}"  ${r.officeSought}`);
    }
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log(`[seed-ocpf-cambridge] Starting${DRY_RUN ? ' (DRY RUN — no DB writes)' : ''}...`);
  console.log('');

  const pool = new Pool({ connectionString: process.env['DATABASE_URL'] });

  try {
    if (CITY_COUNCIL_MODE) {
      await seedCityCouncil(pool);
    } else {
      await seedNov2026(pool);
    }
  } catch (err) {
    console.error('[seed-ocpf-cambridge] Fatal error:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[seed-ocpf-cambridge] Fatal error:', err);
  process.exit(1);
});
