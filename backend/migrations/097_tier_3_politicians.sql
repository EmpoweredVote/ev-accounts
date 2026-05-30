-- Migration 097: Seed Tier 3 incumbent politicians (8 Collin County cities)
-- Depends on migration 090 (Tier 3-4 cities: governments + chambers + offices)
-- 45 incumbents seeded across 8 cities.
-- 10 NOT-YET-SEEDED comment blocks for May 3, 2026 election seats (pending certification).
--
-- Cities (alphabetical): Anna, Fairview (Town), Farmersville, Lavon, Lucas, Melissa, Princeton, Van Alstyne
--
-- Special handling:
--   - Fairview is legally a Town. Office titles use 'Council Member Seat 1-6' (NOT 'Place').
--     SQL lookups: o.title = 'Council Member Seat N'.
--   - Princeton has 8 seats: Mayor + Place 1-7. Place 4 is currently VACANT (special election May 3).
--   - Van Alstyne uses term_date_precision='day' (research provides exact day-of-month dates).
--   - All other cities use term_date_precision='month'.
--   - Lavon and Princeton have urls=NULL for all seed-now rows (no individual bio pages published).
--   - Farmersville: election was certified cancelled (all 6 seats uncontested → declared elected).
--     Place 1 (Coleman Strickland) and Place 3 (Kristi Mondy) use valid_from='2026-05-01' (new term).
--     Mayor + Places 2,4,5 use valid_from='2024-05-01' (mid-term, not up for election).
--   - Melissa role-based emails: mayor@/place1@/place2@/etc. (place5 = cackerman@ personal pattern).
--
-- POST-ELECTION FLAGS (10 stubs; fill in after May 3, 2026 certification):
--   Anna Place 3        — Stan Carver II not running (Olivarez vs. Walden)
--   Anna Place 5        — Elden Baker contested
--   Fairview Seat 2     — Gregg Custer not running; Joe Boggs declared elected (awaits swearing-in)
--   Fairview Seat 4     — Larry Little not running (Doi vs. Stanley)
--   Fairview Seat 6     — Lakia Works contested
--   Lucas Place 1       — Tim Johnson not running (open race)
--   Lucas Place 2       — Brian Stubblefield not running (open race)
--   Princeton Place 4   — VACANT (4-candidate special election)
--   Van Alstyne Mayor   — Jim Atchison contested (Atchison vs. Soucie)
--   Van Alstyne Place 6 — Angelica Pena contested

BEGIN;

-- =============================================================================
-- ANNA (geo_id 4803300)
-- =============================================================================

-- Anna Mayor — Pete Cain
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Anna Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Pete', 'Cain', 'Pete', 'Pete Cain',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.annatexas.gov/1354/Pete-Cain'],
    'annatexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Pete Cain (Anna Mayor) — %', v_politician_id;
END $$;

-- Anna Council Member Place 1 — Kevin Toten
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Anna Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Kevin', 'Toten', 'Kevin', 'Kevin Toten',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.annatexas.gov/1072/Kevin-Toten'],
    'annatexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Kevin Toten (Anna Place 1) — %', v_politician_id;
END $$;

-- Anna Council Member Place 2 — Nathan Bryan
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Anna Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Nathan', 'Bryan', 'Nathan', 'Nathan Bryan',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.annatexas.gov/1612/Nathan-Bryan'],
    'annatexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Nathan Bryan (Anna Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Anna Council Member Place 3 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Stan Carver II is not seeking re-election; the seat is open.
-- Candidates: Mike Olivarez vs. Jessica Walden
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://www.collincountytx.gov/elections/Pages/election-results.aspx
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Anna Council Member Place 4 — Kelly Patterson-Herndon
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Anna Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Kelly', 'Patterson-Herndon', 'Kelly', 'Kelly Patterson-Herndon',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.annatexas.gov/1562/Kelly-Patterson-Herndon'],
    'annatexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Kelly Patterson-Herndon (Anna Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Anna Council Member Place 5 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Elden Baker is the current incumbent but the seat is contested.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://www.collincountytx.gov/elections/Pages/election-results.aspx
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Anna Council Member Place 6 — Manny Singh
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4803300' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Anna Council Member Place 6 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Manny', 'Singh', 'Manny', 'Manny Singh',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.annatexas.gov/1607/Manny-Singh'],
    'annatexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Manny Singh (Anna Place 6) — %', v_politician_id;
END $$;

-- =============================================================================
-- FAIRVIEW (Town of Fairview) (geo_id 4825224)
-- NOTE: SQL lookup uses 'Council Member Seat N' — NOT 'Place'
-- =============================================================================

-- Fairview Mayor — John Hubbard
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Fairview Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'John', 'Hubbard', 'John', 'John Hubbard',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['mayor@fairviewtexas.org'],
    ARRAY['https://fairviewtexas.org/government/town-council.html'],
    'fairviewtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: John Hubbard (Fairview Mayor) — %', v_politician_id;
END $$;

-- Fairview Council Member Seat 1 — Rich Connelly
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Fairview Council Member Seat 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Rich', 'Connelly', 'Rich', 'Rich Connelly',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['RConnelly@FairviewTexas.org'],
    ARRAY['https://fairviewtexas.org/government/town-council.html'],
    'fairviewtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Rich Connelly (Fairview Seat 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Fairview Council Member Seat 2 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Gregg Custer is not seeking re-election; Joe Boggs was declared elected (sole candidate)
--   but has not yet been sworn in as of 2026-05-01.
-- ACTION: After swearing-in/certification (est. May 5-9, 2026), verify at:
--   https://fairviewtexas.org/
--   then add a separate DO block to INSERT Joe Boggs.
-- ---------------------------------------------------------------------------

-- Fairview Council Member Seat 3 — Jill Hawkins
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Fairview Council Member Seat 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jill', 'Hawkins', 'Jill', 'Jill Hawkins',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    ARRAY['jhawkins@fairviewtexas.org'],
    ARRAY['https://fairviewtexas.org/government/town-council.html'],
    'fairviewtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jill Hawkins (Fairview Seat 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Fairview Council Member Seat 4 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Larry Little is not seeking re-election; the seat is open.
-- Candidates: Doi vs. Stanley
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://fairviewtexas.org/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Fairview Council Member Seat 5 — Pat Sheehan
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825224' AND o.title = 'Council Member Seat 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Fairview Council Member Seat 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Pat', 'Sheehan', 'Pat', 'Pat Sheehan',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['psheehan@fairviewtexas.org'],
    ARRAY['https://fairviewtexas.org/government/town-council.html'],
    'fairviewtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Pat Sheehan (Fairview Seat 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Fairview Council Member Seat 6 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Lakia Works is the incumbent but the seat is contested.
-- Candidates: Lakia Works vs. Riyad
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://fairviewtexas.org/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- =============================================================================
-- FARMERSVILLE (geo_id 4825488)
-- Election CANCELLED — all 6 seats uncontested/declared elected.
-- Strickland (Place 1) and Mondy (Place 3): valid_from='2026-05-01' (new term).
-- Others: valid_from='2024-05-01' (mid-term, not up for election this cycle).
-- All emails NULL (form-based obfuscation). Shared bio URL for all.
-- =============================================================================

-- Farmersville Mayor — Craig Overstreet
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Craig', 'Overstreet', 'Craig', 'Craig Overstreet',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Craig Overstreet (Farmersville Mayor) — %', v_politician_id;
END $$;

-- Farmersville Council Member Place 1 — Coleman Strickland (declared re-elected, new term)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Coleman', 'Strickland', 'Coleman', 'Coleman Strickland',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-05-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Coleman Strickland (Farmersville Place 1) — %', v_politician_id;
END $$;

-- Farmersville Council Member Place 2 — Russell Chandler
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Russell', 'Chandler', 'Russell', 'Russell Chandler',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Russell Chandler (Farmersville Place 2) — %', v_politician_id;
END $$;

-- Farmersville Council Member Place 3 — Kristi Mondy (declared re-elected, new term)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Kristi', 'Mondy', 'Kristi', 'Kristi Mondy',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-05-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Kristi Mondy (Farmersville Place 3) — %', v_politician_id;
END $$;

-- Farmersville Council Member Place 4 — Mike Henry
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Mike', 'Henry', 'Mike', 'Mike Henry',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Mike Henry (Farmersville Place 4) — %', v_politician_id;
END $$;

-- Farmersville Council Member Place 5 — Tonya Fox
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Farmersville Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Tonya', 'Fox', 'Tonya', 'Tonya Fox',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.farmersvilletx.com/city-council'],
    'farmersvilletx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Tonya Fox (Farmersville Place 5) — %', v_politician_id;
END $$;

-- =============================================================================
-- LAVON (geo_id 4841800)
-- No May 2026 election — seed all 6.
-- All urls=NULL AND email_addresses=NULL (no bio pages or contact emails published).
-- =============================================================================

-- Lavon Mayor — Vicki Sanson
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Vicki', 'Sanson', 'Vicki', 'Vicki Sanson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Vicki Sanson (Lavon Mayor) — %', v_politician_id;
END $$;

-- Lavon Council Member Place 1 — Mike Shepard
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Mike', 'Shepard', 'Mike', 'Mike Shepard',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Mike Shepard (Lavon Place 1) — %', v_politician_id;
END $$;

-- Lavon Council Member Place 2 — Mike Cook
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Mike', 'Cook', 'Mike', 'Mike Cook',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Mike Cook (Lavon Place 2) — %', v_politician_id;
END $$;

-- Lavon Council Member Place 3 — Travis Jacob
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Travis', 'Jacob', 'Travis', 'Travis Jacob',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Travis Jacob (Lavon Place 3) — %', v_politician_id;
END $$;

-- Lavon Council Member Place 4 — Rachel Dumas
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Rachel', 'Dumas', 'Rachel', 'Rachel Dumas',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Rachel Dumas (Lavon Place 4) — %', v_politician_id;
END $$;

-- Lavon Council Member Place 5 — Lindsey Hedge
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4841800' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lavon Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Lindsey', 'Hedge', 'Lindsey', 'Lindsey Hedge',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'lavontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Lindsey Hedge (Lavon Place 5) — %', v_politician_id;
END $$;

-- =============================================================================
-- LUCAS (geo_id 4845012)
-- Bio URLs = NULL (no individual bio pages).
-- Emails follow {first initial}{lastname}@lucastexas.us pattern.
-- Place 1 and Place 2 are stubs (incumbents not running).
-- =============================================================================

-- Lucas Mayor — Dusty Kuykendall
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lucas Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Dusty', 'Kuykendall', 'Dusty', 'Dusty Kuykendall',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['dkuykendall@lucastexas.us'],
    NULL,
    'lucastexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Dusty Kuykendall (Lucas Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Lucas Council Member Place 1 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Tim Johnson is not seeking re-election; the seat is open (no incumbent).
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://lucastexas.us/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Lucas Council Member Place 2 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Brian Stubblefield is not seeking re-election; the seat is open (no incumbent).
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://lucastexas.us/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Lucas Council Member Place 3 — Chris Bierman
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lucas Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Chris', 'Bierman', 'Chris', 'Chris Bierman',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['cbierman@lucastexas.us'],
    NULL,
    'lucastexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Chris Bierman (Lucas Place 3) — %', v_politician_id;
END $$;

-- Lucas Council Member Place 4 — Phil Lawrence
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lucas Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Phil', 'Lawrence', 'Phil', 'Phil Lawrence',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['plawrence@lucastexas.us'],
    NULL,
    'lucastexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Phil Lawrence (Lucas Place 4) — %', v_politician_id;
END $$;

-- Lucas Council Member Place 5 — Debbie Fisher
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lucas Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Debbie', 'Fisher', 'Debbie', 'Debbie Fisher',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['dfisher@lucastexas.us'],
    NULL,
    'lucastexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Debbie Fisher (Lucas Place 5) — %', v_politician_id;
END $$;

-- Lucas Council Member Place 6 — Neil Peterson
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845012' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lucas Council Member Place 6 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Neil', 'Peterson', 'Neil', 'Neil Peterson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['npeterson@lucastexas.us'],
    NULL,
    'lucastexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Neil Peterson (Lucas Place 6) — %', v_politician_id;
END $$;

-- =============================================================================
-- MELISSA (geo_id 4847496)
-- No May 2026 election — seed all 7.
-- Role-based emails confirmed on official directory.
-- Place 5 uses personal email cackerman@ (not place5@) per official directory.
-- =============================================================================

-- Melissa Mayor — Jay Northcut
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jay', 'Northcut', 'Jay', 'Jay Northcut',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['mayor@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=51'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jay Northcut (Melissa Mayor) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 1 — Preston Taylor
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Preston', 'Taylor', 'Preston', 'Preston Taylor',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['place1@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=103'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Preston Taylor (Melissa Place 1) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 2 — Rendell Hendrickson
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Rendell', 'Hendrickson', 'Rendell', 'Rendell Hendrickson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['place2@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=104'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Rendell Hendrickson (Melissa Place 2) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 3 — Dana Conklin
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Dana', 'Conklin', 'Dana', 'Dana Conklin',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['place3@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=56'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Dana Conklin (Melissa Place 3) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 4 — Joseph Armstrong
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Joseph', 'Armstrong', 'Joseph', 'Joseph Armstrong',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['place4@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=53'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Joseph Armstrong (Melissa Place 4) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 5 — Craig Ackerman
-- NOTE: uses personal email cackerman@ (not place5@) — as published on official directory
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Craig', 'Ackerman', 'Craig', 'Craig Ackerman',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['cackerman@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=50'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Craig Ackerman (Melissa Place 5) — %', v_politician_id;
END $$;

-- Melissa Council Member Place 6 — Sean Lehr
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4847496' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Melissa Council Member Place 6 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Sean', 'Lehr', 'Sean', 'Sean Lehr',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['place6@cityofmelissa.com'],
    ARRAY['https://www.cityofmelissa.com/Directory.aspx?EID=54'],
    'cityofmelissa.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Sean Lehr (Melissa Place 6) — %', v_politician_id;
END $$;

-- =============================================================================
-- PRINCETON (geo_id 4863432)
-- 8 seats: Mayor + Place 1-7.
-- Place 4 is VACANT (special election May 3) — stub only.
-- All urls=NULL AND email_addresses=NULL (no individual bio pages).
-- =============================================================================

-- Princeton Mayor — Eugene Escobar Jr.
-- NOTE: full_name='Eugene Escobar Jr.', first_name='Eugene', last_name='Escobar'
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Eugene', 'Escobar', 'Eugene', 'Eugene Escobar Jr.',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Eugene Escobar Jr. (Princeton Mayor) — %', v_politician_id;
END $$;

-- Princeton Council Member Place 1 — Terrance Johnson
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Terrance', 'Johnson', 'Terrance', 'Terrance Johnson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Terrance Johnson (Princeton Place 1) — %', v_politician_id;
END $$;

-- Princeton Council Member Place 2 — Cristina Todd
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Cristina', 'Todd', 'Cristina', 'Cristina Todd',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Cristina Todd (Princeton Place 2) — %', v_politician_id;
END $$;

-- Princeton Council Member Place 3 — Bryan Washington
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Bryan', 'Washington', 'Bryan', 'Bryan Washington',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Bryan Washington (Princeton Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Princeton Council Member Place 4 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- This seat is currently VACANT — 4-candidate special election on May 3, 2026.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://princetontx.gov/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Princeton Council Member Place 5 — Steven Deffibaugh
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Steven', 'Deffibaugh', 'Steven', 'Steven Deffibaugh',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Steven Deffibaugh (Princeton Place 5) — %', v_politician_id;
END $$;

-- Princeton Council Member Place 6 — Ben Long
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 6 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ben', 'Long', 'Ben', 'Ben Long',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ben Long (Princeton Place 6) — %', v_politician_id;
END $$;

-- Princeton Council Member Place 7 — Carolyn David-Graves
-- NOTE: hyphenated last name 'David-Graves' preserved
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863432' AND o.title = 'Council Member Place 7';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Princeton Council Member Place 7 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Carolyn', 'David-Graves', 'Carolyn', 'Carolyn David-Graves',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'princetontx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Carolyn David-Graves (Princeton Place 7) — %', v_politician_id;
END $$;

-- =============================================================================
-- VAN ALSTYNE (geo_id 4875960)
-- Mayor and Place 6 are stubs (contested May 3 election).
-- All 5 seed-now rows use term_date_precision='day' (exact dates from CivicWeb).
-- All email_addresses=NULL AND urls=NULL for seed-now rows.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Van Alstyne Mayor — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Jim Atchison is the incumbent but the seat is contested.
-- Candidates: Jim Atchison vs. Soucie
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://www.cityofvanalstyne.us/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Van Alstyne Council Member Place 1 — Ryan Neal
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4875960' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Van Alstyne Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ryan', 'Neal', 'Ryan', 'Ryan Neal',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-05', '2027-05-02', 'day',
    NULL,
    NULL,
    'cityofvanalstyne.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ryan Neal (Van Alstyne Place 1) — %', v_politician_id;
END $$;

-- Van Alstyne Council Member Place 2 — Marla Butler
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4875960' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Van Alstyne Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Marla', 'Butler', 'Marla', 'Marla Butler',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-05', '2027-05-01', 'day',
    NULL,
    NULL,
    'cityofvanalstyne.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Marla Butler (Van Alstyne Place 2) — %', v_politician_id;
END $$;

-- Van Alstyne Council Member Place 3 — Dusty Williams
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4875960' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Van Alstyne Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Dusty', 'Williams', 'Dusty', 'Dusty Williams',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-05', '2027-05-01', 'day',
    NULL,
    NULL,
    'cityofvanalstyne.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Dusty Williams (Van Alstyne Place 3) — %', v_politician_id;
END $$;

-- Van Alstyne Council Member Place 4 — Lee Thomas
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4875960' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Van Alstyne Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Lee', 'Thomas', 'Lee', 'Lee Thomas',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-04', '2028-05-06', 'day',
    NULL,
    NULL,
    'cityofvanalstyne.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Lee Thomas (Van Alstyne Place 4) — %', v_politician_id;
END $$;

-- Van Alstyne Council Member Place 5 — Katrina Arsenault
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4875960' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Van Alstyne Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Katrina', 'Arsenault', 'Katrina', 'Katrina Arsenault',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-04', '2028-05-06', 'day',
    NULL,
    NULL,
    'cityofvanalstyne.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Katrina Arsenault (Van Alstyne Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Van Alstyne Council Member Place 6 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Angelica Pena is the incumbent but the seat is contested.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://www.cityofvanalstyne.us/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

COMMIT;
