#!/usr/bin/env node
/**
 * Confirm production matches migration 1711 — parsed out of the file, not retyped.
 * Re-sourced rows must match field for field; retired pairs must be GONE from both tables and
 * present in the rollback file, which is now their only surviving copy.
 */
import fs from 'node:fs';
import pg from 'pg';

const SQL = fs.readFileSync('migrations/1711_the197_class_b_absent_evidence.sql', 'utf8');
const RB = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-the-197-class-b-rollback.json', 'utf8')).rows;

const want = [];
const re = /UPDATE inform\.politician_context SET sources = ARRAY\[([^\]]*)\]::text\[\], reasoning = '((?:[^']|'')*)'\s*\nWHERE politician_id = '([0-9a-f-]+)'::uuid AND topic_id = '([0-9a-f-]+)'::uuid;/g;
for (const m of SQL.matchAll(re)) {
  want.push({ sources: m[1].split(',').map((s) => s.trim().replace(/^'|'$/g, '').replace(/''/g, "'")),
    reasoning: m[2].replace(/''/g, "'"), pid: m[3], tid: m[4] });
}
const retire = [...SQL.matchAll(/^\s*\('([0-9a-f-]{36})', '([0-9a-f-]{36})'\)[,;]/gm)].map((m) => ({ pid: m[1], tid: m[2] }));
console.log(`parsed ${want.length} re-source(s) and ${retire.length} retirement(s) from the migration file`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

let bad = 0;
for (const w of want) {
  const { rows } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id=c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id=c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.pid, w.tid]);
  const r = rows[0];
  const ok = rows.length === 1 && r.reasoning === w.reasoning && JSON.stringify(r.sources) === JSON.stringify(w.sources);
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'BAD '} re-sourced: ${r?.full_name} / ${r?.title} — chair ${r?.value}, ${r?.sources?.length} source(s)`);
}
for (const w of retire) {
  const { rows: [c] } = await pool.query('SELECT count(*)::int n FROM inform.politician_context WHERE politician_id=$1::uuid AND topic_id=$2::uuid', [w.pid, w.tid]);
  const { rows: [a] } = await pool.query('SELECT count(*)::int n FROM inform.politician_answers WHERE politician_id=$1::uuid AND topic_id=$2::uuid', [w.pid, w.tid]);
  const saved = RB.find((x) => x.pid === w.pid && x.tid === w.tid);
  const ok = c.n === 0 && a.n === 0 && saved && saved.old_reasoning;
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'BAD '} retired:    ${saved?.name} / ${saved?.topic} — ctx=${c.n} ans=${a.n}, rollback holds ${saved?.old_reasoning ? 'the reasoning' : 'NOTHING'}`);
}
// nobody emptied
const pids = [...new Set(retire.map((r) => r.pid))];
const { rows: left } = await pool.query(
  `SELECT p.full_name, (SELECT count(*)::int FROM inform.politician_answers a WHERE a.politician_id=p.id) n
   FROM essentials.politicians p WHERE p.id = ANY($1::uuid[]) ORDER BY 1`, [pids]);
for (const l of left) { if (l.n < 1) bad++; console.log(`${l.n > 0 ? 'OK  ' : 'BAD '} ${l.full_name} still has ${l.n} answer(s)`); }

const { rows: [t] } = await pool.query(
  `SELECT (SELECT count(*) FROM inform.politician_context) ctx,
          (SELECT count(*) FROM inform.politician_answers) ans,
          (SELECT count(*) FROM inform.politician_answers a WHERE NOT EXISTS (
             SELECT 1 FROM inform.politician_context c WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id)) orphans`);
console.log(`\ncorpus: context=${t.ctx} answers=${t.ans} orphans=${t.orphans}`);
await pool.end();
console.log(bad ? `\n🔴 ${bad} check(s) failed` : '\n✅ production matches migration 1711 exactly');
process.exit(bad ? 1 : 0);
