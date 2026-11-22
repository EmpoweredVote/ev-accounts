-- CC_0459 — essentials.district_seat_group: emit a group only where the body actually has a
--            recorded election result.
--
-- WHY. CC_0459 is a performance fix for the ADDRESS PATH, which is the surface a voter uses.
--
-- CC_0458 aggregated EVERY office in the database into a group — 8,443 groups over 11,130 offices
-- — and the address query joins that aggregate on every request. Measured on prod against a
-- whole-state read (California, 2,128 offices):
--
--     without the CC_0458 joins at all ............ 416 ms
--     with them, grouping every office ............ 692 ms   (+276 ms, ~66% slower)
--     with them, with the filter this adds ........ 238 ms
--
-- 🔴 THE FILTERED VERSION IS FASTER THAN THE QUERY WAS BEFORE THE FEATURE EXISTED. The aggregate
-- drops from 8,443 groups to 1,268, and the planner stops building a hash of the whole offices
-- table on every address lookup.
--
-- WHAT IT CHANGES FOR A READER. A group is now NULL for a body with no recorded result. That is
-- the correct answer rather than a cheaper one:
--
--   * the group payload exists only to serve the two MULTI-SEAT RESULT cases, where several
--     winners attach to one office row and the sibling seats would otherwise read as "nobody is
--     coming". A body with no result has nothing to group.
--   * a seat with a DATED term does not use the group at all — it names its own successor.
--   * 🔴 THE EXISTS IS EVALUATED PER (district, chamber), NOT PER OFFICE, which is the whole
--     point. An office that carries no race of its own still gets its body's group, as long as
--     SOME office in that body has a result. That is exactly the sibling-seat case: AN OFFICE
--     WITH NO RACE IS INVISIBLE, NOT INCOMPLETE.
--   * so every office that has a pending winner still has a group (it satisfies its own EXISTS),
--     and the single-seat test the renderer makes — offices = 1 — is unaffected.
--
-- ⚠ OVERWRITES CC_0458's DEFINITION OF THIS VIEW, ONE DAY OLD AND NOT YET MERGED. The previous
-- definition is reproduced here in full so this file is a complete record of what was replaced,
-- per the rule that a migration which overwrites a value must record the value it overwrote:
--
--     CREATE OR REPLACE VIEW essentials.district_seat_group
--     WITH (security_invoker = on) AS
--     SELECT o.district_id,
--            o.chamber_id,
--            o.district_id::text || '|' || COALESCE(o.chamber_id::text, '') AS group_id,
--            count(*)::int                              AS offices,
--            count(och.politician_id)::int              AS seated,
--            COALESCE(sum(w.winner_count), 0)::int      AS winners
--       FROM essentials.offices o
--       LEFT JOIN essentials.office_current_holder och  ON och.office_id = o.id
--       LEFT JOIN essentials.office_pending_winner w    ON w.office_id   = o.id
--      WHERE o.district_id IS NOT NULL
--      GROUP BY o.district_id, o.chamber_id;
--
-- Everything else about the view is unchanged: still one row per (district_id, chamber_id), still
-- counting och.politician_id rather than count(*) so a vacancy is not counted as a seated person,
-- still excluding the 25 offices that carry no district.

BEGIN;

CREATE OR REPLACE VIEW essentials.district_seat_group
WITH (security_invoker = on) AS
SELECT o.district_id,
       o.chamber_id,
       o.district_id::text || '|' || COALESCE(o.chamber_id::text, '') AS group_id,
       count(*)::int                              AS offices,
       -- 🔴 NOT count(*). office_current_holder LEFT JOINs from offices, so a vacancy is a row
       -- with a NULL politician_id and count(*) would report an empty seat as occupied. The
       -- group arrow is drawn only when offices = winners = seated, so an inflated seated count
       -- would draw an arrow for a body that is not whole.
       count(och.politician_id)::int              AS seated,
       COALESCE(sum(w.winner_count), 0)::int      AS winners
  FROM essentials.offices o
  LEFT JOIN essentials.office_current_holder och  ON och.office_id = o.id
  LEFT JOIN essentials.office_pending_winner w    ON w.office_id   = o.id
 WHERE o.district_id IS NOT NULL
   -- 🔴 PER BODY, NOT PER OFFICE. See the header: a sibling seat with no race of its own must
   -- still receive its body's group, or the multi-seat display loses the very rows it exists to
   -- explain.
   AND EXISTS (
     SELECT 1
       FROM essentials.offices o2
       JOIN essentials.office_pending_winner w2 ON w2.office_id = o2.id
      WHERE o2.district_id = o.district_id
        AND o2.chamber_id IS NOT DISTINCT FROM o.chamber_id
   )
 GROUP BY o.district_id, o.chamber_id;

COMMENT ON VIEW essentials.district_seat_group IS
  'The three counts the multi-seat group display needs, one row per (district_id, chamber_id), '
  'for bodies that have at least one recorded election result. How many office rows the body has '
  'here, how many of them someone sits in today, and how many winners are recorded across them. '
  'The group-to-group arrow is permitted ONLY when all three agree — a staggered body (five '
  'members, three seats up) would otherwise draw an arrow from five people to three and imply the '
  'body is shrinking. A body with no result has no row: nothing to group. CC_0458, CC_0459.';

DO $$
DECLARE
  v_groups           int;
  v_group_dupes      int;
  v_oversubscribed   int;
  v_clean_groups     int;
  v_pending_offices  int;
  v_orphaned_pending int;
BEGIN
  SELECT count(*) INTO v_groups FROM essentials.district_seat_group;

  SELECT count(*) INTO v_group_dupes FROM (
    SELECT group_id FROM essentials.district_seat_group
     GROUP BY group_id HAVING count(*) > 1
  ) g;

  SELECT count(*) INTO v_oversubscribed
    FROM essentials.district_seat_group WHERE seated > offices;

  SELECT count(*) INTO v_clean_groups
    FROM essentials.district_seat_group
   WHERE offices > 1 AND winners > 0 AND offices = winners AND offices = seated;

  SELECT count(*) INTO v_pending_offices FROM essentials.office_pending_winner;

  -- 🔴 THE GATE THAT MATTERS FOR THIS CHANGE. Every office that has a pending winner must still
  -- resolve a group, or the renderer loses the single-seat test (offices = 1) and every case (b)
  -- card silently stops drawing. A filter that drops one of these is the whole risk of CC_0459.
  SELECT count(*) INTO v_orphaned_pending
    FROM essentials.office_pending_winner w
    JOIN essentials.offices o ON o.id = w.office_id
    LEFT JOIN essentials.district_seat_group dsg
           ON dsg.district_id = o.district_id
          AND dsg.chamber_id IS NOT DISTINCT FROM o.chamber_id
   WHERE o.district_id IS NOT NULL
     AND dsg.group_id IS NULL;

  IF v_group_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0459: % group_id(s) appear more than once', v_group_dupes;
  END IF;

  IF v_oversubscribed <> 0 THEN
    RAISE EXCEPTION 'CC_0459: % group(s) report more people seated than they have offices', v_oversubscribed;
  END IF;

  IF v_orphaned_pending <> 0 THEN
    RAISE EXCEPTION 'CC_0459: % office(s) have a pending winner but NO seat group; the filter is too narrow', v_orphaned_pending;
  END IF;

  IF v_groups = 0 THEN
    RAISE EXCEPTION 'CC_0459: the view is empty; the filter cannot be right';
  END IF;

  RAISE NOTICE 'CC_0459 OK: % group(s) (was 8443), % clean multi-seat group(s), % office(s) with a pending winner and every one of them grouped',
               v_groups, v_clean_groups, v_pending_offices;
END $$;

COMMIT;
