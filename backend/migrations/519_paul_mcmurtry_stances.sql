-- ============================================================================
-- Migration 519: Paul McMurtry Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul McMurtry (MA State Rep,
--          11th Norfolk District, HD-104, external_id=-210144).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Paul McMurtry (HD-104, external_id=-210144, id=5020a35d-1f0c-44f7-b533-4e5e457238b5) --

-- ----- Paul McMurtry / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$McMurtry sponsored a cluster of healthcare access bills: H.1257 (coverage for genetic craniofacial conditions), H.1258 (oral/dental care for head and neck cancer survivors), H.1261 (protecting patients from surprise ambulance bills), H.1262 (dental insurance), H.1390 (MassHealth managed care pharmacy rates), H.2224 (improving mental health care). He has been a persistent advocate for expanding healthcare coverage mandates and protecting patients from unexpected costs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1258', 'https://malegislature.gov/Bills/194/H1261', 'https://malegislature.gov/Bills/194/H1390']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul McMurtry / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McMurtry sponsored H.1883 ("An Act to promote housing stability") and H.1551 ("An Act relative to the Affordable Homes Act"), demonstrating commitment to both tenant stability protections and the broader statewide affordable housing agenda. His bills reflect a government-active approach to addressing the Massachusetts housing crisis.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1883', 'https://malegislature.gov/Bills/194/H1551']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul McMurtry / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$McMurtry sponsored H.2312 ("An Act regarding municipal zoning powers"), which addresses the balance between state housing mandates and local zoning control. His sponsorship of housing stability (H.1883) alongside municipal zoning powers indicates he supports local government having a significant role in zoning decisions while still addressing housing need.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2312', 'https://malegislature.gov/Bills/194/H1550']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul McMurtry / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5020a35d-1f0c-44f7-b533-4e5e457238b5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$McMurtry sponsored H.2667 (POST Commission — police oversight and standards) and H.2668 (confidentiality protections for emergency service providers). His public safety record shows support for both accountability mechanisms for law enforcement (POST Commission) and protections for first responders, reflecting a balanced reform-without-defunding approach common among moderate Democrats.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2667', 'https://malegislature.gov/Bills/194/H2668']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5020a35d-1f0c-44f7-b533-4e5e457238b5';
-- unpaired=0; uncited=0
