---
phase: 128
plan: "01"
subsystem: essentials/classify
tags: [tdd, classify, computeVariant, unit-test, STATE-01, STATE-02, STATE-03]
dependency_graph:
  requires: []
  provides: [computeVariant named export in essentials/src/lib/classify.js]
  affects: [essentials/src/pages/Prototype.jsx (Plan 03)]
tech_stack:
  added: []
  patterns: [Vitest unit tests, named export extension, pure function classification]
key_files:
  created:
    - essentials/src/lib/classify.test.js
  modified:
    - essentials/src/lib/classify.js
decisions:
  - computeVariant uses direct regex + district_type check rather than delegating to classifyCategory() to avoid coupling to group string values (per PATTERNS.md pitfall guard)
  - Pre-existing compass.address.test.js failure confirmed as out-of-scope (localStorage mock issue pre-existing before this plan)
metrics:
  duration_seconds: 81
  completed_date: "2026-04-25"
  tasks_completed: 2
  files_created: 1
  files_modified: 1
---

# Phase 128 Plan 01: computeVariant TDD Scaffold Summary

**One-liner:** TDD RED→GREEN for `computeVariant` — pure classifier function that maps (pol, userAnswers) to 'empty' | 'administrative' | 'judicial' | 'compass' variants for CompassCardHorizontal.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Failing test scaffold for computeVariant | 01ecf58 | essentials/src/lib/classify.test.js |
| 1 (GREEN) | Implement computeVariant export in classify.js | bc02fd6 | essentials/src/lib/classify.js |

## Decisions Made

1. **Direct regex over classifyCategory delegation:** `computeVariant` uses `/clerk|treasurer|auditor|recorder|assessor/` and `dt === 'JUDICIAL'` directly rather than calling `classifyCategory()` and inspecting the returned group string. This avoids fragile coupling to display-string values that could change independently. Documented in PATTERNS.md pitfall guard.

2. **Pre-existing test failure is out of scope:** `compass.address.test.js` has a pre-existing `localStorage` mock failure unrelated to this plan. Verified by stashing changes and confirming the failure existed before any modifications.

## Deviations from Plan

None — plan executed exactly as written. TDD cycle followed: RED commit (`01ecf58`) then GREEN commit (`bc02fd6`).

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED | 01ecf58 | `test(128-01): add failing tests for computeVariant (RED)` |
| GREEN | bc02fd6 | `feat(128-01): implement computeVariant named export in classify.js (GREEN)` |
| REFACTOR | N/A | Not required — implementation is clean |

RED gate: 16 tests failed (computeVariant is not a function).
GREEN gate: 16 tests passing, 0 failing.

## Verification Results

```
Tests  16 passed (16)
Files  1 passed (1)
```

- `grep -nE "^export function computeVariant" essentials/src/lib/classify.js` — line 311
- Export count: 4 named exports (classifyCategory, orderedEntries, getDisplayName, computeVariant)
- Admin regex: `/clerk|treasurer|auditor|recorder|assessor/.test(title)`
- Judicial check: `dt === 'JUDICIAL' || /judge|justice|court/.test(title)`

## Known Stubs

None. `computeVariant` is a pure function with no stubs or placeholders.

## Threat Flags

None. Pure utility function with no network surface, no PII, no side effects.

## Self-Check: PASSED

- essentials/src/lib/classify.test.js: FOUND
- essentials/src/lib/classify.js (computeVariant): FOUND at line 311
- RED commit 01ecf58: confirmed in essentials git log
- GREEN commit bc02fd6: confirmed in essentials git log
