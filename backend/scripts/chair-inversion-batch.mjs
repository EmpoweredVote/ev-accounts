#!/usr/bin/env node
/**
 * Is the chair inversion scattered noise, or ONE BAD BATCH?
 *
 * 🔑 THE HYPOTHESIS, from reading: a research run wrote the chair as an INTENSITY rating — 5 meaning
 * "strongly holds this view" — instead of selecting one of five discrete policy OPTIONS. Sara Love
 * has 19 rows, every one with plainly pro-progressive reasoning, sitting at chair 5 on Civil Rights
 * ("eliminate affirmative action"), Same-Sex Marriage ("make same-sex marriage illegal"), Healthcare,
 * Childcare, Climate, Reproductive Rights and Voting Rights. That is not a per-row slip.
 * This is precisely the failure the standing rule warns about: chairs are 1-5 DISCRETE OPTIONS, not
 * a strength scale and not a left-right axis.
 *
 * 🔑 THE TELL that separates a flipped batch from a genuine conservative: a real conservative's
 * reasoning is ANTI-worded. A flipped row is PRO-worded at the ANTI pole, and the same politician
 * shows it across MANY topics at once.
 *
 * 🔴 Reads only.
 *   node scripts/chair-inversion-batch.mjs
 */
import fs from 'node:fs';
import pg from 'pg';

const SCAN = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-chair-inversion-scan.json', 'utf8'));
const dirOf = {};
for (const c of SCAN.calibration) if (c.dir) dirOf[c.topic_id] = c.dir;

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(
  `SELECT c.politician_id, c.topic_id, t.title AS topic, a.value, c.reasoning, c.sources, p.full_name
   FROM inform.politician_context c
   JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
   JOIN essentials.politicians p ON p.id=c.politician_id
   JOIN inform.compass_topics t ON t.id=c.topic_id`);
await pool.end();

const PRO = /\b(supports?|supported|champions?|championed|backs?|backed|advocat\w*|co-?sponsored|prioriti[sz]es)\b/i;
const RESTRICT = /\b(against|oppos\w*|block\w*|roll ?back|repeal\w*|defund\w*|rescind\w*|cut\w*|restrict\w*|limit\w*|prohibit\w*|\bban\w*|reduc\w*|eliminat\w*|reject\w*|not\b|never\b|no\b)/i;
const cleanPro = (t) => PRO.test(t || '') && !RESTRICT.test(t || '');

const byPol = {};
for (const r of rows) {
  const d = dirOf[r.topic_id];
  if (!d) continue;                       // only calibrated topics can say anything
  const v = Number(r.value);
  const atAntiPole = d === 'LOW_IS_PRO' ? v >= 4 : v <= 2;
  const p = (byPol[r.politician_id] ||= { name: r.full_name, calibrated: 0, proRows: 0, inverted: 0, topics: [] });
  p.calibrated++;
  if (cleanPro(r.reasoning)) {
    p.proRows++;
    if (atAntiPole) { p.inverted++; p.topics.push(`${r.topic} c${v}`); }
  }
}
const suspects = Object.entries(byPol)
  .map(([id, p]) => ({ id, ...p, rate: p.proRows ? p.inverted / p.proRows : 0 }))
  .filter((p) => p.inverted >= 3 && p.rate >= 0.6)
  .sort((a, b) => b.inverted - a.inverted);

console.log(`politicians with >=3 inverted rows and >=60% of their pro-worded rows inverted: ${suspects.length}`);
console.log(`total inverted rows held by them: ${suspects.reduce((s, p) => s + p.inverted, 0)}\n`);
console.log('inv/pro  name                      topics');
for (const p of suspects) console.log(`${String(p.inverted).padStart(3)}/${String(p.proRows).padEnd(3)}  ${p.name.padEnd(24)}  ${p.topics.slice(0, 4).map((t) => t.replace(/ and .*| & .*|Affordability.*|and Environmental.*/, '')).join(', ')}`);

// Which sources do the suspect rows carry? A single research run tends to leave one signature.
const suspectIds = new Set(suspects.map((s) => s.id));
const hosts = {};
for (const r of rows) {
  if (!suspectIds.has(r.politician_id)) continue;
  for (const s of r.sources || []) { try { hosts[new URL(s).hostname] = (hosts[new URL(s).hostname] || 0) + 1; } catch {} }
}
console.log('\nsource hosts across the suspect politicians\' rows:');
for (const [h, n] of Object.entries(hosts).sort((a, b) => b[1] - a[1]).slice(0, 10)) console.log(`  ${String(n).padStart(5)}  ${h}`);

fs.writeFileSync('data/stance-retirement/2026-08-12-chair-inversion-batch.json',
  JSON.stringify({ pass: 'is the chair inversion one batch?', n_suspects: suspects.length, suspects }, null, 1));
console.log('\nwrote data/stance-retirement/2026-08-12-chair-inversion-batch.json');
