-- Phase 103: CA State Remediation
-- Requirements covered: STAX-01, QUAL-01, QUAL-02
-- Source CSV: backend/data/stance-research/2026-06-06-ca-state-remediation.csv
-- Source deletion log: .planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md
--
-- Pre-write cross-check:
--   Expected upserts: 12, deletes: 6, total = 18
--   (12) + (6) = 18 = Plan 01 flagged-stance count (103-CA-TARGETS.csv) ✓
--   Intersection of UPSERT and DELETE (politician_id, topic_id) pairs: empty ✓
--   All UPSERT and DELETE rows reference exactly the 11 CA politician UUIDs below ✓
--
-- DEVIATION: Plan 02 specified migration number 280. At write time, MAX(version) = 281
-- (migrations 278 = md_2026_elections, 279 = md_officials_stances, 280 = md_2026_legislative_races,
--  281 = md_2026_discovery were applied between pre-flight and this Task 3 execution).
-- Next available number: 282. Migration filename uses 282 accordingly.
--
-- Politicians in scope (UUIDs from 103-RESEARCH-NOTES.md, verified against essentials.politicians):
--   Akilah Weber Pierson  (SD39, STATE_UPPER)   UUID: e5470008-3c0d-4970-a485-053621d8f0a6
--   Caroline Menjivar     (SD20, STATE_UPPER)   UUID: 4baa73c2-d38b-4d07-894f-1577d5ba43a3
--   Catherine Stefani     (AD19, STATE_LOWER)   UUID: 0649630c-bd6d-40fe-8f66-e026e6f6c83e
--   Eloise Gómez Reyes    (SD29, STATE_UPPER)   UUID: 1571da4a-b832-4792-917c-184c155b1700
--   Gavin Newsom          (STATE_EXEC)          UUID: f26309c8-2525-49b2-bdaf-62980cbb1853
--   Gregg Hart            (AD37, STATE_LOWER)   UUID: 21940b7c-2424-47e9-a649-077b0f827c2c
--   Henry Stern           (SD27, STATE_UPPER)   UUID: f3671de4-514f-441c-8ad4-4a9ab7c65ae6 (deletions only)
--   Juan Carrillo         (AD39, STATE_LOWER)   UUID: b959d608-5674-467e-a1c8-3572c76a729b
--   Lisa Calderon         (AD57, STATE_LOWER)   UUID: 0afa998d-94e9-4af4-ba00-256c38869398
--   Natasha Johnson       (AD40, STATE_LOWER)   UUID: 3f200d93-74aa-4191-a275-77b64ff5b219
--   Rob Bonta             (STATE_EXEC)          UUID: 8b183a30-3afb-4d9e-aa40-aa2ad2c674aa (deletion only)
--
-- Source-append classification per 103-RESEARCH-NOTES.md:
--   PLAIN_OVERWRITE (6): Newsom×4 (medicare/aid, redistricting, religious-freedom, same-sex-marriage),
--                        Carrillo×1 (childcare), Calderon×1 (campaign-finance)
--   ARRAY_CAT (6):       Weber Pierson (fossil-fuels), Menjivar (homelessness), Stefani (immigration),
--                        Gómez Reyes (campaign-finance), Hart (homelessness), Johnson (school-vouchers)
--
-- Migration number: 282 (verified via SELECT MAX(version) → 281; next = 282)
-- Applied: 2026-06-06 via psql session pooler

BEGIN;

-- ============================================================
-- UPSERT BLOCK — 12 rows (from 2026-06-06-ca-state-remediation.csv)
-- ============================================================

-- ---- Akilah Weber Pierson / fossil-fuels / value=2 / ARRAY_CAT ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'e5470008-3c0d-4970-a485-053621d8f0a6',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'e5470008-3c0d-4970-a485-053621d8f0a6',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Weber Pierson voted YES on SB 1137 (2021-22), which established health protection zones of 3,200 feet around sensitive receptors (schools, homes, daycares) and restricted new oil and gas operations within those zones. Her vote to restrict new fossil fuel drilling operations near communities matches value 2: ''stop issuing new permits for fossil fuel drilling.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1137'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://sd39.senate.ca.gov] (preserves history per CONTEXT.md D-05)

-- ---- Caroline Menjivar / homelessness / value=2 / ARRAY_CAT ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '4baa73c2-d38b-4d07-894f-1577d5ba43a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '4baa73c2-d38b-4d07-894f-1577d5ba43a3',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  'Menjivar voted YES on SB 43 (2023), which expanded California''s LPS conservatorship criteria to allow involuntary mental health and substance use disorder treatment for unhoused individuals with severe conditions, as an alternative to criminalization. She serves on the Senate Health and Human Services budget subcommittee and has consistently prioritized behavioral health outreach and shelter services over enforcement. Her record is consistent with value 2: decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB43'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://sd20.senate.ca.gov/] (preserves history per CONTEXT.md D-05)

-- ---- Catherine Stefani / immigration / value=2 / ARRAY_CAT ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0649630c-bd6d-40fe-8f66-e026e6f6c83e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0649630c-bd6d-40fe-8f66-e026e6f6c83e',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Stefani voted YES on AB 79 (2025, chaptered), which expanded public social services eligibility for higher education purposes regardless of immigration status. As a former San Francisco Board of Supervisors member (SF is a sanctuary city) and now an Assembly member, her record is consistent with keeping legal immigration open and allowing residents to use public services regardless of legal status, which aligns with value 2.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB79'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://sd22.senate.ca.gov/] (preserves history per CONTEXT.md D-05)

-- ---- Eloise Gómez Reyes / campaign-finance / value=2 / ARRAY_CAT ----
-- VALUE CHANGED: 3 → 2 (SB 1439 evidence supports strictly limiting certain political donations)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '1571da4a-b832-4792-917c-184c155b1700',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '1571da4a-b832-4792-917c-184c155b1700',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Gómez Reyes voted YES on SB 1439 (2022, chaptered), which restricts campaign contributions from persons seeking favorable decisions from government agencies (pay-to-play restrictions). Her YES vote on this bill to strictly limit certain political donations from interested parties aligns with value 2: ''strictly limit corporate donations and dark money groups.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1439'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://sd29.senate.ca.gov] (preserves history per CONTEXT.md D-05)

-- ---- Gavin Newsom / medicare/aid / value=2 / PLAIN_OVERWRITE ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'medicare/aid'),
  'Newsom expanded Medi-Cal to all low-income adults regardless of immigration status, including signing a $307.9 billion budget making California the first state to guarantee healthcare to all low-income undocumented immigrants. His Medi-Cal expansion policy of significantly expanding Medicaid eligibility aligns with value 2: ''lower Medicare age to 55 and expand Medicaid significantly.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Gavin_Newsom'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Gavin Newsom / redistricting / value=4 / PLAIN_OVERWRITE ----
-- VALUE CHANGED: 1 → 4 (vetoed independent redistricting AB 1248; championed partisan Prop 50)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'redistricting'),
  'Newsom vetoed AB 1248 (2023), which would have required independent redistricting commissions for local governments, and then championed California Proposition 50 (2025), allowing the state legislature to redraw congressional district boundaries in response to Texas''s gerrymander. His actions — vetoing independent redistricting and supporting legislative control over congressional maps — align with value 4: ''state legislatures with court oversight to prevent extreme partisan bias.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Gavin_Newsom',
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Gavin Newsom / religious-freedom / value=2 / PLAIN_OVERWRITE ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom'),
  'Newsom signed SB 107 (2022), making California a sanctuary state for transgender youth and limiting state cooperation with other states'' laws restricting gender-affirming care — legislation that prioritizes anti-discrimination protections over religious objections. His LGBTQ+ legislative record of signing bills that ensure civil rights protections are not overridden by religious exemptions aligns with value 2: ''protect religious freedom while ensuring it does not override anti-discrimination protections.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Gavin_Newsom'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Gavin Newsom / same-sex-marriage / value=1 / PLAIN_OVERWRITE ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  1
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'f26309c8-2525-49b2-bdaf-62980cbb1853',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage'),
  'Newsom gained national attention in 2004 when he directed the San Francisco city-county clerk to issue marriage licenses to same-sex couples, and he actively opposed Proposition 8 (2008). His decades-long advocacy for full marriage equality including federal recognition aligns with value 1: ''require all states to recognize same-sex marriages and provide full federal benefits and protections.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://en.wikipedia.org/wiki/Gavin_Newsom'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Gregg Hart / homelessness / value=3 / ARRAY_CAT ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '21940b7c-2424-47e9-a649-077b0f827c2c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '21940b7c-2424-47e9-a649-077b0f827c2c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'homelessness'),
  'Hart voted YES on SB 1395 (2024, chaptered) and presented the bill on the Assembly Floor — legislation expanding Low Barrier Navigation Center shelters by making them permissible uses by right in local zoning. His support for expanding shelter capacity alongside service diversion aligns with value 3: ''allowing enforcement only when adequate shelter beds are available, with citations diverting people to services rather than the criminal justice system.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1395'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://gregghart.org/] (preserves history per CONTEXT.md D-05)

-- ---- Juan Carrillo / childcare / value=3 / PLAIN_OVERWRITE ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b959d608-5674-467e-a1c8-3572c76a729b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  3
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b959d608-5674-467e-a1c8-3572c76a729b',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'childcare'),
  'Carrillo voted YES on SB 1112 (2024, chaptered), which expanded the categories of services that childcare alternative payment programs can fund, supporting families through targeted subsidies. His support for expanding childcare subsidy eligibility while maintaining existing income-targeted access aligns with value 3: ''offering targeted tax credits and subsidies for families below a set income threshold while supporting providers through training and facility grants.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1112'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Lisa Calderon / campaign-finance / value=2 / PLAIN_OVERWRITE ----
-- VALUE CHANGED: 3 → 2 (SB 1439 evidence supports strictly limiting certain political donations)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0afa998d-94e9-4af4-ba00-256c38869398',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0afa998d-94e9-4af4-ba00-256c38869398',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance'),
  'Calderon voted YES on SB 1439 (2022, chaptered), which restricts campaign contributions from persons with pending agency decisions — a pay-to-play prohibition. Her YES vote on this bill to strictly limit political contributions from parties seeking favorable government outcomes aligns with value 2: ''strictly limit corporate donations and dark money groups.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1439'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = EXCLUDED.sources;
-- PLAIN_OVERWRITE: prior context row had sources = [] (empty — no history to preserve per CONTEXT.md D-05)

-- ---- Natasha Johnson / school-vouchers / value=4 / ARRAY_CAT ----
-- VALUE CHANGED: 5 → 4 (issues page supports expanding educational choice/charter schools — not universal vouchers)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '3f200d93-74aa-4191-a275-77b64ff5b219',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '3f200d93-74aa-4191-a275-77b64ff5b219',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'school-vouchers'),
  'Johnson''s official issues page states she is ''a strong advocate for educational options in our community, including support for charter schools that have provided innovative and high-performing alternatives to traditional public schools'' and commits to ensuring ''all parents, regardless of zip code, have access to schools that meet their children''s unique needs.'' Her explicit support for expanding educational choice and school alternatives to traditional public schools aligns with value 4: ''expanding voucher eligibility to most families so parents can choose the school that best fits their child, while maintaining baseline public school funding.''',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://natashajohnsonforassembly.com/issues'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
--                ARRAY_CAT: append new URL to existing [https://natashajohnsonforassembly.com] (preserves history per CONTEXT.md D-05)

-- ============================================================
-- DELETE BLOCK — 6 rows (topics skipped by research agents — no evidence found)
-- Order: DELETE context FIRST, then answers (defensive ordering per 103-PATTERNS.md)
-- ============================================================

-- DELETED: Eloise Gómez Reyes / religious-freedom / former value=3 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '1571da4a-b832-4792-917c-184c155b1700'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');
DELETE FROM inform.politician_answers
WHERE politician_id = '1571da4a-b832-4792-917c-184c155b1700'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');

-- DELETED: Eloise Gómez Reyes / ukraine-support / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '1571da4a-b832-4792-917c-184c155b1700'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');
DELETE FROM inform.politician_answers
WHERE politician_id = '1571da4a-b832-4792-917c-184c155b1700'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

-- DELETED: Henry Stern / religious-freedom / former value=3 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');
DELETE FROM inform.politician_answers
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');

-- DELETED: Henry Stern / social-security / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security');
DELETE FROM inform.politician_answers
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security');

-- DELETED: Henry Stern / ukraine-support / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');
DELETE FROM inform.politician_answers
WHERE politician_id = 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

-- DELETED: Rob Bonta / ukraine-support / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');
DELETE FROM inform.politician_answers
WHERE politician_id = '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'ukraine-support');

-- ============================================================
-- POST-STATE RAISE NOTICE (informational — does NOT block commit)
-- Task 4 is responsible for formal STAX-01 verification.
-- ============================================================

DO $$
DECLARE
  v_unsourced_ca integer;
  v_weak_ca integer;
BEGIN
  -- V1: CA state unsourced stances (STAX-01 target: 0)
  SELECT COUNT(*) INTO v_unsourced_ca
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.politician_id = pa.politician_id
      AND COALESCE(o.is_vacant, false) = false
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
  )
  AND EXISTS (
    SELECT 1 FROM essentials.politicians p
    WHERE p.id = pa.politician_id AND p.is_active = true
  )
  AND (
    pc.politician_id IS NULL
    OR pc.sources IS NULL
    OR array_length(pc.sources, 1) IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) s(u)
      WHERE u IS NOT NULL AND trim(u) != ''
    )
  );
  RAISE NOTICE 'POST-MIGRATION CA STATE unsourced stances: %', v_unsourced_ca;

  -- V2: CA state weak-source stances (STAX-01 target: 0)
  -- A stance is weak if ALL non-blank source URLs match the homepage-only pattern
  SELECT COUNT(*) INTO v_weak_ca
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE o.politician_id = pa.politician_id
      AND COALESCE(o.is_vacant, false) = false
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC')
  )
  AND EXISTS (
    SELECT 1 FROM essentials.politicians p
    WHERE p.id = pa.politician_id AND p.is_active = true
  )
  AND pc.sources IS NOT NULL
  AND array_length(pc.sources, 1) IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(pc.sources) AS s(url)
    WHERE url IS NOT NULL AND trim(url) <> ''
      AND url !~ '^https?://[^/]+/?$'
  );
  RAISE NOTICE 'POST-MIGRATION CA STATE weak-source stances: %', v_weak_ca;
END $$;

-- Track this migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('282', '282_ca_state_source_remediation')
ON CONFLICT (version) DO NOTHING;

COMMIT;
