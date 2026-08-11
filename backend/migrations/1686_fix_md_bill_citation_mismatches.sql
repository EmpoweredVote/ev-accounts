-- 1686_fix_md_bill_citation_mismatches.sql
--
-- SELF-CORRECTION to migration 1685. 3 of the 229 citations 1685 attached point at a REAL bill the
-- legislator really sponsored, but NOT the instrument the row's reasoning names. Sponsorship matching
-- proved "this legislator sponsored this bill"; it never proved "this bill is the one being discussed".
--
-- ROOT CAUSE 1 -- A BARE BILL NUMBER IS AMBIGUOUS ACROSS SESSIONS. "HB0993" is the Asian American
--   History bill in the reasoning's intent but "Maryland Pension Risk Mitigation Act" in 2018RS.
--   Matching a number across 14 sessions and then confirming sponsorship attaches a real, unrelated bill.
-- ROOT CAUSE 2 -- A LOOSE (token-subset) act-name match lands on a differently-named act:
--   "CROWN Act" -> "Crown and Care Act"; "Fair Housing Act" -> "Fair Chance in Housing Act".
--
-- Found by scripts/audit-1685-citation-fit.mjs, which checks whether the bill TITLE carries the act the
-- reasoning names. 221 of 229 passed that test outright; 8 were read by hand; 5 of those 8 were the
-- audit being too strict (the act sits in a parenthetical: "Climate Crimes Accountability Act",
-- "Edna G. Neal Palliative Care Act", "Retail Energy Modernization and Consumer Choice Act",
-- "Survivor Reporting Reform Act") and are correct. These 3 are genuinely wrong.
--
-- 1 REPAIRED, 2 REMOVED. Each disposition was decided by fetching the CORRECT bill and checking the
-- legislator's own mgaleg slug in its "Sponsored by" list:
--   Valderrama  REPOINT  2018RS HB0993 -> 2026RS HB1059 "State Department of Education - Asian American
--                        History - Accurate Instruction". Her reasoning's phrase "accurate instruction"
--                        matches this title exactly; slug `valderrama` IS a sponsor (verified).
--   Kim Ross    REMOVE   Maryland's real CROWN Act is 2020RS SB0531/HB1444 ("Discrimination - Definition
--                        of Race - Hair Texture and Hairstyles" -- the title does not contain "CROWN").
--                        Slug `ross01` is NOT a sponsor of either. Claim is UNVERIFIED, not disproven;
--                        the row keeps its stance and returns to the reading queue.
--   Turner      REMOVE   Slug `turner01` is NOT a sponsor of the Fair Housing Opportunities Act of 2019
--                        (2019RS HB0451/SB0812). Row returns to the reading queue.
--
-- No stance VALUE is modified. Ross and Turner lose their bill citation by design.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-citation-fix-1686-rollback.json
--
BEGIN
;

-- Kriselda Valderrama / Civil Rights and Social Justice -- repoint to the correct bill.
UPDATE inform.politician_context
SET sources = ARRAY[
  'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb1059?ys=2026RS',
  'https://mgaleg.maryland.gov/mgawebsite/Members/Details/valderrama?tab=2026RS-legislation'
]::text[]
WHERE politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;

-- Kim Ross / Civil Rights and Social Justice -- drop the mismatched Crown and Care Act citation.
UPDATE inform.politician_context
SET sources = ARRAY[
  'https://mgaleg.maryland.gov/mgawebsite/Members/Details/ross01',
  'https://ballotpedia.org/Kim_Ross'
]::text[]
WHERE politician_id = '5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;

-- Veronica Turner / Civil Rights and Social Justice -- drop the mismatched Fair Chance in Housing citation.
UPDATE inform.politician_context
SET sources = ARRAY[
  'https://mgaleg.maryland.gov/mgawebsite/Members/Details/turner01?tab=2026RS-legislation'
]::text[]
WHERE politician_id = '7a76712a-38cd-41de-b260-cd0127284f16'::uuid
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
;

-- Guards.
DO $$
DECLARE bad int;
BEGIN
  -- The three wrong citations must be gone from the entire corpus.
  SELECT count(*) INTO bad
  FROM inform.politician_context c
  WHERE EXISTS (
    SELECT 1 FROM unnest(c.sources) s
    WHERE s LIKE '%Details/hb0993?ys=2018RS%'
       OR s LIKE '%Details/hb1533?ys=2026RS%'
       OR s LIKE '%Details/hb0964?ys=2024RS%'
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite a mismatched bill', bad; END IF;

  -- Valderrama must now carry the correct bill.
  SELECT count(*) INTO bad
  FROM inform.politician_context c
  WHERE c.politician_id = '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid
    AND c.topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
    AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Details/hb1059?ys=2026RS%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: Valderrama lacks the corrected citation'; END IF;

  -- Nobody may be left with an empty source list.
  SELECT count(*) INTO bad
  FROM inform.politician_context c
  WHERE c.politician_id IN (
    '768ac1cf-a599-4ddb-943c-c985fafb2607'::uuid,
    '5d17e3ea-9d63-4a96-8848-9e293ac05fdb'::uuid,
    '7a76712a-38cd-41de-b260-cd0127284f16'::uuid)
    AND c.topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'::uuid
    AND (c.sources IS NULL OR cardinality(c.sources) = 0);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) left with no sources', bad; END IF;
END
$$;

COMMIT
;
