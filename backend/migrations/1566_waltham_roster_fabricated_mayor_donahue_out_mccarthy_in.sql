-- 1566_waltham_roster_fabricated_mayor_donahue_out_mccarthy_in.sql
--
-- Unseat "Arthur Donahue" from the Waltham Mayor office and seat the real mayor,
-- Jeannette A. McCarthy. Arthur Donahue is not a stale officeholder — he is a
-- FABRICATED PERSON, and this is the first one this audit has found.
--
--   Record:   data/stance-retirement/2026-08-06-waltham-fabricated-mayor.md
--   Rollback: same file, "ROLLBACK" section — every value replaced is recorded verbatim.
--   Follows:  1564 (retired Donahue's single stance row as a fabricated citation)
--   Pattern:  1546 (Beverly Hills roster fix — same shape, unseat + seat replacement)
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1566_waltham_roster_fabricated_mayor_donahue_out_mccarthy_in.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 A NEW DEFECT CLASS: THE OFFICEHOLDER ITSELF WAS INVENTED
-- ---------------------------------------------------------------------------------------------------
-- Every finding in this workstream so far has been a fabricated SOURCE — an invented outlet, a composed
-- path, an article that never existed. The subject of the row was always a real person. Not here.
--
-- Migration 1564 retired Donahue's one and only stance row. Its reasoning read:
--
--     "Mayor Donahue led Waltham's compliance effort with the MBTA Communities Act in 2024,
--      submitting a zoning amendment plan to create a multi-family overl[ay]..."
--
-- cited to `walthampatch.com/posts/waltham-mbta-communities-zoning-compliance-2024` — a host already
-- sitting on the dead-cited-hosts queue (2026-08-04-dead-host-findings.md). So the same generation pass
-- that invented the citation also invented the man it was about, and seeded him into the Mayor seat.
--
-- 🔑 THE GENERALISABLE POINT: retiring a fabricated citation does NOT necessarily repair the row's
-- subject. A politician who exists only because a fabricated source said so survives every sweep this
-- workstream has built, because all of them evaluate CITATIONS against pages, never SUBJECTS against
-- rosters. Donahue was found only because the re-research queue checks the roster first (the 1546 rule).
--
-- ---------------------------------------------------------------------------------------------------
-- EVIDENCE — fetched and read, not recalled
-- ---------------------------------------------------------------------------------------------------
--   * <https://www.city.waltham.ma.us/1714/Mayors-Office> — the Mayor's Office staff table lists exactly
--     one name: "Jeannette A. McCarthy | Mayor | 781-314-3100". "Donahue" appears zero times.
--   * <https://www.city.waltham.ma.us/1715/About-Mayor-Jeannette-A-McCarthy> — the city's own biography
--     page: "Mayor Jeannette A. McCarthy is a lifelong resident of Waltham... became Mayor of Waltham
--     in 2004."
--   * <https://www.city.waltham.ma.us/1341/City-Council> — all 15 councillors enumerated (6 at-large,
--     9 ward). "Donahue" occurs ZERO times in the raw HTML. The other 15 seats in our database match
--     this page name for name, so the roster is otherwise correct and current.
--   * Web search for "Arthur Donahue" + Waltham returns census records, obituaries and unrelated
--     Donahues — no officeholder, no candidate, no coverage.
--
-- ⚠ The city migrated from Drupal to CivicPlus, so the older `/city-council/pages/...` and
-- `/sites/g/files/...` URLs now 404. That 404 is a platform migration, NOT absence — the live pages are
-- the numeric CivicPlus paths above. Classified before being read as evidence (rule #2).
--
-- ⚠ Negative control: all 55 negatively-seeded Mayor rows nationally were listed and eyeballed. Donahue
-- is the only unrecognisable name. The one other that looked wrong — Brockton's "Moises M. Rodrigues" —
-- was checked and is CORRECT (elected Nov 2025, sworn in 2026-01-05). Sixteenth time a first-cut
-- suspicion over-fired; see the standing note in detector_first_cut_overfires.
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT THIS DOES, AND WHY NOT A HARD DELETE
-- ---------------------------------------------------------------------------------------------------
-- Operator ruling 2026-08-06: unseat and DEACTIVATE, do not hard-delete. The politician row is retained
-- with is_active = false / is_incumbent = false so the evidence that a fabricated person reached
-- production survives for audit. He holds zero compass answers and zero context rows (1564 took the
-- one row he had), so deactivating orphans nothing — asserted below rather than assumed.
--
-- McCarthy is seated with NULL term_start / term_end, matching all 16 other Waltham office_terms. She
-- was re-elected in Nov 2023 to a four-year term, but no primary source for the exact swearing-in date
-- was fetched, and this workstream does not assert dates it has not read. NULL term_end + is_incumbent
-- = seated under the two-gate occupancy model.
--
-- ---------------------------------------------------------------------------------------------------
-- BLAST RADIUS
-- ---------------------------------------------------------------------------------------------------
--   * Zero stance rows touched. Donahue has none; McCarthy starts with none.
--   * Waltham's `hasContext` chip is already false (flipped by 1564) — unaffected either way.
--   * The Waltham re-research worklist drops from 5 emptied politicians to 4. Donahue's owed topic is
--     void, not pending: you cannot re-research a person who does not exist.
--
-- ===================================================================================================

BEGIN;

-- --- PRE-CONDITIONS -------------------------------------------------------------------------------

-- The fabricated person is exactly who we think he is, and is seated where we think he is.
DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt
  FROM essentials.politicians p
  WHERE p.id = '3eab65f7-083a-49c6-9944-1a20a5373538'
    AND p.full_name = 'Arthur Donahue'
    AND p.external_id = -2572600001;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'PRE: Arthur Donahue politician row not as expected (found %)', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt
  FROM essentials.office_terms ot
  WHERE ot.id = '327a6e08-9721-4f9a-bc06-653fecdb25a0'
    AND ot.office_id = '34f1b48f-5689-4828-94b0-f7cb5b5abc1b'
    AND ot.politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'PRE: Donahue office_term not as expected (found %)', v_cnt;
  END IF;
END $$;

-- Deactivating him orphans nothing. If this ever fires, STOP — a fabricated person acquired
-- voter-facing stance rows since 1564 and they need retiring before he can be unseated.
DO $$
DECLARE v_ans int; v_ctx int;
BEGIN
  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  IF v_ans <> 0 OR v_ctx <> 0 THEN
    RAISE EXCEPTION 'PRE: Donahue holds stance data (answers=%, context=%) — retire it first', v_ans, v_ctx;
  END IF;
END $$;

-- The Waltham Mayor office is singular, and the external_id we are about to mint is free.
DO $$
DECLARE v_cnt int;
BEGIN
  SELECT count(*) INTO v_cnt
  FROM essentials.offices o
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2572600' AND o.title = 'Mayor';
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'PRE: expected exactly 1 Waltham Mayor office, found %', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians WHERE external_id = -2572600017;
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'PRE: external_id -2572600017 already taken (found %)', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE full_name ILIKE '%Jeannette%McCarthy%';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'PRE: a Jeannette McCarthy already exists (found %) — seat her, do not duplicate', v_cnt;
  END IF;
END $$;

-- --- CHANGES --------------------------------------------------------------------------------------

-- 1. Unseat the fabricated mayor.
DELETE FROM essentials.office_terms
 WHERE id = '327a6e08-9721-4f9a-bc06-653fecdb25a0';

-- 2. Deactivate him. Row retained deliberately: it is the evidence.
UPDATE essentials.politicians
   SET is_active = false,
       is_incumbent = false,
       notes = COALESCE(notes, ARRAY[]::text[]) || ARRAY[
               'FABRICATED PERSON — not a Waltham officeholder. Seeded 2026-06-15 into the Waltham '
               || 'Mayor seat by the same pass that invented the walthampatch.com citation retired by '
               || 'migration 1564. Verified absent from the city''s own Mayor''s Office, About-Mayor and '
               || 'City Council pages 2026-08-06. Unseated by migration 1566; row retained for audit.']
 WHERE id = '3eab65f7-083a-49c6-9944-1a20a5373538';

-- 3. Create the real mayor.
INSERT INTO essentials.politicians
       (full_name, first_name, middle_initial, last_name, external_id, is_incumbent, is_active, is_vacant)
VALUES ('Jeannette A. McCarthy', 'Jeannette', 'A', 'McCarthy', -2572600017, true, true, false);

-- 4. Seat her in the office Donahue vacated. NULL term dates match all 16 other Waltham office_terms.
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, source)
SELECT '34f1b48f-5689-4828-94b0-f7cb5b5abc1b',
       p.id,
       NULL,
       NULL,
       'migration 1566 — city.waltham.ma.us/1714/Mayors-Office and /1715/About-Mayor-Jeannette-A-McCarthy, read 2026-08-06'
  FROM essentials.politicians p
 WHERE p.external_id = -2572600017;

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int; v_name text;
BEGIN
  -- Exactly one person seated as Waltham Mayor, and it is McCarthy.
  SELECT count(*), min(p.full_name) INTO v_cnt, v_name
  FROM essentials.office_terms ot
  JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE ot.office_id = '34f1b48f-5689-4828-94b0-f7cb5b5abc1b';
  IF v_cnt <> 1 OR v_name <> 'Jeannette A. McCarthy' THEN
    RAISE EXCEPTION 'POST: Waltham Mayor seat is % occupant(s), name=%', v_cnt, v_name;
  END IF;

  -- Donahue holds no office anywhere and is deactivated.
  SELECT count(*) INTO v_cnt FROM essentials.office_terms
   WHERE politician_id = '3eab65f7-083a-49c6-9944-1a20a5373538';
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'POST: Donahue still holds % office_term(s)', v_cnt;
  END IF;

  SELECT count(*) INTO v_cnt FROM essentials.politicians
   WHERE id = '3eab65f7-083a-49c6-9944-1a20a5373538'
     AND is_active = false AND is_incumbent = false;
  IF v_cnt <> 1 THEN
    RAISE EXCEPTION 'POST: Donahue not deactivated';
  END IF;

  -- Waltham's roster is now 16 seats: 15 councillors + 1 mayor, each singly occupied.
  SELECT count(*) INTO v_cnt
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.chambers ch ON ch.id = o.chamber_id
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '2572600';
  IF v_cnt <> 16 THEN
    RAISE EXCEPTION 'POST: expected 16 Waltham office_terms, found %', v_cnt;
  END IF;

  -- No stance data was created or destroyed.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id IN ('3eab65f7-083a-49c6-9944-1a20a5373538',
                           (SELECT id FROM essentials.politicians WHERE external_id = -2572600017));
  IF v_cnt <> 0 THEN
    RAISE EXCEPTION 'POST: unexpected stance answers (%)', v_cnt;
  END IF;
END $$;

COMMIT;
