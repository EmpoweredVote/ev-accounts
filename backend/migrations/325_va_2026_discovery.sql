-- Migration 325: VA 2026 Discovery Jurisdictions — Phase 105 Plan 03
--
-- Seeds 2 rows into essentials.discovery_jurisdictions for Virginia's 2026 election cycle.
-- One row per election_date: primary (2026-08-04) + general (2026-11-03).
--
-- D-03: essentials.discovery_jurisdictions has NO cron_active column — eligibility is
-- date-based (180-day cron window before election_date). Follows MD Phase 96 lesson.
--
-- Both VA election dates are within the 180-day cron eligibility window as of 2026-06-09:
--   - Primary 2026-08-04: ~56 days out (cron agent will pick this up immediately)
--   - General 2026-11-03: ~147 days out (well within 180-day window)
--
-- jurisdiction_geoid='51' is the VA FIPS state code (2-digit bare code, matching MD pattern
-- which uses '24' for Maryland — not '5100000' or any other variant).
--
-- Source rationale:
--   - ballotpedia.org: canonical multi-race index for VA federal races (1 Senate + 11 House)
--   - vpap.org: Virginia Public Access Project — VA-equivalent of mgaleg.maryland.gov
--     (finance/candidate data, race-by-race detail)
--   - elections.virginia.gov: Official Virginia State Board of Elections site
--   - virginia.gov: Catch-all for official VA government domain
--
-- Idempotent via ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING.

-- ============================================================
-- SECTION 1: Discovery jurisdictions
-- (no cron_active column — eligibility is date-based, 180-day horizon)
-- ============================================================

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('51', 'Commonwealth of Virginia', 'VA', '2026-08-04',
   'https://ballotpedia.org/United_States_Congress_elections_in_Virginia,_2026',
   ARRAY['ballotpedia.org', 'vpap.org', 'elections.virginia.gov', 'virginia.gov'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('51', 'Commonwealth of Virginia', 'VA', '2026-11-03',
   'https://ballotpedia.org/United_States_Congress_elections_in_Virginia,_2026',
   ARRAY['ballotpedia.org', 'vpap.org', 'elections.virginia.gov', 'virginia.gov'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

-- ============================================================
-- SECTION 2: Post-verification
-- ============================================================

DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM essentials.discovery_jurisdictions
  WHERE state = 'VA';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Expected 2 VA discovery_jurisdictions rows, found %', v_count;
  END IF;
END $$;

-- ============================================================
-- SECTION 3: Supabase migration ledger entry
-- ============================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('325')
ON CONFLICT (version) DO NOTHING;
