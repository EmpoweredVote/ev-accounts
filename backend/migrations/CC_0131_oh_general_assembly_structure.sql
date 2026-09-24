-- CC_0131_oh_general_assembly_structure.sql
-- Knight Foundation program, wave OH-2 (structure half). Slot RESERVED from the allocator.
--
-- Ohio has NO state legislative offices and NO legislative chambers today: production holds 23
-- Ohio offices in total -- 15 US House, 2 US Senate, 5 statewide executives, plus one US Senate
-- CANDIDATE office (holding Sherrod Brown, which must never be counted as a third senator).
-- OH-1 loaded the geography (99 STATE_LOWER + 33 STATE_UPPER, vintage proved on all 132 polygons
-- against the Secretary of State's own shapefiles), so this migration is a clean seed with
-- nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 132 offices, one per district OH-1 loaded;
--   3. flags the TWO seats that are vacant today.
--
-- Creates NO people and NO terms -- CC_0132 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. TIGER writes Ohio's legislative
-- GEOIDs as state FIPS + district code, so Senate District 31 is '39031' and House District 71 is
-- '39071' -- and Ohio's 88 COUNTY districts occupy '39001'..'39175'. Every Senate district's
-- geo_id is also a county's. Nothing here matches on a number or a label; the office insert joins
-- districts by district_type and state, and the gate below asserts that no COUNTY district picked
-- up a legislative office.
-- ⚠ '39153' collides ACROSS STATES as well: it is Summit County (Akron's own county, state '39')
-- AND a Mississippi ZCTA (state '28'). Summit sits outside the legislative code range, so it is
-- not at risk here, but slice 16 will meet the same id.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Ohio' row, 2c6488fa-b23b-4e78-b4f5-8caa0b813d36 (type STATE, state OH, geo_id 39).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate asserts it.
--
-- 🔴🔴 TWO SEATS ARE VACANT, AND ONLY THE CHAMBERS' OWN DIRECTORIES KNOW IT.
--   · HD-66 -- Sharon Ray (R-Wadsworth) resigned effective 2026-09-14 at 11:59 pm to become
--     Medina County Recorder, sworn in 2026-09-15. The House's own press release of 2026-09-14
--     states the time; the first vacant day is therefore 2026-09-15 and vacant_since says so.
--     ⚠ OPEN STATES STILL LISTS SHARON RAY AS THE SITTING MEMBER. The aggregator is nine days
--     stale and shows 99 of 99 House seats filled. This is MN-2's trap with the roles swapped:
--     there the chamber's own page was stale and the aggregator was right.
--   · SD-13 -- Nathan Manning took the bench of the Ninth District Court of Appeals on
--     2026-08-03 and cannot hold both offices. 🔴 vacant_since IS DELIBERATELY LEFT NULL: no
--     source publishes the resignation's effective date. Reporting says "late July or early
--     August"; 2026-08-03 is an UPPER BOUND on the vacancy's start, not the date it began, and
--     CLAUDE.md forbids writing a vacancy whose start date is unknown. The flag is a fact; the
--     date is not. Dating it is a recorded debt.
--   Both are written is_vacant with NO office_terms row at all -- there is no predecessor term
--   to close, because these offices are being created now. They therefore land in the FLAGGED
--   half of essentials.offices_missing_terms, which is where SC-4 put its vacant Richland seat.
--
-- 🔴 THE MISSING-TERMS BASELINE IS NOT THE ONE EVERY EARLIER WAVE ASSERTED. Measured in this
-- session: 427 total / 189 flagged / 238 unflagged, not the 823/655 that MN-2 through SC-4 all
-- closed on. The view is unchanged; a concurrent LA County school-board backfill in the CA_
-- namespace moved it and is still running. This migration therefore asserts only its OWN two
-- rows, never a global total.
--
-- 🔴 PARTY IS NOT WRITTEN. Both directories carry it; party lives on races.primary_party.
-- ⚠ The vacant HD-66 tile still carries the CSS class 'republican' -- that is the last party to
-- hold the seat, not a current occupant, and it is one more reason not to read party from a roster.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and the vacancy UPDATE is guarded on its own
-- current value. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: Ohio Const. art. II s 2 -- Representatives two years, Senators four.
-- official_count: 99 and 33, fixed by Ohio Const. art. XI s 2 and s 3, and equal to the polygon
-- counts OH-1 loaded because Ohio is single-member in both chambers.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '2c6488fa-b23b-4e78-b4f5-8caa0b813d36', 'Ohio House of Representatives', 'Ohio House of Representatives', 99, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '2c6488fa-b23b-4e78-b4f5-8caa0b813d36' AND name = 'Ohio House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '2c6488fa-b23b-4e78-b4f5-8caa0b813d36', 'Ohio Senate', 'Ohio Senate', 33, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '2c6488fa-b23b-4e78-b4f5-8caa0b813d36' AND name = 'Ohio Senate');

-- ─── 2. The 132 offices, one per district OH-1 loaded ─────────────────────────
-- Guarded on district_id: Ohio has no legislative office at all today, so this inserts 132 on a
-- first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'OH', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'Ohio House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Ohio Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = '2c6488fa-b23b-4e78-b4f5-8caa0b813d36' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'oh'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 3. The two vacancies ─────────────────────────────────────────────────────
-- Keyed on (geo_id, district_type), never geo_id alone.

UPDATE essentials.offices o
   SET is_vacant = true, vacant_since = DATE '2026-09-15'
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND lower(d.state) = 'oh' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '39066'
   AND (o.is_vacant IS DISTINCT FROM true OR o.vacant_since IS DISTINCT FROM DATE '2026-09-15');

-- SD-13: flagged, but NO vacant_since — the effective date of the resignation is not published.
UPDATE essentials.offices o
   SET is_vacant = true
  FROM essentials.districts d
 WHERE d.id = o.district_id
   AND lower(d.state) = 'oh' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '39013'
   AND o.is_vacant IS DISTINCT FROM true;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_house_ch   int;
  v_senate_ch  int;
  v_lower      int;
  v_upper      int;
  v_chambers   int;
  v_mistitled  int;
  v_county     int;
  v_vacant     int;
  v_hd66       int;
  v_sd13       int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '2c6488fa-b23b-4e78-b4f5-8caa0b813d36' AND name = 'State of Ohio' AND type = 'STATE' AND state = 'OH';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'OH-2 structure: the State of Ohio government row is not what this migration assumed (got %)', v_gov;
  END IF;

  SELECT count(*) FILTER (WHERE name = 'Ohio House of Representatives'),
         count(*) FILTER (WHERE name = 'Ohio Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = '2c6488fa-b23b-4e78-b4f5-8caa0b813d36';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'OH-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh';
  IF v_lower <> 99 OR v_upper <> 33 THEN
    RAISE EXCEPTION 'OH-2 structure: expected 99 House / 33 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with ZERO
  -- offices is caught too — an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'OH-2 structure: an Ohio legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'OH-2 structure: Ohio legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'OH-2 structure: % legislative office(s) carry the wrong title', v_mistitled;
  END IF;

  -- 🔴 THE COLLISION GATE. If anything here had matched on geo_id alone, a county would have
  -- picked up a legislative office. Ohio's 88 COUNTY districts must still hold exactly the
  -- offices they held before — including Summit '39153', this slice's own county.
  SELECT count(*) INTO v_county
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text = 'COUNTY'
    AND o.title IN ('Representative','Senator');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'OH-2 structure: % Ohio COUNTY district(s) picked up a legislative office — a geo_id-only join', v_county;
  END IF;

  -- The two vacancies, asserted individually rather than as a total, so a vacancy landing on the
  -- WRONG district cannot pass by keeping the count right.
  SELECT count(*) INTO v_vacant
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER') AND o.is_vacant;
  IF v_vacant <> 2 THEN
    RAISE EXCEPTION 'OH-2 structure: expected exactly 2 vacant legislative offices, got %', v_vacant;
  END IF;

  SELECT count(*) INTO v_hd66
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '39066'
    AND o.is_vacant AND o.vacant_since = DATE '2026-09-15';
  IF v_hd66 <> 1 THEN
    RAISE EXCEPTION 'OH-2 structure: HD-66 is not flagged vacant from 2026-09-15 (got %)', v_hd66;
  END IF;

  SELECT count(*) INTO v_sd13
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'oh' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '39013'
    AND o.is_vacant AND o.vacant_since IS NULL;
  IF v_sd13 <> 1 THEN
    RAISE EXCEPTION 'OH-2 structure: SD-13 is not flagged vacant with an UNKNOWN start (got %)', v_sd13;
  END IF;

  RAISE NOTICE 'OH-2 structure OK: 2 chambers, 99 House + 33 Senate offices, 2 vacant (HD-66 dated, SD-13 undated), 0 on a county';
END $$;

COMMIT;
