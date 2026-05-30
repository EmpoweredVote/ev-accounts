/**
 * confirm-indiana.ts — classify Indiana needs_research politician_sources rows and trigger ingest.
 *
 * Usage:
 *   npx tsx scripts/confirm-indiana.ts                    # live run: update DB + trigger ingest
 *   npx tsx scripts/confirm-indiana.ts --dry-run           # classify + write CSVs, no DB writes
 *   npx tsx scripts/confirm-indiana.ts --report            # alias for --dry-run
 *   npx tsx scripts/confirm-indiana.ts --ambiguous <path>  # re-run: apply operator decisions from CSV
 *
 * Classification logic:
 *   1. Extract committee name from notes via /Committee:\s*(.+?)\.\s*Office type/i
 *   2. If no committee name found -> AMBIGUOUS ("no committee name in notes")
 *   3. Extract last name from politician full_name
 *   4. If empty last name -> AMBIGUOUS ("empty lastName")
 *   5. If normalize(lastName) NOT in normalize(committeeName) -> AUTO-REJECT (not_applicable)
 *   6. If normalize(lastName) in normalize(committeeName) AND signal word present -> AUTO-CONFIRM
 *   7. If normalize(lastName) in normalize(committeeName) but NO signal word -> AMBIGUOUS
 *
 * Signal words: FOR, COMMITTEE, CAMPAIGN, ELECT, OFFICEHOLDER, EXPLORATORY, FRIENDS, VOTE,
 *               SUPPORTERS, VICTORY, SENATE, HOUSE, REPRESENTATIVE, HOOSIERS, CTE, SENATOR,
 *               MAYOR, COUNCIL, TRUSTEE
 *
 * DB status values (respect CHECK constraint):
 *   confirmed     -> research_status = 'confirmed'
 *   rejected      -> research_status = 'not_applicable'  (NOT 'rejected')
 *   ambiguous     -> no update (leaves as 'needs_research')
 *
 * IMPORTANT:
 *   - UPDATE existing rows only — NEVER INSERT new rows
 *   - Do NOT trigger ingest via HTTP POST (Cloudflare blocks posts to accounts.empowered.vote)
 *   - Use dynamic import of runAdapterForAll inside try/catch (Phase 8.1 adapter may not exist)
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { parse as parseCsv } from 'csv-parse/sync';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run') || process.argv.includes('--report');
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

interface NeedsResearchRow {
  source_id: string;
  external_id: string;
  notes: string | null;
  full_name: string;
  politician_id: string;
  office_title: string | null;
}

type Decision = 'confirm' | 'reject' | 'ambiguous';

interface ClassifiedRow extends NeedsResearchRow {
  decision: Decision;
  reason: string;
  committee_name: string;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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

/**
 * Windows-compatible timestamp: colons stripped from ISO string.
 */
function nowTimestamp(): string {
  return new Date().toISOString().replace(/:/g, '-').replace(/\..+/, '');
}

function quoteCsv(val: string | null | undefined): string {
  const s = val ?? '';
  return `"${s.replace(/"/g, '""')}"`;
}

function csvRow(fields: (string | null | undefined)[]): string {
  return fields.map(quoteCsv).join(',');
}

const CSV_HEADERS = ['politician_name', 'office_title', 'committee_name', 'external_id', 'decision', 'reason'];

// ─── Signal words ─────────────────────────────────────────────────────────────

const SIGNAL_WORDS = [
  'for', 'committee', 'campaign', 'elect', 'officeholder', 'exploratory',
  'friends', 'vote', 'supporters', 'victory', 'senate', 'house', 'representative',
  'hoosiers', 'hoosier', 'cte', 'senator', 'mayor', 'council', 'trustee',
];

function hasSignalWord(committeeName: string): boolean {
  const normalized = normalize(committeeName);
  return SIGNAL_WORDS.some(word => normalized.includes(word));
}

// ─── Committee name extraction ───────────────────────────────────────────────

const COMMITTEE_RE = /Committee:\s*(.+?)\.\s*Office type/i;

function extractCommitteeName(notes: string | null): string | null {
  if (!notes) return null;
  const match = COMMITTEE_RE.exec(notes);
  return match ? match[1].trim() : null;
}

// ─── DB queries ──────────────────────────────────────────────────────────────

async function fetchNeedsResearchRows(): Promise<NeedsResearchRow[]> {
  const result = await pool.query<NeedsResearchRow>(`
    SELECT
      ps.id          AS source_id,
      ps.external_id,
      ps.notes,
      p.full_name,
      p.id           AS politician_id,
      o.title        AS office_title
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    WHERE ps.source_system = 'indiana'
      AND ps.research_status = 'needs_research'
    ORDER BY p.full_name
  `);
  return result.rows;
}

async function updateResearchStatus(sourceId: string, status: 'confirmed' | 'not_applicable'): Promise<void> {
  await pool.query(
    `UPDATE transparent_motivations.politician_sources
     SET research_status = $1, updated_at = NOW()
     WHERE id = $2`,
    [status, sourceId]
  );
}

// ─── Classification ───────────────────────────────────────────────────────────

function classifyRow(row: NeedsResearchRow): { decision: Decision; reason: string; committeeName: string } {
  const committeeName = extractCommitteeName(row.notes);

  if (!committeeName) {
    return { decision: 'ambiguous', reason: 'no committee name in notes', committeeName: '' };
  }

  const lastName = extractLastName(row.full_name ?? '');
  const normalizedLast = normalize(lastName);

  if (!normalizedLast) {
    return { decision: 'ambiguous', reason: 'empty lastName extracted — cannot match', committeeName };
  }

  const normalizedCmt = normalize(committeeName);

  if (!normalizedCmt.includes(normalizedLast)) {
    return {
      decision: 'reject',
      reason: `lastName "${lastName}" not found in committee name`,
      committeeName,
    };
  }

  // Last name IS in committee name — check for signal word
  if (hasSignalWord(committeeName)) {
    return {
      decision: 'confirm',
      reason: `lastName "${lastName}" in committee name with signal word`,
      committeeName,
    };
  }

  return {
    decision: 'ambiguous',
    reason: `lastName "${lastName}" in committee name but no signal word found`,
    committeeName,
  };
}

// ─── Main flow ────────────────────────────────────────────────────────────────

async function runMain(): Promise<void> {
  const startMs = Date.now();
  const ts = nowTimestamp();

  // Build output paths next to the script file
  const scriptsDir = path.dirname(path.resolve(process.argv[1]));
  const auditPath = path.join(scriptsDir, `indiana-confirm-${ts}.csv`);
  const ambigPath = path.join(scriptsDir, `indiana-ambiguous-${ts}.csv`);

  console.log('[confirm-indiana] Mode: ' + (isDryRun ? 'DRY-RUN (no DB updates, no ingest)' : 'LIVE'));
  console.log('[confirm-indiana] Fetching needs_research rows from DB...');

  const rows = await fetchNeedsResearchRows();
  console.log(`[confirm-indiana] Found ${rows.length} needs_research rows.`);

  if (rows.length === 0) {
    console.log('[confirm-indiana] Nothing to do.');
    return;
  }

  // Open CSV write streams
  const auditStream = fs.createWriteStream(auditPath, { encoding: 'utf8' });
  const ambigStream = fs.createWriteStream(ambigPath, { encoding: 'utf8' });

  auditStream.write(CSV_HEADERS.join(',') + '\n');
  ambigStream.write(CSV_HEADERS.join(',') + '\n');

  const counts = { confirmed: 0, rejected: 0, ambiguous: 0 };

  for (const row of rows) {
    const { decision, reason, committeeName } = classifyRow(row);

    counts[decision === 'confirm' ? 'confirmed' : decision === 'reject' ? 'rejected' : 'ambiguous']++;

    // Write audit row (all decisions)
    const auditLine = csvRow([
      row.full_name,
      row.office_title,
      committeeName,
      row.external_id,
      decision,
      reason,
    ]) + '\n';
    auditStream.write(auditLine);

    // Write ambiguous row (blank decision for operator)
    if (decision === 'ambiguous') {
      const ambigLine = csvRow([
        row.full_name,
        row.office_title,
        committeeName,
        row.external_id,
        '', // blank — operator fills in 'confirm' or 'reject'
        reason,
      ]) + '\n';
      ambigStream.write(ambigLine);
    }

    // Update DB (skip if dry-run)
    if (!isDryRun) {
      if (decision === 'confirm') {
        await updateResearchStatus(row.source_id, 'confirmed');
      } else if (decision === 'reject') {
        await updateResearchStatus(row.source_id, 'not_applicable');
      }
      // ambiguous: leave as needs_research
    }
  }

  // Await stream close to ensure all data is flushed before process.exit()
  await new Promise<void>((resolve, reject) => {
    auditStream.end((err?: Error | null) => (err ? reject(err) : resolve()));
  });
  await new Promise<void>((resolve, reject) => {
    ambigStream.end((err?: Error | null) => (err ? reject(err) : resolve()));
  });

  // Trigger ingest for all confirmed Indiana sources (skip if dry-run)
  // CRITICAL: Use DYNAMIC import inside try/catch — do NOT use a static top-level import.
  // A static import will crash the entire script at startup if campaignFinanceScheduler.js
  // is unresolvable (Phase 8.1 not yet complete), losing all DB confirmations already written.
  if (!isDryRun) {
    try {
      console.log('\n[confirm-indiana] Triggering runAdapterForAll("indiana")...');
      const { runAdapterForAll } = await import('../src/lib/campaignFinanceScheduler.js');
      await runAdapterForAll('indiana');
      console.log('[confirm-indiana] Ingest complete.');
    } catch (err) {
      console.warn(
        '[confirm-indiana] Ingest trigger failed (Phase 8.1 adapter may not exist yet):',
        (err as Error).message
      );
      console.warn('[confirm-indiana] Sources are confirmed — ingest can be triggered manually later.');
    }
  }

  const durationMs = Date.now() - startMs;

  console.log('\n=== CONFIRMATION SUMMARY ===');
  if (isDryRun) {
    console.log('(DRY-RUN — no DB updates, no ingest triggered)');
  }
  console.log(`Total needs_research rows:  ${rows.length}`);
  console.log(`Auto-confirmed:             ${counts.confirmed}`);
  console.log(`Auto-rejected:              ${counts.rejected}`);
  console.log(`Ambiguous (human review):   ${counts.ambiguous}`);
  console.log('');
  console.log(`Audit log:     ${auditPath}`);
  if (counts.ambiguous > 0) {
    console.log(`Ambiguous CSV: ${ambigPath}`);
  } else {
    console.log('Ambiguous CSV: (empty — no ambiguous rows)');
    try {
      fs.unlinkSync(ambigPath);
    } catch {
      /* ignore if already gone */
    }
  }
  console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── Ambiguous re-run mode ───────────────────────────────────────────────────

async function runAmbiguous(filePath: string): Promise<void> {
  const startMs = Date.now();

  console.log(`[confirm-indiana] Ambiguous re-run mode: reading ${filePath}`);
  const content = fs.readFileSync(filePath, 'utf8');

  interface AmbigCsvRow {
    politician_name: string;
    office_title: string;
    committee_name: string;
    external_id: string;
    decision: string;
    reason: string;
  }

  const csvRows = parseCsv(content, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  }) as AmbigCsvRow[];

  console.log(`[confirm-indiana] Parsed ${csvRows.length} rows from ambiguous CSV.`);

  const counts = { confirmed: 0, rejected: 0, skipped: 0 };

  for (const row of csvRows) {
    const externalId = row.external_id?.trim();
    const decision = row.decision?.trim().toLowerCase();

    if (!externalId) {
      counts.skipped++;
      continue;
    }

    if (decision !== 'confirm' && decision !== 'reject') {
      counts.skipped++;
      continue;
    }

    // Look up source row by external_id
    const sourceRes = await pool.query<{ id: string }>(
      `SELECT id FROM transparent_motivations.politician_sources
       WHERE source_system = 'indiana'
         AND external_id = $1
         AND research_status = 'needs_research'
       LIMIT 1`,
      [externalId]
    );

    if (sourceRes.rows.length === 0) {
      console.warn(`[confirm-indiana] No needs_research row found for external_id=${externalId} — skipping`);
      counts.skipped++;
      continue;
    }

    const sourceId = sourceRes.rows[0].id;
    const status = decision === 'confirm' ? 'confirmed' : 'not_applicable';

    await updateResearchStatus(sourceId, status);
    counts[decision === 'confirm' ? 'confirmed' : 'rejected']++;
    console.log(`  [${decision.toUpperCase()}] external_id=${externalId} → ${status}`);
  }

  // Trigger ingest after all DB updates
  // CRITICAL: Dynamic import to avoid crash if Phase 8.1 adapter not yet built
  try {
    console.log('\n[confirm-indiana] Triggering runAdapterForAll("indiana")...');
    const { runAdapterForAll } = await import('../src/lib/campaignFinanceScheduler.js');
    await runAdapterForAll('indiana');
    console.log('[confirm-indiana] Ingest complete.');
  } catch (err) {
    console.warn(
      '[confirm-indiana] Ingest trigger failed (Phase 8.1 adapter may not exist yet):',
      (err as Error).message
    );
    console.warn('[confirm-indiana] Sources are confirmed — ingest can be triggered manually later.');
  }

  const durationMs = Date.now() - startMs;

  console.log('\n=== AMBIGUOUS RE-RUN SUMMARY ===');
  console.log(`Confirmed:  ${counts.confirmed}`);
  console.log(`Rejected:   ${counts.rejected}`);
  console.log(`Skipped:    ${counts.skipped}`);
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
  console.error('[confirm-indiana] Fatal error:', err);
  process.exit(1);
});
