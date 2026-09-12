-- CC_0101_deactivate_indiana_discovery_orphans.sql
-- Indiana debt 1, STEP 1 OF 2. Slot RESERVED from the allocator.
--
-- Sets is_active = false and is_incumbent = false on the 587 `indiana_discovery` people whose ONLY
-- occupancy is a placeholder office. Deletes NOTHING. Creates NOTHING.
--
-- Ruling (Cantrell, 2026-09-12): flags first, retirement second. This migration is the reversible
-- half; the orphan offices themselves come out in a later migration once this has sat.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE READ PATHS ARE NOT BROKEN. THESE 587 ROWS CARRY THE WRONG FLAGS.
--
-- Production holds 77,001 placeholder occupancies. They split by the script that made them:
--
--     cal_access_discovery   76,330 rows    0 is_active    0 is_incumbent
--     indiana_discovery         671 rows  671 is_active  671 is_incumbent
--
-- Every politician-rooted read path guards on `p.is_active` and/or `p.is_incumbent`, so
-- California's 76,330 pass through harmlessly. Indiana's leak, and they leak because
-- `scripts/discover-indiana-candidates.ts:407-408` inserts `is_active=true, is_incumbent=true`
-- where the CalAccess script inserts false. ▶ THE FIX IS TO MATCH CALACCESS, NOT TO ADD A FILTER
-- TO FIVE QUERIES, AND CERTAINLY NOT TO DELETE 587 PEOPLE.
--
-- What leaks today, measured 2026-09-11, not inferred:
--   * `GET /api/essentials/politicians?q=` returns TWO rows for a person holding two offices.
--     Verified: "Aaron Freeman" returns 2. ⚠ The comment above that join in
--     `essentialsService.ts:517-519` says "One row per office, so this cannot fan out" -- true
--     joining FROM offices, false joining FROM politicians, which is what that query does.
--   * `getPoliticianById` reads `o.title` off `rows[0]` of an unordered join, so a profile can
--     render "Governor" for someone who is not the governor. The cohort holds TEN "Governor"
--     rows -- Pence, Holcomb and Braun, who are three different real governors, plus seven people
--     who only ran. The title records the office SOUGHT, not one held.
--   * Indiana's browse-page officeholder count reads 1,252. The true figure is 581. 54% inflated,
--     and Indiana is the only state affected, for the flag reason above.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE 84 DUAL-HOLDERS MUST NOT BE TOUCHED, AND THIS IS THE ONLY WAY THIS MIGRATION CAN DO HARM.
--
-- `is_active` and `is_incumbent` live on the PERSON, not on the office. 84 of the 671 hold a real
-- seat from IN-2 as well as an orphan duplicate of it (Aaron Freeman: real Senator + orphan
-- "State Senator"). Flipping their flags would deactivate 84 SITTING LEGISLATORS.
--
-- So the predicate is "placeholder occupancy AND holds no office with a district", and the gate
-- asserts all 84 are still active and still incumbent afterwards. 🟢 A CONTROL WAS WATCHED FIRING,
-- in a rolled-back transaction on prod: dropping the NOT EXISTS clause selects 671 rows instead of
-- 587, and the first person it would deactivate is AARON FREEMAN, a sitting Indiana state senator.
--
-- ⚠ WHAT THIS COSTS. `campaignFinanceSearchService` filters `p.is_active = true`, so these 587
-- leave campaign-finance search. That was ruled acceptable: it makes Indiana consistent with the
-- 76,330 CalAccess candidate-committee rows, which are already excluded the same way.
--
-- ⚠ IDENTITY IS DELIBERATELY NOT DECIDED HERE. Roughly 66 of the 587 look like a second row for
-- someone already seated in Indiana (Michael Braun / Mike Braun). That set is BOTH dirty and
-- incomplete: it pairs Frank Mrvan SENIOR with his SON the congressman, and it misses Elizabeth
-- Brown / Liz Brown because E and L differ on the first initial. No merge is performed. The list
-- is a research backlog, recorded in the debt file, to be worked with sources rather than a regex.
--
-- Idempotent: the UPDATE is guarded and re-runs as `UPDATE 0`. Ends with a post-verify gate.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────

DO $$
DECLARE v_orphan int; v_dual int; v_ca_active int;
BEGIN
  SELECT count(*) INTO v_orphan FROM (
    SELECT DISTINCT e.politician_id FROM essentials.politician_occupancy_evidence e
     WHERE e.is_placeholder_occupancy AND e.politician_source = 'indiana_discovery'
       AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder och2
                        JOIN essentials.offices o2 ON o2.id = och2.office_id
                       WHERE och2.politician_id = e.politician_id AND o2.district_id IS NOT NULL)) s;
  IF v_orphan <> 587 THEN
    RAISE EXCEPTION 'debt-1 pre-flight: % orphan-only indiana_discovery people, expected 587. The cohort moved -- re-measure before flipping anything.', v_orphan;
  END IF;

  SELECT count(*) INTO v_dual FROM (
    SELECT DISTINCT e.politician_id FROM essentials.politician_occupancy_evidence e
     WHERE e.is_placeholder_occupancy AND e.politician_source = 'indiana_discovery'
       AND EXISTS (SELECT 1 FROM essentials.office_current_holder och2
                    JOIN essentials.offices o2 ON o2.id = och2.office_id
                   WHERE och2.politician_id = e.politician_id AND o2.district_id IS NOT NULL)) s;
  IF v_dual <> 84 THEN
    RAISE EXCEPTION 'debt-1 pre-flight: % dual-holders, expected 84. These are sitting legislators and the migration refuses to run when their count is not what it was measured at.', v_dual;
  END IF;

  -- The comparison cohort. If CalAccess has started setting these flags true, the premise of this
  -- migration -- "match what CalAccess already does" -- is no longer true and somebody must look.
  SELECT count(*) INTO v_ca_active FROM essentials.politician_occupancy_evidence e
    JOIN essentials.politicians p ON p.id = e.politician_id
   WHERE e.is_placeholder_occupancy AND e.politician_source = 'cal_access_discovery'
     AND (p.is_active OR p.is_incumbent);
  IF v_ca_active <> 0 THEN
    RAISE EXCEPTION 'debt-1 pre-flight: % cal_access_discovery placeholder(s) are now active/incumbent, expected 0. The convention this migration copies has changed.', v_ca_active;
  END IF;
END $$;

-- ─── The flip ────────────────────────────────────────────────────────────────
-- 🔴 THE `NOT EXISTS` IS THE WHOLE SAFETY PROPERTY. Without it this selects 671 and deactivates
-- 84 sitting legislators.

CREATE TEMP TABLE in_orphan_only ON COMMIT DROP AS
SELECT DISTINCT e.politician_id AS id
FROM essentials.politician_occupancy_evidence e
WHERE e.is_placeholder_occupancy
  AND e.politician_source = 'indiana_discovery'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.office_current_holder och2
     JOIN essentials.offices o2 ON o2.id = och2.office_id
    WHERE och2.politician_id = e.politician_id AND o2.district_id IS NOT NULL);

UPDATE essentials.politicians p
   SET is_active = false, is_incumbent = false
  FROM in_orphan_only j
 WHERE p.id = j.id
   AND (p.is_active OR p.is_incumbent);

-- ─── Post-verify gate ────────────────────────────────────────────────────────

DO $$
DECLARE v_still int; v_dual_ok int; v_browse int; v_ca int; v_people int; v_offices int;
BEGIN
  -- 1. No orphan-only indiana_discovery person is still active or incumbent.
  SELECT count(*) INTO v_still
    FROM in_orphan_only j JOIN essentials.politicians p ON p.id = j.id
   WHERE p.is_active OR p.is_incumbent;
  IF v_still <> 0 THEN RAISE EXCEPTION 'debt-1: % orphan-only person(s) still flagged active/incumbent', v_still; END IF;

  -- 2. 🔴 ALL 84 DUAL-HOLDERS ARE UNTOUCHED. This is the assertion that matters.
  SELECT count(*) INTO v_dual_ok FROM (
    SELECT DISTINCT e.politician_id FROM essentials.politician_occupancy_evidence e
     WHERE e.is_placeholder_occupancy AND e.politician_source = 'indiana_discovery'
       AND EXISTS (SELECT 1 FROM essentials.office_current_holder och2
                    JOIN essentials.offices o2 ON o2.id = och2.office_id
                   WHERE och2.politician_id = e.politician_id AND o2.district_id IS NOT NULL)) s
    JOIN essentials.politicians p ON p.id = s.politician_id
   WHERE p.is_active AND p.is_incumbent;
  IF v_dual_ok <> 84 THEN
    RAISE EXCEPTION 'debt-1: only % of 84 dual-holders are still active AND incumbent -- a sitting legislator has been deactivated', v_dual_ok;
  END IF;

  -- 3. Nothing was deleted. The people and their placeholder offices are all still here.
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE source = 'indiana_discovery';
  IF v_people <> 672 THEN RAISE EXCEPTION 'debt-1: % indiana_discovery people, expected 672 -- this migration deletes nobody', v_people; END IF;

  SELECT count(*) INTO v_offices FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.source = 'indiana_discovery' AND o.district_id IS NULL;
  IF v_offices <> 671 THEN RAISE EXCEPTION 'debt-1: % orphan offices, expected 671 -- step 1 retires none of them', v_offices; END IF;

  -- 4. The browse-page count for Indiana. 🔴 THIS GATE CAUGHT ITS OWN AUTHOR: the first version
  -- asserted 581, the end-state figure, and the dry run returned 665. Step 1 removes the 587
  -- orphan-ONLY people; the 84 dual-holders stay active by design, so their orphan offices stay in
  -- this count. 1252 - 587 = 665. The remaining 84 come out in step 2 when the offices are
  -- retired: 665 - 84 = 581. ▶ THE RESIDUAL 84 IS THE MEASURE OF WHAT STEP 2 IS FOR.
  SELECT count(*) INTO v_browse
    FROM essentials.offices o
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE p.is_active = true AND o.representing_state = 'IN';
  IF v_browse <> 665 THEN
    RAISE EXCEPTION 'debt-1: Indiana browse count is %, expected 665 after step 1 (was 1252; 581 is the figure after step 2 retires the 671 orphan offices)', v_browse;
  END IF;

  -- 5. CalAccess is untouched -- this migration is scoped to indiana_discovery.
  SELECT count(*) INTO v_ca FROM essentials.politician_occupancy_evidence e
    JOIN essentials.politicians p ON p.id = e.politician_id
   WHERE e.is_placeholder_occupancy AND e.politician_source = 'cal_access_discovery'
     AND (p.is_active OR p.is_incumbent);
  IF v_ca <> 0 THEN RAISE EXCEPTION 'debt-1: cal_access_discovery now has % active placeholder(s)', v_ca; END IF;

  RAISE NOTICE 'debt-1 step 1 OK: 587 orphan-only people deactivated, 84 dual-holders untouched, 0 rows deleted, Indiana browse count 1252 -> 665 (581 after step 2)';
END $$;

COMMIT;
