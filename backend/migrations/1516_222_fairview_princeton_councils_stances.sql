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
-- PRINCETON SEEDED (2 rows / 2 answer+context pairs):
--   Cristina Todd (Place 2)
--     growth-and-development    = 2  (Princeton Herald, June 23, 2025: absent from the
--                                     meeting but "sent a message that she supported the
--                                     second extension" of Princeton's citywide residential
--                                     development moratorium — suspend approvals until
--                                     infrastructure/services catch up = the
--                                     infrastructure-gated chair)
--     Operator flag: the Herald records the fact of her support, not her personal
--     reasoning — if a relayed absentee support-message is ruled insufficient, strike the
--     row; the register preserves the evidence either way. Overwrites NO prior note (her
--     2026-05-12 found-nothing rows cover the 8 Local Lens topics; growth-and-development
--     is not among them — verified live 2026-07-30).
--   Bryan Washington (Place 3, Mayor Pro Tem)
--     public-safety-approach    = 4  (his 2023 re-election site wash4council.com: first
--                                     term saw him "a strong proponent of starting salary
--                                     increases for our police and fire" — explicit
--                                     advocacy of increased public-safety pay = chair 4;
--                                     not chair 5, no top-priority claim)
--     LAVINE-PRECEDENT UPGRADE, replacing his 2026-05-12 found-nothing note on this topic.
--     Verified legitimate 2026-07-30: that note says it "checked wash4council.com", but
--     the site is a Square Online SPA serving an EMPTY SHELL to curl/WebFetch — the prior
--     pass could not have read the content. Recovered this pass via headless render +
--     the embedded JSON in the raw HTML (both methods, sentence confirmed verbatim).
--     Operator flags: third-person campaign voice; police bundled with fire. The bundled
--     EDC-expansion clause in the same sentence was NOT used (adjacency).
--
-- PRINCETON DELIBERATELY BLANK (31 person/topic pairs — see 222-CONFIRMED-BLANK.md):
--   Cristina Todd (Place 2):      10 settled; all 8 Local Lens blanks independently
--                                 corroborate her 2026-05-12 found-nothing notes. Refused:
--                                 budget dissent (fiscal-capacity lament, reporter's
--                                 bracket), TIRZ/PID critique (no incentive mechanism),
--                                 P&Z liaison (adjacency), drainage (maintenance). Her
--                                 explained FY26 budget/rate Nay is preserved in the
--                                 register for any future municipal taxes rewrite.
--   Bryan Washington (Place 3):   10 settled, corroborating 7 of his 8 prior notes (the
--                                 8th is the upgrade above). His June 23, 2025 moratorium
--                                 Aye (6-0) is unexplained — refused; "strategic growth
--                                 planning" = generic; EDC structure = adjacency.
--   Jaisen Rutledge (Place 4):    11 settled (seated mid-June 2026 after the runoff; no
--                                 prior notes). Refused: LWV forum "understaffed" +
--                                 "look at our budgeting" (compatible with chairs 3, 4,
--                                 and reallocation alike; forum video named as retry
--                                 path); "commercial growth, not just residential" = the
--                                 refused commercial-tax-base class.
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

-- =====================================================================================
-- Cristina Todd — Council Member Place 2, City of Princeton, TX
-- politician_id: 3c8d7283-2387-47ff-8a29-1ef7a1e2a554
-- Elected November 5, 2024; sworn in November 18, 2024. The June 23, 2025 moratorium
-- extension falls inside her tenure.
-- =====================================================================================

-- ----- Cristina Todd / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c8d7283-2387-47ff-8a29-1ef7a1e2a554',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $stz$Though absent from the June 23, 2025 council meeting, Todd sent a message — reported by the Princeton Herald — that she supported the second extension of Princeton's residential development moratorium, which suspended acceptance, permits and approvals for residential development citywide and in the ETJ so the fast-growing city's infrastructure and public services could catch up (the city cited "reasonable, yet insufficient" progress preventing a shortage of essential public services). Supporting continued suspension of residential approvals until capacity catches up aligns with allowing growth only where existing infrastructure can support it.$stz$,
        ARRAY['https://princetonherald.com/2025/06/23/housing-moratorium-extended/',
              'https://www.princetontx.gov/AgendaCenter/ViewFile/Minutes/_06232025-1370']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Bryan Washington — Council Member Place 3 (Mayor Pro Tem), City of Princeton, TX
-- politician_id: e40be594-2239-4c28-a8ac-d4f86c6d4180
-- Elected November 2020; re-elected November 7, 2023. The cited first-term record
-- (2020–2023) falls inside his tenure. This row REPLACES his 2026-05-12 found-nothing
-- context note on this topic (Lavine-precedent upgrade — see file header).
-- =====================================================================================

-- ----- Bryan Washington / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e40be594-2239-4c28-a8ac-d4f86c6d4180',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $stz$His 2023 re-election campaign website states that during his first term (2020–2023) he was "a strong proponent of starting salary increases for our police and fire," an explicit first-party advocacy of increasing public-safety compensation, consistent with increasing police pay as a city budget priority. No statement of his supports redirecting public-safety funding or holding it level.$stz$,
        ARRAY['https://www.wash4council.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
