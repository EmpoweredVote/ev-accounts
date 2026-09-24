-- CA_0252_primary_followup_cleanups.sql
--
-- Slot CA_0252 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Three small follow-ups left open by the 2026 primary passes (CA_0222, CA_0231, CA_0243). Each is
-- independent; each is guarded on its pre-image.
--
-- ===========================================================================================
-- 1. ALASKA — the two U.S. Senate primary rows CA_0231 held (Leslie, Heikes)
-- ===========================================================================================
--   CA_0231 held them because the count and the ballot disagreed: Leslie placed 4th (1,850) in the
--   top-four primary but is NOT on the certified general list; Heikes placed 5th (1,741) and IS. Only
--   news explained it. The state's own law does:
--     AS 15.25.100(a): the four candidates receiving the greatest number of votes go on the general
--       ballot.
--     AS 15.25.100(c): "if a candidate nominated at the primary election ... withdraws ... after the
--       primary election and 64 or more days before the general election, the vacancy shall be filled
--       by the director by replacing the withdrawn candidate with the candidate who received the fifth
--       most votes in the primary election."  (akleg.gov/basis/statutes.asp, Sec. 15.25.100)
--   With the Division of Elections' certified general list (elections.alaska.gov/candidates/
--   ?election=26genr: Heikes, Peltola, Dan S. Sullivan, Daniel J. Sullivan Jr., each "(Certified)")
--   and its stated post-primary withdrawal deadline (5:00pm Monday, August 31, 2026 — 64 days before
--   November 3), the only reading consistent with state records is: Leslie was nominated (4th) and
--   left the ballot; Heikes, the fifth-place finisher, was placed on it under (c).
--     Leslie -> 'advanced'  (true of the primary: he was one of the four nominated)
--     Heikes -> 'advanced'  (placed on the general ballot under AS 15.25.100(c))
--   The primary rows' candidate_status is not touched. Leslie has no general-race row (CA_0233 built the
--   AK general race from the certified list), so nothing else needs closing.
--
-- ===========================================================================================
-- 2. WISCONSIN AD9 (R) — our "Samuel Guerreo" is WEC's "Sam Guerrero"
-- ===========================================================================================
--   The WEC certified canvass (CA_0243's source) prints "Sam Guerrero", 597 votes, winner. Our
--   race_candidates row AND its politician row (6dd861ce, source-seeded, not manually overridden, on one
--   race) both carry the misspelling. Corrected to "Sam Guerrero" in both, guarded on the exact old value
--   and on full_name_manual_override = false.
--
-- ===========================================================================================
-- 3. GARY CROCKETT (LA-D Senate 2026) — the fec_senate link CA_0222 noted as missing
-- ===========================================================================================
--   FEC candidate S6LA00680, "CROCKETT, GARY", DEM, LA, Senate, election_years [2026], first Form 2
--   received 2026-02-26 — the only FEC candidate by that surname for a Louisiana Senate seat in 2026
--   (FEC /v1/candidates/?state=LA&office=S&election_year=2026, fetched 2026-09-24). CA_0222 used this
--   Form 2 date as his candidacy term_start but wrote no link. Inserted as 'confirmed' in the notes
--   shape the FEC research pass uses ("Confirmed: <NAME> — Senate, <ST>, <Party> (...)"). He remains
--   is_active = false (unchanged).
--
-- IDEMPOTENT: every write is guarded. Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one
-- transaction, then rolled back and re-read.
-- ROLLBACK (once applied): (1) SET result/result_source/result_recorded_at NULL on the two AK rows whose
--   result_source ends 'CA_0252 (2026-09-24).'; (2) set the two names back to 'Samuel Guerreo' / last name
--   'Guerreo'; (3) DELETE the S6LA00680 politician_sources row whose notes end 'CA_0252 (2026-09-24)'.

BEGIN;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  -- 1. The two AK rows: the held U.S. Senate primary rows, untouched or already written by this file.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name = 'U.S. Senate Alaska'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'primary'
                               AND e.state = 'AK' AND e.election_date = '2026-08-18'
   WHERE rc.id IN ('ede2e633-b0c0-45f6-8c54-488b5198bbbf', '645b941b-9a77-4479-87c5-1857699cd7d0')
     AND rc.full_name IN ('David B. Leslie', 'Gerald L. Heikes')
     AND (rc.result IS NULL OR (rc.result = 'advanced' AND rc.result_source LIKE '%CA_0252 (2026-09-24).'));
  IF n <> 2 THEN RAISE EXCEPTION 'PRE: % of 2 Alaska rows are the held Leslie / Heikes primary rows', n; END IF;

  -- 2. Guerrero: the WI AD9 R primary row and its politician, misspelled (first run) or fixed (re-run).
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name = 'Assembly District 9'
                            AND ra.primary_party = 'Republican'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.state = 'WI' AND e.election_date = '2026-08-11'
    JOIN essentials.politicians p ON p.id = rc.politician_id AND NOT p.full_name_manual_override
   WHERE rc.id = '8e7beb57-66f3-47c6-a44d-5a3d3a4b74b8' AND p.id = '6dd861ce-da11-4a5f-9716-648d7fe80b2a'
     AND rc.full_name IN ('Samuel Guerreo', 'Sam Guerrero') AND p.full_name IN ('Samuel Guerreo', 'Sam Guerrero');
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: the WI AD9 R Guerreo/Guerrero row is not as authored'; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE politician_id = '6dd861ce-da11-4a5f-9716-648d7fe80b2a';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: politician 6dd861ce is on % races, expected 1', n; END IF;

  -- 3. Crockett: the right person, and no FEC link yet except (re-run) this file's.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1'
                   AND full_name = 'Gary Crockett' AND party = 'Democratic') THEN
    RAISE EXCEPTION 'PRE: politician 1c6f7914 is not Gary Crockett (D)';
  END IF;
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1'
     AND NOT (source_system = 'fec_senate' AND external_id = 'S6LA00680' AND notes LIKE '%CA_0252 (2026-09-24)');
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: Crockett already has % other source row(s) — review', n; END IF;
  -- No one else holds S6LA00680.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE external_id = 'S6LA00680' AND essentials_politician_id <> '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: S6LA00680 is already linked to another politician'; END IF;

  RAISE NOTICE 'CA_0252 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. Alaska: Leslie and Heikes both advanced (AS 15.25.100(a) and (c)).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = 'advanced',
       result_source      = v.src,
       result_recorded_at = '2026-09-24T00:00:00Z'
  FROM (VALUES
    ('ede2e633-b0c0-45f6-8c54-488b5198bbbf'::uuid,
     'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (enr26/results), '
     '"U.S. Senator", top-four: Leslie 1,850, 4th — nominated under AS 15.25.100(a). He is absent from the Division''s '
     'certified general list (elections.alaska.gov/candidates/?election=26genr, updated 2026-09-02); under AS '
     '15.25.100(c) a nominee who withdraws by the 64th day before the general (the Division''s deadline: 2026-08-31) '
     'is replaced by the fifth-place finisher, and Heikes (5th) is certified in his place. Recorded by CA_0252 (2026-09-24).'),
    ('645b941b-9a77-4479-87c5-1857699cd7d0'::uuid,
     'Alaska Division of Elections, 2026 PRIMARY ELECTION Election Summary Report, OFFICIAL RESULTS (enr26/results), '
     '"U.S. Senator", top-four: Heikes 1,741, 5th. Certified on the general ballot (elections.alaska.gov/candidates/'
     '?election=26genr) under AS 15.25.100(c), which fills a withdrawn nominee''s place with "the candidate who received '
     'the fifth most votes in the primary election" — here, in place of David B. Leslie (4th). Recorded by CA_0252 (2026-09-24).')
  ) AS v(rc_id, src)
 WHERE rc.id = v.rc_id AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- 2. Wisconsin AD9 R: Samuel Guerreo -> Sam Guerrero (WEC certified canvass spelling).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates
   SET full_name = 'Sam Guerrero', first_name = 'Sam', last_name = 'Guerrero', updated_at = now()
 WHERE id = '8e7beb57-66f3-47c6-a44d-5a3d3a4b74b8' AND full_name = 'Samuel Guerreo';

UPDATE essentials.politicians
   SET full_name = 'Sam Guerrero', first_name = 'Sam', last_name = 'Guerrero'
 WHERE id = '6dd861ce-da11-4a5f-9716-648d7fe80b2a' AND full_name = 'Samuel Guerreo' AND NOT full_name_manual_override;

-- ---------------------------------------------------------------------------
-- 3. Crockett: confirmed fec_senate link.
-- ---------------------------------------------------------------------------
INSERT INTO transparent_motivations.politician_sources
       (essentials_politician_id, source_system, external_id, research_status, notes)
SELECT '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1', 'fec_senate', 'S6LA00680', 'confirmed',
       'Confirmed: CROCKETT, GARY — Senate, LA, Democratic (2026); the only 2026 LA Senate FEC candidate by that '
       'name; Form 2 received 2026-02-26. Linked by CA_0252 (2026-09-24)'
 WHERE NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources
                    WHERE essentials_politician_id = '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1'
                      AND source_system = 'fec_senate' AND external_id = 'S6LA00680');

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM essentials.race_candidates
   WHERE id IN ('ede2e633-b0c0-45f6-8c54-488b5198bbbf', '645b941b-9a77-4479-87c5-1857699cd7d0')
     AND result = 'advanced' AND result_source LIKE '%CA_0252 (2026-09-24).' AND candidate_status = 'filed';
  IF n <> 2 THEN RAISE EXCEPTION 'POST: % of 2 Alaska rows advanced', n; END IF;
  -- No Alaska Senate primary row is left without a result.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.state = 'AK' AND e.election_type = 'primary' AND ra.position_name = 'U.S. Senate Alaska' AND rc.result IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % Alaska Senate primary rows still NULL', n; END IF;
  -- Top-four: exactly five 'advanced' (four nominated + one replacement).
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.state = 'AK' AND e.election_type = 'primary' AND ra.position_name = 'U.S. Senate Alaska' AND rc.result = 'advanced';
  IF n <> 5 THEN RAISE EXCEPTION 'POST: % advanced in the AK Senate primary, expected 5', n; END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.race_candidates WHERE id = '8e7beb57-66f3-47c6-a44d-5a3d3a4b74b8'
                   AND full_name = 'Sam Guerrero' AND last_name = 'Guerrero')
     OR NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '6dd861ce-da11-4a5f-9716-648d7fe80b2a'
                   AND full_name = 'Sam Guerrero' AND last_name = 'Guerrero') THEN
    RAISE EXCEPTION 'POST: Guerrero name not corrected on both rows';
  END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1' AND source_system = 'fec_senate'
     AND external_id = 'S6LA00680' AND research_status = 'confirmed';
  IF n <> 1 THEN RAISE EXCEPTION 'POST: % Crockett fec_senate rows, expected 1', n; END IF;
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '1c6f7914-7475-4bb6-bd15-1ebfb933c6c1' AND is_active) THEN
    RAISE EXCEPTION 'POST: Crockett became active — this file must not change is_active';
  END IF;

  RAISE NOTICE 'CA_0252 applied: AK Leslie + Heikes advanced; Guerrero name fixed; Crockett fec_senate linked';
END $$;

COMMIT;
