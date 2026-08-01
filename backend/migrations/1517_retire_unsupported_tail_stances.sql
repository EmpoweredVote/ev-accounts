-- 1517_retire_unsupported_tail_stances.sql
--
-- Retire 5 published stance answers for which NO SOURCE SUPPORTS THE CHAIR. Per the backlog's standing
-- rule, where no source supports a chair the answer is NO STANCE -- not a weaker one, and not an
-- inference from the person's party, caucus or general record.
--   Rollback record: data/stance-retirement/2026-08-01-tail-corrections-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--   Review:          data/stance-retirement/2026-08-01-tail-hand-review.md
--
-- 🔴 THESE ARE NOT CITATION FAILURES AND MUST NOT BE RECORDED AS SUCH. Three of the five say so in
-- their own reasoning -- "No direct legislation or on-record statements ... were found", "No specific
-- legislation authored by Mitchell ... was identified", "No specific campaign finance reform bill she
-- authored was identified" -- and then assign a chair anyway from LGBTQ+ advocacy, a civil-rights
-- record, or being "a progressive Democrat". The citation did not fail; there was never a citation.
--
-- The other two were found by reading the cited page:
--
--   Holly J. Mitchell / Redistricting -- the row credits her with backing California's independent
--     commission via Prop 11 and Prop 20. The page's ONLY mention of redistricting is that "she was
--     displaced from her current district by redistricting" in 2012. That is election history, not a
--     position. Presence of the word is not support for the claim.
--
--   Brinker Harding / Taxes -- the row says his site "pledges to fight to cut taxes as part of a
--     platform to grow the economy and eliminate wasteful spending". The page pledges to "fight to
--     grow our economy and eliminate wasteful spending to increase revenues and reduce our deficit".
--     There is no tax-cut pledge: "cut taxes", "lower taxes", "tax relief", "reduce taxes" and
--     "tax cut" are ALL absent from the page. "Cut taxes" was inserted into someone else's sentence,
--     and the stance value 4 -- "Cut taxes for everyone and scale back public services" -- rests
--     entirely on the inserted words.
--
-- All five are published and voter-facing; reasoning renders under "Why this position?".

BEGIN;

CREATE TEMP TABLE _retire_1517 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1517 (politician_id, topic_id) VALUES
  ('5cdd28b7-f8be-4968-bc1a-0e7928786980', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Isaac Bryan: Religious Freedom
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Holly J. Mitchell: Religious Freedom
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50', '92730f69-ae57-401c-8ad1-2d07834a895d'),  -- Holly J. Mitchell: Campaign Finance
  ('fc5fda5f-f5bb-49bd-b7b3-b56eeaa6bb50', '48cc9585-ec22-4f53-8d42-6839828dd36f'),  -- Holly J. Mitchell: Redistricting
  ('2f063464-29d8-42a4-bba3-d521ceb53555', 'f7e5678d-dadd-4556-a2fc-446e24642ceb')  -- Brinker Harding: Taxes
;

DELETE FROM inform.politician_context c USING _retire_1517 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1517 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1517 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1517 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;
END $$;

COMMIT;
