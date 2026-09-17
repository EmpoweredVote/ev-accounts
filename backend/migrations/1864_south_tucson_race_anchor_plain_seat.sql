-- 1864_south_tucson_race_anchor_plain_seat.sql
-- South Tucson (AZ): re-point the Nov-2026 council race shell from the seat carrying the rotating
-- "Acting Mayor" designation to a plain `Council Member` seat. One row, one column.
--
-- WHAT THIS IS AND IS NOT. `essentials.races.office_id` anchors a race to ONE office, but this is an
-- at-large multi-seat contest (`seats = 3` of a 7-member body), so the model cannot express "these
-- three of seven seats" and ANY single anchor is a convention. The anchor was left on the seat that
-- migration 1863 retitled to `Council Member (Acting Mayor)`, which reads as though that particular
-- member's seat is the one being contested. We have no term data for this body -- every
-- office_terms row in the chamber has term_start and term_end NULL -- so that implication is not
-- something we can support.
--
-- 🔑 THIS CHANGES NO ROUTING, AND THAT IS VERIFIED BELOW, NOT ASSUMED. All seven South Tucson seats
-- share ONE district: `City of South Tucson (At-Large)`, geo_id 0468850. electionService resolves
-- races to a voter through the office's district geo_id (see the "Government-linked races
-- (city/township at-large offices)" path in backend/src/lib/electionService.ts), so moving the anchor
-- between two offices in the SAME district cannot change who sees the race. The post-flight guard
-- asserts the district_id is identical before and after. This is a consistency fix, not a bug fix.
--
-- WHY BOTHER THEN: so that no future reader infers meaning from the anchor. Sahuarita and Marana
-- already anchor their council shells to plain `Council Member` seats; after this, three of the four
-- Pima-county town councils agree.
--
-- ⚠ ORO VALLEY HAS THE IDENTICAL DEFECT AND IS DELIBERATELY NOT TOUCHED HERE. Its 3-seat council
-- shell is anchored to `Council Member (Vice Mayor)` (Melanie Barrett). Same class, same one-column
-- fix, same no-op for routing (its six council seats also share one at-large district, while its
-- MAYOR sits in a separate `Town of Oro Valley (Mayor)` district because Oro Valley genuinely elects
-- a mayor). Out of the scope asked for; recorded so it is not lost.
--
-- ANCHOR CHOICE IS DETERMINISTIC so this migration is reproducible: of the four plain `Council
-- Member` offices in the chamber, take the one with the lowest id::text --
-- 1f856023-54dd-4e93-848b-7445ab7823c3 (currently Brian Flagg's seat). Nothing about the occupant
-- matters; the seat is interchangeable with the other three by construction.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

CREATE TEMP TABLE m1864_before ON COMMIT DROP AS
SELECT r.id AS race_id, r.office_id AS old_office_id, r.seats, r.position_name,
       o.title AS old_title, o.district_id AS old_district_id,
       (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) AS cands
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.elections e ON e.id = r.election_id
 WHERE c.name_formal = 'South Tucson City Council'
   AND e.state = 'AZ' AND e.election_date >= '2026-01-01';

DO $$
DECLARE n int; t text; s int; k int;
BEGIN
  SELECT count(*) INTO n FROM m1864_before;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1864: expected exactly 1 South Tucson 2026 race shell, found %', n;
  END IF;

  SELECT old_title, seats, cands INTO t, s, k FROM m1864_before;
  IF t <> 'Council Member (Acting Mayor)' THEN
    RAISE EXCEPTION 'migration 1864: expected the shell anchored to "Council Member (Acting Mayor)", found "%" -- has mig 1863 run, or has someone already moved it?', t;
  END IF;
  IF s <> 3 THEN
    RAISE EXCEPTION 'migration 1864: expected seats = 3 on the shell, found %', s;
  END IF;
  -- Re-pointing a shell that has candidates attached would orphan them from their seat.
  IF k <> 0 THEN
    RAISE EXCEPTION 'migration 1864: shell now has % candidate(s); re-anchoring is no longer a safe no-op -- resolve by hand', k;
  END IF;
END $$;

-- Deterministic target: lowest id::text among the plain `Council Member` seats of this chamber.
CREATE TEMP TABLE m1864_target ON COMMIT DROP AS
SELECT o.id, o.district_id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
 WHERE c.name_formal = 'South Tucson City Council'
   AND o.title = 'Council Member'
 ORDER BY o.id::text
 LIMIT 1;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM m1864_target;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1864: expected to resolve exactly 1 plain Council Member anchor, found %', n;
  END IF;
  -- The whole no-op-for-routing claim rests on this.
  SELECT count(*) INTO n
    FROM m1864_target t JOIN m1864_before b ON b.old_district_id IS NOT DISTINCT FROM t.district_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1864: target seat is in a DIFFERENT district than the current anchor -- this would move the race between geofences, which is not what this migration claims to do';
  END IF;
END $$;

UPDATE essentials.races r
   SET office_id = (SELECT id FROM m1864_target)
 WHERE r.id = (SELECT race_id FROM m1864_before);

DO $$
DECLARE new_title text; new_district uuid; old_district uuid; s int; k int; n int;
BEGIN
  SELECT o.title, o.district_id, r.seats,
         (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
    INTO new_title, new_district, s, k
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE r.id = (SELECT race_id FROM m1864_before);

  SELECT old_district_id INTO old_district FROM m1864_before;

  IF new_title <> 'Council Member' THEN
    RAISE EXCEPTION 'migration 1864: expected the shell anchored to a plain "Council Member" seat, found "%"', new_title;
  END IF;
  IF new_district IS DISTINCT FROM old_district THEN
    RAISE EXCEPTION 'migration 1864: district changed from % to % -- routing would move', old_district, new_district;
  END IF;
  IF s <> 3 OR k <> 0 THEN
    RAISE EXCEPTION 'migration 1864: seats/candidates altered (seats=%, candidates=%) -- only office_id should have changed', s, k;
  END IF;

  -- and the chamber still has exactly one 2026 shell
  SELECT count(*) INTO n
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE c.name_formal = 'South Tucson City Council'
     AND e.state = 'AZ' AND e.election_date >= '2026-01-01';
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1864: expected 1 South Tucson 2026 shell after update, found %', n;
  END IF;
END $$;

COMMIT;
