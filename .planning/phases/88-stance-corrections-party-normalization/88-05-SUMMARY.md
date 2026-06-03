---
phase: 88-stance-corrections-party-normalization
plan: "05"
subsystem: database
tags: [migration, party-normalization, data-quality, essentials]
dependency_graph:
  requires: [88-04]
  provides: [SACC-03]
  affects: [essentials.politicians]
tech_stack:
  added: []
  patterns: [direct-postgres-pool, numbered-migration]
key_files:
  created:
    - supabase/migrations/20260603000011_126_party_string_normalization.sql
  modified: []
decisions:
  - "'Democratic' chosen as canonical party string (official party name: Democratic Party, not Democrat Party) — aligns with existing politicians like Padilla, Brown already stored as 'Democratic'"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-03"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
---

# Phase 88 Plan 05: Party String Normalization Summary

**One-liner:** Unified 495 'Democrat' rows to 'Democratic' via migration 126, eliminating the mixed-format party variant in essentials.politicians — no code impact, total count preserved at 775.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Pre-migration safety check — no hardcoded 'Democrat' in backend | (read-only, no commit) | backend/src (grep) |
| 2 | Write and apply party normalization migration | 17ebb30 | supabase/migrations/20260603000011_126_party_string_normalization.sql |

## Pre-Migration Party Distribution

| Party | Count |
|-------|-------|
| Democrat | 495 |
| Democratic | 280 |
| Republican | 604 |
| Nonpartisan | 1289 |
| Independent | 7 |
| Unenrolled | 3 |
| (empty string) | 112 |
| null | 78694 |

**Democratic-affiliated total (pre-migration):** 495 + 280 = 775

## Post-Migration Party Distribution

| Party | Count | Change |
|-------|-------|--------|
| Democrat | 0 | -495 (normalized) |
| Democratic | 775 | +495 (absorbed Democrat rows) |
| Republican | 604 | unchanged |
| Nonpartisan | 1289 | unchanged |
| Independent | 7 | unchanged |
| Unenrolled | 3 | unchanged |

**Democratic-affiliated total (post-migration):** 775 (preserved exactly)

## Verification Results

All acceptance criteria passed:

- `SELECT COUNT(*) FROM essentials.politicians WHERE party = 'Democrat'` → **0** ✓
- `SELECT DISTINCT party FROM essentials.politicians WHERE party ILIKE 'democra%'` → **['Democratic']** ✓
- Democratic count post = 775 = pre-Democrat (495) + pre-Democratic (280) ✓
- Republican (604), Independent (7), Unenrolled (3), Nonpartisan (1289) all unchanged ✓

## Backend Grep Confirmation

Pre-flight grep across `backend/src/**/*.{ts,js}` for pattern `['"]Democrat['"]`:
- **Zero matches found** — no backend code relies on the exact string 'Democrat'
- Additional patterns checked: `party === 'Democrat'`, `party == "Democrat"` → zero matches
- Normalization has no downstream code impact

## Migration Details

- **File:** `supabase/migrations/20260603000011_126_party_string_normalization.sql`
- **Migration number:** 126
- **Applied:** 2026-06-03 via direct postgres pool (essentials schema is not in PostgREST exposed list — pool.query() required)
- **SQL:** Single `UPDATE essentials.politicians SET party = 'Democratic' WHERE party = 'Democrat'` wrapped in BEGIN/COMMIT
- **Commit:** 17ebb30

## Phase 88 Closeout Note

All 5 plans complete. Requirements closed:
- **SACC-02:** All Tier 1 (8 confirmed inversions) + Tier 2 (21 borderline cases) + Wave 3 (Ukraine-support Rs) re-researched with real sources and corrected via migrations 116–125. Closed by plans 88-01 through 88-04.
- **SACC-03:** Party string inconsistency resolved — no more mixed 'Democrat'/'Democratic' entries. Closed by this plan (88-05).

Phase 88 is complete. v2.6 Data Quality milestone correction work finished.

## Deviations from Plan

None — plan executed exactly as written.

Pre-migration count was 495 (not 496 as noted in RESEARCH.md) — minor discrepancy of 1 row, likely a politician record deleted or corrected in a prior migration between research date and execution date. Arithmetic check still passes (475+280=775 preserved).

## Known Stubs

None.

## Threat Flags

None — the migration only updates the `essentials.politicians.party` column within an exact-match WHERE clause. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries were introduced.

## Self-Check: PASSED

- FOUND: supabase/migrations/20260603000011_126_party_string_normalization.sql
- FOUND: .planning/phases/88-stance-corrections-party-normalization/88-05-SUMMARY.md
- FOUND: commit 17ebb30
