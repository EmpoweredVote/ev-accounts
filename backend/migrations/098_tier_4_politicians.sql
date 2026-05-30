-- Migration 098: Seed Tier 4 incumbent politicians (7 of 8 Collin County Tier 4 cities)
-- Depends on migration 090 (Tier 3-4 cities: governments + chambers + offices)
--
-- 29 incumbents seeded across 7 cities. 9 NOT-YET-SEEDED comment blocks for May 3, 2026 election seats.
-- 3 DB-SCHEMA-GAP comment blocks documenting 5 persons who cannot be seeded due to office offsets.
--
-- Cities (alphabetical): Blue Ridge, Josephine, Lowry Crossing, Nevada, Parker, Saint Paul, Weston
-- EXCLUDED: Copeville (possibly unincorporated CDP per Phase 15 CONTEXT.md)
--
-- Special handling:
--   - Saint Paul: election cancelled (all 6 unopposed → declared elected). 4 newly-elected take office 2026-06-01;
--     2 continuing incumbents (Larry Nail Place 1, David Dryden Place 2) keep original valid_from='2024-05-01'.
--   - Saint Paul Mayor J.T. Trevino was former Seat 4 — moves up to Mayor.
--   - Saint Paul DB titles: 'Council Member Place N' (city uses Seat/Alderman terminology).
--   - Parker Place numbers: city does NOT publish Place numbers; assignment is positional from website order.
--   - Lowry Crossing: city has 6 ward-based council members; DB has Mayor + Place 1-4.
--     Wards 1-3 → Places 1-3. Ward 4 vacant (special election May 3) → stub at Place 4.
--   - Weston: DB has 5 offices; city has 6 aldermen. Marla Johnston CANNOT be seeded.
--     NOTE: Weston emails discovered on live site (not in research): {first_initial}{last}@westontexas.com pattern.
--   - Josephine: DB has 5 offices; city has 5 council members. Gary Chappell (Place 5) CANNOT be seeded.
--
-- POST-ELECTION FLAGS (9 stubs):
--   Blue Ridge Mayor          — Rhonda Williams contested
--   Blue Ridge Place 1        — David Apple contested
--   Lowry Crossing Place 4    — Ward 4 vacant; special election
--   Nevada Mayor              — Donald Deering unopposed pending certification
--   Nevada Place 1            — Mike Laye unopposed pending certification
--   Nevada Place 2            — Paul Baker unopposed pending certification
--   Parker Mayor              — Lee Pettle 3-candidate race
--   Parker Place 3            — Buddy Pilgrim at-large 4-candidate race
--   Parker Place 5            — Billy Barron same at-large 4-candidate race as Place 3
--
-- DB SCHEMA GAPS (3 cities, 5 persons; future migrations may add the missing offices):
--   Weston Place 5            — Marla Johnston (city has 6 aldermen)
--   Josephine Place 5         — Gary Chappell (city has 5 council members)
--   Lowry Crossing extra Wards — Chris Madrid, Agur Rios, Cindy Cash (city has 6 ward council)

BEGIN;

-- ===========================================================================
-- BLUE RIDGE (geo_id 4808872, data_source 'blueridgecity.com')
-- City Council — Mayor + Place 1-4
-- Role-based emails confirmed. May 3 ballot: Mayor and Place 1 stubs (both contested).
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Blue Ridge Mayor — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Rhonda Williams is in a contested race.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://blueridgecity.com/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Blue Ridge Place 1 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- David Apple is in a contested race.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://blueridgecity.com/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Blue Ridge Council Member Place 2 — Linda Braly (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Blue Ridge Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Linda', 'Braly', 'Linda', 'Linda Braly',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['council2@blueridgecity.com'],
    ARRAY['https://blueridgecity.com/'],
    'blueridgecity.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Linda Braly (Blue Ridge Council Member Place 2) — %', v_politician_id;
END $$;

-- Blue Ridge Council Member Place 3 — Trenton Sissom (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Blue Ridge Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Trenton', 'Sissom', 'Trenton', 'Trenton Sissom',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['council3@blueridgecity.com'],
    ARRAY['https://blueridgecity.com/'],
    'blueridgecity.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Trenton Sissom (Blue Ridge Council Member Place 3) — %', v_politician_id;
END $$;

-- Blue Ridge Council Member Place 4 — Wendy Mattingly (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Blue Ridge Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Wendy', 'Mattingly', 'Wendy', 'Wendy Mattingly',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['council4@blueridgecity.com'],
    ARRAY['https://blueridgecity.com/'],
    'blueridgecity.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Wendy Mattingly (Blue Ridge Council Member Place 4) — %', v_politician_id;
END $$;

-- ===========================================================================
-- JOSEPHINE (geo_id 4838068, data_source 'cityofjosephinetx.com')
-- City Council — Mayor + Place 1-4 (Place 5 is DB gap — Gary Chappell cannot be seeded)
-- No May 2026 election. No emails. City website unreachable — TML data used as fallback.
-- ===========================================================================

-- Josephine Mayor — Jason Turney (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Josephine Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jason', 'Turney', 'Jason', 'Jason Turney',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'cityofjosephinetx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jason Turney (Josephine Mayor) — %', v_politician_id;
END $$;

-- Josephine Council Member Place 1 — April Aurand (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Josephine Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'April', 'Aurand', 'April', 'April Aurand',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'cityofjosephinetx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: April Aurand (Josephine Council Member Place 1) — %', v_politician_id;
END $$;

-- Josephine Council Member Place 2 — Jane Ridgway (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Josephine Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jane', 'Ridgway', 'Jane', 'Jane Ridgway',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'cityofjosephinetx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jane Ridgway (Josephine Council Member Place 2) — %', v_politician_id;
END $$;

-- Josephine Council Member Place 3 — Alex Esquivel (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Josephine Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Alex', 'Esquivel', 'Alex', 'Alex Esquivel',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'cityofjosephinetx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Alex Esquivel (Josephine Council Member Place 3) — %', v_politician_id;
END $$;

-- Josephine Council Member Place 4 — Pam Sardo (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4838068' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Josephine Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Pam', 'Sardo', 'Pam', 'Pam Sardo',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    NULL,
    NULL,
    'cityofjosephinetx.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Pam Sardo (Josephine Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Josephine DB SCHEMA GAP
-- City of Josephine has 5 council members (Mayor + Place 1-4 + Place 5) but DB
--   (migration 090) only created 5 offices (Mayor + Place 1-4). Gary Chappell
--   (Place 5 council member) CANNOT be seeded by this migration. A future
--   migration would need to:
--     INSERT INTO essentials.offices (chamber_id, title, ...) VALUES
--       (v_chamber_id, 'Council Member Place 5', ...);
--   ...before Gary Chappell could be seeded.
-- Source: TML data (cityofjosephinetx.com unreachable as of 2026-05-01)
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- LOWRY CROSSING (geo_id 4844308, data_source 'lowrycrossingtexas.org')
-- City Council — Mayor + Place 1-4 (mapped from ward system)
-- Ward 1 → Place 1, Ward 2 → Place 2, Ward 3 → Place 3, Ward 4 → stub (vacant, special election)
-- Three extra ward seats (Madrid, Rios, Cash) are DB schema gaps.
-- Emails confirmed plain-text on city website.
-- ===========================================================================

-- Lowry Crossing Mayor — Pat Kelly (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lowry Crossing Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Pat', 'Kelly', 'Pat', 'Pat Kelly',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['pkelly@lowrycrossingtexas.org'],
    ARRAY['https://www.lowrycrossingtexas.org/'],
    'lowrycrossingtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Pat Kelly (Lowry Crossing Mayor) — %', v_politician_id;
END $$;

-- Lowry Crossing Council Member Place 1 — Scott Pitchure (Ward 1 → Place 1; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lowry Crossing Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Scott', 'Pitchure', 'Scott', 'Scott Pitchure',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['spitchure@lowrycrossingtexas.org'],
    ARRAY['https://www.lowrycrossingtexas.org/'],
    'lowrycrossingtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Scott Pitchure (Lowry Crossing Council Member Place 1) — %', v_politician_id;
END $$;

-- Lowry Crossing Council Member Place 2 — Tammy Hodges (Ward 2 → Place 2; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lowry Crossing Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Tammy', 'Hodges', 'Tammy', 'Tammy Hodges',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['thodges@lowrycrossingtexas.org'],
    ARRAY['https://www.lowrycrossingtexas.org/'],
    'lowrycrossingtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Tammy Hodges (Lowry Crossing Council Member Place 2) — %', v_politician_id;
END $$;

-- Lowry Crossing Council Member Place 3 — Eusebio "Joe" Trujillo III (Ward 3 → Place 3; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4844308' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Lowry Crossing Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Eusebio', 'Trujillo', 'Joe', 'Eusebio "Joe" Trujillo III',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['etrujillo@lowrycrossingtexas.org'],
    ARRAY['https://www.lowrycrossingtexas.org/'],
    'lowrycrossingtexas.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Eusebio "Joe" Trujillo III (Lowry Crossing Council Member Place 3) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Lowry Crossing Place 4 — NOT YET SEEDED (Ward 4 vacant; special election May 3, 2026)
-- Ward 4 seat is vacant — special election on May 3, 2026 ballot.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://www.lowrycrossingtexas.org/
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Lowry Crossing DB SCHEMA GAP
-- City of Lowry Crossing has 6 ward-based council members + Mayor; DB (migration 090)
--   only created 5 offices (Mayor + Place 1-4, mapped from Wards 1-4).
--   Three additional ward incumbents CANNOT be seeded by this migration:
--     - Chris Madrid (extra Ward 1 seat)
--     - Agur Rios (extra Ward 2 seat)
--     - Cindy Cash (extra Ward 3 seat)
--   A future migration would need to add 3 additional ward-based offices before
--   these persons could be seeded.
-- Source: https://www.lowrycrossingtexas.org/
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- NEVADA (geo_id 4850760, data_source 'cityofnevadatx.org')
-- City Council — Mayor + Place 1-5
-- Role-based emails confirmed. Mayor + Place 1 + Place 2 are stubs (unopposed, pending certification).
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Nevada Mayor — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Donald Deering is running unopposed but not yet certified.
-- ACTION: After certification (est. May 5-9, 2026), verify at:
--   https://www.cityofnevadatx.org/
--   then add a separate DO block to INSERT Donald Deering as winner.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Nevada Place 1 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Mike Laye is running unopposed but not yet certified.
-- ACTION: After certification (est. May 5-9, 2026), verify at:
--   https://www.cityofnevadatx.org/
--   then add a separate DO block to INSERT Mike Laye as winner.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- Nevada Place 2 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Paul Baker is running unopposed but not yet certified.
-- ACTION: After certification (est. May 5-9, 2026), verify at:
--   https://www.cityofnevadatx.org/
--   then add a separate DO block to INSERT Paul Baker as winner.
-- ---------------------------------------------------------------------------

-- Nevada Council Member Place 3 — Amanda Wilson (term: 2024-05-01 → 2026-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Nevada Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Amanda', 'Wilson', 'Amanda', 'Amanda Wilson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2026-05-01', 'month',
    ARRAY['councilman3@cityofnevadatx.org'],
    NULL,
    'cityofnevadatx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Amanda Wilson (Nevada Council Member Place 3) — %', v_politician_id;
END $$;

-- Nevada Council Member Place 4 — Clayton Laughter (term: 2024-05-01 → 2026-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Nevada Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Clayton', 'Laughter', 'Clayton', 'Clayton Laughter',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2026-05-01', 'month',
    ARRAY['councilman4@cityofnevadatx.org'],
    NULL,
    'cityofnevadatx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Clayton Laughter (Nevada Council Member Place 4) — %', v_politician_id;
END $$;

-- Nevada Council Member Place 5 — Derrick Little (term: 2024-05-01 → 2026-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Nevada Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Derrick', 'Little', 'Derrick', 'Derrick Little',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2026-05-01', 'month',
    ARRAY['councilman5@cityofnevadatx.org'],
    NULL,
    'cityofnevadatx.org'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Derrick Little (Nevada Council Member Place 5) — %', v_politician_id;
END $$;

-- ===========================================================================
-- PARKER (geo_id 4855152, data_source 'parkertexas.us')
-- City Council — Mayor + Place 1-5
-- Email pattern: {first_initial}{lastname}@parkertexas.us (confirmed)
-- City does NOT publish Place numbers — assignment is positional from website order.
-- May 3 ballot: Mayor (3-candidate), Place 3 + Place 5 (at-large 4-candidate, top-2 wins).
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Parker Mayor — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Lee Pettle is in a 3-candidate race.
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://parkertexas.us/76/City-Council
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Parker Council Member Place 1 — Roxanne Bogdan (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Parker Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Roxanne', 'Bogdan', 'Roxanne', 'Roxanne Bogdan',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['rbogdan@parkertexas.us'],
    NULL,
    'parkertexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Roxanne Bogdan (Parker Council Member Place 1) — %', v_politician_id;
END $$;

-- Parker Council Member Place 2 — Colleen Halbert (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Parker Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Colleen', 'Halbert', 'Colleen', 'Colleen Halbert',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['chalbert@parkertexas.us'],
    NULL,
    'parkertexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Colleen Halbert (Parker Council Member Place 2) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Parker Place 3 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Buddy Pilgrim is in an at-large 4-candidate race (top 2 win Places 3 and 5).
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://parkertexas.us/76/City-Council
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- Parker Council Member Place 4 — Darrel Sharpe (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4855152' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Parker Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Darrel', 'Sharpe', 'Darrel', 'Darrel Sharpe',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['dsharpe@parkertexas.us'],
    NULL,
    'parkertexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Darrel Sharpe (Parker Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Parker Place 5 — NOT YET SEEDED (pending May 3, 2026 election certification)
-- Billy Barron is in the same at-large 4-candidate race as Place 3 (top 2 win).
-- ACTION: After certification (est. May 5-9, 2026), verify winner at:
--   https://parkertexas.us/76/City-Council
--   then add a separate DO block to INSERT the winner.
-- ---------------------------------------------------------------------------

-- ===========================================================================
-- SAINT PAUL (geo_id 4864220, data_source 'stpaultexas.us')
-- City Council — Mayor + Place 1-5
-- Election cancelled — all 6 seats unopposed/declared elected.
-- Newly-declared (Mayor/Place 3/Place 4/Place 5): valid_from='2026-06-01', valid_to='2029-06-01'
-- Continuing incumbents (Place 1/Place 2): valid_from='2024-05-01', valid_to='2027-05-01'
-- DB titles: 'Council Member Place N' (city uses Seat/Alderman; DB uses Place)
-- ===========================================================================

-- Saint Paul Mayor — J.T. Trevino (declared elected; takes office 2026-06-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'J.T.', 'Trevino', 'J.T.', 'J.T. Trevino',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-06-01', '2029-06-01', 'month',
    ARRAY['jt.trevino@stpaultexas.us'],
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: J.T. Trevino (Saint Paul Mayor) — %', v_politician_id;
END $$;

-- Saint Paul Council Member Place 1 — Larry Nail (continuing incumbent; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Larry', 'Nail', 'Larry', 'Larry Nail',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['larry.nail@stpaultexas.us'],
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Larry Nail (Saint Paul Council Member Place 1) — %', v_politician_id;
END $$;

-- Saint Paul Council Member Place 2 — David Dryden (continuing incumbent; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'David', 'Dryden', 'David', 'David Dryden',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['david.dryden@stpaultexas.us'],
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: David Dryden (Saint Paul Council Member Place 2) — %', v_politician_id;
END $$;

-- Saint Paul Council Member Place 3 — Greg Pierson (declared elected; takes office 2026-06-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Greg', 'Pierson', 'Greg', 'Greg Pierson',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-06-01', '2029-06-01', 'month',
    NULL,
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Greg Pierson (Saint Paul Council Member Place 3) — %', v_politician_id;
END $$;

-- Saint Paul Council Member Place 4 — Kristen Bewley (declared elected; takes office 2026-06-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Kristen', 'Bewley', 'Kristen', 'Kristen Bewley',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-06-01', '2029-06-01', 'month',
    NULL,
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Kristen Bewley (Saint Paul Council Member Place 4) — %', v_politician_id;
END $$;

-- Saint Paul Council Member Place 5 — Robert Simmons (declared elected; takes office 2026-06-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4864220' AND o.title = 'Council Member Place 5';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Saint Paul Council Member Place 5 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Robert', 'Simmons', 'Robert', 'Robert Simmons',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2026-06-01', '2029-06-01', 'month',
    ARRAY['robert.simmons@stpaultexas.us'],
    ARRAY['https://stpaultexas.us/'],
    'stpaultexas.us'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Robert Simmons (Saint Paul Council Member Place 5) — %', v_politician_id;
END $$;

-- ===========================================================================
-- WESTON (geo_id 4877740, data_source 'westontexas.com')
-- City Council — Mayor + Place 1-4 (positional; DB has 5 offices)
-- No May 2026 election.
-- Emails ARE published (spot-check 2026-05-01 corrects research note of NULL).
-- DB GAP: city has 6 aldermen; Marla Johnston (6th) CANNOT be seeded.
-- ===========================================================================

-- Weston Mayor — Matthew Marchiori (term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Mayor';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Weston Mayor office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Matthew', 'Marchiori', 'Matthew', 'Matthew Marchiori',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['mmarchiori@westontexas.com'],
    NULL,
    'westontexas.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Matthew Marchiori (Weston Mayor) — %', v_politician_id;
END $$;

-- Weston Council Member Place 1 — Patti Harrington (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 1';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Weston Council Member Place 1 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Patti', 'Harrington', 'Patti', 'Patti Harrington',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['pharrington@westontexas.com'],
    NULL,
    'westontexas.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Patti Harrington (Weston Council Member Place 1) — %', v_politician_id;
END $$;

-- Weston Council Member Place 2 — Brian M. Roach (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 2';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Weston Council Member Place 2 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Brian', 'Roach', 'Brian', 'Brian M. Roach',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['broach@westontexas.com'],
    NULL,
    'westontexas.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Brian M. Roach (Weston Council Member Place 2) — %', v_politician_id;
END $$;

-- Weston Council Member Place 3 — Jeff Metzger (Mayor Pro Tem; positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 3';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Weston Council Member Place 3 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Jeff', 'Metzger', 'Jeff', 'Jeff Metzger',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['jmetzger@westontexas.com'],
    NULL,
    'westontexas.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jeff Metzger (Weston Council Member Place 3) — %', v_politician_id;
END $$;

-- Weston Council Member Place 4 — Mike Hill (positional; term: 2024-05-01 → 2027-05-01)
DO $$
DECLARE
  v_office_id     UUID;
  v_politician_id UUID;
BEGIN
  SELECT o.id INTO v_office_id
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '4877740' AND o.title = 'Council Member Place 4';

  IF v_office_id IS NULL THEN
    RAISE EXCEPTION 'Weston Council Member Place 4 office not found — migration 090 must run first';
  END IF;

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id, valid_from, valid_to, term_date_precision,
    email_addresses, urls, data_source
  ) VALUES (
    'Mike', 'Hill', 'Mike', 'Mike Hill',
    NULL, NULL,
    true, true, false, false,
    v_office_id, '2024-05-01', '2027-05-01', 'month',
    ARRAY['mhill@westontexas.com'],
    NULL,
    'westontexas.com'
  ) RETURNING id INTO v_politician_id;

  UPDATE essentials.offices SET politician_id = v_politician_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Mike Hill (Weston Council Member Place 4) — %', v_politician_id;
END $$;

-- ---------------------------------------------------------------------------
-- Weston DB SCHEMA GAP
-- City of Weston has 6 aldermen but DB (migration 090) only created 5 offices
--   (Mayor + Council Member Place 1-4). Marla Johnston (6th alderman) CANNOT
--   be seeded by this migration. A future migration would need to:
--     INSERT INTO essentials.offices (chamber_id, title, ...) VALUES
--       (v_chamber_id, 'Council Member Place 5', ...);
--   ...before Marla Johnston could be seeded.
-- Source: https://www.westontexas.com/page/Mayor_Aldermen
-- ---------------------------------------------------------------------------

COMMIT;
