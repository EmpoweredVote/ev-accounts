/**
 * discover-cal-access-candidates.ts — Cal-Access candidate committee discovery.
 *
 * Usage:
 *   npx tsx scripts/discover-cal-access-candidates.ts --zip /path/to/dbwebexport.zip          # dry-run
 *   npx tsx scripts/discover-cal-access-candidates.ts --zip /path/to/dbwebexport.zip --execute # live
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * What it does:
 *   1. Loads FILER_TO_FILER_TYPE_CD.TSV and FILERNAME_CD.TSV from the Cal-Access bulk ZIP.
 *   2. Classifies each filer as 'candidate', 'ambiguous', or 'exclude'.
 *   3. For each candidate committee:
 *      a. Skips if FILER_ID already exists in politician_sources (idempotent).
 *      b. Flags name-matches against existing politicians for operator review.
 *      c. Creates new essentials.politicians + essentials.offices + politician_sources rows.
 *   4. Writes a JSON report with all counts and flagged entries.
 *
 * IMPORTANT:
 *   - All new politician_sources rows use research_status='needs_research' — never 'confirmed'
 *   - Script is idempotent — re-running produces 0 new rows (ON CONFLICT DO NOTHING)
 *   - Cal-Access uses Windows-1252 encoding — iconv-lite decodes before csv-parse
 */

import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { Pool } from 'pg';
import AdmZip from 'adm-zip';
import iconv from 'iconv-lite';
import { parse } from 'csv-parse/sync';

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

const args = process.argv.slice(2);
const zipArgIdx = args.indexOf('--zip');
if (zipArgIdx === -1 || !args[zipArgIdx + 1]) {
  console.error('ERROR: --zip <path> is required');
  console.error('Usage: npx tsx scripts/discover-cal-access-candidates.ts --zip /path/to/dbwebexport.zip [--execute]');
  process.exit(1);
}

const zipPath = args[zipArgIdx + 1];
const isDryRun = !args.includes('--execute');

if (!fs.existsSync(zipPath)) {
  console.error(`ERROR: ZIP file not found: ${zipPath}`);
  process.exit(1);
}

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
// TSV column types
// ---------------------------------------------------------------------------

interface FilerTypeRow {
  FILER_ID: string;
  FILER_TYPE: string;
  STATUS: string;
  EFFECT_DT: string;
  CATEGORY: string;
  CATEGORY_TYPE: string;
  SUB_CATEGORY: string;
  EFFECT_DT2?: string;
  RACE?: string;
  DISTRICT_CD?: string;
  OFFICE_CD?: string;
  SUB_CATEGORY_TYPE?: string;
  CATEGORY_DESC?: string;
  SUB_CATEGORY_DESC?: string;
  [key: string]: string | undefined;
}

interface FilerNameRow {
  FILER_ID: string;
  NAML: string;
  NAMF: string;
  NAMT?: string;
  NAMS?: string;
  EFFECT_DT: string;
  [key: string]: string | undefined;
}

// ---------------------------------------------------------------------------
// RACE code → office title lookup
// ---------------------------------------------------------------------------

const RACE_TO_OFFICE: Record<string, string | null> = {
  '30002': 'Governor',
  '30003': 'Lieutenant Governor',
  '30004': 'Secretary of State',
  '30005': 'Controller',
  '30006': 'Treasurer',
  '30007': 'Attorney General',
  '30008': 'Superintendent of Public Instruction',
  '30009': 'Member Board of Equalization',
  '30012': 'State Senator',
  '30013': 'Assembly Member',
  '30014': 'Insurance Commissioner',
  '30015': 'Judge',
  '30019': 'Supervisor',
  '30020': 'Sheriff',
  '30024': 'School Board Member',
  '30026': 'District Attorney',
  '30029': 'Mayor',
  '30030': 'City Attorney',
  '30032': 'Town Council Member',
  '30035': 'City Council Member',
  '30036': 'Commissioner',
  '0': null,
};

// ---------------------------------------------------------------------------
// Report types
// ---------------------------------------------------------------------------

interface FlaggedNameEntry {
  filer_id: string;
  filer_name: string;
  existing_politician_id: string;
  existing_politician_name: string;
  office_code: string;
  district_code: string;
}

interface FlaggedTypeEntry {
  filer_id: string;
  filer_name: string;
  category: string;
  sub_category: string;
}

interface Report {
  run_at: string;
  zip_path: string;
  dry_run: boolean;
  counts: {
    total_filer_type_rows: number;
    unique_filers_after_dedup: number;
    candidate_committees: number;
    ambiguous_type_filers: number;
    excluded_filers: number;
    already_exists_skipped: number;
    flagged_name_match: number;
    new_politicians_inserted: number;
    flagged_ambiguous_name: number;
    errors: number;
  };
  flagged_ambiguous_type: FlaggedTypeEntry[];
  flagged_ambiguous_name: FlaggedNameEntry[];
}

// ---------------------------------------------------------------------------
// Phase 1: Load and parse TSV files from ZIP (synchronous — files are small)
// ---------------------------------------------------------------------------

function loadTsv<T extends object>(zipBuffer: Buffer, entryPath: string): T[] {
  const zip = new AdmZip(zipBuffer);
  const entry = zip.getEntry(entryPath);
  if (!entry) throw new Error(`Entry not found in ZIP: ${entryPath}`);
  const rawBytes = entry.getData();
  const utf8 = iconv.decode(rawBytes, 'win1252');
  return parse(utf8, {
    delimiter: '\t',
    columns: true,
    relax_column_count: true,
    quote: false,
    skip_empty_lines: true,
    trim: true,
  }) as T[];
}

// ---------------------------------------------------------------------------
// Phase 2a: Classify filer type
// ---------------------------------------------------------------------------

function classifyFiler(row: FilerTypeRow): 'candidate' | 'ambiguous' | 'exclude' {
  if (row.SUB_CATEGORY === '40102') return 'candidate';  // PRIMARILY FORMED CANDIDATE
  if (row.CATEGORY === '40002' && row.SUB_CATEGORY === '0') return 'candidate';  // CONTROLLED
  if (row.SUB_CATEGORY === '40101') return 'exclude';  // PRIMARILY FORMED MEASURE
  if (['40103', '40104', '40105', '40112'].includes(row.SUB_CATEGORY)) return 'ambiguous';
  if (['40001', '40003'].includes(row.CATEGORY)) return 'ambiguous';
  return 'exclude';
}

// ---------------------------------------------------------------------------
// Phase 2b: Deduplicate by FILER_ID — keep highest EFFECT_DT
// ---------------------------------------------------------------------------

function deduplicateByFilerId<T extends { FILER_ID: string; EFFECT_DT: string }>(rows: T[]): T[] {
  const map = new Map<string, T>();
  for (const row of rows) {
    const existing = map.get(row.FILER_ID);
    if (!existing || row.EFFECT_DT > existing.EFFECT_DT) {
      map.set(row.FILER_ID, row);
    }
  }
  return Array.from(map.values());
}

// ---------------------------------------------------------------------------
// Schema introspection
// ---------------------------------------------------------------------------

interface SchemaInfo {
  hasPoliticiansSourceColumn: boolean;   // 'source' column exists on essentials.politicians
  hasDataSourceColumn: boolean;          // 'data_source' column exists on essentials.politicians
  politicianSourcesUniqueConstraint: string | null; // 'source_system, external_id' or 'politician_id, source_system, external_id'
  caChambers: Array<{ id: string; name: string }>;
  politiciansColumns: string[];
}

async function introspectSchema(): Promise<SchemaInfo> {
  // 1. Check essentials.politicians columns
  const columnsRes = await pool.query<{ column_name: string }>(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'essentials' AND table_name = 'politicians'
    ORDER BY ordinal_position
  `);
  const politiciansColumns = columnsRes.rows.map(r => r.column_name);
  const hasPoliticiansSourceColumn = politiciansColumns.includes('source');
  const hasDataSourceColumn = politiciansColumns.includes('data_source');

  // 2. Check politician_sources unique constraint columns
  let politicianSourcesUniqueConstraint: string | null = null;
  try {
    const constraintRes = await pool.query<{ conname: string; condef: string }>(`
      SELECT conname, pg_get_constraintdef(oid) AS condef
      FROM pg_constraint
      WHERE conrelid = 'transparent_motivations.politician_sources'::regclass
        AND contype = 'u'
      ORDER BY conname
    `);
    // Look for the most relevant unique constraint
    for (const row of constraintRes.rows) {
      const def = row.condef.toLowerCase();
      if (def.includes('source_system') && def.includes('external_id')) {
        politicianSourcesUniqueConstraint = row.condef;
        break;
      }
    }
  } catch (_err) {
    console.warn('[schema] Could not introspect politician_sources constraints — will use SELECT guard');
  }

  // 3. Inventory CA chambers
  const chambersRes = await pool.query<{ id: string; name: string }>(`
    SELECT id, name
    FROM essentials.chambers
    WHERE name ILIKE '%California%'
    ORDER BY name
  `);

  return {
    hasPoliticiansSourceColumn,
    hasDataSourceColumn,
    politicianSourcesUniqueConstraint,
    caChambers: chambersRes.rows,
    politiciansColumns,
  };
}

// ---------------------------------------------------------------------------
// Chamber matching for new office rows
// ---------------------------------------------------------------------------

function findChamberId(officeTitle: string | null, chambers: Array<{ id: string; name: string }>): string | null {
  if (!officeTitle) return null;
  const lower = officeTitle.toLowerCase();

  for (const chamber of chambers) {
    const chamberLower = chamber.name.toLowerCase();
    if (lower.includes('state senator') && chamberLower.includes('senate')) return chamber.id;
    if (lower.includes('assembly') && chamberLower.includes('assembly')) return chamber.id;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Candidate record type
// ---------------------------------------------------------------------------

interface CandidateRecord {
  filerId: string;
  firstName: string;
  lastName: string;
  fullName: string;
  raceCode: string;
  districtCode: string;
  officeCode: string;
  officeTitle: string | null;
  unknownRaceCode: boolean;
  blankFirstName: boolean;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const startMs = Date.now();
  const runAt = new Date().toISOString();

  console.log(`[discover-cal-access-candidates] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);
  console.log(`[discover-cal-access-candidates] ZIP: ${zipPath}`);

  const report: Report = {
    run_at: runAt,
    zip_path: zipPath,
    dry_run: isDryRun,
    counts: {
      total_filer_type_rows: 0,
      unique_filers_after_dedup: 0,
      candidate_committees: 0,
      ambiguous_type_filers: 0,
      excluded_filers: 0,
      already_exists_skipped: 0,
      flagged_name_match: 0,
      new_politicians_inserted: 0,
      flagged_ambiguous_name: 0,
      errors: 0,
    },
    flagged_ambiguous_type: [],
    flagged_ambiguous_name: [],
  };

  try {
    // -----------------------------------------------------------------------
    // Phase 1: Load and parse TSV files
    // -----------------------------------------------------------------------

    console.log('[Phase 1] Loading ZIP into buffer...');
    const zipBuffer = fs.readFileSync(zipPath);
    console.log(`[Phase 1] ZIP loaded (${(zipBuffer.length / 1024 / 1024).toFixed(1)} MB)`);

    console.log('[Phase 1] Parsing FILER_TO_FILER_TYPE_CD.TSV...');
    const filerTypeRows = loadTsv<FilerTypeRow>(zipBuffer, 'CalAccess/DATA/FILER_TO_FILER_TYPE_CD.TSV');
    report.counts.total_filer_type_rows = filerTypeRows.length;
    console.log(`[Phase 1] Loaded ${filerTypeRows.length} FILER_TO_FILER_TYPE_CD rows`);

    console.log('[Phase 1] Parsing FILERNAME_CD.TSV...');
    const filerNameRows = loadTsv<FilerNameRow>(zipBuffer, 'CalAccess/DATA/FILERNAME_CD.TSV');
    console.log(`[Phase 1] Loaded ${filerNameRows.length} FILERNAME_CD rows`);

    // -----------------------------------------------------------------------
    // Phase 2: Classify filers and build candidate map
    // -----------------------------------------------------------------------

    // Step 2a: Deduplicate FILER_TO_FILER_TYPE_CD by FILER_ID (most recent EFFECT_DT wins)
    const dedupedFilerTypes = deduplicateByFilerId(filerTypeRows);
    report.counts.unique_filers_after_dedup = dedupedFilerTypes.length;
    console.log(`[Phase 2] Deduped to ${dedupedFilerTypes.length} unique filer IDs`);

    // Step 2b: Classify
    const candidates: FilerTypeRow[] = [];
    const ambiguousTypes: FilerTypeRow[] = [];
    let excludedCount = 0;

    for (const row of dedupedFilerTypes) {
      const classification = classifyFiler(row);
      if (classification === 'candidate') {
        candidates.push(row);
      } else if (classification === 'ambiguous') {
        ambiguousTypes.push(row);
      } else {
        excludedCount++;
      }
    }

    report.counts.candidate_committees = candidates.length;
    report.counts.ambiguous_type_filers = ambiguousTypes.length;
    report.counts.excluded_filers = excludedCount;
    console.log(`[Phase 2] Classified: ${candidates.length} candidate, ${ambiguousTypes.length} ambiguous, ${excludedCount} excluded`);

    // Step 2c: Deduplicate FILERNAME_CD by FILER_ID — build name lookup map
    const dedupedNames = deduplicateByFilerId(filerNameRows);
    const nameMap = new Map<string, FilerNameRow>();
    for (const row of dedupedNames) {
      nameMap.set(row.FILER_ID, row);
    }
    console.log(`[Phase 2] Name map: ${nameMap.size} unique filer names`);

    // Step 2d–2e: Build candidate records with names and office info
    const candidateRecords: CandidateRecord[] = [];
    for (const filerRow of candidates) {
      const nameRow = nameMap.get(filerRow.FILER_ID);
      if (!nameRow) {
        console.log(`  WARN: FILER_ID ${filerRow.FILER_ID} has no name entry in FILERNAME_CD — skipping`);
        continue;
      }

      const rawFirst = (nameRow.NAMF ?? '').trim();
      const rawLast = (nameRow.NAML ?? '').trim();
      const blankFirstName = rawFirst === '';

      const firstName = rawFirst;
      const lastName = rawLast || '(unknown)';
      const fullName = rawFirst ? `${rawFirst} ${lastName}` : lastName;

      if (blankFirstName) {
        console.log(`  WARN: FILER_ID ${filerRow.FILER_ID} has blank NAMF (first name) — name="${fullName}" will need research`);
      }

      const raceCode = (filerRow.RACE ?? '0').trim();
      const districtCode = (filerRow.DISTRICT_CD ?? '').trim();
      const officeCode = (filerRow.OFFICE_CD ?? raceCode).trim();

      let officeTitle: string | null;
      let unknownRaceCode = false;
      if (raceCode in RACE_TO_OFFICE) {
        officeTitle = RACE_TO_OFFICE[raceCode] ?? null;
      } else {
        officeTitle = null;
        unknownRaceCode = raceCode !== '0' && raceCode !== '';
      }

      candidateRecords.push({
        filerId: filerRow.FILER_ID,
        firstName,
        lastName,
        fullName,
        raceCode,
        districtCode,
        officeCode,
        officeTitle,
        unknownRaceCode,
        blankFirstName,
      });
    }

    console.log(`[Phase 2] Built ${candidateRecords.length} candidate records`);

    // Populate ambiguous type list for report
    for (const row of ambiguousTypes) {
      const nameRow = nameMap.get(row.FILER_ID);
      report.flagged_ambiguous_type.push({
        filer_id: row.FILER_ID,
        filer_name: nameRow ? `${(nameRow.NAMF ?? '').trim()} ${(nameRow.NAML ?? '').trim()}`.trim() : '(no name)',
        category: row.CATEGORY,
        sub_category: row.SUB_CATEGORY,
      });
    }

    // -----------------------------------------------------------------------
    // Phase 3: Schema introspection + match/seed
    // -----------------------------------------------------------------------

    console.log('[Phase 3] Introspecting schema...');
    const schema = await introspectSchema();
    console.log(`[Phase 3] politicians columns: source=${schema.hasPoliticiansSourceColumn}, data_source=${schema.hasDataSourceColumn}`);
    console.log(`[Phase 3] politician_sources constraint: ${schema.politicianSourcesUniqueConstraint ?? 'not found — will use SELECT guard'}`);
    console.log(`[Phase 3] CA chambers found: ${schema.caChambers.length} — ${schema.caChambers.map(c => c.name).join(', ')}`);

    // Determine ON CONFLICT target for politician_sources
    // From STATE.md: constraint is now 3-column (politician_id, source_system, external_id)
    // We verify by checking whether the constraint def includes politician_id.
    // For discovery script inserts: we check FILER_ID (external_id) first to skip, then insert.
    // Since we already do a pre-check, ON CONFLICT DO NOTHING on (source_system, external_id)
    // would work if that index exists. If not, we rely on the pre-check.

    const hasSourceSystemExternalIdIndex = schema.politicianSourcesUniqueConstraint !== null &&
      !schema.politicianSourcesUniqueConstraint.toLowerCase().includes('politician_id');

    // Process in batches of 50
    const BATCH_SIZE = 50;
    let batchNum = 0;

    for (let i = 0; i < candidateRecords.length; i += BATCH_SIZE) {
      batchNum++;
      const batch = candidateRecords.slice(i, i + BATCH_SIZE);

      if (!isDryRun) {
        const client = await pool.connect();
        try {
          await client.query('BEGIN');

          for (const rec of batch) {
            // Use SAVEPOINT per-row so a single row failure doesn't abort the whole batch.
            // This matches the pattern from dedup-essentials-politicians.ts.
            const sp = `sp_${rec.filerId.replace(/[^a-zA-Z0-9]/g, '_')}`;
            await client.query(`SAVEPOINT ${sp}`);
            try {
              await processCandidate(client, rec, schema, hasSourceSystemExternalIdIndex, report, isDryRun);
              await client.query(`RELEASE SAVEPOINT ${sp}`);
            } catch (err: any) {
              await client.query(`ROLLBACK TO SAVEPOINT ${sp}`);
              console.error(`  ERROR processing FILER_ID ${rec.filerId}:`, err.message);
              report.counts.errors++;
            }
          }

          await client.query('COMMIT');
        } catch (err) {
          await client.query('ROLLBACK');
          console.error(`  ERROR: rolled back batch ${batchNum}:`, err);
          throw err;
        } finally {
          client.release();
        }
      } else {
        // Dry-run: just query (no transaction needed)
        for (const rec of batch) {
          try {
            await processCandidate(null, rec, schema, hasSourceSystemExternalIdIndex, report, isDryRun);
          } catch (err: any) {
            console.error(`  ERROR processing FILER_ID ${rec.filerId}:`, err.message);
            report.counts.errors++;
          }
        }
      }

      if (batchNum % 10 === 0) {
        console.log(`  ... processed ${i + batch.length} / ${candidateRecords.length} candidates`);
      }
    }

    // -----------------------------------------------------------------------
    // Write report JSON
    // -----------------------------------------------------------------------

    const timestamp = runAt.replace(/[:.]/g, '-').replace('T', '_').slice(0, 19);
    const reportPath = path.join(process.cwd(), `discover-cal-access-report-${timestamp}.json`);
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    console.log(`\n[discover-cal-access-candidates] Report written: ${reportPath}`);

    // -----------------------------------------------------------------------
    // Summary
    // -----------------------------------------------------------------------

    const durationMs = Date.now() - startMs;
    console.log('\n=== DISCOVERY SUMMARY ===');
    if (isDryRun) {
      console.log('(DRY-RUN — no changes made)');
    }
    console.log(`Total FILER_TO_FILER_TYPE_CD rows: ${report.counts.total_filer_type_rows}`);
    console.log(`Unique filers after dedup:         ${report.counts.unique_filers_after_dedup}`);
    console.log(`Candidate committees:              ${report.counts.candidate_committees}`);
    console.log(`Ambiguous type (logged, skipped):  ${report.counts.ambiguous_type_filers}`);
    console.log(`Excluded:                          ${report.counts.excluded_filers}`);
    console.log(`Already exists (skipped):          ${report.counts.already_exists_skipped}`);
    console.log(`New politicians inserted:           ${report.counts.new_politicians_inserted}`);
    console.log(`Flagged name matches:              ${report.counts.flagged_ambiguous_name}`);
    console.log(`Errors:                            ${report.counts.errors}`);
    console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);

    process.exit(0);
  } finally {
    await pool.end();
  }
}

// ---------------------------------------------------------------------------
// processCandidate: check/skip/flag/insert for a single candidate filer
// ---------------------------------------------------------------------------

import type { PoolClient } from 'pg';

async function processCandidate(
  client: PoolClient | null,
  rec: CandidateRecord,
  schema: SchemaInfo,
  hasSourceSystemExternalIdIndex: boolean,
  report: Report,
  dryRun: boolean,
): Promise<void> {
  const queryFn = client
    ? (sql: string, params?: unknown[]) => client.query(sql, params)
    : (sql: string, params?: unknown[]) => pool.query(sql, params);

  // Step 1: Check if FILER_ID already exists in politician_sources
  const existsRes = await queryFn(
    `SELECT id FROM transparent_motivations.politician_sources
     WHERE source_system = 'cal_access' AND external_id = $1`,
    [rec.filerId]
  );
  if ((existsRes.rowCount ?? 0) > 0) {
    console.log(`SKIP: FILER_ID ${rec.filerId} (${rec.fullName}) already exists`);
    report.counts.already_exists_skipped++;
    return;
  }

  // Step 2: Check for name match in essentials.politicians
  const nameMatchRes = await queryFn(
    `SELECT id, full_name FROM essentials.politicians
     WHERE lower(full_name) = lower($1) AND is_active = true
       AND full_name IS NOT NULL AND full_name != ''
     LIMIT 5`,
    [rec.fullName]
  );

  if ((nameMatchRes.rowCount ?? 0) > 0) {
    // Name match found — flag for review, but still create a new politician row
    const matchedPolitician = nameMatchRes.rows[0];
    console.log(`FLAG_NAME: ${rec.fullName} name-matches existing politician ${matchedPolitician.full_name} (${matchedPolitician.id}) — creating new row anyway`);
    report.counts.flagged_ambiguous_name++;
    report.flagged_ambiguous_name.push({
      filer_id: rec.filerId,
      filer_name: rec.fullName,
      existing_politician_id: matchedPolitician.id,
      existing_politician_name: matchedPolitician.full_name,
      office_code: rec.officeCode,
      district_code: rec.districtCode,
    });
    // Fall through to step 3 — still create a new politician row per CONTEXT.md decision
  }

  // Step 3: Create new politician row (regardless of name match)
  if (!dryRun && client) {
    // 3a: INSERT into essentials.politicians
    // Build dynamic INSERT based on available columns
    let insertCols = 'full_name, first_name, last_name, is_active, is_vacant, is_incumbent';
    let insertVals = '$1, $2, $3, true, false, false';
    const insertParams: unknown[] = [rec.fullName, rec.firstName, rec.lastName];
    let paramIdx = 4;

    if (schema.hasPoliticiansSourceColumn) {
      insertCols += ', source';
      insertVals += `, $${paramIdx++}`;
      insertParams.push('cal_access_discovery');
    } else if (schema.hasDataSourceColumn) {
      insertCols += ', data_source';
      insertVals += `, $${paramIdx++}`;
      insertParams.push('cal_access_discovery');
    }

    const politicianRes = await client.query(
      `INSERT INTO essentials.politicians (${insertCols})
       VALUES (${insertVals})
       ON CONFLICT DO NOTHING
       RETURNING id`,
      insertParams
    );

    if ((politicianRes.rowCount ?? 0) === 0) {
      // ON CONFLICT hit — politician already exists (rare edge case), look it up
      const lookupRes = await client.query(
        `SELECT id FROM essentials.politicians
         WHERE full_name = $1 AND is_active = true
         LIMIT 1`,
        [rec.fullName]
      );
      if ((lookupRes.rowCount ?? 0) === 0) {
        console.error(`  ERROR: Could not insert or find politician for "${rec.fullName}" (FILER_ID ${rec.filerId})`);
        report.counts.errors++;
        return;
      }
      // This is an idempotency case — already inserted politician
      return;
    }

    const politicianId = politicianRes.rows[0].id as string;

    // 3b: INSERT into essentials.offices
    // district_id is a UUID FK — Cal-Access DISTRICT_CD is a numeric code (e.g. "25", "0")
    // that does not map to UUID district records. Store null; district_cd goes in notes.
    const chamberId = findChamberId(rec.officeTitle, schema.caChambers);
    const officeTitle = rec.officeTitle;

    await client.query(
      `INSERT INTO essentials.offices (politician_id, title, representing_state, chamber_id)
       VALUES ($1, $2, 'CA', $3)
       ON CONFLICT (politician_id) DO NOTHING`,
      [politicianId, officeTitle, chamberId]
    );

    // 3c: INSERT into transparent_motivations.politician_sources
    const notes = JSON.stringify({
      office_code: rec.officeCode,
      race_code: rec.raceCode,
      district_code: rec.districtCode,
      blank_first_name: rec.blankFirstName,
      unknown_race_code: rec.unknownRaceCode,
      discovered_by: 'discover-cal-access-candidates.ts',
    });

    // Use ON CONFLICT DO NOTHING. The unique constraint is 3-column
    // (politician_id, source_system, external_id) per STATE.md [quick-004].
    // We already checked source_system+external_id above, so this is the final guard.
    await client.query(
      `INSERT INTO transparent_motivations.politician_sources
         (essentials_politician_id, source_system, external_id, research_status, notes)
       VALUES ($1, 'cal_access', $2, 'needs_research', $3)
       ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
      [politicianId, rec.filerId, notes]
    );

    report.counts.new_politicians_inserted++;
    const officePart = rec.officeTitle ?? `RACE=${rec.raceCode}`;
    const distPart = rec.districtCode || 'no-district';
    console.log(`NEW: ${rec.fullName} (${officePart}, district ${distPart}) → politician_id ${politicianId}`);
  } else {
    // Dry-run: report what would happen
    report.counts.new_politicians_inserted++;
    const officePart = rec.officeTitle ?? `RACE=${rec.raceCode}`;
    const distPart = rec.districtCode || 'no-district';
    const nameMatchNote = (nameMatchRes.rowCount ?? 0) > 0 ? ' [FLAG_NAME]' : '';
    console.log(`NEW (dry-run): ${rec.fullName} (${officePart}, district ${distPart}, FILER_ID=${rec.filerId})${nameMatchNote}`);
  }
}

main().catch(err => {
  console.error('[discover-cal-access-candidates] Fatal error:', err);
  process.exit(1);
});
