BEGIN;

-- =============================================================================
-- CA_0330: record David Scott's past GA-13 term (follow-up to CA_0326)
-- =============================================================================
-- CA_0326 seated Everton Blair Jr. in GA-13 from 2026-09-01. The seat had no earlier term at all, so
-- office_holders_as_of() answers "nobody" for GA-13 on every date before that. Scott held it for 23 years
-- and was never seeded here (there is no politician row for him; bioguide S001157 is absent).
--
-- Facts and sources (read 2026-10-26):
--   * unitedstates/congress-legislators, legislators-historical.json (public domain), bioguide S001157,
--     "David Scott": 12 consecutive House terms for GA-13; first starts 2003-01-07, last runs
--     2025-01-03 .. 2026-04-21.
--   * House Clerk, Vacancies of the 119th Congress: GA-13 "Passed Away April 22, 2026 | Rep. David Scott".
--     The Clerk dates the vacancy, i.e. the first vacant day (as CA_0328 read it), so the term's last day
--     is 2026-04-21 — the same day the dataset gives. The two sources agree.
--
-- Writes:
--   1. One politician, David Scott (external_id -66000424, the next free number in the -66000xxx band),
--      is_incumbent false and is_active false: a former officeholder who died in office (the Scott Smith
--      shape, migration 1796). No party is stored.
--      An ACTIVE, DIFFERENT David Scott exists (508fa6d8, AZ State House candidate, CA_0282), so the name
--      guard is lifted for exactly this insert and turned back off.
--   2. One office_terms row on GA-13: 2003-01-07 .. 2026-04-21, start_precision 'day', how_ended 'died'.
--      term_start follows migration 1536: the first day of the member's current unbroken run of service,
--      from the same dataset. how_started is left NULL, as 1536 did (the dataset says when, not how).
--      It is inserted directly, not through seat_officeholder: that helper writes an open-ended term,
--      which would overlap Blair's.
--
-- Not done: the vacancy span 2026-04-22 .. 2026-08-31 is not written as a NULL-holder term; no other
-- office carries one, and office_holders_as_of already returns nobody for those dates.
-- Idempotent: a re-run inserts nothing and the post-verify passes.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
                  WHERE o.id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e'
                    AND d.district_type = 'NATIONAL_LOWER' AND d.geo_id = '1313') THEN
    RAISE EXCEPTION 'CA_0330: pre-flight — GA-13 office 0d031c4f not found on NATIONAL_LOWER 1313';
  END IF;
  -- -66000424 is free, or already this David Scott (a re-run).
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -66000424 AND bioguide_id IS DISTINCT FROM 'S001157') THEN
    RAISE EXCEPTION 'CA_0330: pre-flight — external_id -66000424 is held by someone else';
  END IF;
  IF EXISTS (SELECT 1 FROM essentials.politicians WHERE bioguide_id = 'S001157' AND external_id IS DISTINCT FROM -66000424) THEN
    RAISE EXCEPTION 'CA_0330: pre-flight — bioguide S001157 already exists under another external_id';
  END IF;
  -- GA-13's only other term is Blair's, from 2026-09-01 (CA_0326).
  IF EXISTS (SELECT 1 FROM essentials.office_terms t
              WHERE t.office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e'
                AND t.politician_id IS DISTINCT FROM '230d1dac-ddbc-472d-9314-89967917eb5a'
                AND t.politician_id IS DISTINCT FROM (SELECT id FROM essentials.politicians WHERE external_id = -66000424)) THEN
    RAISE EXCEPTION 'CA_0330: pre-flight — GA-13 has a term for someone other than Blair or Scott; reconcile first';
  END IF;
END $$;

-- 1. David Scott (guard lifted for this insert only: the active David Scott in Arizona is another person).
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (external_id, first_name, last_name, full_name, bioguide_id,
                                    is_incumbent, is_active, is_appointed, source, data_source)
SELECT -66000424, 'David', 'Scott', 'David Scott', 'S001157',
       false, false, false,
       'CA_0330 (2026-10-26): unitedstates/congress-legislators legislators-historical.json, bioguide S001157 (U.S. Representative, GA-13, 2003-01-07 .. 2026-04-21); House Clerk Vacancies of the 119th Congress: GA-13 "Passed Away April 22, 2026"',
       'manual'
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE external_id = -66000424);
SET LOCAL essentials.allow_duplicate_name = 'off';

-- 2. His GA-13 term.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_ended, source)
SELECT '0d031c4f-07d4-4adb-8839-2bf25f5c533e', p.id, DATE '2003-01-07', DATE '2026-04-21', 'day', 'died',
       'unitedstates/congress-legislators, fetched 2026-10-26 — current unbroken rep service 2003-01-07 .. 2026-04-21 (bioguide S001157); House Clerk: GA-13 vacant from his death 2026-04-22 (CA_0330)'
  FROM essentials.politicians p
 WHERE p.external_id = -66000424
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t
                    WHERE t.office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND t.politician_id = p.id);

DO $$
DECLARE
  v int;
  v_pid uuid;
BEGIN
  SELECT id INTO v_pid FROM essentials.politicians WHERE external_id = -66000424;
  SELECT count(*) INTO v FROM essentials.politicians
   WHERE external_id = -66000424 AND full_name = 'David Scott' AND bioguide_id = 'S001157'
     AND NOT is_incumbent AND NOT is_active AND party IS NULL;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0330: Scott row not as expected (found %)', v; END IF;
  -- The guard was restored: the setting is off again for the rest of the transaction.
  IF current_setting('essentials.allow_duplicate_name', true) IS DISTINCT FROM 'off' THEN
    RAISE EXCEPTION 'CA_0330: name guard left lifted';
  END IF;

  SELECT count(*) INTO v FROM essentials.office_terms
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id = v_pid
     AND term_start = DATE '2003-01-07' AND term_end = DATE '2026-04-21'
     AND start_precision = 'day' AND how_ended = 'died' AND how_started IS NULL;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0330: Scott GA-13 term not as expected (found %)', v; END IF;
  SELECT count(*) INTO v FROM essentials.office_terms WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e';
  IF v <> 2 THEN RAISE EXCEPTION 'CA_0330: GA-13 has % terms, expected 2 (Scott, Blair)', v; END IF;

  -- History answers on fixed dates: Scott in 2020, nobody in June 2026, Blair in October 2026.
  SELECT count(*) INTO v FROM essentials.office_holders_as_of(DATE '2020-06-01')
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id = v_pid;
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0330: office_holders_as_of(2020-06-01) does not return Scott for GA-13'; END IF;
  SELECT count(*) INTO v FROM essentials.office_holders_as_of(DATE '2026-06-01')
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id IS NOT NULL;
  IF v <> 0 THEN RAISE EXCEPTION 'CA_0330: GA-13 has a holder on 2026-06-01, during the vacancy'; END IF;
  SELECT count(*) INTO v FROM essentials.office_holders_as_of(DATE '2026-10-01')
   WHERE office_id = '0d031c4f-07d4-4adb-8839-2bf25f5c533e' AND politician_id = '230d1dac-ddbc-472d-9314-89967917eb5a';
  IF v <> 1 THEN RAISE EXCEPTION 'CA_0330: office_holders_as_of(2026-10-01) does not return Blair for GA-13'; END IF;
END $$;

COMMIT;
