-- CC_0189_in_two_town_geo_ids.sql
-- Slot CC_0189 RESERVED from the allocator (steward.mjs slot CC).
--
-- Sets essentials.governments.geo_id on the LAST TWO town governments anywhere in the database that
-- are seeded, occupied and unreachable from any browse URL: Ellettsville and Stinesville, Indiana.
-- Creates NO people, NO terms, NO districts, NO chambers and NO offices. Touches one column on two
-- rows.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE DEFECT. Identical to CC_0183 (Wichita/Lexington/St. Louis/Bloomington) and CA_0299 (the 55
-- LA County cities). A landing-page chip resolves through
--
--     FROM essentials.governments g JOIN essentials.chambers ch ON ch.government_id = g.id
--     JOIN essentials.offices o ON o.chamber_id = ch.id ...
--     WHERE g.geo_id = ANY($1)
--
-- so a government with a NULL geo_id cannot be named by any browse URL. Address search is unaffected
-- — it goes districts -> offices -> office_current_holder and never touches essentials.governments —
-- which is why both towns answer an address today while having no chip. 6 seated officials:
-- Ellettsville 4, Stinesville 2.
--
-- 🟢 BOTH CODES READ OUT OF THE TOWN'S OWN WIRING, never composed from a name:
--     governments -> chambers -> offices -> districts (mtfcc='G4110')
--       joined to essentials.geofence_boundaries ON (geo_id, mtfcc)
-- i.e. the place code already attached to that town's own offices, and only where it carries a real
-- polygon. Measured 2026-10-06, all clean:
--
--   1820800  G4110  Town of Ellettsville, Indiana, US   polygon ✓  TIGER 'Ellettsville'   4 seated
--   1873232  G4110  Town of Stinesville, Indiana, US    polygon ✓  TIGER 'Stinesville'    2 seated
--
--   * 1:1 — neither town resolves to two codes, neither code is claimed by two governments
--   * zero collisions against any existing governments.geo_id
--   * the INDEPENDENT geofence_boundaries.name (TIGER's own label) agrees with both names exactly
--
-- ⚠ NOT A DEFECT, AND DELIBERATELY NOT TOUCHED: the other NULL-geo_id governments in Indiana are
-- townships (Bean Blossom, Perry, Van Buren, …), school corporations and Indianapolis Public
-- Schools. Those are not chip-bearing tiers — school districts are search-only, and townships have
-- never been surfaced on the landing page — so a geo_id would buy them nothing. Only the two TOWN
-- governments are in scope here.
--
-- ⚠ NO BANNER FOLLOWS. Checked: neither label inherits an existing CURATED_LOCAL key, so both take
-- states/IN-v2.jpg (Indiana Dunes). That is correct and needs no frontend guard — unlike the 55,
-- where "South El Monte" inherited cities/el-monte.jpg and needed match:'exact' on 'el monte'.
--
-- Idempotent: the UPDATE is value-guarded (geo_id IS NULL), so re-running is a no-op. Ends with a
-- post-verify gate that RAISEs.
--
-- No migration runner exists in this repo; this file records SQL applied by hand via
-- mcp__supabase-local__execute_sql as the postgres role.

CREATE TEMP TABLE gov_fix(name text, geo_id text) ON COMMIT DROP;

INSERT INTO gov_fix VALUES
    ('Town of Ellettsville, Indiana, US', '1820800'),
    ('Town of Stinesville, Indiana, US',  '1873232');

-- ─── 1. Pre-flight: the name must name exactly one row ────────────────────────
DO $$
DECLARE v_bad int;
BEGIN
  SELECT count(*) INTO v_bad FROM gov_fix f
   WHERE (SELECT count(*) FROM essentials.governments g WHERE g.name = f.name) <> 1;
  IF v_bad <> 0 THEN
    RAISE EXCEPTION 'CC_0189 pre-flight: % name(s) do not match exactly one government row', v_bad;
  END IF;
END $$;

-- ─── 2. The write ─────────────────────────────────────────────────────────────
UPDATE essentials.governments g
   SET geo_id = f.geo_id
  FROM gov_fix f
 WHERE g.name = f.name
   AND g.geo_id IS NULL;

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  r record;
  v_dupe int; v_reach int; v_browse int; v_nonin int;
BEGIN
  -- 1. Both carry exactly the geo_id they were verified against.
  FOR r IN SELECT * FROM gov_fix LOOP
    PERFORM 1 FROM essentials.governments g WHERE g.name = r.name AND g.geo_id = r.geo_id;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'CC_0189 gate: % does not carry geo_id % — it has %',
        r.name, r.geo_id,
        coalesce((SELECT geo_id FROM essentials.governments WHERE name = r.name), 'NULL (or no such row)');
    END IF;
  END LOOP;

  -- 2. 🔴 Each code must name a district that exists WITH A POLYGON.
  SELECT count(*) INTO v_reach FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1 FROM essentials.districts d
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc
     WHERE d.geo_id = f.geo_id);
  IF v_reach <> 0 THEN
    RAISE EXCEPTION 'CC_0189 gate: % geo_id(s) name no district with a polygon', v_reach;
  END IF;

  -- 3. 🔴 geo_id must stay unique across the WHOLE table.
  SELECT count(*) INTO v_dupe FROM (
    SELECT geo_id FROM essentials.governments WHERE geo_id IS NOT NULL
     GROUP BY geo_id HAVING count(*) > 1) x;
  IF v_dupe <> 0 THEN
    RAISE EXCEPTION 'CC_0189 gate: % government geo_id(s) are now shared by more than one row', v_dupe;
  END IF;

  -- 4. 🔴 Nothing outside Indiana may have been touched.
  SELECT count(*) INTO v_nonin FROM essentials.governments g
    JOIN gov_fix f ON f.name = g.name
   WHERE g.state IS DISTINCT FROM 'IN';
  IF v_nonin <> 0 THEN
    RAISE EXCEPTION 'CC_0189 gate: % updated government(s) are not in IN', v_nonin;
  END IF;

  -- 5. 🔴🔴 THE POINT: both must answer the REAL browse join, not merely carry a column.
  SELECT count(*) INTO v_browse FROM gov_fix f
   WHERE NOT EXISTS (
     SELECT 1
       FROM essentials.governments g
       JOIN essentials.chambers ch ON ch.government_id = g.id
       JOIN essentials.offices o   ON o.chamber_id = ch.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
      WHERE g.geo_id = f.geo_id
        AND och.politician_id IS NOT NULL);
  IF v_browse <> 0 THEN
    RAISE EXCEPTION 'CC_0189 gate: % of the two still resolve to no seated official via the browse join', v_browse;
  END IF;

  RAISE NOTICE 'CC_0189 OK: Ellettsville and Stinesville carry polygon-backed place codes and both answer the browse join';
END $$;
