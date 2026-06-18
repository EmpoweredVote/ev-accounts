-- ============================================================================
-- Migration 505: Christine P. Barber Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Christine P. Barber (MA House HD-90,
--   34th Middlesex District, Somerville). External ID: -210130.
--   Barber has served since 2014; progressive Democrat representing Somerville,
--   strong record on healthcare, housing, climate, and labor rights.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Christine P. Barber (HD-90, external_id=-210130)
-- Politician UUID: 7cbdb829-4836-49e9-afb2-cb8035afc6bf

-- ----- Christine P. Barber / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Barber co-sponsored the ROE Act (H.3320) to codify and expand abortion rights in Massachusetts. She has been a consistent advocate for reproductive rights and received NARAL Pro-Choice Massachusetts endorsement. Her progressive Somerville district and ActOnMass record confirm strong support for abortion access.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Barber has co-sponsored campaign finance transparency legislation and has run her campaigns primarily on small-dollar donations. She has supported bills to increase disclosure requirements for political spending and limit corporate influence in MA elections. Her record reflects progressive-Democratic support for campaign finance reform.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Legislators/Profile/CPB2'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Barber co-sponsored the Affordable and Accessible Child Care for All Act to make childcare universally available and subsidized for working families. She has been a strong voice for early education funding and has supported universal pre-K programs. Her Somerville district has many young families and she has championed public childcare investment.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/universal-childcare/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Barber co-sponsored the 100% Renewable Energy Act and voted for the 2021 climate roadmap. She has supported offshore wind investment, building electrification, and legislation to ban new fossil fuel infrastructure in buildings. Somerville's commitment to climate action aligns with her legislative positions on aggressive emissions reduction.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Barber co-sponsored the Stop Wage Theft Act and the Fair Scheduling Act, supporting worker-protective economic policies. She has backed minimum wage increases and worker rights legislation. Her economic record reflects progressive priorities: worker ownership, living wages, and community-centered economic development over corporate tax incentives.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Barber has co-sponsored bills to ban new gas connections in buildings and accelerate building electrification as part of the fossil fuel phase-out. She backed the 100% Renewable Energy Act and has consistently opposed new fossil fuel infrastructure. Her votes reflect a strong commitment to ending MA's dependency on fossil fuels.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Barber co-sponsored the Medicare for All Massachusetts Act (H.1279) and is a leading advocate for universal single-payer healthcare. She has consistently supported MassHealth expansion, mental health parity, and bills to make healthcare more affordable. Her progressive record on healthcare reflects a commitment to universal coverage as a public right.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Barber is a strong housing affordability advocate representing Somerville, one of the most expensive rental markets in New England. She co-sponsored the Rent Stabilization Act and has pushed for affordable housing funding, community land trusts, and anti-displacement measures. She has been a prominent voice for tenant rights and has supported legislation to expand housing access for low- and moderate-income residents.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Barber co-sponsored the Safe Communities Act to limit MA cooperation with federal immigration enforcement. She has supported the DREAM Act, drivers' licenses for undocumented residents, and comprehensive immigrant rights legislation. Somerville declared itself a sanctuary city and she has championed immigrant protective policies at the state level.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Barber voted for the 2018 criminal justice reform omnibus and the 2020 Police Accountability Act. She has co-sponsored bills to end mandatory minimums, expand expungement, ban solitary confinement, and decriminalize drug possession for personal use. Her criminal justice record reflects progressive reform priorities focused on rehabilitation and reducing mass incarceration.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Barber voted for the 2020 Police Reform and Accountability Act creating the POST Commission. She has supported community-based violence prevention programs and mental health crisis response alternatives to traditional policing. Her approach emphasizes investing in social services alongside law enforcement reform.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Barber co-sponsored the Rent Stabilization Act and has been an active advocate for restoring rent control as a local option in Massachusetts. She has testified before committees on rent stabilization and works closely with Somerville tenant advocacy organizations. Her housing platform reflects a strong commitment to anti-displacement policies and tenant protections.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Barber voted for the 2022 Millionaires Tax (Fair Share Amendment) and has co-sponsored additional progressive tax measures including higher corporate taxes and closing loopholes. Her record reflects consistent support for making the tax system more progressive to fund public services and reduce inequality.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christine P. Barber / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7cbdb829-4836-49e9-afb2-cb8035afc6bf',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Barber voted for the 2022 VOTES Act making early voting and vote-by-mail permanent. She has co-sponsored automatic voter registration and supported noncitizen local voting rights legislation. Her record reflects strong support for expanding voter access and reducing barriers to participation.$$,
        ARRAY['https://actonmass.org/legislators/christine-barber/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7cbdb829-4836-49e9-afb2-cb8035afc6bf';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='7cbdb829-4836-49e9-afb2-cb8035afc6bf' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='7cbdb829-4836-49e9-afb2-cb8035afc6bf' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
