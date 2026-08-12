-- 1704_resource_md_pass6d_intenure_rollcalls.sql
-- Maryland PASS 6d -- the 11 IN_TENURE rows left after mig 1700, settled by PASSAGE roll calls.
-- 7 applied, 4 deliberately not.
--
-- 🔑 THE BILL WAS IDENTIFIED BEFORE THE VOTE WAS BELIEVED. Six rows settle on 2026RS SB0311,
-- "Education - The Blueprint for Maryland's Future - REVISIONS". A *revisions* bill's direction is
-- not self-evident -- it could expand, delay or gut the programme -- so its synopsis was read first:
-- it extends the compensatory-education enrolment calculation through FY2028 and repeals the
-- termination date on Concentration of Poverty Grant funding (both preserve targeted public-school
-- funding), while suspending the Expert Review Team Programme. It passed 96-37 in the House and
-- 30-11 in the Senate, so the vote discriminates rather than being a formality.
--
-- 🔴 IT SAYS NOTHING ABOUT VOUCHERS. Every one of these rows led with "Voted against school voucher
-- legislation" -- a specific we searched for and could not source. Rather than attach an
-- authoritative-looking citation to an unsupported sentence (the exact defect this workstream
-- exists to remove), the voucher clause is REMOVED from the voter-facing reasoning and each row now
-- states only what the roll call actually shows. Reasoning is voter-facing (precedent 1524/1526).
--
-- ⚠ IDENTITY. Vote sheets list bare surnames. Checked against the MGA House roster: Taylor, Coley,
-- Roberson, Toles and Martinez are each UNIQUE in the House. The genuine collisions there are
-- Johnson, Jones, Long and Morgan -- none of which appears in this cohort.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-pass6d-rollcall-rollback.json
--
BEGIN
;

CREATE TEMP TABLE pass6d_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

-- Karen Toles / Reproductive -- the strongest row in the set. YEA on the Abortion Care Access Act
-- itself, House Third Reading Passed 89-47. Seated 2022-01-12, during that session. The prose said
-- "(2023)"; the Act exists in 2022RS only, so the substance is TRUE and the year was wrong.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0937?ys=2022RS',
      'https://mgaleg.maryland.gov/2022RS/votes/house/0291.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01'
    ]::text[],
    reasoning = 'Voted for the Abortion Care Access Act (2022 HB0937), which expanded abortion-care training and removed cost barriers to abortion services — supports expanding access.'
WHERE politician_id = 'cd422f8c-913b-4280-987b-9383ead34e85'::uuid
  AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;

-- ===== 2026RS SB0311, House 96-37 =====

UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/house/1271.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311), extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = 'd8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/house/1271.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311), extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/house/1271.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311), extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = '338210ee-b9ab-4820-bfce-98f5354837af'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/house/1271.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/taylor03'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311), extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = '9273ed81-2052-428a-b39d-849abeef270b'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

-- Supersedes the HOLD recorded in mig 1700: that was a sponsorship of an implementation-coordinator
-- funding bill, which could not carry the chair. This is a recorded floor vote on the revisions.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/house/1271.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/toles01'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311), extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = 'cd422f8c-913b-4280-987b-9383ead34e85'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

-- ===== 2026RS SB0311, SENATE 30-11 (Love moved to the Senate in June 2024) =====
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/sb0311?ys=2026RS',
      'https://mgaleg.maryland.gov/2026RS/votes/senate/0580.pdf',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/love02',
      'https://ballotpedia.org/Sara_Love'
    ]::text[],
    reasoning = 'Voted for the 2026 Blueprint for Maryland''s Future revisions (SB0311) in the Senate, extending the compensatory-education funding calculation and preserving Concentration of Poverty Grant funding — supports sustained public school investment.'
WHERE politician_id = 'c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid
  AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
;

-- Guard 1 (scoped to the 7 touched rows): each must carry a bill citation AND a vote sheet, and none
-- may still carry a ?tab= member page. ⚠ Scope to (politician_id, topic_id) -- these politicians hold
-- other rows that legitimately still cite ?tab= URLs (this exact over-broad mistake failed the first
-- draft of mig 1700's guard; migs 1524, 1530, 1689 are the earlier instances).
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('cd422f8c-913b-4280-987b-9383ead34e85'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('d8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('338210ee-b9ab-4820-bfce-98f5354837af'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('cd422f8c-913b-4280-987b-9383ead34e85'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid)
  )
  AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%')
       OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%/votes/%')
       OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%?tab=%'));
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed on % row(s): missing bill cite, missing vote sheet, or ?tab= survived', bad;
  END IF;
END
$$;

-- Guard 2: no row may still assert the unsourceable voucher-vote claim, and Toles's reproductive row
-- must no longer state the impossible 2023 year. Scoped to the touched rows only.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('d8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('338210ee-b9ab-4820-bfce-98f5354837af'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('cd422f8c-913b-4280-987b-9383ead34e85'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid),
    ('c5d2cd24-170a-4f87-8fde-84216fe62806'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid))
    AND c.reasoning ILIKE '%voucher%';
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % row(s) still assert an unsourced voucher claim', bad;
  END IF;

  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = 'cd422f8c-913b-4280-987b-9383ead34e85'::uuid
    AND c.topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
    AND c.reasoning LIKE '%2023%';
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: Toles reproductive row still states 2023';
  END IF;
END
$$;

-- Guard 3: citations only -- nothing created or deleted. Compared against the in-transaction
-- snapshot, never against a hard-coded corpus total.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM pass6d_snapshot;
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
  RAISE NOTICE 'pass6d ok: context=% (unchanged) answers=% (unchanged) orphans=%',
    ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
