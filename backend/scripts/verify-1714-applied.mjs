#!/usr/bin/env node
/**
 * Confirm production matches migration 1714 — chair values AND the 18 re-sourced rows — parsed out
 * of the file rather than retyped.
 *
 * ⚠ Also re-runs the inversion test over the corrected rows: after the fix, NONE of them may still
 * sit at its topic's anti pole. A migration that ran is not a migration that worked.
 */
import fs from 'node:fs';
import pg from 'pg';

const SQL = fs.readFileSync('migrations/1714_chair_reasoning_inversion_fix.sql', 'utf8');
const SCAN = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-chair-inversion-scan.json', 'utf8'));
const dirOf = {}; for (const c of SCAN.calibration) if (c.dir) dirOf[c.topic_id] = c.dir;

const chairs = [...SQL.matchAll(/UPDATE inform\.politician_answers SET value = (\d+)\s*\nWHERE politician_id = '([0-9a-f-]+)'::uuid AND topic_id = '([0-9a-f-]+)'::uuid AND value = (\d+);/g)]
  .map((m) => ({ to: Number(m[1]), pid: m[2], tid: m[3], from: Number(m[4]) }));
const srcs = [...SQL.matchAll(/UPDATE inform\.politician_context SET sources = ARRAY\[([^\]]*)\]::text\[\], reasoning = '((?:[^']|'')*)'\s*\nWHERE politician_id = '([0-9a-f-]+)'::uuid AND topic_id = '([0-9a-f-]+)'::uuid;/g)]
  .map((m) => ({ sources: m[1].split(',').map((s) => s.trim().replace(/^'|'$/g, '').replace(/''/g, "'")),
    reasoning: m[2].replace(/''/g, "'"), pid: m[3], tid: m[4] }));
console.log(`parsed ${chairs.length} chair change(s) and ${srcs.length} re-source(s) from the file`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

let bad = 0, stillInverted = 0;
for (const c of chairs) {
  const { rows } = await pool.query(
    `SELECT a.value, p.full_name, t.title FROM inform.politician_answers a
     JOIN essentials.politicians p ON p.id=a.politician_id
     JOIN inform.compass_topics t ON t.id=a.topic_id
     WHERE a.politician_id=$1::uuid AND a.topic_id=$2::uuid`, [c.pid, c.tid]);
  const ok = rows.length === 1 && Number(rows[0].value) === c.to;
  if (!ok) { bad++; console.log(`BAD chair ${rows[0]?.full_name} / ${rows[0]?.title}: db=${rows[0]?.value} want=${c.to}`); continue; }
  // the point of the pass: it must no longer sit at the anti pole
  const d = dirOf[c.tid];
  if (d && ((d === 'LOW_IS_PRO' && c.to >= 4) || (d === 'HIGH_IS_PRO' && c.to <= 2))) {
    stillInverted++; console.log(`STILL INVERTED ${rows[0].full_name} / ${rows[0].title} at ${c.to}`);
  }
}
for (const s of srcs) {
  const { rows } = await pool.query(
    'SELECT reasoning, sources FROM inform.politician_context WHERE politician_id=$1::uuid AND topic_id=$2::uuid', [s.pid, s.tid]);
  const ok = rows.length === 1 && rows[0].reasoning === s.reasoning && JSON.stringify(rows[0].sources) === JSON.stringify(s.sources);
  if (!ok) { bad++; console.log(`BAD source row ${s.pid}`); }
}
const { rows: [t] } = await pool.query(
  `SELECT (SELECT count(*) FROM inform.politician_context) ctx,
          (SELECT count(*) FROM inform.politician_answers) ans,
          (SELECT count(*) FROM inform.politician_answers a WHERE NOT EXISTS (
             SELECT 1 FROM inform.politician_context c WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id)) orphans`);
await pool.end();
console.log(`\nchairs verified: ${chairs.length - bad}/${chairs.length} | re-sourced verified: ${srcs.length}`);
console.log(`still at the anti pole after the fix: ${stillInverted}`);
console.log(`corpus: context=${t.ctx} answers=${t.ans} orphans=${t.orphans}`);
console.log(bad || stillInverted ? '\n🔴 FAILED' : '\n✅ production matches migration 1714 and no corrected row remains inverted');
process.exit(bad || stillInverted ? 1 : 0);
