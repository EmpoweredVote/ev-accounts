-- 1765_wa_civil_rights_cohort.sql
-- 13 rows civil-rights = 2, from SB 5038 (2025). All 13 sponsors are seated senators.
--
-- 🔑 WHY THE SENATE. Before this migration the sweep held 72 rows across 60 HOUSE members and
-- exactly ONE senator -- and that one, Emily Alvarado, only because she sponsored EHB 1217 while
-- still in the House. The Senate was 1 of 49 for the same reason the corpus was briefly 35 D / 0 R:
-- the instruments read so far happened to be House bills. Instrument choice, not research, decides
-- who gets covered. Check the chamber and party spread as the sweep proceeds.
--
-- ── civil-rights = 2 ─────────────────────────────────────────────────────────────────────────
-- SB 5038 amends RCW 9A.36.080 to (a) make bias motive sufficient when it operates "in whole OR IN
-- PART", (b) let the trier of fact infer intent to threaten from enumerated acts -- burning a cross
-- on the property of a person perceived as African American, defacing property with a Nazi emblem,
-- removing religious garb, placing a noose -- and (c) define the "reasonable person" who judges a
-- threat as one who shares the victim's race, religion, gender identity or disability.
-- 🔑 Chair 2 is "strengthen civil rights enforcement and address systemic discrimination". Lowering
-- the causation threshold and supplying evidentiary inferences is enforcement being strengthened.
-- Both neighbours are REFUTED FROM THE BILL'S OWN TEXT rather than merely left unproven:
--   · chair 3 ("MAINTAIN current civil rights laws") is refuted because the act amends the statute
--     to broaden liability. It does not maintain anything.
--   · chair 1 ("mandate racial equity requirements in all institutions AND provide reparations") is
--     refuted by section 9, which says in terms that nothing in the act "confers or expands any civil
--     rights or protections to any group or class ... beyond those rights or protections that exist
--     under the federal or state Constitution or the civil laws of the state of Washington".
-- 🔴 CHAIR 1 IS ALSO UNREACHABLE FROM THE WA RECORD AT ALL. It requires reparations, and an anchored
-- search of all 3,411 bills in the 2025-26 biennium finds ZERO reparations instruments. An earlier
-- unanchored pass appeared to find two -- SB 6278 and SB 6287 -- but "reparation" was matching inside
-- "teacher and principal PREPARATION programs" and "the PREPARATION, distribution, and sale of kratom
-- products". That is the fourth substring over-fire in this sweep, after paRENTal, paRENTing and
-- reLEASE. Anchor every keyword before believing a hit.
-- ⚠ Screened per member first. The 13 touch nine other civil-rights instruments -- hate-crime victim
-- leave (SB 5101, enacted), student inclusivity protections (SB 5123), college-bound scholarship
-- eligibility (SB 5543, enacted), oral health equity (SB 6146), school district liability for
-- discrimination (SB 5875), social equity in cannabis licensing (SB 5758), surveillance pricing
-- (SB 6312), college athletics (SB 6235), and Hasegawa's SB 5414 (enacted) requiring social equity
-- impact analysis in performance audits and legislative hearings. SB 5414 is the closest thing to
-- chair 1 in the whole set and still falls short on BOTH of chair 1's clauses: it reaches state
-- audits and hearings, not "all institutions", and it provides no reparations. Every one of the nine
-- is enforcement or access, which is chair 2's territory. No member holds a stronger instrument.
--
-- Identity is by legislature member ID joined through the 147/147 verified linkage.
BEGIN;

CREATE TEMP TABLE cr_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='d1e47ce6-4390-47e0-937e-3c710e81abbb' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Javier Valdez already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='15808557-b30b-44cf-bad2-e627fa547e1a' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jesse Salomon already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='3ac881c7-2d11-42c1-9bc0-23f54770a64b' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jamie Pedersen already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1e6d175b-1af0-444c-b373-e5d0a279d240' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jessica Bateman already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='219f7fc7-d02b-46a0-acad-dfc09814ed11' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Bob Hasegawa already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='eba44d6a-6602-4a90-bef0-44ab12db6109' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Marko Liias already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2147a010-bd4e-445c-840a-8d5ad69573ca' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Vandana Slatter already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78230dff-4e33-4d33-8c46-71f00db01858' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Derek Stanford already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1ff1e922-601b-45f3-a43d-2ef69220f54b' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Wellman already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1ff1e922-601b-45f3-a43d-2ef69220f54b' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Wellman already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has a civil-rights answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f6c042e3-b785-4bf2-b385-65a34ff616e8' AND topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Claire Wilson already has a civil-rights context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762' AND value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: civil-rights chair 2 not defined exactly once (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('0097aee3-e409-44bc-ba20-121108c11ec7','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Prime sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('15808557-b30b-44cf-bad2-e627fa547e1a','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('3ac881c7-2d11-42c1-9bc0-23f54770a64b','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('1e6d175b-1af0-444c-b373-e5d0a279d240','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('219f7fc7-d02b-46a0-acad-dfc09814ed11','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('eba44d6a-6602-4a90-bef0-44ab12db6109','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('4218b4c2-d642-431e-a279-5aff5100379f','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('2147a010-bd4e-445c-840a-8d5ad69573ca','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('78230dff-4e33-4d33-8c46-71f00db01858','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']),
('f6c042e3-b785-4bf2-b385-65a34ff616e8','0bc588c6-39e1-4084-b5de-cac909b8b762',
 $r$Co-sponsor of SB 5038 (2025), which would broaden Washington's hate crime offence so it applies when bias is a motive "in whole or in part", let a jury infer intent from acts such as burning a cross or placing a noose, and judge threats from the perspective of a reasonable person who shares the victim's characteristic. Section 9 states the act does not expand anyone's civil rights beyond those that already exist. The bill did not pass.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('0097aee3-e409-44bc-ba20-121108c11ec7','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('d1e47ce6-4390-47e0-937e-3c710e81abbb','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('15808557-b30b-44cf-bad2-e627fa547e1a','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('3ac881c7-2d11-42c1-9bc0-23f54770a64b','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('1e6d175b-1af0-444c-b373-e5d0a279d240','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('219f7fc7-d02b-46a0-acad-dfc09814ed11','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('eba44d6a-6602-4a90-bef0-44ab12db6109','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('4218b4c2-d642-431e-a279-5aff5100379f','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('2147a010-bd4e-445c-840a-8d5ad69573ca','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('78230dff-4e33-4d33-8c46-71f00db01858','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','0bc588c6-39e1-4084-b5de-cac909b8b762', 2),
('f6c042e3-b785-4bf2-b385-65a34ff616e8','0bc588c6-39e1-4084-b5de-cac909b8b762', 2);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM cr_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 13 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +13', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 13 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +13', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c
      ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762'
     AND a.politician_id IN ('0097aee3-e409-44bc-ba20-121108c11ec7','d1e47ce6-4390-47e0-937e-3c710e81abbb','15808557-b30b-44cf-bad2-e627fa547e1a','3ac881c7-2d11-42c1-9bc0-23f54770a64b','c09a622c-ec49-40e9-87db-ead331f5ab9e','1e6d175b-1af0-444c-b373-e5d0a279d240','219f7fc7-d02b-46a0-acad-dfc09814ed11','eba44d6a-6602-4a90-bef0-44ab12db6109','4218b4c2-d642-431e-a279-5aff5100379f','2147a010-bd4e-445c-840a-8d5ad69573ca','78230dff-4e33-4d33-8c46-71f00db01858','1ff1e922-601b-45f3-a43d-2ef69220f54b','f6c042e3-b785-4bf2-b385-65a34ff616e8')
     AND (a.value <> 2
          OR c.reasoning !~ 'in whole or in part'
          OR c.reasoning !~ 'does not expand anyone'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/5038.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN
    RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing the broadening clause, missing the section 9 clause that refutes chair 1, or missing source', bad; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int; seated int; senators int;
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
   WHERE topic_id='0bc588c6-39e1-4084-b5de-cac909b8b762' AND value=2 AND politician_id IN ('0097aee3-e409-44bc-ba20-121108c11ec7','d1e47ce6-4390-47e0-937e-3c710e81abbb','15808557-b30b-44cf-bad2-e627fa547e1a','3ac881c7-2d11-42c1-9bc0-23f54770a64b','c09a622c-ec49-40e9-87db-ead331f5ab9e','1e6d175b-1af0-444c-b373-e5d0a279d240','219f7fc7-d02b-46a0-acad-dfc09814ed11','eba44d6a-6602-4a90-bef0-44ab12db6109','4218b4c2-d642-431e-a279-5aff5100379f','2147a010-bd4e-445c-840a-8d5ad69573ca','78230dff-4e33-4d33-8c46-71f00db01858','1ff1e922-601b-45f3-a43d-2ef69220f54b','f6c042e3-b785-4bf2-b385-65a34ff616e8');
  IF seated <> 13 THEN RAISE EXCEPTION 'guard 3: civil-rights cohort is %, expected 13', seated; END IF;

  -- the point of this migration: the Senate must no longer be a rounding error
  SELECT count(DISTINCT a.politician_id) INTO senators
    FROM inform.politician_answers a
    JOIN essentials.office_terms ot ON ot.politician_id = a.politician_id
    JOIN essentials.offices o ON o.id = ot.office_id
   WHERE o.chamber_id = '12baf2b5-e627-4e4c-ac21-34331c8b185d'
     AND (ot.term_end IS NULL OR ot.term_end > CURRENT_DATE);
  IF senators < 13 THEN RAISE EXCEPTION 'guard 3: only % senators hold stances, expected at least 13', senators; END IF;

  RAISE NOTICE 'civil-rights=2 x 13 senators seated; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
