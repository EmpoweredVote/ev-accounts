-- Migration 1113: NV 2026 Discovery Jurisdictions — Phase 167 Plan 03
--
-- Seeds 1 row into essentials.discovery_jurisdictions for Nevada's 2026 general election.
-- General only — the June 9 2026 primary is past (D-02).
--
-- D-05: essentials.discovery_jurisdictions has NO cron_active column — eligibility is
-- date-based (180-day cron window before election_date).
-- Nov 3 2026 general is ~127 days out as of 2026-06-29 — inside the 180-day window.
--
-- jurisdiction_geoid='32' is the Nevada FIPS state code (2-digit bare code, matching
-- MD='24' / VA='51' pattern — not '3200000' or any other variant).
--
-- Source rationale:
--   - ballotpedia.org: canonical multi-race index for NV general election (VA precedent)
--     nvsos.gov returns HTTP 403 to automated fetches (D-04), so Ballotpedia is primary.
--   - nvsos.gov: Official Nevada Secretary of State — in allowed_domains so agent citations
--     score as confidence='official' even if pre-fetch fails and agent finds URL via web_search.
--   - nevada.gov: Official Nevada state government domain catch-all.
--   - leg.state.nv.us: Official Nevada Legislature — candidate/legislator data source.
--
-- Idempotent via ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING.
-- NO schema_migrations ledger INSERT (D-08: matches 1109 pattern — on-disk counter authoritative).

-- ============================================================
-- SECTION 1: Discovery jurisdiction row (NV 2026 general)
-- (no cron_active column — eligibility is date-based, 180-day horizon)
-- ============================================================

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('32', 'State of Nevada', 'NV', '2026-11-03',
   'https://ballotpedia.org/Nevada_elections,_2026',
   ARRAY['ballotpedia.org', 'nvsos.gov', 'nevada.gov', 'leg.state.nv.us'])
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
  WHERE state = 'NV';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'Expected 1 NV discovery_jurisdictions row, found %', v_count;
  END IF;
  RAISE NOTICE 'OK: 1 NV discovery_jurisdictions row present (geoid=32, date=2026-11-03)';
END $$;

-- NO schema_migrations ledger INSERT (D-08: matches 1109 pattern)
