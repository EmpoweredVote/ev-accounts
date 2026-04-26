---
phase: quick
plan: 260426-eob
subsystem: essentials/CompassFirstCard
tags: [compass, icon, ui, cleanup]
key-files:
  modified:
    - essentials/src/components/CompassFirstCard.jsx
decisions:
  - "Pass hasStances={false} to IconOverlay in CompassFirstCard — compass icon is redundant given radar chart as primary visual"
metrics:
  duration: "< 5 minutes"
  completed: "2026-04-26"
  tasks: 1
  files: 1
---

# Quick Task 260426-eob: Remove compass icon from CompassFirstCard

**One-liner:** Hardcode `hasStances={false}` in CompassFirstCard's IconOverlay call to suppress redundant compass icon badge.

## What Was Done

Single-line change in `essentials/src/components/CompassFirstCard.jsx` at line 239: replaced `hasStances={Boolean(mockAnswers)}` with `hasStances={false}`.

The radar chart already serves as the primary visual indicator of compass stance data on these cards. Rendering a compass icon badge in the IconOverlay row alongside the radar chart was redundant visual noise.

## Commits

| Task | Commit | Repo | Description |
|------|--------|------|-------------|
| 1 | bba369f | essentials | fix(quick-260426-eob): remove compass icon from CompassFirstCard IconOverlay |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `hasStances={false}` confirmed at line 239 of CompassFirstCard.jsx
- Commit bba369f exists in essentials repo
- ballot and branch props unchanged
