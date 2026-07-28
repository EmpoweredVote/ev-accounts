/**
 * POST-APPLY check: prove no last-copy deletion actually happened.
 *
 * The pre-apply invariant proved the PLAN was safe. This proves the OUTCOME is:
 * for every row recorded in the rollback snapshot, a surviving contribution must
 * still exist in the same report (committee_id, report_year, report_type) for the
 * same donor/amount/date, at the survivor file_number.
 *
 * If any snapshot row has no surviving counterpart, that line was removed from
 * the database entirely — the FEC-04b failure mode — and the snapshot should be
 * used to restore it.
 *
 * READ-ONLY.
 *   node scripts/verify-fec-retirement-postcheck.mjs
 */
import 'dotenv/config';
import { readFileSync } from 'fs';
import pg from 'pg';

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const snap = JSON.parse(readFileSync('data/fec-superseded-local-snapshot.json', 'utf8'));

// Group the retired rows by source so each source costs one scan, not one per row.
const bySource = new Map();
for (const r of snap.rows) {
  if (!bySource.has(r.politician_source_id)) bySource.set(r.politician_source_id, []);
  bySource.get(r.politician_source_id).push(r);
}
console.log(`checking ${snap.rows.length.toLocaleString()} retired row(s) across ${bySource.size} source(s)\n`);

const key = (o) => [o.cmte, o.ry, o.rt, o.donor ?? '', o.amount, o.date ?? ''].join('|');

let checked = 0, orphaned = 0, failed = 0, done = 0;
const examples = [];

for (const [src, rows] of bySource) {
  const c = await pool.connect();
  try {
    await c.query(`SET statement_timeout = '300s'`);
    // Every surviving line in this source, keyed the same way the retirement keyed it.
    const { rows: alive } = await c.query(
      `SELECT raw_record->>'committee_id' AS cmte,
              (raw_record->>'report_year')::text AS ry,
              raw_record->>'report_type' AS rt,
              coalesce(donor_name_normalized,'') AS donor,
              amount::text AS amount,
              coalesce(contribution_date::text,'') AS date,
              (raw_record->>'file_number')::text AS fn
         FROM transparent_motivations.contributions
        WHERE politician_source_id = $1 AND data_source = 'fec' AND raw_record ? 'file_number'`,
      [src]
    );
    const live = new Set(alive.map((a) => key(a) + '|' + a.fn));
    for (const r of rows) {
      checked++;
      const want = [r.cmte, r.ry, r.rt, r.donor_name_normalized ?? '', r.amount,
                    r.contribution_date ?? ''].join('|') + '|' + r.survivor_fn;
      if (!live.has(want)) {
        orphaned++;
        if (examples.length < 5) examples.push(`${src} ${r.cmte} ${r.ry}/${r.rt} fn ${r.fn} -> ${r.survivor_fn} ${r.donor_name_normalized} $${r.amount}`);
      }
    }
  } catch (e) {
    failed++;
    console.log(`  ! ${src}: SKIPPED (${e.message})`);
  } finally { c.release(); }
  if (++done % 25 === 0) console.log(`  ...${done}/${bySource.size}`);
}

console.log(`\nretired rows checked : ${checked.toLocaleString()}`);
console.log(`ORPHANED (no survivor): ${orphaned}   (must be 0 — the pass condition)`);
console.log(`sources not verified : ${failed}   (must be 0 for full coverage)`);
if (examples.length) { console.log('\nexamples:'); examples.forEach((e) => console.log('  ' + e)); }
console.log(
  orphaned === 0 && failed === 0
    ? '\nPASS — every retired line still has its survivor in the database.'
    : '\nFAIL — restore the orphaned rows from the snapshot.'
);
await pool.end();
