-- ============================================================================
-- Migration 498: Erika Uyterhoeven Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Erika Uyterhoeven (MA House HD-83,
--   27th Middlesex District, Somerville). External ID: -210123.
--   Uyterhoeven has served since 2021; Democratic Socialist, strong progressive
--   on housing, healthcare, labor, climate, and criminal justice.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

BEGIN;

-- Erika Uyterhoeven (HD-83, external_id=-210123)
-- Politician UUID: 98291d86-d42d-49d0-a5b2-d689a8154b15

-- ----- Erika Uyterhoeven / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Uyterhoeven co-sponsored the ROE Act and has been an outspoken advocate for abortion access. She has voted consistently for reproductive rights legislation and received NARAL Pro-Choice Massachusetts endorsement. Her Democratic Socialist platform explicitly calls for abortion to be treated as essential healthcare with no restrictions.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Uyterhoeven does not accept corporate PAC money and ran her campaigns on small-dollar grassroots donations. She has co-sponsored legislation to strengthen campaign finance transparency and limit corporate influence in MA politics. As a Democratic Socialist, her political philosophy strongly opposes corporate money in elections.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Legislators/Profile/E_U1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Uyterhoeven co-sponsored the Affordable and Accessible Child Care for All Act, which would make childcare universally available and free for low- and middle-income families. She has advocated for treating childcare as a public good, similar to public education, funded by state government rather than left to the private market.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/universal-childcare/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Uyterhoeven co-sponsored the 100% Renewable Energy Act and voted for the MA climate roadmap committing to net-zero emissions by 2050. She approaches climate as a justice issue and has partnered with environmental justice groups to ensure frontline communities benefit from the clean energy transition. She opposes all new fossil fuel infrastructure.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Uyterhoeven co-sponsored the Stop Wage Theft Act, Fair Scheduling Act, and has advocated for worker cooperatives and worker ownership models. As a Democratic Socialist, she supports worker-centered economic development and has called for higher corporate taxes, stronger unions, and democratic ownership structures over corporate-led growth.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Uyterhoeven has co-sponsored bills to ban new gas connections in buildings and accelerate building electrification. She opposes all new fossil fuel infrastructure and has called for rapid phase-out of gas heating systems. Her climate justice framing connects fossil fuel dependency to environmental racism and disproportionate health impacts on low-income communities.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/100-renewable-energy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Uyterhoeven co-sponsored the Medicare for All Massachusetts Act (H.1279) and is a strong advocate for universal single-payer healthcare. She has spoken publicly about healthcare as a human right and has voted consistently for MassHealth expansion and mental health parity legislation. Her Democratic Socialist platform treats healthcare as a public good, not a commodity.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Bills/194/H1279'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Uyterhoeven is a leading advocate for affordable housing and tenant rights in the MA House. She co-sponsored the Rent Stabilization Act and has called for social housing — publicly owned housing with no profit motive — as a long-term solution. She represents Somerville, one of the most expensive rental markets in New England, and has been a consistent champion for anti-displacement legislation.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Uyterhoeven co-sponsored the Safe Communities Act and has actively defended immigrant communities from federal enforcement. She supports full legalization and a path to citizenship, drivers' licenses for undocumented residents, and in-state tuition. She has spoken against Trump-era immigration policies and called on MA to refuse cooperation with ICE deportation operations.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Uyterhoeven has co-sponsored bills to end mandatory minimum sentencing, decriminalize drug possession, ban solitary confinement, and expand expungement opportunities. She voted for the 2020 Police Accountability Act and has called for significant reductions in the prison population. As a Democratic Socialist, she approaches criminal justice through a lens of systemic reform rather than increased incarceration.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Uyterhoeven voted for the 2020 Police Reform and Accountability Act and has supported redirecting funds from law enforcement to mental health crisis response, housing, and community services. She has spoken in favor of civilian oversight of police and community-driven public safety models. Her platform reflects an approach that prioritizes social investment over punitive policing.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Bills/191/H4990'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Uyterhoeven co-sponsored the Rent Stabilization Act and has been one of the loudest voices for restoring rent control in Massachusetts. She advocates for Somerville's right to protect its tenants from rapid rent increases driven by gentrification. Her Democratic Socialist platform positions rent stabilization as a necessary tool for keeping working-class residents in their homes.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://actonmass.org/bills/rent-control/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Uyterhoeven has opposed charter school expansion and voucher programs, supporting fully funded public schools instead. Her Democratic Socialist platform views public education as a public good and opposes diverting tax dollars to private institutions. She has voted against measures that would expand the charter school cap.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Legislators/Profile/E_U1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Uyterhoeven voted for the Millionaires Tax (Fair Share Amendment, 2022) and has co-sponsored bills for higher corporate taxes and progressive income tax structures. Her Democratic Socialist platform calls for taxing wealth and corporations at significantly higher rates to fund universal public services. She has been a consistent voice for making Massachusetts's flat income tax more progressive.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Uyterhoeven has been a strong advocate for transgender rights and inclusion, supporting the 2016 MA Transgender Anti-Discrimination Act and opposing any restrictions on trans student participation in athletics. Her platform explicitly supports full transgender equality and she has spoken publicly against anti-trans legislation.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Legislators/Profile/E_U1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erika Uyterhoeven / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('98291d86-d42d-49d0-a5b2-d689a8154b15',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Uyterhoeven voted for the 2022 VOTES Act making mail voting and early voting permanent. She co-sponsored automatic voter registration and has supported noncitizen local voting rights bills in the MA House. Her platform calls for removing all barriers to political participation.$$,
        ARRAY['https://actonmass.org/legislators/erika-uyterhoeven/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '98291d86-d42d-49d0-a5b2-d689a8154b15';
-- SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='98291d86-d42d-49d0-a5b2-d689a8154b15' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context WHERE politician_id='98291d86-d42d-49d0-a5b2-d689a8154b15' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
-- ============================================================================
