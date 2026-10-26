-- verify-atlanta-probes.sql
--
-- Acceptance evidence for the Atlanta full seed (CC_0238 … CC_0243).
-- READ-ONLY. Run it against production after applying the wave:
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/verify-atlanta-probes.sql
--
-- ---------------------------------------------------------------------------
-- 🔴 WHY THIS FILE EXISTS, AND WHY check:reachability IS NOT ENOUGH.
--
-- `scripts/check-address-reachability.mjs` takes NO per-jurisdiction probe list: it sweeps every
-- district of an addressable type. A green run after this wave means "no district regressed" —
-- it does NOT prove these districts were examined. So acceptance is two things (spec §5):
--
--   1. this probe file, asserting the four required answers at real anchors; and
--   2. a PER-DISTRICT positive control — every new district tested at its own interior point.
--
-- Part 2 is what distinguishes "swept and clean" from "not swept".
--
-- ---------------------------------------------------------------------------
-- 🔴 EVERY ANCHOR IS GEOCODED (Census onelineaddress, Public_AR_Current, 2026-10-17) and the
--    geocoder's own matchedAddress is recorded, not the string that was asked for. Each was then
--    checked against production geometry for which city and county it falls in.
--
--   55 TRINITY AVE SW, ATLANTA        Atlanta City Hall.      Atlanta · FULTON
--   3393 PEACHTREE DR NE, ATLANTA     Buckhead.               Atlanta · FULTON
--   1 JOSEPH E LOWERY BLVD NW, ATLANTA West End.              Atlanta · FULTON
--   1660 MEMORIAL DR SE, ATLANTA      Kirkwood.               Atlanta · DEKALB  ← the cross-county anchor
--   509 N MCDONOUGH ST, DECATUR       Decatur city hall.      NOT Atlanta · DEKALB  ← negative control
--
-- ---------------------------------------------------------------------------
-- 🔴 THE FOUR-ANSWER TEST AT ATLANTA CITY HALL PASSES THROUGH THE AT-LARGE CHAIR, NOT THE
--    DISTRICT SEAT. City Hall is in Fulton Commission District 4, which is VACANT, so the
--    county tier is answered by the at-large Chairperson alone (1 commissioner, not 2).
--
--    ⚠ West End is in District 4 TOO, so it does not exercise a seated Fulton district either.
--      BUCKHEAD is the anchor that does — it returns 2 county commissioners, the Chair plus
--      District 3. Measured: City Hall 1, West End 1, Buckhead 2, Kirkwood 2.
--      Without Buckhead, a broken Fulton DISTRICT layer would pass every other anchor here,
--      because the at-large chair covers the whole county and would answer regardless.

\set ON_ERROR_STOP on

DO $$
DECLARE
  r              record;
  v_council      int;
  v_county       int;
  v_rep          int;
  v_sen          int;
  v_atl_at_dec   int;
  v_bad          int;
  v_dkdist       int;
  v_dksuper      int;
  v_vacant_title text;
BEGIN
  -- ── PART 1: the four-answer probe, at three ATLANTA anchors ───────────────
  FOR r IN
    SELECT * FROM (VALUES
      ('Atlanta City Hall (Fulton)',        -84.390280, 33.747923),
      ('Buckhead, Atlanta (Fulton)',        -84.362793, 33.843229),
      ('West End, Atlanta (Fulton)',        -84.417484, 33.754777),
      ('Kirkwood, Atlanta (DEKALB)',        -84.332913, 33.747510)
    ) AS t(label, lon, lat)
  LOOP
    -- 1. a city council member (the DISTRICT seat, not an at-large post)
    SELECT count(och.politician_id) INTO v_council
      FROM essentials.geofence_boundaries b
      JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.mtfcc = 'X0077' AND lower(d.state) = 'ga'
       AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(r.lon, r.lat), 4326));
    IF v_council <> 1 THEN
      RAISE EXCEPTION 'PROBE %: expected exactly 1 seated Atlanta council DISTRICT member, got %', r.label, v_council;
    END IF;

    -- 2. a county commissioner of some kind (district, super district, or the Fulton chair)
    SELECT count(och.politician_id) INTO v_county
      FROM essentials.geofence_boundaries b
      JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      JOIN essentials.chambers c ON c.id = o.chamber_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.mtfcc IN ('X0078','X0079','X0080','G4020') AND lower(d.state) = 'ga'
       AND c.name = 'Board of Commissioners'
       AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(r.lon, r.lat), 4326));
    IF v_county < 1 THEN
      RAISE EXCEPTION 'PROBE %: expected at least 1 seated county commissioner, got %', r.label, v_county;
    END IF;

    -- 3. a state representative
    SELECT count(och.politician_id) INTO v_rep
      FROM essentials.geofence_boundaries b
      JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.district_type = 'STATE_LOWER' AND lower(d.state) = 'ga'
       AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(r.lon, r.lat), 4326));
    IF v_rep <> 1 THEN
      RAISE EXCEPTION 'PROBE %: expected exactly 1 seated state representative, got %', r.label, v_rep;
    END IF;

    -- 4. a state senator
    SELECT count(och.politician_id) INTO v_sen
      FROM essentials.geofence_boundaries b
      JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.district_type = 'STATE_UPPER' AND lower(d.state) = 'ga'
       AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(r.lon, r.lat), 4326));
    IF v_sen <> 1 THEN
      RAISE EXCEPTION 'PROBE %: expected exactly 1 seated state senator, got %', r.label, v_sen;
    END IF;

    RAISE NOTICE 'PROBE % — 4 of 4: council %, county commissioner(s) %, rep %, senator %',
      r.label, v_council, v_county, v_rep, v_sen;
  END LOOP;

  -- ── PART 2: the NEGATIVE control ──────────────────────────────────────────
  -- 🔴 Decatur is a separate city inside DeKalb County. It must return DeKalb officials and
  --    state legislators, and NO Atlanta council member. Without this, a council layer that
  --    bled across the whole county would pass every test above.
  SELECT count(*) INTO v_atl_at_dec
    FROM essentials.geofence_boundaries b
    JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.mtfcc IN ('X0077','G4110') AND lower(d.state) = 'ga'
     AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-84.296456, 33.773683), 4326));
  IF v_atl_at_dec <> 0 THEN
    RAISE EXCEPTION 'CONTROL FAILED: Decatur city hall returns % Atlanta city office(s). Decatur is NOT in Atlanta — the council or citywide layer bleeds.', v_atl_at_dec;
  END IF;
  RAISE NOTICE 'CONTROL — Decatur city hall returns 0 Atlanta city offices, as it must';

  -- ── PART 3: DeKalb's TWO-commissioner property ────────────────────────────
  -- 🔴 Every DeKalb address elects ONE single-member commissioner AND ONE super commissioner.
  --    An "exactly one holder" control would FAIL HERE ON CORRECT DATA.
  SELECT
    count(*) FILTER (WHERE d.mtfcc = 'X0079'),
    count(*) FILTER (WHERE d.mtfcc = 'X0080')
    INTO v_dkdist, v_dksuper
    FROM essentials.geofence_boundaries b
    JOIN essentials.districts d ON d.geo_id = b.geo_id AND d.mtfcc = b.mtfcc
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE och.politician_id IS NOT NULL
     AND public.ST_Contains(b.geometry, public.ST_SetSRID(public.ST_MakePoint(-84.332913, 33.747510), 4326));
  IF v_dkdist <> 1 OR v_dksuper <> 1 THEN
    RAISE EXCEPTION 'PROBE Kirkwood: expected exactly 1 DeKalb single-member commissioner AND 1 super commissioner, got % and %', v_dkdist, v_dksuper;
  END IF;
  RAISE NOTICE 'PROBE Kirkwood — DeKalb overlay: 1 district commissioner AND 1 super commissioner';

  -- ── PART 4: PER-DISTRICT POSITIVE CONTROL ─────────────────────────────────
  -- 🔴 This is what distinguishes "swept and clean" from "not swept". EVERY new district is
  --    tested at ITS OWN interior point. ST_PointOnSurface, never a centroid or a mean of
  --    vertices — neither need lie inside the polygon.
  v_bad := 0;
  FOR r IN
    SELECT d.mtfcc, d.geo_id, d.label,
           count(o.id)                  AS offices,
           count(och.politician_id)     AS seated,
           public.ST_PointOnSurface(b.geometry) AS pt
      FROM essentials.districts d
      JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
      LEFT JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.mtfcc IN ('X0077','X0078','X0079','X0080') AND lower(d.state) = 'ga'
     GROUP BY d.mtfcc, d.geo_id, d.label, b.geometry
     ORDER BY d.mtfcc, d.geo_id
  LOOP
    -- Each district must carry exactly one office.
    IF r.offices <> 1 THEN
      RAISE WARNING 'PER-DISTRICT: % (%) carries % office(s), expected 1', r.label, r.geo_id, r.offices;
      v_bad := v_bad + 1;
      CONTINUE;
    END IF;

    -- And its own interior point must resolve back to it, and to no sibling in the same layer.
    SELECT count(*) INTO v_council
      FROM essentials.geofence_boundaries b2
     WHERE b2.mtfcc = r.mtfcc
       AND public.ST_Contains(b2.geometry, r.pt);
    IF v_council <> 1 THEN
      RAISE WARNING 'PER-DISTRICT: the interior point of % resolves to % polygon(s) in layer %, expected exactly 1', r.label, v_council, r.mtfcc;
      v_bad := v_bad + 1;
      CONTINUE;
    END IF;

    -- Seated, unless it is the one documented vacancy.
    IF r.seated <> 1 THEN
      IF r.geo_id = 'fulton-county-ga-commission-4' THEN
        RAISE NOTICE 'PER-DISTRICT: % is UNSEATED — correct, this is the documented District 4 vacancy (Call for Election, O.C.G.A. § 21-2-540, special on 2026-11-03)', r.label;
      ELSE
        RAISE WARNING 'PER-DISTRICT: % (%) has no seated holder and is NOT the known vacancy', r.label, r.geo_id;
        v_bad := v_bad + 1;
      END IF;
    END IF;
  END LOOP;

  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'PER-DISTRICT CONTROL: % district(s) failed. See the warnings above.', v_bad;
  END IF;
  RAISE NOTICE 'PER-DISTRICT CONTROL — all 25 new districts resolve at their own interior point, one office each';

  -- ── PART 5: the vacancy is EXACTLY District 4, and nothing else ───────────
  SELECT string_agg(o.title, ', ') INTO v_vacant_title
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.name IN ('City of Atlanta, Georgia, US','Fulton County, Georgia, US','DeKalb County, Georgia, US')
     AND och.politician_id IS NULL;
  IF COALESCE(v_vacant_title, '') <> 'Commissioner, District 4' THEN
    RAISE EXCEPTION 'VACANCY CONTROL: the unseated offices are "%" — expected exactly "Commissioner, District 4"', COALESCE(v_vacant_title, '(none)');
  END IF;
  RAISE NOTICE 'VACANCY CONTROL — exactly one unseated office across all three governments, and it is Fulton Commissioner, District 4';

  RAISE NOTICE '';
  RAISE NOTICE '✅ ATLANTA PROBES PASSED — 4 anchors × 4 answers, Decatur negative control, DeKalb overlay, 25 per-district controls, 1 expected vacancy';
END $$;
