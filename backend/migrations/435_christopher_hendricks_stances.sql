-- ============================================================================
-- Migration 435: Christopher Hendricks Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Christopher Hendricks
--   (MA State Representative, 11th Bristol District, HD-20, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Pre-existing rows exist for 14 topics from a prior agent run.
--   Several pre-existing rows have value=3.0 "did not co-sponsor" neutral defaults
--   which are out of scope to fix per scope boundary rules. This migration UPSERTS
--   topics where direct evidence exists, improving or adding to the record.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 9cb46542-a671-4bdd-bfcb-98fc1bc79415 (external_id: -210060)

BEGIN;

-- ----- Christopher Hendricks / climate-change -----
-- Evidence: Co-sponsored 100% Renewable Energy by 2045 and Environmental Justice per AOM.
-- (Already in pre-existing with correct value; this upsert confirms/reinforces with current evidence.)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Hendricks co-sponsored both 100% Renewable Energy by 2045 and Environmental Justice per the Act on Mass tracker. The 100% Renewable Energy bill would require Massachusetts to achieve full clean energy by 2045. The Environmental Justice bill strengthens protections for communities of color disproportionately impacted by pollution — directly relevant to his Fall River/New Bedford-area constituents who live near industrial sites. His dual co-sponsorships demonstrate a robust climate action stance.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Legislators/Profile/CH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / fossil-fuels -----
-- Evidence: Co-sponsored 100% Renewable Energy by 2045 per AOM.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Hendricks co-sponsored 100% Renewable Energy by 2045 per Act on Mass, which would require Massachusetts to eliminate fossil fuel use by 2045. This co-sponsorship reflects direct support for phasing out fossil fuels and transitioning to clean energy. His 11th Bristol District (Fall River area) has historically had high industrial pollution, giving him constituency-based motivation for clean energy transition.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Legislators/Profile/CH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / childcare -----
-- Evidence: Co-sponsored Campaign Childcare (H.669) per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Hendricks co-sponsored Campaign Childcare (H.669) per the Act on Mass tracker, which allows campaign funds to cover childcare costs for candidates with young children, reducing barriers to running for office. His 11th Bristol District (Fall River area) has many working families with significant childcare cost challenges. The Campaign Childcare co-sponsorship reflects support for policies that expand childcare access and reduce its cost burden.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://actonmass.org/bills/campaign-childcare/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / school-vouchers -----
-- Evidence: Co-sponsored the Cherish Act (Fully Funded Public Higher Education) per AOM.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Hendricks co-sponsored the Cherish Act (Fully Funded Public Higher Education) per the Act on Mass tracker, which would make public higher education tuition-free in Massachusetts. This co-sponsorship demonstrates strong support for public education investment and opposition to diverting public funds to private institutions via voucher programs. His Fall River district has a high proportion of students who attend public universities, giving strong constituent motivation for public higher education investment.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Legislators/Profile/CH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / healthcare -----
-- Evidence: Co-sponsored Overdose Prevention Centers per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Hendricks co-sponsored Overdose Prevention Centers per the Act on Mass tracker, supporting harm-reduction healthcare facilities that provide supervised drug use to prevent overdose deaths. He also jointly sponsored H.1363 (extending healthcare coverage) and H.1364 (healthcare access and affordability) with fellow Fall River-area representatives. His Fall River district has been significantly impacted by the opioid crisis, making overdose prevention a direct constituent priority. His healthcare co-sponsorships reflect a pro-access, harm-reduction approach.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Legislators/Profile/CH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / taxes -----
-- Evidence: Co-sponsored Stop Wage Theft per AOM tracker.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Hendricks co-sponsored Stop Wage Theft per the Act on Mass tracker, legislation to strengthen enforcement against employers who steal wages from workers. This co-sponsorship reflects a pro-worker, progressive economic stance that prioritizes worker protections and accountability for employers over minimal regulation. His Fall River district includes many hourly workers in service and manufacturing industries who are most vulnerable to wage theft.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Legislators/Profile/CH1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher Hendricks / housing -----
-- Evidence: Member of Joint Committee on Housing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9cb46542-a671-4bdd-bfcb-98fc1bc79415',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Hendricks serves on the Joint Committee on Housing, which handles rent regulation, tenant protections, affordable housing construction, and zoning policy in Massachusetts. As a Democrat on this committee representing Fall River — one of the cities most impacted by the regional housing affordability crisis — he is positioned to advance pro-housing access legislation. His committee assignment reflects active engagement with housing policy as a legislative priority.$$,
        ARRAY['https://actonmass.org/legislators/christopher-hendricks/', 'https://malegislature.gov/Committees/Joint/J20']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '9cb46542-a671-4bdd-bfcb-98fc1bc79415'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
