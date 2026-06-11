-- ============================================================================
-- Migration 361: Andrea Joy Campbell Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Andrea Joy Campbell (Attorney General of Massachusetts).
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
-- Andrea Joy Campbell: 602f147a-90bc-4083-aeab-1d0becf088e9 (external_id = -200004)

BEGIN;

-- ============================================================
-- Andrea Joy Campbell
-- Attorney General of Massachusetts
-- Boston City Council 2016-2022 (President 2018-2020); AG since January 2023
-- ============================================================

-- ----- Andrea Joy Campbell / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Campbell pledged at her swearing-in ceremony to defend abortion rights and established a Reproductive Justice Unit within the AG's Office as a campaign promise she fulfilled. She was the first AG to formally institutionalize reproductive justice enforcement following the Dobbs decision, actively defending Massachusetts as a safe haven for patients from out-of-state seeking abortion care. Campbell has filed amicus briefs supporting abortion access and joined multi-state AG coalitions opposing federal restrictions.$$,
        ARRAY['https://www.masslive.com/politics/2023/01/pledging-to-defend-abortion-rights-andrea-campbell-sworn-in-as-states-1st-black-female-attorney-general.html', 'https://www.wgbh.org/news/health/2023-10-06/ag-campbell-says-new-reproductive-justice-unit-will-help-ensure-access-to-necessary-care']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Campbell has made civil rights central to her career. As Boston City Council President she proposed a police oversight board (2020), passed an ordinance limiting police crowd control weapons, and introduced bills addressing credit check discrimination in hiring. As AG she established a Police Accountability Unit, created an Elder Justice Unit, and pledged to ensure no one is treated "above the law." Her personal history — twin brother died in state custody — drives her civil rights focus.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://commonwealthmagazine.org/criminal-justice/ag-andrea-campbell-picks-her-targets/', 'https://www.wgbh.org/news/politics/2023/01/18/andrea-campbell-sworn-in-as-massachusetts-first-black-woman-attorney-general']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$As Boston City Council President, Campbell was praised by the Boston Globe for pushing climate reform "to the left of the mayor." As AG, Campbell provided advice to the Massachusetts Department of Public Utilities cautioning against large gas procurement that would lock in fossil fuel dependency and advocated for clean energy transition. She has supported the Healey administration's climate agenda and joined coalitions challenging federal EPA rollbacks. Climate justice and environmental equity have been part of her equity lens approach.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.bostonglobe.com/metro/2019/12/10/kim-janey-claims-votes-next-boston-city-council-president/1dJ1PlOOCCtJiBYeup1g7N/story.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Campbell has been a vocal opponent of mass deportation operations. As AG, she has used her office to challenge Trump administration immigration enforcement actions, filing legal challenges to protect Massachusetts immigrants. She coordinated with the Healey administration on executive orders limiting state cooperation with federal immigration enforcement and has spoken out against immigration raids targeting Massachusetts communities. Campbell frames immigration enforcement opposition as both a civil rights and public safety issue.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.wgbh.org/news/politics/2023/01/18/andrea-campbell-sworn-in-as-massachusetts-first-black-woman-attorney-general']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Campbell has consistently supported healthcare access as a core equity issue. As AG, she created an Elder Justice Unit focused in part on healthcare fraud and elder care access. During COVID she criticized city government for inadequate health equity response. She pledged her office would use an "equity lens" addressing healthcare disparities impacting rural communities and communities of color. Campbell has defended the ACA and Massachusetts MassHealth program against federal threats.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.masslive.com/news/2023/04/heres-how-mass-ag-andrea-campbell-is-changing-the-office-she-now-runs.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Campbell has framed homelessness as a housing and economic justice issue requiring upstream investment rather than criminalization. As Boston City Council member representing Roxbury and South End she was familiar with homelessness challenges in those communities. During her AG campaign she emphasized addressing housing affordability as a public safety matter. She has advocated for shelter capacity and services rather than punitive approaches while also supporting public safety in affected communities.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.gloucestertimes.com/news/local_news/ag-campbell-proposes-new-unit-to-tackle-housing-affordability/article_238da9d8-dd9a-11ee-b319-af15dbff2872.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Campbell proposed a vacancy tax on abandoned properties as a Boston City Councilor (2019). As AG she filed a landmark lawsuit against Milton in February 2024 to enforce the MBTA Communities Zoning Law, which requires municipalities to allow multi-family housing near transit — a direct enforcement action for housing production. In March 2024 she proposed creating a Housing Affordability Unit within the AG's Office, making housing a core enforcement priority. Campbell frames housing access as a civil rights and economic justice issue.$$,
        ARRAY['https://www.wgbh.org/news/local/2024-02-27/ag-campbell-sues-milton-over-mbta-communities-law-vote', 'https://www.gloucestertimes.com/news/local_news/ag-campbell-proposes-new-unit-to-tackle-housing-affordability/article_238da9d8-dd9a-11ee-b319-af15dbff2872.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Campbell has been a consistent advocate for immigrant rights. As AG she has used her office to challenge Trump-era immigration enforcement overreach and joined multi-state AG coalitions defending DACA and sanctuary city policies. She has opposed restrictions on immigrants' access to legal services and public benefits. Campbell represented a Boston district with significant immigrant populations as a city councilor and has spoken about immigrant communities as essential to Massachusetts's economy and culture.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.masslive.com/news/2023/06/emerging-black-leaders-in-massachusetts-andrea-campbell.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Campbell's personal history — her twin brother died in state custody awaiting trial — has made criminal justice system reform including incarceration conditions a major driver of her career. She has advocated for reducing jail populations through bail reform, diversion, and treatment alternatives rather than expanding capacity. Her AG campaign platform emphasized prison reform and juvenile justice. Campbell views expanding incarceration as a failed approach and has focused on upstream prevention and diversion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://commonwealthmagazine.org/criminal-justice/ag-andrea-campbell-picks-her-targets/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / judicial-access-to-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
        $$Campbell began her legal career as a staff attorney at EdLaw, providing free legal services to students and parents regarding education rights — direct access-to-justice work. As AG, she has framed her office as the "people's lawyer" with a mandate to serve those who cannot otherwise access legal protection. Her Elder Justice Unit and other new units expand access to legal remedies for underserved populations. Campbell has strongly supported legal aid funding and free civil legal services for low-income Massachusetts residents.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.masslive.com/news/2023/04/heres-how-mass-ag-andrea-campbell-is-changing-the-office-she-now-runs.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Campbell has been a criminal justice reformer throughout her career, driven by personal experience with the system's failures. She made criminal justice reform a central focus of her AG campaign — pledging to address prison conditions, racial disparities in prosecution, juvenile justice, and diversion programs. As AG she created a Gun Violence Prevention Unit focused on upstream prevention. She supports sentencing reform and ending mandatory minimums for non-violent offenses. Her approach is reform-oriented while maintaining accountability for violent crime.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://commonwealthmagazine.org/criminal-justice/ag-andrea-campbell-picks-her-targets/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '7bad33eb-e93e-4d94-8822-97212d49bde5',
        $$Campbell proposed a police oversight board in 2020 as a Boston City Councilor and passed an ordinance limiting crowd control weapons (2021). She also refused to advance $1.2M in BPD grants in 2021 in her public safety committee chair role over accountability concerns. As AG she campaigned on ending qualified immunity and creating a Police Accountability Unit within the AG's Office (though she moderated her qualified immunity position after taking office). She challenged biased police promotion exams and criticized the BPD union's conduct.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://commonwealthmagazine.org/criminal-justice/ag-andrea-campbell-picks-her-targets/', 'https://www.bostonglobe.com/2020/07/13/metro/calling-accountability-campbell-proposes-police-oversight-board/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / judicial-prosecution-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
        $$Campbell pledged as AG to pursue gun violence, abortion-rights violations, elder fraud, police misconduct, housing discrimination, and corporate consumer fraud as prosecution priorities — all reflecting an equity-focused enforcement agenda. She created specific units for gun violence prevention, reproductive justice, elder justice, and police accountability. She has committed to ensuring powerful interests are not treated as "above the law" and has pursued corporate violations harming consumers alongside her social justice priorities.$$,
        ARRAY['https://www.masslive.com/news/2023/04/heres-how-mass-ag-andrea-campbell-is-changing-the-office-she-now-runs.html', 'https://commonwealthmagazine.org/criminal-justice/ag-andrea-campbell-picks-her-targets/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Campbell has supported Medicare and Medicaid programs as essential safety-net protections. Her Elder Justice Unit within the AG's Office focuses in part on protecting elderly Massachusetts residents from healthcare fraud and ensuring access to care. She grew up in circumstances relying on public assistance and has consistently defended social safety-net programs. Campbell has opposed federal cuts to Medicaid and joined AG coalitions defending these programs against federal rollbacks.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.bostonherald.com/2023/08/19/ag-andrea-campbell-appoints-new-head-of-elder-justice-unit']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Campbell's public safety approach combines accountability-focused policing reform with investments in violence prevention. As a city councilor she proposed reallocating 10% ($50M) of the BPD budget to public health, economic justice, and youth programs during her 2021 mayoral campaign. As AG she created a Gun Violence Prevention Unit focused on upstream prevention and community investment. She opposed "defund" rhetoric while supporting meaningful police accountability reforms and diversion programs, representing a reform-and-invest model.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.bostonglobe.com/2021/02/24/metro/50-million-cut-bpds-budget-campbell-pitch-shows-police-reform-will-be-key-issue-mayoral-race/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Campbell's lawsuit against Milton to enforce the MBTA Communities Zoning Law is one of the strongest enforcement actions taken by a Massachusetts AG in support of pro-housing zoning reform. The law requires municipalities to allow multi-family housing by right near transit. Campbell argued municipalities cannot "pick and choose" which state laws to abide by and pursued legal action when Milton voters rejected compliance. This reflects a strong pro-density zoning position focused on housing production near transit.$$,
        ARRAY['https://www.wgbh.org/news/local/2024-02-27/ag-campbell-sues-milton-over-mbta-communities-law-vote', 'https://www.wbur.org/news/2024/03/14/massachusetts-housing-law-milton']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Campbell is a strong supporter of same-sex marriage and LGBTQ+ rights. As AG she has enforced Massachusetts anti-discrimination laws protecting LGBTQ+ residents in employment, housing, and public accommodations. Following the Dobbs decision, she became more vocal about threats to marriage equality and other constitutional rights, committing the AG's Office to defending these rights against federal rollbacks. Her civil rights commitment explicitly encompasses LGBTQ+ equality.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.wgbh.org/news/politics/2023/01/18/andrea-campbell-sworn-in-as-massachusetts-first-black-woman-attorney-general']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Campbell's position on school choice is notable: as a Boston City Councilor in 2016 she was one of only two councilors to vote against a resolution opposing charter school expansion, later receiving funding from charter school proponents in her 2021 mayoral campaign — a position that drew criticism from teachers' unions. However, she also emphasized the quality of public schools and has not actively advocated for school vouchers as AG. Her charter-school-supportive city council record is clearly documented but may not extend to private school vouchers.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.bostonherald.com/2016/08/04/council-votes-against-more-charter-schools/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Campbell has been a consistent defender of transgender rights, including in sports participation. As AG she has enforced Massachusetts's gender identity non-discrimination law (Chapter 272) in all public accommodations. She has opposed federal executive orders targeting transgender students and athletes, joining multi-state AG coalitions challenging these actions. Campbell frames transgender rights as a civil rights and equal protection matter consistent with her overall equity-focused approach to the office.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.wgbh.org/news/politics/2023/01/18/andrea-campbell-sworn-in-as-massachusetts-first-black-woman-attorney-general']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Andrea Joy Campbell / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('602f147a-90bc-4083-aeab-1d0becf088e9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Campbell has been a strong voting rights advocate throughout her career. As Boston City Council President she proposed changes to election laws to strengthen democratic participation. As AG she joined multi-state coalitions defending mail-in and early voting access against federal-level challenges. She has opposed voter ID restrictions and supported automatic voter registration. During her 2022 AG campaign, Campbell highlighted protecting voting rights as a priority amid challenges to election integrity nationally.$$,
        ARRAY['https://en.wikipedia.org/wiki/Andrea_Campbell', 'https://www.masslive.com/news/2023/06/emerging-black-leaders-in-massachusetts-andrea-campbell.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 8 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '602f147a-90bc-4083-aeab-1d0becf088e9';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '602f147a-90bc-4083-aeab-1d0becf088e9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '602f147a-90bc-4083-aeab-1d0becf088e9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
