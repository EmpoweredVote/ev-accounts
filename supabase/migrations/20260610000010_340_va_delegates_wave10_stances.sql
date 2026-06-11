-- Phase 112-10: VA House Delegate Stances â€” Wave 10 (HD-11 through HD-16, NoVA Fairfax/Prince William, FINAL WAVE)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave10.csv
--
-- Pre-write cross-check:
--   CSV data rows:                          58
--   INSERT INTO inform.politician_answers:  58
--   INSERT INTO inform.politician_context:  58
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave10-preflight.json
--   max_migration at authoring: 358
--
-- Honest skips (0 stances, no documentable evidence found):
--   None â€” all 6 Wave 10 delegates have at least 5 sourced stances
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave10-preflight.json):
--   Gretchen M. Bulova  (HD-11, ext_id -5120011) -> 1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0
--   Holly M. Seibold    (HD-12, ext_id -5120012) -> 4a5090f7-8d76-40c1-b2f4-c2ed038e6687
--   Marcus B. Simon     (HD-13, ext_id -5120013) -> c490eece-71f4-4051-975d-8fa5ed5f652b
--   Vivian E. Watts     (HD-14, ext_id -5120014) -> b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264
--   Laura Jane Cohen    (HD-15, ext_id -5120015) -> a1a470c9-1b16-4e98-999c-4106422cc52c
--   Paul E. Krizek      (HD-16, ext_id -5120016) -> cd70f416-c844-41db-9ff4-c528e04a72be
--
-- Migration number: 340
-- Timestamp: 20260610000010
-- Applied: 2026-06-10

BEGIN;

-- ---- Gretchen M. Bulova / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Bulova''s campaign website states she supports 100% marriage equality and pledges to vote for constitutional amendments to enshrine marriage equality. She was seated January 14, 2026 (HD-11 special election) and this was among her top three stated campaign commitments.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.gretchenbulova.com/issues'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Gretchen M. Bulova / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Bulova''s campaign website lists the right to reproductive choice as one of her top three civil liberties priorities and states she supports it 100% pledging to vote for constitutional amendments protecting reproductive choice. Language emphasizes legal access and constitutional protection, consistent with keeping abortion legal and accessible through the second trimester, not all stages publicly funded.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.gretchenbulova.com/issues'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Gretchen M. Bulova / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Bulova''s campaign website lists the restoration of voting rights as one of her top three civil liberties priorities, specifically framing it as a constitutional amendment. In Virginia context this covers automatic rights restoration for formerly incarcerated persons and expanded access; she also serves on the Privileges and Elections Committee.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.gretchenbulova.com/issues',
    'https://house.vga.virginia.gov/members/H0403'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Gretchen M. Bulova / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Bulova''s campaign website says clean, renewable energy is essential for combating climate change and she supports investing in Virginia''s renewable energy potential â€” from offshore wind to solar installations while helping Virginians afford bills as we transition to cleaner energy sources. The framing is gradual investment-led transition, not an emergency phase-out by 2030.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.gretchenbulova.com/issues'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Gretchen M. Bulova / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1a1d7fb4-8bf0-4aaf-8a1d-7a4ccc00e5f0',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Bulova''s campaign website states All Virginians deserve access to affordable healthcare and she will fight to ensure coverage from drug costs and annual exams to specialty treatment and mental health services. The vision is universal affordable coverage through a mix of programs, not a free single-payer system.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.gretchenbulova.com/issues'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Voted YES on SB 15 (2024) prohibiting extradition for reproductive healthcare services (54-46) and YES on SB 16 (2024) prohibiting government seizure of menstrual health data (51-49). Both bills passed the House but were vetoed by the Governor. Consistent pattern of protecting abortion access and reproductive privacy through the second trimester without publicly funding all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV0958',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV0959'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Voted YES on SB 274 (2024) creating a Prescription Drug Affordability Board (50-47) and YES on HB 819 (2024) requiring health insurers to cover contraceptives without cost-sharing (65-31). Both bills were vetoed by the Governor. Supports cost-control measures and coverage mandates consistent with an affordable public-private healthcare mix.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1117',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV0501'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Voted YES on SB 588 (2024) requiring criminal record screening policies for affordable housing to reduce discrimination (50-48). Chief-patroried HB 45 (2024) to allow earned sentence credits for pre-conviction incarceration â€” a criminal justice equity bill vetoed by the Governor. Pattern reflects strengthening civil rights enforcement and addressing systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1127',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=HB45'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Voted YES on HB 597 (2024) enabling localities to pursue enforcement action against landlords who fail to maintain habitable conditions (53-45) and YES on SB 588 (2024) establishing fair criminal-record screening for affordable housing applicants (50-48). Both bills were vetoed. Supports tenant protections and affordable housing accountability consistent with rent caps and affordable mandates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV0243',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1127'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Voted YES on SB 255 (2024) establishing a shared solar program for AEP customers (52-46) and YES on SB 729 (2024) creating the Virginia Clean Energy Innovation Bank (57-40). Both signed into law or advanced. Also chief-patroned HB 47 (2024) on invasive plant species labeling (small environmental bill, vetoed). Consistent with investing in clean energy while gradually reducing fossil fuel reliance â€” market-mechanism approach rather than emergency phase-out mandate.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1115',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1452',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=bil&val=HB47'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Voted YES on SB 364 (2024) protecting election officials from intimidation and allowing election workers to use P.O. boxes on registration records (52-47). The bill passed and became law despite initial veto recommendation dispute. Consistent with Democrats'' 2024 session pattern of expanding voting access and protecting election infrastructure â€” aligns with expanding early voting and mail-in access protections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1551'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Voted YES on SB 69 (2024) allowing individuals with DACA status to qualify for law enforcement officer positions in Virginia (53-47). The bill was vetoed. Supporting DACA-holder eligibility for public service reflects a path toward legal integration rather than enforcement-first stance, consistent with providing legal status to those already in the country.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1267'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Holly M. Seibold / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4a5090f7-8d76-40c1-b2f4-c2ed038e6687',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Voted YES on HB 1 (2024) raising Virginia''s minimum wage from $12 to $13.50 then $15/hour (51-49) and YES on SB 373 (2024) establishing a paid family and medical leave insurance program (50-46). Both were vetoed by the Governor. Consistent with moderately increasing labor income and social insurance â€” raising effective income floors rather than broadly raising income tax rates, aligning with stance 2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV0202',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?ses=241&typ=vot&val=HV1166'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Co-patron of SJ 1 (2025 session) â€” a constitutional amendment establishing reproductive freedom as a fundamental right, restricting state intervention only when justified by a compelling state interest using the least restrictive means. Also authored HB 2382 (2023) protecting consumer privacy for reproductive health data. Pattern reflects protecting broad abortion access without publicly funding all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+SJ0001',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB2382'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Co-patron of HJ 9 (2025 session) â€” a constitutional amendment repealing Virginia''s marriage-as-one-man-one-woman provision and establishing that the right to marry is a fundamental right that cannot be denied based on sex, gender, or race, while protecting religious organizations'' right to decline. Reflects full marriage equality with federal-equivalent protections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HJ0009'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Co-patron of SJ 2 (2025) and HJ 2 (2024) â€” constitutional amendments establishing automatic voting rights restoration upon release from incarceration, eliminating the requirement for gubernatorial restoration. Also co-patron of HB 375 (2024) joining the National Popular Vote Compact. Chairs the House Privileges and Elections Committee. Pattern reflects expanding voting access beyond current law.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+SJ0002',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0375',
    'https://en.wikipedia.org/wiki/Marcus_B._Simon'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / campaign-finance / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Chief patron of HB 40 (2024) prohibiting personal use of campaign contributions, and HB 1045 (2024) creating a public campaign financing program funded by voluntary tax check-offs with small-donor matching. Also authored HB 1552 (2023) and HB 973 (2022) on the same prohibition. Long record of campaign finance reform as chair of the Privileges and Elections Committee. Aligns with strictly limiting political money.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0040',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1045',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB1552'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / redistricting / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Appointed as one of eight legislative members of the 2021 Virginia Redistricting Commission â€” a bipartisan body of eight legislators and eight citizens that drew new maps. Chairs the House Privileges and Elections Committee. The commission structure included both parties and citizen members, consistent with an independent bipartisan commission rather than pure citizen control or legislative control.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Marcus_B._Simon'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Co-patron of HB 570 (2024) establishing a Prescription Drug Affordability Board to set upper payment limits on high-cost drugs for state health plans â€” vetoed by the Governor. Co-patron of HB 256 (2024) requiring paid sick leave for healthcare and grocery workers. Pattern reflects supporting cost regulation and coverage mandates in a public-private mix, consistent with affordable healthcare access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0570',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0256'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Co-patron of HB 1 (2024) raising Virginia''s minimum wage from $12 to $13.50 then $15 per hour â€” vetoed by Governor. Co-patron of SB 373 (2024) establishing paid family and medical leave with employer-employee premium funding â€” also vetoed. Pattern of supporting labor income floors and social insurance programs, consistent with moderately raising effective income without drastically cutting taxes.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0001',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0373'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'The House voted 53-47 along party lines to pass SB 69 (2024) allowing DACA recipients to serve as law enforcement officers in Virginia; Simon voted YES as part of the Democratic majority. The Governor vetoed the bill. Support for integrating DACA holders into public service reflects prioritizing legal pathways and service access for long-term residents.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0069'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Chief patron of HB 1329 (2024) clarifying dual-filing timelines for discrimination complaints under the Virginia Human Rights Act and EEOC â€” strengthening enforcement procedures. Voted with Democratic majority on SB 588 (2024) requiring fair criminal-record screening policies for affordable housing. Pattern reflects strengthening civil rights enforcement mechanisms.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB1329',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0588'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Co-patron of HB 408 (2025) addressing Child Care Subsidy Program reimbursement practices for providers. Co-patron of HB 408 in the 2025 session addresses enrollment-based versus attendance-based reimbursement for childcare providers â€” part of expanding the subsidy system''s reliability. Consistent with expanding subsidies and provider support for access.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+sum+HB0408'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Co-patron of HB 817 (2024) expanding tenant anti-retaliation protections â€” vetoed by the Governor. Voted with Democratic majority on SB 304 (2024) requiring localities to permit ADUs in residential zones. Co-patron of SB 588 (2024) requiring fair criminal-record screening for affordable housing applicants. Pattern reflects affordable housing mandates and tenant protections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0817',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0304',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0588'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / climate-change / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Co-patron of HB 406 (2024 and 2025 sessions) addressing Clean Water Act standards for cooling water intakes at power plants. Co-patron of SB 255 (2024) establishing a shared solar program for AEP customers â€” signed into law. No authored legislation declaring a climate emergency or banning fossil fuel extraction. Pattern reflects investing in clean energy programs and environmental standards while not pursuing emergency phase-out.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0406',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0255'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Marcus B. Simon / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'c490eece-71f4-4051-975d-8fa5ed5f652b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Co-patron of HB 406 addressing cooling water intakes at power plants (clean water/environmental regulation of fossil fuel infrastructure) and co-patron of SB 255 (2024) shared solar expansion. No bill sponsored or co-sponsored banning new fossil fuel permits or drilling. Clean energy support through market-mechanism programs rather than extraction prohibitions aligns with maintaining current production levels with existing regulations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+SB0255',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB0406'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Watts voted YES on SB15 (2024) prohibiting extradition for out-of-state abortion charges, and YES on SB716 (2024) protecting healthcare providers from disciplinary action for lawfully providing abortion care. Both votes align with keeping abortion legal and accessible through the second trimester.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0958',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0915'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Watts voted YES on HB174 (2024) which requires Virginia to issue marriage licenses regardless of sex or gender, and requires the state to recognize such marriages â€” making Virginia law align with Obergefell and the federal Respect for Marriage Act.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0064'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Watts voted YES on HB819 (2024) mandating insurance coverage for contraceptive drugs and devices without cost-sharing, and YES on SB274 (2024) establishing a Prescription Drug Affordability Board to control drug costs. Both votes reflect support for expanding access through a regulated public-private insurance framework.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0501',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1117'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Watts voted YES on SB597 (2024) expanding local zoning authority to create affordable housing programs â€” removing prior restrictions. Also voted YES on HB597 (2024) allowing localities to enforce habitability standards against landlords. Both reflect support for affordable housing through local government tools and regulatory mandates.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1680',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+sum+HB597'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Watts voted YES on SB364 (2024) protecting election officials and electors from threats and obstruction, and YES on HB1490 (2024) expanding absentee in-person voting hours and authorizing voter satellite offices. Both votes reflect support for expanding voting access and protecting election administration.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1551',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0615'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Watts voted YES on SB696 (2024) creating automatic resentencing hearings for pre-legalization marijuana convictions â€” a criminal justice equity measure. Her campaign website lists racial equity and justice as a top priority. These reflect a strengthening-enforcement approach to addressing systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1451',
    'https://vivianwatts.com'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Watts voted YES on HB1/SB1 (2024) raising Virginia''s minimum wage to $13.50/hr, and YES on SB373 (2024) establishing a paid family and medical leave insurance program financed through employer/employee premiums. As House Finance Committee chair she has led progressive tax and spending priorities for years.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0202',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1166'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Watts voted YES on SB69 (2024) allowing persons with DACA status to qualify for positions as law-enforcement officers, deputies, and jail officers â€” a bill that extends legal rights and public-service access to a protected class of immigrants.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1267'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Watts voted YES on SB729 (2024) creating the Virginia Clean Energy Innovation Bank to finance clean energy and greenhouse gas reduction projects, and YES on SB255 (2024) establishing a shared solar program for AEP customers. Her campaign website explicitly lists advancing green energy development as a commitment.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1452',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1115',
    'https://vivianwatts.com/views/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Vivian E. Watts / fossil-fuels / value=3 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b6e0f927-9ce6-41ba-b1b7-43c8c4ae2264',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Watts voted YES on SB454 (2024) allowing Dominion Energy to recover small modular reactor (nuclear) development costs from ratepayers â€” supporting nuclear as an alternative to fossil fuels but not banning new fossil fuel permits. Her YES on clean energy bills signals support for transition without an explicit moratorium on existing fossil fuel operations.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1553'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Cohen voted YES on SB 15 (2024) â€” prohibiting extradition of individuals for reproductive healthcare acts legal in Virginia â€” which passed the House 54-46 before a gubernatorial veto. Her campaign website pledges to defend abortion access and ensure Virginia''s constitution explicitly protects reproductive freedom. She also voted YES on SB 16 (menstrual data privacy). Her positions align with keeping abortion legal and accessible, with constitutional protection; no evidence of supporting public funding at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0958',
    'https://www.laurajanecohen.com/priorities',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0959'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Cohen voted YES on HB 174 (2024) â€” which prohibits denying marriage licenses based on sex or gender and requires Virginia to recognize same-sex marriages, signed into law effective July 1, 2024. Her campaign website explicitly pledges to repeal Virginia''s constitutional ban on same-sex marriage and implement gender identity-affirming policies in Medicaid, among her stated LGBTQIA+ priorities.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0064',
    'https://www.laurajanecohen.com/priorities',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB174'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Cohen voted YES on SB 274 (2024) â€” establishing a Prescription Drug Affordability Board (50-47). Her campaign website calls for preserving Medicaid expansion, lowering prescription drug costs, and expanding mental health services. She authored HB 499 (2025) to modernize Medicaid waiver delivery via telehealth. Positions align with an affordable public-private mix, not universal single-payer.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1117',
    'https://www.laurajanecohen.com/priorities',
    'https://house.vga.virginia.gov/members'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Cohen voted YES on SB 364 (2024) â€” expanding voting protections for election officials and increasing penalties for interference â€” and YES on SB 300 (2024), a voter list maintenance bill (54-45). Her campaign website calls for restoring voting rights and expanding legislative oversight of elections, consistent with expanding early voting and mail-in access rather than strict ID requirements.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1833',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1549',
    'https://www.laurajanecohen.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Cohen voted YES on SB 729 (2024) â€” creating the Virginia Clean Energy Innovation Bank to finance clean energy and greenhouse gas reduction projects (56-43) â€” and YES on SB 255 (solar expansion, 52-46). Her campaign website pledges to accelerate Virginia''s transition to 100% carbon-free electricity and convert diesel buses to electric alternatives, indicating a rapid clean-energy transition goal consistent with stance 2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1723',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1115',
    'https://www.laurajanecohen.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Cohen voted YES on SB 588 (2024) â€” requiring fair housing criminal record screening policies (50-48) â€” and authored HB 502 (2025), which would require all government forms to offer a nonbinary gender option. Her campaign website commits to LGBTQIA+ rights and gender identity-affirming Medicaid policies. These positions align with strengthening civil rights enforcement and addressing systemic discrimination.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1127',
    'https://house.vga.virginia.gov/members',
    'https://www.laurajanecohen.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Cohen voted YES on SB 54 (2024) â€” a bipartisan bill (93-3) expanding childcare subsidy funding for the Virginia Preschool Initiative, Mixed Delivery Program, and Child Care Subsidy Program to maintain slots and reduce waitlists. Her campaign website calls for funding universal Pre-K as a top education priority.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1709',
    'https://www.laurajanecohen.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Cohen voted YES on SB 69 (2024) â€” allowing DACA recipients to qualify for law enforcement positions in Virginia (53-47) â€” demonstrating support for including undocumented residents with legal status in civic roles and maintaining services for most residents.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1267',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+SB69'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Cohen voted YES on HB 1 (2024) â€” raising Virginia''s minimum wage from $12 to $13.50/hour (51-49) â€” and YES on SB 373 (2024), establishing a paid family and medical leave program funded through employer/employee premiums (50-46). Both bills were vetoed by the Governor. These votes show a consistent pattern of supporting policies that raise labor costs on higher earners/employers.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV0202',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1166'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / housing / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Cohen voted YES on SB 597 (2024) â€” expanding local authority to create affordable housing zoning programs (51-48, later vetoed) â€” and YES on SB 588 (fair housing criminal record screening). Both bills reflect support for expanding affordable housing access through local mandates and public program structures.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1680',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1127'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / medicare/aid / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Cohen authored HB 499 (2025) to modernize Medicaid waiver delivery for disability programs and voted YES on SB 274 (Rx Drug Affordability Board). Her campaign website explicitly calls for preserving Medicaid expansion and lowering prescription drug costs, consistent with support for Medicaid expansion and improving Medicare without privatization.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1117',
    'https://www.laurajanecohen.com/priorities',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+mbr+H0355C'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Laura Jane Cohen / fossil-fuels / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a1a470c9-1b16-4e98-999c-4106422cc52c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Cohen voted YES on SB 729 (Clean Energy Innovation Bank, 2024) and YES on SB 255 (shared solar expansion) â€” both advancing clean energy alternatives. She voted NO on SB 454''s Governor''s recommendation (small modular reactor cost recovery), indicating skepticism toward non-renewable energy subsidies. Her campaign''s 100% carbon-free electricity goal aligns with stopping new fossil fuel permits rather than an immediate ban.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1723',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+vot+HV1835',
    'https://www.laurajanecohen.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / abortion / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Krizek is explicitly pro-choice; his campaign site states It should be safe, accessible, affordable, and free from punishment or judgment. He voted against all seven anti-abortion bills in the 2022 session. Language emphasizes access and affordability, consistent with keeping abortion legal and accessible, not publicly funded at all stages.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/healthcare'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / climate-change / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Krizek''s campaign site states he ''strongly supports'' RGGI and commits to ''30 percent of Virginia''s electric system powered by renewable energy resources by 2030'' and ''100 percent carbon-free electricity by 2050.'' He authored HB 199 (2024), which removed barriers to the Brownfield and Coal Mine Renewable Energy Grant Fund (signed into law).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/environment',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB199'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / voting-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights'),
  'Krizek authored HB 220 (2020, prepaid postage on absentee ballots), co-patroned HJ 2 (2024/2025, constitutional amendment for automatic voting rights restoration upon release from incarceration), and supported no-excuse early voting, automatic DMV voter registration, same-day registration, and mail-in voting. He explicitly opposed strict photo ID requirements as disproportionately disenfranchising.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/voting-rights',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+bil+HJ2'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / same-sex-marriage / value=1 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Krizek co-patroned HB 174 (2024), which prohibited denial of marriage licenses based on sex or gender and became law effective July 1, 2024. He also co-patroned HJ 9 (2025), a constitutional amendment to enshrine marriage equality in Virginia''s constitution. His equality page states LGBTQ+ equality goes beyond marriage and he co-sponsored removal of anti-SSM statutory language in 2022.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB174',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+bil+HJ9',
    'https://www.paulkrizek.com/equality'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / healthcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Krizek''s campaign site states ''Every Virginian should have access to quality and affordable health care.'' He is a strong Medicaid expansion supporter and co-patroned HB 819 (2024, contraceptive coverage mandate). His framing centers on expanding coverage through Medicaid and insurance regulation rather than a single-payer system.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/healthcare',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB819'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / civil-rights / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Krizek co-patroned HB 139 (2022, extending the Commission to Study Slavery and Racial and Economic Discrimination Against African Americans) and HB 18 (2024, expanding hate crime protections to include ethnic origin, passed unanimously). He supported Virginia''s 2020 Values Act extending LGBTQ+ non-discrimination protections and voted to ratify the Equal Rights Amendment.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB18',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+bil+HB139',
    'https://www.paulkrizek.com/equality'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / childcare / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Krizek co-patroned HB 1375 (2024/2025), which codifies the Virginia Preschool Initiative, Child Care Subsidy Program, and Mixed Delivery Grant Program for at-risk children. His campaign site identifies him as ''a strong proponent of expanding access to early childhood education, preschool, and quality childcare,'' believing these investments yield long-term savings.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?251+bil+HB1375',
    'https://www.paulkrizek.com/education'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / immigration / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Krizek''s campaign site supports DREAM Act beneficiaries receiving in-state tuition and driver''s licenses, and advocates for allowing undocumented residents to obtain driver''s licenses, noting approximately 250,000 Virginians lack access to safety training. He frames immigration policy around keeping families together and rewarding those following legal processes.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/supporting-immigrants'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / redistricting / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Krizek co-sponsored constitutional amendment legislation in 2016 and 2017 for nonpartisan redistricting commissions, and his campaign site states ''gerrymandering violates these principles'' of voters choosing representatives. He supported Virginia''s 2020 constitutional amendment creating the bipartisan Virginia Redistricting Commission, earning an endorsement from the National Democratic Redistricting Commission.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/redistricting'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ---- Paul E. Krizek / fossil-fuels / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'cd70f416-c844-41db-9ff4-c528e04a72be',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Krizek strongly supports Virginia''s participation in RGGI (the carbon trading program), authored HB 199 (2024) expanding the Brownfield and Coal Mine Renewable Energy Grant Fund, and co-patroned HB 471 (2022) requiring solar-ready roofs on new state buildings. His environmental positions consistently favor renewable transition over fossil fuel expansion, without calling for an immediate drilling ban.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.paulkrizek.com/environment',
    'https://legacylis.virginia.gov/cgi-bin/legp604.exe?241+bil+HB199'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Verification block scoped to Wave 10 (external_id BETWEEN -5120016 AND -5120011)
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120016 AND -5120011;
  RAISE NOTICE 'VA delegates with stances (Wave 10): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120016 AND -5120011
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 10): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found â€” migration blocked';
END $$;

COMMIT;
