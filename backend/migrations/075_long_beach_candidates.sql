-- =============================================================================
-- Migration 075: Add website_url to race_candidates + seed Long Beach June 2026
--
-- Two parts:
--   1. Add website_url column to essentials.race_candidates
--   2. Update 4 already-approved citywide candidates with full data
--   3. Insert all council (D1/D3/D5/D7/D9) and mayor candidates
--
-- Source: Long Beach City Clerk Official Candidate List, June 2, 2026 Primary
-- URL: https://www.longbeach.gov/globalassets/city-clerk/media-library/documents/elections/2026/pne-060226-official-candidates-for-website
-- =============================================================================

-- Part 1: Add website_url column
ALTER TABLE essentials.race_candidates
  ADD COLUMN IF NOT EXISTS website_url TEXT;

-- Part 2: Update already-approved citywide candidates
UPDATE essentials.race_candidates SET
  occupational_designation = 'City Attorney',
  is_incumbent = true,
  website_url = 'https://www.dawnforlb.com'
WHERE full_name = 'Dawn McIntosh'
  AND race_id = (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Attorney');

UPDATE essentials.race_candidates SET
  occupational_designation = 'City Auditor, City of Long Beach',
  is_incumbent = true
WHERE full_name = 'Laura Doud'
  AND race_id = (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Auditor');

UPDATE essentials.race_candidates SET
  occupational_designation = 'Certified Public Accountant',
  is_incumbent = false,
  website_url = 'https://www.gonzalesforcityauditor.com'
WHERE full_name = 'Ginny Gonzales'
  AND race_id = (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Auditor');

UPDATE essentials.race_candidates SET
  occupational_designation = 'City Prosecutor, City of Long Beach',
  is_incumbent = true,
  website_url = 'https://www.doughaubert.com'
WHERE full_name = 'Doug Haubert'
  AND race_id = (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Prosecutor');

-- Part 3: Insert council + mayor candidates
-- Uses WHERE NOT EXISTS to guard against re-runs
DO $$
DECLARE
  r_d1  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Council District 1');
  r_d3  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Council District 3');
  r_d5  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Council District 5');
  r_d7  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Council District 7');
  r_d9  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach City Council District 9');
  r_ma  UUID := (SELECT id FROM essentials.races WHERE position_name = 'Long Beach Mayor');
BEGIN

  -- District 1
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Deb Kahookele', 'Deb', 'Kahookele', 'Realtor / Business Owner', false, 'https://www.debforlongbeach.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Deb Kahookele');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Lori Logan', 'Lori', 'Logan', 'Retired Laboratory Technician', false, 'https://www.loriloganforcitycouncil.my.canva.site', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Lori Logan');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Mary Zendejas', 'Mary', 'Zendejas', 'Councilmember, City of Long Beach', true, 'https://www.maryzendejas.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Mary Zendejas');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Brock Goleman', 'Brock', 'Goleman', 'Trucking', false, 'https://www.golemanforlbcitycouncil.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Brock Goleman');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Tamika Wagner-Osio', 'Tamika', 'Wagner-Osio', 'Executive Director / Entrepreneur', false, 'https://www.tamikawagnerosio.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Tamika Wagner-Osio');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d1, 'Anthony Bryson', 'Anthony', 'Bryson', 'Restaurant Manager', false, 'https://www.brysonforlongbeach.org', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d1 AND full_name = 'Anthony Bryson');

  -- District 3
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  SELECT r_d3, 'Ronald Sampson', 'Ronald', 'Sampson', NULL, false, 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d3 AND full_name = 'Ronald Sampson');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d3, 'Kristina Duggan', 'Kristina', 'Duggan', 'Long Beach Council Member, District 3', true, 'https://www.kristinaduggan.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d3 AND full_name = 'Kristina Duggan');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d3, 'Rebecca Hinderer', 'Rebecca', 'Hinderer', 'Small Business Owner', false, 'https://www.becksforlb.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d3 AND full_name = 'Rebecca Hinderer');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  SELECT r_d3, 'Brian Cochrane', 'Brian', 'Cochrane', NULL, false, 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d3 AND full_name = 'Brian Cochrane');

  -- District 5
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d5, 'Megan Kerr', 'Megan', 'Kerr', 'Long Beach City Councilmember', true, 'https://www.megankerr.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d5 AND full_name = 'Megan Kerr');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d5, 'Tara Riggi', 'Tara', 'Riggi', 'Small Business Owner', false, 'https://www.taraforcouncil.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d5 AND full_name = 'Tara Riggi');

  -- District 7
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d7, 'Vivian Malauulu', 'Vivian', 'Malauulu', 'Long Beach Community College District, Trustee Area 2', false, 'https://www.vivianforlongbeach.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d7 AND full_name = 'Vivian Malauulu');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  SELECT r_d7, 'Dameon Gordon', 'Dameon', 'Gordon', 'Homeless Case Manager', false, 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d7 AND full_name = 'Dameon Gordon');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  SELECT r_d7, 'Jamies Shuford', 'Jamies', 'Shuford', 'Nonprofit CEO', false, 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d7 AND full_name = 'Jamies Shuford');

  -- District 9
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d9, 'Joni Ricks-Oddie', 'Joni', 'Ricks-Oddie', 'Councilmember, City of Long Beach', true, 'https://www.votedrjoni.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d9 AND full_name = 'Joni Ricks-Oddie');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_d9, 'Sequoia Neff', 'Sequoia', 'Neff', 'Small Business Owner', false, 'https://www.sequoianeff.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_d9 AND full_name = 'Sequoia Neff');

  -- Mayor
  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, source)
  SELECT r_ma, 'Joshua Rodriguez', 'Joshua', 'Rodriguez', 'Police Officer / Father', false, 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Joshua Rodriguez');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'Rex Richardson', 'Rex', 'Richardson', 'Mayor', true, 'https://www.joinrexrichardson.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Rex Richardson');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'Lee Goldin', 'Lee', 'Goldin', 'Senior Product Manager', false, 'https://www.goldinformayor.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Lee Goldin');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'Oscar Cancio', 'Oscar', 'Cancio', 'School Relations Manager', false, 'https://www.cancio4lbmayor.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Oscar Cancio');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'Terri Rivers', 'Terri', 'Rivers', 'Chief Nonprofit Executive', false, 'https://www.terririvers.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Terri Rivers');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'Chris Sweeney', 'Chris', 'Sweeney', 'Business Owner', false, 'https://www.sweeneyforlb.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'Chris Sweeney');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, occupational_designation, is_incumbent, website_url, source)
  SELECT r_ma, 'April Ronay', 'April', 'Ronay', 'Write-In Candidate', false, 'https://www.aprilronay4mayor.com', 'clerk_official'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = r_ma AND full_name = 'April Ronay');

END $$;
