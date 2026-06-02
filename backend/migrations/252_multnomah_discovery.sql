-- Migration 252: Multnomah County discovery_jurisdictions row — Phase 85 Plan 02
-- Adds geo_id='41051' (Multnomah County) discovery row for OR 2026 General election
-- Covers county commissioner races + all 5 smaller city races (Multnomah County Elections administers all)
-- Cron arms automatically when election_date is within 180-day window (no activation flag column exists)

INSERT INTO essentials.discovery_jurisdictions
  (id, jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
SELECT
  gen_random_uuid(), '41051', 'Multnomah County, Oregon', 'OR', '2026-11-03',
  'https://www.multco.us/elections',
  ARRAY['multco.us', 'ballotpedia.org', 'sos.oregon.gov']
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid = '41051' AND election_date = '2026-11-03'
);

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('252')
ON CONFLICT (version) DO NOTHING;
