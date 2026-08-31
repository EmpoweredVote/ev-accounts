#!/usr/bin/env node
/**
 * gen-fl-legislature-migrations.mjs
 *
 * Emits the two Florida Legislature seeding migrations from
 * data/fl-legislature-roster.json.
 *
 *   migrations/CC_wip_fl_legislature_structure.sql   2 chambers + 160 offices
 *   migrations/CC_wip_fl_legislature_incumbents.sql  155 politicians + 155 terms
 *
 * 🔴 160 OFFICES BUT 155 PEOPLE. Measured 2026-08-28: the Florida House has 116
 * sitting members and 4 seats awaiting a special election (HD-55, 78, 113, 116); the
 * Senate has 39 and 1 (SD-39). The FL-2 plan assumed 160/160. Every count below comes
 * from the roster file, never from a hardcoded 160.
 *
 * 🔴 THE 5 VACANT OFFICES ARE FLAGGED is_vacant IN THE STRUCTURE MIGRATION, NOT LATER.
 * Two reasons, both load-bearing:
 *   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as
 *      `reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0`.
 *      An unflagged empty office fires a NEW fl|STATE_LOWER bucket and fails the gate.
 *   2. essentials.offices_missing_terms separates flagged-vacant rows from unflagged
 *      ones, and only the unflagged count is drift. Measured before this wave: 814
 *      total / 159 flagged / 655 unflagged. Flagging in the structure migration keeps
 *      the unflagged count at 655 even in the window between the two applies.
 *
 * Split in two to match the WA (1742/1743), CO (1843/1844) and NC (CA_0004/0005)
 * precedent: structure is stable, occupancy churns with every vacancy, and keeping
 * them apart means a re-seat never has to re-run office creation.
 *
 * Files are emitted as `CC_wip_` on purpose. MIGRATION NUMBERS ARE TAKEN LAST,
 * immediately before applying, in Chris Cantrell's CC_ namespace. This script does
 * NOT apply anything and does NOT touch the database.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/gen-fl-legislature-migrations.mjs
 */

import fs from 'node:fs';

const ROSTER = JSON.parse(fs.readFileSync('data/fl-legislature-roster.json', 'utf8'));
const SEATS = ROSTER.seats;
const VACANCIES = ROSTER.vacancies;
const RETRIEVED = ROSTER.retrievedAt;

const GOV_ID = '623ac987-c7bc-4da1-8112-68adaec10cb2'; // State of Florida — ALREADY EXISTS
const HOUSE_NAME = 'Florida House of Representatives';
const SENATE_NAME = 'Florida Senate';

// ── Derived counts. Asserted, never assumed. ────────────────────────────────
const lower = SEATS.filter((s) => s.chamber === 'lower');
const upper = SEATS.filter((s) => s.chamber === 'upper');
const lowerVac = VACANCIES.filter((v) => v.chamber === 'lower');
const upperVac = VACANCIES.filter((v) => v.chamber === 'upper');

const N_LOWER_OFFICES = lower.length + lowerVac.length;
const N_UPPER_OFFICES = upper.length + upperVac.length;
const N_OFFICES = N_LOWER_OFFICES + N_UPPER_OFFICES;
const N_PEOPLE = SEATS.length;
const N_VACANT = VACANCIES.length;

function die(msg) {
  console.error(`FATAL: ${msg}`);
  process.exit(1);
}
if (N_LOWER_OFFICES !== 120) die(`House offices = ${N_LOWER_OFFICES}, expected 120. Re-run build-fl-legislature-roster.mjs.`);
if (N_UPPER_OFFICES !== 40) die(`Senate offices = ${N_UPPER_OFFICES}, expected 40. Re-run build-fl-legislature-roster.mjs.`);
if (N_OFFICES !== 160) die(`offices = ${N_OFFICES}, expected 160`);
if (N_PEOPLE + N_VACANT !== 160) die(`${N_PEOPLE} people + ${N_VACANT} vacancies != 160 offices`);

/**
 * SQL string literal. Escapes single quotes only -- the sole SQL-meaningful character
 * inside a single-quoted literal. Double quotes (Michael A. "Mike" Caruso) and
 * non-ASCII (Fabián Basabe, Johanna López, Susan L. Valdés) pass through untouched:
 * this is a byte-for-byte pass of the name into the literal, never a normalisation.
 * The NFD-stripping helper in build-fl-legislature-roster.mjs is for cross-source
 * MATCHING and must never run on a value headed into full_name.
 */
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

/**
 * external_id band.
 *
 * 🔴 THE OBVIOUS BAND IS TAKEN. FL FIPS is 12, so the NC/CO scheme would give
 * -(1210000+n) -- but -1212802..-1210101 already holds 166 rows, the 2026 US House
 * candidates keyed -12<district><candidate> (measured against prod 2026-08-28).
 * Seating a legislator there would silently overwrite a real person, because
 * ON CONFLICT DO NOTHING would absorb the collision.
 *
 * House -> -(1220000+n), Senate -> -(1230000+n). Both ranges measured completely
 * empty on 2026-08-28, and the incumbents migration re-asserts that against prod
 * BEFORE inserting anything.
 */
const extId = (s) => (s.chamber === 'upper' ? -(1230000 + s.district) : -(1220000 + s.district));

/** TIGER GEOID: FIPS 12 plus the zero-padded 3-digit district. Both chambers. */
const geoIdFor = (chamber, district) => '12' + String(district).padStart(3, '0');
const dtFor = (chamber) => (chamber === 'upper' ? 'STATE_UPPER' : 'STATE_LOWER');
const titleFor = (chamber) => (chamber === 'upper' ? 'Senator' : 'Representative');

/**
 * Split the roster's given-names string into first_name and middle_initial.
 *
 * The roster already gives structured parts (lastName, givenNames, nameSuffix,
 * honorific, preferredName), so no surname guessing happens here.
 *
 * middle_initial is populated ONLY when a remaining token really is an initial.
 * 'Robert Charles "Chuck"' yields first_name Robert and middle_initial NULL -- forcing
 * 'Charles' into a column named middle_INITIAL would be a false claim about the shape
 * of the name, and full_name already carries the truth.
 */
function firstAndMiddle(givenNames) {
  const tokens = String(givenNames).split(/\s+/).filter(Boolean);
  const first = tokens[0] ?? null;
  const initial = tokens.slice(1).find((t) => /^[A-Za-z]\.$/.test(t)) ?? null;
  return { first, initial };
}

// ── Structure ───────────────────────────────────────────────────────────────

const vacancyRows = VACANCIES
  .slice()
  .sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? 1 : -1))
  .map((v) => `    (${q(geoIdFor(v.chamber, v.district))}, ${q(dtFor(v.chamber))}, ${q(titleFor(v.chamber))}, ` +
    `${v.vacantSince === null ? 'NULL' : `DATE ${q(v.vacantSince)}`}, ${q(v.source)})`)
  .join(',\n');

const vacancyComment = VACANCIES
  .map((v) => `--   ${v.chamber === 'lower' ? 'HD' : 'SD'}-${v.district}: vacant since ` +
    `${v.vacantSince ?? 'UNKNOWN (not published)'}` +
    (v.predecessor ? `, after ${v.predecessor}` : ''))
  .join('\n');

const structure = `-- CC_wip_fl_legislature_structure.sql
-- Knight Foundation program, wave FL-2 (structure half).
--
-- Creates the two Florida legislative chambers under the existing 'State of Florida'
-- government, and one office per district: ${N_LOWER_OFFICES} Representatives + ${N_UPPER_OFFICES} Senators = ${N_OFFICES}.
-- Creates NO people and NO terms -- the incumbents migration does that, and the two
-- are applied back to back.
--
-- 🔴 ${N_VACANT} OF THE ${N_OFFICES} OFFICES ARE VACANT and are flagged is_vacant HERE, in the
-- structure migration, not later:
${vacancyComment}
--
-- Flagging here is load-bearing twice over:
--   1. check-address-reachability.mjs classifies DEAD_GEOGRAPHY as
--      "reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0".
--      An unflagged empty office fires a NEW fl|STATE_LOWER bucket and fails the gate.
--   2. essentials.offices_missing_terms separates flagged-vacant rows from unflagged
--      ones, and only the unflagged count is drift (measured before this wave: 814
--      total / 159 flagged / 655 unflagged, against a 699 unflagged threshold).
--      Flagging here keeps the unflagged count at 655 even in the window between the
--      two applies.
--
-- SD-39's vacancy start is NOT PUBLISHED -- the roster row and the member page both
-- read only "Vacant" -- so vacant_since is left NULL rather than invented. CLAUDE.md:
-- do not write a vacancy span whose start date you do not know.
--
-- Districts and geometry come from scripts/load-state-tiger-boundaries.ts (wave FL-1),
-- not from this migration.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded, and the vacancy UPDATE is guarded on
-- the current value. Ends with a post-verify gate.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOV_ID)}, ${q(HOUSE_NAME)}, ${q(HOUSE_NAME)}, ${N_LOWER_OFFICES}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOV_ID)} AND name = ${q(HOUSE_NAME)}
);

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT ${q(GOV_ID)}, ${q(SENATE_NAME)}, ${q(SENATE_NAME)}, ${N_UPPER_OFFICES}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${q(GOV_ID)} AND name = ${q(SENATE_NAME)}
);

-- ─── House offices: ${N_LOWER_OFFICES}, one per STATE_LOWER district ─────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Representative', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = ${q(HOUSE_NAME)}
) c
WHERE d.district_type = 'STATE_LOWER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Representative'
  );

-- ─── Senate offices: ${N_UPPER_OFFICES}, one per STATE_UPPER district ───────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Senator', 'FL', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = ${q(GOV_ID)} AND ch.name = ${q(SENATE_NAME)}
) c
WHERE d.district_type = 'STATE_UPPER'
  AND lower(d.state) = 'fl'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Senator'
  );

-- ─── Flag the ${N_VACANT} vacant seats ─────────────────────────────────────────────────
-- 🔴 The join pairs geo_id WITH district_type. FL's sldl and sldu GEOIDs BOTH start at
-- 12001, so an unpaired join would match HD-n against SD-n for every n <= 40 -- and
-- SD-39 is one of these five, well inside that range.

CREATE TEMP TABLE fl_leg_vacancy (
  geo_id        text,
  district_type text,
  office_title  text,
  vacant_since  date,
  source        text
) ON COMMIT DROP;

INSERT INTO fl_leg_vacancy VALUES
${vacancyRows};

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM fl_leg_vacancy;
  IF v_n <> ${N_VACANT} THEN RAISE EXCEPTION 'vacancy payload: expected ${N_VACANT} rows, got %', v_n; END IF;
END $$;

UPDATE essentials.offices o
   SET is_vacant = true,
       vacant_since = v.vacant_since
  FROM fl_leg_vacancy v
  JOIN essentials.districts d
    ON d.geo_id = v.geo_id
   AND d.district_type = v.district_type
   AND lower(d.state) = 'fl'
 WHERE o.district_id = d.id
   AND o.title = v.office_title
   AND (o.is_vacant IS DISTINCT FROM true
        OR o.vacant_since IS DISTINCT FROM v.vacant_since);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE n_ch int; n_off int; n_orphan int; n_vac int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = ${q(GOV_ID)}
     AND c.name IN (${q(HOUSE_NAME)}, ${q(SENATE_NAME)});
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected 2 FL legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> ${N_OFFICES} THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected ${N_OFFICES} FL legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the seat is
  -- unreachable by address and nothing will error.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CC_wip_fl_structure: % FL legislative offices lack district geometry', n_orphan; END IF;

  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND o.is_vacant = true;
  IF n_vac <> ${N_VACANT} THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected ${N_VACANT} FL legislative offices flagged is_vacant, found %', n_vac; END IF;
END $$;

-- Second gate: per-chamber shape + no cross-wiring. Catches exactly the failure mode
-- where a bare geo_id join fans a House office onto a Senate district while still
-- producing a plausible ${N_OFFICES} total. FL's sldl and sldu GEOIDs BOTH start at 12001, so
-- this collision is total for districts 1-40 and this gate is not theoretical.
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_LOWER';
  IF n_lower <> ${N_LOWER_OFFICES} THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected ${N_LOWER_OFFICES} FL House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='fl' AND d.district_type='STATE_UPPER';
  IF n_upper <> ${N_UPPER_OFFICES} THEN RAISE EXCEPTION 'CC_wip_fl_structure: expected ${N_UPPER_OFFICES} FL Senate offices, found %', n_upper; END IF;

  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CC_wip_fl_structure: % FL districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;

COMMIT;
`;

// ── Incumbents ──────────────────────────────────────────────────────────────

const rows = SEATS
  .slice()
  .sort((a, b) => (a.chamber === b.chamber ? a.district - b.district : a.chamber < b.chamber ? 1 : -1))
  .map((s) => {
    const { first, initial } = firstAndMiddle(s.givenNames);
    const aliases = s.preferredName ? `ARRAY[${q(s.preferredName)}]::text[]` : `'{}'::text[]`;
    const termStartSql = s.assumedOffice === null ? 'NULL' : `DATE ${q(s.assumedOffice)}`;
    return (
      `    (${q(geoIdFor(s.chamber, s.district))}, ${q(dtFor(s.chamber))}, ${q(titleFor(s.chamber))}, ` +
      `${extId(s)}, ${q(s.name)}, ${q(first)}, ${q(s.lastName)}, ${q(initial)}, ${q(s.nameSuffix)}, ` +
      `${aliases}, ${q(s.portraitUrl)}, ${termStartSql}, ${q(s.assumedPrecision)}, ` +
      `${q(s.howStarted)}, ${q(s.source)})`
    );
  })
  .join(',\n');

const nDay = SEATS.filter((s) => s.assumedPrecision === 'day').length;
const nYear = SEATS.filter((s) => s.assumedPrecision === 'year').length;
const nUnknown = SEATS.filter((s) => s.assumedPrecision === 'unknown').length;
const nElected = SEATS.filter((s) => s.howStarted === 'elected').length;
const nAppointed = SEATS.filter((s) => s.howStarted === 'appointed').length;
const nUnknownStarted = SEATS.filter((s) => s.howStarted === 'unknown').length;
const nNullDate = SEATS.filter((s) => s.assumedOffice === null).length;
const nLowerPeople = lower.length;
const nUpperPeople = upper.length;

const incumbents = `-- CC_wip_fl_legislature_incumbents.sql
-- Knight Foundation program, wave FL-2 (occupancy half).
--
-- Seats ${N_PEOPLE} Florida legislators: ${nLowerPeople} Representatives + ${nUpperPeople} Senators.
--
-- 🔴 ${N_PEOPLE} PEOPLE, NOT ${N_OFFICES}. ${N_VACANT} seats are vacant and were flagged is_vacant by the
-- structure migration; they get NO politician and NO office_terms row here:
${vacancyComment}
--
-- SOURCE: flhouse.gov/Representatives and flsenate.gov/Senators/ for identity,
-- district and the canonical name spelling, plus EACH MEMBER'S OWN PAGE for the
-- assumed-office date and the change-since-source check. All ${N_PEOPLE} member pages
-- mention their member's surname. Built by build-fl-legislature-roster.mjs into
-- data/fl-legislature-roster.json; defects documented in
-- data/seed-fl-legislature-2026/ROSTERS.md. Retrieved ${RETRIEVED}.
--
-- ⚠ THE ROSTER'S OWN DATE IS THE CURRENT TERM, NOT CONTINUOUS OCCUPANCY. 120 of the
-- 127 House records read 11/06/24, the 2024 general election. term_start is the start
-- of continuous occupancy by that person and re-election does not end an occupancy, so
-- every date here comes from the member's own "Legislative Service" line instead.
--
-- DATE PRECISION is recorded, never fabricated: ${nDay} seats carry a full date
-- (start_precision='day'); ${nYear} carry only a year (stored YYYY-01-01 with
-- start_precision='year', so month and day are explicitly NOT claimed); ${nUnknown} unknown.
-- ${nNullDate} seat(s) carry a NULL term_start.
--
-- HOW STARTED: elected ${nElected}, appointed ${nAppointed}, unknown ${nUnknownStarted}. Florida fills
-- legislative vacancies by SPECIAL ELECTION, not appointment (Fla. Const. art. III,
-- s. 15(d); ch. 100, F.S.), so every seat is 'elected'. Stated explicitly because
-- seat_officeholder() DEFAULTS p_how_started to 'elected' and a silent default is not
-- evidence.
--
-- 🔴 external_id band: House -(1220000+n), Senate -(1230000+n). NOT -(1210000+n),
-- which holds 166 FL US House candidate rows (-1212802..-1210101). Both bands used
-- here were measured empty against prod on 2026-08-28 and are re-asserted below
-- BEFORE any insert, because ON CONFLICT DO NOTHING would silently absorb a collision
-- and leave the seat held by whoever already owned that id.

BEGIN;

-- ─── Refuse to run if the external_id bands are not as expected ─────────────
DO $$
DECLARE v_house int; v_senate int;
BEGIN
  SELECT count(*) INTO v_house FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001;
  SELECT count(*) INTO v_senate FROM essentials.politicians
   WHERE external_id BETWEEN -1230040 AND -1230001;
  IF v_house NOT IN (0, ${nLowerPeople}) THEN
    RAISE EXCEPTION 'CC_wip_fl_incumbents: FL House external_id band holds % rows (expected 0 on first run, ${nLowerPeople} on a re-run)', v_house;
  END IF;
  IF v_senate NOT IN (0, ${nUpperPeople}) THEN
    RAISE EXCEPTION 'CC_wip_fl_incumbents: FL Senate external_id band holds % rows (expected 0 on first run, ${nUpperPeople} on a re-run)', v_senate;
  END IF;
END $$;

CREATE TEMP TABLE fl_leg_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_name     text,
  name_suffix     text,
  aliases         text[],
  photo_url       text,
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO fl_leg_seed VALUES
${rows};

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM fl_leg_seed;
  IF v_n <> ${N_PEOPLE} THEN RAISE EXCEPTION 'seed payload: expected ${N_PEOPLE} rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM fl_leg_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT geo_id, district_type FROM fl_leg_seed GROUP BY geo_id, district_type HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate (geo_id, district_type) key(s)', v_dup; END IF;
  -- A seeded person must never target an office the structure migration flagged vacant.
  SELECT count(*) INTO v_dup
    FROM fl_leg_seed s
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id AND d.district_type = s.district_type AND lower(d.state) = 'fl'
    JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
   WHERE o.is_vacant = true;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % row(s) target an office flagged is_vacant', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, photo_origin_url, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_name, s.name_suffix,
       s.aliases, s.photo_url, true, true, s.source
FROM fl_leg_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy: dated seats, via the helper ──────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before inserting,
-- which is the whole reason it exists.
--
-- 🔴 The districts join pairs geo_id WITH district_type. FL's sldl and sldu GEOIDs
-- both start at 12001, so dropping the pairing would match HD-n against SD-n for
-- every n <= 40.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
    FROM fl_leg_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id
     AND d.district_type = s.district_type
     AND lower(d.state) = 'fl'
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE s.term_start IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
      )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % FL legislator(s) with a known start date', v_seated;
END $$;

-- ─── Occupancy: unknown-start seats, direct insert ──────────────────────────
-- seat_officeholder() RAISE EXCEPTIONs on a NULL p_term_start by design, so a
-- genuinely unknown start is inserted directly -- the identical shape migration
-- 1459's phase-2 backfill and its corrections (1465, 1546, 1635, 1798, 1814) use.
-- essentials.current_office_holders treats term_start IS NULL / term_end IS NULL as
-- "currently holds", so such a member still counts as seated in the gate below.

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, s.start_precision, s.how_started, s.source
FROM fl_leg_seed s
JOIN essentials.politicians p ON p.external_id = s.ext_id
JOIN essentials.districts d
  ON d.geo_id = s.geo_id
 AND d.district_type = s.district_type
 AND lower(d.state) = 'fl'
JOIN essentials.offices o
  ON o.district_id = d.id AND o.title = s.office_title
WHERE s.term_start IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE v_pol int; v_seated int; v_lower int; v_upper int; v_vac_seated int;
BEGIN
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id BETWEEN -1220120 AND -1220001
      OR external_id BETWEEN -1230040 AND -1230001;
  IF v_pol <> ${N_PEOPLE} THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: FL legislators inserted: expected ${N_PEOPLE}, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id, never an absent row. count(*) would
  -- pass vacuously with every seat empty -- and with ${N_VACANT} genuinely vacant seats here,
  -- count(*) would also read ${N_OFFICES} and hide the difference that matters.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> ${N_PEOPLE} THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected ${N_PEOPLE} seated FL legislators, found %', v_seated; END IF;

  SELECT count(och.politician_id) INTO v_lower
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_LOWER';
  IF v_lower <> ${nLowerPeople} THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected ${nLowerPeople} seated FL Representatives, found %', v_lower; END IF;

  SELECT count(och.politician_id) INTO v_upper
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type = 'STATE_UPPER';
  IF v_upper <> ${nUpperPeople} THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: expected ${nUpperPeople} seated FL Senators, found %', v_upper; END IF;

  -- The ${N_VACANT} flagged-vacant offices must still hold nobody.
  SELECT count(och.politician_id) INTO v_vac_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'fl' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND o.is_vacant = true;
  IF v_vac_seated <> 0 THEN RAISE EXCEPTION 'CC_wip_fl_incumbents: % vacant FL legislative office(s) somehow hold a person', v_vac_seated; END IF;
END $$;

COMMIT;
`;

fs.writeFileSync('migrations/CC_wip_fl_legislature_structure.sql', structure, { encoding: 'utf8' });
fs.writeFileSync('migrations/CC_wip_fl_legislature_incumbents.sql', incumbents, { encoding: 'utf8' });

// Verify the emitted bytes round-trip non-ASCII and quoted names, and carry no BOM.
let failed = false;
for (const f of ['migrations/CC_wip_fl_legislature_structure.sql', 'migrations/CC_wip_fl_legislature_incumbents.sql']) {
  if (fs.readFileSync(f).slice(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf]))) {
    console.error(`FATAL: ${f} carries a UTF-8 BOM.`);
    failed = true;
  }
}
const emitted = fs.readFileSync('migrations/CC_wip_fl_legislature_incumbents.sql', 'utf8');
const nonAscii = SEATS.filter((s) => /[^\u0000-\u007F]/.test(s.name));
const missingNonAscii = nonAscii.filter((s) => !emitted.includes(s.name));
if (missingNonAscii.length) {
  console.error(`FATAL: ${missingNonAscii.length} non-ASCII name(s) failed to round-trip: ${missingNonAscii.map((s) => s.name).join(', ')}`);
  failed = true;
}
const quoted = SEATS.filter((s) => s.name.includes('"'));
const missingQuoted = quoted.filter((s) => !emitted.includes(s.name));
if (missingQuoted.length) {
  console.error(`FATAL: ${missingQuoted.length} quoted-nickname name(s) failed to round-trip: ${missingQuoted.map((s) => s.name).join(', ')}`);
  failed = true;
}
// An apostrophe in a name must appear DOUBLED in the literal, never bare.
const apostrophe = SEATS.filter((s) => s.name.includes("'"));
for (const s of apostrophe) {
  if (!emitted.includes(s.name.replace(/'/g, "''"))) {
    console.error(`FATAL: apostrophe not escaped for ${s.name}`);
    failed = true;
  }
}
if (failed) process.exit(1);

console.log('wrote migrations/CC_wip_fl_legislature_structure.sql');
console.log('wrote migrations/CC_wip_fl_legislature_incumbents.sql');
console.log(`  ${N_OFFICES} offices | House ${N_LOWER_OFFICES}, Senate ${N_UPPER_OFFICES}`);
console.log(`  ${N_PEOPLE} people  | House ${nLowerPeople}, Senate ${nUpperPeople}`);
console.log(`  ${N_VACANT} vacant  | ${VACANCIES.map((v) => `${v.chamber === 'lower' ? 'HD' : 'SD'}-${v.district} (${v.vacantSince ?? 'date UNKNOWN'})`).join(', ')}`);
console.log(`  precision: day ${nDay}, year ${nYear}, unknown ${nUnknown}`);
console.log(`  how_started: elected ${nElected}, appointed ${nAppointed}, unknown ${nUnknownStarted}`);
console.log('  BOM check: none found');
console.log(`  round-trip: ${nonAscii.length} non-ASCII, ${quoted.length} quoted-nickname, ${apostrophe.length} apostrophe name(s) all intact`);
