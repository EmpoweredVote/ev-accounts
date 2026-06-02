-- Migration 241: OR Discovery Jurisdictions — Phase 79 Plan 05
-- D-10: Two rows — OR statewide (FIPS 41) + Portland city (geo_id 4159000)
-- Cron arms rows automatically via election_date window (no activation flag column exists)

INSERT INTO essentials.discovery_jurisdictions
  (id, jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
SELECT
  gen_random_uuid(), '41', 'State of Oregon', 'OR', '2026-11-03',
  'https://sos.oregon.gov/elections/Pages/Candidate-Filings-Local-Measures.aspx',
  ARRAY['sos.oregon.gov', 'oregonlegislature.gov', 'ballotpedia.org']
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid = '41' AND election_date = '2026-11-03'
);

INSERT INTO essentials.discovery_jurisdictions
  (id, jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
SELECT
  gen_random_uuid(), '4159000', 'City of Portland, Oregon', 'OR', '2026-11-03',
  'https://www.portland.gov/auditor/elections',
  ARRAY['portland.gov', 'multco.us', 'ballotpedia.org']
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid = '4159000' AND election_date = '2026-11-03'
);
