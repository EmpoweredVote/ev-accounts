-- 1623: seed City of Fort Worth, Texas, US - City Council
--
-- 11 seats: 11 occupied, 0 seeded VACANT.
--
-- Districts run 2-11; there is NO District 1. Ten districts + mayor = 11 seats, which
-- reconciles exactly with Ballotpedia's seat count, so the mayor occupies the "1" slot.
-- A District 1 office is deliberately NOT invented.
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
       WHERE g.name='City of Fort Worth, Texas, US' AND c.name='City Council') > 0 THEN
    RAISE EXCEPTION 'Migration 1623 already applied';
  END IF;
  IF (SELECT count(*) FROM essentials.geofence_boundaries WHERE geo_id='4827000' AND mtfcc='G4110') = 0 THEN
    RAISE EXCEPTION 'Pre-flight FAILED: geofence 4827000/G4110 not found';
  END IF;
END $$;

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Fort Worth, Texas, US', 'LOCAL', 'TX', 'Fort Worth', '4827000'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name='City of Fort Worth, Texas, US');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, ocd_id, government_id)
SELECT gen_random_uuid(), 'LOCAL', 'tx', '4827000', 'City of Fort Worth', 'G4110',
       'ocd-division/country:us/state:tx/place:fort_worth',
       (SELECT id FROM essentials.governments WHERE name='City of Fort Worth, Texas, US')
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
  WHERE geo_id='4827000' AND district_type='LOCAL' AND state='tx');

DO $$
BEGIN
  IF (SELECT count(*) FROM essentials.districts
       WHERE geo_id='4827000' AND district_type='LOCAL' AND state='tx') <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 LOCAL district for 4827000';
  END IF;
END $$;

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'City Council', 'Fort Worth City Council',
       (SELECT id FROM essentials.governments WHERE name='City of Fort Worth, Texas, US'), 11
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c JOIN essentials.governments gg ON gg.id=c.government_id
  WHERE gg.name='City of Fort Worth, Texas, US' AND c.name='City Council');

-- 11 occupied seats. Titles are unique within the chamber, which is what the
-- ofc/seats join below relies on.
WITH seats(title, full_name, first_name, last_name) AS (VALUES
  ('Mayor', 'Mattie Parker', 'Mattie', 'Parker'),
  ('Council Member District 2', 'Carlos Flores', 'Carlos', 'Flores'),
  ('Council Member District 3', 'Michael D. Crain', 'Michael', 'Crain'),
  ('Council Member District 4', 'Charles Lauersdorf', 'Charles', 'Lauersdorf'),
  ('Council Member District 5', 'Deborah Peoples', 'Deborah', 'Peoples'),
  ('Council Member District 6', 'Mia Hall', 'Mia', 'Hall'),
  ('Council Member District 7', 'Macy Hill', 'Macy', 'Hill'),
  ('Council Member District 8', 'Chris Nettles', 'Chris', 'Nettles'),
  ('Council Member District 9', 'Elizabeth M. Beck', 'Elizabeth', 'Beck'),
  ('Council Member District 10', 'Chris Jamieson', 'Chris', 'Jamieson'),
  ('Council Member District 11', 'Jeanette Martinez', 'Jeanette', 'Martinez')
), ofc AS (
  INSERT INTO essentials.offices
    (id, chamber_id, district_id, title, representing_state, representing_city, seats,
     is_appointed_position, is_vacant, role_canonical)
  SELECT gen_random_uuid(), (SELECT id FROM essentials.chambers WHERE name='City Council' AND government_id=(SELECT id FROM essentials.governments WHERE name='City of Fort Worth, Texas, US')), (SELECT id FROM essentials.districts WHERE geo_id='4827000' AND district_type='LOCAL' AND state='tx'), s.title, 'TX', 'Fort Worth', 1, false, false, NULL
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
  SELECT (SELECT id FROM essentials.chambers WHERE name='City Council' AND government_id=(SELECT id FROM essentials.governments WHERE name='City of Fort Worth, Texas, US')) INTO v_ch;
  SELECT count(*) INTO v_off FROM essentials.offices WHERE chamber_id=v_ch;
  IF v_off <> 11 THEN RAISE EXCEPTION 'expected 11 offices, found %', v_off; END IF;
  SELECT count(*) INTO v_vac FROM essentials.offices WHERE chamber_id=v_ch AND is_vacant;
  IF v_vac <> 0 THEN RAISE EXCEPTION 'expected 0 vacant, found %', v_vac; END IF;
  SELECT count(*) INTO v_fill FROM essentials.offices WHERE chamber_id=v_ch AND NOT is_vacant;
  IF v_fill <> 11 THEN RAISE EXCEPTION 'expected 11 filled, found %', v_fill; END IF;
  SELECT count(*) INTO v_term FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id WHERE o.chamber_id=v_ch;
  IF v_term <> 11 THEN RAISE EXCEPTION 'expected 11 office_terms, found %', v_term; END IF;
  SELECT count(*) INTO v_bad FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id
    JOIN essentials.politicians p ON p.id=ot.politician_id
   WHERE o.chamber_id=v_ch AND (p.office_id IS NULL OR p.office_id <> o.id);
  IF v_bad <> 0 THEN RAISE EXCEPTION '% politicians missing office_id back-fill', v_bad; END IF;
  SELECT count(*) INTO v_bad FROM essentials.office_terms ot JOIN essentials.offices o ON o.id=ot.office_id
   WHERE o.chamber_id=v_ch AND o.is_vacant;
  IF v_bad <> 0 THEN RAISE EXCEPTION '% vacant offices carry a term', v_bad; END IF;
END $$;

COMMIT;
