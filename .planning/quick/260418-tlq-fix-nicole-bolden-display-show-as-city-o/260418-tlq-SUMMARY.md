---
phase: quick-260418-tlq
plan: 01
subsystem: essentials/classify
tags: [classification, local-officials, city-clerk, bug-fix]
dependency_graph:
  requires: []
  provides: [correct-city-clerk-classification]
  affects: [essentials-results-page]
tech_stack:
  added: []
  patterns: [title-before-chamber classification precedence]
key_files:
  modified:
    - essentials/src/lib/classify.js
decisions:
  - Tightened clerk check from `["clerk", "city"]` to explicit admin titles `["clerk", "treasurer", "auditor", "recorder", "assessor"]` — the original "city" keyword was too broad and would have incorrectly matched "City Council Member"
metrics:
  duration: "~10 minutes"
  completed: "2026-04-18"
  tasks_completed: 1
  files_changed: 1
---

# Quick Task 260418-tlq: Fix Nicole Bolden Display — Show as City Official

**One-liner:** Moved clerk/admin title check before council-chamber check in `LOCAL` branch so city clerks attached to council chambers display under "City Officials" instead of "City Council".

## What Was Done

### Task 1: Reorder LOCAL classification (COMPLETE)

**Commit:** `e13a918` (essentials repo, `feat/compass-first-card`)

In `essentials/src/lib/classify.js`, inside the `dt === "LOCAL"` branch, moved the administrative-officer check to run before the council-chamber check. Also tightened the title keywords from `["clerk", "city"]` to `["clerk", "treasurer", "auditor", "recorder", "assessor"]`.

**Root cause:** Nicole Bolden (Bloomington City Clerk) has `chamber_name_formal = "Common City Council"` because the clerk attends council meetings administratively. The old code checked `hasAny(chamber, ["council"])` first, so she fell into "City Council". The clerk-title check was unreachable for her.

**Fix:** Clerk/admin titles now take precedence over chamber-name matching. Added an explanatory comment in the code.

## Verification

Automated unit check passed:
- `{ district_type: "LOCAL", chamber_name_formal: "Common City Council", office_title: "City Clerk" }` → `{ group: "Municipal Officials" }` (PASS)
- `{ district_type: "LOCAL", chamber_name_formal: "Common City Council", office_title: "Council Member" }` → `{ group: "City Council" }` (PASS)

Additional regression tests all passed (Alderman, Township Trustee, Treasurer, Auditor, Councilmember).

## Deviations from Plan

**1. [Rule 1 - Bug] Removed dead duplicate clerk check**

The old `hasAny(title, ["clerk", "city"])` block (previously the only clerk check, living below the council check) was replaced entirely by the new block placed above the council check. There was no separate "dead duplicate" to remove — the edit was a clean replacement in place with the new tighter check. No extra cleanup needed.

**2. [Rule 2 - Improvement] Tightened "city" keyword**

Plan spec explicitly requested removing the overly-broad `"city"` keyword from the clerk check. Applied as instructed — using `["clerk", "treasurer", "auditor", "recorder", "assessor"]` instead.

## Awaiting Human Verification (Task 2 — Checkpoint)

Task 2 is a `checkpoint:human-verify`. The automated check confirms the classification logic is correct. Manual UI verification requires:

1. `cd essentials && npm run dev`
2. Search a Bloomington, IN address
3. Confirm Nicole Bolden appears under "City Officials" (not "City Council")
4. Confirm Common Council members remain under "City Council"

## Self-Check: PASSED

- File modified: `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` — EXISTS
- Commit `e13a918` in essentials repo — FOUND
- Automated verify: PASS (clerk → Municipal Officials, council member → City Council)
