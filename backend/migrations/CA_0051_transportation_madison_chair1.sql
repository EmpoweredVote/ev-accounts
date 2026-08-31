BEGIN;

-- =============================================================================
-- CA_0051: Transportation Priorities — 3 Madison rows re-seated 2 -> 1
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: follow-up to CA_0050. The 3 rows CA_0050 held at chair 2 as
--   "chair-1-by-omission" (own platform listed only multimodal, silent on roads)
--   were deep-re-sourced 2026-08-30 and now carry DISCRIMINATING chair-1 evidence.
--   Each moves 2 -> 1 with reasoning + sources refreshed:
--     - Badri Lankella (Madison D7): 2025 Madison Bikes questionnaire — "fully
--       support[s]" Complete Green Streets (prioritizes walk/bike/transit over
--       driving and car parking), wants parking's role reassessed "reducing car
--       dependency through transit and active transportation", supports eliminating
--       parking minimums.
--     - Julia Matthews (Madison D12): same questionnaire — supports Complete Green
--       Streets "especially when a project requires the removal of car parking or
--       general travel lanes"; parking subsidies should shrink as transit grows.
--     - Sean O'Brien (Madison D16): on the South Stoughton Road redesign in his own
--       district, "I don't think adding a lane is the path forward" — an explicit
--       rejection of added road capacity for a walkable/bikeable boulevard
--       (corridor-specific rather than a citywide rule, but discriminating).
--
-- WHY IN-PLACE (changes open Season 1): schema can't season-split; all answers are
--   Season 1; the correction is right for both seasons. (CA_0049/CA_0050 style.)
--
-- Expected end state (transportation-priorities answers): 1=115, 2=160, 3=110,
--   4=58, 5=3 (was 112/163/110/58/3 after CA_0050); 3 moved 2 -> 1.
-- Idempotent: value UPDATEs scoped to rows still at value 2 in the id set.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='ba59337e-30e2-4aba-a39a-426b3366eb27'
                   AND topic_key='transportation-priorities') THEN
    RAISE EXCEPTION 'CA_0051: transportation-priorities topic id mismatch';
  END IF;
END $$;

-- ── Badri Lankella: 2 -> 1 ────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='86c3a5c2-cf35-49e5-b329-ca811712fb7b';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$On the 2025 Madison Bikes candidate questionnaire, Lankella (Common Council District 7) said he "fully support[s] the implementation of Madison's Complete Green Streets policy," which prioritizes walking, biking, and transit over driving and car parking. On the parking-subsidy question he called for "reassessing parking's role, with emphasis on reducing car dependency through transit and active transportation investments," and he supports eliminating parking minimums. This prioritizes pedestrian, cycling, and transit investment over new road capacity.$r$,
  sources=ARRAY['https://www.madisonbikes.org/madison-spring-elections-2025/']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='86c3a5c2-cf35-49e5-b329-ca811712fb7b';

-- ── Julia Matthews: 2 -> 1 ────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='07fd1bbc-a95d-4f85-8d24-67e8f2e0ef3a';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$On the 2025 Madison Bikes candidate questionnaire, Matthews (Common Council District 12) affirmed she supports the Complete Green Streets policy "especially when a project requires the removal of car parking or general travel lanes," endorsing the reallocation of road/parking space to walking, biking, and transit. She added the City "should reconsider its role in subsidizing parking" since demand for subsidized parking "should decrease over time" as transit investment grows. This prioritizes pedestrian, cycling, and transit investment over new road capacity.$r$,
  sources=ARRAY['https://www.madisonbikes.org/madison-spring-elections-2025/','https://madisonbiz.com/wp-content/uploads/D12-Julia-Matthews.pdf']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='07fd1bbc-a95d-4f85-8d24-67e8f2e0ef3a';

-- ── Sean O'Brien: 2 -> 1 ──────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='6ced47ca-3da5-4ca4-a828-953c41aa5229';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$On the South Stoughton Road redesign in his own district (Common Council District 16), O'Brien told the Cap Times "I don't think adding a lane is the path forward," explicitly rejecting a road-capacity expansion, and said he wants the corridor rebuilt as a boulevard with housing, small business, "walkability and bikeability of the neighborhoods." This forward-looking rejection of added road capacity in favor of a multimodal/walkable redesign prioritizes pedestrian, cycling, and transit investment over new road capacity (evidence is corridor-specific rather than a stated citywide policy).$r$,
  sources=ARRAY['https://captimes.com/news/government/stoughton-road-dilemma-how-to-cut-crashes-and-improve-access/article_3ba87f21-dc0a-4182-9391-1b30c033b96e.html','https://www.seanformadison.com/issues']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='6ced47ca-3da5-4ca4-a828-953c41aa5229';

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic CONSTANT uuid := 'ba59337e-30e2-4aba-a39a-426b3366eb27';
  v_ids   CONSTANT uuid[] := ARRAY['86c3a5c2-cf35-49e5-b329-ca811712fb7b',
                                   '07fd1bbc-a95d-4f85-8d24-67e8f2e0ef3a',
                                   '6ced47ca-3da5-4ca4-a828-953c41aa5229']::uuid[];
  v_n int; v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id=v_topic AND value=1 AND politician_id = ANY(v_ids);
  IF v_n <> 3 THEN RAISE EXCEPTION 'CA_0051: expected 3 rows at chair 1, got %', v_n; END IF;

  IF EXISTS (SELECT 1 FROM inform.politician_answers
             WHERE topic_id=v_topic AND value=2 AND politician_id = ANY(v_ids)) THEN
    RAISE EXCEPTION 'CA_0051: a target row is still at chair 2';
  END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE topic_id=v_topic AND politician_id = ANY(v_ids) AND array_length(sources,1) >= 1;
  IF v_n <> 3 THEN RAISE EXCEPTION 'CA_0051: expected 3 refreshed context rows with sources, got %', v_n; END IF;

  SELECT
    count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2),
    count(*) FILTER (WHERE value=3), count(*) FILTER (WHERE value=4),
    count(*) FILTER (WHERE value=5)
  INTO v_c1, v_c2, v_c3, v_c4, v_c5
  FROM inform.politician_answers WHERE topic_id=v_topic;

  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (115,160,110,58,3) THEN
    RAISE EXCEPTION 'CA_0051: distribution is %/%/%/%/% (expected 115/160/110/58/3)',
      v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;

  RAISE NOTICE 'CA_0051 OK — 3 Madison rows moved 2 -> 1; distribution now %/%/%/%/%',
    v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
