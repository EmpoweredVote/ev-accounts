-- 1499_ut_reparent_citywide_council_seats.sql
--
-- Nine UT cities carry their CITYWIDE council seats (At-Large / Citywide / unnumbered "City
-- Council Member") on the `LOCAL_EXEC` "<City> Mayor" district instead of the `LOCAL`
-- "<City> City Council" district, with a duplicate inactive copy sitting on the LOCAL district:
--
--   Layton, Lehi, Ogden, Orem, Provo, St. George, Sandy, West Jordan, West Valley City
--
-- This is NOT an address-search outage — both districts share the same place-level geo_id, and the
-- G4110 geofence joins to LOCAL_EXEC as well (essentialsService.ts:738), so these members do
-- surface. It is a district_type defect: council members are typed as executives, and every one of
-- them appears twice (once active on the wrong district, once retired on the right one).
--
-- Deferred out of migration 1498 deliberately, since 1498 was fixing an actual outage.
--
-- THE TARGET SHAPE IS SET BY THE 20 UT CITIES THAT ARE ALREADY CORRECT -- Alpine, American Fork,
-- Bluffdale, Cedar Hills, Draper, Eagle Mountain, Lindon, Mapleton, Payson, Pleasant Grove, Salem,
-- Santaquin, Saratoga Springs, South Salt Lake, Spanish Fork, Springville, Vineyard. Every one of
-- them: `LOCAL` district, `seats = 1`, `chamber_id` -> "<City> City Council", active holder. Third
-- migration running to use the non-defective peers to settle the shape (see 1496, 1498).
--
-- Same cohort split as 1496 and 1498, for the third time:
--   ACTIVE side, on LOCAL_EXEC   chamber_id SET, seats NULL, is_active=true, holds the stances
--                                (Orem's six council members carry 40 stance answers)
--   RETIRED side, on LOCAL       chamber_id NULL, seats=1,   is_active=false, holds all 33 contacts
--
-- So: keep the ACTIVE offices, carry `seats = 1` across, move the contacts, drop the retired
-- duplicates, and re-parent the survivors onto the LOCAL council district. Politician rows are not
-- touched, so the 40 Orem stances cannot be affected -- stances hang off the politician, and only
-- `offices.district_id` moves.
--
-- PAIRING IS BY NORMALISED NAME, because citywide seats have no district number to key on. Verified
-- safe before writing: all 31 retired-side holders match an active-side holder within the same city
-- (0 unmatched), and the normalised name is unique within each side of every city, so no 2:1
-- ambiguity. A pre-flight below re-asserts both rather than trusting this comment -- the Ogden
-- "Ben"/"Benjamin" Nadolski and SLC "Erin"/"Erin J." Mendenhall variants already defeated
-- name-matching twice in this series.
--
-- PROVO IS THE ONE EXCEPTION: it has no "Provo City Council" LOCAL district at all, only
-- "Provo Mayor". Its two Citywide offices already point at a "Provo City Council" CHAMBER, so the
-- chamber exists and only the district row is missing; this migration creates it, matching the
-- convention of its peers (same `ocd_id` as the city's LOCAL_EXEC row, place FIPS geo_id,
-- district_id code '0').
--
-- Title filter is `ILIKE '%Council%'`, not `NOT ILIKE 'Mayor'`. Checked: the affected LOCAL_EXEC
-- districts hold exactly one Mayor plus council seats and nothing else, and every council title
-- contains "Council" ('City Council Member', 'Council At-Large Seat A/B/C', 'Council At-Large',
-- 'Council Member At-Large', 'Council Citywide I/II'). Matching on "Council" states the intent
-- instead of relying on the absence of one other word.
--
-- Idempotent: the mapping only selects rows still in the pre-fix shape, so a re-run maps nothing and
-- every statement matches zero rows. Pre-flight accepts a mapping of 34 (fresh) or 0 (re-run) and
-- aborts on anything between, which would mean a partial application. The gate asserts END STATE.
--
-- Follow-up this closes: `check:reachability`'s DEAD_GEOGRAPHY `ut|LOCAL` bucket drops 8 -> 0,
-- because those 8 districts are exactly these cities' council districts, which currently hold only
-- retired duplicates. The baseline is updated in the same commit.

BEGIN;

-- Provo's missing council district. Guarded, so a re-run is a no-op.
INSERT INTO essentials.districts (id, label, district_type, district_id, ocd_id, geo_id, state)
SELECT gen_random_uuid(), 'Provo City Council', 'LOCAL', '0',
       'ocd-division/country:us/state:ut/place:provo', '4962470', 'ut'
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.districts d
    WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id = '4962470'
 );

CREATE TEMP TABLE _ut_citywide (
  geo_id        text,
  council_dist  uuid,   -- LOCAL "<City> City Council"  (destination)
  active_office uuid,   -- currently mis-parented onto LOCAL_EXEC
  active_pol    uuid,
  retired_office uuid,  -- duplicate on the LOCAL district
  retired_pol   uuid
) ON COMMIT DROP;

INSERT INTO _ut_citywide (geo_id, council_dist, active_office, active_pol, retired_office, retired_pol)
WITH council AS (   -- destination district, one per city
  SELECT d.geo_id, d.id
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id ~ '^[0-9]{7}$'
), act AS (         -- citywide council seats sitting on the LOCAL_EXEC mayor district
  SELECT d.geo_id, o.id AS office_id, och.politician_id AS pol_id,
         lower(regexp_replace(coalesce(p.full_name, ''), '[^a-zA-Z]', '', 'g')) AS nkey
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL_EXEC' AND d.geo_id ~ '^[0-9]{7}$'
     AND o.title ILIKE '%Council%'
), ret AS (         -- the retired duplicates already on the LOCAL district
  SELECT d.geo_id, o.id AS office_id, och.politician_id AS pol_id,
         lower(regexp_replace(coalesce(p.full_name, ''), '[^a-zA-Z]', '', 'g')) AS nkey
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id ~ '^[0-9]{7}$'
     AND o.title ILIKE '%Council%'
)
SELECT a.geo_id, c.id, a.office_id, a.pol_id, r.office_id, r.pol_id
  FROM act a
  JOIN council c ON c.geo_id = a.geo_id
  LEFT JOIN ret r ON r.geo_id = a.geo_id AND r.nkey = a.nkey;

-- ── pre-flight ─────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_bad int;
BEGIN
  SELECT count(*) INTO v_n FROM _ut_citywide;
  IF v_n NOT IN (0, 34) THEN
    RAISE EXCEPTION '1499: mapped % citywide seats -- expected 34 (fresh) or 0 (re-run); partial state', v_n;
  END IF;
  IF v_n = 0 THEN
    RAISE NOTICE '1499: already applied -- every statement will match zero rows';
  END IF;

  -- every mapped seat must have a destination district
  SELECT count(*) INTO v_bad FROM _ut_citywide WHERE council_dist IS NULL;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1499: % seats have no LOCAL council district to move into', v_bad;
  END IF;

  -- NEVER delete an occupied seat: no retired-side office may have an ACTIVE holder
  SELECT count(*) INTO v_bad
    FROM _ut_citywide m
    JOIN essentials.office_current_holder och ON och.office_id = m.retired_office
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1499: % retired-side offices have an ACTIVE holder -- aborting', v_bad;
  END IF;

  -- races.office_id is ON DELETE NO ACTION, so a race would block the delete
  SELECT count(*) INTO v_bad
    FROM _ut_citywide m JOIN essentials.races r ON r.office_id = m.retired_office;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1499: % retired-side offices carry a race -- aborting', v_bad;
  END IF;

  -- name pairing must be 1:1 -- no retired office may be claimed by two active seats
  SELECT count(*) INTO v_bad FROM (
    SELECT retired_office FROM _ut_citywide
     WHERE retired_office IS NOT NULL
     GROUP BY retired_office HAVING count(*) > 1
  ) x;
  IF v_bad > 0 THEN
    RAISE EXCEPTION '1499: % retired offices matched more than one active seat by name -- ambiguous', v_bad;
  END IF;
END $$;

-- 1. Move the contacts -- the only thing the retired side holds that the survivors lack.
UPDATE essentials.politician_contacts pc
   SET politician_id = m.active_pol
  FROM _ut_citywide m
 WHERE pc.politician_id = m.retired_pol
   AND m.retired_pol IS DISTINCT FROM m.active_pol;

-- 2. Carry seats=1 onto the surviving office, matching the 20 already-correct cities.
UPDATE essentials.offices o
   SET seats = 1
  FROM _ut_citywide m
 WHERE o.id = m.active_office
   AND o.seats IS NULL;

-- 3. Drop the retired duplicates: terms first, then the offices.
DELETE FROM essentials.office_terms t
 USING _ut_citywide m
 WHERE t.office_id = m.retired_office;

DELETE FROM essentials.offices o
 USING _ut_citywide m
 WHERE o.id = m.retired_office
   AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.office_id = o.id);

-- 4. Re-parent the survivors onto the council district. This is the actual fix; everything above
--    just clears the way. Only offices.district_id changes, so holders, terms, stances, chamber and
--    headshots all ride along untouched.
UPDATE essentials.offices o
   SET district_id = m.council_dist
  FROM _ut_citywide m
 WHERE o.id = m.active_office
   AND o.district_id IS DISTINCT FROM m.council_dist;

-- ── post-verify gate (END STATE, so it is meaningful on a re-run too) ───────────────────
DO $$
DECLARE
  v_stray int; v_seats int; v_shape int; v_contacts int; v_orphans int;
  v_orem int; v_dead int; v_provo int;
BEGIN
  -- no council seat may remain on a UT place-level LOCAL_EXEC district
  SELECT count(*) INTO v_stray
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL_EXEC'
     AND d.geo_id ~ '^[0-9]{7}$' AND o.title ILIKE '%Council%';
  IF v_stray <> 0 THEN
    RAISE EXCEPTION '1499: % council seats still parented to a LOCAL_EXEC mayor district', v_stray;
  END IF;

  -- Provo now has its council district
  SELECT count(*) INTO v_provo
    FROM essentials.districts d
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id = '4962470';
  IF v_provo <> 1 THEN
    RAISE EXCEPTION '1499: expected exactly 1 Provo council district, found %', v_provo;
  END IF;

  -- the nine cities now hold their 34 citywide seats, all occupied
  SELECT count(*) INTO v_seats
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id AND p.is_active
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
     AND d.geo_id IN ('4943660','4944320','4955980','4957300','4962470',
                      '4965330','4967440','4982950','4983470')
     AND o.title ILIKE '%Council%';
  IF v_seats <> 34 THEN
    RAISE EXCEPTION '1499: expected 34 occupied citywide seats across the 9 cities, found %', v_seats;
  END IF;

  -- and they match the Alpine reference shape: chamber_id set AND seats = 1
  SELECT count(*) INTO v_shape
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
   WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id ~ '^[0-9]{7}$'
     AND o.title ILIKE '%Council%'
     AND (o.chamber_id IS NULL OR o.seats IS DISTINCT FROM 1);
  IF v_shape <> 0 THEN
    RAISE EXCEPTION '1499: % UT citywide council offices are off-shape (chamber NULL or seats<>1)', v_shape;
  END IF;

  -- all 33 contacts landed on the survivors
  SELECT count(*) INTO v_contacts
    FROM essentials.politician_contacts pc
   WHERE pc.politician_id IN (
     SELECT och.politician_id
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
      WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL'
        AND d.geo_id IN ('4943660','4944320','4955980','4957300','4962470',
                         '4965330','4967440','4982950','4983470')
        AND o.title ILIKE '%Council%');
  IF v_contacts <> 33 THEN
    RAISE EXCEPTION '1499: expected 33 contacts on the surviving citywide holders, found %', v_contacts;
  END IF;

  -- Orem's 40 council stances must be untouched (they hang off politicians, but prove it)
  SELECT count(*) INTO v_orem
    FROM inform.politician_answers a
   WHERE a.politician_id IN (
     SELECT och.politician_id
       FROM essentials.districts d
       JOIN essentials.offices o ON o.district_id = d.id
       JOIN essentials.office_current_holder och ON och.office_id = o.id
      WHERE lower(d.state) = 'ut' AND d.geo_id = '4957300' AND o.title ILIKE '%Council%');
  IF v_orem <> 40 THEN
    RAISE EXCEPTION '1499: expected 40 Orem council stance answers, found %', v_orem;
  END IF;

  -- districts has no inbound FK, so prove nothing was orphaned
  SELECT count(*) INTO v_orphans
    FROM essentials.offices o
   WHERE o.district_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.id = o.district_id);
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION '1499: % offices orphaned', v_orphans;
  END IF;

  -- closes the check:reachability DEAD_GEOGRAPHY ut|LOCAL bucket: no UT place-level council
  -- district may hold offices while having no active holder and no vacancy flag
  SELECT count(*) INTO v_dead FROM (
    SELECT d.id
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
      LEFT JOIN essentials.politicians p ON p.id = och.politician_id
     WHERE lower(d.state) = 'ut' AND d.district_type = 'LOCAL' AND d.geo_id ~ '^[0-9]{7}$'
     GROUP BY d.id
    HAVING count(*) FILTER (WHERE p.is_active) = 0
       AND count(*) FILTER (WHERE o.is_vacant) = 0
  ) x;
  IF v_dead <> 0 THEN
    RAISE EXCEPTION '1499: % UT place-level council districts still resolve nobody', v_dead;
  END IF;

  RAISE NOTICE '1499 OK: 34 citywide seats re-parented onto LOCAL council districts; 33 contacts, 40 Orem stances preserved';
END $$;

COMMIT;
