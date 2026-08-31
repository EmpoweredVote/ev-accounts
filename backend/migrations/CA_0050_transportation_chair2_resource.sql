BEGIN;

-- =============================================================================
-- CA_0050: Transportation Priorities — re-source of 5 thin chair-2 rows
-- =============================================================================
-- Created 2026-08-30 with Chris Andrews (actor 854fbc06-40fc-458d-b523-20ef8e5ad1b2,
-- candrews@empowered.vote).
--
-- WHAT: follow-up to CA_0049. Of the 12 thin transportation chair-2 rows left at 2
--   by CA_0049, a primary-source re-source pass (2026-08-30) firmed up 5. Each moves
--   off the thin chair-2 seating to the chair its OWN primary source describes, and
--   its context reasoning + sources are REFRESHED to that source (not a value-only
--   move — the prior reasoning was the thin chair-2 text):
--
--   3 MOVE 2 -> 1 (multimodal prioritized over road capacity):
--     - Michael E. Verveer (Madison D4): 2025 Madison Bikes questionnaire — the city
--       "should be investing in sustainable mobility solutions rather than heavily
--       subsidizing private vehicle storage" (explicit over-roads).
--     - Tag Evers (Madison D13): own issues page — BRT, bike network, Vision Zero, a
--       circulator explicitly "to take cars off the road"; no road-capacity plank.
--     - Natalya Zernitskaya (Santa Monica): votes to narrow car lanes and convert bus
--       lanes to bike use on Santa Monica Blvd; no pro-road-capacity evidence
--       (lane-specific).
--
--   2 MOVE 2 -> 3 (maintain roads while selectively adding transit/ped):
--     - Nelson Cheng (LA mayoral candidate): official City Clerk statement proposes a
--       downtown-only peak-hour free-bus plan framed as easing congestion — selective,
--       density-supported transit, not "over roads" (1) or "equal" (2).
--     - Victor Preciado (Pomona D2): own site pairs Foothill Transit route expansion
--       with "continuing street, sidewalk, and alley improvements... repaving" — road
--       maintenance (not new capacity) alongside selective transit.
--
--   The other 7 thin rows are UNCHANGED (left at chair 2): 3 chair-1-by-omission
--   candidates held pending stronger evidence (Badri Lankella, Julia Matthews, Sean
--   O'Brien); 2 confirmed at chair 2 by their own words (Fernando Dutra, Morgan
--   Oyler); 2 that came back blank after searching, left at chair 2 as still-thin
--   rather than deleted (Al Rios, Jordan Rivers — a delete would remove the open
--   Season-1 answer).
--
-- WHY IN-PLACE (changes open Season 1): schema can't season-split (value CHECK 1..5;
--   newest-season collapse, no status gate). All answers are Season 1; the correction
--   is right for both seasons. (CA_0045 / CA_0049 style.)
--
-- Expected end state (transportation-priorities answers): 1=112, 2=163, 3=110, 4=58,
--   5=3 (was 109/168/108/58/3 after CA_0049); 3 moved 2->1, 2 moved 2->3.
-- Idempotent: value UPDATEs are scoped to rows still at value 2 in the id set; a
--   re-run is a no-op and the post-verify still holds.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics
                 WHERE id='ba59337e-30e2-4aba-a39a-426b3366eb27'
                   AND topic_key='transportation-priorities') THEN
    RAISE EXCEPTION 'CA_0050: transportation-priorities topic id mismatch';
  END IF;
END $$;

-- ── Michael E. Verveer: 2 -> 1 ────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='c7ee1c03-63d7-4107-b076-72b1f059b0f7';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$In his 2025 Madison Bikes candidate questionnaire, Verveer said the city "should reevaluate its role in subsidizing private vehicle storage" and that "the City's priority should be investing in sustainable mobility solutions rather than heavily subsidizing private vehicle storage" via expanded transit, bike, and pedestrian infrastructure. Combined with his record backing the Complete Green Streets policy, protected bike lanes, the North-South BRT line, and Amtrak service — and no plank favoring road/car-capacity expansion — this prioritizes pedestrian, cycling, and transit investment over new road capacity.$r$,
  sources=ARRAY['https://www.madisonbikes.org/madison-spring-elections-2025/','https://www.mikeverveer.com/endorsements','https://captimes.com/news/government/madison-spring-election-q-a-with-district-4-city-council-candidates/article_d6cde8e6-ff4f-11ef-9acd-ff53e73aaf07.html']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='c7ee1c03-63d7-4107-b076-72b1f059b0f7';

-- ── Tag Evers: 2 -> 1 ─────────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='10e69d7b-dc44-4c93-bcdf-53c778b9ffcc';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Evers' own campaign issues page (Madison Common Council District 13) emphasizes Bus Rapid Transit, an expanding bike network (citing Madison's Platinum Biking City status), Vision Zero speed reductions, a Transportation Demand Management policy, and a Room-Tax-funded tourist circulator explicitly designed to "take cars off the road." Road capacity or expansion is not discussed, and the circulator explicitly aims to reduce car use — prioritizing pedestrian, cycling, and transit investment over new road capacity.$r$,
  sources=ARRAY['https://www.tagevers.com/issues','https://madison.citycast.fm/local-civics/meet-the-2025-madison-city-council-candidates-tag-evers']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='10e69d7b-dc44-4c93-bcdf-53c778b9ffcc';

-- ── Natalya Zernitskaya: 2 -> 1 ───────────────────────────────────────────────
UPDATE inform.politician_answers SET value=1, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='5fb4bb9b-ab05-4441-85d8-93ed97149e38';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$On the Santa Monica Boulevard safety redesign, Zernitskaya joined the council's unanimous vote sending the plan back to demand narrower travel lanes and stronger pedestrian/cyclist protections ("designing them with the lowest common denominator user in mind"), and backed a motion to legalize bikes in all of the city's bus lanes citywide. Narrowing car-lane capacity and converting bus-lane space for bikes, with no evidence favoring road/car-lane capacity, prioritizes multimodal safety over road capacity (evidence is lane-specific).$r$,
  sources=ARRAY['https://www.smdp.com/santa-monica-council-sends-back-boulevard-safety-plan-demands-stronger-protections/','https://smdp.com/news/transportation/santa-monica-council-approves-shared-bus-bike-lanes-in-split-vote/','https://www.streetsforall.org/2024-voter-guide']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='5fb4bb9b-ab05-4441-85d8-93ed97149e38';

-- ── Nelson Cheng: 2 -> 3 ──────────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='44869705-e048-4099-a964-347bde510d45';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Cheng's official candidate statement (LA City Clerk, 2026 mayoral race) proposes one transportation measure: shortening bus wait times and free bus rides during weekday peak hours "only around downtown L.A." to reduce car congestion. Framed as easing traffic and targeted to a dense corridor rather than citywide — selectively adding transit where density supports it (chair 3) — not prioritizing transit over roads (1) or investing equally (2).$r$,
  sources=ARRAY['https://cityclerk.lacity.org/election/cheng_ENG.pdf','https://patch.com/california/los-angeles/meet-nelson-cheng-candidate-los-angeles-mayor','https://dailybruin.com/2026/05/31/los-angeles-mayoral-contenders-offer-competing-visions-for-citys-future']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='44869705-e048-4099-a964-347bde510d45';

-- ── Victor Preciado: 2 -> 3 ───────────────────────────────────────────────────
UPDATE inform.politician_answers SET value=3, editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now()
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND value=2
   AND politician_id='56cecf7c-6de0-440f-b8e2-34945ec52333';
UPDATE inform.politician_context SET editor_id='854fbc06-40fc-458d-b523-20ef8e5ad1b2', updated_at=now(),
  reasoning=$r$Preciado's own campaign site (Pomona City Council District 2) pairs "leveraging his seat on the Foothill Transit board to expand reliable, affordable routes" with "continuing street, sidewalk, and alley improvements across the District, building on repaving already completed." Road maintenance/repaving (not new capacity) alongside selective transit and sidewalk work matches maintaining roads while selectively adding transit and pedestrian improvements (chair 3).$r$,
  sources=ARRAY['https://victorforpomona.com/','https://www.pomonaca.gov/government/mayor-city-council/councilmember-victor-preciado','https://ballotpedia.org/Victor_Preciado_(Pomona_City_Council_District_2,_California,_candidate_2026)']::text[]
 WHERE topic_id='ba59337e-30e2-4aba-a39a-426b3366eb27' AND politician_id='56cecf7c-6de0-440f-b8e2-34945ec52333';

-- =============================================================================
-- POST-VERIFY GATE
-- =============================================================================
DO $$
DECLARE
  v_topic  CONSTANT uuid := 'ba59337e-30e2-4aba-a39a-426b3366eb27';
  v_to1    CONSTANT uuid[] := ARRAY['c7ee1c03-63d7-4107-b076-72b1f059b0f7',
                                    '10e69d7b-dc44-4c93-bcdf-53c778b9ffcc',
                                    '5fb4bb9b-ab05-4441-85d8-93ed97149e38']::uuid[];
  v_to3    CONSTANT uuid[] := ARRAY['44869705-e048-4099-a964-347bde510d45',
                                    '56cecf7c-6de0-440f-b8e2-34945ec52333']::uuid[];
  v_n int; v_c1 int; v_c2 int; v_c3 int; v_c4 int; v_c5 int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id=v_topic AND value=1 AND politician_id = ANY(v_to1);
  IF v_n <> 3 THEN RAISE EXCEPTION 'CA_0050: expected 3 rows moved to chair 1, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE topic_id=v_topic AND value=3 AND politician_id = ANY(v_to3);
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0050: expected 2 rows moved to chair 3, got %', v_n; END IF;

  -- context refreshed (sources non-empty) for all 5
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE topic_id=v_topic
     AND politician_id = ANY(v_to1 || v_to3)
     AND array_length(sources,1) >= 1;
  IF v_n <> 5 THEN RAISE EXCEPTION 'CA_0050: expected 5 refreshed context rows with sources, got %', v_n; END IF;

  SELECT
    count(*) FILTER (WHERE value=1), count(*) FILTER (WHERE value=2),
    count(*) FILTER (WHERE value=3), count(*) FILTER (WHERE value=4),
    count(*) FILTER (WHERE value=5)
  INTO v_c1, v_c2, v_c3, v_c4, v_c5
  FROM inform.politician_answers WHERE topic_id=v_topic;

  IF (v_c1,v_c2,v_c3,v_c4,v_c5) <> (112,163,110,58,3) THEN
    RAISE EXCEPTION 'CA_0050: distribution is %/%/%/%/% (expected 112/163/110/58/3)',
      v_c1,v_c2,v_c3,v_c4,v_c5;
  END IF;

  RAISE NOTICE 'CA_0050 OK — 3 moved 2->1, 2 moved 2->3; distribution now %/%/%/%/%',
    v_c1,v_c2,v_c3,v_c4,v_c5;
END $$;

COMMIT;
