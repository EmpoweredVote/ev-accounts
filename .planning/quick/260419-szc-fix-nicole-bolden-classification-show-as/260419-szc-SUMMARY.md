---
phase: quick-260419-szc
plan: 01
subsystem: essentials
tags: [groupHierarchy, local-officials, sub-group, data-driven, tdd]
dependency_graph:
  requires: [essentials/src/lib/groupHierarchy.js]
  provides: [admin-officer sub-group separation in LOCAL government bodies]
  affects: [essentials/src/pages/Results.jsx — consumes groupIntoHierarchy output]
tech_stack:
  added: [Vitest (groupHierarchy.test.js)]
  patterns: [isAdminOfficer guard, sub-group key segmentation, TDD]
key_files:
  created:
    - essentials/src/lib/groupHierarchy.test.js
  modified:
    - essentials/src/lib/groupHierarchy.js
decisions:
  - Sub-group key gains a third segment (ADMIN vs MEMBER) so admin officers and council members in the same government_body_name form distinct sub-groups without touching classify.js
  - Admin officers sorted at score 25 — below executives (20), above generic others (30)
  - isAdminOfficer guards on LOCAL district_type prefix to avoid misclassifying county or state treasurers
metrics:
  duration: ~45 minutes
  completed: "2026-04-19"
  tasks_completed: 1
  files_created: 1
  files_modified: 1
---

# Quick Task 260419-szc: Split LOCAL Admin Officers into Own Sub-group

**One-liner:** Data-driven sub-group key segmentation in groupHierarchy.js separates clerk/treasurer/auditor/recorder/assessor from council members in the same LOCAL government body.

## Root Cause Clarification

A prior quick task (260418-tlq) modified `classify.js` hoping to fix Nicole Bolden's display. However, `classify.js` is NOT in the rendering path for the Results page sub-group logic. The actual grouping is driven by `groupHierarchy.js` — specifically `getSubGroupKey()`, which was keying sub-groups by `${government_body_name}||${district_type}`. Since Bolden (City Clerk) and the Common Council members share the same `government_body_name` ("Bloomington Common Council") AND the same `district_type` ("LOCAL"), they were placed in the same sub-group.

## Changes Made

### `isAdminOfficer(pol)` helper
Returns `true` when `office_title` matches `/\b(clerk|treasurer|auditor|recorder|assessor)\b/i` AND `district_type` starts with `"LOCAL"`. The LOCAL guard is essential — county treasurers (district_type=COUNTY) and state-level roles must not be reclassified.

### `getSubGroupKey(pol)` — third segment added
- LOCAL politicians that ARE admin officers: `${body}||${district_type}||ADMIN`
- LOCAL politicians that are NOT admin officers: `${body}||${district_type}||MEMBER`
- Non-LOCAL: unchanged (no third segment)

This produces distinct sub-groups inside the same government_body accordion for Bolden vs. council members.

### `getSubGroupLabel()` — Rule 0 branch added
When all politicians in a sub-group are admin officers (flagged via `isAdminOfficer`), the label is derived from the first politician's `office_title`: strip leading jurisdiction prefix ("City "/"Town "/"Village "/"County ") and any " - <district>" suffix. If that leaves a bare role (e.g., "Clerk"), the jurisdiction noun is prefixed back ("City Clerk").

### `subGroupOrderScore()` — admin officer guard
Admin-officer sub-groups now score 25 (between executives at 20 and "Other" at 30). A `isAdminOfficer(pols[0])` guard prevents the LEGISLATIVE_KW check from misfiring when the accordion key accidentally contains "council".

## Test Results (5/5 passing)

| Test | Description | Result |
|------|-------------|--------|
| A | Bolden + 9 council members in one body → two sub-groups; Bolden's label contains "Clerk" | PASS |
| B | Council members alone → single sub-group, label unchanged | PASS |
| C | LOCAL treasurer + LOCAL council in same body → two sub-groups | PASS |
| D | COUNTY clerk (district_type=COUNTY) → NOT split into ADMIN (guard works) | PASS |
| E | LOCAL_EXEC mayor + LOCAL council → still two sub-groups (existing behavior preserved) | PASS |

## Human Verification

User confirmed: "approved - all 5 tests pass, code reviewed and correct."

## Commit

- `415a932` — `feat(260419-szc): split LOCAL admin officers into own sub-group in groupHierarchy`
  - Files: `src/lib/groupHierarchy.js` (+55 lines), `src/lib/groupHierarchy.test.js` (+176 lines, new)

## Deviations from Plan

None — plan executed exactly as written. Vitest was available in the essentials project; `groupHierarchy.test.js` was created directly (no fallback node script needed).

## Self-Check: PASSED

- `essentials/src/lib/groupHierarchy.js` — exists, modified
- `essentials/src/lib/groupHierarchy.test.js` — exists, created
- Commit `415a932` — verified in essentials git log
