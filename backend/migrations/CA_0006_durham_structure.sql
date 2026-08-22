-- CA_0006_durham_structure.sql
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
-- migrations/CA_0007_durham_incumbents.sql, through essentials.office_terms.
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
-- Neither government row exists yet (verified against prod 2026-08-22: zero
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
  ('Council Member, Ward 1',         'Ward 1 is a residency requirement for candidacy, not an election district: a candidate for this seat must reside in Ward 1 of the City of Durham. The candidate is, however, elected by all city voters. Wards do not affect where a resident votes or which candidate(s) a resident can vote for. (durhamnc.gov/1396/City-Council-Members, retrieved 2026-08-22.)'),
  ('Council Member, Ward 2',         'Ward 2 is a residency requirement for candidacy, not an election district: a candidate for this seat must reside in Ward 2 of the City of Durham. The candidate is, however, elected by all city voters. Wards do not affect where a resident votes or which candidate(s) a resident can vote for. (durhamnc.gov/1396/City-Council-Members, retrieved 2026-08-22.)'),
  ('Council Member, Ward 3',         'Ward 3 is a residency requirement for candidacy, not an election district: a candidate for this seat must reside in Ward 3 of the City of Durham. The candidate is, however, elected by all city voters. Wards do not affect where a resident votes or which candidate(s) a resident can vote for. (durhamnc.gov/1396/City-Council-Members, retrieved 2026-08-22.)')
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
--
-- 🔴 CAVEAT FOR FUTURE WAVES: the top-up below counts existing offices scoped
-- to chamber_id ALONE, not to (chamber_id, district_id). That is correct here
-- because Durham's City Council chamber maps to exactly one district (the
-- Citywide LOCAL district) -- there is nothing else for the count to
-- conflate with. It stops being correct the moment a chamber spans MULTIPLE
-- districts, e.g. Buncombe County's Commission in wave 3: six 'Commissioner'
-- seats spread across three districts (HD-114/115/116) within one chamber.
-- A chamber-scoped count there would top up to 6 total and could land all
-- six offices on a single district while still reporting "6 offices
-- created" -- a silent misassignment, not an error. Any wave that copies
-- this top-up pattern onto a chamber spanning multiple districts MUST scope
-- the existing-count subquery to (chamber_id, district_id) together, not
-- chamber_id alone.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Council Member, At-Large', 'NC', 'Durham'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '3719000' AND dd.district_type = 'LOCAL' AND lower(dd.state) = 'nc'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 3 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = 'Council Member, At-Large'
  )) AS n
) gs
WHERE g.geo_id = '3719000' AND g.type = 'City' AND c.name = 'City Council';

-- ─── 5a. County commission offices: 5 IDENTICAL 'Commissioner' rows ─────────
-- 🔴 district join MUST pair geo_id with district_type = 'COUNTY' -- see
-- header. A bare geo_id = '37063' join matches NC House District 63 too.
-- Same target-count top-up as 4b, for the same reason (no numbered seat on
-- Durham County's ballot either).
--
-- 🔴 SAME CAVEAT AS 4b: this top-up counts existing 'Commissioner' offices
-- scoped to chamber_id alone, which is correct only because Durham's Board
-- of County Commissioners chamber maps to exactly one district (COUNTY
-- 37063). It becomes WRONG the moment a chamber spans multiple districts --
-- exactly the shape of Buncombe County's Commission in wave 3, six seats
-- across three districts (HD-114/115/116) in one chamber -- where a
-- chamber-scoped count could top up to 6 total and land them all on one
-- district while still reporting "6 offices created". Any wave copying this
-- pattern onto a chamber that spans districts MUST scope the count to
-- (chamber_id, district_id) together, not chamber_id alone.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, 'Commissioner', 'NC'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '37063' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 5 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = 'Commissioner'
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
  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL' AND o.title = 'Mayor';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Mayor', '3719000', 'LOCAL', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL' AND o.title = 'Council Member, Ward 1';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Council Member, Ward 1', '3719000', 'LOCAL', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL' AND o.title = 'Council Member, Ward 2';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Council Member, Ward 2', '3719000', 'LOCAL', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL' AND o.title = 'Council Member, Ward 3';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Council Member, Ward 3', '3719000', 'LOCAL', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '3719000' AND d.district_type = 'LOCAL' AND o.title = 'Council Member, At-Large';
  IF n_check <> 3 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 3, 'Council Member, At-Large', '3719000', 'LOCAL', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'COUNTY' AND o.title = 'Commissioner';
  IF n_check <> 5 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 5, 'Commissioner', '37063', 'COUNTY', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'COUNTY' AND o.title = 'Sheriff';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Sheriff', '37063', 'COUNTY', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'COUNTY' AND o.title = 'Register of Deeds';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Register of Deeds', '37063', 'COUNTY', n_check;
  END IF;

  SELECT count(*) INTO n_check FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'COUNTY' AND o.title = 'Clerk of Superior Court';
  IF n_check <> 1 THEN
    RAISE EXCEPTION 'CA_0006: expected % office(s) titled % on (%, %), found %', 1, 'Clerk of Superior Court', '37063', 'COUNTY', n_check;
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
