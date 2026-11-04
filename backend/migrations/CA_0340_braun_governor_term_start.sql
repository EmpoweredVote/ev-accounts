BEGIN;

-- =============================================================================
-- CA_0340: date Mike Braun's term as Indiana Governor (term_start 2025-01-13)
-- =============================================================================
-- Why: the LegiScan signing line (src/lib/legiscanEvidence.ts) ties "Signed by the Governor" on a bill's
-- history to a politician only through a DATED term as that state's governor covering the signing day.
-- All 46 governor terms were backfilled undated (migration 1459: term_start NULL, start_precision
-- 'unknown'), so none can pass. Braun is the first case: Indiana SEA 10 of 2025, "Signed by the Governor"
-- 2025-04-16 (Public Law 70), the follow-up held from the voting-rights Stage 5 batch in-01-held.
-- Chris Andrews, 2026-10-31: "Add Braun's start date".
--
-- Fact and source (read 2026-10-31):
--   * Indiana Constitution, Article 5, Section 9, official in.gov text
--     (https://www.in.gov/history/about-indiana-history-and-trivia/explore-indiana-history-by-topic/indiana-documents-leading-to-statehood/constitution-of-1851/article-5-executive/):
--     "The official term of the Governor and Lieutenant Governor shall commence on the second Monday of
--     January, in the year one thousand eight hundred and fifty-three; and on the same day every fourth year
--     thereafter." 2025 = 1853 + 4 x 43, and the second Monday of January 2025 is the 13th.
--   * Braun holds the office now (his open term row 986ecee5, the only Indiana Governor term) and won the
--     2024 general election, so his term began on that day.
--
-- Writes: term_start 2025-01-13, start_precision 'day', how_started 'elected' on term 986ecee5, and the
-- source appended. term_end stays NULL (he is serving). Nothing else changes.
-- Idempotent: a re-run matches the row already dated and changes nothing; the post-verify passes.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms t
      JOIN essentials.offices o ON o.id = t.office_id
      JOIN essentials.politicians p ON p.id = t.politician_id
     WHERE t.id = '986ecee5-e058-4da6-83e0-ff1b3d382b4e'
       AND p.id = 'a73e7a2a-48b0-4636-8fa4-5324ede65833' AND p.full_name = 'Mike Braun'
       AND o.role_canonical = 'governor' AND o.representing_state = 'IN'
       AND t.term_end IS NULL
       AND (t.term_start IS NULL OR t.term_start = DATE '2025-01-13')) THEN
    RAISE EXCEPTION 'CA_0340: pre-flight — Braun''s open Indiana Governor term 986ecee5 not found as expected';
  END IF;
  -- He is the only holder on the office: no other term to trim or overlap.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
     WHERE t.office_id = (SELECT office_id FROM essentials.office_terms WHERE id = '986ecee5-e058-4da6-83e0-ff1b3d382b4e')
       AND t.id <> '986ecee5-e058-4da6-83e0-ff1b3d382b4e') THEN
    RAISE EXCEPTION 'CA_0340: pre-flight — the Indiana Governor office has another term row; reconcile first';
  END IF;
END $$;

UPDATE essentials.office_terms
   SET term_start = DATE '2025-01-13',
       start_precision = 'day',
       how_started = 'elected',
       source = source || ' | term_start 2025-01-13: Indiana Constitution art. 5 sec. 9 (term commences the second Monday of January every fourth year from 1853), official text at https://www.in.gov/history/about-indiana-history-and-trivia/explore-indiana-history-by-topic/indiana-documents-leading-to-statehood/constitution-of-1851/article-5-executive/, read 2026-10-31 (CA_0340)'
 WHERE id = '986ecee5-e058-4da6-83e0-ff1b3d382b4e'
   AND term_start IS NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms
     WHERE id = '986ecee5-e058-4da6-83e0-ff1b3d382b4e'
       AND term_start = DATE '2025-01-13' AND start_precision = 'day' AND term_end IS NULL
       AND source LIKE '%(CA_0340)%') THEN
    RAISE EXCEPTION 'CA_0340: post-verify — term 986ecee5 is not dated 2025-01-13';
  END IF;
END $$;

COMMIT;
