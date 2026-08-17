-- 1793_cal_access_restore_two_verified.sql
-- Restores the two links migration 1791 purged as "unprovable" that a FOURTH Cal-Access field
-- affirmatively proves are the politician's own.
--
-- Evidence: backend/data/cal-access-bucket-b/candidate-verification.json
-- Check:    backend/scripts/cal-access-bucket-b/08-verify-against-candidate.ts
--
-- 🔑 THE CANDIDATE CROSS-REFERENCE IS THE FIELD `confirm-cal-access.ts` SHOULD HAVE MATCHED ON:
--   /Campaign/Candidates/Detail.aspx?id=<committee filer id>  ->  "TAJ, ALI SAJJAD (ID# 1403290)"
-- It names the candidate behind a committee outright, with a stable candidate id, so identity needs
-- no name-shape reasoning at all. Every technique this project used -- last-token matching,
-- given-name tests, office corroboration, historical names -- was working around its absence.
--
--   filer 1403894  "TAJ FOR SENATE 2018 - SPECIAL"   -> candidate TAJ, ALI SAJJAD (#1403290)  = Ali Taj
--   filer 1439469  "GALLUCCI FOR GOVERNOR 2021"      -> candidate GALLUCCI, SAMUEL L. (#1435027) = Samuel Gallucci
--
-- Both were purged under the operator's prove-it-right posture because the committee name carries no
-- given name and names an office the politician does not hold. That posture was right in aggregate --
-- the same check affirmatively DISPROVED three others (BAILEY FOR JUDGE 2010 -> BAILEY, JULIAN;
-- BECERRA FOR GOVERNOR 2026 -> BECERRA, XAVIER; FUENTES FOR ASSEMBLY 2010 -> FUENTES, FELIPE) -- but
-- it was not free: $4,500 of $1,023,368.85 purged, a 0.44% error rate, now corrected.
--
-- ⚠ THE MONEY IS NOT RESTORED BY THIS MIGRATION. 1791 deleted the contributions and their
-- contribution_summary_agg rows; those are not recoverable from the database. Returning these links to
-- `confirmed` re-arms them for campaignFinanceScheduler, which gates on research_status='confirmed',
-- so the ~$4,500 returns on the next ingest rather than by DML here. Restoring them by hand would
-- fabricate rows, which is worse than a temporary absence.
--
-- ✅ The same check found ZERO contradicted KEEPS across all 161 surviving confirmed links: no
-- politician is displaying another person's money.
BEGIN;

CREATE TEMP TABLE restore_ids (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO restore_ids (sid) VALUES
  ('680028a6-a32b-42a1-9fcd-e361bd214ef1'),   -- Ali Taj
  ('bfeef88f-fc5f-4856-9edd-29a77a389d3f');   -- Samuel Gallucci

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM restore_ids;
  IF n <> 2 THEN RAISE EXCEPTION 'pre-check: restore set is %, expected 2', n; END IF;

  -- Both must be exactly what 1791 left behind: not_applicable, carrying 1791's note, no money.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN restore_ids r ON r.sid = ps.id
   WHERE ps.source_system = 'cal_access'
     AND ps.research_status = 'not_applicable'
     AND ps.notes LIKE '%WRONG PERSON (migration 1791%';
  IF n <> 2 THEN RAISE EXCEPTION 'pre-check: % of 2 are not 1791-purged cal_access links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g
   WHERE g.politician_source_id IN (SELECT sid FROM restore_ids);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % agg row(s) present; 1791 should have removed them', n; END IF;
END $$;

-- Snapshot so the guard can prove this migration moved no money of its own.
CREATE TEMP TABLE restore_money_before AS
SELECT round(coalesce(sum(a.total_amount),0)::numeric,2) AS d
  FROM transparent_motivations.contribution_summary_agg a
  JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
 WHERE ps.source_system = 'cal_access' AND p.is_active;

-- The 1791 WRONG PERSON note is deliberately LEFT IN PLACE and contradicted in the same field rather
-- than erased. The notes are the only provenance of how this tangle arose, and a note that quietly
-- disappears hides that the link was purged and restored.
UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'confirmed',
       notes = coalesce(ps.notes,'') || ' | RESTORED (migration 1793, 2026-08-16): the preceding'
               || ' WRONG PERSON note is WITHDRAWN. The Cal-Access candidate cross-reference'
               || ' (/Campaign/Candidates/Detail.aspx?id=<filer>) names this politician as the'
               || ' candidate behind the committee, which 1791 did not consult. Contributions deleted'
               || ' by 1791 are not restored here; this link is re-armed for re-ingest.'
               || ' See backend/data/cal-access-bucket-b/candidate-verification.json.',
       updated_at = now()
  FROM restore_ids r
 WHERE ps.id = r.sid;

DO $$
DECLARE n int; d0 numeric; d1 numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN restore_ids r ON r.sid = ps.id
   WHERE ps.research_status = 'confirmed' AND ps.notes LIKE '%RESTORED (migration 1793%';
  IF n <> 2 THEN RAISE EXCEPTION 'guard: % of 2 restored with a note', n; END IF;

  -- The withdrawal must be readable alongside what it withdraws.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN restore_ids r ON r.sid = ps.id
   WHERE ps.notes LIKE '%WRONG PERSON (migration 1791%';
  IF n <> 2 THEN RAISE EXCEPTION 'guard: the 1791 note was erased on % row(s); it must be kept and contradicted', 2 - n; END IF;

  -- Exactly two rows moved: nothing else that 1791 purged may have come back.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.notes LIKE '%WRONG PERSON (migration 1791%' AND ps.research_status <> 'not_applicable';
  IF n <> 2 THEN RAISE EXCEPTION 'guard: % 1791-purged link(s) are no longer not_applicable, expected exactly 2', n; END IF;

  SELECT d INTO d0 FROM restore_money_before;
  SELECT round(coalesce(sum(a.total_amount),0)::numeric,2) INTO d1
    FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.source_system = 'cal_access' AND p.is_active;
  IF d0 <> d1 THEN RAISE EXCEPTION 'guard: displayed cal_access money moved from % to %; this migration must not touch money', d0, d1; END IF;

  RAISE NOTICE 'cal_access 1793: 2 links restored to confirmed, money unchanged at % pending re-ingest', d1;
END $$;

DROP TABLE restore_money_before;

COMMIT;
