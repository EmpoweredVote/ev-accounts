-- =============================================================================
-- Migration 091: Seed Plano incumbent politicians (post-May 2025 + Feb 2026 special)
--
-- Depends on migration 088 (Plano government + chamber + 9 offices)
-- 8 incumbents: Mayor + Council Member Place 1-5, 7-8
-- Council Member Place 6 is vacant — no politician row created for that seat.
-- Plano geo_id: '4863000'
--
-- Verified source: https://www.plano.gov/1348/Your-Mayor-and-City-Council-Members
-- Shun Thomas (Place 7): elected via special election January 31, 2026
--   is_appointed=false — elected, not appointed
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Mayor — John B. Muns (term: 2025-05-01 → 2029-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Mayor office not found — migration 088 must run first';
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
    'John', 'Muns', 'John', 'John B. Muns',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    ARRAY['mayor@plano.gov'],
    ARRAY['https://www.plano.gov/1349/Mayor-John-B-Muns'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: John B. Muns (Plano Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 1 — Maria Tu (term: 2023-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 1 office not found — migration 088 must run first';
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
    'Maria', 'Tu', 'Maria', 'Maria Tu',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2027-05-01', 'month',
    ARRAY['mariatu@plano.gov'],
    ARRAY['https://www.plano.gov/1355/Mayor-Pro-Tem-Maria-Tu'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Maria Tu (Plano Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 2 — Bob Kehr (term: 2025-05-01 → 2029-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 2 office not found — migration 088 must run first';
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
    'Bob', 'Kehr', 'Bob', 'Bob Kehr',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    ARRAY['bobkehr@plano.gov'],
    ARRAY['https://www.plano.gov/1354/Councilmember-Bob-Kehr'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Bob Kehr (Plano Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 3 — Rick Horne (term: 2023-05-01 → 2027-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 3 office not found — migration 088 must run first';
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
    'Rick', 'Horne', 'Rick', 'Rick Horne',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2027-05-01', 'month',
    ARRAY['rickhorne@plano.gov'],
    ARRAY['https://www.plano.gov/1356/Councilmember-Rick-Horne'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Rick Horne (Plano Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 4 — Chris Krupa Downs (term: 2025-05-01 → 2029-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 4 office not found — migration 088 must run first';
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
    'Chris', 'Krupa Downs', 'Chris', 'Chris Krupa Downs',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    ARRAY['chrisdowns@plano.gov'],
    ARRAY['https://www.plano.gov/1353/Councilmember-Chris-Krupa-Downs'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Chris Krupa Downs (Plano Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 5 — Steve Lavine (term: 2025-05-01 → 2029-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 5 office not found — migration 088 must run first';
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
    'Steve', 'Lavine', 'Steve', 'Steve Lavine',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    ARRAY['stevelavine@plano.gov'],
    ARRAY['https://www.plano.gov/1357/Councilmember-Steve-Lavine'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Steve Lavine (Plano Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 6 — VACANT
-- No politician record created. Office row left with politician_id = NULL.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Council Member Place 7 — Shun Thomas (term: 2026-02-09 → 2027-05-01)
-- Elected via special election January 31, 2026 (sworn in February 9, 2026)
-- is_appointed=false — elected, not appointed
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 7';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 7 office not found — migration 088 must run first';
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
    'Shun', 'Thomas', 'Shun', 'Shun Thomas',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2026-02-09', '2027-05-01', 'month',
    ARRAY['shunthomas@plano.gov'],
    ARRAY['https://www.plano.gov/1358/Councilmember-Shun-Thomas'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Shun Thomas (Plano Council Member Place 7) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 8 — Vidal Quintanilla (term: 2025-05-01 → 2029-05-01)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_office_id    UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4863000' AND o.title = 'Council Member Place 8';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Plano Council Member Place 8 office not found — migration 088 must run first';
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
    'Vidal', 'Quintanilla', 'Vidal', 'Vidal Quintanilla',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2029-05-01', 'month',
    ARRAY['vidalquintanilla@plano.gov'],
    ARRAY['https://www.plano.gov/1359/Councilmember-Vidal-Quintanilla'],
    'plano.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Vidal Quintanilla (Plano Council Member Place 8) — %', v_politician_id;
END $$;

COMMIT;
