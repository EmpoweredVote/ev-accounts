/**
 * Detect FEC amendment double-counts that PREDATE the FEC-04b fix.
 *
 * The fix (fecAdapter.retireSupersededFilings) retires superseded filings using
 * `file_number`, which is only stored on rows ingested after it shipped. Rows loaded
 * before that carry no file_number, so the fix deliberately never touches them — for
 * those we cannot tell which version a row is, and guessing could delete the CURRENT
 * one. This script finds them instead, using a signature that needs no new fields.
 *
 * Signature: `sub_id` embeds FEC's load date as chars 2-9 (MMDDYYYY) — e.g.
 * 4|05292020|1773727971. Lines from ONE filing therefore share a sub_id date prefix
 * (and are usually consecutive). A group of rows identical on
 * (committee, donor, amount, contribution_date) that spans TWO OR MORE prefixes is a
 * report filed once and then re-reported by an amendment.
 *
 * Why the naive key is not enough: FEC legitimately reports repeated identical lines in
 * a single filing (five $1.00 recurring donations from one donor on one day). Those
 * share a prefix and are NOT duplicates — requiring >1 distinct prefix excludes them.
 * Verified against the real case: committee C00256925, report 12P/2020, prefixes
 * 05292020 (file 1409022) and 12302020 (file 1484476).
 *
 *   node scripts/detect-fec-amendment-dupes.mjs [--limit N] [--json out.json]
 *
 * Read-only. Deletes nothing — the surviving version has to be chosen against the FEC
 * API (highest file_number for that committee/report_year/report_type), not guessed.
 */
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { Pool } from 'pg';

const limIdx = process.argv.indexOf('--limit');
const LIMIT = limIdx > -1 ? parseInt(process.argv[limIdx + 1], 10) : 200;
const jsonIdx = process.argv.indexOf('--json');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Scoped per politician_source so every scan rides idx_contrib_src_cycle. An unscoped
// GROUP BY over 26.9M rows is the shape of the 2026-07-22 P1 pool-saturation incident.
const { rows: sources } = await pool.query(
  `SELECT id FROM transparent_motivations.politician_sources
    WHERE source_system IN ('fec','fec_house','fec_senate') ORDER BY updated_at DESC NULLS LAST LIMIT $1`, [LIMIT]);
console.log(`scanning ${sources.length} politician_source(s)\n`);

const findings = [];
const timedOut = [];
let scanned = 0, rowsSeen = 0;
for (const s of sources) {
  let rows;
  try {
    // The `postgres` role carries statement_timeout=8s (2026-07-22 P1 remediation), which the
    // largest sources exceed — 934k-row slices legitimately need longer. Raised per-connection,
    // not per-role, and only for this read-only analytical scan. Still index-scoped per source,
    // so this is a long single-source read, never the unscoped seq-scan the 8s cap guards against.
    await pool.query(`SET statement_timeout = '180s'`);
    ({ rows } = await pool.query(
    `WITH slice AS (
       SELECT raw_record->>'committee_id' AS cmte,
              donor_name_normalized AS donor,
              amount, contribution_date,
              substring(raw_record->>'sub_id' from 2 for 8) AS sub_date,
              (raw_record ? 'file_number') AS has_file_number
         FROM transparent_motivations.contributions
        WHERE data_source = 'fec' AND politician_source_id = $1
     ), grp AS (
       SELECT cmte, donor, amount, contribution_date,
              count(*) AS n,
              count(DISTINCT sub_date) AS prefixes,
              array_agg(DISTINCT sub_date ORDER BY sub_date) AS load_dates,
              bool_or(has_file_number) AS any_post_fix
         FROM slice GROUP BY 1,2,3,4
     )
     SELECT (SELECT count(*) FROM slice) AS slice_rows,
            coalesce(sum(n - 1) FILTER (WHERE prefixes > 1), 0)::int AS excess_rows,
            count(*) FILTER (WHERE prefixes > 1)::int AS dup_groups,
            coalesce(jsonb_agg(jsonb_build_object(
              'cmte', cmte, 'donor', donor, 'amount', amount,
              'date', contribution_date, 'rows', n, 'load_dates', load_dates,
              'any_post_fix', any_post_fix
            )) FILTER (WHERE prefixes > 1), '[]'::jsonb) AS detail
       FROM grp`, [s.id]));
  } catch (e) {
    // One slow/huge source must never abort a 677-source sweep (it did, 2026-07-25). Record it
    // as unscanned so the coverage number stays honest rather than silently shrinking.
    timedOut.push({ politician_source_id: s.id, error: e.message });
    console.log(`  ! ${s.id}  SKIPPED (${e.message})`);
    continue;
  }
  const r = rows[0];
  scanned++;
  rowsSeen += Number(r.slice_rows);
  if (r.dup_groups > 0) {
    findings.push({ politician_source_id: s.id, dup_groups: r.dup_groups,
                    excess_rows: r.excess_rows, detail: r.detail });
    console.log(`  ${s.id}  ${r.dup_groups} group(s), ${r.excess_rows} excess row(s) of ${r.slice_rows}`);
  }
}

const totalGroups = findings.reduce((a, f) => a + f.dup_groups, 0);
const totalExcess = findings.reduce((a, f) => a + f.excess_rows, 0);
console.log(`\nscanned ${scanned} sources / ${rowsSeen.toLocaleString()} rows`);
if (timedOut.length) console.log(`UNSCANNED (errored): ${timedOut.length} source(s) — coverage is NOT complete`);
console.log(`affected sources: ${findings.length}`);
console.log(`duplicate groups: ${totalGroups}`);
console.log(`EXCESS ROWS (the over-count): ${totalExcess}` +
            (rowsSeen ? `  (${(100 * totalExcess / rowsSeen).toFixed(3)}% of rows scanned)` : ''));
console.log('\nNothing deleted. To retire, resolve each (committee, report_year, report_type) against');
console.log('the FEC API and keep only the highest file_number — do not guess from the prefix alone.');

if (jsonIdx > -1 && process.argv[jsonIdx + 1]) {
  writeFileSync(process.argv[jsonIdx + 1], JSON.stringify({ scanned, rowsSeen, findings, timedOut }, null, 2));
  console.log(`\nwrote ${process.argv[jsonIdx + 1]}`);
}
await pool.end();
