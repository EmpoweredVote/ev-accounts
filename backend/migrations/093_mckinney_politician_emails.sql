-- Migration 093: Add email addresses to McKinney incumbent politicians
-- Role-based email pattern confirmed by user: {role}@mckinneytexas.org
-- Emails: mayor, AtLarge1, AtLarge2, District1, District2, District3, District4
-- McKinney geo_id: '4845744'

BEGIN;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- Mayor — Bill Cox → mayor@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Mayor' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney Mayor politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['mayor@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated Mayor email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- At-Large 1 — Ernest Lynch → AtLarge1@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member At-Large Place 1' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney At-Large 1 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['AtLarge1@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated At-Large 1 email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- At-Large 2 — Michael Jones → AtLarge2@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member At-Large Place 2' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney At-Large 2 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['AtLarge2@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated At-Large 2 email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- District 1 — Justin Beller → District1@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 1' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney District 1 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['District1@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated District 1 email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- District 2 — Patrick Cloutier → District2@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 2' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney District 2 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['District2@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated District 2 email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- District 3 — Geré Feltus → District3@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 3' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney District 3 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['District3@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated District 3 email';
END $$;

DO $$
DECLARE
  v_politician_id UUID;
BEGIN
  -- District 4 — Rick Franklin → District4@mckinneytexas.org
  SELECT p.id INTO v_politician_id
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.id = p.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4845744' AND o.title = 'Council Member District 4' AND p.is_active = true;

  IF v_politician_id IS NULL THEN RAISE EXCEPTION 'McKinney District 4 politician not found'; END IF;
  UPDATE essentials.politicians SET email_addresses = ARRAY['District4@mckinneytexas.org'] WHERE id = v_politician_id;
  RAISE NOTICE 'Updated District 4 email';
END $$;

COMMIT;
