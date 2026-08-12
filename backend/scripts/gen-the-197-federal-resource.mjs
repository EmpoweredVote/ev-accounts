#!/usr/bin/env node
/**
 * Generate the re-sourcing migration for the federal rows inside "the 197" whose claim a recorded
 * roll call actually settles.
 *
 * 🔑 THE POINT OF THIS PASS: these rows were flagged because their only citation was an encyclopaedia
 * bio that never mentions the topic. That makes the CITATION bad — it says nothing about whether the
 * CLAIM is true. Twelve of them turned out to rest on real, recorded votes that nobody had looked up.
 * Re-sourcing beats retiring wherever the record carries the claim (precedent 1690/1692).
 *
 * ⚠ EVERY citation URL here was fetched and checked for its own content before being written — the
 * Clerk vote page for H.R.28 really does contain "Protection of Women and Girls in Sports" and
 * "Tran"; the Senate page for 115-2-271 really does contain "S. 756", "First Step" and "Risch".
 * A 200 is not identity confirmation.
 *
 * ⚠ NEAR-UNANIMOUS VOTES ARE MARKED, NOT GLOSSED. By the Lehman 130-1 rule a lopsided vote cannot
 * establish a DISTINCTIVE position; it can only verify that the member did what the row says. Rows
 * resting on one (Luria 368-57) say so in their own reasoning.
 *
 * 🔴 One row is a CHAIR CORRECTION, not a re-source: Lisa McClain / Ukraine. See the migration header.
 *
 *   node scripts/gen-the-197-federal-resource.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const VERDICTS = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-fed-vote-verdicts.json', 'utf8')).results;
// index the verified votes so no fact below is typed from memory
const V = {};
for (const r of VERDICTS) {
  if (r.status !== 'FOUND') continue;
  V[`${r.label}|${r.roll}`] = r;
  (V[r.label] ||= []).push(r);
}
const one = (label, roll) => {
  const r = roll ? V[`${label}|${roll}`] : (V[label] || [])[0];
  if (!r) throw new Error(`no verified verdict for ${label}${roll ? ' roll ' + roll : ''}`);
  return r;
};
const houseUrl = (r) => `https://clerk.house.gov/Votes/${r.year}${r.roll}`;
const senateUrl = (r) => `https://www.senate.gov/legislative/LIS/roll_call_lists/roll_call_vote_cfm.cfm?congress=${r.congress}&session=${r.sess}&vote=${String(r.roll).padStart(5, '0')}`;
const cite = (r) => (r.chamber === 'house' ? houseUrl(r) : senateUrl(r));

// ---------------------------------------------------------------------------------------------
// The worklist. `why` is written from the verified verdict, never from recollection: the tally and
// the member's own vote are interpolated from the verdict file so the sentence cannot drift.
// ---------------------------------------------------------------------------------------------
const W = [];
const add = (o) => W.push(o);

{ const r = one('Tran / Protection of Women and Girls in Sports Act');
  add({ name: 'Derek Tran', topic: 'Transgender Athletes',
    pid: 'b7612f49-c914-4ea7-a6da-559d71f313c2', tid: 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.28, the Protection of Women and Girls in Sports Act, on ${r.date} (roll call ${r.roll}, ${r.tally}). The bill would have barred transgender girls and women from female school athletic programs receiving federal funds; Tran voted against it.`,
    note: 'replaces caucus-membership inference with the recorded vote' }); }

{ const rp = one('Titus / Same-Sex Marriage (RFMA)', 373), rc = one('Titus / Same-Sex Marriage (RFMA)', 513);
  add({ name: 'Dina Titus', topic: 'Same-Sex Marriage',
    pid: '786af5d2-9502-401c-a3ed-61de88e589e9', tid: 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    sources: [cite(rp), cite(rc)],
    why: `Voted ${rp.member.vote.toUpperCase()} on H.R.8404, the Respect for Marriage Act, at House passage on ${rp.date} (roll call ${rp.roll}, ${rp.tally}) and ${rc.member.vote.toUpperCase()} again on the motion to concur in the Senate amendment on ${rc.date} (roll call ${rc.roll}, ${rc.tally}). The Act requires federal and interstate recognition of same-sex marriages.`,
    note: 'replaces caucus-membership inference with two recorded votes' }); }

{ const rp = one('McClain / Same-Sex Marriage (RFMA)', 373), rc = one('McClain / Same-Sex Marriage (RFMA)', 513);
  add({ name: 'Lisa C. McClain', topic: 'Same-Sex Marriage',
    pid: 'e04094d1-247c-40c8-8829-c7cb8654d0ed', tid: 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    sources: [cite(rp), cite(rc)],
    why: `Voted ${rp.member.vote.toUpperCase()} on H.R.8404, the Respect for Marriage Act, at House passage on ${rp.date} (roll call ${rp.roll}, ${rp.tally}) and ${rc.member.vote.toUpperCase()} again on the motion to concur in the Senate amendment on ${rc.date} (roll call ${rc.roll}, ${rc.tally}). The Act would require all states to recognise same-sex marriages. No record was found of her seeking to prohibit same-sex marriage or impose penalties.`,
    note: 'claim was already right; only the citation was an encyclopaedia bio' }); }

{ const r = one('Risch / First Step Act');
  add({ name: 'James Risch', topic: 'Jail Capacity and Incarceration Alternatives',
    pid: '9a41971c-1e38-41b8-a6ec-bec6055a00b3', tid: 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on S.756, the First Step Act, on 18 December 2018 (Senate roll call ${r.roll}, ${r.tally}). The Act reduced mandatory minimums and expanded earned-time credit and diversion for federal prisoners; Risch was one of the twelve senators opposing it.`,
    note: 'one of 12 nays — a lopsided vote, but being in the 12 is the distinctive fact' }); }

{ const rp = one('Ciscomani / One Big Beautiful Bill', 145), rc = one('Ciscomani / One Big Beautiful Bill', 190);
  add({ name: 'Juan Ciscomani', topic: 'Taxation and Public Spending',
    pid: 'c84bc9f3-6398-4d58-92b8-bbe6f6d1cdd3', tid: 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    sources: [cite(rp), cite(rc)],
    why: `Voted ${rp.member.vote.toUpperCase()} on H.R.1, the One Big Beautiful Bill Act, at House passage on ${rp.date} (roll call ${rp.roll}, ${rp.tally}) and again on the motion to concur in the Senate amendment on ${rc.date} (roll call ${rc.roll}, ${rc.tally}). The Act makes the 2017 individual tax rates permanent and adds further deductions, reducing federal revenue.`,
    note: 'both passage votes recorded; each was decided by a single-digit margin' }); }

{ const r = one('Finstad / Inflation Reduction Act');
  add({ name: 'Brad Finstad', topic: 'Healthcare Access',
    pid: 'dc0a717a-67ef-4ca2-9c43-4896fad03392', tid: 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.5376, the Inflation Reduction Act, on ${r.date} (roll call ${r.roll}, ${r.tally}). Its health provisions included Medicare drug-price negotiation and a three-year extension of the enhanced ACA premium subsidies.`,
    note: 'a vote against a package; it evidences opposition to those provisions, not a stated healthcare philosophy' }); }

{ const b = one('Torres / Build Back Better'), a = one('Torres / American Rescue Plan', 72);
  add({ name: 'Norma Torres', topic: 'Childcare Affordability & Access',
    pid: 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', tid: 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    sources: [cite(b), cite(a)],
    why: `Voted ${b.member.vote.toUpperCase()} on H.R.5376, the Build Back Better Act, on ${b.date} (roll call ${b.roll}, ${b.tally}), which carried universal pre-kindergarten and capped childcare costs as a share of family income, and ${a.member.vote.toUpperCase()} on H.R.1319, the American Rescue Plan Act, on ${a.date} (roll call ${a.roll}, ${a.tally}), which expanded the child and dependent care tax credit.`,
    note: 'both are omnibus votes; they evidence support for the packages containing childcare expansion' }); }

{ const c = one('Torres / CHIPS and Science Act'), i = one('Torres / Inflation Reduction Act'), j = one('Torres / IIJA', 369);
  add({ name: 'Norma Torres', topic: 'Economic Development Incentives',
    pid: 'e4d5cd69-0a54-48d6-9d8c-11da8f091cb6', tid: 'eb3d1247-0de1-4b7f-baec-7259861efd53',
    sources: [cite(c), cite(i), cite(j)],
    why: `Voted ${c.member.vote.toUpperCase()} on H.R.4346, the CHIPS and Science Act, on ${c.date} (roll call ${c.roll}, ${c.tally}); ${i.member.vote.toUpperCase()} on H.R.5376, the Inflation Reduction Act, on ${i.date} (roll call ${i.roll}, ${i.tally}); and ${j.member.vote.toUpperCase()} on H.R.3684, the Infrastructure Investment and Jobs Act, on ${j.date} (roll call ${j.roll}, ${j.tally}). All three direct targeted federal investment into named industries and infrastructure.`,
    note: 'IIJA cited at the concurrence vote that enacted it, not the earlier INVEST Act passage' }); }

{ const r = one('Luria / May-2022 Ukraine supplemental');
  add({ name: 'Elaine Luria', topic: 'Ukraine - Russia Conflict',
    pid: '2a22bd69-fd7a-4782-9057-4647fdb4e7cb', tid: '24e9212c-b011-422a-865c-093e35050901',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.7691, the Additional Ukraine Supplemental Appropriations Act, on ${r.date} (roll call ${r.roll}, ${r.tally}). The vote was lopsided, so it confirms that she supported the aid rather than distinguishing her from colleagues.`,
    note: 'near-unanimous 368-57 — stated in the reasoning rather than glossed' }); }

{ const r = one('Dusty Johnson / Apr-2024 Ukraine aid');
  add({ name: 'Dusty Johnson', topic: 'Ukraine - Russia Conflict',
    pid: '4ec42691-0ce1-4f29-a6ba-0835fe35a963', tid: '24e9212c-b011-422a-865c-093e35050901',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on ${r.date} (roll call ${r.roll}, ${r.tally}). Republicans split 101 yes to 112 no on that vote, so his yes was against the majority of his own conference.`,
    note: 'the 101-112 Republican split was counted off the roll-call sheet itself' }); }

{ const r = one('Larsen / Apr-2024 Ukraine aid');
  add({ name: 'Rick Larsen', topic: 'Ukraine - Russia Conflict',
    pid: '3a2bf7c8-5a49-4d53-88c4-0d4bc6ad17b0', tid: '24e9212c-b011-422a-865c-093e35050901',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on ${r.date} (roll call ${r.roll}, ${r.tally}).`,
    note: 'replaces a FiveThirtyEight presidential-alignment score, which is not a Ukraine position' }); }

{ const r = one('Mrvan / Apr-2024 Ukraine aid');
  add({ name: 'Frank J. Mrvan', topic: 'Ukraine - Russia Conflict',
    pid: 'e08ec276-3194-41d4-833b-953f27454857', tid: '24e9212c-b011-422a-865c-093e35050901',
    sources: [cite(r)],
    why: `Voted ${r.member.vote.toUpperCase()} on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on ${r.date} (roll call ${r.roll}, ${r.tally}).`,
    note: 'replaces a vote on Syria war powers, which is a different conflict' }); }

// 🔴 CHAIR CORRECTION — not a re-source.
const MC = (() => {
  const u = one('McClain / Apr-2024 Ukraine aid'), ll = one('McClain / Ukraine Lend-Lease');
  const p = one('McClain / 21st Century Peace through Strength Act'), il = one('McClain / Israel supplemental');
  return { name: 'Lisa C. McClain', topic: 'Ukraine - Russia Conflict',
    pid: 'e04094d1-247c-40c8-8829-c7cb8654d0ed', tid: '24e9212c-b011-422a-865c-093e35050901',
    from_value: 2, to_value: 4,
    // every bill the reasoning NAMES is cited — including the Israel supplemental, which an
    // earlier cut mentioned in the sentence but left out of the sources
    sources: [cite(u), cite(p), cite(il), cite(ll)],
    why: `Voted ${u.member.vote.toUpperCase()} on H.R.8035, the Ukraine Security Supplemental Appropriations Act, on ${u.date} (roll call ${u.roll}, ${u.tally}) — the April 2024 bill that funded continued military assistance to Ukraine. On the same day she voted ${p.member.vote.toUpperCase()} on H.R.8038, the 21st Century Peace through Strength Act (roll call ${p.roll}, ${p.tally}), and ${il.member.vote.toUpperCase()} on H.R.8034, the Israel Security Supplemental (roll call ${il.roll}, ${il.tally}), so she supported the other bills in that package while opposing the Ukraine appropriation specifically. She had earlier voted ${ll.member.vote.toUpperCase()} on S.3522, the Ukraine Democracy Defense Lend-Lease Act (roll call ${ll.roll}, ${ll.tally}), a near-unanimous vote that does not distinguish her position.`,
    note: 'stored reasoning asserted she "supported the 2024 Ukraine-Israel-Taiwan foreign aid package (360-58)"; 360-58 is H.R.8038, and her vote on the Ukraine bill itself was NAY' };
})();

// ---------------------------------------------------------------------------------------------
const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const all = [...W, MC];
const rollback = [];
for (const w of all) {
  const { rows } = await pool.query(
    `SELECT c.politician_id, c.topic_id, c.reasoning, c.sources, a.value, p.full_name, t.title
     FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id = c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [w.pid, w.tid]);
  if (rows.length !== 1) throw new Error(`expected exactly 1 row for ${w.name} / ${w.topic}, got ${rows.length}`);
  const r = rows[0];
  if (r.full_name !== w.name || r.title !== w.topic) throw new Error(`identity mismatch: ${r.full_name} / ${r.title} != ${w.name} / ${w.topic}`);
  if (w.from_value !== undefined && Number(r.value) !== w.from_value) throw new Error(`${w.name}: expected stored chair ${w.from_value}, found ${r.value}`);
  rollback.push({ ...w, old_reasoning: r.reasoning, old_sources: r.sources, old_value: r.value });
}
await pool.end();
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'the-197 federal re-source', rows: rollback }, null, 1));

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- "The 197" — Tier B rows whose only citation was an encyclopaedia bio that never mentions the`);
L.push(`-- topic. Twelve of them rest on a RECORDED VOTE nobody had looked up, so they are re-sourced`);
L.push(`-- rather than retired. One is a chair correction.`);
L.push(`--`);
L.push(`-- 🔑 A BAD CITATION IS NOT A FALSE CLAIM. The Tier B cut measured the SOURCE, not the truth of`);
L.push(`-- the sentence. Reading each row and looking for the evidence elsewhere turned a putative`);
L.push(`-- retirement queue into twelve properly sourced rows (precedent 1690/1692).`);
L.push(`--`);
L.push(`-- ⚠ Every citation URL below was fetched and checked for its own content before being written.`);
L.push(`-- The Clerk page for H.R.28 contains "Protection of Women and Girls in Sports" and "Tran"; the`);
L.push(`-- Senate page for 115-2-271 contains "S. 756", "First Step" and "Risch". A 200 is not identity.`);
L.push(`--`);
L.push(`-- ⚠ Roll numbers came from the Clerk's own year index, never from recall. H.R.7691's passage`);
L.push(`-- vote is 2022 roll 145; the remembered guess was 209. Matching on the bill number alone also`);
L.push(`-- is not enough — it first selected an AMENDMENT to H.R.8035 (105-319) and reported it as the`);
L.push(`-- Ukraine aid vote (311-112). Bill number AND passage-shaped question, and every matching roll`);
L.push(`-- evaluated, because H.R.8404 has two (267-157 in July, 258-169 in December).`);
L.push(`--`);
L.push(`-- 🔴 CHAIR CORRECTION, ${MC.name} / ${MC.topic}: ${MC.from_value} -> ${MC.to_value}.`);
L.push(`-- ${MC.note}.`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE the197_fed_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before;`);
L.push(``);
for (const w of all) {
  L.push(`-- ${w.name} / ${w.topic}`);
  L.push(`--   ${w.note}`);
  L.push(`UPDATE inform.politician_context SET sources = ${arr(w.sources)}, reasoning = ${q(w.why)}`);
  L.push(`WHERE politician_id = ${q(w.pid)}::uuid AND topic_id = ${q(w.tid)}::uuid;`);
  if (w.to_value !== undefined) {
    L.push(`UPDATE inform.politician_answers SET value = ${w.to_value}`);
    L.push(`WHERE politician_id = ${q(w.pid)}::uuid AND topic_id = ${q(w.tid)}::uuid AND value = ${w.from_value};`);
  }
  L.push(``);
}
const ids = all.map((w) => `(${q(w.pid)}::uuid, ${q(w.tid)}::uuid)`).join(', ');
L.push(`-- Guard 1: every touched row must now cite a roll-call page and NO encyclopaedia article.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM inform.politician_context c`);
L.push(`  WHERE (c.politician_id, c.topic_id) IN (${ids})`);
L.push(`    AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%clerk.house.gov/Votes/%' OR s LIKE '%senate.gov/legislative/LIS/roll_call_lists/%')`);
L.push(`      OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%wikipedia.org%' OR s LIKE '%ballotpedia.org%'));`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) lack a roll call or still cite an encyclopaedia', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${all.length} rows touched, and the one chair change is the one intended.`);
L.push(`DO $$`);
L.push(`DECLARE n int; v numeric;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO n FROM inform.politician_context c WHERE (c.politician_id, c.topic_id) IN (${ids});`);
L.push(`  IF n <> ${all.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${all.length}', n; END IF;`);
L.push(`  SELECT a.value INTO v FROM inform.politician_answers a`);
L.push(`   WHERE a.politician_id = ${q(MC.pid)}::uuid AND a.topic_id = ${q(MC.tid)}::uuid;`);
L.push(`  IF v <> ${MC.to_value} THEN RAISE EXCEPTION 'guard 2 failed: McClain/Ukraine chair is %, expected ${MC.to_value}', v; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 3: citations and one chair value only — nothing created or deleted.`);
L.push(`DO $$`);
L.push(`DECLARE ctx_after int; ans_after int; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM the197_fed_snapshot;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 3 failed: context rows moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 3 failed: answer rows moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 3 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  RAISE NOTICE 'the-197 federal ok: context=% (unchanged) answers=% (unchanged) orphans=%', ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);

fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT} (${all.length} rows: ${W.length} re-sourced, 1 chair correction)`);
console.log(`wrote ${ROLLBACK}`);
