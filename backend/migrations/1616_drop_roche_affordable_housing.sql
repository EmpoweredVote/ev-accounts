-- 1616: Drop Sean Roche's Affordable Housing row added by migration 1615.
--
-- Operator ruling. 1615 flagged this row as the most arguable call in that migration and it is the
-- one being reversed: it rested on the SAME interview passage as Roche's Residential Zoning row —
-- "We have the unique capacity to solve that [housing] problem ourselves … Newton has the building
-- types that the zoning is designed to allow" — used once for a zoning chair and again for an
-- affordability chair.
--
-- 1615's defence was that chair 4 on the Affordable Housing scale ("cut regulations and zoning rules
-- so private developers can build more housing") IS the zoning answer, so the scale itself invites
-- it. The operator has ruled the other way, and the stricter rule is the better one:
-- 🔑 **ONE PASSAGE, ONE CHAIR.** A single statement establishes the position it is actually about.
-- Re-using it across topics is the Mejia error in a milder form — a defensible-looking chair resting
-- on evidence that was really about something else. This is the same discipline that kept Portland's
-- 2025-175 out of the Homelessness topic in mig 1614.
--
-- Roche keeps Residential Zoning (chair 3) and Transportation Priorities (chair 1), both from the
-- same interview but each on its own distinct passage. He does NOT fall to zero answers, so
-- `last_stances_researched_at` is untouched (rule 1494: null it only for people emptied to zero).
--
-- Newton's Affordable Housing coverage returns to zero restored rows — Silber's and Irish's were
-- already deliberately not restored in 1615 for want of any affordability position.
--
-- Deleted from BOTH tables so no orphan context row survives.
-- Restore value if ever reversed: chair 4, source
-- https://www.figcitynews.com/2025/10/interview-sean-roche-at-large-candidate-for-city-council-ward-6/
-- (full prior reasoning is in the mig 1615 INSERT).

BEGIN;

DO $$
DECLARE v_ctx int; v_ans int;
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
  IF v_ctx <> 1 OR v_ans <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 context and 1 answer row to drop, found % / %', v_ctx, v_ans;
  END IF;
END $$;

DELETE FROM inform.politician_answers
 WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
   AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

DELETE FROM inform.politician_context
 WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
   AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

DO $$
DECLARE v_gone int; v_keeps int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gone FROM inform.politician_context
   WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
  IF v_gone <> 0 THEN RAISE EXCEPTION 'context row survived'; END IF;
  SELECT count(*) INTO v_gone FROM inform.politician_answers
   WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100'
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';
  IF v_gone <> 0 THEN RAISE EXCEPTION 'answer row survived'; END IF;

  -- his other two rows are untouched and still paired
  SELECT count(*) INTO v_keeps FROM inform.politician_context
   WHERE politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100';
  IF v_keeps <> 2 THEN RAISE EXCEPTION 'Roche should keep exactly 2 rows, found %', v_keeps; END IF;

  SELECT count(*) INTO v_orphan FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa ON pa.politician_id=pc.politician_id AND pa.topic_id=pc.topic_id
   WHERE pc.politician_id = 'e9abe848-ca92-4197-924d-294e7ed92100' AND pa.politician_id IS NULL;
  IF v_orphan <> 0 THEN RAISE EXCEPTION '% orphan rows for Roche', v_orphan; END IF;
END $$;

COMMIT;
