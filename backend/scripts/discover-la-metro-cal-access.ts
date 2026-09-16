/**
 * discover-la-metro-cal-access.ts — Find Cal-Access filer IDs for all CA city council
 * politicians currently missing confirmed sources.
 *
 * Phase 1 of 3: Discovery only — no DB writes, no ZIP download, runs in seconds.
 *
 * What it does:
 *   1. Queries all CA city council politicians with 0 confirmed sources (via governments table)
 *   2. Loads all cal_access needs_research committee names from politician_sources
 *   3. For each politician, searches committee names using first + last name (requireAllTerms)
 *   4. Writes results to discover-la-metro-TIMESTAMP.csv for operator review
 *
 * Matching logic:
 *   - Normalizes both politician name and committee name (NFD unaccent, lowercase, strip punctuation)
 *   - requireAllTerms = true for ALL politicians (first + last must both appear) — prevents
 *     false positives on common surnames (Garcia, Chen, Lopez, Martinez, etc.)
 *   - Multiple matches = multiple filer IDs (different election cycles) — all listed
 *
 * Output CSV columns:
 *   politician_id, full_name, city, office, match_count, filer_ids, committee_names, status
 *
 * Usage:
 *   npx tsx scripts/discover-la-metro-cal-access.ts
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
  // Handle "Dr. Julia Ruedas", "James T. Butts Jr.", etc.
  const cleaned = fullName
    .replace(/^(Dr\.|Mr\.|Ms\.|Mrs\.)\s+/i, '')
    .replace(/\s+(Jr\.|Sr\.|II|III|IV)$/i, '')
    .trim();

  const parts = cleaned.split(/\s+/).filter(Boolean);
  if (parts.length < 2) return null;

  const first = parts[0];
  // Use last word as last name (handles middle initials like "James T. Butts")
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
  city: string;
  office: string;
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

async function fetchTargetPoliticians(): Promise<TargetPolitician[]> {
  const res = await pool.query<{
    id: string;
    full_name: string;
    city: string;
    office: string;
  }>(`
    SELECT DISTINCT
      p.id,
      p.full_name,
      COALESCE(g.city, regexp_replace(g.name, '^City of (.+), California.*$', '\\1')) AS city,
      o.title AS office
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN (
      SELECT essentials_politician_id, COUNT(*) AS cnt
      FROM transparent_motivations.politician_sources
      WHERE research_status = 'confirmed'
      GROUP BY essentials_politician_id
    ) confirmed ON confirmed.essentials_politician_id = p.id
    WHERE g.state = 'CA'
      AND c.name = 'City Council'
      AND (confirmed.cnt IS NULL OR confirmed.cnt = 0)
    ORDER BY city, p.full_name
  `);
  return res.rows;
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
  const header = 'politician_id,full_name,city,office,match_count,filer_ids,committee_names,status';
  const rows = results.map(r => {
    const filerIds = r.matches.map(m => m.filer_id).join(' | ');
    const committeeNames = r.matches.map(m => m.committee_name).join(' | ');
    return [
      r.politician.id,
      escapeCsv(r.politician.full_name),
      escapeCsv(r.politician.city),
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

  console.log('[discover-la-metro-cal-access] Fetching target politicians...');
  const politicians = await fetchTargetPoliticians();
  console.log(`  Found ${politicians.length} CA city council politicians with 0 confirmed sources`);

  console.log('[discover-la-metro-cal-access] Loading Cal-Access needs_research committee names...');
  const committees = await fetchCalAccessCommittees();
  // Deduplicate by filer_id — some filer_ids appear multiple times
  const uniqueCommittees = Object.values(
    Object.fromEntries(committees.map(c => [c.filer_id, c]))
  ) as CommitteeRow[];
  console.log(`  Loaded ${uniqueCommittees.length} unique Cal-Access committee filer IDs`);

  console.log('[discover-la-metro-cal-access] Matching politicians to committees...');
  const results: MatchResult[] = [];

  for (const politician of politicians) {
    const result = matchPolitician(politician, uniqueCommittees);
    results.push(result);
  }

  // Print summary by city
  const byCityCity = new Map<string, MatchResult[]>();
  for (const r of results) {
    const city = r.politician.city;
    if (!byCityCity.has(city)) byCityCity.set(city, []);
    byCityCity.get(city)!.push(r);
  }

  const matched = results.filter(r => r.status === 'matched');
  const noMatch = results.filter(r => r.status === 'no_match');
  const ambiguous = results.filter(r => r.status === 'ambiguous_name');

  console.log('\n=== DISCOVERY RESULTS BY CITY ===\n');
  const colW = [22, 26, 8, 8];
  const header = '  ' +
    'CITY'.padEnd(colW[0]) + '| ' +
    'POLITICIAN'.padEnd(colW[1]) + '| ' +
    'MATCHES'.padEnd(colW[2]) + '| STATUS';
  console.log(header);
  console.log('-'.repeat(header.length));

  for (const [city, cityResults] of [...byCityCity.entries()].sort()) {
    for (const r of cityResults) {
      const matchStr = r.matches.length > 0
        ? r.matches.map(m => `${m.filer_id}`).join(', ')
        : '-';
      console.log(
        '  ' +
        city.padEnd(colW[0]) + '| ' +
        r.politician.full_name.padEnd(colW[1]) + '| ' +
        String(r.matches.length).padEnd(colW[2]) + '| ' +
        r.status +
        (r.status === 'matched' ? ` [${matchStr}]` : '')
      );
    }
  }

  console.log('-'.repeat(header.length));
  console.log(`\nSummary: ${matched.length} matched, ${noMatch.length} no_match, ${ambiguous.length} ambiguous_name`);
  console.log(`Total filer IDs to seed: ${matched.reduce((n, r) => n + r.matches.length, 0)}`);

  // Write CSV
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputPath = path.join(
    process.cwd(),
    `scripts/discover-la-metro-${timestamp}.csv`
  );
  writeResults(results, outputPath);
  console.log(`\nResults written to: ${outputPath}`);

  const durationMs = Date.now() - startMs;
  console.log(`[discover-la-metro-cal-access] Completed in ${(durationMs / 1000).toFixed(1)}s`);
}

main()
  .then(async () => { await pool.end(); process.exit(0); })
  .catch(async err => {
    console.error('[discover-la-metro-cal-access] Fatal error:', err);
    await pool.end();
    process.exit(1);
  });
