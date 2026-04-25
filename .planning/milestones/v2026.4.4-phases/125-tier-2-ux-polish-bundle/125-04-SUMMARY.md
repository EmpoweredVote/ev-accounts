---
phase: 125-tier-2-ux-polish-bundle
plan: "04"
subsystem: ui
tags: [treasury, sunburst, visualization]

dependency_graph:
  requires: [125-02]
  provides: [G-114-025 deferred]
  affects: []

metrics:
  completed: "2026-04-18"
  tasks_completed: 0
  tasks_total: 4
---

# Phase 125 Plan 04: Sunburst Labels (Wave 3b) Summary

## Outcome: G-114-025 deferred at user request

Path A (add permanent top-level labels to sunburst) was assessed but NOT executed — user confirmed the sunburst is a valued feature and does not want it removed. Path B (remove sunburst toggle) was briefly committed then reverted (`69279b7`) after user feedback.

G-114-025 is carried forward to a future phase. The sunburst visualization remains in treasury-tracker with the existing hover-only label behavior.

## Backlog note

Filed in BACKLOG.md: PostGIS geo-match of evUserAddress to treasury municipalities (township/city/county) — needed before expanding Treasury to more municipalities since state-level filtering is already imprecise for CA users.
