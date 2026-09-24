-- CA_0260_judge_election_flags.sql
-- Correct the election flags on judicial seats in California and Indiana, so the Essentials Judges tab can show
-- elected judges only.
--
-- WHY NOW. The Essentials Judges tab is changing from "appointed only" to "elected only" (operator decision, Chris
-- Andrews, 2026-09-24: "focus on elected judges and leave appointed out"). The frontend reads two office columns:
--   is_elected           = NOT offices.is_appointed_position   (essentialsBrowseService.ts)
--   faces_retention_vote = offices.faces_retention_vote
-- and its "Elected" filter keeps a judge when is_elected OR faces_retention_vote. Measured 2026-09-24, those columns
-- are wrong for four groups of seats, so the new tab would drop every judge in LA County and every Monroe County
-- circuit judge.
-- ORDER: this and the essentials change must ship close together. Neither order is free: the OLD frontend (Judges
-- = 'Appointed') hides the seats this corrects to elected (LA Superior Court 408, Monroe circuit 9), and the NEW
-- frontend hides them until this runs.
--
-- WHAT CHANGES (state law, and the district rows already agree where they carry districts.retention):
--   A. CA Superior Court (473 seats)           is_appointed_position true -> false.
--      Superior Court judges are elected on a nonpartisan ballot (Cal. Const. art. VI, sec. 16(b)). A governor's
--      appointment only fills a vacancy until the next election; the seat is an elected seat.
--   B. CA Court of Appeal + Supreme Court (31) faces_retention_vote false -> true.  is_appointed_position stays true.
--      Justices are appointed and then stand for yes/no retention (art. VI, sec. 16(a), (d)). districts.retention is
--      already true for these seats.
--   C. IN circuit courts + county superior courts outside Marion County (24 seats)
--                                               is_appointed_position true -> false.
--      Indiana circuit court judges are elected (Ind. Const. art. 7, sec. 7); the Greene, Jackson, Lawrence and
--      Morgan superior courts are elected by statute (IC 33-33).
--   D. Marion County Superior Court (28 seats)  faces_retention_vote false -> true.  is_appointed_position stays true.
--      Since 2017 these judges are nominated by the Marion County Judicial Selection Committee, appointed by the
--      governor, and stand for retention (IC 33-33-49, as amended in 2017). districts.retention is already true for
--      these seats.
--
-- NOT CHANGED. Indiana Supreme Court and Court of Appeals (already appointed + retention), Wisconsin and Texas
-- courts (already elected), GA/SC probate and Gary City Court (is_appointed_position NULL reads as elected, which
-- is correct), the four CA "Judge of the Superior Court, Office No. N" race seats (already false), SCOTUS, and every
-- politician-level is_appointed override. No occupancy (office_terms) row is touched. essentials.offices has no
-- triggers (checked 2026-09-24), so the UPDATEs have no side effects.
--
-- No migration runner exists; this file records SQL applied by hand.
-- STATUS: APPLIED to prod 2026-09-24 (operator approval: Chris Andrews, "yes, apply CA_0260").
--   Dry run first inside BEGIN ... ROLLBACK: both gates passed; rollback verified by counts and an md5 digest of
--   every CA/IN judicial seat's two flags (15b6c771e7cac5e0394261670f27736b, unchanged before and after).
--   Digest re-checked unchanged immediately before the apply. After the apply the CA/IN judicial seats read
--   appointed-with-no-retention 0 (was 556), elected 522 (was 25), retention 79 (was 20); digest
--   75383c0b51172019cea4d1d201e512f2. Live by-government-list after: LA County 416 judges and Monroe County 12
--   pass the essentials 'Elected' filter (were 0 and 3).
--
-- ROLLBACK: re-run the four UPDATEs with the old values (A, C: is_appointed_position = true; B, D:
--           faces_retention_vote = false) on the same selectors.
-- IDEMPOTENT: every UPDATE is guarded with IS DISTINCT FROM; a re-run changes 0 rows and every gate still passes.

BEGIN;

CREATE TEMP TABLE ca0260_target ON COMMIT DROP AS
SELECT o.id AS office_id,
       CASE
         WHEN o.representing_state = 'CA' AND c.name = 'Superior Court'                                  THEN 'A'
         WHEN o.representing_state = 'CA' AND (c.name LIKE 'Court of Appeal%' OR c.name = 'Supreme Court') THEN 'B'
         WHEN o.representing_state = 'IN' AND c.name LIKE 'Indiana Circuit Court Judge%'                   THEN 'C'
         WHEN o.representing_state = 'IN' AND c.name LIKE 'Superior Court Judge%'
              AND g.name IS DISTINCT FROM 'Marion County, Indiana, US'                                     THEN 'C'
         WHEN o.representing_state = 'IN' AND g.name = 'Marion County, Indiana, US'
              AND c.name = 'Superior Court Judge'                                                         THEN 'D'
       END AS grp
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'JUDICIAL'
  JOIN essentials.chambers c ON c.id = o.chamber_id
  LEFT JOIN essentials.governments g ON g.id = c.government_id
 WHERE o.representing_state IN ('CA', 'IN');

DELETE FROM ca0260_target WHERE grp IS NULL;

-- ─── Pre-flight: the selectors match exactly the seats measured on 2026-09-24 ────────────────────
DO $$
DECLARE v_a int; v_b int; v_c int; v_d int;
BEGIN
  SELECT count(*) FILTER (WHERE grp = 'A'), count(*) FILTER (WHERE grp = 'B'),
         count(*) FILTER (WHERE grp = 'C'), count(*) FILTER (WHERE grp = 'D')
    INTO v_a, v_b, v_c, v_d FROM ca0260_target;
  IF (v_a, v_b, v_c, v_d) IS DISTINCT FROM (473, 31, 24, 28) THEN
    RAISE EXCEPTION 'PRE: target counts A=% B=% C=% D=%, expected 473/31/24/28 -- re-measure before applying',
      v_a, v_b, v_c, v_d;
  END IF;
END $$;

-- A + C: elected seats.
UPDATE essentials.offices o SET is_appointed_position = false
  FROM ca0260_target t
 WHERE t.office_id = o.id AND t.grp IN ('A', 'C') AND o.is_appointed_position IS DISTINCT FROM false;

-- B + D: appointed seats that stand for retention.
UPDATE essentials.offices o SET faces_retention_vote = true
  FROM ca0260_target t
 WHERE t.office_id = o.id AND t.grp IN ('B', 'D') AND o.faces_retention_vote IS DISTINCT FROM true;

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_bad int; v_shown int;
BEGIN
  SELECT count(*) INTO v_bad
    FROM ca0260_target t JOIN essentials.offices o ON o.id = t.office_id
   WHERE (t.grp IN ('A', 'C') AND o.is_appointed_position IS DISTINCT FROM false)
      OR (t.grp IN ('B', 'D') AND (o.is_appointed_position IS DISTINCT FROM true
                                   OR o.faces_retention_vote IS DISTINCT FROM true));
  IF v_bad <> 0 THEN RAISE EXCEPTION 'POST: % target seats still carry the wrong flags', v_bad; END IF;

  -- Every CA/IN judicial seat now passes the Essentials "Elected" filter (elected OR retention).
  SELECT count(*) INTO v_shown
    FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'JUDICIAL'
   WHERE o.representing_state IN ('CA', 'IN')
     AND o.is_appointed_position IS TRUE AND o.faces_retention_vote IS DISTINCT FROM true;
  IF v_shown <> 0 THEN RAISE EXCEPTION 'POST: % CA/IN judicial seats are still appointed with no retention vote', v_shown; END IF;

  RAISE NOTICE 'CA_0260 applied: 497 seats now elected (A 473 + C 24), 59 seats now retention (B 31 + D 28)';
END $$;

COMMIT;
