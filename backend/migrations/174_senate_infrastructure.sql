-- Migration 174: Senate Infrastructure
-- Adds government_id FK column to essentials.districts, creates government stubs
-- for all 50 states, inserts NATIONAL_UPPER district rows for the 45 states that
-- lack them, fixes two pre-existing data quality issues (CA junk row + IN duplicate),
-- and backfills government_id on all 50 NATIONAL_UPPER rows.
--
-- Pre-state:
--   NATIONAL_UPPER districts: 7 rows (CA x2, IN x2, MA x1, ME x1, TX x1)
--   essentials.governments state rows: 4 states (CA, IN, ME, TX)
-- Post-state:
--   NATIONAL_UPPER districts: 50 rows (one per state, all with government_id)
--   essentials.governments state rows: >= 50 states

BEGIN;

-- ============================================================
-- Step 1: Add government_id column (DDL first)
-- ============================================================
ALTER TABLE essentials.districts
  ADD COLUMN IF NOT EXISTS government_id UUID REFERENCES essentials.governments(id);

-- ============================================================
-- Step 2: Delete CA junk NATIONAL_UPPER row (geo_id='', 0 offices)
-- ============================================================
DELETE FROM essentials.districts
WHERE id = 'e8ffae97-d5df-4061-b85b-a0aa3c790f4e'
  AND district_type = 'NATIONAL_UPPER'
  AND state = 'CA'
  AND geo_id = '';

-- ============================================================
-- Step 3: Reassign Todd Young's office from orphan IN district
--         to canonical IN district
-- ============================================================
UPDATE essentials.offices
SET district_id = '343b3268-d048-4e6d-97de-963590dfddf8'
WHERE id = 'fa8e5ddc-cf1a-4aed-86c9-f7281e25e3c5'
  AND district_id = 'ed02bc1b-d184-4233-954a-12206250ece5';

-- ============================================================
-- Step 4: Delete the orphan IN NATIONAL_UPPER district row
--         (safe now that Todd Young has been reassigned)
-- ============================================================
DELETE FROM essentials.districts
WHERE id = 'ed02bc1b-d184-4233-954a-12206250ece5'
  AND district_type = 'NATIONAL_UPPER'
  AND state = 'IN'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices WHERE district_id = 'ed02bc1b-d184-4233-954a-12206250ece5'
  );

-- ============================================================
-- Step 5: Insert government stubs for 46 states
--         (MA + 45 other states missing from essentials.governments)
-- ============================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Alaska', 'STATE', 'AK', '', '02'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Alaska' AND state = 'AK');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Alabama', 'STATE', 'AL', '', '01'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Alabama' AND state = 'AL');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Arkansas', 'STATE', 'AR', '', '05'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Arkansas' AND state = 'AR');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Arizona', 'STATE', 'AZ', '', '04'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Arizona' AND state = 'AZ');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Colorado', 'STATE', 'CO', '', '08'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Colorado' AND state = 'CO');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Connecticut', 'STATE', 'CT', '', '09'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Connecticut' AND state = 'CT');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Delaware', 'STATE', 'DE', '', '10'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Delaware' AND state = 'DE');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Florida', 'STATE', 'FL', '', '12'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Florida' AND state = 'FL');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Georgia', 'STATE', 'GA', '', '13'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Georgia' AND state = 'GA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Hawaii', 'STATE', 'HI', '', '15'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Hawaii' AND state = 'HI');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Iowa', 'STATE', 'IA', '', '19'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Iowa' AND state = 'IA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Idaho', 'STATE', 'ID', '', '16'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Idaho' AND state = 'ID');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Illinois', 'STATE', 'IL', '', '17'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Illinois' AND state = 'IL');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Kansas', 'STATE', 'KS', '', '20'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Kansas' AND state = 'KS');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Kentucky', 'STATE', 'KY', '', '21'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Kentucky' AND state = 'KY');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Louisiana', 'STATE', 'LA', '', '22'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Louisiana' AND state = 'LA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Massachusetts', 'STATE', 'MA', '', '25'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Massachusetts' AND state = 'MA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Maryland', 'STATE', 'MD', '', '24'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Maryland' AND state = 'MD');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Michigan', 'STATE', 'MI', '', '26'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Michigan' AND state = 'MI');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Minnesota', 'STATE', 'MN', '', '27'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Minnesota' AND state = 'MN');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Missouri', 'STATE', 'MO', '', '29'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Missouri' AND state = 'MO');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Mississippi', 'STATE', 'MS', '', '28'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Mississippi' AND state = 'MS');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Montana', 'STATE', 'MT', '', '30'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Montana' AND state = 'MT');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of North Carolina', 'STATE', 'NC', '', '37'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of North Carolina' AND state = 'NC');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of North Dakota', 'STATE', 'ND', '', '38'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of North Dakota' AND state = 'ND');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Nebraska', 'STATE', 'NE', '', '31'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Nebraska' AND state = 'NE');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of New Hampshire', 'STATE', 'NH', '', '33'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of New Hampshire' AND state = 'NH');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of New Jersey', 'STATE', 'NJ', '', '34'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of New Jersey' AND state = 'NJ');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of New Mexico', 'STATE', 'NM', '', '35'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of New Mexico' AND state = 'NM');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Nevada', 'STATE', 'NV', '', '32'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Nevada' AND state = 'NV');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of New York', 'STATE', 'NY', '', '36'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of New York' AND state = 'NY');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Ohio', 'STATE', 'OH', '', '39'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Ohio' AND state = 'OH');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Oklahoma', 'STATE', 'OK', '', '40'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Oklahoma' AND state = 'OK');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Oregon', 'STATE', 'OR', '', '41'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Oregon' AND state = 'OR');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Pennsylvania', 'STATE', 'PA', '', '42'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Pennsylvania' AND state = 'PA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Rhode Island', 'STATE', 'RI', '', '44'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Rhode Island' AND state = 'RI');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of South Carolina', 'STATE', 'SC', '', '45'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of South Carolina' AND state = 'SC');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of South Dakota', 'STATE', 'SD', '', '46'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of South Dakota' AND state = 'SD');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Tennessee', 'STATE', 'TN', '', '47'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Tennessee' AND state = 'TN');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Utah', 'STATE', 'UT', '', '49'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Utah' AND state = 'UT');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Virginia', 'STATE', 'VA', '', '51'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Virginia' AND state = 'VA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Vermont', 'STATE', 'VT', '', '50'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Vermont' AND state = 'VT');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Washington', 'STATE', 'WA', '', '53'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Washington' AND state = 'WA');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Wisconsin', 'STATE', 'WI', '', '55'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Wisconsin' AND state = 'WI');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of West Virginia', 'STATE', 'WV', '', '54'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of West Virginia' AND state = 'WV');

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'State of Wyoming', 'STATE', 'WY', '', '56'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'State of Wyoming' AND state = 'WY');

-- ============================================================
-- Step 6: Insert NATIONAL_UPPER districts for 45 states
--         (NOT MA — MA already has fd703947-...)
-- ============================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'AK', '02', 'Alaska', 'Alaska', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'AK');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'AL', '01', 'Alabama', 'Alabama', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'AL');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'AR', '05', 'Arkansas', 'Arkansas', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'AR');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'AZ', '04', 'Arizona', 'Arizona', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'AZ');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'CO', '08', 'Colorado', 'Colorado', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'CO');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'CT', '09', 'Connecticut', 'Connecticut', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'CT');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'DE', '10', 'Delaware', 'Delaware', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'DE');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'FL', '12', 'Florida', 'Florida', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'FL');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'GA', '13', 'Georgia', 'Georgia', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'GA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'HI', '15', 'Hawaii', 'Hawaii', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'HI');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'IA', '19', 'Iowa', 'Iowa', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'IA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'ID', '16', 'Idaho', 'Idaho', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'ID');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'IL', '17', 'Illinois', 'Illinois', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'IL');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'KS', '20', 'Kansas', 'Kansas', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'KS');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'KY', '21', 'Kentucky', 'Kentucky', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'KY');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'LA', '22', 'Louisiana', 'Louisiana', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'LA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MD', '24', 'Maryland', 'Maryland', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MD');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MI', '26', 'Michigan', 'Michigan', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MI');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MN', '27', 'Minnesota', 'Minnesota', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MN');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MO', '29', 'Missouri', 'Missouri', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MO');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MS', '28', 'Mississippi', 'Mississippi', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MS');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'MT', '30', 'Montana', 'Montana', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'MT');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NC', '37', 'North Carolina', 'North Carolina', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NC');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'ND', '38', 'North Dakota', 'North Dakota', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'ND');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NE', '31', 'Nebraska', 'Nebraska', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NE');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NH', '33', 'New Hampshire', 'New Hampshire', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NH');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NJ', '34', 'New Jersey', 'New Jersey', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NJ');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NM', '35', 'New Mexico', 'New Mexico', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NM');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NV', '32', 'Nevada', 'Nevada', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NV');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'NY', '36', 'New York', 'New York', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'NY');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'OH', '39', 'Ohio', 'Ohio', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'OH');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'OK', '40', 'Oklahoma', 'Oklahoma', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'OK');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'OR', '41', 'Oregon', 'Oregon', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'OR');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'PA', '42', 'Pennsylvania', 'Pennsylvania', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'PA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'RI', '44', 'Rhode Island', 'Rhode Island', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'RI');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'SC', '45', 'South Carolina', 'South Carolina', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'SC');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'SD', '46', 'South Dakota', 'South Dakota', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'SD');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'TN', '47', 'Tennessee', 'Tennessee', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'TN');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'UT', '49', 'Utah', 'Utah', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'UT');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'VA', '51', 'Virginia', 'Virginia', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'VA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'VT', '50', 'Vermont', 'Vermont', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'VT');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'WA', '53', 'Washington', 'Washington', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'WA');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'WI', '55', 'Wisconsin', 'Wisconsin', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'WI');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'WV', '54', 'West Virginia', 'West Virginia', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'WV');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, district_id, mtfcc)
SELECT gen_random_uuid(), 'NATIONAL_UPPER', 'WY', '56', 'Wyoming', 'Wyoming', ''
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts WHERE district_type = 'NATIONAL_UPPER' AND state = 'WY');

-- ============================================================
-- Step 7: Backfill government_id on all 50 NATIONAL_UPPER districts
-- ============================================================
UPDATE essentials.districts d
SET government_id = (
  SELECT g.id
  FROM essentials.governments g
  WHERE g.state = d.state AND g.type = 'STATE'
  ORDER BY g.id
  LIMIT 1
)
WHERE d.district_type = 'NATIONAL_UPPER'
  AND d.government_id IS NULL;

COMMIT;
