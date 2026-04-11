---
phase: 109
plan: 02
subsystem: CouncilScribe
tags: [councilscribe, cli, fail-fast, validation, security]
dependency_graph:
  requires: [109-01]
  provides: [ensure_body_roster_cached, pre-Stage-1 fail-fast guard, T-109-03 slug validation]
  affects: [CouncilScribe/run_local.py, CouncilScribe/tests/test_body_tagging.py]
tech_stack:
  added: []
  patterns: [fail-fast-guard, regex-slug-validation, pre-stage-exit]
key_files:
  created: []
  modified:
    - CouncilScribe/run_local.py
    - CouncilScribe/tests/test_body_tagging.py
decisions:
  - ensure_body_roster_cached() implemented as module-level helper in run_local.py (not a separate src/body.py) to keep it alongside run_pipeline where it is invoked
  - Slug validation uses compiled _BODY_SLUG_RE regex at module level (not inside function) for efficiency and testability
  - Tests exercise ensure_body_roster_cached() directly (not via run_pipeline subprocess) to avoid GPU/HF token requirements — same pattern as Plan 01's _resolve_body_slug() helper approach
  - Guard call placed after print(f"Body: effective_body_slug") and before Meeting() construction — satisfies D-07 (after resolve, before Stage 1 work)
metrics:
  duration: ~8 minutes
  completed: "2026-04-11"
  tasks: 2
  files: 2
requirements: [CSMEETING-02]
---

# Phase 109 Plan 02: Pre-Stage-1 fail-fast guard Summary

**One-liner:** `ensure_body_roster_cached()` guard with `_BODY_SLUG_RE` slug validation wired before Stage 1 in `run_pipeline` — operators get a 1-second D-08 error instead of burning GPU on a missing-roster run.

## What Was Built

### Task 1: ensure_body_roster_cached() helper

Added to `CouncilScribe/run_local.py` immediately after the imports block:

- `import re` and `from typing import Optional` added to top-level imports
- `_BODY_SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9_-]*$")` — T-109-03 mitigation, compiled at module level
- `ensure_body_roster_cached(body_slug: Optional[str]) -> None` — implements all CSMEETING-02 decisions:
  - D-05: `None`/empty slug returns silently (legacy path unaffected)
  - T-109-03: slug validated against `_BODY_SLUG_RE` before any `Path` join — rejects `..`, `/`, `\`, whitespace, null bytes
  - D-08: on missing cache, prints exact 2-line stderr error (`ERROR: Body "..." has no cached roster at ~/CouncilScribe/config/rosters/...` + `Run: python refresh_roster.py --body ...`) then `sys.exit(2)`
  - D-09: file existence is the only check — staleness handled later by `load_roster()`
  - D-10: resume-with-deleted-cache fails identically (same missing-file path)
  - D-13: error string uses literal `~/CouncilScribe/config/rosters/` (not expanded `CONFIG_DIR`)

### Task 2: Guard wired in run_pipeline + 3 tests green

- Single call `ensure_body_roster_cached(effective_body_slug)` inserted after Plan 01's resolve block (after `print(f"Body: {effective_body_slug}")`) and before `meeting = Meeting(...)` construction
- Byte-offset verified: guard position < Stage 1 banner position in file
- 3 new test implementations in `CouncilScribe/tests/test_body_tagging.py`:
  - `test_missing_roster_fails_fast` — slug with no cache file → `SystemExit(2)` (D-07 + D-08)
  - `test_resume_after_cache_delete_fails_fast` — persisted slug + deleted cache → `SystemExit(2)` (D-10)
  - `test_stale_cache_is_non_blocking` — stale file (fetched_at=2020-01-01) → guard returns, no exit (D-09)

## Test Results

| Test | Status | Plan |
|------|--------|------|
| test_first_run_persists_body_slug | GREEN | 01 |
| test_reinvocation_reads_persisted_slug | GREEN | 01 |
| test_mismatched_body_hard_error | GREEN | 01 |
| test_force_retag_rewinds_and_clears | GREEN | 01 |
| test_force_retag_requires_body | GREEN | 01 |
| test_batch_propagates_body | GREEN | 01 |
| test_missing_roster_fails_fast | GREEN | 02 |
| test_resume_after_cache_delete_fails_fast | GREEN | 02 |
| test_stale_cache_is_non_blocking | GREEN | 02 |
| test_stage4_uses_body_roster | RED (stub) | 03 |
| test_legacy_fallback_intact | RED (stub) | 03 |

**9/11 green — CSMEETING-02 slice complete. 2 remain red for Plan 03.**

## Commits

| Hash | Message |
|------|---------|
| caa5a01 | feat(109-02): add ensure_body_roster_cached() guard with slug validation + D-08 error |
| 7349f96 | feat(109-02): wire ensure_body_roster_cached into run_pipeline before Stage 1 + green tests |

## Deviations from Plan

None — plan executed exactly as written.

The plan's success criteria says "10 of 11 tests green" but Plan 01's summary shows `test_legacy_fallback_intact` is a Plan 03 stub. Actual result is 9/11 green with 2 intentional Plan 03 stubs — consistent with Plan 01's test table which assigns both remaining stubs to Plan 03.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The `_BODY_SLUG_RE` validation explicitly mitigates T-109-03 (path-traversal via `--body`) by rejecting untrusted slug strings before any `Path` join. No new trust boundaries opened.

## Self-Check: PASSED

- SUMMARY.md exists at .planning/phases/109-per-meeting-body-tagging/109-02-SUMMARY.md — FOUND
- Commit caa5a01 (ensure_body_roster_cached helper) — FOUND
- Commit 7349f96 (wiring + tests) — FOUND
- `grep -q "def ensure_body_roster_cached" CouncilScribe/run_local.py` — PASSES
- `grep -q "_BODY_SLUG_RE" CouncilScribe/run_local.py` — PASSES
- `grep -q "ensure_body_roster_cached(effective_body_slug)" CouncilScribe/run_local.py` — PASSES
- 9/11 tests green (3 new Plan 02 tests + 6 Plan 01 regression tests) — VERIFIED
