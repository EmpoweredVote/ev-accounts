---
phase: 109-per-meeting-body-tagging
fixed_at: 2026-04-11T00:00:00Z
review_path: .planning/phases/109-per-meeting-body-tagging/109-REVIEW.md
iteration: 2
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 109: Code Review Fix Report

**Fixed at:** 2026-04-11
**Source review:** .planning/phases/109-per-meeting-body-tagging/109-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 7
- Fixed: 7 (2 previously in iteration 1, 5 new in iteration 2)
- Skipped: 0

## Fixed Issues

### H-01: `--force-retag` leaves stale Stage 4 artifacts on disk

**Files modified:** `CouncilScribe/src/checkpoint.py`, `CouncilScribe/tests/test_body_tagging.py`
**Commit:** d5b9f5e (in CouncilScribe repo)
**Status:** fixed: requires human verification (previously fixed in iteration 1)

**Applied fix:** Extended `PipelineState.rewind_for_retag()` to delete all
three stale Stage 4+ artifacts (`pre_identifications.json`,
`llm_partial_results.json`, `transcript_named.json`). Method now calls
`self.save()` atomically after unlinks. Test updated to assert all three
files are removed.

### M-01: `rewind_for_retag()` is non-atomic across state file + pre_identifications.json

**Files modified:** `CouncilScribe/src/checkpoint.py`, `CouncilScribe/run_local.py`
**Commit:** a95ccad + d5b9f5e (in CouncilScribe repo)
**Status:** fixed (previously fixed in iteration 1)

**Applied fix:** `rewind_for_retag()` now calls `self.save()` internally.
Docstring updated. Caller in `run_local.py` no longer calls `state.save()`
after `rewind_for_retag()`.

### L-01: Dead defensive branch in resolve block

**Files modified:** `CouncilScribe/run_local.py`
**Commit:** a861c6c (in CouncilScribe repo)
**Status:** fixed

**Applied fix:** Replaced the unreachable `pass` in the
`elif not cli_body and persisted_body and force_retag` branch with
`raise AssertionError(...)` so future refactors that remove D-12 argparse
enforcement fail loudly instead of silently doing nothing.

### L-02: `--force-retag` against untagged meeting silently degrades

**Files modified:** `CouncilScribe/run_local.py`
**Commit:** a82451e (in CouncilScribe repo)
**Status:** fixed

**Applied fix:** Added a diagnostic `stderr` log line when `--force-retag`
is used on a meeting with no persisted `body_slug`, informing the operator
that it behaves as a first-run persist (no rewind needed).

### IN-01: `_BODY_SLUG_RE` has no length cap

**Files modified:** `CouncilScribe/run_local.py`
**Commit:** 9dd6ccb (in CouncilScribe repo)
**Status:** fixed

**Applied fix:** Tightened regex from `^[a-z0-9][a-z0-9_-]*$` to
`^[a-z0-9][a-z0-9_-]{0,63}$` (1-64 chars total). Updated the error
message to show the new constraint. Prevents pathologically long slugs
from reaching filesystem operations.

### IN-02: Lazy `from src import config` inside guard

**Files modified:** `CouncilScribe/run_local.py`
**Commit:** 2002e9a (in CouncilScribe repo)
**Status:** fixed

**Applied fix:** Moved `from src import config` to module level (after
`.env.local` loading, which sets `CS_DATA_DIR` before `src.config`
reads it at import time). Removed the redundant lazy import inside
`ensure_body_roster_cached`. `src.config` is lightweight with no
circular import risk.

### IN-03: Force-retag log goes to stderr but `Body:` info goes to stdout

**Files modified:** `CouncilScribe/run_local.py`
**Commit:** 767b0e4 (in CouncilScribe repo)
**Status:** fixed

**Applied fix:** Changed `print(f"Body: {effective_body_slug}")` to route
to `stderr` via `file=sys.stderr`, matching the force-retag diagnostic
line. All body-tagging diagnostics now consistently use stderr.

## Skipped Issues

None.

---

_Fixed: 2026-04-11_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
