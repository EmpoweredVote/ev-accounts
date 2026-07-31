-- =====================================================================================
-- Phase 222 (plan 222-13) — Compass stances: City of Parker, TX (geo_id 4855152)
--                            + City of Lucas, TX (geo_id 4845012) councils
-- Authored 2026-07-30.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * AUDIT-ONLY: no migration runner exists; this file records SQL applied by hand via
--     mcp__supabase-local__execute_sql. It touches only inform.politician_answers and
--     inform.politician_context.
--   * Number 1518 from the phase's 1516-1525 headroom band (claimed 2026-07-30 after two
--     same-day prefix collisions with a concurrent session pushed the live max to 1507;
--     phase files: 1516 = 222-11 Fairview/Princeton, 1517 = 222-12 Melissa/Farmersville).
--   * All three chairs here rest on the officeholders' OWN campaign-platform statements
--     (the Kuykendall/Works/Sharpe statement class: explicit low-density preservation via
--     zoning), each read on the live source AND independently re-fetched by the
--     orchestrator with every operative phrase confirmed verbatim. No party inference,
--     no adjacency, no defaulted middle value.
--   * Parker, TEXAS and Lucas, TEXAS (Collin County) confirmed on every source used.
--     Traps rejected this pass include: the Restore-the-Grasslands file (City-Attorney-
--     authored; Pilgrim/Bogdan appear as the city's designated speakers — representation,
--     not personal positions — refused by the same rule that protected Mayor Pettle in
--     222-08); a WebSearch summary that FABRICATED a Colleen Halbert biography from a
--     Murphy councilmember; unattributable Swagit CC transcripts (no speaker labels);
--     "Orr" as a Lucas street name in 60+ paving items.
--
-- SCOPE: the 5 un-stanced Parker + 6 un-stanced Lucas council members on the 222-01
-- live worklist (mayors excluded — covered in 222-08). Live-verified 2026-07-30: all 11
-- ids at 0 answer rows, 0 context rows.
--
-- SEEDED (3 rows / 3 answer+context pairs — all residential-zoning):
--   Darrel Sharpe (Parker Place 4)      = 1  (2025 platform: named defense of the 2-acre
--                                             minimum with infrastructure reasoning;
--                                             "Maintaining low density / large lot sizes";
--                                             chair 2 excluded — he opposes ANY increase)
--   Jonathan Underhill (Lucas Place 1)  = 1  (April 20, 2026 Ballotpedia Candidate
--                                             Connection survey: "I stand firmly against
--                                             high-density development"; proposes no
--                                             density increase of any kind)
--   Rebecca B. Orr (Lucas Place 2)      = 1  (rebeccaorr.us: "I will never vote to add
--                                             sewer to the City of Lucas. Sewer leads to
--                                             higher costs, higher density, and loss of
--                                             who we are" — forecloses the precondition
--                                             for any density increase, with reasoning)
--   Shared honest limitation, flagged for operator review: chair 1's "require community
--   votes before any rezoning" clause is in none of the three platforms; each mapping
--   rests on chair 1's dominant strict-preservation proposition with chair 2 affirmatively
--   contrary (the Works/Kuykendall precedent, now applied five times phase-wide).
--
-- ⚠ PITFALL-5 TRIGGERS #3 AND #4: Parker (4855152) and Lucas (4845012) are BOTH at zero
--   stances with no coverage chip. These rows move each 0 -> 1; 222-18 must flip
--   hasContext: true for both (joining Fairview 4825224 and Farmersville 4825488).
--
-- taxes — researched, NO CHAIR WRITTEN for any person (operator ruling 2026-07-25).
--
-- DELIBERATELY BLANK (118 person/topic pairs — see 222-CONFIRMED-BLANK.md, Count 738 ->
--   802 after Lucas; Parker took it 684 -> 738):
--   Parker 54 (all settled): Bogdan 11, Halbert 11, Pilgrim 11, Barron 11, Sharpe 10.
--     Near-misses refused: Sharpe/growth (chairs 2 and 3 inseparable — never pick the
--     middle), Sharpe/public-safety (facilities = capital project), Barron/transportation
--     (pulls both ways), Bogdan/public-safety (unexplained LPR motion + a who-decides
--     objection), Halbert/residential-zoning (clerical amendments).
--   Lucas 64 (all settled): Underhill 10, Orr 10, Bierman 11, Lawrence 11, Fisher 11,
--     Peterson 11. Near-misses refused: Underhill/public-safety (chairs 3 and 4
--     inseparable; implementing a department created before his seating = note 16),
--     Orr/growth (chairs 1 and 2 inseparable), Fisher x4 (drainage metric, factual
--     premise, neighboring city's project, a $20 vendor fee), Lawrence/trails (process
--     condition, not a modal priority).
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Darrel Sharpe — Council Member Place 4, City of Parker, TX
-- politician_id: aba6f016-e35d-4977-99e6-a2cfc079ad75
-- Elected at-large May 3, 2025 (canvassed May 13, 2025, 401 votes). The cited platform
-- is the one on which he was elected; his subsequent land-use votes are consistent.
-- =====================================================================================

-- ----- Darrel Sharpe / residential-zoning (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aba6f016-e35d-4977-99e6-a2cfc079ad75',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aba6f016-e35d-4977-99e6-a2cfc079ad75',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$In the 2025 campaign platform on which he was elected to the Parker City Council at-large on May 3, 2025, Sharpe listed "Maintaining low density / large lot sizes" and "Keeping Parker 'Parker'" among the issues he cares about most, and defended the city's existing standard by name and with reasons: "Minimum Lot Sizes. The 2 acre minimum helps preserve the feel of our city, limits the ongoing impact on our water and road infrastructure and helps alleviate the impact of rapid growth occurring all around us. This lot size restriction is a big reason why Parker maintains a small, country feel." He frames lot-size regulation as the tool "to keep the living conditions we cherish while this development continues." Every land-use vote he has cast since taking office subdivides land already zoned single-family at Parker's 2.0-acre code minimum; he has voted for no upzoning, no multifamily and no reduction of a lot-size floor.$stz$,
        ARRAY['https://www.sharpeforparker.com/the-issues-1',
              'https://www.sharpeforparker.com/',
              'https://ballotpedia.org/Darrel_Sharpe_(Parker_City_Council_At-large,_Texas,_candidate_2025)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Jonathan Underhill — Council Member Place 1, City of Lucas, TX
-- politician_id: 4ad7d4e3-c0d2-4b7a-bc32-a8b3f41551a0
-- Elected May 2, 2026 (oath May 21, 2026). The cited survey (April 20, 2026) and
-- campaign site (April 12, 2026) are the platform on which he was elected.
-- =====================================================================================

-- ----- Jonathan Underhill / residential-zoning (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4ad7d4e3-c0d2-4b7a-bc32-a8b3f41551a0',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4ad7d4e3-c0d2-4b7a-bc32-a8b3f41551a0',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$In the Ballotpedia Candidate Connection survey he completed on April 20, 2026 for the May 2, 2026 Lucas City Council Seat 1 election, Underhill wrote that "While growth and densification continue across DFW, Lucas is uniquely defined by its rural feel, and I am dedicated to protecting that legacy" and that "I stand firmly against high-density development that threatens our community's identity," repeating in answer to a separate question that he is "passionate about protecting the unique character of Lucas through smart land-use policies" and that "this means standing firmly against high-density development." His campaign website (April 12, 2026) adds that new development must serve the community "without negatively impacting the peace and privacy of our neighbors." He proposes no density increase of any kind — not multifamily, not duplexes, not accessory units — which places him at the strict-protection end of this scale rather than at the modest-increase chair. As a voting Planning and Zoning member on February 12, 2026 he took part in the unanimous approval of a rezoning to single-family one-acre lots, consistent with, not contrary to, that platform.$stz$,
        ARRAY['https://ballotpedia.org/Jonathan_Underhill_(Lucas_City_Council_Seat_1,_Texas,_candidate_2026)',
              'https://underhillforcitycouncil.carrd.co/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Rebecca B. Orr — Council Member Place 2, City of Lucas, TX
-- politician_id: 3c839111-ed39-41fd-8e63-9c81b1e3e591
-- Elected May 2, 2026 (oath May 21, 2026). rebeccaorr.us is her own campaign site,
-- quoted verbatim by Ballotpedia as of April 13, 2026.
-- =====================================================================================

-- ----- Rebecca B. Orr / residential-zoning (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c839111-ed39-41fd-8e63-9c81b1e3e591',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c839111-ed39-41fd-8e63-9c81b1e3e591',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$On her campaign website for the May 2, 2026 Lucas City Council Seat 2 election — live at rebeccaorr.us and quoted verbatim by Ballotpedia as of April 13, 2026 — Orr wrote "Lucas is known for our large lots and open spaces, and that is core to the identity of Lucas" and, asked what she thinks of adding sewer, "I will never vote to add sewer to the City of Lucas. Sewer leads to higher costs, higher density, and loss of who we are as the City of Lucas." Lucas has no municipal sewer and its one- and two-acre minimum lot sizes follow from septic requirements, so this is a categorical commitment against the change that would permit higher density, stated with her own reasoning attached. She also writes that she wants "to preserve Lucas's rural character" and to keep the town "still recognizable 20 years from now." Because she forecloses the precondition for any density increase, this is the strict-protection end of the scale rather than the modest-increase chair.$stz$,
        ARRAY['https://rebeccaorr.us/',
              'https://ballotpedia.org/Rebecca_B._Orr_(Lucas_City_Council_Seat_2,_Texas,_candidate_2026)']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
