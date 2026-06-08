---
phase: 106-dc-stance-research
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - supabase/migrations/20260608000001_289_dc_mayor_council_ag_stances.sql
  - supabase/migrations/20260608000002_290_dc_sboe_stances.sql
  - supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql
  - backend/data/stance-research/2026-06-08-106-dc-mayor-council-ag.csv
  - backend/data/stance-research/2026-06-08-106-ehn-gap-fill.csv
findings:
  critical: 1
  warning: 2
  info: 1
  total: 4
status: issues_found
---

# Phase 106: Code Review Report

**Reviewed:** 2026-06-08T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five files reviewed: three SQL migrations (289–291) and two research CSVs for DC Mayor/Council/AG stances, DC SBOE (honest-skip), and DC Shadow Senators + EHN gap-fill.

Migration 290 is a correct traceability record with zero INSERTs and a well-documented D-07 honest-skip. Migration 291 row counts are internally consistent (6 Jain + 19 EHN = 25 each for `politician_answers` and `politician_context`). The D-08 EHN invariant is satisfied (pre-flight returned 0 rows, all 19 topics are new inserts). All UUID literals cross-check against the declared UUID maps. All topic_keys in scope were verified against the DC topics snapshot and `compass-topics-reference.md`.

One BLOCKER was found: Charles Allen's `sources` array is structurally broken in migration 289 due to an unescaped comma-containing URL. Two WARNINGs are raised: a post-COMMIT RAISE NOTICE placement inconsistency in migration 291, and a D-11 compliance gap in EHN's misinformation reasoning. One INFO finding covers a `campaign-finance` value calibration concern affecting four DC Council members.

---

## Critical Issues

### CR-01: Charles Allen — ARRAY constructor splits URL into three invalid fragments

**File:** `supabase/migrations/20260608000001_289_dc_mayor_council_ag_stances.sql:618` (also line 638)
**Issue:** The Wikipedia URL for Charles Allen contains commas — `https://en.wikipedia.org/wiki/Charles_Allen_(Washington,_D.C.,_politician)` — and was pasted directly as a SQL string literal inside `ARRAY[...]`. Postgres parses the commas as array element separators, producing a three-element array:
```
{https://en.wikipedia.org/wiki/Charles_Allen_(Washington, _D.C., _politician)}
```
All three fragments are non-empty strings, so the `WHERE trim(u) != ''` filter does not discard them. The `sources` column for both Allen rows (`public-safety-approach` and `campaign-finance`) stores three broken, non-functional URL fragments instead of one valid URL. This affects two `politician_context` rows.

**Fix:** Concatenate the URL with string concatenation to avoid mid-string comma parsing, or use a single-element ARRAY with the full URL in one literal. The comma-containing URL requires escaping the commas inside the array literal — the safest fix is to use `|| ',' ||` string joins or double-check the literal boundary carefully:

```sql
-- Correct: single string literal, no internal commas breaking array parsing
ARRAY(SELECT u FROM unnest(ARRAY[
  'https://en.wikipedia.org/wiki/Charles_Allen_(Washington' || ',' || '_D.C.' || ',' || '_politician)'
]) AS u WHERE u IS NOT NULL AND trim(u) != '')
```

Or more simply, use the URL-encoded form which avoids commas entirely:
```sql
ARRAY(SELECT u FROM unnest(ARRAY[
  'https://en.wikipedia.org/wiki/Charles_Allen_%28Washington%2C_D.C.%2C_politician%29'
]) AS u WHERE u IS NOT NULL AND trim(u) != '')
```

Or, since this is a plain text[] column (not parsed as hyperlink), the most readable fix wraps the entire URL in a subquery that avoids the problematic ARRAY literal:
```sql
ARRAY['https://en.wikipedia.org/wiki/Charles_Allen_(Washington,_D.C.,_politician)']::text[]
```
Wait — that same literal with commas has the identical parse problem. Use the `||` concatenation approach or URL-encoding.

---

## Warnings

### WR-01: Migration 291 — RAISE NOTICE block executes after COMMIT (outside transaction)

**File:** `supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql:613–623`
**Issue:** The `COMMIT;` statement appears at line 613. The `DO $$ BEGIN RAISE NOTICE ... END $$;` reporting block appears at lines 615–623, outside the transaction boundary. In migration 289, the equivalent DO block is inside the transaction (before COMMIT). The migration 291 placement means the NOTICE runs in autocommit mode and is not rolled back if the migration runner encounters an error before this point. More importantly, in some migration runners the post-COMMIT DO block may not execute in the same session context, potentially silently dropping the NOTICE output.

**Fix:** Move the `DO $$ BEGIN RAISE NOTICE ... END $$;` block to before the `COMMIT;` statement, consistent with migration 289's pattern:
```sql
DO $$ BEGIN
  RAISE NOTICE 'Migration 291 complete: ...';
  ...
END $$;

COMMIT;
```

### WR-02: EHN `misinformation` value=2 — D-11 violation (explicit acknowledgment of no direct evidence)

**File:** `supabase/migrations/20260608000003_291_dc_shadow_senators_ehn_stances.sql:424–432`
Also: `backend/data/stance-research/2026-06-08-106-ehn-gap-fill.csv:12`
**Issue:** The reasoning for EHN's `misinformation` stance (value=2) explicitly states: "While her specific position on algorithmic misinformation policy is not extensively documented in public records." This is a self-reported D-11 violation. D-11 requires that a value assignment match a specific FIVE-CHAIRS stance text citing an actual documented position. Instead, this value is inferred from EHN's positions on campaign finance disclosure — a different domain. The stance text for misinformation value=2 is "mandate fact-checking and transparency in how algorithms promote content," which is not supported by the cited evidence.

**Fix:** Apply D-06 (skip > infer). Remove the `misinformation` rows for EHN from both the CSV and migration 291 if no direct evidence is available. If the rows are retained, the reasoning must cite a specific source where Norton expressed a position matching the exact value=2 stance text.

---

## Info

### IN-01: `campaign-finance` value=1 miscalibration for DC Fair Elections Act supporters (four DC Council members)

**File:** `supabase/migrations/20260608000001_289_dc_mayor_council_ag_stances.sql:168–186, 296–314, 404–422, 624–642`
Also: `backend/data/stance-research/2026-06-08-106-dc-mayor-council-ag.csv:8,14,19,29`
**Issue:** Phil Mendelson, Robert C. White Jr., Brianne K. Nadeau, and Charles Allen are all assigned `campaign-finance` value=1 ("ban all private money in politics and publicly fund campaigns") based on their support for DC's Fair Elections Act. The Fair Elections Act implements a public **matching funds** program — it does not ban private contributions. Candidates still accept private money up to lower limits; the public match amplifies small donors. The correct FIVE-CHAIRS alignment for this policy is value=2 ("strictly limit corporate donations and dark money groups"), not value=1. Value=1 implies full prohibition of private money, which the Act does not do.

This is a calibration issue affecting four rows in each of `politician_answers` and `politician_context` (8 total rows). It does not break the migration technically, but it misrepresents the politicians' positions.

**Fix:** Change `campaign-finance` value from 1 to 2 for Mendelson, White Jr., Nadeau, and Allen. Update the reasoning text to reference "strictly limit corporate donations" language matching value=2.

---

_Reviewed: 2026-06-08T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
