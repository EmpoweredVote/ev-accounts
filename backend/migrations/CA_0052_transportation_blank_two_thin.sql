BEGIN;

-- =============================================================================
-- CA_0052: Transportation Priorities — blank 2 unevidenced chair-2 rows
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: the last 2 thin transportation chair-2 rows (Al Rios, Jordan Rivers) came
--   back with no qualifying primary source after a re-source pass (CA_0050 left them
--   at 2 as still-thin). Decision 2026-08-30 (Chris Andrews): blank them. Each was
--   seated at chair 2 with no evidence describing chair 2 (or any chair) on the
--   roads-vs-transit spectrum. Removing the seat is the honest disposition.
--
--   Both were value=2. The seating is DELETED (there is no value=0 sentinel yet —
--   the answer CHECK is 1..5 — so a blank is the absence of a row). All answers are
--   Season 1, so this removes them from the open season too; a wrong/unevidenced
--   chair is wrong in the open season as well.
--
-- CONTEXT DISPOSITION: rewritten-as-blank (NOT deleted). The transportation topic
--   genuinely applies to both (a sitting city Vice Mayor and a City Council
--   candidate) and each record WAS read against primary sources on 2026-08-30, so
--   each context is rewritten as a documented blank naming what was checked and why
--   it fails to place a chair — per the answer-delete context-guard template. The
--   "Researched 2026-08-30" prefix is earned by an actual reading, not used to
--   exempt an unread row.
--
-- 🔴 The CI answer-delete guard (check:answer-delete-guards) matches only ^(\d+)_
--   filenames, so it SKIPS CA_ files. The ORPHAN_CONTEXT guard below is pasted from
--   backend/migrations/_templates/answer_delete_context_guard.sql (regexes
--   character-identical to check-stance-sources.mjs), and check-stance-sources.mjs
--   is run by hand after apply.
--
-- Expected end state (transportation-priorities answers): 1=115, 2=158, 3=110,
--   4=58, 5=3 (was 115/160/110/58/3 after CA_0051); 2 answer rows removed.
-- Idempotent: DELETE is a no-op on re-run; the context UPDATEs are stable.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='ba59337e-30e2-4aba-a39a-426b3366eb27'
                   AND topic_key='transportation-priorities') THEN
    RAISE EXCEPTION 'CA_0052: transportation-priorities topic id mismatch';
  END IF;
END $$;

CREATE TEMP TABLE tr_blank(pid uuid, tid uuid) ON COMMIT DROP;
INSERT INTO tr_blank(pid, tid) VALUES
  ('8247e088-2ac8-4ae1-bac9-ff537dd27fec','ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Al Rios (South Gate Vice Mayor)
  ('716d3f30-d9f9-4d83-ae6f-9022ae1a8d7b','ba59337e-30e2-4aba-a39a-426b3366eb27'); -- Jordan Rivers (LA CD15 candidate)

-- Remove the unevidenced seatings.
DELETE FROM inform.politician_answers a USING tr_blank b
 WHERE a.politician_id=b.pid AND a.topic_id=b.tid;

-- Rewrite context as a documented blank (topic applies; record was read).
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources=ARRAY['https://spectrumnews1.com/ca/la/know-your-electeds/2021/11/10/know-your-electeds-city-of-south-gate-mayor-al-rios']::text[],
  reasoning=$r$Researched 2026-08-30 — Al Rios (Vice Mayor, South Gate, CA City Council). The only located source is a 2021 Spectrum News profile that paraphrases (does not quote) him as enthusiastic about the Southeast Gateway Line / West Santa Ana Branch light rail reaching South Gate; his official city page was unreachable and no campaign platform, candidate forum, or council statement on transportation priorities could be found. General support for one transit project does not state whether transit should be funded over new road capacity or equally alongside it, so no chair on the roads-vs-transit spectrum can be placed; left blank.$r$
 WHERE politician_id='8247e088-2ac8-4ae1-bac9-ff537dd27fec' AND topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  sources=ARRAY['https://patch.com/california/los-angeles/meet-jordan-rivers-candidate-los-angeles-city-council-district-15','https://www.yahoo.com/news/articles/guide-l-city-council-district-100000815.html']::text[],
  reasoning=$r$Researched 2026-08-30 — Jordan Rivers (candidate, Los Angeles City Council District 15). A Patch candidate interview and a Yahoo/AOL voter guide describe a transit-only platform: a San Pedro–Wilmington–downtown rail line, free public transit, and a Metro Blue Line connection to the port communities. None addresses road or highway investment in either direction, so the record does not distinguish prioritizing transit over new road capacity from investing in roads and transit equally; left blank.$r$
 WHERE politician_id='716d3f30-d9f9-4d83-ae6f-9022ae1a8d7b' AND topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27';

-- @context-decision: rewritten-as-blank — the transportation-priorities topic applies to both (a
-- sitting South Gate Vice Mayor and an LA City Council candidate) and each record WAS read against
-- primary sources on 2026-08-30; neither source states a roads-vs-transit priority, so each context
-- is a documented blank naming what was checked. No answer row remains for these pairs.

-- GUARD: check-stance-sources.mjs ORPHAN_CONTEXT predicate on the blanked pairs (regexes identical
-- to the gate). CA_ files bypass the CI answer-delete guard, so this is the enforcement point.
DO $$
DECLARE new_orphans int;
BEGIN
  SELECT count(*) INTO new_orphans
    FROM tr_blank t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.pid AND pc.topic_id = t.tid
   WHERE coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF new_orphans > 0 THEN
    RAISE EXCEPTION
      'CA_0052 context guard: % blanked row(s) kept reasoning that still asserts a position', new_orphans;
  END IF;
END $$;

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic CONSTANT uuid := 'ba59337e-30e2-4aba-a39a-426b3366eb27';
  v_ids   CONSTANT uuid[] := ARRAY['8247e088-2ac8-4ae1-bac9-ff537dd27fec',
                                   '716d3f30-d9f9-4d83-ae6f-9022ae1a8d7b']::uuid[];
  v_ans int; v_ctx int; v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int;
BEGIN
  -- (a) no answer rows remain for the 2 blanked pairs
  SELECT count(*) INTO v_ans FROM inform.politician_answers
   WHERE topic_id=v_topic AND politician_id = ANY(v_ids);
  IF v_ans <> 0 THEN RAISE EXCEPTION 'CA_0052: expected 0 answer rows for blanked pairs, got %', v_ans; END IF;

  -- (b) both context rows still exist (documented blanks, not deleted)
  SELECT count(*) INTO v_ctx FROM inform.politician_context
   WHERE topic_id=v_topic AND politician_id = ANY(v_ids);
  IF v_ctx <> 2 THEN RAISE EXCEPTION 'CA_0052: expected 2 documented-blank context rows, got %', v_ctx; END IF;

  -- (c) distribution
  SELECT
    count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2),
    count(*) FILTER (WHERE value=3), count(*) FILTER (WHERE value=4),
    count(*) FILTER (WHERE value=5)
  INTO v_c1, v_c2, v_c3, v_c4, v_c5
  FROM inform.politician_answers WHERE topic_id=v_topic;

  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (115,158,110,58,3) THEN
    RAISE EXCEPTION 'CA_0052: distribution is %/%/%/%/% (expected 115/158/110/58/3)',
      v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;

  RAISE NOTICE 'CA_0052 OK — 2 rows blanked (answer deleted, context documented-blank); distribution now %/%/%/%/%',
    v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
