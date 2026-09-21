#!/usr/bin/env node
/**
 * Generate migration 1892: put six Texas Deportation Priorities rows onto SB 4 (88-4) recorded-vote
 * evidence or the member's own words. Two of them (Hull, King) are currently BLANK and should not be:
 * both voted for the enacted state removal statute, which migration 1890's 89R-only sweep missed.
 * The other four keep chair 4 but move off dead 89th-session bills onto a recorded vote / a quote.
 * Season 1 is never touched. Dyson and Nichols stay blank.
 */
import 'dotenv/config';
import fs from 'node:fs';
import pg from 'pg';

const OUT = process.argv[2];
if (!OUT) { console.error('need out path'); process.exit(2); }

const S1 = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3';
const S2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const TOPIC = '44905f3b-e105-4f6c-afc7-5d223813dbac';   // Deportation Priorities

// Rung 4 of the Season 2 ladder, read from compass_stance_revisions via this topic's own Season 2
// pin: "Deport all undocumented immigrants, starting with those who have criminal records."
//
// ⚠ Every URL below was FETCHED (HTTP 200) and every quote read off the fetched body. The two
// legislative journals were parsed with pypdf and each parse recovered the journal's OWN stated
// totals exactly (House 83/60; Senate 17/11/3), which is the check that the right vote was read.
// ⚠ No row names a party.
const SB4 =
  'SB 4 of the 88th Legislature’s fourth called session — "prohibitions on the illegal entry into or '
  + 'illegal presence in this state by a person who is an alien, the enforcement of those prohibitions and '
  + 'certain related orders ... and authorizing or requiring under certain circumstances the removal of '
  + 'persons who violate those prohibitions; creating criminal offenses." It was signed on 2023-12-18 with '
  + 'an effective date of 2024-03-05.';
const RUNG =
  ' Authorising state officers to arrest people for unlawful entry or presence and state judges to order '
  + 'their removal reaches undocumented people generally rather than only those convicted of serious violent '
  + 'crimes, and it sorts by immigration and criminal status rather than by how long someone has lived here — '
  + 'which places this at deporting everyone without legal status, starting with those who have criminal '
  + 'records. It is not a mass-deportation programme directed at long-settled families and workers, so it does '
  + 'not reach the top rung.';

const ROWS = [
  {
    name: 'Lacey Hull', from: 0, value: 4,
    reasoning:
      'Hull voted for ' + SB4 + ' The House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays '
      + '(Record 35), and Hull is recorded in the aye column; she is also named in the House Journal among the '
      + 'members who seconded the motion for the previous question on its passage.' + RUNG
      + ' This replaces a blank: the earlier research had examined only her filed bills from the following '
      + 'session, which are about real property, voter registration, bail and the border region, and had found '
      + 'nothing about removal. The recorded vote is the evidence that was missing.',
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4',
      'https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3975',
    ],
  },
  {
    name: 'Phil King', from: 0, value: 4,
    reasoning:
      'King voted for ' + SB4 + ' The Senate read it a third time and passed it finally on 2023-11-09 by 17 '
      + 'ayes to 11 nays, and King is recorded in the aye column.' + RUNG
      + ' This replaces a blank, and it deliberately does not restore the original reasoning, which rested on '
      + 'his chairing a committee on homeland and border security. A committee chairmanship is a role, not a '
      + 'position, and it is not cited here. The recorded vote is.',
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4',
      'https://journals.senate.texas.gov/sjrnl/884/pdf/88S4SJ11-09-F.PDF',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=author&Code=A1345',
    ],
  },
  {
    name: 'John McQueeney', from: 4, value: 4,
    reasoning:
      'McQueeney has stated the position himself, twice. Asked what should be done about the southern border, '
      + 'he answered: "we must continue to pass and enforce laws like Senate Bill 4 which allows Texas law '
      + 'enforcement to arrest illegal immigrants. We must also continue to give our Judges greater authority to '
      + 'deport illegal aliens" (Texas Scorecard, 2024-05-20). Asked again two years later, he said Texas must '
      + 'take "decisive action to secure the border", including "working with the federal government to deport '
      + 'criminal illegal aliens" (Fort Worth Report candidate questionnaire, 2026-02-17). Endorsing broader '
      + 'judicial authority to deport people without legal status rules out the rungs limited to those convicted '
      + 'of serious violent crimes or to recent arrivals, and naming people with criminal records as the '
      + 'priority for federal cooperation is the sequencing this rung describes. He does not call for a '
      + 'mass-deportation programme reaching long-settled families and workers. He also coauthored HB 5580 in '
      + 'the following session, which would have required sheriff agreements with federal immigration '
      + 'authorities; it did not pass.',
    sources: [
      'https://texasscorecard.com/local/runoff-preview-mcqueeney-and-bean-square-off-for-house-district-97/',
      'https://fortworthreport.org/2026/02/16/john-mcqueeney-republican-candidate-for-texas-house-district-97/',
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB5580',
    ],
  },
  {
    name: 'Cody Harris', from: 4, value: 4,
    reasoning:
      'Harris voted for ' + SB4 + ' The House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays '
      + '(Record 35), and Harris is recorded in the aye column.' + RUNG
      + ' In the following session he also coauthored HB 2361, which would have provided for agreements between '
      + 'local law enforcement agencies and federal immigration authorities, and HB 1832, which would have '
      + 'raised penalties for unlawful entry and reentry by people with prior criminal convictions; neither '
      + 'passed. The recorded vote on an enacted statute is the stronger evidence and is why this chair stands.',
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4',
      'https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3580',
    ],
  },
  {
    name: 'Dennis Paul', from: 4, value: 4,
    reasoning:
      'Paul cosponsored and voted for ' + SB4 + ' He appears on the bill’s House cosponsor list, and when the '
      + 'House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35) he is recorded in the '
      + 'aye column.' + RUNG
      + ' In the following session he also coauthored HB 2361, on agreements between local law enforcement '
      + 'agencies and federal immigration authorities, which did not pass. Asked separately about immigration in '
      + 'a candidate questionnaire, his own answer was about stopping crossings and ending sanctuary cities '
      + 'rather than about removal, so this chair rests on the legislation he cosponsored and voted for.',
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4',
      'https://capitol.texas.gov/BillLookup/Sponsors.aspx?LegSess=884&Bill=SB4',
      'https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF',
    ],
  },
  {
    name: 'Cody Vasut', from: 4, value: 4,
    reasoning:
      'Vasut cosponsored and voted for ' + SB4 + ' He appears on the bill’s House cosponsor list, and when the '
      + 'House passed it to third reading on 2023-11-14 by 83 ayes to 60 nays (Record 35) he is recorded in the '
      + 'aye column. He also lists it on his own campaign biography as an accomplishment, describing it as "the '
      + 'strongest border security legislation in the nation" and saying he "successfully defended" it "against '
      + 'points of order" — a procedural defence the House Journal is consistent with, since he is named among '
      + 'the members who seconded the motion for the previous question on its passage.' + RUNG,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=884&Bill=SB4',
      'https://capitol.texas.gov/BillLookup/Sponsors.aspx?LegSess=884&Bill=SB4',
      'https://journals.house.texas.gov/hjrnl/884/pdf/88C4DAY04CFINAL.PDF',
      'https://www.votevasut.com/bio',
    ],
  },
];

// Asserted to be left exactly as they are.
const STAY_BLANK = ['Paul Dyson', 'Robert Nichols'];
const STAY_SEATED = ['Joanne Shofner'];
const ALL = [...ROWS.map((r) => r.name), ...STAY_BLANK, ...STAY_SEATED];

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: db } = await pool.query(`
  SELECT p.id, p.full_name, a1.value::int AS s1_chair, a2.value::int AS s2_value,
         left(c2.reasoning, 20) AS s2_head
  FROM essentials.politicians p
  JOIN inform.politician_answers a1 ON a1.politician_id=p.id AND a1.topic_id=$2 AND a1.season_id=$3
  JOIN inform.politician_answers a2 ON a2.politician_id=p.id AND a2.topic_id=$2 AND a2.season_id=$4
  JOIN inform.politician_context  c2 ON c2.politician_id=p.id AND c2.topic_id=$2 AND c2.season_id=$4
  WHERE p.full_name = ANY($1::text[])
  ORDER BY p.full_name`, [ALL, TOPIC, S1, S2]);
await pool.end();

if (db.length !== ALL.length) {
  console.error(`resolved ${db.length} of ${ALL.length} — refusing`);
  console.error('missing:', ALL.filter((n) => !db.some((r) => r.full_name === n)));
  process.exit(3);
}
const dupes = db.map((r) => r.full_name).filter((n, i, a) => a.indexOf(n) !== i);
if (dupes.length) { console.error('ambiguous names:', dupes); process.exit(3); }

for (const d of db) {
  if (d.s1_chair !== 4) { console.error(`${d.full_name}: Season 1 chair is ${d.s1_chair}, expected 4`); process.exit(3); }
}
for (const r of ROWS) {
  const d = db.find((x) => x.full_name === r.name);
  r.id = d.id;
  if (d.s2_value !== r.from) {
    console.error(`${r.name}: Season 2 holds ${d.s2_value}, expected ${r.from} — state has moved`);
    process.exit(3);
  }
  // a row moving off a blank must currently BE a blank in its prose too, and one that is already
  // seated must NOT be carrying blank prose (that would mean 1890 half-applied).
  const isBlankProse = d.s2_head.startsWith('Blank in Season 2');
  if (r.from === 0 && !isBlankProse) { console.error(`${r.name}: expected blank prose, got "${d.s2_head}"`); process.exit(3); }
  if (r.from !== 0 && isBlankProse) { console.error(`${r.name}: seated row is carrying blank prose`); process.exit(3); }
  if (!r.sources.length) { console.error(`${r.name}: no sources`); process.exit(3); }
  if (!r.sources.some((s) => /^https?:\/\/[^/]+\/.+/.test(s))) { console.error(`${r.name}: all sources bare roots`); process.exit(3); }
  if (!r.sources.every((s) => /^https?:\/\//.test(s))) { console.error(`${r.name}: non-URL source`); process.exit(3); }
  // every row resting on a recorded vote must cite the journal that records it
  if (/recorded in the aye column/.test(r.reasoning)
      && !r.sources.some((s) => s.includes('journals.'))) {
    console.error(`${r.name}: claims a recorded vote but cites no journal`); process.exit(3);
  }
}
const blankIds = STAY_BLANK.map((n) => db.find((d) => d.full_name === n).id);
const seatedIds = STAY_SEATED.map((n) => db.find((d) => d.full_name === n).id);
for (const n of STAY_BLANK) {
  const d = db.find((x) => x.full_name === n);
  if (d.s2_value !== 0) { console.error(`${n}: expected to still be blank, holds ${d.s2_value}`); process.exit(3); }
}
console.log(`seating from blank: ${ROWS.filter((r) => r.from === 0).map((r) => r.name).join(', ')}`);
console.log(`re-sourcing at chair 4: ${ROWS.filter((r) => r.from === 4).map((r) => r.name).join(', ')}`);
console.log(`asserted unchanged: blank=${STAY_BLANK.join(', ')} | seated=${STAY_SEATED.join(', ')}`);

const q = (s) => `$r$${s}$r$`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const ids = ROWS.map((r) => `'${r.id}'`).join(',');
const blankIdList = blankIds.map((i) => `'${i}'`).join(',');
const seatedIdList = seatedIds.map((i) => `'${i}'`).join(',');
const vals = ROWS.map((r) => `  -- ${r.name} (S2 ${r.from === 0 ? 'blank' : `chair ${r.from}`} -> chair ${r.value})\n  ('${r.id}',${q(r.reasoning)},${arr(r.sources)})`);
const avals = ROWS.map((r) => `  -- ${r.name}\n  ('${r.id}',${r.value})`);

const sql = `-- 1892_tx_sb4_vote_evidence_season2.sql
-- Put 6 Texas Deportation Priorities rows onto recorded-vote evidence in Season 2. 6 context rows and
-- 6 answer rows UPDATED in the OPEN season. Nothing inserted, nothing deleted. SEASON 1 IS NOT
-- TOUCHED. **2 of the 6 move from blank (value 0) to chair 4.** Dyson, Nichols and Shofner unchanged.
--
-- 🔴🔴 WHY THIS EXISTS: MIGRATION 1890'S SWEEP HAD A SCOPE ERROR. It swept the filed records of all
-- nine members blanked by migration 1888 -- but **only for the 89th Legislature**. The Texas removal
-- statute is **SB 4 of the 88th Legislature's FOURTH CALLED SESSION**:
--   "prohibitions on the illegal entry into or illegal presence in this state by a person who is an
--    alien, the enforcement of those prohibitions and certain related orders ... and **authorizing or
--    requiring under certain circumstances THE REMOVAL of persons who violate those prohibitions**;
--    creating criminal offenses." -- signed 2023-12-18, effective 2024-03-05.
-- It is already in this audit's SOUND set. One more session would have found it. ▶ **Sweep every
-- session a member actually served, not the current one.**
--
-- ✅ THE RECORDED FLOOR VOTES -- the strongest evidence anywhere in this audit, and the reason two
-- blanks are wrong:
--   * **HOUSE, Record 35, 2023-11-14, passage to third reading: 83 ayes / 60 nays.** Aye: **Hull**,
--     **Cody Harris**, **Dennis Paul**, **Cody Vasut**.
--   * **SENATE, 2023-11-09, third reading and final passage: 17 ayes / 11 nays.** Aye: **Phil King**.
--   🔑 Both journals were parsed with pypdf and each parse **recovered the journal's own stated
--   totals exactly** (83/60; 17/11 with 3 absent-excused). That match is the check that the correct
--   vote was read -- a first attempt at the Senate page grabbed an **18/10** tally belonging to a
--   DIFFERENT bill printed on the same page. Anchor on the bill's own third-reading heading.
--   🔑 The House Journal never spells either Harris out, only "Harris, C.J." and "Harris, C.E."
--   (Cody Harris and Caroline Harris Davila). **BOTH voted aye**, so the attribution to Cody Harris
--   holds whichever initial is his -- the collision did not have to be resolved.
--
-- 🔴 **LACEY HULL and PHIL KING WERE BLANKED BY MIGRATION 1888 AND SHOULD NOT HAVE BEEN.** Both
-- voted for the enacted removal statute. The blanks were honest given what had been examined -- they
-- said so, and said the rows were re-researchable -- but they were wrong, and this corrects them.
-- ⚖ **King's row deliberately does NOT restore his original reasoning**, which rested on his
-- chairing a committee on homeland and border security. A chairmanship is a role, not a position; it
-- is not cited here. A recorded vote is.
--
-- ✅ FOUR ROWS KEEP CHAIR 4 BUT MOVE OFF DEAD BILLS:
--   * **John McQueeney** -> **his own words, twice.** "We must also continue to give our Judges
--     greater authority to deport illegal aliens" (Texas Scorecard, 2024-05-20) and "working with the
--     federal government to deport criminal illegal aliens" (Fort Worth Report questionnaire,
--     2026-02-17). ⚠ He took office in 2025, so SB 4 says nothing about him.
--   * **Cody Harris**, **Dennis Paul**, **Cody Vasut** -> from coauthoring bills that DIED in the
--     89th to a recorded vote on an ENACTED statute. Paul and Vasut are also on its cosponsor list.
--     Vasut advertises it on his own campaign biography.
--
-- ✅ ASSERTED UNCHANGED, so the shape of this edit is checkable from the file:
--   * **Paul Dyson** stays BLANK -- 93 filed bills with nothing about removal, a statement hunt that
--     found nothing, and he took office in 2025 so SB 4 does not reach him. Best-evidenced blank here.
--   * **Robert Nichols** stays BLANK. 🔴🔴 He was **ABSENT-EXCUSED** on SB 4 -- the Senate Journal
--     records that he "was granted leave of absence for today on account of family business."
--     **AN EXCUSED ABSENCE IS NOT A POSITION AND IS NOT CITED AS ONE.** His blank rests on the
--     absence of evidence, never on the absence of a vote; treating a missing vote as evidence is
--     precisely the load-bearing-absence defect this whole audit exists to remove.
--   * **Joanne Shofner** stays at chair 4 on HB 2390. "Deport" appears zero times on her entire
--     Ballotpedia page including her own candidate-written survey, and she took office in 2025.
--
-- ⚠ ONE SOURCE NOT READ: theeagle.com's "Meet the Candidate" questionnaire for Dyson returned
-- HTTP 429. It is the one unexamined item across the nine.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- the two being seated must still be blank, in both value and prose
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id='${TOPIC}' AND a.value=0
     AND c.reasoning LIKE 'Blank in Season 2%'
     AND a.politician_id IN (${ROWS.filter((r) => r.from === 0).map((r) => `'${r.id}'`).join(',')});
  IF n <> ${ROWS.filter((r) => r.from === 0).length} THEN
    RAISE EXCEPTION 'migration 1892: expected ${ROWS.filter((r) => r.from === 0).length} blank row(s) to seat, found % -- state has moved', n;
  END IF;

  -- the four being re-sourced must already be at chair 4
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=4
     AND politician_id IN (${ROWS.filter((r) => r.from === 4).map((r) => `'${r.id}'`).join(',')});
  IF n <> ${ROWS.filter((r) => r.from === 4).length} THEN
    RAISE EXCEPTION 'migration 1892: expected ${ROWS.filter((r) => r.from === 4).length} row(s) already at chair 4, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND value=4
     AND politician_id IN (${ids},${blankIdList},${seatedIdList});
  IF n <> ${ALL.length} THEN
    RAISE EXCEPTION 'migration 1892: expected ${ALL.length} Season 1 chair-4 rows, found %', n;
  END IF;
END $$;

UPDATE inform.politician_context c
   SET reasoning = v.reasoning, sources = v.sources, updated_at = now()
  FROM (VALUES
${vals.join(',\n')}
) AS v(pid, reasoning, sources)
 WHERE c.politician_id = v.pid::uuid
   AND c.topic_id = '${TOPIC}'
   AND c.season_id = '${S2}';

UPDATE inform.politician_answers a
   SET value = v.value, updated_at = now()
  FROM (VALUES
${avals.join(',\n')}
) AS v(pid, value)
 WHERE a.politician_id = v.pid::uuid
   AND a.topic_id = '${TOPIC}'
   AND a.season_id = '${S2}';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=4 AND politician_id IN (${ids});
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1892: expected ${ROWS.length} rows at chair 4, found %', n;
  END IF;

  -- no seated row may still be arguing that it is a blank
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND reasoning LIKE 'Blank in Season 2%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1892: % seated row(s) still carry blank prose', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1892: % row(s) have empty sources', n;
  END IF;

  -- 🔴 Dyson and Nichols stay blank, prose intact
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id AND c.season_id=a.season_id
   WHERE a.season_id='${S2}' AND a.topic_id='${TOPIC}' AND a.value=0
     AND c.reasoning LIKE 'Blank in Season 2%'
     AND a.politician_id IN (${blankIdList});
  IF n <> ${STAY_BLANK.length} THEN
    RAISE EXCEPTION 'migration 1892: expected ${STAY_BLANK.length} row(s) still blank with blank prose, found %', n;
  END IF;

  -- 🔴 Shofner untouched at chair 4
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=4 AND politician_id IN (${seatedIdList});
  IF n <> ${STAY_SEATED.length} THEN
    RAISE EXCEPTION 'migration 1892: Shofner is no longer at chair 4';
  END IF;

  -- 🔴 Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND value=4
     AND politician_id IN (${ids},${blankIdList},${seatedIdList});
  IF n <> ${ALL.length} THEN
    RAISE EXCEPTION 'migration 1892: Season 1 changed -- % of ${ALL.length} still at chair 4', n;
  END IF;
END $$;

COMMIT;
`;
fs.writeFileSync(OUT, sql);
console.log(`wrote ${OUT}`);
