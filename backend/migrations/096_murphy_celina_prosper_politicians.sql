-- =============================================================================
-- Migration 096: Seed Murphy + Celina + Prosper incumbent politicians (Tier 2 batch 3)
-- Depends on migration 089 (Tier 2 cities: Murphy + Celina + Prosper offices)
-- 21 incumbents: Murphy (Mayor + Place 1-6) + Celina (Mayor + Place 1-6) + Prosper Town Council (Mayor + Place 1-6)
--
-- Prosper is legally a Town (not a City). Phase 12 chamber name is 'Town Council'.
-- Celina official domain is 'celina-tx.gov' (HYPHEN) — never 'celinatx.gov'.
--
-- POST-ELECTION FLAGS (handled in follow-up update workflow, NOT this migration):
--   Murphy Mayor (Scott Bradley) — re-elected unopposed May 3, update term to 2026-2029
--   Murphy Place 3 (Andrew Chase) — contested May 3
--   Murphy Place 5 (Laura Deel) — contested May 3
--   Celina Mayor (Ryan Tubbs) — contested May 3
--   Celina Place 4 (Wendie Wigginton) — open seat, not running
--   Celina Place 5 (Mindy Koehne) — open seat, not running
--   Prosper Place 5 (Jeff Hodges) — Doug Charles sworn in May 12, 2026 (handoff)
-- =============================================================================

BEGIN;

-- ===========================================================================
-- MURPHY (geo_id 4850100, data_source 'murphytx.org')
-- City Council — Mayor + Places 1-6
-- All email_addresses = NULL (not published on murphytx.org)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Murphy Mayor — Scott Bradley (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: re-elected unopposed May 3 — update term to 2026-2029
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
  WHERE g.geo_id = '4850100' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Scott', 'Bradley', 'Scott', 'Scott Bradley',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=6'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Scott Bradley (Murphy Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 1 — Elizabeth Abraham (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Elizabeth', 'Abraham', 'Elizabeth', 'Elizabeth Abraham',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=7'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Elizabeth Abraham (Murphy Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 2 — Scott Smith (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Scott', 'Smith', 'Scott', 'Scott Smith',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=8'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Scott Smith (Murphy Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 3 — Andrew Chase (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: contested May 3 — check murphytx.org for winner
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Andrew', 'Chase', 'Andrew', 'Andrew Chase',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=10'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Andrew Chase (Murphy Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 4 — Ken Oltmann (term: 2025-05-01 → 2028-05-01)
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ken', 'Oltmann', 'Ken', 'Ken Oltmann',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=9'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ken Oltmann (Murphy Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 5 — Laura Deel (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: contested May 3 — check murphytx.org for winner
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Laura', 'Deel', 'Laura', 'Laura Deel',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=11'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Laura Deel (Murphy Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Murphy Council Member Place 6 — Jené Butler (term: 2025-05-01 → 2028-05-01)
-- UTF-8 CRITICAL: é accent in 'Jené' must be preserved exactly
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
  WHERE g.geo_id = '4850100' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Murphy Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jené', 'Butler', 'Jené', 'Jené Butler',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.murphytx.org/Directory.aspx?EID=12'],
    'murphytx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jené Butler (Murphy Council Member Place 6) — %', v_politician_id;
END $$;

-- ===========================================================================
-- CELINA (geo_id 4813684, data_source 'celina-tx.gov')
-- City Council — Mayor + Places 1-6
-- DOMAIN NOTE: always 'celina-tx.gov' WITH HYPHEN — never 'celinatx.gov'
-- Only the Mayor has a confirmed email address
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Celina Mayor — Ryan Tubbs (term: 2023-05-01 → 2026-05-01)
-- Only confirmed email across all 21 rows: rtubbs@celina-tx.gov
-- POST-ELECTION FLAG: contested May 3 — check celina-tx.gov for winner
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
  WHERE g.geo_id = '4813684' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ryan', 'Tubbs', 'Ryan', 'Ryan Tubbs',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    ARRAY['rtubbs@celina-tx.gov'],
    ARRAY['https://www.celina-tx.gov/295/Office-of-the-Mayor'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ryan Tubbs (Celina Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 1 — Philip Ferguson (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Philip', 'Ferguson', 'Philip', 'Philip Ferguson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Philip Ferguson (Celina Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 2 — Eddie Cawlfield (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Eddie', 'Cawlfield', 'Eddie', 'Eddie Cawlfield',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Eddie Cawlfield (Celina Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 3 — Andy Hopkins (term: 2025-05-01 → 2028-05-01)
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Andy', 'Hopkins', 'Andy', 'Andy Hopkins',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Andy Hopkins (Celina Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 4 — Wendie Wigginton (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: open seat, Wigginton not running — check celina-tx.gov for winner
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Wendie', 'Wigginton', 'Wendie', 'Wendie Wigginton',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Wendie Wigginton (Celina Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 5 — Mindy Koehne (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: open seat, Koehne not running — check celina-tx.gov for winner
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Mindy', 'Koehne', 'Mindy', 'Mindy Koehne',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Mindy Koehne (Celina Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Celina Council Member Place 6 — Brandon Grumbles (term: 2025-05-01 → 2028-05-01)
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
  WHERE g.geo_id = '4813684' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Celina Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Brandon', 'Grumbles', 'Brandon', 'Brandon Grumbles',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.celina-tx.gov/319/City-Council'],
    'celina-tx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Brandon Grumbles (Celina Council Member Place 6) — %', v_politician_id;
END $$;

-- ===========================================================================
-- PROSPER (geo_id 4863276, data_source 'prospertx.gov')
-- Town Council — Mayor + Places 1-6
-- NOTE: Prosper is legally a Town (not a City); chamber name = 'Town Council'
-- All email_addresses = NULL (not published on prospertx.gov)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Mayor — David F. Bristol (term: 2025-05-01 → 2028-05-01)
-- full_name keeps middle initial 'F.' per official directory listing
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
  WHERE g.geo_id = '4863276' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'David', 'Bristol', 'David', 'David F. Bristol',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=63'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: David F. Bristol (Prosper Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 1 — Marcus E. Ray (term: 2025-05-01 → 2028-05-01)
-- full_name keeps middle initial 'E.' per official directory listing
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Marcus', 'Ray', 'Marcus', 'Marcus E. Ray',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=64'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Marcus E. Ray (Prosper Council Member Place 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 2 — Craig Andres (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Craig', 'Andres', 'Craig', 'Craig Andres',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=65'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Craig Andres (Prosper Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 3 — Amy Bartley (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: re-elected uncontested May 3, sworn in new term May 12
--   After May 12: update valid_from='2026-05-12', valid_to='2029-05-01'
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Amy', 'Bartley', 'Amy', 'Amy Bartley',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=66'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Amy Bartley (Prosper Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 4 — Chris Kern (term: 2025-05-01 → 2028-05-01)
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Chris', 'Kern', 'Chris', 'Chris Kern',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=67'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Chris Kern (Prosper Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 5 — Jeff Hodges (term: 2023-05-01 → 2026-05-01)
-- POST-ELECTION FLAG: Doug Charles sworn in May 12, 2026 as successor
--   After May 12: set Hodges is_active=false, valid_to='2026-05-12'
--   Then insert Doug Charles row with valid_from='2026-05-12', valid_to='2029-05-01'
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jeff', 'Hodges', 'Jeff', 'Jeff Hodges',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2023-05-01', '2026-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=68'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jeff Hodges (Prosper Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Prosper Town Council — Council Member Place 6 — Cameron Reeves (term: 2024-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4863276' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Prosper Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Cameron', 'Reeves', 'Cameron', 'Cameron Reeves',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.prospertx.gov/directory.aspx?EID=69'],
    'prospertx.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Cameron Reeves (Prosper Council Member Place 6) — %', v_politician_id;
END $$;

COMMIT;
