-- =============================================================================
-- Migration 073: Long Beach June 2, 2026 races + discovery jurisdiction
--
-- Seeds the nine races on the Long Beach June 2, 2026 Primary Nominating
-- Election ballot and adds Long Beach to discovery_jurisdictions so the
-- candidate discovery agent will sweep it.
--
-- Races seeded:
--   Citywide (4):  Mayor, City Attorney, City Auditor, City Prosecutor
--   Council (5):   Districts 1, 3, 5, 7, 9  (odd-district cycle)
--
-- Council office_id values map to existing Councilmember office rows whose
-- politician_id is the current incumbent:
--   D1 → Mary Zendejas    (d2aed8fa-a298-41a4-8b98-d0a37bc5345f)
--   D3 → Kristina Duggan  (907083c7-6489-4c10-9752-1b762f3a048d)
--   D5 → Megan Kerr       (8056a370-9051-45b6-a10d-274b3bd5824d)
--   D7 → Roberto Uranga   (25554450-2a42-4072-bfbd-b637fb4e1412)
--   D9 → Joni Ricks-Oddie (9061b93f-cf6b-44f2-a6db-f26f61af7a6a)
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id   UUID := '1ebca37f-cf96-47f4-bc2b-47ef266721fe'; -- 2026 LA County Primary
  v_mayor_id      UUID;
  v_attorney_id   UUID;
  v_auditor_id    UUID;
  v_prosecutor_id UUID;
BEGIN

  -- Citywide offices (none existed for Long Beach before this migration)
  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('Mayor', 'Long Beach', 'CA', 'Mayor', 1)
  RETURNING id INTO v_mayor_id;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Attorney', 'Long Beach', 'CA', 'City Attorney', 1)
  RETURNING id INTO v_attorney_id;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Auditor', 'Long Beach', 'CA', 'City Auditor', 1)
  RETURNING id INTO v_auditor_id;

  INSERT INTO essentials.offices (title, representing_city, representing_state, normalized_position_name, seats)
  VALUES ('City Prosecutor', 'Long Beach', 'CA', 'City Prosecutor', 1)
  RETURNING id INTO v_prosecutor_id;

  -- Citywide races
  INSERT INTO essentials.races (election_id, office_id, position_name, seats) VALUES
    (v_election_id, v_mayor_id,      'Long Beach Mayor',           1),
    (v_election_id, v_attorney_id,   'Long Beach City Attorney',   1),
    (v_election_id, v_auditor_id,    'Long Beach City Auditor',    1),
    (v_election_id, v_prosecutor_id, 'Long Beach City Prosecutor', 1);

  -- Council district races
  INSERT INTO essentials.races (election_id, office_id, position_name, seats) VALUES
    (v_election_id, 'd2aed8fa-a298-41a4-8b98-d0a37bc5345f', 'Long Beach City Council District 1', 1),
    (v_election_id, '907083c7-6489-4c10-9752-1b762f3a048d', 'Long Beach City Council District 3', 1),
    (v_election_id, '8056a370-9051-45b6-a10d-274b3bd5824d', 'Long Beach City Council District 5', 1),
    (v_election_id, '25554450-2a42-4072-bfbd-b637fb4e1412', 'Long Beach City Council District 7', 1),
    (v_election_id, '9061b93f-cf6b-44f2-a6db-f26f61af7a6a', 'Long Beach City Council District 9', 1);

END $$;

-- Discovery jurisdiction
INSERT INTO essentials.discovery_jurisdictions (
  jurisdiction_geoid,
  jurisdiction_name,
  state,
  election_date,
  source_url,
  allowed_domains
) VALUES (
  '0643000',
  'Long Beach',
  'CA',
  '2026-06-02',
  'https://www.longbeach.gov/cityclerk/elections/candidates-home/',
  ARRAY['longbeach.gov', 'ballotpedia.org']
);

COMMIT;
