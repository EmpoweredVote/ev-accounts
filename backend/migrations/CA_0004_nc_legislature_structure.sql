-- CA_0004_nc_legislature_structure.sql
-- North Carolina General Assembly: 2 chambers + 170 offices.
--
-- NC General Assembly wave 1. Depends on the NC TIGER/redistricting load, which
-- ALREADY created all 170 essentials.districts rows (120 STATE_LOWER + 50
-- STATE_UPPER, geo_id = '37' || lpad(district,3,'0'), state 'nc'). This
-- migration therefore creates CHAMBERS and OFFICES ONLY -- it must not insert
-- districts.
--
-- 🔴 geo_id is NOT unique across chambers in NC: '37001' is BOTH House District 1
-- and Senate District 1 (exactly 50 colliding geo_ids, one per Senate seat,
-- since NC runs 120 House / 50 Senate districts numbered independently from 1).
-- Every office join below keys on (geo_id, district_type) together, which IS
-- unique (verified zero duplicate groups) -- a bare geo_id join would either
-- attach a House office to a Senate district or fan out to two rows per seat,
-- while still producing a plausible-looking 170 count.
--
-- essentials.offices.politician_id was DROPPED (ADR 0002 phase 5, migration
-- 1463). This migration writes NO occupant -- occupancy is
-- migrations/CA_0005_nc_legislature_incumbents.sql, entirely through
-- essentials.office_terms.
--
-- Idempotency: essentials.offices has no unique index beyond the pkey, so
-- inserts use NOT EXISTS, never ON CONFLICT. Chamber idempotency keys on
-- (government_id, name).

BEGIN;

-- ─── Chambers ────────────────────────────────────────────────────────────────
-- One chamber per CHAMBER, not one per district (Indiana's 100+
-- "... - District 45" rows with government_id-per-row and official_count=0 is
-- the bug this avoids, not the pattern to follow).

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'North Carolina House of Representatives', 'North Carolina House of Representatives', 120, 2, false, 'full'
FROM essentials.governments g
WHERE g.id = '3a09655d-0d33-45c5-a33a-7a863bd653a1'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'North Carolina House of Representatives'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, term_length, staggered_term, policy_engagement_level)
SELECT g.id, 'North Carolina Senate', 'North Carolina Senate', 50, 2, false, 'full'
FROM essentials.governments g
WHERE g.id = '3a09655d-0d33-45c5-a33a-7a863bd653a1'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'North Carolina Senate'
  );

-- ─── House offices: 120, one per STATE_LOWER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Representative', 'NC', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = '3a09655d-0d33-45c5-a33a-7a863bd653a1' AND ch.name = 'North Carolina House of Representatives'
) c
WHERE d.district_type = 'STATE_LOWER'
  AND lower(d.state) = 'nc'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Representative'
  );

-- ─── Senate offices: 50, one per STATE_UPPER district ────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, is_appointed_position, seats)
SELECT c.id, d.id, 'Senator', 'NC', false, 1
FROM essentials.districts d
CROSS JOIN LATERAL (
  SELECT ch.id
  FROM essentials.chambers ch
  WHERE ch.government_id = '3a09655d-0d33-45c5-a33a-7a863bd653a1' AND ch.name = 'North Carolina Senate'
) c
WHERE d.district_type = 'STATE_UPPER'
  AND lower(d.state) = 'nc'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.title = 'Senator'
  );

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE n_ch int; n_off int; n_orphan int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers c
   WHERE c.government_id = '3a09655d-0d33-45c5-a33a-7a863bd653a1'
     AND c.name IN ('North Carolina House of Representatives', 'North Carolina Senate');
  IF n_ch <> 2 THEN RAISE EXCEPTION 'CA_0004: expected 2 NC legislative chambers, found %', n_ch; END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER');
  IF n_off <> 170 THEN RAISE EXCEPTION 'CA_0004: expected 170 NC legislative offices, found %', n_off; END IF;

  -- Every office must hang off a district that actually has geometry, or the
  -- seat is unreachable by address and nothing will error.
  -- 🔴 WEAK CHECK: this join is bare geo_id, with no mtfcc pairing, so it can
  -- be satisfied by a COUNTY polygon rather than the district's own -- 85 of
  -- the 170 NC legislative districts share a geo_id with an NC county
  -- boundary ('37001' is HD-1, SD-1 AND Alamance County). It is covered here
  -- by the paired 120/50 per-chamber counts below (the fourth assertion) and
  -- by the identity-anchor probe in verify-nc-tiger-import.sql, not by this
  -- gate alone. Any file copying this pattern MUST add the mtfcc pairing
  -- (see that script's identity anchor query for the shape).
  SELECT count(*) INTO n_orphan FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND (d.geo_id IS NULL
          OR NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries g WHERE g.geo_id = d.geo_id));
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC legislative offices lack district geometry', n_orphan; END IF;
END $$;

-- Fourth assertion, same gate: per-chamber shape + no cross-wiring. Catches
-- exactly the failure mode where a bare geo_id join fans a House office onto a
-- Senate district (or vice versa) while still producing a plausible 170 total.
DO $$
DECLARE n_lower int; n_upper int; n_dupe int;
BEGIN
  SELECT count(*) INTO n_lower FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_LOWER';
  IF n_lower <> 120 THEN RAISE EXCEPTION 'CA_0004: expected 120 NC House offices, found %', n_lower; END IF;

  SELECT count(*) INTO n_upper FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state)='nc' AND d.district_type='STATE_UPPER';
  IF n_upper <> 50 THEN RAISE EXCEPTION 'CA_0004: expected 50 NC Senate offices, found %', n_upper; END IF;

  -- Two offices on one district means the geo_id join fanned across chambers.
  SELECT count(*) INTO n_dupe FROM (
    SELECT o.district_id FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state)='nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     GROUP BY o.district_id HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION 'CA_0004: % NC districts carry more than one office — geo_id join fanned across chambers', n_dupe; END IF;
END $$;

COMMIT;
