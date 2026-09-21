#!/usr/bin/env node
/**
 * Generate migration 1886: blank, in Season 2, the Texas Deportation Priorities chairs that rest on
 * inference rather than evidence. Season 1 is never touched.
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv[2];
if (!OUT) { console.error('need out path'); process.exit(2); }

const S1 = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
const S2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const TOPIC = '44905f3b-e105-4f6c-afc7-5d223813dbac';   // Deportation Priorities
const REV_S2 = '55c3167e-3ad8-425d-a699-b2e91552d912';  // its Season 2 pin

// read out of the cohort read on 2026-09-20; each confirmed individually, not taken from a detector
const NAMES = ['Lulu Flores', 'Molly Cook', 'Oscar Longoria', 'Penny Morales Shaw', 'Ray Lopez',
  'Rhetta Bowers', 'Royce West', 'Terry Canales', 'Toni Rose', 'Terry Wilson', 'Steve Toth'];

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT p.id, p.full_name, a.value::int AS s1_chair, c.reasoning
  FROM essentials.politicians p
  JOIN inform.politician_context c ON c.politician_id=p.id AND c.topic_id=$2 AND c.season_id=$3
  JOIN inform.politician_answers a ON a.politician_id=p.id AND a.topic_id=$2 AND a.season_id=$3
  WHERE p.full_name = ANY($1::text[])
  ORDER BY p.full_name`, [NAMES, TOPIC, S1]);
await pool.end();

if (rows.length !== NAMES.length) {
  console.error(`resolved ${rows.length} of ${NAMES.length} — refusing to generate`);
  console.error('missing:', NAMES.filter((n) => !rows.some((r) => r.full_name === n)));
  process.exit(3);
}
const dupes = rows.map((r) => r.full_name).filter((n, i, a) => a.indexOf(n) !== i);
if (dupes.length) { console.error('ambiguous names:', dupes); process.exit(3); }
console.log(`${rows.length} rows; S1 chairs ${JSON.stringify(rows.reduce((m, r) => (m[r.s1_chair] = (m[r.s1_chair] || 0) + 1, m), {}))}`);

const BLANK = (name, chair) => `Blank in Season 2 — researched, and the evidence on record does not reach any rung of this ladder. The Season 1 row seats ${name} at chair ${chair} on inference rather than on anything ${name.split(' ').slice(-1)[0]} did: it cites no bill, no vote, no quote and no dated statement, and argues instead from some combination of (a) NOT having co-authored somebody else's immigration bill, (b) party or caucus membership, and (c) the demographics of the district represented. None of those is a position. The absence of a signature on a bill is not evidence of the opposite position, and a district's composition is a fact about voters rather than about their representative. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.`;

const q = (s) => `$r$${s}$r$`;
const ctx = rows.map((r) => `  -- ${r.full_name} (S1 chair ${r.s1_chair})\n  ('${r.id}',${q(BLANK(r.full_name, r.s1_chair))})`);
const ans = rows.map((r) => `  -- ${r.full_name} (S1 chair ${r.s1_chair} -> blank)\n  ('${r.id}')`);

const sql = `-- 1886_tx_deportation_inference_blanks_season2.sql
-- Blank 11 Texas Deportation Priorities chairs in Season 2. They are seated in Season 1 on inference
-- rather than evidence. 11 context rows + 11 answer rows (value 0) INSERTED. Nothing updated,
-- nothing deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHAT IS WRONG WITH THEM. Each cites no bill, no vote, no quote and no dated statement. The chair
-- is argued from some mixture of:
--   (a) NOT having co-authored someone else's immigration bill,
--   (b) party or caucus membership ("standard progressive Democrat posture", "Freedom Caucus",
--       "ranked 3rd most conservative"),
--   (c) the demographics of the district represented.
-- 🔴 **The absence of a signature is not a position**, and a district's composition is a fact about
-- voters, not about their representative. Christina Morales's Immigration row states the method
-- outright -- *"She did not co-author immigration enforcement bills. Score 2 reflects standard
-- progressive Democrat posture"* -- and cites, as its source, the bill page of a bill she did not sign.
--
-- 🔴🔴 THE DEFECT RUNS IN BOTH DIRECTIONS, WHICH IS WHY THIS IS NOT A PARTISAN EDIT. 9 of the 11 are
-- Democrats inferred toward the protective end from caucus and district; 2 are Republicans inferred
-- toward the enforcement end from party and an ideology ranking (Terry Wilson: "no authored
-- immigration enforcement or ICE cooperation bill found. His general conservative record aligns with
-- the standard Texas Republican enforcement approach"; Steve Toth, seated at chair 5 on being
-- "ranked 3rd most conservative"). Party is never DISPLAYED by this product, and it must not be the
-- thing positions are DERIVED from either.
--
-- ⚖ A BLANK, NOT A REVERSAL. value 0 says the question has not been answered on this person. It does
-- NOT assert the opposite chair, and every one of these is re-researchable: several of these members
-- very likely do hold the position they were seated at. What is missing is evidence, not plausibility.
--
-- 🔑 WHY BLANK AND NOT DELETE. Deleting a Season 2 row does not blank anyone -- with seasons the read
-- falls back to Season 1 (CC_0057's header says so), so the inferred chair would stay visible. A
-- blank is value 0, which CC_0057 made expressible and PR #350/#354 made safe to read.
-- ⚠ This supersedes the note in the Season 3 agenda that "a blank mechanic would have to be proven
-- first" -- CC_0057 landed 2026-09-03 and migration 1882 used value-0 blanks on 2026-09-20.
--
-- 🔑 THE LADDER REVISION DIFFERS BETWEEN SEASONS AND IT DOES NOT MATTER HERE. Deportation Priorities
-- pins 673c3758 in Season 1 and ${REV_S2.slice(0, 8)} in Season 2. A blank asserts no rung, so nothing is being
-- carried across a re-scale; the Season 2 pin is used only because the FK requires the season's own.
--
-- ⚠ READ INDIVIDUALLY, NOT TAKEN FROM A DETECTOR. A first cut flagged 31 rows; all 31 were read and
-- **12 were kept** because they rest on the member's own conduct -- Ramon Romero Jr. fasted for three
-- days in 2017 against SB 4; Armando Walle led floor opposition as Deputy Floor Leader; Eddie Morales
-- and Briscoe Cain carry directly quoted positions. Blanking a correct stance is worse than leaving a
-- weak one, so the queue was read down to the 11 here.
--
-- ⚠ NOT IN THIS MIGRATION: the 10 sibling rows on **Immigration and Treatment of Immigrants**, which
-- has the same defect and includes the two rows seated on NOT co-authoring HB 17 (Jon Rosenthal,
-- Linda Garcia). That topic is **Season 1 only** -- it is the corpus's largest orphan (1,678 stances,
-- not pinned in Season 2 or 3), so no Season 2 row can exist for it and voters cannot reach any of
-- it today. It is fixed by the Season 3 return/retire/merge decision, not by a blank.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}'
     AND politician_id IN (${rows.map((r) => `'${r.id}'`).join(',')});
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1886: expected ${rows.length} Season 1 chairs for this cohort, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}'
     AND politician_id IN (${rows.map((r) => `'${r.id}'`).join(',')});
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1886: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND topic_revision_id='${REV_S2}';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1886: Season 2 does not pin revision ${REV_S2} for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '${TOPIC}'::uuid, '${S2}'::uuid, '${REV_S2}'::uuid, NULL, v.reasoning, ARRAY[]::text[]
FROM (VALUES
${ctx.join(',\n')}
) AS v(pid, reasoning);

INSERT INTO inform.politician_answers
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, value)
SELECT v.pid::uuid, '${TOPIC}'::uuid, '${S2}'::uuid, '${REV_S2}'::uuid, NULL, 0
FROM (VALUES
${ans.join(',\n')}
) AS v(pid);

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=0
     AND politician_id IN (${rows.map((r) => `'${r.id}'`).join(',')});
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1886: expected ${rows.length} Season 2 blanks, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id='${TOPIC}' AND a.value=0 AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1886: % blank(s) carry no context row explaining the blank', n;
  END IF;

  -- 🔴 Season 1 must be untouched: same count, and no Season 1 chair turned into a blank
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}'
     AND politician_id IN (${rows.map((r) => `'${r.id}'`).join(',')}) AND value <> 0;
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1886: Season 1 chairs changed -- % still non-blank, expected ${rows.length}', n;
  END IF;
END $$;

COMMIT;
`;
fs.writeFileSync(OUT, sql);
console.log(`wrote ${OUT}`);
