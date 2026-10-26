-- CC_0297 — give Indiana's shared statewide-executive district its FIPS geo_id.
--
-- This answers the question `CC_0295` wrote down and `CC_0296` deliberately left open: **which
-- district shape is canonical for Indiana's statewide executives.** The answer turned out not to
-- be about shape at all.
--
-- ─── WHAT WAS MEASURED, ACROSS ALL 51 JURISDICTIONS ──────────────────────────────────────
-- Counting every `STATE_EXEC` district in the database:
--
--   * **48 of 51 give every statewide executive office its own district row.** Biggest district
--     holds exactly 1 office.
--   * **Three share one district across several offices** — and that is a legitimate variant,
--     not a defect:
--
--       | state | shared district        | offices | geo_id |
--       | ----- | ---------------------- | ------- | ------ |
--       | CA    | "California"           | 17      | `06`   |
--       | OR    | "Oregon (Statewide)"   |  5      | `41`   |
--       | IN    | "Indiana"              | 10      | **``** |
--
-- 🟢 **SO THE SHARED DISTRICT IS NOT THE ANOMALY — THE EMPTY `geo_id` IS.** California and Oregon
-- do exactly what Indiana does and both carry their real state FIPS. Indiana's is the **only
-- multi-office statewide-executive district in the country with no `geo_id` at all**.
--
-- ▶ That is why this migration does not split the ten offices into ten districts. Doing so would
-- invent a convention that two of the three precedents reject, and would touch ten rows to fix a
-- defect that lives in one.
--
-- ─── THE REPO ALREADY CALLS THIS A DEFECT ────────────────────────────────────────────────
-- `backend/scripts/gen-state-exec-seed.mjs` emits a post-verify gate that **RAISEs** on
-- `d.geo_id IS NULL OR d.geo_id = ''` for any `STATE_EXEC` district in the states it covers.
-- Indiana is not in that generator's state list, which is the whole reason this row survived.
-- So this is not a new opinion about the data model; it is the existing rule reaching a row it
-- never covered.
--
-- ─── WHAT AN EMPTY `geo_id` ACTUALLY COSTS ───────────────────────────────────────────────
-- `geo_id` is a LOOKUP key (`ocd_id` rolls up, `geo_id` looks up). An empty one is a key nothing
-- can ever match, so these ten offices are invisible to every `geo_id`-keyed read. The one that
-- exists today is the `government_bodies` join in `DISTRICT_SELECT_FIELDS`:
--
--     LEFT JOIN essentials.government_bodies gvb
--       ON gvb.state = d.state AND gvb.geo_id = d.geo_id
--      AND gvb.body_key = COALESCE(NULLIF(ch.name_formal, ''), ch.name, '')
--
-- With `geo_id = ''` that join cannot match anything, ever. With `'18'` it can — and today it
-- still matches nothing, because no `government_bodies` row carries any of the ten chambers'
-- join keys. ⚠ **That is checked in the pre-flight below rather than assumed**, so this migration
-- cannot quietly attach a body to an office.
--
-- ─── 🔴 WHAT THIS DOES NOT CHANGE, MEASURED WITH THE CHANGE ACTUALLY APPLIED ─────────────
-- The obvious hazard is that a real `geo_id` lets these offices leak through the GEOFENCED
-- district query as well as the statewide one, returning every Indiana statewide executive twice.
-- It does not, and that was not reasoned about — it was run:
--
--   BEFORE            geofenced=60 (STATE_EXEC 0)  statewide=63 (STATE_EXEC 16)  combined=123
--   AFTER geo_id=18   geofenced=60 (STATE_EXEC 0)  statewide=63 (STATE_EXEC 16)  combined=123
--   offices appearing twice: 0 before, 0 after
--
-- …inside one transaction that was then rolled back, at the Indianapolis City-County Building.
-- 🟢 **And the probe was proved sighted first:** moving one office off the shared district took
-- the statewide count 63 → 62 and the rollback restored it to 63. A zero delta from a detector
-- that has never moved is not evidence.
--
-- The mechanism: `G4000`, the state-outline layer, is in `FALLBACK_EXCLUDED_MTFCCS`, so the
-- geofence catch-all cannot match a state outline, and `STATE_EXEC` appears in no arm of
-- `MTFCC_DISTRICT_TYPE_GUARD`. The six Indiana statewide-exec districts that ALREADY carry
-- `geo_id = '18'` are the standing proof.
--
-- `check:reachability` is unaffected: `STATE_EXEC` is not in its `ADDRESSABLE` list at all —
-- statewide seats are surfaced by the separate statewide branch, which never touches a geofence.
--
-- ─── ⚠ FOUND AND DELIBERATELY LEFT: THE OTHER EMPTY `geo_id` ─────────────────────────────
-- Exactly one other `STATE_EXEC` district has an empty `geo_id`: California's
-- `294f92a7-47a8-429e-adae-cf5bb7954f4b`, **"Board of Equalization Member", `district_id = '3'`**,
-- holding one office. It is NOT the same defect and must not get the same fix: the BOE is elected
-- from four districts of its own, so the right value is a BOE-district geo_id, not California's
-- state FIPS. Giving it `'06'` would assert that the member represents the whole state.
-- The post-verify gate below names it explicitly, so it is recorded as seen rather than missed —
-- the same disposition `CC_0295` gave the Comptroller.
--
-- ⚠ **This migration fixes nothing a voter can see today.** The address response is byte-identical
-- before and after. It removes a key that can never be looked up, in the one row in the country
-- that still has one.
--
-- Author: Chris Cantrell. Slot reserved through the steward.

BEGIN;

CREATE TEMP TABLE _before ON COMMIT DROP AS
SELECT count(*)                                AS total,
       count(*) FILTER (WHERE o.is_vacant)     AS flagged,
       count(*) FILTER (WHERE NOT o.is_vacant) AS unflagged
  FROM essentials.offices_missing_terms m
  JOIN essentials.offices o ON o.id = m.office_id;

-- ─── PRE-FLIGHT ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_shared CONSTANT uuid := '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  v_boe    CONSTANT uuid := '294f92a7-47a8-429e-adae-cf5bb7954f4b';
  v_n   int;
  v_txt text;
BEGIN
  -- Idempotent: already done? Confirm and stop.
  IF EXISTS (SELECT 1 FROM essentials.districts WHERE id = v_shared AND geo_id = '18') THEN
    RAISE NOTICE 'CC_0297: already applied — nothing to do.';
    RETURN;
  END IF;

  -- The row is the one that was measured.
  SELECT d.district_type || ' | ' || d.state || ' | geo_id=' || quote_literal(coalesce(d.geo_id,'<NULL>'))
      || ' | district_id=' || quote_literal(coalesce(d.district_id,'<NULL>'))
      || ' | ' || coalesce(d.label,'<NULL>')
    INTO v_txt FROM essentials.districts d WHERE d.id = v_shared;
  IF v_txt IS DISTINCT FROM 'STATE_EXEC | IN | geo_id='''' | district_id=''IN'' | Indiana' THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: the shared district is not the row measured. Got: %', coalesce(v_txt,'<missing>');
  END IF;

  -- It holds exactly the ten appointed offices.
  SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = v_shared;
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: the shared district holds % offices, expected 10', v_n;
  END IF;
  SELECT string_agg(DISTINCT o.title, ', ' ORDER BY o.title) INTO v_txt
    FROM essentials.offices o WHERE o.district_id = v_shared;
  IF v_txt IS DISTINCT FROM 'Chairman, Commissioner of Labor, Director of Agriculture, '
                         || 'Director of Natural Resources, Insurance Commissioner, '
                         || 'Secretary of Education, Utility Regulatory Commissioner' THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: the ten offices are not the set measured. Got: %', v_txt;
  END IF;

  -- 🔴 THE PREMISE, RE-CHECKED AT APPLY TIME. Indiana must still be the only multi-office
  -- statewide-exec district in the country with no geo_id. If another state has grown one since
  -- this was written, the "fix the one row" reasoning no longer holds and a human should look.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'STATE_EXEC' AND coalesce(d.geo_id,'') = ''
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) > 1;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: % multi-office STATE_EXEC districts have no geo_id, expected exactly 1 (Indiana)', v_n;
  END IF;

  -- California's single-office Board of Equalization row is the other empty one, and is NOT ours.
  IF NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE id = v_boe AND district_type = 'STATE_EXEC'
                    AND coalesce(geo_id,'') = '' AND label = 'Board of Equalization Member') THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: the California BOE district is not the row this migration expects to leave alone';
  END IF;

  -- 🔴 NOTHING MAY SILENTLY ACQUIRE A GOVERNMENT BODY. No government_bodies row at (IN, '18')
  -- carries any of the ten chambers' join keys, so the response is unchanged.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE o.district_id = v_shared
     AND EXISTS (SELECT 1 FROM essentials.government_bodies gb
                  WHERE gb.state = 'IN' AND gb.geo_id = '18'
                    AND gb.body_key = coalesce(nullif(ch.name_formal,''), ch.name, ''));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: % of the ten offices would newly pick up a government body — look before writing', v_n;
  END IF;

  -- All ten are seated today, and must still be afterwards.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
   WHERE o.district_id = v_shared
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = o.id AND och.politician_id IS NOT NULL);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0297 pre-flight: % of the ten offices are unseated before this runs', v_n;
  END IF;
END $$;

-- ─── THE CHANGE: ONE COLUMN, ONE ROW ─────────────────────────────────────────────────────
UPDATE essentials.districts
   SET geo_id = '18'
 WHERE id = '97db28b9-6b56-4427-a6e3-82645d0d6ad5'
   AND coalesce(geo_id,'') = '';

-- ─── POST-VERIFY ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_shared CONSTANT uuid := '97db28b9-6b56-4427-a6e3-82645d0d6ad5';
  v_boe    CONSTANT uuid := '294f92a7-47a8-429e-adae-cf5bb7954f4b';
  v_n   int;
  v_txt text;
  b     record;
  a_total int; a_flagged int; a_unflagged int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.districts WHERE id = v_shared AND geo_id = '18') THEN
    RAISE EXCEPTION 'CC_0297: the shared district did not take geo_id 18';
  END IF;

  -- Nothing else about the row moved.
  SELECT d.district_type || ' | ' || d.state || ' | ' || coalesce(d.district_id,'<NULL>')
      || ' | ' || coalesce(d.label,'<NULL>') || ' | ' || coalesce(d.ocd_id,'<NULL>')
    INTO v_txt FROM essentials.districts d WHERE d.id = v_shared;
  IF v_txt IS DISTINCT FROM 'STATE_EXEC | IN | IN | Indiana | ocd-division/country:us/state:in' THEN
    RAISE EXCEPTION 'CC_0297: something other than geo_id changed on the district. Got: %', v_txt;
  END IF;

  -- The ten offices are still there, still the same titles, still all seated.
  SELECT count(*) INTO v_n FROM essentials.offices WHERE district_id = v_shared;
  IF v_n <> 10 THEN RAISE EXCEPTION 'CC_0297: the shared district now holds % offices, expected 10', v_n; END IF;
  SELECT count(*) INTO v_n
    FROM essentials.offices o
   WHERE o.district_id = v_shared
     AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och
                      WHERE och.office_id = o.id AND och.politician_id IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION 'CC_0297: % of the ten offices are now unseated', v_n; END IF;

  -- Indiana's statewide-executive set is unchanged in size and shape: 7 districts, 16 offices,
  -- and every one of those districts now carries the state FIPS.
  SELECT count(DISTINCT d.id) INTO v_n
    FROM essentials.districts d WHERE d.district_type='STATE_EXEC' AND lower(d.state)='in';
  IF v_n <> 7 THEN RAISE EXCEPTION 'CC_0297: Indiana has % STATE_EXEC districts, expected 7', v_n; END IF;
  SELECT count(*) INTO v_n
    FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id
   WHERE d.district_type='STATE_EXEC' AND lower(d.state)='in';
  IF v_n <> 16 THEN RAISE EXCEPTION 'CC_0297: Indiana has % STATE_EXEC offices, expected 16', v_n; END IF;
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type='STATE_EXEC' AND lower(d.state)='in' AND coalesce(d.geo_id,'') <> '18';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0297: % Indiana STATE_EXEC district(s) still carry a geo_id other than 18', v_n;
  END IF;

  -- 🟢 THE PREMISE, NOW TRUE NATIONWIDE: no multi-office statewide-exec district anywhere lacks a
  -- geo_id, and the only single-office one left is California's BOE seat — named, not swept up.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type='STATE_EXEC' AND coalesce(d.geo_id,'') = ''
     AND (SELECT count(*) FROM essentials.offices o WHERE o.district_id = d.id) > 1;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0297: % multi-office STATE_EXEC district(s) still have no geo_id', v_n;
  END IF;
  SELECT string_agg(coalesce(d.label,'<NULL>') || ' (' || lower(d.state) || ')', ', ' ORDER BY d.label)
    INTO v_txt FROM essentials.districts d
   WHERE d.district_type='STATE_EXEC' AND coalesce(d.geo_id,'') = '';
  IF v_txt IS DISTINCT FROM 'Board of Equalization Member (ca)' THEN
    RAISE EXCEPTION 'CC_0297: STATE_EXEC districts with no geo_id are [%], expected only California''s Board of Equalization seat', coalesce(v_txt,'<none>');
  END IF;

  -- No office silently acquired a government body.
  SELECT count(*) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers ch ON ch.id = o.chamber_id
   WHERE o.district_id = v_shared
     AND EXISTS (SELECT 1 FROM essentials.government_bodies gb
                  WHERE gb.state = 'IN' AND gb.geo_id = '18'
                    AND gb.body_key = coalesce(nullif(ch.name_formal,''), ch.name, ''));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0297: % of the ten offices picked up a government body', v_n;
  END IF;

  -- Occupancy must not move at all: this migration seats nobody and deletes nothing.
  SELECT * INTO b FROM _before;
  SELECT count(*),
         count(*) FILTER (WHERE o.is_vacant),
         count(*) FILTER (WHERE NOT o.is_vacant)
    INTO a_total, a_flagged, a_unflagged
    FROM essentials.offices_missing_terms m
    JOIN essentials.offices o ON o.id = m.office_id;
  IF (b.total, b.flagged, b.unflagged) IS DISTINCT FROM (a_total, a_flagged, a_unflagged) THEN
    RAISE EXCEPTION 'CC_0297: offices_missing_terms moved %/%/% -> %/%/%, expected no change',
      b.total, b.flagged, b.unflagged, a_total, a_flagged, a_unflagged;
  END IF;

  RAISE NOTICE 'CC_0297 OK — Indiana''s shared STATE_EXEC district now carries geo_id 18; occupancy unchanged at %/%/%',
    a_total, a_flagged, a_unflagged;
END $$;

COMMIT;
