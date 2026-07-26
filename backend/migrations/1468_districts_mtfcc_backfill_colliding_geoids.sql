-- 1468_districts_mtfcc_backfill_colliding_geoids.sql
-- Backfill essentials.districts.mtfcc for the 35 district rows that sit on a COLLIDING geo_id and
-- have no mtfcc, so the electionService dual-map fallback stops joining unconstrained. Idempotent.
--
-- THE BUG THIS CLOSES. essentials.geofence_boundaries.geo_id is NOT unique on its own: 861 geo_ids
--   exist under more than one mtfcc (183 under three), because TIGER layers share a numbering
--   namespace. backend/src/lib/geoIdGuard.ts documents the incident this caused — "49021" is
--   simultaneously Utah Senate District 21, Utah House District 21 AND Iron County, which is the
--   "Alpine community shows Iron County" bug. Two of the colliding rows fixed here are literally
--   Alpine (geo_id 4900540).
--
--   Most read paths are protected by MTFCC_DISTRICT_TYPE_GUARD or an equivalent inline matrix. ONE
--   is not, conditionally: backend/src/lib/electionService.ts (the dual-map LATERAL, ~line 303)
--   joins
--       gbo.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc = '' OR gbo.mtfcc = d.mtfcc)
--   so when districts.mtfcc is NULL or '' the mtfcc predicate DISAPPEARS. It sits inside a
--   UNION ALL ... LIMIT 1 with no ORDER BY, so which geometry wins is arbitrary — an election could
--   be served for the wrong geography. Populating mtfcc makes the existing predicate bite; no query
--   change needed.
--
-- SCOPE IS DELIBERATELY THE 35, NOT ALL 1,260 NULL/EMPTY ROWS. For a geo_id with only ONE
--   geofence row the missing predicate is harmless: the LIMIT 1 has exactly one candidate and picks
--   it correctly. Only colliding geo_ids can mis-resolve, so only they are in scope. The other
--   ~1,225 NULL/empty rows are untouched, on purpose.
--
-- NO VALUE IS GUESSED. The correct mtfcc is DERIVED per row, at run time, as
--     {mtfcc present in geofence_boundaries for this geo_id}
--       INTERSECT {mtfcc permitted for this district_type by geoIdGuard's matrix}
--   and the row is updated ONLY when that intersection has exactly ONE element (the
--   HAVING count(DISTINCT gb.mtfcc) = 1 below). Verified against prod 2026-07-26: all 35 rows
--   resolve unambiguously — 0 ambiguous, 0 with no match — so nothing is left to judgement:
--     18013  COUNTY x17 + JUDICIAL x1 (Brown County, IN)  -> G4020   [G4020,G5210,G5220 available]
--     18033/18037/18039/18040/18044/18046 STATE_UPPER      -> G5210
--     18045/18046 STATE_LOWER                             -> G5220
--     0622230 LOCAL x4 + LOCAL_EXEC (El Monte, CA)        -> G4110   [G4110,G5420 available]
--     4900540 LOCAL + LOCAL_EXEC (Alpine, UT)             -> G4110   [G4110,G5420 available]
--     0606000 LOCAL_EXEC (Berkeley, CA)                   -> G4110   [G4110,G5400 available]
--     4900870 SCHOOL (Salt Lake City School District)     -> G5420   [G4110,G5420 available]
--   Because the rule is derived rather than hardcoded, a re-run on drifted data cannot invent a
--   value: anything newly ambiguous is simply skipped and reported by the gate.
--
-- WHY NOT A district_type -> mtfcc LOOKUP. Because the column's EXISTING contents are not a reliable
--   convention to copy. Among the 5,804 populated rows: COUNTY carries G5220 on 49 rows and
--   JUDICIAL carries G5220 on 37 (more than its 11 G4020), both of which CONTRADICT geoIdGuard's
--   matrix; STATE_LOWER has 80 rows on G5210 and STATE_UPPER 40 on G5220, i.e. swapped. That looks
--   like the same collision baked into the column by earlier seeders. Deriving from the geofence
--   layers actually present, filtered by the guard, sidesteps the bad precedent entirely.
--   THOSE PRE-EXISTING WRONG VALUES ARE NOT CORRECTED HERE — that is a separate, larger question
--   about rows already relied upon. The gate REPORTS the count so it stays visible.
BEGIN;

-- =============================================================================
-- Pre-flight: the guard module's contract still looks the way this migration assumes
-- =============================================================================
DO $$
DECLARE v_colliding int;
BEGIN
  SELECT count(*) INTO v_colliding FROM (
    SELECT geo_id FROM essentials.geofence_boundaries
     GROUP BY geo_id HAVING count(DISTINCT mtfcc) > 1
  ) c;
  IF v_colliding = 0 THEN
    RAISE EXCEPTION 'no colliding geo_ids found — geofence_boundaries looks unexpectedly clean; '
                    're-verify before backfilling';
  END IF;
  RAISE NOTICE 'colliding geo_ids in geofence_boundaries: %', v_colliding;
END $$;

-- =============================================================================
-- Backfill, derived and self-limiting
-- =============================================================================
WITH permitted(district_type, mtfcc) AS (VALUES
  -- Mirrors MTFCC_DISTRICT_TYPE_GUARD in backend/src/lib/geoIdGuard.ts. Only the concrete TIGER
  -- layers are listed: the guard's X% catch-all branches are intentionally omitted, because an
  -- X-prefixed custom layer is never ambiguous with a TIGER geo_id in the collision set.
  ('STATE_UPPER','G5210'),
  ('STATE_LOWER','G5220'),
  ('NATIONAL_LOWER','G5200'),
  ('COUNTY','G4020'),
  ('JUDICIAL','G4020'),
  ('LOCAL','G4040'),('LOCAL','G4110'),('LOCAL','G4120'),
  ('LOCAL_EXEC','G4040'),('LOCAL_EXEC','G4110'),('LOCAL_EXEC','G4120'),
  ('SCHOOL','G5400'),('SCHOOL','G5410'),('SCHOOL','G5420')
),
colliding AS (
  SELECT geo_id FROM essentials.geofence_boundaries
   GROUP BY geo_id HAVING count(DISTINCT mtfcc) > 1
),
resolved AS (
  SELECT d.id, min(gb.mtfcc) AS mtfcc            -- min() over a set proven to hold exactly one
    FROM essentials.districts d
    JOIN colliding c              ON c.geo_id = d.geo_id
    JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
    JOIN permitted p              ON p.district_type = d.district_type AND p.mtfcc = gb.mtfcc
   WHERE d.mtfcc IS NULL OR d.mtfcc = ''
   GROUP BY d.id
  HAVING count(DISTINCT gb.mtfcc) = 1            -- UNAMBIGUOUS ONLY; never guess
)
UPDATE essentials.districts d
   SET mtfcc = r.mtfcc
  FROM resolved r
 WHERE d.id = r.id
   AND (d.mtfcc IS NULL OR d.mtfcc = '');        -- guarded: a re-run touches 0 rows

-- =============================================================================
-- Post-verify gate
-- =============================================================================
-- Asserts the END STATE (nothing resolvable left unresolved) rather than a row count, so it holds
-- identically on the first run and every re-run.
DO $$
DECLARE
  v_unresolved  int;
  v_still_null  int;
  v_nonpermit   int;
  v_spot        text;
BEGIN
  -- 1. No district on a colliding geo_id is still missing an mtfcc that COULD have been derived.
  WITH permitted(district_type, mtfcc) AS (VALUES
    ('STATE_UPPER','G5210'),('STATE_LOWER','G5220'),('NATIONAL_LOWER','G5200'),
    ('COUNTY','G4020'),('JUDICIAL','G4020'),
    ('LOCAL','G4040'),('LOCAL','G4110'),('LOCAL','G4120'),
    ('LOCAL_EXEC','G4040'),('LOCAL_EXEC','G4110'),('LOCAL_EXEC','G4120'),
    ('SCHOOL','G5400'),('SCHOOL','G5410'),('SCHOOL','G5420')
  ),
  colliding AS (
    SELECT geo_id FROM essentials.geofence_boundaries
     GROUP BY geo_id HAVING count(DISTINCT mtfcc) > 1
  )
  SELECT count(*) INTO v_unresolved FROM (
    SELECT d.id
      FROM essentials.districts d
      JOIN colliding c ON c.geo_id = d.geo_id
      JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
      JOIN permitted p ON p.district_type = d.district_type AND p.mtfcc = gb.mtfcc
     WHERE d.mtfcc IS NULL OR d.mtfcc = ''
     GROUP BY d.id
    HAVING count(DISTINCT gb.mtfcc) = 1
  ) x;
  IF v_unresolved <> 0 THEN
    RAISE EXCEPTION '% district row(s) on a colliding geo_id still have no mtfcc despite an '
                    'unambiguous derivation — the UPDATE did not apply', v_unresolved;
  END IF;

  -- 2. Spot-check the derivations named in the header, including the Alpine row from the
  --    geoIdGuard.ts incident and the place-vs-school-district collision.
  SELECT string_agg(chk, ', ' ORDER BY chk) INTO v_spot FROM (
    SELECT format('%s/%s=%s', d.geo_id, d.district_type, d.mtfcc) AS chk
      FROM essentials.districts d
     WHERE (d.geo_id, d.district_type) IN
           (('18013','JUDICIAL'),('4900540','LOCAL'),('4900870','SCHOOL'),('18040','STATE_UPPER'))
     GROUP BY d.geo_id, d.district_type, d.mtfcc
  ) s;
  IF v_spot IS NULL
     OR v_spot NOT LIKE '%18013/JUDICIAL=G4020%'
     OR v_spot NOT LIKE '%4900540/LOCAL=G4110%'
     OR v_spot NOT LIKE '%4900870/SCHOOL=G5420%'
     OR v_spot NOT LIKE '%18040/STATE_UPPER=G5210%' THEN
    RAISE EXCEPTION 'spot-check failed, got: %', coalesce(v_spot, '(no rows)');
  END IF;

  -- 3. Visibility, NOT assertions: what this migration deliberately leaves behind.
  SELECT count(*) INTO v_still_null
    FROM essentials.districts WHERE mtfcc IS NULL OR mtfcc = '';

  WITH permitted(district_type, mtfcc) AS (VALUES
    ('STATE_UPPER','G5210'),('STATE_LOWER','G5220'),('NATIONAL_LOWER','G5200'),
    ('COUNTY','G4020'),('JUDICIAL','G4020'),
    ('LOCAL','G4040'),('LOCAL','G4110'),('LOCAL','G4120'),
    ('LOCAL_EXEC','G4040'),('LOCAL_EXEC','G4110'),('LOCAL_EXEC','G4120'),
    ('SCHOOL','G5400'),('SCHOOL','G5410'),('SCHOOL','G5420')
  )
  SELECT count(*) INTO v_nonpermit
    FROM essentials.districts d
   WHERE d.mtfcc IS NOT NULL AND d.mtfcc <> '' AND d.mtfcc NOT LIKE 'X%'
     AND NOT EXISTS (SELECT 1 FROM permitted p
                      WHERE p.district_type = d.district_type AND p.mtfcc = d.mtfcc)
     AND d.district_type IN ('STATE_UPPER','STATE_LOWER','NATIONAL_LOWER','COUNTY','JUDICIAL',
                             'LOCAL','LOCAL_EXEC','SCHOOL');

  RAISE NOTICE 'districts.mtfcc backfill PASSED: 0 resolvable rows left unresolved on colliding '
               'geo_ids. Spot-checks OK (%). STILL OPEN, out of scope: % district row(s) have no '
               'mtfcc at all (safe — non-colliding geo_ids resolve to a single geofence), and '
               '% row(s) carry an mtfcc that CONTRADICTS geoIdGuard''s matrix (pre-existing, e.g. '
               'COUNTY on G5220).', v_spot, v_still_null, v_nonpermit;
END $$;

COMMIT;
