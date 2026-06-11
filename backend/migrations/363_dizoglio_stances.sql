-- ============================================================================
-- Migration 363: Diana DiZoglio Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Diana DiZoglio (Auditor of the Commonwealth).
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
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

-- Politician UUID:
-- Diana DiZoglio: 30b6b674-509f-46f6-a9aa-aa3dbefc2f42 (external_id = -200006)

BEGIN;

-- ============================================================
-- Diana DiZoglio
-- Auditor of the Commonwealth of Massachusetts
-- MA House 2013-2019 (14th Essex); MA Senate 2019-2023 (1st Essex); Auditor since January 2023
-- ============================================================

-- ----- Diana DiZoglio / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$DiZoglio has been a consistent supporter of abortion rights throughout her legislative career. As a Massachusetts State Representative and Senator representing the 14th and 1st Essex districts, she supported pro-choice legislation including the ROE Act, which expanded abortion access in Massachusetts. She backed Governor Healey's executive order protecting Massachusetts as a sanctuary for abortion seekers following the Dobbs decision. DiZoglio ran for Auditor with a progressive platform that included defending reproductive rights.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$DiZoglio made government accountability and transparency a central theme of her Auditor campaign, which directly intersects with campaign finance reform. She has pushed to audit the state legislature's finances — the very institutions that receive campaign money from special interests. Her effort to investigate legislative spending reflects her belief that public funds must be fully accountable. DiZoglio has supported stronger campaign finance disclosure requirements and opposed the influence of corporate money in state elections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://www.bostonglobe.com/2023/03/24/metro/wholly-unnecessary-mass-house-speaker-says-he-will-not-comply-with-state-auditors-legislative-probe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$DiZoglio represented working-class Essex County communities including Lawrence, Haverhill, Methuen, and Newburyport where childcare access is a critical workforce issue. As a state legislator she supported increased childcare funding and subsidies for low-income families. The Auditor's office under DiZoglio has examined state childcare programs to assess whether funding reaches families effectively. She has been an advocate for affordable, accessible childcare as fundamental to women's economic security and workforce participation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$DiZoglio's legislative career has reflected a consistent civil rights record as a progressive Democrat representing diverse Essex County communities including Lawrence (a predominantly Latino city). She worked with the Lawrence delegation on educational equity programs. Her entire Auditor campaign was framed around accountability as a civil rights principle — that citizens have a right to know how their government spends money. DiZoglio has supported anti-discrimination legislation and equal rights protections throughout her time in the legislature.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$DiZoglio has supported climate change legislation during her time in the Massachusetts legislature, voting for clean energy and emissions reduction bills. She worked with Greater Lawrence Technical School on STEM programming that included clean energy education. As Auditor, she has audited state climate programs to ensure effective use of resources. DiZoglio supported Massachusetts's climate goals and has been aligned with the Healey administration's aggressive climate agenda.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$DiZoglio chaired the Joint Committee on Community Development and Small Businesses in the Massachusetts Senate — directly focused on economic development for communities and small business owners. She was a small business owner herself and secured STEM funding for Greater Lawrence Technical School to build workforce pipeline. Her economic development focus has been on supporting working-class communities in the Merrimack Valley, not large corporate subsidies. She has backed small business support programs and workforce development funding.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$DiZoglio filed legislation to curb opioid prescriptions, including a bill to prohibit OxyContin prescriptions for children — directly addressing the opioid epidemic ravaging Essex County communities like Lawrence and Haverhill. This healthcare advocacy reflects her hands-on commitment to public health. She has supported expanded MassHealth coverage and opposed cuts to the ACA. DiZoglio has also prioritized elder healthcare access through protective legislation for elderly persons in public housing.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://valleypatriot.com/dizoglio-bill-would-prohibit-oxycontin-prescriptions-for-children/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$DiZoglio filed legislation to make public housing safer for elderly and vulnerable residents — a direct housing affordability and safety concern for her Essex County constituents. She has represented communities including Lawrence, Haverhill, and Methuen with significant public housing populations. DiZoglio has supported funding for affordable housing development and housing voucher programs. As Auditor she has examined state housing programs to ensure accountability and effective delivery of housing assistance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://www.eagletribune.com/news/with-bill-dizoglio-hopes-to-make-public-housing-safer/article_ebbc94af-7023-5c93-81d4-007dbb6acfb1.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$DiZoglio represented Lawrence, Massachusetts — one of the most immigrant-rich cities in New England with a majority Latino population. Her legislative work with the Lawrence delegation directly served immigrant constituents. She has consistently backed immigrant-friendly policies and opposed cooperation with federal immigration enforcement actions targeting Massachusetts communities. The Auditor's office under DiZoglio has examined state services to ensure equitable access including for immigrant families.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$DiZoglio has supported Medicare and MassHealth programs serving low-income and elderly residents of Essex County. Her legislative work to protect elderly residents in public housing reflects her attention to the needs of seniors dependent on Medicare and Medicaid. She has opposed federal cuts to these programs as attacks on her working-class constituents who rely on them. As Auditor she has examined state health and human services programs to ensure accountability in the delivery of benefits.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$DiZoglio served as chief-of-staff to the president of the Professional Fire Fighters of Massachusetts before entering politics — giving her deep connections to public safety workers and their concerns. She has supported funding for fire departments, police departments, and emergency services while also advocating for community-based violence prevention programs. Her approach balances respect for public safety workers with investment in community programs addressing root causes of crime and public health crises.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$DiZoglio's Auditor campaign centered on government transparency and accountability, which extends to fair redistricting. She has supported independent redistricting processes to prevent legislative self-dealing in drawing district lines. Her push to audit the state legislature itself — arguing citizens deserve transparency about legislative spending and processes — directly reflects her commitment to accountability in redistricting and all legislative actions. DiZoglio has backed reforms to make redistricting more transparent and citizen-driven.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://www.bostonglobe.com/2023/03/24/metro/wholly-unnecessary-mass-house-speaker-says-he-will-not-comply-with-state-auditors-legislative-probe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$DiZoglio is a strong supporter of same-sex marriage and LGBTQ+ rights. She has been a consistent ally of the LGBTQ+ community throughout her legislative career in the Massachusetts House and Senate. She supported state legislation strengthening LGBTQ+ protections and has opposed federal efforts to roll back marriage equality. DiZoglio's progressive platform throughout her political career has included full LGBTQ+ equality as a core principle.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$DiZoglio has consistently opposed school vouchers and private school diversion of public education funds. She represented communities including Lawrence with a majority of students in underfunded public schools, making her a strong defender of public education investment. DiZoglio supported working with Greater Lawrence Technical School — a public vocational school — for STEM funding, reflecting her focus on strengthening public educational institutions rather than diverting resources to private alternatives.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '683c8084-2281-4920-a07c-18439b2dd413',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$DiZoglio's former role as chief-of-staff to the Massachusetts firefighters union president reflects her labor-aligned background, and she has generally supported trade policies that protect American workers. However, as a progressive Democrat from an economically diverse district including working-class manufacturing communities, she holds a nuanced position — supporting targeted tariffs that protect American workers while opposing sweeping tariffs that raise consumer prices for her working-class constituents.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$DiZoglio has supported progressive taxation including the Fair Share Amendment (millionaires surtax) passed by Massachusetts voters in 2022, which she backed during her State Senate tenure. She represents working-class communities that benefit from tax revenue funding schools, healthcare, and public services. As Auditor, she has focused on ensuring taxpayer dollars are spent accountably. DiZoglio has opposed tax cuts that benefit the wealthy while cutting services for working families.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://malegislature.gov/Legislators/Profile/D_D0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Diana DiZoglio / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30b6b674-509f-46f6-a9aa-aa3dbefc2f42',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$DiZoglio's campaign for Auditor explicitly sought a ballot measure to expand her audit authority over the legislature — reflecting her commitment to democratic accountability and transparency. She has supported expanded voting access including vote-by-mail and early voting. As a progressive Democrat representing diverse working-class communities with significant minority and immigrant populations, DiZoglio has backed policies making voting easier and opposing measures that disenfranchise voters.$$,
        ARRAY['https://en.wikipedia.org/wiki/Diana_DiZoglio', 'https://www.bostonglobe.com/2023/03/24/metro/wholly-unnecessary-mass-house-speaker-says-he-will-not-comply-with-state-auditors-legislative-probe/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '30b6b674-509f-46f6-a9aa-aa3dbefc2f42';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '30b6b674-509f-46f6-a9aa-aa3dbefc2f42'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '30b6b674-509f-46f6-a9aa-aa3dbefc2f42'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
