/**
 * seedPolitician.ts — CLI tool to look up FEC candidates by name and seed a
 * politician_sources row linked to an existing essentials.politicians entry.
 *
 * Usage:
 *   npx tsx scripts/seedPolitician.ts --name "Banks" --state IN [options]
 *   npx tsx scripts/seedPolitician.ts --bulk politicians.csv [--dry-run] [--discover]
 *
 * Flags:
 *   --name    <string>   Candidate name to search (required unless --bulk)
 *   --state   <2-letter> Two-letter state code (required unless --bulk)
 *   --office  <H|S|P>   Office type (optional; defaults to H+S combined)
 *   --dry-run            Print seed plan JSON, make no DB writes
 *   --discover           Print FEC candidates and exit (no DB path, no prompt)
 *   --bulk    <filepath> Bulk seeding mode — CSV or JSON file with name/state/office columns
 *
 * Required env vars:
 *   FEC_API_KEY     — FEC API key from api.data.gov
 *   DATABASE_URL    — PostgreSQL connection string
 */

import 'dotenv/config';
import readline from 'readline';
import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';
import {
  searchFecCandidates,
  FecCandidate,
  parseFecName,
} from '../src/lib/fecResearch.js';
import { createSource } from '../src/lib/campaignFinanceService.js';

// ---------------------------------------------------------------------------
// Sleep helper
// ---------------------------------------------------------------------------

const sleep = (ms: number): Promise<void> => new Promise(r => setTimeout(r, ms));

// ---------------------------------------------------------------------------
// Arg parsing
// ---------------------------------------------------------------------------

interface CliArgs {
  name: string | null;
  state: string | null;
  office: string | null;
  dryRun: boolean;
  discoverOnly: boolean;
  bulk: string | null;
}

function parseArgs(): CliArgs {
  const argv = process.argv.slice(2);
  const args: CliArgs = {
    name: null,
    state: null,
    office: null,
    dryRun: false,
    discoverOnly: false,
    bulk: null,
  };

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!;
    if (arg === '--name' && argv[i + 1]) {
      args.name = argv[++i]!;
    } else if (arg === '--state' && argv[i + 1]) {
      args.state = argv[++i]!.toUpperCase();
    } else if (arg === '--office' && argv[i + 1]) {
      args.office = argv[++i]!.toUpperCase();
    } else if (arg === '--dry-run') {
      args.dryRun = true;
    } else if (arg === '--discover') {
      args.discoverOnly = true;
    } else if (arg === '--bulk' && argv[i + 1]) {
      args.bulk = argv[++i]!;
    }
  }

  return args;
}

// ---------------------------------------------------------------------------
// readline prompt helper (new interface per call)
// ---------------------------------------------------------------------------

function prompt(question: string): Promise<string> {
  return new Promise(resolve => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    rl.question(question, answer => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

// ---------------------------------------------------------------------------
// Display candidates
// ---------------------------------------------------------------------------

function displayCandidates(candidates: FecCandidate[]): void {
  console.log(`\nFound ${candidates.length} FEC candidate(s):\n`);
  candidates.forEach((c, i) => {
    const officeLabel = c.office_full ?? c.office ?? '?';
    const partyLabel = c.party_full ?? c.party ?? '?';
    const district = c.district ? `-${c.district}` : '';
    const location = `${c.state ?? '?'}${district}`;
    const lastYear = c.election_years && c.election_years.length > 0
      ? c.election_years[c.election_years.length - 1]
      : '?';
    const status = c.incumbent_challenge_full ?? '?';
    const parsed = parseFecName(c.name);
    const displayName = c.name || `${parsed.last}, ${parsed.first}`;

    console.log(`  [${i + 1}] ${displayName} | ${officeLabel} | ${location} | ${partyLabel} | cycle ${lastYear} | ${status}`);
    console.log(`       FEC ID: ${c.candidate_id}`);
  });
  console.log('');
}

// ---------------------------------------------------------------------------
// DB helpers
// ---------------------------------------------------------------------------

interface EssentialsPolitician {
  id: string;
  full_name: string;
  representing_state: string;
}

async function findExistingPoliticians(
  name: string,
  state: string
): Promise<EssentialsPolitician[]> {
  // Extract last name for targeted search
  const tokens = name.trim().split(/\s+/);
  const lastName = tokens[tokens.length - 1] ?? name;

  const result = await pool.query<EssentialsPolitician>(
    `SELECT id, full_name, representing_state
     FROM essentials.politicians
     WHERE full_name ILIKE $1
       AND representing_state = $2
       AND is_active = true
     LIMIT 10`,
    [`%${lastName}%`, state]
  );

  return result.rows;
}

async function isDuplicate(sourceSystem: string, externalId: string): Promise<boolean> {
  const result = await pool.query(
    `SELECT 1 FROM transparent_motivations.politician_sources
     WHERE source_system = $1 AND external_id = $2`,
    [sourceSystem, externalId]
  );
  return (result.rowCount ?? 0) > 0;
}

// ---------------------------------------------------------------------------
// Bulk mode types and helpers
// ---------------------------------------------------------------------------

interface BulkRow {
  name: string;
  state: string;
  office?: string; // H, S, or P — optional
}

function loadBulkFile(filePath: string): BulkRow[] {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File not found: ${filePath}`);
  }

  const content = fs.readFileSync(filePath, 'utf-8');
  let rows: BulkRow[];

  if (filePath.endsWith('.json')) {
    const parsed = JSON.parse(content);
    if (!Array.isArray(parsed)) {
      throw new Error('JSON bulk file must be an array of objects.');
    }
    rows = parsed as BulkRow[];
  } else {
    // Default: CSV
    rows = parse(content, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    }) as BulkRow[];
  }

  // Validate and filter rows
  const valid: BulkRow[] = [];
  for (let i = 0; i < rows.length; i++) {
    const row = rows[i]!;
    if (!row.name || !row.state) {
      console.warn(`[bulk] Row ${i + 1}: missing required field(s) name/state — skipping.`);
      continue;
    }
    valid.push(row);
  }

  return valid;
}

async function runBulkMode(
  filePath: string,
  dryRun: boolean,
  discoverOnly: boolean
): Promise<void> {
  const rows = loadBulkFile(filePath);
  const total = rows.length;
  console.log(`Loaded ${total} rows from ${filePath}`);

  let processed = 0;
  let errors = 0;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i]!;
    console.log(`\n--- [${i + 1}/${total}] Processing: ${row.name} (${row.state}) ---`);

    // Validate office if provided
    if (row.office && !['H', 'S', 'P'].includes(row.office.toUpperCase())) {
      console.warn(`[bulk] Invalid office "${row.office}" for "${row.name}" — skipping.`);
      errors++;
      continue;
    }

    try {
      await seedSinglePolitician(
        row.name,
        row.state.toUpperCase(),
        row.office ? row.office.toUpperCase() : null,
        dryRun,
        discoverOnly,
        true // bulkMode
      );
      processed++;
    } catch (err) {
      console.error(
        `[bulk] Error for "${row.name}": ${err instanceof Error ? err.message : String(err)}`
      );
      errors++;
    }

    // Rate-limit delay between rows (skip after last row)
    if (i < rows.length - 1) {
      await sleep(1500);
    }
  }

  console.log(
    `\nBulk complete: ${processed} processed, ${errors} errors out of ${total} rows.`
  );
}

// ---------------------------------------------------------------------------
// Core seeding flow
// ---------------------------------------------------------------------------

async function seedSinglePolitician(
  name: string,
  state: string,
  office: string | null,
  dryRun: boolean,
  discoverOnly: boolean,
  bulkMode = false
): Promise<void> {
  const apiKey = process.env.FEC_API_KEY!;

  // Build office list
  const officeList: Array<'H' | 'S'> = office
    ? [office as 'H' | 'S']
    : ['H', 'S'];

  // Fetch candidates for each office
  let allCandidates: FecCandidate[] = [];

  for (let i = 0; i < officeList.length; i++) {
    if (i > 0) await sleep(1500);
    const results = await searchFecCandidates(name, state, officeList[i]!, apiKey);
    allCandidates.push(...results);
  }

  // Deduplicate by candidate_id
  const seen = new Map<string, FecCandidate>();
  for (const c of allCandidates) {
    if (!seen.has(c.candidate_id)) {
      seen.set(c.candidate_id, c);
    }
  }
  const candidates = Array.from(seen.values());

  if (candidates.length === 0) {
    console.log(`No FEC candidates found for "${name}" in ${state}.`);
    return;
  }

  displayCandidates(candidates);

  // --discover mode: just show candidates and exit
  if (discoverOnly) {
    return;
  }

  // Bulk mode disambiguation
  let selected: FecCandidate;
  if (bulkMode) {
    if (candidates.length === 1) {
      selected = candidates[0]!;
    } else {
      console.log(
        `Multiple FEC candidates found (${candidates.length}), skipping (ambiguous).`
      );
      return;
    }
  } else {
    // Interactive: prompt operator to select
    const answer = await prompt(
      `Select candidate [1-${candidates.length}] or 0 to abort: `
    );
    const idx = parseInt(answer, 10);
    if (isNaN(idx) || idx < 1 || idx > candidates.length) {
      console.log('Aborted.');
      return;
    }
    selected = candidates[idx - 1]!;
  }

  // Determine source_system
  const sourceSystem =
    selected.office === 'S'
      ? 'fec_senate'
      : selected.office === 'P'
        ? 'fec_president'
        : 'fec_house';

  // Duplicate check
  const dup = await isDuplicate(sourceSystem, selected.candidate_id);
  if (dup) {
    console.log(
      `DUPLICATE: ${selected.candidate_id} already exists in politician_sources as ${sourceSystem}. Skipping.`
    );
    return;
  }

  // Find matching essentials.politicians entry
  const politicians = await findExistingPoliticians(name, state);

  if (politicians.length === 0) {
    console.log(
      'No matching politician found in essentials.politicians. Cannot seed without an existing politician entry. Exiting.'
    );
    return;
  }

  let politician: EssentialsPolitician;
  if (politicians.length === 1) {
    politician = politicians[0]!;
    console.log(`Matched politician: ${politician.full_name} (id: ${politician.id})`);
  } else if (bulkMode) {
    console.log(
      `Multiple essentials politicians matched (${politicians.length}), skipping (ambiguous).`
    );
    return;
  } else {
    // Interactive: show list and prompt
    console.log('\nMultiple politicians found in essentials.politicians:\n');
    politicians.forEach((p, i) => {
      console.log(`  [${i + 1}] ${p.full_name} | ${p.representing_state} | id: ${p.id}`);
    });
    console.log('');

    const answer = await prompt(
      `Select politician [1-${politicians.length}] or 0 to abort: `
    );
    const idx = parseInt(answer, 10);
    if (isNaN(idx) || idx < 1 || idx > politicians.length) {
      console.log('Aborted.');
      return;
    }
    politician = politicians[idx - 1]!;
  }

  // Build seed plan
  const today = new Date().toISOString().slice(0, 10);
  const seedPlan = {
    essentials_politician_id: politician.id,
    source_system: sourceSystem,
    external_id: selected.candidate_id,
    research_status: 'confirmed',
    notes: `Seeded via CLI on ${today}`,
  };

  // --dry-run mode: print plan and exit
  if (dryRun) {
    console.log('[dry-run] Would insert:');
    console.log(JSON.stringify(seedPlan, null, 2));
    return;
  }

  // Final confirmation (interactive only)
  if (!bulkMode) {
    const confirm = await prompt(
      `Seed ${selected.name} -> ${politician.full_name}? [y/N]: `
    );
    if (confirm !== 'y') {
      console.log('Aborted.');
      return;
    }
  }

  const result = await createSource(seedPlan);
  console.log(`Seeded: ${selected.name} -> source_id ${result.id}`);
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const args = parseArgs();

  // Env var validation
  if (!process.env.FEC_API_KEY) {
    console.error('ERROR: FEC_API_KEY is not set.');
    process.exit(1);
  }
  if (!process.env.DATABASE_URL) {
    console.error('ERROR: DATABASE_URL is not set.');
    process.exit(1);
  }

  // --bulk mode
  if (args.bulk !== null) {
    try {
      await runBulkMode(args.bulk, args.dryRun, args.discoverOnly);
    } finally {
      await pool.end();
    }
    return;
  }

  // Single-politician mode — --name and --state required
  if (!args.name) {
    console.error(
      'Usage: npx tsx scripts/seedPolitician.ts --name <name> --state <state> [--office H|S|P] [--dry-run] [--discover]\n' +
      '       npx tsx scripts/seedPolitician.ts --bulk <filepath> [--dry-run] [--discover]'
    );
    process.exit(1);
  }
  if (!args.state) {
    console.error(
      'Usage: npx tsx scripts/seedPolitician.ts --name <name> --state <state> [--office H|S|P] [--dry-run] [--discover]\n' +
      '       npx tsx scripts/seedPolitician.ts --bulk <filepath> [--dry-run] [--discover]'
    );
    process.exit(1);
  }

  // --office validation
  if (args.office !== null && !['H', 'S', 'P'].includes(args.office)) {
    console.error(`ERROR: --office must be H, S, or P. Got: "${args.office}"`);
    process.exit(1);
  }

  try {
    await seedSinglePolitician(
      args.name,
      args.state,
      args.office,
      args.dryRun,
      args.discoverOnly
    );
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[seedPolitician] Fatal error:', err);
  process.exit(1);
});
