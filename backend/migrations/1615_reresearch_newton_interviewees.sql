-- 1615: Newton block 1 — the four councilors with their own Fig City News candidate interview.
--
-- 15 rows were in scope (Krintzman 8, Roche 3, Silber 2, Irish 2). **5 restored, 10 not.**
--
-- 🔴 A CORRECTION TO MY OWN SCOPE. `2026-08-07-scope.md` treated these four as "15 of the 48 rows"
-- recoverable. Reading the interviews in full yields **5**. An interview existing is not the same as
-- an interview answering the question — three of the four are short (2,769–4,494 chars of body) and
-- each covers only the two or three subjects the reporter actually raised. The scope should have said
-- "15 rows have a candidate source to CHECK", not "15 recoverable". Planning numbers for the rest of
-- Newton should be revised down accordingly.
--
-- ⚠ These are September/October 2025 CANDIDATE interviews. For Roche and Silber — sworn in
-- 2026-01-01 — that is the only honest basis and carries no pre-tenure risk. Krintzman is an
-- incumbent finishing his fourth term, so a campaign interview is still his own stated position. Each
-- reasoning dates the statement so its vintage is visible to a voter.
--
-- ===================================== RESTORED (5) =========================================
--
-- Sean Roche — Residential Zoning 1 -> 3. "believes strongly in denser development, especially in
--   village centers" + "a wider range of housing options and more housing, particularly near transit".
--   Village centres are Newton's commercial corridors, which is chair 3 precisely. Retired chair 1
--   ("protect existing neighborhood character strictly") is the opposite of what he says.
-- Sean Roche — Affordable Housing 1 -> 4. His answer to the housing problem is that Newton controls
--   its own zoning: "We have the unique capacity to solve that [housing] problem ourselves."
--   ⚠ FLAGGED: this rests on the SAME interview passage as his zoning row. I judged that legitimate
--   because chair 4 on the Affordable Housing scale IS the zoning answer ("cut regulations and zoning
--   rules so private developers can build more housing") — the scale offers supply-via-zoning as one
--   of its five positions. A reviewer who prefers one-passage-one-chair should drop this row; it is
--   the single most arguable call in this migration.
-- Sean Roche — Transportation Priorities 2 -> 1. Bike commuter and former Vice Chair of the Newton
--   Bicycle/Pedestrian Task Force; names completion of the MBTA Commuter Rail platforms as "the
--   biggest transformation we in the city can make in the next ten years".
--   ⚠ Chair 1 also mentions reducing parking requirements communitywide, which he never says, so that
--   is not claimed in the reasoning.
-- Jacob Silber — Residential Zoning 2 (unchanged). Co-founded a residents' group against a 244-unit
--   Chapter 40B project; wants the City to retain a hydrogeologist because otherwise "we are
--   abdicating our processes"; questions whether ~20% population growth can be absorbed. That is
--   chair 2's "strong design review and neighborhood input". Chair 1 needs community votes before any
--   rezoning, which he does not propose.
-- Josh Krintzman — Residential Zoning 1 -> 3. "Should they be the exclusive housing in the community?
--   Absolutely not" plus support for the Inclusionary Zoning ordinance. Retired chair 1 asserted the
--   opposite of his stated view. Not 4 or 5: he calls for no by-right upzoning and no citywide
--   elimination of single-family zoning, and describes himself as "reasonable and practical".
--
-- ================================== NOT RESTORED (10) =======================================
-- Nothing is deleted — mig 1548 removed these and they were never restored. Reasons recorded so no
-- later sweep re-queues them.
--
-- Julie Irish x2 (Affordable Housing, Residential Zoning). Her interview is about commercial
--   development and the tax base ("Newton needs to place much greater emphasis on commercial
--   development"), village shuttle pilots, and a City website dashboard. It says nothing about
--   housing affordability or residential density. Her commercial-vs-residential tax argument is NOT
--   a density position and was not used as one.
-- Jacob Silber x1 (Affordable Housing). He organised against a Chapter 40B project — Massachusetts'
--   affordable-housing statute — but his stated reasons are floodplain, tree loss and traffic. He
--   offers no position on the government's role in affordability. Inferring one from the target of
--   his opposition would be reading motive into an action, the same error refused for the Portland
--   2026-205 Nays in mig 1611.
-- Josh Krintzman x7 (Civil Rights and Social Justice, Climate Change and Environmental Protection,
--   Growth and Development Pace, Local Immigration Enforcement, Public Safety Approach, Rent
--   Regulation, Transportation Priorities). His interview covers committee work on the school budget,
--   the Tree Protection Ordinance, recreational fields and artificial turf, plus housing and the
--   Washington Street pilot. Four of the seven are simply absent from it. Of the three that are
--   arguable, each was rejected deliberately:
--     · Climate Change asks about ENERGY and economic policy; his evidence is a tree ordinance and
--       artificial turf. Local tree rules are not an energy-transition position.
--     · Growth and Development Pace — his proactive-planning evidence is recreational FIELDS and a
--       street pilot, not growth management. A correct-looking chair on non-evidence is still a
--       fabrication risk.
--     · Transportation — one clause, that the Washington Street pilot makes the street "safer for
--       pedestrians and vehicles", is too thin for a five-point investment-priority scale. Contrast
--       Roche, whose transportation record is substantial; the asymmetry is evidence-driven.
--
-- All 3 citations were fetched and each quoted passage asserted VERBATIM before this was written.

BEGIN;

DO $$
DECLARE v_existing int;
BEGIN
  SELECT count(*) INTO v_existing FROM inform.politician_context
   WHERE (politician_id, topic_id) IN (
     ('e9abe848-ca92-4197-924d-294e7ed92100','669cac97-66a6-4087-b036-936fbe62efb3'),
     ('e9abe848-ca92-4197-924d-294e7ed92100','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('e9abe848-ca92-4197-924d-294e7ed92100','ba59337e-30e2-4aba-a39a-426b3366eb27'),
     ('ec923a42-9b27-4f8a-a839-69d6e45c2cf8','d4f18138-a2e0-4110-b925-7387d9d0d16d'),
     ('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2','d4f18138-a2e0-4110-b925-7387d9d0d16d'));
  IF v_existing <> 0 THEN RAISE EXCEPTION 'expected 0 existing rows, found %', v_existing; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES

('e9abe848-ca92-4197-924d-294e7ed92100', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Roche wants Newton to add housing density in its village centres rather than uniformly across residential streets. In a 2025 candidate interview he said he believes strongly in denser development, especially in village centers, and argued that the city can change its own rules: "Newton has the building types that the zoning is designed to allow, and if we want something different, we can fix that problem ourselves. We don''t need anybody''s permission." He advocates a wider range of housing options and more housing, particularly near transit.',
 ARRAY['https://www.figcitynews.com/2025/10/interview-sean-roche-at-large-candidate-for-city-council-ward-6/']),

('e9abe848-ca92-4197-924d-294e7ed92100', '669cac97-66a6-4087-b036-936fbe62efb3',
 'Roche''s answer to Newton''s housing costs is for the city to change its own zoning so that more and a wider range of housing can be built, rather than new subsidy programmes. He said Newton has "the unique capacity to solve that [housing] problem ourselves" because it controls its zoning, and he advocates more housing particularly near transit. In a 2025 candidate interview he proposed no rent controls, purchase assistance or public construction.',
 ARRAY['https://www.figcitynews.com/2025/10/interview-sean-roche-at-large-candidate-for-city-council-ward-6/']),

('e9abe848-ca92-4197-924d-294e7ed92100', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
 'Roche puts cycling, walking and public transit at the centre of transportation policy. A bike commuter who served as Vice Chair of the Newton Bicycle/Pedestrian Task Force, he said in a 2025 candidate interview that "the biggest transformation we in the city can make in the next ten years is the completion of the [MBTA Commuter Rail] platforms", noting that single-track platforms limit both the number of trains and their performance. He also praised the Washington Street pilot for testing a street design before finalising it.',
 ARRAY['https://www.figcitynews.com/2025/10/interview-sean-roche-at-large-candidate-for-city-council-ward-6/']),

('ec923a42-9b27-4f8a-a839-69d6e45c2cf8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Silber wants development held to closer scrutiny of its effect on existing neighbourhoods. He helped form a residents group opposing a 244-unit, seven-storey Chapter 40B project on what he describes as Newton''s largest residential floodplain, citing flooding and tree loss. He argues the City should retain a hydrogeologist to analyse the hazards associated with development, saying that without professional analysis "we are abdicating our processes", and questions whether large projects that would raise his ward''s population by about 20 percent can be absorbed by roads that are not being widened.',
 ARRAY['https://www.figcitynews.com/2025/10/interview-jacob-silber-unopposed-candidate-for-at-large-city-councilor-ward-8/']),

('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
 'Krintzman rejects single-family zoning as Newton''s only permitted housing form, while describing his own approach as reasonable and practical. In a 2025 interview he said Newton "has for a long time been a mostly single-family residential community" and asked, "Should they be the exclusive housing in the community? Absolutely not." He supports the city''s Inclusionary Zoning ordinance, which requires new and large developments to include a component of affordable housing.',
 ARRAY['https://www.figcitynews.com/2025/09/interview-josh-krintzman-at-large-candidate-for-city-council-ward-4/']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('e9abe848-ca92-4197-924d-294e7ed92100','d4f18138-a2e0-4110-b925-7387d9d0d16d',3),
('e9abe848-ca92-4197-924d-294e7ed92100','669cac97-66a6-4087-b036-936fbe62efb3',4),
('e9abe848-ca92-4197-924d-294e7ed92100','ba59337e-30e2-4aba-a39a-426b3366eb27',1),
('ec923a42-9b27-4f8a-a839-69d6e45c2cf8','d4f18138-a2e0-4110-b925-7387d9d0d16d',2),
('67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2','d4f18138-a2e0-4110-b925-7387d9d0d16d',3);

DO $$
DECLARE v_ctx int; v_ans int; v_orphan int; v_empty int; v_prose int; v_closed int;
  added text[] := ARRAY[
    'e9abe848-ca92-4197-924d-294e7ed92100|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'e9abe848-ca92-4197-924d-294e7ed92100|669cac97-66a6-4087-b036-936fbe62efb3',
    'e9abe848-ca92-4197-924d-294e7ed92100|ba59337e-30e2-4aba-a39a-426b3366eb27',
    'ec923a42-9b27-4f8a-a839-69d6e45c2cf8|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    '67e5e2f0-f5dc-430b-9d7f-8a10e9a5e6a2|d4f18138-a2e0-4110-b925-7387d9d0d16d'];
  -- Irish's two and Silber's Affordable Housing must remain absent
  closed text[] := ARRAY[
    '3113dcf1-5775-46cc-bb55-4881611fbd98|669cac97-66a6-4087-b036-936fbe62efb3',
    '3113dcf1-5775-46cc-bb55-4881611fbd98|d4f18138-a2e0-4110-b925-7387d9d0d16d',
    'ec923a42-9b27-4f8a-a839-69d6e45c2cf8|669cac97-66a6-4087-b036-936fbe62efb3'];
BEGIN
  SELECT count(*) INTO v_ctx FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ctx <> 5 THEN RAISE EXCEPTION 'expected 5 context rows, found %', v_ctx; END IF;
  SELECT count(*) INTO v_ans FROM inform.politician_answers WHERE politician_id::text||'|'||topic_id::text = ANY(added);
  IF v_ans <> 5 THEN RAISE EXCEPTION 'expected 5 answer rows, found %', v_ans; END IF;

  SELECT count(*) INTO v_closed FROM inform.politician_context WHERE politician_id::text||'|'||topic_id::text = ANY(closed);
  IF v_closed <> 0 THEN RAISE EXCEPTION '% deliberately-unrestored rows are present', v_closed; END IF;

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
END $$;

COMMIT;
