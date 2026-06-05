-- Migration 195: CA State Assembly
-- Creates assembly chamber (already exists as 'Assembly', rename to canonical name),
-- re-keys 36 pre-existing assembly politician rows (-100xxx -> -6002xxx),
-- updates 12 former-member rows to current incumbents (clearing old headshots),
-- inserts 44 new politician rows for gap districts,
-- creates 80 office rows linking assembly members to STATE_LOWER geofences,
-- and backfills office_id on all 80 assembly politicians.
--
-- Key facts:
--   - CA Assembly chamber already exists as name='Assembly', name_formal='California State Assembly',
--     slug='california-state-assembly'. Migration updates name to 'California State Assembly'.
--   - STATE_LOWER districts use state='CA' (uppercase) — pre-existing data
--   - geo_id format: '06' || lpad(district_num::text, 3, '0') e.g. AD-17 -> '06017'
--   - geofence_boundaries mtfcc='G5220' matches STATE_LOWER districts

BEGIN;

-- ============================================================
-- STEP 0: Update Assembly chamber name to canonical form
-- ============================================================
UPDATE essentials.chambers
SET name = 'California State Assembly'
WHERE name = 'Assembly'
  AND name_formal = 'California State Assembly'
  AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California');

-- If chamber somehow does not exist, create it (idempotent guard)
INSERT INTO essentials.chambers (id, name, name_formal, government_id)
SELECT gen_random_uuid(),
       'California State Assembly',
       'California State Assembly',
       (SELECT id FROM essentials.governments WHERE name = 'State of California')
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE name = 'California State Assembly'
    AND government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
);

-- ============================================================
-- STEP 1: UPDATE external_ids for 24 still-current pre-existing rows
-- Also fix name typos in the same UPDATE for accuracy.
-- ============================================================

-- AD-34: Tom Lackey
UPDATE essentials.politicians
SET external_id = -6002034
WHERE external_id = -100051;

-- AD-39: Juan Carrillo
UPDATE essentials.politicians
SET external_id = -6002039
WHERE external_id = -100053;

-- AD-40: Pilar Schiavo
UPDATE essentials.politicians
SET external_id = -6002040
WHERE external_id = -100055;

-- AD-41: John Harabedian
UPDATE essentials.politicians
SET external_id = -6002041
WHERE external_id = -100057;

-- AD-42: Jacqui Irwin
UPDATE essentials.politicians
SET external_id = -6002042
WHERE external_id = -100059;

-- AD-43: Celeste Rodriguez
UPDATE essentials.politicians
SET external_id = -6002043
WHERE external_id = -100061;

-- AD-44: Nick Schultz
UPDATE essentials.politicians
SET external_id = -6002044
WHERE external_id = -100063;

-- AD-46: Jesse Gabriel
UPDATE essentials.politicians
SET external_id = -6002046
WHERE external_id = -100065;

-- AD-48: Blanca E. Rubio (fix name from 'Blanca Rubio')
UPDATE essentials.politicians
SET external_id = -6002048,
    full_name = 'Blanca E. Rubio',
    first_name = 'Blanca E.',
    last_name = 'Rubio'
WHERE external_id = -100067;

-- AD-49: Mike Fong
UPDATE essentials.politicians
SET external_id = -6002049
WHERE external_id = -100069;

-- AD-51: Rick Chavez Zbur
UPDATE essentials.politicians
SET external_id = -6002051
WHERE external_id = -100071;

-- AD-52: Jessica M. Caloza (fix name from 'Jessica Caloza')
UPDATE essentials.politicians
SET external_id = -6002052,
    full_name = 'Jessica M. Caloza',
    first_name = 'Jessica M.',
    last_name = 'Caloza'
WHERE external_id = -100073;

-- AD-53: Michelle Rodriguez
UPDATE essentials.politicians
SET external_id = -6002053
WHERE external_id = -100075;

-- AD-54: Mark Gonzalez
UPDATE essentials.politicians
SET external_id = -6002054
WHERE external_id = -100077;

-- AD-55: Isaac G. Bryan
UPDATE essentials.politicians
SET external_id = -6002055
WHERE external_id = -100079;

-- AD-56: Lisa Calderon
UPDATE essentials.politicians
SET external_id = -6002056
WHERE external_id = -100081;

-- AD-57: Sade Elhawary
UPDATE essentials.politicians
SET external_id = -6002057
WHERE external_id = -100083;

-- AD-61: Tina S. McKinnor (fix name from 'Tina Simone McKinnor')
UPDATE essentials.politicians
SET external_id = -6002061,
    full_name = 'Tina S. McKinnor',
    first_name = 'Tina S.',
    last_name = 'McKinnor'
WHERE external_id = -100085;

-- AD-62: Jose Luis Solache Jr. (fix name from 'Jose Luis Solache')
UPDATE essentials.politicians
SET external_id = -6002062,
    full_name = 'Jose Luis Solache Jr.',
    last_name = 'Solache Jr.'
WHERE external_id = -100087;

-- AD-64: Blanca Pacheco (fix typo from 'Blanca Pachecco')
UPDATE essentials.politicians
SET external_id = -6002064,
    full_name = 'Blanca Pacheco',
    last_name = 'Pacheco'
WHERE external_id = -100089;

-- AD-65: Mike A. Gipson
UPDATE essentials.politicians
SET external_id = -6002065
WHERE external_id = -100091;

-- AD-66: Al Muratsuchi
UPDATE essentials.politicians
SET external_id = -6002066
WHERE external_id = -100093;

-- AD-67: Sharon Quirk-Silva
UPDATE essentials.politicians
SET external_id = -6002067
WHERE external_id = -100095;

-- AD-69: Josh Lowenthal
UPDATE essentials.politicians
SET external_id = -6002069
WHERE external_id = -100097;

-- ============================================================
-- STEP 2: Recycle 12 former-member rows for current incumbents
-- Clear old headshots first, then update name/party/external_id
-- ============================================================

-- AD-50: Robert Garcia (recycled from Tony Vazquez -100049)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100049);
UPDATE essentials.politicians
SET external_id = -6002050,
    full_name = 'Robert Garcia',
    first_name = 'Robert',
    last_name = 'Garcia',
    party = 'Democrat'
WHERE external_id = -100049;

-- AD-19: Catherine Stefani (recycled from Susan Rubio -100099)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100099);
UPDATE essentials.politicians
SET external_id = -6002019,
    full_name = 'Catherine Stefani',
    first_name = 'Catherine',
    last_name = 'Stefani',
    party = 'Democrat'
WHERE external_id = -100099;

-- AD-38: Steve Bennett (recycled from Suzette Martinez Valladares -100101)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100101);
UPDATE essentials.politicians
SET external_id = -6002038,
    full_name = 'Steve Bennett',
    first_name = 'Steve',
    last_name = 'Bennett',
    party = 'Democrat'
WHERE external_id = -100101;

-- AD-26: Patrick J. Ahrens (recycled from Benjamin Allen -100103)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100103);
UPDATE essentials.politicians
SET external_id = -6002026,
    full_name = 'Patrick J. Ahrens',
    first_name = 'Patrick J.',
    last_name = 'Ahrens',
    party = 'Democrat'
WHERE external_id = -100103;

-- AD-45: James C. Ramos (recycled from Sasha Renee Perez -100105)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100105);
UPDATE essentials.politicians
SET external_id = -6002045,
    full_name = 'James C. Ramos',
    first_name = 'James C.',
    last_name = 'Ramos',
    party = 'Democrat'
WHERE external_id = -100105;

-- AD-35: Jasmeet Kaur Bains (recycled from Maria Elena Durazo -100107)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100107);
UPDATE essentials.politicians
SET external_id = -6002035,
    full_name = 'Jasmeet Kaur Bains',
    first_name = 'Jasmeet Kaur',
    last_name = 'Bains',
    party = 'Democrat'
WHERE external_id = -100107;

-- AD-37: Gregg Hart (recycled from Henry Stern -100109)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100109);
UPDATE essentials.politicians
SET external_id = -6002037,
    full_name = 'Gregg Hart',
    first_name = 'Gregg',
    last_name = 'Hart',
    party = 'Democrat'
WHERE external_id = -100109;

-- AD-36: Jeff Gonzalez (recycled from Lola Smallwood-Cuevas -100111)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100111);
UPDATE essentials.politicians
SET external_id = -6002036,
    full_name = 'Jeff Gonzalez',
    first_name = 'Jeff',
    last_name = 'Gonzalez',
    party = 'Republican'
WHERE external_id = -100111;

-- AD-59: Phillip Chen (recycled from Bob Archuleta -100113)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100113);
UPDATE essentials.politicians
SET external_id = -6002059,
    full_name = 'Phillip Chen',
    first_name = 'Phillip',
    last_name = 'Chen',
    party = 'Republican'
WHERE external_id = -100113;

-- AD-33: Alexandra M. Macedo (recycled from Lena A. Gonzalez -100115)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100115);
UPDATE essentials.politicians
SET external_id = -6002033,
    full_name = 'Alexandra M. Macedo',
    first_name = 'Alexandra M.',
    last_name = 'Macedo',
    party = 'Republican'
WHERE external_id = -100115;

-- AD-60: Dr. Corey A. Jackson (recycled from Thomas J. Umberg -100117)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100117);
UPDATE essentials.politicians
SET external_id = -6002060,
    full_name = 'Dr. Corey A. Jackson',
    first_name = 'Dr. Corey A.',
    last_name = 'Jackson',
    party = 'Democrat'
WHERE external_id = -100117;

-- AD-20: Liz Ortega (recycled from Laura Richardson -100119)
DELETE FROM essentials.politician_images
WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -100119);
UPDATE essentials.politicians
SET external_id = -6002020,
    full_name = 'Liz Ortega',
    first_name = 'Liz',
    last_name = 'Ortega',
    party = 'Democrat'
WHERE external_id = -100119;

-- ============================================================
-- STEP 3: INSERT 44 new politician rows for gap districts
-- ============================================================

INSERT INTO essentials.politicians
  (id, full_name, first_name, last_name, party, is_active, is_appointed, is_vacant, is_incumbent, external_id)
VALUES
  (gen_random_uuid(), 'Heather Hadwick', 'Heather', 'Hadwick', 'Republican', true, false, false, true, -6002001),
  (gen_random_uuid(), 'Chris Rogers', 'Chris', 'Rogers', 'Democrat', true, false, false, true, -6002002),
  (gen_random_uuid(), 'James Gallagher', 'James', 'Gallagher', 'Republican', true, false, false, true, -6002003),
  (gen_random_uuid(), 'Cecilia M. Aguiar-Curry', 'Cecilia M.', 'Aguiar-Curry', 'Democrat', true, false, false, true, -6002004),
  (gen_random_uuid(), 'Joe Patterson', 'Joe', 'Patterson', 'Republican', true, false, false, true, -6002005),
  (gen_random_uuid(), 'Maggy Krell', 'Maggy', 'Krell', 'Democrat', true, false, false, true, -6002006),
  (gen_random_uuid(), 'Josh Hoover', 'Josh', 'Hoover', 'Republican', true, false, false, true, -6002007),
  (gen_random_uuid(), 'David J. Tangipa', 'David J.', 'Tangipa', 'Republican', true, false, false, true, -6002008),
  (gen_random_uuid(), 'Heath Flora', 'Heath', 'Flora', 'Republican', true, false, false, true, -6002009),
  (gen_random_uuid(), 'Stephanie Nguyen', 'Stephanie', 'Nguyen', 'Democrat', true, false, false, true, -6002010),
  (gen_random_uuid(), 'Lori D. Wilson', 'Lori D.', 'Wilson', 'Democrat', true, false, false, true, -6002011),
  (gen_random_uuid(), 'Damon Connolly', 'Damon', 'Connolly', 'Democrat', true, false, false, true, -6002012),
  (gen_random_uuid(), 'Rhodesia Ransom', 'Rhodesia', 'Ransom', 'Democrat', true, false, false, true, -6002013),
  (gen_random_uuid(), 'Buffy Wicks', 'Buffy', 'Wicks', 'Democrat', true, false, false, true, -6002014),
  (gen_random_uuid(), 'Anamarie Avila Farias', 'Anamarie', 'Avila Farias', 'Democrat', true, false, false, true, -6002015),
  (gen_random_uuid(), 'Rebecca Bauer-Kahan', 'Rebecca', 'Bauer-Kahan', 'Democrat', true, false, false, true, -6002016),
  (gen_random_uuid(), 'Matt Haney', 'Matt', 'Haney', 'Democrat', true, false, false, true, -6002017),
  (gen_random_uuid(), 'Mia Bonta', 'Mia', 'Bonta', 'Democrat', true, false, false, true, -6002018),
  (gen_random_uuid(), 'Diane Papan', 'Diane', 'Papan', 'Democrat', true, false, false, true, -6002021),
  (gen_random_uuid(), 'Juan Alanis', 'Juan', 'Alanis', 'Republican', true, false, false, true, -6002022),
  (gen_random_uuid(), 'Marc Berman', 'Marc', 'Berman', 'Democrat', true, false, false, true, -6002023),
  (gen_random_uuid(), 'Alex Lee', 'Alex', 'Lee', 'Democrat', true, false, false, true, -6002024),
  (gen_random_uuid(), 'Ash Kalra', 'Ash', 'Kalra', 'Democrat', true, false, false, true, -6002025),
  (gen_random_uuid(), 'Esmeralda Z. Soria', 'Esmeralda Z.', 'Soria', 'Democrat', true, false, false, true, -6002027),
  (gen_random_uuid(), 'Gail Pellerin', 'Gail', 'Pellerin', 'Democrat', true, false, false, true, -6002028),
  (gen_random_uuid(), 'Robert Rivas', 'Robert', 'Rivas', 'Democrat', true, false, false, true, -6002029),
  (gen_random_uuid(), 'Dawn Addis', 'Dawn', 'Addis', 'Democrat', true, false, false, true, -6002030),
  (gen_random_uuid(), 'Dr. Joaquin Arambula', 'Dr. Joaquin', 'Arambula', 'Democrat', true, false, false, true, -6002031),
  (gen_random_uuid(), 'Stan Ellis', 'Stan', 'Ellis', 'Republican', true, false, false, true, -6002032),
  (gen_random_uuid(), 'Greg Wallis', 'Greg', 'Wallis', 'Republican', true, false, false, true, -6002047),
  (gen_random_uuid(), 'Leticia Castillo', 'Leticia', 'Castillo', 'Republican', true, false, false, true, -6002058),
  (gen_random_uuid(), 'Natasha Johnson', 'Natasha', 'Johnson', 'Republican', true, false, false, true, -6002063),
  (gen_random_uuid(), 'Avelino Valencia', 'Avelino', 'Valencia', 'Democrat', true, false, false, true, -6002068),
  (gen_random_uuid(), 'Tri Ta', 'Tri', 'Ta', 'Republican', true, false, false, true, -6002070),
  (gen_random_uuid(), 'Kate Sanchez', 'Kate', 'Sanchez', 'Republican', true, false, false, true, -6002071),
  (gen_random_uuid(), 'Diane B. Dixon', 'Diane B.', 'Dixon', 'Republican', true, false, false, true, -6002072),
  (gen_random_uuid(), 'Cottie Petrie-Norris', 'Cottie', 'Petrie-Norris', 'Democrat', true, false, false, true, -6002073),
  (gen_random_uuid(), 'Laurie Davies', 'Laurie', 'Davies', 'Republican', true, false, false, true, -6002074),
  (gen_random_uuid(), 'Carl DeMaio', 'Carl', 'DeMaio', 'Republican', true, false, false, true, -6002075),
  (gen_random_uuid(), 'Dr. Darshana R. Patel', 'Dr. Darshana R.', 'Patel', 'Democrat', true, false, false, true, -6002076),
  (gen_random_uuid(), 'Tasha Boerner', 'Tasha', 'Boerner', 'Democrat', true, false, false, true, -6002077),
  (gen_random_uuid(), 'Christopher M. Ward', 'Christopher M.', 'Ward', 'Democrat', true, false, false, true, -6002078),
  (gen_random_uuid(), 'Dr. LaShae Sharp-Collins', 'Dr. LaShae', 'Sharp-Collins', 'Democrat', true, false, false, true, -6002079),
  (gen_random_uuid(), 'David A. Alvarez', 'David A.', 'Alvarez', 'Democrat', true, false, false, true, -6002080)
ON CONFLICT (external_id) DO NOTHING;

-- ============================================================
-- STEP 4: INSERT office rows for ALL 80 assembly members
-- Uses geo_id = '06' || lpad(district_num, 3, '0')
-- district_type = 'STATE_LOWER', state = 'CA' (uppercase — pre-existing CA data)
-- ============================================================

INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant)
SELECT
  gen_random_uuid(),
  d.id,
  c.id,
  p.id,
  'Assembly Member',
  'CA',
  false,
  false
FROM essentials.districts d
CROSS JOIN essentials.chambers c
JOIN essentials.politicians p ON p.external_id = (-6002000 - CAST(REGEXP_REPLACE(d.geo_id, '^06', '') AS INTEGER))
WHERE d.district_type = 'STATE_LOWER'
  AND d.state = 'CA'
  AND d.geo_id BETWEEN '06001' AND '06080'
  AND c.name = 'California State Assembly'
  AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'State of California')
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id
      AND o.chamber_id = c.id
  );

-- ============================================================
-- STEP 5: Backfill office_id on all 80 assembly politicians
-- ============================================================

UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
JOIN essentials.chambers c ON c.id = o.chamber_id
WHERE o.politician_id = p.id
  AND c.name = 'California State Assembly'
  AND p.external_id BETWEEN -6002080 AND -6002001
  AND p.office_id IS NULL;

COMMIT;
