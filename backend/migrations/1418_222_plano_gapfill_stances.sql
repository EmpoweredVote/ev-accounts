-- =====================================================================================
-- Phase 222 (plan 222-04, part A) — Compass topic-gap fill: City of Plano, TX
-- (geo_id 4858016). Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * Every seeded chair rests on an explicit, on-topic, dated statement by that specific
--     person, in a source that was actually fetched and read this session (a candidate
--     questionnaire answer, a quoted statement at a council meeting on the matter being
--     decided, or the officeholder's own published account of a specific rezoning case
--     they led). No party inference, no identity inference, no city-policy default, no
--     adjacency inference (board service, profession, tenure), no defaulted middle values,
--     no cross-topic inference.
--   * A unanimous council vote with no individually-attributed statement was NOT treated
--     as evidence. Plano's Sept 8, 2025 tax-rate adoption, its Nov 5, 2025 DART
--     withdrawal-election call, its Feb 23, 2026 DART cancellation, and its May 26, 2026
--     $140M public-safety campus award were all unanimous; none of them sets a chair on
--     its own. Where a member's own quoted reason at that meeting exists, that quote —
--     not the vote — carries the row.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Plano, TEXAS confirmed on every source used.
--
-- SCOPE: exactly the 59 (person, topic) pairs that hold no stance for Plano's 8 seated
-- officeholders after plan 222-02's deletions. Pairs that already hold a stance were not
-- researched, are not referenced here, and must not be touched (D-07). Place 6 is out of
-- scope. 5 pairs are seeded below; the other 54 are honest blanks.
--
-- SEEDED (5 rows / 5 answer+context pairs):
--   Maria Tu           taxes              = 3
--   Rick Horne         taxes              = 3
--   Chris Krupa Downs  taxes              = 3
--   Vidal Quintanilla  taxes              = 3
--   Steve Lavine       residential-zoning = 2
--
-- NOTE ON THE TAXES CLUSTER: four Plano members land on chair 3 from three genuinely
-- different postures (Tu and Horne argued for the higher proposed rate; Quintanilla cast
-- the lone vote against it; Downs campaigned on holding rates low by growing the
-- commercial base). They converge because this topic's chairs 1 and 2 both require raising
-- taxes specifically on wealthy people and large companies, and chairs 4 and 5 both require
-- scaling public services back to match a tax cut. None of these four does either: each
-- keeps the existing broad-based municipal property tax while funding existing services,
-- which is chair 3's text. The convergence is a property of the scale, not a defaulted
-- middle value — each row cites that person's own dated words.
--
-- DELIBERATELY BLANK (54 person/topic pairs — see 222-CONFIRMED-BLANK.md for each).
-- Notable pre-commit self-audit demotions:
--   * John B. Muns / taxes — his only quote in the tax-rate coverage ("If we don't take
--     care of our infrastructure, I think companies will look elsewhere...") is about
--     infrastructure spending and states no position on the tax-and-spend balance; the
--     Sept 8, 2025 adoption was unanimous with no tax statement of his own attributed.
--   * Rick Horne / economic-development — he personally moved the June 8, 2026 TIRZ
--     designation and voted for the Centennial Waterfall Willow Bend incentive agreement,
--     which rules out the no-incentives chairs, but no stated reason of his separates
--     targeted incentives with community-benefit conditions from active competition for
--     major employers. Range-narrowed is not chair-located.
--   * Chris Krupa Downs / public-safety-approach — "Public safety is my top priority,
--     ensuring police and fire departments have needed resources" is the same
--     non-discriminating phrase the 222-01 audit deleted from another Collin record.
--   * Vidal Quintanilla / transportation-priorities — his road-maintenance answers rule
--     out the transit-first and highway-maximalist chairs but do not separate maintaining
--     roads while selectively adding transit from prioritizing road capacity for drivers.
--
-- PREVIOUSLY-DELETED PAIRS (plan 222-02, applied 2026-07-25): all 8 that fall inside this
-- plan's scope were re-researched this session and ALL 8 REMAIN BLANK — no genuinely new,
-- explicit, citable evidence was found for any of them, so none is reinstated:
--   Downs/housing, Downs/residential-zoning, Thomas/housing, Thomas/homelessness,
--   Tu/local-immigration, Muns/local-immigration, Quintanilla/civil-rights,
--   Quintanilla/local-immigration.
-- =====================================================================================

BEGIN;

-- =====================================================================================
-- Maria Tu — Council Member Place 1 (Mayor Pro Tem), City of Plano, TX
-- politician_id: d6bf8d34-5a59-419a-8ed7-9c9b4d865799
-- =====================================================================================

-- ----- Maria Tu / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d6bf8d34-5a59-419a-8ed7-9c9b4d865799',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $stz$During Plano's FY 2025-26 budget deliberations Tu argued for preserving the city's revenue rather than trimming it: on Aug. 25, 2025 she backed the higher proposed rate, saying "If we don't max it this time, we are never going to have this buffer money ever again," and after the Sept. 8, 2025 adoption she explained "Although I was leaning towards a lower tax rate, I proposed a higher one because I just didn't know what we would be facing the next year," adding "It is time for us to have a buffer, and it is time to replenish some of the emergency funds that we basically have run out because of all the storms and all the shocking surprises that we've had in the city." Her position is to keep the existing municipal property tax and adjust the rate modestly to keep funding current services and reserves — she proposes no reduction in services, which rules out the tax-cutting chairs, and the increase she supported is a broad-based rate applied to all property rather than a new levy aimed at wealthy people or large companies, which rules out the redistributive chairs. Her own note that she was personally "leaning towards a lower tax rate" confirms she is defending the status quo balance, not seeking a larger tax take.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/government/2025/08/26/plano-council-considers-raising-property-tax-rate-citing-legislative-uncertainty/',
              'https://communityimpact.com/dallas-fort-worth/plano-south/government/2025/09/09/plano-council-raises-property-tax-rate-adopts-798m-budget/',
              'https://www.keranews.org/news/2025-09-09/own-a-home-in-plano-property-taxes-may-go-up-city-council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Rick Horne — Council Member Place 3 (Deputy Mayor Pro Tem), City of Plano, TX
-- politician_id: bc4a88d7-2f56-48fd-85db-fa1fd4f8547e
-- =====================================================================================

-- ----- Rick Horne / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bc4a88d7-2f56-48fd-85db-fa1fd4f8547e',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $stz$Speaking at Plano's Aug. 25, 2025 budget discussion in support of the higher proposed property tax rate, Horne gave his reason directly: "We are one tornado away from having a catastrophic event [that hurts] us critically from a budget perspective. By tomorrow morning, we're not sure what's going to come out [of the Legislature] with regards to voter approved rates in the future." He is arguing to preserve the city's existing taxing capacity so current services and emergency response stay funded, and he proposes no reduction in public services to match a lower tax take, which rules out the tax-cutting chairs. The rate he defended is the city's existing broad-based property tax rather than a new levy targeted at wealthy people or large companies, which rules out the redistributive chairs, leaving the keep-the-current-system-with-modest-adjustments chair.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/government/2025/08/26/plano-council-considers-raising-property-tax-rate-citing-legislative-uncertainty/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Chris Krupa Downs — Council Member Place 4, City of Plano, TX
-- politician_id: 127b8e69-3900-438c-8361-2cfe24b6c6cf
-- Elected May 3, 2025 (54.96%) over Cody Weaver.
-- =====================================================================================

-- ----- Chris Krupa Downs / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('127b8e69-3900-438c-8361-2cfe24b6c6cf',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $stz$Answering Community Impact Newspaper's candidate questionnaire for the May 3, 2025 Place 4 race, Downs set out the tax-and-services balance she wants: the city "must support police and fire services, expand the commercial tax base, and prioritize spending to maintain excellent services without overburdening residents with taxes," and among her stated priorities, "I will support expanding the commercial tax base to maintain low tax rates while funding essential services." She added that "As the commercial tax base grows, homeowners' share of burden declines." Her route is to hold the existing rate structure steady and shift the burden by growing the commercial base — she explicitly commits to maintaining and funding services rather than scaling them back, which rules out the tax-cutting chairs, and she proposes no increase aimed at wealthy people or large companies, which rules out the redistributive chairs.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/election/2025/03/10/qa-meet-the-candidates-for-plano-city-council-place-4/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Steve Lavine — Council Member Place 5, City of Plano, TX
-- politician_id: ecef0481-27c7-4955-b822-83d64c7ef63f
-- Elected May 3, 2025.
-- =====================================================================================

-- ----- Steve Lavine / residential-zoning (value 2) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ecef0481-27c7-4955-b822-83d64c7ef63f',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $stz$Lavine's own published account of his record describes two specific Plano rezoning cases he personally led on the Haggard Farm tract in west Plano: "Steve built a coalition of homeowners to defeat a request for re-zoning that could have led to more than 4,000 apartments and up to 10-story buildings, nearby to west Plano single-family neighborhoods," and then "Steve once again led the fight, this time to build a compromise with the same landowner, that resulted in a far less dense and more compatible development" delivering lower-density development and more open space. He frames his method as one that "Works constructively with both developers and residents to find balanced, win-win solutions." That locates the chair precisely: he did not demand that rezoning be blocked outright or put to a neighborhood referendum, so the strict-protection chair does not fit, and he actively organized against multifamily density adjacent to single-family neighborhoods, so the allow-multifamily-near-corridors chair does not fit either. What he did do is admit development at a reduced, compatibility-tested density arrived at through neighborhood input and negotiation, which is the modest-density-with-strong-review-and-neighborhood-input chair. The broad by-right upzoning and end-single-family-zoning chairs are ruled out by the same record.$stz$,
        ARRAY['https://steve4plano.com/meet-steve/',
              'https://steve4plano.com/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- =====================================================================================
-- Vidal Quintanilla — Council Member Place 8, City of Plano, TX
-- politician_id: 5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f
-- Elected May 3, 2025 over Hayden Padgett.
-- =====================================================================================

-- ----- Vidal Quintanilla / taxes (value 3) -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5de5cc59-9cbc-4b09-b7a4-88a45d1b1b7f',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $stz$Quintanilla cast the only vote against the higher $0.4406 rate Plano's council proposed on Aug. 25, 2025, and gave his own reason for it: "With [the] cost of living continuing to rise, raising taxes to $0.4406 is not something I can support, specifically after running on the commitment of maintaining low property taxes," having said earlier that day "I have in the back of my mind [that] cost of living is going up, food is going up, groceries [are] going up for everyday citizens" and "It's just a bigger pill for me to swallow at this time." He then voted for the smaller $0.4376 rate the council adopted on Sept. 8, 2025. His campaign platform likewise states he is "committed to keeping property taxes low, ensuring that Plano remains an affordable place." He accepts a modest adjustment within the existing tax structure and rejects a larger one, while proposing no reduction in public services to match a tax cut — he simultaneously pledges resources for police and fire — so the tax-cutting chairs do not fit, and he seeks no increase aimed at wealthy people or large companies, so the redistributive chairs do not fit.$stz$,
        ARRAY['https://communityimpact.com/dallas-fort-worth/plano-north/government/2025/08/26/plano-council-considers-raising-property-tax-rate-citing-legislative-uncertainty/',
              'https://communityimpact.com/dallas-fort-worth/plano-south/government/2025/09/09/plano-council-raises-property-tax-rate-adopts-798m-budget/',
              'https://vidalforplano.com']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
