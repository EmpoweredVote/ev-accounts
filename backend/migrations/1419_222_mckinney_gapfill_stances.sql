-- =====================================================================================
-- Phase 222 (plan 222-04, part B) — Compass topic-gap fill: City of McKinney, TX
-- (geo_id 4845744). Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * Every seeded chair rests on an explicit, on-topic statement or recorded vote by
--     that specific person, in a source that was actually fetched and read this session.
--     No party inference, no identity inference, no city-policy default, no adjacency
--     inference (board service, profession, tenure), no defaulted middle values, no
--     cross-topic inference.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * McKinney, TEXAS confirmed on every source used.
--
-- SCOPE: exactly the 49 (person, topic) pairs that hold no stance for McKinney's 7 seated
-- officeholders after plan 222-02's deletions. Pairs that already hold a stance were not
-- researched, are not referenced here, and must not be touched (D-07). Michael Jones /
-- economic-development and Rick Franklin / residential-zoning were reviewed and KEPT by
-- 222-02 and are deliberately absent from this file.
--
-- SEEDED (2 rows / 2 answer+context pairs):
--   Ernest Lynch   homelessness           = 4
--   Michael Jones  growth-and-development = 3
--
-- NO `taxes` ROW IS INCLUDED IN THIS MIGRATION, BY INSTRUCTION. The taxes scale's chairs
-- 1-2 require raising taxes specifically on wealthy people and large companies and its
-- chairs 4-5 require scaling public services back, neither of which is a municipal power
-- or practice, so chair 3 is the only structurally reachable chair for a city council
-- member and an open methodology question is pending the operator's ruling. Four McKinney
-- members (Lynch, Jones, Cloutier, Feltus) were researched on `taxes` and each would
-- support chair 3 if the operator rules chair 3 acceptable; those findings are recorded in
-- 222-CONFIRMED-BLANK.md as "researched, chair pending methodology ruling" and in this
-- plan's checkpoint report. Beller, Franklin and Cox yielded no chair-locating tax
-- evidence at all. No work is lost either way.
--
-- DELIBERATELY BLANK (47 person/topic pairs — see 222-CONFIRMED-BLANK.md for each).
-- Notable decisions:
--   * Bill Cox / homelessness — he voted for both Oct. 21, 2025 ordinances and told NBC 5
--     DFW "We are getting out front and going to be active and implement ordinances that
--     ensure the safety of our citizens and the viability of our businesses. And at the
--     same time, you have to be compassionate." That rules out the chairs that protect or
--     decriminalize public sleeping, but "you have to be compassionate" is not a shelter
--     commitment and he said nothing about shelter capacity, so the prohibit-plus-maintain-
--     shelter chair and the ban-and-rely-on-existing-services chair both remain live.
--     Range-narrowed is not chair-located, so no chair was assigned. This is the exact
--     evidentiary difference from Lynch, whose own words do commit to adding shelter.
--   * McKinney is 0/7 on civil-rights, local-immigration and healthcare, as the 222-01
--     audit predicted. No statement by any of the seven was found on civil-rights
--     enforcement or equity policy, on McKinney PD's relationship to federal immigration
--     enforcement (a targeted search for a McKinney 287(g)/detainer/information-sharing
--     debate found none), or on the government's role in healthcare access.
--   * growth-and-development is 1/7. Six members' growth language ("grows responsibly",
--     "practical, pragmatic, and listen", "managing that in a way that the people who live
--     here will benefit", "Who does McKinney want to be?", "development enhances — rather
--     than diminishes — the qualities that make our city special") states no position on
--     growth pace, infrastructure gating, or permitting.
--
-- PREVIOUSLY-DELETED PAIRS (plan 222-02, applied 2026-07-25): all 7 McKinney pairs that
-- fall inside this plan's scope were re-researched this session and ALL 7 REMAIN BLANK —
-- no genuinely new, explicit, citable evidence was found for any of them, so none is
-- reinstated: Lynch/economic-development, Feltus/economic-development,
-- Feltus/public-safety-approach, Beller/economic-development,
-- Beller/public-safety-approach, Cloutier/economic-development,
-- Franklin/economic-development. Service on the McKinney Economic Development Corporation
-- board is held by four of these seven members and is NOT evidence of a position on
-- economic-development incentives; it was deliberately not used, since that adjacency is
-- precisely the defect 222-02 removed.
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Ernest Lynch — Council Member At-Large Place 1, City of McKinney, TX
-- politician_id: c3e2d7a6-8096-4e91-9ee0-3cca445af72e
-- Elected in the June 7, 2025 runoff; sworn in June 2025.
-- =====================================================================================

-- ----- Ernest Lynch / homelessness (value 4) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        4)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c3e2d7a6-8096-4e91-9ee0-3cca445af72e',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $stz$Asked by Community Impact Newspaper (March 6, 2025 candidate Q&A for the At Large 1 seat) what new programs he wanted the city to explore, Lynch answered with homelessness: "I'd like the city to explore expanding support for the homeless, addressing the mental health and substance abuse aspects of the crisis. McKinney lacks sufficient shelter facilities, and I'd advocate for additional resources to provide care and long-term stability. This would include collaborating with healthcare providers, law enforcement, and nonprofits." As a seated council member he then voted for both of McKinney's new restrictions on public sleeping and camping on Oct. 21, 2025: Community Impact reports the downtown sitting-and-lying ordinance passed 6-1 with Justin Beller the lone member against, and the citywide camping ordinance — which broadens "camping" to include sleeping in a vehicle overnight — passed 5-2 with Beller and Geré Feltus against, placing Lynch on the prevailing side of both. Prohibiting camping and sleeping on public property is therefore his own recorded position, which rules out the chairs that protect or decriminalize sleeping in public, and because McKinney had no adequate shelter capacity when he cast those votes the chair that permits enforcement only once adequate beds exist does not describe him either. What separates his position from a straight ban is his own stated commitment that the city lacks sufficient shelter facilities and should add resources for care and long-term stability rather than leaning on the services that already exist.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/election/2025/03/06/qa-meet-the-candidates-for-mckinney-city-councils-at-large-1-seat/',
              'https://communityimpact.com/dallas-fort-worth/mckinney/government/2025/10/21/new-mckinney-ordinances-regulate-vehicle-camping-restrict-sleeping-in-downtown/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Michael Jones — Council Member At-Large Place 2, City of McKinney, TX
-- politician_id: 09dbafc2-9252-40e4-9a1c-afda5b069f2e
-- Elected May 6, 2023.
-- =====================================================================================

-- ----- Michael Jones / growth-and-development (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('09dbafc2-9252-40e4-9a1c-afda5b069f2e',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $stz$Answering Community Impact Newspaper's April 3, 2023 candidate questionnaire for the At Large 2 seat on the top issues facing McKinney, Jones described how he would handle the city's expansion: "Growing and improving our infrastructure is another priority. While on the MEDC I took the initiative to start addressing infrastructure rather than wait," and "Population growth will continue to change the landscape of the city. Ensuring the city is properly staffed to handle this growth will be a priority if I'm on council." Building infrastructure and staffing capacity in advance of the growth rather than waiting for it is the proactive-planning chair. He proposes no growth cap and no voter-approval requirement for annexations or large developments, and his explicit preference for acting "rather than wait" is the opposite of allowing growth only where existing infrastructure already supports it and slowing approvals until capacity catches up, so neither restrictive chair fits. He likewise proposes no permit streamlining, no fee reduction and no removal of regulatory barriers, which the two deregulatory chairs require.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/mckinney/government/2023/04/03/meet-the-candidates-for-mckinney-city-council-at-large-2-seat/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
