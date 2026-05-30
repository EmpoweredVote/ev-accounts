-- =============================================================================
-- Migration 092: Seed McKinney incumbent politicians (post-June 2025 runoff)
--
-- Depends on migration 088 (McKinney government + chamber + 7 offices)
-- 7 incumbents: Mayor + At-Large Place 1, At-Large Place 2 + District 1-4
-- McKinney geo_id: '4845744'
--
-- NOTE: email_addresses = NULL for all McKinney rows.
-- The McKinney city website uses CloudFlare email protection on the Council
-- Members page (https://www.mckinneytexas.org/1167/Council-Members). Official
-- email addresses could not be confirmed from public sources. NULL is correct.
--
-- NOTE: At-Large office titles in migration 088 use "Council Member At-Large Place N"
-- (not "Council Member At-Large N"). The WHERE clauses below use the exact DB titles.
--
-- NOTE: Geré Feltus — the é accent is the official name form per the McKinney
-- city website. This file is UTF-8. Do not normalize the accent.
--
-- All 7 incumbents:
--   Bill Cox          — Mayor (won June 2025 runoff)
--   Ernest Lynch      — Council Member At-Large Place 1 (won June 2025 runoff)
--   Michael Jones     — Council Member At-Large Place 2 (elected May 2023)
--   Justin Beller     — Council Member District 1 (ran unopposed May 2025)
--   Patrick Cloutier  — Council Member District 2 (elected May 2023)
--   Geré Feltus       — Council Member District 3 (won May 2025 with 54%)
--   Rick Franklin     — Council Member District 4 (elected May 2023)
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Bill Cox — Mayor (June 2025 runoff)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Mayor office not found — migration 088 must run first';
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
    'Bill', 'Cox', 'Bill', 'Bill Cox',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-06-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#Mayor'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Bill Cox (McKinney Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Ernest Lynch — Council Member At-Large Place 1 (June 2025 runoff)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member At-Large Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member At-Large Place 1 office not found — migration 088 must run first';
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
    'Ernest', 'Lynch', 'Ernest', 'Ernest Lynch',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-06-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#AtLarge1'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ernest Lynch (McKinney Council Member At-Large Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Michael Jones — Council Member At-Large Place 2 (elected May 2023)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member At-Large Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member At-Large Place 2 office not found — migration 088 must run first';
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
    'Michael', 'Jones', 'Michael', 'Michael Jones',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#AtLarge2'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Michael Jones (McKinney Council Member At-Large Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Justin Beller — Council Member District 1 (ran unopposed May 2025)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member District 1 office not found — migration 088 must run first';
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
    'Justin', 'Beller', 'Justin', 'Justin Beller',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#District1'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Justin Beller (McKinney Council Member District 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Patrick Cloutier — Council Member District 2 (elected May 2023)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member District 2 office not found — migration 088 must run first';
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
    'Patrick', 'Cloutier', 'Patrick', 'Patrick Cloutier',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#District2'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Patrick Cloutier (McKinney Council Member District 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Geré Feltus — Council Member District 3 (won May 2025 with 54%)
-- NOTE: é accent is the official name form per mckinneytexas.org — do not normalize
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member District 3 office not found — migration 088 must run first';
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
    'Geré', 'Feltus', 'Geré', 'Geré Feltus',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#District3'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Geré Feltus (McKinney Council Member District 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Rick Franklin — Council Member District 4 (elected May 2023)
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
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'McKinney Council Member District 4 office not found — migration 088 must run first';
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
    'Rick', 'Franklin', 'Rick', 'Rick Franklin',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.mckinneytexas.org/1167/Council-Members#District4'],
    'mckinneytexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Rick Franklin (McKinney Council Member District 4) — %', v_politician_id;
END $$;

COMMIT;
