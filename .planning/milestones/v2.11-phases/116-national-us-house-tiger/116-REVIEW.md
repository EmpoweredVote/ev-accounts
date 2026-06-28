---
phase: 116-national-us-house-tiger
reviewed: 2026-06-12T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - backend/scripts/load-national-house-districts.ts
  - supabase/migrations/20260612000001_342_national_house_tiger_geoid_backfill.sql
findings:
  critical: 2
  warning: 2
  info: 1
  total: 5
status: issues_found
---

# Phase 116: Code Review Report

**Reviewed:** 2026-06-12
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Two files reviewed: the national TIGER CD119 loader script and the `tiger_geoid` backfill migration
for all NATIONAL_LOWER districts. The script correctly handles at-large state districts (AK, DE,
MT, ND, SD, VT, WY) by excluding `'00'` from SKIP_CODES — that is the right call. The migration
is structurally sound and idempotent.

However, two critical defects are present: (1) the script's `SKIP_CODES` set diverges from the
authoritative `skipDistrictCodes` in `load-state-tiger-boundaries.ts` — one of them is wrong for
`cd`/`cd119` layers, and the evidence strongly favors the new script being correct while the older
generalized loader is the bug; (2) DC (FIPS `11`) is included in `STATE_FIPS_CODES` but DC's
delegate is non-voting, the same criterion used to exclude territories — its inclusion contradicts
the code comment and will insert a phantom `geo_districts` row + `geofence_boundaries` row without
a corresponding `essentials.districts` NATIONAL_LOWER row, causing the `tiger_geoid` migration's
`v_null <> 0` assertion to pass trivially (no districts row to update) while silently inserting an
orphan geometry record.

Two warnings: `pool.end()` is not in a `finally` block (minor — process.exit rescues it in
practice, but if the pattern spreads to scripts that don't exit it will leak), and the migration
floor assertion uses `430` while the script expects `435` — a misaligned sanity band.

---

## Critical Issues

### CR-01: SKIP_CODES divergence between this script and the authoritative generalized loader creates a data integrity split

**File:** `backend/scripts/load-national-house-districts.ts:45`

**Issue:** `SKIP_CODES = new Set(['ZZ', 'ZZZ', '000'])` deliberately excludes `'00'` on the basis
that at-large state delegates use `CD119FP='00'`. This is correct reasoning. However, the
authoritative generalized loader `load-state-tiger-boundaries.ts` has:

```
skipDistrictCodes: new Set(['ZZ', 'ZZZ', '00', '000']),
```

for both the `cd` and `cd119` layer dispatch entries (lines 236 and 245). This means any future
run of the generalized loader for a state's `cd119` layer (e.g., when a state is added to
`STATE_LAYER_ALLOWLIST`) will **skip at-large districts** for AK, DE, MT, ND, SD, VT, and WY —
deleting their `geo_districts` rows via the idempotent `ON CONFLICT DO NOTHING` without inserting
replacements. The two scripts are the canonical authority for the same operation and contradict
each other.

The new national script comments say "Removing '00' from the plan's SKIP_CODES set is a bug fix."
If that is true, the generalized loader is the bug and needs the same fix. If the generalized
loader is correct (those states are intentionally excluded there), then this script over-includes
them. This must be resolved before the generalized loader is used for any at-large state.

**Fix:** Reconcile `skipDistrictCodes` in `load-state-tiger-boundaries.ts` LAYER_DISPATCH for
`cd` and `cd119` entries to match the at-large-preserving set:

```typescript
// load-state-tiger-boundaries.ts, LAYER_DISPATCH cd and cd119 entries:
skipDistrictCodes: new Set(['ZZ', 'ZZZ', '000']),  // '00' removed — at-large states (AK, DE, MT, ND, SD, VT, WY) use '00' for their single voting member
```

### CR-02: DC (FIPS '11') is included in STATE_FIPS_CODES despite its delegate being non-voting — same exclusion criterion as territories

**File:** `backend/scripts/load-national-house-districts.ts:49-58`

**Issue:** The comment at line 49 states: "Territories (60=AS, 66=GU, 69=MP, 72=PR, 78=VI) are
excluded — they have non-voting delegates, not full House members." DC's single House delegate
(Eleanor Holmes Norton) is **also non-voting** — exactly the same criterion. Yet DC (FIPS `11`)
is present in `STATE_FIPS_CODES`.

This produces two concrete defects:

1. TIGER will supply a CD119 file for DC (likely with `CD119FP='98'` for the at-large delegate
   seat). The script will insert a row into `essentials.geo_districts` (layer=`us_house`) and
   `essentials.geofence_boundaries` for DC's delegate seat. There is no corresponding
   `essentials.districts` NATIONAL_LOWER row for DC — DC was never seeded as a congressional
   district in any migration. The `tiger_geoid` backfill migration (migration 342) therefore will
   not update any DC row (none exists), but the `geo_districts` orphan row will silently persist.

2. The `EXPECTED_MIN = 435` assertion at line 324 can be met by 434 voting-member districts + 1
   DC delegate row, masking a scenario where one actual voting-member state is missing.

The comment at line 50 ("The plan references 435 districts which correspond to the 50 states +
DC") perpetuates confusion — 435 is the count of **voting** House members from the 50 states;
DC is not among them.

**Fix:** Remove FIPS `'11'` from `STATE_FIPS_CODES`:

```typescript
const STATE_FIPS_CODES: string[] = [
  '01', '02', '04', '05', '06', '08', '09', '10', /* '11' removed */ '12',
  '13', '15', '16', '17', '18', '19', '20', '21', '22', '23',
  '24', '25', '26', '27', '28', '29', '30', '31', '32', '33',
  '34', '35', '36', '37', '38', '39', '40', '41', '42', '44',
  '45', '46', '47', '48', '49', '50', '51', '53', '54', '55',
  '56',
];
```

And update the comment:

```typescript
// 50 states only. DC has a non-voting delegate (same exclusion criterion as territories).
// At-large states (AK, DE, MT, ND, SD, VT, WY) use CD119FP='00' which is NOT in SKIP_CODES.
```

---

## Warnings

### WR-01: pool.end() not in a finally block — leaks on assertion failure path

**File:** `backend/scripts/load-national-house-districts.ts:324-331`

**Issue:** The minimum-count assertion at line 324 throws an `Error` before `pool.end()` at line
331. The `main().catch()` at line 350 calls `process.exit(1)`, which terminates the process
(rescuing the leak in practice), but this is a fragile pattern. If this script ever becomes a
library function, or if the `process.exit(1)` is changed to a soft return, the pool will leak.
The generalized `load-state-tiger-boundaries.ts` uses a `try/finally` pattern for its `Client`
to avoid this.

**Fix:**

```typescript
  try {
    // ... loop over STATE_FIPS_CODES ...

    if (totalProcessed < EXPECTED_MIN) {
      throw new Error(
        `Processed only ${totalProcessed} districts (expected >= ${EXPECTED_MIN}). ` +
        `Check SKIP_CODES and shapefile integrity.`
      );
    }
  } finally {
    await pool.end();
  }

  console.log('\n=== Summary ===');
  // ...
```

### WR-02: Migration 342 floor assertion (430) is misaligned with script assertion (435)

**File:** `supabase/migrations/20260612000001_342_national_house_tiger_geoid_backfill.sql:45`

**Issue:** The migration asserts `v_total < 430` (line 45) as a sanity floor for NATIONAL_LOWER
districts. The loader script uses `EXPECTED_MIN = 435` for geo_districts. These two numbers
protect different things (districts table vs. geo_districts table) but they should use the same
floor to catch regressions. If the districts table were missing 6 rows (429 rows), the migration
would throw, but if it had 430–434 rows the migration would silently succeed even though a
meaningful number of districts are absent. Conversely, the `v_null <> 0` assertion is the hard
correctness gate; the floor is only a belt-and-suspenders check. Using 435 here would make the
floor match the definitive count.

**Fix:**

```sql
  IF v_total < 435 THEN
    RAISE EXCEPTION 'NATIONAL_LOWER total % is suspiciously low (expected >= 435)', v_total;
  END IF;
```

---

## Info

### IN-01: statefpCol resolved but value immediately suppressed with void — dead read

**File:** `backend/scripts/load-national-house-districts.ts:219-227`

**Issue:** Lines 219–227 resolve the STATEFP column from the DBF record and immediately suppress
the read with `void props[statefpCol]`. The value is never used; the column is resolved only to
validate that the field exists (which `resolveColumn` already guarantees by throwing). The
comment "Suppress unused variable warning" refers to `statefpCol` (the key name), not the value.
But `statefpCol` is used at line 227 (`props[statefpCol]`), so the warning-suppression rationale
is circular. The `state` variable is derived from `geoid.substring(0, 2)` instead (line 224),
making the `statefpCol` resolution truly dead.

This is an inherited anti-pattern from the TIGER drift-detection philosophy (resolve all columns
so drift fails loudly). If that intent is desired, add a comment explaining it. If not, remove it.

**Fix (option A — keep for drift detection, clarify intent):**

```typescript
// Validate STATEFP column exists in this vintage (drift guard — value unused because
// state is derived from geoid prefix, but resolution throws if the column is missing).
resolveColumn(props, STATEFP_CANDIDATES);
```

**Fix (option B — remove):** Delete lines 219 and 227 (`statefpCol` resolve + `void` suppress).

---

_Reviewed: 2026-06-12_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
