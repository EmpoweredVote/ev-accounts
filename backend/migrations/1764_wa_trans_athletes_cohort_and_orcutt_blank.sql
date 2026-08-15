-- 1764_wa_trans_athletes_cohort_and_orcutt_blank.sql
-- 26 rows trans-athletes = 4 (HB 1699, 2025) + 1 documented BLANK (Orcutt / taxes).
--
-- This is the first Republican cohort in the WA sweep. Before it the corpus held 35 Democrats and
-- ZERO Republicans, entirely because the first two instruments read (EHB 1217, HB 2367) were
-- majority-party bills. All 26 HB 1699 sponsors are Republicans and all 26 are seated among the 147.
--
-- ── trans-athletes = 4 ───────────────────────────────────────────────────────────────────────
-- 🔴 THE BILL IS FILED UNDER A EUPHEMISM. Its title is "Defending equity in interscholastic sports"
-- and the topic detector bucketed it under CIVIL-RIGHTS on the word "equity". The operative text is
-- about transgender athletes and belongs on the trans-athletes ladder. A title-driven or
-- keyword-driven pass files this row against the wrong topic entirely.
-- Sec. 2(1): a district or voluntary nonprofit entity "may prohibit biologically male students from
-- competing with and against female students" where the activity is "intended for female students"
-- and is "an individual or team competition activity". Sec. 2(2) resolves a dispute about a student's
-- sex by health-provider verification relying on "reproductive anatomy, genetic makeup, or normal
-- endogenously produced testosterone levels".
-- 🔑 Chair 4 is "require transgender athletes to compete only on teams matching their biological sex
-- assigned at birth" -- the outcome this bill authorises. The neighbours are REFUTED, not merely
-- unproven:
--   · chair 5 ("completely ban all transgender athletes from competing in ANY organized sports") is
--     refuted twice -- the bill reaches only events intended for female students, and it permits a
--     prohibition rather than imposing one.
--   · chair 3 ("separate transgender divisions or case-by-case decisions based on individual
--     circumstances") is refuted: the bill authorises a blanket categorical rule and provides no
--     individual assessment beyond verifying sex.
-- ⚠ THE ONE GENUINE GAP, RECORDED RATHER THAN SMOOTHED OVER: the bill is PERMISSIVE ("may prohibit")
-- where chair 4 says "require". A sponsor could in principle hold "let each district decide", which
-- no chair on this ladder describes. Chair 4 was chosen because the position the bill enables is
-- chair 4's position, and because chair 3 -- the only chair that gestures at discretion -- describes
-- individual case-by-case judgement, which this bill does not create. Operator approved 2026-08-15.
-- ⚠ Screened first: the 26 sponsors touch only three other athletics/sex-classification bills --
-- HB 1148 (sales tax on youth athletic facilities), HB 1868 (athletic trainers in schools) and
-- HB 1629 (inmate placement in correctional facilities). None is a competing trans-athletes
-- instrument, so no member holds a stronger record of their own.
--
-- ── Orcutt / taxes = DOCUMENTED BLANK (context row, no answer) ───────────────────────────────
-- Ed Orcutt is ranking minority member of House Finance and PRIME sponsor of eight tax bills:
-- HB 1374 (cut the state sales tax rate from 6.5 to 6.0 percent), HB 1729 (reduce both parts of the
-- state school levies), HB 2130 and HB 2335 (repeal 2025 tax increases), HB 1375 and HB 1728 (estate
-- tax relief), HB 1373/HB 1397 (local taxes credited against state taxes), HB 2716 (restore a
-- low-income public utility tax credit). His official page says constituents want "more economic
-- opportunity, not more taxes and fees" and "a life that is affordable and free of government
-- intrusion".
-- 🔑 THE DIRECTION IS OVERWHELMING AND THE CHAIR IS STILL NOT EVIDENCED. Chair 4 is "cut taxes for
-- everyone AND scale back public services to match"; chair 5 is "DRASTICALLY cut taxes and shrink
-- government". HB 1374 describes chair 4's first clause exactly. NOTHING in the record describes the
-- second: no instrument pairs a cut with a service reduction, there is no expenditure-limit or
-- government-downsizing bill anywhere in his 69 substantive sponsorships, HB 1729 frames itself as
-- correcting an over-collection back to the level budget writers assumed, and HB 2716 RESTORES a
-- low-income credit. Chair 5's "drastically" is refuted by the same incrementalism.
-- 🔑 This is the SAME STANDARD that seated Fitzgibbon at taxes=2 in migration 1762, applied to the
-- other party. HB 2724 described BOTH halves of chair 2 -- raise on the wealthy, and sec. 1(6) naming
-- existing services as the destination. Orcutt's record describes only half of chair 4. Seating him
-- anyway would be the "least extreme option the reasoning supports" tiebreaker, which is the signal
-- that a row is NOT evidenced. Operator approved the blank 2026-08-15.
-- ⚠ The blank is WRITTEN DOWN rather than left absent so a later pass can tell "researched and not
-- placeable" from "never researched". Its wording is truthful, not regex-shaped: the carve-out is
-- earned by the row actually being unplaceable, not by containing the phrase.
-- 🔴 A THIRD BOILERPLATE TRAP was ruled out here: HB 2335 sec. 403 reads "necessary for the immediate
-- preservation of the public peace, health, or safety, or support of the state government and its
-- existing public institutions". That is Washington's standard emergency clause, NOT a pro-government
-- fiscal position, just as HB 2367's "declaring an emergency" was not a climate emergency (mig 1762).
BEGIN;

CREATE TEMP TABLE ta_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

-- Pre-check: nothing may already exist on these pairs.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Volz already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Volz already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0f598558-61ab-4010-a0fd-e7c54f688a1a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim Walsh already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0f598558-61ab-4010-a0fd-e7c54f688a1a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jim Walsh already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3efc8925-9612-4601-aed5-c05234a5e64d' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rob Chase already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3efc8925-9612-4601-aed5-c05234a5e64d' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rob Chase already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a9a04d0e-04a6-46c2-b8ce-cebfdd272b19' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jenny Graham already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a9a04d0e-04a6-46c2-b8ce-cebfdd272b19' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jenny Graham already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d2a0229f-8825-4374-819e-29d8e4bc8e44' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dan Griffey already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d2a0229f-8825-4374-819e-29d8e4bc8e44' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dan Griffey already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0401d7b9-9f0d-4b92-beed-02bcf2afc456' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Suzanne Schmidt already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0401d7b9-9f0d-4b92-beed-02bcf2afc456' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Suzanne Schmidt already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7a2907ff-b519-41c0-b9fb-9a664fa15750' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: David Stuebe already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7a2907ff-b519-41c0-b9fb-9a664fa15750' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: David Stuebe already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d4e6e041-dc18-4415-9201-1a9bd18dea8b' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tom Dent already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d4e6e041-dc18-4415-9201-1a9bd18dea8b' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tom Dent already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Ed Orcutt already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Ed Orcutt already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Ley already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Ley already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f6a25fa8-ef58-4179-8660-bdb642336f68' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Klicker already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f6a25fa8-ef58-4179-8660-bdb642336f68' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Klicker already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Barkis already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Barkis already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7b5839a9-87c9-4789-bd4e-a85e24a90d6d' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michelle Valdez already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7b5839a9-87c9-4789-bd4e-a85e24a90d6d' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michelle Valdez already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='dc5f89f6-be92-4e3d-960e-3959280765ad' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Peter Abbarno already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='dc5f89f6-be92-4e3d-960e-3959280765ad' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Peter Abbarno already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6f2a7dc4-888d-49a0-be12-a7600d976c87' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Travis Couture already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='6f2a7dc4-888d-49a0-be12-a7600d976c87' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Travis Couture already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7db875e2-7a94-4676-bfef-fd6aec93b7c7' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Marshall already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7db875e2-7a94-4676-bfef-fd6aec93b7c7' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Matt Marshall already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7dec5fff-ab9b-45a5-8acf-ab0feccb2771' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie McClintock already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7dec5fff-ab9b-45a5-8acf-ab0feccb2771' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie McClintock already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b676423d-10a2-451a-88a8-ac80f5117c6a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brian Burnett already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b676423d-10a2-451a-88a8-ac80f5117c6a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brian Burnett already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='62bd22ba-058e-4cf8-bd24-905ced2f727a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Schmick already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='62bd22ba-058e-4cf8-bd24-905ced2f727a' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Schmick already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='bec74bbe-a581-402d-9de2-4a65354500ff' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Dye already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='bec74bbe-a581-402d-9de2-4a65354500ff' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mary Dye already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='43bb35d8-ef11-49cb-9bc7-f16e65cc6534' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cyndy Jacobsen already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='43bb35d8-ef11-49cb-9bc7-f16e65cc6534' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cyndy Jacobsen already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a327c238-cf63-4a27-83f7-cc85468f8742' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Connors already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a327c238-cf63-4a27-83f7-cc85468f8742' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Connors already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='b0ba6ded-89b3-49f4-9aab-8aefea840384' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ybarra already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='b0ba6ded-89b3-49f4-9aab-8aefea840384' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Alex Ybarra already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78c2d2cf-5520-490b-a45f-348baad3c59e' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie Barnard already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78c2d2cf-5520-490b-a45f-348baad3c59e' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Stephanie Barnard already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='20691f72-9abe-40ad-b361-eb804b212e29' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Engell already has a trans-athletes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='20691f72-9abe-40ad-b361-eb804b212e29' AND topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Engell already has a trans-athletes context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Orcutt already has a taxes answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Orcutt already has a taxes context row'; END IF;

  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: trans-athletes chair 4 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Prime sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('0f598558-61ab-4010-a0fd-e7c54f688a1a','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('3efc8925-9612-4601-aed5-c05234a5e64d','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('d2a0229f-8825-4374-819e-29d8e4bc8e44','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('0401d7b9-9f0d-4b92-beed-02bcf2afc456','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('7a2907ff-b519-41c0-b9fb-9a664fa15750','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('d4e6e041-dc18-4415-9201-1a9bd18dea8b','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('642ee2f7-b15b-47b5-b71b-d86670e85e4e','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('f6a25fa8-ef58-4179-8660-bdb642336f68','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('7b5839a9-87c9-4789-bd4e-a85e24a90d6d','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('dc5f89f6-be92-4e3d-960e-3959280765ad','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('6f2a7dc4-888d-49a0-be12-a7600d976c87','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('7db875e2-7a94-4676-bfef-fd6aec93b7c7','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('7dec5fff-ab9b-45a5-8acf-ab0feccb2771','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('b676423d-10a2-451a-88a8-ac80f5117c6a','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('62bd22ba-058e-4cf8-bd24-905ced2f727a','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('bec74bbe-a581-402d-9de2-4a65354500ff','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('43bb35d8-ef11-49cb-9bc7-f16e65cc6534','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('a327c238-cf63-4a27-83f7-cc85468f8742','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('b0ba6ded-89b3-49f4-9aab-8aefea840384','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('78c2d2cf-5520-490b-a45f-348baad3c59e','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('20691f72-9abe-40ad-b361-eb804b212e29','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
 $r$Co-sponsor of HB 1699 (2025), which would let a school district or the state activities association prohibit biologically male students from competing against female students in events intended for female students, and resolve any dispute about a student's sex by a health provider's verification of reproductive anatomy, genetic makeup, or endogenous testosterone. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf']),
('642ee2f7-b15b-47b5-b71b-d86670e85e4e','f7e5678d-dadd-4556-a2fc-446e24642ceb',
 $r$Unable to place on this ladder. Orcutt is ranking minority member of House Finance and prime sponsor of eight tax bills, including cutting the state sales tax rate from 6.5 to 6.0 percent and repealing the 2025 business tax increases, and his official page says voters want "more economic opportunity, not more taxes and fees". That establishes a clear direction, but every chair on this ladder also specifies what happens to public services, and none of his bills says. He has no spending-limit bill, one of his tax bills restores a low-income utility credit, and his school-levy bill describes itself as correcting an over-collection rather than reducing services.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1374.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2335.pdf','http://edorcutt.houserepublicans.wa.gov/']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('0f598558-61ab-4010-a0fd-e7c54f688a1a','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('3efc8925-9612-4601-aed5-c05234a5e64d','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('d2a0229f-8825-4374-819e-29d8e4bc8e44','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('0401d7b9-9f0d-4b92-beed-02bcf2afc456','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('7a2907ff-b519-41c0-b9fb-9a664fa15750','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('d4e6e041-dc18-4415-9201-1a9bd18dea8b','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('642ee2f7-b15b-47b5-b71b-d86670e85e4e','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('f6a25fa8-ef58-4179-8660-bdb642336f68','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('7b5839a9-87c9-4789-bd4e-a85e24a90d6d','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('dc5f89f6-be92-4e3d-960e-3959280765ad','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('6f2a7dc4-888d-49a0-be12-a7600d976c87','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('7db875e2-7a94-4676-bfef-fd6aec93b7c7','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('7dec5fff-ab9b-45a5-8acf-ab0feccb2771','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('b676423d-10a2-451a-88a8-ac80f5117c6a','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('62bd22ba-058e-4cf8-bd24-905ced2f727a','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('bec74bbe-a581-402d-9de2-4a65354500ff','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('43bb35d8-ef11-49cb-9bc7-f16e65cc6534','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('a327c238-cf63-4a27-83f7-cc85468f8742','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('b0ba6ded-89b3-49f4-9aab-8aefea840384','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('78c2d2cf-5520-490b-a45f-348baad3c59e','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4),
('20691f72-9abe-40ad-b361-eb804b212e29','d1618b9c-0b9e-45af-b986-bb33d270b8e4', 4);

-- Guard 1: 26 answers and 27 context rows. The counts DIFFER BY ONE on purpose -- the
-- Orcutt taxes row is a documented blank, which is a context row with NO answer.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM ta_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 26 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +26', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 27 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +27', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: content, not the fact that an INSERT ran.
DO $$
DECLARE bad int; r text; v numeric;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4'
     AND a.politician_id IN ('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','0f598558-61ab-4010-a0fd-e7c54f688a1a','3efc8925-9612-4601-aed5-c05234a5e64d','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d2a0229f-8825-4374-819e-29d8e4bc8e44','0401d7b9-9f0d-4b92-beed-02bcf2afc456','7a2907ff-b519-41c0-b9fb-9a664fa15750','d4e6e041-dc18-4415-9201-1a9bd18dea8b','642ee2f7-b15b-47b5-b71b-d86670e85e4e','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','f6a25fa8-ef58-4179-8660-bdb642336f68','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','dc5f89f6-be92-4e3d-960e-3959280765ad','6f2a7dc4-888d-49a0-be12-a7600d976c87','7db875e2-7a94-4676-bfef-fd6aec93b7c7','7dec5fff-ab9b-45a5-8acf-ab0feccb2771','b676423d-10a2-451a-88a8-ac80f5117c6a','62bd22ba-058e-4cf8-bd24-905ced2f727a','bec74bbe-a581-402d-9de2-4a65354500ff','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','a327c238-cf63-4a27-83f7-cc85468f8742','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','b0ba6ded-89b3-49f4-9aab-8aefea840384','78c2d2cf-5520-490b-a45f-348baad3c59e','20691f72-9abe-40ad-b361-eb804b212e29')
     AND (a.value <> 4
          OR c.reasoning !~ 'intended for female students'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1699.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % trans-athletes row(s) wrong chair, missing the operative clause, or missing source', bad; END IF;

  -- the blank must be a blank: context present, answer ABSENT, and the reasoning must actually say
  -- why rather than merely carrying an exempting phrase
  SELECT count(*) INTO v FROM inform.politician_answers
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF v <> 0 THEN RAISE EXCEPTION 'guard 2: the Orcutt taxes blank has an answer row'; END IF;

  SELECT reasoning INTO r FROM inform.politician_context
   WHERE politician_id='642ee2f7-b15b-47b5-b71b-d86670e85e4e' AND topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb';
  IF r !~ 'Unable to place' THEN RAISE EXCEPTION 'guard 2: blank does not declare itself unplaceable'; END IF;
  IF r !~ 'what happens to public services' THEN
    RAISE EXCEPTION 'guard 2: blank does not state WHY the ladder could not be reached'; END IF;
END $$;

-- Guard 3: gate invariants. ORPHAN_CONTEXT must stay 50 -- the documented blank is exempt because it
-- is genuinely unplaceable, not because of its wording. Predicate copied verbatim from the CI gate.
DO $$
DECLARE orphans int; ans_wo_ctx int; seated int;
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

  SELECT count(*) INTO seated FROM inform.politician_answers
   WHERE topic_id='d1618b9c-0b9e-45af-b986-bb33d270b8e4' AND value=4 AND politician_id IN ('0a9d0edb-50ff-4e71-bb8d-a1a0390cdc55','0f598558-61ab-4010-a0fd-e7c54f688a1a','3efc8925-9612-4601-aed5-c05234a5e64d','a9a04d0e-04a6-46c2-b8ce-cebfdd272b19','d2a0229f-8825-4374-819e-29d8e4bc8e44','0401d7b9-9f0d-4b92-beed-02bcf2afc456','7a2907ff-b519-41c0-b9fb-9a664fa15750','d4e6e041-dc18-4415-9201-1a9bd18dea8b','642ee2f7-b15b-47b5-b71b-d86670e85e4e','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','f6a25fa8-ef58-4179-8660-bdb642336f68','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','dc5f89f6-be92-4e3d-960e-3959280765ad','6f2a7dc4-888d-49a0-be12-a7600d976c87','7db875e2-7a94-4676-bfef-fd6aec93b7c7','7dec5fff-ab9b-45a5-8acf-ab0feccb2771','b676423d-10a2-451a-88a8-ac80f5117c6a','62bd22ba-058e-4cf8-bd24-905ced2f727a','bec74bbe-a581-402d-9de2-4a65354500ff','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','a327c238-cf63-4a27-83f7-cc85468f8742','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','b0ba6ded-89b3-49f4-9aab-8aefea840384','78c2d2cf-5520-490b-a45f-348baad3c59e','20691f72-9abe-40ad-b361-eb804b212e29');
  IF seated <> 26 THEN RAISE EXCEPTION 'guard 3: trans-athletes cohort is %, expected 26', seated; END IF;

  RAISE NOTICE 'trans-athletes=4 x 26; Orcutt taxes recorded as a documented blank; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
