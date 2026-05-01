-- =============================================================================
-- Migration 088: Seed Tier 1 city governments, chambers, and offices
--
-- Cities: Plano, McKinney, Allen, Frisco (Collin County, TX)
-- All are nonpartisan municipalities — partisan_type = NULL on all offices.
--
-- Counts:
--   Plano:   1 government + 1 chamber + 9 offices (Mayor + Place 1-8)
--   McKinney: 1 government + 1 chamber + 7 offices (Mayor + 2 at-large + 4 district)
--   Allen:   1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
--   Frisco:  1 government + 1 chamber + 7 offices (Mayor + Place 1-6)
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- Plano (FIPS place GEOID: 4863000)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Plano, Texas, US', 'LOCAL', 'TX', NULL, '4863000')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Plano City Council', 9, 'plano-city-council', 'full', 'https://www.plano.gov/164/City-Council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Plano', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 7', 'Plano', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 8', 'Plano', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- McKinney (FIPS place GEOID: 4845744)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of McKinney, Texas, US', 'LOCAL', 'TX', NULL, '4845744')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'McKinney City Council', 7, 'mckinney-city-council', 'full', 'https://www.mckinneytexas.org/394/City-Council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                         'McKinney', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member At-Large Place 1', 'McKinney', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member At-Large Place 2', 'McKinney', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 1',       'McKinney', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 2',       'McKinney', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 3',       'McKinney', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member District 4',       'McKinney', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- Allen (FIPS place GEOID: 4801924)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Allen, Texas, US', 'LOCAL', 'TX', NULL, '4801924')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Allen City Council', 7, 'allen-city-council', 'full', 'https://www.cityofallen.org/139/City-Council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Allen', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Allen', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Allen', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Allen', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Allen', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Allen', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Allen', 'TX', 'Council Member', 1, NULL, false);
END $$;

-- ---------------------------------------------------------------------------
-- Frisco (FIPS place GEOID: 4827684)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_gov_id     UUID;
  v_chamber_id UUID;
BEGIN
  INSERT INTO essentials.governments (name, type, state, city, geo_id)
  VALUES ('City of Frisco, Texas, US', 'LOCAL', 'TX', NULL, '4827684')
  RETURNING id INTO v_gov_id;

  INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, slug, policy_engagement_level, website_url)
  VALUES (v_gov_id, 'City Council', 'Frisco City Council', 7, 'frisco-city-council', 'full', 'https://www.friscotexas.gov/102/City-Council')
  RETURNING id INTO v_chamber_id;

  INSERT INTO essentials.offices (chamber_id, title, representing_city, representing_state, normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_chamber_id, 'Mayor',                 'Frisco', 'TX', 'Mayor',          1, NULL, false),
    (v_chamber_id, 'Council Member Place 1', 'Frisco', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 2', 'Frisco', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 3', 'Frisco', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 4', 'Frisco', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 5', 'Frisco', 'TX', 'Council Member', 1, NULL, false),
    (v_chamber_id, 'Council Member Place 6', 'Frisco', 'TX', 'Council Member', 1, NULL, false);
END $$;

COMMIT;
