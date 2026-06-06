-- Phase 102: Federal House Remediation
-- Requirements covered: FEDX-02, QUAL-01, QUAL-02
-- Source CSV: backend/data/stance-research/2026-06-06-candidate-remediation.csv
-- Source deletion log: .planning/phases/102-federal-house-remediation/102-DELETION-LOG.md
--
-- Pre-write cross-check (per Task 3 spec):
--   Expected upserts: 7, deletes: 12, total = 19
--   (7) + (12) = 19 = Plan 01 flagged-stance count (Dooley 6 + Shoffner 5 + Alme 8) ✓
--   Intersection of UPSERT and DELETE (politician_id, topic_id) pairs: empty ✓
--   All UPSERT and DELETE rows reference exactly the 3 candidate UUIDs below ✓
--
-- Candidates remediating the Phase 101 deferred V2=19 issue (101-VERIFICATION.md / deferred-items.md):
--   Derek Dooley  (GA, R) UUID: b841a475-41b4-4f19-9ad1-13769b1f4eef
--   Hallie Shoffner (AR, D) UUID: a7307f34-90ca-4d29-8698-4898ed3de05c
--   Kurt Alme     (MT, R) UUID: 0f8bb5ea-8d89-4cfb-9291-04b54c128b82
--
-- Migration number: 269 (verified via SELECT MAX(version) → 268; next = 269)
-- Applied: 2026-06-06 via psql session pooler

BEGIN;

-- ============================================================
-- UPSERT BLOCK — 7 rows (from 2026-06-06-candidate-remediation.csv)
-- ============================================================

-- ---- Derek Dooley / healthcare / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'healthcare'),
  'Dooley''s priorities page states patients and doctors, not bureaucrats and insurance companies, should be making decisions about care. He frames government as an obstacle to remove, calls for transparency and patient choice, and supports rural hospital access — but proposes no public programs, public option, or expanded government coverage. Aligns with stance 4: only help the poorest and leave everyone else to employers and private insurance.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://dooleyforgeorgia.com/priorities/putting-patients-and-doctors-first'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Derek Dooley / immigration / value=4 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'immigration'),
  'Dooley states the open borders policy of the last administration was a disaster and calls for a secure border and enforcing the law. His Safe Communities page explicitly supports criminal deportation and law enforcement resources. Language is restrictionist — tighten border, enforce laws — without any pathway language or openness to legal immigration expansion. Aligns with stance 4: make it harder to immigrate legally and limit public services to people with legal status.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://dooleyforgeorgia.com/priorities/safe-communities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Derek Dooley / climate-change / value=5 (corrected from 4) ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  5
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'b841a475-41b4-4f19-9ad1-13769b1f4eef',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Dooley''s economic priorities page calls to unleash American energy and help drive down costs for businesses and families with no mention of climate change, renewable energy, or environmental regulation. His framing is purely market-driven energy expansion with government getting out of the way. No climate policy engagement found on any page of his campaign website. Aligns with stance 5: reject climate change policies and focus on economic growth.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://dooleyforgeorgia.com/priorities/more-jobs-higher-wages'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Hallie Shoffner / taxes / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7307f34-90ca-4d29-8698-4898ed3de05c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7307f34-90ca-4d29-8698-4898ed3de05c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'taxes'),
  'Shoffner''s priorities page contrasts her approach with Tom Cotton who cut taxes for billionaires and pledges to cut taxes for working families while also proposing to lift the contribution cap on the ultra wealthy to fund Social Security. This signals a redistributive approach — relief for working/middle class funded by higher contributions from the wealthy — which aligns with stance 2: moderately raise taxes on wealthy people and large companies to fund existing services.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.hallieshoffner.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Hallie Shoffner / economic-development / value=2 ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  'a7307f34-90ca-4d29-8698-4898ed3de05c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'economic-development'),
  2
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a7307f34-90ca-4d29-8698-4898ed3de05c',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'economic-development'),
  'Shoffner''s priorities page calls for an Arkansas-first economic plan centered on raising the minimum wage, expanding workforce training, apprenticeships, community college partnerships, and providing local businesses the resources they need to thrive. Emphasis is on small businesses and worker-focused programs with no language about competing for major employers via tax abatements or large corporate subsidies. Aligns with stance 2: small business support and local entrepreneur programs only; avoid large corporate subsidies.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://www.hallieshoffner.com/priorities'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Kurt Alme / abortion / value=4 (corrected from 5) ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion'),
  'Susan B. Anthony Pro-Life America endorsed Alme as a true pro-life champion in the Senate in April 2026, citing his commitment to keeping a pro-life Senate majority and preventing taxpayer-funded late-term abortion. SBA Pro-Life endorsees consistently support significant abortion restrictions — typically backing gestational limits and opposing public funding — which aligns with stance 4: restrict abortion to only cases involving rape, incest, or serious threats to the mother''s life.',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://sbaprolife.org/candidate-fund/leading-natl-pro-life-group-endorses-kurt-alme-for-mt-sen',
    'https://www.ontheissues.org/Senate/Kurt_Alme.htm'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ---- Kurt Alme / fossil-fuels / value=4 (corrected from 5) ----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES (
  '0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  4
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0f8bb5ea-8d89-4cfb-9291-04b54c128b82',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels'),
  'Montana Agricultural Political Action Committee (MAPA PAC) endorsed Alme, a body that explicitly supports candidates who protect and advance the interests of the agricultural, natural resources, and livestock industries. Alme''s campaign pledges to help President Trump put America First, aligning with the administration''s energy-expansion agenda. Evidence supports expanded fossil fuel drilling permits (stance 4) — not the more extreme remove-all-environmental-restrictions position (stance 5).',
  ARRAY(SELECT u FROM unnest(ARRAY[
    'https://mtbeef.org/montana-agricultural-political-action-committee-announces-2026-primary-election-endorsements/',
    'https://almeforsenate.com/'
  ]) AS u WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources = EXCLUDED.sources;

-- ============================================================
-- DELETE BLOCK — 12 rows (topics skipped by research agents)
-- Order: DELETE context FIRST, then answers (defensive ordering)
-- ============================================================

-- DELETED: Derek Dooley / abortion / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');
DELETE FROM inform.politician_answers
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');

-- DELETED: Derek Dooley / civil-rights / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');
DELETE FROM inform.politician_answers
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'civil-rights');

-- DELETED: Derek Dooley / voting-rights / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');
DELETE FROM inform.politician_answers
WHERE politician_id = 'b841a475-41b4-4f19-9ad1-13769b1f4eef'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

-- DELETED: Hallie Shoffner / campaign-finance / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');
DELETE FROM inform.politician_answers
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'campaign-finance');

-- DELETED: Hallie Shoffner / climate-change / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');
DELETE FROM inform.politician_answers
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

-- DELETED: Hallie Shoffner / housing / former value=2 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');
DELETE FROM inform.politician_answers
WHERE politician_id = 'a7307f34-90ca-4d29-8698-4898ed3de05c'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'housing');

-- DELETED: Kurt Alme / religious-freedom / former value=5 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'religious-freedom');

-- DELETED: Kurt Alme / same-sex-marriage / former value=5 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'same-sex-marriage');

-- DELETED: Kurt Alme / social-security / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'social-security');

-- DELETED: Kurt Alme / tariffs / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'tariffs');

-- DELETED: Kurt Alme / trans-athletes / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'trans-athletes');

-- DELETED: Kurt Alme / voting-rights / former value=4 / reason=no evidence found
DELETE FROM inform.politician_context
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');
DELETE FROM inform.politician_answers
WHERE politician_id = '0f8bb5ea-8d89-4cfb-9291-04b54c128b82'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'voting-rights');

-- ============================================================
-- POST-STATE RAISE NOTICE (informational — does NOT block commit)
-- Task 4 is responsible for formal FEDX-02 verification.
-- ============================================================

DO $$
DECLARE
  v_unsourced_nl integer;
  v_homepage_only_nu integer;
BEGIN
  -- V1: Unsourced NATIONAL_LOWER stances (FEDX-02 target: 0)
  SELECT COUNT(*) INTO v_unsourced_nl
  FROM inform.politician_answers pa
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE pa.politician_id IN (
    SELECT DISTINCT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'NATIONAL_LOWER' AND p.is_active = true
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
  RAISE NOTICE 'POST-MIGRATION NATIONAL_LOWER unsourced stances: %', v_unsourced_nl;

  -- V2: Homepage-only stances across ALL active NATIONAL_UPPER politicians
  -- (incumbent AND candidate — closes Phase 101 deferred V2=19 issue)
  SELECT COUNT(*) INTO v_homepage_only_nu
  FROM inform.politician_context pc
  WHERE pc.politician_id IN (
    SELECT DISTINCT p.id
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
  )
  AND pc.sources IS NOT NULL
  AND array_length(pc.sources, 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
      AND trim(u) !~ '^https?://[^/]+/?$'
  )
  AND EXISTS (
    SELECT 1 FROM unnest(pc.sources) s(u)
    WHERE u IS NOT NULL AND trim(u) != ''
  );
  RAISE NOTICE 'POST-MIGRATION NATIONAL_UPPER homepage-only stances: %', v_homepage_only_nu;
END $$;

-- Track this migration in schema_migrations
INSERT INTO supabase_migrations.schema_migrations (version, name)
VALUES ('269', '269_house_source_remediation')
ON CONFLICT (version) DO NOTHING;

COMMIT;
