-- ============================================================================
-- Migration 423: Tricia Farley-Bouvier Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tricia Farley-Bouvier
--   (MA State Representative, 2nd Berkshire District, HD-08, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 15c27efb-0402-4a3a-bfad-9df152874046 (external_id: -210048)

BEGIN;

-- ----- Tricia Farley-Bouvier / climate-change -----
-- Evidence: Co-sponsored 100% Renewable Energy by 2045 and Environmental Justice bills (AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Farley-Bouvier co-sponsored the 100% Renewable Energy by 2045 bill and the Environmental Justice bill, both tracked by Act on Mass as key progressive climate legislation. These co-sponsorships reflect strong support for an aggressive clean energy transition timeline and equitable application of environmental protections. Her Pittsfield/Berkshire district has a legacy of industrial contamination (General Electric PCB contamination) that makes environmental justice particularly salient for her constituents.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tricia Farley-Bouvier / healthcare -----
-- Evidence: Co-sponsored Medicare for All and Overdose Prevention Centers (AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Farley-Bouvier co-sponsored both Medicare for All and Overdose Prevention Centers legislation, tracked by Act on Mass. Medicare for All co-sponsorship reflects support for single-payer universal healthcare. Overdose Prevention Centers co-sponsorship reflects support for harm reduction approaches to the opioid crisis -- a significant issue in Berkshire County, one of the hardest-hit regions in Massachusetts. These co-sponsorships indicate a strong healthcare access expansion stance.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tricia Farley-Bouvier / ai-regulation -----
-- Evidence: Chair of Joint Committee on Advanced Information Technology, Internet and Cybersecurity.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Farley-Bouvier chairs the Joint Committee on Advanced Information Technology, the Internet and Cybersecurity -- the legislature's key committee for AI and technology regulation. As chair, she sets the agenda for AI governance, data privacy, and cybersecurity legislation in Massachusetts. This leadership position places her at the center of AI regulation debates and reflects a commitment to active oversight of technology companies. Her position generally favors consumer protection, privacy rights, and safety guardrails for AI systems.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Committees/Joint/J1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tricia Farley-Bouvier / fossil-fuels -----
-- Evidence: Co-sponsored 100% Renewable Energy by 2045 (AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Farley-Bouvier co-sponsored the 100% Renewable Energy by 2045 bill, which would mandate phasing out all fossil fuel electricity generation by 2045. This co-sponsorship is direct evidence of support for aggressive fossil fuel phase-out. Her district's GE PCB contamination legacy gives her particularly strong environmental motivation to support transitioning away from polluting industries. The 100% renewable target requires eliminating fossil fuels from power generation on an aggressive timeline.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tricia Farley-Bouvier / civil-rights -----
-- Evidence: Co-sponsored Healthy Youth Act (LGBTQ+ comprehensive sex ed) (AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Farley-Bouvier co-sponsored the Healthy Youth Act, which mandates inclusive, LGBTQ+-affirming comprehensive sex education in Massachusetts public schools. She also co-sponsored the Indigenous Peoples Day and Support Native Students bills, reflecting broad civil rights advocacy. Her co-sponsorship of multiple civil rights measures across LGBTQ+ rights, indigenous rights, and environmental justice indicates a consistent civil rights expansion stance.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tricia Farley-Bouvier / campaign-finance -----
-- Evidence: Co-sponsored Sunlight Act and Campaign Childcare (AOM).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('15c27efb-0402-4a3a-bfad-9df152874046',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Farley-Bouvier co-sponsored the Sunlight Act (campaign finance disclosure) and the Open Meeting Law and Public Records Law reform bills, indicating a commitment to government transparency. These co-sponsorships reflect support for stronger campaign finance disclosure requirements and reduced dark money in politics. Her overall legislative pattern shows preference for transparency and accountability in political financing.$$,
        ARRAY['https://actonmass.org/legislators/tricia-farley-bouvier/', 'https://malegislature.gov/Legislators/Profile/TFB1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '15c27efb-0402-4a3a-bfad-9df152874046';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '15c27efb-0402-4a3a-bfad-9df152874046'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '15c27efb-0402-4a3a-bfad-9df152874046'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
