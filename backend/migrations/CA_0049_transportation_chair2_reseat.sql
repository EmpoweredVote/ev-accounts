BEGIN;

-- =============================================================================
-- CA_0049: Transportation Priorities — chair-2 -> chair-1 re-seat (in-place)
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: re-audit the 189 rows seated on transportation-priorities chair 2 against
--   the CA_0048 wording, and move the rows whose evidence prioritizes transit /
--   active modes OVER road capacity to chair 1.
--     chair 1: "Prioritize pedestrian infrastructure, cycling networks, and public
--               transit over new road capacity"
--     chair 2: "Invest equally in road capacity and in multimodal options like
--               transit, bike lanes, and sidewalks"
--   Discriminator: chair 1 = transit/active prioritized OVER roads (reduce car
--   dependence, car-free, road diet / lane reduction, redirect road funds,
--   anti-highway as the defining stance). chair 2 = invests in BOTH, roads named
--   alongside multimodal.
--
-- 21 MOVE 2 -> 1. Each row's EXISTING reasoning already states a transit-over-roads
--   position (e.g. "over car-centric investment", "over automobiles", "over road
--   capacity", "reduce car dependence/dominance", "car-free", a road diet, lane
--   reductions, redirecting road-repair funds, an anti-freeway record) and does NOT
--   conclude "invest equally". So this is a value-only move: the reasoning is left
--   in place, already supporting chair 1 (CA_0045 pattern — movers whose reasoning
--   already fits the new chair keep it; only rows needing a new instrument get a
--   rewrite, and none here do).
--
--   Not moved (decisions 2026-08-30, Chris Andrews):
--   - ~12 THIN transit-only rows (no road-investment evidence AND no explicit
--     "over roads") are LEFT at chair 2 for now and recorded as a re-source
--     follow-up. They establish neither chair cleanly; blanking would delete the
--     open-Season-1 answer (see season-blank-sentinel), so they are not touched.
--   - 5 federal members ("over highway expansion" but voted IIJA roads+transit) are
--     KEPT at chair 2 (balanced record).
--
-- WHY IN-PLACE (changes open Season 1): the schema cannot represent "seated in
--   Season 1, different in Season 2" — politician_answers.value is CHECK 1..5 and
--   the compare read collapses to the newest season with no status gate. All 446
--   answers are stamped Season 1. A wrong chair is wrong in the open season too, so
--   the correction is right for BOTH seasons and carries into Season 2 when it opens.
--   (CA_0033 / CA_0035 / CA_0038 / CA_0045 style.)
--
-- Expected end state (transportation-priorities answers): 1=109, 2=168, 3=108,
--   4=58, 5=3 (was 88/189/108/58/3); 21 moved 2 -> 1, none removed.
-- Idempotent: the UPDATE only touches rows still at value 2 in the id set; a re-run
--   finds none and the post-verify still holds.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='ba59337e-30e2-4aba-a39a-426b3366eb27'
                   AND topic_key='transportation-priorities') THEN
    RAISE EXCEPTION 'CA_0049: transportation-priorities topic id mismatch';
  END IF;
END $$;

-- ── Move: chair 2 -> chair 1 (transit prioritized over road capacity) ─────────
-- 21 rows; existing reasoning already supports chair 1 (value-only move).
UPDATE inform.politician_answers
   SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id IN (
     'e30ddde5-a722-477b-837b-056fdc7e2d6b',  -- Adrin Nazarian
     'f2e91286-8dbc-477a-88be-458dffe774a2',  -- Andrej Selivra
     'd3c5004c-9ca0-444e-96d9-107d4315abcb',  -- Bilal Mahmood
     '77796735-bc75-40f8-baea-5263a027df09',  -- Bill Tishler
     '188c6816-2e22-433a-8bff-fc020ca2da0e',  -- Davy Mayer
     '5d7f84b4-e987-4be2-b3c5-64933e559bed',  -- Dylan Kendall
     '100405fd-4ccc-427d-9ccd-962739d6d292',  -- Elmer Roldan
     '3b3b6525-7a40-4d01-a1cb-3270ed166919',  -- Eric Guerra
     '317698c6-2ae7-4f7f-ab39-bb3811ed50f3',  -- Eunisses Hernandez
     'a9882d8b-b20d-4b0c-b509-c2883b4352e0',  -- Faizah Malik
     '29a8c85b-2572-463c-8034-8986615d7717',  -- Heather Hutt
     '6c795b3b-d59d-4667-b79e-8a2e27e0c283',  -- Hugo Soto-Martinez
     '5114097d-c06a-4147-85bc-f9a6646f5c46',  -- Jon Mitchell
     '6db2abd4-86ce-414a-ba80-6565e6e3b23d',  -- Kateri Walsh
     '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996',  -- Myrna Melgar
     '63534729-c022-4305-bef1-e29d4464f719',  -- Natalie Pinkney
     '43534230-24b1-432a-9901-f1c666ed009e',  -- Roberto Uranga
     'e2ce84d2-ee0b-4851-b1d8-168a2f54a82b',  -- Steve Madison
     '1512eb0b-df87-4288-a598-0212d5520d02',  -- Will Ochowicz
     'f29c9754-363f-48ad-96f4-5773d2a29aa3',  -- Yannette Figueroa Cole
     'af870d90-718a-4d0c-a267-8436e84720ba'); -- Yi-An Huang

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic   CONSTANT uuid := 'ba59337e-30e2-4aba-a39a-426b3366eb27';
  v_ids     CONSTANT uuid[] := ARRAY[
     'e30ddde5-a722-477b-837b-056fdc7e2d6b','f2e91286-8dbc-477a-88be-458dffe774a2',
     'd3c5004c-9ca0-444e-96d9-107d4315abcb','77796735-bc75-40f8-baea-5263a027df09',
     '188c6816-2e22-433a-8bff-fc020ca2da0e','5d7f84b4-e987-4be2-b3c5-64933e559bed',
     '100405fd-4ccc-427d-9ccd-962739d6d292','3b3b6525-7a40-4d01-a1cb-3270ed166919',
     '317698c6-2ae7-4f7f-ab39-bb3811ed50f3','a9882d8b-b20d-4b0c-b509-c2883b4352e0',
     '29a8c85b-2572-463c-8034-8986615d7717','6c795b3b-d59d-4667-b79e-8a2e27e0c283',
     '5114097d-c06a-4147-85bc-f9a6646f5c46','6db2abd4-86ce-414a-ba80-6565e6e3b23d',
     '72621ac9-bcdb-4ea3-aeec-1b1f50c9f996','63534729-c022-4305-bef1-e29d4464f719',
     '43534230-24b1-432a-9901-f1c666ed009e','e2ce84d2-ee0b-4851-b1d8-168a2f54a82b',
     '1512eb0b-df87-4288-a598-0212d5520d02','f29c9754-363f-48ad-96f4-5773d2a29aa3',
     'af870d90-718a-4d0c-a267-8436e84720ba']::uuid[];
  v_moved   int;
  v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int;
BEGIN
  -- (a) all 21 target rows are now at chair 1
  SELECT count(*) INTO v_moved
  FROM inform.politician_answers
  WHERE topic_id=v_topic AND value=1 AND politician_id = ANY(v_ids);
  IF v_moved <> 21 THEN
    RAISE EXCEPTION 'CA_0049: expected 21 target rows at chair 1, got %', v_moved;
  END IF;

  -- (b) none of the 21 remain at chair 2
  IF EXISTS (SELECT 1 FROM inform.politician_answers
             WHERE topic_id=v_topic AND value=2 AND politician_id = ANY(v_ids)) THEN
    RAISE EXCEPTION 'CA_0049: a target row is still at chair 2';
  END IF;

  -- (c) full distribution matches the expected end state
  SELECT
    count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2),
    count(*) FILTER (WHERE value=3), count(*) FILTER (WHERE value=4),
    count(*) FILTER (WHERE value=5)
  INTO v_c1, v_c2, v_c3, v_c4, v_c5
  FROM inform.politician_answers WHERE topic_id=v_topic;

  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (109,168,108,58,3) THEN
    RAISE EXCEPTION 'CA_0049: distribution is %/%/%/%/% (expected 109/168/108/58/3)',
      v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;

  RAISE NOTICE 'CA_0049 OK — 21 rows moved chair 2 -> 1; distribution now %/%/%/%/%',
    v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
