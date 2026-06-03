-- Correction migration for Roger Niello (politician_id: 22152e41-31b9-4700-9226-4e274c616f37)
-- CA State Senator, Senate District 6 (Sacramento/Placer County)
-- Source date: 2026-06-02 (research from batch-A CSV)
-- Corrections: 10 topics updated from original values (most at value=2) to researched values (3-4)
-- Topics corrected: taxes, healthcare, campaign-finance, ai-regulation, climate-change,
--   civil-rights, housing, homelessness, medicare/aid, school-vouchers

BEGIN;

-- taxes: value corrected to 4 (campaign platform, voted NO on Budget Acts, former CPA/auto CFO)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Niello''s 2026 campaign platform explicitly states California has the ''highest in the nation taxes'' and is an ''unsustainable place to start a family or grow a business.'' He voted NO on Budget Act of 2025 (SB-219, SB-100, SB-180, SB-200 — multiple versions) consistently opposing the state''s spending plan. He is a former CPA, former auto business CFO, and Sacramento Metro Chamber president who ran on tax competitiveness. This aligns with value 4 (cut taxes for everyone and scale back public services to match).',
  ARRAY['https://rogerniello.com/issues/', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB219', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB100']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- healthcare: value corrected to 3 (authored SB-1002 telehealth access, supports targeted expansion)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Niello authored SB-1002, expanding telehealth access by allowing out-of-state physicians to practice in California via telehealth without a full CA license — explicitly designed to increase healthcare access in underserved areas. His campaign states ''healthcare costs are too high and access to care limited'' and promises to expand access. He voted YES on SB-717 (cancer registry program). He opposes government-run healthcare (consistent with his Republican fiscal conservatism and voting NO on budget expansions) but supports targeted access improvements. This fits value 3 (help people who can''t afford care and expand programs for seniors and low-income residents, while keeping private insurance for everyone else).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1002', 'https://rogerniello.com/issues/', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB717']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- campaign-finance: value corrected to 3 (voted NO on public financing, YES on disclosure)
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Niello voted NO on SB-42 (public campaign financing / California Fair Elections Act of 2026 — establishing public funding for state elections), indicating he opposes public campaign finance. However, he voted YES on SB-900 (Political Reform Act: requiring disclosure of top contributors in political advertising). This pattern — opposing publicly funded campaigns but supporting contributor disclosure requirements — matches value 3 (require full disclosure of all political donations).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB42', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB900']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- ai-regulation: value corrected to 2 (voted NO on SB-7 employer AI disclosure mandate)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'ai-regulation'),
  'Niello voted NO on SB-7 (Employment: automated decision systems), which would have required employers to disclose and regulate AI use in employment decisions and establish worker protections against automated decision systems. A NO vote on mandatory employer AI regulation suggests he prefers voluntary approaches over government mandates, fitting value 2 (suggest AI safety guidelines but let companies choose whether to follow them).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB7', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB7']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- climate-change: value corrected to 4 (voted NO on clean energy mandates, SB-541, SB-682)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Niello voted NO on SB-541 (electricity load shifting / clean energy mandates), indicating he opposes government-mandated clean energy programs. He also voted NO on SB-682 (banning PFAS/forever chemicals from non-essential uses). He voted NO on SB-131 (omnibus public resources budget bill). As a business-focused Republican from Sacramento/Placer County, his voting pattern on energy/environment bills consistently reflects market-oriented approaches over government mandates. This aligns with value 4 (let market forces drive any transition to cleaner energy sources).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB541', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB682']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- civil-rights: value corrected to 4 (voted NO on SB-48 discrimination prevention coordinators)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights'),
  'Niello voted NO on SB-48 (Educational equity: discrimination prevention coordinators), which would have required school districts to designate discrimination prevention coordinators and implement civil rights protections in schools. Authored by Senator Gonzalez, SB-48 expanded civil rights infrastructure. A NO vote indicates he does not support expanding government civil rights enforcement infrastructure, aligning with value 4 (limit federal civil rights enforcement to clear cases of discrimination).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB48', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB48']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- housing: value corrected to 4 (voted NO on SB-79 transit-oriented development)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing'),
  'Niello voted NO on SB-79 (Transit-Oriented Development housing), which would have allowed higher-density housing near transit corridors by overriding local zoning. His campaign site notes ''out-of-control housing costs'' and pledges to make California more affordable. As a business-oriented Republican who has been on the Budget Committee, Niello''s pattern of opposing government-mandated upzoning while favoring market-based solutions aligns with value 4 (cut regulations and zoning rules so private developers can build more housing).',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79', 'https://rogerniello.com/issues/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- homelessness: value corrected to 4 (campaign: root-cause enforcement over housing investment)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  'Niello''s campaign website states homelessness ''demands a new approach that addresses the root causes of much of the problem: mental health and substance abuse'' — framing that emphasizes accountability and treatment over decriminalization. He voted NO on SB-131 (Public Resources omnibus budget bill that included homelessness housing assistance funding). This combination of prioritizing root-cause (mental health/substance abuse) enforcement over direct housing investment, while opposing expanded homelessness budget programs, aligns with value 4 (prohibiting encampments on public property with graduated warnings and penalties, while requiring jurisdictions to maintain basic shelter options).',
  ARRAY['https://rogerniello.com/issues/', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB131']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- medicare/aid: value corrected to 4 (consistently voted NO on budget expansions, opposes expanded programs)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Niello consistently voted NO on budget expansion bills (Budget Acts SB-219, SB-100, SB-180, SB-200) and as a fiscal conservative Republican opposes expanded government healthcare programs. His campaign emphasizes reducing government spending and making California more affordable. He has not authored or voted for any Medicare/Medicaid expansion bills. His track record of opposing spending expansions while supporting market-based healthcare access (authored SB-1002 for telehealth licensing) aligns with value 4 (partially privatize Medicare and reduce Medicaid coverage), though his campaign states he would not eliminate these programs entirely.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB219', 'https://rogerniello.com/issues/']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

-- school-vouchers: value corrected to 4 (authored SB-399 interdistrict transfers, supports school choice)
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers');

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '22152e41-31b9-4700-9226-4e274c616f37',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Niello authored SB-399 (School districts: interdistrict transfers), which improves the process for students to transfer between school districts — a school choice mechanism within the public school system. His campaign states California schools should be #1 but ''special interest groups dominate our public school system.'' As a Republican who supports school choice within public systems and authored legislation expanding transfer rights, he aligns with value 4 (expanding voucher eligibility to most families so parents can choose the school that best fits their child, while maintaining baseline public school funding) — he supports school choice but has not publicly advocated for fully universal private school vouchers.',
  ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB399', 'https://rogerniello.com/issues/', 'https://ballotpedia.org/Roger_Niello']
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET
  reasoning = EXCLUDED.reasoning,
  sources = EXCLUDED.sources;

COMMIT;
