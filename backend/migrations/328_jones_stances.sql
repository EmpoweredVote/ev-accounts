-- ============================================================================
-- Migration 328: Jay Jones Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jay Jones (Attorney General of Virginia).
--
-- Topic scope: All 44 compass topics attempted; evidence-only — topics with no
--   evidence are omitted entirely (no neutral defaults).
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

BEGIN;

-- ============================================================
-- Jay Jones
-- ============================================================

-- ----- Jay Jones / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Jones has a long documented record supporting abortion access. As a delegate he voted for the 2020 Reproductive Health Protection Act, which eliminated mandatory ultrasound requirements and other abortion restrictions. He served on the Virginia Planned Parenthood board and publicly stated "I've long supported a woman's right to choose." As AG candidate he committed to advancing a Virginia constitutional amendment protecting contraception, abortion care, and fertility treatment access, and received endorsements from Planned Parenthood Advocates of Virginia.$$,
        ARRAY['https://ballotpedia.org/Jay_Jones_(Virginia)',
              'https://virginiaindependentnews.com/elections/jay-jones-promises-to-protect-reproductive-rights-if-elected-virginias-attorney-general/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Jones voted to expand Medicaid as a delegate, citing coverage for 400,000 Virginians. He campaigned against federal Medicaid cuts under the One Big Beautiful Bill Act, warning 350,000 Virginians could lose coverage and rural hospitals could close. He also joined a bipartisan coalition of 44 attorneys general supporting pharmacy benefit manager transparency rules to lower drug costs. His stated position frames access to healthcare as something government must actively protect.$$,
        ARRAY['https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Civil rights enforcement is a defining pillar of Jones's career. As a private attorney he litigated on behalf of the Virginia NAACP against the Youngkin administration on voting rights. He pledged to create a Civil Rights Division within the AG's office and stated he would make "protecting civil rights a true priority for the Attorney General's Office." As AG his day-one actions included establishing a Voter Protection Unit and he has publicly challenged federal rollbacks of civil rights protections.$$,
        ARRAY['https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/',
              'https://virginiaindependentnews.com/elections/meet-the-candidate-former-del-jay-jones/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Jones supported repealing Virginia's statutory same-sex marriage ban as a delegate. He co-sponsored bills prohibiting the limitation of health coverage based on gender identity and backed legislation authorizing replacement birth certificates for transgender people. The Washington Blade documented his LGBTQ record as strongly affirmative in contrast to his 2025 opponent on all marriage equality and LGBTQ rights issues.$$,
        ARRAY['https://www.washingtonblade.com/2025/09/25/va-statewide-candidates-differ-widely-on-lgbtq-rights/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Jones's documented LGBTQ record consistently supports trans-inclusive policies. As a delegate he co-sponsored bills prohibiting discrimination in health coverage based on gender identity, supported transgender-inclusive school policies, backed replacement birth certificates for transgender individuals, and supported repealing the "gay panic" murder defense. GLAAD's 2025 election guide confirmed his record as fully supportive on LGBTQ rights.$$,
        ARRAY['https://www.washingtonblade.com/2025/09/25/va-statewide-candidates-differ-widely-on-lgbtq-rights/',
              'https://glaad.org/election-2025-va-gov-lt-gov-ag-candidates-record-lgbtq/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Jones has a clear documented record of expanding voting access. He cited his support as a delegate for increased early voting, Sunday voting, and same-day registration, stating Virginia moved from "49th hardest state" to "11th easiest" to vote. He litigated on behalf of the NAACP against Youngkin's voting restrictions. As AG he created a Voter Protection Unit and Voting Rights Hotline and issued an opinion requiring electoral boards to provide in-person absentee voting beginning 45 days before elections.$$,
        ARRAY['https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Jones consistently sided with immigrants across multiple documented votes and actions. In 2020 as a delegate he voted to grant in-state tuition to undocumented students and voted against a bill that would have prohibited sanctuary cities. As AG he reversed his predecessor's position to fully defend Virginia's in-state tuition law for undocumented students and joined a multistate lawsuit against the federal government's sharing of Medicaid data with ICE. He also co-led a coalition opposing a HUD rule that would strip housing support from mixed-status immigrant families.$$,
        ARRAY['https://ballotpedia.org/Jay_Jones_(Virginia)',
              'https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Jones opposed federal immigration enforcement cooperation at the state level. In 2020 as a delegate he voted to eliminate a requirement that jails report inmates' citizenship status to ICE and voted against a ban on sanctuary jurisdictions. As AG he reviewed his predecessor's opinion on honoring ICE detainers and announced he would develop guidance prioritizing community trust, and joined a lawsuit challenging federal use of Medicaid data for immigration enforcement.$$,
        ARRAY['https://ballotpedia.org/Jay_Jones_(Virginia)',
              'https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Jones took immediate action on climate upon becoming AG. On day one he filed a joint motion to facilitate Virginia's return to the Regional Greenhouse Gas Initiative (RGGI), stating RGGI "lowers costs for the most vulnerable Virginians while holding industries accountable to transition to cleaner, more stable, and more affordable sources of energy." He also joined a coalition of 24 states challenging the Trump EPA's unlawful rollback of the 2009 Greenhouse Gas Endangerment Finding.$$,
        ARRAY['https://insideclimatenews.org/news/23012026/virginia-attorney-general-takes-steps-to-rejoin-the-regional-greenhouse-gas-initiative/',
              'https://bluevirginia.us/2026/03/ag-jay-jones-joins-coalition-of-24-states-dc-etc-in-challenging-trump-epas-unlawful-rollback-of-2009-greenhouse-gas-endangerment-finding/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Jones received endorsement from Clean Virginia, whose endorsed candidates commit against accepting contributions from regulated electric utility monopolies Dominion Energy and Appalachian Power. He introduced legislation as a delegate to return overcharges from Dominion Energy to Virginia families. He has called for "a democratized energy system" no longer "overwhelmingly dictated by monopoly utilities" and advocated for transitioning to "cleaner, more stable, and more affordable sources of energy" through RGGI.$$,
        ARRAY['https://www.cleanvirginia.org/jayjones/',
              'https://insideclimatenews.org/news/23012026/virginia-attorney-general-takes-steps-to-rejoin-the-regional-greenhouse-gas-initiative/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Jones occupies a reform-leaning but balanced position on public safety. He voted for criminal justice reform bills as a delegate but also highlighted that the legislature allocated "the largest increase in funds for law enforcement in the history of this commonwealth" during his tenure. His AG campaign proposed a three-pillar public safety approach — stopping violent crime, removing illegal guns, and protecting children — developed in conjunction with state and local law enforcement. He emphasizes reform and enforcement as complementary goals.$$,
        ARRAY['https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/',
              'https://virginiaindependentnews.com/elections/2025-attorney-general-jones-miyares-safety-guns-violence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Jones supports reform but with nuance. He stated the Virginia Code contains "vestiges of the Black Codes and Jim Crow" needing a full overhaul, and his 2021 justice reform plan called for ending inequities in the judicial system. He proposed specialty dockets for mental health and addiction, violence intervention, and re-entry programs. However, he simultaneously supported historic law enforcement funding increases, sponsored bipartisan laws strengthening penalties for sex offenders and human trafficking, and emphasized prosecuting violent crime as an AG priority.$$,
        ARRAY['https://bluevirginia.us/2021/05/jay-jones-for-attorney-general-releases-justice-reform-plan',
              'https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Jones supported police reform legislation as a delegate, including measures related to use of force and chokeholds, and his 2021 justice reform plan included "improving policing and ending brutality and abuse." He advocated for the AG's office to prioritize civil rights enforcement against police misconduct. However, he simultaneously championed historic law enforcement funding increases and framed his public safety plan as developed in partnership with state and local law enforcement.$$,
        ARRAY['https://bluevirginia.us/2021/05/jay-jones-for-attorney-general-releases-justice-reform-plan',
              'https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Jones's reform plan called for making the justice system "fairer and more equitable" and ending disparities that disadvantage people of color and those with lesser economic means. He proposed specialty dockets for mental health and addiction. However, he also sponsored bills strengthening penalties for sex offenders and cracked down on human trafficking, and his AG campaign emphasized prosecution of violent crime, child exploitation, and drug trafficking as priorities — reflecting a reforming-but-prosecutorial stance.$$,
        ARRAY['https://bluevirginia.us/2021/05/jay-jones-for-attorney-general-releases-justice-reform-plan',
              'https://virginiaindependentnews.com/elections/2025-attorney-general-jones-miyares-safety-guns-violence/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Jones framed the AG's office as a "watchdog for the people" and created a Public Advocacy Division combining consumer protection and civil rights. He committed to defending Virginians against corporate abuses, established a Voter Protection Unit and Voting Rights Hotline, and emphasized making the justice system equitable for those with lesser economic means. Virginia Lawyers Weekly's profile of his AG priorities highlighted access to justice as a central theme of his administration.$$,
        ARRAY['https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/',
              'https://bluevirginia.us/2021/05/jay-jones-for-attorney-general-releases-justice-reform-plan']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Jones stated "housing security and shelter are basic human rights" and supports rent control as "part of an all-of-the-above approach to the affordable housing crisis." As AG his office conducted fair housing roundtables and issued know-your-fair-housing-rights guidance. He co-led a coalition of 22 AGs opposing a proposed HUD rule that would strip mixed-status immigrant households from public housing. Virginia Lawyers Weekly confirmed fair housing as a core AG priority.$$,
        ARRAY['https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / religious-freedom -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$Jones's documented LGBTQ and civil rights record consistently places anti-discrimination protections above religious exemption claims. He supported transgender-inclusive school policies, backed bills prohibiting discrimination in health coverage based on gender identity, opposed the "gay panic" murder defense, and his AG platform prioritizes creating a Civil Rights Division to protect Virginians' basic rights. No statements supporting broad religious exemptions from anti-discrimination law were found.$$,
        ARRAY['https://www.washingtonblade.com/2025/09/25/va-statewide-candidates-differ-widely-on-lgbtq-rights/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Jones voted to expand Medicaid as a delegate, supported pharmacy benefit manager transparency rules to lower drug costs, and campaigned against the One Big Beautiful Bill Act's Medicaid cuts, warning that 350,000 Virginians would lose coverage and rural hospitals would close. He also joined a coalition opposing federal changes that would weaken protections for retirement investments. No statements supporting cuts or privatization of healthcare programs were found.$$,
        ARRAY['https://www.wsls.com/news/local/2025/10/28/one-on-one-jay-jones-talks-vision-for-virginia/',
              'https://ballotpedia.org/Jay_Jones_(Virginia)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Jones stated "Virginia can only be the best state in the country to do business if it is the best state for workers" and declared he has "been proud to stand with organized labor my whole career." He was endorsed by AFGE, the largest federal employee union, and the Virginia State Council of Machinists, and supported collective bargaining rights and worker protections. His corporate accountability agenda included challenging price gouging and utility overcharges on behalf of consumers.$$,
        ARRAY['https://www.afge.org/publication/largest-federal-employee-union-endorses-jay-jones-for-virginia-attorney-general/',
              'https://www.cleanvirginia.org/jayjones/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / tariffs -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '683c8084-2281-4920-a07c-18439b2dd413',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        '683c8084-2281-4920-a07c-18439b2dd413',
        $$Jones joined a coalition of state AGs suing the Trump administration to stop tariffs imposed under IEEPA, characterizing them as "illegal tariffs" and "nothing more than a tax on Virginia families." He called on Congress to pass legislation requiring automatic tariff refunds after the Supreme Court voided them. His actions and statements consistently frame tariffs as harmful to Virginia consumers and unlawful executive overreach.$$,
        ARRAY['https://ballotpedia.org/Jay_Jones_(Virginia)',
              'https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Jones / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eef42ac4-5573-47c7-8b41-f2f1e0769aec',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As a delegate Jones voted to eliminate requirements for jails to report inmates' citizenship status to ICE and voted against banning sanctuary jurisdictions. As AG he reversed his predecessor's support for honoring ICE detainers, reversed the state's court filing in a lawsuit against in-state tuition for undocumented students, and joined a lawsuit challenging federal sharing of Medicaid data with DHS/ICE for immigration enforcement.$$,
        ARRAY['https://ballotpedia.org/Jay_Jones_(Virginia)',
              'https://valawyersweekly.com/2026/03/09/virginia-ag-jay-jones-priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for Jones (must be >= 21 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'eef42ac4-5573-47c7-8b41-f2f1e0769aec';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'eef42ac4-5573-47c7-8b41-f2f1e0769aec'
--   AND pc.politician_id IS NULL;
--
-- Uncited rows (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'eef42ac4-5573-47c7-8b41-f2f1e0769aec'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
