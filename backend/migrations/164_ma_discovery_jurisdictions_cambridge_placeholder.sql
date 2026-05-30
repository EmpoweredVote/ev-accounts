-- Migration 164: MA discovery_jurisdictions + 2027 Cambridge placeholder
-- Phase 44 Plan 03 — MA 2026 Elections discovery rows + Cambridge 2027 placeholder
--
-- Schema confirmed:
--   essentials.discovery_jurisdictions columns: id, jurisdiction_geoid, jurisdiction_name,
--     state (char 2), election_date, source_url, allowed_domains (text[]), created_at, updated_at
--   Unique index: idx_discovery_jurisdictions_geoid_date UNIQUE (jurisdiction_geoid, election_date)
--
--   essentials.elections unique: (name, election_date, state)
--
-- Idempotent: all inserts use ON CONFLICT DO NOTHING

-- ============================================================
-- Part A: MA state-level discovery_jurisdictions rows
-- jurisdiction_geoid='25' is the FIPS code for Commonwealth of Massachusetts
-- ============================================================

-- 1a. MA state primary — election_date='2026-09-01'
INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('25', 'Commonwealth of Massachusetts', 'MA', '2026-09-01',
   'https://www.sec.state.ma.us/divisions/elections/elections-and-voting.htm',
   ARRAY['sec.state.ma.us', 'ballotpedia.org', 'malegislature.gov'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

-- 1b. MA state general — election_date='2026-11-03'
INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('25', 'Commonwealth of Massachusetts', 'MA', '2026-11-03',
   'https://www.sec.state.ma.us/divisions/elections/elections-and-voting.htm',
   ARRAY['sec.state.ma.us', 'ballotpedia.org', 'malegislature.gov'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

-- ============================================================
-- Part B: 2027 Cambridge Municipal Election placeholder
-- election_date='2027-11-02' — first Tuesday after first Monday in November 2027
--   (Nov 1, 2027 = Monday → Nov 2, 2027 = first Tuesday after first Monday)
-- This is intentionally far future; outside 180-day cron horizon until ~May 2027
-- ============================================================

-- 2. 2027 Cambridge Municipal Election row in essentials.elections
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2027 Cambridge Municipal Election', '2027-11-02', 'general', 'city', 'MA')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- 3. Cambridge discovery_jurisdictions row for 2027
-- jurisdiction_geoid='2511000' — Cambridge city G4110 FIPS place code (confirmed Phase 38)
-- election_date='2027-11-02' — intentionally outside 180-day cron horizon from any 2026 run date
-- NOTE: DO NOT add a 2026 row for '2511000' — Cambridge's next election is 2027
INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('2511000', 'City of Cambridge', 'MA', '2027-11-02',
   'https://www.cambridgema.gov/residents/votingandelectionsinfo',
   ARRAY['cambridgema.gov', 'cambridgecivic.com', 'ballotpedia.org'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;
