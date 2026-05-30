-- Migration 074: Update Long Beach discovery source_url to Ballotpedia
--
-- The original source_url pointed to the LB clerk's landing page which links
-- to a PDF — the agent can't read it and returns candidates without district
-- numbers. Ballotpedia has district-specific candidate listings and is already
-- in allowed_domains.

UPDATE essentials.discovery_jurisdictions
SET source_url = 'https://ballotpedia.org/City_elections_in_Long_Beach,_California_(2026)'
WHERE jurisdiction_name = 'Long Beach'
  AND election_date = '2026-06-02';
