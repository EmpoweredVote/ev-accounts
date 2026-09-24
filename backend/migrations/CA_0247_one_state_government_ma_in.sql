-- CA_0247_one_state_government_ma_in.sql
--
-- One state government row for Massachusetts and for Indiana, like every other state (one 'STATE' row whose
-- geo_id is the state FIPS code).
--
-- WHY (census 2026-09-24: duplicate governments by name+state and by geo_id, all types)
-- -------------------------------------------------------------------------------------
--   Counties: only Orange County CA (fixed in CA_0238) and Los Angeles County CA (CA_0245). States:
--   Massachusetts  85783e20 'Commonwealth of Massachusetts' geo_id 25 — 8 chambers (Governor, Legislature, ...)
--                  66316105 'State of Massachusetts'        geo_id 25 — 0 chambers; only the US Senate district
--                           fd703947 points at it (districts.government_id)
--   Indiana        five 'State of Indiana' rows, ALL with geo_id NULL (every other state carries its FIPS):
--                  e00dba00  11 chambers (General Assembly, row officers, IURC, ...)
--                  6526e524  16 chambers (Supreme Court, Court of Appeals)
--                  36e6b227 / 0e5c12ad / 15efa1f9  one chamber each: Governor / Lieutenant Governor / Attorney General,
--                           name_formal '' — the per-seat pattern CA_0208 fixed for Indiana counties. 0e5c12ad also
--                           carries the US Senate district 343b3268.
--   The browse government step selects governments by geo_id (WHERE g.geo_id = ANY), so an Indiana state row
--   without '18' is never found that way, and duplicate rows split one state's officials across governments.
--
-- CHANGES
-- -------
--   MA  district fd703947 -> 85783e20; delete 66316105.
--   IN  every chamber and district on the four other rows -> e00dba00; e00dba00.geo_id = '18'; name_formal on the
--       three one-seat chambers = their name ('Indiana Governor', ... — the "California Governor" pattern);
--       delete the four emptied rows.
--   Offices, terms and people do not change.
--
-- PRE-IMAGES of deleted rows (essentials.governments; all type 'STATE', city NULL):
--   66316105-cfe2-4c7e-b445-1cd1156453b3  'State of Massachusetts', state 'MA', geo_id '25'
--   6526e524-1290-449e-a5bf-9bb236de2d36  'State of Indiana', state 'IN', geo_id NULL
--   36e6b227-4a55-4abf-b8e2-bdad25bd9c14  'State of Indiana', state 'IN', geo_id NULL
--   0e5c12ad-1a50-4ce2-aff3-41ee595359e8  'State of Indiana', state 'IN', geo_id NULL
--   15efa1f9-8b4b-4da3-9f74-32d2eb68ecac  'State of Indiana', state 'IN', geo_id NULL
--   and the moved rows' old parents: IN chambers of 6526e524 (16), 80557ef6 (Governor) on 36e6b227, e9650ac7
--   (Lt Governor) on 0e5c12ad, 13da2df4 (Attorney General) on 15efa1f9; districts 343b3268 on 0e5c12ad,
--   fd703947 on 66316105. The three one-seat chambers had name_formal ''.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: NOT APPLIED.
--
-- ROLLBACK: re-insert the five pre-image rows; move the chambers / districts listed above back; set e00dba00.geo_id
--   NULL; set name_formal '' on 80557ef6 / e9650ac7 / 13da2df4.
-- IDEMPOTENT: every statement is guarded on the pre-change state; a re-run changes 0 rows.

BEGIN;

CREATE TEMP TABLE ca0247_in_dup ON COMMIT DROP AS
SELECT unnest(ARRAY['6526e524-1290-449e-a5bf-9bb236de2d36', '36e6b227-4a55-4abf-b8e2-bdad25bd9c14',
                    '0e5c12ad-1a50-4ce2-aff3-41ee595359e8', '15efa1f9-8b4b-4da3-9f74-32d2eb68ecac']::uuid[]) AS id;

-- ---------------------------------------------------------------------------
-- 0. Pre-flight.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  -- 0a. The keepers are as recorded (IN geo_id NULL on a first run, '18' on a re-run).
  SELECT count(*) INTO n FROM essentials.governments
   WHERE (id = '85783e20-3031-4d71-89a5-5dd61f4a593f' AND type = 'STATE' AND state = 'MA' AND geo_id = '25')
      OR (id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND type = 'STATE' AND state = 'IN' AND name = 'State of Indiana'
          AND (geo_id IS NULL OR geo_id = '18'));
  IF n <> 2 THEN RAISE EXCEPTION 'keeper governments as recorded: % of 2', n; END IF;

  -- 0b. No other government already claims '18', and no other government row besides the ones named is a STATE row for MA / IN.
  SELECT count(*) INTO n FROM essentials.governments WHERE geo_id = '18' AND id <> 'e00dba00-b293-499c-ad67-6f52ab8f4d7c';
  IF n > 0 THEN RAISE EXCEPTION '% other government(s) already carry geo_id 18', n; END IF;
  SELECT count(*) INTO n FROM essentials.governments WHERE type = 'STATE' AND state IN ('MA', 'IN')
     AND id NOT IN ('85783e20-3031-4d71-89a5-5dd61f4a593f', 'e00dba00-b293-499c-ad67-6f52ab8f4d7c', '66316105-cfe2-4c7e-b445-1cd1156453b3')
     AND id NOT IN (SELECT id FROM ca0247_in_dup);
  IF n > 0 THEN RAISE EXCEPTION '% unrecorded MA/IN STATE government row(s)', n; END IF;

  -- 0c. The Massachusetts duplicate holds no chamber, and only the recorded Senate district.
  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = '66316105-cfe2-4c7e-b445-1cd1156453b3';
  IF n > 0 THEN RAISE EXCEPTION 'MA duplicate holds % chamber(s)', n; END IF;
  SELECT count(*) INTO n FROM essentials.districts WHERE government_id = '66316105-cfe2-4c7e-b445-1cd1156453b3'
     AND id <> 'fd703947-1394-4e95-9401-bf0df7851cc8';
  IF n > 0 THEN RAISE EXCEPTION 'MA duplicate carries % unrecorded district(s)', n; END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Massachusetts.
-- ---------------------------------------------------------------------------
UPDATE essentials.districts SET government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f'
 WHERE id = 'fd703947-1394-4e95-9401-bf0df7851cc8' AND government_id = '66316105-cfe2-4c7e-b445-1cd1156453b3';

DELETE FROM essentials.governments g
 WHERE g.id = '66316105-cfe2-4c7e-b445-1cd1156453b3'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ---------------------------------------------------------------------------
-- 2. Indiana.
-- ---------------------------------------------------------------------------
UPDATE essentials.chambers SET government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c'
 WHERE government_id IN (SELECT id FROM ca0247_in_dup);
UPDATE essentials.districts SET government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c'
 WHERE government_id IN (SELECT id FROM ca0247_in_dup);

UPDATE essentials.chambers SET name_formal = name
 WHERE id IN ('80557ef6-3d28-41f8-8ba9-fcc355a85751', 'e9650ac7-3f65-4110-a1ea-6ea76b72d098', '13da2df4-d649-429b-8d88-c84f7ad5903c')
   AND name IN ('Indiana Governor', 'Indiana Lieutenant Governor', 'Indiana Attorney General')
   AND COALESCE(name_formal, '') = '';

UPDATE essentials.governments SET geo_id = '18'
 WHERE id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c' AND geo_id IS NULL;

DELETE FROM essentials.governments g
 WHERE g.id IN (SELECT id FROM ca0247_in_dup)
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ---------------------------------------------------------------------------
-- 3. Post-verify.
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  -- 3a. Exactly one STATE row each, carrying the FIPS.
  SELECT count(*) INTO n FROM essentials.governments WHERE type = 'STATE' AND state = 'MA';
  IF n <> 1 THEN RAISE EXCEPTION 'MA STATE rows: % (want 1)', n; END IF;
  SELECT count(*) INTO n FROM essentials.governments WHERE type = 'STATE' AND state = 'IN' AND geo_id = '18';
  IF n <> 1 OR (SELECT count(*) FROM essentials.governments WHERE type = 'STATE' AND state = 'IN') <> 1 THEN
    RAISE EXCEPTION 'IN STATE rows: not exactly one with geo_id 18';
  END IF;

  -- 3b. Nothing lost: IN keeps 30 chambers and their offices; MA keeps 8.
  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = 'e00dba00-b293-499c-ad67-6f52ab8f4d7c';
  IF n <> 30 THEN RAISE EXCEPTION 'IN chambers: % (want 30)', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers WHERE government_id = '85783e20-3031-4d71-89a5-5dd61f4a593f';
  IF n <> 8 THEN RAISE EXCEPTION 'MA chambers: % (want 8)', n; END IF;

  -- 3c. The three one-seat chambers have a formal name; no chamber anywhere hangs on a deleted row.
  SELECT count(*) INTO n FROM essentials.chambers
   WHERE id IN ('80557ef6-3d28-41f8-8ba9-fcc355a85751', 'e9650ac7-3f65-4110-a1ea-6ea76b72d098', '13da2df4-d649-429b-8d88-c84f7ad5903c')
     AND name_formal = name;
  IF n <> 3 THEN RAISE EXCEPTION 'named one-seat chambers: % of 3', n; END IF;
  SELECT count(*) INTO n FROM essentials.chambers c WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id)
     AND c.government_id IN (SELECT id FROM ca0247_in_dup UNION ALL SELECT '66316105-cfe2-4c7e-b445-1cd1156453b3'::uuid);
  IF n > 0 THEN RAISE EXCEPTION '% orphaned chamber(s)', n; END IF;

  RAISE NOTICE 'OK: one STATE government each for MA (25) and IN (18); IN 30 chambers, MA 8';
END $$;

COMMIT;
