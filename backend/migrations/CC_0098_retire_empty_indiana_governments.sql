-- CC_0098_retire_empty_indiana_governments.sql
-- Knight Foundation program, Indiana debt 2. Slot RESERVED from the allocator.
--
-- Deletes the 17 `State of Indiana` government rows that reference nothing, leaving 5.
-- Creates nothing. Touches no other state.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- WHERE THEY CAME FROM. IN-2 (CC_0088) repaired Indiana's structural defect: its 18 legislative
-- offices hung on 18 pseudo-chambers, one per district, each with `official_count` 0, spread
-- over 18 separate `State of Indiana` government rows. Indiana was the only state whose
-- legislative chamber count exceeded 2. The offices were repointed and the emptied chambers
-- deleted -- which left their government rows behind, holding nothing. IN-2 predicted this and
-- recorded it as a debt rather than widening its own blast radius. This is that debt.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 "EMPTY OF CHAMBERS" IS NOT "REFERENCED BY NOTHING", AND THE DIFFERENCE IS THE WHOLE RISK.
-- The debt note said "17 empty" on a count of chambers. `essentials.governments` has exactly ONE
-- inbound foreign key and it is not from chambers:
--
--     essentials.districts.government_id   ON DELETE NO ACTION
--
-- Measured 2026-09-11: of the 22 rows, one carries 16 chambers, one carries 11, three carry one
-- each -- and of those three, ONE is also referenced by a district. The 17 this migration deletes
-- have NO chambers AND NO districts. The guard tests both, so the count and the deletion criteria
-- cannot drift apart. NO ACTION means the database would refuse a referenced row anyway; the
-- guard is here so the migration never has to find that out.
--
-- 🟢 INDIANA IS THE ONLY STATE WITH THIS CONDITION. A sweep of every `STATE` government with no
-- chambers and no districts returns 17 rows, all Indiana. So this is IN-2's residue, not a
-- national pattern, and this migration is deliberately scoped by name rather than generalised.
--
-- ⚠ FIVE ROWS SURVIVE AND TWO OF THEM ARE LARGE -- 16 chambers / 20 offices, and 11 chambers /
-- 165 offices. Which of those is "the real Indiana" is NOT settled here and is not this
-- migration's business. Consolidating them would move offices between governments, which is a
-- different decision with a different blast radius. This migration only removes rows that
-- reference nothing and that nothing references.
--
-- Idempotent: the DELETE is guarded, so a re-run removes 0 rows. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_total int; v_dead int;
BEGIN
  SELECT count(*) INTO v_total FROM essentials.governments WHERE name = 'State of Indiana';
  IF v_total NOT IN (22, 5) THEN
    RAISE EXCEPTION 'IN-debt2 pre-flight: % State of Indiana government rows, expected 22 before or 5 after. Re-measure before running.', v_total;
  END IF;

  SELECT count(*) INTO v_dead FROM essentials.governments g
   WHERE g.name = 'State of Indiana'
     AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);
  IF v_dead NOT IN (17, 0) THEN
    RAISE EXCEPTION 'IN-debt2 pre-flight: % unreferenced rows, expected 17 before or 0 after. The cohort has changed -- re-measure.', v_dead;
  END IF;
END $$;

-- ─── Record the pre-existing orphan count ────────────────────────────────────
-- 🔴 `chambers.government_id` HAS NO FOREIGN KEY. Measured 2026-09-11: the only inbound FK on
-- `essentials.governments` is `districts.government_id`, so a chamber CAN point at a government
-- row that does not exist -- and one already does, a chamber named 'Mayor' with 0 offices,
-- unrelated to Indiana. The first version of this gate asserted "0 orphaned chambers" globally
-- and failed on that pre-existing row, which this migration neither caused nor can fix.
-- So the gate asserts the count is UNCHANGED: this migration orphaned nothing.

CREATE TEMP TABLE _debt2_before ON COMMIT DROP AS
SELECT count(*) AS orphan_chambers FROM essentials.chambers c
 WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);

-- ─── Delete ──────────────────────────────────────────────────────────────────
-- Both NOT EXISTS clauses are load-bearing. Dropping either one would delete a row that
-- something points at.

DELETE FROM essentials.governments g
 WHERE g.name = 'State of Indiana'
   AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
   AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_total int; v_dead int; v_big int; v_mid int; v_other int; v_orphan int; v_before int;
BEGIN
  SELECT count(*) INTO v_total FROM essentials.governments WHERE name = 'State of Indiana';
  IF v_total <> 5 THEN RAISE EXCEPTION 'IN-debt2: % State of Indiana rows remain, expected 5', v_total; END IF;

  SELECT count(*) INTO v_dead FROM essentials.governments g
   WHERE g.name = 'State of Indiana'
     AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);
  IF v_dead <> 0 THEN RAISE EXCEPTION 'IN-debt2: % unreferenced rows survive', v_dead; END IF;

  -- The two large rows must be untouched. This is the assertion that would catch a guard that
  -- deleted the wrong thing, which a bare count of 5 would not.
  SELECT count(*) INTO v_big FROM essentials.governments g
   WHERE g.name = 'State of Indiana'
     AND (SELECT count(*) FROM essentials.chambers c WHERE c.government_id = g.id) = 16;
  IF v_big <> 1 THEN RAISE EXCEPTION 'IN-debt2: the 16-chamber Indiana row is gone or duplicated (found %)', v_big; END IF;

  SELECT count(*) INTO v_mid FROM essentials.governments g
   WHERE g.name = 'State of Indiana'
     AND (SELECT count(*) FROM essentials.chambers c WHERE c.government_id = g.id) = 11;
  IF v_mid <> 1 THEN RAISE EXCEPTION 'IN-debt2: the 11-chamber Indiana row is gone or duplicated (found %)', v_mid; END IF;

  -- 🔴 NOTHING OUTSIDE INDIANA MAY HAVE MOVED. The DELETE is scoped by name; this proves it.
  SELECT count(*) INTO v_other FROM essentials.governments g
   WHERE g.type = 'STATE' AND g.name <> 'State of Indiana'
     AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)
     AND NOT EXISTS (SELECT 1 FROM essentials.districts d WHERE d.government_id = g.id);
  IF v_other <> 0 THEN
    RAISE EXCEPTION 'IN-debt2: % empty STATE government(s) outside Indiana -- measured at 0 on 2026-09-11, so this is either drift or the wrong scope', v_other;
  END IF;

  -- This migration must not orphan a chamber. Asserted as "unchanged", not as "zero" -- see the
  -- note above the DELETE for why zero is not true of production.
  SELECT count(*) INTO v_orphan FROM essentials.chambers c
   WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);
  SELECT orphan_chambers INTO v_before FROM _debt2_before;
  IF v_orphan <> v_before THEN
    RAISE EXCEPTION 'IN-debt2: orphaned chambers went from % to % -- this migration orphaned one', v_before, v_orphan;
  END IF;

  RAISE NOTICE 'IN-debt2 OK: 17 unreferenced State of Indiana rows retired, 5 remain (16-chamber and 11-chamber rows intact), nothing outside Indiana touched, orphaned chambers unchanged at %', v_before;
END $$;

COMMIT;
