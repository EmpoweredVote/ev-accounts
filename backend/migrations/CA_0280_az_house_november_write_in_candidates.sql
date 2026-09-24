-- CA_0280_az_house_november_write_in_candidates.sql
--
-- Slot CA_0280 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Seeds the seven registered November write-in candidates that CA_0278 deliberately left out of
-- Arizona's nine U.S. House races. Ruling 2026-09-24 (Chris Andrews): add them, and mark them as
-- write-ins on Essentials. The mark is race_candidates.is_write_in (CA_0279).
--
-- Source: Arizona Secretary of State, 2026 General Election candidate list
--   (apps.arizona.vote/electioninfo/Election/69, Federal tab; captured by the operator 2026-09-24).
--   Each of the seven carries the page's "Write-In Candidate" mark and a nomination paper.
--
--   CD1  Dev Gupta (IND), Gage Dylan Thunder (NON)
--   CD3  Jacob Parkman (REP)
--   CD4  Steven Sanders (NOL)
--   CD6  Michael Dorland (IND)
--   CD9  G. Seville Hatch (IND), William Perry (INDEPENDENT)
--
-- BARE politician rows, 1296 / CA_0276 style: external_id -66000321..-66000327 (the next free numbers
-- in 1296's block at authoring — -66000320 was the last taken; the pre-flight refuses if any is taken
-- by someone else), is_incumbent = false stated explicitly, is_active = true. No politician by any of
-- these names existed. Their race rows: 'active', result 'advanced' (on the certified November field,
-- as every CA_0278 nominee), is_write_in = true, provisional_until NULL.
--
-- DEPLOY ORDER: apply only after CA_0279 AND after the API + Essentials builds that read is_write_in
-- are live. Before that, these seven render as ordinary ballot candidates with no mark.
--
-- CI: new people carry no stance rows; no existing row changes, so stance-sources buckets cannot move.
--
-- IDEMPOTENT: every INSERT is guarded by NOT EXISTS.
-- Dry run: BEGIN; ... ROLLBACK; against prod, applied twice in one transaction, then rolled back and re-read.
-- ROLLBACK (once applied): DELETE the seven race_candidates rows whose source ends 'added by CA_0280
--   (2026-09-24)', then the politicians -66000321..-66000327.

BEGIN;

CREATE TEMP TABLE ca0280_new ON COMMIT DROP AS
SELECT * FROM (VALUES
  (-66000321::bigint, 'Dev',       'Gupta',   'Dev Gupta',          'Independent', 'U.S. Representative District 1', 'GUPTA, DEV (IND)'),
  (-66000322::bigint, 'Gage',      'Thunder', 'Gage Dylan Thunder', 'Independent', 'U.S. Representative District 1', 'THUNDER, GAGE DYLAN (NON)'),
  (-66000323::bigint, 'Jacob',     'Parkman', 'Jacob Parkman',      'Republican',  'U.S. Representative District 3', 'PARKMAN, JACOB (REP)'),
  (-66000324::bigint, 'Steven',    'Sanders', 'Steven Sanders',     'Independent', 'U.S. Representative District 4', 'SANDERS, STEVEN (NOL)'),
  (-66000325::bigint, 'Michael',   'Dorland', 'Michael Dorland',    'Independent', 'U.S. Representative District 6', 'DORLAND, MICHAEL (IND)'),
  (-66000326::bigint, 'G. Seville','Hatch',   'G. Seville Hatch',   'Independent', 'U.S. Representative District 9', 'HATCH, G. SEVILLE (IND)'),
  (-66000327::bigint, 'William',   'Perry',   'William Perry',      'Independent', 'U.S. Representative District 9', 'PERRY, WILLIAM (INDEPENDENT)')
) AS v(ext, first_name, last_name, full_name, party, position_name, listed_as);

CREATE TEMP TABLE ca0280_src ON COMMIT DROP AS
SELECT 'Arizona Secretary of State, 2026 General Election candidate list (apps.arizona.vote/electioninfo/Election/69, Federal tab; captured by the operator 2026-09-24)'::text AS gen;

-- The five races, and the live count each must hold afterwards (CA_0278's ballot + write-ins).
CREATE TEMP TABLE ca0280_race ON COMMIT DROP AS
SELECT x.position_name, ra.id AS race_id, x.expect, x.write_ins
  FROM (VALUES ('U.S. Representative District 1',5,2), ('U.S. Representative District 3',4,1),
               ('U.S. Representative District 4',4,1), ('U.S. Representative District 6',5,1),
               ('U.S. Representative District 9',4,2)) AS x(position_name, expect, write_ins)
  JOIN essentials.elections e ON e.state = 'AZ' AND e.election_date = '2026-11-03' AND e.election_type = 'general'
  JOIN essentials.races ra ON ra.election_id = e.id AND ra.position_name = x.position_name;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'essentials' AND table_name = 'race_candidates' AND column_name = 'is_write_in';
  IF n <> 1 THEN RAISE EXCEPTION 'PRE: race_candidates.is_write_in missing — apply CA_0279 first'; END IF;

  SELECT count(*) INTO n FROM ca0280_race;
  IF n <> 5 THEN RAISE EXCEPTION 'PRE: resolved % of 5 AZ House races', n; END IF;

  -- CA_0278 reconciled these races: every row not withdrawn has a result, and none is flagged.
  SELECT count(*) INTO n FROM essentials.race_candidates rc JOIN ca0280_race r ON r.race_id = rc.race_id
   WHERE (rc.result IS NULL AND rc.candidate_status <> 'withdrawn') OR rc.provisional_until IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows in these races are not reconciled (CA_0278 applied?)', n; END IF;

  -- None of the seven already has a row in its race.
  SELECT count(*) INTO n FROM ca0280_new x JOIN ca0280_race r ON r.position_name = x.position_name
    JOIN essentials.race_candidates rc ON rc.race_id = r.race_id AND rc.last_name = x.last_name
   WHERE coalesce(rc.source, '') NOT LIKE '%added by CA_0280 (2026-09-24)';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of the seven already have a row in their race', n; END IF;

  -- The external_ids are free, or hold exactly the person this file created.
  SELECT count(*) INTO n FROM ca0280_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.full_name <> x.full_name OR p.source NOT LIKE 'CA_0280 (2026-09-24):%';
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % of external_ids -66000321..-66000327 are taken by someone else', n; END IF;

  RAISE NOTICE 'CA_0280 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- 1. The seven people.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, party, is_incumbent, is_active,
                                    source, data_source)
SELECT x.ext, x.first_name, x.last_name, x.full_name, x.party, false, true,
       'CA_0280 (2026-09-24): ' || s.gen || ': ' || replace(x.position_name, 'U.S. Representative District ', 'U.S. Representative in Congress - District No. ')
       || ', ' || x.listed_as || ', Write-In Candidate', 'manual'
  FROM ca0280_new x CROSS JOIN ca0280_src s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = x.ext);

-- ---------------------------------------------------------------------------
-- 2. Their November candidacies — registered write-ins.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent,
                                        candidate_status, is_write_in, source, result, result_source,
                                        result_recorded_at, last_verified_at)
SELECT r.race_id, p.id, x.full_name, x.first_name, x.last_name, false, 'active', true,
       s.gen || '; ' || x.listed_as || ', Write-In Candidate; added by CA_0280 (2026-09-24)', 'advanced',
       s.gen || ': ' || x.full_name || ' is a registered November write-in candidate. Seeded by CA_0280 (2026-09-24).',
       now(), now()
  FROM ca0280_new x
  CROSS JOIN ca0280_src s
  JOIN ca0280_race r ON r.position_name = x.position_name
  JOIN essentials.politicians p ON p.external_id = x.ext
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.race_id AND rc.politician_id = p.id);

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int; r record;
BEGIN
  SELECT count(*) INTO n FROM ca0280_new x JOIN essentials.politicians p ON p.external_id = x.ext
   WHERE p.is_active AND NOT p.is_incumbent
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id AND rc.is_write_in) = 1
     AND (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.politician_id = p.id) = 1;
  IF n <> 7 THEN RAISE EXCEPTION 'POST: % of 7 new people are active non-incumbents on exactly one write-in row', n; END IF;

  -- The only write-in rows anywhere are these seven.
  SELECT count(*) INTO n FROM essentials.race_candidates WHERE is_write_in;
  IF n <> 7 THEN RAISE EXCEPTION 'POST: % write-in rows exist, expected 7', n; END IF;

  FOR r IN
    SELECT c.position_name, c.expect, c.write_ins,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND essentials.is_live_candidate(rc.candidate_status, rc.result)) AS got,
           (SELECT count(*) FROM essentials.race_candidates rc
             WHERE rc.race_id = c.race_id AND rc.is_write_in) AS wi
      FROM ca0280_race c
  LOOP
    IF r.got <> r.expect THEN RAISE EXCEPTION 'POST: AZ % has % live candidates, expected %', r.position_name, r.got, r.expect; END IF;
    IF r.wi <> r.write_ins THEN RAISE EXCEPTION 'POST: AZ % has % write-ins, expected %', r.position_name, r.wi, r.write_ins; END IF;
  END LOOP;

  RAISE NOTICE 'CA_0280 applied: 7 AZ House November write-in candidates seeded (is_write_in = true)';
END $$;

COMMIT;
