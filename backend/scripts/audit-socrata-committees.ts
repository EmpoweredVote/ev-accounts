/**
 * audit-socrata-committees.ts — full Socrata committee audit against politician_sources.
 *
 * Usage:
 *   npx tsx backend/scripts/audit-socrata-committees.ts          # dry-run (no changes)
 *   npx tsx backend/scripts/audit-socrata-committees.ts --execute # apply changes
 *
 * Requires environment variable:
 *   DATABASE_URL — PostgreSQL connection string (in .env)
 *
 * Optional environment variable:
 *   SOCRATA_APP_TOKEN — Socrata SODA API app token (recommended to avoid rate limits)
 *
 * What it does:
 *   1. Fetches all distinct committees from the LA Socrata dataset (m6g2-gc6c).
 *   2. Finds which cmt_ids are already in politician_sources (source_system='la_socrata').
 *   3. For each un-linked committee, tries to match it to ANY active politician
 *      (including politicians who already have a different la_socrata committee).
 *   4. Classifies into four buckets:
 *      - already-linked: cmt_id already in politician_sources
 *      - new-link: exactly 1 politician match → inserts needs_research row
 *      - ambiguous: 2+ politician matches → printed for manual review
 *      - unmatched: 0 politician matches
 *   5. Prints a full audit table and summary report.
 *   6. In --execute mode, inserts new politician_sources rows with ON CONFLICT DO NOTHING.
 *
 * IMPORTANT: research_status='needs_research' — operator must confirm before ingestion runs.
 * The Socrata scheduler only ingests 'confirmed' rows; these rows are safe to insert.
 *
 * Critical difference from relink-socrata-skipped.ts:
 *   relink-socrata-skipped.ts starts from the POLITICIAN side (politicians with no la_socrata source).
 *   This script starts from the COMMITTEE side — every Socrata committee is audited,
 *   including those that might match politicians who already have a different committee linked.
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

// ─── Types ───────────────────────────────────────────────────────────────────

interface SocrataCommittee {
  cmt_id: string;
  cmt_nm: string;
}

interface SocrataCommitteeNormalized extends SocrataCommittee {
  normalized_nm: string;
}

interface Politician {
  id: string;
  full_name: string;
}

type AuditStatus = 'already-linked' | 'new-link' | 'ambiguous' | 'unmatched';

interface AuditResult {
  committee: SocrataCommitteeNormalized;
  status: AuditStatus;
  matchedPoliticians: Politician[];
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

// ─── Data fetching ────────────────────────────────────────────────────────────

async function fetchSocrataCommittees(): Promise<SocrataCommittee[]> {
  const url =
    'https://data.lacity.org/resource/m6g2-gc6c.json?$select=cmt_id,cmt_nm&$group=cmt_id,cmt_nm&$limit=10000';

  const headers: Record<string, string> = {
    Accept: 'application/json',
  };
  if (process.env.SOCRATA_APP_TOKEN) {
    headers['X-App-Token'] = process.env.SOCRATA_APP_TOKEN;
  } else {
    console.warn('[audit-socrata-committees] SOCRATA_APP_TOKEN not set — requests may be rate-limited');
  }

  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`Socrata API returned ${response.status}: ${await response.text()}`);
  }

  const data = (await response.json()) as SocrataCommittee[];
  return data;
}

async function fetchLinkedCmtIds(): Promise<Set<string>> {
  const result = await pool.query<{ external_id: string }>(`
    SELECT external_id
    FROM transparent_motivations.politician_sources
    WHERE source_system = 'la_socrata'
  `);
  return new Set(result.rows.map(r => r.external_id));
}

async function fetchAllActivePoliticians(): Promise<Politician[]> {
  const result = await pool.query<Politician>(`
    SELECT p.id, p.full_name
    FROM essentials.politicians p
    WHERE p.is_active = true
    ORDER BY p.full_name
  `);
  return result.rows;
}

// ─── Insert ───────────────────────────────────────────────────────────────────

async function insertPoliticianSource(
  politicianId: string,
  cmtId: string,
  cmtNm: string,
): Promise<boolean> {
  const notes = JSON.stringify({ cmt_nm: cmtNm, linked_by: 'audit-socrata-committees.ts' });
  const result = await pool.query(
    `INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
     VALUES ($1, 'la_socrata', $2, 'needs_research', $3)
     ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
    [politicianId, cmtId, notes],
  );
  return (result.rowCount ?? 0) > 0;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`[audit-socrata-committees] Mode: ${isDryRun ? 'DRY-RUN (no changes)' : 'EXECUTE'}`);

  const startMs = Date.now();

  const summary = {
    committeesTotal: 0,
    alreadyLinked: 0,
    unlinkedAudited: 0,
    newLinks: 0,
    ambiguous: 0,
    unmatched: 0,
    insertedNew: 0,
    skippedConflict: 0,
  };

  try {
    // Step 1: Fetch all committees from Socrata
    console.log('[audit-socrata-committees] Fetching committees from Socrata dataset m6g2-gc6c...');
    const rawCommittees = await fetchSocrataCommittees();
    summary.committeesTotal = rawCommittees.length;
    console.log(`[audit-socrata-committees] Fetched ${rawCommittees.length} committees.`);

    // Filter out entries with null/empty cmt_nm or cmt_id, build normalized lookup
    const committees: SocrataCommitteeNormalized[] = rawCommittees
      .filter(c => c.cmt_id && c.cmt_nm)
      .map(c => ({
        ...c,
        normalized_nm: normalize(c.cmt_nm),
      }));

    // Step 2: Fetch already-linked cmt_ids
    console.log('[audit-socrata-committees] Fetching already-linked cmt_ids from politician_sources...');
    const linkedCmtIds = await fetchLinkedCmtIds();
    // Count how many valid (non-filtered) Socrata committees are already linked
    const alreadyLinkedCommittees = committees.filter(c => linkedCmtIds.has(c.cmt_id));
    summary.alreadyLinked = alreadyLinkedCommittees.length;
    console.log(`[audit-socrata-committees] ${summary.alreadyLinked} committees already linked.`);

    // Step 3: Identify un-linked committees
    const unlinkedCommittees = committees.filter(c => !linkedCmtIds.has(c.cmt_id));
    summary.unlinkedAudited = unlinkedCommittees.length;
    console.log(
      `[audit-socrata-committees] ${summary.alreadyLinked} of ${summary.committeesTotal} committees already linked, ${summary.unlinkedAudited} un-linked to audit.`,
    );

    // Step 4: Fetch ALL active politicians (not just those without sources)
    console.log('[audit-socrata-committees] Fetching all active politicians...');
    const politicians = await fetchAllActivePoliticians();
    console.log(`[audit-socrata-committees] ${politicians.length} active politician(s) loaded.`);

    // Pre-compute normalized last names for politicians (exclude null/empty names)
    const politiciansWithLastName = politicians
      .filter(p => p.full_name && p.full_name.trim().length > 0)
      .map(p => ({
        ...p,
        normalizedLastName: normalize(extractLastName(p.full_name)),
      }));

    // Step 5: Match un-linked committees to politicians
    const auditResults: AuditResult[] = [];

    for (const committee of unlinkedCommittees) {
      const matchedPoliticians = politiciansWithLastName
        .filter(p => committee.normalized_nm.includes(p.normalizedLastName))
        .map(({ id, full_name }) => ({ id, full_name }));

      let status: AuditStatus;
      if (matchedPoliticians.length === 1) {
        status = 'new-link';
      } else if (matchedPoliticians.length === 0) {
        status = 'unmatched';
      } else {
        status = 'ambiguous';
      }

      auditResults.push({ committee, status, matchedPoliticians });
    }

    // Build already-linked results for display (reuse pre-computed list)
    const alreadyLinkedResults: AuditResult[] = alreadyLinkedCommittees.map(c => ({
      committee: c,
      status: 'already-linked' as AuditStatus,
      matchedPoliticians: [],
    }));

    // Tally buckets
    for (const r of auditResults) {
      if (r.status === 'new-link') summary.newLinks++;
      else if (r.status === 'ambiguous') summary.ambiguous++;
      else if (r.status === 'unmatched') summary.unmatched++;
    }

    // Step 6: Print full audit table
    console.log('\n=== FULL COMMITTEE AUDIT ===');

    console.log(`\nALREADY LINKED (${alreadyLinkedResults.length} committees):`);
    for (const r of alreadyLinkedResults) {
      console.log(`  cmt_id=${r.committee.cmt_id}  "${r.committee.cmt_nm}"`);
    }

    const newLinks = auditResults.filter(r => r.status === 'new-link');
    console.log(`\nNEW LINKS (${newLinks.length} committees):`);
    for (const r of newLinks) {
      const p = r.matchedPoliticians[0];
      console.log(
        `  cmt_id=${r.committee.cmt_id}  "${r.committee.cmt_nm}" → politician="${p.full_name}" (id=${p.id})`,
      );
    }

    const ambiguousResults = auditResults.filter(r => r.status === 'ambiguous');
    console.log(`\nAMBIGUOUS (${ambiguousResults.length} committees — manual review needed):`);
    for (const r of ambiguousResults) {
      const names = r.matchedPoliticians.map(p => `"${p.full_name}"`).join(', ');
      console.log(
        `  cmt_id=${r.committee.cmt_id}  "${r.committee.cmt_nm}" → ${r.matchedPoliticians.length} matches: ${names}`,
      );
    }

    const unmatchedResults = auditResults.filter(r => r.status === 'unmatched');
    console.log(`\nUNMATCHED (${unmatchedResults.length} committees — no politician found):`);
    for (const r of unmatchedResults) {
      console.log(`  cmt_id=${r.committee.cmt_id}  "${r.committee.cmt_nm}"`);
    }

    console.log('');

    // Step 7: Insert in execute mode
    if (!isDryRun) {
      console.log('[audit-socrata-committees] Inserting new-link sources...');
      for (const r of newLinks) {
        const p = r.matchedPoliticians[0];
        const inserted = await insertPoliticianSource(p.id, r.committee.cmt_id, r.committee.cmt_nm);
        if (inserted) {
          summary.insertedNew++;
          console.log(`  [INSERT] "${p.full_name}" → cmt_id=${r.committee.cmt_id} "${r.committee.cmt_nm}"`);
        } else {
          summary.skippedConflict++;
          console.log(
            `  [SKIP]   "${p.full_name}" → cmt_id=${r.committee.cmt_id} already exists (ON CONFLICT DO NOTHING)`,
          );
        }
      }
    }

    const durationMs = Date.now() - startMs;

    // Step 8: Print summary report
    console.log('\n=== AUDIT SUMMARY ===');
    if (isDryRun) {
      console.log('(DRY-RUN — no changes made)');
    }
    console.log(`Total committees in Socrata:   ${summary.committeesTotal}`);
    console.log(`Already linked:                ${summary.alreadyLinked}`);
    console.log(`Un-linked audited:             ${summary.unlinkedAudited}`);
    console.log(`  New links (unambiguous):     ${summary.newLinks}`);
    console.log(`  Ambiguous (manual review):   ${summary.ambiguous}`);
    console.log(`  Unmatched (no politician):   ${summary.unmatched}`);
    if (!isDryRun) {
      console.log(`  Inserted new sources:        ${summary.insertedNew}`);
      console.log(`  Skipped (already existed):   ${summary.skippedConflict}`);
    }

    // Sanity check: buckets should sum to total (committees with valid cmt_id and cmt_nm)
    const validTotal = committees.length;
    const bucketSum = summary.alreadyLinked + summary.newLinks + summary.ambiguous + summary.unmatched;
    if (bucketSum !== validTotal) {
      console.warn(
        `\n[WARN] Bucket sum (${bucketSum}) does not match valid committee count (${validTotal}). Check for filtering differences.`,
      );
    } else {
      console.log(`\nBucket check: ${bucketSum} = already-linked + new-links + ambiguous + unmatched (OK)`);
    }

    console.log(`\nCompleted in ${(durationMs / 1000).toFixed(1)}s`);

    process.exit(0);
  } finally {
    await pool.end();
  }
}

main().catch(err => {
  console.error('[audit-socrata-committees] Fatal error:', err);
  process.exit(1);
});
