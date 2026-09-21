#!/usr/bin/env node
/**
 * Generate migration 1888: blank, in Season 2, the nine Texas Deportation Priorities chairs that are
 * seated on instruments which are not about removal — SB 17 / HB 17 (real-property purchases by
 * foreign nationals), SB 16 / HB 5337 (proof of citizenship to REGISTER TO VOTE), SB 1 (87-2,
 * election security), SB 14 (regulatory reform) — plus party, caucus, geography or a committee role.
 * Season 1 is never touched. Each blank carries the Season 1 row's own sources forward, because the
 * pages that were examined and found insufficient are exactly what makes a blank auditable (mig 1887).
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

// Read individually out of the 16-row cohort on 2026-09-20. Seven of the sixteen are NOT here:
// Janie Lopez holds (her own campaign platform calls for banning sanctuary cities), and McLaughlin,
// Patterson, Barry, Pierson, Kolkhorst and Middleton each carry one thin member-specific leg and are
// left standing for a re-sourcing pass rather than destroyed. Do not re-derive this list from a
// detector.
const CITED = {
  'Cody Harris': 'HB 17 (real-property purchases by certain foreign nationals) and HB 5337 (proof of citizenship to register to vote), followed by a bare assertion that he supports deporting people without legal status',
  'Cody Vasut': 'HB 17 (real-property purchases by certain foreign nationals) together with membership of the Texas Freedom Caucus',
  'Dennis Paul': 'SB 17 (the foreign-land ban) and SB 14 (regulatory reform), together with "Republican caucus enforcement posture" — while the row itself records that he is "not among the most vocal deportation advocates"',
  'John McQueeney': 'HB 5337 (proof of citizenship to register to vote) and HB 17 (real-property purchases by certain foreign nationals), reasoning from a voter-registration bill to a removal chair',
  'Joanne Shofner': 'HB 17, described as "immigration enforcement", together with being "in line with [the] Abbott/Trump Republican primary profile"',
  'Lacey Hull': 'HB 17, described as "strengthening ICE cooperation", together with being "a Houston-area Republican who has aligned with conservative immigration enforcement"',
  'Paul Dyson': 'HB 17 and a Judiciary committee seat — after the row itself records that he "did not author or co-author any direct deportation enforcement bill" and that the committee "handles criminal law and civil procedure, not specifically immigration enforcement bills"',
  'Phil King': 'SB 16 (proof of citizenship to register to vote) and SB 17 (the foreign-land ban), together with his chairmanship of the Homeland and Border Security Select Committee',
  'Robert Nichols': 'SB 1 (87th Legislature, 2nd Called Session — election security), SB 16 (proof of citizenship to register to vote) and SB 17 (the foreign-land ban)',
};
const NAMES = Object.keys(CITED);

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT p.id, p.full_name, a.value::int AS s1_chair, c.sources
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
// 🔴 trap #2 from the handoff: a blank must carry the sources it examined. EMPTY_SOURCES is
// zero-tolerance and it is PR-invisible, so refuse at generation time rather than on master.
const unsourced = rows.filter((r) => !Array.isArray(r.sources) || r.sources.length === 0);
if (unsourced.length) {
  console.error('Season 1 rows with no sources to carry forward:', unsourced.map((r) => r.full_name));
  process.exit(3);
}
console.log(`${rows.length} rows; S1 chairs ${JSON.stringify(rows.reduce((m, r) => (m[r.s1_chair] = (m[r.s1_chair] || 0) + 1, m), {}))}`);

const last = (name) => name.split(' ').slice(-1)[0];
const BLANK = (name, chair) => `Blank in Season 2 — researched, and the instruments on record are not about removal, so the evidence does not reach any rung of this ladder. The Season 1 row seats ${name} at chair ${chair} on ${CITED[name]}. ${last(name)}'s co-authorship is real; the characterisation of it is what fails. SB 17 and HB 17 (89R) restrict the purchase of real property by certain foreign nationals — HB 17 was left pending in committee on 2025-04-02 and never passed. SB 16 and HB 5337 (89R) require proof of citizenship to register to vote. SB 1 (87th, 2nd C.S.) is an election-security law and SB 14 (89R) is regulatory reform. A property-ownership restriction, a voter-registration requirement and an election-administration law are not positions on whether people without legal status should be removed, and party, caucus, district and a committee chairmanship are roles and affiliations rather than positions. The sources carried on this row are the pages that were examined and found insufficient. Season 1 keeps the original row unchanged as the historical record of what was once claimed. This is a blank, not a finding that the opposite is true: it says the question has not been answered on this person, and it is re-researchable from here.`;

const q = (s) => `$r$${s}$r$`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const ctx = rows.map((r) => `  -- ${r.full_name} (S1 chair ${r.s1_chair})\n  ('${r.id}',${q(BLANK(r.full_name, r.s1_chair))},${arr(r.sources)})`);
const ans = rows.map((r) => `  -- ${r.full_name} (S1 chair ${r.s1_chair} -> blank)\n  ('${r.id}')`);
const ids = rows.map((r) => `'${r.id}'`).join(',');

const sql = `-- 1888_tx_deportation_instrument_blanks_season2.sql
-- Blank 9 Texas Deportation Priorities chairs in Season 2. They are seated in Season 1 on bills that
-- are not about removal. 9 context rows + 9 answer rows (value 0) INSERTED. Nothing updated, nothing
-- deleted. SEASON 1 IS NOT TOUCHED.
--
-- 🔴 WHAT IS WRONG WITH THEM. Every one rests on some combination of four instruments, none of which
-- is a removal instrument:
--   * **SB 17 / HB 17 (89R)** — "the purchase of or acquisition of title to real property by certain
--     aliens or foreign entities". 🔴 **HB 17 was LEFT PENDING IN COMMITTEE on 2025-04-02 and never
--     passed** (author Hefner; verified against capitol.texas.gov BillLookup). The 89(1) and 89(2)
--     HB 17s are property-tax notice bills. **No HB 17 in the 89th Legislature is about ICE.**
--   * **SB 16 / HB 5337 (89R)** — proof of citizenship to REGISTER TO VOTE.
--   * **SB 1 (87th, 2nd C.S.)** — the omnibus election-security law.
--   * **SB 14 (89R)** — regulatory reform.
-- ...topped up with party, caucus membership, the region represented, or a committee chairmanship.
--
-- 🔑 THE CO-AUTHORSHIP CLAIMS ARE TRUE — the coauthor lists were checked. A bad characterisation is
-- not a false claim. The defect is inferring a removal chair from a property bill and a voter
-- registration bill. Three rows go further and call HB 17 an enforcement bill outright ("immigration
-- enforcement legislation", "strengthening ICE cooperation"), which it is not.
--
-- 🔴 TWO ROWS RECORD THE ABSENCE AND SEAT THE CHAIR ANYWAY. **Paul Dyson**: "did not author or
-- co-author any direct deportation enforcement bill (HB 5580, HB 1491)" and sits on a committee that
-- "handles criminal law and civil procedure, not specifically immigration enforcement bills" — then
-- chair 4. **Dennis Paul**: "not among the most vocal deportation advocates" — then chair 4.
-- **Phil King** is seated partly on chairing the Homeland and Border Security Select Committee;
-- a chairmanship is a role, not a position (the Leigh Davis / Derek Tran / Steven Johnson precedent).
--
-- ⚖ A BLANK, NOT A REVERSAL. value 0 says the question has not been answered on this person. It does
-- NOT assert the opposite chair. Several of these members may well hold the position they were seated
-- at; what is missing is evidence, not plausibility.
--
-- 🔑 WHY BLANK AND NOT DELETE. Deleting a Season 2 row does not blank anyone — the read falls back to
-- Season 1, so the inferred chair would stay visible. A blank is value 0, which CC_0057 made
-- expressible and PR #350/#354 made safe to read.
--
-- 🔑 EVERY BLANK CARRIES THE SOURCES IT EXAMINED, copied from its own Season 1 row. \`EMPTY_SOURCES\`
-- is zero-tolerance in \`npm run check:stance-sources\`, it is what turned master red after migration
-- 1886, and that gate **never runs on a pull request** (\`if: github.event_name != 'pull_request'\`) —
-- so it was run by hand before merge. Carrying the examined pages forward is also the argument: a
-- bill page for a property statute cannot state a deportation position.
--
-- ⚠ SEVEN OF THE SIXTEEN IN THIS COHORT ARE DELIBERATELY NOT HERE. **Janie Lopez** holds — her own
-- campaign platform calls for banning sanctuary cities, which is a real enforcement position on her
-- own say-so. **Don McLaughlin, Jared Patterson, Jeffrey Barry, Katrina Pierson, Lois Kolkhorst** and
-- **Mayes Middleton** each carry exactly one thin member-specific leg (a vague "voiced concern", a
-- Wikipedia characterisation, an unquoted campaign platform, an unsourced Trump-agenda association, a
-- $6bn border-security appropriation, an endorsement blurb about an unnamed bill). Those are too thin
-- for the chairs they hold — two of them are at chair 5 — but they are re-sourcing work, not blanks.
-- Blanking a correct stance is worse than leaving a weak one: the previous pass's first cut of 31 was
-- 39% wrong.
--
-- ⚠ NOT IN THIS MIGRATION: the sibling rows on **Immigration and Treatment of Immigrants**, which has
-- the same defect. That topic is **Season 1 only** — the corpus's largest orphan (1,678 stances, not
-- pinned in Season 2 or 3) — so \`politician_answers_pin_fkey\` forbids a Season 2 row for it. Those
-- ride on the Season 3 return/retire/merge decision, not on a blank.
--
-- 🔑 THE LADDER REVISION DIFFERS BETWEEN SEASONS AND IT DOES NOT MATTER HERE. Deportation Priorities
-- pins 673c3758 in Season 1 and ${REV_S2.slice(0, 8)} in Season 2. A blank asserts no rung, so nothing is being
-- carried across a re-scale; the Season 2 pin is used only because the FK requires the season's own.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}'
     AND politician_id IN (${ids});
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1888: expected ${rows.length} Season 1 chairs for this cohort, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}'
     AND politician_id IN (${ids});
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: Season 2 already holds % row(s) for this cohort/topic', n;
  END IF;

  SELECT count(*) INTO n FROM inform.season_questions
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND topic_revision_id='${REV_S2}';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1888: Season 2 does not pin revision ${REV_S2} for Deportation Priorities';
  END IF;
END $$;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, editor_id, reasoning, sources)
SELECT v.pid::uuid, '${TOPIC}'::uuid, '${S2}'::uuid, '${REV_S2}'::uuid, NULL, v.reasoning, v.sources
FROM (VALUES
${ctx.join(',\n')}
) AS v(pid, reasoning, sources);

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
     AND politician_id IN (${ids});
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1888: expected ${rows.length} Season 2 blanks, found %', n;
  END IF;

  -- every blank must carry a context row explaining it...
  SELECT count(*) INTO n FROM inform.politician_answers a
    LEFT JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id='${TOPIC}' AND a.value=0 AND c.politician_id IS NULL;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: % blank(s) carry no context row explaining the blank', n;
  END IF;

  -- ...and that context row must carry the sources it examined (EMPTY_SOURCES is zero-tolerance)
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}'
     AND politician_id IN (${ids})
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1888: % new blank(s) shipped with empty sources', n;
  END IF;

  -- 🔴 Season 1 must be untouched: same count, and no Season 1 chair turned into a blank
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}'
     AND politician_id IN (${ids}) AND value <> 0;
  IF n <> ${rows.length} THEN
    RAISE EXCEPTION 'migration 1888: Season 1 chairs changed -- % still non-blank, expected ${rows.length}', n;
  END IF;
END $$;

COMMIT;
`;
fs.writeFileSync(OUT, sql);
console.log(`wrote ${OUT}`);
