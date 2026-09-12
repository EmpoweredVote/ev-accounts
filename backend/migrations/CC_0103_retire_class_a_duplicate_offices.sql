-- CC_0103_retire_class_a_duplicate_offices.sql
-- Indiana debt 1, STEP 2a. Slot RESERVED from the allocator.
--
-- Deletes the 84 CLASS A orphan offices: placeholder offices whose holder ALSO holds the real
-- version of that same seat. Their 84 placeholder terms cascade with them.
-- Deletes NO people. Touches NO flags. Leaves the 587 class B/C orphan offices alone.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS IS A DELETE, SO THE BAR IS HIGHER, AND THE EVIDENCE IS THAT THE ROW ASSERTS NOTHING.
--
-- IN-2 reused 84 existing `indiana_discovery` person rows rather than creating duplicates, which
-- was right (ruling R2, 2026-09-10). Each of those people now holds TWO offices: the real seat
-- IN-2 gave them, and the placeholder the discovery sweep made. The placeholder has:
--
--     no district · no chamber · no government · no representing_city
--     a term from the ADR 0002 phase-2 backfill: no start date, no end date, precision 'unknown'
--     0 races referencing it · 0 `politicians.office_id` snapshots pointing at it
--
-- ▶ **AND ITS TITLE IS THE SAME SEAT, MEASURED, NOT ASSUMED.** Across all 84:
--
--     State Representative      -> Representative ... 33      State Senator -> Senator ... 18
--     Indiana Elected Official  -> Representative ... 23      Indiana Elected Official -> Senator ... 10
--
-- Not one contradicts. Nobody holds a House seat plus an orphan "Governor". So the row carries no
-- fact the real seat does not carry better, and the term carries no date to preserve.
--
-- 🔴 WHAT IT COSTS TODAY, which is the reason this is step 2a and not "later":
-- `GET /api/essentials/politicians?q=` joins FROM politicians to `office_current_holder`, so a
-- person holding two offices yields TWO ROWS. Verified in production: "Aaron Freeman" returns 2.
-- ⚠ The comment above that join (`essentialsService.ts:517-519`) says "One row per office, so this
-- cannot fan out" -- true joining FROM offices, false joining FROM politicians. `CC_0101` could not
-- fix this: these 84 are sitting legislators and must stay active. Only removing the duplicate
-- OFFICE fixes it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 A CONTROL WAS WATCHED FIRING before this was written: the broad predicate (any orphan office
-- held by an `indiana_discovery` person) selects **671**; adding the "holder also holds a real
-- seat" clause selects **84**. The restriction discriminates, and the pre-flight asserts both
-- numbers so it keeps discriminating.
--
-- ⚠ CLASS B AND C ARE NOT TOUCHED. The other 587 orphan offices belong to people who hold no real
-- seat -- former officeholders, losing candidates, and the 55 identity duplicates `CC_0102` moved
-- the finance links off. Retiring those is step 2b and is a different argument, because for them
-- the orphan office is the ONLY office on the record.
--
-- Idempotent: a re-run selects 0 and deletes 0.

BEGIN;

-- ─── Select, then assert, then delete ────────────────────────────────────────
-- 🔴 THE `EXISTS` CLAUSE IS THE WHOLE SAFETY PROPERTY. Without it this selects 671 offices and
-- unseats 587 people who have no other office at all.

CREATE TEMP TABLE in_class_a ON COMMIT DROP AS
SELECT o.id AS office_id, o.title AS orphan_title, p.id AS politician_id, p.full_name
FROM essentials.offices o
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE p.source = 'indiana_discovery'
  AND o.district_id IS NULL
  AND o.chamber_id IS NULL
  AND nullif(btrim(coalesce(o.representing_city, '')), '') IS NULL
  AND EXISTS (
    SELECT 1 FROM essentials.office_current_holder o2
     JOIN essentials.offices oo ON oo.id = o2.office_id
    WHERE o2.politician_id = p.id AND oo.district_id IS NOT NULL);

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_a int; v_broad int; v_races int; v_snap int; v_dated int; v_multi int; v_browse int;
BEGIN
  SELECT count(*) INTO v_a FROM in_class_a;
  IF v_a NOT IN (0, 84) THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: class A selects % offices, expected 84 (or 0 on a re-run)', v_a;
  END IF;
  IF v_a = 0 THEN RAISE NOTICE 'CC_0103: nothing to do, class A is already retired'; END IF;

  -- 🟢 THE CONTROL, KEPT IN THE MIGRATION. If the broad predicate ever equals the narrow one, the
  -- EXISTS clause has stopped discriminating and this migration must not run.
  SELECT count(*) INTO v_broad
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.source = 'indiana_discovery' AND o.district_id IS NULL;
  IF v_a > 0 AND v_broad <> 671 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: % orphan offices in total, expected 671 -- the cohort moved', v_broad;
  END IF;
  IF v_a > 0 AND v_broad = v_a THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: the class A restriction selects everything (% = %) -- it is not discriminating', v_a, v_broad;
  END IF;

  -- Nothing may reference these offices except their own placeholder term.
  SELECT count(*) INTO v_races FROM essentials.races r JOIN in_class_a a ON a.office_id = r.office_id;
  IF v_races <> 0 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: % race(s) reference a class A office -- races.office_id is ON DELETE NO ACTION and this would abort', v_races;
  END IF;

  SELECT count(*) INTO v_snap FROM essentials.politicians p JOIN in_class_a a ON a.office_id = p.office_id;
  IF v_snap <> 0 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: % legacy politicians.office_id snapshot(s) point at a class A office', v_snap;
  END IF;

  -- 🔴 A DATED TERM WOULD BE A REAL RECORD. These are all the undated phase-2 backfill; if one has
  -- acquired a date since, somebody researched it and it is no longer disposable.
  SELECT count(*) INTO v_dated FROM essentials.office_terms ot JOIN in_class_a a ON a.office_id = ot.office_id
   WHERE ot.term_start IS NOT NULL OR coalesce(ot.start_precision, 'unknown') <> 'unknown';
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: % class A term(s) carry a real date or precision -- stop and read them', v_dated;
  END IF;

  -- One orphan office per person, or the 1:1 reasoning above does not hold.
  SELECT count(*) INTO v_multi FROM (
    SELECT politician_id FROM in_class_a GROUP BY politician_id HAVING count(*) > 1) s;
  IF v_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: % person(s) hold more than one class A office', v_multi;
  END IF;

  SELECT count(*) INTO v_browse
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active = true AND o.representing_state = 'IN';
  IF v_a > 0 AND v_browse <> 665 THEN
    RAISE EXCEPTION 'CC_0103 pre-flight: Indiana browse count is %, expected 665 after CC_0101', v_browse;
  END IF;
END $$;

-- The 84 placeholder terms go with their offices: office_terms.office_id is ON DELETE CASCADE.
DELETE FROM essentials.offices o USING in_class_a a WHERE o.id = a.office_id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_left int; v_people int; v_active int; v_one int; v_orph int; v_freeman int;
        v_browse int; v_terms int;
BEGIN
  -- The 84 offices and their terms are gone.
  SELECT count(*) INTO v_left FROM essentials.offices o JOIN in_class_a a ON a.office_id = o.id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'CC_0103: % class A office(s) survive', v_left; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot JOIN in_class_a a ON a.office_id = ot.office_id;
  IF v_terms <> 0 THEN RAISE EXCEPTION 'CC_0103: % class A term(s) survive the cascade', v_terms; END IF;

  -- 🔴 EVERY ONE OF THE 84 PEOPLE IS STILL HERE, STILL ACTIVE, AND STILL SEATED.
  SELECT count(DISTINCT a.politician_id) INTO v_people
    FROM in_class_a a JOIN essentials.politicians p ON p.id = a.politician_id;
  IF v_people <> 84 THEN RAISE EXCEPTION 'CC_0103: % of 84 people survive -- this migration deletes nobody', v_people; END IF;

  SELECT count(*) INTO v_active FROM in_class_a a JOIN essentials.politicians p ON p.id = a.politician_id
   WHERE p.is_active AND p.is_incumbent;
  IF v_active <> 84 THEN RAISE EXCEPTION 'CC_0103: only % of 84 are still active and incumbent', v_active; END IF;

  -- ▶ THE POINT OF THE MIGRATION: each now holds EXACTLY ONE office.
  SELECT count(*) INTO v_one FROM (
    SELECT a.politician_id FROM in_class_a a
     JOIN essentials.office_current_holder och ON och.politician_id = a.politician_id
     GROUP BY a.politician_id HAVING count(*) <> 1) s;
  IF v_one <> 0 THEN
    RAISE EXCEPTION 'CC_0103: % of the 84 still hold more than one office -- the duplicate search row survives', v_one;
  END IF;

  -- Class B and C are untouched: 671 - 84 = 587.
  SELECT count(*) INTO v_orph
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.source = 'indiana_discovery' AND o.district_id IS NULL;
  IF v_orph <> 587 THEN RAISE EXCEPTION 'CC_0103: % orphan offices remain, expected 587', v_orph; END IF;

  -- 🟢 END-TO-END: the query shape the search endpoint actually uses, for the person it was
  -- verified broken on. Two rows before this migration; one after.
  SELECT count(*) INTO v_freeman
    FROM essentials.politicians p
    LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
    LEFT JOIN essentials.offices o ON o.id = och.office_id
   WHERE p.full_name = 'Aaron Freeman' AND p.is_incumbent = true
     AND coalesce(o.title, '') NOT ILIKE 'Candidate for%';
  IF v_freeman <> 1 THEN
    RAISE EXCEPTION 'CC_0103: the search query shape returns % rows for Aaron Freeman, expected 1', v_freeman;
  END IF;

  -- The browse count reaches the figure CC_0101 predicted for the end state.
  SELECT count(*) INTO v_browse
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active = true AND o.representing_state = 'IN';
  IF v_browse <> 581 THEN
    RAISE EXCEPTION 'CC_0103: Indiana browse count is %, expected 581 (1252 originally, 665 after CC_0101)', v_browse;
  END IF;

  RAISE NOTICE 'CC_0103 OK: 84 duplicate offices retired, 84 people kept and still seated once each, 587 orphans remain, Indiana browse 665 -> 581, Aaron Freeman returns 1 row';
END $$;

COMMIT;
