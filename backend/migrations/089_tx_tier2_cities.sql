-- =============================================================================
-- Migration 089: Seed Tier 2 city governments, chambers, and offices
--
-- Cities: Murphy, Celina, Prosper (legally a Town), Richardson (Collin County, TX)
-- All are nonpartisan municipalities — partisan_type = NULL on all offices.
--
-- Counts:
--   Murphy:     1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Celina:     1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Prosper:    1 government + 1 chamber + 7 offices (Mayor + Place 1-6) [legally a Town]
--   Richardson: 1 government + 1 chamber + 7 offices (Mayor + Districts 1-4 + Places 5-6)
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Murphy (FIPS place GEOID: 4850100)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Murphy, Texas, US', 'LOCAL', 'TX', NULL, '4850100')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Murphy City Council', 7, 'murphy-city-council', 'full', 'https://www.murphytx.org/government/city-council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Murphy', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Murphy', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Murphy', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Murphy', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Murphy', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Murphy', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Murphy', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- Celina (FIPS place GEOID: 4813684)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Celina, Texas, US', 'LOCAL', 'TX', NULL, '4813684')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Celina City Council', 7, 'celina-city-council', 'full', 'https://www.celinatx.gov/government/city-council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Celina', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Celina', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Celina', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Celina', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Celina', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Celina', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Celina', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- Prosper (FIPS place GEOID: 4863276) — NOTE: legally a Town, not a City
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('Town of Prosper, Texas, US', 'LOCAL', 'TX', NULL, '4863276')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'Town Council', 'Prosper Town Council', 7, 'prosper-town-council', 'full', 'https://www.prospertx.gov/government/town-council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Prosper', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Prosper', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Prosper', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Prosper', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Prosper', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Prosper', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Prosper', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- Richardson (FIPS place GEOID: 4863500) — mixed district + at-large structure
-- Mayor + Districts 1-4 (single-member) + Places 5-6 (at-large)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Richardson, Texas, US', 'LOCAL', 'TX', NULL, '4863500')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Richardson City Council', 7, 'richardson-city-council', 'full', 'https://www.cor.net/government/city-council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                    'Richardson', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member District 1', 'Richardson', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 2', 'Richardson', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 3', 'Richardson', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 4', 'Richardson', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5',    'Richardson', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6',    'Richardson', 'TX', 'Council Member', 1, NULL, false);
END $$;

COMMIT;
