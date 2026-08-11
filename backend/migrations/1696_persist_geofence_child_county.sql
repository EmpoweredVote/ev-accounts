-- 1696_persist_geofence_child_county.sql
--
-- Persist the child -> county spatial assignment that the coverage map recomputed on every cold load.
--
-- WHY
--
-- buildJurisdictions() assigned every place / school / county-subdivision to the county it OVERLAPS
-- MOST, via a correlated subquery doing public.ST_Area(public.ST_Intersection(...)) per candidate
-- county. Measured 2026-08-11: that was 15.9 s of work across the 13 tracked states (ca 5.8 s, in 2.1,
-- ut 2.1, wi 2.0, tx 1.9) and the single largest cost in the endpoint -- which had been returning
-- HTTP 500 on a 30 s statement timeout until migration-adjacent fixes today (commits d11b0334,
-- fb469a54) brought it to ~10 s cold.
--
-- The assignment depends ONLY on geometry, so it changes when boundaries are reloaded and at no other
-- time. Recomputing it per request was pure waste. Reading it from here instead: 15,875 ms -> 282 ms
-- across all 13 states, verified byte-identical per state before this migration was written.
--
-- This is NOT the "never cache current" anti-pattern from ADR 0002 / CLAUDE.md. That rule exists
-- because occupancy changes when the CALENDAR advances and no trigger fires. Geometry does not change
-- on its own -- only a boundary load changes it, which is an explicit operator action with a defined
-- refresh step (below).
--
-- FIRST MATERIALIZED VIEW IN THE `essentials` SCHEMA. There was no precedent, so two things are set
-- deliberately rather than inherited:
--   * GRANT SELECT to ev_api only. geofence_boundaries also grants SELECT to anon/authenticated, but
--     this view is read solely by the admin coverage services, and the essentials frontend never
--     queries essentials.* directly (CLAUDE.md). Least privilege.
--   * A UNIQUE index on (child_geo_id, child_mtfcc) -- required for REFRESH ... CONCURRENTLY, and
--     correct on its own terms: geofence_boundaries.geo_id is NOT unique by itself, it is unique per
--     mtfcc.
--
-- REFRESHING IT -- REQUIRED AFTER ANY BOUNDARY LOAD:
--
--     REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;   -- ~17 s
--
-- CONCURRENTLY keeps the coverage dashboard readable during the rebuild and cannot run inside a
-- transaction block. Staleness is OBSERVABLE, not silent: essentials.geofence_child_county_stale
-- lists children with no mapping row, and buildJurisdictions logs a warning naming the state and
-- count when it sees any (a stale child degrades to an unassigned county, never to a dropped row).
--
-- 🔴 DO NOT rebuild this with a DISTINCT ON spatial join. It is ~20% faster and CHANGED THE COUNTY
-- ASSIGNED in ca/in/or/ut/wi, because a child that merely TOUCHES a neighbouring county intersects it
-- with area 0, so ties resolve differently than the correlated `ORDER BY ... DESC LIMIT 1`. The view
-- below deliberately uses the SAME correlated form as the query it replaces, which is why its output
-- matches. A centroid shortcut is also wrong -- San Francisco's centroid lands in the ocean.
--
-- Idempotent: guarded CREATEs, and the gate asserts an END STATE.

BEGIN;

DROP MATERIALIZED VIEW IF EXISTS essentials.geofence_child_county;

CREATE MATERIALIZED VIEW essentials.geofence_child_county AS
SELECT child.geo_id AS child_geo_id,
       child.mtfcc  AS child_mtfcc,
       child.state  AS state,
       (SELECT cc.geo_id
          FROM essentials.geofence_boundaries cc
         WHERE cc.state = child.state
           AND cc.mtfcc = 'G4020'
           AND public.ST_Intersects(cc.geometry, child.geometry)
         ORDER BY public.ST_Area(public.ST_Intersection(cc.geometry, child.geometry)) DESC
         LIMIT 1) AS county_geo_id
  FROM essentials.geofence_boundaries child
 WHERE child.mtfcc IN ('G4110', 'G5420', 'G5400', 'G5410');

-- Deliberately NOT filtered on child.name IS NOT NULL. The read path applies that filter itself;
-- keeping presentation out of the mapping means a later name backfill needs no refresh.

CREATE UNIQUE INDEX geofence_child_county_pk
    ON essentials.geofence_child_county (child_geo_id, child_mtfcc);
CREATE INDEX geofence_child_county_state
    ON essentials.geofence_child_county (state);

GRANT SELECT ON essentials.geofence_child_county TO ev_api;

COMMENT ON MATERIALIZED VIEW essentials.geofence_child_county IS
  'Child (place/school/county-subdivision) -> county by GREATEST OVERLAP, not centroid. Populated by '
  'migration 1696. Depends only on geometry: REFRESH MATERIALIZED VIEW CONCURRENTLY after any '
  'boundary load. Staleness is visible in essentials.geofence_child_county_stale.';

-- Staleness is observable, in the house idiom of essentials.offices_missing_terms.
CREATE OR REPLACE VIEW essentials.geofence_child_county_stale AS
SELECT child.state, child.mtfcc, child.geo_id, child.name
  FROM essentials.geofence_boundaries child
  LEFT JOIN essentials.geofence_child_county m
         ON m.child_geo_id = child.geo_id AND m.child_mtfcc = child.mtfcc
 WHERE child.mtfcc IN ('G4110', 'G5420', 'G5400', 'G5410')
   AND m.child_geo_id IS NULL;

GRANT SELECT ON essentials.geofence_child_county_stale TO ev_api;

DO $$
DECLARE
  v_rows       integer;
  v_children   integer;
  v_stale      integer;
  v_assigned   integer;
  v_wrong_st   integer;
  v_not_county integer;
  v_no_touch   integer;
  v_single_bad integer;
BEGIN
  SELECT count(*) INTO v_rows     FROM essentials.geofence_child_county;
  SELECT count(*) INTO v_children FROM essentials.geofence_boundaries
   WHERE mtfcc IN ('G4110', 'G5420', 'G5400', 'G5410');

  -- END STATE: one mapping row per child, no exceptions.
  IF v_rows <> v_children THEN
    RAISE EXCEPTION '1696: % mapping rows for % children', v_rows, v_children;
  END IF;

  SELECT count(*) INTO v_stale FROM essentials.geofence_child_county_stale;
  IF v_stale <> 0 THEN
    RAISE EXCEPTION '1696: staleness view reports % children with no mapping row', v_stale;
  END IF;

  SELECT count(county_geo_id) INTO v_assigned FROM essentials.geofence_child_county;

  -- Every assigned county must be a real county IN THE SAME STATE. Catches a cross-state join.
  SELECT count(*) INTO v_wrong_st
    FROM essentials.geofence_child_county m
    JOIN essentials.geofence_boundaries cc
      ON cc.geo_id = m.county_geo_id AND cc.mtfcc = 'G4020'
   WHERE cc.state <> m.state;
  IF v_wrong_st <> 0 THEN
    RAISE EXCEPTION '1696: % children assigned a county in a different state', v_wrong_st;
  END IF;

  SELECT count(*) INTO v_not_county
    FROM essentials.geofence_child_county m
   WHERE m.county_geo_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries cc
                      WHERE cc.geo_id = m.county_geo_id AND cc.mtfcc = 'G4020');
  IF v_not_county <> 0 THEN
    RAISE EXCEPTION '1696: % assigned geo_ids are not G4020 counties', v_not_county;
  END IF;

  -- The real correctness property, and it is DETERMINISTIC unlike an area tie-break:
  -- an assigned county must actually intersect its child.
  SELECT count(*) INTO v_no_touch
    FROM essentials.geofence_child_county m
    JOIN essentials.geofence_boundaries child
      ON child.geo_id = m.child_geo_id AND child.mtfcc = m.child_mtfcc
    JOIN essentials.geofence_boundaries cc
      ON cc.geo_id = m.county_geo_id AND cc.mtfcc = 'G4020'
   WHERE NOT public.ST_Intersects(cc.geometry, child.geometry);
  IF v_no_touch <> 0 THEN
    RAISE EXCEPTION '1696: % children assigned a county they do not intersect', v_no_touch;
  END IF;

  -- Where exactly ONE county intersects, the answer is forced -- no tie to break. Assert those
  -- exactly. This covers the overwhelming majority and needs no assumption about ordering.
  -- (Deliberately NOT re-running the full ORDER BY ... LIMIT 1: among equal areas its pick is
  -- arbitrary, so a re-run could differ and fail a correct view. Full per-state equivalence against
  -- the old query was verified out-of-band before this migration.)
  SELECT count(*) INTO v_single_bad
    FROM (
      SELECT m.child_geo_id, m.child_mtfcc, m.county_geo_id,
             (SELECT count(*) FROM essentials.geofence_boundaries cc
               WHERE cc.state = m.state AND cc.mtfcc = 'G4020'
                 AND public.ST_Intersects(cc.geometry, child.geometry))          AS n_int,
             (SELECT min(cc.geo_id) FROM essentials.geofence_boundaries cc
               WHERE cc.state = m.state AND cc.mtfcc = 'G4020'
                 AND public.ST_Intersects(cc.geometry, child.geometry))          AS only_one
        FROM essentials.geofence_child_county m
        JOIN essentials.geofence_boundaries child
          ON child.geo_id = m.child_geo_id AND child.mtfcc = m.child_mtfcc
    ) q
   WHERE q.n_int = 1 AND q.county_geo_id IS DISTINCT FROM q.only_one;
  IF v_single_bad <> 0 THEN
    RAISE EXCEPTION '1696: % single-county children disagree with the only county they intersect',
      v_single_bad;
  END IF;

  RAISE NOTICE '1696 OK: % children mapped, % assigned a county, 0 stale, 0 cross-state, 0 non-intersecting',
    v_rows, v_assigned;
END $$;

COMMIT;
