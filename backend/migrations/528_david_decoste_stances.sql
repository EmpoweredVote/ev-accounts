-- ============================================================================
-- Migration 528: David F. DeCoste Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David F. DeCoste (MA State Rep,
--          5th Plymouth District, HD-113, external_id=-210153).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- David F. DeCoste (HD-113, external_id=-210153, id=a743a9a0-711c-40cf-b6e2-0ce2b587949a) --

-- ----- David F. DeCoste / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$DeCoste sponsored H.1661 ("An Act to protect victims of rape and children conceived during the commission of said offense"), H.1662 (relative to coerced abortion), H.1663 (relative to unborn victims of violence), and H.217 ("An Act relative to ensuring resources and support for pregnant and parenting families"). These four bills collectively reflect a strong pro-life position — protecting unborn life, limiting coerced abortion, and supporting pregnant women as an alternative to abortion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1661', 'https://malegislature.gov/Bills/194/H1662', 'https://malegislature.gov/Bills/194/H1663']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David F. DeCoste / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$DeCoste sponsored a cluster of housing bills: H.1489 (tenant escrow accounts), H.1490 (landlord's right to information), H.1492 (expanding affordable housing definition to include manufactured homes), H.1493 (allowing tiny houses as permanent dwellings), and H.1494 (improving access to rental assistance). His approach reflects a Republican preference for expanding housing supply through market and small-scale alternatives rather than rent control.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1492', 'https://malegislature.gov/Bills/194/H1493', 'https://malegislature.gov/Bills/194/H1494']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David F. DeCoste / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a743a9a0-711c-40cf-b6e2-0ce2b587949a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$DeCoste sponsored H.1666 ("An Act relative to capital punishment for the murder of law enforcement officers"), reinstating the death penalty for police killings, and H.2595 (use of force equipment — supporting law enforcement equipment access). These bills reflect a strong law enforcement support and tough-on-crime stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1666', 'https://malegislature.gov/Bills/194/H2595']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a743a9a0-711c-40cf-b6e2-0ce2b587949a';
-- unpaired=0; uncited=0
