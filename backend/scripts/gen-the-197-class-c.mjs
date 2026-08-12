#!/usr/bin/env node
/**
 * Class C of "the 197" — the Maryland TEMPLATE rows, re-sourced to the member's own bills.
 *
 * 🔑🔑 THE RESULT REVERSES THE PREMISE. These rows looked like the most obviously fabricated class in
 * the set: one sentence, filled in per legislator, over a Ballotpedia bio that never mentions the
 * topic. Building the full sponsor index shows the CLAIMS ARE TRUE — 35 of 47 members really did
 * co-sponsor the anti-discrimination and hate-crime legislation their row asserts. The template was
 * a bad way to write a true thing. Nothing here is retired.
 *
 * 🔴 WHY THE CACHED CORPUS COULD NOT ANSWER THIS. It indexes only the FIRST sponsor of each bill,
 * and every row claims CO-sponsorship. The bill page carries the whole list — "Sponsored by
 * Delegates A. Washington, Afzali, Branch, Clippinger …" — so 882 bill pages were fetched to build
 * a real reverse index (scripts/md-cr-sponsor-index.mjs).
 *
 * ⚠ EVERY CITED BILL PAGE WAS FETCHED AND PARSED to build the index, so no URL here is unvisited and
 * each one demonstrably carries this member's name in its sponsor list.
 *
 * ⚠ IDENTITY: mgaleg prints bare surnames. Where a surname is shared the initialled form is required
 * ("A. Washington" is Alonzo, "M. Washington" is Mary — a collision that already bit this workstream).
 *
 *   node scripts/gen-the-197-class-c.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const M = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-class-c-sponsor-match.json', 'utf8'));
const IDX = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-cr-sponsor-index.json', 'utf8'));
const slugOf = {};
for (const b of IDX.bills) slugOf[b.session + b.number] = b.slug;

// 🔑 Rank candidate bills by how SQUARELY on topic the title is, not merely whether it matched.
// The inclusion filter is deliberately loose; citation demands the tight one.
const CORE = {
  'Civil Rights and Social Justice': [
    /hate crime|hate-bias|antihate|antidiscrimination/i,
    /human relations|civil right|fair housing|public accommodation/i,
    /discrimination in (employment|housing|underwriting)|employment discrimination|housing discrimination/i,
    /reparation|lynching|definition of race/i,
    /discriminat/i,
  ],
  'Same-Sex Marriage': [/LGBTQ|sexual orientation|gender identity|conversion therapy|same-?sex/i],
  'Immigration and Treatment of Immigrants': [/sanctuary|immigration (enforcement|detainer)/i, /immigra/i],
  'Religious Freedom': [/religious (freedom|liberty|exercise|exemption)|conscience/i, /religio/i],
  'Transgender Athletes': [/transgender|gender identity/i],
};
const rank = (topic, title) => {
  const tiers = CORE[topic] || [];
  for (let i = 0; i < tiers.length; i++) if (tiers[i].test(title)) return i;
  return tiers.length;
};

/**
 * 🔴🔴 HOLD THE INVERTED ROWS. A separate defect surfaced while preparing this pass: some rows pair
 * plainly PRO-civil-rights reasoning with the ANTI pole of the scale. On this topic chair 5 is
 * "eliminate affirmative action and all race-based government programs", yet Alonzo Washington's row
 * reads "As an African American senator in PG County, he prioritizes racial justice" — at chair 5.
 * That is not a sourcing fault and re-sourcing would make it WORSE, because the citation would then
 * actively contradict the position on display. Held for a chair pass, untouched.
 */
const PRO_WORDED = /(champion|backs? |backed |supports? |supported |advocate|co-?sponsored|prioritizes racial justice)/i;
const ANTI_WORDED = /\boppos|against expansions|limiting|restrict/i;
// 🔴 SCOPED TO ONE TOPIC AT FIRST, AND THAT WAS WRONG. The check only looked at Civil Rights, so
// Sara Love / Same-Sex Marriage sailed through at CHAIR 5 — which on that scale reads "make same-sex
// marriage illegal" — with reasoning that says she supports it. The rule is not per-topic: on every
// one of these scales 1-2 is the PRO pole and 4-5 the ANTI pole, and a citation to bills the member
// CO-SPONSORED can only ever evidence a PRO chair. So no chair >= 4 may be re-sourced this way at
// all. That also catches Mary Beth Carozza, whose row is correctly anti but was about to be cited to
// hate-crime bills — one of them "Hate Crimes - Law Enforcement Officers", a police-protection bill
// that points the other way again.
const inverted = (r) => Number(r.answer_value) >= 4;

const held = M.rows.filter((r) => r.verdict === 'SPONSORED_ON_TOPIC' && inverted(r));
for (const h of held) console.log(`  HELD (chair/reasoning inverted): ${h.full_name} / ${h.topic} — chair ${h.answer_value}`);
const rows = M.rows.filter((r) => r.verdict === 'SPONSORED_ON_TOPIC' && !inverted(r));
const work = [];
for (const r of rows) {
  const picked = r.bills
    .map((b) => ({ ...b, score: rank(r.topic, b.title) }))
    .filter((b) => b.score < (CORE[r.topic] || []).length)   // drop anything only the loose filter liked
    .sort((a, b) => a.score - b.score || b.session.localeCompare(a.session))
    .slice(0, 3);
  if (!picked.length) { console.log(`  skip ${r.full_name} / ${r.topic} — no squarely on-topic bill after ranking`); continue; }
  const cites = picked.map((b) => {
    const slug = slugOf[b.session + b.number];
    if (!slug) throw new Error(`no slug for ${b.session} ${b.number}`);
    return `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${b.session}`;
  });
  const list = picked.map((b) => `${b.number} (${b.session.slice(0, 4)}) "${b.title}"`).join('; ');
  work.push({ ...r, picked, sources: cites,
    why: `Co-sponsored ${picked.length === 1 ? 'the following bill' : `${picked.length} bills`} in the Maryland General Assembly: ${list}. Maryland lists every sponsor on the bill page, and this member's name appears on each.` });
}
console.log(`\n${work.length} row(s) re-sourced`);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const rollback = [];
for (const w of work) {
  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id=c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id=c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.politician_id, w.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${w.full_name} / ${w.topic}, got ${got.length}`);
  if (got[0].full_name !== w.full_name || got[0].title !== w.topic) throw new Error(`identity mismatch ${got[0].full_name}`);
  rollback.push({ ...w, old_reasoning: got[0].reasoning, old_sources: got[0].sources, old_value: got[0].value });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'the-197 class C re-source', rows: rollback }, null, 1));

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- "The 197", class C — the Maryland TEMPLATE rows, re-sourced to each member's own bills.`);
L.push(`--`);
L.push(`-- 🔑🔑 THE RESULT REVERSES THE PREMISE. These looked like the most obviously fabricated rows in`);
L.push(`-- the set: one sentence, filled in per legislator ("X co-sponsored civil rights legislation`);
L.push(`-- including anti-discrimination protections — strong supporter of civil rights expansion in`);
L.push(`-- <County>"), over a Ballotpedia bio that never mentions the topic. THE CLAIMS ARE TRUE.`);
L.push(`-- ${work.length} rows are re-sourced to bills the member demonstrably co-sponsored.`);
L.push(`--`);
L.push(`-- 🔴🔴 ${held.length} FURTHER ROWS ARE HELD, NOT RE-SOURCED — a different defect. They pair plainly`);
L.push(`-- PRO-civil-rights reasoning with the ANTI pole: on this topic chair 5 is "eliminate affirmative`);
L.push(`-- action and all race-based government programs", yet Alonzo Washington's row reads "As an African`);
L.push(`-- American senator in PG County, he prioritizes racial justice" AT CHAIR 5. That is not a sourcing`);
L.push(`-- fault, and re-sourcing would make it WORSE: the citation would actively contradict the position`);
L.push(`-- on display. Corpus-wide this topic has 28 rows at chair 5 and 20 at chair 4 with pro-worded`);
L.push(`-- reasoning. Held for a chair pass: ${held.map(h=>h.full_name).join(', ')}.`);
L.push(`-- The template was a bad way to write a true thing. NOTHING IS RETIRED HERE.`);
L.push(`--`);
L.push(`-- 🔴 WHY THE CACHED CORPUS COULD NOT ANSWER THIS: it indexes only the FIRST sponsor of each`);
L.push(`-- bill, and every row claims CO-sponsorship. "Not in the corpus" would have been a false`);
L.push(`-- negative on all 47. Maryland puts the whole list on the bill page — "Sponsored by Delegates`);
L.push(`-- A. Washington, Afzali, Branch, Clippinger …" — so 882 bill pages were fetched to build a real`);
L.push(`-- reverse index. Every cited page was fetched and parsed; each demonstrably carries the name.`);
L.push(`--`);
L.push(`-- ⚠ IDENTITY: mgaleg prints bare surnames, so an initialled form is required where a surname is`);
L.push(`-- shared. "A. Washington" is Alonzo and "M. Washington" is Mary — a collision that has already`);
L.push(`-- produced a wrong answer in this workstream.`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE classc_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before;`);
L.push(``);
for (const w of work) {
  L.push(`-- ${w.full_name} / ${w.topic}  [${w.id_note}]`);
  L.push(`UPDATE inform.politician_context SET sources = ${arr(w.sources)}, reasoning = ${q(w.why)}`);
  L.push(`WHERE politician_id = ${q(w.politician_id)}::uuid AND topic_id = ${q(w.topic_id)}::uuid;`);
  L.push(``);
}
const ids = work.map((w) => `(${q(w.politician_id)}::uuid, ${q(w.topic_id)}::uuid)`).join(', ');
L.push(`-- Guard 1: every touched row cites mgaleg bill pages and no encyclopaedia.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM inform.politician_context c`);
L.push(`  WHERE (c.politician_id, c.topic_id) IN (${ids})`);
L.push(`    AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%')`);
L.push(`      OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%wikipedia.org%' OR s LIKE '%ballotpedia.org%'));`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) lack an mgaleg bill page or still cite an encyclopaedia', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: NOTHING created or deleted — this pass only rewrites citations.`);
L.push(`DO $$`);
L.push(`DECLARE ctx_after int; ans_after int; orphans int; snap record; n int;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM classc_snapshot;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  SELECT count(*) INTO n FROM inform.politician_context c WHERE (c.politician_id, c.topic_id) IN (${ids});`);
L.push(`  IF n <> ${work.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${work.length}', n; END IF;`);
L.push(`  RAISE NOTICE 'class C ok: context=% answers=% orphans=% (all unchanged)', ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}`);
console.log(`wrote ${ROLLBACK}`);
