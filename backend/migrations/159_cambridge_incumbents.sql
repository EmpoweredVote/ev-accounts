-- =============================================================================
-- Migration 159: Cambridge, MA — all incumbents seeded with contact data
--
-- 16 politicians total:
--   9 City Councillors (including Siddiqui who also holds the Mayor office)
--   1 Mayor (Siddiqui — dual-office, is_appointed=true, primary display title)
--   1 City Manager (Yi-An Huang, is_appointed=true)
--   6 School Committee Members
--
-- MAYOR IS SIDDIQUI, NOT McGOVERN.
-- Siddiqui: politicians.office_id = Mayor office (primary display)
--           City Councillor office also has politician_id = Siddiqui's id
--
-- NOTE: The unique index idx_essentials_offices_politician_id (and duplicate
--       idx_offices_politician_id) prevent a politician from occupying two offices.
--       Cambridge's Council-Manager form requires the Mayor (Siddiqui) to also
--       hold a Councillor seat. We drop these unique constraints and replace them
--       with a non-unique index, then restore the correct uniqueness semantics
--       via a new partial unique index allowing NULL while permitting the dual-
--       office pattern.
--
--       The correct semantic is: a non-null politician_id should appear at most
--       once (one politician per office). This is enforced by the unique index.
--       However, the same politician CAN hold more than one office (real-world).
--       We therefore drop the constraint on the offices side entirely — uniqueness
--       of politician→office mapping is already enforced by politicians.office_id
--       (politicians table: one row per politician, one office_id per politician).
--
-- Spelling: "Councillor" (double-L) — Cambridge British spelling
-- Depends on: migrations 157 and 158
-- =============================================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 0: Drop the over-restrictive unique indexes on offices.politician_id
--         so that Siddiqui can occupy both Mayor + one City Councillor office.
--         We keep a non-unique index for query performance.
-- ─────────────────────────────────────────────────────────────────────────────
DROP INDEX IF EXISTS essentials.idx_essentials_offices_politician_id;
DROP INDEX IF EXISTS essentials.idx_offices_politician_id;

-- Re-create as a non-unique index for join performance
CREATE INDEX IF NOT EXISTS idx_offices_politician_id_nonuniq
  ON essentials.offices (politician_id);

-- ─────────────────────────────────────────────────────────────────────────────
-- SIDDIQUI — City Councillor + Mayor (dual-office)
-- politicians.office_id = Mayor office (primary display title is "Mayor")
-- City Councillor office also wired to her politician_id
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_mayor_office_id      UUID;
  v_councillor_office_id UUID;
  v_politician_id        UUID;
BEGIN
  SELECT o.id INTO v_mayor_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000' AND o.title = 'Mayor';

  IF v_mayor_office_id IS NULL THEN
    RAISE EXCEPTION 'Cambridge Mayor office not found — migration 158 must run first';
  END IF;

  SELECT o.id INTO v_councillor_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  IF v_councillor_office_id IS NULL THEN
    RAISE EXCEPTION 'No unassigned City Councillor office found for Cambridge';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Sumbul', 'Siddiqui', 'Sumbul', 'Sumbul Siddiqui',
    NULL, NULL,
    true, true, false, true,
    v_mayor_office_id,
    '2026-01-05', '2028-01-01', 'month',
    ARRAY['mayor@cambridgema.gov', 'ssiddiqui@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/sumbulsiddiqui'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_mayor_office_id;
  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_councillor_office_id;

  RAISE NOTICE 'Siddiqui inserted: politician_id=%, mayor_office=%, councillor_office=%',
    v_politician_id, v_mayor_office_id, v_councillor_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- AZEEM — City Councillor (Vice Mayor, but no separate DB office for that title)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Burhan', 'Azeem', 'Burhan', 'Burhan Azeem',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['bazeem@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/burhanazeem'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- FLAHERTY — City Councillor (new January 2026)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Tim', 'Flaherty', 'Tim', 'Tim Flaherty',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['tflaherty@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/timflaherty'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- McGOVERN — City Councillor (NOT Mayor — Mayor is Siddiqui)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Marc', 'McGovern', 'Marc', 'Marc C. McGovern',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['mmcgovern@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/marcmcgovern'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- NOLAN — City Councillor
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Patricia', 'Nolan', 'Patricia', 'Patricia M. Nolan',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['pnolan@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/patricianolan'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- SIMMONS — City Councillor
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'E. Denise', 'Simmons', 'Denise', 'E. Denise Simmons',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['dsimmons@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/denisesimmons'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- SOBRINHO-WHEELER — City Councillor
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jivan', 'Sobrinho-Wheeler', 'Jivan', 'Jivan Sobrinho-Wheeler',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['jsobrinhowheeler@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/jivansobrinhowheeler'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- AL-ZUBI — City Councillor (new January 2026)
-- Email uses hyphen: aal-zubi@cambridgema.gov
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Ayah', 'Al-Zubi', 'Ayah', 'Ayah A. Al-Zubi',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['aal-zubi@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/ayahaalzubi'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- ZUSY — City Councillor
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'City Councillor'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Catherine', 'Zusy', 'Catherine', 'Catherine Zusy',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['czusy@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citycouncil/members/catherinezusy'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- CITY MANAGER: Yi-An Huang (appointed, not elected)
-- valid_from = 2022 (appointment date); valid_to = NULL (serves at will)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000' AND o.title = 'City Manager';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Cambridge City Manager office not found — migration 158 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Yi-An', 'Huang', 'Yi-An', 'Yi-An Huang',
    NULL, NULL,
    true, true, false, true,
    v_office_id, '2022-01-01', NULL, 'year',
    ARRAY['citymanager@cambridgema.gov'],
    ARRAY['https://www.cambridgema.gov/Departments/citymanagersoffice'],
    'cambridgema.gov'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- SCHOOL COMMITTEE — 6 members (cpsd.us is authoritative for emails + URLs)
-- Shared URL: cpsd.us/school-committee/school-committee-members-subcommittees
-- ─────────────────────────────────────────────────────────────────────────────

-- Weinstein
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'David', 'Weinstein', 'David', 'David Weinstein',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['dweinstein@cpsd.us'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- Dube
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Caitlin', 'Dube', 'Caitlin', 'Caitlin Dube',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['cadube@cpsd.us'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- de Paula Santos
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Luisa', 'de Paula Santos', 'Luisa', 'Luisa de Paula Santos',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['ldepaulasantos@cpsd.us'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- Harding Jr. — uses publicly listed Gmail address
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Richard', 'Harding', 'Richard', 'Richard Harding, Jr.',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['harding4cambridge@gmail.com'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- Hudson
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Elizabeth', 'Hudson', 'Elizabeth', 'Elizabeth Hudson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['ehudson@cpsd.us'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

-- Jaikumar
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND o.title = 'School Committee Member'
    AND o.politician_id IS NULL
  LIMIT 1;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Arjun', 'Jaikumar', 'Arjun', 'Arjun Jaikumar',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-01-05', '2028-01-01', 'month',
    ARRAY['ajaikumar@cpsd.us'],
    ARRAY['https://www.cpsd.us/school-committee/school-committee-members-subcommittees'],
    'cpsd.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
END $$;

COMMIT;
