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
 * FIX ROUND 1 (coordinator, 2026-08-22): two changes from the first draft.
 *   (A) Durham's ballot has no numbered at-large or commissioner seats --
 *       the earlier "At-Large 1/2/3" / "Seat 1..5" titles invented a
 *       distinction that does not exist (the Bainbridge precedent misled:
 *       WA law puts numbered "Council Position No. N" ON THE BALLOT; NC does
 *       not). The house convention for genuinely identical multi-member
 *       seats is IDENTICAL TITLES, MULTIPLE OFFICE ROWS -- measured in prod:
 *       468 distinct (district_id, title) groups already carry more than one
 *       office (Newton 16 "City Councilor", Cambridge 9 "City Councillor",
 *       the United States 8 "Associate Justice", "House At-Large" 13
 *       "Representative"). So: 3 identical "Council Member, At-Large" rows
 *       and 5 identical "Commissioner" rows. The 3 ward seats keep their
 *       distinct titles -- Durham genuinely designates Ward 1/2/3.
 *   (B) Durham writes "Council Member" as two words (its own roster page:
 *       "the Mayor, 3 Council Members representing specific wards, and 3
 *       at-large Council Members") -- not Bainbridge's one-word
 *       "Councilmember".
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

const AT_LARGE_TITLE = 'Council Member, At-Large';
const COMMISSIONER_TITLE = 'Commissioner';

const atLargeCount = citySeats.filter((s) => s.officeTitle === AT_LARGE_TITLE).length;
const commissionerCount = commissionSeats.filter((s) => s.officeTitle === COMMISSIONER_TITLE).length;
if (atLargeCount !== 3) {
  console.error(`FATAL: expected 3 roster rows titled '${AT_LARGE_TITLE}', got ${atLargeCount}.`);
  process.exit(1);
}
if (commissionerCount !== 5) {
  console.error(`FATAL: expected 5 roster rows titled '${COMMISSIONER_TITLE}', got ${commissionerCount}.`);
  process.exit(1);
}

// ── Ward representation notes (unchanged by fix round 1 -- confirmed correct
// by the coordinator; kept verbatim) ─────────────────────────────────────────
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

// ── Post-verify office-count expectations (used by both the structure gate
// and the FATAL pre-checks above) ────────────────────────────────────────────
const OFFICE_EXPECTATIONS = [
  { geoId: '3719000', districtType: 'LOCAL', title: 'Mayor', expected: 1 },
  { geoId: '3719000', districtType: 'LOCAL', title: 'Council Member, Ward 1', expected: 1 },
  { geoId: '3719000', districtType: 'LOCAL', title: 'Council Member, Ward 2', expected: 1 },
  { geoId: '3719000', districtType: 'LOCAL', title: 'Council Member, Ward 3', expected: 1 },
  { geoId: '3719000', districtType: 'LOCAL', title: AT_LARGE_TITLE, expected: 3 },
  { geoId: '37063', districtType: 'COUNTY', title: COMMISSIONER_TITLE, expected: 5 },
  { geoId: '37063', districtType: 'COUNTY', title: 'Sheriff', expected: 1 },
  { geoId: '37063', districtType: 'COUNTY', title: 'Register of Deeds', expected: 1 },
  { geoId: '37063', districtType: 'COUNTY', title: 'Clerk of Superior Court', expected: 1 },
];

const officeGateChecks = OFFICE_EXPECTATIONS.map(
  (e) => `  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(e.geoId)} AND d.district_type = ${q(e.districtType)} AND o.title = ${q(e.title)};
  IF n_check <> ${e.expected} THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', ${e.expected}, ${q(e.title)}, ${q(e.geoId)}, ${q(e.districtType)}, n_check;
  END IF;`
).join('\n\n');

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
-- 🔴 FIX ROUND 1: Durham's ballot has NO numbered at-large or commissioner
-- seats -- voters elect three at-large council members and a slate of
-- commissioners, with no "At-Large 2" or "Seat 4" anywhere in Durham's
-- election machinery (unlike Bainbridge, where WA law puts a legally numbered
-- "Council Position No. N" ON THE BALLOT). Inventing seat numbers here would
-- assert a distinction that does not exist. Instead this migration follows
-- the corpus's own convention for genuinely identical multi-member seats:
-- IDENTICAL TITLES, MULTIPLE OFFICE ROWS -- measured in prod, 468 distinct
-- (district_id, title) groups already carry more than one office this way
-- (Newton 16 "City Councilor", Cambridge 9 "City Councillor", the United
-- States 8 "Associate Justice", "House At-Large" 13 "Representative"). So:
-- 3 offices titled 'Council Member, At-Large' (identical) and 5 titled
-- 'Commissioner' (identical). The 3 ward seats keep their distinct titles --
-- Durham genuinely designates Ward 1/2/3, so those are real, not invented.
--
-- 🔴 Because two title groups are now intentionally non-unique per
-- (district_id, title), the usual NOT EXISTS-on-title idempotency guard would
-- COLLAPSE 3 at-large seats (or 5 commissioner seats) down to 1 on a re-run.
-- Those two INSERTs instead guard on a COUNT: each run tops the group up to
-- its target (3 or 5) via 'generate_series(1, target - existing)', which is
-- empty (zero rows) once the target is already met -- see steps 4b/5a below.
-- Reasoned proof of idempotency (not applied, per task scope): on a first run
-- existing=0, so generate_series(1,3-0)=generate_series(1,3) inserts 3 rows;
-- on any subsequent run existing=3, so generate_series(1,3-3)=
-- generate_series(1,0) is empty (Postgres generate_series with start > stop
-- and the default ascending step returns zero rows) and nothing more is
-- inserted. The same reasoning holds for Commissioner at target 5.
--
-- Durham writes the body's title as "Council Member" (two words) --
-- durhamnc.gov's own roster page: "the Mayor, 3 Council Members representing
-- specific wards, and 3 at-large Council Members" -- not Bainbridge's
-- one-word "Councilmember".
--
-- Durham County Commissioners are 5 at-large seats; per ROSTERS.md, Chair and
-- Vice-Chair are annual BOARD VOTES, not separate offices, so no Chair/
-- Vice-Chair office is created here.
--
-- essentials.offices.politician_id was DROPPED (ADR 0002 phase 5, migration
-- 1463). This migration writes NO occupant -- occupancy is entirely
-- migrations/_wip_durham_incumbents.sql, through essentials.office_terms.
--
-- Idempotency: essentials.districts/governments/chambers have no unique index
-- beyond their pkeys (chambers.slug is a GENERATED ALWAYS column and must
-- never be inserted directly), so those inserts are NOT EXISTS guarded.
-- Single-seat office titles (Mayor, wards, Sheriff, Register of Deeds, Clerk
-- of Superior Court) are also NOT EXISTS guarded on (chamber_id, title). The
-- two multi-seat titles (Council Member, At-Large / Commissioner) are instead
-- guarded on a target-count top-up -- see above.

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

-- ─── 4a. City single-seat offices: Mayor + 3 wards, on the Citywide district ─

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, representation_note)
SELECT c.id, d.id, v.title, 'NC', 'Durham', v.note
FROM (VALUES
  ('Mayor',                          NULL),
  ('Council Member, Ward 1',         ${q(wardNote(1))}),
  ('Council Member, Ward 2',         ${q(wardNote(2))}),
  ('Council Member, Ward 3',         ${q(wardNote(3))})
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

-- ─── 4b. City at-large offices: 3 IDENTICAL 'Council Member, At-Large' rows ──
-- No numbered seat exists on Durham's ballot (see header). Guarded on a
-- target-count top-up, not NOT EXISTS-on-title, since three rows must share
-- one title without collapsing to one on a re-run.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, '${AT_LARGE_TITLE}', 'NC', 'Durham'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '3719000' AND dd.district_type = 'LOCAL' AND lower(dd.state) = 'nc'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 3 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = '${AT_LARGE_TITLE}'
  )) AS n
) gs
WHERE g.geo_id = '3719000' AND g.type = 'City' AND c.name = 'City Council';

-- ─── 5a. County commission offices: 5 IDENTICAL 'Commissioner' rows ─────────
-- 🔴 district join MUST pair geo_id with district_type = 'COUNTY' -- see
-- header. A bare geo_id = '37063' join matches NC House District 63 too.
-- Same target-count top-up as 4b, for the same reason (no numbered seat on
-- Durham County's ballot either).

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, '${COMMISSIONER_TITLE}', 'NC'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '37063' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 5 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = '${COMMISSIONER_TITLE}'
  )) AS n
) gs
WHERE g.geo_id = '37063' AND g.type = 'County' AND c.name = 'Board of County Commissioners';

-- ─── 5b. County executive offices: 3, on the EXISTING COUNTY district ───────

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
  n_orphan int; n_hd63 int; n_check int;
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
     AND o.title LIKE 'Council Member, Ward %'
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

  -- Explicit per-title counts: 1 each for Mayor / Ward 1 / Ward 2 / Ward 3 /
  -- Sheriff / Register of Deeds / Clerk of Superior Court; 3 for
  -- 'Council Member, At-Large'; 5 for 'Commissioner'. This is what actually
  -- proves the two multi-seat groups landed at their target count and no
  -- other title group was fed extra rows by mistake.
${officeGateChecks}

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
-- 🔴 FIX ROUND 1 (coordinator, 2026-08-22): the structure migration now
-- creates 3 IDENTICALLY-TITLED 'Council Member, At-Large' offices and 5
-- IDENTICALLY-TITLED 'Commissioner' offices (no numbered seat exists on
-- Durham's ballot -- see _wip_durham_structure.sql header). A bare
-- office_id/title join can no longer resolve one person to one office row
-- within either group. This file resolves the ambiguity DETERMINISTICALLY
-- by pairing row_number() over each side's natural key, partitioned by
-- (geo_id, district_type, office_title):
--   * office side:  ORDER BY o.id (each office row's UUID is fixed for good
--                   the moment CA_0006 creates it -- an arbitrary but STABLE
--                   ordering key, never reshuffled by a later run).
--   * roster side:  ORDER BY s.ext_id (fixed per person by ROSTERS.md's own
--                   external_id mapping table).
-- Because the structure migration is asserted (by its own post-verify gate)
-- to create EXACTLY 3 At-Large offices and EXACTLY 5 Commissioner offices,
-- and this file's payload guard (below) asserts EXACTLY 3 and 5 roster rows
-- per group, row_number() on each side produces the SAME set of integers
-- 1..N with no gaps and no repeats -- so the join is a bijection: every
-- office gets exactly one politician, every politician gets exactly one
-- office, and re-running is idempotent (the same office UUID always sorts to
-- the same rank, so the same person is matched to the same row every time).
-- If the two counts ever drifted apart, the payload guard below fails loudly
-- instead of silently double-seating one office or leaving another vacant.
-- Every other seat (Mayor, wards, Sheriff, Register of Deeds, Clerk of
-- Superior Court) is a group of size 1, where rank 1 trivially matches rank
-- 1 -- the identical mechanism, just with N=1.
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

-- Guard the payload itself before it touches anything. Duplicate office_title
-- within (geo_id, district_type) is now EXPECTED for the two multi-seat
-- groups (3x 'Council Member, At-Large', 5x 'Commissioner'), so the guard
-- checks per-group COUNTS against the exact expectation instead of rejecting
-- any duplicate -- a plain duplicate-key check would wrongly fail on these
-- two legitimate groups.
DO $$
DECLARE v_n int; v_dup int; v_grp int;
BEGIN
  SELECT count(*) INTO v_n FROM durham_seed;
  IF v_n <> 15 THEN RAISE EXCEPTION 'seed payload: expected 15 rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM durham_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_grp FROM durham_seed
   WHERE geo_id = '3719000' AND district_type = 'LOCAL' AND office_title = '${AT_LARGE_TITLE}';
  IF v_grp <> 3 THEN RAISE EXCEPTION 'seed payload: expected 3 ''${AT_LARGE_TITLE}'' rows, got %', v_grp; END IF;

  SELECT count(*) INTO v_grp FROM durham_seed
   WHERE geo_id = '37063' AND district_type = 'COUNTY' AND office_title = '${COMMISSIONER_TITLE}';
  IF v_grp <> 5 THEN RAISE EXCEPTION 'seed payload: expected 5 ''${COMMISSIONER_TITLE}'' rows, got %', v_grp; END IF;

  -- Every OTHER (geo_id, district_type, office_title) combination must be
  -- unique -- these are the genuinely single-seat titles (Mayor, wards,
  -- Sheriff, Register of Deeds, Clerk of Superior Court).
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, district_type, office_title FROM durham_seed
    WHERE office_title NOT IN ('${AT_LARGE_TITLE}', '${COMMISSIONER_TITLE}')
    GROUP BY geo_id, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % unexpected duplicate single-seat (geo_id, district_type, office_title) key(s)', v_dup; END IF;
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
--
-- office_rank/seed_rank: deterministic row_number() pairing within each
-- (geo_id, district_type, office_title) group -- see file header for the
-- bijection argument. For every size-1 group this degenerates to "the one
-- office matches the one roster row", identical in effect to a plain title
-- join.

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    WITH office_rank AS (
      SELECT o.id AS office_id, d.geo_id, d.district_type, o.title,
             row_number() OVER (
               PARTITION BY d.geo_id, d.district_type, o.title ORDER BY o.id
             ) AS rn
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE (d.geo_id = '3719000' AND d.district_type = 'LOCAL')
         OR (d.geo_id = '37063' AND d.district_type = 'COUNTY')
    ),
    seed_rank AS (
      SELECT s.*,
             row_number() OVER (
               PARTITION BY s.geo_id, s.district_type, s.office_title ORDER BY s.ext_id
             ) AS rn
      FROM durham_seed s
    )
    SELECT sr.term_start, sr.start_precision, sr.how_started, sr.source,
           orr.office_id, p.id AS politician_id
    FROM seed_rank sr
    JOIN office_rank orr
      ON orr.geo_id = sr.geo_id
     AND orr.district_type = sr.district_type
     AND orr.title = sr.office_title
     AND orr.rn = sr.rn
    JOIN essentials.politicians p ON p.external_id = sr.ext_id
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = orr.office_id AND t.politician_id = p.id
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
