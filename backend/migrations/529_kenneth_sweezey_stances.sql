-- ============================================================================
-- Migration 529: Kenneth P. Sweezey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kenneth P. Sweezey (MA State Rep,
--          6th Plymouth District, HD-114, external_id=-210154).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Kenneth P. Sweezey (HD-114, external_id=-210154, id=8512ef88-a285-4c6f-89d3-41fb4f8cfd48) --

-- ----- Kenneth P. Sweezey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sweezey sponsored a comprehensive set of pro-gun-rights bills: H.2610 (lawful right to carry), H.2708 (gun registration changes), H.2711 (semiautomatic rifles/shotguns — opposing restrictions), H.2712 (pre-ban magazines — opposing confiscation), and H.2713 (challenging the 2024 firearms law). He has been one of the most active Republican sponsors of legislation rolling back Massachusetts firearms restrictions, reflecting a strong pro-Second Amendment position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2610', 'https://malegislature.gov/Bills/194/H2711', 'https://malegislature.gov/Bills/194/H2713']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth P. Sweezey / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Sweezey sponsored H.2338 (MBTA community exemptions), H.2339 (MBTA community guidelines revisions), and H.2340 ("An Act repealing section 3A relative to MBTA communities"), which would entirely eliminate the state's requirement that municipalities near transit allow multifamily housing by right. This cluster of bills reflects strong opposition to state zoning mandates and a defense of local zoning autonomy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2340', 'https://malegislature.gov/Bills/194/H2338', 'https://malegislature.gov/Bills/194/H2339']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kenneth P. Sweezey / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8512ef88-a285-4c6f-89d3-41fb4f8cfd48',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sweezey sponsored H.3573 ("An Act relative to containers, litter, ecology and nips" — CLEAN Act targeting single-use nip bottles that litter MA coastlines) and H.5139-H.5141 (beach recreation management and piping plover habitat protection). His environmental bills focus on coastal conservation and litter reduction, consistent with a South Shore district's coastal identity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3573', 'https://malegislature.gov/Bills/194/H5139', 'https://malegislature.gov/Bills/194/H5141']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8512ef88-a285-4c6f-89d3-41fb4f8cfd48';
-- unpaired=0; uncited=0
