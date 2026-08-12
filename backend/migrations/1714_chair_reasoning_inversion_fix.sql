-- 1714_chair_reasoning_inversion_fix.sql
-- CHAIR CORRECTION — rows whose stored chair is the OPPOSITE POLE from their own reasoning.
--
-- 🔴 A wrong chair is a wrong VOTER-FACING POSITION: the compass dot and the "Why this position?"
-- text currently say opposite things about the same person. Alonzo Washington sits at chair 5,
-- "eliminate affirmative action and all race-based government programs", on a row reading "As an
-- African American senator in PG County, he prioritizes racial justice". Todd Gloria, the first
-- openly gay mayor of San Diego, sits at chair 5 on Same-Sex Marriage — "make same-sex marriage
-- illegal". Mark Warner and Tim Kaine sit at "end all aid to Ukraine immediately".
--
-- 🔑 ONE BAD BATCH, NOT SCATTERED NOISE. 15 politicians hold 79 inverted rows and for 14 of them
-- 100% of their pro-worded rows sit at the anti pole; 14 are Maryland. Best reading: a research
-- run wrote the chair as an INTENSITY rating — 5 meaning "strongly holds this view" — instead of
-- selecting one of five discrete policy options.
--
-- ⚠ A MECHANICAL 5→1 FLIP WOULD BE WRONG, which is why each row was read. The same batch got
-- other topics right: Sara Love and Ron Watson both sit correctly at chair 2 on Fossil Fuel Policy
-- and School Vouchers, because there the reasoning is phrased as opposition and a low number was
-- picked. The batch is inconsistent.
--
-- 🔑 TARGET = THE LEAST EXTREME PRO-SIDE OPTION THE REASONING ACTUALLY SUPPORTS:
--     Civil Rights and Social Justice → 2
--     Same-Sex Marriage → 1
--     Childcare Affordability & Access → 2
--     Healthcare Access → 2
--     Climate Change and Environmental Protection → 3
--     Affordable Housing → 3
--     Rent Regulation → 2
--     Ukraine - Russia Conflict → 2
--     Misinformation and the Role of Algorithms in Democracy → 2
-- Rows with clearly stronger wording are overridden individually (Sierra Club chapter chair,
-- "aggressive climate action", "universal healthcare access", "housing as a human right").
--
-- ⚠ HAND-CONFIRMED, NOT DETECTOR-SELECTED. The scan produced 194 candidates and every one was
-- read. Genuine conservatives correctly at the anti pole were removed: Harold Rogers ("voted YES
-- on ending racial preferences", 28% NAACP), seven real same-sex-marriage opponents, Shannon
-- Grove, Will Ainsworth, Leslie Rutledge, Andy Harris. Two topics were dropped whole because
-- "support" attaches to opposite objects in them — School Vouchers ("supporter of public
-- education and opponent of voucher programs" IS chair 1) and AI Oversight.
--
-- ⚠ SOURCING: 18 rows are additionally re-sourced to bills the member co-sponsored,
-- from the 882-bill Maryland index. The rest keep their existing citations — the chair is fixed
-- but the sourcing is still owed, and that is recorded rather than glossed.
--
-- Rollback: data/stance-retirement/2026-08-12-chair-inversion-rollback.json
BEGIN;

CREATE TEMP TABLE chairfix_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

-- Joanne C. Benson / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Nick Charles / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Arthur Ellis / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Kevin M. Harris / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Shaneka Henson / Climate Change and Environmental Protection: chair 5 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- William C. Smith, Jr. / Climate Change and Environmental Protection: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- Benjamin F. Kramer / Climate Change and Environmental Protection: chair 5 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- C. Anthony Muse / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Jim Rosapepe / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Jeff Waldstreicher / Climate Change and Environmental Protection: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- Alonzo T. Washington / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Ron Watson / Climate Change and Environmental Protection: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 4;

-- Vivian Moreno / Climate Change and Environmental Protection: chair 5 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- Sean Elo-Rivera / Climate Change and Environmental Protection: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- Igor Tregub / Climate Change and Environmental Protection: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value = 5;

-- Joanne C. Benson / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Nick Charles / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Arthur Ellis / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Kevin M. Harris / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Shaneka Henson / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- William C. Smith, Jr. / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Cheryl C. Kagan / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Sara Love / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- C. Anthony Muse / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Jim Rosapepe / Healthcare Access: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 4;

-- Alonzo T. Washington / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Ron Watson / Healthcare Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 5;

-- Todd Gloria / Healthcare Access: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid AND value = 4;

-- Joanne C. Benson / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Nick Charles / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Arthur Ellis / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Kevin M. Harris / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Shaneka Henson / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- William C. Smith, Jr. / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Cheryl C. Kagan / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Benjamin F. Kramer / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Sara Love / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- C. Anthony Muse / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Jim Rosapepe / Affordable Housing: chair 4 -> 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Jeff Waldstreicher / Affordable Housing: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 5;

-- Alonzo T. Washington / Affordable Housing: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 5;

-- Ron Watson / Affordable Housing: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4;

-- Rashi Kesarwani / Affordable Housing: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'd2013613-769f-4374-809e-a018dbc1e683'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 5;

-- Terry Taplin / Affordable Housing: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 5;

-- Todd Gloria / Civil Rights and Social Justice: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;

-- Joanne C. Benson / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0161?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0606?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0473?ys=2019RS']::text[], reasoning = 'Benson has championed civil rights throughout her career as one of the longest-serving African American women in the Maryland Senate. She supports racial equity, LGBTQ protections, and anti-discrimination measures. Co-sponsored in the Maryland General Assembly: SB0161 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; SB0606 (2020) "Criminal Law - Hate Crimes - Basis (2nd Lieutenant Richard Collins, III''s Law)"; SB0473 (2019) "Hate Crimes - Civil Remedy".'
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Nick Charles / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0917?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0050?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0703?ys=2020RS']::text[], reasoning = 'Charles consistently supports civil rights legislation including racial equity measures, LGBTQ protections, and anti-discrimination laws in his Prince George''s County district. Co-sponsored in the Maryland General Assembly: HB0917 (2020) "Criminal Law - Hate Crimes - Basis (2nd Lieutenant Richard Collins, III''s Law)"; SB0050 (2024) "Human Relations - Commission on Civil Rights - Appeal of Final Orders"; HB0703 (2020) "Maryland Commission on Civil Rights - Employment Discrimination - Reporting".'
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Arthur Ellis / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0161?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0473?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0531?ys=2020RS']::text[], reasoning = 'Ellis consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He represents a diverse Southern Maryland district. Co-sponsored in the Maryland General Assembly: SB0161 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; SB0473 (2019) "Hate Crimes - Civil Remedy"; SB0531 (2020) "Discrimination – Definition of Race – Hair Texture and Hairstyles".'
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Kevin M. Harris / Civil Rights and Social Justice: chair 5 -> 2  (+1 bill citation)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0339?ys=2023RS']::text[], reasoning = 'Harris consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He is a strong advocate for his diverse Prince George''s County constituents. Co-sponsored in the Maryland General Assembly: HB0339 (2023) "Maryland Lynching Truth and Reconciliation Commission - Reporting and Sunset Extension".'
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Shaneka Henson / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1066?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0541?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0917?ys=2020RS']::text[], reasoning = 'Henson is a strong civil rights advocate representing a diverse Anne Arundel County district including Annapolis. She backs racial equity legislation, LGBTQ protections, and anti-discrimination measures. Co-sponsored in the Maryland General Assembly: HB1066 (2023) "Hate Crimes - Commission on Hate Crime Response and Prevention - Establishment"; HB0541 (2020) "Maryland Police Training and Standards Commission - Training Requirements - Hate Crimes"; HB0917 (2020) "Criminal Law - Hate Crimes - Basis (2nd Lieutenant Richard Collins, III''s Law)".'
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- William C. Smith, Jr. / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1058?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0335?ys=2020RS']::text[], reasoning = 'Smith consistently supports civil rights legislation including LGBTQ protections, racial equity measures, and anti-discrimination laws. He has championed these issues through his committee chair position. Co-sponsored in the Maryland General Assembly: SB1058 (2024) "Education - Curriculum Standards - Antihate and Holocaust Education (Educate to Stop the Hate Act)"; SB0071 (2022) "Hate Crimes - Civil Remedy"; SB0335 (2020) "Criminal Law - Hate Crimes - Harassment and Destruction of Property".'
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Cheryl C. Kagan / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0161?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0473?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0486?ys=2022RS']::text[], reasoning = 'Kagan has consistently backed civil rights legislation throughout her career. She supports LGBTQ protections, racial equity measures, and anti-discrimination laws. Co-sponsored in the Maryland General Assembly: SB0161 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; SB0473 (2019) "Hate Crimes - Civil Remedy"; SB0486 (2022) "Places of Public Accommodation and Public Buildings - Gender-Inclusive Signage".'
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Benjamin F. Kramer / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1058?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0840?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0071?ys=2022RS']::text[], reasoning = 'Kramer backs civil rights legislation including anti-discrimination measures, LGBTQ protections, and racial equity policies. He represents a diverse Montgomery County district. Co-sponsored in the Maryland General Assembly: SB1058 (2024) "Education - Curriculum Standards - Antihate and Holocaust Education (Educate to Stop the Hate Act)"; SB0840 (2023) "Public Safety - Protecting Against Hate Crimes Grant Fund - Establishment"; SB0071 (2022) "Hate Crimes - Civil Remedy".'
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Sara Love / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1066?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0541?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0699?ys=2019RS']::text[], reasoning = 'Love consistently backs civil rights legislation including anti-discrimination measures. She serves a diverse Montgomery County district and supports LGBTQ protections and racial equity bills. Co-sponsored in the Maryland General Assembly: HB1066 (2023) "Hate Crimes - Commission on Hate Crime Response and Prevention - Establishment"; HB0541 (2020) "Maryland Police Training and Standards Commission - Training Requirements - Hate Crimes"; HB0699 (2019) "Maryland Police Training and Standards Commission - Training Requirements - Hate Crimes".'
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- C. Anthony Muse / Civil Rights and Social Justice: chair 4 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 4;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0528?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0050?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0604?ys=2015RS']::text[], reasoning = 'Muse supports civil rights and racial equity legislation. As an African American senator representing a predominantly Black district in Prince George''s County, he is a strong advocate for racial justice. Co-sponsored in the Maryland General Assembly: SB0528 (2018) "Criminal Law - Hate Crimes Group Victim"; SB0050 (2024) "Human Relations - Commission on Civil Rights - Appeal of Final Orders"; SB0604 (2015) "Human Relations - Employment Discrimination - Protection for Interns".'
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Jim Rosapepe / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0161?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0473?ys=2019RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0604?ys=2015RS']::text[], reasoning = 'Rosapepe has consistently backed civil rights including LGBTQ protections, racial equity measures, and anti-discrimination laws throughout his legislative career. Co-sponsored in the Maryland General Assembly: SB0161 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; SB0473 (2019) "Hate Crimes - Civil Remedy"; SB0604 (2015) "Human Relations - Employment Discrimination - Protection for Interns".'
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Jeff Waldstreicher / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1058?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0840?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0161?ys=2020RS']::text[], reasoning = 'Waldstreicher consistently champions civil rights including LGBTQ protections, racial equity legislation, and anti-discrimination measures throughout his Senate tenure. Co-sponsored in the Maryland General Assembly: SB1058 (2024) "Education - Curriculum Standards - Antihate and Holocaust Education (Educate to Stop the Hate Act)"; SB0840 (2023) "Public Safety - Protecting Against Hate Crimes Grant Fund - Establishment"; SB0161 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate".'
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Alonzo T. Washington / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0511?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0700?ys=2018RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1661?ys=2017RS']::text[], reasoning = 'Washington has consistently supported civil rights legislation including racial equity measures, LGBTQ protections, and anti-discrimination laws. As an African American senator in PG County, he prioritizes racial justice. Co-sponsored in the Maryland General Assembly: HB0511 (2018) "Public Institutions of Higher Education - Hate-Bias Incident Prevention"; HB0700 (2018) "Criminal Law - Hate Crimes - Group Victim"; HB1661 (2017) "Schools and Child Care Centers - State Grant Program - Security Upgrades for Facilities at Risk of Hate Crimes or Attacks".'
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Ron Watson / Civil Rights and Social Justice: chair 5 -> 2  (+2 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0005?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0917?ys=2020RS']::text[], reasoning = 'Watson consistently supports civil rights legislation including racial equity measures and LGBTQ protections. He is a strong voice for his diverse Prince George''s County constituents. Co-sponsored in the Maryland General Assembly: HB0005 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; HB0917 (2020) "Criminal Law - Hate Crimes - Basis (2nd Lieutenant Richard Collins, III''s Law)".'
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Rashi Kesarwani / Civil Rights and Social Justice: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'd2013613-769f-4374-809e-a018dbc1e683'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 4;

-- Terry Taplin / Civil Rights and Social Justice: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;

-- Ben Bartlett / Civil Rights and Social Justice: chair 5 -> 2  (+3 bill citations)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0005?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0541?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0917?ys=2020RS']::text[], reasoning = 'Bartlett''s campaign credits him with supporting reparations initiatives, creating BenDex (racial equity in city contracting), making Berkeley a Cannabis Sanctuary City with racial equity priorities, enacting Paid Family Leave, and championing equity and inclusion as a ''5th generation Berkeley native.'' He frames his entire legislative record around racial equity and economic justice for disadvantaged communities, consistent with the most progressive civil rights stance including reparations support. Co-sponsored in the Maryland General Assembly: HB0005 (2020) "Crimes - Hate Crimes - Use of an Item or a Symbol to Threaten or Intimidate"; HB0541 (2020) "Maryland Police Training and Standards Commission - Training Requirements - Hate Crimes"; HB0917 (2020) "Criminal Law - Hate Crimes - Basis (2nd Lieutenant Richard Collins, III''s Law)".'
WHERE politician_id = 'eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid;

-- Brent Blackaby / Civil Rights and Social Justice: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '424eb63b-9976-4059-8049-365c09719cc6'::uuid AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid AND value = 4;

-- Todd Gloria / Same-Sex Marriage: chair 5 -> 1
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;

-- Arthur Ellis / Same-Sex Marriage: chair 5 -> 1
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;

-- Kevin M. Harris / Same-Sex Marriage: chair 5 -> 1
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;

-- William C. Smith, Jr. / Same-Sex Marriage: chair 5 -> 1  (+3 bill citations)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0554?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2020RS']::text[], reasoning = 'Smith supports same-sex marriage and LGBTQ equality. He backed Maryland''s marriage equality legislation and LGBTQ anti-discrimination measures. Co-sponsored in the Maryland General Assembly: SB0554 (2020) "Crimes - Mitigation - Sex, Gender Identity, or Sexual Orientation"; HB0488 (2020) "Crimes – Mitigation – Race, Color, National Origin, Sex, Gender Identity, or Sexual Orientation"; HB0706 (2020) "Commission on LGBTQ Affairs - Established".'
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Cheryl C. Kagan / Same-Sex Marriage: chair 5 -> 1  (+1 bill citation)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb1028?ys=2018RS']::text[], reasoning = 'Kagan supported marriage equality in Maryland during the 2012 ballot initiative and has voted for LGBTQ non-discrimination legislation throughout her Senate tenure. Co-sponsored in the Maryland General Assembly: SB1028 (2018) "Health Occupations - Conversion Therapy for Minors - Prohibition (Youth Mental Health Protection Act)".'
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Benjamin F. Kramer / Same-Sex Marriage: chair 5 -> 1
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;

-- Sara Love / Same-Sex Marriage: chair 5 -> 1  (+3 bill citations)
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;
UPDATE inform.politician_context SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0488?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0706?ys=2020RS','https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1010?ys=2020RS']::text[], reasoning = 'Love supports same-sex marriage and LGBTQ equality. As a Montgomery County Democrat, she voted for LGBTQ anti-discrimination legislation and consistently supports marriage equality. Co-sponsored in the Maryland General Assembly: HB0488 (2020) "Crimes – Mitigation – Race, Color, National Origin, Sex, Gender Identity, or Sexual Orientation"; HB0706 (2020) "Commission on LGBTQ Affairs - Established"; HB1010 (2020) "Health Care Facilities – Discrimination (LGBTQ Senior Bill of Rights)".'
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;

-- Ron Watson / Same-Sex Marriage: chair 5 -> 1
UPDATE inform.politician_answers SET value = 1
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND value = 5;

-- Joanne C. Benson / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4a7dc8a6-2138-4472-8197-8b878034f029'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Nick Charles / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Arthur Ellis / Childcare Affordability & Access: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '4754dede-4a3b-4280-a8b1-7497530107f7'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 4;

-- Kevin M. Harris / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Shaneka Henson / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- William C. Smith, Jr. / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Cheryl C. Kagan / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Sara Love / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- C. Anthony Muse / Childcare Affordability & Access: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '47823046-7dea-4a4f-a11b-0c5890539891'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 4;

-- Jim Rosapepe / Childcare Affordability & Access: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 4;

-- Jeff Waldstreicher / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Alonzo T. Washington / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Ron Watson / Childcare Affordability & Access: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid AND value = 5;

-- Mark Warner / Ukraine - Russia Conflict: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '85d27350-e1b6-45b8-aee3-509ca88c5af4'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid AND value = 5;

-- Tim Kaine / Ukraine - Russia Conflict: chair 5 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '8cffe7a0-b56c-42fe-adbf-f57d63589973'::uuid AND topic_id = '24e9212c-b011-422a-865c-093e35050901'::uuid AND value = 5;

-- Cheryl C. Kagan / Misinformation and the Role of Algorithms in Democracy: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid AND value = 4;

-- Sara Love / Rent Regulation: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid AND value = 4;

-- Jeff Waldstreicher / Rent Regulation: chair 4 -> 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'da75c207-bb23-477e-b3c0-7c462394b570'::uuid AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid AND value = 4;

-- Guard 1: every targeted row now holds exactly its intended chair.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM (VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('d2013613-769f-4374-809e-a018dbc1e683'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('d2013613-769f-4374-809e-a018dbc1e683'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('424eb63b-9976-4059-8049-365c09719cc6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('85d27350-e1b6-45b8-aee3-509ca88c5af4'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric), ('8cffe7a0-b56c-42fe-adbf-f57d63589973'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2::numeric)) AS w(pid, tid, want)
  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid
  WHERE a.value <> w.want;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;
END $$;

-- Guard 2: exactly 89 rows touched, nothing created or deleted, no orphans.
DO $$
DECLARE n int; ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM chairfix_snapshot;
  SELECT count(*) INTO n FROM (VALUES ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('0b16443e-fec4-4f33-abbc-eb1331e3b42d'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 3::numeric), ('dc3d8a98-07ce-4797-bc84-957a72fd854f'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('9f9a35a9-0226-45f0-9fd8-ef46163f7245'::uuid, 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 3::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('d2013613-769f-4374-809e-a018dbc1e683'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('d2013613-769f-4374-809e-a018dbc1e683'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('bcdb549a-48bf-400f-9d23-c93e2e71007c'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('eaab41f8-71c8-47db-bd0b-62da46b5607b'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('424eb63b-9976-4059-8049-365c09719cc6'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid, 2::numeric), ('a975b943-f3e0-492a-bd26-9f5993a5c094'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid, 1::numeric), ('4a7dc8a6-2138-4472-8197-8b878034f029'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('4754dede-4a3b-4280-a8b1-7497530107f7'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('05c9b5b9-cb2b-4387-ab6b-350b69553fac'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('47823046-7dea-4a4f-a11b-0c5890539891'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('8c8b0896-dfd0-4d3c-8492-e594d93b78ca'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid, 'c1ac1330-47f7-44ec-baf3-c913d926b97c'::uuid, 2::numeric), ('85d27350-e1b6-45b8-aee3-509ca88c5af4'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric), ('8cffe7a0-b56c-42fe-adbf-f57d63589973'::uuid, '24e9212c-b011-422a-865c-093e35050901'::uuid, 2::numeric), ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid, 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d'::uuid, 2::numeric), ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2::numeric), ('da75c207-bb23-477e-b3c0-7c462394b570'::uuid, 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'::uuid, 2::numeric)) AS w(pid, tid, want)
  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;
  IF n <> 89 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 89', n; END IF;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'chair fix ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;
END $$;

COMMIT;
