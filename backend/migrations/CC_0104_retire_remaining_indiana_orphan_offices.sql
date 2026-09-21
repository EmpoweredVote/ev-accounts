-- CC_0104_retire_remaining_indiana_orphan_offices.sql
-- Indiana debt 1, STEP 2b — the last of it. Slot RESERVED from the allocator.
--
-- Deletes the remaining 587 `indiana_discovery` orphan offices (classes B and C) and their 587
-- placeholder terms, which cascade. Deletes NO people. Touches NO flags. Moves NO finance links.
--
-- After this, `indiana_discovery` holds ZERO placeholder occupancies and Indiana's share of the
-- 77,001 the database carried is closed. The 672 people all remain.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THIS IS THE HARDER HALF, AND THE REASON IS WORTH STATING PLAINLY.
--
-- Class A (CC_0103) was easy: the holder already held the real version of the same seat, so the
-- row was a duplicate of a better row. **These 587 people hold no other office at all.** Deleting
-- their office leaves them in the database with none. That is the disposition, and it is right,
-- because the row is FALSE for every one of them:
--
--   * for a former officeholder -- Pence, Holcomb, Connie Lawson, Rebecca Skillman, Jon Ford --
--     it asserts the office in the PRESENT TENSE. It carries no start date and no end date, so it
--     does not record that they once held it. It says they hold it now. They do not.
--   * for a losing candidate -- and the cohort is full of them -- it is simply wrong.
--
-- ▶ **THE TITLE RECORDS THE OFFICE SOUGHT, NOT ONE HELD.** The diagnostic is `Governor`, which
-- held TEN people: three real governors across three decades, and seven who only ran.
--
-- ⚠ **NOTHING IN THE ROW TELLS THE TWO APART, AND THAT IS MEASURED, NOT ASSUMED.**
-- `total_years_in_office` null on all of them, `bio_text` null on all but three, `valid_from` null
-- throughout, every term from the phase-2 backfill with `precision 'unknown'`. There is no field
-- to sort a former governor from a failed candidate — which is exactly why the same disposition
-- is correct for both: the row is unreachable, undated, and untrue either way.
--
-- 🟢 **WHAT SURVIVES, AND IT IS THE PART WORTH KEEPING.** The FK on
-- `transparent_motivations.politician_sources` is to the PERSON, not the office, so:
--
--     587 people ................................ all kept, deactivated by CC_0101
--     536 candidate-committee sources ........... all kept, still on their people
--      79 researched stance answers .............. all kept, across 7 people
--
-- Those seven include Jon Ford (11 answers), the former District 38 senator who now heads the
-- Office of Energy Development. If any of them is seated properly by a later roster wave, their
-- research and their finance record come with them. **Deleting the office loses no research.**
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🟢 THE CONTROL, AND IT CHANGED SHAPE SINCE CC_0103. That migration's safety clause was "the
-- holder ALSO holds a real seat", which selected 84 of 671. After it ran, every remaining orphan
-- is held by an INACTIVE person: measured 587 inactive, **0 active**. So the pre-flight asserts
-- both halves — 587 to take, and 0 orphan office whose holder is still active. If an active
-- person ever appears in this set again, a class A row has come back and this must not run.
--
-- Idempotent: a re-run selects 0 and deletes 0.

BEGIN;

CREATE TEMP TABLE in_orphan_rest ON COMMIT DROP AS
SELECT o.id AS office_id, o.title AS orphan_title, p.id AS politician_id, p.full_name
FROM essentials.offices o
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE p.source = 'indiana_discovery'
  AND o.district_id IS NULL
  AND o.chamber_id IS NULL
  AND nullif(btrim(coalesce(o.representing_city, '')), '') IS NULL;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_n int; v_active int; v_dual int; v_races int; v_snap int;
        v_dated int; v_multi int; v_src int; v_ans int;
BEGIN
  SELECT count(*) INTO v_n FROM in_orphan_rest;
  IF v_n NOT IN (0, 587) THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % orphan offices, expected 587 (or 0 on a re-run)', v_n;
  END IF;
  IF v_n = 0 THEN RAISE NOTICE 'CC_0104: nothing to do, the orphan offices are already retired'; END IF;

  -- 🔴 THE CONTROL. Every remaining orphan must be held by a DEACTIVATED person. An active holder
  -- means a class A duplicate has reappeared, and deleting its office would unseat nobody but
  -- would also mean CC_0103's reasoning no longer describes the data.
  SELECT count(*) INTO v_active FROM in_orphan_rest a
    JOIN essentials.politicians p ON p.id = a.politician_id WHERE p.is_active OR p.is_incumbent;
  IF v_active <> 0 THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % orphan office(s) are held by an ACTIVE person -- expected 0 after CC_0101/CC_0103', v_active;
  END IF;

  -- And none may hold a real seat: class A is gone, and this migration is not allowed to do its job.
  SELECT count(*) INTO v_dual FROM in_orphan_rest a
   WHERE EXISTS (SELECT 1 FROM essentials.office_current_holder och2
                  JOIN essentials.offices oo ON oo.id = och2.office_id
                 WHERE och2.politician_id = a.politician_id AND oo.district_id IS NOT NULL);
  IF v_dual <> 0 THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % holder(s) also hold a real seat -- that is class A, and CC_0103 owns it', v_dual;
  END IF;

  SELECT count(*) INTO v_races FROM essentials.races r JOIN in_orphan_rest a ON a.office_id = r.office_id;
  IF v_races <> 0 THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % race(s) reference an orphan office -- races.office_id is ON DELETE NO ACTION', v_races;
  END IF;

  SELECT count(*) INTO v_snap FROM essentials.politicians p JOIN in_orphan_rest a ON a.office_id = p.office_id;
  IF v_snap <> 0 THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % legacy politicians.office_id snapshot(s) point at an orphan office', v_snap;
  END IF;

  -- 🔴 A DATED TERM IS A REAL RECORD. All 587 are the undated phase-2 backfill; one with a date
  -- means somebody researched it since, and it is no longer disposable.
  SELECT count(*) INTO v_dated FROM essentials.office_terms ot JOIN in_orphan_rest a ON a.office_id = ot.office_id
   WHERE ot.term_start IS NOT NULL OR ot.term_end IS NOT NULL
      OR coalesce(ot.start_precision, 'unknown') <> 'unknown';
  IF v_dated <> 0 THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % term(s) carry a date -- stop and read them before deleting anything', v_dated;
  END IF;

  SELECT count(*) INTO v_multi FROM (
    SELECT politician_id FROM in_orphan_rest GROUP BY politician_id HAVING count(*) > 1) s;
  IF v_multi <> 0 THEN RAISE EXCEPTION 'CC_0104 pre-flight: % person(s) hold more than one orphan office', v_multi; END IF;

  -- Recorded so the post-verify can prove they were NOT collateral damage.
  SELECT count(*) INTO v_src FROM transparent_motivations.politician_sources s
    JOIN in_orphan_rest a ON a.politician_id = s.essentials_politician_id;
  SELECT count(*) INTO v_ans FROM inform.politician_answers ans
    JOIN in_orphan_rest a ON a.politician_id = ans.politician_id;
  IF v_n > 0 AND (v_src <> 536 OR v_ans <> 79) THEN
    RAISE EXCEPTION 'CC_0104 pre-flight: % committee source(s) and % stance answer(s) on these people, expected 536 and 79', v_src, v_ans;
  END IF;
END $$;

CREATE TEMP TABLE in_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.politicians WHERE source = 'indiana_discovery') AS people,
       (SELECT count(*) FROM transparent_motivations.politician_sources) AS sources,
       (SELECT count(*) FROM inform.politician_answers) AS answers;

DELETE FROM essentials.offices o USING in_orphan_rest a WHERE o.id = a.office_id;

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_left int; v_terms int; v_people int; v_orph int; v_src int; v_ans int;
        v_placeholder int; v_browse int; v_missing int;
BEGIN
  SELECT count(*) INTO v_left FROM essentials.offices o JOIN in_orphan_rest a ON a.office_id = o.id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'CC_0104: % orphan office(s) survive', v_left; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot JOIN in_orphan_rest a ON a.office_id = ot.office_id;
  IF v_terms <> 0 THEN RAISE EXCEPTION 'CC_0104: % term(s) survive the cascade', v_terms; END IF;

  -- 🔴 NOBODY WAS DELETED. All 672 indiana_discovery people are still here.
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE source = 'indiana_discovery';
  IF v_people <> (SELECT people FROM in_before) THEN
    RAISE EXCEPTION 'CC_0104: % indiana_discovery people, was % -- this migration deletes nobody',
      v_people, (SELECT people FROM in_before);
  END IF;

  -- 🟢 THE RESEARCH AND THE FINANCE RECORD ARE UNTOUCHED, table-wide, not just for this cohort.
  SELECT count(*) INTO v_src FROM transparent_motivations.politician_sources;
  IF v_src <> (SELECT sources FROM in_before) THEN
    RAISE EXCEPTION 'CC_0104: politician_sources went from % to % -- deleting an office must not touch the person''s finance record',
      (SELECT sources FROM in_before), v_src;
  END IF;

  SELECT count(*) INTO v_ans FROM inform.politician_answers;
  IF v_ans <> (SELECT answers FROM in_before) THEN
    RAISE EXCEPTION 'CC_0104: politician_answers went from % to % -- 79 researched answers sit on these people and must survive',
      (SELECT answers FROM in_before), v_ans;
  END IF;

  -- Indiana's orphan cohort is closed.
  SELECT count(*) INTO v_orph
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.source = 'indiana_discovery' AND o.district_id IS NULL;
  IF v_orph <> 0 THEN RAISE EXCEPTION 'CC_0104: % orphan office(s) remain, expected 0', v_orph; END IF;

  SELECT count(*) INTO v_placeholder FROM essentials.politician_occupancy_evidence
   WHERE is_placeholder_occupancy AND politician_source = 'indiana_discovery';
  IF v_placeholder <> 0 THEN
    RAISE EXCEPTION 'CC_0104: % indiana_discovery placeholder occupancy(ies) remain, expected 0', v_placeholder;
  END IF;

  -- Unchanged, and asserted so: these holders were already inactive, so they were never counted.
  SELECT count(*) INTO v_browse
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active = true AND o.representing_state = 'IN';
  IF v_browse <> 581 THEN RAISE EXCEPTION 'CC_0104: Indiana browse count moved to %, expected 581', v_browse; END IF;

  -- These offices carried terms, so the missing-terms view never listed them.
  SELECT count(*) INTO v_missing FROM essentials.offices_missing_terms WHERE NOT is_vacant;
  IF v_missing <> 655 THEN
    RAISE EXCEPTION 'CC_0104: offices_missing_terms unflagged is %, expected 655 unchanged', v_missing;
  END IF;

  RAISE NOTICE 'CC_0104 OK: 587 orphan offices retired, 0 remain; 672 people, 536 committee sources and 79 stance answers all kept; Indiana browse still 581';
END $$;

COMMIT;
