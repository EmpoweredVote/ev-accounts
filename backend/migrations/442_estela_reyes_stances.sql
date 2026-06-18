-- ============================================================================
-- Migration 442: Estela A. Reyes Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Estela A. Reyes (MA State Rep, HD-27,
--   4th Essex District, Lawrence).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 8e125ae2-3101-49b1-b228-f172ad9c70d9 (external_id=-210067)

BEGIN;

-- ----- Estela A. Reyes / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Reyes co-sponsored the Abortion Access Act as tracked by Act on Mass, a bill that would further expand and protect abortion access in Massachusetts. This direct co-sponsorship of the primary abortion access expansion bill reflects a strong pro-reproductive-rights stance.$$,
        ARRAY['https://actonmass.org/legislators/estela-reyes/', 'https://malegislature.gov/Legislators/Profile/EAR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Estela A. Reyes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Reyes co-sponsored Medicare for All and Overdose Prevention Centers bills as tracked by Act on Mass, and sponsored H.680 to provide mental health counselors in public schools and H.681 on school wellness programs. She also co-sponsored the Cherish Act for fully funded higher education and the THRIVE Act for expanded social services. Her record reflects strong support for universal healthcare coverage and mental health services.$$,
        ARRAY['https://actonmass.org/legislators/estela-reyes/', 'https://malegislature.gov/Bills/194/H680', 'https://malegislature.gov/Bills/194/H681']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Estela A. Reyes / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Reyes co-sponsored Progressive Revenue legislation as tracked by Act on Mass, which supports raising taxes on high-income earners and corporations to fund public services. She also sponsored H.3550 relative to a cap on gas delivery fees by gas companies — a consumer protection measure that constrains utility company pricing.$$,
        ARRAY['https://actonmass.org/legislators/estela-reyes/', 'https://malegislature.gov/Bills/194/H3550']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Estela A. Reyes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Reyes co-sponsored Ban Native American Mascots legislation and Indigenous Peoples Day recognition (Act on Mass), reflecting support for Indigenous rights and representation. She also co-sponsored the Age of Criminal Majority to 21 and Life without Parole reform bills, reflecting support for criminal justice reform that disproportionately affects communities of color. These bills reflect a consistent civil rights priority.$$,
        ARRAY['https://actonmass.org/legislators/estela-reyes/', 'https://malegislature.gov/Legislators/Profile/EAR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Estela A. Reyes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8e125ae2-3101-49b1-b228-f172ad9c70d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Reyes co-sponsored Right to Strike and State House Union legislation as tracked by Act on Mass, reflecting strong support for organized labor and worker rights. She also co-sponsored Stop Wage Theft via her other AOM bill co-sponsorships. Representing Lawrence — one of Massachusetts's most economically challenged gateway cities — her economic development focus centers on labor rights and worker protections.$$,
        ARRAY['https://actonmass.org/legislators/estela-reyes/', 'https://malegislature.gov/Legislators/Profile/EAR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8e125ae2-3101-49b1-b228-f172ad9c70d9';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8e125ae2-3101-49b1-b228-f172ad9c70d9'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8e125ae2-3101-49b1-b228-f172ad9c70d9'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
