#!/usr/bin/env node
/**
 * gen-durham-migrations.mjs
 *
 * Emits the two City/County of Durham, NC seeding migrations from
 * data/seed-durham-2026/durham-roster.json, which is a direct machine-readable
 * transcription of data/seed-durham-2026/ROSTERS.md (the source of truth --
 * this generator does not re-derive or re-research any fact; ROSTERS.md was
 * already committed, reviewed and fact-checked).
 *
 *   migrations/_wip_durham_structure.sql    1 LOCAL district + 2 governments +
 *                                            3 chambers + 15 offices
 *   migrations/_wip_durham_incumbents.sql   15 politicians + 15 terms
 *
 * Split in two to match the WA (1798 struct-ish/1800 wiring), NC legislature
 * (CA_0004/CA_0005) and CO (1843/1844) precedent: structure is stable,
 * occupancy churns with every election/resignation, and keeping them apart
 * means a re-seat never has to re-run office/district creation.
 *
 * Files are emitted as `_wip_` on purpose. MIGRATION NUMBERS ARE TAKEN LAST,
 * immediately before applying, in Chris's CA_ namespace (CA_0006 / CA_0007) --
 * this script does NOT apply anything and does NOT touch the database. It
 * only reads the roster JSON and writes the two SQL files below.
 *
 * Usage (from C:/EV-Accounts/backend):
 *   node scripts/gen-durham-migrations.mjs
 */

import fs from 'node:fs';

const ROSTER = JSON.parse(fs.readFileSync('data/seed-durham-2026/durham-roster.json', 'utf8'));
const SEATS = ROSTER.seats;

if (SEATS.length !== 15) {
  console.error(`FATAL: expected 15 seats, roster has ${SEATS.length}. Check durham-roster.json against ROSTERS.md.`);
  process.exit(1);
}

// SQL string literal. Escapes single quotes only -- the sole SQL-meaningful
// character inside a single-quoted literal. Double quotes (Dr. Michael "Mike"
// Lee, Leonardo "Leo" Williams) pass through untouched: this is a byte-for-byte
// pass of the name into the literal, never a normalization.
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

const RETRIEVED = ROSTER.retrievedAt ? ROSTER.retrievedAt.slice(0, 10) : '2026-08-22';

const citySeats = SEATS.filter((s) => s.seatGroup === 'city');
const commissionSeats = SEATS.filter((s) => s.seatGroup === 'county-commission');
const execSeats = SEATS.filter((s) => s.seatGroup === 'county-exec');

if (citySeats.length !== 7) {
  console.error(`FATAL: expected 7 city seats, got ${citySeats.length}.`);
  process.exit(1);
}
if (commissionSeats.length !== 5) {
  console.error(`FATAL: expected 5 county commission seats, got ${commissionSeats.length}.`);
  process.exit(1);
}
if (execSeats.length !== 3) {
  console.error(`FATAL: expected 3 county executive seats, got ${execSeats.length}.`);
  process.exit(1);
}

// ── Ward representation notes ──────────────────────────────────────────────
// Bainbridge Island's ward notes (migration 1800) say "residency and
// nomination district" -- correct THERE because BIMC 2.06 has ward voters
// nominate in the August primary before an all-city November general.
// Durham's wards do NOT gate nomination at all; a Ward N seat requires only
// that the CANDIDATE reside in Ward N, and every city voter -- not just Ward N
// residents -- votes on every council seat in every election. Copying
// Bainbridge's "nomination" phrasing here would assert a primary restriction
// Durham does not have, so this wording is deliberately different: residency
// requirement only, using Durham's own sentence for the "no voting effect"
// half (per task instructions, verbatim).
const wardNote = (n) =>
  `Ward ${n} is a residency requirement for candidacy, not an election district: a candidate for ` +
  `this seat must reside in Ward ${n} of the City of Durham. The candidate is, however, elected by ` +
  `all city voters. Wards do not affect where a resident votes or which candidate(s) a resident can ` +
  `vote for. (durhamnc.gov/1396/City-Council-Members, retrieved ${RETRIEVED}.)`;

// ── structure ────────────────────────────────────────────────────────────────
const structure = `-- _wip_durham_structure.sql
-- City of Durham + Durham County, North Carolina: 1 LOCAL district, 2
-- governments, 3 chambers, 15 offices.
--
-- Durham NC wave 2. The 'place' TIGER/redistricting load already wrote the
-- Durham city POLYGON (essentials.geofence_boundaries, geo_id '3719000',
-- mtfcc 'G4110') with writeDistrictRow: false, so there is NO essentials.
-- districts row for the city yet -- this migration creates it. Durham
-- COUNTY's district row ALREADY EXISTS (COUNTY, geo_id '37063', TIGER load)
-- and is reused, never re-created.
--
-- 🔴 geo_id '37063' IS NOT UNIQUE: it is simultaneously Durham County
-- (COUNTY, 0 offices before this migration) and NC House District 63
-- (STATE_LOWER, 1 office, seated by wave 1). '37' || lpad(63,3,'0') = '37063'
-- is byte-identical to Durham County's FIPS. Every county-office join below
-- keys on (geo_id, district_type) TOGETHER -- a bare geo_id join would attach
-- the Sheriff, Register of Deeds, Clerk of Superior Court and 5 commissioners
-- to a STATE HOUSE seat, or fan out to both, while an "8 offices" count could
-- still look correct if only counted, not typed. The post-verify gate below
-- ends with an explicit assertion that NC House District 63 still carries
-- exactly 1 office after this migration runs.
--
-- All 7 City of Durham seats (Mayor + 3 wards + 3 at-large) are elected
-- CITYWIDE, so all 7 hang off ONE LOCAL district -- 'Durham Citywide' --
-- following the Bainbridge Island Citywide precedent (geo_id 5303736, 7
-- offices; migration 1800), not Austin's 10-district model (Austin's council
-- is genuinely district-elected; Durham's is not).
--
-- Durham County Commissioners are 5 at-large seats; per ROSTERS.md, Chair and
-- Vice-Chair are annual BOARD VOTES, not separate offices, so no Chair/
-- Vice-Chair office is created here. The 5 commissioner seats share an
-- identical title in the source record, so "Commissioner, Seat 1..5" is used
-- as an internal DB disambiguator ONLY (no numbered-seat claim is being made
-- about Durham County's actual structure) -- the same convention this corpus
-- already uses for indistinguishable at-large seats (e.g. "Council Member
-- (At-Large 1..N)" in Auburn/Augusta/Bangor/Bath, Maine). The 3 city
-- at-large seats get the identical treatment for the identical reason.
--
-- essentials.offices.politician_id was DROPPED (ADR 0002 phase 5, migration
-- 1463). This migration writes NO occupant -- occupancy is entirely
-- migrations/_wip_durham_incumbents.sql, through essentials.office_terms.
--
-- Idempotency: essentials.districts/governments/chambers/offices have no
-- unique index beyond their pkeys (chambers.slug is a GENERATED ALWAYS column
-- and must never be inserted directly), so every insert below is NOT EXISTS
-- guarded. Chamber idempotency keys on (government_id, name); office
-- idempotency keys on (chamber_id, title).

BEGIN;

-- ─── 1. Durham Citywide district (the polygon that actually elects) ─────────
-- Mirrors Bainbridge Island Citywide (LOCAL, 5303736, G4110): the Durham city
-- polygon already exists (geofence_boundaries, mtfcc G4110); only the
-- districts row is new.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT '3719000', 'Durham Citywide', 'LOCAL', 'nc', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '3719000' AND district_type = 'LOCAL'
);

-- ─── 2. Governments ──────────────────────────────────────────────────────────
-- Neither government row exists yet (verified against prod ${RETRIEVED}: zero
-- rows in essentials.governments named or geo_id-matched to Durham).

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Durham, North Carolina, US', 'City', 'NC', 'Durham', '3719000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '3719000' AND type = 'City'
);

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Durham County, North Carolina, US', 'County', 'NC', NULL, '37063'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '37063' AND type = 'County'
);

-- ─── 3. Chambers ─────────────────────────────────────────────────────────────
-- Durham County follows the Travis County shape: one chamber for the elected
-- legislative board (Commissioners), one for the countywide elected executive
-- officials (Sheriff, Register of Deeds, Clerk of Superior Court) -- rather
-- than Kitsap's one-chamber-per-office split, since all three of Durham's
-- executive offices sit at the same policy_engagement_level ('full', matching
-- the corpus-wide majority for Sheriff/Register of Deeds/Clerk).

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'City Council', 'Durham City Council', 7, 'full'
FROM essentials.governments g
WHERE g.geo_id = '3719000' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'City Council'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Board of County Commissioners', 'Durham County Board of Commissioners', 5, 'full'
FROM essentials.governments g
WHERE g.geo_id = '37063' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Durham County Elected Officials', 3, 'full'
FROM essentials.governments g
WHERE g.geo_id = '37063' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Elected Officials'
  );

-- ─── 4. City offices: 7, on the Durham Citywide LOCAL district ──────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, representation_note)
SELECT c.id, d.id, v.title, 'NC', 'Durham', v.note
FROM (VALUES
  ('Mayor',                       NULL),
  ('Councilmember, Ward 1',       ${q(wardNote(1))}),
  ('Councilmember, Ward 2',       ${q(wardNote(2))}),
  ('Councilmember, Ward 3',       ${q(wardNote(3))}),
  ('Councilmember, At-Large 1',   NULL),
  ('Councilmember, At-Large 2',   NULL),
  ('Councilmember, At-Large 3',   NULL)
) AS v(title, note)
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '3719000' AND g.type = 'City' AND ch.name = 'City Council'
) c
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '3719000' AND dd.district_type = 'LOCAL' AND lower(dd.state) = 'nc'
) d
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
);

-- ─── 5. County commission offices: 5, on the EXISTING COUNTY district ───────
-- 🔴 district join MUST pair geo_id with district_type = 'COUNTY' -- see
-- header. A bare geo_id = '37063' join matches NC House District 63 too.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, v.title, 'NC'
FROM (VALUES
  ('Commissioner, Seat 1'),
  ('Commissioner, Seat 2'),
  ('Commissioner, Seat 3'),
  ('Commissioner, Seat 4'),
  ('Commissioner, Seat 5')
) AS v(title)
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '37063' AND g.type = 'County' AND ch.name = 'Board of County Commissioners'
) c
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '37063' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
);

-- ─── 6. County executive offices: 3, on the EXISTING COUNTY district ────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, v.title, 'NC'
FROM (VALUES
  ('Sheriff'),
  ('Register of Deeds'),
  ('Clerk of Superior Court')
) AS v(title)
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '37063' AND g.type = 'County' AND ch.name = 'Elected Officials'
) c
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '37063' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
);

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  n_district int; n_city_off int; n_county_off int; n_ward_notes int;
  n_orphan int; n_hd63 int;
BEGIN
  -- 1 new LOCAL district.
  SELECT count(*) INTO n_district FROM essentials.districts
   WHERE geo_id = '3719000' AND district_type = 'LOCAL' AND lower(state) = 'nc';
  IF n_district <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected 1 Durham Citywide LOCAL district, found %', n_district;
  END IF;

  -- 7 offices on the Durham Citywide district.
  SELECT count(*) INTO n_city_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL';
  IF n_city_off <> 7 THEN
    RAISE EXCEPTION 'CA_0006: expected 7 offices on Durham Citywide, found %', n_city_off;
  END IF;

  -- 8 offices on the COUNTY row for 37063 -- district_type pinned, or this
  -- would silently include NC House District 63's 1 office too.
  SELECT count(*) INTO n_county_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'COUNTY';
  IF n_county_off <> 8 THEN
    RAISE EXCEPTION 'CA_0006: expected 8 offices on the Durham County COUNTY district, found %', n_county_off;
  END IF;

  -- 3 ward offices carry a non-null representation_note.
  SELECT count(*) INTO n_ward_notes FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL'
     AND o.title LIKE 'Councilmember, Ward %'
     AND o.representation_note IS NOT NULL;
  IF n_ward_notes <> 3 THEN
    RAISE EXCEPTION 'CA_0006: expected 3 Durham ward offices with a representation_note, found %', n_ward_notes;
  END IF;

  -- 0 offices on a district lacking geometry.
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE ((d.geo_id = '3719000' AND d.district_type = 'LOCAL')
          OR (d.geo_id = '37063' AND d.district_type = 'COUNTY'))
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN
    RAISE EXCEPTION 'CA_0006: % Durham offices lack district geometry', n_orphan;
  END IF;

  -- 0 districts carrying an unexpected office count: the two exact-count
  -- assertions above (7 and 8) already prove this for the two districts this
  -- migration touches, but restated explicitly as a single combined check.
  IF (n_city_off, n_county_off) IS DISTINCT FROM (7, 8) THEN
    RAISE EXCEPTION 'CA_0006: unexpected office count on a Durham district (city=%, county=%)', n_city_off, n_county_off;
  END IF;

  -- 🔴 The assertion that actually catches the '37063' collision: NC House
  -- District 63 (STATE_LOWER, same geo_id, different district_type) must
  -- still carry exactly its own 1 office -- never fed by a bare geo_id join.
  SELECT count(*) INTO n_hd63 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'STATE_LOWER';
  IF n_hd63 <> 1 THEN
    RAISE EXCEPTION 'CA_0006: NC House District 63 carries % offices, expected 1 — county offices cross-wired onto the house district', n_hd63;
  END IF;
END $$;

COMMIT;
`;

// ── incumbents ───────────────────────────────────────────────────────────────
const rows = SEATS
  .map((s) => {
    const aliases = s.preferredName ? `ARRAY[${q(s.preferredName)}]::text[]` : `'{}'::text[]`;
    return (
      `    (${q(s.geoId)}, ${q(s.districtType)}, ${q(s.officeTitle)}, ${s.externalId}, ${q(s.fullName)}, ` +
      `${q(s.firstName)}, ${q(s.lastName)}, ${q(s.middleInitial)}, ${q(s.nameSuffix)}, ${aliases}, ` +
      `DATE ${q(s.termStart)}, ${q(s.precision)}, ${q(s.howStarted)}, ${q(s.source)})`
    );
  })
  .join(',\n');

const nAppointed = SEATS.filter((s) => s.howStarted === 'appointed').length;
const nElected = SEATS.filter((s) => s.howStarted === 'elected').length;
const appointedNames = SEATS.filter((s) => s.howStarted === 'appointed').map((s) => s.fullName).join(', ');

const incumbents = `-- _wip_durham_incumbents.sql
-- Seats all 15 Durham, NC elected officials (7 City of Durham + 8 Durham
-- County), keyed to the offices _wip_durham_structure.sql creates.
--
-- SOURCE: backend/data/seed-durham-2026/ROSTERS.md (committed, reviewed,
-- fact-checked; sources S1-S19 cited there), transcribed machine-readably in
-- data/seed-durham-2026/durham-roster.json. Retrieved ${RETRIEVED}. No new
-- research was performed by this generator.
--
-- DATE PRECISION is recorded, never fabricated: 14 seats carry a full
-- assumed-office date (start_precision='day'); Wendy Jacobs' original 2012
-- seating could not be pinned to a day despite a primary-source search
-- (ROSTERS.md 'source defects' section) and is stored as 2012-01-01 with
-- start_precision='year' rather than guessed from N.C.G.S. Sec. 153A-26 alone.
--
-- how_started: ${nElected} 'elected', ${nAppointed} 'appointed' (vacancy fills who
-- continued in the same seat rather than restarting occupancy at their later
-- election win): ${appointedNames}. Passed through to p_how_started
-- explicitly -- NOT left to seat_officeholder()'s 'elected' default, which
-- would misclassify all three.
--
-- 🔴 THE MIKE LEE COLLISION: Durham County's Board Chair is stored as
-- full_name = 'Dr. Michael "Mike" Lee' (external_id -3730008), first_name
-- 'Dr. Michael', last_name 'Lee', preferred_name 'Mike' -- matching this
-- corpus's existing convention of folding a courtesy title into first_name
-- (see 'Dr. Kathleen Lang', 'Dr. Monica Sanchez'). Prod ALREADY contains two
-- distinct, unrelated people: 'Mike Lee' (external_id -400077, US Senator,
-- Utah) and 'Michael V. Lee' (external_id -3710007, NC State Senate District
-- 7, New Hanover County, Republican). Durham's Lee is a third, distinct
-- person (Avalara customer-success manager, former Durham Public Schools
-- Board of Education member, elected countywide 2024, Democrat). Never write
-- 'Michael Lee' or 'Mike Lee' bare for this row -- either string collides
-- with an existing prod row under a lower(full_name) match.
--
-- NAME HANDLING: full_name is ROSTERS.md's exact string, byte-for-byte --
-- never run through NFD/diacritic-stripping. Two names carry embedded double
-- quotes around a nickname (Leonardo "Leo" Williams, Dr. Michael "Mike" Lee).
-- This file is written as UTF-8 without a BOM; the generator verifies the
-- emitted bytes decode correctly for both quoted names before reporting
-- success.
--
-- EXTERNAL IDS: -(3730000+n), n=1..15, per ROSTERS.md's external_id mapping
-- table. Verified collision-free against prod ${RETRIEVED}: zero existing rows
-- in -3730015..-3730001.
--
-- IDEMPOTENCY: politicians uses ON CONFLICT (external_id) DO NOTHING (real
-- unique index, migration 191). All 15 terms go through
-- essentials.seat_officeholder(), which is idempotent and closes any
-- predecessor's term rather than silently overlapping it -- none of these 15
-- seats has an unknown term_start, so no direct office_terms insert is
-- needed (unlike the NC legislature's one unknown-start seat).
--
-- Joins key on (geo_id, district_type) together -- '37063' is NOT unique
-- across Durham County (COUNTY) and NC House District 63 (STATE_LOWER).

BEGIN;

CREATE TEMP TABLE durham_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_initial  text,
  name_suffix     text,
  aliases         text[],
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO durham_seed VALUES
${rows};

-- Guard the payload itself before it touches anything.
DO $$
DECLARE v_n int; v_dup int;
BEGIN
  SELECT count(*) INTO v_n FROM durham_seed;
  IF v_n <> 15 THEN RAISE EXCEPTION 'seed payload: expected 15 rows, got %', v_n; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM durham_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;
  SELECT count(*) INTO v_dup FROM (SELECT geo_id, district_type, office_title FROM durham_seed GROUP BY geo_id, district_type, office_title HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate (geo_id, district_type, office_title) key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_initial, s.name_suffix,
       s.aliases, true, true, s.source
FROM durham_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy, via the helper ───────────────────────────────────────────────
-- seat_officeholder() closes any predecessor's open-ended term before
-- inserting, which is the whole reason it exists. All 15 rows carry a real
-- term_start (Jacobs' is year-precision, not NULL), so every row goes through
-- this loop -- no direct office_terms insert is needed for this file.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
    FROM durham_seed s
    JOIN essentials.politicians p ON p.external_id = s.ext_id
    JOIN essentials.districts d
      ON d.geo_id = s.geo_id
     AND d.district_type = s.district_type
     AND lower(d.state) = 'nc'
    JOIN essentials.offices o
      ON o.district_id = d.id AND o.title = s.office_title
    WHERE NOT EXISTS (
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
  RAISE NOTICE 'seated % Durham official(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_seated int; v_appointed int; v_homonym int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN -3730015 AND -3730001;
  IF v_pol <> 15 THEN RAISE EXCEPTION 'CA_0007: Durham officials inserted: expected 15, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row.
  -- count(*) would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE (d.geo_id = '3719000' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '37063' AND d.district_type = 'COUNTY');
  IF v_seated <> 15 THEN RAISE EXCEPTION 'CA_0007: expected 15 seated Durham officials, found %', v_seated; END IF;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE ((d.geo_id = '3719000' AND d.district_type = 'LOCAL')
          OR (d.geo_id = '37063' AND d.district_type = 'COUNTY'))
     AND t.how_started = 'appointed';
  IF v_appointed <> ${nAppointed} THEN RAISE EXCEPTION 'CA_0007: expected ${nAppointed} Durham terms with how_started=appointed, found %', v_appointed; END IF;

  -- 🔴 Cross-state homonym assertion: no politician seated on a Durham office
  -- may simultaneously hold an office whose district state is not 'nc'. This
  -- is the check that would catch a Utah senator or a New Hanover state
  -- senator landing on the Durham County Commission via a bad name match.
  SELECT count(*) INTO v_homonym
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och1 ON och1.politician_id = p.id
    JOIN essentials.offices o1 ON o1.id = och1.office_id
    JOIN essentials.districts d1 ON d1.id = o1.district_id
    JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id AND och2.office_id <> och1.office_id
    JOIN essentials.offices o2 ON o2.id = och2.office_id
    JOIN essentials.districts d2 ON d2.id = o2.district_id
   WHERE ((d1.geo_id = '3719000' AND d1.district_type = 'LOCAL')
          OR (d1.geo_id = '37063' AND d1.district_type = 'COUNTY'))
     AND lower(d2.state) <> 'nc';
  IF v_homonym <> 0 THEN
    RAISE EXCEPTION 'CA_0007: % politician(s) seated on a Durham office also hold an office outside NC — cross-state homonym collision', v_homonym;
  END IF;
END $$;

COMMIT;
`;

fs.writeFileSync('migrations/_wip_durham_structure.sql', structure, { encoding: 'utf8' });
fs.writeFileSync('migrations/_wip_durham_incumbents.sql', incumbents, { encoding: 'utf8' });

// Verify the emitted bytes round-trip both quoted names correctly and carry
// no BOM (node's utf8 writer never adds one, but check anyway).
const emitted = fs.readFileSync('migrations/_wip_durham_incumbents.sql', 'utf8');
const rawBytes = fs.readFileSync('migrations/_wip_durham_incumbents.sql');
const hasBOM = rawBytes.slice(0, 3).equals(Buffer.from([0xef, 0xbb, 0xbf]));
const leeOk = emitted.includes('Dr. Michael "Mike" Lee');
const williamsOk = emitted.includes('Leonardo "Leo" Williams');

if (hasBOM) {
  console.error('FATAL: emitted incumbents file carries a UTF-8 BOM.');
  process.exit(1);
}
if (!leeOk) {
  console.error('FATAL: Dr. Michael "Mike" Lee round-trip failed (quote characters mangled).');
  process.exit(1);
}
if (!williamsOk) {
  console.error('FATAL: Leonardo "Leo" Williams round-trip failed (quote characters mangled).');
  process.exit(1);
}

console.log('wrote migrations/_wip_durham_structure.sql');
console.log('wrote migrations/_wip_durham_incumbents.sql');
console.log(`  ${SEATS.length} seats | city ${citySeats.length}, county-commission ${commissionSeats.length}, county-exec ${execSeats.length}`);
console.log(`  how_started: elected ${nElected}, appointed ${nAppointed} (${appointedNames})`);
console.log('  BOM check: none found');
console.log(`  quoted-name round-trip: Dr. Michael "Mike" Lee ok=${leeOk}, Leonardo "Leo" Williams ok=${williamsOk}`);
