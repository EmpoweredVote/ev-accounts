-- ============================================================================
-- Migration 469: Angelo J. Puppolo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Angelo J. Puppolo (MA State Rep, 12th Hampden District, HD-54).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Angelo J. Puppolo (HD-54, external_id=-210094)
-- UUID: 9b3772d3-3602-457a-82e7-479b5e557b13
-- District: 12th Hampden (Springfield area)
-- Democrat; committee: House Committee on Intergovernmental Affairs.
-- ============================================================================

-- ----- Angelo J. Puppolo / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Puppolo co-sponsored H.1080, "An Act relative to copay assistance for certain branded drugs," reducing patient out-of-pocket costs; sponsored H.1290, "An Act relative to dental insurance coverage of periodontal treatments," expanding dental insurance; H.1291, "An Act further clarifying the delivery of health care"; and H.2404, "An Act relative to increased availability of opioid antagonist medication," expanding naloxone access to combat the opioid crisis. These bills collectively represent a comprehensive pro-access healthcare agenda.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1080', 'https://malegislature.gov/Bills/194/H1290', 'https://malegislature.gov/Bills/194/H2404']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angelo J. Puppolo / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Puppolo sponsored H.1820, "An Act providing increased protections from harassment and discrimination on the basis of height," expanding the protected class categories under Massachusetts anti-discrimination law. This extension of civil rights protections to height reflects a pattern of broadening anti-discrimination coverage.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1820']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angelo J. Puppolo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Puppolo sponsored H.305, "An Act improving housing opportunities," which targets expansion of housing availability and affordability. This bill reflects a pro-expansion approach to housing policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H305']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angelo J. Puppolo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Puppolo sponsored H.3406, "An Act relative to responsibly reducing emissions in the transportation sector," targeting transportation-sector decarbonization, and H.3545, "An Act relative to energy conservation," promoting energy efficiency across the state. Both bills directly address climate change mitigation through emissions reduction and efficiency.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3406', 'https://malegislature.gov/Bills/194/H3545']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Angelo J. Puppolo / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3772d3-3602-457a-82e7-479b5e557b13',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Puppolo co-sponsored H.1937, "An Act relative to the Commonwealth's right to appeal bail decisions," which gives prosecutors expanded ability to appeal bail determinations — a law-enforcement-friendly measure on pretrial detention. Simultaneously, he sponsored H.2404 expanding naloxone access (treatment approach to opioid crisis). The evidence reflects a centrist position: supporting both enforcement tools and treatment-based approaches to public safety.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1937', 'https://malegislature.gov/Bills/194/H2404']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9b3772d3-3602-457a-82e7-479b5e557b13';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9b3772d3-3602-457a-82e7-479b5e557b13'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9b3772d3-3602-457a-82e7-479b5e557b13'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
