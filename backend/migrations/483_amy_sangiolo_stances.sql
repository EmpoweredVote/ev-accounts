-- ============================================================================
-- Migration 483: Amy M. Sangiolo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Amy M. Sangiolo (MA House HD-68,
--   11th Middlesex District). External ID: -210108.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 11 rows in DB, mostly 3.0 neutral defaults from prior agent.
--   This migration corrects topics with positive evidence found.
--   Remaining 3.0 neutral defaults without evidence are left in place (out-of-scope).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Amy M. Sangiolo (HD-68, external_id=-210108)
-- Politician UUID: 2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf

-- ----- Amy M. Sangiolo / civil-rights -----
-- Correcting pre-existing 3.0 neutral default: committee assignment is evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sangiolo serves on the Joint Committee on Racial Equity, Civil Rights, and Inclusion — a direct assignment to the committee responsible for civil rights legislation in Massachusetts. This committee assignment places her in a key role for advancing civil rights protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMS3/Committees', 'https://malegislature.gov/Committees/Detail/J34'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / climate-change -----
-- Correcting pre-existing 3.0 neutral default: sponsored clean energy bills
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sangiolo filed H.3565, "An Act relative to Mass Save assessments," strengthening Massachusetts' energy efficiency programs, and H.4722, "An Act promoting fair tax treatment for zero-emission vehicles," encouraging EV adoption. These bills reflect support for climate-friendly energy and transportation policies.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3565', 'https://malegislature.gov/Bills/194/H4722'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / fossil-fuels -----
-- Correcting pre-existing 3.0 neutral default: gas stove warning bill is evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Sangiolo filed H.464, "An Act warning consumers of the health risks of gas stoves," requiring health risk disclosures on gas stove purchases — reflecting concern about the health and climate impacts of burning natural gas. Combined with her zero-emission vehicle tax bill (H.4722), this positions her toward phasing out fossil fuel use.$$,
        ARRAY['https://malegislature.gov/Bills/194/H464', 'https://malegislature.gov/Bills/194/H4722'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / healthcare -----
-- Correcting pre-existing 3.0 neutral default: multiple healthcare bills and committee
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sangiolo serves on the Joint Committee on Public Health and filed H.1317, "An Act improving access to breast pumps," expanding insurance coverage for breastfeeding support. Her Public Health committee assignment and healthcare-access bill reflect support for expanded, accessible healthcare services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMS3/Committees', 'https://malegislature.gov/Bills/194/H1317'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / housing -----
-- Correcting pre-existing 3.0 neutral default: rent regulation bill is evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Sangiolo filed H.1553, "An Act to regulate junk fees in rental housing," which would prohibit landlords from charging undisclosed fees (application fees, admin fees, etc.) to renters. This bill reflects support for tenant protections and affordable housing access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1553'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / judicial-criminal-justice -----
-- New topic: evidence from youth protection bill
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
        $$Sangiolo filed H.1984, "An Act protecting youth during custodial interrogations," which would establish procedural protections for minors being questioned by law enforcement, including requiring adult support and a cooling-off period before interrogation. This bill reflects a reform-oriented approach to criminal justice that prioritizes youth protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1984'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Amy M. Sangiolo / public-safety-approach -----
-- New topic: evidence from Public Safety committee assignment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sangiolo serves on the Joint Committee on Public Safety and Homeland Security, which handles police oversight and public safety legislation. Her committee assignment combined with her bill protecting youth during custodial interrogations (H.1984) suggests a reform-oriented approach to public safety that emphasizes procedural protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AMS3/Committees', 'https://malegislature.gov/Committees/Detail/J22', 'https://malegislature.gov/Bills/194/H1984'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~13 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2dcaf90d-f476-4fcf-af03-3d0a7aa5d3bf'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
