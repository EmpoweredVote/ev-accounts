/**
 * Retire the stance rows flagged by scripts/sweep-or-preseating.mjs — rows citing
 * a legislative session the member did not serve, i.e. a vote that cannot be
 * theirs. Reads the sweep's --json report; does NOT re-derive it.
 *
 * Snapshots every row (value + reasoning + sources) before deleting, so the
 * delete is reversible.
 *
 *   node scripts/retire-or-preseating.mjs <sweep.json>            # dry run
 *   node scripts/retire-or-preseating.mjs <sweep.json> --apply
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'fs';
import { Pool } from 'pg';

const report = process.argv[2];
if (!report) { console.error('usage: retire-or-preseating.mjs <sweep.json> [--apply]'); process.exit(2); }
const APPLY = process.argv.includes('--apply');
const bad = JSON.parse(readFileSync(report, 'utf8')).bad;
const SNAP = 'data/stance-research/or-bend-stateleg/retired-preseating-snapshot.json';

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const pairs = bad.map((b) => [b.external_id, b.topic_key]);

// impact: how many stances does each person have, and how many survive?
const { rows: totals } = await pool.query(`
  SELECT p.external_id, p.full_name, count(*)::int AS total
    FROM essentials.politicians p
    JOIN inform.politician_answers pa ON pa.politician_id = p.id
   WHERE p.external_id = ANY($1::bigint[])
   GROUP BY p.external_id, p.full_name`, [[...new Set(bad.map((b) => b.external_id))]]);
const dropCount = new Map();
// pg returns bigint as a STRING, so key everything as String or the
// impact table silently reports 0 dropped for every person.
for (const b of bad) {
  const k = String(b.external_id);
  dropCount.set(k, (dropCount.get(k) || 0) + 1);
}

let emptied = 0;
console.log(`Retiring ${bad.length} rows across ${totals.length} politicians\n`);
console.log('  person                          total  drop  left');
for (const t of totals.sort((a, b) => a.full_name.localeCompare(b.full_name))) {
  const d = dropCount.get(String(t.external_id)) || 0;
  const left = t.total - d;
  if (left === 0) emptied++;
  console.log(`  ${t.full_name.padEnd(30)} ${String(t.total).padStart(5)} ${String(d).padStart(5)} ` +
              `${String(left).padStart(5)}${left === 0 ? '  <-- compass becomes EMPTY' : ''}`);
}
console.log(`\n${emptied} politician(s) will have an empty compass — honest, and preferable to fabricated rows.`);

// snapshot
const { rows: snap } = await pool.query(`
  SELECT p.external_id, p.full_name, t.topic_key, pa.value, pc.reasoning, pc.sources
    FROM essentials.politicians p
    JOIN inform.politician_answers pa ON pa.politician_id = p.id
    JOIN inform.compass_topics t      ON t.id = pa.topic_id
    LEFT JOIN inform.politician_context pc
           ON pc.politician_id = p.id AND pc.topic_id = pa.topic_id
   WHERE (p.external_id, t.topic_key) IN (
     SELECT (x->>0)::bigint, x->>1 FROM jsonb_array_elements($1::jsonb) AS x)
   ORDER BY p.full_name, t.topic_key`, [JSON.stringify(pairs)]);
writeFileSync(SNAP, JSON.stringify({
  retired_at: new Date().toISOString(),
  reason: 'pre-seating: cited a legislative session the member did not serve (OLIS OData Legislators is ground truth)',
  source_report: report, rows: snap,
}, null, 2));
console.log(`\nSnapshot: ${snap.length} rows -> ${SNAP}`);
if (snap.length !== bad.length) console.log(`  NOTE: snapshot ${snap.length} vs flagged ${bad.length} — inspect before applying.`);

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
