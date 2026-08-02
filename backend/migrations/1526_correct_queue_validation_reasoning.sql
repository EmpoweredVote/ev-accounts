-- 1526_correct_queue_validation_reasoning.sql
--
-- Correct the REASONING of 2 published rows found by working the calibrated reading queue. Nothing is
-- retired and no stance value changes -- only the text a voter reads.
--   Rollback record: data/stance-retirement/2026-08-01-queue-remedies-rollback.json
--   Review:          data/stance-retirement/2026-08-01-queue-validation.md
--
-- Same principle as 1516/1518/1524: inform.politician_context.reasoning is VOTER-FACING (Citations.jsx
-- renders it under "Why this position?"). Both replacement strings were verified verbatim on the live
-- page on 2026-08-01 with scripts/read-site.mjs against raw HTML.

BEGIN;

-- Maria Lou Calanche / Transportation Priorities — 🔴 THE ROW SAID THERE WAS NO SOURCE, AND IT WAS
-- WRONG. The old reasoning read: "Detailed transportation positions were not publicly available, but
-- her focus on working families and community development suggests transit-supportive values."
-- Her issues page carries "Free community transit and shuttles to connect communities" and "Street
-- and sidewalk repair to ensure walkability". Chair 2 ("invest equally in roads and multimodal
-- options") is BETTER supported than the row claimed, not worse -- this is a row that undersold its
-- own evidence, which is the opposite failure from the rest of this workstream and worth noting.
UPDATE inform.politician_context SET reasoning = 'Calanche''s issues page commits to "Free community transit and shuttles to connect communities" alongside "Street and sidewalk repair to ensure walkability" and "Safe parks and green spaces for community to enjoy". Backing free community transit while also funding street and sidewalk repair is investment in roads and multimodal options together.'
 WHERE politician_id = '13eea214-867a-4a66-ae1a-c0f9916ac833' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';

-- Ericka Kopp / Fossil Fuels — the chair stands; the reasoning must rest on the page, not on "implies".
-- Old text: "Green New Deal endorsement implies stopping new fossil fuel permits". The words fossil,
-- drilling, permit, oil and gas do not appear anywhere on the site. What IS there, verbatim, is the
-- Green New Deal endorsement and a clean-energy plank -- and a Green New Deal endorsement is
-- definitionally a fossil-fuel phase-out commitment, so chair 2 survives on substance. Kept rather
-- than retired for exactly that reason: unlike the 1522 retirements, the inference here stays inside
-- the topic instead of crossing from one domain into another.
UPDATE inform.politician_context SET reasoning = 'Kopp''s campaign site lists "Endorsing a Green New Deal" and "Prioritizing clean energy initiatives, including solar and wind energy" among her priorities. A Green New Deal commitment is a programme of transition off fossil fuels, which entails halting new drilling permits. The site does not use the words drilling, permits or fossil fuels, and states no position on existing production.'
 WHERE politician_id = '372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id = '13eea214-867a-4a66-ae1a-c0f9916ac833'
          AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'
          AND reasoning ILIKE '%not publicly available%')
      OR (politician_id = '372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a'
          AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'
          AND reasoning ILIKE '%endorsement implies%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% row(s) still carry the old unsourced reasoning', v_n; END IF;

  -- Neither stance value may move in this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id = '13eea214-867a-4a66-ae1a-c0f9916ac833' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27' AND value = 2.0)
      OR (politician_id = '372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570' AND value = 2.0);
  IF v_n <> 2 THEN RAISE EXCEPTION 'expected 2 rows at their original chairs, found %', v_n; END IF;
END $$;

COMMIT;
