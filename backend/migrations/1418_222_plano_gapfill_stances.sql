-- =====================================================================================
-- Phase 222 (plan 222-04, part A) — Compass topic-gap fill: City of Plano, TX
-- (geo_id 4858016). Authored 2026-07-25.
--
-- EVIDENCE-ONLY / HONEST-BLANK / AUDIT-ONLY migration.
--   * This file is AUDIT-ONLY and is deliberately NOT registered in schema_migrations.
--     It touches only inform.politician_answers and inform.politician_context.
--     The operator applies it (the executor has no Supabase MCP binding).
--   * Every seeded chair rests on an explicit, on-topic, dated statement by that specific
--     person, in a source that was actually fetched and read (a candidate questionnaire
--     answer, a quoted statement at a council meeting on the matter being decided, or the
--     officeholder's own published account of a specific rezoning case they led). No party
--     inference, no identity inference, no city-policy default, no adjacency inference
--     (board service, profession, tenure), no defaulted middle values, no cross-topic
--     inference.
--   * A unanimous council vote with no individually-attributed statement was NOT treated
--     as evidence. Plano's Sept 8, 2025 tax-rate adoption, its Nov 5, 2025 DART
--     withdrawal-election call, its Feb 23, 2026 DART cancellation, and its May 26, 2026
--     $140M public-safety campus award were all unanimous; none of them sets a chair on
--     its own.
--   * Topics with no explicit, chair-locating evidence emit NO row (honest blank) and are
--     logged per (person, topic) in 222-CONFIRMED-BLANK.md.
--   * Plano, TEXAS confirmed on every source used.
--
-- SCOPE: exactly the 59 (person, topic) pairs that held no stance for Plano's 8 seated
-- officeholders after plan 222-02's deletions. Pairs that already hold a stance were not
-- researched, are not referenced here, and must not be touched (D-07). Place 6 is out of
-- scope.
--
-- SEEDED (1 row / 1 answer+context pair):
--   Steve Lavine       residential-zoning = 2
--
-- ---------------------------------------------------------------------------------------
-- REVISION 2026-07-25 — OPERATOR RULING: the four `taxes` rows are DROPPED.
-- ---------------------------------------------------------------------------------------
-- Revision 1 seeded 5 rows: four `taxes` = 3 (Maria Tu, Rick Horne, Chris Krupa Downs,
-- Vidal Quintanilla) plus Steve Lavine `residential-zoning` = 2.
--
-- The operator ruled on 2026-07-25 that the four `taxes` rows be dropped, and that `taxes`
-- be treated as STRUCTURALLY UNANSWERABLE for municipal officeholders for the remainder of
-- Phase 222. Reasoning:
--
--   The `taxes` scale (topic f7e5678d-dadd-4556-a2fc-446e24642ceb) reads:
--     1  Significantly raise taxes ON WEALTHY PEOPLE AND LARGE COMPANIES to fund more services
--     2  Moderately raise taxes ON WEALTHY PEOPLE AND LARGE COMPANIES to fund existing services
--     3  Keep the current tax system mostly as-is with small adjustments to close loopholes
--     4  Cut taxes for everyone AND SCALE BACK PUBLIC SERVICES to match
--     5  Drastically cut taxes and shrink government
--
--   Texas cities levy a uniform ad-valorem property tax. They cannot tax by wealth or by
--   company size, so chairs 1 and 2 are outside municipal power. They do not cut services to
--   match rate cuts, so chairs 4 and 5 do not occur. Chair 3 is therefore the only
--   structurally reachable chair for any city council member — which means it carries no
--   discriminating information, and worse, it flattens members who genuinely disagree.
--
--   Concretely: Tu and Horne argued FOR Plano's 2025 property-tax rate increase, Quintanilla
--   cast the lone vote AGAINST it, and Downs campaigned on holding rates down via commercial
--   base growth. All four would have rendered as the identical chair 3. Tu and Horne voted to
--   RAISE the rate, which "keep the current system mostly as-is" does not describe at all.
--   The scale has no chair for "raise uniform property taxes to fund existing services."
--
--   Assigning the middle chair because the outer four are unreachable is defaulting to a
--   middle value, which this phase's own prohibitions forbid even when each row cites a real
--   quote. The four rows are therefore dropped and recorded as blanks with their evidence
--   preserved in 222-CONFIRMED-BLANK.md, so the research is not lost if the scale is later
--   revised with a municipal-appropriate `taxes` question.
--
--   Plan 222-04 part B (McKinney) was instructed to exclude `taxes` before authoring, and
--   independently reproduced the same flattening: Cloutier pushing rate cuts and Feltus
--   declining an exemption increase to protect services would both have landed on chair 3.
--
-- NET: this migration now seeds exactly ONE row-pair. 58 of the 59 pairs are honest blanks.
-- Follow-on: the Local Lens `taxes` question needs a municipal-scope rewrite before any city
-- officeholder can be placed on it. Logged for a future scale-revision phase.
-- =====================================================================================

BEGIN;

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

COMMIT;
