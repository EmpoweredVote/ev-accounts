-- CA_0276_phase167_seed_vt_wy_va_house_candidates.sql
--
-- Slot CA_0276 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Phase 167 follow-up, same shape as CA_0269. Chris Cantrell's 1854 (VT), 1857 (WY) and 1859 (VA-07)
-- deliberately left their races flagged (rule 5) because each state's certified November field holds
-- candidates we had no row for. VA-04 has the same defect and 1859 named it but did not flag it: its
-- REPUBLICAN NOMINEE is missing, and our field carries a name the certified list does not.
-- This seeds the nine missing people, records the remaining results, and clears the four races' flags.
--
--   VT At-Large  + Phoenix K. Altair, Suzanne "Suz" Seymour, Ryan P. Walton (all Independent)
--                  Adam Ortiz (I, no primary) -> advanced.   Balint, Malloy already advanced.
--                  Source: VT SOS "2026 General Election qualified candidates" (outside.vermont.gov/dept/
--                  sos/Elections_Division/election_info_resources/candidates/2026_general_election_
--                  qualified_candidates.xlsx; created 2026-09-23), REPRESENTATIVE TO CONGRESS: 6 names.
--   WY At-Large  + Jeffrey A. Haggit (Constitution)
--                  Shawn Johnson (Libertarian) -> advanced.   Gray, Kinney already advanced.
--                  Source: WY SOS 2026_WY_General_Election_Candidates.csv, UNITED STATES REPRESENTATIVE.
--   VA-07        + Taner E. Demirci Lopez (Libertarian), Alaha Ahrar (Independent), Joshua E. Ertle (Independent)
--                  Vindman, Ollivant, Terry -> advanced.
--   VA-04        + Robert P. "Family Man" Murray, Jr. (Republican — THE NOMINEE), Joan E. "Andrews" Bell (Independent)
--                  McClellan -> advanced.  Jason Brown II -> not_nominated (not on the certified list;
--                  1859: "Brown" occurs zero times).
--                  Source (both VA): VA ELECT "2026 November Federal Offices Candidate List (rev 9-14-2026)".
--
-- BARE politician rows, CA_0233 / CA_0269 style: external_id -66000311..-66000319 (the next free numbers
-- in 1296's block at authoring — -66000310 was the last taken; the pre-flight refuses if any is taken by
-- someone else), is_incumbent = false stated explicitly, is_active = true. No active row by these names
-- existed. Their November rows are 'active' / 'advanced', provisional_until NULL.
--
-- CI: no candidate_status changes; new people have no stance rows, so stance-sources buckets cannot move.
-- Every prod-reading CI check is run before and after the apply.
--
-- IDEMPOTENT: inserts by NOT EXISTS; updates guarded on result IS NULL; flag clear on IS NOT NULL.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the nine race_candidates rows whose source ends 'added by CA_0276
--   (2026-09-24)' and the politicians -66000311..-66000319; set result/result_source NULL on rows whose
--   result_source ends 'Recorded by CA_0276 (2026-09-24).'; restore provisional_until 2026-09-18 on the
--   VT, WY and VA-07 rows it cleared.

BEGIN;

CREATE TEMP TABLE ca0276_new ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000311::bigint, 'Phoenix', 'Altair',        'Phoenix K. Altair',                  'Independent', 'VT', 'U.S. Representative At-Large'),
  (-66000312::bigint, 'Suzanne', 'Seymour',       'Suzanne "Suz" Seymour',              'Independent', 'VT', 'U.S. Representative At-Large'),
  (-66000313::bigint, 'Ryan',    'Walton',        'Ryan P. Walton',                     'Independent', 'VT', 'U.S. Representative At-Large'),
  (-66000314::bigint, 'Jeffrey', 'Haggit',        'Jeffrey A. Haggit',                  'Constitution','WY', 'U.S. Representative At-Large'),
  (-66000315::bigint, 'Taner',   'Demirci Lopez', 'Taner E. Demirci Lopez',             'Libertarian', 'VA', 'U.S. House VA-07'),
  (-66000316::bigint, 'Alaha',   'Ahrar',         'Alaha Ahrar',                        'Independent', 'VA', 'U.S. House VA-07'),
  (-66000317::bigint, 'Joshua',  'Ertle',         'Joshua E. Ertle',                    'Independent', 'VA', 'U.S. House VA-07'),
  (-66000318::bigint, 'Robert',  'Murray',        'Robert P. "Family Man" Murray, Jr.', 'Republican',  'VA', 'U.S. House VA-04'),
  (-66000319::bigint, 'Joan',    'Bell',          'Joan E. "Andrews" Bell',             'Independent', 'VA', 'U.S. House VA-04')
) AS v(ext, first_name, last_name, full_name, party, st, position_name);

CREATE TEMP TABLE ca0276_src ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('VT', 'Vermont Secretary of State, 2026 General Election qualified candidates (outside.vermont.gov/dept/sos/Elections_Division/election_info_resources/candidates/2026_general_election_qualified_candidates.xlsx, created 2026-09-23), REPRESENTATIVE TO CONGRESS: Altair, Balint, Malloy, Ortiz, Seymour, Walton'),
  ('WY', 'Wyoming Secretary of State, 2026_WY_General_Election_Candidates.csv (sos.wyo.gov/Elections/Docs/2026/), UNITED STATES REPRESENTATIVE: Gray (REP), Kinney (DEM), Johnson (LBR), Haggit (CT)'),
  ('VA', 'Virginia Department of Elections, "2026 November Federal Offices Candidate List (rev 9-14-2026)" (elections.virginia.gov/casting-a-ballot/candidate-list/november-3-2026-gen-elect-federal-offices/)')
) AS v(st, source);

CREATE TEMP TABLE ca0276_race ON COMMIT DROP AS
SELECT x.st, x.position_name, ra.id AS race_id, x.expect
  FROM (VALUES ('VT','U.S. Representative At-Large',6), ('WY','U.S. Representative At-Large',4),
               ('VA','U.S. House VA-07',6), ('VA','U.S. House VA-04',3)) AS x(st, position_name, expect)
  JOIN essentials.elections e ON e.state = x.st AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- Existing rows that still need a result (by id + name, each with its disposition).
CREATE TEMP TABLE ca0276_upd ON COMMIT DROP AS
SELECT * FROM (VALUES
  ('c222836d-9e05-44aa-9f0f-cbae96567338'::uuid, 'VT', 'Adam Ortiz',         'advanced'),
  ('e13d3830-ffdc-4257-96b3-387a16f8b660'::uuid, 'WY', 'Shawn Johnson',      'advanced'),
  ('434a0c71-40a7-471d-9b76-29b8b63be9c1'::uuid, 'VA', 'Eugene Vindman',     'advanced'),
  ('7a859705-1f47-44ce-81f3-913c0d841bdc'::uuid, 'VA', 'Doug Ollivant',      'advanced'),
  ('44005981-fcc5-49f9-8a5c-dfd94cdb68d2'::uuid, 'VA', 'Randall Terry',      'advanced'),
  ('750255ac-fcfc-46fa-b738-014a2bd48b4a'::uuid, 'VA', 'Jennifer McClellan', 'advanced'),
  ('6bf39e15-ec62-4a85-8b6f-6fcc3ee49c99'::uuid, 'VA', 'Jason Brown II',     'not_nominated')
) AS v(rc_id, st, full_name, result);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0276_race;
  IF n <> 4 THEN RAISE EXCEPTION 'PRE: resolved % of 4 races', n; END IF;

  -- The update rows are in these races, and untouched or already written by this file.
  SELECT count(*) INTO n FROM ca0276_upd u
    JOIN essentials.race_candidates rc ON rc.id = u.rc_id AND rc.full_name = u.full_name
    JOIN ca0276_race r ON r.race_id = rc.race_id AND r.st = u.st
   WHERE rc.result IS NULL OR (rc.result = u.result AND rc.result_source LIKE '%Recorded by CA_0276 (2026-09-24).');
  IF n <> 7 THEN RAISE EXCEPTION 'PRE: only % of 7 existing rows are as authored', n; END IF;

  -- Nothing else in these races lacks a result.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0276_race r ON r.race_id = rc.race_id
   WHERE rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.id NOT IN (SELECT rc_id FROM ca0276_upd)
     AND coalesce(rc.source, '') NOT LIKE '%added by CA_0276 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % unreviewed rows in these races', n; END IF;

  -- None of the nine already has a row in its race.
  SELECT count(*) INTO n FROM ca0276_new x JOIN ca0276_race r ON r.st = x.st AND r.position_name = x.position_name
    JOIN essentials.race_candidates rc ON rc.race_id = r.race_id AND rc.last_name = x.last_name
   WHERE coalesce(rc.source, '') NOT LIKE '%added by CA_0276 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the nine already have a row in their race', n; END IF;

  -- The external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0276_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source NOT LIKE 'CA_0276 (2026-09-24):%';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000311..-66000319 are taken by someone else', n; END IF;

  RAISE NOTICE 'CA_0276 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The nine people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true, 'CA_0276 (2026-09-24): ' || s.source, 'manual'
  FROM ca0276_new x JOIN ca0276_src s ON s.st = x.st
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. Their November candidacies — on the certified field.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, source, result, result_source, result_recorded_at,
                                        last_verified_at)
SELECT r.race_id, p.id, x.full_name, x.first_name, x.last_name, false, 'active',
       s.source || '; added by CA_0276 (2026-09-24)', 'advanced',
       s.source || '. On the certified November field; seeded by CA_0276 (2026-09-24).', now(), now()
  FROM ca0276_new x
  JOIN ca0276_src s ON s.st = x.st
  JOIN ca0276_race r ON r.st = x.st AND r.position_name = x.position_name
  JOIN essentials.politicians p ON p.external_id = x.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- 3. The existing rows' results.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = u.result,
       result_source      = s.source || '. ' || u.full_name || ': '
                            || CASE WHEN u.result = 'advanced' THEN 'on the certified November field'
                                    ELSE 'NOT on the certified November field' END
                            || '. Recorded by CA_0276 (2026-09-24).',
       result_recorded_at = now(),
       last_verified_at   = now(),
       updated_at         = now()
  FROM ca0276_upd u JOIN ca0276_src s ON s.st = u.st
 WHERE rc.id = u.rc_id AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- 4. The four fields are complete: clear their flags (rule 5 released).
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET provisional_until = NULL, last_verified_at = now(), updated_at = now()
  FROM ca0276_race r
 WHERE rc.race_id = r.race_id AND rc.provisional_until IS NOT NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0276_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 9 THEN RAISE EXCEPTION 'POST: % of 9 new people are active non-incumbents on exactly one race', n; END IF;

  SELECT count(*) INTO n FROM ca0276_upd u JOIN essentials.race_candidates rc ON rc.id = u.rc_id
   WHERE rc.result = u.result AND rc.result_source LIKE '%Recorded by CA_0276 (2026-09-24).';
  IF n <> 7 THEN RAISE EXCEPTION 'POST: % of 7 existing rows carry their result', n; END IF;

  FOR r IN
    SELECT c.st, c.position_name, c.expect,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.provisional_until IS NOT NULL) AS flagged,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.result IS NULL AND rc.candidate_status <> 'withdrawn') AS unresolved
      FROM ca0276_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: % % has % live candidates, expected %', r.st, r.position_name, r.got, r.expect; END IF;
    IF r.flagged <> 0 THEN RAISE EXCEPTION 'POST: % % still has % flagged rows', r.st, r.position_name, r.flagged; END IF;
    IF r.unresolved <> 0 THEN RAISE EXCEPTION 'POST: % % still has % rows without a result', r.st, r.position_name, r.unresolved; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0276 applied: 9 certified House candidates seeded; VT, WY, VA-04, VA-07 complete and unflagged';
END $$;

COMMIT;
