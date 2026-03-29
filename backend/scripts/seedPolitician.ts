/**
 * seedPolitician.ts — CLI tool to look up FEC candidates by name and seed a
 * politician_sources row linked to an existing essentials.politicians entry.
 *
 * Usage:
 *   npx tsx scripts/seedPolitician.ts --name "Banks" --state IN [options]
 *   npx tsx scripts/seedPolitician.ts --bulk politicians.csv [--dry-run] [--discover]
 *   npx tsx scripts/seedPolitician.ts --indiana all [--dry-run]
 *   npx tsx scripts/seedPolitician.ts --indiana "PIERCE" [--dry-run]
 *
 * Flags:
 *   --name    <string>   Candidate name to search (required unless --bulk/--indiana)
 *   --state   <2-letter> Two-letter state code (required unless --bulk/--indiana)
 *   --office  <H|S|P>   Office type (optional; defaults to H+S combined)
 *   --dry-run            Print seed plan JSON, make no DB writes
 *   --discover           Print FEC candidates and exit (no DB path, no prompt)
 *   --bulk    <filepath> Bulk seeding mode — CSV or JSON file with name/state/office columns
 *   --indiana <filter>   Indiana confirmation mode — filter is "all" or a name/committee fragment
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
  indiana: string | null;
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
    indiana: null,
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
    } else if (arg === '--indiana' && argv[i + 1]) {
      args.indiana = argv[++i]!;
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
  // FEC names are in "LAST, FIRST" format. Parse first and last name.
  // parseFecName handles this correctly; fall back if no comma.
  const parsed = parseFecName(name);
  const lastName = parsed.last.trim() || name.trim();
  const firstName = parsed.first.trim();

  // representing_state lives in essentials.offices (joined), not on politicians directly.
  // Match on both first and last name to avoid false positives from common last names.
  // If we have a first name, require BOTH first and last name to match (ILIKE).
  // This prevents linking e.g. federal candidate "James Davidson" to unrelated
  // Indiana state politician "Michael Davidson".
  const result = await pool.query<EssentialsPolitician>(
    `SELECT DISTINCT p.id, p.full_name, o.representing_state
     FROM essentials.politicians p
     JOIN essentials.offices o ON o.politician_id = p.id
     WHERE p.full_name ILIKE $1
       AND ($3 = '' OR p.full_name ILIKE $4)
       AND o.representing_state = $2
       AND p.is_active = true
     LIMIT 10`,
    [`%${lastName}%`, state, firstName, `%${firstName}%`]
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

// Chamber IDs for federal offices (pre-looked-up from essentials.chambers)
const CHAMBER_US_HOUSE = 'c2facc31-7b13-428c-b7b9-32d0d3b95f76';
const CHAMBER_US_SENATE = '7cbe07bc-84b8-433b-952b-540e7de18a92';

/**
 * Create a new essentials.politicians + essentials.offices row for a
 * 2026 federal candidate who has no existing DB entry.
 * Used in bulk mode when no match is found.
 */
async function createFederalPolitician(
  fecCandidate: FecCandidate,
  state: string,
  officeCode: 'H' | 'S',
  dryRun: boolean
): Promise<EssentialsPolitician> {
  const parsed = parseFecName(fecCandidate.name);
  const firstName = parsed.first;
  const lastName = parsed.last;
  // Build display name as "First Last" (title-case)
  const toTitleCase = (s: string) =>
    s.toLowerCase().replace(/\b\w/g, c => c.toUpperCase());
  const fullName = [toTitleCase(firstName), toTitleCase(lastName)]
    .filter(Boolean)
    .join(' ');

  const chamberIdForOffice = officeCode === 'S' ? CHAMBER_US_SENATE : CHAMBER_US_HOUSE;
  const officeTitle = officeCode === 'S' ? 'U.S. Senator' : 'U.S. Representative';

  if (dryRun) {
    console.log(`[dry-run] Would CREATE politician: ${fullName} (${state}, ${officeTitle})`);
    // Return a fake politician record for dry-run chaining
    return {
      id: '00000000-0000-0000-0000-000000000000',
      full_name: fullName,
      representing_state: state,
    };
  }

  // Insert politician
  const polResult = await pool.query<{ id: string }>(
    `INSERT INTO essentials.politicians
       (full_name, first_name, last_name, is_active, is_incumbent, source)
     VALUES ($1, $2, $3, true, false, 'federal_2026_bulk_seed')
     RETURNING id`,
    [fullName, toTitleCase(firstName), toTitleCase(lastName)]
  );
  const politicianId = polResult.rows[0]!.id;

  // Insert office
  await pool.query(
    `INSERT INTO essentials.offices
       (politician_id, chamber_id, title, representing_state, is_vacant)
     VALUES ($1, $2, $3, $4, false)`,
    [politicianId, chamberIdForOffice, officeTitle, state]
  );

  console.log(`CREATED: ${fullName} (${state}, ${officeTitle}) -> id: ${politicianId}`);
  return {
    id: politicianId,
    full_name: fullName,
    representing_state: state,
  };
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

  let politician: EssentialsPolitician;
  if (politicians.length === 0) {
    if (bulkMode && (selected.office === 'H' || selected.office === 'S')) {
      // In bulk mode for federal candidates, create the politician if not found
      console.log(`No existing politician found — creating new entry for ${name}`);
      politician = await createFederalPolitician(selected, state, selected.office, dryRun);
    } else {
      console.log(
        'No matching politician found in essentials.politicians. Cannot seed without an existing politician entry. Exiting.'
      );
      return;
    }
  } else if (politicians.length === 1) {
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
// Indiana confirmation mode
// ---------------------------------------------------------------------------

interface IndianaSourceRow {
  source_id: string;
  external_id: string;
  notes: string | null;
  full_name: string;
  politician_id: string;
  office_title: string | null;
}

async function promptRaw(question: string): Promise<string> {
  return new Promise(resolve => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    rl.question(question, answer => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

async function runIndianaConfirmMode(filter: string, dryRun: boolean): Promise<void> {
  // Query all needs_research Indiana sources with politician names and office titles
  const result = await pool.query<IndianaSourceRow>(
    `SELECT ps.id AS source_id, ps.external_id, ps.notes,
            p.full_name, p.id AS politician_id,
            o.title AS office_title
     FROM transparent_motivations.politician_sources ps
     JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
     LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
     WHERE ps.source_system = 'indiana'
       AND ps.research_status = 'needs_research'
     ORDER BY p.full_name`
  );

  let rows = result.rows;

  // Apply filter
  if (filter !== 'all') {
    const filterLower = filter.toLowerCase();
    rows = rows.filter(
      r =>
        r.full_name.toLowerCase().includes(filterLower) ||
        (r.notes ?? '').toLowerCase().includes(filterLower)
    );
  }

  console.log(`\nFound ${rows.length} Indiana needs_research sources (filter: "${filter}")`);

  if (rows.length === 0) {
    console.log('No matching sources. Try a different filter or "all" to see all records.');
    return;
  }

  let confirmed = 0;
  let skipped = 0;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i]!;
    const displayTitle = row.office_title ?? 'Indiana Elected Official';

    console.log(`\n--- [${i + 1}/${rows.length}] ---`);
    console.log(`Name:         ${row.full_name}`);
    console.log(`Source ID:    ${row.source_id}`);
    console.log(`External ID (FileNumber): ${row.external_id}`);
    console.log(`Committee:    ${row.notes ?? '(none)'}`);
    console.log(`Current office: ${displayTitle}`);

    const answer = await promptRaw(
      'Confirm this politician? (y/n/skip/quit) [or type an office title to confirm with that title]: '
    );

    const answerLower = answer.toLowerCase();

    if (answerLower === 'quit' || answerLower === 'q') {
      console.log('Stopping at user request.');
      break;
    }

    if (answerLower === 'n' || answerLower === 'no' || answerLower === 'skip' || answerLower === '') {
      console.log('Skipped.');
      skipped++;
      continue;
    }

    // Determine office title
    let newTitle: string | null = null;

    if (answerLower === 'y' || answerLower === 'yes') {
      // Prompt separately for office title
      const titleAnswer = await promptRaw(
        'Office title [e.g. Indiana State Representative / Indiana State Senator / leave blank to keep current]: '
      );
      if (titleAnswer.trim().length > 0) {
        newTitle = titleAnswer.trim();
      }
    } else {
      // Treat non-empty answer as the office title itself
      newTitle = answer.trim();
    }

    if (dryRun) {
      console.log('[dry-run] Would UPDATE politician_sources SET research_status = \'confirmed\' WHERE id =', row.source_id);
      if (newTitle && newTitle !== row.office_title) {
        console.log('[dry-run] Would UPDATE essentials.offices SET title =', JSON.stringify(newTitle), 'WHERE politician_id =', row.politician_id, 'AND title = \'Indiana Elected Official\'');
      }
    } else {
      // Update research_status to confirmed
      await pool.query(
        `UPDATE transparent_motivations.politician_sources
         SET research_status = 'confirmed', updated_at = NOW()
         WHERE id = $1`,
        [row.source_id]
      );

      // Update office title if provided and different
      if (newTitle && newTitle !== row.office_title) {
        await pool.query(
          `UPDATE essentials.offices
           SET title = $1, updated_at = NOW()
           WHERE politician_id = $2 AND title = 'Indiana Elected Official'`,
          [newTitle, row.politician_id]
        );
        console.log(`Confirmed: ${row.full_name} (office title -> "${newTitle}")`);
      } else {
        console.log(`Confirmed: ${row.full_name}`);
      }
    }

    confirmed++;
  }

  const total = confirmed + skipped;
  console.log(`\nSummary: Confirmed=${confirmed}, Skipped=${skipped}, Total processed=${total}`);
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

  // --indiana mode
  if (args.indiana !== null) {
    try {
      await runIndianaConfirmMode(args.indiana, args.dryRun);
    } finally {
      await pool.end();
    }
    return;
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
      '       npx tsx scripts/seedPolitician.ts --bulk <filepath> [--dry-run] [--discover]\n' +
      '       npx tsx scripts/seedPolitician.ts --indiana <filter|all> [--dry-run]'
    );
    process.exit(1);
  }
  if (!args.state) {
    console.error(
      'Usage: npx tsx scripts/seedPolitician.ts --name <name> --state <state> [--office H|S|P] [--dry-run] [--discover]\n' +
      '       npx tsx scripts/seedPolitician.ts --bulk <filepath> [--dry-run] [--discover]\n' +
      '       npx tsx scripts/seedPolitician.ts --indiana <filter|all> [--dry-run]'
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
