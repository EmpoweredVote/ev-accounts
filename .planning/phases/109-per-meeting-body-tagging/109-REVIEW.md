---
phase: 109-per-meeting-body-tagging
reviewed: 2026-04-11T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - CouncilScribe/src/checkpoint.py
  - CouncilScribe/run_local.py
  - CouncilScribe/tests/test_body_tagging.py
findings:
  blocker: 0
  high: 1
  medium: 1
  low: 2
  info: 3
  critical: 0
  warning: 2
  total: 7
status: issues_found
---

# Phase 109: Code Review Report

**Reviewed:** 2026-04-11
**Depth:** standard
**Files Reviewed:** 3 (checkpoint.py, run_local.py Phase-109 regions, test_body_tagging.py)
**Status:** issues_found

## Summary

Phase 109 (per-meeting body tagging) is a small, tightly-scoped change across
three Python files. The implementation is clean, well-commented, and closely
tracks the plan. Threat model items T-109-01 (atomic checkpoint), T-109-02
(force-retag invalidation), and T-109-03 (path traversal) are all mitigated.

One meaningful correctness gap (HIGH) was found: `rewind_for_retag()` does
not delete `transcript_named.json` or `llm_partial_results.json`, which means
a `--force-retag` run can resume Stage 4 LLM identification against cached
partial results from the OLD roster. This partially undermines D-04's
promise that "stages 4-7 re-run against the new roster."

One MEDIUM issue: `rewind_for_retag()` mutates on-disk state (deletes
`pre_identifications.json`) before the caller calls `save()`, so an exception
between the two creates an inconsistent directory.

The rest are minor/info observations.

## High

### H-01: `--force-retag` leaves stale Stage 4 artifacts on disk

**File:** `CouncilScribe/src/checkpoint.py:71-82` and `CouncilScribe/run_local.py:297-302, 676-681, 706`
**Issue:** `rewind_for_retag()` rewinds `completed_stage` to `TRANSCRIBED` and
deletes `pre_identifications.json`, but leaves two other Stage 4 artifacts
untouched:

- `transcript_named.json` — Stage 4 output containing speaker names from the
  OLD roster. At `run_local.py:676`, the `is_complete(IDENTIFIED)` check will
  be False after rewind, so this file is overwritten cleanly on re-run — OK
  in the happy path, but if the re-run crashes mid-Stage-4, the on-disk
  `transcript_named.json` still reflects the old roster while
  `pipeline_state.json` claims we have the new body_slug and stage 3. A
  subsequent resume that skips stage 4 (e.g. if a later bug sets
  `completed_stage` back to 4 without regenerating) would surface old names.
- `llm_partial_results.json` — passed to `llm_identify_speakers` at line 706
  as `partial_results_path`. LLM identification uses this to resume partial
  progress. After a force-retag, this file contains speaker guesses made
  against the OLD roster hint. When the body-specific roster re-runs Stage
  4, the LLM helper may load and trust these stale partial guesses, mixing
  old-roster names into the new-roster output. This directly contradicts
  D-04's "Stages 4/5/6/7 re-run against the new roster on the same
  invocation."

Plan 01 D-04 rationale states: "`transcript_named.json`, summaries, and
voice-profile enrollments produced against the old roster are now stale —
forcing re-run is the only way to keep artifacts consistent." The plan
identified the risk; the implementation only deleted one of the three
mentioned files.

**Fix:** Extend `rewind_for_retag()` to remove all Stage 4+ artifacts
touched by CSMEETING-03's roster swap, and have the method persist state
itself so callers can't forget:

```python
def rewind_for_retag(self) -> None:
    """D-04: Invalidate downstream stages when body_slug changes."""
    self.completed_stage = PipelineStage.TRANSCRIBED
    self.transcription_progress = 0  # optional: only if stage 3 also re-runs
    stale = [
        "pre_identifications.json",   # D-11
        "llm_partial_results.json",   # Stage 4 LLM resume cache
        "transcript_named.json",      # Stage 4 output
    ]
    for name in stale:
        p = self.meeting_dir / name
        if p.exists():
            p.unlink()
    self.save()  # atomic persist; no half-rewound state on disk
```

Also update the call site in `run_local.py:300-302` to drop the explicit
`state.save()` since the method now handles it, and add the two new file
names to the existing test `test_force_retag_rewinds_and_clears` so the
guarantee is enforced in CI.

Note: if Phase 110 adds more stage-4-output files, this list must grow.
Consider making the cleanup list a module-level constant near
`PipelineStage` so future phases update one place.

## Medium

### M-01: `rewind_for_retag()` is non-atomic across state file + pre_identifications.json

**File:** `CouncilScribe/src/checkpoint.py:71-82`
**Issue:** The method mutates in-memory `completed_stage` and unlinks
`pre_identifications.json` but does NOT call `self.save()`. The contract is
documented in the docstring ("Caller must ... call save()"), and the current
single caller (`run_local.py:300-302`) follows it correctly. But:

1. If `pre_identifications.json.unlink()` succeeds and then `state.save()`
   is interrupted (SIGINT, disk full, OS crash), `pipeline_state.json`
   on disk still says `completed_stage=EXPORTED` with `body_slug=old_slug`,
   while `pre_identifications.json` is gone — an inconsistent state that
   neither the old nor new body can resume cleanly.
2. Any future caller that forgets the `.save()` contract silently leaves
   the atomic-write discipline broken — the whole point of
   `PipelineState.save()` using tempfile+`os.replace` is to make checkpoint
   mutations atomic; splitting `rewind_for_retag` across two steps defeats
   that guarantee.

**Fix:** Call `self.save()` at the end of `rewind_for_retag()` (see H-01
fix). Delete the "Caller must ... then call save()" language from the
docstring. Update `run_local.py:300-302` to drop the now-redundant explicit
save. This also neatly consolidates H-01's cleanup list into a single
atomic-ish operation (note: deleting files is still not transactional with
respect to the state file; the best you can do is delete files FIRST, then
save the rewound state — that way if the crash happens between, the state
file still reflects the old stage and a resume will recompute the missing
artifacts rather than trust a stale `pipeline_state.json`).

## Low

### L-01: Dead defensive branch in resolve block

**File:** `CouncilScribe/run_local.py:307-309`
**Issue:** The branch
```python
elif not cli_body and persisted_body and force_retag:
    # Already guarded at argparse level; defensive no-op
    pass
```
is unreachable: D-12 enforcement at `run_local.py:1835` (`if args.force_retag
and not args.body: parser.error(...)`) exits with code 2 before
`run_pipeline` is called. The comment acknowledges this, but dead branches
that can never fire are a code-smell — if D-12 enforcement is ever moved or
removed, this silent `pass` becomes a surprising footgun (force-retag with
no body silently does nothing instead of erroring).

**Fix:** Either remove the branch entirely, or replace the `pass` with an
explicit assertion so future refactors fail loudly:

```python
elif not cli_body and persisted_body and force_retag:
    # Should be unreachable: D-12 enforced at argparse (line 1835).
    raise AssertionError("--force-retag without --body bypassed D-12 guard")
```

### L-02: `--force-retag` against an untagged meeting silently degrades to first-run

**File:** `CouncilScribe/run_local.py:287-306`
**Issue:** If an operator runs `--body X --force-retag` against a meeting
that has no persisted body_slug yet:
- Line 287 mismatch-check skipped (persisted is None)
- Line 297 force-retag-with-mismatch skipped (persisted is None)
- Line 303 `cli_body and not persisted_body` matches → body is persisted
  as a first-run, no rewind, no pre_identifications cleanup.

This is probably harmless — there is nothing stale to invalidate — but it
means `--force-retag` has two different behaviors depending on persisted
state (rewind-and-overwrite vs silent first-run). Either is defensible; the
ambiguity should at least be logged.

**Fix:** Detect this case and print a single info line so the operator
knows `--force-retag` was a no-op:

```python
elif cli_body and not persisted_body:
    if force_retag:
        print(
            f"  --force-retag on untagged meeting: behaving as first-run "
            f"persist of {cli_body}",
            file=sys.stderr,
        )
    state.body_slug = cli_body
    state.save()
```

## Info

### IN-01: `_BODY_SLUG_RE` has no length cap

**File:** `CouncilScribe/run_local.py:45`
**Issue:** `^[a-z0-9][a-z0-9_-]*$` accepts arbitrarily long slugs. A
pathological 10 KB slug would pass validation and then be joined into a
filesystem path. Not a security issue (the regex blocks path separators),
but `Path` on some filesystems caps individual component names at 255
bytes and will raise `OSError: File name too long`, which surfaces as an
ugly stacktrace rather than the clean D-08 error.

**Fix:** Tighten to `^[a-z0-9][a-z0-9_-]{0,63}$` (64 chars total) or similar.
Realistic slugs like `bloomington-common-council` are ~27 chars.

### IN-02: Lazy `from src import config` inside guard

**File:** `CouncilScribe/run_local.py:71`
**Issue:** `ensure_body_roster_cached` does `from src import config` inside
the function body. Plan 02's summary notes this was intentional to avoid
circular imports, but `src.config` is already imported at top-level in
several other places in the file, and there's no apparent circular-import
risk (`src/config.py` does not import `run_local`). Inline imports
complicate static analysis and are mildly slower on each call.

**Fix:** Move `from src import config` to the top-level imports block
alongside the existing `from src.checkpoint import ...` etc. No behavior
change.

### IN-03: `--force-retag` log line goes to stderr, not stdout

**File:** `CouncilScribe/run_local.py:299`
**Issue:** The "Force-retag: old → new" message is printed to `stderr`,
while the `Body: <slug>` info line at line 316 goes to `stdout`. Mixed
streams make it harder for operators to `tee` or grep logs consistently.
The plan/context does not specify which stream this should use.

**Fix:** Either route both to stdout (they're informational, not errors) or
document the split. Mild preference for stdout since this is an intentional
operator action, not an error condition.

---

## Positive Notes

- **Atomic write discipline preserved.** `PipelineState.save()` still uses
  `tempfile.mkstemp` + `os.replace`, with `body_slug` round-tripping
  cleanly. Legacy JSON without the key loads as `None` via
  `data.get("body_slug")` — backward compatibility confirmed.
- **T-109-03 mitigation is sound.** `_BODY_SLUG_RE` is compiled once at
  module load, validates BEFORE the `CONFIG_DIR / "rosters" / f"{slug}.json"`
  join, rejects `..`, `/`, `\`, whitespace, null bytes, and leading hyphens.
  The tests in `test_body_tagging.py` (via Plan 02 verify-script in the
  SUMMARY, though not in the test file itself) exercise the path-traversal
  and shell-metacharacter cases.
- **D-05 legacy fallback is intact and tested.**
  `test_legacy_fallback_intact` covers the `effective_body_slug is None`
  branch at `run_local.py:665-666`, and the bare `load_roster()` calls at
  the three offline utility sites (1126, 1842, 1872) are intentionally
  unchanged and documented in the code comment with a pointer to
  `109-RESEARCH.md §1`.
- **Error messages do not leak filesystem paths.** Per D-13, the D-08 error
  uses the literal `~/CouncilScribe/config/rosters/<slug>.json` string
  rather than expanding `CONFIG_DIR`, so the operator gets a stable,
  shareable path that doesn't reveal the actual `$HOME`.
- **No antipartisan regressions.** No `party` references introduced in the
  modified regions.
- **Tests cover all 13 decisions (D-01..D-13) and all three CSMEETING
  requirements.** 11/11 tests pass; 60/60 in the full suite.

---

_Reviewed: 2026-04-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
