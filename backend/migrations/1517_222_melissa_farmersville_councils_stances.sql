-- =====================================================================================
-- Phase 222 (plan 222-12) — Compass stances: City of Melissa, TX (geo_id 4847496)
--                            + City of Farmersville, TX (geo_id 4825488) councils
-- Authored 2026-07-30.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * AUDIT-ONLY: no migration runner exists; this file records SQL applied by hand via
--     mcp__supabase-local__execute_sql. It touches only inform.politician_answers and
--     inform.politician_context.
--   * Number 1507 claimed live 2026-07-30 (then max 1505); renumbered 1517 after origin/master shipped its own 1507. Phase 222 now claims the 1516-1525 band with headroom against the racing counter. This
--     phase's earlier file was renumbered 1503 -> 1506 -> 1516 after concurrent sessions shipped
--     its own 1503 — always re-check the live max before claiming.
--   * The single chair seeded here rests on a RECORDED LEGISLATIVE PATTERN in
--     Farmersville's official council minutes — motions Henry personally made, with
--     stated density reasoning, spanning 2021-2025 — recovered by OCR (all 133 minutes
--     PDFs are RICOH scanner images with no text layer; Tesseract 5 at 200 dpi, decisive
--     documents re-OCR'd independently at 300 dpi, plus an orchestrator-side independent
--     OCR of media/5221 confirming the MF-2/MF-1 density-reduction proposal verbatim).
--     No party inference, no adjacency, no defaulted middle value.
--   * MELISSA: ALL BLANK — 66 of 66 (person, topic) pairs settled honest blanks across
--     all 6 council members (Taylor, Hendrickson, Conklin, Armstrong, Ackerman, Lehr).
--     Melissa's 2025-26 minutes are action-only ("There was no Council discussion."),
--     the city publishes no officeholder bios, and all 48 prior 2026-05-12 found-nothing
--     notes were independently corroborated. NO Melissa rows below.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and
--     are logged per (person, topic) in 222-CONFIRMED-BLANK.md (Count 564 -> 630 -> 684).
--   * Farmersville, TEXAS (Collin County) confirmed on every source used (Farmersville
--     CA is a real homonym city and was excluded). Identity traps rejected this pass:
--     ballotpedia.org/Mike_Henry (a Virginia political operative), "Benny Mondy" of the
--     Texoma Housing Partners Board (NOT Councilmember Kristi Mondy).
--
-- SCOPE: the 6 un-stanced Melissa + 5 un-stanced Farmersville council members on the
-- 222-01 live worklist (mayors excluded — covered in 222-08). Live-verified 2026-07-30:
-- all 11 ids at 0 answer rows.
--
-- SEEDED (1 row / 1 answer+context pair):
--   Mike Henry (Farmersville Place 4)
--     residential-zoning        = 3  (allow multifamily/mixed-use near commercial
--                                     corridors while protecting most residential zones)
--     Chair 3 located, not defaulted: 5 excluded by his motions to deny two SF-2-to-
--     duplex rezonings (Apr 7, 2025, both denied 4-0); 4 excluded by his citywide
--     multifamily DOWNZONING (proposed Jun 8, 2021; adopted via his motion Feb 8, 2022,
--     Ordinance O-2022-0208-001, MF-2 24->18 u/ac & 4->3 stories, MF-1 18->12 & 3->2,
--     5-0); 2 excluded because chair 2's defining vehicle is the duplex and he moved/
--     seconded denial of both; 1 excluded on both clauses (no voter-approval mechanism;
--     moved approval of a 350-unit MF planned development). Both halves of chair 3
--     affirmatively supported: moved approval of the 37-acre SH-78/US-380 commercial+
--     multifamily PD with a 350-unit cap "in order to control the density" (Apr 28,
--     2021); seconded denial of a 240-unit standalone apartment rezone "due to density
--     concerns" (May 25, 2021).
--     NOTE: minutes paraphrase in third person — no verbatim quote is claimed. BoxCast
--     council video is the named path to a quotable sentence.
--
-- ⚠ PITFALL-5 TRIGGER #2: Farmersville is at ZERO stances with NO coverage chip. This
--   row moves it 0 -> 1; 222-18 must flip hasContext: true for geo_id 4825488 in
--   src/lib/coverage.js (joining Fairview 4825224 from 222-11).
--
-- taxes — researched, NO CHAIR WRITTEN for any person, per the settled operator ruling
--   of 2026-07-25 (222-RESEARCH.md §B).
--
-- DELIBERATELY BLANK (120 person/topic pairs — see 222-CONFIRMED-BLANK.md):
--   Melissa 66 (all settled, structural: action-only minutes, no bios, no Ballotpedia
--   pages, homelessness/immigration/civil-rights structurally absent from the corpus).
--   Farmersville 54 (all settled — the harder class: OCR'd minutes narrate member-
--   attributed speech, but Strickland's 656 quoted lines are fiscal/process, Chandler's
--   "not penalize but incentivize" is one negotiation, Mondy has 13 months of liaison
--   reports, Fox's homelessness co-sponsorship specifies no enforcement mechanism, and
--   Henry's other 10 topics have no explicit on-axis position).
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Mike Henry — Council Member Place 4, City of Farmersville, TX
-- politician_id: 5712d682-ffd5-4e6d-afa8-9707613fd838
-- On council continuously across the cited 2021-2025 window (attendance lines confirm
-- presence at every cited meeting).
-- =====================================================================================

-- ----- Mike Henry / residential-zoning (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5712d682-ffd5-4e6d-afa8-9707613fd838',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5712d682-ffd5-4e6d-afa8-9707613fd838',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$On June 8, 2021 Henry personally proposed reducing Farmersville's citywide multifamily density and height limits — MF-2 from 24 to 18 units per acre and four stories to three, MF-1 from 18 to 12 units per acre and three stories to two — and on February 8, 2022 he made the motion adopting Ordinance O-2022-0208-001, which amended Chapter 77 §77-52 to enact exactly that (5-0). He moved to deny two SF-2-to-duplex rezonings on April 7, 2025 (111 Wilcoxson St and 201 Neathery St, both denied 4-0), and on April 28, 2021 he moved to approve a 37-acre planned development combining commercial with multifamily at the State Highway 78 / U.S. 380 quadrant only with a 350-unit cap "in order to control the density," while seconding the denial of a 240-unit standalone apartment rezone "due to density concerns" on May 25, 2021. That record allows multifamily and mixed use at commercial corridors at capped density while keeping established single-family neighborhoods single-family.$stz$,
        ARRAY['https://www.farmersvilletx.com/media/5221',
              'https://www.farmersvilletx.com/media/5041',
              'https://www.farmersvilletx.com/media/8396',
              'https://www.farmersvilletx.com/media/5261',
              'https://www.farmersvilletx.com/media/5291',
              'https://www.farmersvilletx.com/media/5231',
              'https://www.farmersvilletx.com/media/5071']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
