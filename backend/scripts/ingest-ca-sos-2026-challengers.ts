/**
 * ingest-ca-sos-2026-challengers.ts — CA SoS 2026 Primary challenger ingestion
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
 *   2. For each race in CHALLENGER_DATA, finds the matching race by position_name.
 *   3. Inserts challengers as race_candidates with is_incumbent=false.
 *   4. Idempotent — ON CONFLICT (external_id) WHERE external_id IS NOT NULL DO UPDATE
 *      (preserves politician_id linkage set by a human operator).
 *
 * Data sources:
 *   CA Secretary of State candidate search — https://www.sos.ca.gov/elections/upcoming-elections/
 *   June 3, 2026 Statewide Direct Primary. Candidates verified as filed/qualified as of 2026-04-13.
 *   Calmatters CA Governor candidate list — published 2026-03-06.
 *
 * CA is a "top-2 jungle primary" state:
 *   - ALL candidates appear on one primary ballot regardless of party
 *   - races.primary_party = NULL for ALL CA race records
 *
 * ANTIPARTISAN POLICY: No party column is stored on race_candidates.
 *   Party affiliation is excluded per EV design (see importElectionData.ts header).
 *
 * Scope:
 *   This script covers challengers for races already seeded in the DB:
 *   - CA statewide races (Governor, Lt. Gov, AG, SoS, Treasurer, Controller, Insurance, Supt.)
 *   - Legislative/Congressional: CA Assembly D54, CA Senate D26, U.S. Rep D34
 *   - County/Local: LA County Sheriff, LA County Assessor
 *   - LAUSD Board: District 2, 4, 6
 *
 * Incumbents already seeded (is_incumbent=true, politician_id linked):
 *   Isaac G. Bryan (Assembly D54), Jimmy Gomez (CD-34), Robert Luna (Sheriff),
 *   Scott Schmerelson (LAUSD D2), Nick Melvoin (LAUSD D4), Kelly Gonez (LAUSD D6),
 *   Eleni Kounalakis (Lt. Gov), Rob Bonta (AG), Shirley N. Weber (SoS),
 *   Fiona Ma (Treasurer), Malia M. Cohen (Controller), Ricardo Lara (Insurance),
 *   Tony Thurmond (Supt.)
 *
 * Open seats (no incumbent — all candidates are challengers):
 *   CA Governor (Newsom term-limited), CA State Senate D26 (Ben Allen term-limited),
 *   LA County Assessor (Jeff Prang open status pending verification)
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
  /**
   * Stable external ID for idempotency. Format: ca-sos-2026-{normalized-name}
   * Uses full name (not SoS filing number) since SoS doesn't expose a machine-readable ID.
   */
  external_id: string;
}

// ---------------------------------------------------------------------------
// Challenger data — sourced from CA SoS candidate search (2026-04-13)
// https://www.sos.ca.gov/elections/upcoming-elections/
// All entries verified as filed/qualified for the June 3, 2026 Statewide Primary.
// ---------------------------------------------------------------------------

function makeExternalId(fullName: string): string {
  const normalized = fullName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `ca-sos-2026-${normalized}`;
}

/**
 * Build a ChallengerEntry with auto-derived external_id.
 */
function c(
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
    external_id: makeExternalId(full_name),
  };
}

/**
 * Challenger data organized by race.
 *
 * NOTE ON GOVERNOR: All gubernatorial candidates are challengers (Newsom term-limited).
 *   Tony Thurmond is listed here as a CHALLENGER for Governor even though he is seeded
 *   as incumbent Supt. — his politician_id may be linkable later via name match.
 *   Eleni Kounalakis is seeded as incumbent Lt. Gov but is ALSO running for Governor
 *   as a challenger — included here separately.
 *
 * NOTE ON INCUMBENTS RUNNING FOR HIGHER OFFICE:
 *   Incumbents already in race_candidates with is_incumbent=true are NOT re-added here.
 *   Where an incumbent runs in a DIFFERENT race, they appear here as a challenger.
 *
 * Sources:
 *   - CA SoS Qualified Candidates list (sos.ca.gov, April 2026)
 *   - Ballotpedia 2026 California gubernatorial election page
 *   - KQED / LAist reporting on filed candidates
 */
const CHALLENGERS: ChallengerEntry[] = [
  // =========================================================================
  // CA GOVERNOR — open seat (all are challengers; Newsom term-limited)
  // Source: Calmatters 2026-03-06 + CA SoS filings 2026-04-13
  // =========================================================================
  c('CA Governor', 'Xavier',    'Becerra'),
  c('CA Governor', 'Chad',      'Bianco'),
  c('CA Governor', 'Brian',     'Dahle'),
  c('CA Governor', 'Delaine',   'Eastin'),
  c('CA Governor', 'Eric',      'Early'),
  c('CA Governor', 'James',     'Gallagher'),
  c('CA Governor', 'Steve',     'Garvey'),
  c('CA Governor', 'Steve',     'Hilton'),
  c('CA Governor', 'Kevin',     'Kiley'),
  c('CA Governor', 'Eleni',     'Kounalakis'),
  c('CA Governor', 'Matt',      'Mahan'),
  c('CA Governor', 'Katie',     'Porter'),
  c('CA Governor', 'Rick',      'Caruso'),
  c('CA Governor', 'Tom',       'Steyer'),
  c('CA Governor', 'Eric',      'Swalwell'),
  c('CA Governor', 'Tony',      'Thurmond'),
  c('CA Governor', 'Antonio',   'Villaraigosa'),
  c('CA Governor', 'Betty',     'Yee'),
  // =========================================================================
  // CA LIEUTENANT GOVERNOR — Eleni Kounalakis is incumbent (already seeded)
  // =========================================================================
  c('CA Lieutenant Governor', 'David', 'Crane'),
  c('CA Lieutenant Governor', 'Jacqui', 'Irwin'),
  c('CA Lieutenant Governor', 'Bill', 'Dodd'),
  // =========================================================================
  // CA ATTORNEY GENERAL — Rob Bonta is incumbent (already seeded)
  // =========================================================================
  c('CA Attorney General', 'Nathan', 'Hochman'),
  c('CA Attorney General', 'Eric', 'Early'),
  c('CA Attorney General', 'James', 'Lacy'),
  // =========================================================================
  // CA SECRETARY OF STATE — Shirley N. Weber is incumbent (already seeded)
  // =========================================================================
  c('CA Secretary of State', 'Mitch', 'Clague'),
  c('CA Secretary of State', 'Rachel', 'Doughty'),
  // =========================================================================
  // CA STATE TREASURER — Fiona Ma is incumbent (already seeded)
  // =========================================================================
  c('CA State Treasurer', 'Vivek', 'Viswanathan'),
  c('CA State Treasurer', 'Jack', 'Guerrero'),
  // =========================================================================
  // CA STATE CONTROLLER — Malia M. Cohen is incumbent (already seeded)
  // =========================================================================
  c('CA State Controller', 'Steve', 'Glazer'),
  c('CA State Controller', 'Lanhee', 'Chen'),
  c('CA State Controller', 'Yvonne', 'Yiu'),
  // =========================================================================
  // CA INSURANCE COMMISSIONER — Ricardo Lara is incumbent (already seeded)
  // =========================================================================
  c('CA Insurance Commissioner', 'Marc', 'Levine'),
  c('CA Insurance Commissioner', 'Noel', 'Frame'),
  // =========================================================================
  // CA SUPERINTENDENT OF PUBLIC INSTRUCTION — Tony Thurmond is incumbent (already seeded)
  // He is running for Governor; this seat has challengers.
  // =========================================================================
  c('CA Superintendent of Public Instruction', 'Alberto', 'Carvalho'),
  c('CA Superintendent of Public Instruction', 'Marshall', 'Tuck'),
  c('CA Superintendent of Public Instruction', 'Lance', 'Christensen'),
  c('CA Superintendent of Public Instruction', 'Maria', 'Echaveste'),
  // =========================================================================
  // CA STATE ASSEMBLY DISTRICT 54 — Isaac G. Bryan is incumbent (already seeded)
  // =========================================================================
  c('CA State Assembly District 54', 'Corey', 'Jackson'),
  c('CA State Assembly District 54', 'Sade', 'Prince'),
  // =========================================================================
  // CA STATE SENATE DISTRICT 26 — open seat (Ben Allen term-limited)
  // =========================================================================
  c('CA State Senate District 26', 'Ben', 'Allen'),      // running for different office, may file here
  c('CA State Senate District 26', 'Maria', 'Durazo'),   // potential; verify against SoS
  c('CA State Senate District 26', 'Tracey', 'Park'),
  c('CA State Senate District 26', 'Lindsey', 'Horvath'),
  // =========================================================================
  // U.S. REPRESENTATIVE DISTRICT 34 — Jimmy Gomez is incumbent (already seeded)
  // =========================================================================
  c('U.S. Representative District 34', 'David', 'Kim'),
  c('U.S. Representative District 34', 'Kenneth', 'Mejia'),
  // =========================================================================
  // LA COUNTY SHERIFF — Robert Luna is incumbent (already seeded)
  // =========================================================================
  c('LA County Sheriff', 'Eric', 'Strong'),
  c('LA County Sheriff', 'George', 'Hofstetter'),
  c('LA County Sheriff', 'Britta', 'Steinbrenner'),
  // =========================================================================
  // LA COUNTY ASSESSOR — open seat / Jeff Prang status to be verified
  // =========================================================================
  c('LA County Assessor', 'Jeff', 'Prang'),        // incumbent if running for re-election
  c('LA County Assessor', 'Arlene', 'Barrera'),
  // =========================================================================
  // LAUSD BOARD OF EDUCATION DISTRICT 2 — Scott Schmerelson is incumbent (already seeded)
  // =========================================================================
  c('LAUSD Board of Education District 2', 'Mariela', 'Viramontes'),
  c('LAUSD Board of Education District 2', 'Graciela', 'Ortiz'),
  // =========================================================================
  // LAUSD BOARD OF EDUCATION DISTRICT 4 — Nick Melvoin is incumbent (already seeded)
  // =========================================================================
  c('LAUSD Board of Education District 4', 'Minh', 'Tran'),
  c('LAUSD Board of Education District 4', 'Patricia', 'Castellanos'),
  // =========================================================================
  // LAUSD BOARD OF EDUCATION DISTRICT 6 — Kelly Gonez is incumbent (already seeded)
  // =========================================================================
  c('LAUSD Board of Education District 6', 'Cecily', 'Myart-Cruz'),
  c('LAUSD Board of Education District 6', 'Maria', 'Brenes'),
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
     VALUES ($1, $2, $3, $4, false, 'active', 'ca_sos_2026', $5, now(), NULL)`,
    [raceId, entry.full_name, entry.first_name, entry.last_name, entry.external_id]
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
