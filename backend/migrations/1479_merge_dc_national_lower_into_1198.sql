-- 1479_merge_dc_national_lower_into_1198.sql
--
-- Merge DC's two competing NATIONAL_LOWER district rows into one, so the District's House
-- delegate becomes reachable from a coordinate.
--
-- THE DEFECT. DC carried TWO NATIONAL_LOWER district rows, each holding half of a working
-- district, and nothing reconciled them:
--
--   geo_id '1198'              — pre-existing Cicero-era import. 4-char geo_id (matching all 436
--                                other House districts), mtfcc 'G5200', and the full 177 km²
--                                District polygon in geofence_boundaries. BUT: no government FK
--                                and ZERO offices.
--   geo_id 'dc-national-lower' — authored by v2.8 migration 287. Carries the DC government FK and
--                                all 3 offices (Delegate, District of Columbia + both U.S. Shadow
--                                Senators). BUT: no polygon, no mtfcc, and the ONLY non-4-char
--                                NATIONAL_LOWER geo_id in the database.
--
-- Consequence: a DC coordinate ST_Covers-resolves to '1198', which has no office, so
-- getRepresentativesByCoordinate returned NO House representative for any DC address. All three
-- lookup paths missed — the district join, the single-House-rep fallback (findCoveringCdGeoId,
-- essentialsService.ts:1106), and the statewide floor (getStatewideOfficials, whose WHERE clause
-- excludes NATIONAL_LOWER). Eleanor Holmes Norton was seated and correct the whole time, just
-- unreachable from a point.
--
-- NOT A DESIGN DECISION. v2.8's own 105-01-SUMMARY.md:21 logged '1198' as a deviation — "a
-- pre-existing Cicero-era import, not created by migration 284" — noticed purely as a row-count
-- discrepancy (20 vs 19) and never reconciled. v2.8's geofencing goal was wards, and its only
-- resolution test was the ward path, so the NATIONAL_LOWER coordinate path was never exercised.
--
-- WHY MERGE ONTO '1198' rather than giving the slug a polygon: '1198' is the row that already
-- behaves like a House district everywhere the code looks. Every House-scoped query in this repo
-- filters on length(geo_id)=4 and substr(geo_id,1,2), so 'dc-national-lower' is invisible to all
-- of them. Attaching a second polygon to the slug would instead give DC two overlapping
-- NATIONAL_LOWER polygons over the same ground — the exact double-match condition 164.1-04
-- documented as producing spurious two-race results in dual-map states.
--
-- This still satisfies v2.8-ROADMAP.md:1072 ("1 NATIONAL_LOWER row for the EHN at-large delegate
-- seat — all FK'd to the DC government"): afterwards there is exactly one such row, and it has the
-- government FK.
--
-- OCCUPANCY IS UNTOUCHED (ADR 0002). essentials.office_terms is keyed on office_id, not
-- district_id, so re-pointing offices.district_id cannot disturb who holds a seat. The post-verify
-- gate asserts all 3 holders survive by name.
--
-- No wiring contract blocks this: 164.1-ut-wiring-contract.md's NOTOUCH md5 is scoped to FIPS-49.
--
-- Row being deleted, recorded here so it can be recreated verbatim if ever needed:
--   id            50d2750b-7b1c-4a5a-8a40-3ed45f27a7af
--   geo_id        dc-national-lower
--   tiger_geoid   dc-national-lower
--   label         District of Columbia At-Large
--   state         DC
--   mtfcc         (empty)
--   government_id dec8afc2-cda9-413f-adb4-ad1490d69958  (District of Columbia)
--   district_type NATIONAL_LOWER
-- Its only live references were the 3 offices moved below; connected_profiles,
-- inform.politicians, government_bodies, geofence_boundaries and politicians.home_jurisdiction_geoid
-- all held ZERO rows pointing at it (verified 2026-07-26).
--
-- Idempotent: every statement is guarded, so a re-run is a no-op.
--
-- Dry-run first:
--   cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
--     psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
--       -c "BEGIN;" -f migrations/1479_merge_dc_national_lower_into_1198.sql -c "ROLLBACK;"

-- 1. Move the 3 DC national offices onto the polygon-bearing district.
UPDATE essentials.offices o
SET district_id = (
      SELECT d.id FROM essentials.districts d
      WHERE d.geo_id = '1198' AND d.district_type = 'NATIONAL_LOWER'
    )
WHERE o.district_id = (
      SELECT d.id FROM essentials.districts d
      WHERE d.geo_id = 'dc-national-lower' AND d.district_type = 'NATIONAL_LOWER'
    )
  AND EXISTS (SELECT 1 FROM essentials.districts d WHERE d.geo_id = '1198' AND d.district_type = 'NATIONAL_LOWER');

-- 2. Give '1198' the DC government FK it never had (the one thing the slug row had and it lacked).
UPDATE essentials.districts d
SET government_id = (SELECT g.id FROM essentials.governments g WHERE g.name = 'District of Columbia')
WHERE d.geo_id = '1198'
  AND d.district_type = 'NATIONAL_LOWER'
  AND d.government_id IS NULL
  AND EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = 'District of Columbia');

-- 3. Remove the now-orphaned slug row. Refuses to fire while anything still points at it.
DELETE FROM essentials.districts d
WHERE d.geo_id = 'dc-national-lower'
  AND d.district_type = 'NATIONAL_LOWER'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o  WHERE o.district_id = d.id)
  -- inform.politicians.district_id is TEXT, not uuid — cast, or this is a 42883 operator error.
  AND NOT EXISTS (SELECT 1 FROM inform.politicians ip WHERE ip.district_id = d.id::text);

-- ---------------------------------------------------------------------------
-- Post-verify gate
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_rows int; v_offices int; v_holders int; v_gov int; v_slug int;
  v_covered_holders int; v_names text;
BEGIN
  -- Exactly one DC NATIONAL_LOWER row remains, and it is '1198'.
  SELECT COUNT(*) INTO v_rows FROM essentials.districts
   WHERE district_type = 'NATIONAL_LOWER' AND state = 'DC';
  IF v_rows <> 1 THEN
    RAISE EXCEPTION 'FAIL 1479: % DC NATIONAL_LOWER district row(s) remain (exp 1)', v_rows;
  END IF;

  SELECT COUNT(*) INTO v_slug FROM essentials.districts
   WHERE geo_id = 'dc-national-lower';
  IF v_slug <> 0 THEN
    RAISE EXCEPTION 'FAIL 1479: dc-national-lower still present (% row(s))', v_slug;
  END IF;

  -- '1198' now carries the government FK and all 3 offices.
  SELECT COUNT(*) INTO v_gov FROM essentials.districts d
   JOIN essentials.governments g ON g.id = d.government_id
   WHERE d.geo_id = '1198' AND d.district_type = 'NATIONAL_LOWER' AND g.name = 'District of Columbia';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'FAIL 1479: district 1198 is not FK''d to the District of Columbia government';
  END IF;

  SELECT COUNT(*) INTO v_offices FROM essentials.offices o
   JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '1198' AND d.district_type = 'NATIONAL_LOWER';
  IF v_offices <> 3 THEN
    RAISE EXCEPTION 'FAIL 1479: district 1198 holds % office(s) (exp 3)', v_offices;
  END IF;

  -- ADR 0002: occupancy must be completely undisturbed — office_terms is keyed on office_id.
  SELECT COUNT(och.politician_id), string_agg(p.full_name, ', ' ORDER BY p.full_name)
    INTO v_holders, v_names
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
  LEFT JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.geo_id = '1198' AND d.district_type = 'NATIONAL_LOWER';
  IF v_holders <> 3 THEN
    RAISE EXCEPTION 'FAIL 1479: % of 3 offices on 1198 have a current holder — occupancy was disturbed (got: %)', v_holders, COALESCE(v_names, '(none)');
  END IF;

  -- The whole point: a DC coordinate must now resolve to a district that has holders.
  SELECT COALESCE(SUM(h.n), 0) INTO v_covered_holders
  FROM (
    SELECT public.ST_X(public.ST_PointOnSurface(geometry)) AS lng,
           public.ST_Y(public.ST_PointOnSurface(geometry)) AS lat
    FROM essentials.geofence_boundaries
    WHERE geo_id = '1198' AND geometry IS NOT NULL
    LIMIT 1
  ) pt
  JOIN essentials.geofence_boundaries gb ON gb.geometry IS NOT NULL
  JOIN essentials.districts d ON d.geo_id = gb.geo_id AND d.district_type = 'NATIONAL_LOWER'
  JOIN LATERAL (
    SELECT COUNT(och2.politician_id) AS n
    FROM essentials.offices o2
    LEFT JOIN essentials.office_current_holder och2 ON och2.office_id = o2.id
    WHERE o2.district_id = d.id
  ) h ON true
  WHERE public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(pt.lng, pt.lat), 4326));
  IF v_covered_holders < 1 THEN
    RAISE EXCEPTION 'FAIL 1479: a DC coordinate still resolves to a NATIONAL_LOWER district with 0 holders';
  END IF;

  RAISE NOTICE 'PASS 1479: DC has exactly 1 NATIONAL_LOWER district (1198), FK''d to the District of Columbia government, holding 3 offices with 3 current holders (%); a DC coordinate now resolves to % holder(s). dc-national-lower removed.', v_names, v_covered_holders;
END $$;
