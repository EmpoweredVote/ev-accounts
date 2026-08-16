/**
 * confirm-cal-access.ts — match 76k+ Cal-Access needs_research source rows to real CA politicians.
 *
 * Usage:
 *   npx tsx scripts/confirm-cal-access.ts                    # live run: INSERT confirmed rows + trigger ingest
 *   npx tsx scripts/confirm-cal-access.ts --dry-run           # classify + write CSVs, no DB writes
 *   npx tsx scripts/confirm-cal-access.ts --report            # generate operator-friendly review CSV (one row per committee)
 *   npx tsx scripts/confirm-cal-access.ts --ambiguous <path>  # re-run: apply operator decisions from CSV
 *
 * Classification logic:
 *   AUTO-CONFIRM: exactly 1 CA politician's last name found as whole word in committee name
 *                 AND at least 1 signal word present (FOR/COMMITTEE/CAMPAIGN/ELECT/OFFICEHOLDER/EXPLORATORY)
 *   AMBIGUOUS:    multiple politicians match; OR last name matches but no signal word found
 *   NO-MATCH:     no politician's last name found -> silently skip (not written to CSV)
 *
 * DB write strategy:
 *   - INSERT new confirmed source rows linking Cal-Access filer IDs to real is_active=true CA politicians
 *   - ON CONFLICT DO NOTHING (safe to re-run)
 *   - Old PAC-linked needs_research rows are NEVER modified or deleted
 *
 * DO NOT trigger ingest via HTTP POST — Cloudflare blocks posts to accounts.empowered.vote.
 * Use runAdapterForAll('cal_access') direct function call instead.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { parse as parseCsv } from 'csv-parse/sync';

// ─── 🔴 PREDICATE TRIPWIRE — READ BEFORE RE-ENABLING THIS SCRIPT ──────────────
//
// This script's matching rule is BROKEN and produced 7,853 committee links across 578 active
// politicians (7,836 of them auto-confirmed), displaying $42.3M. Audited 2026-08-16.
//
// THE DEFECT, in two parts:
//   1. `extractLastName()` returns the LAST SPACE-DELIMITED TOKEN of full_name, which is very often
//      not the surname. `essentials.politicians.last_name` is stored on the row and was ignored.
//        Gracey Van Der Mark -> "mark"  -> 391 committees containing the GIVEN NAME Mark
//        Jesse Avila Jr      -> "jr"    -> 116 committees containing the SUFFIX
//        Walter Allen III    -> "iii"   ->  25
//   2. Even when the token IS the surname, a surname is not a person. Traci Park -> "park" matched
//      Buena Park, Menlo Park and East Bay Regional Park District. Ashley Johnson -> "johnson"
//      matched Ray, Ben, Jimmie, Stephanie, Nancy and Michael V. Johnson's committees.
//   Compounding both: hasSignalWord() is not a filter. SIGNAL_WORDS is FOR/COMMITTEE/CAMPAIGN/
//   ELECT/OFFICEHOLDER/EXPLORATORY, and every candidate committee name contains one, so it ADMITS.
//
// 🔑 THERE WAS NEVER AN INDEPENDENT CHECK. This script both generates the match and confirms it in
// one pass, which is why 7,836 of 7,853 came back "confirmed". A ~100% confirm rate is the smell.
//
// The script has been INERT since migration 1463 dropped `essentials.offices.politician_id`, which
// line ~163 still joins on — it throws at runtime. That is luck, not design. Fixing that join is a
// one-line change and would silently re-run the identical predicate at full scale.
//
// ⛔ DO NOT remove this abort merely to make the script run. Replace the PREDICATE first:
//   · match on `essentials.politicians.last_name`, never on a token split out of full_name;
//   · require the politician's GIVEN name adjacent to the surname, or corroborate against the
//     Cal-Access candidate-name / office / district / year fields — `committee_name` alone cannot
//     identify a person;
//   · make confirmation a SEPARATE pass with a DIFFERENT predicate from the generator.
// `backend/scripts/check-cal-access-predicate.mjs` enforces exactly this in CI: it lets you delete
// this abort only once `parts[parts.length - 1]` is gone from the file.
//
// Audit + remediation state: memory `cal_access_lasttoken_mislinks`; migration 1788 (the Robert
// Garcia / Antonio Vazquez conflation that surfaced it); migration 1789 (bucket-A cleanup).
if (!process.env.CAL_ACCESS_PREDICATE_REPLACED) {
  console.error(
    'ABORT: confirm-cal-access.ts is disabled — its matching predicate is known-broken.\n' +
    'It links committees on the LAST TOKEN of full_name ("Van Der Mark" -> "mark", "Avila Jr" -> "jr")\n' +
    'and its signal-word check admits every committee name rather than filtering any.\n' +
    'It created 7,853 links on 578 active politicians, 7,836 auto-confirmed, $42.3M displayed.\n\n' +
    'Fix the PREDICATE, not just the dead offices.politician_id join, then set\n' +
    'CAL_ACCESS_PREDICATE_REPLACED=1. See the block above this check and memory\n' +
    '`cal_access_lasttoken_mislinks` for what a correct predicate has to do.'
  );
  process.exit(1);
}

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');
const isReport = process.argv.includes('--report');
const ambiguousIdx = process.argv.indexOf('--ambiguous');
const ambiguousFile = ambiguousIdx !== -1 ? process.argv[ambiguousIdx + 1] : null;

if (ambiguousFile && !fs.existsSync(ambiguousFile)) {
  console.error(`ERROR: --ambiguous file not found: ${ambiguousFile}`);
  process.exit(1);
}

// ─── DB Pool ─────────────────────────────────────────────────────────────────

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Types ────────────────────────────────────────────────────────────────────

interface CaPolitician {
  id: string;
  full_name: string;
  office_title: string | null;
  normalized_last: string;
}

interface CalAccessSourceRow {
  source_id: string;
  external_id: string;   // Cal-Access filer ID
  committee_name: string; // full_name from the PAC politician row (is_active=false)
}

type ClassifiedDecision = 'confirm' | 'ambiguous' | 'no-match';

interface MatchedPolitician {
  id: string;
  full_name: string;
  office_title: string | null;
}

interface ClassifiedRow {
  source_id: string;
  filer_id: string;
  committee_name: string;
  decision: ClassifiedDecision;
  reason: string;
  matched_count: number;
  matches: MatchedPolitician[];
}

// ─── Helpers (copied verbatim from confirm-la-socrata.ts) ─────────────────────

/**
 * Normalize a string for matching: lowercase, remove accents.
 */
function normalize(str: string): string {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase();
}

/**
 * Extract last name from a full name string (last space-delimited token).
 */
function extractLastName(fullName: string): string {
  const parts = fullName.trim().split(/\s+/);
  return parts[parts.length - 1] ?? fullName;
}

// ─── Signal words ─────────────────────────────────────────────────────────────

const SIGNAL_WORDS = ['FOR', 'COMMITTEE', 'CAMPAIGN', 'ELECT', 'OFFICEHOLDER', 'EXPLORATORY'];

function hasSignalWord(committeeName: string): boolean {
  const upper = committeeName.toUpperCase();
  return SIGNAL_WORDS.some(word => upper.includes(word));
}

// ─── Timestamp helper ────────────────────────────────────────────────────────

function nowTimestamp(): string {
  return new Date().toISOString().replace(/:/g, '-').replace(/\..+/, '');
}

// ─── CSV helpers ─────────────────────────────────────────────────────────────

function quoteCsv(val: string | null | undefined): string {
  const s = val ?? '';
  return `"${s.replace(/"/g, '""')}"`;
}

function csvRow(fields: (string | null | undefined)[]): string {
  return fields.map(quoteCsv).join(',');
}

const CSV_HEADERS = ['filer_id', 'committee_name', 'politician_id', 'politician_name', 'office_title', 'matched_count', 'reason', 'decision'];

// Report CSV — one row per committee, operator-friendly grouping
// Compatible with --ambiguous re-run mode (reads filer_id, politician_id, decision)
const REPORT_CSV_HEADERS = ['filer_id', 'committee_name', 'case_type', 'match_count', 'matches', 'politician_id', 'decision'];

interface ReportRow {
  filerId: string;
  committeeName: string;
  caseType: 'single_no_signal' | 'multi_match';
  matchCount: number;
  matches: MatchedPolitician[];
}

// ─── DB queries ──────────────────────────────────────────────────────────────

/**
 * Fetch all is_active=true politicians with CA office connections.
 * Deduplicated by politician ID (takes first office found).
 */
async function fetchCaPoliticians(): Promise<Map<string, CaPolitician>> {
  const result = await pool.query<{ id: string; full_name: string; office_title: string | null }>(`
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      o.title AS office_title
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    LEFT JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.is_active = true
      AND (o.representing_state = 'CA' OR d.state = 'CA')
    ORDER BY p.id, p.full_name
  `);

  const map = new Map<string, CaPolitician>();
  for (const row of result.rows) {
    const lastName = extractLastName(row.full_name ?? '');
    if (!lastName) {
      console.warn(`[confirm-cal-access] WARNING: empty lastName for politician ${row.id} ("${row.full_name}") — skipping from matching`);
      continue;
    }
    map.set(row.id, {
      id: row.id,
      full_name: row.full_name,
      office_title: row.office_title,
      normalized_last: normalize(lastName),
    });
  }
  return map;
}

/**
 * Fetch all Cal-Access needs_research source rows.
 * committee_name comes from the PAC politician row (is_active=false).
 */
async function fetchCalAccessSourceRows(): Promise<CalAccessSourceRow[]> {
  const result = await pool.query<CalAccessSourceRow>(`
    SELECT
      ps.id          AS source_id,
      ps.external_id,
      p.full_name    AS committee_name
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'cal_access'
      AND ps.research_status = 'needs_research'
  `);
  return result.rows;
}

// ─── Classification ───────────────────────────────────────────────────────────

function classifyRow(
  sourceRow: CalAccessSourceRow,
  caPoliticians: Map<string, CaPolitician>
): ClassifiedRow {
  const committeeName = sourceRow.committee_name ?? '';
  const normalizedCmt = normalize(committeeName);

  const matches: MatchedPolitician[] = [];

  for (const politician of caPoliticians.values()) {
    const { normalized_last } = politician;
    if (!normalized_last) continue;

    // Escape regex special chars in last name before building whole-word regex
    const escaped = normalized_last.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const lastNameRegex = new RegExp('\\b' + escaped + '\\b', 'i');

    if (lastNameRegex.test(normalizedCmt)) {
      matches.push({
        id: politician.id,
        full_name: politician.full_name,
        office_title: politician.office_title,
      });
    }
  }

  const matchCount = matches.length;

  if (matchCount === 0) {
    return {
      source_id: sourceRow.source_id,
      filer_id: sourceRow.external_id,
      committee_name: committeeName,
      decision: 'no-match',
      reason: 'no CA politician last name found in committee name',
      matched_count: 0,
      matches: [],
    };
  }

  const signalPresent = hasSignalWord(committeeName);

  if (matchCount === 1 && signalPresent) {
    return {
      source_id: sourceRow.source_id,
      filer_id: sourceRow.external_id,
      committee_name: committeeName,
      decision: 'confirm',
      reason: `lastName "${extractLastName(matches[0].full_name)}" in committee name, signal word present`,
      matched_count: 1,
      matches,
    };
  }

  if (matchCount > 1) {
    return {
      source_id: sourceRow.source_id,
      filer_id: sourceRow.external_id,
      committee_name: committeeName,
      decision: 'ambiguous',
      reason: `multiple CA politicians matched (${matchCount}): ${matches.map(m => extractLastName(m.full_name)).join(', ')}`,
      matched_count: matchCount,
      matches,
    };
  }

  // matchCount === 1 but no signal word
  return {
    source_id: sourceRow.source_id,
    filer_id: sourceRow.external_id,
    committee_name: committeeName,
    decision: 'ambiguous',
    reason: `lastName "${extractLastName(matches[0].full_name)}" in committee name but no signal word found`,
    matched_count: 1,
    matches,
  };
}

// ─── Main flow ────────────────────────────────────────────────────────────────

async function runMain(): Promise<void> {
  const startMs = Date.now();
  const ts = nowTimestamp();

  // Build output paths using process.argv[1] for Windows compat (not import.meta.url)
  const scriptsDir = path.dirname(path.resolve(process.argv[1]));
  const auditPath = path.join(scriptsDir, `cal-access-confirm-${ts}.csv`);
  const ambigPath = path.join(scriptsDir, `cal-access-ambiguous-${ts}.csv`);

  console.log('[confirm-cal-access] Mode: ' + (isDryRun ? 'DRY-RUN (no DB writes, no ingest)' : 'LIVE'));

  // Step 1 — Fetch target politicians
  console.log('[confirm-cal-access] Fetching is_active=true CA politicians...');
  const caPoliticians = await fetchCaPoliticians();
  console.log(`[confirm-cal-access] Found ${caPoliticians.size} unique CA politicians for matching.`);

  // Step 2 — Fetch Cal-Access source rows
  console.log('[confirm-cal-access] Fetching Cal-Access needs_research source rows...');
  const sourceRows = await fetchCalAccessSourceRows();
  console.log(`[confirm-cal-access] Found ${sourceRows.length} needs_research rows.`);

  if (sourceRows.length === 0) {
    console.log('[confirm-cal-access] Nothing to do.');
    return;
  }

  // Open CSV write streams
  const auditStream = fs.createWriteStream(auditPath, { encoding: 'utf8' });
  const ambigStream = fs.createWriteStream(ambigPath, { encoding: 'utf8' });

  auditStream.write(CSV_HEADERS.join(',') + '\n');
  ambigStream.write(CSV_HEADERS.join(',') + '\n');

  const counts = { confirmed: 0, ambiguous: 0, noMatch: 0, dbInserted: 0 };

  // Collect ambiguous rows for --report mode
  const reportRows: ReportRow[] = [];

  // Collect confirmed rows for batch insert
  interface ConfirmedInsertRow {
    politicianId: string;
    filerId: string;
    committeeName: string;
  }
  const confirmedInserts: ConfirmedInsertRow[] = [];

  // Step 3–5 — Classify and write CSVs
  for (const sourceRow of sourceRows) {
    const classified = classifyRow(sourceRow, caPoliticians);

    if (classified.decision === 'no-match') {
      counts.noMatch++;
      // NO-MATCH rows are silently skipped — not written to any CSV
      continue;
    }

    if (classified.decision === 'confirm') {
      counts.confirmed++;
      const politician = classified.matches[0];

      // Write to audit CSV
      const auditLine = csvRow([
        classified.filer_id,
        classified.committee_name,
        politician.id,
        politician.full_name,
        politician.office_title,
        String(classified.matched_count),
        classified.reason,
        'confirm',
      ]) + '\n';
      auditStream.write(auditLine);

      // Collect for batch insert
      if (!isDryRun) {
        confirmedInserts.push({
          politicianId: politician.id,
          filerId: classified.filer_id,
          committeeName: classified.committee_name,
        });
      }
    } else if (classified.decision === 'ambiguous') {
      counts.ambiguous++;

      // Collect for --report mode (one entry per committee regardless of match count)
      reportRows.push({
        filerId: classified.filer_id,
        committeeName: classified.committee_name,
        caseType: classified.matched_count === 1 ? 'single_no_signal' : 'multi_match',
        matchCount: classified.matched_count,
        matches: classified.matches,
      });

      if (classified.matched_count === 1) {
        // Single-match ambiguous: pre-fill politician_id, blank decision
        const politician = classified.matches[0];
        const auditLine = csvRow([
          classified.filer_id,
          classified.committee_name,
          politician.id,
          politician.full_name,
          politician.office_title,
          String(classified.matched_count),
          classified.reason,
          '', // blank — operator fills in
        ]) + '\n';
        auditStream.write(auditLine);
        ambigStream.write(auditLine);
      } else {
        // Multi-match ambiguous: write one row per candidate politician, politician_id blank
        for (const politician of classified.matches) {
          const auditLine = csvRow([
            classified.filer_id,
            classified.committee_name,
            '', // blank — operator selects which UUID
            politician.full_name,
            politician.office_title,
            String(classified.matched_count),
            classified.reason,
            '', // blank — operator fills in
          ]) + '\n';
          auditStream.write(auditLine);
          ambigStream.write(auditLine);
        }
      }
    }
  }

  // Await stream close before proceeding (Windows WriteStream flush)
  await new Promise<void>((resolve, reject) => {
    auditStream.end((err?: Error | null) => err ? reject(err) : resolve());
  });
  await new Promise<void>((resolve, reject) => {
    ambigStream.end((err?: Error | null) => err ? reject(err) : resolve());
  });

  // Step 3b — Write report CSV if --report flag set
  if (isReport && reportRows.length > 0) {
    const reportPath = path.join(scriptsDir, `cal-access-report-${ts}.csv`);
    const reportStream = fs.createWriteStream(reportPath, { encoding: 'utf8' });
    reportStream.write(REPORT_CSV_HEADERS.join(',') + '\n');

    // Sort: single_no_signal first (bulk pre-approved, easy to scan), then multi_match by match_count ascending
    const sorted = [...reportRows].sort((a, b) => {
      if (a.caseType !== b.caseType) return a.caseType === 'single_no_signal' ? -1 : 1;
      return a.matchCount - b.matchCount;
    });

    for (const row of sorted) {
      // matches column: "Full Name (Office Title) [uuid] | ..." — all options visible in one cell
      const matchesStr = row.matches
        .map(m => `${m.full_name}${m.office_title ? ' (' + m.office_title + ')' : ''} [${m.id}]`)
        .join(' | ');

      const politicianId = row.caseType === 'single_no_signal' ? row.matches[0].id : '';
      const decision = row.caseType === 'single_no_signal' ? 'confirm' : '';

      reportStream.write(csvRow([
        row.filerId,
        row.committeeName,
        row.caseType,
        String(row.matchCount),
        matchesStr,
        politicianId,
        decision,
      ]) + '\n');
    }

    await new Promise<void>((resolve, reject) => {
      reportStream.end((err?: Error | null) => err ? reject(err) : resolve());
    });

    const singleCount = sorted.filter(r => r.caseType === 'single_no_signal').length;
    const multiCount = sorted.filter(r => r.caseType === 'multi_match').length;
    console.log(`\nReport CSV: ${reportPath}`);
    console.log(`  ${singleCount} single_no_signal rows (pre-filled "confirm" — change to "reject" to exclude)`);
    console.log(`  ${multiCount} multi_match rows (paste correct UUID into politician_id, type "confirm")`);
    console.log(`\nTo apply decisions: npx tsx scripts/confirm-cal-access.ts --ambiguous ${reportPath}`);
  }

  // Step 4 — Batch INSERT all confirmed source rows (live mode only)
  if (!isDryRun && confirmedInserts.length > 0) {
    console.log(`\n[confirm-cal-access] Inserting ${confirmedInserts.length} confirmed source rows...`);
    const BATCH_SIZE = 500;
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (let i = 0; i < confirmedInserts.length; i += BATCH_SIZE) {
        const batch = confirmedInserts.slice(i, i + BATCH_SIZE);
        const values: string[] = [];
        const params: string[] = [];
        let idx = 1;
        for (const row of batch) {
          const notes = JSON.stringify({
            confirmed_by: 'confirm-cal-access.ts',
            committee_name: row.committeeName,
          });
          values.push(`($${idx++}, 'cal_access', $${idx++}, 'confirmed', $${idx++})`);
          params.push(row.politicianId, row.filerId, notes);
        }
        const sql = `
          INSERT INTO transparent_motivations.politician_sources
            (essentials_politician_id, source_system, external_id, research_status, notes)
          VALUES ${values.join(', ')}
          ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING
        `;
        const result = await client.query(sql, params);
        counts.dbInserted += result.rowCount ?? 0;
        console.log(`  Batch ${Math.floor(i / BATCH_SIZE) + 1}: inserted ${result.rowCount ?? 0} rows`);
      }
      await client.query('COMMIT');
      console.log(`[confirm-cal-access] Batch insert complete. ${counts.dbInserted} new rows inserted.`);
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // Step 6 — Trigger ingest (live mode only)
  if (!isDryRun) {
    console.log('\n[confirm-cal-access] Triggering cal_access ingest...');
    try {
      const { runAdapterForAll } = await import('../src/lib/campaignFinanceScheduler.js');
      await runAdapterForAll('cal_access');
      console.log('[confirm-cal-access] Ingest complete.');
    } catch (importErr) {
      console.warn(
        '[confirm-cal-access] WARNING: Could not import runAdapterForAll from campaignFinanceScheduler.js.',
        'Phase 8.1 Express port may not yet be complete.',
        'Ingest must be triggered separately once Phase 8.1 is done.',
        '\nError:', (importErr as Error).message
      );
    }
  }

  const durationMs = Date.now() - startMs;

  // Step 7 — Print summary
  console.log('\n=== CONFIRMATION SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no DB writes, no ingest triggered)');
  }
  console.log(`Total needs_research rows:    ${sourceRows.length}`);
  console.log(`Auto-confirmed:               ${counts.confirmed}`);
  console.log(`Ambiguous (human review):     ${counts.ambiguous}`);
  console.log(`No-match (skipped):           ${counts.noMatch}`);
  if (!isDryRun) {
    console.log(`DB rows inserted:             ${counts.dbInserted}`);
  }
  console.log('');
  console.log(`Audit log:     ${auditPath}`);
  if (counts.ambiguous > 0) {
    console.log(`Ambiguous CSV: ${ambigPath}`);
  } else {
    console.log('Ambiguous CSV: (empty — no ambiguous rows)');
    try { fs.unlinkSync(ambigPath); } catch { /* ignore if already gone */ }
  }
  console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── UUID validation helper ───────────────────────────────────────────────────

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isValidUuid(str: string): boolean {
  return UUID_REGEX.test(str);
}

// ─── Ambiguous re-run mode (Plan 02) ─────────────────────────────────────────

async function runAmbiguous(filePath: string): Promise<void> {
  const startMs = Date.now();

  console.log(`[confirm-cal-access] Ambiguous re-run mode: reading ${filePath}`);
  const content = fs.readFileSync(filePath, 'utf8');

  interface AmbigCsvRow {
    filer_id: string;
    committee_name: string;
    politician_id: string;
    politician_name: string;
    office_title: string;
    matched_count: string;
    reason: string;
    decision: string;
  }

  const csvRows = parseCsv(content, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  }) as AmbigCsvRow[];

  console.log(`[confirm-cal-access] Parsed ${csvRows.length} rows from ambiguous CSV.`);

  const counts = { confirmed: 0, rejected: 0, skipped: 0, errors: 0 };

  for (const row of csvRows) {
    const filerId    = row.filer_id?.trim();
    const decision   = row.decision?.trim().toLowerCase();
    const politicianId = row.politician_id?.trim();

    // Skip blank decisions — operator hasn't reviewed yet
    if (!decision) {
      counts.skipped++;
      continue;
    }

    if (decision !== 'confirm' && decision !== 'reject') {
      counts.skipped++;
      continue;
    }

    if (decision === 'reject') {
      // Rejected: do not insert a new row, do not touch old PAC row. Log and skip.
      console.log(`  [REJECT] filer_id=${filerId} (${row.committee_name?.substring(0, 50)}) — skipped, no DB action`);
      counts.rejected++;
      continue;
    }

    // decision === 'confirm': validate then INSERT
    if (!politicianId) {
      console.error(`  [ERROR] decision=confirm but politician_id is blank for filer_id=${filerId} — skipping`);
      counts.errors++;
      continue;
    }

    if (!isValidUuid(politicianId)) {
      console.error(`  [ERROR] politician_id "${politicianId}" is not a valid UUID for filer_id=${filerId} — skipping`);
      counts.errors++;
      continue;
    }

    // INSERT new confirmed source row (politician_id is authoritative UUID — no name lookup needed)
    const notes = JSON.stringify({
      confirmed_by: 'confirm-cal-access.ts --ambiguous',
      committee_name: row.committee_name ?? '',
      politician_name: row.politician_name ?? '',
    });

    try {
      const result = await pool.query(
        `INSERT INTO transparent_motivations.politician_sources
           (essentials_politician_id, source_system, external_id, research_status, notes)
         VALUES ($1, 'cal_access', $2, 'confirmed', $3)
         ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
        [politicianId, filerId, notes]
      );
      const inserted = result.rowCount ?? 0;
      if (inserted > 0) {
        console.log(`  [CONFIRM] filer_id=${filerId} → politician_id=${politicianId} (${row.politician_name}) — inserted`);
        counts.confirmed++;
      } else {
        console.log(`  [CONFIRM] filer_id=${filerId} → politician_id=${politicianId} — already exists (skipped duplicate)`);
        counts.skipped++;
      }
    } catch (err) {
      console.error(`  [ERROR] INSERT failed for filer_id=${filerId} politician_id=${politicianId}:`, (err as Error).message);
      counts.errors++;
    }
  }

  // Trigger ingest after all DB updates
  console.log('\n[confirm-cal-access] Triggering cal_access ingest...');
  try {
    const { runAdapterForAll } = await import('../src/lib/campaignFinanceScheduler.js');
    await runAdapterForAll('cal_access');
    console.log('[confirm-cal-access] Ingest complete.');
  } catch (importErr) {
    console.warn(
      '[confirm-cal-access] WARNING: Could not import runAdapterForAll from campaignFinanceScheduler.js.',
      'Phase 8.1 Express port may not yet be complete.',
      'Ingest must be triggered separately once Phase 8.1 is done.',
      '\nError:', (importErr as Error).message
    );
  }

  const durationMs = Date.now() - startMs;

  console.log('\n=== AMBIGUOUS RE-RUN SUMMARY ===');
  console.log(`Confirmed:  ${counts.confirmed}`);
  console.log(`Rejected:   ${counts.rejected}`);
  console.log(`Skipped:    ${counts.skipped}`);
  if (counts.errors > 0) {
    console.log(`Errors:     ${counts.errors}`);
  }
  console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── Entry point ─────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  try {
    if (ambiguousFile) {
      await runAmbiguous(ambiguousFile);
    } else {
      await runMain();
    }
    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[confirm-cal-access] Fatal error:', err);
  process.exit(1);
});
