-- 1700_resource_md_pass6b_rescreened_rows.sql
-- Maryland PASS 6b -- the two rows freed by re-screening pass 6's contaminated PRE_TENURE verdicts.
--
-- WHY: pass 6's tenure screen produced 21 PRE_TENURE_ALL_BILLS verdicts. A pre-tenure verdict is a
-- claim that a stance was IMPOSSIBLE -- the strongest claim in this workstream, and the one that
-- justifies deletion (mig 1692). Re-screened, **13 of the 21 were wrong**, for two reasons:
--   1. the resolver had attached bills from the wrong sessions, so tenure was judged against the
--      wrong instrument (Mark Edelson was screened on 2013RS bills; his are 2024-2026);
--   2. the screen read each member's CURRENT mgaleg page, which carries only their CURRENT CHAMBER
--      -- so a chamber switch erases the earlier service. Sara Love's Senate page says "since
--      June 13, 2024" while love01?ys=2023RS says "Delegate Sara Love ... House since 2019-01-09".
--
-- This migration applies only the two rows where the corrected screen found the member IN TENURE
-- and sponsoring the instrument their own reasoning names. Everything else stays in the queue.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-pass6b-rescreen-rollback.json
--
BEGIN
;

CREATE TEMP TABLE pass6b_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

-- Mark Edelson / Fossil Fuel Policy -- citations only; his reasoning already names both instruments
-- correctly ("Cost Recovery - Limitations" AND the "Climate Alignment Act") and he sponsors both.
UPDATE inform.politician_context
SET sources = ARRAY[
  'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0001?ys=2026RS',
  'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0437?ys=2026RS',
  'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0084?ys=2025RS',
  'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0836?ys=2024RS',
  'https://mgaleg.maryland.gov/mgawebsite/Members/Details/edelson01'
]::text[]
WHERE politician_id = 'bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'::uuid
;

-- Derrick Coley / Voting Rights -- seated 2026-01-13, so the stated 2023 VOTE is impossible. He
-- SPONSORS the Voting Rights Act of 2026 (HB0350), which is stronger than the "voted for" claimed.
-- Reasoning is corrected because it is voter-facing and a wrong year is a live misstatement
-- (precedent 1524/1526; same disposition as Odom and Stinnett in mig 1697).
-- The old member-page URL carried ?tab=2023RS-legislation -- a session three years before he was
-- seated -- so it is normalised to the bare slug, verified to resolve to "Delegate Derrick Coley".
UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/coley01'
    ]::text[],
    reasoning = 'Sponsored the Voting Rights Act of 2026 (HB0350) covering counties and municipal corporations; supports expanded voter registration and ballot access.'
WHERE politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
  AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
;

-- Guard 1 (scoped): both rows must now carry a bill citation, and neither may still cite the
-- ?tab= variant. ⚠ '?' is a LITERAL in LIKE, so this pattern is exact, not a wildcard.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad
  FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ('bec4b395-bb4b-4740-ac1c-8e89f12608a2'::uuid,'a22215c3-6693-4bc2-b248-01aebba14570'::uuid),
    ('8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid,'d1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid)
  )
  AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % row(s) lack a bill citation', bad;
  END IF;

  -- ⚠ SCOPE THE ASSERTION TO THE ROW, NOT JUST THE POLITICIAN. The first draft of this guard keyed
  -- on politician_id alone and failed at 10 rows -- Coley has 10 stances that ALL cite
  -- coley01?tab=2023RS-legislation, and this migration repairs exactly ONE of them. The other 9 are
  -- untouched and still carry it legitimately. Fourth time an over-broad assertion has bitten this
  -- workstream (migs 1524, 1530, 1689). A guard must assert only about what the migration changed.
  SELECT count(*) INTO bad
  FROM inform.politician_context c
  WHERE c.politician_id = '8fab5ff7-603d-4ab0-a05c-a7070d187a48'::uuid
    AND c.topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'::uuid
    AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%coley01?tab=%');
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: the repaired Coley row still cites the ?tab= member page';
  END IF;
END
$$;

-- Guard 2: nothing created or deleted. Compared against the in-transaction snapshot above, never
-- against a hard-coded corpus total, and never against a count taken in the same statement.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM pass6b_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans
  FROM inform.politician_answers a
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
  );
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 2 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 2 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % answer(s) without context', orphans;
  END IF;
  RAISE NOTICE 'pass6b ok: context=% (unchanged) answers=% (unchanged) orphans=%',
    ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
