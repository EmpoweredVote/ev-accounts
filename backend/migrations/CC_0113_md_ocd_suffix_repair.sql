-- CC_0113_md_ocd_suffix_repair.sql
-- Repairs Maryland's collapsed state-legislative OCD-IDs. Slot RESERVED from the allocator.
--
-- 🔴 THE DEFECT. `scripts/load-state-tiger-boundaries.ts` derived the OCD-ID suffix for both SLD
-- layers with `parseInt(districtNum, 10)`. `parseInt('01A', 10)` is **1**, so the letter was
-- dropped. Maryland's delegate districts are subdivided `1A`/`1B`/`1C`, so all three collapsed to
-- `ocd-division/country:us/state:md/sldl:1`.
--
-- The loader was fixed on 2026-09-12 by `src/lib/ocdDistrictSuffix.ts` (13 tests), BEFORE any
-- Minnesota row was written — MN's 134 House districts are correct in production, and this file
-- is the separate migration that doc named: **writing Minnesota correctly does not fix Maryland.**
--
-- 🔴🔴 THE SCOPE IS 84 ROWS IN **TWO** TABLES, NOT THE 24 PREVIOUSLY RECORDED.
-- The figure carried forward from MN-1 was "24 rows sharing one", which is rows-minus-distinct in
-- ONE table — a count of the collapse, not of the rows that carry it. Measured 2026-09-16:
--
--   essentials.districts           71 STATE_LOWER rows, 47 distinct ocd_id, **42 carry a letter**
--   essentials.geofence_boundaries 71 G5220 rows,       47 distinct ocd_id, **42 carry a letter**
--
-- `geofence_boundaries` was never mentioned in the defect write-up and has exactly the same
-- damage. Repairing only `districts` would leave the two tables disagreeing about the same
-- district. Both are repaired here, in one transaction.
--
-- 🔴 WHAT IT ACTUALLY BREAKS, MEASURED. `federalCoverage.ts` `districtTotalsByState()` computes
-- the state-legislative seat denominator as `COUNT(DISTINCT ocd_id) FILTER (WHERE ocd_id ~
-- '/sld[ul]:')`. Maryland has **118** legislative district rows and reports **94** — a denominator
-- 24 short, so Maryland's state-legislative coverage has been displayed against the wrong total.
-- After this migration it reports 118.
--   ⚠ `coverageMapService.ts` `statsByJurisdiction()` is NOT affected: its regexp only extracts
--     `county|place|school_district` prefixes, so an `sldl` row yields NULL and is skipped. The
--     harm is the denominator, and that is the one asserted below.
--
-- 🟢 `geo_id` WAS NEVER AFFECTED and is not touched here. It comes from the raw TIGER `GEOID`
-- (`2401A`), which keeps the letter — which is why address search was always correct
-- (`ocd_id` ROLLS UP, `geo_id` LOOKS UP) and why `check:reachability` could never have caught this.
-- **`geo_id` is therefore the SOURCE for the repair**: the new suffix is derived from it, not from
-- the damaged `ocd_id`, so nothing is reconstructed from a value known to be lossy.
--
-- ⚠ MASSACHUSETTS IS DELIBERATELY NOT TOUCHED. 40 `sldu` rows carry the literal suffix `NaN`
--   (its Senate districts are named — "First Essex" — not numbered), and 200 MA rows collapse to
--   161. That is a DIFFERENT defect with a different fix, and `ocdDistrictSuffix.ts` preserves
--   `NaN` on purpose rather than re-key 40 live rows as a side effect. The post-verify below
--   asserts MA is unchanged, so this migration cannot quietly widen.
--
-- ⚠ `staging.politicians.district_ocd_id` holds **0** rows matching `state:md/sldl:`, so there is
--   no third copy to repair. Checked, not assumed.
--
-- Idempotent: the UPDATEs are guarded on the defect shape, so a second run matches nothing.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_d int; v_b int; v_clash int;
BEGIN
  -- The defect shape: geo_id ends in a letter, the ocd_id suffix does not.
  SELECT count(*) INTO v_d FROM essentials.districts
   WHERE lower(state) = 'md' AND district_type::text = 'STATE_LOWER'
     AND geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL
     AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$';

  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries
   WHERE state = '24' AND mtfcc = 'G5220'
     AND geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL
     AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$';

  -- 🟢 IDEMPOTENCE: 0/0 means the repair already ran. That is a success, not a failure.
  IF v_d = 0 AND v_b = 0 THEN
    RAISE NOTICE 'CC_0113: already repaired — 0 collapsed rows in either table. Nothing to do.';
    RETURN;
  END IF;

  IF v_d <> 42 OR v_b <> 42 THEN
    RAISE EXCEPTION 'CC_0113 pre-flight: expected 42 collapsed districts and 42 collapsed boundaries, found % and %. The damage is not the shape this migration was written against.', v_d, v_b;
  END IF;

  -- 🔴 The corrected id must not already belong to a DIFFERENT row. Re-keying onto an id in use
  --    would merge two districts, which is the very failure this migration exists to undo.
  SELECT count(*) INTO v_clash
  FROM essentials.districts d
  JOIN essentials.districts other
    ON other.ocd_id = 'ocd-division/country:us/state:md/sldl:' ||
                      upper(regexp_replace(substring(d.geo_id from 3), '^0*(\d+)([A-Za-z]*)$', '\1\2'))
   AND other.id <> d.id
  WHERE lower(d.state) = 'md' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id ~ '[A-Za-z]$';
  IF v_clash <> 0 THEN
    RAISE EXCEPTION 'CC_0113 pre-flight: % corrected ocd_id(s) are already held by another district row', v_clash;
  END IF;
END $$;

-- ─── 1. essentials.districts — 42 rows ───────────────────────────────────────
-- The suffix is rebuilt from geo_id: strip the '24' state FIPS, strip leading zeros from the
-- digits, keep the letter and uppercase it. '2401A' -> '1A'. This is exactly what
-- src/lib/ocdDistrictSuffix.ts does, expressed in SQL.

UPDATE essentials.districts d
   SET ocd_id = 'ocd-division/country:us/state:md/sldl:' ||
                upper(regexp_replace(substring(d.geo_id from 3), '^0*(\d+)([A-Za-z]*)$', '\1\2'))
 WHERE lower(d.state) = 'md'
   AND d.district_type::text = 'STATE_LOWER'
   AND d.geo_id ~ '[A-Za-z]$'
   AND d.ocd_id IS NOT NULL
   AND regexp_replace(d.ocd_id, '^.*:', '') !~ '[A-Za-z]$';

-- ─── 2. essentials.geofence_boundaries — 42 rows ─────────────────────────────

UPDATE essentials.geofence_boundaries b
   SET ocd_id = 'ocd-division/country:us/state:md/sldl:' ||
                upper(regexp_replace(substring(b.geo_id from 3), '^0*(\d+)([A-Za-z]*)$', '\1\2'))
 WHERE b.state = '24'
   AND b.mtfcc = 'G5220'
   AND b.geo_id ~ '[A-Za-z]$'
   AND b.ocd_id IS NOT NULL
   AND regexp_replace(b.ocd_id, '^.*:', '') !~ '[A-Za-z]$';

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE
  v_left_d int; v_left_b int; v_dist_d int; v_dist_b int; v_rows_d int; v_rows_b int;
  v_denom int; v_agree int; v_ma_rows int; v_ma_distinct int; v_other int; v_malformed int;
BEGIN
  -- 1. No collapsed row survives, in either table.
  SELECT count(*) INTO v_left_d FROM essentials.districts
   WHERE lower(state) = 'md' AND district_type::text = 'STATE_LOWER'
     AND geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL
     AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$';
  SELECT count(*) INTO v_left_b FROM essentials.geofence_boundaries
   WHERE state = '24' AND mtfcc = 'G5220'
     AND geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL
     AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$';
  IF v_left_d <> 0 OR v_left_b <> 0 THEN
    RAISE EXCEPTION 'CC_0113: % district(s) and % boundary row(s) still carry a collapsed ocd_id', v_left_d, v_left_b;
  END IF;

  -- 2. Every row is now distinct, in both tables. This is the defect's definition, inverted.
  SELECT count(*), count(DISTINCT ocd_id) INTO v_rows_d, v_dist_d
    FROM essentials.districts WHERE lower(state) = 'md' AND district_type::text = 'STATE_LOWER';
  IF v_rows_d <> 71 OR v_dist_d <> 71 THEN
    RAISE EXCEPTION 'CC_0113: MD STATE_LOWER is % row(s) with % distinct ocd_id, expected 71 and 71', v_rows_d, v_dist_d;
  END IF;
  SELECT count(*), count(DISTINCT ocd_id) INTO v_rows_b, v_dist_b
    FROM essentials.geofence_boundaries WHERE state = '24' AND mtfcc = 'G5220';
  IF v_rows_b <> 71 OR v_dist_b <> 71 THEN
    RAISE EXCEPTION 'CC_0113: MD G5220 is % row(s) with % distinct ocd_id, expected 71 and 71', v_rows_b, v_dist_b;
  END IF;

  -- 3. 🔴 THE TWO TABLES MUST AGREE. Repairing one and not the other is the failure mode this
  --    migration was widened to prevent, so it is asserted rather than assumed.
  SELECT count(*) INTO v_agree
  FROM essentials.districts d
  JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = 'G5220'
  WHERE lower(d.state) = 'md' AND d.district_type::text = 'STATE_LOWER'
    AND d.ocd_id IS DISTINCT FROM b.ocd_id;
  IF v_agree <> 0 THEN
    RAISE EXCEPTION 'CC_0113: % MD district(s) disagree with their boundary row on ocd_id', v_agree;
  END IF;

  -- 4. Every repaired suffix is well formed: digits then a single A-C.
  SELECT count(*) INTO v_malformed FROM essentials.districts
   WHERE lower(state) = 'md' AND district_type::text = 'STATE_LOWER' AND geo_id ~ '[A-Za-z]$'
     AND ocd_id !~ '^ocd-division/country:us/state:md/sldl:[0-9]+[A-C]$';
  IF v_malformed <> 0 THEN
    RAISE EXCEPTION 'CC_0113: % repaired ocd_id(s) are malformed', v_malformed;
  END IF;

  -- 5. 🔴 THE USER-VISIBLE FIX. federalCoverage's seat denominator must now be 118, not 94.
  SELECT COUNT(DISTINCT ocd_id) FILTER (WHERE ocd_id ~ '/sld[ul]:') INTO v_denom
    FROM essentials.districts
   WHERE ocd_id LIKE 'ocd-division/country:us/state:md/%';
  IF v_denom <> 118 THEN
    RAISE EXCEPTION 'CC_0113: the MD state-legislative seat denominator is %, expected 118', v_denom;
  END IF;

  -- 6. ⚠ MASSACHUSETTS IS UNCHANGED. Its 200 sld rows must still collapse to 161 — a different
  --    defect, with its own decision and its own migration. This migration must not widen.
  SELECT count(*), count(DISTINCT ocd_id) INTO v_ma_rows, v_ma_distinct
    FROM essentials.districts
   WHERE ocd_id LIKE 'ocd-division/country:us/state:ma/%' AND ocd_id ~ '/sld[ul]:';
  IF v_ma_rows <> 200 OR v_ma_distinct <> 161 THEN
    RAISE EXCEPTION 'CC_0113: Massachusetts moved — % rows / % distinct, expected 200 / 161. This migration must not touch MA.', v_ma_rows, v_ma_distinct;
  END IF;

  -- 7. No other state gained or lost a collapsed sld row. The only two states with a lettered
  --    geo_id whose suffix drops the letter were MD (42) and, before its fix, MN. MN is correct.
  SELECT count(*) INTO v_other FROM essentials.districts
   WHERE geo_id ~ '[A-Za-z]$' AND ocd_id IS NOT NULL AND ocd_id <> ''
     AND district_type::text IN ('STATE_LOWER','STATE_UPPER')
     AND regexp_replace(ocd_id, '^.*:', '') !~ '[A-Za-z]$';
  IF v_other <> 0 THEN
    RAISE EXCEPTION 'CC_0113: % state-legislative row(s) nationally still drop a geo_id letter', v_other;
  END IF;

  RAISE NOTICE 'CC_0113 OK: MD repaired — 71/71 distinct districts, 71/71 distinct boundaries, both tables agree, seat denominator 118, MA untouched at 200/161';
END $$;

COMMIT;
