-- 1385_racine_county_government.sql
-- Racine County government: 2 chambers, 7 countywide elected officials, 21 County Board
-- supervisors, and their 28 offices. STRUCTURAL. Idempotent.
--
-- PRECONDITION: the 21 supervisor-district polygons must be loaded first --
--   npx tsx scripts/import-racine-supervisor-districts.ts
--   That creates geofence_boundaries + districts rows with mtfcc='X-RC-SUP',
--   geo_id='55101-sup-d{1..21}'. Without it the 21 supervisor offices insert ZERO rows
--   (the countywide 7 still land, since they hang off the pre-existing G4020 county district).
--
-- WHY: prod had NO Racine County government row at all, and the Racine County district
--   (geo_id 55101, G4020) existed with a geofence but ZERO offices -- so a Racine address
--   returned federal and state officials only, nothing local.
--
-- SOURCES (the WEC report covers ONLY state/federal offices -- no county tier exists in it):
--   - 21 supervisors + County Executive/Clerk/Treasurer/Register of Deeds/Clerk of Circuit
--     Court/District Attorney: racinecounty.gov department pages, read 2026-07-25. The county
--     site 403s on plain fetching; it was read through a browser.
--   - Sheriff Christopher Schmaling: the county's Sheriff page signs off with a signature
--     IMAGE and never prints the name, so this one name is sourced from secondary reporting
--     rather than the county site. WEAKEST link in this migration -- verify before relying on
--     it. (He is absent from the 2026 ballot, i.e. retiring at term end.)
--
-- !! The supervisor ROSTER is deliberately NOT taken from the county GIS layer that supplied
--    the polygons. That layer's REPNAME attribute is materially stale: 10 of 21 disagreed with
--    the county's roster page on 2026-07-25, and 4 were entirely DIFFERENT PEOPLE (D3 GIS
--    'Tom Rutkowski' vs actual Monte Osterman; D14 'Jason Eckman' vs James M. Hoffman;
--    D17 'Gary Kolb' vs Thomas Weatherston; D18 'Thomas E Roanhouse' vs Troy McReynolds).
--    Geometry from GIS, names from the roster page. Never the reverse.
--
-- CHAMBER SHAPE: follows Deschutes County, Oregon (2 chambers: a board + one bucket for the
--   countywide constitutional officers) rather than the Indiana pattern of one chamber PER
--   office, which would mean 8 near-empty chambers here.
--
-- CRITICAL (office guard divergence, mirrors AZ 1286's collegial-body note): the 21 supervisor
--   offices each own a distinct district, so a (district_id, chamber_id) guard is correct for
--   them. The 7 countywide offices ALL share the SAME district (55101) and the SAME chamber, so
--   that guard would silently no-op officials 2 through 7 -- they are guarded on
--   (district_id, chamber_id, title) instead. Titles are unique within the seven.
--
-- CRITICAL (two COUNTY tiers now share state='wi'): districts holds BOTH the 72 G4020 county
--   polygons AND the 21 X-RC-SUP supervisor districts as district_type='COUNTY'. Every join
--   below pins mtfcc as well as district_type, so a supervisor can never bind to the countywide
--   district or vice versa.
--
-- Racine County has an appointed MEDICAL EXAMINER, not an elected Coroner -- 7 elected
--   countywide offices, not the 8 a generic Wisconsin county template would assume.
--
-- ANTIPARTISAN + data honesty: politicians.party is left NULL for all 28. County pages do not
--   publish party, and inventing it is worse than omitting it. (County Executive and
--   supervisors are elected on NONPARTISAN spring ballots anyway; Sheriff, Clerk, Treasurer,
--   Register of Deeds, Clerk of Circuit Court and DA are partisan November offices.)
--
-- NO RACES here. Wisconsin county offices are filed with the COUNTY CLERK, not the WEC, so the
--   2026 county candidate field is not in any source parsed so far. County Executive and
--   supervisors were elected in the April 2026 spring election, which has already passed.
BEGIN;

-- ── 1. Government row (no unique constraint on geo_id -> NOT EXISTS guard) ──
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Racine County, Wisconsin, US', 'County', 'WI', NULL, '55101'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US'
);

-- ── 2. Two chambers (chambers.slug is GENERATED ALWAYS -- never in the column list) ──
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'County Board', 'Racine County Board of Supervisors',
       (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US'), 21
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'County Board'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Countywide Elected Officials',
       'Racine County Countywide Elected Officials',
       (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US'), 7
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Countywide Elected Officials'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
);

-- ── 3. 28 politicians (party intentionally NULL -- see header) ──
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    -- countywide constitutional officers
    (-5510001::bigint, 'Ralph Malicki'::text,       'Ralph'::text,    'Malicki'::text),
    (-5510002,         'Wendy M. Christensen',      'Wendy',          'Christensen'),
    (-5510003,         'Jeff Latus',                'Jeff',           'Latus'),
    (-5510004,         'Karie L. Pope',             'Karie',          'Pope'),
    (-5510005,         'Christopher Schmaling',     'Christopher',    'Schmaling'),
    (-5510006,         'Amy Vanderhoef',            'Amy',            'Vanderhoef'),
    (-5510007,         'Patricia J. Hanson',        'Patricia',       'Hanson'),
    -- County Board supervisors, districts 1-21
    (-5510101,         'Valena Lena Coleman',       'Valena',         'Coleman'),
    (-5510102,         'Renee Kelly',               'Renee',          'Kelly'),
    (-5510103,         'Monte Osterman',            'Monte',          'Osterman'),
    (-5510104,         'Melissa Kaprelian',         'Melissa',        'Kaprelian'),
    (-5510105,         'Jody Spencer',              'Jody',           'Spencer'),
    (-5510106,         'Q.A. Shakoor, II',          'Q.A.',           'Shakoor'),
    (-5510107,         'Ernie Rossi',               'Ernie',          'Rossi'),
    (-5510108,         'Brett A. Nielsen',          'Brett',          'Nielsen'),
    (-5510109,         'Eric Hopkins',              'Eric',           'Hopkins'),
    (-5510110,         'Tony Veranth',              'Tony',           'Veranth'),
    (-5510111,         'Robert N. Miller',          'Robert',         'Miller'),
    (-5510112,         'Don Trottier',              'Don',            'Trottier'),
    (-5510113,         'Tom Kramer',                'Tom',            'Kramer'),
    (-5510114,         'James M. Hoffman',          'James',          'Hoffman'),
    (-5510115,         'John Wisch',                'John',           'Wisch'),
    (-5510116,         'Scott Meier',               'Scott',          'Meier'),
    (-5510117,         'Thomas Weatherston',        'Thomas',         'Weatherston'),
    (-5510118,         'Troy McReynolds',           'Troy',           'McReynolds'),
    (-5510119,         'Greg Horeth',               'Greg',           'Horeth'),
    (-5510120,         'Tom Preusker',              'Tom',            'Preusker'),
    (-5510121,         'Taylor Wishau',             'Taylor',         'Wishau')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- ── 4. 7 countywide offices -> the pre-existing G4020 Racine County district ──
--    Guarded on (district_id, chamber_id, title): all seven share district AND chamber.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', false, false, 1
FROM (VALUES
    (-5510001::bigint, 'County Executive'::text),
    (-5510002,         'County Clerk'),
    (-5510003,         'County Treasurer'),
    (-5510004,         'Register of Deeds'),
    (-5510005,         'Sheriff'),
    (-5510006,         'Clerk of Circuit Court'),
    (-5510007,         'District Attorney')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '55101' AND d.district_type = 'COUNTY' AND d.mtfcc = 'G4020' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'Countywide Elected Officials'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = v.title
);

-- ── 5. 21 supervisor offices -> their OWN X-RC-SUP district (per-district routing) ──
--    One officeholder per district, so (district_id, chamber_id) is a sufficient guard here.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'County Board Supervisor', 'WI', false, false, 1
FROM (VALUES
    (-5510101::bigint, '55101-sup-d1'::text),  (-5510102, '55101-sup-d2'),
    (-5510103,         '55101-sup-d3'),        (-5510104, '55101-sup-d4'),
    (-5510105,         '55101-sup-d5'),        (-5510106, '55101-sup-d6'),
    (-5510107,         '55101-sup-d7'),        (-5510108, '55101-sup-d8'),
    (-5510109,         '55101-sup-d9'),        (-5510110, '55101-sup-d10'),
    (-5510111,         '55101-sup-d11'),       (-5510112, '55101-sup-d12'),
    (-5510113,         '55101-sup-d13'),       (-5510114, '55101-sup-d14'),
    (-5510115,         '55101-sup-d15'),       (-5510116, '55101-sup-d16'),
    (-5510117,         '55101-sup-d17'),       (-5510118, '55101-sup-d18'),
    (-5510119,         '55101-sup-d19'),       (-5510120, '55101-sup-d20'),
    (-5510121,         '55101-sup-d21')
  ) AS v(external_id, geo_id)
JOIN essentials.districts d
  ON d.geo_id = v.geo_id AND d.district_type = 'COUNTY' AND d.mtfcc = 'X-RC-SUP' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'County Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id
);

-- ── 6. Post-verify gate ──
DO $$
DECLARE
  n_govt int; n_chamber int; n_sup_d int; n_cw_off int; n_sup_off int;
  n_orphan int; n_crosstier int; n_party int;
BEGIN
  SELECT count(*) INTO n_govt FROM essentials.governments
   WHERE name = 'Racine County, Wisconsin, US';
  IF n_govt <> 1 THEN RAISE EXCEPTION 'expected 1 Racine County government row, found %', n_govt; END IF;

  SELECT count(*) INTO n_chamber FROM essentials.chambers
   WHERE government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US');
  IF n_chamber <> 2 THEN RAISE EXCEPTION 'expected 2 Racine County chambers, found %', n_chamber; END IF;

  SELECT count(*) INTO n_sup_d FROM essentials.districts
   WHERE mtfcc = 'X-RC-SUP' AND district_type = 'COUNTY' AND state = 'wi';
  IF n_sup_d <> 21 THEN
    RAISE EXCEPTION 'expected 21 X-RC-SUP districts, found % -- run import-racine-supervisor-districts.ts first', n_sup_d;
  END IF;

  SELECT count(*) INTO n_cw_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'Countywide Elected Officials'
     AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US');
  IF n_cw_off <> 7 THEN RAISE EXCEPTION 'countywide offices: got %, want 7', n_cw_off; END IF;

  SELECT count(*) INTO n_sup_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name = 'County Board'
     AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US');
  IF n_sup_off <> 21 THEN RAISE EXCEPTION 'supervisor offices: got %, want 21', n_sup_off; END IF;

  -- every seeded politician must hold exactly one office
  SELECT count(*) INTO n_orphan FROM essentials.politicians p
   WHERE p.external_id BETWEEN -5510121 AND -5510001
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);
  IF n_orphan <> 0 THEN RAISE EXCEPTION '% Racine County officials hold no office', n_orphan; END IF;

  -- no supervisor may be bound to the countywide district, and no countywide officer to a
  -- supervisor district (the shared district_type='COUNTY' hazard)
  SELECT count(*) INTO n_crosstier FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
     AND ((c.name = 'County Board' AND d.mtfcc <> 'X-RC-SUP')
       OR (c.name = 'Countywide Elected Officials' AND d.mtfcc <> 'G4020'));
  IF n_crosstier <> 0 THEN RAISE EXCEPTION '% Racine County offices bound to the wrong district tier', n_crosstier; END IF;

  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE external_id BETWEEN -5510121 AND -5510001 AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% Racine County officials carry an unsourced party', n_party; END IF;

  RAISE NOTICE 'Racine County verify PASSED: 1 government, 2 chambers, 7 countywide + 21 supervisor offices, 0 orphans, 0 cross-tier binds.';
END $$;

COMMIT;
