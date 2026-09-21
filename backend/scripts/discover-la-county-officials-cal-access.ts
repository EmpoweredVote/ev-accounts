/**
 * discover-la-county-officials-cal-access.ts — Find Cal-Access filer IDs for the 8 LA County
 * officeholders (5 Supervisors, DA, Sheriff, Assessor).
 *
 * Phase 1 of 3: Discovery only — no DB writes, no ZIP download, runs in seconds.
 *
 * What it does:
 *   1. Hard-coded TARGET_POLITICIANS array: resolves each official's essentials.politicians.id
 *      by full_name lookup (case-insensitive exact match, then ILIKE first/last fallback).
 *   2. Loads all cal_access needs_research committee names from politician_sources.
 *   3. For each official, searches committee names using first + last name (requireAllTerms).
 *   4. Writes results to discover-la-county-officials-<TIMESTAMP>.csv for operator review.
 *
 * Matching logic:
 *   - Normalizes both politician name and committee name (NFD unaccent, lowercase, strip punctuation)
 *   - requireAllTerms = true: first AND last must both appear as whole words — prevents false
 *     positives on common surnames.
 *   - Multiple matches = multiple filer IDs (different election cycles) — all listed.
 *   - Middle initials in politician names are stripped before matching (only first + last used).
 *
 * Output CSV columns:
 *   politician_id, full_name, office, match_count, filer_ids, committee_names, status
 *
 * Usage:
 *   npx tsx scripts/discover-la-county-officials-cal-access.ts
 */

import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

// ─── Hard-coded target list ───────────────────────────────────────────────────

// Each entry: the full_name as it should appear in essentials.politicians, plus office context.
// Optional secondarySearch: if the primary needs_research pass returns no matches, a secondary
// last-name+role search is performed across ALL research_status values (including confirmed).
// Used for Robert Luna whose LUNA FOR SHERIFF committees were already confirmed before this script ran.
// If the script can't resolve a name, it prints a fatal error and exits non-zero.
const TARGET_DEFINITIONS: Array<{
  full_name: string;
  office: string;
  secondarySearch?: { lastName: string; roleKeyword: string };
}> = [
  { full_name: 'Hilda L. Solis',    office: 'Supervisor District 1' },
  { full_name: 'Holly J. Mitchell', office: 'Supervisor District 2' },
  { full_name: 'Lindsey P. Horvath',office: 'Supervisor District 3' },
  { full_name: 'Janice Hahn',       office: 'Supervisor District 4' },
  { full_name: 'Kathryn Barger',    office: 'Supervisor District 5' },
  { full_name: 'Nathan Hochman',    office: 'District Attorney' },
  {
    full_name: 'Robert Luna',
    office: 'Sheriff',
    // Primary pass matches only needs_research rows by first+last name — misses confirmed rows.
    // Secondary pass: query ALL rows for "LUNA" + "SHERIFF" to recover confirmed sheriff committees.
    secondarySearch: { lastName: 'luna', roleKeyword: 'sheriff' },
  },
  { full_name: 'Jeff Prang',        office: 'Assessor' },
];

// ─── Normalization ────────────────────────────────────────────────────────────

function normalize(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '') // strip accent marks
    .toLowerCase()
    .replace(/[.,/#!$%^&*;:{}=\-_`~()]/g, ' ') // punctuation → space
    .replace(/\s+/g, ' ')
    .trim();
}

function extractNameParts(fullName: string): { first: string; last: string } | null {
  // Handle "Dr. Julia Ruedas", "James T. Butts Jr.", "Hilda L. Solis", etc.
  const cleaned = fullName
    .replace(/^(Dr\.|Mr\.|Ms\.|Mrs\.)\s+/i, '')
    .replace(/\s+(Jr\.|Sr\.|II|III|IV)$/i, '')
    .trim();

  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length < 2) return null;

  const first = parts[0];
  // Use last word as last name (handles middle initials like "Hilda L. Solis")
  const last = parts[parts.length - 1];

  return {
    first: normalize(first),
    last: normalize(last),
  };
}

// ─── Types ────────────────────────────────────────────────────────────────────

interface TargetPolitician {
  id: string;
  full_name: string;
  office: string;
  secondarySearch?: { lastName: string; roleKeyword: string };
}

interface CommitteeRow {
  filer_id: string;
  committee_name: string;
  normalized: string;
}

interface MatchResult {
  politician: TargetPolitician;
  matches: Array<{ filer_id: string; committee_name: string }>;
  status: 'matched' | 'no_match' | 'ambiguous_name';
}

// ─── DB queries ───────────────────────────────────────────────────────────────

/**
 * Resolve a single official's essentials.politicians.id by name.
 * Tries exact LOWER match first, then ILIKE first+last fallback.
 * Returns null and logs an error if not found; returns null and logs if multiple matches.
 */
async function resolvePoliticianId(
  fullName: string
): Promise<{ id: string; full_name: string } | null> {
  const parts = extractNameParts(fullName);
  const firstName = parts ? '%' + parts.first + '%' : '%';
  const lastName = parts ? '%' + parts.last + '%' : '%';

  const res = await pool.query<{ id: string; full_name: string }>(
    `SELECT id, full_name FROM essentials.politicians
     WHERE LOWER(full_name) = LOWER($1)
        OR (full_name ILIKE $2 AND full_name ILIKE $3
            -- Exclude Cal-Access committee records (all-caps) by checking for mixed case:
            -- a real politician name has at least one lowercase letter
            AND full_name ~ '[a-z]')
     LIMIT 5`,
    [fullName, firstName, lastName]
  );

  if (res.rows.length === 0) {
    console.error(`  ERROR: politician not found: "${fullName}"`);
    return null;
  }

  if (res.rows.length > 1) {
    // Check if any row is an exact case-insensitive match — prefer it
    const exact = res.rows.find(r => r.full_name.toLowerCase() === fullName.toLowerCase());
    if (exact) return exact;

    console.error(`  ERROR: multiple matches for "${fullName}" — disambiguation needed:`);
    for (const row of res.rows) {
      console.error(`    id=${row.id}  full_name="${row.full_name}"`);
    }
    console.error(`  Fix: update TARGET_DEFINITIONS to use the exact full_name shown above.`);
    return null;
  }

  return res.rows[0];
}

async function fetchCalAccessCommittees(): Promise<CommitteeRow[]> {
  const res = await pool.query<{ filer_id: string; committee_name: string }>(`
    SELECT ps.external_id AS filer_id, p.full_name AS committee_name
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'cal_access'
      AND ps.research_status = 'needs_research'
  `);
  return res.rows.map(r => ({
    filer_id: r.filer_id,
    committee_name: r.committee_name,
    normalized: normalize(r.committee_name),
  }));
}

/**
 * Secondary pass: fetch Cal-Access rows (any research_status) whose notes->committee_name
 * contains a given last name AND a role keyword. Used to recover officials like Robert Luna
 * whose SHERIFF committees were already confirmed and thus excluded from the primary pass.
 *
 * Returns rows as CommitteeRow[] using the notes->'committee_name' field (the actual filing name).
 */
async function fetchCalAccessByLastNameAndRole(
  lastName: string,
  roleKeyword: string,
  politicianFullName: string
): Promise<CommitteeRow[]> {
  const res = await pool.query<{ filer_id: string; committee_name: string }>(`
    SELECT DISTINCT ps.external_id AS filer_id,
           ps.notes::json->>'committee_name' AS committee_name
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    WHERE ps.source_system = 'cal_access'
      AND LOWER(p.full_name) = LOWER($1)
      AND LOWER(ps.notes::json->>'committee_name') LIKE $2
      AND LOWER(ps.notes::json->>'committee_name') LIKE $3
  `, [politicianFullName, `%${lastName.toLowerCase()}%`, `%${roleKeyword.toLowerCase()}%`]);

  return res.rows
    .filter(r => r.committee_name) // skip rows with null committee_name
    .map(r => ({
      filer_id: r.filer_id,
      committee_name: r.committee_name,
      normalized: normalize(r.committee_name),
    }));
}

// ─── Matching ─────────────────────────────────────────────────────────────────

function matchPolitician(
  politician: TargetPolitician,
  committees: CommitteeRow[]
): MatchResult {
  const nameParts = extractNameParts(politician.full_name);

  if (!nameParts) {
    return { politician, matches: [], status: 'ambiguous_name' };
  }

  const { first, last } = nameParts;

  // Skip very short or generic name parts that would cause false positives
  if (last.length < 3) {
    return { politician, matches: [], status: 'ambiguous_name' };
  }

  const seenFilerIds = new Set<string>();
  const matches: Array<{ filer_id: string; committee_name: string }> = [];

  for (const c of committees) {
    if (seenFilerIds.has(c.filer_id)) continue;

    const norm = c.normalized;
    // Both first and last name must appear as whole words
    const lastRegex = new RegExp(`\\b${last}\\b`);
    const firstRegex = new RegExp(`\\b${first}\\b`);

    if (lastRegex.test(norm) && firstRegex.test(norm)) {
      matches.push({ filer_id: c.filer_id, committee_name: c.committee_name });
      seenFilerIds.add(c.filer_id);
    }
  }

  return {
    politician,
    matches,
    status: matches.length > 0 ? 'matched' : 'no_match',
  };
}

// ─── CSV writer ───────────────────────────────────────────────────────────────

function escapeCsv(s: string): string {
  if (s.includes(',') || s.includes('"') || s.includes('\n')) {
    return `"${s.replace(/"/g, '""')}"`;
  }
  return s;
}

function writeResults(results: MatchResult[], outputPath: string): void {
  const header = 'politician_id,full_name,office,match_count,filer_ids,committee_names,status';
  const rows = results.map(r => {
    const filerIds = r.matches.map(m => m.filer_id).join(' | ');
    const committeeNames = r.matches.map(m => m.committee_name).join(' | ');
    return [
      r.politician.id,
      escapeCsv(r.politician.full_name),
      escapeCsv(r.politician.office),
      String(r.matches.length),
      escapeCsv(filerIds),
      escapeCsv(committeeNames),
      r.status,
    ].join(',');
  });

  fs.writeFileSync(outputPath, [header, ...rows].join('\n'), 'utf8');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const startMs = Date.now();

  console.log('[discover-la-county-officials-cal-access] Resolving politician IDs...');
  const resolvedPoliticians: TargetPolitician[] = [];
  let anyResolutionError = false;

  for (const def of TARGET_DEFINITIONS) {
    const row = await resolvePoliticianId(def.full_name);
    if (row === null) {
      anyResolutionError = true;
    } else {
      resolvedPoliticians.push({
        id: row.id,
        full_name: row.full_name,
        office: def.office,
        secondarySearch: def.secondarySearch,
      });
      console.log(`  Resolved: "${row.full_name}" -> id=${row.id}`);
    }
  }

  if (anyResolutionError) {
    console.error('\nFATAL: One or more politicians could not be resolved. Fix names in TARGET_DEFINITIONS and re-run.');
    await pool.end();
    process.exit(1);
  }

  console.log(`\n[discover-la-county-officials-cal-access] Loading Cal-Access needs_research committee names...`);
  const committees = await fetchCalAccessCommittees();
  // Deduplicate by filer_id — some filer_ids appear multiple times
  const uniqueCommittees = Object.values(
    Object.fromEntries(committees.map(c => [c.filer_id, c]))
  ) as CommitteeRow[];
  console.log(`  Loaded ${uniqueCommittees.length} unique Cal-Access committee filer IDs`);

  console.log('[discover-la-county-officials-cal-access] Matching officials to committees...');
  const results: MatchResult[] = [];

  for (const politician of resolvedPoliticians) {
    let result = matchPolitician(politician, uniqueCommittees);

    // Secondary pass: if primary failed AND the definition specifies a last-name+role search,
    // query ALL cal_access rows (including confirmed) for that politician filtered by role keyword.
    // This recovers officials like Robert Luna whose sheriff committees were already confirmed.
    if (result.status === 'no_match' && politician.secondarySearch) {
      const { lastName, roleKeyword } = politician.secondarySearch;
      console.log(`  [secondary pass] ${politician.full_name}: searching by last_name="${lastName}" + role="${roleKeyword}" across all statuses...`);
      const secondaryRows = await fetchCalAccessByLastNameAndRole(
        lastName,
        roleKeyword,
        politician.full_name
      );

      if (secondaryRows.length > 0) {
        console.log(`  [secondary pass] Found ${secondaryRows.length} committees for ${politician.full_name}:`);
        for (const r of secondaryRows) {
          console.log(`    [${r.filer_id}] ${r.committee_name}`);
        }
        result = {
          politician,
          matches: secondaryRows.map(r => ({ filer_id: r.filer_id, committee_name: r.committee_name })),
          status: 'matched',
        };
      } else {
        console.log(`  [secondary pass] No results for ${politician.full_name} — remains no_match`);
      }
    }

    results.push(result);
  }

  // Print results table
  const matched = results.filter(r => r.status === 'matched');
  const noMatch = results.filter(r => r.status === 'no_match');
  const ambiguous = results.filter(r => r.status === 'ambiguous_name');

  console.log('\n=== DISCOVERY RESULTS ===\n');
  const colW = [26, 22, 8, 8];
  const tableHeader =
    '  ' + 'OFFICIAL'.padEnd(colW[0]) + '| ' +
    'OFFICE'.padEnd(colW[1]) + '| ' +
    'MATCHES'.padEnd(colW[2]) + '| STATUS';
  console.log(tableHeader);
  console.log('-'.repeat(tableHeader.length));

  for (const r of results) {
    const matchStr = r.matches.length > 0
      ? r.matches.map(m => m.filer_id).join(', ')
      : '-';
    console.log(
      '  ' +
      r.politician.full_name.padEnd(colW[0]) + '| ' +
      r.politician.office.padEnd(colW[1]) + '| ' +
      String(r.matches.length).padEnd(colW[2]) + '| ' +
      r.status +
      (r.status === 'matched' ? ` [${matchStr}]` : '')
    );
  }

  console.log('-'.repeat(tableHeader.length));
  console.log(`\nSummary: ${matched.length} matched, ${noMatch.length} no_match, ${ambiguous.length} ambiguous_name`);
  console.log(`Total filer IDs to seed: ${matched.reduce((n, r) => n + r.matches.length, 0)}`);

  // Print matched committee names for operator review
  if (matched.length > 0) {
    console.log('\n=== MATCHED COMMITTEE NAMES (for operator review) ===\n');
    for (const r of matched) {
      console.log(`  ${r.politician.full_name} (${r.politician.office}):`);
      for (const m of r.matches) {
        console.log(`    [${m.filer_id}] ${m.committee_name}`);
      }
    }
  }

  // Write CSV
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputPath = path.join(
    process.cwd(),
    `scripts/discover-la-county-officials-${timestamp}.csv`
  );
  writeResults(results, outputPath);
  console.log(`\nResults written to: ${outputPath}`);

  const durationMs = Date.now() - startMs;
  console.log(`[discover-la-county-officials-cal-access] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[discover-la-county-officials-cal-access] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
