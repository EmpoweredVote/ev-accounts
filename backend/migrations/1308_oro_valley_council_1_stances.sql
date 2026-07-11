-- =====================================================================================
-- Compass stances: Melanie Barrett — Oro Valley (AZ) Town Council, current Vice Mayor
-- politician_id: c33b6be0-1192-4483-9343-28084a0f947d
-- Nonpartisan; on Town Council ~8 years (elected Aug 2018 on a slower-growth slate),
-- current Vice Mayor, and the 2026 candidate for Mayor (campaign site melaniebarrett.org).
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * Every seeded topic is backed by a documented, attributable position (recorded Council
--     vote/motion, on-record statement, or a clear 2026 mayoral-campaign platform position),
--     naming the vote/statement/date in the reasoning, with real cited source URLs confirmed
--     via web research (all URLs below were actually fetched).
--   * Topics with no clear documented Barrett position emit NO row (honest blank). No party
--     inference (she is nonpartisan), no neutral defaults.
--   * This file is AUDIT-ONLY / unregistered (no migration-ledger entry). It touches only
--     inform.politician_answers and inform.politician_context. The orchestrator applies it.
--
-- SEEDED (6 topics):
--   data-centers            = 1  (against data centers in/adjacent to OV; will review Town
--                                 Code to block them — most-restrictive available chair)
--   growth-and-development  = 2  (elected 2018 on slower-growth platform; "responsible and
--                                 reasonable development"; managed/cautious growth posture)
--   local-environment       = 2  (platform: protect open spaces/views; cites Vistoso golf
--                                 course "saved from extensive development")
--   public-safety-approach  = 4  (police "supported and funded"; fixed $27M police-pension
--                                 liability to 100%; new police HQ a stated priority)
--   residential-zoning      = 2  (May 6 2026 motion capping Rooney Wash townhouses at 30 ft —
--                                 modest, design-constrained density)
--   taxes                   = 3  (Jan 14 2026: voted against all three proposed tax increases,
--                                 "there is time before this becomes a crisis"; no town
--                                 property tax — keep current low-tax structure as-is)
--
-- DELIBERATELY BLANK (no attributable documented Barrett position found):
--   Local/municipal: campaign-finance, childcare, city-sanitation, civil-rights,
--          climate-change, economic-development, fossil-fuels, homelessness,
--          homelessness-response, housing, jail-capacity, local-immigration,
--          rent-regulation, transportation-priorities.
--          (Her generic "commercial annexation/retail without new taxes" remarks were too
--           unspecific to pin an economic-development chair — left blank.)
--   Non-local federal/national (a town council member has no record on these): abortion,
--          ai-regulation, deportation, healthcare, immigration, medicare/aid, misinformation,
--          redistricting, religious-freedom, same-sex-marriage, school-vouchers,
--          social-security, tariffs, trans-athletes, ukraine-support, voting-rights.
-- =====================================================================================

BEGIN;

-- ----- Melanie Barrett / data-centers (value 1) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Barrett's 2026 mayoral platform states plainly: "I am against Data Centers in or adjacent to Oro Valley, and if elected, I will review our Town Code to address this issue proactively." KGUN9's June 2026 profile likewise reports she opposes data centers in or near the town. That is an outright-opposition posture — she wants the Town Code changed to head off data-center development rather than permit it under conditions — which maps to the most restrictive available chair (halt/block new data-center construction) rather than any of the allow-with-conditions options.$$,
        ARRAY['https://melaniebarrett.org/',
              'https://www.kgun9.com/news/community-inspired-journalism/oro-valley/melanie-barrett-highlights-record-growth-strategy-in-oro-valley-mayoral-bid']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melanie Barrett / growth-and-development (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Barrett was elected to the Oro Valley Council on Aug. 28, 2018 as part of the new slate that ran on a "slower-growth platform" (Arizona Daily Star / Steller notebook). Across her tenure and her 2026 mayoral bid she frames her approach as "responsible and reasonable development" — balancing new development with community preservation, favoring infill/redevelopment such as the Oro Valley Marketplace over sprawl, and pledging to operate "without developer funding" — and she tied her January 2026 vote against tax increases to the town having reached the end of its high-growth era. That is a cautious, capacity-conscious managed-growth posture (allow growth where it fits, slow approvals) rather than proactively recruiting or deregulating development.$$,
        ARRAY['https://tucson.com/news/local/govt-and-politics/article_3a15c5ce-a4cb-5e2b-939f-72ac1bd07d0f.html',
              'https://www.kgun9.com/news/community-inspired-journalism/oro-valley/melanie-barrett-highlights-record-growth-strategy-in-oro-valley-mayoral-bid',
              'https://melaniebarrett.org/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melanie Barrett / local-environment (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Barrett's 2026 platform centers on "protecting the open spaces and quality of life that make OV home" and says she has "worked to advocate for residents, protect Oro Valley's beauty and views." She specifically cites the Vistoso golf course property — "saving [it] from extensive development" — as an example of why the town needs a Mayor and Council who operate without developer funding. That record reflects strict protection of existing open space and scenic desert views against development, i.e. a preservation-first stance rather than merely applying flexible standards.$$,
        ARRAY['https://melaniebarrett.org/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melanie Barrett / public-safety-approach (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Barrett campaigns on "a safe community where police are supported and funded" and touts Oro Valley being recognized as the #1 safest city in Arizona. Her signature fiscal accomplishment is that the council she served on "fixed a long-ignored $27 million unfunded police pension liability, bringing it to 100% funded and saving taxpayers up to $30 million," and KGUN9 reports she lists a new police headquarters among her top priorities. That is a consistent record of increasing and securing police funding, staffing and facilities to bolster public safety.$$,
        ARRAY['https://melaniebarrett.org/',
              'https://www.kgun9.com/news/community-inspired-journalism/oro-valley/melanie-barrett-highlights-record-growth-strategy-in-oro-valley-mayoral-bid']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melanie Barrett / residential-zoning (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$At the May 6, 2026 Council meeting that rezoned an undeveloped desert parcel along Rooney Wash to allow stores and townhouses, Barrett made the motion to restrict the residential portion to townhouses no taller than 30 feet. Drawing on her land-use/zoning background, she allowed attached (multifamily) housing to proceed but constrained its scale and height — a modest, design-controlled density approach rather than broad by-right upzoning or a hard block on any density.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/5/11/229686-oro-valley-allows-stores-townhouses-on-parts-of-undeveloped-desert-parcel/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Melanie Barrett / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c33b6be0-1192-4483-9343-28084a0f947d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$At the Jan. 14, 2026 Council meeting (reported by AZPM Jan. 15), Barrett voted against all three proposed tax increases, saying "I think there is time before this becomes a crisis." Her 2026 platform touts "fiscal stewardship with no town property taxes" and a balanced budget/five-year forecast. Her documented position is to hold the town's current low-tax structure in place — resisting tax increases while keeping existing services — rather than raising rates or cutting taxes and scaling back services.$$,
        ARRAY['https://news.azpm.org/p/azpmnews/2026/1/15/228000-tax-debate-in-oro-valley-signals-the-end-of-a-high-growth-era/',
              'https://melaniebarrett.org/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
