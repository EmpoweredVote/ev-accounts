-- ============================================================================
-- Migration 511: Ronald Mariano Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Ronald Mariano (MA House HD-96,
--   3rd Norfolk District, Quincy). External ID: -210136.
--   Mariano has served since 1992 and is the Speaker of the MA House of
--   Representatives since 2021. As Speaker, his public record is extensive.
--   Target 8-12 stances per plan directive.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Ronald Mariano (HD-96, external_id=-210136)
-- Politician UUID: 5fdefd59-b543-4221-b6ed-b33532f9bd5f

-- ----- Ronald Mariano / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As Speaker of the House, Mariano facilitated passage of the ROE Act and similar reproductive rights legislation. He voted for the ROE Act and has made clear that the House will protect abortion access in Massachusetts. After the Supreme Court's Dobbs decision, Speaker Mariano reinforced the legislature's commitment to reproductive rights.$$,
        ARRAY['https://www.bostonglobe.com/2022/06/24/metro/massachusetts-reaction-supreme-court-dobbs/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$As Speaker, Mariano has not been a champion of campaign finance reform and has maintained large campaign finance accounts backed by business and real estate interests. The House under his leadership has not advanced comprehensive campaign finance reform bills. His position as Speaker makes him a beneficiary of the current campaign finance system, reflecting a more cautious approach than progressive reform advocates would prefer.$$,
        ARRAY['https://www.opensecrets.org/', 'https://www.bostonglobe.com/2021/01/21/metro/mariano-elected-house-speaker/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Speaker Mariano moved the 2021 MA climate roadmap bill through the House and it passed under his leadership, committing Massachusetts to net-zero emissions by 2050. However, he has been more cautious than climate activists on aggressive mandates, preferring a balanced approach sensitive to ratepayer and business impacts. He supports clean energy investment but is not the lead champion for the most ambitious climate proposals.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://www.bostonglobe.com/2021/03/25/metro/house-sends-climate-bill-mariano/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$As Speaker, Mariano has championed economic development bills including the 2024 economic development bill, emphasizing job creation, housing, and business incentives. He takes a centrist Democratic approach to economic development: supporting both business incentives for growth and worker protections like minimum wage increases. His record reflects pragmatic, growth-focused economic development rather than purely worker-centered or purely business-friendly policy.$$,
        ARRAY['https://www.bostonglobe.com/2024/08/01/metro/massachusetts-economic-development-bill-2024/', 'https://malegislature.gov/Legislators/Profile/R_M1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Speaker Mariano led the House in passing a major behavioral health bill in 2023, expanding access to mental health and substance use treatment. He supported MassHealth expansion and healthcare cost-control legislation. His healthcare record reflects support for expanding access within the existing mixed public-private system rather than single-payer approaches; he did not champion the Medicare for All Massachusetts Act.$$,
        ARRAY['https://www.bostonglobe.com/2023/10/23/metro/massachusetts-behavioral-health-legislation/', 'https://malegislature.gov/Legislators/Profile/R_M1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Speaker Mariano led the House in passing major housing legislation including the 2024 Affordable Homes Act, which included significant new affordable housing funding, the HOME Act, and MBTA Communities zoning reform. He has made housing production a legislative priority, though he has not championed rent stabilization and has taken a production-focused approach rather than tenant-protection-first framing.$$,
        ARRAY['https://www.bostonglobe.com/2024/08/01/metro/massachusetts-affordable-homes-act-2024/', 'https://malegislature.gov/Legislators/Profile/R_M1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Mariano voted for the Work and Family Mobility Act (drivers' licenses for all residents) and the DREAM Act. As Speaker, he navigated the MA emergency shelter crisis related to migrant influx in 2023-2024, balancing compassion with fiscal constraints. His approach reflects moderate Democratic immigration policy: supporting legal pathways and immigrant services while being more cautious on enforcement limitation bills.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/R_M1', 'https://www.bostonglobe.com/2023/10/01/metro/massachusetts-shelter-crisis-migrants/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Mariano voted for the 2018 criminal justice reform omnibus and the 2020 Police Accountability Act. As Speaker, he has taken a pragmatic approach to criminal justice: supporting some reforms while also emphasizing public safety concerns from his South Shore district. He moved behavioral health legislation expanding treatment options, which serves as an alternative pathway to incarceration. His record reflects a moderate Democratic position on criminal justice reform.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2700', 'https://www.bostonglobe.com/2021/01/21/metro/mariano-elected-house-speaker/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Speaker, Mariano oversaw the 2023 MA tax reform package, which cut some taxes including estate tax and short-term capital gains while also providing targeted relief for working families (child care credit, rental deduction increase). He supported the 2022 Millionaires Tax (Fair Share Amendment). His approach to taxation is moderate-progressive: supporting some redistribution while also making strategic cuts to maintain business competitiveness.$$,
        ARRAY['https://www.bostonglobe.com/2023/09/26/metro/massachusetts-tax-relief-package-governor-healey/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Ronald Mariano / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5fdefd59-b543-4221-b6ed-b33532f9bd5f',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Mariano voted for the 2022 VOTES Act making early voting and vote-by-mail permanent. He has supported ballot access expansion as part of his legislative record. His approach to voting rights reflects mainstream Democratic support for expanded access without leading the most ambitious reform proposals.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2977', 'https://malegislature.gov/Legislators/Profile/R_M1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5fdefd59-b543-4221-b6ed-b33532f9bd5f';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='5fdefd59-b543-4221-b6ed-b33532f9bd5f' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
