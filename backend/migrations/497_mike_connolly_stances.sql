-- ============================================================================
-- Migration 497: Mike Connolly Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Mike Connolly (MA House HD-82,
--   26th Middlesex District, Cambridge/Somerville). External ID: -210122.
--   Connolly has served since 2017; strong progressive on housing, healthcare,
--   climate, and criminal justice reform.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Mike Connolly (HD-82, external_id=-210122)
-- Politician UUID: 49963775-d2d5-4ae2-95cf-b2b8d0ed2a92

-- ----- Mike Connolly / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Connolly co-sponsored the ROE Act (H.3320), which codifies and expands abortion rights in Massachusetts beyond what Roe v. Wade required. He has consistently voted for reproductive rights legislation and received NARAL Pro-Choice Massachusetts endorsement. His ActOnMass scorecard shows 100% support on reproductive rights issues.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Connolly co-sponsored the 100% Renewable Energy Act and voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has been a vocal advocate for building electrification, offshore wind investment, and an end to new fossil fuel infrastructure. He is one of the most active climate legislators in the MA House, frequently testifying and filing bills related to clean energy transition.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Connolly co-sponsored the Stop Wage Theft Act, Fair Scheduling Act, and minimum wage increase bills, supporting worker-centered economic policies. He has advocated for locally-owned businesses and community land trusts over large corporate development. His record reflects support for economic equity measures including employee ownership and worker protections.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Connolly has been a leading House voice for ending fossil fuel dependency, co-sponsoring bills to ban new gas connections in buildings, accelerate building electrification, and end fossil fuel subsidies. He supports the 100% Renewable Energy Act and has called for divestment of public funds from fossil fuel companies. He regularly partners with Sunrise Movement and 350.org on fossil fuel phase-out campaigns.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Connolly co-sponsored the Medicare for All Massachusetts Act (H.1279) and has been a consistent advocate for universal single-payer healthcare. He has supported MassHealth expansion, mental health parity bills, and legislation to cap prescription drug prices. His ActOnMass record shows consistent progressive votes on healthcare access.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Connolly has co-sponsored legislation to fund permanent supportive housing and mental health/substance use services as part of a Housing First approach to homelessness. He has opposed criminalization of homelessness and supported emergency shelter funding. His district (Cambridge/Somerville) has active homelessness response programs that he has championed at the state level.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Legislators/Profile/M_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Connolly is one of the most vocal housing affordability advocates in the MA House. He co-sponsored the Rent Stabilization Act to restore rent control as a local option and has pushed for increased public housing funding, community land trusts, and anti-displacement measures. He represents one of the most expensive housing markets in the country and has written extensively on housing policy reform.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Connolly co-sponsored the Safe Communities Act to limit MA cooperation with federal immigration enforcement and has supported the DREAM Act and drivers' licenses for undocumented residents. He represents a district with large immigrant communities and has been a consistent defender of immigrant rights. He spoke publicly against ICE enforcement actions in Cambridge and Somerville.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Connolly voted for the 2018 criminal justice reform omnibus and the 2020 Police Accountability Act. He has co-sponsored bills to end mandatory minimum sentencing, expand expungement, ban solitary confinement, and decriminalize drug possession for personal use. He is among the most progressive House members on criminal justice reform, consistently supporting decarceration and restorative justice approaches.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Connolly co-sponsored the Medicare for All Massachusetts Act and has consistently voted to protect and expand MassHealth. He has supported legislation to restore MassHealth coverage that was cut and to expand eligibility. His record reflects strong commitment to universal government-funded healthcare coverage.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Connolly voted for the 2020 Police Reform and Accountability Act and has supported redirecting resources from punitive policing toward mental health crisis response and community services. He has called for civilian oversight of law enforcement and supported the SAFE Communities Act to limit police involvement in immigration enforcement.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Connolly is a primary sponsor of the Rent Stabilization Act and has been one of the most prominent voices for restoring the local option for rent control in Massachusetts. He has testified repeatedly before the Joint Committee on Housing on behalf of rent stabilization and written op-eds calling for anti-displacement measures in Cambridge and Somerville.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Connolly has consistently supported LGBTQ equality legislation, including marriage equality and transgender anti-discrimination protections. He represents Cambridge, the first US city where same-sex couples were legally married in 2004, and has voted for all LGBTQ rights bills during his tenure.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Legislators/Profile/M_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Connolly has opposed charter school expansion and voucher programs, supporting strong public school funding instead. He voted against measures to expand the charter school cap and has advocated for fully-funded public education. His ActOnMass scorecard reflects opposition to privatizing public school resources.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Legislators/Profile/M_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Connolly voted for the 2022 Millionaires Tax (Fair Share Amendment, Question 1) adding a 4% surtax on income over $1 million. He has co-sponsored progressive tax bills including corporate minimum taxes and closing loopholes benefiting wealthy interests. His record reflects consistent support for making the tax system more progressive to fund public services.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Connolly has supported transgender inclusion in all aspects of public life including school sports. He voted for the MA Transgender Anti-Discrimination Act and opposed bills that would restrict trans student participation in athletics. His progressive record and Cambridge/Somerville district reflect full support for transgender rights.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Legislators/Profile/M_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Mike Connolly / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Connolly voted for the 2022 VOTES Act making early voting and mail voting permanent in Massachusetts. He has co-sponsored automatic voter registration, same-day registration, and noncitizen local voting bills. He is a strong proponent of expanding voter access and removing barriers to political participation.$$,
        ARRAY['https://actonmass.org/legislators/mike-connolly/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
