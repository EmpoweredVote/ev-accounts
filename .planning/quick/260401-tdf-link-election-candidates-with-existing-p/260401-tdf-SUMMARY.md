---
phase: quick
plan: 260401-tdf
subsystem: essentials-elections
tags: [elections, candidates, politicians, data-linking, monroe-county]
dependency-graph:
  requires: [q95-01]
  provides: [candidate-politician-linkage]
  affects: [candidate-profiles, essentials-elections]
tech-stack:
  added: []
  patterns: [idempotent-sql-scripts, name-matching-with-prefix]
key-files:
  created:
    - ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql
  modified: []
decisions:
  - Used 3-character first_name prefix matching to disambiguate last_name collisions (e.g., Scott Smith)
  - Set is_incumbent=true for all linked candidates since they have existing politician records
  - Fixed Efrat Feferman name to Efrat Rosser (married name) as part of data correction
metrics:
  duration: ~20min
  completed: 2026-04-01
---

# Quick Task 260401-tdf: Link Election Candidates with Existing Politicians Summary

Idempotent SQL script linking Monroe County 2026 primary race_candidates to existing essentials.politicians records via last_name + first_name prefix matching, enabling CandidateProfile pages to show full politician data for incumbents.

## What Was Done

### Task 1: Create candidate-to-politician linking script

Created `link-monroe-candidates-to-politicians.sql` with four steps:

- **Step 0 (Name Fix):** Corrected Efrat Feferman to Efrat Rosser (married name change) in essentials.politicians, including slug update
- **Step 1 (Preview):** SELECT query showing candidate-to-politician matches by `lower(last_name)` + `lower(left(first_name, 3))` prefix
- **Step 2 (Update):** CTE-based UPDATE setting `politician_id` and `is_incumbent = true` on matched race_candidates (only where `politician_id IS NULL` for idempotency)
- **Step 3 (Verify):** Verification query showing all candidates ordered by link status

### Task 2: Execute against production

Script was run against production Supabase:

- **45 candidates linked** total (44 via automated matching + 1 after Efrat Rosser name fix)
- **Scott Smith** correctly matched to the Polk Township Trustee politician (not the Council At Large one) via first_name prefix disambiguation
- **~36 candidates remain unlinked** — these are genuine challengers without existing politician records in essentials.politicians

## Deviations from Plan

None — executed as designed.

## Known Stubs

None.

## Verification

- Verification query (Step 3) confirmed 45 candidates have non-null politician_id with is_incumbent = true
- Remaining unlinked candidates are expected (new challengers)
- Script is idempotent and safe to re-run
