-- =====================================================================================
-- Compass stances: Jeffrey Bernstein — City of Palm Springs (CA) City Council, District 2
-- ext_id: -4011002   politician_id: befbbea4-9e33-4f37-9745-c7184e824d48
-- Nonpartisan municipal office (party not stored/displayed). Downtown Palm Springs small-
-- business owner; elected 2022; served as Mayor Pro Tem / Mayor during his term.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration. Every seeded topic is backed by a
-- documented, attributable position with a real cited source URL. Topics with no clearly
-- attributable individual position emit NO row. AUDIT-ONLY / unregistered. Non-court-scoped office —
-- no court-scoped-* topics.
--
-- SEEDED (2 topics):
--   housing = 2               (personally proposed raising the TOT set-aside to 50% for affordable
--                              housing, June 2023, adding ~$3.2M; three affordable developments in term)
--   homelessness-response = 3 (as Mayor, voted FOR the July 2024 encampment-regulation ordinance
--                              while the city invests heavily in services — Navigation Center, TOT
--                              affordable housing — a balanced invest-and-enforce posture)
--
-- DELIBERATELY BLANK (real record but no clean single-chair map, or no attributable position):
--   economic-development (his $125M convention-center modernization + airport-upgrade + creative-
--     economy record is documented public-infrastructure investment, but does not map cleanly to a
--     single economic-development chair without over-reading — left blank rather than force-fit),
--   and all other local + non-local topics.
-- =====================================================================================

BEGIN;

-- ----- Jeffrey Bernstein / housing (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('befbbea4-9e33-4f37-9745-c7184e824d48',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('befbbea4-9e33-4f37-9745-c7184e824d48',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Bernstein is the councilmember who first proposed, and then voiced support for, increasing the City's transient occupancy tax (TOT) allocation dedicated to affordable housing to 50% during a June 2023 council meeting — a change that was approved and made an additional roughly $3.2 million available for affordable-housing efforts. During his tenure the city also saw the completion of three affordable-housing developments. Championing a large, dedicated public-revenue stream to fund affordable housing (rather than leaving supply to the market or relying only on light-touch permit incentives) aligns with using public funding and affordable-unit development to expand the housing supply.$$,
        ARRAY['https://thepalmspringspost.com/millions-more-in-city-taxes-will-be-dedicated-to-affordable-housing-efforts-following-council-vote/',
              'https://www.jeffreyforps.com/meet-jeffrey']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey Bernstein / homelessness-response (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('befbbea4-9e33-4f37-9745-c7184e824d48',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('befbbea4-9e33-4f37-9745-c7184e824d48',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Bernstein's homelessness record pairs enforcement of public-space rules with substantial service and housing investment. As Mayor he was in the council majority that approved, 3-1, the July 2024 ordinance regulating homeless encampments (making it a violation to set up an encampment or sleep on public property) — an enforcement measure. At the same time he championed the city's affordable-housing funding (the 50% TOT set-aside) and the opening of the Navigation Center, which provides homeless residents with services and support. Voting for reasonable public-space enforcement while simultaneously expanding outreach, shelter, and housing investment fits a balanced approach that invests in services and enforces public-space rules, rather than an enforcement-only or a no-enforcement posture.$$,
        ARRAY['https://thepalmspringspost.com/city-council-approves-regulating-homeless-encampments-despite-concerns/',
              'https://thepalmspringspost.com/millions-more-in-city-taxes-will-be-dedicated-to-affordable-housing-efforts-following-council-vote/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
