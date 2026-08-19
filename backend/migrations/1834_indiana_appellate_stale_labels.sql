-- 1834_indiana_appellate_stale_labels.sql
--
-- Migration 1833 seated the two sitting judges, which left their district LABELS naming the judges
-- they replaced: "Indiana Appeals Court Judge - District 3 (Retain Crone?)" now resolves to Stephen
-- Scheele, and "... District 5 (Retain Robb?)" to Paul Felix.
--
-- This is voter-facing, not cosmetic. `districts.label` is selected as `district_label` in
-- districtQueries.ts, compassService.ts and essentialsBodiesService.ts, and
-- essentialsBodiesService.resolveDistrictLabel passes a non-empty label through UNCHANGED — so the
-- retired judge's name renders beside the sitting judge's.
--
-- ⚠ THE PARENTHETICAL IS DROPPED, NOT REWRITTEN. "(Retain Scheele?)" would be worse than the bug:
-- it asserts a retention question that is on no ballot. Judges appointed to the Court of Appeals
-- face retention at a later general election, and inventing that question here would be a claim
-- about a future ballot that nothing in this repo sources. The label becomes exactly the seat, which
-- is the thing that is actually true and already matches offices.title.
--
-- SCOPE. Only the two rows whose holder changed. The other nine keep their parenthetical: for seven
-- the named judge still holds the seat, and the remaining two (Retain Kirsch?, Retain Riley?) are
-- unoccupied offices — a different defect, untouched here rather than quietly folded in.

BEGIN;

UPDATE essentials.districts
   SET label = 'Indiana Appeals Court Judge - District 3'
 WHERE state = 'IN' AND district_type = 'JUDICIAL'
   AND label = 'Indiana Appeals Court Judge - District 3 (Retain Crone?)';

UPDATE essentials.districts
   SET label = 'Indiana Appeals Court Judge - District 5'
 WHERE state = 'IN' AND district_type = 'JUDICIAL'
   AND label = 'Indiana Appeals Court Judge - District 5 (Retain Robb?)';

DO $$
DECLARE n_stale int; n_ok int;
BEGIN
  -- No Indiana appellate label may name a judge who does not hold that seat.
  SELECT count(*) INTO n_stale
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
    LEFT JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.state = 'IN' AND d.district_type = 'JUDICIAL' AND d.label ILIKE '%Appeals%'
     AND d.label ~ '\(Retain .+\?\)'
     AND p.last_name IS NOT NULL
     AND d.label NOT ILIKE '%(Retain ' || p.last_name || '?)%';
  IF n_stale > 0 THEN
    RAISE EXCEPTION '% Indiana appellate label(s) name a judge who does not hold the seat', n_stale;
  END IF;

  SELECT count(*) INTO n_ok
    FROM essentials.districts
   WHERE state = 'IN' AND district_type = 'JUDICIAL'
     AND label IN ('Indiana Appeals Court Judge - District 3',
                   'Indiana Appeals Court Judge - District 5');
  IF n_ok <> 2 THEN
    RAISE EXCEPTION 'expected 2 de-parenthesised appellate labels, found %', n_ok;
  END IF;

  RAISE NOTICE 'OK: 2 stale labels cleared; no appellate label names a non-holder';
END $$;

COMMIT;
