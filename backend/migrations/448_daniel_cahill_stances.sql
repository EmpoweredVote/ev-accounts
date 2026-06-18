-- ============================================================================
-- Migration 448: Daniel F. Cahill Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Daniel F. Cahill (MA State Rep, HD-33,
--   10th Essex District, Lynn).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: ca6d9c06-e613-46a1-b938-0d89d488b583 (external_id=-210073)

BEGIN;

-- ----- Daniel F. Cahill / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Cahill serves as Chair of the Joint Committee on Environment and Natural Resources in the 194th General Court — the committee that oversees environmental policy, water resources, and natural resource management in Massachusetts. This leadership role reflects a sustained and direct commitment to local and state environmental protection.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DFC1/Committees', 'https://actonmass.org/legislators/daniel-cahill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cahill co-sponsored the Safe Communities Act as tracked by Act on Mass, a Massachusetts sanctuary bill that would limit state and local law enforcement from assisting with federal immigration enforcement. Representing Lynn — a gateway city with a large immigrant population — this co-sponsorship reflects a strong pro-immigrant protection stance.$$,
        ARRAY['https://actonmass.org/legislators/daniel-cahill/', 'https://malegislature.gov/Legislators/Profile/DFC1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cahill sponsored H.1354 relative to financing the Health Safety Net Trust Fund (which provides healthcare for uninsured and underinsured residents) and H.1107 relative to insurance coverage for discounted drugs. He also co-sponsored the THRIVE Act and the Cherish Act (Act on Mass). These bills reflect support for expanding the health safety net and drug cost coverage for Massachusetts residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1354', 'https://malegislature.gov/Bills/194/H1107', 'https://actonmass.org/legislators/daniel-cahill/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cahill sponsored H.1472 relative to affordable and public housing options, H.1473 relative to homesharing (enabling homeowners to share space), and H.1474 relative to affordable housing in certain municipalities (co-sponsored with Rep. Sean Reid). This housing package reflects support for expanding affordable housing supply through both traditional means and innovative approaches like homesharing for his Lynn district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1472', 'https://malegislature.gov/Bills/194/H1473', 'https://malegislature.gov/Bills/194/H1474']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cahill sponsored H.1108 to establish portable benefit accounts for app-based delivery drivers — an innovative gig economy worker protection bill — and co-sponsored Stop Wage Theft and Right to Strike legislation (Act on Mass). He also sponsored H.481 on sports wagering licenses, which addresses economic development through gaming. His mix of worker protection and economic innovation bills reflects a pro-economic development stance focused on worker rights.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1108', 'https://actonmass.org/legislators/daniel-cahill/', 'https://malegislature.gov/Bills/194/H481']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cahill co-sponsored Progressive Revenue legislation as tracked by Act on Mass. He also sponsored H.1354 on the Health Safety Net Trust Fund (a health tax/fee mechanism) and multiple financial regulation bills including H.1103/1104 on banking and commercial insurance. His progressive revenue co-sponsorship reflects support for higher taxes on corporations and high earners, while his finance bills reflect an interest in regulated financial markets.$$,
        ARRAY['https://actonmass.org/legislators/daniel-cahill/', 'https://malegislature.gov/Bills/194/H1354']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel F. Cahill / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ca6d9c06-e613-46a1-b938-0d89d488b583',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cahill co-sponsored the Healthy Youth Act (LGBTQ+ inclusive sex education) and Support Native Students legislation as tracked by Act on Mass. Representing Lynn — a diverse gateway city — he brings a civil rights focus to his legislative work. These co-sponsorships reflect consistent support for LGBTQ+ rights and Indigenous rights.$$,
        ARRAY['https://actonmass.org/legislators/daniel-cahill/', 'https://malegislature.gov/Legislators/Profile/DFC1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ca6d9c06-e613-46a1-b938-0d89d488b583';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ca6d9c06-e613-46a1-b938-0d89d488b583'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ca6d9c06-e613-46a1-b938-0d89d488b583'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
