-- CA_0136_backfill_monroe_school_current_holders.sql
-- Record the CURRENT officeholder on the geofenced (address-reachable) Monroe school-board
-- offices, clearing the 3 `in|SCHOOL` DEAD_GEOGRAPHY findings the reachability gate reported
-- after CA_0127 seeded those offices.
--
-- ROOT CAUSE. Monroe's school boards exist under two office/district schemes:
--   (a) a STALE, non-address-reachable scheme that carries the sitting members via office_terms
--       (MCCSC geo_ids '1800630-board-dN'; RBB geo_ids '1809480-twp-<township>'), and
--   (b) the address-reachable scheme CA_0127 created for the 2026 races
--       (MCCSC geo_id '1800630'; RBB geo_id '1809480').
-- CA_0127 added the (b) offices + 2026 races/candidates but never recorded a current holder on
-- them, so office_current_holder is empty for (b). The reachability gate keys on (b) (it is the
-- geofenced one) and reports DEAD_GEOGRAPHY = "reachable district, has offices, but no active
-- holder and nothing marked vacant." The seats are NOT vacant — the members sit via (a).
--
-- FIX. Add one current office_term (term_end NULL) linking each sitting member to the matching
-- (b) office. All five members already exist as active politician rows (ballotready). The member
-- seated on each (b) office is the incumbent of the exact seat whose 2026 race lives on it:
--   MCCSC District 1        Erin Wyatt      (incumbent, re-running unopposed 2026)
--   MCCSC District 3        Ashley Pirani   (incumbent, re-running unopposed 2026)
--   MCCSC District 7        Aja Jester      (incumbent, re-running unopposed 2026)
--   RBB Bean Blossom Twp    Angie Jacobs    (2023-2026 term, seat up 2026; successor field: Curtis)
--   RBB Richland Twp        Dana Kerr       (2023-2026 term, seat up 2026; successors: Adams/Scholl)
-- (RBB's other Bean Blossom / Richland seats — Jimmie Durnil and Lawrence Demoss — hold 2025-2028
-- terms and are NOT up in 2026, so they are not the incumbents of the (b) offices, which carry the
-- 2026 races. RBB At-Large already has its holder, Brad Tucker.)
--
-- This does not remove or alter the stale (a) office_terms; it is purely additive. It clears the
-- gate by giving each reachable district a current holder, and it makes the sitting board members
-- surface for residents who look up these seats by address.
--
-- SOURCE: Richland-Bean Blossom Community School Corporation Board of School Trustees roster
-- (rbbschools.net/school-board) and Monroe County Community School Corporation board; incumbency
-- and term windows per the existing politician/office_terms records. Retrieved 2026-09-22.
--
-- IDEMPOTENCY: guarded on (office_id, politician_id) with an open (term_end IS NULL) term.

BEGIN;

CREATE TEMP TABLE sch_term_seed (office_id uuid, politician_id uuid, who text) ON COMMIT DROP;
INSERT INTO sch_term_seed VALUES
  ('8a8393ca-57af-46ce-b13e-d3e936640b85','760e1b7d-022c-4c70-b605-07b6fea2384b','Erin Wyatt / MCCSC District 1'),
  ('a8fb059c-7060-47f2-9268-1e9071e437f6','556a7d23-3acb-4068-a7bc-cecf5194296c','Ashley Pirani / MCCSC District 3'),
  ('d3e11729-0df8-424a-a777-d4bf655a0e84','b3799cb0-d361-4405-b82e-59031c5ffe73','Aja Jester / MCCSC District 7'),
  ('956b21a1-f1ce-44dd-a207-643d19885599','234cb50f-b0fb-4902-b807-da06ac2faddf','Angie Jacobs / RBB Bean Blossom Township'),
  ('ea3c3a2e-68fa-4032-b2aa-d01d79716cfb','55dc950c-cd52-4460-ae3f-630c1c4f771a','Dana Kerr / RBB Richland Township');

INSERT INTO essentials.office_terms
  (id, office_id, politician_id, term_start, term_end, start_precision, how_started, source, created_at)
SELECT gen_random_uuid(), s.office_id, s.politician_id, NULL, NULL, 'unknown', NULL,
       'CA_0136: current officeholder backfilled onto the geofenced (address-reachable) Monroe school-board office; member already sat via a stale duplicate office. Roster: rbbschools.net/school-board + Monroe County Community Schools board. Retrieved 2026-09-22.',
       now()
FROM sch_term_seed s
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot
  WHERE ot.office_id=s.office_id AND ot.politician_id=s.politician_id AND ot.term_end IS NULL
);

-- ─── Post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE v_seated int; v_dead int;
BEGIN
  -- all five intended (office -> holder) pairs now resolve via office_current_holder to an ACTIVE politician
  SELECT count(*) INTO v_seated
    FROM sch_term_seed s
    JOIN essentials.office_current_holder och ON och.office_id=s.office_id AND och.politician_id=s.politician_id
    JOIN essentials.politicians p ON p.id=och.politician_id AND p.is_active;

  -- none of the three reachable school districts is left with zero active holders (i.e. no DEAD_GEOGRAPHY)
  SELECT count(*) INTO v_dead FROM (
    SELECT d.id
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id=d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id=o.id
      LEFT JOIN essentials.politicians p ON p.id=och.politician_id AND p.is_active
     WHERE d.id IN ('9bdc2b0f-6e27-4480-854b-be820d99013a',  -- MCCSC (geo_id 1800630)
                    '76d0828f-b78f-417d-9c49-21b129ba05b9',  -- RBB Bean Blossom (geo_id 1809480)
                    'a2c00ac4-0e1b-4a91-b670-4d6b3ef09c6e')  -- RBB Richland (geo_id 1809480)
     GROUP BY d.id
     HAVING count(p.id) = 0
  ) x;

  IF v_seated <> 5 THEN RAISE EXCEPTION 'Expected 5 seated current holders, got %', v_seated; END IF;
  IF v_dead   <> 0 THEN RAISE EXCEPTION '% reachable school district(s) still have no active holder', v_dead; END IF;
  RAISE NOTICE 'CA_0136 applied: 5 current holders seated; all 3 reachable school districts now covered';
END $$;

COMMIT;
