-- =====================================================================================
-- Compass stances: David H. Ready — City of Palm Springs (CA) City Council, District 5 (Mayor Pro Tem)
-- ext_id: -4011005   politician_id: 59c2f45b-5369-4db0-936b-df94a57527c9
-- Nonpartisan municipal office (party not stored/displayed). Former Palm Springs City Manager
-- (21 years, retired Dec 2020); elected Nov 2024; council-appointed Mayor Pro Tem (rotational).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration. Non-court-scoped office — no court-scoped-* topics.
-- The active directly-elected-mayor petition is background only and is NOT forced into any topic.
--
-- SEEDED: NONE (0 topics) — HONEST BLANK.
--   Ready's documented positions as of this research pass are general management/fiscal themes
--   ("no-nonsense, common-sense approach," cutting bureaucracy, building on his City-Manager-era
--   successes, advocating for District 5's share of city resources) plus a Firefighters Association
--   endorsement characterizing his City-Manager tenure as supportive of public safety. None of
--   these map cleanly to a discrete compass chair without over-reading:
--     - public-safety-approach: a union endorsement of his administrative tenure is not an
--       on-record position on staffing/budget LEVELS (chairs 1-5), so it is NOT seeded (no force-fit).
--     - his fiscal/"common-sense" and District-resource-advocacy themes have no matching non-court-scoped
--       compass topic.
--   Per the project's evidence-only discipline, a topic with no clearly attributable chair-mappable
--   position gets NO row and is never given a neutral default. This member therefore has zero
--   seeded stances this pass (an honest blank), pending a future documented council voting record.
--
-- Pattern reference (the standard two-table shape used when evidence exists — see the D1-D4 files):
--   INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES (...)
--     ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
--   INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES (...)
--     ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
-- AUDIT-ONLY / unregistered (not registered in the migration ledger).
-- =====================================================================================

BEGIN;

-- (No evidence-mapped stance rows for David H. Ready this pass — honest blank. See header.)

COMMIT;
