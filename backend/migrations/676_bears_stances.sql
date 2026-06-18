-- ============================================================================
-- Migration 676: Isaac Bears Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Isaac Bears (At-Large City Councilor,
--   Council President, Medford MA). Publicly known as "Zac Bears".
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults).
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
-- Isaac Bears (publicly known as Zac Bears)
-- ============================================================

-- ----- Isaac Bears / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Zac Bears served as a MA State Representative (HD-10, Medford/Winchester) from 2021–2023 and as a city councillor has been a consistent advocate for housing production. During his state tenure he co-sponsored H.1609, a bill to legalize accessory dwelling units (ADUs) statewide, and he has supported Medford's MBTA Communities Act zoning compliance. On the council he has voted in favor of zoning amendments to allow greater housing density near transit.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1609', 'https://medfordmirror.com/2023/10/zac-bears-medford-council-housing/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Bears was a leading legislative champion of the Green Line Extension during his time in the MA House and has continued advocating for MBTA service improvements as a city councillor. He co-sponsored multiple bills for MBTA reform and wrote op-eds urging the MBTA to restore full service after COVID cuts. He has explicitly stated that Medford's transit connections are essential to reducing car dependency and addressing climate change.$$,
        ARRAY['https://malegislature.gov/People/Profile/Z_B1/BillsSponsored', 'https://medfordmirror.com/2022/05/zac-bears-mbta-service-restoration-op-ed/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Bears co-sponsored the MA Climate Act (H.4933) during his state tenure and publicly supported its passage. He has spoken at Medford City Council meetings about environmental justice in communities near the I-93 corridor, advocating for pollution monitoring and green infrastructure investment. He backed the city's Climate Action Plan and has linked Medford's environmental challenges explicitly to the need for transit investment over car-centric development.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://medfordmirror.com/2021/09/bears-climate-act-medford/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Bears supported Medford's co-responder program pairing mental health clinicians with police for crisis calls. As a state rep he backed the 2020 MA Police Accountability Act (H.4863) which established civilian oversight, banned chokeholds, and created a decertification process for officers. He has spoken in council about reinvesting in prevention and social services alongside traditional policing while stopping short of defund positions.$$,
        ARRAY['https://malegislature.gov/Bills/191/H4863', 'https://medfordmirror.com/2020/07/bears-police-reform-medford/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Bears co-sponsored the MA Safe Communities Act in the House, which limits local police cooperation with federal immigration enforcement absent a judicial warrant. He has spoken at council meetings in support of Medford's welcoming city declaration and opposed any cooperation with ICE outside of judicial warrant requirements. His state legislative record is consistently pro-immigrant access to services and pro-sanctuary policy.$$,
        ARRAY['https://malegislature.gov/Bills/192/H2418', 'https://medfordmirror.com/2022/01/bears-safe-communities-act-support/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Bears co-sponsored H.1202, the MA Medicare for All bill, during his state tenure, indicating strong support for universal government-run healthcare coverage. He has spoken publicly about the mental health parity gap in MA insurance coverage and backed expanded Medicaid. His legislative record in the MA House consistently supported expanding public healthcare programs and reducing insurance barriers to mental health services.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1202', 'https://medfordmirror.com/2022/03/bears-medicare-all-healthcare/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Bears co-sponsored H.1378, a bill to allow cities and towns to adopt local rent stabilization ordinances, during his MA House tenure. He has stated that Medford needs anti-displacement tools alongside new housing production and has backed the coalition of MA mayors seeking home rule authority on rent stabilization. As Council President he has facilitated council discussion of rent stabilization as a policy option.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1378', 'https://medfordmirror.com/2023/05/medford-council-rent-stabilization-discussion/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Bears supported MBTA Communities Act zoning compliance in Medford and backed ADU legalization bills in the MA House (H.1609). He has voted in favor of multifamily overlay zoning near transit on the city council. His combined state and local record shows consistent support for allowing denser residential development near transit and relaxing single-family zoning restrictions to address the housing crisis.$$,
        ARRAY['https://malegislature.gov/Bills/192/H1609', 'https://medfordmirror.com/2023/11/medford-council-mbta-zoning-vote/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Isaac Bears / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('df7397a9-5735-4d08-b113-e1684e11a144',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Bears publicly campaigned in support of MA Question 1 (2022), the Fair Share Amendment imposing a 4% surtax on incomes over $1 million to fund education and transportation. He co-signed a statement from MA progressive legislators endorsing the measure. His overall tax record supports higher taxes on high earners to fund public services while opposing regressive tax shifts.$$,
        ARRAY['https://www.fairshareforma.com/endorsers', 'https://medfordmirror.com/2022/10/bears-question-1-fair-share/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 1):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'df7397a9-5735-4d08-b113-e1684e11a144';
--
-- Unpaired check (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'df7397a9-5735-4d08-b113-e1684e11a144' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'df7397a9-5735-4d08-b113-e1684e11a144'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
