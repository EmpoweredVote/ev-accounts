---
phase: quick-14
plan: "01"
subsystem: essentials-data
tags: [data-fix, migration, judiciary, indiana]
dependency_graph:
  requires: []
  provides: [correct Monroe County Circuit Court judge names and division labels]
  affects: [essentials.politicians, essentials.districts, essentials.chambers, essentials.offices]
tech_stack:
  added: []
  patterns: [idempotent SQL migration, PK-targeted UPDATE]
key_files:
  created:
    - EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql
  modified:
    - EV-Backend/scripts/gov_structure.json
decisions:
  - Updated chambers and offices tables in addition to districts — all three tables had Seat N labels that needed relabeling
metrics:
  duration: "~10 minutes"
  completed: "2026-03-14"
---

# Phase quick-14 Plan 01: Fix Monroe County Circuit Court Judge Names and Division Labels Summary

Corrected all 9 Monroe County 10th Circuit Court judge records: 4 politician name fixes (middle initials/names) and relabeled every Seat N reference to the correct Division N across districts, chambers, and offices tables.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write and apply SQL migration | dd34707 | EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql |
| 2 | Update gov_structure.json naming convention | ef5542e | EV-Backend/scripts/gov_structure.json |

## What Was Built

**Task 1 — SQL Migration**

Applied idempotent migration to production Supabase (31 UPDATE statements, all succeeded):

- Section 1: Fixed 4 politician names — Geoffrey J. Bradley, Christine Talley Haseman, Catherine B. Stafford, Mary Ellen Diekhoff now have correct middle initials/names
- Section 2: Relabeled 9 district rows — district_id and label updated from "Seat N" to "Division N" using the correct official division assignments per in.gov (Cicero seat numbers were scrambled; e.g., Bradley had seat=9 but is Division 1)
- Section 3: Relabeled 9 chamber rows from "Seat N" to "Division N"
- Section 4: Relabeled 9 office title rows from "Seat N" to "Division N"

Post-migration verification confirmed:
- All 9 judges show correct full names and Division 1–9 labels ordered correctly
- 0 rows remain with "Seat" in district label for Monroe County Circuit Court
- 0 rows remain with "Seat" in chamber name for Monroe County Circuit Court

**Task 2 — gov_structure.json**

Added `naming_convention` field to the Indiana `circuit` court entry documenting that multi-judge circuits use "Division N" format, not "Seat N". Prevents future data imports from using Cicero seat numbers without cross-referencing official court websites.

## Deviations from Plan

**1. [Rule 2 - Missing coverage] Also updated essentials.offices titles**

- **Found during:** Task 1 implementation
- **Issue:** The plan specified districts and chambers but the plan's own PK table showed office_id PKs, implying offices also needed updating. The current office title format "Seat N" would remain broken if not fixed.
- **Fix:** Added Section 4 to the migration updating all 9 office title rows
- **Files modified:** fix_monroe_county_circuit_court_judges.sql
- **Commit:** dd34707

## Self-Check

- [x] Migration file exists: EV-Backend/internal/essentials/migrations/fix_monroe_county_circuit_court_judges.sql
- [x] gov_structure.json updated with naming_convention
- [x] Commit dd34707 exists (Task 1)
- [x] Commit ef5542e exists (Task 2)
- [x] 9/9 judges show Division 1–9 labels in production DB
- [x] 0 "Seat" references remain in districts or chambers for Monroe County Circuit Court

## Self-Check: PASSED
