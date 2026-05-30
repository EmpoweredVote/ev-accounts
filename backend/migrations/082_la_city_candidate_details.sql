-- =============================================================================
-- Migration 082: Fill in ballot designations + website_urls for LA City
-- June 2, 2026 primary candidates.
--
-- All races were already seeded in a prior migration. This pass adds the
-- official certified ballot designations (per LA City Clerk certified list)
-- and confirmed campaign websites for all candidates where available.
--
-- D3 extra candidates (Jon Rawlings, Lehi White) and D15 extra candidate
-- (Phillip L. Crouch Jr.) have no designation/website data confirmed —
-- those rows are left as-is.
--
-- Source: cityclerk.lacity.org/election/2026_Primary_Certified_List_of_Candidates.pdf
--         LAist voter guides per district
-- =============================================================================

BEGIN;

-- Helper: update a single candidate by race name + full name
-- Pattern: UPDATE ... FROM races WHERE election_id + position_name + full_name

-- ---------------------------------------------------------------------------
-- Mayor
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET website_url = 'https://www.karenbass.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles Mayor' AND rc.full_name = 'Karen Ruth Bass';

UPDATE essentials.race_candidates rc
SET website_url = 'https://www.nithyaforthecity.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles Mayor' AND rc.full_name = 'Nithya Raman';

UPDATE essentials.race_candidates rc
SET website_url = 'https://www.mayorpratt.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles Mayor' AND rc.full_name = 'Spencer Pratt';

-- ---------------------------------------------------------------------------
-- City Attorney
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Los Angeles City Attorney',
    website_url = 'https://www.reelecthydee.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Attorney' AND rc.full_name = 'Hydee Feldstein Soto';

UPDATE essentials.race_candidates rc
SET website_url = 'https://www.mckinney4la.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Attorney' AND rc.full_name = 'John McKinney';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Deputy Attorney General',
    website_url = 'https://www.marissaroy.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Attorney' AND rc.full_name = 'Marissa Roy';

UPDATE essentials.race_candidates rc
SET website_url = 'https://www.aida4la.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Attorney' AND rc.full_name = 'Aida Ashouri';

-- ---------------------------------------------------------------------------
-- City Controller
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Controller/Public Accountant',
    website_url = 'https://www.mejiaforcontroller.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Controller' AND rc.full_name = 'Kenneth Mejia';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Financial Accounting Executive',
    website_url = 'https://www.zachforcontroller.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'LA City Controller' AND rc.full_name = 'Zach Sokoloff';

-- ---------------------------------------------------------------------------
-- District 1
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Councilmember',
    website_url = 'https://www.eunissesforthepeople.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 1' AND rc.full_name = 'Eunisses Hernandez';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Small Business Owner',
    website_url = 'https://www.sylviarobledo.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 1' AND rc.full_name = 'Sylvia Robledo';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Housing Advocate',
    website_url = 'https://www.raulclaros.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 1' AND rc.full_name = 'Raul Claros';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Youth Empowerment Director',
    website_url = 'https://www.louforcd1.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 1' AND rc.full_name = 'Maria Lou Calanche';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Entrepreneur/Community Advocate',
    website_url = 'https://www.gogandeforcd1.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 1' AND rc.full_name = 'Nelson Grande';

-- ---------------------------------------------------------------------------
-- District 3 (open seat — Blumenfield term-limited)
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Tech Entrepreneur/Dad',
    website_url = 'https://www.crcelona.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 3' AND rc.full_name = 'C.R. Celona';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Valley Businessman/Parent',
    website_url = 'https://www.timgaspar.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 3' AND rc.full_name = 'Timothy Gaspar';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Valley Community Advocate',
    website_url = 'https://www.barriforthevalley.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 3' AND rc.full_name = 'Barri Worth Girvan';

-- ---------------------------------------------------------------------------
-- District 5
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'City Councilwoman/Mom',
    website_url = 'https://www.katyforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 5' AND rc.full_name = 'Katy Yaroslavsky';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Tenants'' Rights Attorney',
    website_url = 'https://www.henrymantelforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 5' AND rc.full_name = 'Henry Mantel';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Small Business Accountant',
    website_url = 'https://www.moforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 5' AND rc.full_name = 'Morgan Oyler';

-- ---------------------------------------------------------------------------
-- District 7 (effectively uncontested)
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Los Angeles City Councilwoman',
    website_url = 'https://www.monicarodriguez.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 7' AND rc.full_name = 'Monica Rodriguez';

-- ---------------------------------------------------------------------------
-- District 9 (open seat — Curren Price term-limited)
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Director, Community Organization',
    website_url = 'https://www.estuardo4la.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Estuardo Mazariegos';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Education Nonprofit Director',
    website_url = 'https://www.elmerroldan.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Elmer Roldan';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Educator/Therapist'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Jorge Hernandez Rosas';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Social Entrepreneur'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Jorge Nuño';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Professor/Therapist',
    website_url = 'https://www.marthasanchezforcitycouncil2026.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Martha Sánchez';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Community Outreach Director',
    website_url = 'https://www.ugarteforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 9' AND rc.full_name = 'Jose Ugarte';

-- ---------------------------------------------------------------------------
-- District 11
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Councilwoman',
    website_url = 'https://www.tracipark.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 11' AND rc.full_name = 'Traci Park';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Civil Rights Attorney',
    website_url = 'https://www.faizahforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 11' AND rc.full_name = 'Faizah Malik';

-- ---------------------------------------------------------------------------
-- District 13
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'Councilmember',
    website_url = 'https://www.hugo2026.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 13' AND rc.full_name = 'Hugo Soto-Martinez';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Neighborhood Councilmember',
    website_url = 'https://www.colterforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 13' AND rc.full_name = 'Colter Carlisle';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Housing Advocate/Mom',
    website_url = 'https://www.dylanfordistrict13.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 13' AND rc.full_name = 'Dylan Kendall';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Urban Community Planner',
    website_url = 'https://www.richsarian.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 13' AND rc.full_name = 'Rich Sarian';

-- ---------------------------------------------------------------------------
-- District 15
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
SET occupational_designation = 'City Councilmember',
    website_url = 'https://www.timmcosker.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 15' AND rc.full_name = 'Tim McOsker';

UPDATE essentials.race_candidates rc
SET occupational_designation = 'Community Organizer',
    website_url = 'https://www.riversdeliversforla.com'
FROM essentials.races r
WHERE rc.race_id = r.id AND r.election_id = '1ebca37f-cf96-47f4-bc2b-47ef266721fe'
  AND r.position_name = 'Los Angeles City Council District 15' AND rc.full_name = 'Jordan Rivers';

COMMIT;
