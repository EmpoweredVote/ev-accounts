-- ═══════════════════════════════════════════════════════════════════════════════════════════════
-- TEMPLATE — paste into any migration that CREATES offices, CREATES districts, or changes
-- chambers.official_count. Not a migration. Nothing here runs on its own; `_templates/` is
-- skipped by the numbering check.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════
--
-- 🔴 WHY THIS EXISTS. `npm run check:body-completeness` reads PRODUCTION data, so it runs on master
-- pushes and the nightly schedule, never on a PR. That means it CANNOT VET THE MERGE THAT TRIPS IT:
-- it fails on the NEXT push and names an innocent author. CLAUDE.md states the general rule —
-- carry the check into the migration's own post-verify, as a DELTA, if you need it to block the
-- guilty change. This is that delta, for the two conditions that gate watches.
--
-- 🔴 GATE ON THE DELTA, NOT ON A TOTAL. Several sessions write into this database at once. The
-- totals move under you between the moment you measure and the moment you apply — `CC_0295`
-- measured 297/58/239 and `CC_0296`, hours later, measured 296/57/239 before writing anything,
-- because another session had resolved a seat in between. Neither migration caused it and neither
-- was wrong. A migration that asserts a TOTAL fails for reasons that have nothing to do with it.
-- Capture the before-count inside your own transaction and assert the CHANGE.
--
-- ⚠ CREATING AN OFFICE IS AN OCCUPANCY ACT. An office with no `office_terms` row is invisible: no
-- holder, so the official never appears in Essentials, stance research, coverage or campaign
-- finance — and nothing errors. The first guard below is what makes that loud. It is the same
-- reason `CC_0429` did NOT create Lewiston's ninth school committee seat: naming its holder needed
-- a roster the committee publishes only as an image, and an unseated office raises the drift
-- baseline.
--
-- ⚠ CREATING A DISTRICT IS ALSO ONE, ONE LEVEL UP. A district with no office is invisible to every
-- existing gate — `DEAD_GEOGRAPHY` requires offices > 0, `offices_missing_terms` starts FROM
-- offices, so the drift baseline cannot move. That is how all sixteen Maine counties sat empty
-- without anything noticing (ROSTERS.md R9k).
--
-- ── HOW TO USE ─────────────────────────────────────────────────────────────────────────────────
-- 1. Capture the counts at the TOP of your migration, inside the same transaction as the writes.
-- 2. Paste the matching DO blocks after your writes, before COMMIT.
-- 3. Delete the guards that do not apply to your migration. Do not leave a vacuous one in — a gate
--    scoped to a population it never touches compares 0 against 0 and passes while proving
--    nothing. `CC_0409` shipped exactly that.
-- ═══════════════════════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ── STEP 1: capture the before-state, in this transaction ──────────────────────────────────────
CREATE TEMP TABLE _bc_before ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM essentials.offices)                                   AS offices,
  (SELECT count(*) FROM essentials.districts d
     WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id))
                                                                              AS officeless_districts,
  (SELECT count(*) FROM essentials.offices o
     WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
                                                                              AS termless_offices;


--   ... your migration's own writes go here ...


-- ── GUARD A: every office this migration created is SEATED ─────────────────────────────────────
-- Keep only if your migration creates offices. Change the expected number to yours.
DO $$
DECLARE
  v_new_offices   int;
  v_new_termless  int;
  v_expected      int := 0;   -- ← how many offices this migration creates
BEGIN
  SELECT (SELECT count(*) FROM essentials.offices) - b.offices,
         (SELECT count(*) FROM essentials.offices o
            WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id))
           - b.termless_offices
    INTO v_new_offices, v_new_termless
    FROM _bc_before b;

  IF v_new_offices <> v_expected THEN
    RAISE EXCEPTION 'created % offices, expected %', v_new_offices, v_expected;
  END IF;

  -- The one that matters: an unseated office is invisible AND raises the drift baseline.
  IF v_new_termless <> 0 THEN
    RAISE EXCEPTION
      '% of the offices this migration created carry no office_terms row. An office with no term '
      'has no holder, never appears anywhere, and nothing errors. Seat them or do not create them.',
      v_new_termless;
  END IF;
END $$;


-- ── GUARD B: this migration left no district empty ─────────────────────────────────────────────
-- Keep only if your migration creates districts, or creates offices that were meant to fill one.
-- Note the direction: seeding a tier should make this number FALL. It must never RISE.
DO $$
DECLARE
  v_delta int;
BEGIN
  SELECT (SELECT count(*) FROM essentials.districts d
            WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id))
         - b.officeless_districts
    INTO v_delta
    FROM _bc_before b;

  IF v_delta > 0 THEN
    RAISE EXCEPTION
      'this migration left % more district(s) holding no office. A district with no office is '
      'invisible to every other gate in this repo — DEAD_GEOGRAPHY needs offices > 0 and '
      'offices_missing_terms starts FROM offices — so nothing downstream will catch it.',
      v_delta;
  END IF;
END $$;


-- ── GUARD C: the chamber still holds the number of seats it claims ─────────────────────────────
-- Keep if your migration touches a chamber's offices or its official_count. Substitute the
-- chamber id. `official_count = 0` means "unset", so this guard refuses to run against one
-- rather than reading the zero as a size.
DO $$
DECLARE
  v_stated  int;
  v_offices int;
  v_people  int;
  v_chamber uuid := '00000000-0000-0000-0000-000000000000';  -- ← your chamber
BEGIN
  SELECT ch.official_count,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id),
         (SELECT count(DISTINCT t.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms t ON t.office_id = o.id
           WHERE o.chamber_id = ch.id AND t.politician_id IS NOT NULL)
    INTO v_stated, v_offices, v_people
    FROM essentials.chambers ch WHERE ch.id = v_chamber;

  IF v_stated IS NULL OR v_stated = 0 THEN
    RAISE EXCEPTION
      'chamber % states no size (NULL or the 0 sentinel), so this guard would compare against '
      'nothing. Set official_count from the body''s OWN charter or roster first — never from the '
      'row count it is meant to check. South Portland''s 8 agreed with our 8 rows and with no '
      'source, and it confirmed the defect instead of catching it.', v_chamber;
  END IF;

  IF v_offices <> v_stated THEN
    RAISE EXCEPTION 'chamber % states % seats and holds % offices', v_chamber, v_stated, v_offices;
  END IF;

  -- 🔴 ASK HOW MANY DISTINCT PEOPLE HOLD THE BODY'S OFFICES, NOT HOW MANY OFFICES ARE FILLED.
  -- Bangor (9 offices / 9 people) wanted a retitle; South Portland (8 offices / 7 people) wanted a
  -- delete. Both read "every seat occupied" and both agreed with their own chamber row.
  IF v_people <> v_offices THEN
    RAISE EXCEPTION
      'chamber % holds % offices but only % distinct people. One person holds two seats on this '
      'body — which is South Portland''s signature, where the mayor row and District 5 were the '
      'same woman. Read the charter before deciding whether to retitle or delete.',
      v_chamber, v_offices, v_people;
  END IF;
END $$;

COMMIT;
