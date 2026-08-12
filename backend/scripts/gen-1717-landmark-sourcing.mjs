#!/usr/bin/env node
/**
 * Migration 1717 — SOURCE the landmark-act half of the rows migration 1714 corrected.
 *
 * 1714 fixed 89 inverted chairs but could only re-source 18 of them, leaving 71 rows whose chair is
 * right and whose citation is not. 23 of those 71 name a landmark act — the Blueprint for Maryland's
 * Future or the Climate Solutions Now Act — and this pass resolves each act once and tests every
 * member against its sponsor list and its passage roll calls.
 *
 * 🔑 THE CHAIRS ARE NOT TOUCHED. This migration writes reasoning and sources only.
 *
 * 🔑 SOURCES ARE ADDED, NOT SWAPPED. The encyclopaedia bios already on these rows were never checked
 * against the claim, and the standing rule is that a citation verified NOT to carry a claim may be
 * dropped while an unchecked one may not. Every new primary citation is prepended; nothing is removed.
 *
 * 🔴 WHAT READING THE EVIDENCE CHANGED, twice over:
 *   · TWO ROWS WERE PRE-TENURE. Kevin M. Harris (House 2023-2025, Senate from December 2025) and
 *     C. Anthony Muse (Senate 2007-2019, then from 2023) are both credited with backing an Act passed
 *     in 2021 and 2022, while neither sat in the legislature. Retirement is what is left after looking,
 *     so both were re-sourced to real in-tenure clean-energy sponsorships instead.
 *   · A NEAR-UNANIMOUS VOTE IS NOT A POSITION. SB1030/2019 passed the Senate 43-1 and then 45-0. Those
 *     sheets are recorded and deliberately NOT cited; every vote cited here had at least 10% of those
 *     voting against it.
 *
 * 🔴 THREE IDENTITY TRAPS WERE LIVE IN THIS SET and each would have published a false claim:
 *   · SB0528 and SB0414 are SENATE bills, so their "Washington" is Senator MARY Washington
 *     (`washington01`) — not our Delegate Alonzo T. Washington (`washington02`). The bill page's own
 *     sponsor hyperlink settles it where a surname cannot.
 *   · Ron Watson joined the Senate on 31 August 2021, months AFTER the 2021 session adjourned, so his
 *     2021 votes are HOUSE votes. A January-swearing-in assumption put him in the wrong chamber.
 *   · Sara Love's mgaleg page states her tenure as "Senate since June 13, 2024" and omits her House
 *     service entirely, though the corpus records "Delegate Love" sponsoring from 2019RS. Trusting the
 *     page put her whole Blueprint-era service outside her tenure and the test silently never ran.
 *
 *   node scripts/gen-1717-landmark-sourcing.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const D = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-landmark-disposition.json', 'utf8'));
const work = D.rows.filter((r) => ['SPONSOR', 'VOTE', 'RESOURCED_PRETENURE'].includes(r.verdict));
const skipped = D.rows.filter((r) => !['SPONSOR', 'VOTE', 'RESOURCED_PRETENURE'].includes(r.verdict));
if (skipped.length) {
  // 🔑 no silent caps: anything not carried is named, not quietly dropped
  console.log(`NOT INCLUDED (${skipped.length}):`);
  for (const s of skipped) console.log(`  [${s.verdict}] ${s.name} / ${s.topic}`);
}

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const rollback = [], updates = [];
for (const r of work) {
  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title
       FROM inform.politician_context c
       JOIN essentials.politicians p ON p.id = c.politician_id
       LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
       LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
      WHERE c.politician_id = $1::uuid AND c.topic_id = $2::uuid`, [r.politician_id, r.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${r.name}/${r.topic}, got ${got.length}`);
  const live = got[0];
  if (live.full_name !== r.name || live.title !== r.topic) throw new Error(`identity mismatch for ${r.name}/${r.topic}`);
  // 🔑 the row must still say what the scan read, or the disposition is stale
  if (live.reasoning !== r.old_reasoning) throw new Error(`reasoning changed since the scan for ${r.name}/${r.topic}`);
  if (Number(live.value) !== Number(r.chair)) throw new Error(`chair moved since the scan for ${r.name}/${r.topic}: ${live.value} vs ${r.chair}`);

  const old = live.sources || [];
  const sources = [...r.evidence_sources, ...old.filter((s) => !r.evidence_sources.includes(s))];
  updates.push({ ...r, new_sources: sources, new_reasoning: r.evidence_clause });
  rollback.push({ politician_id: r.politician_id, topic_id: r.topic_id, name: r.name, topic: r.topic,
    old_reasoning: live.reasoning, old_sources: old, chair_untouched: Number(live.value) });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'landmark-act sourcing (1717)', rows: rollback }, null, 1));

const byVerdict = updates.reduce((m, u) => { m[u.verdict] = (m[u.verdict] || 0) + 1; return m; }, {});
console.log(`\n${updates.length} row(s): ${JSON.stringify(byVerdict)}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- LANDMARK-ACT SOURCING for 23 of the 71 rows migration 1714 corrected but could not re-source.`);
L.push(`--`);
L.push(`-- 1714 fixed 89 chairs that sat at the OPPOSITE POLE from their own reasoning. It could only`);
L.push(`-- re-source 18 of them, because only Civil Rights and Same-Sex Marriage bills had been crawled.`);
L.push(`-- These 23 rows name a landmark act outright — the Blueprint for Maryland's Future (11) or the`);
L.push(`-- Climate Solutions Now Act (12) — so each act was resolved ONCE and every member tested against`);
L.push(`-- its full sponsor list and its passage roll calls.`);
L.push(`--`);
L.push(`-- 🔑 CHAIRS ARE NOT TOUCHED. Reasoning and sources only; inform.politician_answers is untouched.`);
L.push(`--`);
L.push(`-- 🔑 SOURCES ARE ADDED, NOT SWAPPED. The encyclopaedia bios on these rows were never checked`);
L.push(`-- against the claim. A citation VERIFIED not to carry a claim may be dropped; an unchecked one`);
L.push(`-- may not, so every primary citation is prepended and nothing is removed.`);
L.push(`--`);
L.push(`-- ⚠ TWO ROWS WERE PRE-TENURE — the claim could not be true:`);
L.push(`--   Kevin M. Harris  (House 2023-2025, Senate from Dec 2025) credited with the 2021/2022 Act`);
L.push(`--   C. Anthony Muse  (Senate 2007-2019, then from 2023) — the Act falls squarely in his gap`);
L.push(`-- Retirement is what is left AFTER looking, so both were re-sourced to real in-tenure clean-energy`);
L.push(`-- sponsorships (Harris SB0669/SB0923 2026; Muse SB0120 2025, Chapter 516) rather than retired.`);
L.push(`--`);
L.push(`-- ⚠ A NEAR-UNANIMOUS VOTE IS NOT A POSITION. SB1030/2019 passed the Senate 43-1 and then 45-0;`);
L.push(`-- those sheets are deliberately NOT cited. Every vote cited here had >=10% voting against.`);
L.push(`--`);
L.push(`-- 🔴 THREE IDENTITY TRAPS WERE LIVE IN THIS SET, each of which would have published a false claim:`);
L.push(`--   · SB0528/SB0414 are SENATE bills, so their "Washington" is Senator MARY Washington`);
L.push(`--     (washington01), not Delegate Alonzo T. Washington (washington02). The sponsor HYPERLINK`);
L.push(`--     settles identity where a surname cannot — but a retired slug proves nothing, so HB1300's`);
L.push(`--     now-dead 'washington' link falls back to surname plus the chamber gate.`);
L.push(`--   · Ron Watson joined the Senate on 31 Aug 2021, AFTER the 2021 session adjourned, so his 2021`);
L.push(`--     votes are HOUSE votes; assuming a January swearing-in put him in the wrong chamber.`);
L.push(`--   · Sara Love's mgaleg tenure field omits her House service entirely, so her whole Blueprint-era`);
L.push(`--     record fell outside her tenure and the test silently never ran.`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE lm_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before,`);
L.push(`       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;`);
L.push(``);
// 🔑 ONE SOURCE OF TRUTH. The intended values are stated once, in a temp table; the UPDATE reads from
// it and the guard checks the write against it. Spelling each reasoning string out twice — once to
// write, once to verify — is not an independent check, it is the same text pasted twice, and it made
// the migration twice the size for no extra safety.
L.push(`CREATE TEMP TABLE lm_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;`);
L.push(`INSERT INTO lm_intent (pid, tid, reasoning, sources) VALUES`);
updates.forEach((u, i) => {
  L.push(`-- ${u.name} / ${u.topic} — ${u.verdict}${u.sponsor_on ? ` (sponsor: ${u.sponsor_on})` : ''}${u.vote_on ? ` (vote: ${u.vote_on})` : ''}`);
  L.push(`(${q(u.politician_id)}, ${q(u.topic_id)}, ${q(u.new_reasoning)}, ${arr(u.new_sources)})${i === updates.length - 1 ? ';' : ','}`);
});
L.push(``);
L.push(`UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources`);
L.push(`FROM lm_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;`);
L.push(``);
L.push(`-- Guard 1: every targeted row now holds its intended reasoning, and carries a primary citation.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM lm_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid`);
L.push(`  WHERE c.reasoning IS DISTINCT FROM i.reasoning`);
L.push(`     OR c.sources IS DISTINCT FROM i.sources`);
L.push(`     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov%');`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${updates.length} rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM lm_snapshot;`);
L.push(`  SELECT count(*) INTO n FROM lm_intent i`);
L.push(`  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;`);
L.push(`  IF n <> ${updates.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${updates.length}', n; END IF;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  -- this pass must not move a single chair; 1714 already set them`);
L.push(`  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  RAISE NOTICE 'landmark sourcing ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}\nwrote ${ROLLBACK}`);
