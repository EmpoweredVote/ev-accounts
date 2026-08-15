-- 1768_wa_housing_split.sql
-- 42 rows on housing, SPLIT 10 at chair 1 and 32 at chair 3.
--
-- ── chair 3 (32): HB 1696 ──────────────────────────────────────────────────────────────────────
-- The covenant homeownership programme provides "down payment and closing cost assistance" through
-- special purpose credit programmes. Chair 3 is "offer targeted help like subsidies for affordable
-- projects, FIRST-TIME BUYER ASSISTANCE, and easier building permits" — down payment assistance is
-- that mechanism by name. Chair 4 and 5 are refuted because this is active public help, not
-- deregulation and not staying out.
--
-- 🔑 CHAIR 2 IS NOT MERELY UNPROVEN, IT IS UNREACHABLE FROM THIS BIENNIUM. It requires three things:
-- rent caps, REQUIRING NEW DEVELOPMENTS TO INCLUDE AFFORDABLE UNITS, and publicly funding new
-- housing. Rent caps exist (EHB 1217, already seated on the rent-regulation ladder at chair 2, and
-- 26 of these 42 sponsored it). But an anchored search of all 3,411 bills finds NO inclusionary-
-- zoning instrument at all. The single apparent hit, HB 1357, is "inclusionary practices" in SPECIAL
-- EDUCATION — the fifth substring over-fire in this sweep, after paRENTal, paRENTing, reLEASE and
-- pREPARATION. Chair 2 therefore cannot be evidenced for anyone here, and chair 3 — whose three named
-- mechanisms are ALL present in this cohort's record (buyer assistance HB 1696, subsidies for
-- affordable projects HB 1808/HB 2227, easier permitting HB 1491/HB 1859) — is the fit.
--
-- ── chair 1 (10): HB 1687 ──────────────────────────────────────────────────────────────────────
-- These ten also sponsored the social housing act. It defines "social housing" as "subsidized and
-- cross-subsidized rental housing that is made available to households of ANY INCOME LEVEL,
-- including low-income, moderate-income, and high-income households, and PUBLICLY OWNED IN PERPETUITY
-- by a social housing developer", and amends RCW 35.83 so public development authorities can do it.
-- 🔑 Chair 1 is "directly build and operate public housing so anyone who needs a home can get one".
-- Public ownership in perpetuity is the "public housing" half; availability to households of any
-- income level rather than only the poorest is the "anyone who needs a home" half. That combination
-- is what separates chair 1 from chair 3's targeted, means-tested help.
-- ⚠ THE HONEST WEAKNESS, RECORDED. HB 1687 is an ENABLING statute — it authorises social housing
-- developers and defines what they may own; it is not itself a construction programme, and "available
-- to any income level" is a statement about eligibility rather than a guarantee of sufficient supply.
-- A reader who thinks chair 1 requires the state actually building at scale should revisit these ten
-- rows. They are the only ten in the cohort where the question arises.
-- ⚠ Not a breach of the cohort rule: HB 1696 sets chair 3 as the floor for all 42 of its sponsors,
-- and HB 1687 raises it for the ten who also signed that. One instrument still seats its own
-- co-sponsors identically — the same structure as migration 1766's SB 5002 split.
BEGIN;

CREATE TEMP TABLE hs_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7a0da48f-2c29-463e-969a-52d06137cde9' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chipalo Street already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='67b9aaf1-46eb-471f-8f31-dcf501a92933' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julia Reed already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='56d6dd6f-4959-4339-be78-e4b1d0083b08' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Berry already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='edc48d7e-4f91-4e59-af50-79f34df8b011' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mia Gregerson already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='22d959a5-ec5f-4b92-98d3-85dc219c2c61' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Nicole Macri already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='34ff9b7a-decc-4b21-8f6d-339957ab60bf' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shaun Scott already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6341053d-0580-4fbf-85ea-71ddb6b6f838' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Strom Peterson already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6341053d-0580-4fbf-85ea-71ddb6b6f838' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Strom Peterson already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f68a7024-846d-4383-a34e-a21df06b2314' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adam Bernbaum already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f68a7024-846d-4383-a34e-a21df06b2314' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adam Bernbaum already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='41ef42e8-fe56-4f82-92e7-eefe85232cd2' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ramel already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='be3c2a24-1576-4636-9374-18fc77a8513f' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Amy Walen already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='be3c2a24-1576-4636-9374-18fc77a8513f' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Amy Walen already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ec9da15f-7d79-42bc-a368-da3ab0855ddf' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Berg already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ec9da15f-7d79-42bc-a368-da3ab0855ddf' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Berg already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='40ae39e3-8e86-46a5-b660-96b46a3e6c02' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brandy Donaghy already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='40ae39e3-8e86-46a5-b660-96b46a3e6c02' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brandy Donaghy already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c88a915a-6613-4940-a12d-18a28b00935c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brianna Thomas already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c88a915a-6613-4940-a12d-18a28b00935c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brianna Thomas already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Stearns already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Stearns already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='86e6a2bf-5216-4022-900c-621a8480f2e7' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cindy Ryu already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='86e6a2bf-5216-4022-900c-621a8480f2e7' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cindy Ryu already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f3daea18-1a32-486f-b8df-659d7c653c05' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Davina Duerr already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='628a26a2-bcb9-4e87-a29f-ac5f6b381a37' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Debra Entenman already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='628a26a2-bcb9-4e87-a29f-ac5f6b381a37' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Debra Entenman already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='97b47446-b0ee-4a2c-b4fe-ec8a995356ea' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jake Fey already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='97b47446-b0ee-4a2c-b4fe-ec8a995356ea' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jake Fey already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='da15c353-3744-4dd3-a6ed-c4b6e89752e1' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamila Taylor already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='da15c353-3744-4dd3-a6ed-c4b6e89752e1' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamila Taylor already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a961a076-f7be-436f-881f-155a0e9e687c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Janice Zahn already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a961a076-f7be-436f-881f-155a0e9e687c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Janice Zahn already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='805fd55e-2e38-43b1-8b9d-a757af05f8e4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Julio Cortes already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kristine Reeves already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kristine Reeves already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ae61e4af-16a8-44d6-933a-c4826882e103' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Larry Springer already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ae61e4af-16a8-44d6-933a-c4826882e103' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Larry Springer already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d97bcc03-4c74-4c9d-9e0f-13ae551ed54c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lillian Ortiz-Self already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d97bcc03-4c74-4c9d-9e0f-13ae551ed54c' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lillian Ortiz-Self already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7b992556-5e0d-488a-92f7-942ab56660c1' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mari Leavitt already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7b992556-5e0d-488a-92f7-942ab56660c1' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mari Leavitt already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e36107af-ea8f-4fca-a727-0e37ca2f6fd4' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Fosse already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='e3e2c4be-bc12-43c3-9e86-4ba229d44346' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Monica Jurado Stonier already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='e3e2c4be-bc12-43c3-9e86-4ba229d44346' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Monica Jurado Stonier already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Osman Salahuddin already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Osman Salahuddin already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Roger Goodman already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Roger Goodman already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='363fe07c-171e-4044-b6f9-979662962027' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharlett Mena already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d5c6e6e4-c474-41fa-ab96-bd237c8ff4de' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Tomiko Santos already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d5c6e6e4-c474-41fa-ab96-bd237c8ff4de' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Tomiko Santos already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b918fb31-108f-49e7-b977-627ce667422d' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Shelley Kloba already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f4f7acdf-1761-4cac-82e6-19bf8f6ea525' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Bergquist already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f4f7acdf-1761-4cac-82e6-19bf8f6ea525' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Bergquist already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2ffd9e47-b0f1-428f-9164-01025dd34310' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Victoria Hunt already has a housing answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2ffd9e47-b0f1-428f-9164-01025dd34310' AND topic_id='669cac97-66a6-4087-b036-936fbe62efb3';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Victoria Hunt already has a housing context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND value=1;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: housing chair 1 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: housing chair 3 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('7a0da48f-2c29-463e-969a-52d06137cde9','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Prime sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('30fdeba0-e9d3-414d-859f-2941140d8e80','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('edc48d7e-4f91-4e59-af50-79f34df8b011','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('370f9462-ed1d-4a83-b244-8bb593038444','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1687 (Chapter law, 2025), which amends the housing authorities law to enable social housing public development authorities. It defines social housing as rental housing "made available to households of any income level" and "publicly owned in perpetuity by a social housing developer"; and of HB 1696, which expands the covenant homeownership programme's down payment and closing cost assistance and adds loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('f68a7024-846d-4383-a34e-a21df06b2314','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('be3c2a24-1576-4636-9374-18fc77a8513f','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('45737b89-a83b-421f-9d6c-abc829c7eae0','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('40ae39e3-8e86-46a5-b660-96b46a3e6c02','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('c88a915a-6613-4940-a12d-18a28b00935c','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('86e6a2bf-5216-4022-900c-621a8480f2e7','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('f3daea18-1a32-486f-b8df-659d7c653c05','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('628a26a2-bcb9-4e87-a29f-ac5f6b381a37','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('73ad3771-798c-4855-a467-7c6269bca5fc','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('463c9085-ff29-45f4-88b0-fe3be9693a36','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('97b47446-b0ee-4a2c-b4fe-ec8a995356ea','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('da15c353-3744-4dd3-a6ed-c4b6e89752e1','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Prime sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('a961a076-f7be-436f-881f-155a0e9e687c','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('cf992e89-7b96-46f3-9999-58432c690fe4','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('ae61e4af-16a8-44d6-933a-c4826882e103','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('7b992556-5e0d-488a-92f7-942ab56660c1','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('e3e2c4be-bc12-43c3-9e86-4ba229d44346','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('4b5055b4-2ed1-4894-acae-0e1465159564','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('de6d7929-66dd-4166-998a-479cfa264ce5','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('363fe07c-171e-4044-b6f9-979662962027','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('b918fb31-108f-49e7-b977-627ce667422d','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('f4f7acdf-1761-4cac-82e6-19bf8f6ea525','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']),
('2ffd9e47-b0f1-428f-9164-01025dd34310','669cac97-66a6-4087-b036-936fbe62efb3',
 $r$Co-sponsor of HB 1696 (2025-26), which expands Washington's covenant homeownership programme — special purpose credit programmes providing "down payment and closing cost assistance" to reduce racial disparities in homeownership — by loosening the income threshold and adding loan forgiveness.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('7a0da48f-2c29-463e-969a-52d06137cde9','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('67b9aaf1-46eb-471f-8f31-dcf501a92933','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('30fdeba0-e9d3-414d-859f-2941140d8e80','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('56d6dd6f-4959-4339-be78-e4b1d0083b08','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('edc48d7e-4f91-4e59-af50-79f34df8b011','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('22d959a5-ec5f-4b92-98d3-85dc219c2c61','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('34ff9b7a-decc-4b21-8f6d-339957ab60bf','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('370f9462-ed1d-4a83-b244-8bb593038444','669cac97-66a6-4087-b036-936fbe62efb3', 1),
('f68a7024-846d-4383-a34e-a21df06b2314','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('41ef42e8-fe56-4f82-92e7-eefe85232cd2','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('be3c2a24-1576-4636-9374-18fc77a8513f','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('45737b89-a83b-421f-9d6c-abc829c7eae0','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('40ae39e3-8e86-46a5-b660-96b46a3e6c02','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('c88a915a-6613-4940-a12d-18a28b00935c','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('86e6a2bf-5216-4022-900c-621a8480f2e7','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('f3daea18-1a32-486f-b8df-659d7c653c05','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('628a26a2-bcb9-4e87-a29f-ac5f6b381a37','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('73ad3771-798c-4855-a467-7c6269bca5fc','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('fab8170e-a747-41de-ad39-769d8e0dd901','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('463c9085-ff29-45f4-88b0-fe3be9693a36','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('97b47446-b0ee-4a2c-b4fe-ec8a995356ea','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('da15c353-3744-4dd3-a6ed-c4b6e89752e1','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('a961a076-f7be-436f-881f-155a0e9e687c','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('805fd55e-2e38-43b1-8b9d-a757af05f8e4','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('cf992e89-7b96-46f3-9999-58432c690fe4','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('ae61e4af-16a8-44d6-933a-c4826882e103','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('7b992556-5e0d-488a-92f7-942ab56660c1','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('e36107af-ea8f-4fca-a727-0e37ca2f6fd4','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('e3e2c4be-bc12-43c3-9e86-4ba229d44346','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('4b5055b4-2ed1-4894-acae-0e1465159564','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('de6d7929-66dd-4166-998a-479cfa264ce5','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('363fe07c-171e-4044-b6f9-979662962027','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('b918fb31-108f-49e7-b977-627ce667422d','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('f4f7acdf-1761-4cac-82e6-19bf8f6ea525','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','669cac97-66a6-4087-b036-936fbe62efb3', 3),
('2ffd9e47-b0f1-428f-9164-01025dd34310','669cac97-66a6-4087-b036-936fbe62efb3', 3);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM hs_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 42 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +42', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 42 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +42', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c1 int; c3 int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND a.politician_id IN ('7a0da48f-2c29-463e-969a-52d06137cde9','67b9aaf1-46eb-471f-8f31-dcf501a92933','30fdeba0-e9d3-414d-859f-2941140d8e80','56d6dd6f-4959-4339-be78-e4b1d0083b08','edc48d7e-4f91-4e59-af50-79f34df8b011','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','22d959a5-ec5f-4b92-98d3-85dc219c2c61','34ff9b7a-decc-4b21-8f6d-339957ab60bf','6341053d-0580-4fbf-85ea-71ddb6b6f838','370f9462-ed1d-4a83-b244-8bb593038444')
     AND (a.value <> 1
          OR c.reasoning !~ 'publicly owned in perpetuity'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/1687.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-1 row(s) wrong chair, missing the public-ownership clause, or missing HB 1687', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND a.politician_id IN ('f68a7024-846d-4383-a34e-a21df06b2314','41ef42e8-fe56-4f82-92e7-eefe85232cd2','be3c2a24-1576-4636-9374-18fc77a8513f','ec9da15f-7d79-42bc-a368-da3ab0855ddf','45737b89-a83b-421f-9d6c-abc829c7eae0','40ae39e3-8e86-46a5-b660-96b46a3e6c02','c88a915a-6613-4940-a12d-18a28b00935c','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','86e6a2bf-5216-4022-900c-621a8480f2e7','f3daea18-1a32-486f-b8df-659d7c653c05','628a26a2-bcb9-4e87-a29f-ac5f6b381a37','73ad3771-798c-4855-a467-7c6269bca5fc','fab8170e-a747-41de-ad39-769d8e0dd901','463c9085-ff29-45f4-88b0-fe3be9693a36','97b47446-b0ee-4a2c-b4fe-ec8a995356ea','da15c353-3744-4dd3-a6ed-c4b6e89752e1','a961a076-f7be-436f-881f-155a0e9e687c','805fd55e-2e38-43b1-8b9d-a757af05f8e4','cf992e89-7b96-46f3-9999-58432c690fe4','ae61e4af-16a8-44d6-933a-c4826882e103','d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','7b992556-5e0d-488a-92f7-942ab56660c1','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','e3e2c4be-bc12-43c3-9e86-4ba229d44346','4b5055b4-2ed1-4894-acae-0e1465159564','de6d7929-66dd-4166-998a-479cfa264ce5','363fe07c-171e-4044-b6f9-979662962027','d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','b918fb31-108f-49e7-b977-627ce667422d','f4f7acdf-1761-4cac-82e6-19bf8f6ea525','945d0b44-3329-46b2-a39e-47f5fdddc6ed','2ffd9e47-b0f1-428f-9164-01025dd34310')
     AND (a.value <> 3
          OR c.reasoning !~ 'down payment and closing cost assistance'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1696.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-3 row(s) wrong chair, missing the buyer-assistance clause, or missing HB 1696', bad; END IF;

  SELECT count(*) INTO c1 FROM inform.politician_answers WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND value=1 AND politician_id IN ('7a0da48f-2c29-463e-969a-52d06137cde9','67b9aaf1-46eb-471f-8f31-dcf501a92933','30fdeba0-e9d3-414d-859f-2941140d8e80','56d6dd6f-4959-4339-be78-e4b1d0083b08','edc48d7e-4f91-4e59-af50-79f34df8b011','165640fd-99e3-4e1e-bd73-8df36e4ac1d6','22d959a5-ec5f-4b92-98d3-85dc219c2c61','34ff9b7a-decc-4b21-8f6d-339957ab60bf','6341053d-0580-4fbf-85ea-71ddb6b6f838','370f9462-ed1d-4a83-b244-8bb593038444');
  SELECT count(*) INTO c3 FROM inform.politician_answers WHERE topic_id='669cac97-66a6-4087-b036-936fbe62efb3' AND value=3 AND politician_id IN ('f68a7024-846d-4383-a34e-a21df06b2314','41ef42e8-fe56-4f82-92e7-eefe85232cd2','be3c2a24-1576-4636-9374-18fc77a8513f','ec9da15f-7d79-42bc-a368-da3ab0855ddf','45737b89-a83b-421f-9d6c-abc829c7eae0','40ae39e3-8e86-46a5-b660-96b46a3e6c02','c88a915a-6613-4940-a12d-18a28b00935c','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','86e6a2bf-5216-4022-900c-621a8480f2e7','f3daea18-1a32-486f-b8df-659d7c653c05','628a26a2-bcb9-4e87-a29f-ac5f6b381a37','73ad3771-798c-4855-a467-7c6269bca5fc','fab8170e-a747-41de-ad39-769d8e0dd901','463c9085-ff29-45f4-88b0-fe3be9693a36','97b47446-b0ee-4a2c-b4fe-ec8a995356ea','da15c353-3744-4dd3-a6ed-c4b6e89752e1','a961a076-f7be-436f-881f-155a0e9e687c','805fd55e-2e38-43b1-8b9d-a757af05f8e4','cf992e89-7b96-46f3-9999-58432c690fe4','ae61e4af-16a8-44d6-933a-c4826882e103','d97bcc03-4c74-4c9d-9e0f-13ae551ed54c','7b992556-5e0d-488a-92f7-942ab56660c1','e36107af-ea8f-4fca-a727-0e37ca2f6fd4','e3e2c4be-bc12-43c3-9e86-4ba229d44346','4b5055b4-2ed1-4894-acae-0e1465159564','de6d7929-66dd-4166-998a-479cfa264ce5','363fe07c-171e-4044-b6f9-979662962027','d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','b918fb31-108f-49e7-b977-627ce667422d','f4f7acdf-1761-4cac-82e6-19bf8f6ea525','945d0b44-3329-46b2-a39e-47f5fdddc6ed','2ffd9e47-b0f1-428f-9164-01025dd34310');
  IF c1 <> 10 THEN RAISE EXCEPTION 'guard 2: chair-1 count is %, expected 10', c1; END IF;
  IF c3 <> 32 THEN RAISE EXCEPTION 'guard 2: chair-3 count is %, expected 32', c3; END IF;
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

  RAISE NOTICE 'housing: 10 at chair 1, 32 at chair 3; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
