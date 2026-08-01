-- 1521_retire_inferred_stances.sql
--
-- Retire 2 more published stance answers whose cited site carries NO CONTENT ON THE TOPIC, so the
-- chair rested entirely on inference. Same rule and same operator decision as 1520: an absent topic
-- is NO STANCE, retired until it can be re-sourced.
--   Rollback record: data/stance-retirement/2026-08-01-inferred-stance-retirements-rollback.json
--                    (the ONLY surviving copy of these rows' reasoning and sources)
--   Review:          data/stance-retirement/2026-08-01-not-found-hand-review.md
--
-- 🔴 "VERIFIED ABSENT", NOT "UNSURE". These two were held back from 1520 precisely because they read
-- as thin rather than empty, and the standing rule is that doubt resolves toward KEEPING a row -- on
-- this workstream, doubtful rows have turned out fine far more often than not. They are retired here
-- because measurement, not intuition, showed the topic is simply not on the page. Both were checked
-- against RAW HTML across every page of the site, after the <main> extractor fix.
--
--   Carlton E. Bowen / Taxes (bowenforcongress.com, 4 pages) -- the word "taxes" occurs ZERO times,
--     in the extracted text and in the raw HTML alike; so do "cut taxes", "lower taxes", "tax relief",
--     "tax cut", "reduce taxes", "flat tax", "income tax" and "tax rate". The site is about the
--     national debt and spending discipline. The row carried chair 4, "Cut taxes for everyone and
--     scale back public services", and its own reasoning conceded "he does not state an explicit
--     tax-rate number or plan". Spending discipline is not a tax position.
--     This is the SAME SHAPE AS 1517's Brinker Harding retirement, where a tax-cut pledge had been
--     inserted into a sentence about eliminating wasteful spending.
--     ⚠ 1518 corrected this row's fabricated quotations; retiring it now supersedes that correction.
--     That is the right order -- the quote fix was true regardless, and could not rescue a chair the
--     source never supported.
--
--   Scott Schwab / Religious Freedom (scottschwab.com, 4 pages) -- no occurrence of religion, church,
--     conscience, exemption, liberty, worship or prayer anywhere. "Religious" appears once, in privacy
--     boilerplate ("we do not use or disclose ... your religious beliefs"). The only faith content is
--     one biographical line: "As a Christian, my faith has guided me at home and in my work as
--     Secretary of State." The row inferred chair 4 -- allowing faith-based exemptions from laws that
--     conflict with sincere religious belief -- from that sentence.
--     🔴 PRESENCE IS NOT SUPPORT. A statement of personal faith is biography; the topic asks whether
--     religious belief should exempt people from generally applicable laws, and the site is silent on
--     it. Same error as crediting Travis Nelson with a Medicaid-expansion vote because his page
--     contains the word "Medicaid".
--
-- ⚠ BOWEN DROPS TO ZERO ANSWERS -- this was his ONLY stance. That is the correct outcome, not a
-- reason to keep an unsupported row: a profile with no compass is honest, one with a fabricated
-- chair is not. His last_stances_researched_at is already NULL, so he is recorded as UNRESEARCHED
-- and resurfaces in the research queue on his own. (Migration 1494 set the precedent: politicians
-- emptied by a retirement had their timestamp cleared for exactly this reason, and a NULL timestamp
-- with zero answers is "nobody has looked yet" -- distinct from a SET timestamp with zero answers,
-- which is how an honest "we looked and found nothing" is recorded and must never be erased.)
-- Schwab keeps 8 of his 9 answers. Both topics are OWED RE-RESEARCH.

BEGIN;

CREATE TEMP TABLE _retire_1521 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1521 (politician_id, topic_id) VALUES
  ('e752a957-c776-4942-9aae-63ebf23174ac', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),  -- Scott Schwab: Religious Freedom
  ('6eccd92f-958a-4ee5-8eb6-f9ca48e41af2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb')  -- Carlton E. Bowen: Taxes
;

DELETE FROM inform.politician_context c USING _retire_1521 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1521 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

DO $$
DECLARE
  v_left int;
  v_ctx  int;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1521 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1521 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- Schwab keeps the rest of his compass; only the one unsupported topic goes.
  SELECT count(*) INTO v_left FROM inform.politician_answers
   WHERE politician_id = 'e752a957-c776-4942-9aae-63ebf23174ac' AND value <> 0;
  IF v_left < 1 THEN RAISE EXCEPTION 'Schwab left with no answers'; END IF;

  -- Bowen is emptied deliberately, and MUST be left as unresearched rather than as an honest zero.
  SELECT count(*) INTO v_left FROM essentials.politicians
   WHERE id = '6eccd92f-958a-4ee5-8eb6-f9ca48e41af2' AND last_stances_researched_at IS NOT NULL;
  IF v_left <> 0 THEN
    RAISE EXCEPTION 'Bowen has 0 answers but a research timestamp -- that reads as "we looked and found nothing"';
  END IF;
END $$;

COMMIT;
