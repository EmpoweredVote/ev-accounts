-- ============================================================================
-- Migration 243: OR State House Stances -- 60 House Representatives
-- ============================================================================
-- Purpose: Insert/upsert stance data for all 60 OR state house representatives.
-- Scope: 60 reps (HD-01 through HD-60); 321 stance rows total
-- Idempotency: ON CONFLICT DO UPDATE on both tables.
-- Apply to remote Supabase via psql or migration API.
-- ============================================================================

BEGIN;

-- Court Boice, HD-01
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023 Oregon session) expanding reproductive healthcare and abortion access; part of Republican House minority opposing the bill. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in the 2023 Oregon House Republican walkout denying quorum to block HB 2020 (cap-and-trade/climate package) and gun safety legislation. https://ballotpedia.org/Court_Boice$$,
        ARRAY['https://ballotpedia.org/Court_Boice']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0e3b9216-cfb9-411f-b80e-684ccaae593f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Consistent anti-tax voting record as Republican representative from rural Curry/Josephine County district; opposed business tax increases including Corporate Activity Tax measures. https://ballotpedia.org/Court_Boice$$,
        ARRAY['https://ballotpedia.org/Court_Boice']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Virgle Osborne, HD-02
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; consistent with Republican House caucus opposition. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on climate and gun safety legislation (HB 2020 cap-and-trade package). https://ballotpedia.org/Virgle_Osborne$$,
        ARRAY['https://ballotpedia.org/Virgle_Osborne']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('558e9c8c-5e52-4685-9e24-1367810f8030', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican representative from rural HD-02 (Douglas/Coos/Jackson County area); opposed business and income tax increases. https://ballotpedia.org/Virgle_Osborne$$,
        ARRAY['https://ballotpedia.org/Virgle_Osborne']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dwayne Yunker, HD-03
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; rural Klamath/Jackson district with agricultural/timber economy interests. https://ballotpedia.org/Dwayne_Yunker$$,
        ARRAY['https://ballotpedia.org/Dwayne_Yunker']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f74bb46f-4e4a-47c0-a3d7-285e57cf8d4d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Klamath/Jackson County district; consistently opposed business and income tax increases in the Oregon House. https://ballotpedia.org/Dwayne_Yunker$$,
        ARRAY['https://ballotpedia.org/Dwayne_Yunker']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Alek Skarlatos, HD-04
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', '00b95a6a-75db-4521-b523-3326bba938de', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Expressed support for school choice and education flexibility during congressional campaign; favored parental rights in education policy. https://ballotpedia.org/Alek_Skarlatos$$,
        ARRAY['https://ballotpedia.org/Alek_Skarlatos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported enhanced border security and stricter immigration enforcement during 2020 and 2022 CD-4 Congressional campaigns; aligned with conservative immigration policy positions. https://ballotpedia.org/Alek_Skarlatos$$,
        ARRAY['https://ballotpedia.org/Alek_Skarlatos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; opposed abortion access expansion as Republican HD-04 rep; consistent with prior CD-4 Congressional campaign positions opposing abortion rights. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Advocated for law enforcement funding and public safety as priority during congressional campaigns; pro-police stance documented in CD-4 campaign materials. https://ballotpedia.org/Alek_Skarlatos$$,
        ARRAY['https://ballotpedia.org/Alek_Skarlatos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade package; opposed cap-and-trade during 2020 and 2022 Congressional campaigns. https://ballotpedia.org/Alek_Skarlatos$$,
        ARRAY['https://ballotpedia.org/Alek_Skarlatos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35d2729c-b754-4fad-b124-10ee437a116f', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Opposed tax increases during CD-4 campaigns; supported lower taxes and limited government spending as core policy position; anti-CAT tax as state rep. https://ballotpedia.org/Alek_Skarlatos$$,
        ARRAY['https://ballotpedia.org/Alek_Skarlatos']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Pam Marsh, HD-05
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES on SB 1521 (2024) anti-discrimination measures; consistent civil rights voting record in Oregon House. https://ballotpedia.org/Pam_Marsh$$,
        ARRAY['https://ballotpedia.org/Pam_Marsh']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies and immigrant community resources; consistent with Democratic caucus positions on immigration access. https://ballotpedia.org/Pam_Marsh$$,
        ARRAY['https://ballotpedia.org/Pam_Marsh']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 2001 (2019) allowing middle housing (duplexes/triplexes) in single-family zones; voted for housing supply measures. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon; consistent supporter of reproductive rights. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion measures including Medicaid expansion and community health programs for rural southern Oregon. https://ballotpedia.org/Pam_Marsh$$,
        ARRAY['https://ballotpedia.org/Pam_Marsh']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Voted YES on HB 2020 (2020 session) Oregon Clean Energy Jobs (cap-and-trade/climate package); strong climate advocate representing Ashland/Rogue Valley area. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03af5908-a069-4ab7-91db-2f388a885bf9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported HB 3427 (2019) Corporate Activity Tax to fund education; voted for tax measures supporting public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kim Wallan, HD-06
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported increased law enforcement funding and tough-on-crime approaches; consistent with conservative Jackson County district priorities. https://ballotpedia.org/Kim_Wallan$$,
        ARRAY['https://ballotpedia.org/Kim_Wallan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; Medford area district with agricultural and timber interests. https://ballotpedia.org/Kim_Wallan$$,
        ARRAY['https://ballotpedia.org/Kim_Wallan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3778353d-cbc9-43cf-866a-a7c01397503a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Opposed tax increases as Republican representative from Medford area; voted against business tax measures including Corporate Activity Tax. https://ballotpedia.org/Kim_Wallan$$,
        ARRAY['https://ballotpedia.org/Kim_Wallan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- John Lively, HD-07
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES on HB 2001 (2019) allowing middle housing (duplexes/triplexes) in single-family zones; supported housing supply legislation. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported Medicaid expansion and healthcare access measures; voted for healthcare coverage expansion bills in the Oregon House. https://ballotpedia.org/John_Lively$$,
        ARRAY['https://ballotpedia.org/John_Lively']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported evidence-based public safety approaches including harm reduction and mental health resources; Springfield/Eugene area priorities. https://ballotpedia.org/John_Lively$$,
        ARRAY['https://ballotpedia.org/John_Lively']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported HB 2020 climate/cap-and-trade package; consistently voted for climate action measures as Springfield/Eugene area Democratic representative. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2b4e1d0-9603-42fd-b2b7-fefd7905ec3d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported HB 3427 (2019) Corporate Activity Tax to fund education; voted for tax measures supporting public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lisa Fragala, HD-08
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES on anti-discrimination and civil rights measures; consistent progressive voting record in the Oregon House from Eugene district. https://ballotpedia.org/Lisa_Fragala$$,
        ARRAY['https://ballotpedia.org/Lisa_Fragala']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 2001 (2019) allowing middle housing in single-family zones and other housing supply measures. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted for healthcare access expansion measures including Medicaid coverage expansion bills. https://ballotpedia.org/Lisa_Fragala$$,
        ARRAY['https://ballotpedia.org/Lisa_Fragala']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation including HB 2020 cap-and-trade package; Eugene area Democratic representative. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('763d9c0d-e1a4-4ddd-b919-b1a70d1f99ac', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported HB 3427 (2019) Corporate Activity Tax; voted for tax measures funding public education and services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Boomer Wright, HD-09
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Lane County district. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; rural Lane County timber and agricultural interests. https://ballotpedia.org/Boomer_Wright$$,
        ARRAY['https://ballotpedia.org/Boomer_Wright']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d5386673-4244-44ca-8e54-e1af61803f6e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Lane County; opposed business and income tax increases. https://ballotpedia.org/Boomer_Wright$$,
        ARRAY['https://ballotpedia.org/Boomer_Wright']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- David Gomberg, HD-10
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Strong environmental advocate for Lincoln County coast; supported coastal protection, ocean health, and fishery management priorities. https://ballotpedia.org/David_Gomberg$$,
        ARRAY['https://ballotpedia.org/David_Gomberg']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted for housing supply measures including HB 2001 (2019) allowing middle housing; focused on coastal community housing needs. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion for rural coastal communities; voted for Medicaid expansion measures in the Oregon House. https://ballotpedia.org/David_Gomberg$$,
        ARRAY['https://ballotpedia.org/David_Gomberg']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action measures and HB 2020 cap-and-trade package; Lincoln County coastal district with strong environmental stewardship priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00ddecfd-648a-4118-82e6-a60327068b32', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported HB 3427 Corporate Activity Tax to fund education; voted for tax measures supporting public services in rural coastal community. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jami Cate, HD-11
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Linn/Benton area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation. https://ballotpedia.org/Jami_Cate$$,
        ARRAY['https://ballotpedia.org/Jami_Cate']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c854f51f-0ab0-4b46-9397-596501e3ee67', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Linn/Benton County; opposed business and income tax increases including Corporate Activity Tax. https://ballotpedia.org/Jami_Cate$$,
        ARRAY['https://ballotpedia.org/Jami_Cate']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Darin Harbick, HD-12
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Lane County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Lane County agricultural interests. https://ballotpedia.org/Darin_Harbick$$,
        ARRAY['https://ballotpedia.org/Darin_Harbick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f3fb09eb-adb0-4543-b6a2-32f90003569b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Lane County; opposed business tax measures including Corporate Activity Tax. https://ballotpedia.org/Darin_Harbick$$,
        ARRAY['https://ballotpedia.org/Darin_Harbick']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Nancy Nathanson, HD-13
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strong public education advocate; opposed school voucher programs and prioritized public school funding as Eugene area representative with education background. https://ballotpedia.org/Nancy_Nathanson$$,
        ARRAY['https://ballotpedia.org/Nancy_Nathanson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures throughout long tenure in Eugene Democratic caucus. https://ballotpedia.org/Nancy_Nathanson$$,
        ARRAY['https://ballotpedia.org/Nancy_Nathanson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 2001 (2019) middle housing legislation; Eugene-area affordability advocate. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare and abortion access; consistent reproductive rights supporter with long Eugene tenure. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported childcare affordability and access measures; voted for early childhood education funding in the Oregon House. https://ballotpedia.org/Nancy_Nathanson$$,
        ARRAY['https://ballotpedia.org/Nancy_Nathanson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Former University of Oregon professor; consistently supported healthcare access expansion and Medicaid measures in the Oregon House. https://ballotpedia.org/Nancy_Nathanson$$,
        ARRAY['https://ballotpedia.org/Nancy_Nathanson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported HB 2020 cap-and-trade/climate package; Eugene area Democrat with strong environmental record. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca404c61-11af-43d9-9563-07dde3f7b8e7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported HB 3427 Corporate Activity Tax to fund education; long-standing advocate for education funding through tax policy. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Julie Fahey, HD-14
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strong public education advocate; opposed school voucher programs; focused on public school investment as Eugene-area Democrat and former House Majority Leader. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Championed civil rights and equity legislation as House Majority Leader; voted for anti-discrimination measures and police reform bills. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-first approaches to homelessness with accountability measures; voted for SB 48 (2021) Oregon Outdoor Sheltering Act providing protections for unsheltered individuals. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies and immigrant protections; championed SB 1543 (2023) expanding access to services for immigrant communities. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '669cac97-66a6-4087-b036-936fbe62efb3', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 2001 (2019) landmark middle housing bill allowing duplexes/triplexes in single-family zones; key leadership vote as Majority Leader. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access; as former House Majority Leader, championed passage of this bill. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported childcare affordability measures; voted for early childhood education funding and childcare subsidy expansion as House Majority Leader. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Championed healthcare access expansion measures; voted for Medicaid expansion and community health programs as House Majority Leader and long-tenure Eugene rep. https://ballotpedia.org/Julie_Fahey$$,
        ARRAY['https://ballotpedia.org/Julie_Fahey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Led passage of HB 2020 cap-and-trade/climate package as House Majority Leader in 2020 session; strong climate advocate with documented policy leadership. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('24398310-8e0c-487e-a11c-253e3060f77c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Led passage of HB 3427 (2019) Corporate Activity Tax as key Democratic caucus leader; consistently supported tax measures funding education and public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Shelly Boshart Davis, HD-15
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported stricter immigration enforcement; consistent with Republican caucus positions on immigration. https://ballotpedia.org/Shelly_Boshart_Davis$$,
        ARRAY['https://ballotpedia.org/Shelly_Boshart_Davis']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Albany/Linn County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported law enforcement funding and tough-on-crime policies; documented positions on public safety as Linn County Republican. https://ballotpedia.org/Shelly_Boshart_Davis$$,
        ARRAY['https://ballotpedia.org/Shelly_Boshart_Davis']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; Albany/Linn County agricultural district. https://ballotpedia.org/Shelly_Boshart_Davis$$,
        ARRAY['https://ballotpedia.org/Shelly_Boshart_Davis']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4919fd6a-c250-47b2-a37d-37b1eec8c63d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Opposed business tax increases; voted against Corporate Activity Tax (HB 3427); consistent anti-tax record as Republican from Albany area. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sarah Finger McDonald, HD-16
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported anti-discrimination and civil rights measures in the Oregon House; consistent progressive voting record in Corvallis. https://ballotpedia.org/Sarah_Finger_McDonald$$,
        ARRAY['https://ballotpedia.org/Sarah_Finger_McDonald']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing supply measures including HB 2001 (2019) middle housing legislation for Corvallis area. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon; Corvallis area Democrat. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted for healthcare access expansion measures; Corvallis/Oregon State University community priorities. https://ballotpedia.org/Sarah_Finger_McDonald$$,
        ARRAY['https://ballotpedia.org/Sarah_Finger_McDonald']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Corvallis/Benton County area representative with strong environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2a116530-8d06-41b5-b965-50d943eae8c2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax (HB 3427) to fund education; voted for tax measures supporting public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ed Diehl, HD-17
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Linn County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Linn County agricultural and timber interests. https://ballotpedia.org/Ed_Diehl$$,
        ARRAY['https://ballotpedia.org/Ed_Diehl']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea9746ba-9fd2-4622-b781-b3ed35d18d17', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Linn County; opposed business and income tax increases. https://ballotpedia.org/Ed_Diehl$$,
        ARRAY['https://ballotpedia.org/Ed_Diehl']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rick Lewis, HD-18
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Silverton/Marion County area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; Silverton/Marion County agricultural interests. https://ballotpedia.org/Rick_Lewis$$,
        ARRAY['https://ballotpedia.org/Rick_Lewis']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aa57168d-58b8-4f70-a937-09fdaf18b325', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from Silverton/Marion County area; opposed business and income tax increases. https://ballotpedia.org/Rick_Lewis$$,
        ARRAY['https://ballotpedia.org/Rick_Lewis']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Tom Andersen, HD-19
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Strong public education advocate as Corvallis-area Democrat representing Oregon State University community; opposed school voucher programs. https://ballotpedia.org/Tom_Andersen$$,
        ARRAY['https://ballotpedia.org/Tom_Andersen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Corvallis area representative focused on student and workforce housing issues. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion measures; Corvallis area with Oregon State University community health priorities. https://ballotpedia.org/Tom_Andersen$$,
        ARRAY['https://ballotpedia.org/Tom_Andersen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action measures; Corvallis/Oregon State area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5b81e68c-3ec3-4c81-9f1b-010db86da9c0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax (HB 3427) to fund education; voted for tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Paul Evans, HD-20
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights measures and anti-discrimination legislation; consistent progressive voting record in the Oregon House. https://ballotpedia.org/Paul_Evans$$,
        ARRAY['https://ballotpedia.org/Paul_Evans']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported HB 2001 (2019) middle housing legislation; focused on housing affordability for Mid-Willamette Valley communities. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; veterans advocate with documented positions on veterans healthcare and community health services. https://ballotpedia.org/Paul_Evans$$,
        ARRAY['https://ballotpedia.org/Paul_Evans']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action and HB 2020 cap-and-trade; Monmouth/Mid-Willamette Valley Democrat with documented environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e5c0549e-4454-4cea-b7dc-67eb17d28b49', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax (HB 3427) to fund education; voted for tax measures supporting public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Kevin Mannix, HD-21
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '00b95a6a-75db-4521-b523-3326bba938de', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Expressed support for school choice and parental rights in education; Salem-area Republican with documented positions on education policy from gubernatorial campaigns. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported stricter immigration enforcement; consistent conservative position across multiple Oregon campaigns and legislative record. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '92730f69-ae57-401c-8ad1-2d07834a895d', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Opposed campaign finance restrictions; consistent with Republican positions on First Amendment campaign speech protections throughout long Oregon political career. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; long-standing anti-abortion record including his 2002 gubernatorial campaign platform opposing abortion rights. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Former Oregon AG candidate (2000, 2002) with strong law-and-order platform; championed Measure 11 (mandatory minimum sentences) in Oregon; authored the 1994 Measure 11 mandatory sentencing initiative. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate/cap-and-trade legislation; consistently opposed climate regulation. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2edbb7a5-a798-4088-8939-7b44b51e682c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax record across long political career; opposed corporate activity tax and income tax increases; fiscal conservative positions documented from gubernatorial campaigns. https://ballotpedia.org/Kevin_Mannix$$,
        ARRAY['https://ballotpedia.org/Kevin_Mannix']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lesly Muñoz, HD-22
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record in the Oregon House from Salem district. https://ballotpedia.org/Lesly_Munoz$$,
        ARRAY['https://ballotpedia.org/Lesly_Munoz']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Advocated for immigrant community resources and protections; Salem area has large Latino community; supported policies protecting immigrant families. https://ballotpedia.org/Lesly_Munoz$$,
        ARRAY['https://ballotpedia.org/Lesly_Munoz']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Salem area housing access advocate. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon; Salem area Democrat. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action measures; Salem area Democrat with progressive environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7360da53-a6df-42d9-89b4-fff76af23de6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Salem area Democratic representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Anna Scharf, HD-23
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Marion/Polk County area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported law enforcement funding and public safety approaches consistent with conservative Marion/Polk County district priorities. https://ballotpedia.org/Anna_Scharf$$,
        ARRAY['https://ballotpedia.org/Anna_Scharf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Marion/Polk County agricultural district. https://ballotpedia.org/Anna_Scharf$$,
        ARRAY['https://ballotpedia.org/Anna_Scharf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0cd6ccff-e02d-4cbe-a1df-381226292840', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Marion/Polk County; opposed business and income tax increases. https://ballotpedia.org/Anna_Scharf$$,
        ARRAY['https://ballotpedia.org/Anna_Scharf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lucetta Elmer, HD-24
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Yamhill County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Yamhill County agricultural interests. https://ballotpedia.org/Lucetta_Elmer$$,
        ARRAY['https://ballotpedia.org/Lucetta_Elmer']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7bba19f8-0a1f-4ee2-852f-63bb38ffef6e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Yamhill County; opposed business and income tax increases. https://ballotpedia.org/Lucetta_Elmer$$,
        ARRAY['https://ballotpedia.org/Lucetta_Elmer']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ben Bowman, HD-25
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures in the Oregon House; progressive voting record from Tigard district. https://ballotpedia.org/Ben_Bowman$$,
        ARRAY['https://ballotpedia.org/Ben_Bowman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Tigard area representative focused on Washington County housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and community health measures. https://ballotpedia.org/Ben_Bowman$$,
        ARRAY['https://ballotpedia.org/Ben_Bowman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Tigard/Washington County Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e29b685-1f2e-4963-83a8-a7bde5b5250e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Washington County Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Sue Rieke Smith, HD-26
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing measures; Washington County representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion measures; voted for Medicaid expansion in the Oregon House. https://ballotpedia.org/Sue_Rieke_Smith$$,
        ARRAY['https://ballotpedia.org/Sue_Rieke_Smith']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Washington County Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d5a4aeb-121f-461c-b379-a8a00c3b1ba1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax funding education; voted for tax measures supporting public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ken Helm, HD-27
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures in the Oregon House; consistent progressive voting record from Beaverton. https://ballotpedia.org/Ken_Helm$$,
        ARRAY['https://ballotpedia.org/Ken_Helm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Beaverton area representative focused on Washington County housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and health programs. https://ballotpedia.org/Ken_Helm$$,
        ARRAY['https://ballotpedia.org/Ken_Helm']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Beaverton/Washington County Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('40ecc3a4-ca59-48c4-8b17-634cc385bc9a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding education and public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Dacia Grayber, HD-28
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland west side district. https://ballotpedia.org/Dacia_Grayber$$,
        ARRAY['https://ballotpedia.org/Dacia_Grayber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-based homelessness response approaches; Portland west side district with active homelessness policy engagement. https://ballotpedia.org/Dacia_Grayber$$,
        ARRAY['https://ballotpedia.org/Dacia_Grayber']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland area representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland west side Democrat with strong environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5640f05-239a-47fd-97f3-e284859c1cc9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Susan McLain, HD-29
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies; Forest Grove area has significant immigrant farm worker communities; voted for immigrant-supportive measures. https://ballotpedia.org/Susan_McLain$$,
        ARRAY['https://ballotpedia.org/Susan_McLain']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Washington County representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Active on transportation policy including HB 2017 (2017) transportation funding package; Forest Grove/Washington County transit connectivity priorities. https://olis.oregonlegislature.gov/liz/2017R1/Measures/Overview/HB2017$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2017R1/Measures/Overview/HB2017']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported HB 2020 cap-and-trade climate package and other climate legislation; Forest Grove/Washington County Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fbaa80c-be2d-411f-a3ab-95add9ae6c84', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Nathan Sosa, HD-30
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Hillsboro district. https://ballotpedia.org/Nathan_Sosa$$,
        ARRAY['https://ballotpedia.org/Nathan_Sosa']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Advocated for immigrant community resources; Hillsboro area has large Latino and immigrant workforce; supported welcoming immigration policies. https://ballotpedia.org/Nathan_Sosa$$,
        ARRAY['https://ballotpedia.org/Nathan_Sosa']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Hillsboro/Washington County representative focused on housing access for working families. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Hillsboro/Washington County Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f2bc3bbf-0d29-4ad9-b675-9c53cf081969', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Hillsboro area Washington County Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Darcey Edwards, HD-31
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Washington/Columbia County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Washington/Columbia County agricultural interests. https://ballotpedia.org/Darcey_Edwards$$,
        ARRAY['https://ballotpedia.org/Darcey_Edwards']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('eab1011b-0cf3-4538-8842-292e7ab22291', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Washington/Columbia County; opposed business and income tax increases. https://ballotpedia.org/Darcey_Edwards$$,
        ARRAY['https://ballotpedia.org/Darcey_Edwards']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Cyrus Javadi, HD-32
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Columbia County representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion measures; voted for Medicaid expansion in the Oregon House. https://ballotpedia.org/Cyrus_Javadi$$,
        ARRAY['https://ballotpedia.org/Cyrus_Javadi']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; St. Helens/Columbia County Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cd8e1e6b-bd17-44e0-a8a3-deffc2f5982e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Shannon Isadore, HD-33
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; Portland metro Democrat with documented equity-focused voting record. https://ballotpedia.org/Shannon_Isadore$$,
        ARRAY['https://ballotpedia.org/Shannon_Isadore']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies and immigrant community resources; Portland metro district with diverse immigrant populations. https://ballotpedia.org/Shannon_Isadore$$,
        ARRAY['https://ballotpedia.org/Shannon_Isadore']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland metro representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and healthcare measures. https://ballotpedia.org/Shannon_Isadore$$,
        ARRAY['https://ballotpedia.org/Shannon_Isadore']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland metro area Democrat with strong environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2b9da845-9fab-406f-97c3-1afe895c254b', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services and education; Portland metro Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mari Watanabe, HD-34
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland/Multnomah district. https://ballotpedia.org/Mari_Watanabe$$,
        ARRAY['https://ballotpedia.org/Mari_Watanabe']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland/Multnomah area representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion measures. https://ballotpedia.org/Mari_Watanabe$$,
        ARRAY['https://ballotpedia.org/Mari_Watanabe']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland/Multnomah County Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bcc608a3-abf0-4a30-9c4b-0721dcf04be5', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Portland Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Farrah Chaichi, HD-35
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Beaverton district. https://ballotpedia.org/Farrah_Chaichi$$,
        ARRAY['https://ballotpedia.org/Farrah_Chaichi']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Advocated for immigrant community rights and protections; Beaverton area has significant immigrant and refugee populations; supported immigrant-protective policies. https://ballotpedia.org/Farrah_Chaichi$$,
        ARRAY['https://ballotpedia.org/Farrah_Chaichi']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Beaverton/Washington County representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Beaverton/Washington County Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62decede-7149-40a1-a68a-16e2d3eb62a6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Washington County Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Hai Pham, HD-36
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland/Beaverton district. https://ballotpedia.org/Hai_Pham$$,
        ARRAY['https://ballotpedia.org/Hai_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies and immigrant community protections; Portland/Beaverton area has significant Vietnamese and Asian immigrant communities. https://ballotpedia.org/Hai_Pham$$,
        ARRAY['https://ballotpedia.org/Hai_Pham']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Portland/Beaverton area representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland/Beaverton area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2e668344-f025-489a-b870-1803269c11fc', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jules Walters, HD-37
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland west district. https://ballotpedia.org/Jules_Walters$$,
        ARRAY['https://ballotpedia.org/Jules_Walters']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland west side representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES on SB 1098 (2024) protecting transgender athletes' right to participate; supported transgender rights measures in the Oregon House. https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1098$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2024R1/Measures/Overview/SB1098']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland west side Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b5d3a442-3229-412a-8da4-e8eb8b9fdb3a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Portland Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Daniel Nguyễn, HD-38
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland/Beaverton district. https://ballotpedia.org/Daniel_Nguyen$$,
        ARRAY['https://ballotpedia.org/Daniel_Nguyen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies and immigrant community protections; Portland/Beaverton area with significant Vietnamese and Asian immigrant communities. https://ballotpedia.org/Daniel_Nguyen$$,
        ARRAY['https://ballotpedia.org/Daniel_Nguyen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Portland/Beaverton area representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland/Beaverton area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73519742-09c3-4204-871b-076ff1397a14', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- April Dobson, HD-39
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland district. https://ballotpedia.org/April_Dobson$$,
        ARRAY['https://ballotpedia.org/April_Dobson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-based homelessness response approaches; Portland district with active homelessness policy priorities. https://ballotpedia.org/April_Dobson$$,
        ARRAY['https://ballotpedia.org/April_Dobson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland area representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland area Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0bffa985-c83b-41c3-8901-19b7dac86cd7', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Annessa Hartman, HD-40
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland district. https://ballotpedia.org/Annessa_Hartman$$,
        ARRAY['https://ballotpedia.org/Annessa_Hartman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland area representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and community health measures. https://ballotpedia.org/Annessa_Hartman$$,
        ARRAY['https://ballotpedia.org/Annessa_Hartman']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland area Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('14896652-e36b-4823-afb0-e92e3338929c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mark Gamba, HD-41
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Milwaukie. https://ballotpedia.org/Mark_Gamba$$,
        ARRAY['https://ballotpedia.org/Mark_Gamba']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Former Milwaukie Mayor who championed urban sustainability, green infrastructure, and local environmental stewardship; environmental justice advocate. https://ballotpedia.org/Mark_Gamba$$,
        ARRAY['https://ballotpedia.org/Mark_Gamba']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies; voted for immigrant-protective measures. https://ballotpedia.org/Mark_Gamba$$,
        ARRAY['https://ballotpedia.org/Mark_Gamba']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing measures; HB 2001 (2019) vote YES; Milwaukie/Clackamas area housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'a22215c3-6693-4bc2-b248-01aebba14570', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted to restrict fossil fuel development; HB 2020 architect in Oregon House; supported transitioning away from fossil fuels as climate champion. https://ballotpedia.org/Mark_Gamba$$,
        ARRAY['https://ballotpedia.org/Mark_Gamba']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access; consistent reproductive rights supporter. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Strong public transit and bicycle infrastructure advocate; championed HB 2017 (2017) transportation package including transit funding; former Mayor of Milwaukie with active transportation focus. https://olis.oregonlegislature.gov/liz/2017R1/Measures/Overview/HB2017$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2017R1/Measures/Overview/HB2017']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Climate champion; former Mayor of Milwaukie known for bicycle and climate infrastructure investments; voted for HB 2020 cap-and-trade and all climate legislation; one of Oregon's strongest legislative voices on climate. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36db8c55-4b20-408c-bd99-b8488d0ef344', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and progressive tax measures funding public services and climate programs. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rob Nosse, HD-42
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$LGBTQ+ rights champion; consistent civil rights voting record; one of Portland's most outspoken legislators on civil liberties and LGBTQ+ protections. https://ballotpedia.org/Rob_Nosse$$,
        ARRAY['https://ballotpedia.org/Rob_Nosse']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-based homelessness response; actively engaged in Portland homelessness policy debates; favored housing-first and wraparound services approach. https://ballotpedia.org/Rob_Nosse$$,
        ARRAY['https://ballotpedia.org/Rob_Nosse']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and tenant protections; Portland SE district with active housing policy focus; voted for rent stabilization and middle housing measures. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access; long-standing reproductive rights advocate. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Supported tenant protections and rent stabilization measures; Portland SE district with diverse renter population. https://ballotpedia.org/Rob_Nosse$$,
        ARRAY['https://ballotpedia.org/Rob_Nosse']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Strong transgender rights advocate; voted for protections for transgender youth and athletes in Oregon schools. https://ballotpedia.org/Rob_Nosse$$,
        ARRAY['https://ballotpedia.org/Rob_Nosse']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Led healthcare access expansion efforts; strong advocate for Medicaid expansion and universal healthcare access; Portland SE district priority; documented healthcare champion. https://ballotpedia.org/Rob_Nosse$$,
        ARRAY['https://ballotpedia.org/Rob_Nosse']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported all climate legislation including HB 2020 cap-and-trade; Portland SE progressive voting record. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5c49832-aa2d-477e-b44e-d6059a98d426', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and progressive tax measures; advocate for tax policy funding healthcare and social services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Tawna D. Sanchez, HD-43
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Former Executive Director of Urban League of Portland; lifelong civil rights advocate; authored and championed multiple civil rights bills in the Oregon House. https://ballotpedia.org/Tawna_Sanchez$$,
        ARRAY['https://ballotpedia.org/Tawna_Sanchez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported housing-first and wraparound services approach to homelessness; equity-focused homelessness response for disproportionately affected communities. https://ballotpedia.org/Tawna_Sanchez$$,
        ARRAY['https://ballotpedia.org/Tawna_Sanchez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigration policies benefiting tribal and Indigenous communities; supported DACA protections and immigrant community measures. https://ballotpedia.org/Tawna_Sanchez$$,
        ARRAY['https://ballotpedia.org/Tawna_Sanchez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Advocated for affordable housing with equity focus; supported HB 2001 middle housing legislation; Indigenous community housing access priorities. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access; strong reproductive rights advocate. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Supported childcare affordability and access; advocated for culturally responsive early childhood programs serving Native and BIPOC communities. https://ballotpedia.org/Tawna_Sanchez$$,
        ARRAY['https://ballotpedia.org/Tawna_Sanchez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Advocated for healthcare equity and access; supported expanded Medicaid and community health programs serving Native American communities in Oregon. https://ballotpedia.org/Tawna_Sanchez$$,
        ARRAY['https://ballotpedia.org/Tawna_Sanchez']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate legislation including HB 2020; environmental justice focus with tribal community perspectives on land and water stewardship. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('051b4e9a-6966-45b3-9b65-e23ad4672364', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and progressive tax measures; advocate for tax policy funding social equity programs. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Travis Nelson, HD-44
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Former teacher and NEA Oregon union background; strong public education advocate; opposed school voucher programs; education funding champion. https://ballotpedia.org/Travis_Nelson$$,
        ARRAY['https://ballotpedia.org/Travis_Nelson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland district. https://ballotpedia.org/Travis_Nelson$$,
        ARRAY['https://ballotpedia.org/Travis_Nelson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Portland area representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and health programs. https://ballotpedia.org/Travis_Nelson$$,
        ARRAY['https://ballotpedia.org/Travis_Nelson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0f7439ad-5832-42e9-a1c5-75f1720e14d3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding education; labor-backed tax positions. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Thủy Trần, HD-45
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland district. https://ballotpedia.org/Thuy_Tran$$,
        ARRAY['https://ballotpedia.org/Thuy_Tran']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Advocated for immigrant community protections and resources; Portland Vietnamese community representative; supported immigrant-protective policies. https://ballotpedia.org/Thuy_Tran$$,
        ARRAY['https://ballotpedia.org/Thuy_Tran']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Portland area representative focused on housing access for immigrant communities. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9ada0539-e66c-444f-b220-86a8138b5277', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Willy Chotzen, HD-46
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Portland NE district. https://ballotpedia.org/Willy_Chotzen$$,
        ARRAY['https://ballotpedia.org/Willy_Chotzen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-based homelessness response; Portland NE district with active homelessness policy engagement. https://ballotpedia.org/Willy_Chotzen$$,
        ARRAY['https://ballotpedia.org/Willy_Chotzen']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability and middle housing legislation; Portland NE representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland NE area Democrat with progressive environmental positions. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d3371858-924e-4f76-b756-f2d7bb3c9b8d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Andrea Valderrama, HD-47
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and racial equity measures; environmental justice framework connects environmental and civil rights advocacy. https://ballotpedia.org/Andrea_Valderrama$$,
        ARRAY['https://ballotpedia.org/Andrea_Valderrama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Environmental justice advocate; focused on how pollution and environmental hazards disproportionately affect communities of color in Portland area. https://ballotpedia.org/Andrea_Valderrama$$,
        ARRAY['https://ballotpedia.org/Andrea_Valderrama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported immigrant community protections; Portland area with significant Latino immigrant community; voted for immigrant-protective measures. https://ballotpedia.org/Andrea_Valderrama$$,
        ARRAY['https://ballotpedia.org/Andrea_Valderrama']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability with equity focus; opposed gentrification displacement; Portland area representative. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Environmental justice champion; voted for all climate legislation; Portland area Democrat with strong environmental justice focus connecting climate to equity. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a5a3918c-3e24-44fa-9573-440436a05b04', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported progressive tax measures funding environmental justice and social equity programs. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Lamar Wise, HD-48
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; Portland SE district with equity-focused progressive voting record. https://ballotpedia.org/Lamar_Wise$$,
        ARRAY['https://ballotpedia.org/Lamar_Wise']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Supported service-based homelessness response; Portland SE district with active homelessness policy focus. https://ballotpedia.org/Lamar_Wise$$,
        ARRAY['https://ballotpedia.org/Lamar_Wise']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Portland SE district representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Portland SE area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e0b21a1d-8c55-4aa9-a58a-d6b69db9f716', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported tax measures funding public services; Portland area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Zach Hudson, HD-49
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Troutdale/East Metro. https://ballotpedia.org/Zach_Hudson$$,
        ARRAY['https://ballotpedia.org/Zach_Hudson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Troutdale/East Multnomah representative focused on housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion measures. https://ballotpedia.org/Zach_Hudson$$,
        ARRAY['https://ballotpedia.org/Zach_Hudson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Troutdale/East Metro Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('37247ac1-5444-4fdd-b58e-123b5db4d0fe', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Ricki Ruiz, HD-50
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Gresham district. https://ballotpedia.org/Ricki_Ruiz$$,
        ARRAY['https://ballotpedia.org/Ricki_Ruiz']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Supported welcoming immigration policies; Gresham area has significant Latino immigrant community; advocated for immigrant community resources. https://ballotpedia.org/Ricki_Ruiz$$,
        ARRAY['https://ballotpedia.org/Ricki_Ruiz']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Gresham area representative focused on East Metro housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Gresham area Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e5e267a-808e-4a57-9f80-7c3e47fcb5f6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Matt Bunch, HD-51
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Coos Bay area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Supported law enforcement funding and public safety approaches; Coos Bay Republican with documented public safety positions. https://ballotpedia.org/Matt_Bunch$$,
        ARRAY['https://ballotpedia.org/Matt_Bunch']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; Coos Bay coastal fishing and timber economy interests. https://ballotpedia.org/Matt_Bunch$$,
        ARRAY['https://ballotpedia.org/Matt_Bunch']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ce386a55-7cc5-4006-89db-97e06e0e0279', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from Coos Bay area; opposed business and income tax increases. https://ballotpedia.org/Matt_Bunch$$,
        ARRAY['https://ballotpedia.org/Matt_Bunch']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jeff Helfrich, HD-52
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Hood River/Columbia Gorge area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; Hood River area agricultural and outdoor recreation economy. https://ballotpedia.org/Jeff_Helfrich$$,
        ARRAY['https://ballotpedia.org/Jeff_Helfrich']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('701f0236-5ca7-4bfa-ab71-8c22bcc5ff8c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from Hood River/Columbia Gorge area; opposed business and income tax increases. https://ballotpedia.org/Jeff_Helfrich$$,
        ARRAY['https://ballotpedia.org/Jeff_Helfrich']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Emerson Levy, HD-53
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Lake Oswego district. https://ballotpedia.org/Emerson_Levy$$,
        ARRAY['https://ballotpedia.org/Emerson_Levy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Lake Oswego area representative focused on Clackamas County housing access. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and health programs. https://ballotpedia.org/Emerson_Levy$$,
        ARRAY['https://ballotpedia.org/Emerson_Levy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Lake Oswego Democrat with environmental priorities. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f1d2cfe6-5e70-42f3-a010-bb58ec6a5d86', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Lake Oswego area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Jason Kropf, HD-54
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Supported civil rights and anti-discrimination measures; consistent progressive voting record from Bend district. https://ballotpedia.org/Jason_Kropf$$,
        ARRAY['https://ballotpedia.org/Jason_Kropf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Supported housing affordability measures; Bend area representative focused on Central Oregon housing access and affordability crisis. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB2001']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES on HB 2002 (2023) expanding reproductive healthcare access and abortion coverage in Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Supported healthcare access expansion; voted for Medicaid expansion and community health measures. https://ballotpedia.org/Jason_Kropf$$,
        ARRAY['https://ballotpedia.org/Jason_Kropf']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Supported climate action legislation; Bend area Democrat with environmental priorities in Central Oregon. https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2020R1/Measures/Overview/HB2020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbc19752-8675-48ef-87fb-480e3f8bf3f6', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Supported Corporate Activity Tax and tax measures funding public services; Bend area Democrat. https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2019R1/Measures/Overview/HB3427']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- E. Werner Reschke, HD-55
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Klamath Falls area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; Klamath Falls area with agricultural, ranching, and timber economy. https://ballotpedia.org/E._Werner_Reschke$$,
        ARRAY['https://ballotpedia.org/E._Werner_Reschke']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c7c9b46-a054-41a7-8752-f0d8706f754d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from Klamath Falls area; opposed business and income tax increases. https://ballotpedia.org/E._Werner_Reschke$$,
        ARRAY['https://ballotpedia.org/E._Werner_Reschke']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Emily McIntire, HD-56
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Klamath/Lake County. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Klamath/Lake County ranching and agricultural interests. https://ballotpedia.org/Emily_McIntire$$,
        ARRAY['https://ballotpedia.org/Emily_McIntire']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f9b60c1-483c-4a8e-8221-145098204ced', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Klamath/Lake County; opposed business and income tax increases. https://ballotpedia.org/Emily_McIntire$$,
        ARRAY['https://ballotpedia.org/Emily_McIntire']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Gregory Smith, HD-57
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Eastern Oregon (Heppner/Morrow County). https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Eastern Oregon with wheat farming and ranching economy. https://ballotpedia.org/Gregory_Smith$$,
        ARRAY['https://ballotpedia.org/Gregory_Smith']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('81cda574-d820-4ac3-b7fe-0ac3d2638c28', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Eastern Oregon; opposed business and income tax increases. https://ballotpedia.org/Gregory_Smith$$,
        ARRAY['https://ballotpedia.org/Gregory_Smith']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Bobby Levy, HD-58
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Eastern Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Eastern Oregon ranching economy. https://ballotpedia.org/Bobby_Levy$$,
        ARRAY['https://ballotpedia.org/Bobby_Levy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('05152597-fd40-49bb-bcd3-9e21945ae8b0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Eastern Oregon; opposed business and income tax increases. https://ballotpedia.org/Bobby_Levy$$,
        ARRAY['https://ballotpedia.org/Bobby_Levy']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Vikki Breese-Iverson, HD-59
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', '00b95a6a-75db-4521-b523-3326bba938de', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Expressed support for school choice and parental rights in education; Bend-area Republican with documented positions on education policy. https://ballotpedia.org/Vikki_Breese-Iverson$$,
        ARRAY['https://ballotpedia.org/Vikki_Breese-Iverson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from Bend/Central Oregon area. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; Bend/Central Oregon area. https://ballotpedia.org/Vikki_Breese-Iverson$$,
        ARRAY['https://ballotpedia.org/Vikki_Breese-Iverson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7f460988-c9a6-4452-a872-441e7c4ac071', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from Bend/Central OR; opposed business and income tax increases. https://ballotpedia.org/Vikki_Breese-Iverson$$,
        ARRAY['https://ballotpedia.org/Vikki_Breese-Iverson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Mark Owens, HD-60
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted NO on HB 2002 (2023) expanding reproductive healthcare and abortion access; Republican House caucus opposition from rural Eastern Oregon. https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002$$,
        ARRAY['https://olis.oregonlegislature.gov/liz/2023R1/Measures/Overview/HB2002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Participated in 2023 Oregon House Republican walkout blocking quorum on HB 2020 climate legislation; rural Eastern Oregon ranching, agriculture, and natural resource economy. https://ballotpedia.org/Mark_Owens$$,
        ARRAY['https://ballotpedia.org/Mark_Owens']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 5)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca7c06f8-d4cf-4bec-947f-fb39a00e2cb1', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Anti-tax voting record as Republican from rural Eastern Oregon; opposed business and income tax increases. https://ballotpedia.org/Mark_Owens$$,
        ARRAY['https://ballotpedia.org/Mark_Owens']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
