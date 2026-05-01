-- =============================================================================
-- Migration 090: Seed Tier 3 and Tier 4 city governments, chambers, and offices
--
-- Collin County, Texas — remaining 15 cities/towns
-- All are nonpartisan municipalities — partisan_type = NULL on all offices.
--
-- NOTE: Copeville (GEOID 4816600) is excluded from this migration.
-- Copeville may be an unincorporated Census-designated place (CDP) rather
-- than an incorporated municipality. If confirmed incorporated, add it
-- in a follow-up migration with the correct council structure.
--
-- TIER 3 cities (8):
--   Anna:        1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Melissa:     1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Princeton:   1 government + 1 chamber + 8 offices (Mayor + Place 1-7) [8 SEATS]
--   Lucas:       1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Lavon:       1 government + 1 chamber + 6 offices (Mayor + Place 1-5)
--   Fairview:    1 government + 1 chamber + 7 offices (Mayor + Seat 1-6) [legally a Town]
--   Van Alstyne: 1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Farmersville: 1 government + 1 chamber + 6 offices (Mayor + Place 1-5)
--
-- TIER 4 cities (7):
--   Parker:         1 government + 1 chamber + 6 offices (Mayor + Place 1-5)
--   Saint Paul:     1 government + 1 chamber + 6 offices (Mayor + Place 1-5)
--   Nevada:         1 government + 1 chamber + 6 offices (Mayor + Place 1-5)
--   Weston:         1 government + 1 chamber + 5 offices (Mayor + Place 1-4)
--   Lowry Crossing: 1 government + 1 chamber + 5 offices (Mayor + Place 1-4)
--   Josephine:      1 government + 1 chamber + 5 offices (Mayor + Place 1-4)
--   Blue Ridge:     1 government + 1 chamber + 5 offices (Mayor + Place 1-4)
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- TIER 3: Anna (FIPS place GEOID: 4803300)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Anna, Texas, US', 'LOCAL', 'TX', NULL, '4803300')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Anna City Council', 7, 'anna-city-council', 'full', 'https://www.annatexas.gov')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                'Anna', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Anna', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Anna', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Anna', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Anna', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Anna', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Anna', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Melissa (FIPS place GEOID: 4847496)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Melissa, Texas, US', 'LOCAL', 'TX', NULL, '4847496')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Melissa City Council', 7, 'melissa-city-council', 'full', 'https://www.cityofmelissa.com')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Melissa', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Melissa', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Melissa', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Melissa', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Melissa', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Melissa', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Melissa', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Princeton (FIPS place GEOID: 4863432) — 8 SEATS (Mayor + Place 1-7)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Princeton, Texas, US', 'LOCAL', 'TX', NULL, '4863432')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Princeton City Council', 8, 'princeton-city-council', 'full', 'https://www.princetontx.gov')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Princeton', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Princeton', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 7', 'Princeton', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Lucas (FIPS place GEOID: 4845012)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Lucas, Texas, US', 'LOCAL', 'TX', NULL, '4845012')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Lucas City Council', 7, 'lucas-city-council', 'full', 'https://www.lucastexas.us')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Lucas', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Lucas', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Lucas', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Lucas', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Lucas', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Lucas', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Lucas', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Lavon (FIPS place GEOID: 4841800) — 6 seats (Mayor + Place 1-5)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Lavon, Texas, US', 'LOCAL', 'TX', NULL, '4841800')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Lavon City Council', 6, 'lavon-city-council', 'full', 'https://www.lavontexas.org')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Lavon', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Lavon', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Lavon', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Lavon', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Lavon', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Lavon', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Fairview (FIPS place GEOID: 4825224) — NOTE: legally a Town, not a City
-- Uses 'Seat N' naming convention; 7 seats (Mayor + Seat 1-6)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('Town of Fairview, Texas, US', 'LOCAL', 'TX', NULL, '4825224')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'Town Council', 'Fairview Town Council', 7, 'fairview-town-council', 'full', 'https://www.fairviewtexas.org')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                   'Fairview', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Seat 1',   'Fairview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Seat 2',   'Fairview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Seat 3',   'Fairview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Seat 4',   'Fairview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Seat 5',   'Fairview', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Seat 6',   'Fairview', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Van Alstyne (FIPS place GEOID: 4875960)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Van Alstyne, Texas, US', 'LOCAL', 'TX', NULL, '4875960')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Van Alstyne City Council', 7, 'van-alstyne-city-council', 'full', 'https://www.vanalstyne.org')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Van Alstyne', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Van Alstyne', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 3: Farmersville (FIPS place GEOID: 4825488) — 6 seats (Mayor + Place 1-5)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Farmersville, Texas, US', 'LOCAL', 'TX', NULL, '4825488')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Farmersville City Council', 6, 'farmersville-city-council', 'full', 'https://www.farmersvilletx.com')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Farmersville', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Farmersville', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Farmersville', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Farmersville', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Farmersville', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Farmersville', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Parker (FIPS place GEOID: 4855152) — 6 seats (Mayor + Place 1-5)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Parker, Texas, US', 'LOCAL', 'TX', NULL, '4855152')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Parker City Council', 6, 'parker-city-council', 'full', 'https://www.parkertexas.us')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Parker', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Parker', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Parker', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Parker', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Parker', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Parker', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Saint Paul (FIPS place GEOID: 4864220) — 6 seats (Mayor + Place 1-5)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Saint Paul, Texas, US', 'LOCAL', 'TX', NULL, '4864220')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Saint Paul City Council', 6, 'saint-paul-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Saint Paul', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Saint Paul', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Saint Paul', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Saint Paul', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Saint Paul', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Saint Paul', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Nevada (FIPS place GEOID: 4850760) — 6 seats (Mayor + Place 1-5)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Nevada, Texas, US', 'LOCAL', 'TX', NULL, '4850760')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Nevada City Council', 6, 'nevada-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Nevada', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Nevada', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Nevada', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Nevada', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Nevada', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Nevada', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Weston (FIPS place GEOID: 4877740) — 5 seats (Mayor + Place 1-4)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Weston, Texas, US', 'LOCAL', 'TX', NULL, '4877740')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Weston City Council', 5, 'weston-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Weston', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Weston', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Weston', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Weston', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Weston', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Lowry Crossing (FIPS place GEOID: 4844308) — 5 seats (Mayor + Place 1-4)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Lowry Crossing, Texas, US', 'LOCAL', 'TX', NULL, '4844308')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Lowry Crossing City Council', 5, 'lowry-crossing-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Lowry Crossing', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Lowry Crossing', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Lowry Crossing', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Lowry Crossing', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Lowry Crossing', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Josephine (FIPS place GEOID: 4838068) — 5 seats (Mayor + Place 1-4)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Josephine, Texas, US', 'LOCAL', 'TX', NULL, '4838068')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Josephine City Council', 5, 'josephine-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Josephine', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Josephine', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Josephine', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Josephine', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Josephine', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- TIER 4: Blue Ridge (FIPS place GEOID: 4808872) — 5 seats (Mayor + Place 1-4)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Blue Ridge, Texas, US', 'LOCAL', 'TX', NULL, '4808872')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Blue Ridge City Council', 5, 'blue-ridge-city-council', 'full', NULL)
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                  'Blue Ridge', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Blue Ridge', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Blue Ridge', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Blue Ridge', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Blue Ridge', 'TX', 'Council Member', 1, NULL, false);
END $$;

COMMIT;
