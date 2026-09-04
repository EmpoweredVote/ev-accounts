-- CC_0053_long_beach_council_district_geometry.sql
--
-- Long Beach, CA — repoint the nine council district rows onto their own polygons.
-- Wave CA-1 of the Knight Foundation cities program.
--
-- Spec:    docs/superpowers/specs/2026-08-28-knight-cities-program-design.md
-- Roster:  backend/data/seed-long-beach-2026/ROSTERS.md
-- Tracker: .planning/knight-foundation/PROGRAM.md
--
-- ── WHAT IS WRONG ──────────────────────────────────────────────────────────────────────────────
-- All NINE Long Beach council district rows carry geo_id '0643000' — the TIGER place polygon for
-- the whole city — so an address in Long Beach resolves all nine of them. Measured against prod
-- 2026-09-02, the ST_PointOnSurface probe that check-address-reachability.mjs runs returned:
--
--     District 1  Councilmember  Mary Zendejas
--     District 2  Councilmember  Cindy Allen
--     ... all nine ...
--     Long Beach Mayor / City Attorney / City Auditor / City Prosecutor
--     District 4  Supervisor     Janice Hahn
--
-- NINE councilmembers for one address. The four citywide seats and the county supervisor are
-- correct; the nine are not.
--
-- ⚠ check-address-reachability.mjs deliberately does NOT flag this, and it is right not to. Its
--   header records that "two districts share a geo_id" was measured and rejected as an invariant,
--   because ~700 rows match it legitimately — and it names Long Beach's own 0643000 as the
--   example. This needed a per-jurisdiction probe to surface, not a broader guard.
--
-- San José, the other half of this slice, already returns exactly one councilmember: its ten
-- districts have carried real polygons (X0010) since the 2022 map was loaded. Long Beach is the
-- outlier, not the pattern.
--
-- ── WHAT THIS DOES ─────────────────────────────────────────────────────────────────────────────
-- This is a REPAIR, not a seed. Nothing is created and nothing is deleted. The nine district rows
-- and their nine offices and nine terms all already exist and are correct; only the geography they
-- point at is wrong.
--
--   geo_id  '0643000'                                    -> 'long-beach-ca-council-district-N'
--   mtfcc   'G4110'  (the TIGER place layer)             -> 'X0046'
--   ocd_id  '.../place:long_beach'                       -> '.../place:long_beach/ward:N'
--   population  449468 (the whole city, on every row)    -> the district's own count
--
-- 🔴 NOTHING IS DELETED. essentials.districts has NO inbound foreign keys, so deleting a district
--    row silently ORPHANS its offices rather than erroring. Repointing in place cannot orphan
--    anything, and it keeps every office_id, term and politician link untouched.
--
-- ⚠ THE FOUR CITYWIDE SEATS STAY ON 0643000/G4110. Mayor, City Attorney, City Auditor and City
--   Prosecutor are elected citywide, so the place polygon IS their district. After this migration
--   the place polygon resolves those four and nothing else; each X0046 polygon resolves exactly
--   one councilmember.
--
-- ── WHY ocd_id GETS '/ward:N' RATHER THAN NULL ─────────────────────────────────────────────────
-- Two conventions are live. Columbus, Macon and Milledgeville leave synthetic district rows with a
-- NULL ocd_id; San José — the sibling city in this same slice, same state — uses
-- '.../place:san_jose/ward:N'. CA's convention is followed here so the two Californian cities read
-- alike. Nothing depends on the choice: ocd_id ROLLS UP, geo_id LOOKS UP, and address search never
-- reads ocd_id. Leaving '.../place:long_beach' on nine district rows would assert that each
-- district IS the city, which is the very error being fixed.
--
-- ── WHY mtfcc MOVES TOO ────────────────────────────────────────────────────────────────────────
-- essentials.districts.mtfcc is not read by the address join — the guard reads the mtfcc of the
-- GEOFENCE the point fell in, not the district's own column (src/lib/geoIdGuard.ts). But leaving
-- 'G4110' on a row whose geo_id is no longer a TIGER place is simply false, and the next reader
-- would have to re-derive that it does not matter. X0046 + district_type 'LOCAL' is admitted by
-- the guard's X%% catch-all, the same route X0010 takes for San José.
--
-- ── POPULATION ─────────────────────────────────────────────────────────────────────────────────
-- Every one of the nine rows carries 449468, Long Beach's whole population, which is wrong nine
-- times over. Replaced with the per-district POPULATION field the city's own layer publishes.
-- population_source_year is left NULL: the layer labels the field "POPULATION ESTIMATE" and states
-- no vintage, and a year is not invented here. Nothing in the API reads districts.population — only
-- treasury.municipalities.population is read — so this corrects a stored falsehood rather than a
-- rendered one.
--
-- ── PREREQUISITE ───────────────────────────────────────────────────────────────────────────────
--   npx tsx scripts/load-long-beach-council-boundaries.ts
-- must have run. It loads the nine X0046 polygons and gates on: 9 single valid polygons; the
-- layer's own roster field still naming the sitting members; per-district area within 2%%; no
-- overlapping pairs; 900 of the city's own business-licence locations each landing in the district
-- the city assigns it to; and the union covering at least Long Beach's 50.67 sq mi of TIGER LAND.
-- This migration refuses to run without those nine rows.
--
-- Idempotent. The post-verify gate asserts the END STATE, not the delta, so a re-run is a no-op
-- that still proves the end state.

BEGIN;

-- ── Preconditions ──────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n integer;
BEGIN
  -- 1. The nine polygons are loaded.
  SELECT count(*) INTO v_n
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0046'
     AND geo_id IN ('long-beach-ca-council-district-1','long-beach-ca-council-district-2',
                    'long-beach-ca-council-district-3','long-beach-ca-council-district-4',
                    'long-beach-ca-council-district-5','long-beach-ca-council-district-6',
                    'long-beach-ca-council-district-7','long-beach-ca-council-district-8',
                    'long-beach-ca-council-district-9');
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'long beach geometry: expected 9 X0046 boundaries, found % -- run scripts/load-long-beach-council-boundaries.ts first', v_n;
  END IF;

  -- 2. Every one of them is valid and in SRID 4326. A polygon that cannot be covered is a polygon
  --    that resolves nobody, and ST_Covers fails silently rather than loudly.
  SELECT count(*) INTO v_n
    FROM essentials.geofence_boundaries
   WHERE mtfcc = 'X0046'
     AND (NOT public.ST_IsValid(geometry) OR public.ST_SRID(geometry) <> 4326 OR public.ST_IsEmpty(geometry));
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach geometry: % of the 9 X0046 boundaries are invalid, empty or not SRID 4326', v_n;
  END IF;

  -- 3. The TIGER place polygon is still there. The four citywide seats hang on it, and this
  --    migration would strand them if it had gone.
  IF NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries
                  WHERE geo_id = '0643000' AND mtfcc = 'G4110') THEN
    RAISE EXCEPTION 'long beach geometry: TIGER place 0643000/G4110 is missing -- the four citywide seats would be unreachable';
  END IF;

  -- 4. The nine district rows are where we left them: nine LOCAL rows under the city's ocd_id,
  --    labelled District 1..9, one office each. Either pre-state or post-state is accepted so a
  --    re-run passes.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL'
     AND lower(d.state) = 'ca'
     AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
     AND d.label IN ('District 1','District 2','District 3','District 4','District 5',
                     'District 6','District 7','District 8','District 9');
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'long beach geometry: expected 9 Long Beach council district rows, found % -- the shape has changed, stop and re-measure', v_n;
  END IF;

  -- 5. Each of the nine carries exactly one office. If one carried two, repointing would move
  --    both, and this is the 1495/1496 duplicate-office signature.
  SELECT count(*) INTO v_n
    FROM (SELECT d.id
            FROM essentials.districts d
            JOIN essentials.offices o ON o.district_id = d.id
           WHERE d.district_type = 'LOCAL'
             AND lower(d.state) = 'ca'
             AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:long_beach%'
             AND d.label LIKE 'District %'
           GROUP BY d.id
          HAVING count(*) <> 1) s;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach geometry: % council district row(s) do not carry exactly one office', v_n;
  END IF;
END $$;

-- ── Repoint ────────────────────────────────────────────────────────────────────────────────────
-- Matched on (district_type, state, ocd_id, label). Only Long Beach rows carry that ocd_id, and
-- the nine labels are distinct within it, so each UPDATE touches exactly one row. Deliberately NOT
-- matched on label alone: 'District 1' + LOCAL + 'ca' also matches San José's District 1 and Los
-- Angeles County's Supervisorial District 1.
UPDATE essentials.districts d
   SET geo_id     = 'long-beach-ca-council-district-' || v.n,
       mtfcc      = 'X0046',
       ocd_id     = 'ocd-division/country:us/state:ca/place:long_beach/ward:' || v.n,
       population = v.pop
  FROM (VALUES
          ('1', 52781), ('2', 53670), ('3', 50157),
          ('4', 51146), ('5', 54627), ('6', 53796),
          ('7', 50425), ('8', 50809), ('9', 51483)
       ) AS v(n, pop)
 WHERE d.district_type = 'LOCAL'
   AND lower(d.state) = 'ca'
   AND d.ocd_id = 'ocd-division/country:us/state:ca/place:long_beach'
   AND d.label = 'District ' || v.n;

-- ── Post-verify: the END STATE, not the delta ──────────────────────────────────────────────────
DO $$
DECLARE
  v_n         integer;
  v_offices   integer;
  v_seated    integer;
BEGIN
  -- 1. Nine district rows, each on its own X0046 geo_id.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL'
     AND lower(d.state) = 'ca'
     AND d.geo_id LIKE 'long-beach-ca-council-district-%'
     AND d.mtfcc = 'X0046';
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'long beach geometry: expected 9 repointed district rows, found %', v_n;
  END IF;

  -- 2. Nine DISTINCT geo_ids. The whole defect was nine rows sharing one.
  SELECT count(DISTINCT d.geo_id) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL'
     AND lower(d.state) = 'ca'
     AND d.geo_id LIKE 'long-beach-ca-council-district-%';
  IF v_n <> 9 THEN
    RAISE EXCEPTION 'long beach geometry: the 9 district rows carry only % distinct geo_ids', v_n;
  END IF;

  -- 3. NO council district is left on the place polygon. This is the assertion that the defect is
  --    gone, and it is separate from (1) on purpose: a tenth stray row would satisfy (1) and (2).
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL'
     AND lower(d.state) = 'ca'
     AND d.geo_id = '0643000';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach geometry: % council district row(s) still sit on the city place polygon 0643000', v_n;
  END IF;

  -- 4. The four citywide seats are STILL on the place polygon. Repointing must not have caught them.
  SELECT count(*) INTO v_n
    FROM essentials.districts d
   WHERE d.district_type = 'LOCAL_EXEC'
     AND lower(d.state) = 'ca'
     AND d.geo_id = '0643000'
     AND d.mtfcc = 'G4110';
  IF v_n <> 4 THEN
    RAISE EXCEPTION 'long beach geometry: expected the 4 citywide seats to remain on place 0643000, found %', v_n;
  END IF;

  -- 5. Every district row still has its office, and every office still has a seated holder.
  --    🔴 count(och.politician_id), never count(*) -- office_current_holder LEFT JOINs from
  --    offices, so a vacancy is a NULL politician_id, not an absent row, and count(*) passes
  --    vacuously.
  SELECT count(o.id), count(och.politician_id) INTO v_offices, v_seated
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.district_type = 'LOCAL'
     AND lower(d.state) = 'ca'
     AND d.geo_id LIKE 'long-beach-ca-council-district-%';
  IF v_offices <> 9 OR v_seated <> 9 THEN
    RAISE EXCEPTION 'long beach geometry: expected 9 offices and 9 seated holders after the repoint, found % offices and % seated', v_offices, v_seated;
  END IF;

  -- 6. THE ACCEPTANCE TEST, run for ALL NINE districts, not a sample. Take ST_PointOnSurface of
  --    each polygon and run the real address-search join. The set of Long Beach council districts
  --    resolved at that point must be EXACTLY {that district} — one member, and the right one.
  --    Before this migration every one of these points resolved all nine.
  --
  --    Counting to one is not enough on its own: nine polygons each resolving exactly one
  --    councilmember, but the wrong one, is the mislabelled-control failure. The equality below
  --    tests identity, not cardinality.
  SELECT count(*) INTO v_n
    FROM essentials.geofence_boundaries gb
   WHERE gb.mtfcc = 'X0046'
     AND gb.geo_id LIKE 'long-beach-ca-council-district-%'
     AND COALESCE((SELECT array_agg(d.geo_id::text ORDER BY d.geo_id::text)
            FROM essentials.geofence_boundaries g2
            JOIN essentials.districts d
              ON d.geo_id = g2.geo_id AND d.mtfcc = g2.mtfcc
            JOIN essentials.offices o ON o.district_id = d.id
            JOIN essentials.office_current_holder och ON och.office_id = o.id
           WHERE g2.mtfcc = 'X0046'
             AND public.ST_Covers(g2.geometry, public.ST_PointOnSurface(gb.geometry))
             AND lower(d.state) = 'ca'
             AND d.district_type = 'LOCAL'
             AND och.politician_id IS NOT NULL), ARRAY[]::text[]) <> ARRAY[gb.geo_id::text];
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach geometry: % of the 9 districts do not resolve to their OWN seated councilmember, and only theirs, at their representative point', v_n;
  END IF;

  -- 7. And the place polygon must now resolve the four citywide seats and NO councilmember. This
  --    is the same probe from the other direction: the defect was visible from a city point, so
  --    the fix has to be visible from one too.
  SELECT count(*) INTO v_n
    FROM essentials.geofence_boundaries gb
    JOIN essentials.districts d ON d.geo_id = gb.geo_id
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE gb.geo_id = '0643000' AND gb.mtfcc = 'G4110'
     AND lower(d.state) = 'ca'
     AND d.district_type = 'LOCAL';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'long beach geometry: the city place polygon still resolves % council district office(s)', v_n;
  END IF;

  RAISE NOTICE 'long beach geometry: 9 council districts repointed onto X0046, 9 seated, each address resolves exactly one councilmember; 4 citywide seats remain on place 0643000';
END $$;

COMMIT;
