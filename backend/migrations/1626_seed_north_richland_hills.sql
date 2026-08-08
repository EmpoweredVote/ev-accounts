-- 1626: seed City of North Richland Hills, Texas, US - City Council
--
-- 8 seats: 8 occupied, 0 seeded VACANT.
--
-- Mayor + SEVEN places, all at-large, three-year terms. Mayor Pro Tem is not a title.
--
-- Roster source: Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md
-- party NULL (antipartisan), role_canonical NULL, external_id NULL - matches the current TX
-- pattern (City of Frisco), not the legacy Lynn scheme. Occupancy = is_incumbent + an
-- office_terms row; term dates NULL, as every existing TX city row has.
-- office_id is set ON THE POLITICIAN INSERT: data-modifying CTEs cannot see each other's
-- rows, so a follow-up UPDATE would scan a stale snapshot and match zero rows.

BEGIN;

DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.chambers c JOIN essentials.governments g ON g.id=c.government_id
       WHERE g.name='City of North Richland Hills, Texas, US' AND c.name='City Council') > 0 THEN
    RAISE EXCEPTION 'Migration 1626 already applied';
  END IF;
  IF (SELECT count(*) FROM essentials.geofence_boundaries WHERE geo_id='4852356' AND mtfcc='G4110') = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: geofence 4852356/G4110 not found';
  END IF;
END $$;

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of North Richland Hills, Texas, US', 'LOCAL', 'TX', 'North Richland Hills', '4852356'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name='City of North Richland Hills, Texas, US');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, ocd_id, government_id)
SELECT gen_random_uuid(), 'LOCAL', 'tx', '4852356', 'City of North Richland Hills', 'G4110',
       'ocd-division/country:us/state:tx/place:north_richland_hills',
       (SELECT id FROM essentials.governments WHERE name='City of North Richland Hills, Texas, US')
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
  WHERE geo_id='4852356' AND district_type='LOCAL' AND state='tx');

DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.districts
       WHERE geo_id='4852356' AND district_type='LOCAL' AND state='tx') <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 LOCAL district for 4852356';
  END IF;
END $$;

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'City Council', 'North Richland Hills City Council',
       (SELECT id FROM essentials.governments WHERE name='City of North Richland Hills, Texas, US'), 8
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c JOIN essentials.governments gg ON gg.id=c.government_id
  WHERE gg.name='City of North Richland Hills, Texas, US' AND c.name='City Council');

-- 8 occupied seats. Titles are unique within the chamber, which is what the
-- ofc/seats join below relies on.
WITH seats(title, full_name, first_name, last_name) AS (VALUES
  ('Mayor', 'Jack McCarty', 'Jack', 'McCarty'),
  ('Council Member Place 1', 'Cecille Delaney', 'Cecille', 'Delaney'),
  ('Council Member Place 2', 'Brianne Goetz', 'Brianne', 'Goetz'),
  ('Council Member Place 3', 'Danny Roberts', 'Danny', 'Roberts'),
  ('Council Member Place 4', 'Matt Blake', 'Matt', 'Blake'),
  ('Council Member Place 5', 'Billy Parks', 'Billy', 'Parks'),
  ('Council Member Place 6', 'Russ Mitchell', 'Russ', 'Mitchell'),
  ('Council Member Place 7', 'Kelvin Deupree', 'Kelvin', 'Deupree')
), ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='City Council' AND government_id=(SELECT id FROM essentials.governments WHERE name='City of North Richland Hills, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='4852356' AND district_type='LOCAL' AND state='tx'), s.title, 'TX', 'North Richland Hills', 1, false, false, NULL
    FROM seats s
  RETURNING id, title
), pol AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant,
     is_incumbent, data_source, office_id)
  SELECT gen_random_uuid(), s.full_name, s.first_name, s.last_name, NULL,
         true, false, false, true, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md', o.id
    FROM seats s JOIN ofc o ON o.title = s.title
  RETURNING id, office_id
)
INSERT INTO essentials.office_terms (id, office_id, politician_id, source)
SELECT gen_random_uuid(), p.office_id, p.id, 'Tarrant seed 2026-08-08; see backend/data/seed-tarrant-2026/ROSTERS.md' FROM pol p;

DO $$
DECLARE v_off int; v_fill int; v_vac int; v_term int; v_bad int; v_ch uuid;
BEGIN
  SELECT (SELECT id FROM essentials.chambers WHERE name='City Council' AND government_id=(SELECT id FROM essentials.governments WHERE name='City of North Richland Hills, Texas, US')) INTO v_ch;
  SELECT count(*) INTO v_off FROM essentials.offices WHERE chamber_id=v_ch;
  IF v_off <> 8 THEN RAISE EXCEPTION 'expected 8 offices, found %', v_off; END IF;
  SELECT count(*) INTO v_vac FROM essentials.offices WHERE chamber_id=v_ch AND is_vacant;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'expected 0 vacant, found %', v_vac; END IF;
  SELECT count(*) INTO v_fill FROM essentials.offices WHERE chamber_id=v_ch AND NOT is_vacant;
  IF v_fill <> 8 THEN RAISE EXCEPTION 'expected 8 filled, found %', v_fill; END IF;
  SELECT count(*) INTO v_term FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id WHERE o.chamber_id=v_ch;
  IF v_term <> 8 THEN RAISE EXCEPTION 'expected 8 office_terms, found %', v_term; END IF;
  SELECT count(*) INTO v_bad FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id
    JOIN essentials.politicians p ON p.id=ot.politician_id
   WHERE o.chamber_id=v_ch AND (p.office_id IS NULL OR p.office_id <> o.id);
  IF v_bad <> 0 THEN RAISE EXCEPTION '% politicians missing office_id back-fill', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id
   WHERE o.chamber_id=v_ch AND o.is_vacant;
  IF v_bad <> 0 THEN RAISE EXCEPTION '% vacant offices carry a term', v_bad; END IF;
END $$;

COMMIT;
