-- ============================================================================
-- Migration 419: Hadley Luddy Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Hadley Luddy
--   (MA State Representative, 4th Barnstable District, HD-04, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 03e35156-c179-4dd5-9c8c-8d418976914e (external_id: -210044)

BEGIN;

-- ----- Hadley Luddy / housing -----
-- Evidence: Extensive housing legislation including H.4410/H.4411 (housing in seasonal
--   communities), H.4288-H.4291 (housing trust funds in Chatham), H.4311 (year-round
--   rental housing trust Provincetown), H.4318 (attainable housing Harwich),
--   H.4576-H.4577 (real estate transfer fees).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Luddy has sponsored an extensive slate of housing legislation reflecting the acute housing crisis in her 4th Barnstable District on Cape Cod. She filed H.4410 and H.4411 (housing production in seasonal communities), H.4288 through H.4291 (housing trust funds for Chatham), H.4311 (year-round rental housing trust for Provincetown), H.4318 (attainable housing in Harwich), and H.4576 to H.4577 (real estate transfer fees for affordable housing). This breadth of housing legislation reflects a strong pro-housing access stance focused on year-round affordability in a vacation-dominated real estate market.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Legislators/Profile/H_L1/Bills/Sponsored/194']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hadley Luddy / civil-rights -----
-- Evidence: Sponsored H.776 (racial/ethnic/sexual orientation protections for seniors),
--   H.3433 (Commission on the Status of Women).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Luddy sponsored H.776 (An Act regarding racial and ethnic status protections for seniors), which adds protections for seniors based on race, ethnicity, sexual orientation, gender identity, and HIV status. She also sponsored H.3433 (Commission on the Status of Women). These bills reflect active engagement with expanding civil rights protections across multiple dimensions including racial justice, LGBTQ+ rights, and gender equity. Her legislative record shows a pro-civil-rights stance from her first term.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Bills/194/H776']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hadley Luddy / climate-change -----
-- Evidence: Sponsored H.2904 (fossil fuel divestment for independent retirement systems),
--   H.2488 (dry cask spent nuclear fuel monitoring), H.2661 (nuclear power plant community health standards).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Luddy sponsored H.2904 (An Act relative to fossil fuel divestment for independent retirement systems), H.2488 (dry cask spent nuclear fuel monitoring), and H.2661 (public health standards for nuclear power plant communities). This cluster of legislation reflects a strong climate action stance: divesting public retirement funds from fossil fuels and applying rigorous oversight to nuclear facilities as part of the clean energy transition. Her Cape Cod district's vulnerability to sea level rise and coastal erosion gives her strong constituent motivation to support aggressive climate action.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Bills/194/H2904']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Hadley Luddy / fossil-fuels -----
-- Evidence: Sponsored H.2904 (fossil fuel divestment from retirement systems).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('03e35156-c179-4dd5-9c8c-8d418976914e',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Luddy sponsored H.2904 (An Act relative to fossil fuel divestment for independent retirement systems), directly requiring public retirement systems to divest from fossil fuel companies. This is strong direct evidence of her opposition to fossil fuel investment and support for phasing out fossil fuels from the economy. Her additional sponsorship of nuclear safety monitoring bills (H.2488, H.2661) reflects a comprehensive clean energy transition approach rather than simply opposing one energy type.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/H_L1', 'https://malegislature.gov/Bills/194/H2904']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '03e35156-c179-4dd5-9c8c-8d418976914e'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
