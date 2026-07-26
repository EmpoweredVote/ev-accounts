-- =====================================================================================
-- Phase 222 — follow-on integrity remediation: one bio-page-only row (AUDIT-ONLY)
-- Date: 2026-07-25
--
-- AUDIT-ONLY / UNREGISTERED. Deliberately NOT registered in schema_migrations.
-- Touches only inform.politician_answers and inform.politician_context.
-- Applied by the orchestrator at operator instruction; not applied by the authoring session.
--
-- WHAT THIS DELETES: exactly one (politician_id, topic_id) pair.
--
--   Dan Barrios — City of Richardson, TX — e8c863a7-d116-480e-a81f-47d26f45e264
--   topic: healthcare — e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
--   sources: ARRAY['https://ballotpedia.org/Dan_Barrios']  (single bio URL)
--
-- WHY: the row's only source is a Ballotpedia **biography** page. A bio page carries no
-- stance content in either direction, so it cannot support a chair on healthcare — or on
-- anything else. This is the "bio-page-only" defect class documented independently in
-- C:/EV-Accounts/.planning/todos/2026-07-24-party-prior-stance-contamination-audit.md,
-- which measured 907 such rows across 293 politicians nationally (TX 23).
--
-- WHY IT SURVIVED PLAN 222-02: that plan's Class A1 signature required `sources IS NULL`
-- **and** reasoning admitting "no record found". This row has a source — just a useless
-- one — and so matched neither arm of the test. Two of Barrios's other rows WERE deleted by
-- 222-02 (civil-rights as A2 party-in-reasoning, homelessness as party-inference plus an
-- admitted absence of evidence). This is the third and last of his defective rows in the
-- Collin/Longview scope.
--
-- The operator authorised this deletion explicitly on 2026-07-25, separately from the 27
-- pairs approved for migration 1416.
--
-- Blank is the correct terminal state. Logged at (person, topic) granularity in
-- 222-CONFIRMED-BLANK.md. Deletion removes BOTH the answer row and its paired context row.
-- Idempotent: keyed on (politician_id, topic_id), 0-or-1 rows each, errors on nothing
-- already gone.
--
-- NOT IN SCOPE HERE: the other 906 bio-page-only rows nationally. Those belong to the
-- pre-existing EV-Accounts audit above and to backlog Phase 999.2 — do not widen this file.
-- =====================================================================================

BEGIN;

-- ----- Dan Barrios / healthcare (bio-page-only source) -----
DELETE FROM inform.politician_answers
 WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264'
   AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

DELETE FROM inform.politician_context
 WHERE politician_id = 'e8c863a7-d116-480e-a81f-47d26f45e264'
   AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

COMMIT;
