-- 1691_fix_turner_civil_rights_bill_numbers.sql
--
-- Veronica Turner / Civil Rights and Social Justice -- the last row still stating a bill number this
-- session disproved. Found because a corpus-wide check after 1690 still counted 1 row: 1690's own guard
-- was correctly scoped to the rows it touched, and this row was not one of them.
-- ⚠ Mig 1686 stripped this row's mismatched citation (it had pointed at the "Fair Chance in Housing Act")
-- but left the prose untouched, so it kept asserting the wrong numbers with no citation at all.
--
-- All THREE of its claims are true; only the numbers were wrong. Each verified by fetching the bill page
-- and finding `turner01` in its "Sponsored by" list:
--   "commission to review racial disparities in criminal justice (HB0810, 2026)" -> really 2026 HB1309
--        (2026 HB0810 is a blockchain property-recordation study, which she also sponsors -- hence the
--         bare-number collision that produced the wrong match in the first place)
--   "Fair Housing Act reform (HB0480)"                                          -> really 2026 HB0573
--        (2026 HB0480 is "Transportation Network Companies - Deactivation of Operators")
--   "supported Voting Rights Act 2026"                                          -> 2026 HB0350, and she
--        is in fact a SPONSOR, which is stronger than the prose claimed
--
-- Reasoning is voter-facing, so a wrong bill number there is a live misstatement. Precedent: 1524, 1526.
-- No stance VALUE is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-turner-civil-rights-1691-rollback.json
--
BEGIN
;

UPDATE inform.politician_context
SET sources = ARRAY[
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1309?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0573?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS',
      'https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation'
    ]::text[],
    reasoning = 'Sponsored HB1309 (2026) establishing a commission to review and assess racial disparities in the State criminal justice system; sponsored HB0573 (2026) on fair housing and housing discrimination; sponsored HB0350 (2026), the Voting Rights Act of 2026 for counties and municipal corporations; supports expansive civil rights protections.'
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;

DO $$
DECLARE bad int;
BEGIN
  -- Corpus-wide now: no stance may state any of the three disproved numbers.
  SELECT count(*) INTO bad FROM inform.politician_context
  WHERE reasoning LIKE '%HB0480%' OR reasoning LIKE '%HB0574%' OR reasoning LIKE '%HB0810%';
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still state a disproved bill number', bad; END IF;

  -- The row must carry all three verified citations.
  SELECT count(*) INTO bad FROM (VALUES
    ('https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1309?ys=2026RS'),
    ('https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0573?ys=2026RS'),
    ('https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0350?ys=2026RS')
  ) AS v(u)
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c, unnest(c.sources) s
    WHERE c.politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid
      AND c.topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
      AND s = v.u
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % verified citation(s) missing', bad; END IF;
END
$$;

COMMIT
;
