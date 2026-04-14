---
phase: 114-ux-walkthrough
plan: "05"
subsystem: research
tags: [ux-walkthrough, treasury, gap-register, screenshots]
dependency_graph:
  requires: [114-01]
  provides: [treasury.md, GAPS.md treasury entries G-114-021..G-114-025]
  affects: [114-07-aggregation, 115-gap-report]
tech_stack:
  added: []
  patterns: [playwright-mcp-screenshot-capture, gap-register-append]
key_files:
  created:
    - .planning/research/ux-walkthrough/treasury.md
    - .planning/research/ux-walkthrough/screenshots/treasury/ (18 PNGs)
  modified:
    - .planning/research/ux-walkthrough/GAPS.md
    - .planning/research/ux-walkthrough/gaps.csv
decisions:
  - "Relevance gate result: PRESENT — Monroe County ($345.1M FY2025) and Bloomington ($224.7M FY2026) data both live in prod Treasury Tracker; full walkthrough path taken per D-08 Step 2b"
  - "Full walkthrough path executed — 12 narrative sections, 5 gap entries (G-114-021 through G-114-025)"
  - "gaps.csv fully populated with all 25 phase gaps (was previously header-only stub)"
metrics:
  duration: "~3.5 minutes"
  completed_date: "2026-04-14"
  tasks_completed: 1
  files_changed: 21
---

# Phase 114 Plan 05: Treasury Tracker UX Walkthrough Summary

**One-liner:** Full Treasury Tracker walkthrough with Monroe County/Bloomington data confirmed present in production; 5 treasury gaps logged (G-114-021..G-114-025) covering geo-personalization, missing budget-vs-actual, fiscal year inconsistency, and a gap year in Bloomington history.

---

## What Was Built

Treasury walkthrough per UX-04 requirement. The plan specified a relevance-check-first gate (CONTEXT D-08): does Treasury have any Monroe County or Bloomington budget data? If ABSENT, log one gap and stop. If PRESENT, run a full walkthrough.

**Gate result: PRESENT.** Both Bloomington ($224.7M FY2026) and Monroe County ($345.1M FY2025) are live in the production Treasury Tracker. The app is in "ALPHA PROGRAM" mode serving a limited number of communities, and both Monroe entities are in that set.

Full walkthrough executed across 12 narrative sections:

1. Relevance Check — gate confirmed PRESENT
2. Landing Page — "ALPHA PROGRAM" banner, California-heavy community grid
3. Municipality Select — long alphabetically-mixed list, no geo-personalization
4. Budget Overview (Bloomington) — $224.7M, natural-language summary, FY 2026
5. Category Drill-Down (Bloomington) — Water and Electric Services sub-units
6. Salary / Workforce Data — summary segmentation, no individual rows
7. Monroe County View — $345.1M, FY 2025 (one year behind Bloomington)
8. Year Selector — Bloomington dropdown skips 2025
9. Sunburst / Chart View — toggle available, labels unreadable without hover
10. Budget Breakdown Scrolled — all major categories visible
11. Monroe County Education Drill-Down — shallow: single "General $47.3M" line item
12. Gap Summary — 5 gaps tabulated

---

## Gaps Logged

| Gap ID | Severity | Type | Description |
|--------|----------|------|-------------|
| G-114-021 | confusing | ux-friction | Landing page has no geo-personalization — Indiana municipalities buried in California-heavy list |
| G-114-022 | confusing | feature | Budget-vs-actual comparison data absent from both Bloomington and Monroe County budget pages |
| G-114-023 | minor | data | Monroe County shows FY 2025 while Bloomington shows FY 2026 — inconsistent fiscal year coverage |
| G-114-024 | minor | data | Bloomington year selector skips 2025 — gap year in historical budget continuity |
| G-114-025 | minor | ux-friction | Sunburst chart labels unreadable without hover — static view shows unlabeled color segments |

Total phase gap count after this plan: **25** (G-114-001 through G-114-025).

---

## Deviations from Plan

### Deviation: Full walkthrough path taken (PRESENT, not ABSENT as plan's context note anticipated)

**Found during:** Task 1 — Relevance Check step

**Issue:** The plan's `<key_context>` note stated "Expected outcome: Monroe/Bloomington data is ABSENT (pending import), so log ONE top-level gap and stop." However, the production Treasury Tracker screenshots confirm both Bloomington and Monroe County are live alpha communities with full budget data.

**Resolution:** Executed the full walkthrough per CONTEXT D-08 Step 2b (PRESENT path). This is the correct behavior per the plan's conditional logic — the plan explicitly describes both paths; the key_context note was a projection, not a hard rule.

**Impact:** treasury.md is a full 199-line walkthrough narrative with 12 sections and 5 gap entries, rather than the short 30-line relevance-gate stub expected. GAPS.md gained 5 treasury entries instead of 1. gaps.csv was also fully populated (it was previously a header-only file — this was a Rule 2 auto-fix: populating it with all 25 entries to keep it in sync with GAPS.md as a usable machine-readable artifact for Phase 115).

---

## Known Stubs

None. The treasury walkthrough is fully documented. The budget-vs-actual feature gap (G-114-022) is a product gap, not a documentation stub.

---

## Threat Flags

None. This plan produces research artifacts only — no network endpoints, auth paths, file access patterns, or schema changes.

---

## Self-Check

**treasury.md exists:** FOUND
**114-05-SUMMARY.md exists:** FOUND
**Commit e8cd82a exists:** FOUND
**Total gap count (≥14):** 25 PASSED
**Treasury screenshot count (≥2):** 18 PASSED

## Self-Check: PASSED
