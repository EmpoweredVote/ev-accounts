-- Migration 1216: Arm candidate discovery for the west-metro 2026 election — 8 discovery_jurisdictions
--
-- Phase 185-03 (v20.0 WashCo 2026 Elections & Discovery, Plan 03). Seeds 8 discovery_jurisdictions rows
-- (Washington County + 7 west-metro cities) so the date-based cron (180-day horizon before election_date)
-- keeps finding candidates from official OR/WashCo sources. School boards are NOT armed (D-05).
--
-- NUMBERING: Plan 01 BASE=1213 (races), Plan 02 = 1215 (candidates; counter drifted — a parallel IN
--   workstream took 1213/1214). Live max at write time = 1215, 1216 free → this migration is 1216.
--
-- CASING (Pitfall 5): discovery_jurisdictions.state = 'OR' UPPERCASE (char(2), matches NV/VA/MD), which is
--   a DIFFERENT convention than essentials.districts.state ('or' lowercase). Do not conflate.
--
-- SOURCE URLs (D-06 resilience): the county's own candidate-filing sub-page 403s, so Washington County
--   uses the sos.oregon.gov Candidate-Filings-Local-Measures fallback in source_url with the county page +
--   ballotpedia.org in allowed_domains (the discovery agent navigates hub pages a raw scraper cannot).
--   Per-city source_url uses each city's own confirmed election page. Reachability re-checked 2026-07-04:
--     - Cornelius /385/Elections-2024 302-redirects to the live /385/Elections-2026 → use the resolved URL.
--     - Hillsboro root + sub-paths are WAF-403 to curl; root domain is used as source_url (agent-navigable),
--       hillsboro-oregon.gov stays in allowed_domains.
--
-- Idempotent via ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING (the ONE table in this phase
--   with a real unique index for this). NO BEGIN/COMMIT wrap and NO schema_migrations ledger INSERT
--   (matches 1113 family — do NOT copy 325/281's ledger tail).

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('41067', 'Washington County, Oregon', 'OR', '2026-11-03',
   'https://sos.oregon.gov/elections/Pages/Candidate-Filings-Local-Measures.aspx',
   ARRAY['sos.oregon.gov','washingtoncountyor.gov','ballotpedia.org']),
  ('4105350', 'Beaverton, Oregon', 'OR', '2026-11-03',
   'https://beavertonoregon.gov/944/Elections',
   ARRAY['beavertonoregon.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4134100', 'Hillsboro, Oregon', 'OR', '2026-11-03',
   'https://www.hillsboro-oregon.gov/',
   ARRAY['hillsboro-oregon.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4173650', 'Tigard, Oregon', 'OR', '2026-11-03',
   'https://www.tigard-or.gov/your-government/council/election',
   ARRAY['tigard-or.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4174950', 'Tualatin, Oregon', 'OR', '2026-11-03',
   'https://tualatinoregon.gov/city-council/elections/',
   ARRAY['tualatinoregon.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4126200', 'Forest Grove, Oregon', 'OR', '2026-11-03',
   'https://www.forestgrove-or.gov/362/Elections',
   ARRAY['forestgrove-or.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4167100', 'Sherwood, Oregon', 'OR', '2026-11-03',
   'https://www.sherwoodoregon.gov/elections',
   ARRAY['sherwoodoregon.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org']),
  ('4115550', 'Cornelius, Oregon', 'OR', '2026-11-03',
   'https://www.corneliusor.gov/385/Elections-2026',
   ARRAY['corneliusor.gov','washingtoncountyor.gov','sos.oregon.gov','ballotpedia.org'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

-- Post-verification: exactly 8 west-metro OR rows; 0 school-board jurisdictions armed (D-05).
DO $$
DECLARE
  v_count INT;
  v_school INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.discovery_jurisdictions
  WHERE state = 'OR' AND election_date = '2026-11-03'
    AND jurisdiction_geoid IN ('41067','4105350','4134100','4173650','4174950','4126200','4167100','4115550');
  IF v_count <> 8 THEN
    RAISE EXCEPTION 'Expected 8 west-metro OR discovery_jurisdictions rows, found %', v_count;
  END IF;

  -- Negative (D-05): none of the 5 west-metro G5420 school-board geo_ids are armed.
  SELECT COUNT(*) INTO v_school
  FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid IN ('4101920','4105160','4100023','4111290','4112240');
  IF v_school <> 0 THEN
    RAISE EXCEPTION 'Found % armed school-board discovery_jurisdictions (D-05 says 0)', v_school;
  END IF;

  RAISE NOTICE 'OK: 8 west-metro OR discovery_jurisdictions rows present, 0 school boards armed';
END $$;

-- NO schema_migrations ledger INSERT (matches 1113 pattern — on-disk counter authoritative)
