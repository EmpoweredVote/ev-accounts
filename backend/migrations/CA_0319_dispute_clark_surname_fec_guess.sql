-- CA_0319_dispute_clark_surname_fec_guess.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-10-21.
--
-- APPLIED: 2026-10-22 01:33 UTC on production, on yes from Chris Andrews. UPDATE 1; gate passed;
-- f8b6bc77 now reads disputed with the CA_0319 note. Dry run first on prod (COMMIT swapped for
-- ROLLBACK): UPDATE 1, gate OK, row unchanged after. Re-run after apply: UPDATE 0, gate OK (no-op).
-- ⚠ check:duplicate-people still reports this pair after apply: it counts any FEC link with an ID,
-- disputed included. The different_people verdict in data/duplicate-people-baseline.json (#1098)
-- is what quiets it.
--
-- =============================================================================
-- CA_0319: Lawrence Kyle Clark does not hold FEC H6CO06165 — dispute the
--          surname-only guess the auto-match queue wrote on his row
-- =============================================================================
--
-- WHAT WAS WRONG
--   politician_sources f8b6bc77-3965-4a03-9e73-d7de9507803e puts fec_house H6CO06165 on
--   ce8aef29-b9da-4e25-b7ea-d7a746de317b "Lawrence Kyle Clark" as needs_research, score 0.6. The
--   auto-match queue (src/lib/fecResearch.ts, strategy 3: surname exact, one candidate) wrote it
--   2026-10-21 06:03. The duplicate-people check has failed on every master push since, reading the
--   shared ID as one person on two rows (SHARED_FEC).
--
-- THE FINDING: DIFFERENT PEOPLE
--   FEC H6CO06165 is CLARK, JASON, Republican, Colorado District 06, first filed 2026-06-13
--   (api.open.fec.gov/v1/candidate/H6CO06165). d71c4160-9380-4788-88f1-4627b4abcb62 "Jason Clark" holds
--   it as confirmed and is on the CO 2026 general ballot for U.S. Representative District 6.
--   Lawrence Kyle Clark (created by CC_0276) is on the same ballot for District 7. FEC lists no Clark
--   for CO-07 (candidates search q=Clark, state=CO, office=H: only Jason Clark and a 1984 Betsy Mae Clark).
--   The pair is recorded as different_people in data/duplicate-people-baseline.json (PR #1098).
--
-- WHY DISPUTE, NOT DELETE
--   🔴 A DELETED ROW COMES BACK. The queue picks up any House candidate with no FEC row, or with a
--   needs_research row older than 7 days; it would search "Clark" in CO again, find the same single
--   surname match, and write the same guess. A row whose research_status is anything but
--   needs_research keeps the person out of the queue for good. 'disputed' is the shape CA_0230 used for
--   a wrong FEC ID on the wrong person: the row is kept, marked, and read by nothing that sums money
--   (finance reads confirmed rows only).
--   ⚠ The cost: if Lawrence Kyle Clark files with FEC later, the queue will not look for him. Add his
--   ID by hand then, and leave this row disputed.
--
-- Idempotent: the update is guarded on the row still being needs_research with this ID; a re-run
-- touches nothing and the gate still passes.
-- =============================================================================

BEGIN;

-- ── 0. Preconditions ─────────────────────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                 WHERE id = 'ce8aef29-b9da-4e25-b7ea-d7a746de317b' AND full_name = 'Lawrence Kyle Clark') THEN
    RAISE EXCEPTION 'CA_0319 precondition: Lawrence Kyle Clark row id/name mismatch';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources
                 WHERE id = 'f8b6bc77-3965-4a03-9e73-d7de9507803e'
                   AND essentials_politician_id = 'ce8aef29-b9da-4e25-b7ea-d7a746de317b'
                   AND source_system = 'fec_house' AND external_id = 'H6CO06165'
                   AND research_status IN ('needs_research', 'disputed')) THEN
    RAISE EXCEPTION 'CA_0319 precondition: source f8b6bc77 is not the H6CO06165 guess on Lawrence Kyle Clark';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources
                 WHERE essentials_politician_id = 'd71c4160-9380-4788-88f1-4627b4abcb62'
                   AND source_system = 'fec_house' AND external_id = 'H6CO06165'
                   AND research_status = 'confirmed') THEN
    RAISE EXCEPTION 'CA_0319 precondition: Jason Clark no longer holds H6CO06165 as confirmed';
  END IF;
END $$;

-- ── 1. Dispute the guess ─────────────────────────────────────────────────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET research_status = 'disputed',
       notes = COALESCE(notes, '') || ' | CA_0319 (2026-10-21): disputed — H6CO06165 is CLARK, JASON (CO-06, '
               || 'd71c4160). Lawrence Kyle Clark runs in CO-07 and has no FEC filing. Surname-only guess; '
               || 'kept so the auto-match queue does not write it again.',
       updated_at = now()
 WHERE id = 'f8b6bc77-3965-4a03-9e73-d7de9507803e'
   AND external_id = 'H6CO06165'
   AND research_status = 'needs_research';

-- ── 2. Gate ──────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = 'ce8aef29-b9da-4e25-b7ea-d7a746de317b'
     AND source_system LIKE 'fec%' AND research_status = 'needs_research';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: Lawrence Kyle Clark still has % needs_research FEC row(s)', v_n; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE id = 'f8b6bc77-3965-4a03-9e73-d7de9507803e' AND research_status = 'disputed'
     AND strpos(notes, 'CA_0319 (2026-10-21)') > 0;
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: f8b6bc77 is not disputed with the CA_0319 note'; END IF;

  SELECT count(*) INTO v_n FROM transparent_motivations.politician_sources
   WHERE external_id = 'H6CO06165' AND research_status = 'confirmed';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: H6CO06165 has % confirmed holder(s), expected 1 (Jason Clark)', v_n; END IF;
END $$;

COMMIT;

-- Rollback:
--   UPDATE transparent_motivations.politician_sources
--      SET research_status = 'needs_research',
--          notes = split_part(notes, ' | CA_0319 (2026-10-21)', 1)
--    WHERE id = 'f8b6bc77-3965-4a03-9e73-d7de9507803e' AND research_status = 'disputed';
