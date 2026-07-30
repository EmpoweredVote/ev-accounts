-- =====================================================================================
-- Phase 222 (plan 222-11) — Compass stances: Town of Fairview, TX (geo_id 4825224)
--                            + City of Princeton, TX (geo_id 4859576) councils
-- Authored 2026-07-30.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * AUDIT-ONLY: no migration runner exists; this file records SQL applied by hand via
--     mcp__supabase-local__execute_sql. It touches only inform.politician_answers and
--     inform.politician_context.
--   * The single chair seeded here rests on the officeholder's own 2026 campaign-platform
--     statements, read twice on her live campaign site and reproduced verbatim by
--     Ballotpedia (as of April 13, 2026). No party inference, no identity inference, no
--     city-policy or city-budget default, no adjacency inference (board service,
--     profession, tenure), no defaulted middle value.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Fairview, TEXAS (Collin County) confirmed on every source used. Homonym traps hit
--     and rejected this pass: ballotpedia.org/John_Stanley (South Carolina Municipal
--     Courts), Patrick_Sheehan (disambiguation), New Fairview TX (Wise County).
--
-- SCOPE: the 6 un-stanced Fairview council members + 3 un-stanced Princeton council
-- members on the 222-01 live worklist (mayors excluded — covered in 222-08; the Fairview
-- and Princeton mayors' rows are untouched here). Live-verified 2026-07-30: all 9 ids at
-- 0 answer rows; Princeton's Todd and Washington carry 2026-05-12 found-nothing context
-- notes (8 rows each) that are honest blanks, not defects.
--
-- SEEDED (1 row / 1 answer+context pair):
--   Lakia Works (Fairview Seat 6)
--     residential-zoning        = 1  (her own 2026 platform: "protecting the Town's
--                                     low-density, residential character", "strengthening
--                                     ordinances ... applied consistently so that growth
--                                     never comes at the expense of quality of life",
--                                     "strictly enforce ordinances that protect our
--                                     neighborhoods" — the strict-preservation chair,
--                                     following the register's Kuykendall precedent for
--                                     this exact statement class)
--     Honest limitation, flagged for operator review at apply time: chair 1's
--     "require community votes before any rezoning" clause is not in her platform; the
--     mapping rests on chair 1's dominant strict-preservation proposition, and chair 2 is
--     affirmatively contrary (she supports no density increase of any scale).
--
-- taxes — RESEARCHED, NO CHAIR WRITTEN for any person, per the settled operator ruling of
--   2026-07-25 (222-RESEARCH.md §B): no taxes row may be written by plans 222-05..222-17.
--
-- DELIBERATELY BLANK (65 Fairview person/topic pairs — see 222-CONFIRMED-BLANK.md):
--   Rich Connelly (Seat 1):  11/11 settled (7 recorded Nays in 14 months, all unexplained
--                            — Fairview minutes are action-only; MLK-holiday motion
--                            refused: unexplained + off-axis for civil-rights)
--   Joe W. Boggs (Seat 2):   11/11 settled (elected unopposed, no questionnaire, no
--                            campaign site, 8 weeks served)
--   Jill Hawkins (Seat 3):   11/11 settled (bio-only record; chamber/EDC service is
--                            adjacency; drainage motion is maintenance framing)
--   John Stanley (Seat 4):   11/11 settled (six-plank platform read verbatim, every plank
--                            refused: temple plank = due-process critique; DART plank =
--                            evaluate-before-commit spanning chairs 2-4; tax planks
--                            generic/off-scale)
--   Pat Sheehan (Seat 5):    10 settled + 1 ACCESS FAILURE (homelessness — Jan 6, 2026
--                            minutes record he "spoke regarding updates to laws regarding
--                            homelessness and panhandling" with zero content; retry path =
--                            that meeting's MP3 audio via CivicClerk externalMediaUrl)
--   Lakia Works (Seat 6):    10 settled (her "smart, intentional growth" line refused for
--                            growth-and-development as generically evaluative; the
--                            low-density plank deliberately NOT carried across to housing
--                            or growth topics)
--
-- Princeton block appended below after the Task 2 research pass (or this comment is
-- replaced by the all-blank note if Princeton sources nothing).
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Lakia Works — Council Member Seat 6, Town of Fairview, TX
-- politician_id: 9e80fff4-8b89-4c38-b33e-a1a0fff7e080
-- Elected to Seat 6 in the May 2026 general election; five years on the Fairview
-- Planning and Zoning Commission before election.
-- =====================================================================================

-- ----- Lakia Works / residential-zoning (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9e80fff4-8b89-4c38-b33e-a1a0fff7e080',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9e80fff4-8b89-4c38-b33e-a1a0fff7e080',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$On her 2026 campaign website (reproduced verbatim by Ballotpedia as of April 13, 2026), Works states she believes in "protecting the Town's low-density, residential character" and supports "strengthening ordinances and ensuring they are applied consistently so that growth never comes at the expense of quality of life," citing five years of "vetting development on the Planning and Zoning Commission" as the technical expertise "to strictly enforce ordinances that protect our neighborhoods." This is an explicit commitment to strict preservation of existing low-density neighborhood character through zoning ordinances.$stz$,
        ARRAY['https://worksforfairview.com/',
              'https://ballotpedia.org/Lakia_Works_(Fairview_Town_Council_Seat_6,_Texas,_candidate_2026)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
