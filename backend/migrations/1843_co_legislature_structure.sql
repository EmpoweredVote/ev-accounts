-- 1843_co_legislature_structure.sql
-- Colorado General Assembly: 2 chambers + 100 offices.
--
-- Colorado Springs deep seed. Depends on the CO TIGER load, which ALREADY created
-- all 100 essentials.districts rows (writeDistrictRow=true for sldu/sldl). This
-- migration therefore creates CHAMBERS and OFFICES ONLY -- it must not insert
-- districts.
--
-- Confirmed against the database 2026-08-21:
--   * MTFCC orientation matches the other states in this loader:
--       STATE_UPPER (Senate) = G5210,  STATE_LOWER (House) = G5220.
--   * districts.state = 'co' (LOWERCASE) for these rows -- the TIGER loader
--     writes the abbreviation lowercased, unlike CO's older federal/exec rows
--     which carry 'CO'. Joins below use ILIKE so they are insensitive to it.
--   * geo_id is NOT unique across MTFCCs ('08011' is both SD 11 and, in other
--     states' shape, a county). Every join keys on (district_type, mtfcc, state).
--
-- COLORADO IS SINGLE-MEMBER IN BOTH CHAMBERS: 35 Senate + 65 House = 100 offices,
-- one per district. This is NOT the WA/AZ multi-member shape, so there is no
-- Position 1 / Position 2 split and the office title carries no position number.
--
-- Senate terms are 4 years and STAGGERED; House terms are 2 years, all up every
-- even year.
--
-- Idempotency: essentials.offices has NO unique index beyond the pkey, so inserts
-- use NOT EXISTS, never ON CONFLICT. Chamber idempotency keys on
-- (government_id, name), matching the five existing CO executive chambers which
-- all carry NULL external_id.

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────
-- Short-form names matching this government's existing convention ('Governor',
-- not 'Colorado Governor').

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'State Senate', 'Colorado State Senate', 35, 4, true, 'full'
FROM essentials.governments g
WHERE g.state = 'CO' AND g.geo_id = '08'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'State Senate'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'House of Representatives', 'Colorado House of Representatives', 65, 2, false, 'full'
FROM essentials.governments g
WHERE g.state = 'CO' AND g.geo_id = '08'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'House of Representatives'
  );

-- ─── Senate offices: 35, one per STATE_UPPER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'State Senator', 'CO', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'CO' AND g.geo_id = '08' AND ch.name = 'State Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND d.state ILIKE 'co'
  AND d.mtfcc = 'G5210'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'State Senator'
  );

-- ─── House offices: 65, one per STATE_LOWER district ─────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'State Representative', 'CO', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON ch.government_id = g.id
  WHERE g.state = 'CO' AND g.geo_id = '08' AND ch.name = 'House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND d.state ILIKE 'co'
  AND d.mtfcc = 'G5220'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'State Representative'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_sen int;
  v_rep int;
  v_dup int;
BEGIN
  SELECT count(*) INTO v_sen
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_UPPER' AND d.state ILIKE 'co' AND d.mtfcc = 'G5210'
    AND o.title = 'State Senator';

  SELECT count(*) INTO v_rep
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'STATE_LOWER' AND d.state ILIKE 'co' AND d.mtfcc = 'G5220'
    AND o.title = 'State Representative';

  -- More than one office per district would fan out every downstream join.
  SELECT count(*) INTO v_dup
  FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type IN ('STATE_UPPER','STATE_LOWER') AND d.state ILIKE 'co'
    GROUP BY o.district_id
    HAVING count(*) > 1
  ) x;

  IF v_sen <> 35 THEN
    RAISE EXCEPTION 'CO Senate offices: expected 35, got %', v_sen;
  END IF;
  IF v_rep <> 65 THEN
    RAISE EXCEPTION 'CO House offices: expected 65, got %', v_rep;
  END IF;
  IF v_dup <> 0 THEN
    RAISE EXCEPTION 'CO state-leg districts carrying more than one office: %', v_dup;
  END IF;
END $$;

COMMIT;
