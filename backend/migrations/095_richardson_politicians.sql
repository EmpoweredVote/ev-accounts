-- =============================================================================
-- Migration 095: Seed Richardson incumbent politicians (Tier 2 batch 2)
--
-- Depends on migration 089 (Tier 2 cities: Richardson offices)
-- 7 incumbents: Mayor + Council Member District 1-4 + Council Member Place 5-6
-- Richardson geo_id: '4863500'
--
-- TITLE QUIRK: Richardson officially calls every council seat "Place 1-6", but Phase 12
-- migration 089 chose DB titles 'Council Member District 1-4' for the first four seats.
-- This migration uses DB titles as lookup keys.
--
-- TERM QUIRK: Richardson runs 2-year staggered terms (all current members elected
-- May 2025, terms expire May 2027). All other Tier 2 cities use 3-year terms.
--
-- EMAIL NOTE: Confirmed pattern Firstname.Lastname@cor.gov (bio URLs on cor.net).
--
-- POST-ELECTION FLAGS: NONE — no Richardson council races on May 3, 2026.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Mayor — Amir Omar (term: 2025-05-01 → 2027-05-01)
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
  WHERE g.geo_id = '4863500' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Mayor office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Amir', 'Omar', 'Amir', 'Amir Omar',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Amir.Omar@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/amir-omar'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Amir Omar (Richardson Mayor) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member District 1 — Curtis Dorian (term: 2025-05-01 → 2027-05-01)
-- DB title 'Council Member District 1' corresponds to Richardson's official 'Place 1'
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member District 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member District 1 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Curtis', 'Dorian', 'Curtis', 'Curtis Dorian',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Curtis.Dorian@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/curtis-dorian'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Curtis Dorian (Richardson Council Member District 1) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member District 2 — Jennifer Justice (term: 2025-05-01 → 2027-05-01)
-- DB title 'Council Member District 2' corresponds to Richardson's official 'Place 2'
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member District 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member District 2 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jennifer', 'Justice', 'Jennifer', 'Jennifer Justice',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Jennifer.Justice@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/jennifer-justice'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jennifer Justice (Richardson Council Member District 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member District 3 — Dan Barrios (term: 2025-05-01 → 2027-05-01)
-- DB title 'Council Member District 3' corresponds to Richardson's official 'Place 3'
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member District 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member District 3 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Dan', 'Barrios', 'Dan', 'Dan Barrios',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Dan.Barrios@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/dan-barrios'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Dan Barrios (Richardson Council Member District 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member District 4 — Joe Corcoran (term: 2025-05-01 → 2027-05-01)
-- DB title 'Council Member District 4' corresponds to Richardson's official 'Place 4'
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member District 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member District 4 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Joe', 'Corcoran', 'Joe', 'Joe Corcoran',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Joe.Corcoran@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/joe-corcoran'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Joe Corcoran (Richardson Council Member District 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 5 — Ken Hutchenrider (term: 2025-05-01 → 2027-05-01)
-- At-large seat (no district residency requirement)
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member Place 5 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ken', 'Hutchenrider', 'Ken', 'Ken Hutchenrider',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Ken.Hutchenrider@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/ken-hutchenrider'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Ken Hutchenrider (Richardson Council Member Place 5) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Council Member Place 6 — Arefin Shamsul (term: 2025-05-01 → 2027-05-01)
-- At-large seat (no district residency requirement)
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
  WHERE g.geo_id = '4863500' AND o.title = 'Council Member Place 6';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Richardson Council Member Place 6 office not found — migration 089 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Arefin', 'Shamsul', 'Arefin', 'Arefin Shamsul',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2025-05-01', '2027-05-01', 'month',
    ARRAY['Arefin.Shamsul@cor.gov'],
    ARRAY['https://www.cor.net/government/city-council/who-are-our-city-council-members/arefin-shamsul'],
    'cor.net'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Arefin Shamsul (Richardson Council Member Place 6) — %', v_politician_id;
END $$;

COMMIT;
