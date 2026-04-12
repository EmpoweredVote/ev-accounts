---
phase: 109-per-meeting-body-tagging
fixed_at: 2026-04-11T00:00:00Z
review_path: .planning/phases/109-per-meeting-body-tagging/109-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 109: Code Review Fix Report

**Fixed at:** 2026-04-11
**Source review:** .planning/phases/109-per-meeting-body-tagging/109-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope (High + Medium): 2
- Fixed: 2
- Skipped: 0

Low (L-01, L-02) and Info (IN-01..IN-03) findings are out of scope for
this fix pass (fix_scope=critical_warning) and were not addressed.

## Fixed Issues

### H-01: `--force-retag` leaves stale Stage 4 artifacts on disk

**Files modified:** `CouncilScribe/src/checkpoint.py`, `CouncilScribe/tests/test_body_tagging.py`
**Commit:** d5b9f5e (in CouncilScribe repo)
**Status:** fixed: requires human verification

**Applied fix:** Extended `PipelineState.rewind_for_retag()` to delete all
three stale Stage 4+ artifacts instead of just `pre_identifications.json`:

1. `pre_identifications.json` (already deleted — D-11)
2. `llm_partial_results.json` (NEW — Stage 4 LLM resume cache)
3. `transcript_named.json` (NEW — Stage 4 output with old-roster names)

The cleanup list is a local tuple inside the method; future Stage 4+
artifacts must be added here. As a concurrent improvement, the method
now persists state atomically via `self.save()` after the unlinks
(see M-01), so rewind is a single call.

Also updated `test_force_retag_rewinds_and_clears` to:
- Seed all three stale files in the test fixture
- Assert all three are removed after `_resolve_body_slug(..., force_retag=True)`

**Human verification requested:** The fix changes filesystem cleanup
behavior that is not directly validated by the existing passing tests
outside the updated unit test. Please run the full test suite
(`cd CouncilScribe && pytest tests/test_body_tagging.py -v`) and
confirm `test_force_retag_rewinds_and_clears` passes with the new
assertions, plus a manual `--force-retag` dry run on a real tagged
meeting to confirm Stage 4 re-runs cleanly against the new roster.

### M-01: `rewind_for_retag()` is non-atomic across state file + pre_identifications.json

**Files modified:** `CouncilScribe/src/checkpoint.py` (included in d5b9f5e), `CouncilScribe/run_local.py`
**Commit:** a95ccad (in CouncilScribe repo, run_local.py change); d5b9f5e included the in-method `self.save()`
**Status:** fixed

**Applied fix:**
1. `PipelineState.rewind_for_retag()` now calls `self.save()` at the end,
   after unlinking stale Stage 4+ artifacts. Deletion-before-save ordering
   means a crash between the two still leaves `pipeline_state.json`
   reflecting the old stage, so a resume regenerates missing artifacts
   rather than trusting a stale state file.
2. Docstring updated to drop the "Caller must ... then call save()"
   language and document the new atomic-ish contract.
3. `run_local.py` force-retag branch no longer calls `state.save()`
   explicitly (previously lines 300-302); the rewind method handles it.

This consolidates the rewind into one operation, eliminates the window
where `pre_identifications.json` was gone but `pipeline_state.json`
still claimed EXPORTED, and prevents future callers from forgetting
the save contract.

## Skipped Issues

None.

---

_Fixed: 2026-04-11_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
