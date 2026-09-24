/**
 * parse-local-cfa.ts — Monroe County CFA-4 pre-primary report PDF importer.
 *
 * Purpose:
 *   Walks a folder of candidate subfolders, runs each CFA-4 PDF through the
 *   Vision OCR pipeline (pdfOcrPipeline.ts), and upserts contributions into
 *   transparent_motivations.contributions with source_system='IN_MONROE_COUNTY_LOCAL'.
 *
 *   This is the first caller of the reusable pdfOcrPipeline module. Future
 *   callers (Marion County, California Form 460, NY CF-02, etc.) only need to
 *   write a similar folder-walker and DB mapping — no OCR re-implementation.
 *
 * Idempotency contract:
 *   Re-running with the same input produces ZERO new rows (ON CONFLICT skips).
 *   source_transaction_id = SHA-256 of politicianId|date|amount|donorNormalized|page.
 *
 * Summary sheets:
 *   Every PDF's page 1 (the CFA-4 summary sheet) is also read, in dry-run too and for $0 reports, into
 *   local-cfa-summaries-<ts>.csv. Nothing from it is written to the DB here: review the CSV against the PDFs,
 *   then run scripts/cfa-summaries-to-migration.ts. Already-loaded candidates are skipped by default, so pass
 *   --include-already-loaded to get their summary sheets (contribution inserts are idempotent).
 *
 * Dry-run note:
 *   --dry-run skips DB writes ONLY — OCR still runs (to show you what would be inserted).
 *   Cost is ~$0.001/page × ~10 pages × ~7 new candidates ≈ $0.07 per dry-run.
 *
 * Usage:
 *   npx tsx scripts/parse-local-cfa.ts --folder "C:/path/to/reports"
 *   npx tsx scripts/parse-local-cfa.ts --folder "..." --candidate "Goodrich" --dry-run
 *   npx tsx scripts/parse-local-cfa.ts --folder "..." --candidate "Goodrich" --commit
 *   npx tsx scripts/parse-local-cfa.ts --folder "..." --commit    # all unloaded candidates
 *
 * Requires:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *   ANTHROPIC_API_KEY — Claude API key (in .env)
 *   pdftoppm — from poppler; install with: winget install poppler
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import * as crypto from 'crypto';
import { Pool } from 'pg';
import { normalizeDonorName } from '../src/lib/adapters/normalizeDonorName.js';
import { pdfToPageImages, extractContributionsFromImages, ContributionRow } from './lib/pdfOcrPipeline.js';
import { extractSummarySheet, summaryCsvRow, SUMMARY_CSV_COLUMNS } from './lib/cfaSummarySheet.js';

// =============================================================================
// CLI argument parsing
// =============================================================================

const args = process.argv.slice(2);

function getFlag(name: string): string | undefined {
  const idx = args.indexOf(name);
  if (idx === -1) return undefined;
  const val = args[idx + 1];
  if (!val || val.startsWith('--')) return undefined;
  return val;
}

function hasFlag(name: string): boolean {
  return args.includes(name);
}

const KNOWN_FLAGS = new Set([
  '--folder', '--candidate', '--dry-run', '--commit',
  '--skip-already-loaded', '--include-already-loaded',
  '--source-system', '--jurisdiction-hint', '--limit',
]);

// Print usage and exit if no args or --help
if (args.length === 0 || hasFlag('--help') || hasFlag('-h')) {
  console.error('Usage: npx tsx scripts/parse-local-cfa.ts --folder <path> [options]');
  console.error('');
  console.error('Options:');
  console.error('  --folder <path>            Path to folder with candidate subfolders (required)');
  console.error('  --candidate <name>         Limit to one candidate folder (case-insensitive substring)');
  console.error('  --dry-run                  Parse + OCR, report results; NO DB writes (default)');
  console.error('  --commit                   Actually insert contributions into DB');
  console.error('  --skip-already-loaded      Skip candidates with existing IN_MONROE_COUNTY_LOCAL data (default)');
  console.error('  --include-already-loaded   Process all candidates, even already-loaded ones');
  console.error('  --source-system <name>     Source system name (default: IN_MONROE_COUNTY_LOCAL)');
  console.error('  --jurisdiction-hint <text> Vision prompt hint (default: Indiana Monroe County CFA-4 form)');
  console.error('  --limit <N>                Process only first N candidate folders');
  console.error('');
  console.error('Examples:');
  console.error('  npx tsx scripts/parse-local-cfa.ts --folder "C:/Data/Reports 2026"');
  console.error('  npx tsx scripts/parse-local-cfa.ts --folder "..." --candidate "Goodrich"');
  console.error('  npx tsx scripts/parse-local-cfa.ts --folder "..." --candidate "Goodrich" --commit');
  console.error('  npx tsx scripts/parse-local-cfa.ts --folder "..." --commit');
  process.exit(1);
}

for (const arg of args) {
  if (arg.startsWith('--') && !KNOWN_FLAGS.has(arg)) {
    console.error(`ERROR: Unknown flag: ${arg}`);
    console.error('Run with --help to see available options.');
    process.exit(1);
  }
}

const folderPath = getFlag('--folder');
if (!folderPath) {
  console.error('ERROR: --folder is required.');
  console.error('Run with --help to see usage.');
  process.exit(1);
}

if (!fs.existsSync(folderPath)) {
  console.error(`ERROR: --folder does not exist: ${folderPath}`);
  process.exit(1);
}

const candidateFilter = getFlag('--candidate');
const isCommit = hasFlag('--commit');
const isDryRun = !isCommit || hasFlag('--dry-run');
const skipAlreadyLoaded = !hasFlag('--include-already-loaded');
const sourceSystem = getFlag('--source-system') ?? 'IN_MONROE_COUNTY_LOCAL';
const jurisdictionHint = getFlag('--jurisdiction-hint') ?? 'Indiana Monroe County CFA-4 form';
const limitStr = getFlag('--limit');
const limit = limitStr ? parseInt(limitStr, 10) : undefined;

// data_source for new contributions (lowercase, distinct from 'indiana' which is the state SoS source)
const DATA_SOURCE = 'in_monroe_county_local';

// Print resolved config
console.log('==========================================================');
console.log('parse-local-cfa.ts — Monroe County CFA-4 PDF Importer');
console.log('==========================================================');
console.log(`Folder:             ${folderPath}`);
console.log(`Candidate filter:   ${candidateFilter ?? '(all)'}`);
console.log(`Mode:               ${isCommit ? 'COMMIT' : 'DRY-RUN'}`);
console.log(`Skip already loaded: ${skipAlreadyLoaded}`);
console.log(`Source system:      ${sourceSystem}`);
console.log(`Jurisdiction hint:  ${jurisdictionHint}`);
console.log(`Limit:              ${limit ?? 'none'}`);
console.log(`Data source:        ${DATA_SOURCE}`);
console.log('');

// =============================================================================
// DB pool
// =============================================================================

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// =============================================================================
// Types
// =============================================================================

interface ReviewRow {
  folderName: string;
  candidateName: string;
  pdfFilename: string;
  pageNumber: number;
  scheduleType: string;
  donorName: string;
  amount: number;
  contributionDate: string;
  confidence: string;
  reasonForLowConfidence: string;
  recommendedAction: string;
}

interface SkipRow {
  folderName: string;
  candidateName: string;
  reason: string;
}

interface CandidateSummary {
  folderName: string;
  politicianName: string;
  contributionsFound: number;
  inserted: number;
  skipped: number;
  lowConfidence: number;
  costUsd: number;
}

// =============================================================================
// Name parsing (from import-indiana-sos-xlsx.ts pattern)
// =============================================================================

const SUFFIXES = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'jr.', 'sr.', '2nd', '3rd']);
const ORG_FOLDER_KEYWORDS = ['young democrats', 'democratic', 'republican', 'committee', 'pac', 'club', 'association', 'organization', 'party'];

/**
 * Manual overrides for folder names that can't be resolved by name parsing alone.
 * Key: exact folder name. Value: array of full name forms to try against the DB.
 * Use when: nickname ≠ legal name (Bob/Robert), compound last names (Olmes-Stevens),
 * or apostrophes in the folder name break parsing.
 */
const FOLDER_NAME_OVERRIDES: Record<string, string[]> = {
  "Nyquist, Bob":      ["Robert Nyquist", "Bob Nyquist", "Robert Earl Nyquist"],
  "Stevens, Jenny":    ["Jenny Stevens", "Jenny Olmes-Stevens", "Jenny Olmes Stevens"],
  "Marte' Ruben":      ["Ruben Marte", "Ruben D Marte"],
  "Martin-Lucas, Tree": ["Tressia Martin-Lucas", "Tree Martin-Lucas", "Tressia Martin Lucas"],
};

function titleCase(s: string): string {
  return s.toLowerCase().split(' ').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
}

interface ParsedName {
  firstName: string;
  lastName: string;
  fullName: string;
  aliases: string[]; // Additional name forms to try (e.g., nickname variants)
}

/**
 * Parses a candidate folder name (typically "Lastname, Firstname" or "Lastname, Firstname Middle")
 * into a normalized full name. Handles edge cases like:
 *   - "Smith III, William (Will) E" → "William Smith"
 *   - "Marte' Ruben" (no comma) → "Ruben Marte"
 *   - "Martin-Lucas, Tree" → "Tree Martin-Lucas"
 */
function parseFolderName(folderName: string): ParsedName | null {
  const lower = folderName.toLowerCase();

  // Detect org folders — skip these
  if (ORG_FOLDER_KEYWORDS.some(kw => lower.includes(kw))) {
    return null; // Caller checks for null → skip with reason='not_a_candidate'
  }

  let raw = folderName.trim();

  // Extract parenthetical nickname before stripping: "Hawk, Martha (Marty)" → nickname = "Marty"
  const nicknameMatch = raw.match(/\(([^)]+)\)/);
  const nickname = nicknameMatch ? nicknameMatch[1].trim() : null;

  // Strip parenthetical nicknames: "Smith, William (Will) E" → "Smith, William E"
  raw = raw.replace(/\s*\([^)]*\)\s*/g, ' ').trim();

  if (raw.includes(',')) {
    const commaIdx = raw.indexOf(',');
    const rawLast = raw.slice(0, commaIdx).trim();
    const rawFirst = raw.slice(commaIdx + 1).trim();

    // Strip suffixes from the last-name portion if present (e.g., "Smith III")
    const lastTokens = rawLast.split(/\s+/).filter(Boolean);
    const lastFiltered = lastTokens.filter(t => !SUFFIXES.has(t.toLowerCase()));
    const last = titleCase(lastFiltered.join(' '));

    // Take first token of first-name portion
    const firstTokens = rawFirst.split(/\s+/).filter(Boolean);
    const firstFiltered = firstTokens.filter(t => !SUFFIXES.has(t.toLowerCase().replace('.', '')));
    const first = firstFiltered.length > 0 ? titleCase(firstFiltered[0]) : '';

    const fullName = first ? `${first} ${last}` : last;
    // If there's a nickname, also try "Nickname Lastname" (e.g., "Marty Hawk")
    const aliases = nickname ? [`${titleCase(nickname)} ${last}`] : [];
    return { firstName: first, lastName: last, fullName, aliases };
  } else {
    // No comma — try "FIRST LAST" form (e.g., "Marte' Ruben" is actually "Ruben Marte'")
    // For the Marte' case specifically, the apostrophe is in the last name
    const tokens = raw.split(/\s+/).filter(Boolean);
    if (tokens.length === 0) return null;
    if (tokens.length === 1) {
      return { firstName: '', lastName: titleCase(tokens[0]), fullName: titleCase(tokens[0]), aliases: [] };
    }
    // Assume "LAST FIRST" ordering for single-comma-less names in this dataset
    const last = titleCase(tokens[0]);
    const first = titleCase(tokens.slice(1).join(' '));
    const fullName = `${first} ${last}`;
    return { firstName: first, lastName: last, fullName, aliases: [] };
  }
}

// =============================================================================
// CSV helpers
// =============================================================================

function escapeCsvCell(value: string | number | null | undefined): string {
  const s = String(value ?? '');
  if (s.includes(',') || s.includes('"') || s.includes('\n') || s.includes('\r')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

// =============================================================================
// DB helpers
// =============================================================================

/**
 * Looks up a politician by full name (normalized). Tries multiple name forms
 * to handle the folder-name → full_name mapping ambiguity.
 * Returns null if 0 or 2+ matches.
 */
async function resolvePoliticianId(
  namesToTry: string[]
): Promise<{ id: string; fullName: string } | null | 'ambiguous'> {
  const normalizedForms = namesToTry.map(n => normalizeDonorName(n));
  const uniqueForms = [...new Set(normalizedForms)];

  // Load all active politicians' normalized names (we compare in JS to use normalizeDonorName)
  const res = await pool.query<{ id: string; full_name: string }>(
    `SELECT id, full_name
     FROM essentials.politicians
     WHERE is_active = true
       AND full_name IS NOT NULL
       AND (${uniqueForms.map((_, i) => `LOWER(full_name) ILIKE $${i + 1}`).join(' OR ')})
     LIMIT 10`,
    uniqueForms.map(f => `%${f.split(' ').filter(Boolean).join('%')}%`)
  );

  // JS-side normalization match
  const matches = res.rows.filter(r => {
    const dbNorm = normalizeDonorName(r.full_name);
    return uniqueForms.some(f => dbNorm === f || dbNorm.includes(f) || f.includes(dbNorm));
  });

  // Deduplicate by id
  const seen = new Set<string>();
  const unique = matches.filter(r => { if (seen.has(r.id)) return false; seen.add(r.id); return true; });

  if (unique.length === 0) return null;
  if (unique.length > 1) return 'ambiguous';
  return { id: unique[0].id, fullName: unique[0].full_name };
}

/**
 * Politician lookup with three-tier matching:
 * 1. Exact normalizeDonorName equality ("rita barrow" === "rita barrow")
 * 2. First + last name match ignoring middle initials ("rita barrow" matches "rita m barrow")
 * 3. DB-side ILIKE fuzzy fallback via resolvePoliticianId
 */
async function resolvePoliticianIdExact(
  namesToTry: string[]
): Promise<{ id: string; fullName: string } | null | 'ambiguous'> {
  const res = await pool.query<{ id: string; full_name: string; first_name: string; last_name: string }>(
    `SELECT id, full_name, first_name, last_name FROM essentials.politicians WHERE is_active = true AND full_name IS NOT NULL`
  );

  const normalizedForms = namesToTry.map(n => normalizeDonorName(n));

  // Tier 1: exact normalized match
  let matches = res.rows.filter(r => {
    const dbNorm = normalizeDonorName(r.full_name);
    return normalizedForms.some(f => f === dbNorm);
  });

  // Tier 2: first + last match ignoring middle initials (handles "Rita Barrow" → "Rita M Barrow")
  if (matches.length === 0) {
    matches = res.rows.filter(r => {
      const dbFirst = normalizeDonorName(r.first_name ?? '');
      const dbLast = normalizeDonorName(r.last_name ?? '');
      return normalizedForms.some(f => {
        const parts = f.split(' ').filter(Boolean);
        if (parts.length < 2) return false;
        const tryFirst = parts[0];
        const tryLast = parts[parts.length - 1];
        return tryFirst === dbFirst && tryLast === dbLast;
      });
    });
  }

  const seen = new Set<string>();
  const unique = matches.filter(r => { if (seen.has(r.id)) return false; seen.add(r.id); return true; });

  if (unique.length === 0) return resolvePoliticianId(namesToTry); // Tier 3: fuzzy ILIKE
  if (unique.length > 1) return 'ambiguous';
  return { id: unique[0].id, fullName: unique[0].full_name };
}

/**
 * Returns true if this politician already has IN_MONROE_COUNTY_LOCAL contributions.
 */
async function hasExistingContributions(politicianId: string): Promise<boolean> {
  const res = await pool.query<{ n: string }>(
    `SELECT 1 AS n
     FROM transparent_motivations.contributions c
     JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
     WHERE ps.essentials_politician_id = $1
       AND ps.source_system = $2
     LIMIT 1`,
    [politicianId, sourceSystem]
  );
  return (res.rowCount ?? 0) > 0;
}

/**
 * Upserts a politician_sources row and returns its id.
 * The existing 14 Monroe candidates have NULL external_id — this sets it.
 */
async function upsertPoliticianSource(
  politicianId: string,
  externalId: string,
  pdfFilenames: string[]
): Promise<string> {
  const notes = JSON.stringify({
    ingest_method: 'claude_vision_ocr',
    pdf_filenames: pdfFilenames,
    ingested_at: new Date().toISOString(),
  });

  // Try to update existing row first (existing 14 candidates have NULL external_id)
  const updateRes = await pool.query<{ id: string }>(
    `UPDATE transparent_motivations.politician_sources
     SET external_id = $3, research_status = 'confirmed', notes = $4, updated_at = NOW()
     WHERE essentials_politician_id = $1 AND source_system = $2 AND external_id IS NULL
     RETURNING id`,
    [politicianId, sourceSystem, externalId, notes]
  );

  if ((updateRes.rowCount ?? 0) > 0) {
    return updateRes.rows[0].id;
  }

  // Upsert (handles both new rows and rows that already have external_id set)
  const upsertRes = await pool.query<{ id: string }>(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, $2, $3, 'confirmed', $4)
     ON CONFLICT (essentials_politician_id, source_system, external_id)
     DO UPDATE SET research_status = 'confirmed', notes = EXCLUDED.notes, updated_at = NOW()
     RETURNING id`,
    [politicianId, sourceSystem, externalId, notes]
  );

  return upsertRes.rows[0].id;
}

/**
 * Generates a stable source_transaction_id from contribution fields.
 * SHA-256 hex, truncated to 32 chars.
 */
function makeSourceTransactionId(
  politicianId: string,
  contributionDate: string,
  amount: number,
  donorNameNormalized: string,
  pageNumber: number
): string {
  const input = `${politicianId}|${contributionDate}|${amount.toFixed(2)}|${donorNameNormalized}|${pageNumber}`;
  return crypto.createHash('sha256').update(input).digest('hex').slice(0, 32);
}

/**
 * Batch-inserts contributions (50 at a time) and returns counts of inserted vs updated.
 */
async function insertContributions(
  politicianSourceId: string,
  politicianId: string,
  rows: ContributionRow[],
  pdfFilename: string
): Promise<{ inserted: number; updated: number }> {
  let inserted = 0;
  let updated = 0;

  const batchSize = 50;
  for (let start = 0; start < rows.length; start += batchSize) {
    const batch = rows.slice(start, start + batchSize);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (const row of batch) {
        // Validate date before inserting — skip OCR hallucinations like 2026-02-29
        const parsedDate = new Date(row.contributionDate);
        if (isNaN(parsedDate.getTime()) || parsedDate.getFullYear() < 2000 || parsedDate.getFullYear() > 2030) {
          console.warn(`    SKIP invalid date "${row.contributionDate}" for donor "${row.donorName}"`);
          continue;
        }
        // Verify day is valid for the given month (catches 2026-02-29, etc.)
        const [yyyy, mm, dd] = row.contributionDate.split('-').map(Number);
        const check = new Date(yyyy, mm - 1, dd);
        if (check.getFullYear() !== yyyy || check.getMonth() + 1 !== mm || check.getDate() !== dd) {
          console.warn(`    SKIP impossible date "${row.contributionDate}" for donor "${row.donorName}"`);
          continue;
        }

        const donorNorm = normalizeDonorName(row.donorName);
        const sourceTxId = makeSourceTransactionId(
          politicianId,
          row.contributionDate,
          row.amount,
          donorNorm,
          row.pageNumber
        );
        const rawRecord = JSON.stringify({
          ...row,
          pdf_filename: pdfFilename,
          ingest_method: 'claude_vision_ocr',
        });

        const confidenceLevel =
          row.confidence === 'high' ? 'HIGH' : row.confidence === 'medium' ? 'MEDIUM' : 'ESTIMATED';

        const res = await client.query<{ inserted: boolean }>(
          `INSERT INTO transparent_motivations.contributions
             (politician_source_id, donor_id, committee_id, amount, contribution_date,
              election_cycle, confidence_level, data_source, source_transaction_id,
              raw_record, donor_name_normalized)
           VALUES ($1, NULL, NULL, $2, $3::date,
                   '2026', $4, $5, $6,
                   $7::jsonb, $8)
           ON CONFLICT (data_source, source_transaction_id) DO UPDATE SET
             updated_at = NOW(),
             donor_name_normalized = EXCLUDED.donor_name_normalized
           RETURNING (xmax = 0) AS inserted`,
          [
            politicianSourceId,
            row.amount,
            row.contributionDate,
            confidenceLevel,
            DATA_SOURCE,
            sourceTxId,
            rawRecord,
            donorNorm,
          ]
        );

        if (res.rows[0]?.inserted) {
          inserted++;
        } else {
          updated++;
        }
      }
      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  return { inserted, updated };
}

// =============================================================================
// Main
// =============================================================================

async function main(): Promise<void> {
  const startMs = Date.now();
  const reviewRows: ReviewRow[] = [];
  const skipRows: SkipRow[] = [];
  const summaries: CandidateSummary[] = [];
  const summarySheetRows: string[][] = [];

  let totalInserted = 0;
  let totalSkippedFolders = 0;
  let totalLowConfidence = 0;
  let totalCostUsd = 0;
  let totalCandidatesProcessed = 0;

  // ─── Step 1: Enumerate candidate folders ─────────────────────────────────

  let candidateFolders = fs
    .readdirSync(folderPath, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name);

  if (candidateFilter) {
    candidateFolders = candidateFolders.filter(name =>
      name.toLowerCase().includes(candidateFilter.toLowerCase())
    );
    if (candidateFolders.length === 0) {
      console.error(`ERROR: No folders matching --candidate "${candidateFilter}" in ${folderPath}`);
      await pool.end();
      process.exit(1);
    }
    console.log(`Filtered to ${candidateFolders.length} folder(s) matching "${candidateFilter}"`);
  }

  if (limit && candidateFolders.length > limit) {
    candidateFolders = candidateFolders.slice(0, limit);
    console.log(`Limited to first ${limit} candidate folders`);
  }

  console.log(`Processing ${candidateFolders.length} candidate folder(s)...\n`);

  // ─── Step 2: Process each candidate ──────────────────────────────────────

  for (const folderName of candidateFolders) {
    const candidateFolder = path.join(folderPath, folderName);
    console.log(`─── ${folderName} ───`);

    // Step 2a: Parse folder name
    const parsed = parseFolderName(folderName);
    if (!parsed) {
      console.log(`  SKIP: Organization folder (not a candidate): ${folderName}`);
      skipRows.push({ folderName, candidateName: folderName, reason: 'not_a_candidate' });
      totalSkippedFolders++;
      continue;
    }

    // Step 2b: Resolve politician_id
    // Try multiple name forms: parsed full name, reversed (for no-comma folders), raw folder name
    // Check manual overrides first (handles nicknames, compound last names, apostrophes)
    const overrideNames = FOLDER_NAME_OVERRIDES[folderName];
    const namesToTry = overrideNames ?? [
      parsed.fullName,
      // Nickname aliases (e.g., "Marty Hawk" from "Hawk, Martha (Marty)")
      ...parsed.aliases,
      // For no-comma folders (e.g., "Marte' Ruben"), also try reversed order
      ...(folderName.includes(',') ? [] : [`${parsed.lastName} ${parsed.firstName}`.trim()]),
    ];

    let resolveResult = await resolvePoliticianIdExact(namesToTry);

    if (resolveResult === null) {
      console.log(`  SKIP: No politician match for "${folderName}" (tried: ${namesToTry.join(', ')})`);
      skipRows.push({
        folderName,
        candidateName: parsed.fullName,
        reason: 'no_politician_match',
      });
      reviewRows.push({
        folderName,
        candidateName: parsed.fullName,
        pdfFilename: '',
        pageNumber: 0,
        scheduleType: '',
        donorName: '',
        amount: 0,
        contributionDate: '',
        confidence: '',
        reasonForLowConfidence: '',
        recommendedAction: `No politician match found. Tried names: ${namesToTry.join(', ')}`,
      });
      totalSkippedFolders++;
      continue;
    }

    if (resolveResult === 'ambiguous') {
      console.log(`  SKIP: Ambiguous politician match for "${folderName}"`);
      skipRows.push({
        folderName,
        candidateName: parsed.fullName,
        reason: 'ambiguous_politician_match',
      });
      reviewRows.push({
        folderName,
        candidateName: parsed.fullName,
        pdfFilename: '',
        pageNumber: 0,
        scheduleType: '',
        donorName: '',
        amount: 0,
        contributionDate: '',
        confidence: '',
        reasonForLowConfidence: '',
        recommendedAction: 'Multiple politicians match this name — disambiguate manually',
      });
      totalSkippedFolders++;
      continue;
    }

    const politicianId = resolveResult.id;
    const politicianName = resolveResult.fullName;
    console.log(`  Matched: "${politicianName}" (${politicianId})`);

    // Step 2c: Skip-already-loaded check
    if (skipAlreadyLoaded) {
      const alreadyLoaded = await hasExistingContributions(politicianId);
      if (alreadyLoaded) {
        console.log(`  SKIP: Already has ${sourceSystem} contributions (use --include-already-loaded to re-process)`);
        skipRows.push({
          folderName,
          candidateName: politicianName,
          reason: 'already_loaded',
        });
        totalSkippedFolders++;
        continue;
      }
    }

    // Step 2d: Find PDFs
    const allFiles = fs.readdirSync(candidateFolder);
    const pdfFiles = allFiles.filter(f => f.toLowerCase().endsWith('.pdf'));
    if (pdfFiles.length === 0) {
      console.log(`  SKIP: No PDF files in folder`);
      skipRows.push({
        folderName,
        candidateName: politicianName,
        reason: 'no_pdf_in_folder',
      });
      totalSkippedFolders++;
      continue;
    }

    console.log(`  PDFs: ${pdfFiles.join(', ')}`);

    // Step 2e: OCR pipeline for each PDF
    const allContributions: ContributionRow[] = [];
    let pdfCostUsd = 0;

    for (const pdfFile of pdfFiles) {
      const pdfPath = path.join(candidateFolder, pdfFile);
      const tmpDir = path.join(os.tmpdir(), `cfa-ocr-${crypto.randomUUID()}`);
      fs.mkdirSync(tmpDir, { recursive: true });

      try {
        console.log(`  OCR: ${pdfFile}...`);
        const pagePaths = await pdfToPageImages(pdfPath, tmpDir);
        console.log(`    Pages: ${pagePaths.length}`);

        // Page 1 is the CFA-4 summary sheet: read its totals even when the report has no Schedule A rows.
        const summary = await extractSummarySheet(pagePaths[0], jurisdictionHint);
        pdfCostUsd += summary.costUsd;
        const ctx = { folder: folderName, pdf: pdfFile, politician_id: politicianId, politician_name: politicianName };
        if (summary.sheet) {
          summarySheetRows.push(summaryCsvRow(ctx, summary.sheet));
          const m = summary.sheet.money;
          console.log(`    Summary: ${summary.sheet.report_type} ${summary.sheet.period_start}..${summary.sheet.period_end} raised=${m.receipts_total ?? '—'} spent=${m.expenditures_total ?? '—'} cash_end=${m.cash_end ?? '—'}`);
        } else {
          // Keep the PDF visible in the CSV so a person reads it by hand; the generator refuses needs_review=yes.
          const blank = SUMMARY_CSV_COLUMNS.map(() => '');
          const at = (c: string) => SUMMARY_CSV_COLUMNS.indexOf(c);
          blank[at('folder')] = ctx.folder; blank[at('pdf')] = ctx.pdf;
          blank[at('politician_id')] = ctx.politician_id; blank[at('politician_name')] = ctx.politician_name;
          blank[at('needs_review')] = 'yes'; blank[at('review_reasons')] = summary.warning ?? 'extraction failed';
          summarySheetRows.push(blank);
          console.log(`    Summary: NOT READ — ${summary.warning}`);
        }

        const result = await extractContributionsFromImages(pagePaths, {
          candidateName: politicianName,
          jurisdictionHint,
        });

        pdfCostUsd += result.totalCostUsd;
        console.log(`    Extracted: ${result.contributions.length} rows | Cost: $${result.totalCostUsd.toFixed(4)}`);

        if (result.warnings.length > 0) {
          console.log(`    Warnings: ${result.warnings.length}`);
          result.warnings.slice(0, 3).forEach(w => console.log(`      ${w.slice(0, 120)}`));
          if (result.warnings.length > 3) {
            console.log(`      ... and ${result.warnings.length - 3} more`);
          }
        }

        // Split by confidence
        const highMedium = result.contributions.filter(c => c.confidence !== 'low');
        const low = result.contributions.filter(c => c.confidence === 'low');

        // Filter to schedule A only (not B/expenditures)
        const scheduleA = highMedium.filter(c =>
          c.scheduleType === 'A-1' || c.scheduleType === 'A-2' || c.scheduleType === 'A-4' || c.scheduleType === 'unknown'
        );

        allContributions.push(...scheduleA);

        // Low confidence → review CSV
        for (const row of low) {
          totalLowConfidence++;
          reviewRows.push({
            folderName,
            candidateName: politicianName,
            pdfFilename: pdfFile,
            pageNumber: row.pageNumber,
            scheduleType: row.scheduleType,
            donorName: row.donorName,
            amount: row.amount,
            contributionDate: row.contributionDate,
            confidence: row.confidence,
            reasonForLowConfidence: row.reasonForLowConfidence ?? '',
            recommendedAction: 'Review and manually insert if valid',
          });
        }

      } catch (err: any) {
        console.error(`  ERROR processing ${pdfFile}: ${err.message}`);
        reviewRows.push({
          folderName,
          candidateName: politicianName,
          pdfFilename: pdfFile,
          pageNumber: 0,
          scheduleType: '',
          donorName: '',
          amount: 0,
          contributionDate: '',
          confidence: '',
          reasonForLowConfidence: '',
          recommendedAction: `OCR failed: ${err.message.slice(0, 200)}`,
        });
      } finally {
        fs.rmSync(tmpDir, { recursive: true, force: true });
      }
    }

    totalCostUsd += pdfCostUsd;
    totalCandidatesProcessed++;

    // Step 2f: DB writes (commit mode only)
    let insertedCount = 0;
    let updatedCount = 0;

    if (isCommit && allContributions.length > 0) {
      const externalId = `monroe_county_${normalizeDonorName(politicianName).replace(/\s+/g, '_')}`;
      try {
        const sourceId = await upsertPoliticianSource(politicianId, externalId, pdfFiles);
        const counts = await insertContributions(sourceId, politicianId, allContributions, pdfFiles.join(', '));
        insertedCount = counts.inserted;
        updatedCount = counts.updated;
        totalInserted += insertedCount;
      } catch (err: any) {
        console.error(`  ERROR inserting contributions: ${err.message}`);
        reviewRows.push({
          folderName,
          candidateName: politicianName,
          pdfFilename: pdfFiles.join(', '),
          pageNumber: 0,
          scheduleType: '',
          donorName: '',
          amount: 0,
          contributionDate: '',
          confidence: '',
          reasonForLowConfidence: '',
          recommendedAction: `DB insert failed: ${err.message.slice(0, 200)}`,
        });
      }
    } else if (!isCommit && allContributions.length > 0) {
      console.log(`  [DRY-RUN] Would insert ${allContributions.length} contribution(s)`);
    }

    const skippedCount = totalLowConfidence; // approximate
    console.log(
      `  [${folderName}] politician=${politicianName} contributions_found=${allContributions.length} ` +
      `inserted=${insertedCount} updated=${updatedCount} low_confidence=${reviewRows.filter(r => r.folderName === folderName && r.confidence === 'low').length} ` +
      `cost_usd=$${pdfCostUsd.toFixed(4)}`
    );

    summaries.push({
      folderName,
      politicianName,
      contributionsFound: allContributions.length,
      inserted: insertedCount,
      skipped: updatedCount,
      lowConfidence: reviewRows.filter(r => r.folderName === folderName && r.confidence === 'low').length,
      costUsd: pdfCostUsd,
    });

    console.log('');
  }

  // ─── Step 3: Write review CSV ─────────────────────────────────────────────

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const csvFilename = `local-cfa-review-${timestamp}.csv`;

  // Resolve script dir (tsx doesn't set __dirname reliably on Windows)
  let scriptDir: string;
  try {
    const u = new URL(import.meta.url);
    const p = u.pathname.replace(/^\/([A-Z]:)/, '$1');
    scriptDir = path.dirname(p);
  } catch {
    scriptDir = process.cwd();
  }

  const csvPath = path.join(scriptDir, csvFilename);
  const csvHeader = 'folderName,candidateName,pdfFilename,pageNumber,scheduleType,donorName,amount,contributionDate,confidence,reasonForLowConfidence,recommendedAction';
  const csvLines = reviewRows.map(r => [
    escapeCsvCell(r.folderName),
    escapeCsvCell(r.candidateName),
    escapeCsvCell(r.pdfFilename),
    String(r.pageNumber),
    escapeCsvCell(r.scheduleType),
    escapeCsvCell(r.donorName),
    String(r.amount),
    escapeCsvCell(r.contributionDate),
    escapeCsvCell(r.confidence),
    escapeCsvCell(r.reasonForLowConfidence),
    escapeCsvCell(r.recommendedAction),
  ].join(','));
  fs.writeFileSync(csvPath, [csvHeader, ...csvLines].join('\n'), 'utf8');

  const summariesPath = path.join(scriptDir, `local-cfa-summaries-${timestamp}.csv`);
  fs.writeFileSync(
    summariesPath,
    [SUMMARY_CSV_COLUMNS.join(','), ...summarySheetRows.map((r) => r.map(escapeCsvCell).join(','))].join('\n') + '\n',
    'utf8'
  );

  // ─── Step 4: Final summary ────────────────────────────────────────────────

  const durationMs = Date.now() - startMs;

  console.log('==========================================================');
  console.log('FINAL SUMMARY');
  console.log('==========================================================');
  console.log(`Mode:                  ${isCommit ? 'COMMIT' : 'DRY-RUN'}`);
  console.log(`Candidates processed:  ${totalCandidatesProcessed}`);
  console.log(`Candidates skipped:    ${totalSkippedFolders}`);
  console.log(`Total inserted:        ${totalInserted}`);
  console.log(`Total low-confidence:  ${totalLowConfidence}`);
  console.log(`Total cost (USD):      $${totalCostUsd.toFixed(4)}`);
  console.log(`Review CSV:            ${csvPath}`);
  console.log(`Summaries CSV:         ${summariesPath} (${summarySheetRows.length} report(s); review, then cfa-summaries-to-migration.ts)`);
  console.log(`Duration:              ${(durationMs / 1000).toFixed(1)}s`);
  console.log('');

  if (summaries.length > 0) {
    console.log('Per-candidate breakdown:');
    for (const s of summaries) {
      console.log(`  ${s.folderName}: found=${s.contributionsFound} inserted=${s.inserted} low=${s.lowConfidence} cost=$${s.costUsd.toFixed(4)}`);
    }
    console.log('');
  }

  if (skipRows.length > 0) {
    console.log('Skipped folders:');
    for (const s of skipRows) {
      console.log(`  ${s.folderName}: ${s.reason}`);
    }
    console.log('');
  }

  await pool.end();
  process.exit(0);
}

main().catch(async (err) => {
  console.error('[parse-local-cfa] Fatal error:', err);
  try { await pool.end(); } catch { /* ignore */ }
  process.exit(1);
});
