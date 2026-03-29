/**
 * discover-indiana-candidates.ts — Indiana Campaign Finance candidate committee discovery.
 *
 * Usage:
 *   npx tsx scripts/discover-indiana-candidates.ts                      # dry-run, all years 2020-2025
 *   npx tsx scripts/discover-indiana-candidates.ts --years 2024         # dry-run, single year
 *   npx tsx scripts/discover-indiana-candidates.ts --execute            # live, all years
 *   npx tsx scripts/discover-indiana-candidates.ts --years 2024 --execute
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * What it does:
 *   1. Downloads Indiana annual contribution ZIPs (campaignfinance.in.gov) for each year.
 *   2. Parses CSVs using header-driven column indexing (no hardcoded column positions).
 *   3. Logs ALL DISTINCT committeeType values before filtering.
 *   4. Filters candidate committees; deduplicates by FileNumber.
 *   5. Matches candidate names against existing essentials.politicians.
 *   6. Seeds new politicians + offices + politician_sources rows for unmatched candidates.
 *
 * IMPORTANT:
 *   - All new politician_sources rows use research_status='needs_research' — never 'confirmed'
 *     (DB CHECK constraint: needs_research/confirmed/not_applicable/disputed)
 *   - Script is idempotent — re-running produces 0 new rows (ON CONFLICT DO NOTHING)
 *   - SAVEPOINT per-row within batch transactions (lesson from 15.2 — UUID errors cascade)
 *   - Office title 'Indiana Elected Official' is a placeholder — must be manually corrected
 */

import 'dotenv/config';
import AdmZip from 'adm-zip';
import { parse } from 'csv-parse/sync';
import { Pool } from 'pg';
import type { PoolClient } from 'pg';

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const isExecute = args.includes('--execute');
const isDryRun = !isExecute;

// Parse --years flag: comma-separated or multiple --years args
let years: number[] = [2020, 2021, 2022, 2023, 2024, 2025];
const yearsIdx = args.indexOf('--years');
if (yearsIdx !== -1 && args[yearsIdx + 1]) {
  years = args[yearsIdx + 1].split(',').map(y => parseInt(y.trim(), 10)).filter(y => !isNaN(y));
}

console.log(`[discover-indiana-candidates] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);
console.log(`[discover-indiana-candidates] Years: ${years.join(', ')}`);

// ---------------------------------------------------------------------------
// DB pool
// ---------------------------------------------------------------------------

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ---------------------------------------------------------------------------
// Indiana CSV download
// ---------------------------------------------------------------------------

const ZIP_URL_TEMPLATE = 'https://campaignfinance.in.gov/PublicSite/Docs/BulkDataDownloads/{year}_ContributionData.csv.zip';

async function downloadZip(year: number): Promise<Buffer | null> {
  const url = ZIP_URL_TEMPLATE.replace('{year}', String(year));
  console.log(`[Phase 1] Downloading ${year} ZIP from ${url}...`);
  try {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(120_000), // 2 min for large ZIPs
    });
    if (response.status !== 200) {
      console.warn(`[Phase 1] WARNING: HTTP ${response.status} for ${url} — skipping year ${year}`);
      return null;
    }
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    console.log(`[Phase 1] Downloaded ${year} ZIP: ${(buffer.length / 1024 / 1024).toFixed(1)} MB`);
    return buffer;
  } catch (err: any) {
    console.warn(`[Phase 1] WARNING: Download failed for year ${year}: ${err.message} — skipping`);
    return null;
  }
}

// ---------------------------------------------------------------------------
// CSV parsing (mirrors indianaAdapter.ts pattern exactly)
// ---------------------------------------------------------------------------

/** Returns value at column name from a record using header-index map. */
function colGet(record: string[], colIdx: Record<string, number>, name: string): string {
  const i = colIdx[name];
  if (i === undefined || i >= record.length) return '';
  return (record[i] ?? '').trim();
}

interface RawCommitteeRow {
  fileNumber: string;
  committeeType: string;
  committee: string;
  candidateName: string;
  year: number;
}

function parseZipCsv(zipBuffer: Buffer, year: number): RawCommitteeRow[] {
  const zip = new AdmZip(zipBuffer);
  const entries = zip.getEntries();

  // Find the CSV entry — Indiana names it "{year}_ContributionData.csv"
  const csvEntry = entries.find(e => e.entryName.endsWith('ContributionData.csv'));
  if (!csvEntry) {
    throw new Error(`indiana: parseZipCsv year=${year}: no *ContributionData.csv entry in ZIP`);
  }

  let csvContent = csvEntry.getData().toString('utf8');
  // Strip BOM if present (Windows-generated CSV)
  if (csvContent.startsWith('\uFEFF')) {
    csvContent = csvContent.slice(1);
  }

  const rawRows = parse(csvContent, {
    relax_quotes: true,
    relax_column_count: true,
    skip_empty_lines: true,
    bom: true,
  }) as string[][];

  if (rawRows.length === 0) {
    throw new Error(`indiana: parseZipCsv year=${year}: CSV is empty`);
  }

  // Build column-name-to-index map from header row (same pattern as indianaAdapter.ts)
  const headerRow = rawRows[0];
  const colIdx: Record<string, number> = {};
  for (let i = 0; i < headerRow.length; i++) {
    // Strip BOM from individual header cells too (sometimes per-cell)
    const colName = headerRow[i].replace(/^\uFEFF/, '').trim();
    colIdx[colName] = i;
  }

  const rows: RawCommitteeRow[] = [];
  for (let rowNum = 1; rowNum < rawRows.length; rowNum++) {
    const record = rawRows[rowNum];
    const fileNumber = colGet(record, colIdx, 'FileNumber');
    if (!fileNumber) continue; // Skip rows with no FileNumber

    rows.push({
      fileNumber,
      committeeType: colGet(record, colIdx, 'CommitteeType'),
      committee: colGet(record, colIdx, 'Committee'),
      candidateName: colGet(record, colIdx, 'CandidateName'),
      year,
    });
  }

  console.log(`[Phase 1] Parsed ${rows.length} data rows from ${year} CSV`);
  return rows;
}

// ---------------------------------------------------------------------------
// Phase 2: Enumerate candidate committees
// ---------------------------------------------------------------------------

interface CommitteeRecord {
  fileNumber: string;
  committeeType: string;
  committee: string;
  candidateName: string;
  latestYear: number;
}

function buildCommitteeMap(allRows: RawCommitteeRow[]): {
  committees: CommitteeRecord[];
  distinctTypes: Map<string, number>;
} {
  // First: collect all DISTINCT committeeType values (before filtering)
  const distinctTypes = new Map<string, number>();
  for (const row of allRows) {
    const ct = row.committeeType || '(empty)';
    distinctTypes.set(ct, (distinctTypes.get(ct) ?? 0) + 1);
  }

  // Deduplicate by FileNumber — keep latest year's record
  const committeeMap = new Map<string, CommitteeRecord>();
  for (const row of allRows) {
    const existing = committeeMap.get(row.fileNumber);
    if (!existing || row.year > existing.latestYear) {
      committeeMap.set(row.fileNumber, {
        fileNumber: row.fileNumber,
        committeeType: row.committeeType,
        committee: row.committee,
        candidateName: row.candidateName,
        latestYear: row.year,
      });
    }
  }

  // Filter: keep candidate committees
  // "Candidate" is the standard Indiana type for candidate committees
  const CANDIDATE_TYPES = new Set(['Candidate']);
  const committees = Array.from(committeeMap.values()).filter(
    c => CANDIDATE_TYPES.has(c.committeeType)
  );

  return { committees, distinctTypes };
}

// ---------------------------------------------------------------------------
// Name parsing helpers
// ---------------------------------------------------------------------------

const SUFFIXES = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'jr.', 'sr.', '2nd', '3rd']);

function titleCase(s: string): string {
  return s
    .toLowerCase()
    .split(' ')
    .map(w => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

interface ParsedName {
  firstName: string;
  lastName: string;
  fullName: string;
}

function parseCandidateName(rawInput: string): ParsedName {
  if (!rawInput || !rawInput.trim()) {
    return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
  }

  // Strip surrounding quotes that can appear in Indiana CSVs with relax_quotes parsing
  // e.g. '"charles Meeks"' → 'charles Meeks'
  let raw = rawInput.trim();
  if ((raw.startsWith('"') && raw.endsWith('"')) || (raw.startsWith("'") && raw.endsWith("'"))) {
    raw = raw.slice(1, -1).trim();
  }

  if (!raw) {
    return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
  }

  let first = '';
  let last = '';

  if (raw.includes(',')) {
    // "LAST, FIRST" or "Last, First Middle" format
    const commaIdx = raw.indexOf(',');
    const rawLast = raw.slice(0, commaIdx).trim();
    const rawFirst = raw.slice(commaIdx + 1).trim();

    last = titleCase(rawLast);
    // First name may have middle name/initial — take the first token
    const firstTokens = rawFirst.split(/\s+/).filter(Boolean);
    // Strip suffixes from the end of the first-name part
    const filtered = firstTokens.filter(t => !SUFFIXES.has(t.toLowerCase().replace('.', '')));
    first = filtered.length > 0 ? titleCase(filtered[0]) : '';
  } else {
    // "First Last" or "First Middle Last" format
    const tokens = raw.trim().split(/\s+/).filter(Boolean);
    if (tokens.length === 0) {
      return { firstName: '', lastName: '(unknown)', fullName: '(unknown)' };
    }
    if (tokens.length === 1) {
      last = titleCase(tokens[0]);
      first = '';
    } else {
      first = titleCase(tokens[0]);
      // Last token may be a suffix — use the one before it if so
      const lastToken = tokens[tokens.length - 1];
      if (SUFFIXES.has(lastToken.toLowerCase()) && tokens.length > 2) {
        last = titleCase(tokens[tokens.length - 2]);
      } else {
        last = titleCase(lastToken);
      }
    }
  }

  const fullName = first ? `${first} ${last}` : last;
  return { firstName: first, lastName: last, fullName };
}

// ---------------------------------------------------------------------------
// Schema introspection
// ---------------------------------------------------------------------------

interface SchemaInfo {
  hasPoliticiansSourceColumn: boolean;
  sourceColumnConstrained: boolean; // true if source column has a CHECK or enum restriction
}

async function introspectSchema(): Promise<SchemaInfo> {
  // Check if 'source' column exists on essentials.politicians
  const colRes = await pool.query<{ column_name: string; data_type: string }>(`
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'essentials' AND table_name = 'politicians' AND column_name = 'source'
  `);
  const hasPoliticiansSourceColumn = colRes.rows.length > 0;

  let sourceColumnConstrained = false;
  if (hasPoliticiansSourceColumn) {
    // Check for CHECK constraints on the source column
    const checkRes = await pool.query<{ conname: string; consrc: string }>(`
      SELECT c.conname, pg_get_constraintdef(c.oid) AS consrc
      FROM pg_constraint c
      JOIN pg_class t ON t.oid = c.conrelid
      JOIN pg_namespace n ON n.oid = t.relnamespace
      WHERE n.nspname = 'essentials'
        AND t.relname = 'politicians'
        AND c.contype = 'c'
        AND pg_get_constraintdef(c.oid) ILIKE '%source%'
    `);
    sourceColumnConstrained = checkRes.rows.length > 0;
    if (sourceColumnConstrained) {
      console.warn('[schema] WARNING: source column has CHECK constraint — will use NULL instead of "indiana_discovery"');
      for (const row of checkRes.rows) {
        console.warn(`  Constraint: ${row.conname} — ${row.consrc}`);
      }
    }
  }

  return { hasPoliticiansSourceColumn, sourceColumnConstrained };
}

// ---------------------------------------------------------------------------
// Per-candidate processing
// ---------------------------------------------------------------------------

interface ProcessResult {
  action: 'SKIP' | 'EXISTING_LINKED' | 'EXISTING_NEW_SOURCE' | 'NEW' | 'ERROR';
  name: string;
  fileNumber: string;
  error?: string;
}

async function processCandidate(
  queryFn: (sql: string, params?: unknown[]) => Promise<{ rows: any[]; rowCount: number | null }>,
  rec: CommitteeRecord,
  parsed: ParsedName,
  schema: SchemaInfo,
  dryRun: boolean,
): Promise<ProcessResult> {
  const { fileNumber, committee, latestYear } = rec;
  const { firstName, lastName, fullName } = parsed;

  // Step 1: Check if this FileNumber already exists in politician_sources
  const existsRes = await queryFn(
    `SELECT id FROM transparent_motivations.politician_sources
     WHERE source_system = 'indiana' AND external_id = $1`,
    [fileNumber]
  );
  if ((existsRes.rowCount ?? 0) > 0) {
    return { action: 'SKIP', name: fullName, fileNumber };
  }

  // Step 2: Check for name match in essentials.politicians
  const nameMatchRes = await queryFn(
    `SELECT id, full_name FROM essentials.politicians
     WHERE lower(full_name) = lower($1) AND is_active = true
       AND full_name IS NOT NULL AND full_name != ''
     LIMIT 1`,
    [fullName]
  );

  if ((nameMatchRes.rowCount ?? 0) > 0) {
    // Name match found — check for existing indiana source
    const matchedId = nameMatchRes.rows[0].id as string;

    const sourceExistsRes = await queryFn(
      `SELECT id FROM transparent_motivations.politician_sources
       WHERE source_system = 'indiana' AND essentials_politician_id = $1`,
      [matchedId]
    );

    if ((sourceExistsRes.rowCount ?? 0) > 0) {
      // Already linked
      return { action: 'EXISTING_LINKED', name: fullName, fileNumber };
    }

    // Create politician_sources only (no new politician row)
    if (!dryRun) {
      const notes = `Auto-discovered from Indiana ${latestYear} contribution data. Committee: ${committee}. Office type unknown — needs manual assignment.`;
      await queryFn(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, notes)
         VALUES ($1, 'indiana', $2, 'needs_research', $3)
         ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
        [matchedId, fileNumber, notes]
      );
    }
    return { action: 'EXISTING_NEW_SOURCE', name: fullName, fileNumber };
  }

  // Step 3: No match — create new politician + office + source
  if (!dryRun) {
    // 3a: INSERT politician
    let insertCols = 'full_name, first_name, last_name, is_active, is_incumbent, is_vacant';
    let insertVals = '$1, $2, $3, true, true, false';
    const insertParams: unknown[] = [fullName, firstName, lastName];
    let paramIdx = 4;

    // Only include 'source' column if it exists AND is not constrained
    if (schema.hasPoliticiansSourceColumn && !schema.sourceColumnConstrained) {
      insertCols += ', source';
      insertVals += `, $${paramIdx++}`;
      insertParams.push('indiana_discovery');
    }

    const politicianRes = await queryFn(
      `INSERT INTO essentials.politicians (${insertCols})
       VALUES (${insertVals})
       ON CONFLICT DO NOTHING
       RETURNING id`,
      insertParams
    );

    let politicianId: string;
    if ((politicianRes.rowCount ?? 0) === 0) {
      // ON CONFLICT hit — politician was created by a concurrent row or race condition
      // Look it up
      const lookupRes = await queryFn(
        `SELECT id FROM essentials.politicians WHERE lower(full_name) = lower($1) LIMIT 1`,
        [fullName]
      );
      if ((lookupRes.rowCount ?? 0) === 0) {
        return {
          action: 'ERROR',
          name: fullName,
          fileNumber,
          error: `Could not insert or find politician for "${fullName}"`,
        };
      }
      politicianId = lookupRes.rows[0].id as string;
    } else {
      politicianId = politicianRes.rows[0].id as string;
    }

    // 3b: INSERT office (placeholder title — Indiana CSVs have no office type)
    await queryFn(
      `INSERT INTO essentials.offices
         (politician_id, title, representing_state, chamber_id, district_id)
       VALUES ($1, 'Indiana Elected Official', 'IN', NULL, NULL)
       ON CONFLICT (politician_id) DO NOTHING`,
      [politicianId]
    );

    // 3c: INSERT politician_sources
    const notes = `Auto-discovered from Indiana ${latestYear} contribution data. Committee: ${committee}. Office type unknown — needs manual assignment.`;
    await queryFn(
      `INSERT INTO transparent_motivations.politician_sources
         (essentials_politician_id, source_system, external_id, research_status, notes)
       VALUES ($1, 'indiana', $2, 'needs_research', $3)
       ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
      [politicianId, fileNumber, notes]
    );
  }

  return { action: 'NEW', name: fullName, fileNumber };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const startMs = Date.now();

  // ---------------------------------------------------------------------------
  // Phase 1: Download and parse all years
  // ---------------------------------------------------------------------------

  console.log('\n=== PHASE 1: Download and parse Indiana contribution CSVs ===');
  const allRows: RawCommitteeRow[] = [];
  let totalDataRows = 0;

  for (const year of years) {
    const zipBuffer = await downloadZip(year);
    if (!zipBuffer) continue;

    try {
      const rows = parseZipCsv(zipBuffer, year);
      totalDataRows += rows.length;
      // Use loop instead of spread to avoid stack overflow on large arrays (163k+ rows)
      for (const row of rows) {
        allRows.push(row);
      }
    } catch (err: any) {
      console.warn(`[Phase 1] WARNING: CSV parse failed for year ${year}: ${err.message} — skipping`);
    }
  }

  console.log(`[Phase 1] Total data rows across all years: ${totalDataRows.toLocaleString()}`);
  console.log(`[Phase 1] Total rows collected: ${allRows.length.toLocaleString()}`);

  if (allRows.length === 0) {
    console.error('[Phase 1] ERROR: No rows collected — check download failures above');
    process.exit(1);
  }

  // ---------------------------------------------------------------------------
  // Phase 2: Enumerate candidate committees
  // ---------------------------------------------------------------------------

  console.log('\n=== PHASE 2: Enumerate candidate committees ===');
  const { committees, distinctTypes } = buildCommitteeMap(allRows);

  // Log ALL DISTINCT committeeType values (critical for filter validation)
  console.log('\n--- DISTINCT committeeType values found ---');
  const sortedTypes = Array.from(distinctTypes.entries()).sort((a, b) => b[1] - a[1]);
  for (const [type, count] of sortedTypes) {
    console.log(`  "${type}": ${count.toLocaleString()} rows`);
  }
  console.log('--- end committeeType values ---\n');

  console.log(`[Phase 2] Unique committees (all types): ${Array.from(new Set(allRows.map(r => r.fileNumber))).length.toLocaleString()}`);
  console.log(`[Phase 2] Candidate committees (after filter): ${committees.length.toLocaleString()}`);
  console.log(`[Phase 2] Found ${committees.length} unique candidate committees across years ${years.join(', ')}, from ${totalDataRows.toLocaleString()} total contribution rows`);

  // ---------------------------------------------------------------------------
  // Phase 3: Match and seed
  // ---------------------------------------------------------------------------

  console.log('\n=== PHASE 3: Match against existing politicians and seed ===');

  // Schema introspection (always run — needed for INSERT column selection)
  const schema = await introspectSchema();
  console.log(`[Phase 3] politicians.source column exists: ${schema.hasPoliticiansSourceColumn}, constrained: ${schema.sourceColumnConstrained}`);

  // Process in batches of 50
  const BATCH_SIZE = 50;
  const counts = {
    skip: 0,
    existingLinked: 0,
    existingNewSource: 0,
    newPolitician: 0,
    errors: 0,
  };

  for (let i = 0; i < committees.length; i += BATCH_SIZE) {
    const batch = committees.slice(i, i + BATCH_SIZE);

    if (!isDryRun) {
      const client = await pool.connect();
      try {
        await client.query('BEGIN');

        for (const rec of batch) {
          const parsed = parseCandidateName(rec.candidateName);
          // SAVEPOINT per-row — UUID errors or constraint violations don't abort the whole batch
          const spName = `sp_${rec.fileNumber.replace(/[^a-zA-Z0-9]/g, '_')}`;
          await client.query(`SAVEPOINT ${spName}`);

          try {
            const queryFn = (sql: string, params?: unknown[]) => client.query(sql, params) as any;
            const result = await processCandidate(queryFn, rec, parsed, schema, false);

            switch (result.action) {
              case 'SKIP':
                counts.skip++;
                break;
              case 'EXISTING_LINKED':
                counts.existingLinked++;
                console.log(`EXISTING_LINKED: ${result.name} (FileNumber=${result.fileNumber})`);
                break;
              case 'EXISTING_NEW_SOURCE':
                counts.existingNewSource++;
                console.log(`EXISTING_NEW_SOURCE: ${result.name} (FileNumber=${result.fileNumber})`);
                break;
              case 'NEW':
                counts.newPolitician++;
                console.log(`NEW: ${result.name} → created (FileNumber=${result.fileNumber})`);
                break;
              case 'ERROR':
                counts.errors++;
                console.error(`ERROR: ${result.name} (FileNumber=${result.fileNumber}): ${result.error}`);
                break;
            }

            await client.query(`RELEASE SAVEPOINT ${spName}`);
          } catch (err: any) {
            await client.query(`ROLLBACK TO SAVEPOINT ${spName}`);
            counts.errors++;
            console.error(`  ERROR processing FileNumber ${rec.fileNumber} (${rec.candidateName}): ${err.message}`);
          }
        }

        await client.query('COMMIT');
      } catch (err) {
        await client.query('ROLLBACK');
        console.error(`  ERROR: rolled back batch at offset ${i}:`, err);
      } finally {
        client.release();
      }
    } else {
      // Dry-run: run queries but no writes
      for (const rec of batch) {
        const parsed = parseCandidateName(rec.candidateName);
        try {
          const queryFn = (sql: string, params?: unknown[]) => pool.query(sql, params) as any;
          const result = await processCandidate(queryFn, rec, parsed, schema, true);

          switch (result.action) {
            case 'SKIP':
              counts.skip++;
              break;
            case 'EXISTING_LINKED':
              counts.existingLinked++;
              break;
            case 'EXISTING_NEW_SOURCE':
              counts.existingNewSource++;
              break;
            case 'NEW':
              counts.newPolitician++;
              break;
            case 'ERROR':
              counts.errors++;
              console.error(`ERROR (dry-run): ${result.name} (FileNumber=${result.fileNumber}): ${result.error}`);
              break;
          }
        } catch (err: any) {
          counts.errors++;
          console.error(`  ERROR (dry-run) processing FileNumber ${rec.fileNumber}: ${err.message}`);
        }
      }
    }

    // Progress report every 500 candidates
    if ((i + BATCH_SIZE) % 500 === 0 || i + BATCH_SIZE >= committees.length) {
      console.log(`  ... processed ${Math.min(i + BATCH_SIZE, committees.length)} / ${committees.length} candidates`);
    }
  }

  // ---------------------------------------------------------------------------
  // Summary
  // ---------------------------------------------------------------------------

  const durationMs = Date.now() - startMs;
  console.log('\n=== DISCOVERY SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no changes made to database)');
  }
  console.log(`Years processed:              ${years.join(', ')}`);
  console.log(`Total contribution rows:      ${totalDataRows.toLocaleString()}`);
  console.log(`Candidate committees found:   ${committees.length.toLocaleString()}`);
  console.log(`Already linked (skip):        ${counts.skip.toLocaleString()}`);
  console.log(`Existing, now linked:         ${counts.existingLinked.toLocaleString()}`);
  console.log(`Existing + new source added:  ${counts.existingNewSource.toLocaleString()}`);
  console.log(`New politicians created:       ${counts.newPolitician.toLocaleString()}`);
  console.log(`Errors:                       ${counts.errors.toLocaleString()}`);
  console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);

  process.exit(0);
}

main()
  .catch(err => {
    console.error('[discover-indiana-candidates] Fatal error:', err);
    process.exit(1);
  })
  .finally(() => pool.end());
