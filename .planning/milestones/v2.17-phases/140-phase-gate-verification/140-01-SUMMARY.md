---
phase: 140-phase-gate-verification
plan: 01
status: complete
requirements: [USHS-14]
---

# 140-01 SUMMARY — Consolidated v2.17 Phase Gate

**Completed:** 2026-06-20
**Deliverable:** `backend/scripts/verify-phase-132-140.sql` — one read-only, labeled-assertion SQL gate (USHS-06..14), mirroring the `verify-phase-127-131.sql` pattern.

## Result

Ran read-only against production (`psql -v ON_ERROR_STOP=1`). **Every assertion PASSED:**

```
USHS-06 PASS: 28/29 OH+NC House reps covered (McDowell NC-6 -37006 = documented honest-skip)
USHS-07 PASS: 26/26 GA+MI House reps covered
USHS-08 PASS: 31/31 NJ+WA+AZ House reps covered
USHS-09 PASS: 33/33 TN+CO+MN+MO House reps covered
USHS-10 PASS: 28/28 WI+AL+SC+KY House reps covered
USHS-11 PASS: 29/29 LA+CT+IN+OK+AR+IA House reps covered
USHS-12 PASS: 18/18 KS+MS+NV+NE+NM House reps covered
USHS-13 PASS: 18/18 single/low-rep-state House reps covered (HI/ID/MT/NH/RI/WV + AK/DE/ND/SD/VT/WY)
USHS-14a PASS: 211/212 in-scope v2.17 reps covered; sole gap = McDowell NC-6 (-37006), the documented honest-skip
USHS-14b PASS: 0 in-scope answers lack a paired context row with a real (http) source
verify-phase-132-140: ALL USHS-06..14 ASSERTIONS PASSED
```

## What it proves

- All 212 v2.17 in-scope US House reps (38 states, phases 132–139) are accounted for: **211 covered + 1 documented honest-skip** (Addison McDowell NC-6, −37006, a brand-new freshman with no documentable record).
- USHS-14a pins the sole coverage gap to exactly −37006 — any *other* uncovered in-scope rep would have raised an exception, so the gate distinguishes the documented exemption from a regression.
- **Zero** in-scope answer rows lack a paired `inform.politician_context` row with a real (http) source URL.

## Design notes

- Read-only: only SELECT/COUNT inside `DO $$` blocks; no INSERT/UPDATE/DELETE/DDL. Safe to re-run.
- All assertion constants were fixed by a live production diagnostic before authoring (not guessed); no constant was edited to force a pass.
- Full national House range `-56999..-1000` = 299 seeded = v2.16's 87 + v2.17's 212, so per-state-FIPS coverage counts are uncontaminated.

## Artifacts

- `backend/scripts/verify-phase-132-140.sql` (committed)

## Self-Check: PASSED
