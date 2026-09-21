-- CC_0106_delete_orphaned_mayor_chamber.sql
-- Indiana slice, DEBT 5 — and it is not Indiana's. Slot RESERVED from the allocator.
--
-- Deletes the single `essentials.chambers` row whose `government_id` points at a government that
-- does not exist. Deletes nothing else.
--
--     id e6935d9d-7a89-4c21-b0e0-7f3f90183b8c · name 'Mayor' · official_count 1 · 0 offices
--     government_id d50caa4b-592f-42d8-8619-4ec82d9ac4ac -- absent from essentials.governments
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 `essentials.chambers.government_id` HAS NO FOREIGN KEY. THAT IS HOW THIS EXISTS.
--
-- Found 2026-09-11 while closing debt 2, which had been written as "delete the government rows
-- that hold no chamber". Checking the constraint showed `essentials.governments` has exactly ONE
-- inbound foreign key and it is **not** from chambers — it is `districts.government_id`. So
-- "empty of chambers" was never the same question as "referenced by nothing", and a chamber can
-- outlive its government silently. One has.
--
-- ▶ **THE RULE WORTH KEEPING: A COUNT OF CHILDREN IS NOT A COUNT OF REFERENCES UNTIL YOU HAVE
-- READ `pg_constraint`.** Debt 2's guard was corrected to "no chambers AND no districts" before it
-- ran, and its count happened to be the same either way — which was luck, not confirmation.
--
-- ⚠ NOT INDIANA'S, AND IT PREDATES THIS WORK. `CC_0098` neither caused it nor fixed it; its gate
-- deliberately asserted the orphan count was UNCHANGED rather than zero, so this row would still
-- be here to deal with on purpose. There is no way to tell which city's mayor it was: the row
-- carries a name, a count of 1, no offices, and a dangling id. Nothing to repoint it to.
--
-- WHY A DELETE IS SAFE HERE. Three tables reference `chambers`, and this row is reachable from
-- none of them — checked 2026-09-12, and two of the three would not even have blocked it:
--
--     meetings.meetings.chamber_id ......... 0 rows   (NO ACTION — this one WOULD have blocked)
--     essentials.discovered_sources ........ 0 rows   (ON DELETE SET NULL)
--     essentials.source_outlets ............ 0 rows   (ON DELETE SET NULL)
--     essentials.offices.chamber_id ........ 0 rows
--
-- 🔴 A meeting row would have been evidence the chamber is REAL and wants repointing rather than
-- deleting. There is none, so it is not evidence of anything.
--
-- ⚠ SCOPE. Seven OTHER chambers hold no offices, and they are left alone: their governments exist,
-- so they are empty, not orphaned. This migration takes only the row whose parent is missing.
--
-- Idempotent: a re-run deletes 0.

BEGIN;

CREATE TEMP TABLE in_orphan_chamber ON COMMIT DROP AS
SELECT c.id, c.name, c.government_id
FROM essentials.chambers c
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);

DO $$
DECLARE v_n int; v_off int; v_meet int; v_ds int; v_so int; v_named int; v_total int;
BEGIN
  SELECT count(*) INTO v_n FROM in_orphan_chamber;
  IF v_n NOT IN (0, 1) THEN
    RAISE EXCEPTION 'CC_0106 pre-flight: % orphaned chamber(s), expected exactly 1 (or 0 on a re-run). More than one means a new mechanism, not this row.', v_n;
  END IF;
  IF v_n = 0 THEN RAISE NOTICE 'CC_0106: nothing to do, the orphaned chamber is already gone'; END IF;

  -- Pin the identity, so this cannot quietly delete some other orphan that appears later.
  SELECT count(*) INTO v_named FROM in_orphan_chamber
   WHERE id = 'e6935d9d-7a89-4c21-b0e0-7f3f90183b8c' AND name = 'Mayor';
  IF v_n = 1 AND v_named <> 1 THEN
    RAISE EXCEPTION 'CC_0106 pre-flight: the orphaned chamber is not the one this migration was written for -- read it before deleting it';
  END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o JOIN in_orphan_chamber c ON c.id = o.chamber_id;
  IF v_off <> 0 THEN RAISE EXCEPTION 'CC_0106 pre-flight: % office(s) hang on it -- it is in use', v_off; END IF;

  -- 🔴 meetings.meetings has NO ON DELETE clause: a row here both blocks the delete and means the
  -- chamber is real.
  SELECT count(*) INTO v_meet FROM meetings.meetings m JOIN in_orphan_chamber c ON c.id = m.chamber_id;
  IF v_meet <> 0 THEN
    RAISE EXCEPTION 'CC_0106 pre-flight: % meeting(s) reference it -- that is evidence it is a real body, so repoint it rather than delete it', v_meet;
  END IF;

  -- These two would SET NULL rather than block, so silence here is worth asserting explicitly.
  SELECT count(*) INTO v_ds FROM essentials.discovered_sources d JOIN in_orphan_chamber c ON c.id = d.chamber_id;
  SELECT count(*) INTO v_so FROM essentials.source_outlets s JOIN in_orphan_chamber c ON c.id = s.chamber_id;
  IF v_ds <> 0 OR v_so <> 0 THEN
    RAISE EXCEPTION 'CC_0106 pre-flight: % discovered_source(s) and % source_outlet(s) reference it -- ON DELETE SET NULL would silently blank them', v_ds, v_so;
  END IF;

  SELECT count(*) INTO v_total FROM essentials.chambers;
  IF v_n = 1 AND v_total <> 1176 THEN
    RAISE EXCEPTION 'CC_0106 pre-flight: % chambers, expected 1176 as measured 2026-09-12', v_total;
  END IF;
END $$;

DELETE FROM essentials.chambers c USING in_orphan_chamber o WHERE c.id = o.id;

DO $$
DECLARE v_left int; v_total int; v_empty int;
BEGIN
  SELECT count(*) INTO v_left FROM essentials.chambers c
   WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);
  IF v_left <> 0 THEN RAISE EXCEPTION 'CC_0106: % orphaned chamber(s) remain', v_left; END IF;

  SELECT count(*) INTO v_total FROM essentials.chambers;
  IF v_total NOT IN (1175, 1176) THEN
    RAISE EXCEPTION 'CC_0106: % chambers remain, expected 1175 (or 1176 on a re-run)', v_total;
  END IF;

  -- ⚠ The seven legitimately-empty chambers are untouched: empty is not orphaned.
  SELECT count(*) INTO v_empty FROM essentials.chambers c
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id);
  IF v_empty <> 7 THEN
    RAISE EXCEPTION 'CC_0106: % chamber(s) hold no offices, expected the 7 that have a real government', v_empty;
  END IF;

  RAISE NOTICE 'CC_0106 OK: the orphaned Mayor chamber is gone, 0 orphans remain, the 7 empty-but-parented chambers untouched';
END $$;

COMMIT;
