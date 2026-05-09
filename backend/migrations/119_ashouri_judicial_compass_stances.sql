-- Migration 119: Aida Ashouri judicial compass stances
-- politician_id: 0f6484bd-2fc1-4071-9648-d7b8a950d29c
-- Researched: 2026-05-09
-- Sources: Patch Q&A, LAist voter guide, aida4la.com platform, SPNA DTLA article, AOL/LA Times piece
-- All 6 applicable topics have placed stances (no "not found" topics for this candidate)

BEGIN;

-- ============================================================
-- Section A: politician_answers for all 6 placed stances
-- ============================================================

-- judicial-criminal-justice (value=2: fair chance through treatment/rehabilitation)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-access-to-justice (value=1: easy access; courts for everyone)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', '9d45acaf-1ba4-4cb8-95e1-5ed985223b91', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-government-deference (value=1: citizen-favoring; city must be held accountable)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', 'e5e48f0e-8f3a-40e1-8080-889fea389603', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-transparency (value=2: default to open; transparency and accountability)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', '6674d87e-999d-433a-aab7-3f626f59fd5f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-police-accountability (value=1: independent investigation; office works for the public)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', '7bad33eb-e93e-4d94-8822-97212d49bde5', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- judicial-prosecution-priorities (value=1: prosecution as last resort; treatment/housing first)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f6484bd-2fc1-4071-9648-d7b8a950d29c', 'abb99d95-cbb1-4617-8f8b-f220ef6028ca', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

-- ============================================================
-- Section B: politician_context (reasoning + sources) for all 6 topics
-- ============================================================

-- judicial-criminal-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'Ashouri frames criminal justice as rehabilitation and reform over punishment. In her Patch Q&A she stated: "As city attorney, I would reform the criminal division and train attorneys to recognize cases where constitutional rights are violated and to not file those cases. My goal would be to abolish racial profiling in my office." She describes allowing "changes in sentencing for non-violent cases to allow for people to seek rehabilitation and schooling" and making a policy "not to criminalize poverty." Her platform states she wants to "focus on drug rehabilitation and providing services like housing rather than criminalizing addiction or poverty." She explicitly supports diversion and restorative justice. She retains prosecution for serious/violent crimes and vehicular crimes, placing her at value 2 (fair chance through treatment/rehabilitation) rather than value 1.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://aida4la.com/platform'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-access-to-justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
  'Ashouri''s entire career and platform is built around eliminating legal barriers for low-income residents, renters, immigrants, and workers. The LAist voter guide notes her top priorities include "supporting renters and defending tenants from landlords." She frames the City Attorney''s Office as a vehicle for residents who cannot afford legal representation, commits to reopening the Code Enforcement Unit to help tenants, and explicitly opposes "expensive outsourcing to big law firms." Her platform commits to multilingual outreach and a hotline so workers can report wage theft — framing government legal resources as directly accessible to all residents. Her career history at Legal Aid Foundation of Los Angeles and Public Counsel (free legal services) reinforces this as a foundational value.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://aida4la.com/platform'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-government-deference
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  'e5e48f0e-8f3a-40e1-8080-889fea389603',
  'Inferred from overall platform framing across all sources. Ashouri''s platform is built on the premise that the City Attorney should hold the city government accountable, not reflexively defend it. The LAist voter guide quotes her: "We need new leadership that has the right experience, knowledge, and passion that will keep the City Council accountable." In her Patch Q&A she explicitly criticizes the incumbent for creating "an office catering to real estate interests" and describes the city as having "a terrible legacy of corruption and opaqueness." She states "the city should be held accountable for its negligence" on liability payouts (AOL/LA Times). Her civil rights and legal aid career — representing tenants, immigrants, and low-wage workers against powerful institutions including city government — consistently positions her as citizen-favoring. For City Attorney, this maps to value 1: regular people need the office to level the playing field against city government power, not to have the office reflexively defend city decisions.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://www.aol.com/news/guide-l-city-attorneys-race-100000010.html',
    'https://aida4la.com/platform'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-transparency
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  '6674d87e-999d-433a-aab7-3f626f59fd5f',
  'Inferred from general transparency framing and civil rights background — no specific quote on court-record transparency per se. The LAist voter guide reports she pledges to make the City Attorney''s Office "accountable to the people of Los Angeles" by restructuring it and "eliminating expensive outsourcing." Her Patch Q&A states she would use social media "to make the office more transparent and accountable" and describes her city as having "a terrible legacy of corruption and opaqueness, which disenfranchises the community." Her campaign website prominently lists accountability and transparency. Her civil-rights legal background — representing tenants and immigrants who need transparent legal processes to protect their rights — supports a strong default-open stance, consistent with value 2 (default to open; sealing requires compelling reason). No evidence for value 1 (everything must be public, secrecy always breeds injustice) specifically.',
  ARRAY[
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://aida4la.com/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-police-accountability
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  '7bad33eb-e93e-4d94-8822-97212d49bde5',
  'Ashouri has direct, specific positions on police accountability. Her Patch Q&A states: "As city attorney, I would reform the criminal division and train attorneys to recognize cases where constitutional rights are violated and to not file those cases. My goal would be to abolish racial profiling in my office. This will also impact the LAPD as they will be disincentivized to arrest when they knew that we would not file those cases." The LAist voter guide confirms she described "how overpolicing leads to racial profiling and the criminalization of poverty." Her platform explicitly commits to "protecting our rights to protest and be free from unreasonable search and seizure." The SPNA DTLA article summarizes: "Police Accountability: Emphasizes protecting the right to protest and freedom from unreasonable search and seizure." Her approach — using prosecutorial declination as an accountability mechanism against LAPD, abolishing racial profiling, declining unconstitutional cases — maps directly to value 1: the office investigates independently and works for the public, not for officials it is supposed to keep accountable.',
  ARRAY[
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://www.spna-dtla.org/blog/la-city-attorney-race-4-candidates-their-views',
    'https://aida4la.com/platform'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- judicial-prosecution-priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f6484bd-2fc1-4071-9648-d7b8a950d29c',
  'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
  'Ashouri consistently treats prosecution as a last resort, with treatment, mediation, and community services as preferred interventions. Her platform explicitly states "Housing over handcuffs" and focuses "on alternatives to incarceration." Her Patch Q&A describes dismissing cases where evidence was insufficient, allowing "changes in sentencing for non-violent cases to allow for people to seek rehabilitation," making a policy "not to criminalize poverty," and treating "substance abuse as a crime but a public health matter." Her platform commits to "prioritizing mediation and restorative justice" and restarting the Neighborhood Prosecutor program to "resolve issues without punitive measures." The AOL/LA Times piece quotes her: "We need to focus on cases that are harming people," implying prosecution reserved for genuine harm. She explicitly says "housing over handcuffs" and frames drug addiction as public health, not crime — maps directly to value 1: prosecution is a last resort; connecting people to treatment, housing, or job programs does more good than a criminal record.',
  ARRAY[
    'https://aida4la.com/platform',
    'https://patch.com/california/los-angeles/meet-aida-ashouri-candidate-los-angeles-city-attorney',
    'https://laist.com/news/politics/voter-guides/2026-election-california-primary-la-city-attorney',
    'https://www.aol.com/news/guide-l-city-attorneys-race-100000010.html'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Section C: "not found" context rows — NONE for this candidate
-- All 6 topics have placed stances with evidence.
-- ============================================================

COMMIT;
