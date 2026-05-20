-- Migration 183: Maine 2026 Elections Foundation
-- Phase 55 Plan 01 — ME 2026 Elections + Discovery Pipeline
--
-- DEVIATION NOTE: Originally planned as migration 182, but
-- 182_drop_legacy_civic_spaces_views.sql already exists (unapplied).
-- Renumbered to 183 to avoid filename collision.
--
-- SOS VERIFICATION (2026-05-20): Candidate data verified against
-- Maine SOS official xlsx "2026 Primary Candidate List posting FINAL 3.16.26"
-- and Non-Party Candidate List (5/18/2026 posting).
--
-- Governor: 5D + 8R = 13 total primary candidates (research estimated 5D+4R=9 — CORRECTED)
--   R candidates confirmed: Bush, Charles, Jones, Libby, Mason, McCarthy, Midgley, Wessels
-- US Senate: Collins (R), Costello (D), Platner (D) — Mills WITHDREW 2026-04-30 (after 3/16 xlsx)
--   NOTE: Plan mentioned Calabrese + Smeriglio as R challengers but NEITHER appears in SOS xlsx
--   or non-party candidate list — excluded per SOS-only policy
-- CD1 (CG Dist=1): Pingree (D, incumbent), Pietrowicz (R), Russell (R)
-- CD2 (CG Dist=2): Baldacci (D), Dunlap (D), LePage (R), Loud (D), Wood (D) — OPEN SEAT
--
-- DEFERRED: D primary winners for US Senate, CD1, CD2 general race rows require
-- a follow-up migration after June 9, 2026 primary results.
--
-- Schema notes:
--   - election_method lives on essentials.chambers (NOT on essentials.races)
--   - essentials.discovery_jurisdictions has NO cron_active column (date-based horizon only)
--   - races unique index: (election_id, position_name) WHERE primary_party IS NULL
--   - race_candidates has no unique constraint — use WHERE NOT EXISTS for idempotency

-- ============================================================
-- SECTION 1: Election rows
-- ============================================================

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Maine State Primary', '2026-06-09', 'primary', 'state', 'ME')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2026 Maine General Election', '2026-11-03', 'general', 'state', 'ME')
ON CONFLICT (name, election_date, state) DO NOTHING;

INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
VALUES ('2027 Portland Municipal Election', '2027-11-02', 'general', 'city', 'ME')
ON CONFLICT (name, election_date, state) DO NOTHING;

-- ============================================================
-- SECTION 2: Discovery jurisdictions
-- (no cron_active column — eligibility is date-based, 180-day horizon)
-- ============================================================

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('23', 'State of Maine', 'ME', '2026-06-09',
   'https://www.maine.gov/sos/elections-voting/upcoming-elections',
   ARRAY['maine.gov', 'legislature.maine.gov', 'ballotpedia.org'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('23', 'State of Maine', 'ME', '2026-11-03',
   'https://www.maine.gov/sos/elections-voting/upcoming-elections',
   ARRAY['maine.gov', 'legislature.maine.gov', 'ballotpedia.org'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

INSERT INTO essentials.discovery_jurisdictions
  (jurisdiction_geoid, jurisdiction_name, state, election_date, source_url, allowed_domains)
VALUES
  ('2360545', 'City of Portland, Maine', 'ME', '2027-11-02',
   'https://www.portlandmaine.gov/172/Elections-Voting',
   ARRAY['portlandmaine.gov', 'ballotpedia.org'])
ON CONFLICT (jurisdiction_geoid, election_date) DO NOTHING;

-- ============================================================
-- SECTION 3: Statewide races and candidates
-- ============================================================

DO $$
DECLARE
  v_primary_id UUID;
  v_general_id  UUID;
  v_race        UUID;
BEGIN

  -- Fetch election IDs by name+state (never hardcode UUIDs)
  SELECT id INTO v_primary_id
    FROM essentials.elections
   WHERE name = '2026 Maine State Primary' AND state = 'ME';

  SELECT id INTO v_general_id
    FROM essentials.elections
   WHERE name = '2026 Maine General Election' AND state = 'ME';

  -- --------------------------------------------------------
  -- GOVERNOR (open seat — Mills term-limited)
  -- --------------------------------------------------------

  -- Governor primary race
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_primary_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230001),
    'Governor of Maine',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_primary_id
       AND position_name = 'Governor of Maine'
       AND primary_party IS NULL;
  END IF;

  -- Governor primary candidates (5D + 8R = 13 — SOS verified 2026-05-20)
  -- Democrats
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Shenna Bellows') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race,
            (SELECT id FROM essentials.politicians WHERE external_id = -230003),
            'Shenna Bellows', 'Shenna', 'Bellows', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Troy Jackson') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Troy Jackson', 'Troy', 'Jackson', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Angus King III') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Angus King III', 'Angus', 'King', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Hannah Pingree') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Hannah Pingree', 'Hannah', 'Pingree', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Nirav Shah') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Nirav Shah', 'Nirav', 'Shah', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- Republicans (8 total — SOS xlsx confirmed)
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Jonathan Bush') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Jonathan Bush', 'Jonathan', 'Bush', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Robert Charles') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Robert Charles', 'Robert', 'Charles', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'David Jones') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'David Jones', 'David', 'Jones', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'James Libby') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'James Libby', 'James', 'Libby', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Garrett Mason') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Garrett Mason', 'Garrett', 'Mason', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Owen McCarthy') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Owen McCarthy', 'Owen', 'McCarthy', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Benjamin Midgley') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Benjamin Midgley', 'Benjamin', 'Midgley', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Robert Wessels') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Robert Wessels', 'Robert', 'Wessels', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- Governor general race (empty — primary winner TBD)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_general_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230001),
    'Governor of Maine',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  -- --------------------------------------------------------
  -- US SENATE (Collins R incumbent up for re-election 2026)
  -- DEFERRED: D primary winner (Costello or Platner) to be added post-June-9
  -- --------------------------------------------------------

  -- US Senate primary race
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_primary_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230101),
    'U.S. Senate Maine',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_primary_id
       AND position_name = 'U.S. Senate Maine'
       AND primary_party IS NULL;
  END IF;

  -- US Senate primary candidates
  -- Collins (R, incumbent)
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Susan M. Collins') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race,
            (SELECT id FROM essentials.politicians WHERE external_id = -230101),
            'Susan M. Collins', 'Susan', 'Collins', true, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- D challengers (Mills NOT included — withdrew 2026-04-30)
  -- NOTE: Calabrese and Smeriglio do not appear in SOS primary or non-party lists — excluded
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'David Costello') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'David Costello', 'David', 'Costello', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Graham Platner') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Graham Platner', 'Graham', 'Platner', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- US Senate general race (Collins only — D winner TBD post-June-9)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_general_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230101),
    'U.S. Senate Maine',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_general_id
       AND position_name = 'U.S. Senate Maine'
       AND primary_party IS NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Susan M. Collins') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race,
            (SELECT id FROM essentials.politicians WHERE external_id = -230101),
            'Susan M. Collins', 'Susan', 'Collins', true, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- --------------------------------------------------------
  -- ME-01 (Chellie Pingree D incumbent; contested R primary)
  -- DEFERRED: R primary winner (Pietrowicz or Russell) to be added to general post-June-9
  -- --------------------------------------------------------

  -- ME-01 primary race
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_primary_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230201),
    'U.S. House ME-01',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_primary_id
       AND position_name = 'U.S. House ME-01'
       AND primary_party IS NULL;
  END IF;

  -- ME-01 primary candidates
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Chellie Pingree') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race,
            (SELECT id FROM essentials.politicians WHERE external_id = -230201),
            'Chellie Pingree', 'Chellie', 'Pingree', true, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Ronald Russell') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Ronald Russell', 'Ronald', 'Russell', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Joshua Pietrowicz') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Joshua Pietrowicz', 'Joshua', 'Pietrowicz', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- ME-01 general race (Pingree only — R primary winner TBD post-June-9)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_general_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230201),
    'U.S. House ME-01',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_general_id
       AND position_name = 'U.S. House ME-01'
       AND primary_party IS NULL;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Chellie Pingree') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race,
            (SELECT id FROM essentials.politicians WHERE external_id = -230201),
            'Chellie Pingree', 'Chellie', 'Pingree', true, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- --------------------------------------------------------
  -- ME-02 (OPEN SEAT — Jared Golden NOT running; all is_incumbent=false)
  -- DEFERRED: Primary winners (D + R) to be added to general post-June-9
  -- office_id references Golden's former office (reused for the race row)
  -- --------------------------------------------------------

  -- ME-02 primary race
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_primary_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230202),
    'U.S. House ME-02',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING
  RETURNING id INTO v_race;

  IF v_race IS NULL THEN
    SELECT id INTO v_race FROM essentials.races
     WHERE election_id = v_primary_id
       AND position_name = 'U.S. House ME-02'
       AND primary_party IS NULL;
  END IF;

  -- ME-02 primary candidates (all is_incumbent=false — open seat)
  -- Democrats
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Matt Dunlap') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Matt Dunlap', 'Matt', 'Dunlap', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Jordan Wood') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Jordan Wood', 'Jordan', 'Wood', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Joe Baldacci') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Joe Baldacci', 'Joe', 'Baldacci', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Paige Loud') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Paige Loud', 'Paige', 'Loud', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- Republican (uncontested primary)
  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE race_id = v_race AND full_name = 'Paul LePage') THEN
    INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
    VALUES (v_race, NULL, 'Paul LePage', 'Paul', 'LePage', false, 'filed',
            'https://www.maine.gov/sos/elections-voting/upcoming-elections');
  END IF;

  -- ME-02 general race (empty — primary winners TBD post-June-9)
  INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
  VALUES (
    v_general_id,
    (SELECT o.id FROM essentials.offices o
       JOIN essentials.politicians p ON p.id = o.politician_id
      WHERE p.external_id = -230202),
    'U.S. House ME-02',
    NULL,
    1
  )
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

END $$;
