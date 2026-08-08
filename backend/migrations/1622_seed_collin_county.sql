-- 1622: seed Collin County, Texas, US - Commissioners Court
--
-- 5 seats: 5 occupied, 0 seeded VACANT.
--
-- Government row ALREADY EXISTS with 0 chambers (the empty shell). Adds the chamber only.
-- COUNTY district on 48085 already exists (G4020) and is reused.
-- WARNING: geo_id 48085 is ambiguous - it is also TX House District 85 (G5220).
-- Every lookup below is qualified by mtfcc/district_type for exactly this reason.
--
-- Roster source: Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md
-- Party is NULL throughout (antipartisan design). role_canonical NULL and external_id NULL,
-- matching the current TX pattern (City of Frisco) rather than the legacy Lynn scheme.
-- Occupancy is expressed as is_incumbent=true + an office_terms row; term dates are left NULL,
-- which is what every existing TX city row does.

BEGIN;

-- Pre-flight 1: abort on double-apply
DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.chambers c
        JOIN essentials.governments g ON g.id = c.government_id
       WHERE g.name = 'Collin County, Texas, US' AND c.name = 'Commissioners Court') > 0 THEN
    RAISE EXCEPTION 'Migration 1622 already applied - Collin County, Texas, US / Commissioners Court exists';
  END IF;
END $$;

-- Pre-flight 2: the TIGER geofence must already exist (seeds never create geofences).
-- Qualified by mtfcc because geo_id is NOT unique across layers.
DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.geofence_boundaries
       WHERE geo_id = '48085' AND mtfcc = 'G4020') = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: geofence 48085/G4020 not found';
  END IF;
END $$;

-- Government row already exists (the empty shell) - assert, do not insert.
DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.governments WHERE name = 'Collin County, Texas, US') <> 1 THEN
    RAISE EXCEPTION 'expected the existing Collin County, Texas, US shell row';
  END IF;
END $$;

-- Assert exactly ONE district to attach offices to. Runs AFTER the district insert above,
-- because for a city that district is created by this migration. Qualified by district_type +
-- state because geo_id alone is NOT unique across layers.
DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.districts
       WHERE geo_id = '48085' AND district_type = 'COUNTY' AND state = 'tx') <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 COUNTY district for 48085';
  END IF;
END $$;

-- Chamber. slug is GENERATED ALWAYS - never list it.
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Commissioners Court', 'Collin County Commissioners Court',
       (SELECT id FROM essentials.governments WHERE name = 'Collin County, Texas, US'), 5
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers c JOIN essentials.governments gg ON gg.id = c.government_id
   WHERE gg.name = 'Collin County, Texas, US' AND c.name = 'Commissioners Court');

-- County Judge - Chris Hill
-- office_id is set ON THE POLITICIAN INSERT, not by a follow-up UPDATE: data-modifying CTEs
-- cannot see each other's rows, so an UPDATE over essentials.politicians in this same
-- statement would scan a snapshot without the row just inserted and match zero rows.
WITH ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='48085' AND district_type='COUNTY' AND state='tx'),
         'County Judge', 'TX', NULL, 1, false, false, NULL
  RETURNING id
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), 'Chris Hill', 'Chris', 'Hill', NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', ofc.id
    FROM ofc
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), pol.office_id, pol.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol;

-- Commissioner, Precinct 1 - Susan Fletcher
-- office_id is set ON THE POLITICIAN INSERT, not by a follow-up UPDATE: data-modifying CTEs
-- cannot see each other's rows, so an UPDATE over essentials.politicians in this same
-- statement would scan a snapshot without the row just inserted and match zero rows.
WITH ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='48085' AND district_type='COUNTY' AND state='tx'),
         'Commissioner, Precinct 1', 'TX', NULL, 1, false, false, NULL
  RETURNING id
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), 'Susan Fletcher', 'Susan', 'Fletcher', NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', ofc.id
    FROM ofc
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), pol.office_id, pol.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol;

-- Commissioner, Precinct 2 - Cheryl Williams
-- office_id is set ON THE POLITICIAN INSERT, not by a follow-up UPDATE: data-modifying CTEs
-- cannot see each other's rows, so an UPDATE over essentials.politicians in this same
-- statement would scan a snapshot without the row just inserted and match zero rows.
WITH ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='48085' AND district_type='COUNTY' AND state='tx'),
         'Commissioner, Precinct 2', 'TX', NULL, 1, false, false, NULL
  RETURNING id
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), 'Cheryl Williams', 'Cheryl', 'Williams', NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', ofc.id
    FROM ofc
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), pol.office_id, pol.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol;

-- Commissioner, Precinct 3 - Darrell Hale
-- office_id is set ON THE POLITICIAN INSERT, not by a follow-up UPDATE: data-modifying CTEs
-- cannot see each other's rows, so an UPDATE over essentials.politicians in this same
-- statement would scan a snapshot without the row just inserted and match zero rows.
WITH ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='48085' AND district_type='COUNTY' AND state='tx'),
         'Commissioner, Precinct 3', 'TX', NULL, 1, false, false, NULL
  RETURNING id
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), 'Darrell Hale', 'Darrell', 'Hale', NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', ofc.id
    FROM ofc
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), pol.office_id, pol.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol;

-- Commissioner, Precinct 4 - Duncan Webb
-- office_id is set ON THE POLITICIAN INSERT, not by a follow-up UPDATE: data-modifying CTEs
-- cannot see each other's rows, so an UPDATE over essentials.politicians in this same
-- statement would scan a snapshot without the row just inserted and match zero rows.
WITH ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='48085' AND district_type='COUNTY' AND state='tx'),
         'Commissioner, Precinct 4', 'TX', NULL, 1, false, false, NULL
  RETURNING id
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), 'Duncan Webb', 'Duncan', 'Webb', NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', ofc.id
    FROM ofc
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), pol.office_id, pol.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol;

-- Post-verify: assert on ROW COUNTS, never on absence of error.
DO $$
DECLARE v_off int; v_fill int; v_vac int; v_term int; v_orphan int;
  v_chamber uuid;
BEGIN
  SELECT (SELECT id FROM essentials.chambers WHERE name='Commissioners Court' AND government_id=(SELECT id FROM essentials.governments WHERE name='Collin County, Texas, US')) INTO v_chamber;
  SELECT count(*) INTO v_off  FROM essentials.offices WHERE chamber_id = v_chamber;
  IF v_off <> 5 THEN RAISE EXCEPTION 'expected 5 offices, found %', v_off; END IF;

  SELECT count(*) INTO v_vac FROM essentials.offices WHERE chamber_id = v_chamber AND is_vacant;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'expected 0 vacant offices, found %', v_vac; END IF;

  SELECT count(*) INTO v_fill FROM essentials.offices WHERE chamber_id = v_chamber AND NOT is_vacant;
  IF v_fill <> 5 THEN RAISE EXCEPTION 'expected 5 filled offices, found %', v_fill; END IF;

  SELECT count(*) INTO v_term FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id WHERE o.chamber_id = v_chamber;
  IF v_term <> 5 THEN RAISE EXCEPTION 'expected 5 office_terms, found %', v_term; END IF;

  -- every seeded politician must be linked back via office_id
  SELECT count(*) INTO v_orphan FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.politicians p ON p.id = ot.politician_id
   WHERE o.chamber_id = v_chamber AND (p.office_id IS NULL OR p.office_id <> o.id);
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% politicians missing the office_id back-fill', v_orphan; END IF;

  -- a vacant office must never carry a term
  SELECT count(*) INTO v_orphan FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
   WHERE o.chamber_id = v_chamber AND o.is_vacant;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% vacant offices carry an office_term', v_orphan; END IF;
END $$;

COMMIT;
