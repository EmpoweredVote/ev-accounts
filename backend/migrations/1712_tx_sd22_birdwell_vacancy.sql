-- 1712_tx_sd22_birdwell_vacancy.sql
--
-- Close Brian Birdwell's tenure in TX Senate District 22.
--
-- He vacated the seat on 2026-05-26 on executing the oath as Assistant Secretary of War for
-- Sustainment. Prod still carried him on the open-ended `office_terms` row written by the ADR 0002
-- phase-2 backfill (migration 1459, start_precision 'unknown'), so he resolved through
-- `essentials.office_current_holder` and rendered as a sitting senator everywhere that view reaches
-- -- including a live Essentials profile carrying 25 researched compass answers.
--
-- Sources (both re-checked 2026-08-11, the day this was written):
--   * Texas Legislative Reference Library member profile 5678 lists his terms of service as
--     "Jan 10, 2023 - May 26, 2026", footnoted: "Brian Birdwell, letter to Governor Greg Abbott,
--     5/26/2026, vacating the position of State Senator, District 22, upon executing the oath of
--     office for the duties of Assistant Secretary of War for Sustainment."
--   * senate.texas.gov/members.php lists District 22 as "Constituent Services*" (the asterisk is
--     the roster's vacancy marker). All 30 other districts return a named senator, so no successor
--     has been seated and `vacate_office` -- not `seat_officeholder` -- is the correct call.
--
-- 2026-05-26 is his LAST DAY. vacate_office takes the FIRST VACANT day, so it gets 2026-05-27 and
-- writes term_end = 2026-05-26 itself.
--
-- This closes a tenure. It does not touch the `politicians` row or the 25 compass answers, both of
-- which are asserted intact below. Found by the migration 1699 headshot sweep: he was the only one
-- of 159 TX targets whose district had no member on the official roster.
-- Background: .planning/todos/2026-08-11-sd22-birdwell-vacancy.md

DO $$
DECLARE
  v_office_id  uuid;
  v_pol_id     uuid := '7de0d70b-81ba-484c-aa82-43dfb4dadd0a';  -- Brian Birdwell
  v_n          int;
  v_term_end   date;
  v_is_vacant  boolean;
BEGIN
  -- Resolve the seat on (state, district_type, geo_id). geo_id alone is NOT unique -- 48022 also
  -- names TX House District 22 (Christian Manuel, who is very much still seated). Assert 1:1;
  -- never LIMIT 1.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.state = 'TX' AND d.district_type = 'STATE_UPPER' AND d.geo_id = '48022';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 office for TX STATE_UPPER geo_id 48022, found %', v_n;
  END IF;

  SELECT o.id INTO v_office_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.state = 'TX' AND d.district_type = 'STATE_UPPER' AND d.geo_id = '48022';

  -- Idempotent: only act while Birdwell is still the resolved current holder. A re-run after the
  -- fix, or a run after someone else has been seated by a special election, is a no-op.
  IF EXISTS (SELECT 1 FROM essentials.office_current_holder och
              WHERE och.office_id = v_office_id AND och.politician_id = v_pol_id) THEN
    PERFORM essentials.vacate_office(
      v_office_id,
      DATE '2026-05-27',
      'senate.texas.gov roster + lrl.texas.gov member 5678, both checked 2026-08-11; '
        || 'resignation effective 2026-05-26 on oath as Asst. Secretary of War for Sustainment '
        || '(migration 1712)');
  END IF;

  -- ---- post-verify -------------------------------------------------------------------------

  -- The seat resolves to nobody now. NOTE: office_current_holder LEFT JOINs from offices, so it
  -- always has exactly one row per office -- the vacancy shows as a NULL politician_id, not as an
  -- absent row. Counting rows here would assert nothing (a first draft did, and passed vacuously).
  IF NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                  WHERE och.office_id = v_office_id AND och.politician_id IS NULL) THEN
    RAISE EXCEPTION 'TX SD-22 still resolves to a current holder after vacate';
  END IF;

  -- Birdwell's term is closed on his real last day, not open and not guessed.
  SELECT t.term_end INTO v_term_end
    FROM essentials.office_terms t
   WHERE t.office_id = v_office_id AND t.politician_id = v_pol_id;
  IF v_term_end IS DISTINCT FROM DATE '2026-05-26' THEN
    RAISE EXCEPTION 'expected Birdwell term_end 2026-05-26, got %', v_term_end;
  END IF;

  -- The office carries the vacancy flag and the date.
  SELECT o.is_vacant INTO v_is_vacant FROM essentials.offices o WHERE o.id = v_office_id;
  IF v_is_vacant IS NOT TRUE THEN
    RAISE EXCEPTION 'TX SD-22 is_vacant did not get set';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.offices o
                  WHERE o.id = v_office_id AND o.vacant_since::date = DATE '2026-05-27') THEN
    RAISE EXCEPTION 'TX SD-22 vacant_since is not 2026-05-27';
  END IF;

  -- The person and his research survive. This closed a tenure; it deleted nobody.
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = v_pol_id) THEN
    RAISE EXCEPTION 'Birdwell politicians row disappeared';
  END IF;
  SELECT count(*) INTO v_n FROM inform.politician_answers a WHERE a.politician_id = v_pol_id;
  IF v_n <> 25 THEN
    RAISE EXCEPTION 'expected Birdwell to keep 25 compass answers, found %', v_n;
  END IF;

  -- The 30 remaining TX senators are untouched.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.state = 'TX' AND d.district_type = 'STATE_UPPER'
     AND och.politician_id IS NOT NULL;      -- same trap: the join alone would count all 31
  IF v_n <> 30 THEN
    RAISE EXCEPTION 'expected 30 seated TX senators after vacating SD-22, found %', v_n;
  END IF;

  RAISE NOTICE 'TX SD-22 vacated: Birdwell term closed 2026-05-26, 30 senators remain seated';
END $$;
