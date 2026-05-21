-- =============================================================================
-- Migration 185: Longview TX city government, chamber, offices, and politicians
--
-- City: Longview, Texas (Gregg County) — NOT Collin County; separate ingestion
-- FIPS place GEOID: 4843888
-- Government type: Council-Manager
-- Council: Mayor (at-large) + 6 district council members (nonpartisan elections)
--
-- Council as of 2026-05-20:
--   Kristen Ishihara    — Mayor        (elected May 2024, term expires May 2027)
--   Derrick Conley      — District 1   (elected May 2024, term expires May 2027)
--   Shannon Moore       — District 2   (elected May 2024, term expires May 2027)
--   Wray Wade           — District 3   (elected Feb 2018; current term expired May 2026;
--                                        hold-over pending June 13, 2026 runoff between
--                                        Brandon Smith and Marlena Cooper)
--   John Nustad         — District 4   (orig. elected May 2023; re-elected unopposed May 2026;
--                                        new term expires May 2029; serves as Mayor ProTem)
--   Jody Berryhill      — District 5   (elected May 2025, term expires May 2028)
--   Sidney Allen        — District 6   (elected May 2025, term expires May 2028)
--
-- Sources:
--   https://longviewtexas.gov/2198/City-Council
--   https://www.longviewtexas.gov/3308/City-Election-Results
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
  v_office_id  UUID;
  v_pol_id     UUID;
BEGIN

  -- -------------------------------------------------------------------------
  -- Government
  -- -------------------------------------------------------------------------
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Longview, Texas, US', 'LOCAL', 'TX', NULL, '4843888')
  RETURNING id INTO v_gov_id;

  -- -------------------------------------------------------------------------
  -- Chamber
  -- -------------------------------------------------------------------------
  INSERT INTO essentials.chambers (
    government_id, name, name_formal, official_count,
    policy_engagement_level, website_url
  )
  VALUES (
    v_gov_id,
    'City Council',
    'Longview City Council',
    7,
    'full',
    'https://longviewtexas.gov/2198/City-Council'
  )
  RETURNING id INTO v_chamber_id;

  -- -------------------------------------------------------------------------
  -- Offices (Mayor + District 1..6)
  -- -------------------------------------------------------------------------
  INSERT INTO essentials.offices (
    chamber_id, title, representing_city, representing_state,
    normalized_position_name, seats, partisan_type, is_appointed_position
  )
  VALUES
    (v_chamber_id, 'Mayor',                   'Longview', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member District 1', 'Longview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 2', 'Longview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 3', 'Longview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 4', 'Longview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 5', 'Longview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 6', 'Longview', 'TX', 'Council Member', 1, NULL, false);

  -- =========================================================================
  -- Politicians
  -- =========================================================================

  -- -------------------------------------------------------------------------
  -- Kristen Ishihara — Mayor (elected May 2024; term expires May 2027)
  -- Attorney; former District 4 council member 2014-2024; board certified in
  -- estate planning & probate law; elected mayor May 2024.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Mayor';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Kristen', 'Ishihara', 'Kristen', 'Kristen Ishihara',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://longviewtexas.gov/2202/Mayor---Kristen-Ishihara'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Kristen Ishihara (Longview Mayor) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- Derrick Conley — District 1 (elected May 2024; term expires May 2027)
  -- Liaison: Council Appointments Committee; Zoning Board of Adjustment.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 1';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Derrick', 'Conley', 'Derrick', 'Derrick Conley',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://longviewtexas.gov/2201/District-1---Derrick-Conley'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Derrick Conley (Longview District 1) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- Shannon Moore — District 2 (elected May 2024; term expires May 2027)
  -- Liaison: Construction Advisory and Appeals Board; Firefighters Pension Fund;
  -- Housing Authority Advisory Committee.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 2';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Shannon', 'Moore', 'Shannon', 'Shannon Moore',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2024-05-01', '2027-05-01', 'month',
    NULL,
    ARRAY['https://www.longviewtexas.gov/2203/District-2---Shannon-Moore'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Shannon Moore (Longview District 2) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- Wray Wade — District 3 (elected Feb 2018; current term expired May 2026;
  -- serving in hold-over capacity pending June 13, 2026 runoff between
  -- Brandon Smith and Marlena Cooper. Term expiry recorded as June 2026.)
  -- Entrepreneur; Japanese interpreter background; liaison: Public Transportation.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 3';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Wray', 'Wade', 'Wray', 'Wray Wade',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2023-05-01', '2026-06-01', 'month',
    NULL,
    ARRAY['https://www.longviewtexas.gov/2204/District-3---Wray-Wade'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Wray Wade (Longview District 3) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- John Nustad — District 4 (orig. elected May 2023; re-elected unopposed May
  -- 2026; new term expires May 2029; serves as Mayor ProTem)
  -- Mortgage loan officer; Realtors Association; Kilgore College Foundation.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 4';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'John', 'Nustad', 'John', 'John Nustad',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2026-05-01', '2029-05-01', 'month',
    NULL,
    ARRAY['https://www.longviewtexas.gov/2205/District-4---John-Nustad'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: John Nustad (Longview District 4) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- Jody Berryhill — District 5 (elected May 2025; term expires May 2028)
  -- Athletic trainer; 25 years at Pine Tree ISD; liaison: Parks & Rec, Cultural Activities.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 5';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Jody', 'Berryhill', 'Jody', 'Jody Berryhill',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.longviewtexas.gov/2206/District-5---Jody-Berryhill'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Jody Berryhill (Longview District 5) — %', v_pol_id;

  -- -------------------------------------------------------------------------
  -- Sidney Allen — District 6 (elected May 2025; term expires May 2028)
  -- Liaison: Historic Preservation Commission; LEDCO; Planning and Zoning Commission.
  -- -------------------------------------------------------------------------
  SELECT id INTO v_office_id FROM essentials.offices
  WHERE chamber_id = v_chamber_id AND title = 'Council Member District 6';

  INSERT INTO essentials.politicians (
    first_name, last_name, preferred_name, full_name,
    party, party_short_name,
    is_active, is_incumbent, is_vacant, is_appointed,
    office_id,
    valid_from, valid_to, term_date_precision,
    email_addresses, urls,
    data_source
  ) VALUES (
    'Sidney', 'Allen', 'Sidney', 'Sidney Allen',
    NULL, NULL,
    true, true, false, false,
    v_office_id,
    '2025-05-01', '2028-05-01', 'month',
    NULL,
    ARRAY['https://www.longviewtexas.gov/2207/District-6---Sidney-Allen'],
    'longviewtexas.gov'
  ) RETURNING id INTO v_pol_id;

  UPDATE essentials.offices SET politician_id = v_pol_id WHERE id = v_office_id;
  RAISE NOTICE 'Inserted: Sidney Allen (Longview District 6) — %', v_pol_id;

END $$;

COMMIT;
