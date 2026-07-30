-- 1497_null_dangling_politician_office_pointers.sql
--
-- 11 essentials.politicians rows carry an `office_id` pointing at an office that no longer
-- exists. `politicians.office_id` has NO foreign key (it is the legacy point-in-time snapshot
-- deprecated by ADR 0002), so nothing prevented the value from outliving its office.
--
-- Nulling is the correct fix, not repair: none of the 11 has ANY office_terms row, so there is
-- no current seat to re-point at, and the deleted office id is unrecoverable. The read path
-- already resolves the real office through essentials.office_current_holder --
-- getPoliticianById (backend/src/lib/essentialsService.ts) selects p.office_id as a passthrough
-- field but joins on och.office_id, so no join behaviour changes here. The API field simply goes
-- from a stale nonexistent UUID to null, which is the honest value.
--
-- The 11, by why they are unseated:
--
--   duplicate of a row that IS seated (7) -- pointer is redundant
--     Bettina Smith Edmondson  twin -4943660003 seated on Layton city council
--     Richard A. Hyer          twin 'Richard Hyer' seated Ogden Council District 2
--     Victoria Petro           twin 'Victoria Petro-Eschler' seated SLC Council District 1
--     Bill Miranda             twin -200980 seated Santa Clarita Councilmember At-Large
--     Caroline Menjivar        twin -6001020 seated California State Senate district 20
--     Tony Strickland          twin -6001036 seated California State Senate district 36
--     Mario Trujillo           twin 'Mario Trujillo -' seated Councilmember District 5
--
--   no current term; the seat is now held by someone else (2)
--     Darin Mano               SLC Council District 5 currently holds Erika Carlsen
--     Eva Lopez                SLC Council District 4 currently holds Jennifer Napier-Pearce
--
--   no twin, no seat, jurisdiction not seeded (2)
--     Ara Najarian             Glendale CA; a second Najarian row is likewise unseated
--     James T. Butts           Inglewood CA; the city has no districts/offices in the DB
--
-- Written as a general NOT EXISTS sweep rather than 11 hard-coded ids: it repairs exactly the
-- dangling rows, is naturally idempotent, and will catch any future stragglers.
--
-- NOT fixed here, deliberately, and NOT the same bug: 11 UT council seats are duplicated across
-- `districts.state` letter-casing ('ut' vs 'UT') -- Ogden District 1/3/4, West Jordan District
-- 1-4, West Valley City District 1-4. Each is two district rows carrying two offices that
-- resolve to a single holder. A duplicate detector that groups by district_id cannot see these,
-- because the duplicates live on DIFFERENT district rows. Tracked separately.

BEGIN;

UPDATE essentials.politicians p
   SET office_id = NULL
 WHERE p.office_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p.office_id);

-- ── post-verify gate ───────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_dangling int;
  v_lost     int;
BEGIN
  SELECT count(*) INTO v_dangling
    FROM essentials.politicians p
   WHERE p.office_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p.office_id);
  IF v_dangling <> 0 THEN
    RAISE EXCEPTION '1497: % politicians.office_id values still dangle', v_dangling;
  END IF;

  -- Nulling a dangling pointer must not have cost anyone a resolvable office. Every politician
  -- with a NON-null office_id must still point at a real office.
  SELECT count(*) INTO v_lost
    FROM essentials.politicians p
   WHERE p.office_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.id = p.office_id);
  IF v_lost <> 0 THEN
    RAISE EXCEPTION '1497: % surviving pointers are invalid', v_lost;
  END IF;

  RAISE NOTICE '1497 OK: no dangling politicians.office_id remains';
END $$;

COMMIT;
