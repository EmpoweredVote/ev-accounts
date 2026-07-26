-- =====================================================================================
-- Phase 222 (plan 222-07) — Compass stances: Town of Prosper, TX (geo_id 4859696),
--   City of Celina, TX (geo_id 4813684), City of Longview, TX (geo_id 4843888)
-- Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * Every chair seeded here rests on the officeholder's own first-person words in a
--     dated candidate questionnaire or dated local-press interview, on the exact axis the
--     compass topic measures. No party inference, no identity inference, no endorsement or
--     donor inference, no city-policy or state-law default, no adjacency inference (EDC /
--     chamber / P&Z / bond-committee service, profession, tenure, academy attendance),
--     no capital-project attribution, no defaulted middle value.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * TEXAS confirmed on every source used. The homonym gate was applied deliberately:
--     "Doug Charles", "Shea Scott", "Shane Lambert", "Shannon Moore", "Brandon Smith",
--     "John Nustad" and "Sidney Allen" are all common names, and "Sidney Allen" of
--     LONGVIEW must not be confused with the separate city of Allen, TX (covered by plan
--     222-05). Each person's identity was pinned to their seat on their own city's
--     official directory before any evidence was accepted as theirs.
--
-- SCOPE: the 8 un-stanced officeholders of these three cities on the 222-01 live worklist,
-- re-derived live against production by the orchestrator on 2026-07-25 at stance_count = 0.
--   Prosper  — Doug Charles     — Council Member Place 5   — 48500428-3421-4298-b618-613696ca644c
--   Celina   — Shea Scott       — Council Member Place 4   — 91128e4f-94f6-4119-8087-4449ee16964a
--   Celina   — Shane Lambert    — Council Member Place 5   — 2e8dc841-f8ea-42f0-b6a4-08e9c779a20e
--   Longview — Derrick Conley   — Council Member District 1 — c723b079-c7db-4376-b8d3-72ac896fefe2
--   Longview — Shannon Moore    — Council Member District 2 — d55159ff-7c27-4313-b464-722f653fd7b7
--   Longview — Brandon Smith    — Council Member District 3 — c6ec603a-3ba9-478b-a43d-35ef9bb5b0f0
--   Longview — John Nustad      — Council Member District 4 — 94957758-20db-4590-8cc9-ce54c24e2449
--   Longview — Sidney Allen     — Council Member District 6 — 2baab241-b3c5-48e9-b9a6-fd29b7b77beb
-- Longview is a GREGG County city bundled into the Texas browse list, not a Collin
-- government. Its 5 un-stanced officeholders exceed plan 222-07's own 3-person "ride
-- along" threshold; the operator decided on 2026-07-25 to keep Longview in 222-07 as an
-- 8-person plan rather than open a 19th plan. Longview's Mayor Kristen Ishihara (9 topics
-- held) and Jody Berryhill, District 5 (2 topics held) are already partially stanced and
-- are OUT OF SCOPE per D-07 — none of their rows was read, re-reasoned, or modified.
-- Every other seated Prosper and Celina officeholder likewise already holds stances and
-- is out of scope; this file touches none of their rows.
--
-- SEEDED (4 rows / 4 answer+context pairs across 3 people; 84 of the 88 attempted
-- (person, topic) pairs are honest blanks):
--   Shea Scott (Celina, 2)
--     economic-development    = 1  (his own March 16, 2026 contested-race candidate
--                                   questionnaire answers: "We must slow down
--                                   incentive-driven development and refocus our city's
--                                   budget on core infrastructure and public safety" and
--                                   "I will prioritize funding for essential services over
--                                   taxpayer incentives for private developers")
--     public-safety-approach  = 4  (his April 17, 2026 Star Local Media commitment, "I'll
--                                   advocate for data-driven staffing models tied to
--                                   response times, call volumes and competitive
--                                   salaries", plus his questionnaire finding that growth
--                                   "is outpacing our public safety resources")
--   Derrick Conley (Longview, 1)
--     homelessness            = 5  (his recorded Yes vote of May 23, 2024 on Ordinance
--                                   No. 4495 — see the Longview note below)
--   John Nustad (Longview, 1)
--     homelessness            = 5  (his recorded Yes vote of May 23, 2024 on Ordinance
--                                   No. 4495 — see the Longview note below)
-- Doug Charles (Prosper), Shane Lambert (Celina), Shannon Moore, Brandon Smith and
-- Sidney Allen (all Longview) yield NO rows at all — every one of their 11 topics is an
-- honest blank. Five of eight people ending fully blank is the expected, correct outcome
-- under D-04, not a research failure.
--
-- taxes (f7e5678d-dadd-4556-a2fc-446e24642ceb) — RESEARCHED FOR ALL 8 PEOPLE, NO CHAIR
--   WRITTEN FOR ANY OF THEM. Per the settled operator ruling of 2026-07-25
--   (222-RESEARCH.md §B; header of 1418_222_plano_gapfill_stances.sql), the taxes scale is
--   structurally unanswerable for a Texas municipal officeholder: chairs 1-2 require
--   raising taxes on wealthy people and large companies and chairs 4-5 require scaling
--   public services back, so chair 3 is the only reachable chair and carries no
--   discriminating information. Real tax material was found for several of these people —
--   Prosper's Charles on broadening the commercial tax base and on the Windsong Ranch PISD
--   annexation petition, Celina's Scott on the city's ~$1B debt load and its reliance on
--   non-voter-approved Certificates of Obligation, Celina's Lambert on property-tax
--   affordability — and all of it is preserved verbatim in 222-CONFIRMED-BLANK.md so it can
--   be placed if this question is ever rewritten with municipal scope. Utility, water and
--   wastewater rate positions are additionally refused as taxes evidence per the ruling
--   established in 222-06: those are fee decisions, not tax-and-spend positions, which
--   matters here because water-bill relief is a stated Lambert priority.
--
-- healthcare (e8dad4a8-eb93-4931-91f5-d8fb5d7dd529) — searched honestly for all 8 people
--   and blank for all 8. All five of its chairs describe national healthcare policy, which
--   a city council member holds no position on by role. No health-adjacent remark was
--   stretched into a chair.
--
-- DELIBERATELY BLANK: see 222-CONFIRMED-BLANK.md, sections "Town of Prosper (4859696) —
--   222-07", "City of Celina (4813684) — 222-07" and "City of Longview (4843888) —
--   222-07", for a per-(person, topic) explanation of every blank in this plan, including
--   the self-audit demotions listed below.
--
-- SELF-AUDIT DEMOTIONS (recorded, not hidden — a demotion is the contract working):
--   * Doug Charles / residential-zoning — NOT WRITTEN. A WebSearch summary attributed to
--     "Council Member Charles" both the motion approving the June 9, 2026 Bella Prosper
--     rezoning and the quote "I greatly appreciate the removal of the multifamily. That was
--     my large hesitation." The official Town of Prosper minutes for that meeting, read in
--     full, show the motion was Mayor Pro-Tem Bartley's (seconded by Deputy Mayor Pro-Tem
--     Kern) and the multifamily remark was Councilmember Marcus E. RAY's. Charles only
--     "shared their appreciation" and voted yes in a 6-0 tally. The misattributed chair was
--     rejected outright.
--   * Shea Scott / growth-and-development — DEMOTED TO BLANK. His evidence spans chair 2
--     ("We must slow down incentive-driven development"; growth is "unsustainable" and
--     "outpacing our public safety resources and infrastructure") and chair 3 ("a city where
--     infrastructure leads growth instead of chasing it"; "public safety is planned ahead of
--     growth, not responding after the fact") without resolving between them.
--
-- SOURCES THAT COULD NOT BE READ THIS SESSION (recorded so a later pass can retry, NOT
-- treated as absence of a position): every ballotpedia.org individual candidate page
-- attempted returned an EMPTY BODY (Doug Charles; Shea Scott 2026; Shane Lambert 2026) —
-- the known phase-wide Ballotpedia failure; starlocalmedia.com returned HTTP 429 on one
-- attempt; no VOTE411 / League of Women Voters of Collin County questionnaire was found for
-- any of these seats and lwvcollin.org has returned HTTP 403 all phase; the celinaradio.com
-- Shane Lambert interview (April 18, 2026) is audio-only with no transcript published, and
-- podcast audio is not readable by this pass; Community Impact's Celina Place 5 candidate
-- Q&A TRUNCATES three of Lambert's four answers mid-sentence with an ellipsis and the full
-- text could not be recovered from either URL variant; council meeting VIDEO on
-- prospertx.new.swagit.com and celinatx.new.swagit.com was not watched; campaign Facebook
-- pages were not fetched (Facebook is not fetchable here and social posts are not treated
-- as evidence of a policy position absent a direct citable quote). For Longview: the KLTV
-- 2024 District 1/District 2 candidate forum coverage and the celinaradio-style broadcast
-- items are video, not readable here; Longview's own official council-member pages carry
-- NO biography for Conley, Moore, Smith, Nustad or Allen, only a photo, an election date
-- and liaison assignments; no candidate questionnaire exists for Nustad (his 2026 District
-- 4 election was CANCELLED for lack of an opponent) or for Allen (unopposed in 2025, his
-- election likewise cancelled); and Allen's earlier nine years of council service ending
-- in 2016 were not mined, being too stale to bear on a 2025-2028 term.
--
-- ** LONGVIEW HOMONYM WARNING for any future pass. ** There is also a Longview,
-- WASHINGTON with its own city council, and searches for "Longview city council"
-- ordinance news return it freely. Specifically rejected this session: a tdn.com (The
-- Daily News, Longview WA) story headlined "Longview council narrowly OKs excessive
-- storage ordinance", quoting a "council member Ruth Kendall" — no such member sits on the
-- Longview TEXAS council, and that camping-ordinance-adjacent story is NOT about this
-- city. Also rejected: OPB, klog.com and longviewlibrary.org items about a Longview
-- council selecting a mayor and a "What Your City Council Accomplished in 2025" summary,
-- all Washington. Every Longview source relied on above was confirmed Texan by an
-- explicit marker — the Gregg County Tax Assessor-Collector, the Gregg County appraisal
-- district, the Jo Ann Metcalf Municipal Building, or the City of Longview, Texas seal.
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Town of Prosper, TX — Doug Charles, Council Member Place 5
-- politician_id: 48500428-3421-4298-b618-613696ca644c
-- ZERO ROWS. All 11 topics are honest blanks; see 222-CONFIRMED-BLANK.md. He took office
-- in May 2026 (unopposed, lone filer for Place 5), so only two months of council record
-- exists, and his campaign platform's policy language is generically evaluative
-- ("manage that growth wisely", "strengthen what makes Prosper special"). No row.
-- =====================================================================================

-- =====================================================================================
-- City of Celina, TX — Shea Scott, Council Member Place 4
-- politician_id: 91128e4f-94f6-4119-8087-4449ee16964a
-- Won Place 4 on May 2, 2026 with 907 votes (~51%) against Katie Dunn's 875 (~49%).
-- Both chairs below rest on his own first-person answers in dated, contested-race
-- candidate questionnaires published BEFORE that election, on the exact axis each topic
-- measures. 2 rows.
-- =====================================================================================

-- ----- Shea Scott / economic-development (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91128e4f-94f6-4119-8087-4449ee16964a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('91128e4f-94f6-4119-8087-4449ee16964a',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $stz$In his answers to Community Impact Newspaper's Celina City Council Place 4 candidate questionnaire, published March 16, 2026 during a contested race he went on to win, Scott twice took an explicit position against municipal subsidy of private development and for spending that money on services and infrastructure instead. Asked how he would address the challenges facing Celina, he answered: "We must slow down incentive-driven development and refocus our city's budget on core infrastructure and public safety." Asked for his top priorities, he answered: "I will prioritize funding for essential services over taxpayer incentives for private developers." On his campaign site he frames the same principle as prioritising "essential services and infrastructure before vanity projects." That is the no-incentives chair: he proposes to attract investment by funding core infrastructure and services rather than by offering abatements or grants, and he has never proposed targeted incentives carrying community-benefit or job-quality conditions, aggressive competition for major employers, or a small-business-only incentive program. Recorded as a complicating datum rather than as support: on July 14, 2026 he was one of two council members to vote against a $3.05M economic development agreement for the Trackside Junction downtown mixed-use project (city land worth about $1M sold for $1, a $1.7M TIRZ No. 11 grant and a $350K Celina EDC grant), but his stated objection was narrow — "I am not against the project. I think it's great, but I have a problem with a very small portion of the project that needs to be worked out," referring to an 18-space parking-lot lease on Louisiana Drive — so the vote is consistent in direction with the chair but is not the basis for it. His 27 years in law enforcement, including service as Celina's assistant police chief, were deliberately not used for any topic: profession and tenure are adjacency, not positions.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/16/qa-meet-the-candidates-running-for-celina-city-council-place-4/',
              'https://communityimpact.com/prosper-celina/development/celina-council-approves-3m-incentive-package-for-downtown-mixed-use-development/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shea Scott / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('91128e4f-94f6-4119-8087-4449ee16964a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('91128e4f-94f6-4119-8087-4449ee16964a',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $stz$Scott ran on increasing Celina's police staffing and pay to bring response times into line with a fast-growing city. In Star Local Media's Celina Record candidate profile of April 17, 2026 he committed specifically: "I'll advocate for data-driven staffing models tied to response times, call volumes and competitive salaries," adding "I see a city where public safety is planned ahead of growth, not responding after the fact." In Community Impact's March 16, 2026 Place 4 questionnaire he identified as a top challenge that Celina's "rapid expansion is outpacing our public safety resources and infrastructure," and pledged to "refocus our city's budget on core infrastructure and public safety" and to ensure "public safety and infrastructure keep pace with growth." Advocating more officers and higher police pay explicitly in order to improve response times is the increase-staffing-equipment-and-pay chair. He has proposed no crisis-response team, no unarmed mental-health co-responder program and no shift of non-violent calls away from police, which is what would have located the middle chairs, and he has not proposed redirecting any part of the police budget to social services. Nor is this the top-priority-above-all-other-services chair: he pairs public safety with core infrastructure throughout, and the spending he would deprioritise is taxpayer incentives to private developers, not other municipal services. His 27 years in law enforcement and his service as Celina's assistant police chief were deliberately NOT used to set this value — profession is adjacency, and the chair rests only on his own stated budget and staffing commitments.$stz$,
        ARRAY['https://starlocalmedia.com/celinarecord/news/election-2026-2-candidates-vying-for-celina-place-4-seat/article_44da37a9-14c9-4ce0-990a-0adfd1577ec6.html',
              'https://communityimpact.com/dallas-fort-worth/prosper-celina/election/2026/03/16/qa-meet-the-candidates-running-for-celina-city-council-place-4/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- City of Celina, TX — Shane Lambert, Council Member Place 5
-- politician_id: 2e8dc841-f8ea-42f0-b6a4-08e9c779a20e
-- ZERO ROWS. All 11 topics are honest blanks; see 222-CONFIRMED-BLANK.md. Won Place 5 on
-- May 2, 2026 with 1,211 votes (69%) against Brent Baty's 543 (31%). His only substantive
-- source is Community Impact's March 16, 2026 Place 5 questionnaire, three of whose four
-- answers are truncated mid-sentence by the publisher, and his surviving policy language
-- ("Responsible growth means", "Thoughtful incentives", "properly managing our growth
-- while preserving our small town charm") is generically evaluative. His nearly two years
-- on the Celina EDC were deliberately not used — board service is adjacency. No row.
-- =====================================================================================

-- =====================================================================================
-- City of Longview, TX (Gregg County) — the shared evidentiary basis for the two chairs
-- seeded below, stated once so each row's reasoning need not repeat it.
--
-- On May 23, 2024 the Longview City Council adopted Ordinance No. 4495, "AN ORDINANCE ...
-- ADDING A NEW ARTICLE VIII TO CHAPTER 58 OF THE LONGVIEW CITY CODE REGARDING SLEEPING
-- OUTSIDE ON PRIVATE PROPERTY; PROVIDING FOR THE IMPOSITION OF A CRIMINAL PENALTY NOT TO
-- EXCEED $2,000 FOR EACH VIOLATION". Longview's code already prohibited camping in the
-- city and sleeping on public property; this ordinance extended the prohibition to
-- sleeping outside on PRIVATE property and attached a criminal penalty. It contains no
-- graduated-warning scheme and no requirement that the city maintain shelter capacity.
--
-- The vote was CONTESTED and recorded by name in the official city minutes:
--   MOTION: Council Member Pirtle.  SECOND: Council Member Gamboa.
--   Conley Yes · Moore No · Wade No · Nustad Yes · Gamboa Yes · Pirtle Yes · Ishihara Yes
--   "The motion carried (5, 2)."
-- Eight citizens spoke against the ordinance at that same meeting, including one who told
-- the council she has cancer and cannot use a shelter for medical reasons, and two spoke
-- for it on behalf of area businesses. Municipal-court charges were subsequently filed
-- against the executive director of the nonprofit One Love Longview for allowing clients
-- to sleep in front of its building at 1015 McCann Road; the city attorney's office moved
-- to dismiss them "in the interest of justice" in January 2026.
--
-- This is a recorded council vote on an ordinance whose entire subject matter is the
-- question the `homelessness` topic asks, decided by a divided roll call in which two
-- members voted the other way — so a Yes vote is a genuine, dated, individually-recorded
-- choice, which D-04 accepts ("a stated position, recorded vote/motion, or
-- candidate-questionnaire answer"). It is NOT the refused defect class of a generic
-- UNANIMOUS approval with no stated reason. Neither member seeded below is individually
-- quoted on the item, and each reasoning says so explicitly rather than implying a quote.
--
-- Direction check against the inversion-trap table for topic_key `homelessness`:
-- 1 = housing-first / no criminalization, 5 = enforcement and camping bans — "camping ban
-- authors get HIGH scores". Chair 5 ("Banning public camping and sleeping with criminal
-- penalties to maintain public safety and order, relying on existing social services for
-- those who seek help") is the correct chair, not chair 4, because chair 4 requires
-- graduated warnings and a jurisdictional obligation to maintain basic shelter options and
-- Ordinance 4495 provides neither; if anything the ordinance reaches further than chair 5
-- describes, since it covers private as well as public property.
--
-- Sidney Allen and Brandon Smith did NOT take part in this vote and receive no row from
-- it: the May 23, 2024 minutes record the council as Ishihara, Conley, Moore, Wade,
-- Nustad, Gamboa and Pirtle. Allen returned to District 6 in May 2025 and Smith won
-- District 3 in a June 13, 2026 runoff. Shannon Moore's recorded NO vote is real evidence
-- of direction but is not chair-locating on its own and was left blank — see
-- 222-CONFIRMED-BLANK.md for that reasoning.
-- =====================================================================================

-- =====================================================================================
-- City of Longview, TX — Derrick Conley, Council Member District 1
-- politician_id: c723b079-c7db-4376-b8d3-72ac896fefe2
-- Elected May 2024 (227 votes, 58.21%, over Jim Cogar and Arthur Carter), succeeding
-- Temple "Tem" Carpenter; term expires May 2027. 1 row.
-- =====================================================================================

-- ----- Derrick Conley / homelessness (value 5) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $stz$On May 23, 2024, at the same meeting at which he was sworn in to the District 1 seat, Conley voted Yes on Longview Ordinance No. 4495, which added Article VIII to Chapter 58 of the city code to prohibit sleeping outside on private property and imposed a criminal penalty of up to $2,000 per violation. The city already banned camping and sleeping on public property, so the effect of his vote was to close the remaining place a person could lawfully sleep outdoors in Longview, and the ordinance requires no graduated warnings and obliges the city to maintain no shelter capacity. The official minutes record the roll call by name — Conley Yes, Moore No, Wade No, Nustad Yes, Gamboa Yes, Pirtle Yes, Ishihara Yes, carried 5 to 2 — so this was a contested choice rather than a formality: eight residents spoke against the ordinance that night, one of them explaining that she has cancer and cannot use a shelter for medical reasons, and the council adopted it anyway. Charges were later filed in municipal court against the director of the nonprofit One Love Longview for letting clients sleep in front of its building, and dropped in January 2026. Conley is not individually quoted on the item in the minutes or in the Longview News-Journal's coverage of it; this chair rests on his recorded vote, not on a paraphrase of one. Banning public camping and sleeping outright, backed by criminal penalties and with no accompanying shelter guarantee, is the fifth chair; he has advocated no shelter-availability precondition on enforcement, no diversion of citations to services, and no decriminalization.$stz$,
        ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_05232024-1872',
              'https://www.news-journal.com/news/local/longview-council-votes-to-strengthen-rules-on-camping-in-city/article_619ae128-197c-11ef-b408-3b96fa3c1993.html',
              'https://news-journal.com/2026/01/01/city-drops-charges-against-one-love-longview-director-related-to-anti-camping-ordinance/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- City of Longview, TX — John Nustad, Council Member District 4
-- politician_id: 94957758-20db-4590-8cc9-ce54c24e2449
-- Elected May 2023; declared re-elected unopposed on March 6, 2026 when no one else filed
-- and the District 4 election was cancelled. 1 row.
-- =====================================================================================

-- ----- John Nustad / homelessness (value 5) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        5)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $stz$Nustad, a sitting District 4 member since May 2023, voted Yes on May 23, 2024 on Longview Ordinance No. 4495, which added Article VIII to Chapter 58 of the city code to prohibit sleeping outside on private property and imposed a criminal penalty of up to $2,000 per violation. Because Longview already prohibited camping and sleeping on public property, his vote extended the ban to the last outdoor place a person could lawfully sleep in the city; the ordinance sets out no graduated-warning process and imposes no obligation on the city to maintain shelter beds. The official minutes record the roll call by name — Conley Yes, Moore No, Wade No, Nustad Yes, Gamboa Yes, Pirtle Yes, Ishihara Yes, carried 5 to 2 — so his was a contested, individually-recorded choice taken over the objection of eight residents who spoke against it at that meeting, one of whom said a medical condition prevented her from using a shelter. Municipal-court charges were subsequently brought against the director of the nonprofit One Love Longview for allowing clients to sleep in front of its building, and dismissed in January 2026. Nustad is not individually quoted on the item in the minutes or in the Longview News-Journal's coverage; this chair rests on his recorded vote and nothing more. An outright ban on public camping and sleeping enforced through criminal penalties, with reliance on whatever social services already exist, is the fifth chair; he has proposed no shelter-availability precondition, no citation-to-services diversion, and no decriminalization.$stz$,
        ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_05232024-1872',
              'https://www.news-journal.com/news/local/longview-council-votes-to-strengthen-rules-on-camping-in-city/article_619ae128-197c-11ef-b408-3b96fa3c1993.html',
              'https://news-journal.com/2026/01/01/city-drops-charges-against-one-love-longview-director-related-to-anti-camping-ordinance/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- City of Longview, TX — Shannon Moore (District 2), Brandon Smith (District 3),
--   Sidney Allen (District 6)
-- politician_ids: d55159ff-7c27-4313-b464-722f653fd7b7,
--                 c6ec603a-3ba9-478b-a43d-35ef9bb5b0f0,
--                 2baab241-b3c5-48e9-b9a6-fd29b7b77beb
-- ZERO ROWS for all three. All 33 of their (person, topic) pairs are honest blanks; see
-- 222-CONFIRMED-BLANK.md for each.
--   Moore  — her recorded NO vote on Ordinance 4495 establishes she opposed criminalising
--            sleeping outside on private property, but no stated reason was found in any
--            source, and a No vote alone cannot separate chair 1 (right to sleep in public,
--            redirect enforcement budgets), chair 2 (decriminalise and invest in shelter),
--            and chair 3 (enforce only when shelter beds are available). She has not sought
--            repeal of Longview's pre-existing public-camping ban. Blank, not defaulted.
--   Smith  — took office after a June 13, 2026 runoff (223 votes, 52.22%, over Marlena
--            Cooper's 204); roughly six weeks of tenure and no votes on any compass topic.
--            His campaign material is about potholes, street lighting and park restrooms.
--   Allen  — returned to District 6 in May 2025 after nine earlier years that ended in 2016
--            under term limits, unopposed (his election was cancelled). Everything he is
--            recorded saying this session is fee ratemaking — fire-department lift-assist
--            charges, the Maude Cobb nonprofit discount, credit-card processing fees, water
--            and trash rates — which the 222-06 ruling refuses as taxes evidence and which
--            locates no other chair.
-- =====================================================================================

COMMIT;
