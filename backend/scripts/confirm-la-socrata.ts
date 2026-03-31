/**
 * confirm-la-socrata.ts — classify 167 la_socrata needs_research rows and trigger ingest.
 *
 * Usage:
 *   npx tsx scripts/confirm-la-socrata.ts                    # live run: update DB + trigger ingest
 *   npx tsx scripts/confirm-la-socrata.ts --dry-run           # classify + write CSVs, no DB writes
 *   npx tsx scripts/confirm-la-socrata.ts --ambiguous <path>  # re-run: apply operator decisions from CSV
 *
 * Classification logic (from Phase 17 locked decisions):
 *   AUTO-CONFIRM:  normalize(lastName) in normalize(cmtNm)  AND  cmt_type === 'C'
 *   AUTO-REJECT:   normalize(lastName) NOT in normalize(cmtNm)  at all
 *   AMBIGUOUS:     everything else (last name present but cmt_type !== 'C')
 *
 * Guards:
 *   - Empty/null lastName -> ambiguous (prevents empty string matching every committee name)
 *   - cmt_id not found in Socrata map -> ambiguous with note
 *
 * DB status values:
 *   confirmed     -> research_status = 'confirmed'
 *   rejected      -> research_status = 'not_applicable'  (NOT 'rejected' — CHECK constraint violation)
 *   ambiguous     -> no update (leaves as 'needs_research' for operator)
 *
 * DO NOT trigger ingest via HTTP POST — Cloudflare blocks posts to accounts.empowered.vote.
 * Use runAdapterForAll('la_socrata') direct function call.
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { parse as parseCsv } from 'csv-parse/sync';
import { runAdapterForAll } from '../src/lib/campaignFinanceScheduler.js';

// ─── Env guard ────────────────────────────────────────────────────────────────

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

// ─── Arg parsing ─────────────────────────────────────────────────────────────

const isDryRun = process.argv.includes('--dry-run');
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
  external_id: string;   // cmt_id
  notes: string | null;
  full_name: string;
  politician_id: string;
  office_title: string | null;
}

interface SocrataCommitteeMeta {
  cmt_nm: string;
  cmt_type: string;
}

type Decision = 'confirm' | 'reject' | 'ambiguous';

interface ClassifiedRow extends NeedsResearchRow {
  decision: Decision;
  reason: string;
  cmt_nm: string;
  cmt_type: string;
}

// ─── Helpers (copied verbatim from relink-socrata-skipped.ts) ─────────────────

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

const CSV_HEADERS = ['politician_name', 'office_title', 'committee_name', 'committee_id', 'cmt_type', 'decision', 'reason'];

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
    WHERE ps.source_system = 'la_socrata'
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

// ─── Socrata fetch ────────────────────────────────────────────────────────────

async function fetchSocrataMeta(): Promise<Map<string, SocrataCommitteeMeta>> {
  const url =
    'https://data.lacity.org/resource/m6g2-gc6c.json' +
    '?$select=cmt_id,cmt_nm,cmt_type' +
    '&$group=cmt_id,cmt_nm,cmt_type' +
    '&$limit=10000';

  const headers: Record<string, string> = { Accept: 'application/json' };
  if (process.env.SOCRATA_APP_TOKEN) {
    headers['X-App-Token'] = process.env.SOCRATA_APP_TOKEN;
  } else {
    console.warn('[confirm-la-socrata] SOCRATA_APP_TOKEN not set — requests may be rate-limited');
  }

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Socrata API returned ${response.status}: ${await response.text()}`);
  }

  const data = (await response.json()) as Array<{ cmt_id: string; cmt_nm: string; cmt_type: string }>;

  const map = new Map<string, SocrataCommitteeMeta>();
  for (const row of data) {
    if (row.cmt_id) {
      map.set(row.cmt_id, { cmt_nm: row.cmt_nm ?? '', cmt_type: row.cmt_type ?? '' });
    }
  }
  return map;
}

// ─── Main flow ────────────────────────────────────────────────────────────────

async function runMain(): Promise<void> {
  const startMs = Date.now();
  const ts = nowTimestamp();

  // Build output paths (next to the script file, using process.argv[1] for cross-platform compat)
  const scriptsDir = path.dirname(path.resolve(process.argv[1]));
  const auditPath   = path.join(scriptsDir, `la-socrata-confirm-${ts}.csv`);
  const ambigPath   = path.join(scriptsDir, `la-socrata-ambiguous-${ts}.csv`);

  console.log('[confirm-la-socrata] Mode: ' + (isDryRun ? 'DRY-RUN (no DB updates, no ingest)' : 'LIVE'));
  console.log('[confirm-la-socrata] Fetching needs_research rows from DB...');

  const rows = await fetchNeedsResearchRows();
  console.log(`[confirm-la-socrata] Found ${rows.length} needs_research rows.`);

  if (rows.length === 0) {
    console.log('[confirm-la-socrata] Nothing to do.');
    return;
  }

  console.log('[confirm-la-socrata] Fetching committee metadata from Socrata (cmt_id, cmt_nm, cmt_type)...');
  const socrataMap = await fetchSocrataMeta();
  console.log(`[confirm-la-socrata] Loaded ${socrataMap.size} committee records from Socrata.`);

  // Open CSV write streams
  const auditStream = fs.createWriteStream(auditPath, { encoding: 'utf8' });
  const ambigStream = fs.createWriteStream(ambigPath, { encoding: 'utf8' });

  auditStream.write(CSV_HEADERS.join(',') + '\n');
  ambigStream.write(CSV_HEADERS.join(',') + '\n');

  const counts = { confirmed: 0, rejected: 0, ambiguous: 0 };

  for (const row of rows) {
    const cmtId = row.external_id;
    const meta  = socrataMap.get(cmtId);

    const cmtNm   = meta?.cmt_nm   ?? '';
    const cmtType = meta?.cmt_type ?? '';

    let decision: Decision;
    let reason: string;

    if (!meta) {
      // Guard: committee not found in Socrata
      decision = 'ambiguous';
      reason   = 'committee not found in Socrata';
    } else {
      const lastName          = extractLastName(row.full_name ?? '');
      const normalizedLast    = normalize(lastName);
      const normalizedCmtNm   = normalize(cmtNm);

      // Guard: empty lastName prevents false-positive substring match
      if (!normalizedLast) {
        decision = 'ambiguous';
        reason   = 'empty lastName extracted — cannot match';
      } else if (!normalizedCmtNm.includes(normalizedLast)) {
        // AUTO-REJECT: last name not in committee name
        decision = 'reject';
        reason   = `lastName "${lastName}" not found in committee name`;
      } else if (cmtType === 'C') {
        // AUTO-CONFIRM: last name in committee name AND cmt_type is Candidate
        decision = 'confirm';
        reason   = `lastName "${lastName}" in committee name, cmt_type=C (Candidate)`;
      } else {
        // AMBIGUOUS: last name present but cmt_type !== 'C'
        decision = 'ambiguous';
        reason   = `lastName "${lastName}" in committee name but cmt_type="${cmtType}" (not C)`;
      }
    }

    counts[decision === 'confirm' ? 'confirmed' : decision === 'reject' ? 'rejected' : 'ambiguous']++;

    // Write audit row (all decisions)
    const auditLine = csvRow([
      row.full_name,
      row.office_title,
      cmtNm,
      cmtId,
      cmtType,
      decision,
      reason,
    ]) + '\n';
    auditStream.write(auditLine);

    // Write ambiguous row (blank decision for operator)
    if (decision === 'ambiguous') {
      const ambigLine = csvRow([
        row.full_name,
        row.office_title,
        cmtNm,
        cmtId,
        cmtType,
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
    auditStream.end((err?: Error | null) => err ? reject(err) : resolve());
  });
  await new Promise<void>((resolve, reject) => {
    ambigStream.end((err?: Error | null) => err ? reject(err) : resolve());
  });

  // Trigger ingest for all confirmed la_socrata sources (skip if dry-run)
  if (!isDryRun) {
    console.log('\n[confirm-la-socrata] Triggering runAdapterForAll("la_socrata")...');
    await runAdapterForAll('la_socrata');
    console.log('[confirm-la-socrata] Ingest complete.');
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
    try { fs.unlinkSync(ambigPath); } catch { /* ignore if already gone */ }
  }
  console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);
}

// ─── Ambiguous re-run mode ───────────────────────────────────────────────────

async function runAmbiguous(filePath: string): Promise<void> {
  const startMs = Date.now();

  console.log(`[confirm-la-socrata] Ambiguous re-run mode: reading ${filePath}`);
  const content = fs.readFileSync(filePath, 'utf8');

  interface AmbigCsvRow {
    politician_name: string;
    office_title: string;
    committee_name: string;
    committee_id: string;
    cmt_type: string;
    decision: string;
    reason: string;
  }

  const csvRows = parseCsv(content, {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  }) as AmbigCsvRow[];

  console.log(`[confirm-la-socrata] Parsed ${csvRows.length} rows from ambiguous CSV.`);

  const counts = { confirmed: 0, rejected: 0, skipped: 0 };

  for (const row of csvRows) {
    const cmtId    = row.committee_id?.trim();
    const decision = row.decision?.trim().toLowerCase();

    if (!cmtId) {
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
       WHERE source_system = 'la_socrata'
         AND external_id = $1
         AND research_status = 'needs_research'
       LIMIT 1`,
      [cmtId]
    );

    if (sourceRes.rows.length === 0) {
      console.warn(`[confirm-la-socrata] No needs_research row found for cmt_id=${cmtId} — skipping`);
      counts.skipped++;
      continue;
    }

    const sourceId = sourceRes.rows[0].id;
    const status   = decision === 'confirm' ? 'confirmed' : 'not_applicable';

    await updateResearchStatus(sourceId, status);
    counts[decision === 'confirm' ? 'confirmed' : 'rejected']++;
    console.log(`  [${decision.toUpperCase()}] cmt_id=${cmtId} → ${status}`);
  }

  // Trigger ingest after all DB updates
  console.log('\n[confirm-la-socrata] Triggering runAdapterForAll("la_socrata")...');
  await runAdapterForAll('la_socrata');
  console.log('[confirm-la-socrata] Ingest complete.');

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
  console.error('[confirm-la-socrata] Fatal error:', err);
  process.exit(1);
});
