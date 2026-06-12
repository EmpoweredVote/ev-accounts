-- ============================================================================
-- Migration 468: Bud L. Williams Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Bud L. Williams (MA State Rep, 11th Hampden District, HD-53).
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
-- Bud L. Williams (HD-53, external_id=-210093)
-- UUID: aee5ccea-d3ca-426c-9849-fbfc5e297e2a
-- District: 11th Hampden (Springfield area)
-- Democrat; committee: Racial Equity, Civil Rights, and Inclusion.
-- ============================================================================

-- ----- Bud L. Williams / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Williams serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion — directly shaping civil rights legislation. He sponsored H.2732, "An Act relative to missing Black women and girls in Massachusetts," and H.1416-1417, "An Act to advance health equity," and H.1418 funding the African Diaspora Mental Health Association. These bills reflect a deep commitment to racial justice and equity as civil rights principles.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BLW1/Committees', 'https://malegislature.gov/Bills/194/H2732', 'https://malegislature.gov/Bills/194/H1416']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bud L. Williams / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Williams sponsored H.1346-1347, "An Act to improve sickle cell care," expanding treatment and screening for sickle cell disease; H.476, "An Act relative to medical debt exclusion from creditor reports," protecting patients from medical debt ruining their credit; and H.1416-1417, "An Act to advance health equity," targeting systemic disparities in healthcare access and outcomes. These bills reflect a comprehensive pro-equity healthcare access agenda.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1346', 'https://malegislature.gov/Bills/194/H476', 'https://malegislature.gov/Bills/194/H1416']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bud L. Williams / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Williams sponsored H.2047, "An Act eliminating mandatory minimum sentences related to drug offenses," which removes mandatory minimums that disproportionately impact communities of color; H.2048, "An Act decriminalizing non-violent and verbal student misconduct," ending school-to-prison pipeline practices; H.2049, expunging past marijuana convictions; and H.2050, removing barriers to expungement of records. These four bills together represent a strong reform-focused public safety stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2047', 'https://malegislature.gov/Bills/194/H2048', 'https://malegislature.gov/Bills/194/H2050']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bud L. Williams / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Williams sponsored H.1575, "An Act relative to reducing damage caused by the current foreclosure crisis in the historic districts of Massachusetts," which protects homeowners in historically significant communities from predatory foreclosures. This bill targets housing stability for long-term residents in communities of color facing gentrification and displacement pressures.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1575']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bud L. Williams / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aee5ccea-d3ca-426c-9849-fbfc5e297e2a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Williams sponsored H.315, "An Act empowering disadvantaged state contractors," providing front payments and bridge loans to socially and economically disadvantaged microbusinesses that win state contracts; H.1348, a loan loss guarantee program for CDFIs; and H.1349, expanding banking access for underserved microbusinesses. These bills reflect a strong equity-in-economic-development stance targeting minority-owned and disadvantaged small businesses.$$,
        ARRAY['https://malegislature.gov/Bills/194/H315', 'https://malegislature.gov/Bills/194/H1349', 'https://malegislature.gov/Bills/194/H1348']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'aee5ccea-d3ca-426c-9849-fbfc5e297e2a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'aee5ccea-d3ca-426c-9849-fbfc5e297e2a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'aee5ccea-d3ca-426c-9849-fbfc5e297e2a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
