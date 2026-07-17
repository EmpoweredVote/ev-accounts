-- Migration 1376: AZ 2026 discovery_jurisdictions arming
-- Phase 199 (AZ 2026 Elections & Discovery), Plan 04.
--
-- Seeds 4 essentials.discovery_jurisdictions rows: {statewide FIPS 04, Pima County 04019}
-- x {primary 2026-07-21, general 2026-11-03}, each with the curated 5-domain AZ election-
-- authority allowlist. Arming is date-window driven (the cron eligible-izes any row whose
-- election_date is inside the 180-day window) -- there is no arming flag column.
--
-- Primary date is 2026-07-21 (HB 2022) -- NOT 2026-08-04.
--
-- Idempotent via WHERE NOT EXISTS on (jurisdiction_geoid, election_date) -- the table has no
-- unique constraint on that pair, so ON CONFLICT is not usable here.

INSERT INTO essentials.discovery_jurisdictions (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
SELECT v.geoid, v.name, 'AZ', v.edate::date, v.url,
       ARRAY['azsos.gov', 'azcleanelections.gov', 'pima.gov', 'recorder.pima.gov', 'ballotpedia.org']
FROM (VALUES
  ('04',    'State of Arizona',     '2026-07-21', 'https://azsos.gov/elections'),
  ('04',    'State of Arizona',     '2026-11-03', 'https://azsos.gov/elections'),
  ('04019', 'Pima County, Arizona', '2026-07-21', 'https://www.pima.gov/394/Elections'),
  ('04019', 'Pima County, Arizona', '2026-11-03', 'https://www.pima.gov/394/Elections')
) AS v(geoid, name, edate, url)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.discovery_jurisdictions dj
  WHERE dj.jurisdiction_geoid = v.geoid AND dj.election_date = v.edate::date
);

-- Post-verify: 4 AZ rows across the two geoids, each with a 5-element allowlist and a valid date.
DO $$
DECLARE
  v_rows  int;
  v_baddomain int;
  v_baddate int;
BEGIN
  SELECT COUNT(*) INTO v_rows FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid IN ('04', '04019') AND state = 'AZ';
  IF v_rows <> 4 THEN RAISE EXCEPTION 'Migration 1376: expected 4 AZ discovery rows, got %', v_rows; END IF;

  SELECT COUNT(*) INTO v_baddomain FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid IN ('04', '04019') AND state = 'AZ'
    AND COALESCE(array_length(allowed_domains, 1), 0) <> 5;
  IF v_baddomain <> 0 THEN RAISE EXCEPTION 'Migration 1376: % AZ rows with allowlist length <> 5', v_baddomain; END IF;

  SELECT COUNT(*) INTO v_baddate FROM essentials.discovery_jurisdictions
  WHERE jurisdiction_geoid IN ('04', '04019') AND state = 'AZ'
    AND election_date NOT IN (DATE '2026-07-21', DATE '2026-11-03');
  IF v_baddate <> 0 THEN RAISE EXCEPTION 'Migration 1376: % AZ rows with unexpected election_date', v_baddate; END IF;
END $$;

INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('1376') ON CONFLICT (version) DO NOTHING;
