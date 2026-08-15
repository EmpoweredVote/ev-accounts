-- 1767_wa_abortion_split.sql
-- 9 rows abortion = 1, plus 18 DOCUMENTED BLANKS. 27 context rows, 9 answers.
--
-- 🔴 THIS LADDER CANNOT DESCRIBE WASHINGTON'S ACTUAL POSITION, AND THAT IS WHY 18 ROWS ARE BLANK.
-- SJR 8204 has 27 seated sponsors -- more than half the Senate -- and would write into the state
-- constitution a "fundamental right to choose to have an abortion" which the state "shall not deny or
-- interfere with", with NO limit by stage of pregnancy. That single fact refutes chairs 2 through 5
-- for every one of the 27: each of them imposes a gestational limit or a restriction these members
-- demonstrably do not hold. Chair 2 in particular ("through the second trimester with rare exceptions
-- afterward") does not describe a softer version of their position -- it describes a DIFFERENT one.
-- So the fallback for an unproven chair 1 here is a blank, NOT the next chair along.
--
-- 🔑 CHAIR 1 HAS THREE ELEMENTS AND SJR 8204 SUPPLIES ONLY TWO. It is "ensure abortion is legal,
-- ACCESSIBLE, AND PUBLICLY FUNDED at all stages of pregnancy". SJR 8204 is a NEGATIVE right -- the
-- state shall not deny or interfere -- and is explicitly not a funding guarantee. Legality and
-- accessibility at all stages: yes. Public funding: not addressed.
--
-- ── the 9 seated at chair 1 ───────────────────────────────────────────────────────────────
-- These nine also sponsored SB 6182, which supplies the missing element outright. Sec. 2(1)
-- establishes the abortion savings programme "to provide grants to maintain access to direct patient
-- abortion clinical care services for individuals in the state", and sec. 2(2) directs the grants at
-- services "for which federal funding is prohibited for individuals without sufficient resources" --
-- i.e. state money filling the gap federal funding will not cover. It is funded by a per-coverage-
-- month assessment on health carriers paid to the state treasurer (sec. 1), so it is public money,
-- and it carries NO gestational limit. Legal + accessible + publicly funded, all stages. Chair 1.
--
-- ── the 18 documented blanks ──────────────────────────────────────────────────────────────
-- ⚠ FIFTEEN OF THE EIGHTEEN ARE NOT EMPTY-HANDED, AND THE BLANK IS STILL RIGHT. They sponsored
-- SB 5321 or SB 5826, which require public postsecondary student health centres to provide MEDICATION
-- abortion and whose findings declare that "Access to abortion is a human right, an integral part of
-- essential health care". That is genuine public provision, and it was weighed. It fails chair 1 on
-- the words "AT ALL STAGES": medication abortion reaches roughly the first ten weeks, so it does not
-- evidence funding across pregnancy. Seating them at chair 1 anyway would be reading the direction of
-- their record rather than the text of the chair.
-- ⚠ The remaining three -- Cortes, Kauffman and Robinson -- hold SJR 8204 alone.
-- 🔑 The blanks are WRITTEN DOWN, with sources, so a later pass can tell "researched, ladder cannot
-- reach it" from "never researched". Each names the instrument that was read and the clause that
-- failed. The wording earns the ORPHAN_CONTEXT carve-out by being true, not by matching a regex.
--
-- ⚠ Ramos appears on SJR 8204 and is deliberately absent here: he served during the biennium but is
-- not among the seated 147, so the cohort is 27 of 28 sponsors.
BEGIN;

CREATE TEMP TABLE ab_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5a36591c-66c5-4cb1-b99d-d7fc7fa93b25' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Emily Alvarado already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mike Chapman already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7535e225-d3d0-40ca-ba9c-3890563c40a0' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tina Orwall already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7535e225-d3d0-40ca-ba9c-3890563c40a0' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tina Orwall already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f8feca06-c2bb-4ec8-ad85-0989559912e9' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adrian Cortes already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f8feca06-c2bb-4ec8-ad85-0989559912e9' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adrian Cortes already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='14332488-3986-4e86-abc2-666b7a3f2dd5' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Annette Cleveland already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='14332488-3986-4e86-abc2-666b7a3f2dd5' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Annette Cleveland already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4042de49-5bea-413c-aecd-9abbe742a9a2' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claudia Kauffman already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4042de49-5bea-413c-aecd-9abbe742a9a2' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claudia Kauffman already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deborah Krishnadasan already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deborah Krishnadasan already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='47ac1908-3715-4599-82f6-606aaf2d9fe6' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Lovick already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='47ac1908-3715-4599-82f6-606aaf2d9fe6' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Lovick already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7ac92b63-d489-45d5-a85f-c0deac9d8508' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: June Robinson already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7ac92b63-d489-45d5-a85f-c0deac9d8508' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: June Robinson already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='207ff383-f26e-462b-a554-72472b52712a' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Lovelett already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='207ff383-f26e-462b-a554-72472b52712a' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Liz Lovelett already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c3fccc57-8278-43c8-8e54-dc3c78e50bc9' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marcus Riccelli already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c3fccc57-8278-43c8-8e54-dc3c78e50bc9' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marcus Riccelli already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7902547a-e33b-4fff-8a77-5d4e76163f47' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Shewmake already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7902547a-e33b-4fff-8a77-5d4e76163f47' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Shewmake already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='054dd953-bc6b-44de-8173-00efab5a9c04' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Conway already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='054dd953-bc6b-44de-8173-00efab5a9c04' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Steve Conway already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has an abortion answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has an abortion context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND value=1;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: abortion chair 1 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('f6c042e3-b785-4bf2-b385-65a34ff616e8','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('1e6d175b-1af0-444c-b373-e5d0a279d240','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('4218b4c2-d642-431e-a279-5aff5100379f','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('436194e1-479e-4066-8d99-f325fd6bb880','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('7535e225-d3d0-40ca-ba9c-3890563c40a0','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Co-sponsor of SJR 8204, a proposed constitutional amendment making it a "fundamental right to choose to have an abortion" that the state "shall not deny or interfere with", with no limit by stage of pregnancy; and of SB 6182, which creates a state-funded grant programme for "direct patient abortion clinical care services" aimed at care "for which federal funding is prohibited for individuals without sufficient resources". Neither passed.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf']),
('f8feca06-c2bb-4ec8-ad85-0989559912e9','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. Their record contains no instrument addressing who pays for abortion care.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf']),
('14332488-3986-4e86-abc2-666b7a3f2dd5','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('219f7fc7-d02b-46a0-acad-dfc09814ed11','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('4042de49-5bea-413c-aecd-9abbe742a9a2','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. Their record contains no instrument addressing who pays for abortion care.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf']),
('7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('78230dff-4e33-4d33-8c46-71f00db01858','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('3ac881c7-2d11-42c1-9bc0-23f54770a64b','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('15808557-b30b-44cf-bad2-e627fa547e1a','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('47ac1908-3715-4599-82f6-606aaf2d9fe6','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('7ac92b63-d489-45d5-a85f-c0deac9d8508','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. Their record contains no instrument addressing who pays for abortion care.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf']),
('207ff383-f26e-462b-a554-72472b52712a','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('0097aee3-e409-44bc-ba20-121108c11ec7','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('c3fccc57-8278-43c8-8e54-dc3c78e50bc9','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('eba44d6a-6602-4a90-bef0-44ab12db6109','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('7902547a-e33b-4fff-8a77-5d4e76163f47','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('054dd953-bc6b-44de-8173-00efab5a9c04','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As co-sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']),
('2147a010-bd4e-445c-840a-8d5ad69573ca','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
 $r$Unable to place on this ladder. As prime sponsor of SJR 8204 they back a constitutional amendment making abortion a fundamental right with no limit by stage of pregnancy, which rules out every chair that sets a gestational limit. The remaining chair also requires abortion to be publicly funded at all stages, and SJR 8204 is a negative right that says nothing about funding. They also sponsored a bill requiring public university health centres to provide medication abortion, which is public provision but only reaches about the first ten weeks, so it does not show funding at all stages.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Joint%20Resolutions/8204.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5826.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('f6c042e3-b785-4bf2-b385-65a34ff616e8','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('1e6d175b-1af0-444c-b373-e5d0a279d240','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('4218b4c2-d642-431e-a279-5aff5100379f','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('436194e1-479e-4066-8d99-f325fd6bb880','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('7535e225-d3d0-40ca-ba9c-3890563c40a0','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM ab_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 9 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +9', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 27 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +27', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 2: the SPLIT is the point. Assert the seated side sits at chair 1 with the funding instrument
-- cited, and -- more importantly -- that not one of the 18 blanks acquired an answer.
DO $$
DECLARE bad int; blank_answers int; blank_ctx int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND a.politician_id IN ('f6c042e3-b785-4bf2-b385-65a34ff616e8','5a36591c-66c5-4cb1-b99d-d7fc7fa93b25','d1e47ce6-4390-47e0-937e-3c710e81abbb','1e6d175b-1af0-444c-b373-e5d0a279d240','cf38d9ea-d72d-4a44-9d9c-efd9cd9c432f','4218b4c2-d642-431e-a279-5aff5100379f','436194e1-479e-4066-8d99-f325fd6bb880','7535e225-d3d0-40ca-ba9c-3890563c40a0','c09a622c-ec49-40e9-87db-ead331f5ab9e')
     AND (a.value <> 1
          OR c.reasoning !~ 'direct patient abortion clinical care services'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6182.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % seated row(s) wrong chair, missing the funding clause, or missing SB 6182', bad; END IF;

  SELECT count(*) INTO blank_answers FROM inform.politician_answers
   WHERE topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND politician_id IN ('f8feca06-c2bb-4ec8-ad85-0989559912e9','14332488-3986-4e86-abc2-666b7a3f2dd5','219f7fc7-d02b-46a0-acad-dfc09814ed11','4042de49-5bea-413c-aecd-9abbe742a9a2','7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe','78230dff-4e33-4d33-8c46-71f00db01858','3ac881c7-2d11-42c1-9bc0-23f54770a64b','15808557-b30b-44cf-bad2-e627fa547e1a','47ac1908-3715-4599-82f6-606aaf2d9fe6','7ac92b63-d489-45d5-a85f-c0deac9d8508','207ff383-f26e-462b-a554-72472b52712a','0097aee3-e409-44bc-ba20-121108c11ec7','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','eba44d6a-6602-4a90-bef0-44ab12db6109','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','7902547a-e33b-4fff-8a77-5d4e76163f47','054dd953-bc6b-44de-8173-00efab5a9c04','2147a010-bd4e-445c-840a-8d5ad69573ca');
  IF blank_answers <> 0 THEN
    RAISE EXCEPTION 'guard 2: % of the documented blanks have an answer row', blank_answers; END IF;

  SELECT count(*) INTO blank_ctx FROM inform.politician_context
   WHERE topic_id='af2fdfd6-02c4-49df-b09c-cf8536f4773f' AND politician_id IN ('f8feca06-c2bb-4ec8-ad85-0989559912e9','14332488-3986-4e86-abc2-666b7a3f2dd5','219f7fc7-d02b-46a0-acad-dfc09814ed11','4042de49-5bea-413c-aecd-9abbe742a9a2','7e5f6613-ee3c-4ac3-b697-9e28c25b0bfe','78230dff-4e33-4d33-8c46-71f00db01858','3ac881c7-2d11-42c1-9bc0-23f54770a64b','15808557-b30b-44cf-bad2-e627fa547e1a','47ac1908-3715-4599-82f6-606aaf2d9fe6','7ac92b63-d489-45d5-a85f-c0deac9d8508','207ff383-f26e-462b-a554-72472b52712a','0097aee3-e409-44bc-ba20-121108c11ec7','c3fccc57-8278-43c8-8e54-dc3c78e50bc9','eba44d6a-6602-4a90-bef0-44ab12db6109','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','7902547a-e33b-4fff-8a77-5d4e76163f47','054dd953-bc6b-44de-8173-00efab5a9c04','2147a010-bd4e-445c-840a-8d5ad69573ca')
     AND reasoning ~ 'Unable to place' AND reasoning ~ 'nothing about funding';
  IF blank_ctx <> 18 THEN
    RAISE EXCEPTION 'guard 2: % blanks carry the reason, expected 18', blank_ctx; END IF;
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

  RAISE NOTICE 'abortion: 9 seated at chair 1, 18 documented blanks; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
