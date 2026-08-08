-- 1618: Newton block 3 -- the three "good prospect" rows from the 08-08 reachability pass.
--
-- 3 rows worked. **1 restored, 2 not.** Reading the full articles killed two of the three.
--
-- 🔴 MY OWN ASSESSMENT OVERSTATED THIS AND THE FULL READ CORRECTED IT. The 08-08 doc
-- (`2026-08-08-remaining-24-reachability.md`) called Leary, Block and Greenberg all "good prospect --
-- converging, first-person, on-topic" off sentence-level extracts. Two dissolve on inspection, both
-- for the SAME reason: **the councilor's stated reason is economic, not about housing density or
-- neighbourhood character.** A sentence can be on-topic by vocabulary and off-topic by rationale.
-- This is the third time in this cluster that a promising extract failed its full read.
--
-- 🔴 AND AN ATTRIBUTION ERROR I MADE AND CAUGHT. The 08-08 doc quotes Leary as wanting "some local
-- control of where duplexes should be in a single-family zone, where some neighborhoods' characters
-- could really change." **That is John LAWN, her opponent, not Leary** -- my sentence splitter glued
-- his quote onto her next sentence. Same family as the scope doc's "Grossman interview" that was
-- actually an interview with Brian Golden, and the Kalis/Albright group attribution refused in 1617.
-- It matters twice over: it is the exact defect class this whole workstream exists to clean up, and
-- removing it makes Leary's position *less* hedged, not more. A negative control asserting the string
-- "Lawn said. \"With single-family zoning" is present was run before writing this.
--
-- ===================================== RESTORED (1) =========================================
--
-- Allison Leary -- Residential Zoning 1 -> 4. Two 2026 Newton Beacon pieces (a solo profile and a
--   Chamber candidate forum -- she is a sitting councilor running for state representative).
--   "I do think we need to have more multifamily housing by-right in certain areas ... It was about
--   zoning for multi-families so they don't have to go through the Land Use Committee", would support
--   "even more density" in Newton's village centres, supported the VCOD and the MBTA Communities law,
--   backs state bills for statewide duplexes and by-right religious-organisation housing, and says
--   "if they're not doing it, I think the state needs to step in."
--   Chair 4 ("upzone broadly to allow multifamily by right; streamline approvals"): the streamlining
--   clause is nearly verbatim -- by-right so projects skip the Land Use Committee.
--   Not 3: chair 3 protects most residential zones, and she backs statewide duplex legalisation and
--   disagrees that duplexes change a neighbourhood's character. Not 5: she allows "rare exceptions"
--   for single-family-only zoning and frames by-right multifamily as "in certain areas", so
--   "any housing type on any lot communitywide" overshoots what she says.
--   ⚠ Chair 4's "reduce parking requirements" is NOT claimed -- she never says it.
--
-- ================================== NOT RESTORED (2) ========================================
--
-- Randy Block -- Residential Zoning. Looked like the strongest of the three: opposed the 148
--   California St rezoning, wanted "a much more thorough analysis by the Planning Department",
--   opposed 60 Brookside Avenue, wants two-year demolition delays and more aggressive landmarking.
--   It does not hold. **His stated rationale is the commercial tax base**, in his own words --
--   rezoning "opens up the possibility, even the likelihood, of residential development instead of
--   commercial development ... given our concern to protect our commercial tax base". He cites a 2023
--   Utile study recommending the corridor stay commercial-only. His preservation motive is likewise
--   explicit and historical ("That's the historian in me talking"), not about density.
--   ⚠ Two things actively cut against a restrictive chair: he **opposed the amendment to add parking
--   requirements** and was undecided on the zoning ordinance itself, and his 60 Brookside dissent is
--   recorded with **no stated reason at all** -- a bare tally, which 1617 already refused as evidence.
--   Chairs 1, 2 and 3 all fail: he never proposes community votes, never speaks to duplexes or ADUs,
--   and opposed exactly the commercial-corridor rezoning chair 3 describes.
-- Maria S. Greenberg -- Residential Zoning. The 08-08 doc rested this on "One size doesn't fit all if
--   you have unique neighborhoods with different needs." 🔴 **That quote is from a WINTER PARKING BAN
--   debate** -- she was asking for per-neighbourhood parking-pattern data. It is not about zoning at
--   all. Her genuine zoning remarks (backing the Mula rezoning and the MU4 project) are reasoned
--   entirely on commerce: foot traffic, the tax base, "attract other growing industries". Chairing
--   her on residential density from a commercial rationale is the Malakie/Newton-Crossing error that
--   1617 already refused in the mirror direction.
--
-- Both cited URLs fetched live (HTTP 200) and all 12 distinctive terms asserted present in raw HTML,
-- plus the Lawn attribution negative control, before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE (politician_id, topic_id) IN
     (('bc313a82-8b30-4ca7-acdb-47d2cc6906e3','d4f18138-a2e0-4110-b925-7387d9d0d16d'));
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

('bc313a82-8b30-4ca7-acdb-47d2cc6906e3', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Leary wants multi-family housing allowed by right rather than approved case by case, and wants the state to force the issue where communities will not. In a June 2026 profile she said "I do think we need to have more multifamily housing by-right in certain areas", explaining that the MBTA Communities law "was about zoning for multi-families so they don''t have to go through the Land Use Committee", and she would support even more density in Newton''s village centres. She supported Newton''s Village Center Overlay Districts, which brought the city into compliance with that law. At a July 2026 candidate forum she backed state bills that would allow duplexes to be built statewide and let faith-based organisations build housing by right, and said the state should intervene more to advance housing development: "every community should have opportunities for multifamily housing and more diverse housing options, and if they''re not doing it, I think the state needs to step in." She allows only rare exceptions for single-family-only zoning and disagrees that duplexes change a neighbourhood''s character. These are statements she made as a sitting Newton councilor while running for state representative.',
 ARRAY['https://www.newtonbeacon.org/alison-leary-talks-health-care-government-transparency-and-a-second-run-at-state-rep/',
       'https://www.newtonbeacon.org/lawn-leary-trade-barbs-over-housing-transparency-and-more-during-chamber-forum/']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('bc313a82-8b30-4ca7-acdb-47d2cc6906e3','d4f18138-a2e0-4110-b925-7387d9d0d16d',4);

DO $$
DECLARE v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int; v_closed int;
        v_nonascii int; v_frac int;
  added text[] := ARRAY['bc313a82-8b30-4ca7-acdb-47d2cc6906e3|d4f18138-a2e0-4110-b925-7387d9d0d16d'];
  -- examined this pass and deliberately refused; plus Leary's two other owed rows, untouched
  closed text[] := ARRAY[
    'a3bc0f3b-3cee-4c3a-bfea-5aa382a161eb|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    '3d68627c-c4cb-44f5-8b13-b48cd0edcd7a|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'bc313a82-8b30-4ca7-acdb-47d2cc6906e3|669cac97-66a6-4087-b036-936fbe62efb3',
    'bc313a82-8b30-4ca7-acdb-47d2cc6906e3|e9ebefcd-c496-45e8-b816-a79f8442ba85'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ctx <> 1 THEN RAISE EXCEPTION 'expected 1 context row, found %', v_ctx; END IF;
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ans <> 1 THEN RAISE EXCEPTION 'expected 1 answer row, found %', v_ans; END IF;

  SELECT count(*) INTO v_closed FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% deliberately-unrestored rows are present', v_closed; END IF;
  SELECT count(*) INTO v_closed FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% deliberately-unrestored answers are present', v_closed; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id::text||'|'||pc.topic_id::text = ANY(added) AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows', v_orphan; END IF;

  SELECT count(*) INTO v_empty FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND (sources IS NULL OR cardinality(sources)=0);
  IF v_empty <> 0 THEN RAISE EXCEPTION '% rows with empty sources', v_empty; END IF;

  SELECT count(*) INTO v_prose FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND reasoning ~ 'https?://';
  IF v_prose <> 0 THEN RAISE EXCEPTION '% rows embed a URL in reasoning', v_prose; END IF;

  SELECT count(*) INTO v_nonascii FROM inform.politician_context
   WHERE politician_id::text||'|'||topic_id::text = ANY(added) AND reasoning ~ '[^\x00-\x7F]';
  IF v_nonascii <> 0 THEN RAISE EXCEPTION '% rows contain non-ASCII reasoning', v_nonascii; END IF;

  SELECT count(*) INTO v_frac FROM inform.politician_answers
   WHERE politician_id::text||'|'||topic_id::text = ANY(added)
     AND (value <> round(value) OR value < 1 OR value > 5);
  IF v_frac <> 0 THEN RAISE EXCEPTION '% answers are fractional or out of range', v_frac; END IF;
END $$;

COMMIT;
