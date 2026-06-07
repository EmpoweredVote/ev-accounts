-- Migration 281: MD 2026 Discovery Jurisdictions — Phase 96 Plan 03
--
-- Seeds 2 rows into essentials.discovery_jurisdictions for Maryland's 2026 election cycle.
-- One row per election_date: primary (2026-06-23) + general (2026-11-03).
--
-- D-03: essentials.discovery_jurisdictions has NO cron_active column — eligibility is
-- date-based (180-day cron window before election_date). ROADMAP wording 'cron_active=true'
-- for MD-ELECTIONS-02 is stale and ignored.
--
-- D-04: Landing.jsx edit is co-deployed (NOT in this SQL file) — see src/pages/Landing.jsx.
--
-- Idempotent via ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING.
-- Both election dates are within the 180-day cron eligibility window as of 2026-06-06:
--   - Primary 2026-06-23: ~17 days out (cron agent will pick this up immediately)
--   - General 2026-11-03: ~150 days out (well within 180-day window)

-- ============================================================
-- SECTION 1: Discovery jurisdictions
-- (no cron_active column — eligibility is date-based, 180-day horizon)
-- ============================================================

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('24', 'State of Maryland', 'MD', '2026-06-23',
   'https://elections.maryland.gov/elections/2026/primary_candidates/index.html',
   ARRAY['elections.maryland.gov', 'mgaleg.maryland.gov', 'ballotpedia.org', 'maryland.gov'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('24', 'State of Maryland', 'MD', '2026-11-03',
   'https://elections.maryland.gov/elections/2026/primary_candidates/index.html',
   ARRAY['elections.maryland.gov', 'mgaleg.maryland.gov', 'ballotpedia.org', 'maryland.gov'])
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
  WHERE state = 'MD';
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Expected 2 MD discovery_jurisdictions rows, found %', v_count;
  END IF;
END $$;

-- ============================================================
-- SECTION 3: Supabase migration ledger entry
-- ============================================================
INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('281')
ON CONFLICT (version) DO NOTHING;
