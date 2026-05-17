-- =============================================================================
-- Migration 158: Cambridge, MA — all office rows
--
-- 16 offices total:
--   9 × City Councillor       (City Council chamber, elected at-large, STV)
--   1 × Mayor                 (City Council chamber, is_appointed_position=true)
--   1 × City Manager          (City Council chamber, is_appointed_position=true)
--   6 × School Committee Member (School Committee chamber, elected at-large, STV)
--
-- Spelling: "Councillor" (double-L) — Cambridge uses British spelling
-- Depends on: migration 157 (government + chambers must exist)
-- politician_id is NOT set here — assigned in migration 159
-- =============================================================================

BEGIN;

DO $$
DECLARE
  v_council_id UUID;
  v_school_id  UUID;
BEGIN
  -- Resolve City Council chamber UUID
  SELECT ch.id INTO v_council_id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND ch.name = 'City Council';

  IF v_council_id IS NULL THEN
    RAISE EXCEPTION 'Cambridge City Council chamber not found — run migration 157 first';
  END IF;

  -- Resolve School Committee chamber UUID
  SELECT ch.id INTO v_school_id
  FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2511000'
    AND ch.name = 'School Committee';

  IF v_school_id IS NULL THEN
    RAISE EXCEPTION 'Cambridge School Committee chamber not found — run migration 157 first';
  END IF;

  -- 9 City Councillor offices (at-large, elected, STV)
  -- Identical rows differentiated by politician_id assignment in migration 159
  INSERT INTO essentials.offices
    (chamber_id, title, representing_city, representing_state,
     normalized_position_name, seats, partisan_type, is_appointed_position)
  SELECT
    v_council_id,
    'City Councillor',
    'Cambridge',
    'MA',
    'City Councillor',
    1,
    NULL,
    false
  FROM generate_series(1, 9);

  -- Mayor office (appointed annually by City Council vote)
  INSERT INTO essentials.offices
    (chamber_id, title, representing_city, representing_state,
     normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_council_id, 'Mayor', 'Cambridge', 'MA', 'Mayor', 1, NULL, true);

  -- City Manager office (appointed by City Council, not elected)
  INSERT INTO essentials.offices
    (chamber_id, title, representing_city, representing_state,
     normalized_position_name, seats, partisan_type, is_appointed_position)
  VALUES
    (v_council_id, 'City Manager', 'Cambridge', 'MA', 'City Manager', 1, NULL, true);

  -- 6 School Committee Member offices (at-large, elected, STV)
  INSERT INTO essentials.offices
    (chamber_id, title, representing_city, representing_state,
     normalized_position_name, seats, partisan_type, is_appointed_position)
  SELECT
    v_school_id,
    'School Committee Member',
    'Cambridge',
    'MA',
    'School Committee Member',
    1,
    NULL,
    false
  FROM generate_series(1, 6);

  RAISE NOTICE 'Cambridge offices inserted — council_id: %, school_id: %', v_council_id, v_school_id;
END $$;

COMMIT;
