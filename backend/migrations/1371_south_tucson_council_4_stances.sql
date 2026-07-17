-- =====================================================================================
-- Compass stances: Cesar Aguirre — Council Member, City of South Tucson (AZ)
-- politician_id: aec8b558-0a8b-4ee1-bc26-1cb9369f6ed5   (external_id -4015007)
-- Nonpartisan (antipartisan display). Council Member (term thru 2026 — up in the July 21,
-- 2026 primary).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file INTENTIONALLY seeds NO stance rows (0 into inform.politician_answers / 0
--     into inform.politician_context). No documented, attributable position for the SOUTH
--     TUCSON Cesar Aguirre could be found across the 36 non-judicial live compass topics
--     from reachable non-WAF sources this session. Per feedback_stance_no_default_value, a
--     topic (here, every topic) with no evidence gets NO row — never a neutral default.
--   * This is a genuine, documented honest blank, not an omission: the AZ Luminaria 2026
--     voter guide states "Aguirre did not respond to questions despite multiple attempts to
--     contact them. Neither have campaign websites nor have made any public comments
--     regarding their positions" (fetched 2026-07-17).
--
-- ⚠ NAME-COLLISION CAVEAT (T-198-SRC / wrong-person binding — DO NOT SEED):
--   A prominent environmental-justice activist ALSO named "Cesar Aguirre" is the Air and
--   Climate Justice Director at the Central California Environmental Justice Network
--   (Kern County / San Joaquin Valley, CALIFORNIA) and a co-founder of California Youth vs.
--   Big Oil, with strong on-record fossil-fuel/oil-and-gas-setback positions. That is a
--   DIFFERENT PERSON, not the South Tucson AZ council member. His fossil-fuels / climate /
--   local-environment positions were deliberately NOT seeded here — attributing them to the
--   South Tucson Aguirre would be a wrong-person binding error. If a future pass finds a
--   genuine on-record SOUTH TUCSON Aguirre position (e.g. in city council meeting minutes),
--   seed it then, evidence-only.
--
--   * Discrete 1-5 "chairs" (feedback_compass_chairs_not_polarity), never a polarity scale.
--   * AUDIT-ONLY / unregistered (no migration-ledger entry). This file touches
--     inform.politician_answers / inform.politician_context ONLY conceptually — it writes
--     no rows. The orchestrator applies it (a clean, empty transaction) as the per-official
--     save-point marker for Aguirre.
--
-- Reference: the 36 non-judicial live compass topics are the in-scope universe; the 8
--   judicial-* topics are NEVER seeded for a city council official. NONE is seeded here.
--
-- DELIBERATELY BLANK: ALL 36 non-judicial topics — no citable South Tucson Aguirre
--   position exists (voter-guide non-response; no campaign site; no public comments; the
--   same-name California activist is a different person and is NOT attributed).
-- =====================================================================================

BEGIN;

-- No stance rows: no documented South Tucson Cesar Aguirre position found (honest blank).
-- (Intentionally empty transaction — see header. No INSERT into inform.politician_answers
--  or inform.politician_context; no judicial-* topic; no ledger registration.)

COMMIT;
