#!/usr/bin/env node
/**
 * Pull the full DB record for the 197 Tier-B rows that scored
 * HAS_POSITIONS_SECTION + TOPIC_ABSENT, so they can be READ.
 *
 * 🔑 The coverage JSON carries only article + reasoning. Disposition needs the
 * chair value, every source on the row, and the quote — a row whose citation is
 * non-probative may still carry a verbatim quotation that names its evidence.
 *
 * 🔴 Reads only.
 *   node scripts/the-197-dump.mjs --out <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out', 'data/stance-retirement/2026-08-12-the-197.json');

const COV = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-11-tier-b-coverage.json', 'utf8'));
const target = COV.rows.filter((r) => r.verdict === 'HAS_POSITIONS_SECTION' && r.coverage === 'TOPIC_ABSENT');
const key = (a, b) => `${a}|${b}`;
const want = new Map(target.map((r) => [key(r.politician_id, r.topic_id), r]));
console.log(`target rows: ${target.length}`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const pids = [...new Set(target.map((r) => r.politician_id))];
const tids = [...new Set(target.map((r) => r.topic_id))];

const { rows } = await pool.query(`
  SELECT c.politician_id, c.topic_id, c.reasoning, c.sources,
         a.value AS answer_value, a.write_in_text,
         p.full_name, p.last_stances_researched_at,
         t.title AS topic, t.question_text
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a
         ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE c.politician_id = ANY($1::uuid[]) AND c.topic_id = ANY($2::uuid[])`, [pids, tids]);

const out = [];
for (const r of rows) {
  const m = want.get(key(r.politician_id, r.topic_id));
  if (!m) continue;
  out.push({ ...r, article: m.article, has_positions_section: m.has_positions_section });
}
console.log(`matched in DB: ${out.length}`);
await pool.end();

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'The 197 — HAS_POSITIONS_SECTION + TOPIC_ABSENT, full DB record',
  n: out.length, rows: out,
}, null, 1));
console.log(`wrote ${OUT}`);
