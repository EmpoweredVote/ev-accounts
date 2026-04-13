/**
 * ingest-ca-sos-2026-challengers.ts — CA 2026 Primary challenger ingestion
 *
 * Usage:
 *   npx tsx scripts/ingest-ca-sos-2026-challengers.ts             # dry-run (default)
 *   npx tsx scripts/ingest-ca-sos-2026-challengers.ts --commit     # write to DB
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * What it does:
 *   1. Looks up the '2026 LA County Primary' election record.
 *   2. For each race in CHALLENGERS, finds the matching race by position_name.
 *   3. Inserts challengers as race_candidates with is_incumbent=false.
 *   4. Idempotent — skips by name collision within the same race.
 *
 * DATA PROVENANCE — READ BEFORE ADDING CANDIDATES:
 *   Only add candidates to this script from a citable, human-verified source.
 *   Do NOT add candidates based on inference, prior election history, or speculation.
 *   Each section below must reference its source URL/publication and date.
 *
 *   All other races (Lt. Gov, AG, SoS, Treasurer, Controller, Insurance, Supt.,
 *   Assembly D54, Senate D26, CD-34, Sheriff, Assessor, LAUSD) currently have
 *   incumbents only. Add challengers to those races when a verified source is available.
 *
 * CA is a "top-2 jungle primary" state:
 *   - ALL candidates appear on one primary ballot regardless of party
 *   - races.primary_party = NULL for ALL CA race records
 *
 * ANTIPARTISAN POLICY: No party column is stored on race_candidates.
 *   Party affiliation is excluded per EV design (see importElectionData.ts header).
 */

import 'dotenv/config';
import path from 'path';
import { fileURLToPath } from 'url';
import { Pool, PoolClient } from 'pg';

// ---------------------------------------------------------------------------
// ESM __dirname shim
// ---------------------------------------------------------------------------
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ---------------------------------------------------------------------------
// Load .env from backend root
// ---------------------------------------------------------------------------
import dotenv from 'dotenv';
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
const isCommit = args.includes('--commit');
const isDryRun = !isCommit;

// ---------------------------------------------------------------------------
// DB pool
// ---------------------------------------------------------------------------
if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set. Add it to backend/.env');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface ChallengerEntry {
  /** Must match races.position_name exactly */
  race_position_name: string;
  full_name: string;
  first_name: string;
  last_name: string;
  /** Source tag stored in race_candidates.source — should match the data's origin */
  source: string;
  /** Stable external ID for idempotency. Format: {source}-{normalized-name} */
  external_id: string;
}

function makeExternalId(source: string, fullName: string): string {
  const normalized = fullName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${source}-${normalized}`;
}

/**
 * Build a ChallengerEntry with auto-derived external_id.
 */
function c(
  source: string,
  race_position_name: string,
  first_name: string,
  last_name: string,
  full_name_override?: string
): ChallengerEntry {
  const full_name = full_name_override ?? `${first_name} ${last_name}`;
  return {
    race_position_name,
    full_name,
    first_name,
    last_name,
    source,
    external_id: makeExternalId(source, full_name),
  };
}

/**
 * Verified challenger data.
 *
 * Each section must cite its source. Do not add candidates from inference or
 * prior election history — only from a citable human-verified source.
 */
const CHALLENGERS: ChallengerEntry[] = [
  // =========================================================================
  // CA GOVERNOR — open seat (Newsom term-limited; all candidates are challengers)
  // Source: Calmatters — https://calmatters.org/politics/2026/03/california-governor-candidates/
  // Published: 2026-03-06. Verified against DB: 2026-04-13.
  // Note: Eric Swalwell withdrew 2026-04-11 — already in DB as candidate_status='withdrawn'.
  //       This script will skip him on re-run (name collision check).
  // =========================================================================
  c('calmatters-2026', 'CA Governor', 'Xavier',   'Becerra'),
  c('calmatters-2026', 'CA Governor', 'Chad',     'Bianco'),
  c('calmatters-2026', 'CA Governor', 'Steve',    'Hilton'),
  c('calmatters-2026', 'CA Governor', 'Matt',     'Mahan'),
  c('calmatters-2026', 'CA Governor', 'Katie',    'Porter'),
  c('calmatters-2026', 'CA Governor', 'Tom',      'Steyer'),
  c('calmatters-2026', 'CA Governor', 'Tony',     'Thurmond'),
  c('calmatters-2026', 'CA Governor', 'Antonio',  'Villaraigosa'),
  c('calmatters-2026', 'CA Governor', 'Betty',    'Yee'),

  // ---------------------------------------------------------------------------
  // TODO — add challengers for remaining races once a verified source is available:
  //   CA Lieutenant Governor, CA Attorney General, CA Secretary of State,
  //   CA State Treasurer, CA State Controller, CA Insurance Commissioner,
  //   CA Superintendent of Public Instruction, CA State Assembly District 54,
  //   CA State Senate District 26, U.S. Representative District 34,
  //   LA County Sheriff, LA County Assessor, LAUSD Board D2/D4/D6
  // ---------------------------------------------------------------------------
];

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

async function getElectionId(client: PoolClient): Promise<string> {
  const result = await client.query<{ id: string }>(
    `SELECT id FROM essentials.elections WHERE name = $1`,
    ['2026 LA County Primary']
  );
  if (result.rows.length === 0) {
    throw new Error("Election '2026 LA County Primary' not found in DB. Run seed scripts first.");
  }
  return result.rows[0].id;
}

async function getRaceIdByPosition(
  client: PoolClient,
  electionId: string,
  positionName: string
): Promise<string | null> {
  const result = await client.query<{ id: string }>(
    `SELECT id FROM essentials.races
     WHERE election_id = $1 AND position_name = $2 AND primary_party IS NULL`,
    [electionId, positionName]
  );
  return result.rows[0]?.id ?? null;
}

interface InsertResult {
  action: 'inserted' | 'updated' | 'skipped';
  external_id: string;
}

async function upsertChallenger(
  client: PoolClient,
  raceId: string,
  entry: ChallengerEntry
): Promise<InsertResult> {
  // Check if this candidate already exists for this race by external_id
  const existing = await client.query<{ id: string; is_incumbent: boolean }>(
    `SELECT id, is_incumbent FROM essentials.race_candidates
     WHERE external_id = $1`,
    [entry.external_id]
  );

  if (existing.rows.length > 0) {
    // Already exists — update status/name but preserve politician_id (manual link)
    await client.query(
      `UPDATE essentials.race_candidates
       SET full_name        = $1,
           first_name       = $2,
           last_name        = $3,
           is_incumbent     = false,
           candidate_status = 'active',
           last_verified_at = now()
       WHERE external_id = $4`,
      [entry.full_name, entry.first_name, entry.last_name, entry.external_id]
    );
    return { action: 'updated', external_id: entry.external_id };
  }

  // Check for name collision in same race (handles case where external_id is missing
  // but the person was added via a different pathway)
  const nameCheck = await client.query<{ id: string }>(
    `SELECT id FROM essentials.race_candidates
     WHERE race_id = $1 AND full_name = $2`,
    [raceId, entry.full_name]
  );

  if (nameCheck.rows.length > 0) {
    return { action: 'skipped', external_id: entry.external_id };
  }

  // Insert new challenger
  await client.query(
    `INSERT INTO essentials.race_candidates
       (race_id, full_name, first_name, last_name,
        is_incumbent, candidate_status, source, external_id,
        last_verified_at, politician_id)
     VALUES ($1, $2, $3, $4, false, 'active', $5, $6, now(), NULL)`,
    [raceId, entry.full_name, entry.first_name, entry.last_name, entry.source, entry.external_id]
  );
  return { action: 'inserted', external_id: entry.external_id };
}

// ---------------------------------------------------------------------------
// Dry-run preview
// ---------------------------------------------------------------------------

function printDryRunPreview(
  byRace: Map<string, { raceFound: boolean; raceId: string | null; challengers: ChallengerEntry[] }>
): void {
  console.log('\n=== DRY RUN — pass --commit to write to DB ===\n');

  let totalFound = 0;
  let totalMissing = 0;

  for (const [positionName, info] of byRace) {
    const statusIcon = info.raceFound ? '✓' : '✗ RACE NOT FOUND';
    console.log(`\n[${statusIcon}] ${positionName} (${info.challengers.length} challengers)`);
    if (info.raceFound) {
      totalFound += info.challengers.length;
    } else {
      totalMissing += info.challengers.length;
    }
    for (const ch of info.challengers) {
      console.log(`      ${ch.full_name} [external_id: ${ch.external_id}]`);
    }
  }

  console.log('\n--- Summary ---');
  console.log(`  Races found:        ${[...byRace.values()].filter(v => v.raceFound).length}`);
  console.log(`  Races missing:      ${[...byRace.values()].filter(v => !v.raceFound).length}`);
  console.log(`  Challengers ready:  ${totalFound}`);
  console.log(`  Challengers skipped (race not found): ${totalMissing}`);
  console.log('\nRun with --commit to execute inserts.');
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const client = await pool.connect();

  try {
    console.log('\n[ingest-ca-sos-2026-challengers] Starting...');
    console.log(`  Mode: ${isDryRun ? 'DRY RUN (preview only)' : 'COMMIT (writing to DB)'}`);

    // 1. Resolve election
    const electionId = await getElectionId(client);
    console.log(`  Election ID: ${electionId}`);

    // 2. Group challengers by race and resolve race IDs
    const byRace = new Map<
      string,
      { raceFound: boolean; raceId: string | null; challengers: ChallengerEntry[] }
    >();

    for (const entry of CHALLENGERS) {
      if (!byRace.has(entry.race_position_name)) {
        const raceId = await getRaceIdByPosition(client, electionId, entry.race_position_name);
        byRace.set(entry.race_position_name, {
          raceFound: raceId !== null,
          raceId,
          challengers: [],
        });
        if (!raceId) {
          console.warn(`  WARN: Race not found: "${entry.race_position_name}"`);
        }
      }
      byRace.get(entry.race_position_name)!.challengers.push(entry);
    }

    // 3. Dry-run: preview and exit
    if (isDryRun) {
      printDryRunPreview(byRace);
      return;
    }

    // 4. Commit mode: insert within transaction
    await client.query('BEGIN');

    let inserted = 0;
    let updated = 0;
    let skipped = 0;
    let raceMissed = 0;

    for (const [positionName, info] of byRace) {
      if (!info.raceFound || !info.raceId) {
        console.warn(`  SKIP (race not found): ${positionName} — ${info.challengers.length} candidates skipped`);
        raceMissed += info.challengers.length;
        continue;
      }

      console.log(`\n  Processing: ${positionName} (race_id: ${info.raceId})`);

      for (const entry of info.challengers) {
        const result = await upsertChallenger(client, info.raceId, entry);
        const icon = result.action === 'inserted' ? '+' : result.action === 'updated' ? '~' : '=';
        console.log(`    [${icon}] ${result.action.padEnd(8)} ${entry.full_name}`);

        if (result.action === 'inserted') inserted++;
        else if (result.action === 'updated') updated++;
        else skipped++;
      }
    }

    await client.query('COMMIT');

    console.log('\n=== COMMIT COMPLETE ===');
    console.log(`  Inserted: ${inserted}`);
    console.log(`  Updated:  ${updated}`);
    console.log(`  Skipped (name collision): ${skipped}`);
    console.log(`  Skipped (race not found): ${raceMissed}`);
    console.log(`  Total processed: ${CHALLENGERS.length}`);

  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error('\nERROR:', (err as Error).message);
    console.error((err as Error).stack);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

main();
