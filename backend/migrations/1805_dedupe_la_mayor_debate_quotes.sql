-- 1805_dedupe_la_mayor_debate_quotes.sql
--
-- Follow-up to 1566. Sourcing the 30 orphaned LA Mayor quotes to the 2026-05-06 NBC4/Telemundo
-- debate revealed that four of them duplicate other rows from the SAME moment of the SAME debate:
-- three against quotes that were already sourced, and one against another orphan filed under a
-- different question. A voter could meet the same sentence twice in one race.
--
-- Keep exactly one row per moment, choosing on content rather than on which row is older:
--
--   residential-zoning / Bass   KEEP 5c090c4e  DROP 71044f3e
--     Not strict duplicates — two sentences from one answer. The keeper opens "We need absolutely
--     more housing built, BUT SB 79...", carrying the tension (wants housing, opposes the state
--     mandate); the dropped row opens with flat opposition and its blind text rewrote "I don't
--     support" into "[The candidate] doesn't support" rather than marking a cut.
--
--   homelessness / Bass         KEEP dd5bdce9  DROP 5230bec6
--     The keeper is the dropped row PLUS its opening line, "Everybody needs to go inside."
--     Without that, Bass states only what she opposes and carries no forward position. The
--     dropped row's editor_note is merged onto the keeper below, so no curation work is lost.
--
--   homelessness / Raman        KEEP 27f705ef  DROP 7d2e49cd
--     The keeper carries a third sentence the orphan drops — "You don't get an opportunity to
--     say no" — which is the mechanism that distinguishes her from Bass on this question.
--
--   growth-and-development /    KEEP 9ea38e55  DROP 84f56b9d
--   residential-zoning / Raman
--     84f56b9d is a strict substring of 9ea38e55, filed under a different question. Raman keeps
--     a stronger residential-zoning answer (d8f9bf5d, an exact 106-word match), so nothing is lost.
--
-- All four dropped rows are drafts (readrank_selected = false), so nothing user-visible changes.
-- None is referenced by essentials.readrank_questions.origin_quote_id.
--
-- Evidence: on-the-record docs/audits/2026-08-07-la-mayor-orphan-quote-provenance.md

BEGIN;

-- Guard 1: all four must still exist, and must still be drafts. If a human selected one live
-- since this was written, abort rather than delete something a voter may be seeing.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM essentials.quotes
     WHERE id IN ('71044f3e-380e-4887-9169-95fbd7926f08',
                  '5230bec6-c7ad-4639-82c2-cdbec290fc02',
                  '7d2e49cd-81bc-411b-bef6-498552588a1e',
                  '84f56b9d-ca40-4268-b02a-81d4ac116ce0')
       AND readrank_selected = false;
    IF n <> 4 THEN
        RAISE EXCEPTION 'Aborting: expected 4 draft rows to drop, found %. One may have gone live.', n;
    END IF;
END $$;

-- Guard 2: every keeper must still exist, so a delete can never leave the moment unrepresented.
DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n FROM essentials.quotes
     WHERE id IN ('5c090c4e-4c6e-45c5-a7f3-85ea7213f0e3',
                  'dd5bdce9-667c-4891-955a-98ec6c49d44e',
                  '27f705ef-08a4-459f-b107-2602b4f1a0a5',
                  '9ea38e55-6e78-4ec1-b41c-eb74fa6a5217');
    IF n <> 4 THEN
        RAISE EXCEPTION 'Aborting: expected 4 surviving rows, found %.', n;
    END IF;
END $$;

-- Merge the dropped row's rationale onto the keeper before deleting it. Adapted for the fuller
-- quote: the keeper leads with the affirmative position, which the original note did not cover.
UPDATE essentials.quotes SET
    editor_note = 'This is Bass''s direct answer on whether camping should be enforced with '
                  'citations or arrests: she opens by affirming everyone should come indoors, '
                  'then rejects arrest as the means, matching a decriminalize-while-investing-'
                  'in-shelter approach. Verbatim, no edits.'
  WHERE id = 'dd5bdce9-667c-4891-955a-98ec6c49d44e';

DELETE FROM essentials.quotes
 WHERE id IN ('71044f3e-380e-4887-9169-95fbd7926f08',
              '5230bec6-c7ad-4639-82c2-cdbec290fc02',
              '7d2e49cd-81bc-411b-bef6-498552588a1e',
              '84f56b9d-ca40-4268-b02a-81d4ac116ce0');

COMMIT;
