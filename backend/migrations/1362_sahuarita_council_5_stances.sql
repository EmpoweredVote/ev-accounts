-- =====================================================================================
-- Compass stances: Edgar (Ed) Lytle — Council Member, Town of Sahuarita (AZ)
-- politician_id: bbfcbd5f-ff32-40d4-af9f-f5c755869571   (external_id -4014007)
-- Nonpartisan, at-large. Elected July 2024, SWORN IN NOV. 18, 2024 (term to 2028). Seven
-- years USAF; 30-year career with Anchorage Telephone Utility; youth-sports coach.
-- TENURE NOTE: no Sahuarita Council vote or action before Nov. 2024 is attributed to him —
-- the June 10, 2024 town bond vote is NOT attributed to Lytle.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file intentionally seeds NO stance rows: no clean, attributable, chair-mappable
--     Lytle position on any of the 36 non-judicial live compass topics was found in citable
--     public sources as of the 2026-07-16 research date. This is an HONEST BLANK, not an
--     oversight — no neutral/default value is ever emitted to fill a topic.
--   * Touches only inform.politician_answers and inform.politician_context (no rows written).
--   * AUDIT-ONLY / unregistered. The orchestrator applies it.
--
-- Reference: topic UUIDs available (36 non-judicial live compass topics; the 8 judicial-*
--   topics are NEVER seeded for a town official) — none seeded here for lack of evidence.
--
-- DELIBERATELY BLANK (why every topic is blank for Lytle):
--   * He DID NOT RESPOND to the Green Valley News 2024 candidate five-question Q&A (the primary
--     candidate-positions source used for the other 2024 council winners), so there is no
--     candidate-survey record to draw on.
--   * His only public self-description is a general aspiration — "focused on representing all
--     neighborhoods and supporting the community's growth and prosperity" — which is too generic
--     to map to any topic's discrete chairs (per the project's no-default / evidence-only rule,
--     generic "support growth and prosperity" is not a chair-mappable position).
--   * His documented council-meeting activity (e.g., fiber-internet expansion, transportation
--     planning) is participation, not an attributable policy position that maps to a chair.
--   * The June 10, 2024 $66M bond vote predates his Nov. 18, 2024 swearing-in and is NOT
--     attributed to him.
--   * Copper World / Hudbay mine, water, data-centers: no citable individual Lytle statement or
--     standalone vote located.
--   * Non-local federal/state topics: a town council member has no governing record.
--   (No judicial-* topic is ever seeded.)
-- =====================================================================================

BEGIN;

-- No stance rows: honest blank (see header). No INSERT is emitted for any topic — a topic with
-- no clear documented, attributable Lytle position gets NO row, per the evidence-only convention.

COMMIT;
