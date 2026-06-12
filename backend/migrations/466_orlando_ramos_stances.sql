-- ============================================================================
-- Migration 466: Orlando Ramos Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Orlando Ramos (MA State Rep, 9th Hampden District, HD-51).
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
-- Orlando Ramos (HD-51, external_id=-210091)
-- UUID: ef8a23a0-7f93-425c-a773-dcec9eb96dfb
-- District: 9th Hampden (Springfield area)
-- Democrat; committees: Racial Equity/Civil Rights/Inclusion, IT/Cybersecurity, Transportation.
-- ============================================================================

-- ----- Orlando Ramos / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Ramos sponsored H.863, "An Act establishing same-day voter registration," which allows residents to register and vote on Election Day — one of the most expansive voting access measures possible. He also sponsored H.864, "An Act relative to mail-in ballots," expanding absentee/mail voting options. Both bills represent maximum voting access expansion, placing him at the strong-expansion end of the voting rights spectrum.$$,
        ARRAY['https://malegislature.gov/Bills/194/H863', 'https://malegislature.gov/Bills/194/H864']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ramos serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion — a direct legislative role shaping civil rights policy. He sponsored H.1946, "An Act to implement the recommendations of the special commission on facial recognition technology," addressing algorithmic bias and civil liberties. He also sponsored H.1945 creating a judicial accountability commission, and H.493 establishing a Puerto Rico trade commission reflecting community representation interests.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/O_R1/Committees', 'https://malegislature.gov/Bills/194/H1946', 'https://malegislature.gov/Bills/194/H1945']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Ramos serves on the Joint Committee on Advanced Information Technology, the Internet and Cybersecurity, placing him in a direct role shaping AI and technology policy. He sponsored H.1946, "An Act to implement the recommendations of the special commission on facial recognition technology," which seeks to regulate and limit the use of facial recognition by law enforcement — a pro-regulation AI stance focused on civil liberties protection.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1946', 'https://malegislature.gov/Legislators/Profile/O_R1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ramos sponsored H.1482, "An Act to establish an accessory dwelling unit trust fund," which creates dedicated funding to build ADUs — a key housing supply expansion strategy. He also sponsored H.3216, "An Act supporting home sales to first-time home buyers," expanding homeownership access, and H.1947, "An Act relative to small landlords." These bills reflect consistent support for expanding the housing supply and homeownership opportunity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1482', 'https://malegislature.gov/Bills/194/H3216']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ramos sponsored H.2159, "An Act relative to fair wages on government subsidized construction projects," ensuring prevailing wages on publicly funded construction. He also sponsored H.494, "An Act reducing costs for microbusinesses," supporting small entrepreneurship in Springfield, and H.493 establishing a Puerto Rico trade commission. These bills favor labor standards and equitable access to economic opportunity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2159', 'https://malegislature.gov/Bills/194/H494']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Ramos sponsored H.3548, "An Act limiting the eligibility of woody biomass as an alternative energy supply," which restricts biomass (a fossil fuel alternative that can cause emissions comparable to coal) from qualifying as renewable energy. This legislation reflects a pro-clean-energy, anti-dirty-biomass stance favoring genuine renewable energy over fossil fuel substitutes that perpetuate emissions.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3548']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Orlando Ramos / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef8a23a0-7f93-425c-a773-dcec9eb96dfb',
        '6674d87e-999d-433a-aab7-3f626f59fd5f',
        $$Ramos sponsored H.1945, "An Act establishing a commission to study judicial accountability in the Commonwealth," which creates a formal commission to evaluate and recommend improvements to judicial accountability mechanisms in Massachusetts courts. This reflects support for greater judicial transparency and oversight.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1945']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 7 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ef8a23a0-7f93-425c-a773-dcec9eb96dfb';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'ef8a23a0-7f93-425c-a773-dcec9eb96dfb'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'ef8a23a0-7f93-425c-a773-dcec9eb96dfb'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
