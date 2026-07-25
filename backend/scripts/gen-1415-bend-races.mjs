/**
 * gen-1415-bend-races.mjs — emits migrations/1415_bend_or_2026_races_candidates.sql
 *
 * Run: node scripts/gen-1415-bend-races.mjs
 */
import { writeFileSync } from 'fs';

const MIG = '1415';
const ELECTION = 'OR 2026 General'; // 2026-11-03, already in essentials.elections

const CITY_GOV = 'City of Bend, Oregon, US';
const COUNTY_GOV = 'Deschutes County, Oregon, US';

const SRC_CITY = 'https://bendoregon.gov/city-council/elections/';
const SRC_COUNTY = 'https://www.deschutescounty.gov/1593/November-3-2026-General-Election';
const SRC_BP53 = 'https://ballotpedia.org/Oregon_House_of_Representatives_District_53';
const SRC_BP54 = 'https://ballotpedia.org/Oregon_House_of_Representatives_District_54';

// ---------------------------------------------------------------------------
// New challenger politician rows (12). Bands:
//   -41058 3x  Bend city candidates      (city officials are -41058 0x, park board -41058 2x)
//   -41017 2x  Deschutes county candidates (commissioners -41017 0x, row officers -41017 1x)
//   -41290 xx  OR state-legislative non-incumbent candidates (incumbents are -41200 NN by district)
// ---------------------------------------------------------------------------
const CANDIDATE_POLS = [
  { ext: -4105831, name: 'Ron (Rondo) Boozell', first: 'Ron', last: 'Boozell' },
  { ext: -4105832, name: 'Bobbi Cummiskey', first: 'Bobbi', last: 'Cummiskey' },
  { ext: -4105833, name: 'Elana Reinholtz', first: 'Elana', last: 'Reinholtz' },
  { ext: -4105834, name: 'Dan Sorrells', first: 'Dan', last: 'Sorrells' },
  { ext: -4101721, name: 'Lauren Connally', first: 'Lauren', last: 'Connally' },
  { ext: -4101722, name: 'Amy Sabbadini', first: 'Amy', last: 'Sabbadini' },
  { ext: -4101723, name: 'Rob Imhoff', first: 'Rob', last: 'Imhoff' },
  { ext: -4101724, name: 'Morgan Schmidt', first: 'Morgan', last: 'Schmidt' },
  { ext: -4101725, name: 'Jonathan Curtis', first: 'Jonathan', last: 'Curtis' },
  { ext: -4101726, name: 'James (Mac) McLaughlin', first: 'James', last: 'McLaughlin' },
  { ext: -4101727, name: 'Robert Tintle', first: 'Robert', last: 'Tintle' },
  { ext: -4129001, name: 'Michael Summers', first: 'Michael', last: 'Summers' },
];

// ---------------------------------------------------------------------------
// Races. `anchor` identifies the office the race hangs off:
//   {holder: ext}  -> the office currently held by that politician
//   {vacantTitle}  -> the vacant office row created in Step 1
//   {existing: position_name} -> race row already exists; only candidates are added
// ---------------------------------------------------------------------------
const RACES = [
  { pos: 'Bend Mayor', anchor: { holder: -4105801 }, src: SRC_CITY,
    cands: [ { ext: -4105801, inc: true }, { ext: -4105831, inc: false } ] },
  { pos: 'Bend City Council Position 5', anchor: { holder: -4105806 }, src: SRC_CITY,
    cands: [ { ext: -4105806, inc: true } ] },
  { pos: 'Bend City Council Position 6', anchor: { holder: -4105807 }, src: SRC_CITY,
    cands: [ { ext: -4105832, inc: false }, { ext: -4105833, inc: false }, { ext: -4105834, inc: false } ] },
  { pos: 'Deschutes County Commissioner Position 3', anchor: { holder: -4101703 }, src: SRC_COUNTY,
    cands: [ { ext: -4101721, inc: false }, { ext: -4101722, inc: false } ] },
  { pos: 'Deschutes County Commissioner Position 5', anchor: { vacantTitle: 'Commissioner, Position 5' }, src: SRC_COUNTY,
    cands: [ { ext: -4101723, inc: false }, { ext: -4101724, inc: false } ] },
  { pos: 'Deschutes County Clerk', anchor: { holder: -4101711 }, src: SRC_COUNTY,
    cands: [ { ext: -4101711, inc: true }, { ext: -4101725, inc: false } ] },
  { pos: 'Deschutes County Sheriff', anchor: { holder: -4101714 }, src: SRC_COUNTY,
    cands: [ { ext: -4101714, inc: true }, { ext: -4101726, inc: false } ] },
  { pos: 'Deschutes County Treasurer', anchor: { holder: -4101713 }, src: SRC_COUNTY,
    cands: [ { ext: -4101727, inc: false } ] },
  { pos: 'OR State House District 53', anchor: { existing: true }, src: SRC_BP53,
    cands: [ { ext: -4120053, inc: true }, { ext: -4129001, inc: false } ] },
  { pos: 'OR State House District 54', anchor: { existing: true }, src: SRC_BP54,
    cands: [ { ext: -4120054, inc: true } ] },
];

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const electionSel = `(SELECT id FROM essentials.elections WHERE name = ${q(ELECTION)} AND election_date = DATE '2026-11-03')`;
const raceSel = (pos) => `(SELECT id FROM essentials.races WHERE election_id = ${electionSel} AND position_name = ${q(pos)})`;
const polSel = (ext) => `(SELECT id FROM essentials.politicians WHERE external_id = ${ext})`;
const officeOfHolder = (ext) => `(SELECT o.id FROM essentials.offices o WHERE o.politician_id = ${polSel(ext)})`;
const vacantOfficeSel = (title) =>
  `(SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE o.title = ${q(title)}
       AND c.name = 'Board of County Commissioners'
       AND c.government_id = (SELECT id FROM essentials.governments WHERE name = ${q(COUNTY_GOV)}))`;

const nameOf = (ext) => {
  const c = CANDIDATE_POLS.find((p) => p.ext === ext);
  if (c) return c;
  const KNOWN = {
    '-4105801': { name: 'Melanie Kebler', first: 'Melanie', last: 'Kebler' },
    '-4105806': { name: 'Ariel Méndez', first: 'Ariel', last: 'Méndez' },
    '-4101711': { name: 'Steve Dennison', first: 'Steve', last: 'Dennison' },
    '-4101714': { name: 'Ty Rupert', first: 'Ty', last: 'Rupert' },
    '-4120053': { name: 'Emerson Levy', first: 'Emerson', last: 'Levy' },
    '-4120054': { name: 'Jason Kropf', first: 'Jason', last: 'Kropf' },
  };
  const k = KNOWN[String(ext)];
  if (!k) throw new Error(`no name for external_id ${ext}`);
  return k;
};

const newRaces = RACES.filter((r) => !r.anchor.existing);
const allCandRows = RACES.flatMap((r) => r.cands.map((c) => ({ ...c, pos: r.pos, src: r.src })));

const sql = `-- Migration ${MIG}: Bend, OR deep seed — November 3, 2026 races + candidates
--
-- Depends on migration 1414 (Bend/Deschutes governments, offices, officials).
--
-- Adds to the existing '${ELECTION}' election (2026-11-03):
--   ${newRaces.length} NEW races: 3 City of Bend (Mayor, Council Positions 5 and 6) +
--                 5 Deschutes County (Commissioner Positions 3 and 5, Clerk, Sheriff, Treasurer)
--   ${CANDIDATE_POLS.length} NEW candidate politician rows (non-incumbent challengers)
--   ${allCandRows.length} race_candidates rows, including candidates for the two PRE-EXISTING
--                 OR State House District 53/54 races (both had zero candidates before this)
--   1 dual-PID merge (Patti Adair)
--
-- BALLOT ACCURACY NOTES (sourced in data/stance-research/bend-or/00-ROSTER-RESEARCH.md):
--   * Every county office in Deschutes is NONPARTISAN, as are all City of Bend offices:
--     races.primary_party stays NULL. HD 53/54 are partisan but their party nominees were already
--     settled in the May 19 2026 primary, so these are general-election rows, not primary rows.
--   * City filing closes 2026-08-25 (non-incumbents) and withdrawal closes 2026-08-28, so this
--     candidate field is PROVISIONAL. Incumbent Councilor Mike Riley (Position 6) had NOT filed
--     as of 2026-07-24 — his race therefore carries three non-incumbent candidates and no
--     incumbent. A dated re-check is filed at
--     .planning/todos/2026-07-24-bend-or-postfiling-recheck.md.
--   * Commissioner Position 5 is one of TWO seats created by the 2024 board-expansion measure.
--     Nobody holds it until January 2027, so Step 1 creates VACANT office rows for Positions 4
--     and 5 (politician_id NULL -> they never appear in the officials feed, which INNER JOINs
--     politicians) purely so the race has a non-NULL office_id. Position 4 was decided in the May
--     primary and has no November race; it is created only so the chamber's 5 seats are all
--     represented. Commissioner Position 1 (won outright in May by Jamie Collins) and the
--     Assessor race likewise have NO November row — do not add them.
--   * SD 27 is deliberately absent: Anthony Broadman was elected Nov 2024 to a term running
--     through January 2029, so Bend has no 2026 Senate race. (The DB nonetheless contains
--     2026-11-03 rows for all 30 OR Senate districts — a pre-existing defect logged at
--     .planning/todos/2026-07-24-or-senate-2026-phantom-races.md. Not touched here.)
--
-- DUAL-PID MERGE (Patti Adair): the OR-05 congressional seeding created politician -410501
-- ("Patti Adair", no office, 1 headshot, linked to the U.S. House OR-05 race). Migration 1414
-- created -4101703 for the same person as the sitting Deschutes County Commissioner Position 3.
-- One human must be one politician row, so this migration repoints the OR-05 race_candidates row
-- and the headshot at -4101703 (the row that carries the office) and deactivates -410501.
-- Party is intentionally left NULL: she is the Republican OR-05 nominee, but her county office is
-- nonpartisan and candidate cards never render party.

BEGIN;

DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.races r
      WHERE r.election_id = ${electionSel}
        AND r.position_name LIKE 'Bend %') > 0 THEN
    RAISE EXCEPTION 'Migration ${MIG} already applied (Bend races exist) — aborting re-run';
  END IF;
  IF (SELECT COUNT(*) FROM essentials.governments WHERE name = ${q(CITY_GOV)}) <> 1 THEN
    RAISE EXCEPTION 'Migration ${MIG} requires migration 1414 (City of Bend government missing)';
  END IF;
  IF ${electionSel} IS NULL THEN
    RAISE EXCEPTION 'Migration ${MIG}: election ${ELECTION} (2026-11-03) not found';
  END IF;
END $$;


-- =============================================================================
-- Step 1: vacant office rows for the two NEW Deschutes commissioner seats,
--         and widen the chamber to its post-2026 authorized size of 5.
-- =============================================================================
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, vacant_since, description)
SELECT gen_random_uuid(), d.id,
       (SELECT id FROM essentials.chambers
        WHERE name = 'Board of County Commissioners'
          AND government_id = (SELECT id FROM essentials.governments WHERE name = ${q(COUNTY_GOV)})),
       NULL, v.title, 'OR', NULL, false, true, TIMESTAMPTZ '2026-01-01',
       'Seat created by the 2024 voter-approved expansion of the Deschutes County Board of Commissioners from three to five members; first filled January 2027.'
FROM essentials.districts d
CROSS JOIN (VALUES ('Commissioner, Position 4'), ('Commissioner, Position 5')) AS v(title)
WHERE d.geo_id = '41017' AND d.district_type = 'COUNTY' AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    WHERE o.title = v.title
      AND c.name = 'Board of County Commissioners'
      AND c.government_id = (SELECT id FROM essentials.governments WHERE name = ${q(COUNTY_GOV)})
  );

UPDATE essentials.chambers
SET official_count = 5,
    remarks = 'Three members served through 2026; voters expanded the board to five seats effective with the 2026 election (Positions 4 and 5 first filled January 2027).'
WHERE name = 'Board of County Commissioners'
  AND government_id = (SELECT id FROM essentials.governments WHERE name = ${q(COUNTY_GOV)});


-- =============================================================================
-- Step 2: ${newRaces.length} new races (nonpartisan -> primary_party NULL, single seat each)
-- =============================================================================
${newRaces
  .map((r) => {
    const office = r.anchor.holder ? officeOfHolder(r.anchor.holder) : vacantOfficeSel(r.anchor.vacantTitle);
    return `INSERT INTO essentials.races (id, election_id, office_id, position_name, primary_party, seats, description, created_at, updated_at)
SELECT gen_random_uuid(), ${electionSel}, ${office}, ${q(r.pos)}, NULL, 1, NULL, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM essentials.races
                  WHERE election_id = ${electionSel} AND position_name = ${q(r.pos)});
`;
  })
  .join('\n')}

-- =============================================================================
-- Step 3: ${CANDIDATE_POLS.length} challenger politician rows
--   is_incumbent=false (they hold none of these offices); no office_id — a candidate is not an
--   officeholder, and seeding officeholder-titled offices for candidates is what caused the
--   Senate candidate-office leak (migs 1323-1327).
-- =============================================================================
${CANDIDATE_POLS.map(
  (c) => `INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
SELECT gen_random_uuid(), ${q(c.name)}, ${q(c.first)}, ${q(c.last)}, NULL, true, false, false, false, ${c.ext}
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = ${c.ext});
`,
).join('')}

-- =============================================================================
-- Step 4: ${allCandRows.length} race_candidates rows
-- =============================================================================
${allCandRows
  .map((c) => {
    const n = nameOf(c.ext);
    return `INSERT INTO essentials.race_candidates
  (id, race_id, politician_id, full_name, first_name, last_name, is_incumbent,
   candidate_status, source, last_verified_at, created_at, updated_at)
SELECT gen_random_uuid(), ${raceSel(c.pos)}, ${polSel(c.ext)},
       ${q(n.name)}, ${q(n.first)}, ${q(n.last)}, ${c.inc}, 'active', ${q(c.src)}, NOW(), NOW(), NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates
  WHERE race_id = ${raceSel(c.pos)} AND politician_id = ${polSel(c.ext)}
);
`;
  })
  .join('')}

-- =============================================================================
-- Step 5: Patti Adair dual-PID merge (-410501 -> -4101703)
-- =============================================================================
UPDATE essentials.race_candidates
SET politician_id = ${polSel(-4101703)}, updated_at = NOW()
WHERE politician_id = ${polSel(-410501)};

UPDATE essentials.politician_images
SET politician_id = ${polSel(-4101703)}
WHERE politician_id = ${polSel(-410501)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi2
    WHERE pi2.politician_id = ${polSel(-4101703)}
  );

UPDATE essentials.politicians
SET photo_origin_url = COALESCE(photo_origin_url, (SELECT photo_origin_url FROM essentials.politicians WHERE external_id = -410501))
WHERE external_id = -4101703;

UPDATE essentials.politicians
SET is_active = false,
    notes = COALESCE(notes, ARRAY[]::text[]) ||
            ARRAY['Duplicate identity retired 2026-07-24 by migration ${MIG}: merged into external_id -4101703 (Patti Adair, Deschutes County Commissioner Position 3 and Republican nominee for U.S. House OR-05).']::text[]
WHERE external_id = -410501;


-- =============================================================================
-- Post-verification
-- =============================================================================
DO $$
DECLARE
  v_races     INTEGER;
  v_null_off  INTEGER;
  v_cands     INTEGER;
  v_hd53      INTEGER;
  v_hd54      INTEGER;
  v_p6_inc    INTEGER;
  v_adair_dup INTEGER;
  v_adair_or5 INTEGER;
  v_vacant    INTEGER;
BEGIN
  -- Bend + Deschutes races created
  SELECT COUNT(*) INTO v_races FROM essentials.races r
  WHERE r.election_id = ${electionSel}
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %');
  IF v_races <> ${newRaces.length} THEN
    RAISE EXCEPTION 'FAILED: Bend/Deschutes race count=%, expected ${newRaces.length}', v_races;
  END IF;

  -- no race may have a NULL office_id
  SELECT COUNT(*) INTO v_null_off FROM essentials.races r
  WHERE r.election_id = ${electionSel}
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %')
    AND r.office_id IS NULL;
  IF v_null_off <> 0 THEN
    RAISE EXCEPTION 'FAILED: % Bend/Deschutes races have NULL office_id', v_null_off;
  END IF;

  -- candidate rows, all politician-linked
  SELECT COUNT(*) INTO v_cands FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.election_id = ${electionSel}
    AND (r.position_name LIKE 'Bend %' OR r.position_name LIKE 'Deschutes County %')
    AND rc.politician_id IS NOT NULL;
  IF v_cands <> ${allCandRows.filter((c) => !c.pos.startsWith('OR State')).length} THEN
    RAISE EXCEPTION 'FAILED: Bend/Deschutes candidate count=%, expected ${allCandRows.filter((c) => !c.pos.startsWith('OR State')).length}', v_cands;
  END IF;

  -- the two previously-empty state house races are now populated
  SELECT COUNT(*) INTO v_hd53 FROM essentials.race_candidates rc
  WHERE rc.race_id = ${raceSel('OR State House District 53')};
  IF v_hd53 <> 2 THEN RAISE EXCEPTION 'FAILED: HD 53 candidates=%, expected 2', v_hd53; END IF;

  SELECT COUNT(*) INTO v_hd54 FROM essentials.race_candidates rc
  WHERE rc.race_id = ${raceSel('OR State House District 54')};
  IF v_hd54 <> 1 THEN RAISE EXCEPTION 'FAILED: HD 54 candidates=%, expected 1', v_hd54; END IF;

  -- Position 6 must have NO incumbent candidate (Riley had not filed as of 2026-07-24)
  SELECT COUNT(*) INTO v_p6_inc FROM essentials.race_candidates rc
  WHERE rc.race_id = ${raceSel('Bend City Council Position 6')} AND rc.is_incumbent;
  IF v_p6_inc <> 0 THEN
    RAISE EXCEPTION 'FAILED: Bend Position 6 has % incumbent candidate(s), expected 0', v_p6_inc;
  END IF;

  -- dual-PID merge complete: the retired row is inactive and holds no race links
  SELECT COUNT(*) INTO v_adair_dup FROM essentials.race_candidates rc
  WHERE rc.politician_id = ${polSel(-410501)};
  IF v_adair_dup <> 0 THEN
    RAISE EXCEPTION 'FAILED: retired Adair row still has % race link(s)', v_adair_dup;
  END IF;

  SELECT COUNT(*) INTO v_adair_or5 FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.position_name = 'U.S. House OR-05' AND rc.politician_id = ${polSel(-4101703)};
  IF v_adair_or5 <> 1 THEN
    RAISE EXCEPTION 'FAILED: canonical Adair row has % OR-05 candidate link(s), expected 1', v_adair_or5;
  END IF;

  -- vacant commissioner seats exist and are unfilled
  SELECT COUNT(*) INTO v_vacant FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE c.name = 'Board of County Commissioners'
    AND c.government_id = (SELECT id FROM essentials.governments WHERE name = ${q(COUNTY_GOV)})
    AND o.is_vacant AND o.politician_id IS NULL;
  IF v_vacant <> 2 THEN
    RAISE EXCEPTION 'FAILED: vacant commissioner offices=%, expected 2', v_vacant;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: races=${newRaces.length}, candidates=${allCandRows.length} (HD53=2, HD54=1), P6 incumbents=0, Adair merged, 2 vacant commissioner seats';
END $$;

-- Ledger entry for '${MIG}' is registered separately as the postgres role (the Session pooler
-- role used by psql has no privileges on the supabase_migrations schema).

COMMIT;
`;

const out = `${import.meta.dirname}/../migrations/${MIG}_bend_or_2026_races_candidates.sql`;
writeFileSync(out, sql);
console.log(`wrote ${out}`);
console.log(`  new races: ${newRaces.length}, new candidate politicians: ${CANDIDATE_POLS.length}, race_candidates: ${allCandRows.length}`);
