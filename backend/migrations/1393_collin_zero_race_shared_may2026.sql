-- =============================================================================
-- Migration 1393: Collin County TX shared-cycle zero-race city seeding
-- Blue Ridge (4808872), Farmersville (4825488), Nevada (4850760), Van Alstyne (4874924)
-- (Phase 219 Plan 02 — elections-candidates-backfill)
--
-- Seeds essentials.races + essentials.race_candidates for the 4 shared-2026-05-02-cycle
-- zero-race cities identified in 219-PREFLIGHT.md §4. Resolves the shared '2026 Texas
-- Municipal General' election by (name, election_date, state) — never hardcodes the literal
-- election UUID as an INSERT target (RESEARCH Pattern 1).
--
-- RESEARCH CORRECTION (re-verified live 2026-07-24, this migration): 219-PREFLIGHT.md
-- characterized Blue Ridge Mayor (Rhonda Williams) and Council Member Place 1 (David Apple)
-- as "contested" races. A direct fetch of the OFFICIAL Collin County "May 2, 2026 Joint
-- General and Special Election — Summary Results Report — All Races" (19 pages, every
-- jurisdiction with a countable ballot that day, down to single-digit-vote MUD elections)
-- shows Blue Ridge is ABSENT ENTIRELY from the report — the identical absence pattern
-- independently confirmed for Farmersville and Nevada, both of which publish their own
-- city-level "election cancelled — unopposed" notices for 2026-05-02. Texas Election Code
-- cancels an entire jurisdiction's ballot only when every race on it is unopposed. Blue
-- Ridge's total absence from a report that includes even 1-2-vote special-district races is
-- strong affirmative evidence its May 2026 election was likewise fully uncontested, not
-- "contested, retained" as PREFLIGHT assumed from an earlier, less-verified pass. No
-- independent citation of an opponent for Williams, Apple, or Chitwood was found this
-- session (direct fetch of blueridgecity.com/elections's own document library) or by Phase
-- 218's prior research despite direct effort. All 3 Blue Ridge seats are therefore seeded
-- here as D-03 single-candidate declared-elected (RESEARCH Pattern 4), NOT as contested
-- multi-candidate races (Pattern 3).
--
-- Van Alstyne's Mayor race (Atchison 399-71 over Soucie) IS seeded as genuinely contested:
-- that result carries an independent secondary-source citation with an actual vote count
-- (KTEN news; Ballotpedia candidate pages for both Atchison and Soucie, per migration 1389),
-- uncorrelated with the Collin canvass. Van Alstyne straddles the Collin/Grayson county
-- line and plausibly certifies through Grayson County, which would explain its own absence
-- from the Collin-only report without contradicting the KTEN/Ballotpedia vote-count
-- citation. Van Alstyne Place 6 (Zach Williams) carries only a generic "elected...in 2026"
-- citation (city's own bio page, per migration 1390) with no opponent/vote-count found — it
-- is seeded here as D-03 single-candidate declared-elected, matching Williams replacing the
-- previously-stubbed Angelica Pena (is_incumbent = false, new to this seat).
--
-- Documented race-less seats this migration deliberately does NOT seed (no confirmed
-- 2026-05-02 election found — left honestly race-less per D-06 no-fabrication):
--   Blue Ridge Places 2/3/4 (Braly/Sissom/Mattingly) — confirmed via direct fetch of
--     blueridgecity.com/council (2026-07-24): all three list "Term ends May 2027" — a
--     2-year staggered term NOT up in the May 2026 cycle.
--   Farmersville Mayor, Place 2, Place 4, Place 5 — farmersvilletx.com/city-secretary/
--     page/elections explicitly states only Strickland (Place 1) and Mondy (Place 3) filed
--     for the (cancelled) May 2026 ballot; the other 4 seats were not up this cycle.
--   Nevada Places 3, 4, 5 (Wilson/Laughter/Little) — cityofnevadatx.org/government/
--     elections.php states verbatim: "Council Member Positions 3, 4, and 5 are elected in
--     odd-numbered years" (last elected 2025, term expires 2027 per the same page's table)
--     — not up in the 2026-05-02 cycle.
--   Van Alstyne Places 1-5 — no citation of a 2026-05-02 (or any) election found this
--     session for these 5 seats; remains [OPEN] per PREFLIGHT, deferred to a future
--     reconcile phase.
--
-- Idempotent: races via ON CONFLICT (election_id, position_name) WHERE primary_party IS
-- NULL DO NOTHING (migration 044's real partial-unique constraint); candidates via
-- WHERE NOT EXISTS (race_id, full_name) guard. D-06 antipartisan: primary_party NULL on
-- every race. D-07: zero inform.* writes (verified by the apply-script's before/after gate).
-- position_name is city-prefixed throughout (RESEARCH Pitfall 3).
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_election_id UUID;
  v_office_id   UUID;
  v_race        UUID;
  v_politician  UUID;
BEGIN
  SELECT id INTO v_election_id FROM essentials.elections
   WHERE name = '2026 Texas Municipal General' AND election_date = '2026-05-02' AND state = 'TX';

  IF v_election_id IS NULL THEN
    RAISE EXCEPTION 'Migration 1393: shared 2026-05-02 TX election row not found — aborting';
  END IF;

  -- ============================================================
  -- NEVADA (geo_id 4850760) — Mayor, Place 1, Place 2: all unopposed, declared elected.
  -- Source: cityofnevadatx.org/government/city_council.php (current roster, verbatim titles);
  -- cityofnevadatx.org/government/elections.php ("Cancellation of May 2, 2026, General
  -- Election" document referenced; term-expires table confirms Mayor/Place1/Place2 = 2026).
  -- ============================================================

  -- Nevada Mayor — Donald Deering (retained/re-elected, unopposed)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4850760' AND o.title = 'Mayor';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Nevada Mayor', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Nevada Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Donald Deering', 'Donald', 'Deering', true, 'active', 'cityofnevadatx.org/government/city_council.php'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Donald Deering');

  -- Nevada Council Member Place 1 — Mike Laye (retained/re-elected, unopposed)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 1';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Nevada Council Member Place 1', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Nevada Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Mike Laye', 'Mike', 'Laye', true, 'active', 'cityofnevadatx.org/government/city_council.php'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Mike Laye');

  -- Nevada Council Member Place 2 — Paul Baker (retained/re-elected, unopposed)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4850760' AND o.title = 'Council Member Place 2';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Nevada Council Member Place 2', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Nevada Council Member Place 2';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Paul Baker', 'Paul', 'Baker', true, 'active', 'cityofnevadatx.org/government/city_council.php'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Paul Baker');

  -- ============================================================
  -- FARMERSVILLE (geo_id 4825488) — Place 1, Place 3: both unopposed, declared elected.
  -- Mayor/Place 2/Place 4/Place 5 NOT seeded (not on this cycle's ballot — see header).
  -- Source: farmersvilletx.com/city-secretary/page/elections (live-fetched 2026-07-24:
  -- "The May 2, 2026 City General Election has been cancelled. Incumbents Coleman
  -- Strickland (CC Place 1) and Kristi Mondy (CC Place 3) are the only applicants...").
  -- ============================================================

  -- Farmersville Council Member Place 1 — Coleman Strickland (incumbent, unopposed)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 1';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Farmersville Council Member Place 1', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Farmersville Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Coleman Strickland', 'Coleman', 'Strickland', true, 'active', 'farmersvilletx.com/city-secretary/page/elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Coleman Strickland');

  -- Farmersville Council Member Place 3 — Kristi Mondy (incumbent, unopposed)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4825488' AND o.title = 'Council Member Place 3';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Farmersville Council Member Place 3', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Farmersville Council Member Place 3';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Kristi Mondy', 'Kristi', 'Mondy', true, 'active', 'farmersvilletx.com/city-secretary/page/elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Kristi Mondy');

  -- ============================================================
  -- BLUE RIDGE (geo_id 4808872) — Mayor, Place 1, Place 5: all uncontested, declared
  -- elected (see RESEARCH CORRECTION in header — supersedes PREFLIGHT's "contested" claim).
  -- Places 2/3/4 NOT seeded (confirmed "Term ends May 2027" — off-cycle this election).
  -- Source: blueridgecity.com/elections (live-fetched 2026-07-24: "Seats open: Mayor, 2
  -- At-Large Council Seats"; current-council table shows Williams/Apple's terms + one
  -- "Open Seat" all expiring May 2026, i.e. the 3 seats actually contested this cycle);
  -- absence from the official Collin County May 2, 2026 canvass (all 19 pages) as
  -- corroborating evidence of zero opposition.
  -- ============================================================

  -- Blue Ridge Mayor — Rhonda Williams (retained/re-elected, uncontested)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4808872' AND o.title = 'Mayor';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Blue Ridge Mayor', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Blue Ridge Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Rhonda Williams', 'Rhonda', 'Williams', true, 'active', 'blueridgecity.com/elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Rhonda Williams');

  -- Blue Ridge Council Member Place 1 — David Apple (retained/re-elected, uncontested)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 1';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Blue Ridge Council Member Place 1', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Blue Ridge Council Member Place 1';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'David Apple', 'David', 'Apple', true, 'active', 'blueridgecity.com/elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'David Apple');

  -- Blue Ridge Council Member Place 5 — Keith Chitwood (new; this was the "Open Seat" per
  -- blueridgecity.com/elections — genuinely vacant going into the election, uncontested)
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4808872' AND o.title = 'Council Member Place 5';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Blue Ridge Council Member Place 5', 1, NULL, 'Declared elected — unopposed (open seat)')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Blue Ridge Council Member Place 5';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Keith Chitwood', 'Keith', 'Chitwood', false, 'active', 'blueridgecity.com/elections'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Keith Chitwood');

  -- ============================================================
  -- VAN ALSTYNE (geo_id 4874924) — Mayor (contested, cited vote count) + Place 6
  -- (uncontested, generic election citation). Places 1-5 NOT seeded (no citation found).
  -- ============================================================

  -- Van Alstyne Mayor — Jim Atchison defeated Kevin Soucie, 399-71 (retained/re-elected)
  -- Source: KTEN news; Ballotpedia candidate pages for both Atchison and Soucie (per
  -- migration 1389's own citation of this same result).
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4874924' AND o.title = 'Mayor';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Van Alstyne Mayor', 1, NULL, 'Atchison defeated Soucie, 399-71')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Van Alstyne Mayor';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Jim Atchison', 'Jim', 'Atchison', true, 'active', 'KTEN news; Ballotpedia (Jim Atchison, Van Alstyne Mayor 2026 candidate page)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Jim Atchison');

  INSERT INTO essentials.race_candidates (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, 'Kevin Soucie', 'Kevin', 'Soucie', false, 'active', 'KTEN news; Ballotpedia (Kevin Soucie, Van Alstyne Mayor 2026 candidate page)'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Kevin Soucie');

  -- Van Alstyne Council Member Place 6 — Zach Williams (new; replaces stubbed Angelica
  -- Pena; no opponent/vote-count citation found — seeded as declared-elected uncontested)
  -- Source: cityofvanalstyne.us/council official bio text "Zach Williams was elected to
  -- City Council Place 6 in 2026" (per migration 1390's own direct-fetch citation).
  SELECT o.id INTO v_office_id FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
    JOIN essentials.governments g ON g.id = ch.government_id
   WHERE g.geo_id = '4874924' AND o.title = 'Council Member Place 6';

  INSERT INTO essentials.races (election_id, office_id, position_name, seats, primary_party, description)
  VALUES (v_election_id, v_office_id, 'Van Alstyne Council Member Place 6', 1, NULL, 'Declared elected — unopposed')
  ON CONFLICT (election_id, position_name) WHERE primary_party IS NULL DO NOTHING;

  SELECT r.id INTO v_race FROM essentials.races r WHERE r.election_id = v_election_id AND r.position_name = 'Van Alstyne Council Member Place 6';
  SELECT o.politician_id INTO v_politician FROM essentials.offices o WHERE o.id = v_office_id;

  INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
  SELECT v_race, v_politician, 'Zach Williams', 'Zach', 'Williams', false, 'active', 'cityofvanalstyne.us/council'
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = v_race AND rc.full_name = 'Zach Williams');

END $$;

COMMIT;
