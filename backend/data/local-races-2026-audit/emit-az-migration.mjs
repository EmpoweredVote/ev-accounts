#!/usr/bin/env node
// Emit CC_0421 from the committed analysis, so the migration can be regenerated and diffed rather
// than trusted.
//
// What it writes, and why each act is the act it is:
//   1. FIVE RACES MOVE to `AZ 2026 Statewide Primary`. Their contests were on the July ballot and
//      not on the November one -- Pima County's two summary files say so, and the Town of Marana
//      publishes the rule ("A General Election will only be held if one or more Town races are not
//      decided at the Primary Election"). The race row is "what was on a ballot", so it belongs to
//      the election whose ballot carried it.
//   2. SOUTH TUCSON GETS A PRIMARY RACE of its own, because its contest ran at BOTH elections: one
//      seat was filled in July and two in November, and a race row can carry only one election.
//   3. SOUTH TUCSON'S GENERAL RACE KEEPS ITS ROW but its `seats` is corrected 3 -> 2, which is how
//      many seats that ballot actually filled.
//   4. 32 CANDIDACIES are seeded.
//
// 🔴 NO VOTE COUNT GOES INTO ANY CITATION. The house rule from the legislative waves: AP reports
//    zero votes for an uncontested race, so a count formatted into prose has reached production as
//    a falsehood before. result_source names the statute and the publisher, never a number.
//
// 🔴 `result_certainty` IS 'called', NOT 'certified', AND THE DIFFERENCE IS DELIBERATE. Pima
//    publishes a canvass document for the July primary and its live portal labels those results
//    OFFICIAL, so the primary IS canvassed -- but what was established is that a canvass EXISTS,
//    not what it says, because the canvass PDF's result tables are not extractable text. Certifying
//    on a document nobody read is the composed-citation defect wearing a different hat.
//
// 🔴 THE SOUTH TUCSON GENERAL CARRIES NO RESULT AT ALL. Pima has published no canvass for
//    November 3, and the second seat rests on 8 votes. A call needs the bound, and the bound is not
//    legible. The four candidacies are recorded; the outcome is not.
import fs from 'node:fs';

const [analysisPath, outPath] = process.argv.slice(2);
if (!analysisPath || !outPath) { console.error('usage: emit-az-migration.mjs <analysis.json> <out.sql>'); process.exit(2); }

// Our rows, as production held them on 2026-11-14.
const RACE = {
  'Marana Mayor':              { id: '64eb9e2a-5169-4dde-9d64-badca5fcf174', office: 'ac3daf57-c50a-4056-af79-acdda23551df', seats: 1 },
  'Marana Town Council':       { id: 'be35d5c0-f689-43c3-b4ba-295e71984b5a', office: '45bf5933-cde0-41c4-aebb-7dbf8819b358', seats: 4 },
  'Oro Valley Mayor':          { id: '794322b0-f3eb-44c5-81f3-ebb226806245', office: 'b3c8f75c-e8f9-4097-ab14-5790e380f9df', seats: 1 },
  'Oro Valley Town Council':   { id: '3309178b-780a-4009-8af4-58ee754d9550', office: '51669c28-a44d-4770-8dc4-d599f57fa58f', seats: 3 },
  'Sahuarita Town Council':    { id: '4b0ebdad-d321-4e6b-8b68-a583164759f4', office: '10e78a80-bac8-4991-87fd-002651ae7e73', seats: 3 },
  'South Tucson City Council': { id: '31aad1c8-06af-4c8f-821c-21ad89795dc1', office: '1f856023-54dd-4e93-848b-7445ab7823c3', seats: 3 },
};
const SOUTH_TUCSON_PRIMARY_RACE = 'c7f1a6d2-5b84-4a3e-9d21-0e6f4b88c310';   // fixed, so re-running is a no-op

// 🔴 NAMES ARE MAPPED BY HAND, NOT TITLE-CASED. Pima prints "MCGUIRE, JACKIE" and "DESIMONE, CHRIS";
//    mechanical title casing yields "Mcguire" and "Desimone", and "CUBILLO, JD" becomes "Jd". The
//    emitter REFUSES any county name it has no entry for, so a name added later cannot slip through
//    silently mangled. Marana's forms are confirmed against the Town's own published candidate list
//    (maranaaz.gov), which spells Ritz "Susan" where the ballot says "Sue" -- the BALLOT form is
//    kept, because that is the name the voter saw.
const NAME = {
  'POST, JON': ['Jon Post', 'Jon', 'Post'],
  'JOHNSEN, GREG': ['Greg Johnsen', 'Greg', 'Johnsen'],
  'KAI, HERB': ['Herb Kai', 'Herb', 'Kai'],
  'MURPHY, TERI': ['Teri Murphy', 'Teri', 'Murphy'],
  'OFFICER, JOHN': ['John Officer', 'John', 'Officer'],
  'MCGUIRE, JACKIE': ['Jackie McGuire', 'Jackie', 'McGuire'],
  'RITZ, SUE': ['Sue Ritz', 'Sue', 'Ritz'],
  'PRINCE, JULIE': ['Julie Prince', 'Julie', 'Prince'],
  'BARRETT, MELANIE': ['Melanie Barrett', 'Melanie', 'Barrett'],
  'NAPIER, MARK D.': ['Mark D. Napier', 'Mark', 'Napier'],
  'DAILEY, ROSA': ['Rosa Dailey', 'Rosa', 'Dailey'],
  'PINA, RHONDA': ['Rhonda Pina', 'Rhonda', 'Pina'],
  'WOOD, MATT': ['Matt Wood', 'Matt', 'Wood'],
  'DESIMONE, CHRIS': ['Chris DeSimone', 'Chris', 'DeSimone'],
  'HERRINGTON, JACOB "JAKE"': ['Jacob "Jake" Herrington', 'Jacob', 'Herrington'],
  'MORALES, DEBORAH': ['Deborah Morales', 'Deborah', 'Morales'],
  'MURPHY, TOM': ['Tom Murphy', 'Tom', 'Murphy'],
  'HUNDAL, CHELSEA': ['Chelsea Hundal', 'Chelsea', 'Hundal'],
  'CUBILLO, JD': ['JD Cubillo', 'JD', 'Cubillo'],
  'EARL, ROBIN': ['Robin Earl', 'Robin', 'Earl'],
  'VALENZUELA, ROXANNA': ['Roxanna Valenzuela', 'Roxanna', 'Valenzuela'],
  'AGUIRRE, CESAR': ['Cesar Aguirre', 'Cesar', 'Aguirre'],
  'FEDERICO, DEBBIE': ['Debbie Federico', 'Debbie', 'Federico'],
  'FLAGG, BRIAN': ['Brian Flagg', 'Brian', 'Flagg'],
  'BACA, EDUARDO': ['Eduardo Baca', 'Eduardo', 'Baca'],
  'COOK, ZEKE': ['Zeke Cook', 'Zeke', 'Cook'],
  'MORENO-SEARS, DIANA': ['Diana Moreno-Sears', 'Diana', 'Moreno-Sears'],
  'DODSON, CHRISTOPHER': ['Christopher Dodson', 'Christopher', 'Dodson'],
};

// ⚠ An incumbency flag is a claim that THIS candidate holds THIS seat, so it is written only where
//   our own office_current_holder names that person. Three do; everyone else is false, including
//   Oro Valley's retiring mayor and the Sahuarita and Oro Valley council holders, who did not run.
const INCUMBENT = new Set(['Marana Mayor|Jon Post', 'Marana Town Council|John Officer',
  'South Tucson City Council|Brian Flagg']);

const SRC_PRIMARY = 'Pima County Elections, 2026 Primary Election Summary Results (county totals); A.R.S. 9-821.01(D),(F),(G)';
const SRC_GENERAL = 'Pima County Elections, 2026 General Election Summary Results (county totals); A.R.S. 9-821.01(H)';
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const slug = (s) => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

const analysis = JSON.parse(fs.readFileSync(analysisPath, 'utf8'));
const rows = [];
for (const c of analysis.contests) {
  for (const r of c.rows) {
    const nm = NAME[r.name];
    if (!nm) throw new Error(`no hand-checked name for ${JSON.stringify(r.name)} -- add it rather than letting it be title-cased`);
    const isPrimary = r.election.startsWith('primary');
    const raceId = isPrimary
      ? (c.contest === 'South Tucson City Council' ? SOUTH_TUCSON_PRIMARY_RACE : RACE[c.contest].id)
      : RACE[c.contest].id;
    // The South Tucson GENERAL is not called: the candidacy is recorded, the outcome is not.
    const withhold = !isPrimary && c.contest === 'South Tucson City Council';
    rows.push({
      raceId, contest: c.contest, election: isPrimary ? '2026-07-21' : '2026-11-03',
      full: nm[0], first: nm[1], last: nm[2],
      result: withhold ? null : r.result,
      certainty: withhold ? null : (r.result === 'won' ? 'called' : null),
      source: isPrimary ? SRC_PRIMARY : SRC_GENERAL,
      externalId: `pima-${isPrimary ? '2026-07-21' : '2026-11-03'}-${slug(c.contest)}-${slug(nm[0])}`,
      incumbent: INCUMBENT.has(`${c.contest}|${nm[0]}`),
    });
  }
}

const values = rows.map((r) => `  (${[
  q(r.raceId), q(r.full), q(r.first), q(r.last), r.incumbent ? 'true' : 'false',
  q('active'), q(r.externalId), q(r.source),
  r.result ? q(r.result) : 'NULL',
  r.result ? q(r.source) : 'NULL',
  r.certainty ? q(r.certainty) : 'NULL',
].join(', ')})`).join(',\n');

const moved = ['Marana Mayor', 'Marana Town Council', 'Oro Valley Mayor', 'Oro Valley Town Council', 'Sahuarita Town Council'];

const sql = `-- CC_0421: Arizona's town contests sit on the election that actually held them
--
-- Generated by backend/data/local-races-2026-audit/emit-az-migration.mjs from
-- az-analysis-2026-11-14.json. Regenerate and diff rather than editing this file by hand.
--
-- WHAT IS WRONG
-- We hold six 2026-11-03 races for Pima County towns and every one of them is empty. Five of the
-- six contests were never on the November ballot at all: Arizona lets a town elect at the primary,
-- and these were decided there on 2026-07-21. The sixth, South Tucson, ran at BOTH elections.
--
-- THE EVIDENCE
--  * Pima County's own summary files. The five contests are present in the 2026 Primary file and
--    absent from the 2026 General file, where Oro Valley's only entry is Proposition 431.
--  * The Town of Marana publishes the rule, answering "Will there be a General Election?":
--    "Maybe. A General Election will only be held if one or more Town races are not decided at the
--    Primary Election."
--  * The Town of Oro Valley publishes both the seat count and the date: "three Councilmember seats
--    and one mayoral seat up for election for the July 21, 2026, Primary Election", the date having
--    moved there under HB2022.
--  * A.R.S. 9-821.01(F) fixes the majority threshold, (G) seats the highest vote-getters when more
--    clear it than there are seats, and (H) advances twice the open seats to the general.
--
-- 🔴 WRITE-INS ARE OUTSIDE THE (F) DENOMINATOR, WHICH COUNTS ONLY CANDIDATES "LAWFULLY ON THE
--    BALLOT". Marana's aggregate write-in line alone is 4,680 votes and would have moved the bar
--    for every candidate in that contest.
--
-- 🔴🔴 SOUTH TUCSON WAS DECIDED IN TWO PARTS, AND THE BALLOT ITSELF PROVES IT. Roxanna Valenzuela
--    cleared the (F) majority in July and took one of the three seats there, leaving two. (H)
--    advances twice the open seats -- and South Tucson's general ballot carries FOUR names, which
--    is twice two and not twice three. So the general elected only its top two. An earlier reading
--    of this contest put all three seats in November and would have recorded Debbie Federico as
--    elected; she came third, by 8 votes.
--
-- ⚠ (D) DECLARES A PRIMARY WINNER ELECTED "EFFECTIVE AS OF THE DATE OF THE GENERAL ELECTION". That
--   is a fact about the TERM, not about which ballot carried the contest, and nothing here seats
--   anybody.
--
-- 🔴 OVERWRITTEN VALUES, RECORDED HERE BECAUSE NOTHING ELSE RECORDS THEM:
--      races.election_id for the five moved races was the AZ 2026 Statewide General (2026-11-03);
--      it becomes the AZ 2026 Statewide Primary (2026-07-21).
--      races.seats for South Tucson City Council (31aad1c8-06af-4c8f-821c-21ad89795dc1) was 3;
--      it becomes 2, the number of seats that ballot filled.
--
-- 🔴 result_certainty IS 'called', NOT 'certified'. Pima publishes a canvass for the July primary
--    and its portal labels those results OFFICIAL, so the primary is canvassed -- but what was
--    established is that a canvass EXISTS, not what it says, because that document's result tables
--    are not extractable text. Certifying on a document nobody read is a composed citation.
--
-- 🔴 THE SOUTH TUCSON GENERAL GETS NO RESULT. Pima has published no canvass for 2026-11-03 and the
--    second seat rests on 8 votes; its ballots-processed reports suffer the same column drift as
--    every other PDF in this programme, so the bound is not legible. The four candidacies are
--    recorded and the outcome is not. ▶ Revisit after Pima canvasses.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The five contests that ran only at the primary move to it.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.races
   SET election_id = (SELECT id FROM essentials.elections WHERE state = 'AZ' AND name = 'AZ 2026 Statewide Primary')
 WHERE id IN (${moved.map((m) => `'${RACE[m].id}'`).join(',\n                ')});

-- ---------------------------------------------------------------------------------------------
-- 2. South Tucson ran at both. Give the primary contest its own race row.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats)
SELECT '${SOUTH_TUCSON_PRIMARY_RACE}',
       (SELECT id FROM essentials.elections WHERE state = 'AZ' AND name = 'AZ 2026 Statewide Primary'),
       '${RACE['South Tucson City Council'].office}',
       'South Tucson City Council', NULL, 3
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races WHERE id = '${SOUTH_TUCSON_PRIMARY_RACE}');

-- ---------------------------------------------------------------------------------------------
-- 3. The general filled two of its three seats, not three.
-- ---------------------------------------------------------------------------------------------
UPDATE essentials.races SET seats = 2
 WHERE id = '${RACE['South Tucson City Council'].id}' AND seats <> 2;

-- ---------------------------------------------------------------------------------------------
-- 4. The ballots.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, external_id, source,
   result, result_source, result_certainty)
VALUES
${values}
-- ⚠ The unique index on external_id is PARTIAL (it carries WHERE external_id IS NOT NULL), so the
--   conflict target has to repeat that predicate; without it Postgres refuses with "no unique or
--   exclusion constraint matching the ON CONFLICT specification" and the whole insert fails.
ON CONFLICT (external_id) WHERE external_id IS NOT NULL DO NOTHING;

-- ---------------------------------------------------------------------------------------------
-- 5. Post-verify, on the end state and on the delta.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_primary uuid; v_general uuid;
  v_moved int; v_seats int; v_rows int; v_won int; v_adv int; v_notnom int; v_null int;
  v_general_empty int; v_unflagged int;
BEGIN
  SELECT id INTO v_primary FROM essentials.elections WHERE state='AZ' AND name='AZ 2026 Statewide Primary';
  SELECT id INTO v_general FROM essentials.elections WHERE state='AZ' AND name='AZ 2026 Statewide General';

  SELECT count(*) INTO v_moved FROM essentials.races
   WHERE id IN (${moved.map((m) => `'${RACE[m].id}'`).join(', ')}) AND election_id = v_primary;
  IF v_moved <> 5 THEN RAISE EXCEPTION 'CC_0421: % of the 5 town races sit on the primary, expected 5.', v_moved; END IF;

  SELECT seats INTO v_seats FROM essentials.races WHERE id = '${RACE['South Tucson City Council'].id}';
  IF v_seats <> 2 THEN RAISE EXCEPTION 'CC_0421: South Tucson general seats reads %, expected 2.', v_seats; END IF;

  SELECT count(*) INTO v_rows FROM essentials.race_candidates rc
   WHERE rc.external_id LIKE 'pima-2026-%';
  IF v_rows <> ${rows.length} THEN RAISE EXCEPTION 'CC_0421: % pima candidacies, expected ${rows.length}.', v_rows; END IF;

  SELECT count(*) FILTER (WHERE result='won'), count(*) FILTER (WHERE result='advanced'),
         count(*) FILTER (WHERE result='not_nominated'), count(*) FILTER (WHERE result IS NULL)
    INTO v_won, v_adv, v_notnom, v_null
    FROM essentials.race_candidates WHERE external_id LIKE 'pima-2026-%';
  IF v_won <> ${rows.filter((r) => r.result === 'won').length}
     OR v_adv <> ${rows.filter((r) => r.result === 'advanced').length}
     OR v_notnom <> ${rows.filter((r) => r.result === 'not_nominated').length}
     OR v_null <> ${rows.filter((r) => r.result === null).length} THEN
    RAISE EXCEPTION 'CC_0421: results read won=% advanced=% not_nominated=% null=%, expected ${rows.filter((r) => r.result === 'won').length}/${rows.filter((r) => r.result === 'advanced').length}/${rows.filter((r) => r.result === 'not_nominated').length}/${rows.filter((r) => r.result === null).length}.',
      v_won, v_adv, v_notnom, v_null;
  END IF;

  -- Not one citation may carry a vote count. The legislative waves put 55 such rows into
  -- production before this gate existed.
  IF EXISTS (SELECT 1 FROM essentials.race_candidates
              WHERE external_id LIKE 'pima-2026-%' AND result_source ~ '[0-9][0-9,]* votes') THEN
    RAISE EXCEPTION 'CC_0421: a result_source carries a vote count.';
  END IF;

  -- The AZ 2026 general must now hold exactly one of these town races -- South Tucson's -- and it
  -- must carry a ballot. The other five have left.
  SELECT count(*) INTO v_general_empty
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE r.election_id = v_general AND lower(d.state) = 'az'
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id);
  IF v_general_empty <> 0 THEN
    RAISE EXCEPTION 'CC_0421: % Arizona races on the 2026 general still carry no candidate.', v_general_empty;
  END IF;

  -- Occupancy is untouched: this wave records candidacies, and seats nobody.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN RAISE EXCEPTION 'CC_0421: drift baseline reads %, not 238.', v_unflagged; END IF;

  RAISE NOTICE 'CC_0421 OK: 5 races moved to the 2026-07-21 primary, South Tucson split across both, % candidacies (won % / advanced % / not_nominated % / no result %), no Arizona race left empty on the general, drift baseline 238.',
    v_rows, v_won, v_adv, v_notnom, v_null;
END $$;

COMMIT;
`;

fs.writeFileSync(outPath, sql);
console.log(`wrote ${outPath}: ${rows.length} candidacies — won ${rows.filter((r) => r.result === 'won').length}, advanced ${rows.filter((r) => r.result === 'advanced').length}, not_nominated ${rows.filter((r) => r.result === 'not_nominated').length}, no result ${rows.filter((r) => r.result === null).length}`);
