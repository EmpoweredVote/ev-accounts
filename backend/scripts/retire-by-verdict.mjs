/**
 * Retire stance rows by verdict from a check-source-supports.py report.
 *
 *   node scripts/retire-by-verdict.mjs <report.json> --verdicts SOURCE-DEAD,UNSUPPORTED-STRUCTURAL
 *   node scripts/retire-by-verdict.mjs <report.json> --verdicts ... --apply
 *
 * Dry run by default. Snapshots every row (value, reasoning, sources) to a JSON
 * file BEFORE deleting, so the delete is reversible. Prints per-person impact and
 * names anyone whose compass becomes empty.
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

const report = process.argv[2];
const vIdx = process.argv.indexOf('--verdicts');
if (!report || vIdx === -1) {
  console.error('usage: retire-by-verdict.mjs <report.json> --verdicts A,B [--apply]');
  process.exit(2);
}
const verdicts = process.argv[vIdx + 1].split(',').map((s) => s.trim());
const APPLY = process.argv.includes('--apply');
const SNAP = `data/stance-research/or-bend-stateleg/retired-${verdicts.join('+').toLowerCase()}-snapshot.json`;

const all = JSON.parse(readFileSync(report, 'utf8'));
const target = all.filter((r) => verdicts.includes(r.verdict));
if (!target.length) { console.error('no rows match those verdicts'); process.exit(1); }
const pairs = target.map((r) => [String(r.external_id), r.topic_key]);

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
console.log(`report: ${all.length} rows; matching ${verdicts.join(', ')}: ${target.length}\n`);
for (const v of verdicts) console.log(`   ${v}: ${target.filter((r) => r.verdict === v).length}`);

// ---- impact ----
const ids = [...new Set(target.map((r) => String(r.external_id)))];
const { rows: totals } = await pool.query(`
  SELECT p.external_id, p.full_name, count(*)::int AS total
    FROM essentials.politicians p
    JOIN inform.politician_answers pa ON pa.politician_id = p.id
   WHERE p.external_id = ANY($1::bigint[])
   GROUP BY p.external_id, p.full_name`, [ids]);
const drop = new Map();
for (const r of target) {
  const k = String(r.external_id);
  drop.set(k, (drop.get(k) || 0) + 1);
}
const emptied = [];
console.log(`\n  person                          total  drop  left`);
for (const t of totals.sort((a, b) => a.full_name.localeCompare(b.full_name))) {
  const d = drop.get(String(t.external_id)) || 0;
  const left = t.total - d;
  if (left === 0) emptied.push(t.full_name);
  console.log(`  ${t.full_name.padEnd(30)} ${String(t.total).padStart(5)} ${String(d).padStart(5)} ${String(left).padStart(5)}` +
              (left === 0 ? '  <-- EMPTY compass' : ''));
}
console.log(`\n${totals.length} politicians affected; ${emptied.length} left with an empty compass` +
            (emptied.length ? `: ${emptied.join(', ')}` : ''));

// ---- snapshot ----
const { rows: snap } = await pool.query(`
  SELECT p.external_id, p.full_name, t.topic_key, pa.value, pc.reasoning, pc.sources
    FROM essentials.politicians p
    JOIN inform.politician_answers pa ON pa.politician_id = p.id
    JOIN inform.compass_topics t      ON t.id = pa.topic_id
    LEFT JOIN inform.politician_context pc
           ON pc.politician_id = p.id AND pc.topic_id = pa.topic_id
   WHERE (p.external_id, t.topic_key) IN (
     SELECT (e->>0)::bigint, e->>1 FROM jsonb_array_elements($1::jsonb) AS e)
   ORDER BY p.full_name, t.topic_key`, [JSON.stringify(pairs)]);
writeFileSync(SNAP, JSON.stringify({
  retired_at: new Date().toISOString(), verdicts, source_report: report,
  reason: 'source-supports-claim: cited source is dead (404), or the only source is a biography '
        + 'page and the reasoning names no bill/date/vote/quote — nothing checkable',
  rows: snap,
}, null, 2));
console.log(`\nSnapshot: ${snap.length} rows -> ${SNAP}`);
if (snap.length !== target.length) {
  console.log(`  NOTE: snapshot ${snap.length} vs targeted ${target.length}. Inspect before applying.`);
}

if (!APPLY) { console.log('\nDRY RUN — pass --apply to delete.'); await pool.end(); process.exit(0); }

await pool.query('BEGIN');
try {
  const del = async (tbl) => (await pool.query(`
    DELETE FROM inform.${tbl} x
     USING essentials.politicians p, inform.compass_topics t
     WHERE x.politician_id = p.id AND x.topic_id = t.id
       AND (p.external_id, t.topic_key) IN (
         SELECT (e->>0)::bigint, e->>1 FROM jsonb_array_elements($1::jsonb) AS e)`,
    [JSON.stringify(pairs)])).rowCount;
  const ctx = await del('politician_context');
  const ans = await del('politician_answers');
  await pool.query('COMMIT');
  console.log(`COMMIT: deleted ${ans} answers + ${ctx} context rows.`);
} catch (e) {
  await pool.query('ROLLBACK');
  console.error('ROLLBACK:', e.message);
  process.exit(1);
}
await pool.end();
