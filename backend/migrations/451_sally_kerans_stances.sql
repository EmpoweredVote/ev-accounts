-- ============================================================================
-- Migration 451: Sally P. Kerans Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Sally P. Kerans (MA State Rep, HD-36,
--   13th Essex District, Danvers/Middleton).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: de40220c-2935-42a2-ac90-d662bb47d49b (external_id=-210076)

BEGIN;

-- ----- Sally P. Kerans / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Kerans co-sponsored the Abortion Access Act as tracked by Act on Mass (green checkmark on AOM profile), and she sponsored her own bill H.1815 to enhance access to abortion in Massachusetts. Sponsoring a direct abortion access bill in addition to co-sponsoring the broader coalition bill signals a strong and active commitment to reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/sally-kerans/', 'https://malegislature.gov/Bills/194/H1815']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally P. Kerans / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Kerans co-sponsored LGBTQ+ Rights and Indigenous Peoples' Rights legislation as tracked by Act on Mass (green checkmarks). She also sponsored H.2466 relative to supporting survivors through financial assistance (supporting domestic violence/sexual assault survivors). These co-sponsorships reflect a broad civil rights commitment across gender identity, LGBTQ+ rights, and Indigenous rights.$$,
        ARRAY['https://actonmass.org/legislators/sally-kerans/', 'https://malegislature.gov/Bills/194/H2466']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally P. Kerans / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kerans serves on the Joint Committee on Public Health and sponsored a cluster of healthcare access bills: H.1222 (prescription medication re-authorization), H.1223 (scalp/facial hair prostheses for children and adults with medical conditions), H.1224 (insurance coverage for biennial echocardiograms), H.2217 (opioid reversal drugs), and H.2463 (proper classification of healthcare workers). This comprehensive healthcare bill portfolio reflects a strong pro-access stance across pharmaceutical coverage, specialty care, and worker protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1222', 'https://malegislature.gov/Bills/194/H1223', 'https://malegislature.gov/Bills/194/H1224', 'https://malegislature.gov/Bills/194/H2217', 'https://malegislature.gov/Legislators/Profile/SPK1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally P. Kerans / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kerans sponsored H.1814 to create an office of the tenant advocate within the Attorney General's office — a dedicated pro-tenant enforcement body. She also sponsored H.1225 requiring sufficient notice to homeowners before insurance cancellation, reflecting both renter and homeowner housing stability concerns. An office of tenant advocate bill is a strong pro-renter position for Massachusetts housing policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1814', 'https://malegislature.gov/Bills/194/H1225']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sally P. Kerans / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('de40220c-2935-42a2-ac90-d662bb47d49b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Kerans sponsored H.3513 to ensure notice to abutter communities of applications to the Department of Public Utilities — giving neighboring communities a voice in environmental and utility infrastructure decisions. She also sponsored H.3713 relative to noise report data and good neighbor policy at Beverly Regional Airport, reflecting local environmental quality concerns for her North Shore district. These bills reflect community-level environmental advocacy and procedural environmental justice.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3513', 'https://malegislature.gov/Bills/194/H3713', 'https://malegislature.gov/Legislators/Profile/SPK1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'de40220c-2935-42a2-ac90-d662bb47d49b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'de40220c-2935-42a2-ac90-d662bb47d49b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'de40220c-2935-42a2-ac90-d662bb47d49b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
