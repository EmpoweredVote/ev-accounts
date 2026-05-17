/**
 * seed-ocpf-cambridge.ts — One-shot seeder for Cambridge OCPF candidate sources.
 *
 * Fetches Cambridge City Council candidates from OCPF ytd report, fuzzy-matches
 * against essentials.politicians (MA, Cambridge), and upserts politician_sources
 * rows with source_system='ocpf'.
 *
 * Usage (from C:\EV-Accounts\backend):
 *   npx tsx scripts/seed-ocpf-cambridge.ts [--dry-run]
 *
 * --dry-run: prints matches/mismatches without writing to DB.
 *
 * Matching:
 *   Normalizes both sides (lowercase, strip punctuation, trim).
 *   Jaccard token overlap >= 0.5 = match.
 *   Logs all pairs for operator review.
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface OcpfReport {
  cpfId: number;
  filerName: string;
  officeSought: string;
  [key: string]: unknown;
}

interface OcpfYtdResponse {
  reports: OcpfReport[];
}

interface DbPolitician {
  id: string;
  full_name: string;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const OCPF_BASE = 'https://api.ocpf.us';
const DRY_RUN = process.argv.includes('--dry-run');

// ---------------------------------------------------------------------------
// Fuzzy match helpers
// ---------------------------------------------------------------------------

/**
 * normalizeName lowercases, strips punctuation, collapses whitespace.
 * Used for both OCPF filerName and essentials.politicians.full_name.
 */
function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')   // strip punctuation to spaces
    .replace(/\s+/g, ' ')       // collapse whitespace
    .trim();
}

/**
 * jaccardScore computes token overlap between two normalized name strings.
 * Returns intersection size / union size.
 */
function jaccardScore(a: string, b: string): number {
  const setA = new Set(a.split(' ').filter(Boolean));
  const setB = new Set(b.split(' ').filter(Boolean));
  if (setA.size === 0 && setB.size === 0) return 1;
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  for (const token of setA) {
    if (setB.has(token)) intersection++;
  }
  const union = setA.size + setB.size - intersection;
  return intersection / union;
}

/**
 * parseFilerName converts OCPF "Last, First [Middle]" to "First Last" for matching.
 * Falls back to original string if no comma found.
 */
function parseFilerName(filerName: string): string {
  const commaIdx = filerName.indexOf(',');
  if (commaIdx === -1) return filerName;
  const last = filerName.slice(0, commaIdx).trim();
  const rest = filerName.slice(commaIdx + 1).trim();
  return `${rest} ${last}`;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log(`[seed-ocpf-cambridge] Starting${DRY_RUN ? ' (DRY RUN — no DB writes)' : ''}...`);

  // --- 1. Fetch Cambridge City Council candidates from OCPF ---
  const year = new Date().getFullYear();
  const url = `${OCPF_BASE}/reports/cc/ytd/${year}`;
  console.log(`[seed-ocpf-cambridge] Fetching OCPF ytd report: ${url}`);

  let ocpfResponse: OcpfYtdResponse;
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(30_000) });
    if (res.status !== 200) {
      throw new Error(`HTTP ${res.status}`);
    }
    ocpfResponse = await res.json() as OcpfYtdResponse;
  } catch (err) {
    console.error('[seed-ocpf-cambridge] Failed to fetch OCPF report:', err);
    process.exit(1);
  }

  const allReports = ocpfResponse.reports ?? [];
  // Filter to Cambridge (case-insensitive on officeSought)
  const cambridgeReports = allReports.filter(r =>
    r.officeSought.toLowerCase().includes('cambridge')
  );

  console.log(`[seed-ocpf-cambridge] Total reports: ${allReports.length}`);
  console.log(`[seed-ocpf-cambridge] Cambridge candidates: ${cambridgeReports.length}`);
  console.log('');
  console.log('[seed-ocpf-cambridge] All Cambridge OCPF filers:');
  for (const r of cambridgeReports) {
    console.log(`  cpfId=${r.cpfId}  filerName="${r.filerName}"  officeSought="${r.officeSought}"`);
  }
  console.log('');

  // --- 2. Load Cambridge politicians from essentials ---
  const pool = new Pool({ connectionString: process.env['DATABASE_URL'] });

  let dbPoliticians: DbPolitician[] = [];
  try {
    const result = await pool.query<DbPolitician>(
      `SELECT p.id, p.full_name
       FROM essentials.politicians p
       JOIN essentials.offices o ON o.id = p.office_id
       WHERE o.representing_state = 'MA'
         AND o.representing_city ILIKE '%Cambridge%'`
    );
    dbPoliticians = result.rows;
  } catch (err) {
    console.error('[seed-ocpf-cambridge] Failed to load Cambridge politicians:', err);
    await pool.end();
    process.exit(1);
  }

  console.log(`[seed-ocpf-cambridge] Cambridge politicians in DB: ${dbPoliticians.length}`);
  for (const p of dbPoliticians) {
    console.log(`  id=${p.id}  name="${p.full_name}"`);
  }
  console.log('');

  // --- 3. Fuzzy-match OCPF filerName against DB politicians ---
  const JACCARD_THRESHOLD = 0.5;

  interface MatchResult {
    cpfId: number;
    filerName: string;
    officeSought: string;
    matchedId: string | null;
    matchedName: string | null;
    score: number;
  }

  const matches: MatchResult[] = [];
  const unmatched: OcpfReport[] = [];

  for (const report of cambridgeReports) {
    // Convert "Last, First" to "First Last" for comparison
    const parsedFiler = parseFilerName(report.filerName);
    const normalizedFiler = normalizeName(parsedFiler);

    let bestMatch: DbPolitician | null = null;
    let bestScore = 0;

    for (const politician of dbPoliticians) {
      const normalizedDb = normalizeName(politician.full_name);
      const score = jaccardScore(normalizedFiler, normalizedDb);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = politician;
      }
    }

    if (bestMatch && bestScore >= JACCARD_THRESHOLD) {
      matches.push({
        cpfId: report.cpfId,
        filerName: report.filerName,
        officeSought: report.officeSought,
        matchedId: bestMatch.id,
        matchedName: bestMatch.full_name,
        score: bestScore,
      });
    } else {
      console.log(`[seed-ocpf-cambridge] UNMATCHED: "${report.filerName}" (best score=${bestScore.toFixed(2)} for "${bestMatch?.full_name ?? 'none'}")`);
      unmatched.push(report);
    }
  }

  console.log('');
  console.log('[seed-ocpf-cambridge] Matches:');
  for (const m of matches) {
    console.log(`  MATCH (score=${m.score.toFixed(2)}): "${m.filerName}" -> "${m.matchedName}" [${m.matchedId}]`);
  }
  console.log('');

  // --- 4. Upsert politician_sources ---
  let inserted = 0;
  let alreadyExisted = 0;

  if (!DRY_RUN) {
    for (const m of matches) {
      try {
        const result = await pool.query(
          `INSERT INTO transparent_motivations.politician_sources
             (essentials_politician_id, source_system, external_id, research_status, notes)
           VALUES ($1, 'ocpf', $2, 'confirmed', $3)
           ON CONFLICT (essentials_politician_id, source_system, external_id) DO NOTHING`,
          [
            m.matchedId,
            String(m.cpfId),
            `Auto-seeded from OCPF /reports/cc/ytd — filerName: ${m.filerName}`,
          ]
        );
        if ((result.rowCount ?? 0) > 0) {
          inserted++;
          console.log(`[seed-ocpf-cambridge] Inserted: "${m.filerName}" (cpfId=${m.cpfId}) -> politician ${m.matchedId}`);
        } else {
          alreadyExisted++;
          console.log(`[seed-ocpf-cambridge] Already exists: "${m.filerName}" (cpfId=${m.cpfId})`);
        }
      } catch (err) {
        console.error(`[seed-ocpf-cambridge] ERROR inserting cpfId=${m.cpfId}:`, err);
      }
    }
  }

  // --- 5. Summary ---
  console.log('');
  console.log('=== seed-ocpf-cambridge SUMMARY ===');
  console.log(`  OCPF Cambridge filers found: ${cambridgeReports.length}`);
  console.log(`  DB Cambridge politicians:    ${dbPoliticians.length}`);
  console.log(`  Matched (Jaccard >= 0.50):  ${matches.length}`);
  console.log(`  Unmatched:                  ${unmatched.length}`);
  if (!DRY_RUN) {
    console.log(`  Inserted into DB:           ${inserted}`);
    console.log(`  Already existed (skipped):  ${alreadyExisted}`);
  } else {
    console.log(`  (Dry run — no DB writes)`);
  }
  if (unmatched.length > 0) {
    console.log('');
    console.log('  Unmatched OCPF filers (operator review needed):');
    for (const r of unmatched) {
      console.log(`    cpfId=${r.cpfId}  "${r.filerName}"  officeSought="${r.officeSought}"`);
    }
  }

  await pool.end();
}

main().catch(err => {
  console.error('[seed-ocpf-cambridge] Fatal error:', err);
  process.exit(1);
});
