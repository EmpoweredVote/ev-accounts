-- ============================================================================
-- Migration 403: William N. Brownsberger Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for William N. Brownsberger (MA State Senator, 25D28,
--   Suffolk and Middlesex District — Brighton/Allston, Belmont, Watertown).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7 (external_id: -210028)

BEGIN;

-- ----- William N. Brownsberger / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Brownsberger has been the leading Senate voice on criminal justice reform for many years. A former public defender, he chaired the Senate Committee on Criminal Justice for a decade and was the primary author of the 2018 criminal justice reform law (Chapter 69, Acts of 2018) — one of the most comprehensive CJ reforms in MA history. The law reduced mandatory minimum sentences, decriminalized low-level drug offenses, expanded diversion programs, and reformed pretrial detention. He has been a consistent advocate for reducing incarceration, expanding alternatives to prison, and reforming the bail system.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://www.wbur.org/news/2018/04/13/massachusetts-criminal-justice-reform-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / judicial-criminal-justice -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Brownsberger authored the 2018 criminal justice reform law dramatically reducing mandatory minimums and reforming drug offenses. He has been an outspoken critic of mass incarceration and has advocated for rehabilitation-centered approaches in the criminal justice system. He has backed expanded drug court and diversion programs and has opposed harsh mandatory minimum sentences for non-violent drug offenders. His career-defining work on CJ reform reflects a strong commitment to reducing the criminal justice system footprint on non-violent offenders.$$,
        ARRAY['https://malegislature.gov/Bills/190/S2185', 'https://www.wbur.org/news/2018/04/13/massachusetts-criminal-justice-reform-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / judicial-bail-pretrial -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
        $$The 2018 CJ reform law that Brownsberger authored included significant pretrial detention reforms, reducing the use of cash bail for non-violent defendants and reforming the dangerousness hearing process. He has been a consistent advocate for eliminating cash bail as a condition of pretrial release, arguing it unfairly penalizes poverty. He has supported risk-based pretrial decision-making and backed legislation further reforming the bail system.$$,
        ARRAY['https://malegislature.gov/Bills/190/S2185', 'https://www.wbur.org/news/2018/04/13/massachusetts-criminal-justice-reform-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Brownsberger supported the 2024 Affordable Homes Act and has backed affordable housing production in his district, which includes Brighton, Allston, Belmont, and Watertown — all areas facing housing cost pressure. He has supported MBTA Communities zoning compliance and by-right permitting reforms to increase housing supply. He has also been attentive to neighborhood concerns about development scale and quality, taking a somewhat more measured approach than the most aggressive housing advocates.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Brownsberger voted for the 2021 Climate Act and has supported clean energy legislation. His approach has been supportive of climate action while also weighing ratepayer costs and grid reliability. He has backed offshore wind and solar development and has supported building electrification programs. He blogs extensively about policy and his writing has included nuanced analysis of energy transition tradeoffs, reflecting support for strong climate policy with attention to economic impacts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Brownsberger has been a strong transit advocate, championing Green Line service improvements for his Brighton/Allston constituents and backed the 2022 MBTA reform legislation. He has supported increased MBTA capital funding and has been critical of the agency when service has fallen short. He has backed bike infrastructure investments in his district and supported pedestrian safety improvements. He consistently prioritizes public transit and active transportation over highway expansion.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://www.wbur.org/news/2022/06/10/mbta-reform-legislation-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Brownsberger voted for the 2022 Work and Family Mobility Act. His district includes Brighton/Allston, which has significant immigrant communities. He has supported in-state tuition for undocumented students and backed sanctuary policies. His immigration positions are consistently pro-immigrant, though his primary policy focus has been on criminal justice and transportation rather than immigration specifically.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.masslive.com/politics/2022/06/massachusetts-senate-passes-drivers-licenses-for-undocumented-immigrants.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- William N. Brownsberger / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Brownsberger supported the 2022 millionaires surtax (Question 1) and the 2023 tax relief package. He has written extensively on his blog about fiscal policy and has taken a somewhat more fiscally cautious position than some Democratic colleagues, emphasizing the importance of sustainable revenue. He has supported the Child and Family Tax Credit and progressive tax measures but has also been attentive to overall tax competitiveness. His record is center-left on taxation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/WNB0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
