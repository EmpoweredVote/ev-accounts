-- Phase 111-03: VA State Senators Wave 3 Stances
-- Requirements covered: VAST-02, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-09-111-va-senators-wave3.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  79
--   INSERT INTO inform.politician_answers count: 79
--   INSERT INTO inform.politician_context count: 79
--   All UUID literals verified against 2026-06-09-111-va-senators-wave3-preflight.json
--   max_migration at authoring: 325 (waves 1+2 applied but 326/327 not tracked in schema_migrations)
--
-- Honest skips: No full honest-skips — all 8 senators have >= 1 stance row
--
-- Politician UUIDs (from 2026-06-09-111-va-senators-wave3-preflight.json):
--   Emily M. Jordan           (ext_id -5110017) -> a6774628-e5fd-423e-822a-32c2d59f09af
--   L. Louise Lucas           (ext_id -5110018) -> 0efec835-12f2-472b-b7a0-7a166ed937a1
--   Christie New Craig        (ext_id -5110019) -> 7b7540c8-f62f-4edd-a49a-19a3f883ebd8
--   Bill DeSteph              (ext_id -5110020) -> ec4a7239-4681-4284-b77d-9c2d5c5473dd
--   Angelia Williams Graves   (ext_id -5110021) -> b65454d1-6707-4d4e-be3e-27121afc8388
--   Aaron R. Rouse            (ext_id -5110022) -> 51547ab6-fee3-42c6-8418-f6fe7b67ee93
--   Mamie E. Locke            (ext_id -5110023) -> 090feb66-a051-4624-8174-bf8b6272994d
--   J.D. "Danny" Diggs        (ext_id -5110024) -> f890829a-87e9-4f2e-ae33-ce8b98bf5105
--
-- Migration number: 328
-- Timestamp: 20260609000003
-- Applied: 2026-06-09

BEGIN;

-- ---- Emily M. Jordan / school-vouchers / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Jordan was the chief patron of SB533 in the 2024 Virginia session, establishing the Education Excellence for All Program — an education savings account allocating 95% of state per-pupil funds to family-controlled accounts redeemable at private, nonpublic, or homeschool settings. Eligible families earn up to 300% of the federal poverty level (400% for students with disabilities), covering a broad population. Authoring this bill as chief patron is the strongest possible signal of support for education funding following the student to any school of the family''s choice.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB533',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S116'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Emily M. Jordan / climate-change / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Jordan co-patroned SB3 in the 2024 Virginia session, which restricted the State Air Pollution Control Board from adopting California-style zero-emission vehicle standards and repealed provisions of the Clean Economy Act''s vehicle emissions mandates. Opposing government-mandated clean energy transitions aligns with letting market forces drive the process rather than government-driven rapid transition.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB3',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S116'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Emily M. Jordan / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Jordan co-patroned SB3 in the 2024 Virginia session, which blocked state adoption of California-style zero-emission vehicle standards — directly removing an environmental regulation that would accelerate transition away from fossil fuels. This supports expanding the permissive environment for fossil fuel use over government-driven restrictions, aligning with expanding current policy latitude rather than maintaining strict environmental controls.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB3',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S116'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Emily M. Jordan / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Jordan co-patroned SB58 (2024), establishing an annual three-day August retail sales and use tax holiday covering school supplies, clothing, Energy Star products, and generators. She also authored SB310 creating a $4,000 nonfamily adoption tax credit. Both bills represent targeted tax reductions consistent with preferring lower tax rates across income levels rather than closing loopholes or raising rates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB58',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB310',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S116'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Emily M. Jordan / civil-rights / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a6774628-e5fd-423e-822a-32c2d59f09af',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Jordan co-patroned SB7 (2024), which expanded Virginia''s hate crime and anti-discrimination statutes to add ''ethnic or'' as a protected category alongside national origin in multiple code sections. Sponsoring an expansion of civil rights protections indicates support for maintaining and modestly extending current civil rights law, rather than either mandating equity requirements or eliminating existing programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+ful+SB7',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S116'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / abortion / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Lucas was the chief patron of SJ1 in both the 2024 and 2025 Virginia sessions — a constitutional amendment establishing that ''every individual has the fundamental right to reproductive freedom'' with no stage limit, protecting decisions about all matters related to pregnancy. She also co-patroned SB15 (2024) barring Virginia from extraditing people who received or assisted with reproductive health care, and SB1243 (2023) with the same extradition protection. This three-bill pattern documents a stance favoring full abortion access at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19S',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Lucas was chief patron of SB1248 (2023), requiring at least 30% of boards of directors to be women and historically underrepresented groups for companies seeking MEI project approval — a mandate aimed at addressing structural racial and gender inequity. She also authored SB1523 (2023) creating a resentencing pathway for people convicted of felony marijuana offenses before legalization, directly targeting racially disparate incarceration. Both bills go beyond maintaining current law toward actively addressing systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+S19C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1248',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+SB1523'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Lucas was the chief patron of SB588 (2024), requiring the Department of Housing and Community Development to develop a criminal record screening model policy restricting landlords of affordable housing units from using criminal history to deny applicants, in alignment with federal Fair Housing Act guidance. The bill passed both chambers 21-19 and 50-48 before being vetoed by the governor. Authoring protections that bar landlords from denying affordable housing based on criminal records reflects a stance favoring government intervention to make housing more accessible.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB588',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Lucas was chief patron of SB1 (2024), raising Virginia''s minimum wage from $12.00 to $13.50 effective January 2025 and $15.00 by January 2026. She also authored SB703, which expanded the sales and use tax to digital personal property and streaming services. Both bills represent raising revenue or mandating higher compensation for workers — consistent with modestly raising taxes on higher earners and businesses to fund existing services rather than wholesale tax cuts.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB1',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB703',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Lucas has consistently authored and championed public school investment bills: SB1175 (2023) expanding the Virginia Literacy Act to grades 4-8, SB624 (2024) on evidence-based reading instruction, SB104 (2024) requiring the governor''s budget to raise teacher pay to the national average, SB1260 (2023) on teacher certification incentive rewards, and SB1448 (2023) on reduced tuition at HBCUs. She has no school choice or voucher bills in her authored record; her legislative footprint is entirely public-school-focused.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S19C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+mbr+S19C',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / redistricting / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Lucas led the Virginia Senate Democrats in drawing a partisan congressional map in 2024 that was designed to favor Democrats and flip Republican-held seats — prompting complaints from Sen. Ted Cruz and others. Rather than supporting an independent commission process, she championed the legislature using its majority to draw maps advantageous to the controlling party. This directly reflects the stance that the party controlling the legislature should draw maps without outside interference.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Louise_Lucas',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- L. Louise Lucas / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0efec835-12f2-472b-b7a0-7a166ed937a1',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Lucas voted consistently with the 21-19 Democratic Senate majority on voter access legislation in 2024 including SB196 (protecting voter registration lists from unreliable data sources and transferring challenge authority to courts) and SB300 (strengthening voter list maintenance standards and public records requirements) — both vetoed by the Republican governor. As Senate President pro tempore, she led the chamber''s pro-voter-access agenda, consistent with expanding early voting and mail-in access without restrictive ID mandates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB196',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB300',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S19'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Craig voted NO on SB 15 (2024), which would have prohibited Virginia from extraditing individuals for receiving or providing reproductive health care services that are legal in Virginia. She also voted NO on SB 16 (2024), protecting menstrual health data from government search warrants. Both votes align with opposing legal protections for abortion access, placing her closer to restricting abortion to cases of rape, incest, or serious maternal health risk rather than supporting broader access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0340SB0016',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Craig authored SB 61 (2025) creating income tax subtractions for firefighter benefits and SB 126 (2025) increasing the vehicle personal property tax relief threshold from $20,000 to $30,000. She also voted NO on HB 1 (2024), which would have raised Virginia''s minimum wage to $15.00/hour. Her campaign website describes tax reform to help working families retain more income as her ''TOP priority,'' consistent with cutting taxes across income levels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+S118C',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0582HB0001',
    'https://christienewcraig.com/issues/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / climate-change / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Craig voted NO on SB 234 (2024), establishing the Parking Lot Solar Development Pilot Grant Program to fund solar installations in two Virginia localities. She joined only 9 other Republican senators in opposing this bipartisan bill that passed 30-10. No clean energy or climate legislation appears in her authored bills. This aligns with letting market forces drive any energy transition rather than government-funded clean energy programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0308SB0234',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Craig voted NO on the Parking Lot Solar Development Program (SB 234, 2024), the clearest available signal on energy policy. No fossil fuel restriction bills appear in her authored record. Her alignment with the most conservative Republican bloc on energy votes (she was one of only 10 senators opposing the solar grant program) indicates support for expanding rather than restricting fossil fuel use, though no direct drill-permit votes were found in the 2024 session.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0308SB0234',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / civil-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Craig voted NO on SB 393 (2024), which required companies seeking MEI project approval to disclose the gender and racial diversity of their boards of directors. She was one of 19 Republicans voting against the diversity disclosure requirement. This pattern of opposing government-mandated diversity measures aligns with limiting federal and state civil rights enforcement to clear cases of discrimination rather than proactively requiring equity reporting.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0134SB0393',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / voting-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Craig voted NO on SB 364 (2024), which established enhanced protections for election officials including address privacy for poll workers and new felony penalties for coercing election employees. She was among all 19 Republicans who opposed the bill. This consistent pattern of voting against Democratic voting access and election administration bills aligns with supporting photo ID requirements and stricter voter roll maintenance rather than expanding access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0408SB0364',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Craig voted NO on SB 69 (2024), which would have allowed DACA recipients to serve as law enforcement officers including police officers and deputy sheriffs. She joined all 18 other Republican senators in opposing the bill. Her opposition to extending professional credentials to immigrants without full legal status reflects a stance of limiting public services and credentials to those with legal status, consistent with making it harder to immigrate and limiting services for those without legal status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0435SB0069',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / trans-athletes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes'),
  'Craig voted NO on the committee motion to pass SB 37 (2024) by indefinitely — meaning she voted to keep ''Sage''s Law'' alive. SB 37 required schools to notify parents when students expressed gender incongruence and prohibited gender affirmation plans without parental consent. She was one of six committee members (all Republicans) voting to advance the bill, signaling strong support for restricting transgender recognition in public institutions and aligning with requiring athletes to compete based on biological sex assigned at birth.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+S04V0110+SB0037',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=SB37',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / healthcare / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Craig served as a named Senate conferee on SB 488 (2024), a bipartisan Medicaid waiver bill that expanded home and community-based services for families with multiple children on waivers — passing 40-0 in the Senate. Her willingness to work on expanding Medicaid waiver access in a bipartisan context, combined with her lack of authored healthcare privatization bills, places her closer to supporting existing programs while controlling costs rather than pushing for significant privatization or significant expansion.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=SB488',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Christie New Craig / childcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '7b7540c8-f62f-4edd-a49a-19a3f883ebd8',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Craig authored SB 170 (2025), which created a licensing exemption for out-of-school time programs (after-school, summer) that obtain Board of Education certification instead — reducing government oversight of childcare providers. While she was also a Senate conferee on HB 419 (2024), a bipartisan childcare funding reporting bill, her primary legislative action on childcare was deregulatory. This aligns with reducing regulations on childcare providers to increase supply and lower costs, with limited subsidies for the lowest-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=SB170',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=HB419',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S118'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / school-vouchers / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'DeSteph was chief patron of SB 558 (2024), establishing renewable education savings accounts funded at a percentage of state per-pupil funds, redeemable at private schools, nonpublic online programs, or higher education — with eligibility expanding by 2028-29 to any Virginia student entering kindergarten or previously in public school. This is the broadest possible education funding-follows-the-student model. The bill was killed 9-6 in committee.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0558',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'DeSteph voted NO on SB 15 (2024), which would have prohibited Virginia from extraditing people who received or assisted with reproductive health care legal in Virginia (vote 21-19). He also voted NO on SB 16 (2024), protecting menstrual health data from government search warrants (vote 22-18). Both votes are consistent with opposing legal protections for abortion access, aligning with restricting abortion to cases of rape, incest, or serious maternal health risk.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0340SB0016',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'DeSteph voted NO on SB 1 (2024, minimum wage to $13.50-$15.00, vote 21-19) and NO on HB 1 (2024, same wage increase, vote 21-18). He authored SB 260 (Virginia procurement preference for domestic bidders) and SB 302 (Virginia First Manufacturing Incentive Program), both business-friendly/pro-growth measures. His legislative pattern consistently opposes government-mandated wage floors and favors cutting costs for businesses and individuals.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0582HB0001',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0302',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'DeSteph voted NO on SB 69 (2024), which would have allowed DACA recipients to serve as law enforcement officers (vote 21-18). He also voted NO on SB 720''s committee advancement — a bill to ban sanctuary city policies and require mandatory ICE detainer compliance. His legislative record reflects consistently restrictive immigration policy: opposing expanded credentials for DACA recipients and supporting mandatory federal immigration enforcement cooperation.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0435SB0069',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0720',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / civil-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'DeSteph voted NO on SB 393 (2024), requiring companies to disclose the gender and racial composition of their boards of directors to receive MEI project approvals — opposing government-mandated diversity reporting. He did co-sponsor SB 7 (2024), adding ethnic origin to hate crime and employment discrimination protections (passed unanimously). This combination supports baseline civil rights enforcement for clear cases of discrimination while opposing mandatory equity programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0134SB0393',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0007',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / climate-change / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'DeSteph voted NO on SB 234 (2024), the Parking Lot Solar Development Pilot Grant Program — one of only 10 senators (in a 30-9 vote) to oppose this bipartisan bill creating solar grants for two Virginia localities. He has no authored clean energy bills. His opposition to government-funded renewable energy incentives aligns with letting market forces drive any transition rather than government-sponsored clean energy programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0308SB0234',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'DeSteph voted NO on SB 234 (2024 Parking Lot Solar grant program) and has no authored clean energy or fossil fuel restriction bills. His opposition to even modest solar incentive programs signals preference for expanding fossil fuel use over government-supported renewables, consistent with supporting expanded fossil fuel drilling permits rather than maintaining strict environmental controls.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0308SB0234',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / voting-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'DeSteph voted NO on SB 364 (2024), establishing enhanced protections for election officials including address privacy for poll workers and new felony penalties for coercing election employees (vote 21-19). He voted NO on SB 300 (2024, voter list maintenance and cancellation notice requirements). His consistent pattern of opposing Democratic voting access legislation aligns with requiring photo ID and regularly updating voter rolls rather than expanding access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0408SB0364',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S96',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Bill DeSteph / tariffs / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'ec4a7239-4681-4284-b77d-9c2d5c5473dd',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs'),
  'DeSteph authored SB 260 (2024, passed 97-0), establishing Virginia public procurement preferences for Virginia-resident bidders and U.S.-made goods, with price-matching rights within 10% of the lowest bid — a form of selective domestic protection. He also authored SB 302, the Virginia First Manufacturing Incentive Program focused on reshoring manufacturing to Virginia. Both bills use targeted protectionist mechanisms to support American industry without imposing broad tariffs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0260',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB0302',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S96C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Williams Graves voted YES on SB 15 (2024), which prohibited Virginia from extraditing individuals who received or provided reproductive health care services legal in Virginia (vote 21-19). She also authored SB 525 (2024, Stillbirth Support Grant Program) supporting access to pregnancy care services. Her voting record on reproductive health is fully aligned with the Democratic caucus in protecting legal abortion access, placing her at full legal access through the second trimester rather than publicly funded access at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB525D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Williams Graves voted YES on SB 274 (2024), establishing the Prescription Drug Affordability Board to set upper payment limits for drugs in state health plans — a government body to regulate healthcare costs. She also voted YES on SB 376 (2024), requiring health insurers to cap prescription drug cost-sharing at $100-$150 per 30-day supply. Both votes support government regulation to ensure affordable coverage through a mix of public programs and regulated private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0405SB0274',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB376D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / housing / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Williams Graves authored SB 555 (2024), creating a tax credit for sellers who sell their primary residence to first-time homebuyers (2% of sales price, capped at $5,000, for tax years 2024-2028). This targeted subsidy to facilitate private market access for first-time buyers reflects a government role focused on helping buyers enter the market rather than building public housing, mandating affordability requirements in new construction, or capping rents.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB555D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Williams Graves voted YES on SB 1 (2024), raising Virginia''s minimum wage to $13.50 then $15.00/hour (vote 21-19, vetoed by governor). She voted YES on SB 373 (2024), establishing a paid family and medical leave insurance program funded by employer and employee premium contributions (vote 21-19, vetoed). Both votes support mandating higher compensation floors and new employer contributions — consistent with modestly raising taxes on businesses and higher earners to fund existing and expanded services.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0426SB0373',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Williams Graves authored SB 517 (2024), eliminating Virginia''s tax exemptions for Confederate heritage organizations including the United Daughters of the Confederacy and the Stonewall Jackson Memorial (passed Senate 23-16, vetoed by governor). She also authored SB 696 (2024), creating automatic resentencing hearings for people convicted of marijuana felonies before Virginia''s 2021 legalization — targeting racially disparate incarceration patterns. Both bills go beyond maintaining current law to actively address systemic inequality.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB517D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB696D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Williams Graves voted YES on SB 234 (2024), the Parking Lot Solar Development Pilot Grant Program creating state grants for solar installations in two localities (vote 30-10 including some bipartisan support). No authored clean energy bills or fossil fuel restriction bills were found in her 2024-2025 record. The solar grant support indicates willingness to invest in clean energy without evidence of advocating for a rapid phase-out of fossil fuels.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0304SB0234',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Williams Graves voted YES on SB 234 (2024), a solar grants pilot program, and the broader party-line pattern of her votes shows support for clean energy investment. However, no bills authoring new fossil fuel restrictions or drilling permit limitations appear in her record, and Virginia''s offshore energy policy was not a subject of her authored legislation. Her position matches maintaining current production levels while investing in renewables.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0304SB0234',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Williams Graves voted YES on SB 69 (2024), allowing DACA recipients to qualify for law enforcement positions including police officer and deputy sheriff (vote 21-18, vetoed by governor). This reflects a stance of keeping legal immigration pathways open and allowing immigrants — including those with deferred action status — to fully participate in public institutions and services regardless of citizenship status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0435SB0069',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Williams Graves voted consistently with all 21 Senate Democrats on voting access legislation in 2024. She voted YES on SB 15 (reproductive health extradition protections, 21-19), demonstrating alignment with the Democratic bloc that also backed SB 196 and SB 300 on voter roll protection and SJ 2 (constitutional amendment for automatic voting rights restoration for people released from incarceration). Her authored legislation does not include voter suppression measures.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SJ2D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Angelia Williams Graves / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b65454d1-6707-4d4e-be3e-27121afc8388',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Williams Graves authored SB 518 (2024/2025), requiring every public high school to employ at least one college and career specialist — explicitly as an addition to, not replacement for, existing counseling staff. This public school investment bill reflects fully funding public schools and strengthening their services, with no authored school choice or voucher legislation in her Senate or House record.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+bil+SB518D',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+mbr+S130C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Rouse voted YES on SB 15 (2024), prohibiting Virginia from extraditing individuals for receiving or providing reproductive health care services legal in Virginia (vote 21-19, vetoed by governor). He also voted YES on SB 16 (2024), protecting menstrual health data from government search warrants (vote 22-17), and YES on HB 819 (2024), requiring health insurance coverage for contraceptive drugs and devices (vote 23-16). This pattern supports keeping abortion legal and accessible through the second trimester without evidence of advocating for publicly funded access at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0560',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0592'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Rouse voted YES on HB 174 (2024), which requires Virginia to issue marriage licenses regardless of the sex, gender, or race of the parties and mandates statewide recognition of such marriages. The bill passed the Senate 22-17 and was signed into law by Governor Youngkin on March 8, 2024. Voting to enshrine marriage equality in state statute, making it effective regardless of federal law changes, aligns with requiring all states to recognize same-sex marriages and provide full protections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB174',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0451'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Rouse was the primary patron of SB 300 (2024), establishing data quality standards for voter list maintenance and requiring advance notice before canceling voter registrations — protecting voters from improper removal. He voted with the full 21-senator Democratic caucus on all party-line voting access legislation including SB 196 (voter list maintenance protections) and SB 364 (election official protections). His record reflects expanding voter access protections and making mail-in and early voting broadly available without restrictive ID mandates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB300',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0343'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Rouse voted YES on SB 491 (2024), establishing civil liability standards for firearm industry members to prevent negligent distribution to prohibited buyers (vote 21-19), and YES on SB 588 (2024), requiring affordable housing landlords to develop criminal record screening policies reducing barriers to housing for people with prior convictions (vote 21-19). Both bills go beyond maintaining current law to actively address systemic discrimination and predatory practices, consistent with strengthening civil rights enforcement.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0361',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0369',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB491'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Rouse voted YES on SB 729 (2024), establishing the Virginia Clean Energy Innovation Bank to finance clean energy and greenhouse gas reduction projects with grants and loans (vote 29-9, vetoed by governor). He also voted YES on SB 565 (2024, energy efficiency programs, vote 20-19), SB 255 (2024, shared solar programs, vote 21-16), and SB 697 (2024, solar facility local regulation, vote 21-18). However, he also crossed party lines to vote YES on SB 454 (2024, nuclear small modular reactor cost recovery for Dominion Energy, vote 20-19), suggesting a pragmatic invest-in-clean-energy approach rather than an aggressive fossil fuel phase-out.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0430',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0413',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0410'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Rouse voted YES on SB 729 (2024, Virginia Clean Energy Innovation Bank), SB 255 (shared solar), SB 697 (solar local regulation), and SB 565 (energy efficiency) — all supporting clean energy investment. He also voted YES on SB 454 (2024), authorizing Dominion Energy to recover development costs for a nuclear small modular reactor from ratepayers, crossing party lines (vote 20-19). No authored or voted bills banning new fossil fuel permits or drilling appear in his record. His stance aligns with maintaining current production levels with existing environmental regulations while investing in clean energy rather than halting new permits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0410',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0430',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB454'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Rouse voted YES on SB 274 (2024), establishing the Prescription Drug Affordability Board to conduct cost reviews and set upper payment limits for drugs in state health plans (vote 23-17, vetoed by governor). He also voted YES on HB 819 (2024), requiring health insurers to cover contraceptive drugs and devices with no cost-sharing (vote 23-16). Both votes support government regulation to ensure affordable coverage through a mix of public programs and regulated private insurance rather than market-only solutions.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0405',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0592'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Rouse voted YES on SB 597 (2024), authorizing localities to use zoning authority to facilitate affordable housing development in comprehensive plans (vote 21-19). He also voted YES on SB 588 (2024), requiring affordable housing landlords to adopt criminal record screening policies reducing denials (vote 21-19), and YES on HB 817 (2024), strengthening tenant protections in the Virginia Residential Landlord and Tenant Act (vote 23-17). This pattern of supporting government mandates to expand affordable housing access aligns with using rent and zoning tools alongside publicly funded housing programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0370',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0369',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0647'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Rouse voted YES on SB 69 (2024), allowing individuals granted Deferred Action for Childhood Arrivals (DACA) to qualify as law enforcement officers including police officers and deputy sheriffs (vote 21-18, vetoed by governor). This reflects a stance of keeping legal immigration open and allowing most residents — including those with deferred immigration status — to fully use public institutions and services regardless of full legal citizenship status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB69',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0435'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / deportation / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Rouse voted YES on SB 69 (2024), allowing DACA recipients to serve as law enforcement officers — treating deferred-action immigrants as eligible for full public employment rather than as deportation targets. His consistent alignment with the Democratic Senate caucus on all immigration-related votes (all 21-19 on party-line votes) reflects a stance of deporting only those convicted of serious violent crimes while providing legal status to others.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB69',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0435'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Rouse voted YES on SB 373 (2024), establishing a paid family and medical leave insurance program funded through employer and employee premium contributions starting January 1, 2026 (vote 21-19, vetoed by governor). He consistently voted with the 21-senator Democratic caucus on all party-line tax and labor legislation including SB 1 (minimum wage increase from $12 to $15/hour, vote 21-19). These votes reflect support for modest increases in employer and worker contributions to fund existing and expanded public services.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0426',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB1'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Aaron R. Rouse / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '51547ab6-fee3-42c6-8418-f6fe7b67ee93',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Rouse voted YES on SB 54 (2024), establishing a need- and demand-based funding framework for Virginia''s early childhood care and education system, requiring the state to annually report funding needs for the Virginia Preschool Initiative, Mixed Delivery Program, and Child Care Subsidy Program with the goal of eliminating waitlists (vote 40-0). This reflects support for significantly expanding childcare subsidies and provider grants to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0382',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB54'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Locke voted YES on SB15 (2024), barring Virginia from extraditing anyone charged with criminal violations in another state related to receiving or providing reproductive health care services (vote 21-19, vetoed by governor). She also voted YES on SB716 (2024), prohibiting professional disciplinary action against doctors for providing lawful abortion care (vote 23-17). Both votes reflect support for keeping abortion legal and accessible, consistent with the second-trimester framework rather than publicly funding abortion at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0339SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0253',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB15'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Locke was the chief patron of SJ2 (2024), a constitutional amendment proposing automatic restoration of voting rights upon release from incarceration, eliminating the gubernatorial restoration requirement (continued to 2025 in committee 14-0). She also voted YES on SB364 (2024), protecting election officials from harassment and intimidation (vote 21-19). Sponsoring automatic rights restoration and supporting election official protections reflects expanding voter access aligned with expanding early voting and mail-in voting frameworks.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SJ2',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0408SB0364',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB364'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Locke voted YES on HB568 (2024), eliminating Virginia tax exemptions for Confederate organizations including the United Daughters of the Confederacy (vote 23-17). She voted YES on SB393 (2024), requiring diversity disclosure from businesses seeking major state economic incentives (vote 21-19). Both votes reflect active use of government policy to address systemic inequality and strengthen civil rights enforcement beyond maintaining the status quo.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0489',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB393',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB568'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Locke voted YES on HB174 (2024), which prohibits denying marriage licenses based on the sex or gender of the parties and requires Virginia to recognize all such marriages, codifying marriage equality into state law (vote 21-18 on final Senate passage, signed by governor March 8, 2024). This vote directly places her in the chair favoring requiring all states to recognize same-sex marriages and provide full protections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0463',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB174'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Locke voted YES on SB1 (2024), raising Virginia minimum wage from $12 to $13.50 effective January 2025 and $15 by 2026 (vote 21-19, vetoed by governor). She also voted YES on SB373 (2024), establishing a paid family and medical leave insurance program funded through employer and employee premiums (vote 21-19, vetoed by governor). These votes consistently reflect support for modestly increasing obligations on businesses to fund expanded public benefits.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0395',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB373',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB1'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Locke was the chief patron of SB54 (2024), establishing a need- and demand-based state funding framework for Virginia early childhood care and education, requiring annual funding-need reports for the Virginia Preschool Initiative, Mixed Delivery Program, and Child Care Subsidy Program. The bill passed both chambers (40-0 in Senate, 90-9 in House) and was signed by the governor on April 8, 2024. Authoring a bill requiring state funding to meet early childcare demand reflects support for significantly expanding subsidies to make childcare affordable for low- and middle-income families.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB54',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0382'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Locke voted YES on SB274 (2024), establishing a Prescription Drug Affordability Board with authority to set upper payment limits on high-cost drugs for state health plans (vote 23-16). She also voted YES on HB819 (2024), requiring health insurance to cover contraceptive drugs without cost-sharing (vote 23-16 in Senate). Both votes reflect ensuring affordable coverage through regulated private insurance and public programs rather than a fully public or fully private system.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0405SB0274',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB274',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB819'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Locke voted YES on SB234 (2024), establishing a Parking Lot Solar Development Pilot Grant Program (vote 37-2 on reconsideration). She voted YES on SB255 (2024), requiring the State Corporation Commission to establish shared solar program regulations for AEP customers (vote 21-19). These votes support investing in clean energy; the pattern without emergency carbon bans aligns with gradually reducing reliance on fossil fuels rather than a rapid phaseout.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0307',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0403',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB255'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Locke voted YES on SB255 (2024), expanding shared solar access for utility customers (vote 21-19), and YES on SB234 (2024), a solar grant program (vote 37-2). She supported clean energy expansion through regulated utility mechanisms without advocating for a ban on new fossil fuel permits. The evidence reflects maintaining current production levels with existing environmental regulations while investing in renewables, consistent with a managed transition rather than prohibition.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0403',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0307',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB255'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / school-vouchers / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'The DeSteph ESA/voucher bill SB558 (2024) was killed in the Senate Education and Health Committee 9-6 by the Democratic majority; Locke consistently votes with the 21-senator Democratic caucus on all party-line legislation. Her chief authorship of SB54 (2024) requiring state funding for the Virginia Preschool Initiative, Mixed Delivery Program, and Child Care Subsidy Program directly reflects channeling public funds into public early childhood education systems rather than private alternatives.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB558',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB54'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Locke voted YES on SB304 (2024), requiring localities to permit accessory dwelling units in all residential zones (vote 22-18). She voted YES on SB588 (2024), requiring affordable housing landlords to adopt criminal record screening policies aligned with federal Fair Housing Act guidance (vote 21-19, vetoed by governor). These votes reflect support for using zoning reform and government-mandated fair housing rules to expand housing access and affordability.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0297SB0304',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB304',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB588'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Locke voted YES on SB69 (2024), allowing DACA recipients to qualify for law enforcement positions including police officer, deputy sheriff, and jail officer (vote 21-18, vetoed by governor). This reflects a stance of keeping legal immigration open and allowing residents with deferred immigration status to fully use public institutions and employment pathways regardless of citizenship status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB69',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB15'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / medicare/aid / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Locke voted YES on SB274 (2024), establishing a Prescription Drug Affordability Board to set upper payment limits on high-cost drugs for state health plans (vote 23-16). Her consistent support for contraceptive coverage mandates (HB819, SB238) and drug cost regulation reflects expanding Medicaid and Medicare programs through stronger coverage requirements and cost controls rather than privatizing or phasing out programs.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0405SB0274',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB274'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Mamie E. Locke / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '090feb66-a051-4624-8174-bf8b6272994d',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Locke voted YES on SB78 (2024), expanding definitions of independent expenditures and electioneering communications in campaign finance law to require more disclosure (vote 19-21, narrowly failed). She consistently voted with the Democratic bloc to strengthen campaign disclosure requirements rather than reduce them, reflecting a stance of strictly limiting corporate dark money and requiring transparency.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+SV0337',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB78'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / abortion / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Diggs voted NO on SB 15 (2024), which barred Virginia from extraditing individuals for receiving or providing reproductive health care services legal in Virginia (vote 21-19, vetoed by governor). He also voted NO on SB 716 (2024), prohibiting the Board of Medicine from disciplining physicians for providing lawful abortion care (vote 21-18, vetoed). Both votes align with the Republican bloc opposing legal protections for abortion access. His record supports restricting abortion rather than ensuring broad access, but no authored bill calling for a complete ban was found.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0015',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0716',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / same-sex-marriage / value=5 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Diggs voted NO on HB 174 (2024), which required Virginia to issue marriage licenses regardless of the sex or gender of the parties and mandated statewide recognition of such marriages. The Senate vote was 22-17 with all Republicans voting against; the bill passed and was signed by the governor on March 8, 2024. Voting against codifying state recognition of same-sex marriages — when the sole purpose of the bill was to enshrine marriage equality in state statute — reflects opposition to requiring recognition of same-sex marriage.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0174',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / taxes / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Diggs voted NO on SB 1 / HB 1 (2024), which would have raised Virginia''s minimum wage from $12.00 to $13.50 then $15.00 per hour (vote 21-18/19, vetoed by governor). He also voted NO on SB 373 (2024), establishing a paid family and medical leave insurance program funded by employer and employee premium contributions (vote 21-19, vetoed). His campaign website pledges to ''lower the cost of living'' and ''lower taxes.'' This pattern aligns with cutting taxes and scaling back government mandates on businesses.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0001',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0373',
    'https://diggsforsenate.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Diggs voted NO on SB 69 (2024), which would have allowed individuals granted Deferred Action for Childhood Arrivals (DACA) status to serve as law enforcement officers including police officers and deputy sheriffs (vote 21-18, vetoed by governor). He joined all 18 other Republican senators in opposing the bill. Opposing expanded professional credentials and public employment for immigrants without full legal status aligns with making it harder to immigrate and limiting public services to those with legal status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0069',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / deportation / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'deportation'),
  'Diggs voted NO on SB 69 (2024), allowing DACA recipients to serve in law enforcement, joining all 18 Republican senators in opposition. His record as a former York County Sheriff (2000-2023) and his law enforcement identity center on enforcement-first approaches. No authored or voted bills protecting undocumented immigrants from deportation appear in his record. This aligns with deporting everyone without legal status, prioritizing those with criminal records first.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0069',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119',
    'https://en.wikipedia.org/wiki/Danny_Diggs'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / civil-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Diggs voted NO on SB 393 (2024), which would have required companies seeking Major Employment and Investment (MEI) project approvals to disclose the gender and racial diversity of their boards of directors (vote 21-19, vetoed by governor). He voted NO on SB 517 (2024), eliminating state tax exemptions for Confederate heritage organizations (vote 23-16, vetoed). His voting pattern aligns with the Republican bloc limiting civil rights enforcement to clear cases of discrimination rather than mandating equity reporting or proactively addressing systemic inequality.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0517',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / healthcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Diggs voted NO on SB 274 (2024), establishing a Prescription Drug Affordability Board with authority to set upper payment limits on high-cost drugs for state health plans (vote 23-16, vetoed by governor). He also voted NO on HB 819 (2024), requiring health insurers to cover contraceptive drugs without cost-sharing (vote 23-16 in Senate). His authored bills are exclusively law enforcement focused with no healthcare legislation. This pattern reflects only helping the poorest people afford healthcare while leaving others to employers and private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0274',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0819',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / housing / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Diggs voted NO on SB 597 (2024), authorizing localities to implement affordable housing programs through zoning amendments (vote 21-19, vetoed). He voted NO on SB 304 (2024), requiring localities to permit accessory dwelling units in residential zones (vote 22-18). His authored bills contain no housing provisions. This consistent vote against government-mandated zoning and affordable housing requirements reflects a preference for cutting regulations and letting private developers address housing supply.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0597',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0304',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / climate-change / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Diggs has no authored clean energy or climate legislation. His Republican caucus pattern on energy bills — including opposing SB 255 (shared solar, 21-18), SB 729 (Clean Energy Innovation Bank, vetoed), and SB 565 (energy efficiency, 21-18 initial passage) — aligns with letting market forces drive energy transitions. Virginia Republicans in 2024 consistently voted against government-funded clean energy programs. Value 4 (market-driven transition) rather than 5 (reject climate policies entirely) is supported by the pragmatic center-right framing of his district.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0255',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0729',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / fossil-fuels / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Diggs voted with the Republican bloc against Democratic clean energy legislation in 2024, including SB 255 (shared solar expansion, 21-18) and SB 729 (Clean Energy Innovation Bank, 29-9 with some Republican support). No authored fossil fuel restriction bills appear in his record. His law enforcement/public safety legislative focus and Republican energy-policy pattern align with supporting expanded fossil fuel permitting over strict environmental regulations, though no direct drill-permit vote was found.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0255',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0729',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / voting-rights / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Diggs voted NO on SB 364 (2024), establishing enhanced protections for election officials including address privacy for poll workers and new felony penalties for coercing election employees (vote 21-19, vetoed). He voted NO on SB 300 (2024), strengthening data quality standards for voter list maintenance and requiring advance notice before canceling voter registrations (vote 21-19, vetoed). Both votes align with the Republican caucus position of supporting photo ID requirements and regularly updating voter rolls over expanding voter access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0364',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0300',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- J.D. Danny Diggs / campaign-finance / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f890829a-87e9-4f2e-ae33-ce8b98bf5105',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Diggs voted NO on SB 78 (2024), which would have expanded Virginia''s campaign finance disclosure requirements for independent expenditures and electioneering communications by requiring disclosure of top three contributors (vote 19-21, bill failed). He voted with all Republican senators in blocking expanded disclosure requirements. No authored campaign finance legislation appears in his record. This pattern aligns with reducing restrictions on political donations and spending rather than mandating additional disclosure.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0078',
    'https://apps.senate.virginia.gov/Senator/memberpage.php?id=S119'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 3 (external_id BETWEEN -5110024 AND -5110017)
DO $$
DECLARE
  senator_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO senator_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5110024 AND -5110017;
  RAISE NOTICE 'VA senators with stances (Wave 3): %', senator_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5110024 AND -5110017
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA senator stances (Wave 3): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
