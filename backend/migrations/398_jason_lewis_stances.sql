-- ============================================================================
-- Migration 398: Jason M. Lewis Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jason M. Lewis (MA State Senator, 25D23,
--   Fifth Middlesex District).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: a40f234e-1790-4b52-8670-090b6379eb03 (external_id: -210023)

BEGIN;

-- ----- Jason M. Lewis / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Lewis has been one of the most vocal state senators on expanding healthcare access. As Senate Chair of the Joint Committee on Public Health, he championed the 2022 mental health parity law and has been a strong advocate for universal healthcare coverage. He has backed legislation to study single-payer healthcare for Massachusetts and has consistently supported MassHealth expansion and protecting the ACA. He filed legislation to improve maternal health outcomes and has advocated for increased mental health funding throughout the state budget process.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.wbur.org/news/2022/11/21/massachusetts-mental-health-parity-law']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Lewis has been a leading voice for aggressive climate action. He voted for the 2021 Climate Act (Chapter 8) and has supported subsequent clean energy legislation. He has backed accelerated electric vehicle adoption, building electrification requirements, and offshore wind procurement. He has served on committees working on climate policy and has called for more ambitious emissions reduction targets. He consistently supports the most aggressive climate action proposals under consideration.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lewis has supported phasing out fossil fuels and has backed legislation restricting new fossil fuel infrastructure in Massachusetts. He has supported the gas ban pilot program allowing municipalities to ban new fossil fuel hookups in new construction. He consistently votes against fossil fuel industry positions and in favor of clean energy alternatives. He backed the 2024 clean energy law accelerating offshore wind and solar deployment as replacements for fossil fuel generation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://commonwealthbeacon.org/energy/natural-gas-ban-debate-heats-up-at-state-house/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Lewis supported the 2024 Affordable Homes Act and has backed the MBTA Communities zoning law requiring multifamily housing near transit. He has advocated for increased affordable housing production, anti-displacement protections, and inclusionary zoning requirements. His district includes communities like Malden and Medford that have faced significant gentrification pressure, and he has backed local tenant protections and anti-displacement measures alongside housing production.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Lewis supported the 2022 millionaires surtax (Question 1) adding a 4% surcharge on incomes over $1 million for education and transportation. He has consistently backed progressive taxation and opposed tax cuts that primarily benefit high earners. He supported the 2023 tax relief package while also advocating that its benefits be weighted toward lower- and middle-income residents rather than across-the-board cuts. He has backed increasing the minimum wage and expanding the earned income tax credit.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Lewis voted for the 2022 Work and Family Mobility Act extending driver licenses to undocumented immigrants. He has supported in-state tuition for undocumented students and opposed deportation enforcement policies that separate families. He backed the MA Drivers Licensing for All campaign and has advocated for expanded access to state services for immigrant residents. His district includes significant immigrant communities in Malden and Medford and he has been a consistent ally of those communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Lewis voted for the 2020 police reform law (Chapter 253) and has been a consistent supporter of criminal justice reform. He has advocated for mental health co-responder programs as alternatives to police for mental health crises and has backed diversion programs for drug offenses. He supported bail reform reducing pretrial detention for non-violent offenses. His approach emphasizes addressing root causes of crime through social services and treatment while supporting community-oriented policing.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.wbur.org/news/2020/12/01/massachusetts-police-reform-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Lewis has been a consistent champion of civil rights and anti-discrimination legislation. He supported the 2016 Transgender Public Accommodations Act and subsequent LGBTQ+ rights legislation. He has backed racial justice legislation including studies of systemic racism in state government and backed the Safe Communities Act protecting immigrant communities from discriminatory enforcement. He has been a vocal opponent of discrimination in housing, employment, and public services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.masslive.com/politics/2016/07/massachusetts-transgender-rights-anti-discrimination-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Lewis represents a district well served by the MBTA Orange Line and Green Line Extension, and has been a strong transit advocate. He backed the 2022 free MBTA fare pilot and has consistently supported increased MBTA capital funding for state of good repair. He has advocated for fare-free transit and has backed active transportation (cycling and walking) infrastructure. He supports prioritizing transit investment over highway expansion as a climate and equity strategy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.wbur.org/news/2022/08/01/free-mbta-fares-pilot-program-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Lewis voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. He has supported automatic voter registration and legislation to allow same-day voter registration. He has been a vocal critic of voter suppression efforts nationally and has backed all Massachusetts expansions of voting access. He supported the option to vote by mail without needing an excuse as a permanent right for Massachusetts voters.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Lewis served as Senate Chair of the Joint Committee on Education and has been a strong advocate for universal pre-K and subsidized childcare. He backed the major early education funding increases in the FY2024 and FY2025 budgets and has filed legislation to make childcare affordable for all Massachusetts families regardless of income. He has supported increases in childcare worker wages and the Child and Family Tax Credit expansion.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.wbur.org/news/2023/07/31/massachusetts-childcare-funding-budget']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jason M. Lewis / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a40f234e-1790-4b52-8670-090b6379eb03',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Lewis has opposed school voucher programs and charter school expansion beyond what is needed to serve students effectively. He voted against the 2016 Question 2 ballot initiative to expand charter school seats. As Senate Education Chair, he has focused on improving public schools rather than diverting funding to private or charter alternatives. He has expressed concern that voucher programs drain resources from public schools and leave the most disadvantaged students behind.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/jml0', 'https://www.masslive.com/politics/2016/10/question_2_charter_schools_massachusetts.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'a40f234e-1790-4b52-8670-090b6379eb03'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
