-- 1722_md_medicaid_template.sql
-- REPLACE THE "backed Medicaid expansion" TEMPLATE — the Maryland slice.
--
-- The phrase sits on 368 rows across 288 politicians in 44 states, 360 with NO bill citation of
-- any kind. Maryland expanded Medicaid in 2013, so for members seated afterwards the sentence is
-- not merely unsourced, it is impossible. 53 Maryland rows across 51 politicians — a WIDER and
-- DIFFERENT cohort than migration 1714's, which is the "the cohort itself was the defect" lesson.
--
-- 🔑 CHAIRS ARE NOT TOUCHED.
--
-- 🔴🔴 THE CHAIR GATE — 9 ROWS REFUSED ON PURPOSE. 1-2 is the PRO pole and 4-5 the ANTI pole, so a
-- citation to a bill the member SPONSORED can only ever evidence a PRO chair. Attaching one to a
-- chair-4/5 row would make the dot and the text contradict each other; this workstream shipped
-- exactly that once (mig 1712) and had to revert it.
-- ⚠ Kramer and Waldstreicher sit at chair 5 with PRO-worded reasoning. Both were in the 1714 bad
-- batch for other topics while their Healthcare Access rows were never flagged — the inversion
-- defect surviving in rows that cohort never covered. They need the CHAIR pass.
--
-- 🔑 THE CITATION QUOTES THE BILL'S OFFICIAL TITLE instead of paraphrasing its synopsis: across 40
-- rows every paraphrase is a chance to overstate. Title, chapter number and sponsor slug are all
-- re-checked against the live bill page at generation time.
--
-- 13 rows left owed, with reasons:
--   · Benjamin F. Kramer / Healthcare Access: chair 5 with pro-worded reasoning — looks like the mig-1714 inversion defect in a row that cohort never covered; needs the CHAIR pass
--   · Jeff Waldstreicher / Healthcare Access: chair 5 with pro-worded reasoning — same as Kramer; needs the CHAIR pass
--   · Chris West / Healthcare Access: chair 4 (anti pole) — sponsorship cannot evidence it
--   · Jason C. Gallion / Healthcare Access: chair 4 (anti pole) — sponsorship cannot evidence it
--   · Johnny Mautz / Healthcare Access: chair 4 (anti pole), and his member record returned no readable session
--   · Mary Beth Carozza / Healthcare Access: chair 4 (anti pole) — already recorded in the 1714 notes as a member whose co-sponsorships point the other way
--   · Nicholaus R. Kipke / Healthcare Access: chair 4 (anti pole) — sponsorship cannot evidence it
--   · Bryan W. Simonaire / Healthcare Access: chair 3 (middle option) — a pro-side sponsorship does not evidence it
--   · Jack Bailey / Healthcare Access: chair 3 (middle option) — a pro-side sponsorship does not evidence it
--   · Dalya Attar / Healthcare Access: no bill passed the STRICT title test in any readable session
--   · Aruna Miller / Healthcare Access: no readable session — tenure unparsed on her mgaleg page (now Lt. Governor)
--   · Karen Toles / Healthcare Access: no readable session — her tenure reads "Maryland General Assembly", which names no chamber, so no session could be resolved
--   · Brian J. Feldman / Medicare / Medicaid: no mgaleg member slug in sources (only a Wikipedia link), so no record could be read
--
-- Rollback: data/stance-retirement/2026-08-12-medicaid-1722-rollback.json
BEGIN;

CREATE TEMP TABLE mt_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT coalesce(sum(value), 0) FROM inform.politician_answers) AS chair_sum_before;

CREATE TEMP TABLE mt_intent (pid uuid, tid uuid, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO mt_intent (pid, tid, reasoning, sources) VALUES
-- Andrea Fletcher Harrison / Healthcare Access (chair 1.0) — cosp on 2026RS:hb0637
('d61a670a-7626-4464-93dc-c1e21d7b26da', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Harrison co-sponsored HB0637 (2026), "Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)", enacted as Chapter 7 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0637?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harrison01?tab=2025RS-legislation']::text[]),
-- Anne Healey / Healthcare Access (chair 1.0) — cosp on 2024RS:hb0728
('4436b432-a63f-4946-919a-f30c41f899e4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Healey co-sponsored HB0728 (2024), "Health Insurance - Qualified Resident Enrollment Program (Access to Care Act)", enacted as Chapter 842 of 2024.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0728?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/healey']::text[]),
-- Ashanti Martinez / Healthcare Access (chair 1.0) — lead on 2026RS:hb0445
('d8eee978-cec3-492d-9867-9d40b2a50a9d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Martinez was the lead sponsor of HB0445 (2026), "Maryland Medical Assistance Program and Health Insurance - Coverage for Orthoses and Prostheses (So Every Body Can Move Act)", enacted as Chapter 628 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0445?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01?tab=2025RS-legislation']::text[]),
-- Ben Barnes / Healthcare Access (chair 1.0) — cosp on 2025RS:hb1315
('590b56b2-1473-4e86-ba96-0490e172f6ff', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Barnes co-sponsored HB1315 (2025), "Vaccinations by Pharmacists and Health Insurance Coverage for Immunizations", enacted as Chapter 738 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1315?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]),
-- Brooke Lierman / Healthcare Access (chair 1.0) — cosp on 2020RS:hb0930
('b26fb5d2-90eb-4108-8ce5-838df719473d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Lierman co-sponsored HB0930 (2020), "Maryland Health Benefit Exchange - Funding for Small Business Insurance Subsidies and Outreach".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0930?ys=2020RS','https://ballotpedia.org/Brooke_Lierman','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lierman01?ys=2025RS']::text[]),
-- Chao Wu / Healthcare Access (chair 1.0) — lead on 2026RS:hb0795
('7ced90a8-39dc-447e-ba33-e3af4cd47473', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Wu was the lead sponsor of HB0795 (2026), "Health Insurance - Artificial Intelligence - Grievance Process and Reporting (AI Health Insurance Accountability Act of 2026)".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0795?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/wu01','https://ballotpedia.org/Chao_Wu']::text[]),
-- Cheryl E. Pasteur / Healthcare Access (chair 1.0) — cosp on 2026RS:hb1118
('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Pasteur co-sponsored HB1118 (2026), "Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions", enacted as Chapter 637 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pasteur01','https://ballotpedia.org/Cheryl_Pasteur']::text[]),
-- Courtney Watson / Healthcare Access (chair 2.0) — cosp on 2026RS:hb1153
('a4b61b58-9006-4e58-952d-abeb2521cda0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Watson co-sponsored HB1153 (2026), "Maryland Medical Assistance Program and Health Insurance - Claims for Reimbursement - Downcoding".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1153?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson02','https://ballotpedia.org/Courtney_Watson']::text[]),
-- Dana Stein / Healthcare Access (chair 2.0) — cosp on 2024RS:hb0728
('e94337e1-4776-4058-87b4-32dfeb7732a0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Stein co-sponsored HB0728 (2024), "Health Insurance - Qualified Resident Enrollment Program (Access to Care Act)", enacted as Chapter 842 of 2024.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0728?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/stein','https://ballotpedia.org/Dana_Stein']::text[]),
-- Denise Roberts / Healthcare Access (chair 1.0) — lead on 2026RS:hb1291
('d5999df9-83b8-4870-a170-4d13f40473e2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Roberts was the lead sponsor of HB1291 (2026), "Public Health - Maryland Medical Assistance Program - Continuity of Care".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1291?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberts01']::text[]),
-- Edith J. Patterson / Healthcare Access (chair 1.0) — cosp on 2026RS:hb0393
('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Patterson co-sponsored HB0393 (2026), "Health Insurance - Scalp Cooling Systems - Required Coverage", enacted as Chapter 52 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0393?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/patterson02','https://ballotpedia.org/Edith_Patterson']::text[]),
-- Gabriel M. Moreno / Healthcare Access (chair 2.0) — cosp on 2026RS:hb1153
('c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Moreno co-sponsored HB1153 (2026), "Maryland Medical Assistance Program and Health Insurance - Claims for Reimbursement - Downcoding".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1153?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/moreno01','https://ballotpedia.org/Gabriel_Moreno_(Maryland)']::text[]),
-- Jen Terrasa / Healthcare Access (chair 2.0) — cosp on 2026RS:hb0633
('f45e2178-2a05-4974-8af8-379662412060', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Terrasa co-sponsored HB0633 (2026), "Health Insurance - Ovarian Cancer Prevention With Salpingectomy - Required Coverage".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0633?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/terrasa01','https://ballotpedia.org/Jen_Terrasa']::text[]),
-- Jessica Feldmark / Healthcare Access (chair 2.0) — lead on 2023RS:hb0726
('fdb9f7d3-93db-4436-bd82-5d7fd853f05e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Feldmark was the lead sponsor of HB0726 (2023), "Maryland Medical Assistance Program - Autism Waiver - Military Families", enacted as Chapter 620 of 2023.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0726?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/feldmark01','https://ballotpedia.org/Jessica_Feldmark']::text[]),
-- Jon S. Cardin / Healthcare Access (chair 2.0) — lead on 2023RS:hb0583
('631dac5c-fb86-41f5-a82d-5963164a9142', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Cardin was the lead sponsor of HB0583 (2023), "Health Insurance – Podiatrists – Reimbursement for Infusion of Medication".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0583?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/cardin01','https://ballotpedia.org/Jon_Cardin']::text[]),
-- Joseline Peña-Melnyk / Healthcare Access (chair 1.0) — cosp on 2025RS:hb0848
('00cd05cc-75de-4d9a-ab23-9f53441bc186', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Peña-Melnyk co-sponsored HB0848 (2025), "Health Insurance - Adverse Decisions - Notices, Reporting, and Examinations", enacted as Chapter 669 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0848?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]),
-- Kent Roberson / Healthcare Access (chair 1.0) — cosp on 2026RS:hb1118
('338210ee-b9ab-4820-bfce-98f5354837af', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Roberson co-sponsored HB1118 (2026), "Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions", enacted as Chapter 637 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01?tab=2025RS-legislation']::text[]),
-- Kevin M. Harris / Healthcare Access (chair 2.0) — cosp on 2026RS:sb0385
('8c6327bf-2eb4-4788-91f7-c5518ab5a3f1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Harris co-sponsored SB0385 (2026), "Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)", enacted as Chapter 8 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0385?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/harris03','https://ballotpedia.org/Kevin_Harris_(Maryland)']::text[]),
-- Kym Taylor / Healthcare Access (chair 1.0) — cosp on 2026RS:hb1118
('9273ed81-2052-428a-b39d-849abeef270b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Taylor co-sponsored HB1118 (2026), "Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions", enacted as Chapter 637 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03']::text[]),
-- Mark S. Chang / Healthcare Access (chair 1.0) — cosp on 2023RS:hb0726
('4a409af4-8568-42c3-bb72-7bb7500c96ce', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Chang co-sponsored HB0726 (2023), "Maryland Medical Assistance Program - Autism Waiver - Military Families", enacted as Chapter 620 of 2023.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0726?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/chang01?tab=2026RS-legislation','https://ballotpedia.org/Mark_Chang']::text[]),
-- Marvin E. Holmes, Jr. / Healthcare Access (chair 1.0) — cosp on 2026RS:hb0637
('b8e331fa-d58e-479f-b076-8fda0b0604c5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Holmes co-sponsored HB0637 (2026), "Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)", enacted as Chapter 7 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0637?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/holmes']::text[]),
-- Mary A. Lehman / Healthcare Access (chair 1.0) — cosp on 2026RS:hb1153
('251a2047-372b-480e-aa09-231f9a5edeca', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Lehman co-sponsored HB1153 (2026), "Maryland Medical Assistance Program and Health Insurance - Claims for Reimbursement - Downcoding".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1153?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lehman01?tab=2025RS-legislation']::text[]),
-- Mary Washington / Healthcare Access (chair 1.0) — lead on 2022RS:sb0682
('38404814-7be0-40e3-b044-062f98b2a5b0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Washington was the lead sponsor of SB0682 (2022), "Maryland Medical Assistance Program - Gender-Affirming Treatment (Trans Health Equity Act of 2022)".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0682?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/washington01','https://ballotpedia.org/Mary_Washington']::text[]),
-- Mary-Dulany James / Healthcare Access (chair 2.0) — lead on 2025RS:sb0547
('18313901-28d8-464c-9368-2873577e9d44', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'James was the lead sponsor of SB0547 (2025), "Commission to Study Health Insurance Pooling - Establishment", enacted as Chapter 741 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0547?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/james01','https://ballotpedia.org/Mary-Dulany_James']::text[]),
-- N. Scott Phillips / Healthcare Access (chair 2.0) — cosp on 2026RS:hb1118
('04eb4549-ad64-4ddc-ad53-8f90217f905f', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Phillips co-sponsored HB1118 (2026), "Health, Health Insurance, and Health Occupations - Perinatal Behavioral Health Conditions", enacted as Chapter 637 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1118?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/phillips02','https://ballotpedia.org/N._Scott_Phillips']::text[]),
-- Nancy J. King / Healthcare Access (chair 2.0) — lead on 2026RS:sb0808
('81b8bae9-0b0f-43de-8079-c0b605e12cec', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'King was the lead sponsor of SB0808 (2026), "Health Insurance - Provider Panels - Requirements", enacted as Chapter 706 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0808?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/king','https://ballotpedia.org/Nancy_King']::text[]),
-- Nicole A. Williams / Healthcare Access (chair 1.0) — cosp on 2026RS:hb1291
('5c24446e-c9d6-4dda-9703-e3c049798315', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Williams co-sponsored HB1291 (2026), "Public Health - Maryland Medical Assistance Program - Continuity of Care".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1291?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/williams01']::text[]),
-- Pam Lanman Guzzone / Healthcare Access (chair 2.0) — lead on 2026RS:hb1153
('589ed7af-602a-4ec9-8072-448b05446772', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Guzzone was the lead sponsor of HB1153 (2026), "Maryland Medical Assistance Program and Health Insurance - Claims for Reimbursement - Downcoding".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1153?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/guzzone01','https://ballotpedia.org/Pam_Guzzone']::text[]),
-- Pamela Beidle / Healthcare Access (chair 2.0) — lead on 2026RS:sb0276
('409ad653-a4fc-41d0-bb61-a933c5bc45c7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Beidle was the lead sponsor of SB0276 (2026), "Maryland Medical Assistance Program and Health Insurance - Coverage for Orthoses and Prostheses (So Every Body Can Move Act)", enacted as Chapter 629 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0276?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/beidle01','https://ballotpedia.org/Pamela_Beidle']::text[]),
-- Robbyn Lewis / Healthcare Access (chair 2.0) — cosp on 2026RS:hb0637
('9285f590-79b5-48de-a1c0-a022629e6ebb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Lewis co-sponsored HB0637 (2026), "Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)", enacted as Chapter 7 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0637?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/lewis01']::text[]),
-- Ron Watson / Healthcare Access (chair 2.0) — cosp on 2022RS:sb0621
('9aef8bfb-8e0c-4f00-9898-c738abe4970c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Watson co-sponsored SB0621 (2022), "Health Insurance - Changes to Coverage, Benefits, and Drug Formularies - Timing".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0621?ys=2022RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/watson04','https://ballotpedia.org/Ron_Watson_(Maryland)']::text[]),
-- Sara Love / Healthcare Access (chair 2.0) — cosp on 2026RS:sb0385
('c5d2cd24-170a-4f87-8fde-84216fe62806', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Love co-sponsored SB0385 (2026), "Public Health - Recommendations for Immunizations, Screenings, and Preventive Services - Pharmacist Administration and Required Health Insurance Coverage (The Vax Act)", enacted as Chapter 8 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0385?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02','https://ballotpedia.org/Sara_Love']::text[]),
-- Terri L. Hill / Healthcare Access (chair 1.0) — lead on 2026RS:hb0633
('f6a237a0-34ff-4a93-b05a-335ec38b6da3', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Hill was the lead sponsor of HB0633 (2026), "Health Insurance - Ovarian Cancer Prevention With Salpingectomy - Required Coverage".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0633?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/hill02','https://ballotpedia.org/Terri_Hill']::text[]),
-- Tiffany T. Alston / Healthcare Access (chair 1.0) — lead on 2024RS:hb1259
('2e809682-2d95-480c-885e-d2174b811cfe', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 'Alston was the lead sponsor of HB1259 (2024), "Health Insurance - Breast and Lung Cancer Screening - Coverage Requirements", enacted as Chapter 868 of 2024.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1259?ys=2024RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/alston01?tab=2025RS-legislation']::text[]),
-- Adrienne A. Jones / Medicare / Medicaid (chair 1.0) — cosp on 2017RS:hb1158
('760cd4a7-235c-472f-a0ba-fb07098dfd57', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Jones co-sponsored HB1158 (2017), "Maryland Medical Assistance Program - Comprehensive Dental Benefits for Adults - Authorization".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1158?ys=2017RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/jones','https://ballotpedia.org/Adrienne_A._Jones']::text[]),
-- Ben Barnes / Medicare / Medicaid (chair 1.0) — cosp on 2023RS:hb0283
('590b56b2-1473-4e86-ba96-0490e172f6ff', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Barnes co-sponsored HB0283 (2023), "Maryland Medical Assistance Program - Gender-Affirming Treatment (Trans Health Equity Act)", enacted as Chapter 253 of 2023.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0283?ys=2023RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/barnes']::text[]),
-- Bill Ferguson / Medicare / Medicaid (chair 1.0) — cosp on 2014RS:sb0721
('6e3c30f5-52be-48b0-b5b4-383e5d745c57', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Ferguson co-sponsored SB0721 (2014), "Maryland Medical Assistance Program - Services for Children With Down Syndrome (Micah''s Law)".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0721?ys=2014RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ferguson','https://ballotpedia.org/Bill_Ferguson']::text[]),
-- Joseline Peña-Melnyk / Medicare / Medicaid (chair 1.0) — cosp on 2025RS:hb0553
('00cd05cc-75de-4d9a-ab23-9f53441bc186', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Peña-Melnyk co-sponsored HB0553 (2025), "Maryland Medical Assistance Program - Maternal Health Self-Measured Blood Pressure Monitoring", enacted as Chapter 714 of 2025.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0553?ys=2025RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/pena']::text[]),
-- Malcolm P. Ruff / Medicare / Medicaid (chair 2.0) — cosp on 2026RS:hb0440
('7e1dfb66-1eff-4c8d-b3fe-d39f990b99c4', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Ruff co-sponsored HB0440 (2026), "Maryland Medical Assistance Program - Individuals With Intellectual and Developmental Disabilities - Provider Reimbursement".', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0440?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/ruff01']::text[]),
-- Samuel I. Rosenberg / Medicare / Medicaid (chair 2.0) — lead on 2026RS:hb1376
('36eecaff-4677-441a-b36e-a323e87d9158', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 'Rosenberg was the lead sponsor of HB1376 (2026), "Maryland Medical Assistance Program, Maryland Children''s Health Program, and Health Insurance - Transfers to Special Pediatric Hospitals - Requirements", enacted as Chapter 325 of 2026.', ARRAY['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1376?ys=2026RS','https://mgaleg.maryland.gov/mgawebsite/Members/Details/rosenberg']::text[]);

UPDATE inform.politician_context c SET reasoning = i.reasoning, sources = i.sources
FROM mt_intent i WHERE c.politician_id = i.pid AND c.topic_id = i.tid;

-- Guard 1: intended text landed, an mgaleg bill page is cited, and the template phrase is GONE.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM mt_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE c.reasoning IS DISTINCT FROM i.reasoning OR c.sources IS DISTINCT FROM i.sources
     OR c.reasoning ILIKE '%Medicaid expansion%'
     OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%mgaleg.maryland.gov/mgawebsite/Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) wrong', bad; END IF;
END $$;

-- Guard 2: exactly 40 rows touched, nothing created or deleted, NO CHAIR MOVED, no orphans.
DO $$
DECLARE n int; ctx_after int; ans_after int; chair_sum_after numeric; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM mt_snapshot;
  SELECT count(*) INTO n FROM mt_intent i
  JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid;
  IF n <> 40 THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected 40', n; END IF;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT coalesce(sum(value), 0) INTO chair_sum_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  IF chair_sum_after <> snap.chair_sum_before THEN RAISE EXCEPTION 'guard 2 failed: a chair moved (% -> %)', snap.chair_sum_before, chair_sum_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
  RAISE NOTICE 'medicaid template ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;
END $$;

COMMIT;
