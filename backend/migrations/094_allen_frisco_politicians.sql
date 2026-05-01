-- =============================================================================
-- Migration 094: Seed Allen + Frisco incumbent politicians (Tier 2 batch 1)
-- Depends on migration 089 (Tier 2 cities: Allen + Frisco offices)
-- 14 incumbents: Allen (Mayor + Place 1-6) + Frisco (Mayor + Place 1-6)
--
-- POST-ELECTION FLAGS (handled in follow-up update workflow, NOT this migration):
--   Allen Mayor (Baine Brooks) — term-limited, check cityofallen.org after May 3, 2026
--   Allen Place 2 (Tommy Baril) — re-elected unopposed May 3, update term to 2026-2029
--   Frisco Mayor (Jeff Cheney) — contested May 3
--   Frisco Place 5 (Laura Rummel) — contested May 3
--   Frisco Place 6 (Brian Livingston) — contested May 3
-- =============================================================================

BEGIN;

-- ===========================================================================
-- ALLEN (geo_id: 4801924)
-- data_source: cityofallen.org
-- email_addresses confirmed via mailto: links on bio pages
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Allen Mayor — Baine Brooks (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: term-limited — check cityofallen.org after May 3 for new mayor
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Baine', 'Brooks', 'Baine', 'Baine Brooks',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-05-01', 'month',
    ARRAY['bbrooks@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R16.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Baine Brooks (Allen Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 1 — Michael Schaeffer (term: 2024-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Michael', 'Schaeffer', 'Michael', 'Michael Schaeffer',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    ARRAY['michael.schaeffer@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R21.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Michael Schaeffer (Allen Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 2 — Tommy Baril (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: re-elected unopposed May 3 — update term to 2026-2029 after certification
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Tommy', 'Baril', 'Tommy', 'Tommy Baril',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-05-01', 'month',
    ARRAY['tommy.baril@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R78.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Tommy Baril (Allen Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 3 — Ken Cook (term: 2024-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Ken', 'Cook', 'Ken', 'Ken Cook',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    ARRAY['ken.cook@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R82.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ken Cook (Allen Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 4 — Amy Gnadt (term: 2025-05-01 → 2028-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Amy', 'Gnadt', 'Amy', 'Amy Gnadt',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    ARRAY['amy.gnadt@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R83.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Amy Gnadt (Allen Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 5 — Carl Clemencich (term: 2024-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Carl', 'Clemencich', 'Carl', 'Carl Clemencich',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    ARRAY['carl.clemencich@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R92.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Carl Clemencich (Allen Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Allen Council Member Place 6 — Ben Trahan (term: 2025-05-01 → 2028-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4801924' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Allen Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Ben', 'Trahan', 'Ben', 'Ben Trahan',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    ARRAY['ben.trahan@allentx.gov'],
    ARRAY['https://www.cityofallen.org/business_detail_T4_R86.php'],
    'cityofallen.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ben Trahan (Allen Council Member Place 6) — %', v_politician_id;
END $$;

-- ===========================================================================
-- FRISCO (geo_id: 4827684)
-- data_source: friscotexas.gov
-- email_addresses = NULL for all rows (CloudFlare-protected; bio URL satisfies contact requirement)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Frisco Mayor — Jeff Cheney (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: contested May 3 — check friscotexas.gov for winner
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Jeff', 'Cheney', 'Jeff', 'Jeff Cheney',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=477'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jeff Cheney (Frisco Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 1 — Ann Anderson (term: 2026-02-01 → 2029-05-01)
-- Won special election February 2026; is_appointed=false (elected, not appointed)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Ann', 'Anderson', 'Ann', 'Ann Anderson',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2026-02-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=925'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ann Anderson (Frisco Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 2 — Burt Thakur (term: 2024-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Burt', 'Thakur', 'Burt', 'Burt Thakur',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=888'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Burt Thakur (Frisco Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 3 — Angelia Pelham (term: 2025-05-01 → 2028-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Angelia', 'Pelham', 'Angelia', 'Angelia Pelham',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=683'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Angelia Pelham (Frisco Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 4 — Jared Elad (term: 2025-05-01 → 2028-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Jared', 'Elad', 'Jared', 'Jared Elad',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=190'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jared Elad (Frisco Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 5 — Laura Rummel (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: contested May 3 — check friscotexas.gov for winner
-- Live page confirmed as "Deputy Mayor Pro Tem, Place 5"
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Laura', 'Rummel', 'Laura', 'Laura Rummel',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=189'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Laura Rummel (Frisco Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Frisco Council Member Place 6 — Brian Livingston (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: contested May 3 — check friscotexas.gov for winner
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4827684' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Frisco Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Brian', 'Livingston', 'Brian', 'Brian Livingston',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.friscotexas.gov/directory.aspx?EID=484'],
    'friscotexas.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Brian Livingston (Frisco Council Member Place 6) — %', v_politician_id;
END $$;

COMMIT;
