-- 1705_resource_md_coley_rows.sql
-- Derrick Coley (MD House, seated 2026-01-13) -- his 7 remaining generic-only rows.
-- 5 re-sourced to his own 2026 sponsorships, 2 rejected on the evidence and only URL-normalised.
--
-- ⚠ CORRECTION TO AN EARLIER CLAIM OF MINE: I recorded that "all 10 of Coley's rows cite
-- coley01?tab=2023RS-legislation". That was wrong. It came from reading a guard's match COUNT on the
-- pattern '%coley01?tab=%', which matches ANY session tab. The real spread is 4 rows on ?tab=2025RS
-- (a session before he was seated, so the tab lists nothing) and 3 on ?tab=2026RS (his real first
-- session, so that tab is valid, though still a generic bill LIST rather than a per-topic source).
-- A count is not a description.
--
-- METHOD: fetched his 2026RS legislation tab (124 bills), resolved titles against the 73,232-bill
-- corpus, screened by topic, READ every candidate, then confirmed sponsorship by finding coley01 in
-- each cited bill's "Sponsored by" list. 2026RS is his ONLY session of record.
--
-- ⚠ HONEST WEIGHT: several are broadly co-sponsored (HB0444 has 81 sponsors, HB0637 55, HB0894 47).
-- A co-sponsorship among dozens is a real recorded position but weaker than lead sponsorship, so the
-- reasoning says "co-sponsored" and claims nothing beyond the bill's own subject.
--
-- 🔴 TWO ROWS GET NO CITATION, and both rejections are the point of this workstream:
--   Public Safety -- nothing in his record is mental-health crisis response or violence prevention,
--     and his public-safety bills point in OPPOSITE directions ("Eluding Police - Penalties" is
--     enforcement-heavy, the "ICE Breaker Act" restricts enforcement hiring). No coherent position.
--   Taxation -- his tax bills are a Veterans' Day tax-free day, a retail-service-station property tax
--     credit, a classroom-supplies subtraction and the Theatrical Production Tax Credit. ⚠ That is
--     the SAME CLASS mig 1697 rejected BY NAME for a progressive-taxation chair. A narrow targeted
--     credit does not pin "tax the wealthy", and several of these are tax CUTS.
--
-- ⚠ A SUBSTRING ARTIFACT CAUGHT BY READING: the housing screen also returned "Maryland Public
-- Education PARENTAL Partnership Act" because "Parental" contains "rental". Rejected. Same family as
-- the Socrata "Tran" -> "Transportation" mislinks.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-coley-rows-rollback.json
--
BEGIN
;

CREATE TEMP TABLE coley_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

-- Immigration -- the strongest. Old prose claimed "language access" and "community support
-- programs", neither of which these bills are.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1575?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Co-sponsored 2026 legislation prohibiting state and local immigration-enforcement agreements (HB0444) and limiting enforcement cooperation through the Community Trust Act (HB1575).'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;

-- Economic Development Incentives
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0898?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0864?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Co-sponsored the 2026 DECADE Act on economic competitiveness and development (HB0898) and apprenticeship requirements for public works contracts (HB0864).'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid
;

-- Affordable Housing
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0894?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Co-sponsored the 2026 Maryland Transit and Housing Opportunity Act (HB0894), altering land-use rules to enable transit-oriented housing development.'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
;

-- Civil Rights -- old prose claimed "racial equity and LGBTQ+ protection"; HB0536 is neither.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0536?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Co-sponsored 2026 legislation requiring employers to provide reasonable accommodations for disabilities arising from childbirth and menopause (HB0536), one of only eight sponsors.'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;

-- Healthcare Access -- weakest of the five, and written as such. NOT Medicaid expansion.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0637?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Co-sponsored 2026 legislation letting pharmacists administer recommended immunizations, screenings and preventive services (HB0637), expanding access to preventive care.'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid
;

-- ===== URL NORMALISATION ONLY -- no citation, because the evidence does not carry the chair =====
-- ?tab=2025RS points at a session before he held office, so it is affirmatively misleading. The bare
-- slug was verified to resolve to "Members - Delegate Derrick Coley". Reasoning left UNTOUCHED: these
-- rows remain unsourced and belong in the human reading queue, and pretending otherwise is the defect.
UPDATE inform.politician_context
SET sources = ARRAY['https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01']::text[]
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id IN (
    'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,  -- Public Safety Approach
    'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid   -- Taxation and Public Spending
  )
;

-- Guard 1: NO row of Coley's may still carry a ?tab= URL. ⚠ Unlike migs 1700/1704, a politician-wide
-- assertion IS correct here, because this migration touches every remaining row of his that had one.
-- Scope the guard to what the migration changed -- which this time is all of them.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
    AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%?tab=%');
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % Coley row(s) still cite a ?tab= member page', bad;
  END IF;
END
$$;

-- Guard 2: the 5 re-sourced rows carry a bill citation; the 2 rejected rows deliberately do NOT.
DO $$
DECLARE missing int; wrongly_cited int;
BEGIN
  SELECT count(*) INTO missing FROM inform.politician_context c
  WHERE c.politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
    AND c.topic_id IN (
      '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid, 'eb3d1247-0de1-4b7f-baec-7259861efd53'::uuid,
      '669cac97-66a6-4087-b036-936fbe62efb3'::uuid, '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid,
      'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid)
    AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF missing > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % re-sourced row(s) lack a bill citation', missing;
  END IF;

  SELECT count(*) INTO wrongly_cited FROM inform.politician_context c
  WHERE c.politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
    AND c.topic_id IN (
      'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid, 'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid)
    AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF wrongly_cited > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % rejected row(s) gained a bill citation they should not have', wrongly_cited;
  END IF;
END
$$;

-- Guard 3: citations and reasoning only -- nothing created or deleted.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM coley_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 3 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 3 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 3 failed: % answer(s) without context', orphans;
  END IF;
  RAISE NOTICE 'coley ok: context=% (unchanged) answers=% (unchanged) orphans=%',
    ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
