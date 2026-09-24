-- CA_0269_phase167_seed_missing_house_candidates.sql
--
-- Slot CA_0269 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Phase 167 follow-up (2026 U.S. House). CA_0263 and CA_0266 reconciled five races against the state's
-- certified November field but, under rule 5, left them flagged (provisional_until kept): each certified
-- field holds a candidate we had no row for. This seeds those five people, CA_0233 style, and then — the
-- fields now complete — clears the five races' provisional flags.
--
--   DE At-Large   Joseph "Dr. Joe" Arminio  Republican   the REPUBLICAN NOMINEE (beat Earl Cooper in the
--                                                         2026-09-15 primary). DE Dept. of Elections general
--                                                         candidate list: Qualified 7/14/2026; primary ENR JSON
--                                                         (OFFICIAL RESULTS).
--   NH CD2        Robbie Mahrou             Independent  NH SOS "CANDIDATE LIST W/ ADDRESS - 09/17/2026"
--                                                         (operator download).
--   CT CD1        Mary L. Sanders           Green        CT SOTS November 3 2026 sample ballots (Bloomfield).
--   CT CD3        Thomas Egan               Independent  CT SOTS sample ballots (North Branford, Woodbridge).
--   CT CD4        Benjamin Wesley           Independent  CT SOTS sample ballots (Oxford, Greenwich, Westport).
--
-- BARE politician rows, 1296 / CA_0233 style: name, party, external_id -66000171..-66000175 (the next
-- free numbers in 1296's block at authoring — -66000170 was the last taken; the pre-flight refuses if any
-- is taken by someone else), is_incumbent = false stated explicitly (a candidate — CLAUDE.md),
-- is_active = true. No portrait, bio or stance research; profiles are follow-up work. No active row by
-- these names existed.
--
-- The race_candidates rows are the November general ('active', result 'advanced' — on the certified
-- field — like every nominee CA_0263 / CA_0266 wrote), provisional_until NULL.
--
-- Then the 23 existing rows in these five races: provisional_until -> NULL, last_verified_at -> now().
-- Their results (written by CA_0263 / CA_0266) are unchanged. This is what rule 5 was holding back.
--
-- CI: new politicians carry no stance rows, and no existing row's candidate_status changes, so the
-- stance-sources buckets cannot move (the #719 / #762 failure mode). Every prod-reading CI check was run
-- locally before and after the apply.
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS, the flag clear by provisional_until IS NOT NULL.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the five race_candidates rows whose source ends 'added by CA_0269
--   (2026-09-24)'; DELETE the politicians with external_id -66000171..-66000175 (after confirming nothing
--   else references them); restore provisional_until on the 23 rows (DE 2026-09-15, NH 2026-09-08,
--   CT 2026-08-12).

BEGIN;

CREATE TEMP TABLE ca0269_new ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000171::bigint, 'Joseph', 'Arminio',  'Joseph "Dr. Joe" Arminio', 'Republican', 'DE', 'U.S. Representative At-Large',
   'Delaware Department of Elections, 2026 General Election candidate list (elections.delaware.gov/candidates/candidatelist/genl_fcddt_2026.html, 2026-09-24): Representative in Congress, Republican, Qualified 7/14/2026; won the 2026-09-15 Republican primary over Earl L. Cooper (ENR JSON, OFFICIAL RESULTS)'),
  (-66000172::bigint, 'Robbie',  'Mahrou',  'Robbie Mahrou',            'Independent', 'NH', 'U.S. Representative District 2',
   'New Hampshire Secretary of State, "CANDIDATE LIST W/ ADDRESS - 09/17/2026" (2026 general; downloaded by the operator 2026-09-24): Representative in Congress District 2, IND'),
  (-66000173::bigint, 'Mary',    'Sanders', 'Mary L. Sanders',          'Green',       'CT', 'U.S. Representative District 1',
   'Connecticut Secretary of the State, November 3 2026 State Election sample ballots (portal.ct.gov/sots/election-services/town-ballots/2026-november-town-election-ballots): Representative in Congress District 1, Green Party (Bloomfield)'),
  (-66000174::bigint, 'Thomas',  'Egan',    'Thomas Egan',              'Independent', 'CT', 'U.S. Representative District 3',
   'Connecticut Secretary of the State, November 3 2026 State Election sample ballots: Representative in Congress District 3, Independent Party (North Branford, Woodbridge)'),
  (-66000175::bigint, 'Benjamin','Wesley',  'Benjamin Wesley',          'Independent', 'CT', 'U.S. Representative District 4',
   'Connecticut Secretary of the State, November 3 2026 State Election sample ballots: Representative in Congress District 4, Independent Party (Oxford, Greenwich, Westport)')
) AS v(ext, first_name, last_name, full_name, party, st, position_name, source);

-- The five races, and the live count each must hold afterwards (existing nominees + the new person).
CREATE TEMP TABLE ca0269_race ON COMMIT DROP AS
SELECT x.st, x.position_name, ra.id AS race_id, x.expect
  FROM (VALUES ('DE','U.S. Representative At-Large',2), ('NH','U.S. Representative District 2',3),
               ('CT','U.S. Representative District 1',3), ('CT','U.S. Representative District 3',3),
               ('CT','U.S. Representative District 4',3)) AS x(st, position_name, expect)
  JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0269_race;
  IF n <> 5 THEN RAISE EXCEPTION 'PRE: resolved % of 5 races (duplicate or missing race row?)', n; END IF;

  -- Each race: every existing row already reconciled (CA_0263 / CA_0266) and nothing else unreviewed.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0269_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.politician_id NOT IN (SELECT p.id FROM essentials.politicians p JOIN ca0269_new x ON x.ext = p.external_id);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows in these races carry no result — not reconciled', n; END IF;
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0269_race r ON r.race_id = rc.race_id
   WHERE rc.result_source NOT LIKE '%CA_0263%' AND rc.result_source NOT LIKE '%CA_0266%'
     AND rc.source NOT LIKE '%added by CA_0269 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows in these races were not reconciled by CA_0263 / CA_0266', n; END IF;

  -- No existing row, active or not, carries one of these names in its race (no duplicate person).
  SELECT count(*) INTO n FROM ca0269_new x JOIN ca0269_race r ON r.st = x.st AND r.position_name = x.position_name
    JOIN essentials.race_candidates rc ON rc.race_id = r.race_id AND rc.last_name = x.last_name
   WHERE rc.source NOT LIKE '%added by CA_0269 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the five already have a row in their race', n; END IF;

  -- The external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0269_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source IS DISTINCT FROM ('CA_0269 (2026-09-24): ' || x.source);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000171..-66000175 are taken by someone else', n; END IF;

  RAISE NOTICE 'CA_0269 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The five people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true, 'CA_0269 (2026-09-24): ' || x.source, 'manual'
  FROM ca0269_new x
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. Their November candidacies — on the certified field, so 'advanced', no provisional flag.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source, result, result_source, result_recorded_at,
                                        last_verified_at)
SELECT r.race_id, p.id, x.full_name, x.first_name, x.last_name, false, 'active',
       x.source || '; added by CA_0269 (2026-09-24)', 'advanced',
       x.source || '. On the certified November field; seeded by CA_0269 (2026-09-24).', now(), now()
  FROM ca0269_new x
  JOIN ca0269_race r ON r.st = x.st AND r.position_name = x.position_name
  JOIN essentials.politicians p ON p.external_id = x.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- 3. The fields are complete: clear the five races' provisional flags (rule 5 released).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET provisional_until = NULL, last_verified_at = now(), updated_at = now()
  FROM ca0269_race r
 WHERE rc.race_id = r.race_id AND rc.provisional_until IS NOT NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0269_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 5 THEN RAISE EXCEPTION 'POST: % of 5 new people are active non-incumbents on exactly one race', n; END IF;

  FOR r IN
    SELECT c.st, c.position_name, c.expect,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.provisional_until IS NOT NULL) AS flagged
      FROM ca0269_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: % % has % live candidates, expected %', r.st, r.position_name, r.got, r.expect; END IF;
    IF r.flagged <> 0 THEN RAISE EXCEPTION 'POST: % % still has % flagged rows', r.st, r.position_name, r.flagged; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0269 applied: 5 certified House candidates seeded; DE, NH CD2, CT CD1/CD3/CD4 now complete and unflagged';
END $$;

COMMIT;
