#!/usr/bin/env node
/**
 * Confirm the DB now matches migration 1710 EXACTLY — parsed out of the migration file, not retyped.
 *
 * 🔴 WHY: the migration was applied by pasting ~14k characters through a different channel than the
 * file on disk. "success: true" says the SQL ran, not that it was the SQL in the repo. Any drift
 * between the committed file and what production actually holds is exactly the kind of silent gap
 * this workstream keeps finding. So: parse the file, read the rows, compare byte for byte.
 */
import fs from 'node:fs';
import pg from 'pg';

const SQL = fs.readFileSync('migrations/1710_the197_federal_rollcall_resource.sql', 'utf8');
const want = [];
const re = /UPDATE inform\.politician_context SET sources = ARRAY\[([^\]]*)\]::text\[\], reasoning = '((?:[^']|'')*)'\s*\nWHERE politician_id = '([0-9a-f-]+)'::uuid AND topic_id = '([0-9a-f-]+)'::uuid;/g;
for (const m of SQL.matchAll(re)) {
  want.push({
    sources: m[1].split(',').map((s) => s.trim().replace(/^'|'$/g, '').replace(/''/g, "'")),
    reasoning: m[2].replace(/''/g, "'"),
    pid: m[3], tid: m[4],
  });
}
const chair = SQL.match(/UPDATE inform\.politician_answers SET value = (\d+)\s*\nWHERE politician_id = '([0-9a-f-]+)'::uuid AND topic_id = '([0-9a-f-]+)'::uuid/);
console.log(`parsed ${want.length} context update(s) + ${chair ? 1 : 0} chair update from the migration file`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

let bad = 0;
for (const w of want) {
  const { rows } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title
     FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id=c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id=c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.pid, w.tid]);
  if (rows.length !== 1) { console.log(`BAD  ${w.pid}: ${rows.length} rows`); bad++; continue; }
  const r = rows[0];
  const srcOk = JSON.stringify(r.sources) === JSON.stringify(w.sources);
  const reaOk = r.reasoning === w.reasoning;
  if (!srcOk || !reaOk) {
    bad++;
    console.log(`BAD  ${r.full_name} / ${r.title}`);
    if (!srcOk) console.log(`       sources   db=${JSON.stringify(r.sources)}\n                 sql=${JSON.stringify(w.sources)}`);
    if (!reaOk) console.log(`       reasoning db=${JSON.stringify(r.reasoning.slice(0, 90))}\n                 sql=${JSON.stringify(w.reasoning.slice(0, 90))}`);
  } else {
    console.log(`OK   ${r.full_name} / ${r.title} — chair ${r.value}, ${r.sources.length} source(s)`);
  }
}
if (chair) {
  const { rows } = await pool.query(
    'SELECT value FROM inform.politician_answers WHERE politician_id=$1::uuid AND topic_id=$2::uuid', [chair[2], chair[3]]);
  const ok = rows.length === 1 && Number(rows[0].value) === Number(chair[1]);
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'BAD '} chair correction -> ${chair[1]} (db has ${rows[0]?.value})`);
}

// Corpus-level check: this pass must not have created or destroyed anything.
const { rows: [t] } = await pool.query(
  `SELECT (SELECT count(*) FROM inform.politician_context) ctx,
          (SELECT count(*) FROM inform.politician_answers) ans,
          (SELECT count(*) FROM inform.politician_answers a WHERE NOT EXISTS (
             SELECT 1 FROM inform.politician_context c
             WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id)) orphans`);
console.log(`\ncorpus: context=${t.ctx} answers=${t.ans} orphans=${t.orphans}`);
await pool.end();
console.log(bad ? `\n🔴 ${bad} row(s) do NOT match the migration file` : '\n✅ production matches migration 1710 exactly');
process.exit(bad ? 1 : 0);
