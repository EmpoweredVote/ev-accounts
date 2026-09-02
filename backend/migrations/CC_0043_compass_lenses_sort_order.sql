BEGIN;

-- =============================================================================
-- CC_0043: give inform.compass_lenses an explicit sort_order
-- =============================================================================
-- Created 2026-09-01 with Chris Cantrell. Follow-up to CC_0042 / CompassV2 #83.
--
-- WHY. compass_lenses has no ordering column, so getCompassLenses returns
-- `ORDER BY l.key` — alphabetical. That is not an order anyone chose: it happens
-- to read federal, judicial, local, and the moment the Education Lens row was
-- added it led the row, ahead of the three chips users already know.
--
-- The client has been papering over that. CompassV2 #83 carries a
-- LENS_DISPLAY_ORDER constant precisely because the DB could not express this,
-- and every other consumer of /compass/lenses (Essentials included) either
-- repeats that list or shows alphabetical order. This puts the decision in the
-- one place both apps already read.
--
-- THE VALUES PRESERVE WHAT IS LIVE TODAY. federal, local, judicial is the order
-- the switcher has always rendered — it was hardcoded three-at-a-time in
-- CombinedPage — and Education goes fourth, where #83 already appends it. This
-- migration changes no visible order; it just stops the order being an accident
-- of the key spelling. Gaps of 10 leave room to insert without a renumber.
--
-- DEFAULT 100, NOT 0. A lens added later with no explicit value sorts AFTER the
-- curated set rather than silently jumping to the front of the row — the same
-- semantics the client fallback already has ("unknown keys sort last"). NOT NULL
-- so ORDER BY never has to reason about nulls.
--
-- `key` STAYS IN THE ORDER BY as a tiebreaker. sort_order is not unique and the
-- default puts every future lens at 100, so without it two lenses could swap
-- places between requests. Same reasoning as the p.created_at, p.topic_key
-- tiebreak in getPromotedTopics.
--
-- ⚠ THE BACKEND MUST DEPLOY BEFORE THIS HELPS, AND THAT IS SAFE. Adding the
-- column changes nothing on its own: getCompassLenses does not select it yet.
-- Once deployed it orders by it, and the client prefers the API's number when
-- present and falls back to LENS_DISPLAY_ORDER when absent — so old client + new
-- server and new client + old server both render the order below.
-- =============================================================================

ALTER TABLE inform.compass_lenses
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 100;

UPDATE inform.compass_lenses SET sort_order = 10 WHERE key = 'federal';
UPDATE inform.compass_lenses SET sort_order = 20 WHERE key = 'local';
UPDATE inform.compass_lenses SET sort_order = 30 WHERE key = 'judicial';
UPDATE inform.compass_lenses SET sort_order = 40 WHERE key = 'education';

COMMENT ON COLUMN inform.compass_lenses.sort_order IS
  'Switcher display order, ascending; ties broken by key. Default 100 so a new '
  'lens sorts after the curated set instead of jumping to the front.';

DO $$
DECLARE
  v_order text;
  v_nulls int;
BEGIN
  -- The whole point: this exact sequence, from the DB alone.
  SELECT string_agg(key, ',' ORDER BY sort_order, key)
    INTO v_order
    FROM inform.compass_lenses
   WHERE is_active = true;

  IF v_order <> 'federal,local,judicial,education' THEN
    RAISE EXCEPTION
      'CC_0043: active lens order is "%", expected "federal,local,judicial,education"',
      v_order;
  END IF;

  SELECT count(*) INTO v_nulls
    FROM inform.compass_lenses WHERE sort_order IS NULL;
  IF v_nulls <> 0 THEN
    RAISE EXCEPTION 'CC_0043: % lens rows have a null sort_order', v_nulls;
  END IF;

  RAISE NOTICE 'CC_0043 OK: %', v_order;
END $$;

COMMIT;
