-- 1520_retire_absent_topic_stances.sql
--
-- Retire 3 published stance answers whose ONLY cited source does not discuss the topic at all.
-- Per the backlog's standing rule: where no source supports a chair, the answer is NO STANCE --
-- not a weaker chair, and not an inference from party or general record.
--   Rollback record: data/stance-retirement/2026-08-01-absent-topic-retirements-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--   Review:          data/stance-retirement/2026-08-01-not-found-hand-review.md
--
-- 🔴 EVERY ONE WAS RE-VERIFIED AFTER THE <main> EXTRACTOR BUG WAS FIXED, AND AGAINST RAW HTML.
-- These three were first read with the extractor that silently dropped everything outside <main> --
-- the same fault that nearly retired four correctly-sourced rows for Faye Johnson hours earlier. They
-- were therefore re-checked page by page, searching the RAW HTML rather than the extracted text, so
-- that no site-builder markup could hide a plank.
--
--   Clyde Welford (clydewelford.com) -- ALL 11 pages of the site fetched and grepped.
--     abortion / reproduct / "right to choose" / pro-choice / climate / renewable / solar:
--     ZERO occurrences anywhere in the raw HTML. His site lists six priorities -- Health Care,
--     Education, Economy, Veterans, foreign policy, Data Centers -- and neither topic is among them.
--     The rows assert he lists "Women's reproductive rights" and "support combating climate change"
--     as platform planks. No such planks exist.
--
--   Shannon Taylor (shannontaylorva.com) -- 4 pages. The word "tariff" does not occur once. The row
--     quotes her on "the reckless tariffs and endless wars that are driving up the price of groceries,
--     gas, and everyday goods"; her page says "Fight against inflationary policies that are driving up
--     the cost of groceries, gas, and utilities". A tariffs claim was spliced into a real sentence.
--     The site's only "trade" hits are Rob Wittman trading STOCKS; its only "import" hits are the word
--     "important".
--
-- Neither politician drops to zero answers (Welford 5 -> 3, Taylor 8 -> 7), so both keep a populated
-- profile. Both topics are OWED RE-RESEARCH against a real source.

BEGIN;

CREATE TEMP TABLE _retire_1520 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1520 (politician_id, topic_id) VALUES
  ('4782f3f1-c940-47ad-a3ab-a753b8cd719a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'),  -- Clyde Welford: Abortion
  ('4782f3f1-c940-47ad-a3ab-a753b8cd719a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Clyde Welford: Climate Change
  ('4b3850c4-debb-4b92-a796-3cf15cf31e80', '683c8084-2281-4920-a07c-18439b2dd413')  -- Shannon Taylor: Tariffs
;

DELETE FROM inform.politician_context c USING _retire_1520 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1520 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1520 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1520 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- Neither politician may be emptied by this migration.
  SELECT count(*) INTO v_left FROM inform.politician_answers
   WHERE politician_id = '4782f3f1-c940-47ad-a3ab-a753b8cd719a' AND value <> 0;
  IF v_left < 1 THEN RAISE EXCEPTION 'Welford left with no answers'; END IF;

  SELECT count(*) INTO v_left FROM inform.politician_answers
   WHERE politician_id = '4b3850c4-debb-4b92-a796-3cf15cf31e80' AND value <> 0;
  IF v_left < 1 THEN RAISE EXCEPTION 'Taylor left with no answers'; END IF;
END $$;

COMMIT;
