---
phase: quick-260422-upn
plan: 01
subsystem: essentials/grouping
tags: [judiciary, grouping, local-officials, treasury]
dependency_graph:
  requires: []
  provides: [judicial-subgroup-split, treasury-guard-on-courts]
  affects: [essentials/src/lib/groupHierarchy.js, essentials/src/pages/Results.jsx]
tech_stack:
  added: []
  patterns: [isJudicialOfficial helper, subGroupOrderScore tiebreak]
key_files:
  created: []
  modified:
    - essentials/src/lib/groupHierarchy.js
    - essentials/src/lib/groupHierarchy.test.js
    - essentials/src/pages/Results.jsx
decisions:
  - isJudicialOfficial is a separate helper from isAdminOfficer to keep LOCAL and JUDICIAL logic distinct; broadening isAdminOfficer to match JUDICIAL district types would misclassify county-level clerks
  - Treasury link guard lives in Results.jsx (not groupHierarchy.js) because groupHierarchy produces pure data; rendering decisions (what links appear) belong to the view layer
  - subGroupOrderScore uses score 15 for judges and 30 for judicial officials so judges always render before the clerk within the same court accordion
metrics:
  duration: ~10 min
  completed: 2026-04-22
  tasks_completed: 1
  files_changed: 3
---

# Phase quick-260422-upn Plan 01: Fix Circuit Court Category (Nicole Brown) Summary

**One-liner:** Split JUDICIAL accordion into "Circuit Judges" and "Circuit Court Officials" sub-groups, and suppress the treasury link on judicial bodies.

## What Was Built

### Task 1: Split judicial sub-groups and guard treasury link (TDD — RED + GREEN)

**groupHierarchy.js changes:**

1. Added `isJudicialOfficial(pol)` helper — matches `district_type === 'JUDICIAL'` and title containing `clerk`, `administrator`, or `court officer`.
2. Extended `getSubGroupKey()` — JUDICIAL pols now get a `JUDGE` or `OFFICIAL` role segment, producing separate sub-group keys for judges vs. clerk.
3. Extended `getSubGroupLabel()` — added Rule 4a: when all pols in a JUDICIAL sub-group are judicial officials, return `"Circuit Court Officials"` (or generic `"Court Officials"` fallback). Rule 4b (existing judges label) continues to run for the judge sub-group.
4. Extended `subGroupOrderScore()` — judicial officials score 30, judges score 15 within the same court body, ensuring judges render first.

**Results.jsx change:**

Added `isJudicialBody` check before computing `treasuryMatch`. When any sub-group pol has `district_type === 'JUDICIAL'`, `treasuryMatch` is forced to `null` regardless of accordion title match against treasury cities.

## Test Coverage

| Test | Description | Result |
|------|-------------|--------|
| Test F (new) | 3 judges + clerk -> 2 sub-groups; clerk in "Circuit Court Officials"; judges first | PASS |
| Test G (new) | Judges only (no clerk) -> exactly 1 sub-group, no "Officials" group | PASS |
| Tests A–E (existing) | LOCAL admin officer splitting regression suite | PASS (all 5) |

**Total:** 7 tests pass.

## Commits

| Hash | Message |
|------|---------|
| d0c5c91 | test(quick-260422-upn): add failing tests for Circuit Court sub-group split |
| c7c3041 | feat(quick-260422-upn): split Circuit Court officials from judges and hide treasury link on courts |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

- `essentials/src/lib/groupHierarchy.js` — modified (confirmed)
- `essentials/src/lib/groupHierarchy.test.js` — modified (confirmed)
- `essentials/src/pages/Results.jsx` — modified (confirmed)
- Commit d0c5c91 — exists in essentials git log
- Commit c7c3041 — exists in essentials git log
- All 7 tests pass
- Build succeeds
