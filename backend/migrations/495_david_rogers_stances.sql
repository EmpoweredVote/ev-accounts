-- ============================================================================
-- Migration 495: David M. Rogers Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David M. Rogers (MA House HD-80,
--   24th Middlesex District). External ID: -210120.
--   Rogers is a Democrat and prolific filer of technology/privacy/voting bills.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 13 rows in DB; abortion=3.0, healthcare=3.0, housing=3.0,
--   medicare/aid=3.0, taxes=3.0, voting-rights=3.0 are neutral defaults.
--   This migration corrects those with positive evidence and adds new topics.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- David M. Rogers (HD-80, external_id=-210120)
-- Politician UUID: ffb8e526-7ad7-4911-92c5-d69528a0f280

-- ----- David M. Rogers / abortion -----
-- Correcting pre-existing 3.0: ROE Act co-sponsorship is clear evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rogers co-sponsored the ROE Act, which codifies and expands abortion rights in Massachusetts beyond what federal law required. Co-sponsorship of this landmark abortion rights bill reflects a strong pro-abortion-access position.$$,
        ARRAY['https://actonmass.org/legislators/david-rogers/', 'https://actonmass.org/bills/abortion-protection/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David M. Rogers / data-centers -----
-- New topic: H.96 (biometric AI), H.97 (AI consumer protection), H.98 (children's internet privacy), H.104 (MA Data Privacy Act)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Rogers filed H.96 (accountability in biometric recognition technology and AI), H.97 (consumer protections in AI systems), H.98 (internet privacy rights for children), and H.104 (Massachusetts Data Privacy Act). This cluster of four technology regulation bills reflects strong support for oversight and consumer protection in AI, data centers, and internet services — a protective stance on emerging technology.$$,
        ARRAY['https://malegislature.gov/Bills/194/H96', 'https://malegislature.gov/Bills/194/H97', 'https://malegislature.gov/Bills/194/H98', 'https://malegislature.gov/Bills/194/H104'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David M. Rogers / economic-development -----
-- New topic: Stop Wage Theft + Fair Scheduling co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Rogers co-sponsored the Stop Wage Theft bill (H.1868 / S.1158) and the Fair Scheduling bill (H.1974 / S.1236). These co-sponsorships reflect support for worker-protective economic policies, including protecting workers from wage theft and ensuring predictable work schedules.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/fair-scheduling/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David M. Rogers / judicial-criminal-justice -----
-- New topic: Age of Criminal Majority to 21 + Overdose Prevention + Prison Moratorium
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Rogers co-sponsored the Age of Criminal Majority to 21 bill (H.1710 / S.942), Overdose Prevention Centers (H.1981 / S.1242), and the Prison Moratorium bill (H.1795 / S.1979). These three co-sponsorships reflect a reform-oriented, rehabilitative approach to criminal justice that prioritizes treatment and reduced incarceration over punishment.$$,
        ARRAY['https://actonmass.org/bills/age-of-criminal-majority-to-21/', 'https://actonmass.org/bills/overdose-prevention-centers/', 'https://actonmass.org/bills/prison-moratorium/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David M. Rogers / local-environment -----
-- New topic: Environmental Justice co-sponsorship + H.457 (greenwashing in recycling)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Rogers co-sponsored the Environmental Justice bill (H.1677 / S.953) and filed H.457 to address greenwashing in recycling labeling. These actions reflect support for local environmental quality and accountability in environmental claims by businesses.$$,
        ARRAY['https://actonmass.org/bills/environmental-justice/', 'https://malegislature.gov/Bills/194/H457'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David M. Rogers / voting-rights -----
-- Correcting pre-existing 3.0: H.865 (voter qualification), H.866 (extend voting rights to noncitizens),
-- same-day voter registration co-sponsorship
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ffb8e526-7ad7-4911-92c5-d69528a0f280',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rogers filed H.866 (enabling cities and towns to extend voting rights in municipal elections to certain noncitizens) and H.865 (relative to the qualification of voters), and co-sponsored same-day voter registration legislation. Filing a bill to extend voting rights to noncitizens in municipal elections is among the most expansive voting rights positions in the legislature. These actions reflect a strong pro-voting-access stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H866', 'https://malegislature.gov/Bills/194/H865', 'https://actonmass.org/legislators/david-rogers/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~18 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ffb8e526-7ad7-4911-92c5-d69528a0f280';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ffb8e526-7ad7-4911-92c5-d69528a0f280'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ffb8e526-7ad7-4911-92c5-d69528a0f280'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
