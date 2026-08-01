#!/usr/bin/env node
/**
 * Emit migrations 1516 (correct 4 published rows) and 1517 (retire 5 unsupported rows), from the
 * hand-review of the tail cohort. Every replacement string below was written against the live cited
 * page, and the evidence is quoted in each migration's header.
 *
 * Usage (from backend/):  node scripts/emit-1516-1517.mjs
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const plan = JSON.parse(readFileSync('C:/Users/Chris/AppData/Local/Temp/plan11.json', 'utf8'));
const pick = (g, n, t) => plan[g].find((r) => r.name.includes(n) && r.topic === t);
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

// ---------------------------------------------------------------- 1516: corrections
const CORRECT = [
  {
    row: pick('fix', 'Miller-Watkins', 'Voting Rights'),
    why: 'quote compressed two separate sentences into one quotation',
    reasoning:
      "Platform commits to 'protect voting rights, increase civic participation, strengthen faith in our "
      + "elections and ensure government remains accountable to the people,' and she describes herself as "
      + "'a strong supporter of the John Lewis Voting Rights Act,' an expansive federal ballot-access and "
      + 'anti-discrimination measure. That places her at the more access-expanding end of the spectrum, '
      + 'absent an explicit automatic-registration or online-voting pledge.',
    sources: null,
  },
  {
    row: pick('fix', 'Baucom', 'Taxes'),
    why: 'reasoning claimed the survey could not be retrieved; it is on the cited page verbatim',
    reasoning:
      "In his Ballotpedia Candidate Connection survey Baucom writes that 'income and property taxes are "
      + "unconstitutional and reprehensible' and that 'the full abolition of the IRS is the only proper step "
      + "forward in American liberation.' He lists taxation and deregulation among the policy areas he is "
      + 'most passionate about. That is a drastically-cut-taxes and shrink-government position.',
    sources: null,
  },
  {
    row: pick('fix', 'Bryan', 'Housing'),
    why: 'removes an unsourced quotation; adds the bill the claim actually rests on',
    reasoning:
      'Bryan authored AB 1685 (2021-22), which relieves parking-ticket debt for unhoused people living in '
      + 'their vehicles, and has introduced legislation extending homelessness mandates to large California '
      + 'jurisdictions. That record reflects public investment in housing and rental assistance, consistent '
      + 'with stance 2 — publicly funded housing plus requirements that new developments include affordable '
      + 'units. He has not advocated government directly building and operating public housing as in stance 1.',
    sources: (cur) => [...cur, 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB1685'],
  },
  {
    row: pick('fix', 'Werner', 'Housing'),
    why: 'adds the bill the claim rests on; SB1729 confirmed as hers at azleg',
    reasoning: null,
    sources: (cur) => [...cur, 'https://www.azleg.gov/legtext/57leg/1R/bills/sb1729p.htm'],
  },
];

// ---------------------------------------------------------------- 1517: retirements
const RETIRE = [
  { row: pick('retire', 'Bryan', 'Religious Freedom'), why: 'reasoning states no legislation or on-record statement was found' },
  { row: pick('retire', 'Mitchell', 'Religious Freedom'), why: 'reasoning states no specific legislation was identified' },
  { row: pick('retire', 'Mitchell', 'Campaign Finance'), why: 'reasoning states no specific bill was identified; inference from caucus alignment' },
  { row: pick('retire', 'Mitchell', 'Redistricting'), why: 'cited page mentions redistricting only as the reason her district changed in 2012 — not a position' },
  { row: pick('retire', 'Harding', 'Taxes'), why: 'cited page contains no tax-cut pledge at all; "cut taxes" was inserted into a pledge about wasteful spending' },
];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const all = [...CORRECT, ...RETIRE].map((x) => x.row);
const { rows: live } = await pool.query(
  `SELECT politician_id::text AS pid, topic_id::text AS tid, reasoning, sources
     FROM inform.politician_context
    WHERE (politician_id::text, topic_id::text) IN (${all.map((r) => `(${q(r.pid)},${q(r.tid)})`).join(',')})`,
);
await pool.end();
const byKey = new Map(live.map((r) => [`${r.pid}|${r.tid}`, r]));
if (byKey.size !== all.length) { console.error(`REFUSING: expected ${all.length} live rows, found ${byKey.size}`); process.exit(1); }

writeFileSync('data/stance-retirement/2026-08-01-tail-corrections-rollback.json', `${JSON.stringify({
  _comment: 'Rollback record for migrations 1516 (corrections) and 1517 (retirements). `before` is the '
    + 'exact prod state at generation time. 1517 deletes rows outright, so this file is the only copy of '
    + 'their reasoning and sources.',
  corrections: CORRECT.map((c) => ({
    pid: c.row.pid, tid: c.row.tid, name: c.row.name, topic: c.row.topic, why: c.why,
    before: byKey.get(`${c.row.pid}|${c.row.tid}`),
    after_reasoning: c.reasoning, after_sources: c.sources ? c.sources(byKey.get(`${c.row.pid}|${c.row.tid}`).sources) : null,
  })),
  retirements: RETIRE.map((r) => ({
    pid: r.row.pid, tid: r.row.tid, name: r.row.name, topic: r.row.topic, value: r.row.value, why: r.why,
    before: byKey.get(`${r.row.pid}|${r.row.tid}`),
  })),
}, null, 2)}\n`);

const stmts = CORRECT.map((c) => {
  const cur = byKey.get(`${c.row.pid}|${c.row.tid}`);
  const sets = [];
  if (c.reasoning) sets.push(`reasoning = ${q(c.reasoning)}`);
  if (c.sources) sets.push(`sources = ARRAY[${c.sources(cur.sources).map(q).join(', ')}]`);
  return `-- ${c.row.name} / ${c.row.topic}: ${c.why}\nUPDATE inform.politician_context SET ${sets.join(', ')}\n WHERE politician_id = ${q(c.row.pid)} AND topic_id = ${q(c.row.tid)};`;
}).join('\n\n');

writeFileSync('migrations/1516_correct_tail_cohort_reasoning.sql', `-- 1516_correct_tail_cohort_reasoning.sql
--
-- Correct 4 published stance rows whose reasoning misstated what the cited page says. NOTHING IS
-- RETIRED HERE and no stance VALUE changes -- only the text a voter reads and the sources it rests on.
--   Rollback record: data/stance-retirement/2026-08-01-tail-corrections-rollback.json
--   Review:          data/stance-retirement/2026-08-01-tail-hand-review.md
--
-- WHY THIS MATTERS MORE THAN THE GATE COUNTS. inform.politician_context.reasoning is VOTER-FACING --
-- Citations.jsx renders it under "Why this position?" and the compass card shows it in the stance
-- accordion. A quotation mark around words the source never said is a fabricated quote on a live
-- profile, regardless of whether the underlying stance is correct.
--
-- Civil Miller-Watkins: the row quoted "protect voting rights and election integrity". Her page says
--   "I will work to protect voting rights, increase civic participation, strengthen faith in our
--   elections and ensure government remains accountable to the people" -- two separate commitments
--   compressed into one quotation that appears nowhere. Replaced with the verbatim sentence, plus her
--   actual words on the John Lewis Voting Rights Act.
--
-- Johnny Baucom: the row said his survey "could not be directly retrieved (repeated access block), so
--   no verbatim quote is available". It retrieves fine, and it is far more specific than the
--   paraphrase: "income and property taxes are unconstitutional and reprehensible" and "the full
--   abolition of the IRS is the only proper step forward in American liberation". The stance value is
--   unchanged and the page supports it more strongly than the old text did.
--
-- Isaac Bryan: the row quoted "The solution to homelessness is housing." That sentence is not on the
--   cited page and no source for it was found, so it is REMOVED rather than re-attributed. AB 1685 is
--   confirmed his at leginfo -- "Assembly Bill No. 1685 Introduced by Assembly Member Bryan ...
--   Vehicles: parking violations" -- and is added as a source.
--
-- Carine Werner: SB1729 confirmed hers at azleg -- "REFERENCE TITLE: first-time homebuyer assistance
--   program ... Introduced by Senators Werner: Angius". Source added; reasoning already accurate.
--
-- 🔴 JARRETT KEOHOKALOLE WAS DROPPED FROM THIS MIGRATION. His row asserts he sponsored HI HB489 (2015).
-- The bill is real and its mechanism matches exactly -- it registers to vote everyone applying for a
-- driver's licence "unless that person affirmatively declines" -- but his NAME APPEARS NOWHERE in the
-- measure's 53,000-character status page, and the bill document's INTRODUCED BY line is a blank
-- signature placeholder. Adding a citation to a sponsorship the record does not show would lend the
-- row false authority, which is the exact failure this whole workstream exists to undo. Left for a
-- human with the evidence recorded.

BEGIN;

${stmts}

DO $$
DECLARE
  v_bad int;
BEGIN
  -- The removed Bryan quotation must not survive anywhere in the corrected text.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = ${q(CORRECT[2].row.pid)} AND topic_id = ${q(CORRECT[2].row.tid)}
     AND reasoning ILIKE '%solution to homelessness is housing%';
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'Bryan row still carries the unsourced quotation';
  END IF;

  -- Both bill citations must be present.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = ${q(CORRECT[2].row.pid)} AND topic_id = ${q(CORRECT[2].row.tid)}
     AND NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%leginfo.legislature.ca.gov%');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Bryan row missing the AB 1685 citation'; END IF;

  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = ${q(CORRECT[3].row.pid)} AND topic_id = ${q(CORRECT[3].row.tid)}
     AND NOT EXISTS (SELECT 1 FROM unnest(sources) s WHERE s ILIKE '%azleg.gov%');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Werner row missing the SB1729 citation'; END IF;
END $$;

COMMIT;
`);

writeFileSync('migrations/1517_retire_unsupported_tail_stances.sql', `-- 1517_retire_unsupported_tail_stances.sql
--
-- Retire 5 published stance answers for which NO SOURCE SUPPORTS THE CHAIR. Per the backlog's standing
-- rule, where no source supports a chair the answer is NO STANCE -- not a weaker one, and not an
-- inference from the person's party, caucus or general record.
--   Rollback record: data/stance-retirement/2026-08-01-tail-corrections-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--   Review:          data/stance-retirement/2026-08-01-tail-hand-review.md
--
-- 🔴 THESE ARE NOT CITATION FAILURES AND MUST NOT BE RECORDED AS SUCH. Three of the five say so in
-- their own reasoning -- "No direct legislation or on-record statements ... were found", "No specific
-- legislation authored by Mitchell ... was identified", "No specific campaign finance reform bill she
-- authored was identified" -- and then assign a chair anyway from LGBTQ+ advocacy, a civil-rights
-- record, or being "a progressive Democrat". The citation did not fail; there was never a citation.
--
-- The other two were found by reading the cited page:
--
--   Holly J. Mitchell / Redistricting -- the row credits her with backing California's independent
--     commission via Prop 11 and Prop 20. The page's ONLY mention of redistricting is that "she was
--     displaced from her current district by redistricting" in 2012. That is election history, not a
--     position. Presence of the word is not support for the claim.
--
--   Brinker Harding / Taxes -- the row says his site "pledges to fight to cut taxes as part of a
--     platform to grow the economy and eliminate wasteful spending". The page pledges to "fight to
--     grow our economy and eliminate wasteful spending to increase revenues and reduce our deficit".
--     There is no tax-cut pledge: "cut taxes", "lower taxes", "tax relief", "reduce taxes" and
--     "tax cut" are ALL absent from the page. "Cut taxes" was inserted into someone else's sentence,
--     and the stance value 4 -- "Cut taxes for everyone and scale back public services" -- rests
--     entirely on the inserted words.
--
-- All five are published and voter-facing; reasoning renders under "Why this position?".

BEGIN;

CREATE TEMP TABLE _retire_1517 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1517 (politician_id, topic_id) VALUES
${RETIRE.map((r, i) => `  (${q(r.row.pid)}, ${q(r.row.tid)})${i === RETIRE.length - 1 ? '' : ','}  -- ${r.row.name}: ${r.row.topic}`).join('\n')}
;

DELETE FROM inform.politician_context c USING _retire_1517 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1517 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1517 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1517 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;
END $$;

COMMIT;
`);

console.log('wrote migrations/1516_correct_tail_cohort_reasoning.sql (4 corrections)');
console.log('wrote migrations/1517_retire_unsupported_tail_stances.sql (5 retirements)');
console.log('wrote data/stance-retirement/2026-08-01-tail-corrections-rollback.json');
