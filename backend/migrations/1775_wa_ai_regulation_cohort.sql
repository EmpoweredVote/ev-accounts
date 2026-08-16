-- 1775_wa_ai_regulation_cohort.sql
-- 31 rows on `ai-regulation` at chair 3, from HB 2225 (AI companion chatbots, Callan D-5 prime, by
-- request of the Governor). A House Democratic instrument, the last untouched bloc: after migration
-- 1774 the 25 uncovered were 11 Senate R, 8 House D, 3 House R and 3 Senate D.
--
-- ⚠ READ CHAIR 1 FIRST — THIS LADDER RUNS BACKWARDS. Chair 1 is "allow AI companies to develop and
-- deploy technology freely without government interference" and chair 5 is the ban. The
-- pro-regulation position is at the HIGH end, the opposite of most ladders in the corpus, and a
-- left-to-right reading of it produces exactly inverted rows.
--
-- ── why chair 3 ──────────────────────────────────────────────────────────────────────────────────
-- Chair 3 is "require AI developers to DISCLOSE RISKS and be HELD RESPONSIBLE when their systems
-- cause harm" — two limbs, and HB 2225 enacts both in operative text:
--   · disclosure — §3 and §4 require the "artificially generated and not human" notice at the start of
--     an interaction, every three hours, and at each new session; §5(3) requires the operator to
--     publish its self-harm safeguards and the number of crisis referrals issued in the prior year;
--   · responsibility — §7 declares a violation an unfair practice under the consumer protection act,
--     which is a private right of action plus attorney general enforcement, not a regulatory wrist-slap.
-- The other four chairs are refuted from the text:
--   · chair 1 (free development) and chair 2 ("SUGGEST AI safety guidelines but let companies CHOOSE
--     whether to follow them") — every duty here is mandatory: the operator "shall", and "may not make
--     available or deploy" a chatbot without a self-harm protocol;
--   · chair 4 ("require SAFETY TESTING and BAN high-risk AI uses in areas like hiring, healthcare, and
--     policing") — the act mandates no testing regime and bans no use; it regulates one product class
--     and does not touch hiring, healthcare or policing;
--   · chair 5 ("impose strict APPROVAL requirements") — there is no approval regime; §6 expressly
--     exempts general purpose models unless deployed as a companion.
--
-- ── per-member screen: 3 flagged, all read, nobody moved — and the reason is worth keeping ───────
-- 🔑 A COMPREHENSIVE HIGH-RISK AI FRAMEWORK IS STILL CHAIR 3, because chair 4 requires a BAN.
--   · Ryu's HB 2157 ("regulating high-risk artificial intelligence system development, deployment,
--     and use") and Shavers' HB 2667 ("consumer protections for artificial intelligence systems") both
--     build economy-wide duties against algorithmic discrimination in consequential decisions. Neither
--     PROHIBITS a use. HB 2667 §1 says the intent is a framework that "continues to promote
--     innovation" through "a comprehensive risk-based approach to artificial intelligence
--     accountability" — accountability, which is chair 3's second limb, at a wider scope.
--   · Shavers also holds HB 1170 (enacted — informing users when content is AI-generated) and HB 1168
--     (increasing transparency), both pure chair 3 disclosure. Parshley's HB 1622 is a collective
--     bargaining bill about AI at work and reaches no chair on this ladder.
-- Scope, not chair, is what separates these instruments, and this ladder has no scope axis.
--
-- ⚠ Note the cohort is not uniform by party — Eslick (R) co-sponsored — and it is a Governor-request
-- bill, which is why it is broad. Chair 3 applies to every sponsor alike under the cohort rule.
BEGIN;

CREATE TEMP TABLE ai_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0265efd8-29c9-46b4-b408-7da40b455257' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alicia Rule already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0265efd8-29c9-46b4-b408-7da40b455257' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alicia Rule already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c88a915a-6613-4940-a12d-18a28b00935c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brianna Thomas already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c88a915a-6613-4940-a12d-18a28b00935c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brianna Thomas already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e1538de2-4e22-44cc-a50f-02fe7e2e9f2e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Carolyn Eslick already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e1538de2-4e22-44cc-a50f-02fe7e2e9f2e' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Carolyn Eslick already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Stearns already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Stearns already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='86e6a2bf-5216-4022-900c-621a8480f2e7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cindy Ryu already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='86e6a2bf-5216-4022-900c-621a8480f2e7' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cindy Ryu already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='721bf21e-7913-431b-9807-037561f18b82' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Clyde Shavers already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='721bf21e-7913-431b-9807-037561f18b82' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Clyde Shavers already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78726dd6-5ce2-40d4-9cf6-10fc6a840756' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dave Paul already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78726dd6-5ce2-40d4-9cf6-10fc6a840756' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dave Paul already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a961a076-f7be-436f-881f-155a0e9e687c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Janice Zahn already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a961a076-f7be-436f-881f-155a0e9e687c' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Janice Zahn already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kristine Reeves already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kristine Reeves already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Callan already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Callan already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7b992556-5e0d-488a-92f7-942ab56660c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mari Leavitt already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7b992556-5e0d-488a-92f7-942ab56660c1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mari Leavitt already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: My-Linh Thai already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: My-Linh Thai already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Osman Salahuddin already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Osman Salahuddin already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Roger Goodman already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Roger Goodman already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Wylie already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Wylie already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has an ai-regulation answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='666bf03d-81fc-4138-ab15-69ae734c9023';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has an ai-regulation context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: ai-regulation chair 3 not defined exactly once (%)', n; END IF;
  -- the reversed-ladder tripwire: chair 1 must still be the FREE-DEVELOPMENT end. If someone reorders
  -- this ladder, these rows mean the opposite of what they were written to mean.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND value=1 AND text ILIKE '%freely without government interference%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: ai-regulation chair 1 is no longer the free-development end — re-read before seating'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('0265efd8-29c9-46b4-b408-7da40b455257','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('c88a915a-6613-4940-a12d-18a28b00935c','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('7a0da48f-2c29-463e-969a-52d06137cde9','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('86e6a2bf-5216-4022-900c-621a8480f2e7','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('721bf21e-7913-431b-9807-037561f18b82','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('78726dd6-5ce2-40d4-9cf6-10fc6a840756','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('f3daea18-1a32-486f-b8df-659d7c653c05','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('a961a076-f7be-436f-881f-155a0e9e687c','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('cf992e89-7b96-46f3-9999-58432c690fe4','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Prime sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('30fdeba0-e9d3-414d-859f-2941140d8e80','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('7b992556-5e0d-488a-92f7-942ab56660c1','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('edc48d7e-4f91-4e59-af50-79f34df8b011','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('1963d6e9-069b-4770-9489-59e36faaa2e1','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('4b5055b4-2ed1-4894-acae-0e1465159564','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('de6d7929-66dd-4166-998a-479cfa264ce5','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('363fe07c-171e-4044-b6f9-979662962027','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('5617115e-78d5-4480-9534-aa337612a285','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('b918fb31-108f-49e7-b977-627ce667422d','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('370f9462-ed1d-4a83-b244-8bb593038444','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','666bf03d-81fc-4138-ab15-69ae734c9023',
 $r$Co-sponsor of HB 2225 (2026), which regulates AI companion chatbots: an operator must give a "clear and conspicuous notification indicating that the companion chatbot is artificially generated and not human" at the start of an interaction, every three hours, and at each new session; may not deploy one at all unless it maintains a protocol for detecting and referring expressions of suicidal ideation or self-harm; and must publicly disclose those safeguards and the number of crisis referrals issued each year. Section 7 makes a violation an unfair practice under the consumer protection act, chapter 19.86 RCW.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('0265efd8-29c9-46b4-b408-7da40b455257','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('c88a915a-6613-4940-a12d-18a28b00935c','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('7a0da48f-2c29-463e-969a-52d06137cde9','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('86e6a2bf-5216-4022-900c-621a8480f2e7','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('721bf21e-7913-431b-9807-037561f18b82','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('78726dd6-5ce2-40d4-9cf6-10fc6a840756','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('f3daea18-1a32-486f-b8df-659d7c653c05','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('fab8170e-a747-41de-ad39-769d8e0dd901','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('a961a076-f7be-436f-881f-155a0e9e687c','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('cf992e89-7b96-46f3-9999-58432c690fe4','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('30fdeba0-e9d3-414d-859f-2941140d8e80','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('7b992556-5e0d-488a-92f7-942ab56660c1','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('edc48d7e-4f91-4e59-af50-79f34df8b011','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('1963d6e9-069b-4770-9489-59e36faaa2e1','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('4b5055b4-2ed1-4894-acae-0e1465159564','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('de6d7929-66dd-4166-998a-479cfa264ce5','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('363fe07c-171e-4044-b6f9-979662962027','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('5617115e-78d5-4480-9534-aa337612a285','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('b918fb31-108f-49e7-b977-627ce667422d','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('370f9462-ed1d-4a83-b244-8bb593038444','666bf03d-81fc-4138-ab15-69ae734c9023', 3),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','666bf03d-81fc-4138-ab15-69ae734c9023', 3);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM ai_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 31 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +31', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 31 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +31', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c3 int; primes int;
BEGIN
  -- content: both limbs of chair 3 must be in the reasoning, plus the source.
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND a.politician_id IN ('0265efd8-29c9-46b4-b408-7da40b455257','c88a915a-6613-4940-a12d-18a28b00935c','e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','7a0da48f-2c29-463e-969a-52d06137cde9','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','86e6a2bf-5216-4022-900c-621a8480f2e7','721bf21e-7913-431b-9807-037561f18b82','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f3daea18-1a32-486f-b8df-659d7c653c05','fab8170e-a747-41de-ad39-769d8e0dd901','a961a076-f7be-436f-881f-155a0e9e687c','67b9aaf1-46eb-471f-8f31-dcf501a92933','805fd55e-2e38-43b1-8b9d-a757af05f8e4','cf992e89-7b96-46f3-9999-58432c690fe4','e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','30fdeba0-e9d3-414d-859f-2941140d8e80','56d6dd6f-4959-4339-be78-e4b1d0083b08','7b992556-5e0d-488a-92f7-942ab56660c1','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','edc48d7e-4f91-4e59-af50-79f34df8b011','1963d6e9-069b-4770-9489-59e36faaa2e1','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','22d959a5-ec5f-4b92-98d3-85dc219c2c61','4b5055b4-2ed1-4894-acae-0e1465159564','de6d7929-66dd-4166-998a-479cfa264ce5','363fe07c-171e-4044-b6f9-979662962027','5617115e-78d5-4480-9534-aa337612a285','34ff9b7a-decc-4b21-8f6d-339957ab60bf','b918fb31-108f-49e7-b977-627ce667422d','370f9462-ed1d-4a83-b244-8bb593038444','945d0b44-3329-46b2-a39e-47f5fdddc6ed')
     AND (a.value <> 3
          OR c.reasoning !~ 'artificially generated and not human'
          OR c.reasoning !~ 'consumer protection act'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2225.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing the disclosure or liability limb, or missing HB 2225', bad; END IF;

  SELECT count(*) INTO c3 FROM inform.politician_answers
   WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND value=3 AND politician_id IN ('0265efd8-29c9-46b4-b408-7da40b455257','c88a915a-6613-4940-a12d-18a28b00935c','e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','7a0da48f-2c29-463e-969a-52d06137cde9','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','86e6a2bf-5216-4022-900c-621a8480f2e7','721bf21e-7913-431b-9807-037561f18b82','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f3daea18-1a32-486f-b8df-659d7c653c05','fab8170e-a747-41de-ad39-769d8e0dd901','a961a076-f7be-436f-881f-155a0e9e687c','67b9aaf1-46eb-471f-8f31-dcf501a92933','805fd55e-2e38-43b1-8b9d-a757af05f8e4','cf992e89-7b96-46f3-9999-58432c690fe4','e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','30fdeba0-e9d3-414d-859f-2941140d8e80','56d6dd6f-4959-4339-be78-e4b1d0083b08','7b992556-5e0d-488a-92f7-942ab56660c1','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','edc48d7e-4f91-4e59-af50-79f34df8b011','1963d6e9-069b-4770-9489-59e36faaa2e1','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','22d959a5-ec5f-4b92-98d3-85dc219c2c61','4b5055b4-2ed1-4894-acae-0e1465159564','de6d7929-66dd-4166-998a-479cfa264ce5','363fe07c-171e-4044-b6f9-979662962027','5617115e-78d5-4480-9534-aa337612a285','34ff9b7a-decc-4b21-8f6d-339957ab60bf','b918fb31-108f-49e7-b977-627ce667422d','370f9462-ed1d-4a83-b244-8bb593038444','945d0b44-3329-46b2-a39e-47f5fdddc6ed');
  IF c3 <> 31 THEN RAISE EXCEPTION 'guard 2: chair-3 count is %, expected 31', c3; END IF;

  SELECT count(*) INTO primes FROM inform.politician_context
   WHERE topic_id='666bf03d-81fc-4138-ab15-69ae734c9023' AND politician_id IN ('0265efd8-29c9-46b4-b408-7da40b455257','c88a915a-6613-4940-a12d-18a28b00935c','e1538de2-4e22-44cc-a50f-02fe7e2e9f2e','7a0da48f-2c29-463e-969a-52d06137cde9','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','86e6a2bf-5216-4022-900c-621a8480f2e7','721bf21e-7913-431b-9807-037561f18b82','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f3daea18-1a32-486f-b8df-659d7c653c05','fab8170e-a747-41de-ad39-769d8e0dd901','a961a076-f7be-436f-881f-155a0e9e687c','67b9aaf1-46eb-471f-8f31-dcf501a92933','805fd55e-2e38-43b1-8b9d-a757af05f8e4','cf992e89-7b96-46f3-9999-58432c690fe4','e3a93cc4-a4ee-4e4f-8a67-c9a0c5c66efb','30fdeba0-e9d3-414d-859f-2941140d8e80','56d6dd6f-4959-4339-be78-e4b1d0083b08','7b992556-5e0d-488a-92f7-942ab56660c1','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','edc48d7e-4f91-4e59-af50-79f34df8b011','1963d6e9-069b-4770-9489-59e36faaa2e1','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','22d959a5-ec5f-4b92-98d3-85dc219c2c61','4b5055b4-2ed1-4894-acae-0e1465159564','de6d7929-66dd-4166-998a-479cfa264ce5','363fe07c-171e-4044-b6f9-979662962027','5617115e-78d5-4480-9534-aa337612a285','34ff9b7a-decc-4b21-8f6d-339957ab60bf','b918fb31-108f-49e7-b977-627ce667422d','370f9462-ed1d-4a83-b244-8bb593038444','945d0b44-3329-46b2-a39e-47f5fdddc6ed') AND reasoning LIKE 'Prime sponsor of %';
  IF primes <> 1 THEN RAISE EXCEPTION 'guard 2: % prime-sponsor row(s), expected 1', primes; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'ai-regulation: 31 at chair 3 from HB 2225; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
