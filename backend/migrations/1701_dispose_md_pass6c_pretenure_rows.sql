-- 1701_dispose_md_pass6c_pretenure_rows.sql
-- Maryland PASS 6c -- dispose of the 7 pre-tenure rows that SURVIVED the pass-6b re-screen.
--
-- Pass 6 produced 21 PRE_TENURE verdicts; pass 6b (mig 1700) showed 13 were wrong. These are the
-- remaining 7: each names an instrument that exists ONLY in sessions before the member was seated,
-- so the claim as written is IMPOSSIBLE, not merely unsourced.
--
-- 🔑 THE STANDARD (Guzzone, migs 1690 vs 1692): same politician, same pre-tenure prose, OPPOSITE
-- dispositions, because the evidence differed. Search for in-tenure evidence FIRST; retire only
-- where there is none. Applied here: 3 RE-SOURCED, 4 RETIRED.
--
-- 🔴 THE AUTOMATED SEARCH SAID 4 RE-SOURCE / 3 RETIRE. READING THE CANDIDATES MADE IT 3 / 4.
-- Kym Taylor's only match was 2026RS HB0645 "Criminal Law - Fraud - Assisted Reproductive
-- Treatment", offered for an ABORTION ACCESS chair. Fertility fraud is not abortion access.
-- ⚠ That is the SAME BILL mig 1697 already rejected for the same reason, now surfacing on a
-- different politician -- the collision is a property of the bill title, not of one row.
-- On-topic by VOCABULARY is not on-topic by RATIONALE.
--
-- Reasoning is rewritten on every re-sourced row: it is voter-facing, and each one asserted a vote
-- the member could not have cast (precedent 1524/1526/1690).
--
-- Nobody is emptied: Martinez 12 rows, Roberts 11, Coley 11, Roberson 11, Taylor 12.
-- last_stances_researched_at stays NULL for all, so a retired topic RESURFACES for re-research
-- rather than reading as "we looked and found nothing" (precedent 1677).
--
-- Rollback -- the only surviving copy of the retired reasoning/sources/values:
--   backend/data/stance-retirement/2026-08-11-md-pass6c-pretenure-rollback.json
--
BEGIN
;

CREATE TEMP TABLE pass6c_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

-- ============ RE-SOURCED (3) ============

-- Ashanti Martinez / Immigration -- seated 2023-02-24; the RELIEF Act is 2021RS SB0496, impossible.
-- He sponsors three in-tenure bills limiting immigration-enforcement cooperation.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1575?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0630?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01'
    ]::text[],
    reasoning = 'Sponsored 2026 legislation prohibiting state and local immigration-enforcement agreements (HB0444), restricting immigration detention facilities (HB0630), and limiting enforcement cooperation (HB1575) — a consistent pro-immigrant record.'
WHERE politician_id = 'd8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid
;

-- Ashanti Martinez / Reproductive -- the Abortion Care Access Act is 2022RS only.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0930?ys=2025RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1131?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/martinez01'
    ]::text[],
    reasoning = 'Sponsored the 2025 Public Health Abortion Grant Program (HB0930) and the 2026 Pregnancy Outcome Protection Act (HB1131) — supports expanding abortion access and shielding pregnancy outcomes from prosecution.'
WHERE politician_id = 'd8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid
  AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;

-- Kent Roberson / Reproductive -- seated 2023-05-30, AFTER the 2023 session adjourned, so his first
-- session is 2024 and the 2022 ACAA is doubly impossible.
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0930?ys=2025RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/roberson01'
    ]::text[],
    reasoning = 'Sponsored the 2025 Public Health Abortion Grant Program (HB0930), which funds abortion care for uninsured and underinsured patients — supports expanding access.'
WHERE politician_id = '338210ee-b9ab-4820-bfce-98f5354837af'::uuid
  AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid
;

-- ============ RETIRED (4) ============
-- 🔑 Retire = DELETE the answer AND the context row. Context alone strands an orphan answer.
-- Answers first, then context.

DELETE FROM inform.politician_answers WHERE (politician_id, topic_id) IN (
  ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid), -- Denise Roberts / Reproductive
  ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid), -- Derrick Coley / Climate
  ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid), -- Derrick Coley / Reproductive
  ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid)  -- Kym Taylor / Reproductive
)
;

DELETE FROM inform.politician_context WHERE (politician_id, topic_id) IN (
  ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
  ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
  ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
  ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid)
)
;

-- Guard 1 (scoped to the touched rows only): the 3 re-sourced rows carry a bill citation and none
-- of them still cites a ?tab= member page. ⚠ '?' is a LITERAL in LIKE, so these patterns are exact.
-- ⚠ Scope to (politician_id, topic_id), never politician_id alone -- Martinez and Roberson each hold
-- other rows that legitimately still cite the ?tab= URL and are untouched here (this exact mistake
-- failed the first draft of mig 1700's guard).
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('d8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid,'4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid),
    ('d8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('338210ee-b9ab-4820-bfce-98f5354837af'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid)
  )
  AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%')
       OR EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%?tab=%'));
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % re-sourced row(s) lack a bill cite or still carry ?tab=', bad;
  END IF;
END
$$;

-- Guard 2: the 4 retired rows are gone from BOTH tables.
DO $$
DECLARE left_ctx int; left_ans int;
BEGIN
  SELECT count(*) INTO left_ctx FROM inform.politician_context WHERE (politician_id, topic_id) IN (
    ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid));
  SELECT count(*) INTO left_ans FROM inform.politician_answers WHERE (politician_id, topic_id) IN (
    ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),
    ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid));
  IF left_ctx > 0 OR left_ans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % context and % answer row(s) survived the retirement', left_ctx, left_ans;
  END IF;
END
$$;

-- Guard 3: deltas against the in-transaction snapshot -- EXACTLY -4 on both tables, orphans 0,
-- and nobody emptied. Never asserted against a hard-coded corpus total.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; emptied int; snap record;
BEGIN
  SELECT * INTO snap FROM pass6c_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF ctx_after <> snap.ctx_before - 4 THEN
    RAISE EXCEPTION 'guard 3 failed: context % -> %, expected -4', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before - 4 THEN
    RAISE EXCEPTION 'guard 3 failed: answers % -> %, expected -4', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 3 failed: % answer(s) without context', orphans;
  END IF;

  -- ⚠ NOT "GROUP BY politician_id HAVING count(*) = 0" -- an emptied politician has NO rows left to
  -- group, so that form can never return one and the guard would pass unconditionally. Drive the
  -- check from a literal list of the politicians this migration deleted from, and assert each still
  -- HAS rows. (Second tautological guard caught by re-reading my own SQL; see mig 1698.)
  SELECT count(*) INTO emptied
  FROM (VALUES
    ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid),
    ('9273ed81-2052-428a-b39d-849abeef270b'::uuid)) AS v(pid)
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = v.pid);
  IF emptied > 0 THEN
    RAISE EXCEPTION 'guard 3 failed: % politician(s) emptied', emptied;
  END IF;

  RAISE NOTICE 'pass6c ok: context % -> %, answers % -> %, orphans %',
    snap.ctx_before, ctx_after, snap.ans_before, ans_after, orphans;
END
$$;

COMMIT
;
