-- =====================================================================================
-- Phase 222 (plan 222-05) — Compass stances: City of Allen, TX (geo_id 4801924)
-- Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * The single chair seeded here rests on a recorded council vote for which the
--     officeholder himself gave his reason on the record, plus his own direct quotes in
--     the same interview. No party inference, no identity inference, no city-policy or
--     city-budget default, no adjacency inference (board service, profession, tenure),
--     no defaulted middle value.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Allen, TEXAS confirmed on every source used. His identity as the Allen TX council
--     member (Place 4, May 2019 – May 2025) and now Allen TX mayor (term 2026–2029,
--     sworn in May 26, 2026) was confirmed on cityofallen.org's City Council page and in
--     Community Impact / KERA coverage of the May 2, 2026 Allen mayoral election.
--
-- SCOPE: the one un-stanced Allen officeholder on the 222-01 live worklist.
--   Chris Schulmeister — Mayor — 698da6ca-eadd-46a0-8e27-94ae48d23279
-- The other seated Allen officeholders already hold stances and are out of scope per
-- D-07 (no overwrite pass); this file references and touches none of their rows. Several
-- of those rows were remediated on 2026-07-25 and must not be disturbed.
--
-- SEEDED (1 row / 1 answer+context pair):
--   Chris Schulmeister (1)
--     residential-zoning        = 3  (recorded Aug 2019 council vote against the 800-unit
--                                     Allen City Center downtown multifamily plan, with his
--                                     own stated reason, plus his own quote affirming that
--                                     Allen must offer multifamily to compete)
--
-- taxes — RESEARCHED, NO CHAIR WRITTEN. Per the settled operator ruling of 2026-07-25
--   (222-RESEARCH.md §B; header of 1418_222_plano_gapfill_stances.sql), the taxes scale is
--   structurally unanswerable for a Texas municipal officeholder: chairs 1–2 require raising
--   taxes on wealthy people and large companies and chairs 4–5 require scaling public
--   services back, so chair 3 is the only reachable chair and carries no discriminating
--   information. Schulmeister's evidence on this topic is unusually explicit (Community
--   Impact, March 17, 2026: "During my six years on Council, I voted to reduce the tax rate
--   every year. A 5% Homestead Exemption was adopted." plus "The level of city services may
--   need to be adjusted... continuing my efforts toward further tax relief"). It is preserved
--   verbatim in 222-CONFIRMED-BLANK.md so it can be placed if the question is ever rewritten
--   with municipal scope. No taxes row is written here.
--
-- DELIBERATELY BLANK (10 person/topic pairs — see 222-CONFIRMED-BLANK.md for each):
--   Schulmeister: housing, civil-rights, homelessness, economic-development,
--                 local-immigration, public-safety-approach, transportation-priorities,
--                 taxes, growth-and-development, healthcare.
--   Note in particular that his service on the Allen Economic Development Corporation and
--   Community Development Corporation boards was deliberately NOT used for
--   economic-development, and his generic platform language on supporting police and fire
--   was deliberately NOT used for public-safety-approach. Both are the exact adjacency and
--   generic-quote defects the 222-01 county-wide audit deleted from five other Allen rows
--   on 2026-07-25.
--
-- SOURCES THAT COULD NOT BE READ THIS SESSION (recorded so a later pass can retry, not
-- treated as absence of a position): chrisforallen.org and www.chrisforallen.org returned
-- HTTP 404 to every fetch (root and /meet-chris/), so his campaign platform pages were
-- never read; ballotpedia.org's individual candidate page resolved but returned an empty
-- body; lwvcollin.org/voters-guides and cityofallen.org/directory.aspx returned HTTP 403.
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Chris Schulmeister — Mayor, City of Allen, TX
-- politician_id: 698da6ca-eadd-46a0-8e27-94ae48d23279
-- Elected May 2, 2026 (3,278 votes, 81%) over Dave Shafer; sworn in at the May 26, 2026
-- council meeting; term 2026–2029. Previously Allen City Council Place 4, May 2019 –
-- May 2025, including two years as mayor pro tem — the 2019 vote cited below was cast in
-- that council capacity.
-- =====================================================================================

-- ----- Chris Schulmeister / residential-zoning (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('698da6ca-eadd-46a0-8e27-94ae48d23279',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('698da6ca-eadd-46a0-8e27-94ae48d23279',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$At the August 2019 Allen City Council meeting on developer Wolverine Interests' Allen City Center plan — 800 apartment units on 12 acres in Allen's central business district — Schulmeister voted against advancing the project, and told Bisnow (September 2, 2019) that he did so because the "density of the apartments was just too much relative to the retail" proposed by the developers. In the same interview he affirmed multifamily development itself: "When you look at the census reports, we are in high growth mode for this area, and multifamily is what millennials are seeking and we have to be able to compete against neighboring cities," and said he wanted the developer to return with a revised plan better suited to the area rather than no project at all. Supporting multifamily and mixed-use in the downtown commercial core while voting down a specific plan for carrying more apartment density than its retail component could balance is the corridor-focused chair: he neither demanded strict character protection or a community vote, nor confined himself to duplex-and-accessory-unit scale increases, nor sought by-right multifamily approvals.$stz$,
        ARRAY['https://www.bisnow.com/dallas-ft-worth/news/multifamily/from-rage-to-city-council-gridlock-getting-multifamily-off-the-ground-is-no-simple-feat-in-america-100527']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
