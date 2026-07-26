-- =====================================================================================
-- Phase 222 (plan 222-06) — Compass stances: City of Richardson, TX (geo_id 4861796)
-- Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * The single chair seeded here rests on the officeholder's own first-person statement
--     of preference at a dated council work session, on a specific allocation decision,
--     corroborated by his own words one week earlier at a recorded rezoning vote. No party
--     inference, no identity inference, no city-policy or city-budget default, no adjacency
--     inference (board service, chamber membership, profession, tenure), no capital-project
--     attribution, no defaulted middle value.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Richardson, TEXAS confirmed on every source used. Richardson straddles Dallas and
--     Collin counties and "Richardson" is also a common surname and a city name in other
--     states, so the homonym gate was applied deliberately: every source used is on
--     Community Impact's Dallas-Fort Worth / Richardson desk and names Richardson ISD,
--     the Envision Richardson comprehensive plan, and Richardson street addresses. His
--     identity as the Richardson TX council member for Place 1 / District 1 (elected
--     May 2023; re-elected unopposed May 3, 2025 with 8,009 votes) was confirmed before
--     any evidence was accepted as his.
--
-- SCOPE: the one un-stanced Richardson officeholder on the 222-01 live worklist.
--   Curtis Dorian — Council Member District 1 — 6b512b29-d3c1-4709-829f-df78664ffee1
-- The other seated Richardson officeholders already hold stances and are out of scope per
-- D-07 (no overwrite pass); this file references and touches none of their rows. Several
-- Richardson rows (Omar, Shamsul, Barrios) were remediated on 2026-07-25 and must not be
-- disturbed.
--
-- SEEDED (1 row / 1 answer+context pair):
--   Curtis Dorian (1)
--     housing                   = 3  (his own stated preference at the May 18, 2026 council
--                                     work session for spending Richardson's ~$798K CDBG
--                                     allocation on means-tested home repair rather than the
--                                     competing street/infrastructure/park uses, plus his own
--                                     May 11, 2026 reaffirmation of the council's
--                                     affordable-housing objective)
--
-- taxes — RESEARCHED, NO CHAIR WRITTEN. Per the settled operator ruling of 2026-07-25
--   (222-RESEARCH.md §B; header of 1418_222_plano_gapfill_stances.sql), the taxes scale is
--   structurally unanswerable for a Texas municipal officeholder: chairs 1–2 require raising
--   taxes on wealthy people and large companies and chairs 4–5 require scaling public
--   services back, so chair 3 is the only reachable chair and carries no discriminating
--   information. Dorian's evidence on this axis is thin in any case — no statement on the
--   property-tax rate was found at all, and his one adjacent remark is about utility rates,
--   not taxes. It is preserved verbatim in 222-CONFIRMED-BLANK.md. No taxes row is written.
--
-- DELIBERATELY BLANK (10 person/topic pairs — see 222-CONFIRMED-BLANK.md for each):
--   Dorian: civil-rights, homelessness, economic-development, local-immigration,
--           public-safety-approach, residential-zoning, transportation-priorities, taxes,
--           growth-and-development, healthcare.
--   Note in particular:
--     - residential-zoning was DEMOTED TO BLANK during this plan's Tier-1 self-audit. A
--       re-fetch of the May 14, 2026 Community Impact story confirmed that his remarks at the
--       May 11, 2026 Greenwood Park rezoning vote say nothing about where middle housing
--       should be allowed, nothing about multifamily, nothing about neighborhood character,
--       and nothing about community votes on rezoning — so the available evidence spans
--       chair 2's and chair 3's subject matter without resolving between them.
--     - His two other 2025 rezoning votes (89 townhomes at 3600 Shiloh Rd, unanimous
--       April 28, 2025; 279 downtown apartments on Polk St, February 10, 2025) were
--       deliberately NOT used: he is not quoted in either and a generic unanimous rezoning
--       approval with no stated reason is the exact defect the 222-01 audit deleted from an
--       Allen record on 2026-07-25.
--     - His Richardson Chamber of Commerce membership and his career as a land-development
--       and design-build contractor were deliberately NOT used for economic-development or
--       residential-zoning; his Citizens Police Academy attendance and his volunteering with
--       the Richardson police and fire departments were deliberately NOT used for
--       public-safety-approach. Both are adjacency, not positions.
--     - The Interurban district's stated aim of "reducing auto uses" refers to automotive
--       businesses (repair garages), not to car travel, and was deliberately NOT read as a
--       transportation-priorities position.
--
-- SOURCES THAT COULD NOT BE READ THIS SESSION (recorded so a later pass can retry, not
-- treated as absence of a position): every www.cor.net URL attempted returned HTTP 403,
-- including his official council-member page and the city's news/Week-in-Review pages, so
-- the official City of Richardson site was never read and no city agenda packet, minutes
-- document, or meeting video was opened; ballotpedia.org's individual candidate page for him
-- resolved but returned an EMPTY BODY, as did the Richardson 2025 city-elections page (a
-- known Ballotpedia failure throughout this phase); he ran unopposed on May 3, 2025, so no
-- 2025 candidate questionnaire appears to exist; lwvcollin.org / VOTE411 produced no
-- Richardson Place 1 questionnaire.
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Curtis Dorian — Council Member District 1 (Place 1), City of Richardson, TX
-- politician_id: 6b512b29-d3c1-4709-829f-df78664ffee1
-- Elected to Place 1 in May 2023; re-elected unopposed May 3, 2025 (8,009 votes, 100%).
-- Both dated actions cited below were taken in that council capacity.
-- =====================================================================================

-- ----- Curtis Dorian / housing (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6b512b29-d3c1-4709-829f-df78664ffee1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $stz$At the May 18, 2026 Richardson City Council work session on the city's Community Development Block Grant participation — an estimated $798,000 federal allocation for fiscal year 2027-28, at least 70 percent of which must benefit low- and moderate-income residents — Dorian stated his own preference for spending the money on housing rather than on the competing street, infrastructure and park uses also under discussion: "I would like to see [the funds] going into helping repair homes and keep the neighborhoods intact. We are so landlocked, and we do have a lot of neighborhoods that require [rehabilitation], and we have an aging population." The program he backed is a means-tested senior home-repair program, identified together with missing middle housing as a city priority in the January 2026 affordable-housing-initiatives presentation; one week earlier, after voting on May 11, 2026 to approve the Greenwood Park rezoning, he reaffirmed that the council's objective under the Envision Richardson comprehensive plan should be supporting opportunities for more affordable housing, saying "We're always taking into consideration that we do need some middle ground housing." Directing targeted public subsidy to households who could not otherwise afford to keep the housing they have is the targeted-help chair: he has advocated no rent caps and no requirement that new developments include affordable units, has not proposed that the city build or operate housing itself, and has not argued that cutting regulation alone should carry housing affordability.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/richardson/development/2026/05/26/richardson-considers-federal-funding-program-for-home-repair-infrastructure/',
              'https://communityimpact.com/dallas-fort-worth/richardson/development/2026/05/14/single-family-neighborhood-heads-for-development-in-richardson/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
