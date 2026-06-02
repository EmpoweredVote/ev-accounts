-- ============================================================================
-- Migration 242: OR State Senate Stances -- 30 Senators
-- ============================================================================
-- Purpose: Insert/upsert stance data for all 30 OR state senators.
-- Scope: 30 senators (SD-01 through SD-30); 215 stance rows total
-- Idempotency: ON CONFLICT DO UPDATE on both tables.
-- Apply to remote Supabase via psql or migration API.
-- ============================================================================

BEGIN;

-- David Brock Smith, SD-01
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023 Oregon session) expanding reproductive healthcare and abortion access; part of Republican minority opposing the bill. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout denying quorum to block climate and gun control legislation (HB 2020 climate package and HB 2005 gun safety). One of the walkout senators. https://ballotpedia.org/David_Brock_Smith$$,
ARRAY['https://ballotpedia.org/David_Brock_Smith']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5350c0ba-0ef4-4021-a620-90820df859b7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Opposed HB 3427 (2019) Corporate Activity Tax; consistent anti-tax voting record as Republican senator from rural coastal district. https://ballotpedia.org/David_Brock_Smith$$,
ARRAY['https://ballotpedia.org/David_Brock_Smith']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Noah Robinson, SD-02
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout blocking quorum to prevent passage of climate and gun legislation; opposed cap-and-trade style climate bills. https://ballotpedia.org/Noah_Robinson_(Oregon)$$,
ARRAY['https://ballotpedia.org/Noah_Robinson_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('13ce589f-756e-4968-881f-c8cc95dae404', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on tax increase measures; consistent conservative anti-tax voting record as Republican senator from rural southern Oregon. https://ballotpedia.org/Noah_Robinson_(Oregon)$$,
ARRAY['https://ballotpedia.org/Noah_Robinson_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Jeff Golden, SD-03
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supported civil rights protections; voted YES on HB 2002 (2023) expanding gender-affirming care rights; supports inclusive policies. https://ballotpedia.org/Jeff_Golden$$,
ARRAY['https://ballotpedia.org/Jeff_Golden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Champion of climate legislation; supported SB 488 (2021) clean energy and coal transition; supported HB 2021 (2021) 100% clean electricity standard; active on Senate Environment and Natural Resources Committee. https://ballotpedia.org/Jeff_Golden$$,
ARRAY['https://ballotpedia.org/Jeff_Golden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'a22215c3-6693-4bc2-b248-01aebba14570', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Supported clean energy transition legislation including HB 2021 (2021) requiring 100% clean electricity by 2040; consistent opposition to fossil fuel expansion. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on SB 1089 (2024) healthcare access expansion; supported ACA-aligned Medicaid coverage policies. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1089$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1089']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported zoning reform to increase housing availability. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported sanctuary policies and immigrant protections; opposed immigration enforcement collaboration with federal ICE. https://ballotpedia.org/Jeff_Golden$$,
ARRAY['https://ballotpedia.org/Jeff_Golden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21b454d4-e6a5-48fe-9bd1-0da84f2a1a39', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Supported revenue measures and public investment; voted YES on HB 3427 (2019) Corporate Activity Tax to fund education. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Floyd Prozanski, SD-04
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon; long-standing supporter of reproductive rights. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Supported campaign finance transparency; backed measures expanding donor disclosure requirements as part of Democratic caucus agenda. https://ballotpedia.org/Floyd_Prozanski$$,
ARRAY['https://ballotpedia.org/Floyd_Prozanski']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Long-serving Democrat who has championed civil rights legislation; supported anti-discrimination protections and LGBTQ+ equality bills throughout career. https://ballotpedia.org/Floyd_Prozanski$$,
ARRAY['https://ballotpedia.org/Floyd_Prozanski']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy and climate legislation including HB 2021 (2021) 100% clean electricity standard. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on healthcare access expansion bills; supported Medicaid expansion and Oregon Health Plan coverage. https://ballotpedia.org/Floyd_Prozanski$$,
ARRAY['https://ballotpedia.org/Floyd_Prozanski']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) housing supply package; supported zoning reform to address Oregon housing shortage. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported sanctuary policies and immigrant rights protections; opposed state-level immigration enforcement collaboration with ICE. https://ballotpedia.org/Floyd_Prozanski$$,
ARRAY['https://ballotpedia.org/Floyd_Prozanski']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
$$Senate Judiciary Committee chair; supported criminal justice reform including HB 2005 (2023) gun safety legislation; worked on sentencing reform. https://ballotpedia.org/Floyd_Prozanski$$,
ARRAY['https://ballotpedia.org/Floyd_Prozanski']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$As Senate Judiciary chair, focused on rehabilitation and prevention alongside accountability; supported HB 2005 gun safety measures; mixed approach on public safety. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; generally supports public investment through taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b6f5cd9e-a9d2-44ff-9027-0d931765f378', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported HB 2015 (2015) automatic voter registration; supported voting access expansion measures as long-serving Democratic senator. https://olis.oregonlegislature.gov/liz/2015R1/Measures/Overview/HB2015$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2015R1/Measures/Overview/HB2015']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Dick Anderson, SD-05
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout blocking quorum to prevent climate legislation; opposed clean energy mandates. https://ballotpedia.org/Dick_Anderson_(Oregon)$$,
ARRAY['https://ballotpedia.org/Dick_Anderson_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d9803822-6bf8-437d-aa4b-d7e6b4a67b7c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; consistent Republican opposition to tax increases. https://ballotpedia.org/Dick_Anderson_(Oregon)$$,
ARRAY['https://ballotpedia.org/Dick_Anderson_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Cedric Hayden, SD-06
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout to block climate legislation; opposes environmental regulations that impact rural communities and resource industries. https://ballotpedia.org/Cedric_Hayden$$,
ARRAY['https://ballotpedia.org/Cedric_Hayden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposes government-mandated healthcare expansion; as a dentist, emphasizes market-based healthcare approaches; voted against Oregon Health Plan expansion mandates. https://ballotpedia.org/Cedric_Hayden$$,
ARRAY['https://ballotpedia.org/Cedric_Hayden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3dedaa7-bda5-4e3d-af18-6214719d6e1e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; opposes tax increases affecting rural business and agriculture. https://ballotpedia.org/Cedric_Hayden$$,
ARRAY['https://ballotpedia.org/Cedric_Hayden']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- James I. Manning Jr., SD-07
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Long-serving Democratic senator; consistent supporter of civil rights protections and anti-discrimination measures in Oregon legislature. https://ballotpedia.org/James_Manning$$,
ARRAY['https://ballotpedia.org/James_Manning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation including HB 2021 (2021) 100% clean electricity standard for Oregon. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on healthcare access expansion bills; supports Oregon Health Plan expansion and Medicaid coverage for low-income Oregonians. https://ballotpedia.org/James_Manning$$,
ARRAY['https://ballotpedia.org/James_Manning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supports affordable housing expansion in Eugene. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protection policies; opposed state collaboration with federal immigration enforcement. https://ballotpedia.org/James_Manning$$,
ARRAY['https://ballotpedia.org/James_Manning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bef7b04c-a2ba-4daf-9359-ae1ae0e38e9e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supports public investment through progressive taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Sara Gelser Blouin, SD-08
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; long-time supporter of reproductive rights in Oregon legislature. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Supported campaign finance transparency measures; backed donor disclosure requirements as part of Democratic caucus agenda. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Sponsored legislation expanding childcare access and subsidies for working families; consistent advocate for early childhood investment. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Led disability rights legislation including SB 1534 (2020) strengthening protections for people with disabilities; championed anti-discrimination work throughout career. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard and SB 488 (2021) clean energy transition; consistent progressive environmental voting record. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Champion of mental health services funding and Oregon Health Plan expansion; led efforts to reform Oregon's foster care and developmental disability services systems. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '4938766b-b45a-46e3-93bd-b8b30651271a', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '4938766b-b45a-46e3-93bd-b8b30651271a',
$$Opposed criminalization of homelessness; authored legislation expanding services-first approach to homelessness; opposed Measure 110 (drug decriminalization) reversal. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported affordable housing measures particularly for people with disabilities. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protections; voted YES on measures protecting immigrant communities from state-level enforcement collaboration. https://ballotpedia.org/Sara_Gelser_Blouin$$,
ARRAY['https://ballotpedia.org/Sara_Gelser_Blouin']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Focused on root causes of crime through mental health and social services investment; supported HB 2005 (2023) gun safety legislation; rehabilitation-focused approach to public safety. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supported public investment in social services through taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1ca1abf1-9523-499c-b644-0b32c61257c6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported HB 2015 (2015) automatic voter registration and voting access expansion measures; consistent voting rights advocate. https://olis.oregonlegislature.gov/liz/2015R1/Measures/Overview/HB2015$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2015R1/Measures/Overview/HB2015']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Fred Girod, SD-09
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon; consistent anti-abortion voting record. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout opposing climate legislation; former Senate Minority Leader leading Republican opposition to clean energy mandates. https://ballotpedia.org/Fred_Girod$$,
ARRAY['https://ballotpedia.org/Fred_Girod']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposed government-mandated healthcare expansion; voted against Oregon Health Plan mandates; Republican position on market-based healthcare. https://ballotpedia.org/Fred_Girod$$,
ARRAY['https://ballotpedia.org/Fred_Girod']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill; supported removing zoning restrictions to increase housing supply. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$As Senate Minority Leader, advocated for tougher public safety measures; opposed Measure 110 drug decriminalization; supported law enforcement funding. https://ballotpedia.org/Fred_Girod$$,
ARRAY['https://ballotpedia.org/Fred_Girod']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b107b84-afbe-4141-8951-bafb65543dda', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax as part of Republican opposition; former Senate Minority Leader consistently opposing tax increases. https://ballotpedia.org/Fred_Girod$$,
ARRAY['https://ballotpedia.org/Fred_Girod']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Deb Patterson, SD-10
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; healthcare professional background informs her reproductive rights advocacy. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access expansion legislation; views childcare as essential infrastructure for working families and public health. https://ballotpedia.org/Deb_Patterson$$,
ARRAY['https://ballotpedia.org/Deb_Patterson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Consistent civil rights supporter; voted YES on anti-discrimination protections and LGBTQ+ equality measures in Oregon legislature. https://ballotpedia.org/Deb_Patterson$$,
ARRAY['https://ballotpedia.org/Deb_Patterson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported climate legislation as public health issue. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Healthcare professional (physician) who champions universal healthcare access; supported Oregon Health Plan expansion and Medicaid coverage; serves on Senate Health Care Committee. https://ballotpedia.org/Deb_Patterson$$,
ARRAY['https://ballotpedia.org/Deb_Patterson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supports affordable housing as social determinant of health. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant health access; backed measures ensuring immigrant communities can access healthcare without fear of enforcement. https://ballotpedia.org/Deb_Patterson$$,
ARRAY['https://ballotpedia.org/Deb_Patterson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('631cc414-8793-42ec-b883-594ed7f0b249', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax; supports public investment in healthcare and education through taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Kim Thatcher, SD-11
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; longtime anti-abortion voting record. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout blocking climate legislation; opposed clean energy mandates and cap-and-trade. https://ballotpedia.org/Kim_Thatcher$$,
ARRAY['https://ballotpedia.org/Kim_Thatcher']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposed Oregon Health Plan mandates and government-run healthcare; voted against healthcare coverage expansion bills. https://ballotpedia.org/Kim_Thatcher$$,
ARRAY['https://ballotpedia.org/Kim_Thatcher']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Supported law enforcement funding and opposed Measure 110 drug decriminalization; advocated for tougher sentencing and public safety measures. https://ballotpedia.org/Kim_Thatcher$$,
ARRAY['https://ballotpedia.org/Kim_Thatcher']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; long record of opposing tax increases and government spending expansion. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$$Voted in favor of measures restricting transgender athletes in school sports; consistent conservative social position. https://ballotpedia.org/Kim_Thatcher$$,
ARRAY['https://ballotpedia.org/Kim_Thatcher']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b548a0f7-5086-4124-a510-49ef8f60f515', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Opposed automatic voter registration; supported voter ID measures and questioned election integrity; conservative position on voting access vs. election security. https://ballotpedia.org/Kim_Thatcher$$,
ARRAY['https://ballotpedia.org/Kim_Thatcher']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Bruce Starr, SD-12
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout opposing climate legislation; opposed clean energy mandates affecting Washington County businesses. https://ballotpedia.org/Bruce_Starr$$,
ARRAY['https://ballotpedia.org/Bruce_Starr']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposed government-run healthcare mandates; voted against Medicaid expansion requirements; Republican position on market-based healthcare. https://ballotpedia.org/Bruce_Starr$$,
ARRAY['https://ballotpedia.org/Bruce_Starr']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill addressing housing shortage in Washington County. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Supported law enforcement funding and opposed Measure 110 drug decriminalization in 2024 session; backed tougher public safety measures. https://ballotpedia.org/Bruce_Starr$$,
ARRAY['https://ballotpedia.org/Bruce_Starr']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0c228d44-a876-4371-bdfd-13fdfd8ea9b6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; consistent anti-tax position throughout legislative career. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Courtney Neron Misslin, SD-13
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Voted YES on HB 2002 (2023) expanding gender-affirming care rights; supported anti-discrimination protections as Democratic senator. https://ballotpedia.org/Courtney_Neron$$,
ARRAY['https://ballotpedia.org/Courtney_Neron']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation including HB 2021 (2021) clean electricity standard; voted YES on climate bills. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on healthcare access expansion bills; supported Medicaid coverage and Oregon Health Plan expansion. https://ballotpedia.org/Courtney_Neron$$,
ARRAY['https://ballotpedia.org/Courtney_Neron']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported zoning reform to increase housing availability in Yamhill County. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('dcdc002c-8fd6-415a-a30a-8fc70c83d9ff', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on tax measures supporting public services; supported revenue measures for education and social services. https://ballotpedia.org/Courtney_Neron$$,
ARRAY['https://ballotpedia.org/Courtney_Neron']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Kate Lieber, SD-14
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; endorsed by NARAL Pro-Choice Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Supported campaign finance reform including disclosure requirements; backed measures reducing dark money in Oregon politics. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access and affordability legislation; backed expanded childcare subsidies for working families. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Consistent supporter of civil rights and LGBTQ+ equality; voted YES on HB 2002 (2023) gender-affirming care protections. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported clean energy transition legislation. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported Oregon Health Plan expansion and healthcare access; voted YES on healthcare coverage expansion bills. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Strong housing advocate; supported SB 1537 (2024) and HB 2001 (2019) allowing more density in urban areas; progressive position on housing supply. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protection policies; opposed state collaboration with federal ICE enforcement; voted against immigration restriction measures. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax; supports public investment through progressive taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('529ea93b-c234-4df5-ae22-6ba32d0ae9a4', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported voting rights expansion including automatic voter registration; opposed voter ID restrictions. https://ballotpedia.org/Kate_Lieber$$,
ARRAY['https://ballotpedia.org/Kate_Lieber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Janeen Sollman, SD-15
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Champion of childcare policy; sponsored legislation expanding access to affordable childcare for working families; member of childcare advocacy coalition. https://ballotpedia.org/Janeen_Sollman$$,
ARRAY['https://ballotpedia.org/Janeen_Sollman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supported anti-discrimination protections and LGBTQ+ equality bills; voted YES on HB 2002 (2023) gender-affirming care rights. https://ballotpedia.org/Janeen_Sollman$$,
ARRAY['https://ballotpedia.org/Janeen_Sollman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported clean energy transition legislation. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported Oregon Health Plan expansion and healthcare access; voted YES on healthcare coverage expansion bills. https://ballotpedia.org/Janeen_Sollman$$,
ARRAY['https://ballotpedia.org/Janeen_Sollman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported housing affordability measures. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fa9d50e7-7e9b-4eed-b105-bf8277b51f95', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supports public investment. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Suzanne Weber, SD-16
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout opposing climate legislation; opposes environmental regulations affecting coastal businesses and agriculture. https://ballotpedia.org/Suzanne_Weber$$,
ARRAY['https://ballotpedia.org/Suzanne_Weber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill; supported removing zoning barriers to increase housing supply. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d34df5c8-9534-4472-814d-971adff16f50', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; consistent conservative anti-tax position. https://ballotpedia.org/Suzanne_Weber$$,
ARRAY['https://ballotpedia.org/Suzanne_Weber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Lisa Reynolds, SD-17
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; endorsed by reproductive rights organizations. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access expansion; backed subsidized childcare for low-income families as pediatrician and senator. https://ballotpedia.org/Lisa_Reynolds$$,
ARRAY['https://ballotpedia.org/Lisa_Reynolds']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Consistent supporter of civil rights protections; voted YES on LGBTQ+ equality and anti-discrimination measures. https://ballotpedia.org/Lisa_Reynolds$$,
ARRAY['https://ballotpedia.org/Lisa_Reynolds']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported climate and clean energy legislation. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'a22215c3-6693-4bc2-b248-01aebba14570', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Supported clean energy transition and opposed fossil fuel expansion; backed HB 2021 (2021) decarbonization goals. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Pediatrician background informs healthcare advocacy; supported Oregon Health Plan expansion and universal healthcare access bills. https://ballotpedia.org/Lisa_Reynolds$$,
ARRAY['https://ballotpedia.org/Lisa_Reynolds']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Supported SB 1537 (2024) housing supply package and HB 2001 (2019) allowing more housing density; strong housing affordability advocate. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protection policies; opposed state-level immigration enforcement collaboration; backed measures ensuring immigrant healthcare access. https://ballotpedia.org/Lisa_Reynolds$$,
ARRAY['https://ballotpedia.org/Lisa_Reynolds']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Supported HB 2005 (2023) gun safety measures; focused on prevention and root causes approach to public safety. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supports public investment through progressive taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d910cf6e-7d70-4b0c-b883-2fe2dcb185b6', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported automatic voter registration and voting access expansion; opposed restrictions on ballot access. https://ballotpedia.org/Lisa_Reynolds$$,
ARRAY['https://ballotpedia.org/Lisa_Reynolds']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Wlnsvey Campos, SD-18
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Consistent champion of civil rights and equity; supports LGBTQ+ equality, racial justice, and anti-discrimination protections. https://ballotpedia.org/Wlnsvey_Campos$$,
ARRAY['https://ballotpedia.org/Wlnsvey_Campos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation; voted YES on climate bills protecting frontline communities disproportionately impacted by pollution. https://ballotpedia.org/Wlnsvey_Campos$$,
ARRAY['https://ballotpedia.org/Wlnsvey_Campos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on healthcare access expansion; supports Oregon Health Plan and universal healthcare access. https://ballotpedia.org/Wlnsvey_Campos$$,
ARRAY['https://ballotpedia.org/Wlnsvey_Campos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Supports affordable housing and tenant protections; voted YES on SB 1537 (2024) housing supply package; advocates for community land trusts. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Immigrant rights advocate; supports sanctuary policies and immigrant community protections; opposed state-level immigration enforcement. https://ballotpedia.org/Wlnsvey_Campos$$,
ARRAY['https://ballotpedia.org/Wlnsvey_Campos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('95300e6e-ea4e-47f9-8a24-5f6f762d5c73', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Supports progressive taxation and public investment in education and social services; backed revenue measures for community programs. https://ballotpedia.org/Wlnsvey_Campos$$,
ARRAY['https://ballotpedia.org/Wlnsvey_Campos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Rob Wagner, SD-19
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; consistent pro-choice voting record. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Supported campaign finance transparency measures; backed disclosure requirements and limits on political spending. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access legislation; backed subsidies for working families as part of economic equity agenda. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Former Senate President pro tempore; championed civil rights legislation including LGBTQ+ equality and anti-discrimination protections throughout career. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported SB 488 clean energy transition; active climate legislation supporter. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'a22215c3-6693-4bc2-b248-01aebba14570', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Supported clean energy transition; voted for fossil fuel reduction legislation as part of climate action agenda. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on Oregon Health Plan expansion; supported universal healthcare access; backed mental health parity legislation. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Supported SB 1537 (2024) housing supply package; championed affordable housing legislation particularly for working families in Lake Oswego area. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protections; opposed state-level immigration enforcement; backed sanctuary policies. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Supported HB 2005 (2023) gun safety legislation; focused on prevention and mental health investment alongside enforcement. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supports progressive taxation and public investment. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14faa864-de9f-497f-a78a-db41f42ee5e0', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported voting access expansion including automatic voter registration; consistent voting rights advocate as Senate leader. https://ballotpedia.org/Rob_Wagner$$,
ARRAY['https://ballotpedia.org/Rob_Wagner']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Mark Meek, SD-20
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supported civil rights and anti-discrimination protections; voted YES on HB 2002 gender-affirming care rights. https://ballotpedia.org/Mark_Meek$$,
ARRAY['https://ballotpedia.org/Mark_Meek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) 100% clean electricity standard; supported clean energy transition legislation. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Focus on balanced economic development supporting both business growth and worker protections in Clackamas County. https://ballotpedia.org/Mark_Meek$$,
ARRAY['https://ballotpedia.org/Mark_Meek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on Oregon Health Plan expansion and healthcare access bills; supported Medicaid coverage for working families. https://ballotpedia.org/Mark_Meek$$,
ARRAY['https://ballotpedia.org/Mark_Meek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported housing affordability measures in Clackamas County. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('be46ed6d-363e-46f4-89d4-c95d9af67db1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax while in House; supports public investment through progressive taxation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Kathleen Taylor, SD-21
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supports civil rights and racial equity; voted YES on anti-discrimination protections and LGBTQ+ equality measures. https://ballotpedia.org/Kathleen_Taylor_(Oregon)$$,
ARRAY['https://ballotpedia.org/Kathleen_Taylor_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation and environmental justice; voted YES on HB 2021 (2021) clean electricity standard. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on Oregon Health Plan expansion; supports healthcare access as a right for all Oregonians. https://ballotpedia.org/Kathleen_Taylor_(Oregon)$$,
ARRAY['https://ballotpedia.org/Kathleen_Taylor_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) housing supply package; supports affordable housing particularly in SE Portland community. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant protections and sanctuary policies; backed measures protecting immigrant communities from enforcement. https://ballotpedia.org/Kathleen_Taylor_(Oregon)$$,
ARRAY['https://ballotpedia.org/Kathleen_Taylor_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b4702e0-3b88-4fd0-aa17-aa379be0dbac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on tax measures supporting public investment; backed progressive taxation for education and social services. https://ballotpedia.org/Kathleen_Taylor_(Oregon)$$,
ARRAY['https://ballotpedia.org/Kathleen_Taylor_(Oregon)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Lew Frederick, SD-22
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; consistent champion of reproductive rights. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Supported campaign finance reform and disclosure requirements; backed measures reducing dark money influence in Oregon elections. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access expansion; backed subsidies for low-income families as part of equity agenda. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Long-serving civil rights champion; has authored and championed civil rights legislation including racial equity and anti-discrimination measures throughout career; NAACP Oregon chapter president before entering politics. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation with environmental justice lens; voted YES on HB 2021 (2021); focuses on disproportionate pollution impact on communities of color. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported universal healthcare access; voted YES on Oregon Health Plan expansion and healthcare equity bills addressing disparities in Black communities. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Supported SB 1537 (2024) housing supply package; advocates for affordable housing and anti-displacement policies in NE Portland. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Supported immigrant rights and sanctuary protections; backed measures preventing racial profiling in immigration enforcement. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '7bad33eb-e93e-4d94-8822-97212d49bde5', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', '7bad33eb-e93e-4d94-8822-97212d49bde5',
$$Authored police accountability legislation; supported SB 1089 (2020) police accountability reform; longtime advocate for civilian oversight. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Focused on police accountability and criminal justice reform; supported HB 2005 (2023) gun safety; advocated for community investment over incarceration. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2005']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education; supports progressive taxation for public investment in underserved communities. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae4b1163-e9a7-4529-a8f2-5610f6c93cbd', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Champion of voting rights; supported automatic voter registration, vote-by-mail expansion, and opposed voter suppression measures. https://ballotpedia.org/Lew_Frederick$$,
ARRAY['https://ballotpedia.org/Lew_Frederick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Khanh Pham, SD-23
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Supported childcare access expansion; backed subsidies for immigrant and low-income families. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Vietnamese American immigrant rights champion; consistent advocate for LGBTQ+ equality and racial justice; focuses on equity for marginalized communities. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Environmental justice focus; supported clean energy legislation with emphasis on protecting frontline communities; voted YES on HB 2021 (2021). https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported Oregon Health Plan expansion; advocates for healthcare equity for immigrant and low-income communities. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) housing supply package; strong affordable housing and anti-displacement advocate for SE Portland. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Immigration rights advocate; supported sanctuary policies and protections for immigrant communities; led efforts to expand immigrant access to driver licenses. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Supports progressive taxation for public investment in services for low-income and immigrant communities. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('80ed3ab4-f7f6-4738-a9b7-49e6f52ad61e', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported automatic voter registration and multilingual ballot access; voted for voting rights expansion measures. https://ballotpedia.org/Khanh_Pham$$,
ARRAY['https://ballotpedia.org/Khanh_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Kayse Jama, SD-24
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Consistent civil rights advocate; focuses on racial justice, LGBTQ+ rights, and protections for refugee communities. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Supported clean energy legislation with environmental justice lens; voted YES on HB 2021 (2021) clean electricity standard. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported Oregon Health Plan expansion; advocates for healthcare equity for refugee and immigrant communities. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) housing supply; strong advocate for affordable housing and anti-displacement for East Portland communities. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Somali refugee and immigrant rights champion; co-founded Unite Oregon; led efforts to expand immigrant driver licenses and sanctuary protections. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Focused on community investment and addressing root causes of crime; supported police accountability reforms; opposed over-criminalization. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Supports progressive taxation and public investment; backed revenue measures supporting immigrant and low-income communities. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a703adb5-1086-471b-ba8b-2dbeddd8102b', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Supported multilingual voting access and automatic voter registration; advocates for voting rights for immigrant and refugee communities. https://ballotpedia.org/Kayse_Jama$$,
ARRAY['https://ballotpedia.org/Kayse_Jama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Chris Gorsek, SD-25
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supported civil rights and anti-discrimination protections; voted YES on HB 2002 gender-affirming care. https://ballotpedia.org/Chris_Gorsek$$,
ARRAY['https://ballotpedia.org/Chris_Gorsek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on HB 2021 (2021) clean electricity standard; supported clean energy legislation particularly focused on Columbia River Gorge region. https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2021R1/Measures/Overview/HB2021']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Focused on sustainable economic development in East Portland and Columbia River Gorge; supports balancing business growth with environmental protection. https://ballotpedia.org/Chris_Gorsek$$,
ARRAY['https://ballotpedia.org/Chris_Gorsek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Voted YES on Oregon Health Plan expansion and healthcare access bills. https://ballotpedia.org/Chris_Gorsek$$,
ARRAY['https://ballotpedia.org/Chris_Gorsek']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply package; supported housing affordability in East Metro area. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22a1e980-4f15-435d-a0c4-1a08202d6bb5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on HB 3427 (2019) Corporate Activity Tax to fund education and public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Christine Drazan, SD-26
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare; 2022 gubernatorial candidate who opposed abortion expansion; anti-abortion position well-documented throughout career. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout opposing climate legislation; as 2022 gubernatorial candidate, opposed cap-and-trade and clean energy mandates as job-killing regulations. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'a22215c3-6693-4bc2-b248-01aebba14570', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'a22215c3-6693-4bc2-b248-01aebba14570',
$$Opposed fossil fuel restrictions and cap-and-trade; as gubernatorial candidate, supported continued fossil fuel industry in Oregon; opposed clean energy mandates. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposed government-run healthcare mandates as gubernatorial candidate; advocated for market-based healthcare reform; voted against Medicaid expansion requirements. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill; supported removing regulatory barriers to housing development as market-based solution. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
$$Opposed sanctuary policies as 2022 gubernatorial candidate; supported stricter immigration enforcement; advocated for border security measures. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Advocated strongly for law enforcement funding and tougher criminal penalties as gubernatorial candidate; opposed Measure 110 drug decriminalization; made public safety central campaign theme. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; as House Minority Leader and gubernatorial candidate, consistently opposed tax increases; made tax reduction a key campaign platform. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$$Opposed transgender athletes in female sports; consistent Republican position supported in 2022 campaign statements. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('402a00be-71c3-4584-b29f-bf493365bffb', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
$$Opposed automatic voter registration and questioned some election procedures; supported voter ID requirements; conservative position on election security vs. access tradeoffs. https://ballotpedia.org/Christine_Drazan$$,
ARRAY['https://ballotpedia.org/Christine_Drazan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Anthony Broadman, SD-27
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Supported civil rights protections and anti-discrimination measures; voted YES on HB 2002 gender-affirming care. https://ballotpedia.org/Anthony_Broadman$$,
ARRAY['https://ballotpedia.org/Anthony_Broadman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Voted YES on clean energy legislation; Central Oregon Democrat focused on outdoor recreation and environmental protection of high desert region. https://ballotpedia.org/Anthony_Broadman$$,
ARRAY['https://ballotpedia.org/Anthony_Broadman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Supported Oregon Health Plan expansion and healthcare access; voted YES on healthcare coverage bills. https://ballotpedia.org/Anthony_Broadman$$,
ARRAY['https://ballotpedia.org/Anthony_Broadman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill; active on housing issues in Bend which faces severe housing shortage. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3af0dfad-d1a1-4c91-a859-6f17c5e238b9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted YES on tax measures supporting public investment in services and infrastructure. https://ballotpedia.org/Anthony_Broadman$$,
ARRAY['https://ballotpedia.org/Anthony_Broadman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Diane Linthicum, SD-28
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout opposing climate legislation; represents agricultural and timber Klamath Falls region dependent on water rights and resource use. https://ballotpedia.org/Diane_Linthicum$$,
ARRAY['https://ballotpedia.org/Diane_Linthicum']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('50eab431-7b51-4a56-acaa-61af3509c298', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; consistent anti-tax position representing rural agricultural district. https://ballotpedia.org/Diane_Linthicum$$,
ARRAY['https://ballotpedia.org/Diane_Linthicum']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Todd Nash, SD-29
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Rancher and livestock industry representative; participated in 2023 Republican walkout opposing climate legislation; strongly opposes regulations affecting agriculture and Eastern Oregon water rights. https://ballotpedia.org/Todd_Nash$$,
ARRAY['https://ballotpedia.org/Todd_Nash']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('86d23630-36ff-48a7-b2ac-6071a0cabd64', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; consistent anti-tax position representing rural agricultural district. https://ballotpedia.org/Todd_Nash$$,
ARRAY['https://ballotpedia.org/Todd_Nash']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- Mike McLane, SD-30
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
$$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access in Oregon; consistent anti-abortion voting record. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Participated in May 2023 Senate Republican walkout blocking climate legislation; as former House Minority Leader, led opposition to cap-and-trade and clean energy mandates. https://ballotpedia.org/Mike_McLane$$,
ARRAY['https://ballotpedia.org/Mike_McLane']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Opposed government-run healthcare mandates; voted against Medicaid expansion requirements as House Minority Leader. https://ballotpedia.org/Mike_McLane$$,
ARRAY['https://ballotpedia.org/Mike_McLane']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Voted YES on SB 1537 (2024) bipartisan housing supply bill; supported market-based approaches to housing development. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1537']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Supported law enforcement funding and opposed Measure 110 drug decriminalization; advocated for tougher public safety measures. https://ballotpedia.org/Mike_McLane$$,
ARRAY['https://ballotpedia.org/Mike_McLane']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Voted NO on HB 3427 (2019) Corporate Activity Tax; former House Minority Leader leading Republican opposition to tax increases. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('252a2adf-68a5-4b5a-9024-d5635e2fbd88', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
$$Voted in favor of measures restricting transgender athletes in school sports; consistent conservative social position. https://ballotpedia.org/Mike_McLane$$,
ARRAY['https://ballotpedia.org/Mike_McLane']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


COMMIT;