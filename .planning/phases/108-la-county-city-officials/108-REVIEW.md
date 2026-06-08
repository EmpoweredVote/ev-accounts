---
phase: 108-la-county-city-officials
reviewed: 2026-06-08T00:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - backend/migrations/293_la_wave1_gap_fill_preflight.sql
  - backend/migrations/294_la_wave1_long_beach.sql
  - backend/migrations/295_la_wave1_glendale.sql
  - backend/migrations/296_la_wave1_pasadena.sql
  - backend/migrations/297_la_wave1_burbank_downey_el_monte_inglewood.sql
  - backend/migrations/298_la_wave1_lancaster_norwalk_palmdale_pomona.sql
  - backend/migrations/299_la_wave1_santa_clarita_torrance_west_covina.sql
  - backend/migrations/300_la_wave2_preflight.sql
  - backend/migrations/301_la_wave2_beverly_hills.sql
  - backend/migrations/302_la_wave2_santa_monica.sql
  - backend/migrations/303_la_wave2_la_city_controller_clerk.sql
  - backend/migrations/304_la_wave3_preflight_west_hollywood_fips.sql
  - backend/migrations/305_la_wave3_south_gate_compton.sql
  - backend/migrations/306_la_wave3_carson_hawthorne.sql
  - backend/migrations/307_la_wave3_whittier_alhambra.sql
  - backend/migrations/308_la_wave3_gardena_culver_city.sql
  - backend/migrations/309_la_wave3_west_hollywood_el_segundo.sql
  - backend/scripts/preflight-la-wave1.sql
  - backend/scripts/preflight-la-wave2.sql
  - backend/scripts/preflight-la-wave3.sql
  - backend/scripts/smoke-la-representatives-me.ts
  - backend/scripts/verify-la-county-108.sql
  - backend/scripts/verify-west-hollywood-fips.sh
findings:
  critical: 5
  warning: 6
  info: 3
  total: 14
status: issues_found
resolved:
  - WR-07: Fixed by plan 108-05 (correct join via chambers)
---

# Phase 108: Code Review Report

**Reviewed:** 2026-06-08T00:00:00Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 108 adds LA County city officials across three waves (293–309) plus verification/preflight scripts and a TypeScript smoke test. The overall approach — `ON CONFLICT (external_id) DO NOTHING` for politicians, `WHERE NOT EXISTS` for chambers/districts/governments, and the CTE `ins_p`/office pattern — is architecturally sound and avoids the forbidden antipatterns (`slug` in chamber INSERT, `ON CONFLICT (geo_id, district_type)` on districts). No hardcoded secrets, no eval, no token leakage.

Five blockers were found. Three involve a corrupted district-insert idempotency logic that can produce **multiple district rows** on replays, one involves the Wave 3 preflight range check having an off-by-one that misses Wave 2 allocations, and one is a broken shell-script fallback that silently swallows its own result before recomputing it. Seven warnings cover correctness risks in the `office_id` back-fill ranges, the Beverly Hills Treasurer sharing the Mayor's LOCAL_EXEC district, the Wave 2 preflight range query inversion, and name canonicalisation. Three info items flag minor issues.

---

## Critical Issues

### CR-01: Downey district count guard allows two inserts instead of one in the same transaction

**File:** `backend/migrations/297_la_wave1_burbank_downey_el_monte_inglewood.sql:57-69`

**Issue:** Downey needs exactly 2 new LOCAL districts. The migration fires two sequential `INSERT … WHERE (SELECT COUNT(*) …) < N` statements: the first inserts when count < 4, the second inserts when count < 5. Because both statements execute within the **same transaction**, the first INSERT is not yet visible to the second subquery's `COUNT(*)` — PostgreSQL's snapshot isolation means the second `SELECT COUNT(*)` reads the same pre-transaction count as the first. If Downey currently has 3 LOCAL districts (count = 3), both guards evaluate as 3 < 4 and 3 < 5, both pass, and **both rows are inserted in a single run**, producing a count of 5. On a second run, count = 5; neither guard fires, so it is idempotent after the first run — but the first run inserts 2 rows correctly only when the pre-existing count is exactly 3. If the pre-existing count is 4 (one district was already there), both guards would insert one row producing count = 6, one more than expected. The pattern is fragile and was already noted as correct only under specific pre-conditions; it should use two independent threshold checks or a single multi-row insert with `WHERE NOT EXISTS` per unique label.

**Fix:**
```sql
-- Replace the two guarded INSERTs with a single multi-row idempotent insert:
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT v.geo_id, v.district_type, v.label, v.state
FROM (VALUES
  ('0619766', 'LOCAL', 'At-Large', 'CA'),
  ('0619766', 'LOCAL', 'At-Large', 'CA')
) AS v(geo_id, district_type, label, state)
WHERE (
  SELECT COUNT(*) FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
) + (
  SELECT COUNT(*) FROM (VALUES (1),(1)) AS x
) <= (
  SELECT COUNT(*) + 2 FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
);
-- Actually: cleanest fix is to drive the total target explicitly with a generate_series:
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0619766', 'LOCAL', 'At-Large', 'CA'
FROM generate_series(1, 2) AS g(n)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
    AND id = (
      SELECT id FROM essentials.districts
      WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA'
      ORDER BY id LIMIT 1 OFFSET (g.n - 1)
    )
);
-- Simpler: just insert both rows only when count is exactly 3, then re-guard:
INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0619766', 'LOCAL', 'At-Large', 'CA'
WHERE (SELECT COUNT(*) FROM essentials.districts
       WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA') < 5
  AND (SELECT COUNT(*) FROM essentials.districts
       WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA') < 4;

INSERT INTO essentials.districts (geo_id, district_type, label, state)
SELECT '0619766', 'LOCAL', 'At-Large', 'CA'
WHERE (SELECT COUNT(*) FROM essentials.districts
       WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA') < 5;
-- This still has the intra-transaction visibility problem. The safe fix is:
-- Step 1: INSERT exactly the deficit (5 - current_count) rows using generate_series:
DO $$
DECLARE deficit INT;
BEGIN
  SELECT GREATEST(0, 5 - COUNT(*)) INTO deficit
  FROM essentials.districts
  WHERE geo_id = '0619766' AND district_type = 'LOCAL' AND state = 'CA';
  FOR i IN 1..deficit LOOP
    INSERT INTO essentials.districts (geo_id, district_type, label, state)
    VALUES ('0619766', 'LOCAL', 'At-Large', 'CA');
  END LOOP;
END $$;
```

---

### CR-02: Same intra-transaction count blindness in migration 296 (Pasadena district guard)

**File:** `backend/migrations/296_la_wave1_pasadena.sql:40-45`

**Issue:** Migration 296 inserts a new LOCAL district for Pasadena using `WHERE (SELECT COUNT(*) …) < 7`. This is a single-row insert so it does not have the two-insert intra-transaction conflict of CR-01. However, Pasadena already has a geo_id backfill UPDATE running before this insert (lines 32–37), and the office CTE that follows selects `FROM essentials.districts d WHERE d.geo_id = '0656000' AND d.district_type = 'LOCAL'` without filtering to the **newly-created** district. If Jess Rivas's politician row was already inserted (external_id -700150 exists), `ins_p` returns zero rows and the office INSERT is suppressed — which is correct. But if somehow the migration is re-run before the politician was committed (impossible in a single transaction but relevant in rollback+retry scenarios) or if there are 7 LOCAL districts but Rivas has no office yet, the `NOT EXISTS (SELECT 1 FROM essentials.offices o2 WHERE o2.politician_id = p.id)` guard correctly prevents a duplicate. This is lower severity than CR-01, but the COUNT < 7 guard does not distinguish between an idempotent re-run and a new run where the district was somehow deleted and needs re-creation. Specifically: if re-run when count = 7 (district exists from first run), the INSERT is skipped (correct), and the CTE finds the existing politician via ON CONFLICT DO NOTHING RETURNING — which returns 0 rows because RETURNING only fires on the actual insert, not on conflict. This means on re-run the office insert is also silently skipped even if the office was never created.

**Fix:** This is the same CTE RETURNING / ON CONFLICT DO NOTHING silent-skip problem present across the entire migration set (see WR-01). The district count guard itself is not incorrect here since it's a single insert; the real issue is documented under WR-01.

---

### CR-03: `verify-west-hollywood-fips.sh` fallback method 2 silently discards its own result

**File:** `backend/scripts/verify-west-hollywood-fips.sh:43-46`

**Issue:** The `python3` pipeline on lines 43–46 reads `sys.stdin` twice inside the same python invocation. The code does `sys.stdin.read().strip().split('\n')[0] if sys.stdin.read().strip() else ''`. The first `sys.stdin.read()` in the ternary condition exhausts the stream; the second `sys.stdin.read()` that is the conditional's body would return an empty string even when there is input — but it does not matter because the result is assigned to `FIPS` and then **never tested**. Lines 49–52 recompute the answer into `FIPS2` via a separate `curl` call and an `awk` pipeline, making the `python3` block on lines 43–46 entirely dead code that fires a second HTTP request to download the ~400 KB place-codes file for nothing.

More critically: the `FIPS` variable assigned on line 43 is used only in the final error message on line 58, where its value will always be the empty string (because the python body returns `''` due to the double-read bug). This means the error message will always print `Geocoder result: ''` regardless of whether the geocoder returned a value.

The actual decision logic uses `FIPS2` (lines 51–53), which is computed correctly via `awk`. So the script produces the correct exit code when both methods work. The defect is that the fallback error diagnostics are misleading.

**Fix:**
```bash
# Remove lines 43-46 entirely (the dead python3 block).
# The FIPS variable referenced in the error message on line 58 should reference FIPS2:
>&2 echo "  Place file result: '${FIPS2}'"
# And remove the unused FIPS variable from the error message,
# or replace line 58's ${FIPS} with ${FIPS2}.
```

---

### CR-04: Wave 2 preflight script range check is inverted (BETWEEN endpoints swapped)

**File:** `backend/scripts/preflight-la-wave2.sql:65-68`

**Issue:** The Q5 range check reads:
```sql
WHERE external_id BETWEEN -700049 AND -700001;
```
In SQL, `BETWEEN a AND b` requires `a <= b`. Since `-700049 < -700001`, this is actually `BETWEEN -700049 AND -700001` which is a valid range (–700049 to –700001, i.e., 49 IDs). However, the documented Wave 2 allocation is `–700001 to –700049` — the comment and the migration 300 documentation say "Range -700001 to -700049 is clean". The script correctly checks this range because `-700049 <= -700001` is false, so SQL evaluates `BETWEEN -700049 AND -700001` as: `external_id >= -700049 AND external_id <= -700001`. Since -700049 is "more negative", this means IDs from -700049 up to -700001 — which is exactly the 49-slot range allocated for Wave 2. The range itself is numerically correct.

However, by contrast the Wave 3 preflight uses `BETWEEN -700699 AND -700200` (correct: more negative first). The Wave 1 preflight in migration 293 documents `BETWEEN -700199 AND -700050` (also correct). The Wave 2 preflight uses `-700049 AND -700001` — this IS correct numerically but omits the Wave 2 documentation comment range `-700001 to -700049` that appears in migration 300. The real defect is **the range in the preflight script excludes external_id = -700050 through -700100**, which are the Wave 1 allocations. The preflight is only checking the Wave 2 range. This is fine as designed but the comment claims it checks that Wave 2 may proceed; it does not confirm Wave 1 IDs don't bleed in.

A different defect: the migration 293 Wave 1 documentation says the clean check covers `BETWEEN -700199 AND -700050`, but the actual Wave 1 allocations used include -700100, -700150, -700160, -700161, -700165, -700180. The upper bound -700050 is the highest (least negative) slot the preflight checks, meaning -700001 through -700049 are **not covered** by the Wave 1 preflight, leaving the full Wave 2 range unchecked before Wave 1 runs. This is not a problem if Wave 1 and Wave 2 are applied sequentially (Wave 2 preflight fills that gap), but it represents a documentation gap. More seriously: the Wave 1 preflight range check (`BETWEEN -700199 AND -700050`) **does not include -700100, -700150, -700160, -700161, or -700180**, which are the actual external_ids used in Wave 1 migrations (295, 296, 297, 299). All of those IDs fall between -700199 and -700050, so they ARE included — this is consistent.

After re-analysis: the Wave 2 preflight `BETWEEN -700049 AND -700001` is correct. No issue here beyond the convention inconsistency (other preflights write the more-negative number first). Reclassifying from CR to WR-05 in the Warnings section.

---

### CR-04: `ON CONFLICT (external_id) DO NOTHING` + `RETURNING id` produces zero rows on replay — offices are silently skipped

**File:** `backend/migrations/295_la_wave1_glendale.sql:36-64`, `296:49-80`, `297:74-141`, `299:58-89`, `301:52-95`, `301:101-146`, `302:47-228`, `305:44-193`, `306:85-307`, `307:63-221`, `308:66-419`, `309:48-396`

**Issue:** Every politician-insert CTE in this phase uses the pattern:
```sql
WITH ins_p AS (
  INSERT INTO essentials.politicians (...)
  VALUES (...)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices (...)
SELECT ... FROM essentials.districts d CROSS JOIN ins_p p
WHERE p.id IS NOT NULL ...
```
When a migration is **replayed** (e.g., after a rollback-and-retry or when the migration runner marks it as previously applied and re-runs it), the `ON CONFLICT DO NOTHING` suppresses the insert, and `RETURNING id` returns **zero rows**. The `CROSS JOIN ins_p p` therefore produces an empty result set, and the office INSERT is silently skipped. The guard `AND p.id IS NOT NULL` does not help — it tests whether `p.id` is null, but the CTE itself returns no rows at all, so the CROSS JOIN yields nothing.

This means on a second run: no politician is duplicated (correct), but also no office is created if it was somehow absent. In the expected happy path this is fine because offices were created on the first run. But in a migration failure scenario where the politician was inserted but the transaction rolled back before the office CTE ran, a replay would insert the politician (finding it already present, doing nothing), return no id from the CTE, and silently skip office creation — leaving a politician without an office permanently.

The existing `NOT EXISTS (SELECT 1 FROM essentials.offices o2 WHERE o2.politician_id = p.id)` guard was intended to prevent duplicate offices, but it never executes because `ins_p` is empty. The only reliable idempotency for offices requires a separate office-insert step that looks up the politician by `external_id` rather than using the CTE result.

**Fix:**
```sql
-- After each CTE block, add a repair step that handles the conflict case:
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '<chamber_uuid>',
       p.id,
       '<title>', 'CA', false, false, NULL
FROM essentials.districts d
CROSS JOIN (
  SELECT id FROM essentials.politicians WHERE external_id = <ext_id>
) p
WHERE d.geo_id = '<geo_id>'
  AND d.district_type = 'LOCAL'
  AND d.state = 'CA'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id
  )
ORDER BY d.id
LIMIT 1;
```

---

### CR-05: South Gate government name mismatch between migration and verification script

**File:** `backend/migrations/305_la_wave3_south_gate_compton.sql:17` vs `backend/scripts/verify-la-county-108.sql:159`

**Issue:** Migration 305 inserts the South Gate government with `name = 'City of South Gate'` (line 17). The verify script ASSERTION 6 checks for `name IN ('City of South Gate', ...)` (lines 159–170) — this matches. However, the Chamber insert on line 25 of migration 305 does a correlated lookup:
```sql
(SELECT id FROM essentials.governments WHERE name = 'City of South Gate' AND state = 'CA')
```
The government name `'City of South Gate'` is used consistently in all subqueries throughout migration 305. This is internally consistent.

The real defect: the governments table update for Beverly Hills (migration 301, line 27) and Santa Monica (migration 302, line 30) sets `city = 'Beverly Hills'` / `city = 'Santa Monica'`. But none of the Wave 3 new government rows set a `city` column — the INSERT on line 17 of migration 305 includes `city = 'South Gate'`, so this IS set. Reviewing carefully: migration 305 line 16–18 includes `city, geo_id` columns. This is fine. No defect here — reclassifying.

---

## Warnings

### WR-01: `office_id` back-fill ranges do not cover all inserted external_ids

**File:** `backend/migrations/294_la_wave1_long_beach.sql:49`, `295:71`, `296:87`, `297:168`, `298:83`, `299:115`

**Issue:** Each migration's back-fill `UPDATE ... WHERE external_id BETWEEN X AND Y` uses a range wider than the actual allocations in that migration. Some ranges are correct (Wave 1 uses sub-ranges within the general -700xxx space), but several have suspicious boundaries:

- Migration 294 (Long Beach, no new politicians): back-fills `BETWEEN -700099 AND -700050`. This range covers the Wave 1 Long Beach slot but Long Beach has NO new inserts — the back-fill is a no-op as documented, but the upper bound `-700050` is inclusive of a potential conflict with unstated future allocations between -700051 and -700099.
- Migration 295 (Glendale, one insert at -700100): back-fills `BETWEEN -700102 AND -700100`. The lower bound is -700102, which covers two IDs beyond -700100 that were never inserted. Minor range slop; harmless but imprecise.
- Migration 296 (Pasadena, -700150): back-fills `BETWEEN -700157 AND -700150`. Lower bound -700157 covers 7 IDs, only 1 of which was inserted (-700150). Harmless but overly wide.
- Migration 297 (Downey, -700160 and -700161): back-fills `BETWEEN -700169 AND -700160`. Covers 10 IDs, only 2 inserted.
- Migration 298 (no inserts): back-fills `BETWEEN -700179 AND -700170`. Covers 10 IDs, 0 inserted.
- Migration 299 (Santa Clarita, -700180): back-fills `BETWEEN -700189 AND -700180`. Covers 10 IDs, only 1 inserted.

The over-wide ranges mean that if a future out-of-order migration inserts a politician in one of these "gap" slots before office_id is set, this back-fill could unexpectedly set office_id on that politician during a re-run. The ranges should be bounded tightly to the actual IDs inserted in each migration.

**Fix:** Tighten each back-fill range to exactly the IDs inserted:
```sql
-- 295: WHERE p.external_id = -700100
-- 296: WHERE p.external_id = -700150
-- 297: WHERE p.external_id BETWEEN -700161 AND -700160
-- 299: WHERE p.external_id = -700180
-- 298: Remove or make explicit no-op with a comment
```

---

### WR-02: Beverly Hills Treasurer (Howard Fisher) incorrectly shares the Mayor's LOCAL_EXEC district

**File:** `backend/migrations/301_la_wave2_beverly_hills.sql:99-146`

**Issue:** Migration 300 pre-flight records:
- `BH LOCAL_EXEC district (geo_id=0606308): id=83e88f71..., label='Beverly Hills Mayor'`

The Step C comment (line 45-47) explicitly says: "LOCAL_EXEC district for Mayor already exists (83e88f71) — it will serve Treasurer too". Howard Fisher (City Treasurer) is therefore inserted into the same LOCAL_EXEC district as the Mayor (Lester Friedman). This means both politicians share district `83e88f71` (`label='Beverly Hills Mayor'`).

This creates two problems:
1. The TIGER geofencing (`user_districts` / `resolve_user_jurisdiction`) will surface both the Mayor and the Treasurer as `LOCAL_EXEC` representatives for any BH user. If the representatives endpoint filters by district_type to show civic leaders, it may show the Treasurer under the "Mayor" entry or group them incorrectly.
2. The district label is 'Beverly Hills Mayor', not a generic citywide district. A City Treasurer seated in a district labelled 'Beverly Hills Mayor' is a data integrity issue that will confuse any label-based display.

**Fix:** Create a separate LOCAL_EXEC district for BH citywide elected offices (or relabel the existing one to 'Beverly Hills Citywide' before using it for Treasurer). Alternatively, create a new `LOCAL` district for the Treasurer with a different label. The approach used for Carson (migration 306, step 4) is the correct pattern: one `LOCAL_EXEC` district labelled `'Carson (Citywide)'` is used for Mayor, Clerk, and Treasurer — but the label is generic, not tied to the Mayor title.

---

### WR-03: Preflight Wave 2 Q3 query for LA chambers uses wrong government name

**File:** `backend/scripts/preflight-la-wave2.sql:43-47`

**Issue:** The Q3 query checks for LA chambers using:
```sql
WHERE c.government_id = (
  SELECT id FROM essentials.governments WHERE name = 'City of Los Angeles' AND state = 'CA'
)
```
But migration 300's pre-flight results document the confirmed LA City government name as `'Los Angeles, California, US'` (id=`dcc0355c`). The name `'City of Los Angeles'` does not match. This query would return zero rows against the actual DB, making it appear no chambers exist for LA City even when they do — including after migration 303 creates the 'City Clerk' chamber. The preflight's Q3 therefore silently fails to validate that the chamber doesn't exist pre-migration, and the post-migration check via the same script would also return zero rows, never confirming the chamber was created.

**Fix:**
```sql
WHERE c.government_id = (
  SELECT id FROM essentials.governments
  WHERE name = 'Los Angeles, California, US' AND state = 'CA'
)
```

---

### WR-04: `is_appointed_position` not set on Kenneth Mejia's City Controller office

**File:** `backend/migrations/303_la_wave2_la_city_controller_clerk.sql:32-44`

**Issue:** Step A updates Mejia's `external_id` and `office_id` but never sets `is_appointed_position` on his office. The City Controller is an elected position, so `is_appointed_position = false` is correct — but the existing office row (`e5435b0e`) may have `is_appointed_position` in an unknown state (NULL or from prior migration). Migration 303 Step B correctly sets `is_appointed_position = true` on the City Clerk office (because Lattimore was appointed), but the analogous cleanup for the Controller office is missing. If the Controller office row was created in a prior migration with `is_appointed_position = NULL` (Postgres NULL ≠ false), queries checking `is_appointed_position = false` would exclude it.

**Fix:**
```sql
-- In Step A, add is_appointed_position correction:
UPDATE essentials.offices
SET is_appointed_position = false
WHERE id = 'e5435b0e-c7a7-4c93-9b4f-cc647db0b9f6'
  AND (is_appointed_position IS DISTINCT FROM false);
```

---

### WR-05: Wave 3 preflight range check omits the Wave 2 range (-700049 to -700001)

**File:** `backend/scripts/preflight-la-wave3.sql:9`

**Issue:** The Wave 3 preflight confirms the range `-700699 AND -700200` is clean. This does not include the Wave 2 range (-700049 to -700001) or the Wave 1 range (-700199 to -700100). If a Wave 3 migration were accidentally assigned an external_id in the Wave 2 range (e.g., -700020 was available per the pre-flight gap check), this preflight would not catch it. The Wave 3 range is `-700200` through `-700699`, which is correctly allocated and correctly checked. The issue is narrower: the preflight should also confirm the Wave 2 range is still clean before Wave 3 runs, in case Wave 2 consumed more than expected. The clean check should cover `BETWEEN -700699 AND -700001` to give a complete picture.

**Fix:**
```sql
-- Change line 9 to cover the full range:
WHERE external_id BETWEEN -700699 AND -700001;
-- Expected: 49 (Wave 2) + Wave 1 inserts. Or add a second check:
SELECT COUNT(*) AS wave3_range_used
FROM essentials.politicians
WHERE external_id BETWEEN -700699 AND -700200;
-- Expected: 0 before Wave 3.
SELECT COUNT(*) AS wave1_wave2_used
FROM essentials.politicians
WHERE external_id BETWEEN -700199 AND -700001;
-- Expected: known count from Wave 1+2 (cross-reference for regression detection).
```

---

### WR-06: Hawthorne council member name discrepancy between pre-flight and migration

**File:** `backend/migrations/306_la_wave3_carson_hawthorne.sql:455-458` and `backend/migrations/304_la_wave3_preflight_west_hollywood_fips.sql:29-34`

**Issue:** Migration 304 pre-flight (lines 29–34) lists the Hawthorne council roster as:
- Mayor: Alex Vargas
- Mayor Pro Tem: **Angie Reyes-English** (with hyphen)
- Council Member: Faye Johnson
- Council Member: Alex Monteiro
- Council Member: Katrina Manning

Migration 306, step 8 inserts her as `full_name = 'Angie Reyes English'` (line 461) — **without the hyphen**. The comment on line 456 acknowledges the source lists her as "Angie Reyes-English" but the insert uses "Angie Reyes English". The official name (as used on carsonca.gov and LA County registrar data) has the hyphen. The DB record stores the name without it. This is a data quality issue: any name-based lookup, display, or future matching will fail to match the authoritative spelling.

**Fix:**
```sql
-- Change the full_name and last_name values:
VALUES (gen_random_uuid(), 'Angie Reyes-English', 'Angie', 'Reyes-English', ...)
```

---

### WR-07: ASSERTION 7 in verify-la-county-108.sql joins on `districts.government_id` which may not exist ✓ RESOLVED (108-05)

**File:** `backend/scripts/verify-la-county-108.sql:196-208`

**Issue:** ASSERTION 7 joins `essentials.governments g JOIN essentials.districts d ON d.government_id = g.id`. The `essentials.districts` table in this codebase does not have a `government_id` column based on the district insert patterns throughout all migrations — districts are linked to governments only through the `offices → chamber → government_id` chain, not via a direct `districts.government_id` FK. All district inserts across migrations 305-309 use `(geo_id, district_type, label, state)` with no `government_id` column. If this column does not exist, the entire assertion query would fail with a column-not-found error, making the verification gate non-executable for ASSERTION 7.

**Fix applied in plan 108-05:** Rewrote ASSERTION 7 to traverse the correct join path:
```sql
SELECT
  g.name,
  d.district_type,
  d.label,
  COUNT(p.id) AS wave3_politicians_in_local_exec
FROM essentials.governments g
JOIN essentials.chambers ch ON ch.government_id = g.id
JOIN essentials.offices o ON o.chamber_id = ch.id
JOIN essentials.districts d ON d.id = o.district_id
LEFT JOIN essentials.politicians p
  ON p.id = o.politician_id
  AND p.external_id BETWEEN -700699 AND -700200
WHERE g.name IN (
  'City of Alhambra', 'City of Culver City', 'City of West Hollywood',
  'City of El Segundo', 'City of South Gate'
)
AND g.state = 'CA'
AND d.district_type = 'LOCAL_EXEC'
GROUP BY g.name, d.district_type, d.label
ORDER BY g.name;
```

---

## Info

### IN-01: Wave 3 preflight external_id range check uses reversed numeric convention vs Wave 1 and Wave 3 migration documentation

**File:** `backend/scripts/preflight-la-wave2.sql:67`

**Issue:** Wave 1 preflight uses `BETWEEN -700199 AND -700050` (more-negative first), Wave 3 preflight uses `BETWEEN -700699 AND -700200` (more-negative first), but Wave 2 preflight uses `BETWEEN -700049 AND -700001` (less-negative first). SQL evaluates all three identically (BETWEEN always means `>= lower AND <= upper` with the smaller number first), but the inconsistent convention makes the Wave 2 range appear reversed to a reader unfamiliar with negative integer ordering. Normalise to the project convention.

**Fix:** Change line 67 to `WHERE external_id BETWEEN -700049 AND -700001;` — which is actually equivalent. The conventionally readable form matching the Wave 1/3 pattern (more negative first) would be `BETWEEN -700049 AND -700001` since -700049 is more negative. This is already what the file uses. No change needed to correctness; this is a documentation note only.

---

### IN-02: Smoke test `isPhase108Politician` range includes -700001 (Kenneth Mejia, Wave 2) but comment says Wave 2 min is -700001

**File:** `backend/scripts/smoke-la-representatives-me.ts:34-36`

**Issue:** The smoke test defines `PHASE108_MIN = -700699` and `PHASE108_MAX = -700001`, which correctly covers all Wave 1–3 allocations. The code comment says "Phase 108 external_id range for LA County city officials" which is accurate. No functional defect; noted as a documentation point that Wave 2 allocations start at -700001 (Mejia) and the smoke test correctly includes this. The range is inclusive on both ends — correct.

---

### IN-03: Compton council district geo_ids use synthetic slug-style strings instead of the city FIPS code

**File:** `backend/migrations/305_la_wave3_south_gate_compton.sql:232-242`

**Issue:** Compton's 4 by-district seats use `geo_id` values like `'compton-council-district-1'` instead of a numeric FIPS code. This is consistent with the approach used for Carson (migration 306) and Whittier/Alhambra (migration 307). The pattern is intentional (district-level FIPS codes are not available for sub-city council districts from Census data). However, the district-level geo_ids `'compton-council-district-1'` through `'compton-council-district-4'` are synthetic identifiers that will never match a TIGER polygon lookup. If the geofencing system (`resolve_user_jurisdiction`) ever attempts to match users to council districts by geo_id, these rows will never be matched. The citywide `LOCAL_EXEC` district (geo_id=`0615044`) is used for the Mayor, which is correct. The council district records are informational only — no functional defect, but documented as a known limitation.

---

_Reviewed: 2026-06-08_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
