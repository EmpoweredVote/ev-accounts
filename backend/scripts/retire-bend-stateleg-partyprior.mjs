/**
 * Retire the fabricated party-prior stance rows for the three Bend-ballot Oregon
 * legislators (Levy -4120053, Kropf -4120054, Broadman -4110027).
 *
 * WHY: all 18 rows came from a bulk seed that inferred from party + district
 * geography. 7 of the 8 bill-cited rows attribute votes cast BEFORE the member
 * was seated (verified term_start: Levy 2023-01-09, Kropf 2021-01-11, Broadman
 * SENATE 2025-01-13). Four of Levy's six rows describe a "Lake Oswego /
 * Clackamas County" representative; she represents Bend/Deschutes.
 * An empty compass is honest; a confabulated one is not.
 *
 * Snapshots every row to retired-partyprior-snapshot.json BEFORE deleting, so
 * this is reversible. Run with --apply to actually delete; default is a dry run.
 *
 *   node scripts/retire-bend-stateleg-partyprior.mjs            # dry run
 *   node scripts/retire-bend-stateleg-partyprior.mjs --apply
 */
import 'dotenv/config';
import { writeFileSync } from 'fs';
import { Pool } from 'pg';

const EXT = [-4120053, -4120054, -4110027];
const OUT = 'data/stance-research/or-bend-stateleg/retired-partyprior-snapshot.json';
const APPLY = process.argv.includes('--apply');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const { rows: snap } = await pool.query(
  `SELECT p.external_id, p.full_name, t.topic_key, pa.value,
          pc.reasoning, pc.sources
     FROM essentials.politicians p
     JOIN inform.politician_answers pa ON pa.politician_id = p.id
     JOIN inform.compass_topics t      ON t.id = pa.topic_id
     LEFT JOIN inform.politician_context pc
            ON pc.politician_id = p.id AND pc.topic_id = pa.topic_id
    WHERE p.external_id = ANY($1::bigint[])
    ORDER BY p.full_name, t.topic_key`, [EXT]);

writeFileSync(OUT, JSON.stringify({
  retired_at: new Date().toISOString(),
  reason: 'party-prior/pre-seating fabricated seed; see .planning/todos/2026-07-24-party-prior-stance-contamination-audit.md',
  rows: snap,
}, null, 2));
console.log(`Snapshot: ${snap.length} rows -> ${OUT}`);
for (const r of snap) console.log(`  ${r.full_name} / ${r.topic_key} = ${r.value}`);

const { rows: q } = await pool.query(
  `SELECT count(*)::int AS n FROM essentials.quotes q
     JOIN essentials.politicians p ON p.id = q.politician_id
    WHERE p.external_id = ANY($1::bigint[])`, [EXT]);
console.log(`Quotes attached to these three: ${q[0].n} (expected 0 — the seed produced none)`);

if (!APPLY) { console.log('\nDRY RUN — pass --apply to delete.'); await pool.end(); process.exit(0); }

await pool.query('BEGIN');
try {
  const ids = await pool.query(
    `SELECT id FROM essentials.politicians WHERE external_id = ANY($1::bigint[])`, [EXT]);
  const pids = ids.rows.map((r) => r.id);
  const ctx = await pool.query(
    `DELETE FROM inform.politician_context WHERE politician_id = ANY($1::uuid[])`, [pids]);
  const ans = await pool.query(
    `DELETE FROM inform.politician_answers WHERE politician_id = ANY($1::uuid[])`, [pids]);
  await pool.query('COMMIT');
  console.log(`COMMIT: deleted ${ans.rowCount} answers + ${ctx.rowCount} context rows.`);
} catch (e) {
  await pool.query('ROLLBACK');
  console.error('ROLLBACK:', e.message);
  process.exit(1);
}
await pool.end();
