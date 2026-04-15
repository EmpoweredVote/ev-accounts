/**
 * seed-la-county-netfile.ts — Seed confirmed politician_sources rows for the 8 LA County
 * officeholders using their Netfile Filer_IDs.
 *
 * Purpose: Links each LA County officeholder in essentials.politicians to their
 * LA County Netfile committee Filer_ID(s) so netfileAdapter can ingest their
 * contribution data.
 *
 * Usage:
 *   npx tsx scripts/seed-la-county-netfile.ts --dry-run   # print plan, no DB writes
 *   npx tsx scripts/seed-la-county-netfile.ts             # write to DB
 *
 * Workflow:
 *   1. Run discover-netfile-filers.ts --all-years first to find Filer_IDs
 *   2. Operator reviews discovery output, picks correct Filer_IDs per politician
 *   3. Fill in the filerIds arrays in TARGET_POLITICIANS below
 *   4. Run this script with --dry-run to verify, then without --dry-run to seed
 *
 * DB full_names confirmed (2026-04-15):
 *   - "Hilda L. Solis"      (Supervisor D1) — exists in essentials.politicians
 *   - "Holly J. Mitchell"   (Supervisor D2) — exists
 *   - "Lindsey P. Horvath"  (Supervisor D3) — exists
 *   - "Janice Hahn"         (Supervisor D4) — exists
 *   - "Kathryn Barger"      (Supervisor D5) — exists
 *   - "Nathan Hochman"      (District Attorney) — exists
 *   - "Robert Luna"         (Sheriff) — exists
 *   - "Jeff Prang"          (Assessor) — exists as "Jeff Prang" (NOT "Jeffrey Prang")
 *
 * IMPORTANT: Assessor is "Jeff Prang" in the DB (not "Jeffrey Prang").
 * The discover script targets "prang" so it will find him regardless.
 */

import 'dotenv/config';
import { Pool } from 'pg';

// ---------------------------------------------------------------------------
// Env guard
// ---------------------------------------------------------------------------

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

const isDryRun = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// DB pool
// ---------------------------------------------------------------------------

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Target politicians
// ---------------------------------------------------------------------------

interface TargetPolitician {
  fullName: string;      // exact essentials.politicians.full_name to look up
  officeTitle: string;   // for INSERT if politician not found
  jurisdiction: string;  // 'Los Angeles County'
  state: string;         // 'CA'
  district?: string;     // '1', '2', '3', '4', '5' or undefined
  filerIds: string[];    // confirmed Filer_IDs — EMPTY TO START, filled after checkpoint
}

const TARGET_POLITICIANS: TargetPolitician[] = [
  {
    fullName: 'Hilda L. Solis',
    officeTitle: 'County Supervisor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    district: '1',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Holly J. Mitchell',
    officeTitle: 'County Supervisor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    district: '2',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Lindsey P. Horvath',
    officeTitle: 'County Supervisor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    district: '3',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Janice Hahn',
    officeTitle: 'County Supervisor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    district: '4',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Kathryn Barger',
    officeTitle: 'County Supervisor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    district: '5',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Nathan Hochman',
    officeTitle: 'District Attorney',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    fullName: 'Robert Luna',
    officeTitle: 'Sheriff',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
  {
    // IMPORTANT: DB full_name is "Jeff Prang" (not "Jeffrey Prang")
    // The discover script uses search term "prang" so will find him correctly.
    // Use "Jeff Prang" here to match the existing DB record.
    fullName: 'Jeff Prang',
    officeTitle: 'Assessor',
    jurisdiction: 'Los Angeles County',
    state: 'CA',
    filerIds: [], // TODO: fill after operator reviews discover-netfile-filers.ts output
  },
];

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

type SeedResult = 'inserted' | 'already_confirmed' | 'skipped_no_filer_ids' | 'skipped_dry_run' | 'politician_inserted';

interface RowResult {
  filerId: string;
  result: SeedResult;
}

interface PoliticianResult {
  fullName: string;
  officeTitle: string;
  district?: string;
  politicianId: string | null;
  wasInserted: boolean;
  rowResults: RowResult[];
  status: 'seeded' | 'already_confirmed' | 'skipped' | 'no_filer_ids' | 'no_uuid' | 'dry_run';
}

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

async function lookupPoliticianId(fullName: string): Promise<string | null> {
  const res = await pool.query<{ id: string }>(
    `SELECT id FROM essentials.politicians WHERE full_name = $1 LIMIT 1`,
    [fullName]
  );
  return res.rows[0]?.id ?? null;
}

async function insertPolitician(politician: TargetPolitician): Promise<string | null> {
  // Build district info for notes
  const notes: Record<string, string> = {
    jurisdiction: politician.jurisdiction,
    seeded_by: 'seed-la-county-netfile.ts',
  };
  if (politician.district) {
    notes.district = politician.district;
  }

  const res = await pool.query<{ id: string }>(
    `INSERT INTO essentials.politicians
       (full_name, is_active, is_vacant, is_incumbent)
     VALUES ($1, true, false, true)
     ON CONFLICT DO NOTHING
     RETURNING id`,
    [politician.fullName]
  );

  if ((res.rowCount ?? 0) > 0) {
    const politicianId = res.rows[0].id;

    // Also insert an office record
    await pool.query(
      `INSERT INTO essentials.offices
         (politician_id, title, representing_state)
       VALUES ($1, $2, $3)
       ON CONFLICT (politician_id) DO NOTHING`,
      [politicianId, politician.officeTitle, politician.state]
    );

    return politicianId;
  }

  // ON CONFLICT hit — look it up
  return lookupPoliticianId(politician.fullName);
}

async function seedPoliticianSource(
  politicianId: string,
  filerId: string
): Promise<'inserted' | 'already_confirmed'> {
  const notes = JSON.stringify({
    seeded_by: 'seed-la-county-netfile.ts',
    source: 'LA County Netfile FPPC CA-460',
  });

  const res = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'la_county_netfile', $2, 'confirmed', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [politicianId, filerId, notes]
  );

  if ((res.rowCount ?? 0) > 0) return 'inserted';
  return 'already_confirmed';
}

// ---------------------------------------------------------------------------
// Summary table
// ---------------------------------------------------------------------------

function printSummaryTable(results: PoliticianResult[]): void {
  console.log('\n=== LA COUNTY NETFILE SOURCE SEEDING SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no DB writes made)\n');
  }

  const col1 = 22;
  const col2 = 22;
  const col3 = 36;
  const col4 = 18;

  const header =
    ' ' +
    'POLITICIAN'.padEnd(col1) +
    '| ' +
    'OFFICE'.padEnd(col2) +
    '| ' +
    'FILER_IDS'.padEnd(col3) +
    '| STATUS';

  const divider = '-'.repeat(header.length);
  console.log(header);
  console.log(divider);

  for (const r of results) {
    const filerStr =
      r.rowResults.length === 0
        ? '(none configured)'
        : r.rowResults
            .map((row) => `${row.filerId}[${row.result}]`)
            .join(', ');

    const officeLabel = r.district
      ? `${r.officeTitle} D${r.district}`
      : r.officeTitle;

    const statusStr =
      r.wasInserted ? `${r.status} (politician inserted)` : r.status;

    console.log(
      ' ' +
        r.fullName.padEnd(col1) +
        '| ' +
        officeLabel.padEnd(col2) +
        '| ' +
        filerStr.padEnd(col3) +
        '| ' +
        statusStr
    );
  }

  console.log(divider);

  const insertedRows = results.reduce(
    (sum, r) => sum + r.rowResults.filter((row) => row.result === 'inserted').length,
    0
  );
  const alreadyConfirmed = results.reduce(
    (sum, r) => sum + r.rowResults.filter((row) => row.result === 'already_confirmed').length,
    0
  );
  const skipped = results.filter((r) => r.status === 'no_filer_ids').length;
  const newPoliticians = results.filter((r) => r.wasInserted).length;

  console.log(`\nNew politician_sources rows inserted: ${insertedRows}`);
  console.log(`Already confirmed (skipped):         ${alreadyConfirmed}`);
  console.log(`Skipped (no filerIds configured):    ${skipped}`);
  console.log(`New politicians inserted:             ${newPoliticians}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log(
    '[seed-la-county-netfile] Mode: ' +
      (isDryRun ? 'DRY-RUN (no DB writes)' : 'LIVE')
  );

  const results: PoliticianResult[] = [];

  for (const politician of TARGET_POLITICIANS) {
    const result: PoliticianResult = {
      fullName: politician.fullName,
      officeTitle: politician.officeTitle,
      district: politician.district,
      politicianId: null,
      wasInserted: false,
      rowResults: [],
      status: 'skipped',
    };

    // Skip politicians with no Filer_IDs configured yet
    if (politician.filerIds.length === 0) {
      console.log(`SKIP: ${politician.fullName} — no filerIds configured yet`);
      result.status = 'no_filer_ids';
      results.push(result);
      continue;
    }

    // Look up politician UUID
    let politicianId = await lookupPoliticianId(politician.fullName);

    if (!politicianId) {
      // Not found — insert if not dry-run
      if (isDryRun) {
        console.log(
          `  [DRY-RUN] ${politician.fullName} not in DB — would INSERT into essentials.politicians`
        );
        result.status = 'dry_run';
        result.rowResults = politician.filerIds.map((id) => ({
          filerId: id,
          result: 'skipped_dry_run' as SeedResult,
        }));
        results.push(result);
        continue;
      }

      console.log(
        `  [INSERT] ${politician.fullName} not found in essentials.politicians — inserting...`
      );
      politicianId = await insertPolitician(politician);
      result.wasInserted = true;
    }

    if (!politicianId) {
      console.error(
        `  [ERROR] Could not find or insert politician: ${politician.fullName}`
      );
      result.status = 'no_uuid';
      results.push(result);
      continue;
    }

    result.politicianId = politicianId;

    if (isDryRun) {
      console.log(
        `  [DRY-RUN] ${politician.fullName} (${politicianId}) — would seed filerIds: ${politician.filerIds.join(', ')}`
      );
      result.status = 'dry_run';
      result.rowResults = politician.filerIds.map((id) => ({
        filerId: id,
        result: 'skipped_dry_run' as SeedResult,
      }));
      results.push(result);
      continue;
    }

    // Seed each Filer_ID as a confirmed politician_sources row
    let anyInserted = false;
    for (const filerId of politician.filerIds) {
      const seedResult = await seedPoliticianSource(politicianId, filerId);
      result.rowResults.push({ filerId, result: seedResult });
      console.log(
        `  [${seedResult.toUpperCase()}] ${politician.fullName} Filer_ID=${filerId}`
      );
      if (seedResult === 'inserted') anyInserted = true;
    }

    result.status = anyInserted ? 'seeded' : 'already_confirmed';
    results.push(result);
  }

  printSummaryTable(results);

  const durationMs = Date.now() - startMs;
  console.log(
    `\n[seed-la-county-netfile] Completed in ${(durationMs / 1000).toFixed(1)}s`
  );
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

main()
  .then(async () => {
    await pool.end();
    process.exit(0);
  })
  .catch(async (err) => {
    console.error('[seed-la-county-netfile] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
