/**
 * relink-socrata-skipped.ts — link previously-skipped politicians to Socrata committees.
 *
 * Usage:
 *   npx tsx backend/scripts/relink-socrata-skipped.ts          # dry-run (no changes)
 *   npx tsx backend/scripts/relink-socrata-skipped.ts --execute # apply changes
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * Optional environment variable:
 *   SOCRATA_APP_TOKEN — Socrata SODA API app token (recommended to avoid rate limits)
 *
 * What it does:
 *   1. Fetches all distinct committees from the LA Socrata dataset (m6g2-gc6c).
 *   2. Finds active politicians with no la_socrata politician_sources row.
 *   3. Matches each politician by last name against committee names (normalized, accent-stripped).
 *   4. Inserts unambiguous matches as politician_sources with research_status='needs_research'.
 *      Ambiguous and unmatched cases are logged for manual review.
 *
 * IMPORTANT: research_status='needs_research' — operator must confirm before ingestion runs.
 */

import 'dotenv/config';
import { Pool } from 'pg';

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL is not set');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const isDryRun = !process.argv.includes('--execute');

interface SocrataCommittee {
  cmt_id: string;
  cmt_nm: string;
}

interface UnlinkedPolitician {
  id: string;
  full_name: string;
}

interface MatchResult {
  politician: UnlinkedPolitician;
  status: 'linked' | 'ambiguous' | 'unmatched';
  matches: SocrataCommittee[];
}

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

async function fetchSocrataCommittees(): Promise<SocrataCommittee[]> {
  const url =
    'https://data.lacity.org/resource/m6g2-gc6c.json?$select=cmt_id,cmt_nm&$group=cmt_id,cmt_nm&$limit=10000';

  const headers: Record<string, string> = {
    'Accept': 'application/json',
  };
  if (process.env.SOCRATA_APP_TOKEN) {
    headers['X-App-Token'] = process.env.SOCRATA_APP_TOKEN;
  } else {
    console.warn('[relink-socrata-skipped] SOCRATA_APP_TOKEN not set — requests may be rate-limited');
  }

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Socrata API returned ${response.status}: ${await response.text()}`);
  }

  const data = await response.json() as SocrataCommittee[];
  return data;
}

async function findUnlinkedPoliticians(): Promise<UnlinkedPolitician[]> {
  const result = await pool.query<UnlinkedPolitician>(`
    SELECT p.id, p.full_name
    FROM essentials.politicians p
    WHERE p.is_active = true
      AND NOT EXISTS (
        SELECT 1 FROM transparent_motivations.politician_sources ps
        WHERE ps.essentials_politician_id = p.id
          AND ps.source_system = 'la_socrata'
      )
    ORDER BY p.full_name;
  `);
  return result.rows;
}

async function insertPoliticianSource(
  politicianId: string,
  cmtId: string,
  cmtNm: string
): Promise<boolean> {
  const notes = JSON.stringify({ cmt_nm: cmtNm, linked_by: 'relink-socrata-skipped.ts' });
  const result = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'la_socrata', $2, 'needs_research', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [politicianId, cmtId, notes]
  );
  return (result.rowCount ?? 0) > 0;
}

async function main() {
  console.log(`[relink-socrata-skipped] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);

  const startMs = Date.now();

  const summary = {
    committeesTotal: 0,
    politiciansChecked: 0,
    linked: 0,
    ambiguous: 0,
    unmatched: 0,
    insertedNew: 0,
    skippedConflict: 0,
  };

  try {
    // Step 1: Fetch Socrata committees
    console.log('[relink-socrata-skipped] Fetching committees from Socrata dataset m6g2-gc6c...');
    const committees = await fetchSocrataCommittees();
    summary.committeesTotal = committees.length;
    console.log(`[relink-socrata-skipped] Fetched ${committees.length} committees.`);

    // Build normalized lookup (filter out entries with null/empty cmt_nm or cmt_id)
    const normalizedCommittees = committees
      .filter(c => c.cmt_id && c.cmt_nm)
      .map(c => ({
        ...c,
        normalized_nm: normalize(c.cmt_nm),
      }));

    // Step 2: Find politicians with no la_socrata source
    console.log('[relink-socrata-skipped] Finding politicians with no la_socrata source...');
    const unlinked = await findUnlinkedPoliticians();
    summary.politiciansChecked = unlinked.length;
    console.log(`[relink-socrata-skipped] ${unlinked.length} politician(s) checked.`);

    // Step 3: Match each politician to committees
    const matchResults: MatchResult[] = [];

    for (const politician of unlinked) {
      const lastName = extractLastName(politician.full_name || '');
      const normalizedLastName = normalize(lastName);

      const matches = normalizedCommittees.filter(c =>
        c.normalized_nm.includes(normalizedLastName)
      );

      let status: MatchResult['status'];
      if (matches.length === 1) {
        status = 'linked';
      } else if (matches.length === 0) {
        status = 'unmatched';
      } else {
        status = 'ambiguous';
      }

      matchResults.push({ politician, status, matches });
    }

    // Step 4: Print match table
    console.log('\n=== MATCH TABLE ===');
    for (const mr of matchResults) {
      const lastName = extractLastName(mr.politician.full_name || '');
      if (mr.status === 'linked') {
        const c = mr.matches[0];
        console.log(`  LINK    "${mr.politician.full_name}" (last="${lastName}") → cmt_id=${c.cmt_id}, cmt_nm="${c.cmt_nm}"`);
      } else if (mr.status === 'ambiguous') {
        const names = mr.matches.map(c => `"${c.cmt_nm}" (${c.cmt_id})`).join(', ');
        console.log(`  AMBIG   "${mr.politician.full_name}" (last="${lastName}") — ${mr.matches.length} matches: ${names}`);
      } else {
        console.log(`  NOMATCH "${mr.politician.full_name}" (last="${lastName}")`);
      }
    }
    console.log('');

    // Step 5: Apply or report
    for (const mr of matchResults) {
      if (mr.status === 'linked') {
        summary.linked++;
        if (!isDryRun) {
          const match = mr.matches[0];
          const inserted = await insertPoliticianSource(mr.politician.id, match.cmt_id, match.cmt_nm);
          if (inserted) {
            summary.insertedNew++;
            console.log(`  [INSERT] ${mr.politician.full_name} → ${match.cmt_id}`);
          } else {
            summary.skippedConflict++;
            console.log(`  [SKIP] ${mr.politician.full_name} already has la_socrata source (ON CONFLICT DO NOTHING)`);
          }
        }
      } else if (mr.status === 'ambiguous') {
        summary.ambiguous++;
      } else {
        summary.unmatched++;
      }
    }

    const durationMs = Date.now() - startMs;

    console.log('\n=== RELINK SUMMARY ===');
    if (isDryRun) {
      console.log('(DRY-RUN — no changes made)');
    }
    console.log(`Committees fetched:    ${summary.committeesTotal}`);
    console.log(`Politicians checked:   ${summary.politiciansChecked}`);
    console.log(`Linked (unambiguous):  ${summary.linked}`);
    console.log(`Ambiguous (manual):    ${summary.ambiguous}`);
    console.log(`Unmatched (no cmt):    ${summary.unmatched}`);
    if (!isDryRun) {
      console.log(`Inserted new sources:  ${summary.insertedNew}`);
      console.log(`Skipped (conflict):    ${summary.skippedConflict}`);
    }
    console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);

    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[relink-socrata-skipped] Fatal error:', err);
  process.exit(1);
});
