-- 1865_oro_valley_race_anchor_plain_seat.sql
-- Oro Valley (AZ): re-point the Nov-2026 council race shell from the seat carrying the rotating
-- "Vice Mayor" designation to a plain `Council Member` seat. One row, one column.
--
-- Same class and same reasoning as migration 1864 (South Tucson); this is the last of the four
-- Pima-county town-council shells to be brought into line. After this, all four anchor their
-- at-large council contests to a plain `Council Member` seat.
--
-- 🔑 A CONVENTION, NOT ROUTING -- and verified below rather than assumed. `essentials.races.office_id`
-- anchors a race to ONE office, but this is an at-large multi-seat contest (`seats = 3` of a
-- 7-member body), so the model cannot express "these three of seven seats" and any single anchor is
-- arbitrary. Oro Valley's SIX council seats all share one district, `Town of Oro Valley (At-Large)`;
-- electionService resolves races to a voter through the office's district geo_id, so moving the
-- anchor between two seats in that district cannot change who sees the race. The post-flight guard
-- asserts the district_id is identical before and after.
--
-- ⚠ ORO VALLEY GENUINELY ELECTS ITS MAYOR -- unlike Sahuarita and South Tucson. The canvass carries
-- a `Mayor - Town of Oro Valley` contest, the `Mayor` office sits in its OWN district
-- (`Town of Oro Valley (Mayor)`), and it has its own 1-seat race shell. That shell is NOT touched
-- here, and a guard asserts it still points at the `Mayor` office afterwards. This is exactly why
-- migration 1863 left Oro Valley's titles alone: see project_office_title_ballot_truth_rule.
--
-- ⚠ Oro Valley's `Council Member (Vice Mayor)` TITLE is correct and stays. The vice-mayoralty is a
-- designation on a council seat, which is what the parenthetical form records. Only the RACE ANCHOR
-- moves: a contest for three ordinary seats should not hang off the one seat whose title happens to
-- carry a rotating honorific.
--
-- ANCHOR CHOICE IS DETERMINISTIC so this migration is reproducible: of the five plain `Council
-- Member` offices in the chamber, take the one with the lowest id::text. Nothing about the occupant
-- matters; the seats are interchangeable by construction.
--
-- No migration runner exists; this file records SQL applied by hand via mcp__supabase-local__execute_sql.

BEGIN;

CREATE TEMP TABLE m1865_before ON COMMIT DROP AS
SELECT r.id AS race_id, r.seats, r.position_name,
       o.title AS old_title, o.district_id AS old_district_id,
       (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id) AS cands
  FROM essentials.races r
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.elections e ON e.id = r.election_id
 WHERE c.name_formal = 'Oro Valley Town Council'
   AND e.state = 'AZ' AND e.election_date >= '2026-01-01'
   AND r.position_name = 'Oro Valley Town Council';   -- the COUNCIL shell, never the Mayor shell

DO $$
DECLARE n int; t text; s int; k int;
BEGIN
  SELECT count(*) INTO n FROM m1865_before;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1865: expected exactly 1 Oro Valley 2026 council shell, found %', n;
  END IF;
  SELECT old_title, seats, cands INTO t, s, k FROM m1865_before;
  IF t <> 'Council Member (Vice Mayor)' THEN
    RAISE EXCEPTION 'migration 1865: expected the shell anchored to "Council Member (Vice Mayor)", found "%" -- already moved?', t;
  END IF;
  IF s <> 3 THEN
    RAISE EXCEPTION 'migration 1865: expected seats = 3 on the council shell, found %', s;
  END IF;
  IF k <> 0 THEN
    RAISE EXCEPTION 'migration 1865: shell has % candidate(s); re-anchoring is no longer a safe no-op -- resolve by hand', k;
  END IF;
END $$;

-- Deterministic target: lowest id::text among the plain `Council Member` seats of this chamber.
CREATE TEMP TABLE m1865_target ON COMMIT DROP AS
SELECT o.id, o.district_id
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
 WHERE c.name_formal = 'Oro Valley Town Council'
   AND o.title = 'Council Member'
 ORDER BY o.id::text
 LIMIT 1;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM m1865_target;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1865: expected to resolve exactly 1 plain Council Member anchor, found %', n;
  END IF;
  SELECT count(*) INTO n
    FROM m1865_target t JOIN m1865_before b ON b.old_district_id IS NOT DISTINCT FROM t.district_id;
  IF n <> 1 THEN
    RAISE EXCEPTION 'migration 1865: target seat is in a DIFFERENT district than the current anchor -- this would move the race between geofences';
  END IF;
END $$;

UPDATE essentials.races r
   SET office_id = (SELECT id FROM m1865_target)
 WHERE r.id = (SELECT race_id FROM m1865_before);

DO $$
DECLARE new_title text; new_district uuid; old_district uuid; s int; k int; mayor_anchor text;
BEGIN
  SELECT o.title, o.district_id, r.seats,
         (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
    INTO new_title, new_district, s, k
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
   WHERE r.id = (SELECT race_id FROM m1865_before);

  SELECT old_district_id INTO old_district FROM m1865_before;

  IF new_title <> 'Council Member' THEN
    RAISE EXCEPTION 'migration 1865: expected a plain "Council Member" anchor, found "%"', new_title;
  END IF;
  IF new_district IS DISTINCT FROM old_district THEN
    RAISE EXCEPTION 'migration 1865: district changed from % to % -- routing would move', old_district, new_district;
  END IF;
  IF s <> 3 OR k <> 0 THEN
    RAISE EXCEPTION 'migration 1865: seats/candidates altered (seats=%, candidates=%) -- only office_id should have changed', s, k;
  END IF;

  -- the separately-elected Mayor shell must be exactly where it was
  SELECT o.title INTO mayor_anchor
    FROM essentials.races r
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE c.name_formal = 'Oro Valley Town Council'
     AND e.state = 'AZ' AND e.election_date >= '2026-01-01'
     AND r.position_name = 'Oro Valley Mayor';
  IF mayor_anchor IS DISTINCT FROM 'Mayor' THEN
    RAISE EXCEPTION 'migration 1865: the Oro Valley Mayor shell should still anchor to the "Mayor" office, found %', coalesce(mayor_anchor, '<missing>');
  END IF;
END $$;

COMMIT;
