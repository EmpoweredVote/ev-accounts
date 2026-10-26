-- CC_0289_township_geo_ids.sql
--
-- Give the 16 Indiana townships the `geo_id` their own districts already carry.
--
-- A landing-page chip is keyed on `essentials.governments.geo_id`
-- (`WHERE g.geo_id = ANY($1)` in `essentialsBrowseService.getPoliticiansByGovernmentList`).
-- A NULL there cannot be named by any browse URL, so these 16 townships -- 61 seated
-- trustees, board members and small-claims constables across Marion, Monroe and Morgan
-- counties -- are invisible on the main page. Address search already finds them, because
-- it runs `districts -> offices -> office_current_holder` and never touches
-- `essentials.governments`. That is exactly why this stayed invisible.
--
-- WHY THESE 16 AND NOT THE OTHER 137. Measured 2026-10-25, 153 governments carry a NULL
-- `geo_id` and still hold a current occupant. Reading what they are settles the scope:
--
--     131  LOCAL   school districts, community college districts, water and irrigation
--                  districts, library / health / park districts -- reached through the
--                  area browse, never meant to be their own chip
--      16  Township  general-purpose local government  <- this migration
--       5  School District (Indiana)                   -- same reasoning as the 131
--       1  federal / NATIONAL duplicate                -- CC_0288
--
-- 🔴 NOT ONE CITY OR TOWN IS UNREACHABLE. The backlog note this came from
-- (`.planning/todos/2026-09-29-open-items-backlog.md`, item 1) recorded 210 governments
-- with occupants and estimated "roughly 80" were cities and towns. The count is now 153,
-- and the city-and-town subset is ZERO: every row of type City (80), Town (9), Village
-- (11), County (84) and STATE (50) carries a geoid. Measured with a title predicate
-- (mayor / council member / alderman / city clerk / city attorney / selectman) over the
-- NULL-geoid set, which returned 0 -- against a positive control running the same
-- predicate over the geoid-bearing set, which returned 280. The control is the only
-- reason that zero can be trusted.
--
-- 🔴 EVERY GEOID IS VERIFIED AGAINST A DISTRICT THAT EXISTS AND CARRIES A POLYGON -- the
-- rule CC_0183 established, whose own first run its gate refused over this. None of these
-- is composed from a name. Each township's offices hang off districts that already carry
-- a TIGER county-subdivision geoid (MTFCC G4040), all 16 resolve to exactly ONE distinct
-- geoid, and all 16 have a matching polygon in `essentials.geofence_boundaries`.
--
-- ⚠ INDIANA REUSES TOWNSHIP NAMES ACROSS COUNTIES -- there is a Washington Township in
-- Monroe and a Center Township in Marion, and the government rows are named "Center
-- Township, Indiana, US" with no county in the string. So the pairs below are keyed on
-- the government UUID, never on the name, and the gate re-derives each geoid from that
-- government's own districts rather than trusting this list.
--
-- `mtfcc` is set alongside, because the real key is the PAIR (mtfcc, geo_id): 1,159
-- geo_id values collide across 13 states, and G4040 is a different space from the G4020
-- that the counties and the consolidated city use.
--
-- Idempotent: the UPDATE is guarded on `geo_id IS NULL`, so a second run changes nothing
-- and the gate still passes.

BEGIN;

WITH proposed(govt_id, geo_id, mtfcc) AS (VALUES
  ('2be64319-3443-4adf-9b21-024b29342149'::uuid, '1810902440', 'G4040'),  -- Ashland      (Morgan)
  ('8ecc851d-4fa8-4854-824c-326b15dc0e67'::uuid, '1810903178', 'G4040'),  -- Baker        (Morgan)
  ('32899eef-98ad-4dee-9dbe-f86379e8bf30'::uuid, '1810503808', 'G4040'),  -- Bean Blossom (Monroe)
  ('4c05883a-9290-4b0a-9934-07fce05ce7dc'::uuid, '1810504816', 'G4040'),  -- Benton       (Monroe)
  ('131aec34-3319-40f3-a624-134bc52d125b'::uuid, '1810505878', 'G4040'),  -- Bloomington  (Monroe)
  ('fec4f72d-c76d-4193-9183-1d6b44792e62'::uuid, '1809711512', 'G4040'),  -- Center       (Marion)
  ('ea2b9f44-10d0-4b52-aed5-88d461993c9b'::uuid, '1810513420', 'G4040'),  -- Clear Creek  (Monroe)
  ('fac77663-9eac-466d-883a-4c50a4c7c286'::uuid, '1810536072', 'G4040'),  -- Indian Creek (Monroe)
  ('cf427e70-c02d-4cb2-86d5-a12aa7159194'::uuid, '1810559112', 'G4040'),  -- Perry        (Monroe)
  ('e3ba2dfe-c71f-46bc-947f-8217083e6de7'::uuid, '1810560984', 'G4040'),  -- Polk         (Monroe)
  ('57c68caf-b895-4695-b24e-afa6fcfddb60'::uuid, '1810963144', 'G4040'),  -- Ray          (Morgan)
  ('d58194e9-e385-4ab6-bd64-7bff5f5e0655'::uuid, '1810564152', 'G4040'),  -- Richland     (Monroe)
  ('6b17da8a-5e76-4de7-b77e-40a242463e8a'::uuid, '1810567590', 'G4040'),  -- Salt Creek   (Monroe)
  ('e969757b-dcd2-4764-a3e8-75ae1566a26c'::uuid, '1810578542', 'G4040'),  -- Van Buren    (Monroe)
  ('02277418-b7d1-47d6-8376-06e6b380674e'::uuid, '1809780144', 'G4040'),  -- Warren       (Marion)
  ('7f37356d-e532-473c-b5ff-d7c7a4aec7e4'::uuid, '1810580828', 'G4040')   -- Washington   (Monroe)
)
UPDATE essentials.governments g
   SET geo_id = p.geo_id,
       mtfcc  = p.mtfcc
  FROM proposed p
 WHERE g.id = p.govt_id
   AND g.geo_id IS NULL
   AND g.type = 'Township'
   -- The pair must be the one this government's OWN districts carry. A geoid typed into
   -- the list above that does not match the data is refused here, row by row.
   AND EXISTS (
     SELECT 1 FROM essentials.chambers c
       JOIN essentials.offices o   ON o.chamber_id = c.id
       JOIN essentials.districts d ON d.id = o.district_id
      WHERE c.government_id = g.id
        AND d.geo_id = p.geo_id
        AND d.mtfcc  = p.mtfcc)
   -- And it must have a polygon. A geoid with no boundary is a name, not a place.
   AND EXISTS (
     SELECT 1 FROM essentials.geofence_boundaries gb
      WHERE gb.geo_id = p.geo_id AND gb.mtfcc = p.mtfcc);

DO $$
DECLARE
  v_with_geoid   int;
  v_still_null   int;
  v_disagree     int;
  v_no_polygon   int;
  v_dupes        int;
BEGIN
  SELECT count(*) INTO v_with_geoid
    FROM essentials.governments WHERE type='Township' AND geo_id IS NOT NULL;

  SELECT count(*) INTO v_still_null
    FROM essentials.governments WHERE type='Township' AND geo_id IS NULL;

  -- Re-derived from the data, not from the VALUES list: every township's geoid must be
  -- the single geoid its own districts carry.
  SELECT count(*) INTO v_disagree
    FROM essentials.governments g
   WHERE g.type='Township'
     AND g.geo_id IS NOT NULL
     AND (g.geo_id, g.mtfcc) IS DISTINCT FROM (
       SELECT (min(d.geo_id), min(d.mtfcc))
         FROM essentials.chambers c
         JOIN essentials.offices o   ON o.chamber_id = c.id
         JOIN essentials.districts d ON d.id = o.district_id
        WHERE c.government_id = g.id
       HAVING count(DISTINCT d.geo_id) = 1);

  SELECT count(*) INTO v_no_polygon
    FROM essentials.governments g
   WHERE g.type='Township' AND g.geo_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = g.geo_id AND gb.mtfcc = g.mtfcc);

  -- geo_id stays unique table-wide, the invariant CC_0183's gate asserts.
  SELECT count(*) INTO v_dupes
    FROM (SELECT geo_id FROM essentials.governments
           WHERE geo_id IS NOT NULL GROUP BY geo_id HAVING count(*) > 1) x;

  IF v_with_geoid <> 16 THEN
    RAISE EXCEPTION 'CC_0289: expected 16 townships to carry a geo_id, found %', v_with_geoid;
  END IF;
  IF v_still_null <> 0 THEN
    RAISE EXCEPTION 'CC_0289: % township(s) still have a NULL geo_id', v_still_null;
  END IF;
  IF v_disagree > 0 THEN
    RAISE EXCEPTION 'CC_0289: % township geoid(s) disagree with their own districts', v_disagree;
  END IF;
  IF v_no_polygon > 0 THEN
    RAISE EXCEPTION 'CC_0289: % township geoid(s) have no matching polygon', v_no_polygon;
  END IF;
  IF v_dupes > 0 THEN
    RAISE EXCEPTION 'CC_0289: geo_id is no longer unique in essentials.governments -- % duplicated value(s)', v_dupes;
  END IF;

  RAISE NOTICE 'CC_0289: 16 townships carry a verified (mtfcc, geo_id); 0 null, 0 disagreeing, 0 without a polygon, geo_id still unique';
END $$;

COMMIT;
