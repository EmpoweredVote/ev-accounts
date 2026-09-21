#!/usr/bin/env node
/**
 * Generate migration 1890: re-seat, in Season 2, the five Texas Deportation Priorities rows that
 * migration 1888 blanked and that a complete filed-record sweep then showed DO carry an
 * ICE-cooperation instrument their Season 1 rows never cited. Blank -> chair 4, with the reasoning
 * and sources REPLACED in the same statement so no row is left arguing a chair it no longer holds.
 * Season 1 is never touched. The other four of 1888's nine stay blank.
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
// ⚠ Every URL below was FETCHED (HTTP 200) during the sweep. The 287(g)-class bills all DIED, and
// every row says so. No row names a party.
const SHARED_TAIL =
  ' A 287(g) agreement deputises local officers to identify and hold people for federal immigration '
  + 'authorities, so its purpose is to increase removals — unlike the real-property and '
  + 'voter-registration bills this row previously cited, which are not removal instruments. Because '
  + 'such cooperation reaches everyone booked into a local jail rather than only people convicted of '
  + 'serious violent crimes, and sorts by criminal contact rather than by how long someone has lived '
  + 'here, it supports deporting everyone without legal status starting with those who have criminal '
  + 'records. This chair rests on filed legislation and not on a statement: no first-person statement '
  + 'about how far removal should go was found.';

const ROWS = [
  {
    name: 'John McQueeney', code: 'A4665',
    reasoning:
      'McQueeney coauthored HB 5580 of the 89th Legislature — "agreements between sheriffs and the United States '
      + 'Immigration and Customs Enforcement to enforce federal immigration law." It did not pass; its committee report '
      + 'was sent to Calendars on 2025-05-02 and it went no further.' + SHARED_TAIL,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB5580',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4665',
    ],
  },
  {
    name: 'Cody Harris', code: 'A3580',
    reasoning:
      'Harris coauthored two removal-related bills in the 89th Legislature. HB 2361 provided for "agreements between '
      + 'local law enforcement agencies and United States Immigration and Customs Enforcement to enforce federal '
      + 'immigration law"; HB 1832 raised criminal penalties for illegal entry into and reentry to the state, which the '
      + 'committee analysis describes as increasing penalties "for those with prior criminal" convictions. Neither passed '
      + '— HB 2361 was referred to committee on 2025-03-14 and HB 1832 got as far as being considered in Calendars on '
      + '2025-05-05.' + SHARED_TAIL,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2361',
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB1832',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3580',
    ],
  },
  {
    name: 'Dennis Paul', code: 'A3090',
    reasoning:
      'Paul coauthored HB 2361 of the 89th Legislature — "agreements between local law enforcement agencies and United '
      + 'States Immigration and Customs Enforcement to enforce federal immigration law." It did not pass; it was referred '
      + 'to committee on 2025-03-14 and went no further.' + SHARED_TAIL,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2361',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A3090',
    ],
  },
  {
    name: 'Cody Vasut', code: 'A4065',
    reasoning:
      'Vasut coauthored HB 2390 of the 89th Legislature — "agreements between municipalities and counties and United '
      + 'States Immigration and Customs Enforcement to enforce federal immigration law." It did not pass; it was referred '
      + 'to committee on 2025-03-14 and went no further.' + SHARED_TAIL,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2390',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4065',
    ],
  },
  {
    name: 'Joanne Shofner', code: 'A4755',
    reasoning:
      'Shofner coauthored HB 2390 of the 89th Legislature — "agreements between municipalities and counties and United '
      + 'States Immigration and Customs Enforcement to enforce federal immigration law." It did not pass; it was referred '
      + 'to committee on 2025-03-14 and went no further.' + SHARED_TAIL,
    sources: [
      'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=HB2390',
      'https://capitol.texas.gov/reports/report.aspx?LegSess=89R&ID=coauthor&Code=A4755',
    ],
  },
];

// The four that stay blank, asserted explicitly so a later reader can see the sweep's negative half
// was deliberate and is still in force.
const STAY_BLANK = ['Lacey Hull', 'Paul Dyson', 'Phil King', 'Robert Nichols'];

const ALL = [...ROWS.map((r) => r.name), ...STAY_BLANK];

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
  console.error(`resolved ${db.length} of ${ALL.length} — refusing to generate`);
  console.error('missing:', ALL.filter((n) => !db.some((r) => r.full_name === n)));
  process.exit(3);
}
const dupes = db.map((r) => r.full_name).filter((n, i, a) => a.indexOf(n) !== i);
if (dupes.length) { console.error('ambiguous names:', dupes); process.exit(3); }

for (const d of db) {
  if (d.s1_chair !== 4) { console.error(`${d.full_name}: Season 1 chair is ${d.s1_chair}, expected 4`); process.exit(3); }
  if (d.s2_value !== 0) { console.error(`${d.full_name}: Season 2 is ${d.s2_value}, expected 0 (blank) — state has moved`); process.exit(3); }
  // 🔴 the prose being replaced must actually be migration 1888's blank text. Re-seating a chair and
  // leaving the old reasoning behind is the stale-prose defect this corpus has already paid for.
  if (!d.s2_head.startsWith('Blank in Season 2')) {
    console.error(`${d.full_name}: Season 2 prose does not start with "Blank in Season 2" (got "${d.s2_head}") — refusing`);
    process.exit(3);
  }
}
for (const r of ROWS) {
  r.id = db.find((d) => d.full_name === r.name).id;
  if (!r.sources.length) { console.error(`${r.name}: no sources`); process.exit(3); }
  if (!r.sources.some((s) => /^https?:\/\/[^/]+\/.+/.test(s))) { console.error(`${r.name}: all sources are bare roots`); process.exit(3); }
  if (!r.sources.every((s) => /^https?:\/\//.test(s))) { console.error(`${r.name}: non-URL source`); process.exit(3); }
  // the member's own report must be cited, so the claim of coauthorship is checkable
  if (!r.sources.some((s) => s.includes(`Code=${r.code}`))) { console.error(`${r.name}: own filed-record report not cited`); process.exit(3); }
}
const blankIds = STAY_BLANK.map((n) => db.find((d) => d.full_name === n).id);
console.log(`re-seating ${ROWS.length}: ${ROWS.map((r) => r.name).join(', ')}`);
console.log(`staying blank (asserted): ${STAY_BLANK.join(', ')}`);

const q = (s) => `$r$${s}$r$`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const ids = ROWS.map((r) => `'${r.id}'`).join(',');
const blankIdList = blankIds.map((i) => `'${i}'`).join(',');
const vals = ROWS.map((r) => `  -- ${r.name}\n  ('${r.id}',${q(r.reasoning)},${arr(r.sources)})`);

const sql = `-- 1890_tx_reseat_ice_coauthors_season2.sql
-- Re-seat 5 Texas Deportation Priorities rows in Season 2 from blank (value 0) to chair 4.
-- 5 answer rows and 5 context rows UPDATED in the OPEN season. Nothing inserted, nothing deleted.
-- SEASON 1 IS NOT TOUCHED. The other four rows blanked by migration 1888 STAY BLANK.
--
-- 🔑 WHY THIS EXISTS, AND WHY IT IS NOT A REVERSAL. Migration 1888 blanked nine rows whose chairs
-- rested on real-property and voter-registration bills. Each blank said, in the voter-facing prose,
-- that "the evidence ON RECORD does not reach any rung" and that the row "is re-researchable from
-- here". A complete filed-record sweep of all nine members then ran: 27 author/coauthor/sponsor
-- reports from capitol.texas.gov, ~1,995 bill entries. **Five of the nine do carry an
-- ICE-cooperation instrument that their Season 1 rows never cited.** That is the designed path
-- working, not a retraction: the blank recorded an absence of evidence and the evidence was found.
--
-- ✅ WHAT THE SWEEP FOUND, per member (all 287(g)-class -- their whole purpose is to increase removals):
--   * **John McQueeney** -- coauthor **HB 5580**, "agreements between sheriffs and ... Immigration and
--     Customs Enforcement to enforce federal immigration law". Got furthest of the four: committee
--     report sent to Calendars 2025-05-02. HB 5580 is already recorded in this audit as a genuinely
--     topical, sound instrument.
--   * **Cody Harris** -- coauthor **HB 2361** (local law enforcement + ICE) AND **HB 1832**
--     (entry/reentry penalties, keyed by the committee analysis to prior criminal convictions).
--   * **Dennis Paul** -- coauthor **HB 2361**.
--   * **Cody Vasut** -- coauthor **HB 2390** (municipalities and counties + ICE).
--   * **Joanne Shofner** -- coauthor **HB 2390**.
-- 🔴 **ALL FOUR OF THESE HOUSE BILLS DIED** -- only the Senate vehicle SB 8 was enacted. Every
-- reasoning row below says so explicitly. Coauthoring a bill that died is thinner than Kolkhorst's
-- enacted SB 8 coauthorship in migration 1889, and the prose does not pretend otherwise.
--
-- 🔴🔴 THE REASONING AND SOURCES ARE REPLACED IN THE SAME STATEMENT AS THE CHAIR. Re-seating a chair
-- and leaving the old prose behind is a known, voter-facing defect in this corpus: the blank text
-- ("the instruments on record are not about removal") would render under "Why this position?"
-- directly beneath a chair 4. The generator refuses to emit unless the prose it is about to replace
-- actually begins "Blank in Season 2", and the migration asserts afterwards that no re-seated row
-- still carries blank prose.
--
-- ✅ THE FOUR THAT STAY BLANK -- the negative half of the sweep, and it is stronger than before:
--   * **Paul Dyson** -- 93 bills filed, 5 immigration-adjacent, none about removal. Thinnest of the nine.
--   * **Lacey Hull** -- 221 bills: real property, voter registration, bail, border region. No ICE instrument.
--   * **Phil King** -- 🔴 **NOT an SB 8 coauthor**, though he chairs Homeland and Border Security.
--     Six senators signed on to the session's flagship ICE-cooperation bill -- including Kolkhorst and
--     Middleton, both re-sourced in migration 1889 -- and he was not among them. His Season 1 row
--     seated him at chair 4 partly BECAUSE of that chairmanship; the filed record shows the
--     chairmanship did not come with the session's actual removal-cooperation bill.
--   * **Robert Nichols** -- also not an SB 8 coauthor. SB 16 (author), SB 17 (coauthor), bail bills.
-- This migration ASSERTS all four are still blank, so the split is verifiable from the file.
--
-- ⚖ ONE LINE DELIBERATELY NOT CROSSED. **HJR 16 / SJR 1** -- denial of bail for people without legal
-- status charged with a felony -- appears on six of the nine. It is **pretrial detention, not
-- removal**, and it is NOT treated here as a removal instrument. That is the same line drawn for
-- Middleton in migration 1889, where SJR 1 was cited as context rather than as the seating basis.
-- If that line is ever moved, Hull and Dyson are the rows it would change.
--
-- 🔑 THE SWEEP'S OWN INTEGRITY, since a false zero here would silently preserve nine wrong blanks:
--   * Every one of the 27 reports had its identity header verified against the intended person.
--     **A3580 Harris vs A4205 Harris Davila vs A4085 Harrison** is a live collision in this chamber.
--   * 28 bill entries initially failed caption parsing. Every one that was a bill or a policy
--     resolution was chased individually -- HB 2258 (civil liability re minors), HJR 22 (Article V),
--     and four Israel / Taiwan / monument / medal resolutions. **None immigration-related.** The
--     remainder are HR/SR single-chamber memorial and congratulatory resolutions.
--
-- ⚠ SCOPE LIMIT: this was a FILED-RECORD sweep. No statement hunt was run on these nine -- the kind
-- that turned Middleton from an endorsement blurb into a verbatim quote in migration 1889. Any of
-- the four remaining blanks could still have said something on the record.
--
-- No migration runner exists; this file records SQL applied by hand via scripts/apply-migration-file.mjs.

BEGIN;

DO $$
DECLARE n int;
BEGIN
  -- the five must currently be blank in Season 2, and carrying migration 1888's blank prose
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=0 AND politician_id IN (${ids});
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1890: expected ${ROWS.length} Season 2 blanks to re-seat, found % -- state has moved', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND reasoning LIKE 'Blank in Season 2%';
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1890: only % of ${ROWS.length} rows carry migration 1888 blank prose -- refusing to overwrite', n;
  END IF;

  -- and Season 1 must still hold chair 4 for all nine
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND value=4
     AND politician_id IN (${ids},${blankIdList});
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1890: expected 9 Season 1 chair-4 rows across the cohort, found %', n;
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
   SET value = 4, updated_at = now()
 WHERE a.topic_id = '${TOPIC}'
   AND a.season_id = '${S2}'
   AND a.politician_id IN (${ids});

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=4 AND politician_id IN (${ids});
  IF n <> ${ROWS.length} THEN
    RAISE EXCEPTION 'migration 1890: expected ${ROWS.length} rows at chair 4, found %', n;
  END IF;

  -- 🔴 no re-seated row may still be arguing that it is a blank
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND reasoning LIKE 'Blank in Season 2%';
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1890: % re-seated row(s) still carry blank prose', n;
  END IF;

  -- every re-seated row must cite something
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${ids})
     AND coalesce(cardinality(sources), 0) = 0;
  IF n <> 0 THEN
    RAISE EXCEPTION 'migration 1890: % re-seated row(s) have empty sources', n;
  END IF;

  -- 🔴 the other four stay blank, and keep their blank prose
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND value=0 AND politician_id IN (${blankIdList});
  IF n <> ${STAY_BLANK.length} THEN
    RAISE EXCEPTION 'migration 1890: expected ${STAY_BLANK.length} rows still blank, found %', n;
  END IF;

  SELECT count(*) INTO n FROM inform.politician_context
   WHERE season_id='${S2}' AND topic_id='${TOPIC}' AND politician_id IN (${blankIdList})
     AND reasoning LIKE 'Blank in Season 2%';
  IF n <> ${STAY_BLANK.length} THEN
    RAISE EXCEPTION 'migration 1890: a still-blank row lost its blank prose (% of ${STAY_BLANK.length})', n;
  END IF;

  -- 🔴 Season 1 untouched
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE season_id='${S1}' AND topic_id='${TOPIC}' AND value=4
     AND politician_id IN (${ids},${blankIdList});
  IF n <> 9 THEN
    RAISE EXCEPTION 'migration 1890: Season 1 changed -- % of 9 still at chair 4', n;
  END IF;
END $$;

COMMIT;
`;
fs.writeFileSync(OUT, sql);
console.log(`wrote ${OUT}`);
