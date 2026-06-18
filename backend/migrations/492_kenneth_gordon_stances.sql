-- ============================================================================
-- Migration 492: Kenneth I. Gordon Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kenneth I. Gordon (MA House HD-77,
--   21st Middlesex District). External ID: -210117.
--   Gordon is Chair of the Joint Committee on Public Service.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 0 rows in DB — all stances inserted fresh.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Kenneth I. Gordon (HD-77, external_id=-210117)
-- Politician UUID: afb64fe5-b2a7-4c47-b113-5200ed26182a

-- ----- Kenneth I. Gordon / abortion -----
-- ROE Act co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Gordon co-sponsored the ROE Act, which codifies Roe v. Wade protections into Massachusetts law and expands abortion access beyond what federal law required. Co-sponsorship of this landmark abortion rights bill reflects a strong pro-abortion-access position.$$,
        ARRAY['https://actonmass.org/legislators/kenneth-gordon/', 'https://actonmass.org/bills/abortion-protection/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / childcare -----
-- THRIVE Act co-sponsorship + Public Service Committee
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Gordon co-sponsored the THRIVE Act (H.495 / S.246), which addresses high-stakes testing and educational access for children. He also chairs the Joint Committee on Public Service, which oversees public employee benefits including family leave policies. These roles reflect support for publicly-funded childcare and family services.$$,
        ARRAY['https://actonmass.org/bills/moratorium-on-high-stakes-testing/', 'https://malegislature.gov/Legislators/Profile/KIG1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / civil-rights -----
-- CARE Act, Healthy Youth Act, Indigenous Peoples Day, Support Native Students
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Gordon co-sponsored four civil rights bills: the CARE Act (H.542 / S.288) for racially inclusive education, the Healthy Youth Act (H.544 / S.268) for LGBTQ+-inclusive sex education, Indigenous Peoples Day (H.2989 / S.1976), and Support Native Students (H.536 / S.318). This breadth of co-sponsorships reflects strong support for civil rights protections across racial, LGBTQ+, and indigenous communities.$$,
        ARRAY['https://actonmass.org/bills/commission-for-anti-racism-and-equity-in-education/', 'https://actonmass.org/bills/healthy-youth-act/', 'https://actonmass.org/bills/indigenous-peoples-day/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / climate-change -----
-- 100% Renewable Energy by 2045 co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Gordon co-sponsored the 100% Renewable Energy by 2045 bill (H.3689), which would mandate Massachusetts transition to 100% clean renewable energy by 2045. He also co-sponsored the Environmental Justice bill (H.1677 / S.953). These co-sponsorships reflect strong support for ambitious climate action.$$,
        ARRAY['https://actonmass.org/bills/100-renewable-energy-by-2045/', 'https://actonmass.org/bills/environmental-justice/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / economic-development -----
-- Stop Wage Theft + Right to Strike + Rideshare Union co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Gordon co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Right to Strike bill (H.1845 / S.1217), and the Right to Unionize for Ride Share Drivers bill (H.1099). As Chair of the Joint Committee on Public Service, he oversees public employee labor protections. These roles reflect consistent support for worker rights and labor organizing.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/the-right-to-strike/', 'https://actonmass.org/bills/right-to-unionize-for-ride-share-drivers/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / healthcare -----
-- Overdose Prevention + THRIVE Act co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gordon co-sponsored the Overdose Prevention Centers bill (H.1981 / S.1242), which would authorize supervised consumption sites to reduce opioid overdose deaths, and the THRIVE Act (H.495) addressing student health and wellbeing. These co-sponsorships reflect a public health approach to healthcare and harm reduction.$$,
        ARRAY['https://actonmass.org/bills/overdose-prevention-centers/', 'https://actonmass.org/bills/moratorium-on-high-stakes-testing/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / immigration -----
-- Work & Family Mobility Act (driver's licenses regardless of immigration status)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Gordon co-sponsored the Work and Family Mobility Act (H.3456 / S.2289), which provides driver's licenses to all Massachusetts residents regardless of immigration status. This co-sponsorship reflects support for immigrant inclusion and access to basic services.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / judicial-criminal-justice -----
-- Overdose Prevention + Age of Criminal Majority to 21 + Life Without Parole
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Gordon co-sponsored the Overdose Prevention Centers bill (harm reduction approach to drug offenses), the Age of Criminal Majority to 21 bill (H.1710 / S.942) which would raise the adult criminal prosecution age, and the Life Without Parole reform bill (H.2398 / S.1544). These three co-sponsorships reflect a reform-oriented, rehabilitative approach to criminal justice.$$,
        ARRAY['https://actonmass.org/bills/overdose-prevention-centers/', 'https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://actonmass.org/bills/life-without-parole/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / local-environment -----
-- Environmental Justice co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Gordon co-sponsored the Environmental Justice bill (H.1677 / S.953), which would require state agencies to address environmental burdens in low-income and minority communities. This co-sponsorship reflects support for local environmental protections, particularly for vulnerable communities disproportionately impacted by pollution.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://actonmass.org/legislators/kenneth-gordon/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / local-immigration -----
-- Work & Family Mobility Act provides strong evidence for local-immigration as well
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Gordon co-sponsored the Work and Family Mobility Act (H.3456 / S.2289), which grants driver's licenses regardless of immigration status and directly improves access to transportation and services for undocumented residents in local communities. This bill reflects a position of support for integrating immigrant communities into local civic life.$$,
        ARRAY['https://actonmass.org/bills/driver-license-regardless-immigration-status/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth I. Gordon / voting-rights -----
-- Same-day voter registration co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('afb64fe5-b2a7-4c47-b113-5200ed26182a',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Gordon co-sponsored same-day voter registration legislation, which would allow eligible voters to register and vote on Election Day in Massachusetts. This co-sponsorship reflects support for expanding ballot access and democratic participation.$$,
        ARRAY['https://actonmass.org/legislators/kenneth-gordon/', 'https://malegislature.gov/Legislators/Profile/KIG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 11):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'afb64fe5-b2a7-4c47-b113-5200ed26182a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'afb64fe5-b2a7-4c47-b113-5200ed26182a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'afb64fe5-b2a7-4c47-b113-5200ed26182a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
