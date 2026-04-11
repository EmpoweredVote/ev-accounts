---
phase: 109-per-meeting-body-tagging
verified: 2026-04-11T00:00:00Z
status: gaps_found
score: 3/3 roadmap success criteria verified
re_verification: false
gaps:
  - truth: "--force-retag fully invalidates all Stage 4 stale artifacts (D-04)"
    status: partial
    reason: "rewind_for_retag() deletes pre_identifications.json (D-11) but leaves transcript_named.json and llm_partial_results.json on disk. After a force-retag that crashes mid-Stage-4, the directory holds old-roster names in transcript_named.json while pipeline_state.json shows the new body_slug and completed_stage=TRANSCRIBED. Additionally, rewind_for_retag() does not call self.save() internally — the method relies on the caller to call save() afterward, which the current caller does correctly but the docstring promise of atomicity is incomplete. Identified in code review as H-01 (HIGH) and M-01 (MEDIUM)."
    artifacts:
      - path: "CouncilScribe/src/checkpoint.py"
        issue: "rewind_for_retag() at lines 71-82 does not delete transcript_named.json or llm_partial_results.json, and does not call self.save() — violating D-04 completeness and the class's atomic-write discipline"
    missing:
      - "Extend rewind_for_retag() stale-file list to include llm_partial_results.json and transcript_named.json"
      - "Call self.save() inside rewind_for_retag() (delete stale files FIRST, then save) so the method is self-contained and callers cannot forget"
      - "Remove the 'Caller must ... then call save()' language from the docstring once self.save() is moved inside"
      - "Drop the explicit state.save() call at run_local.py:302 since the method will handle it"
      - "Add llm_partial_results.json and transcript_named.json to test_force_retag_rewinds_and_clears assertions"
human_verification:
  - test: "End-to-end tagged meeting run"
    expected: "Running `python run_local.py --body bloomington-common-council <meeting-dir>` prints 'Body: bloomington-common-council', passes the fail-fast guard, and Stage 4 produces transcript_named.json with names drawn from the bloomington-common-council roster (not phantom names)"
    why_human: "Requires real audio file, GPU, and a refreshed cached roster at ~/CouncilScribe/config/rosters/bloomington-common-council.json. VALIDATION.md explicitly defers end-to-end identification fidelity to Phase 111."
---

# Phase 109: Per-meeting body tagging Verification Report

**Phase Goal:** Every meeting run declares which governing body it belongs to, and that slug flows through the pipeline so identification consumes the right roster.
**Verified:** 2026-04-11
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| #  | Truth | Status | Evidence |
|----|-------|--------|---------|
| 1  | A meeting tagged with `--body X` persists that slug to pipeline metadata and reads it back on every subsequent stage invocation without re-specifying the flag | VERIFIED | `PipelineState.body_slug` persists atomically via `os.replace` (checkpoint.py:47-65). `_resolve_body_slug()` helper in tests exercises D-01/D-02/D-03/D-04/D-06. All 6 CSMEETING-01 tests green. Commit b0b580a + f1b8007. |
| 2  | Launching a meeting with a body slug that has no cached roster fails fast with a clear error message telling the operator to run `refresh_roster.py` | VERIFIED | `ensure_body_roster_cached()` at run_local.py:48-85 fires before `Meeting()` construction (line 322), before Stage 1. D-08 two-line error confirmed in code. Slug regex T-109-03 mitigation in place. 4 CSMEETING-02 tests green. Commit caa5a01 + 7349f96. |
| 3  | Stage 4 uses the body-specific roster for `correct_speaker_name`, pattern matching, and the LLM prompt — no code path falls back to the legacy global roster when a body_slug is present | VERIFIED | `if effective_body_slug: roster = load_roster(body_slug=effective_body_slug) else: roster = load_roster()` at run_local.py:663-666. Downstream `identify_speakers` and `roster_names_for_prompt` receive the returned Roster object unchanged. Both CSMEETING-03 tests green. Commit d2691a0. |

**Score: 3/3 roadmap truths verified**

### Gap: --force-retag Partial Invalidation (H-01 + M-01 from code review)

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| G1 | `--force-retag` fully invalidates all Stage 4 stale artifacts per D-04 | PARTIAL | `rewind_for_retag()` (checkpoint.py:71-82) deletes only `pre_identifications.json`. `transcript_named.json` and `llm_partial_results.json` are left on disk. In the happy path these are overwritten when Stage 4 re-runs, but a mid-Stage-4 crash produces an inconsistent directory: `pipeline_state.json` claims new body_slug at TRANSCRIBED while `transcript_named.json` holds old-roster speaker names. Additionally, the method does not call `self.save()` internally — the single current caller (run_local.py:302) adds it explicitly, but the method contract is fragile and the docstring's atomicity claim is misleading. Code review rated H-01 (HIGH) + M-01 (MEDIUM). |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `CouncilScribe/src/checkpoint.py` | PipelineState.body_slug attribute with atomic persistence | VERIFIED | Lines 35, 45, 53, 71-82. body_slug defaults None, round-trips atomically, legacy JSON without key loads cleanly. |
| `CouncilScribe/run_local.py` | --body / --force-retag argparse flags + resolve logic | VERIFIED | Flags at lines 1818-1829, D-12 guard at 1835-1836, resolve block at 282-316, batch propagation at 1067-1068. |
| `CouncilScribe/run_local.py` | ensure_body_roster_cached() guard helper | VERIFIED | Lines 48-85. _BODY_SLUG_RE at line 45. Guard invoked at line 320, before Meeting() at line 322. |
| `CouncilScribe/run_local.py` | Stage 4 body-aware load_roster call | VERIFIED | Lines 663-666. Conditional on effective_body_slug. Offline utility sites (1126, 1842, 1872) intentionally untouched with documented scope narrowing. |
| `CouncilScribe/tests/test_body_tagging.py` | 11 tests covering CSMEETING-01/02/03 and D-01..D-13 | VERIFIED | 11 test functions confirmed. All 11 pass: `.venv/bin/pytest tests/test_body_tagging.py -x -q` → 11 passed in 0.05s. |
| `CouncilScribe/tests/conftest.py` | tmp_config_dir, tmp_meetings_dir, fake_roster_cache, tagged_meeting_dir fixtures | VERIFIED | All 4 fixtures confirmed at lines 22, 36, 45, 86. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| run_local.py argparse | PipelineState.body_slug | run_pipeline resolve block (effective_body_slug) | WIRED | cli_body → state.body_slug → save() at lines 282-312 |
| run_local.py _run_batch | batch_args Namespace | explicit body= and force_retag= kwargs | WIRED | Lines 1067-1068: `body=getattr(args, "body", None), force_retag=getattr(args, "force_retag", False)` |
| run_pipeline effective_body_slug | ensure_body_roster_cached() | pre-Stage-1 call at line 320 | WIRED | Call at line 320, before Meeting() at 322, before Stage 1 banner |
| effective_body_slug (Plan 01) | Stage 4 load_roster(body_slug=...) | conditional at run_local.py:663 | WIRED | `if effective_body_slug: roster = load_roster(body_slug=effective_body_slug)` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| run_local.py Stage 4 | `roster` | `load_roster(body_slug=effective_body_slug)` when tagged | Yes — reads from `~/CouncilScribe/config/rosters/{slug}.json` (validated present by ensure_body_roster_cached before Stage 4 runs) | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 11 body tagging tests pass | `.venv/bin/pytest tests/test_body_tagging.py -x -q` | 11 passed in 0.05s | PASS |
| --force-retag without --body exits 2 | subprocess test via test_force_retag_requires_body | Confirmed by test passing | PASS |
| End-to-end tagged meeting | Requires GPU + real audio | Not runnable without hardware | SKIP (human) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| CSMEETING-01 | 109-01 | Meeting metadata accepts body_slug field; --body flag persists; mismatch hard error; --force-retag escape hatch; batch propagation | SATISFIED | 6 tests green; checkpoint.py body_slug attribute; argparse flags + resolve block; batch_args propagation confirmed |
| CSMEETING-02 | 109-02 | --body reads from metadata on subsequent runs; fails fast if slug has no cached roster | SATISFIED | ensure_body_roster_cached() guard; 4 tests green; T-109-03 slug validation |
| CSMEETING-03 | 109-03 | Stage 4 loads body-specific roster; no legacy fallback when body is tagged | SATISFIED | Conditional at run_local.py:663-666; 2 tests green; offline utility sites explicitly scoped out with documentation |

No orphaned CSMEETING requirements. CSPROFILE and CSIDENT requirements are correctly mapped to Phases 110 and 111.

### Anti-Patterns Found

| File | Lines | Pattern | Severity | Impact |
|------|-------|---------|----------|--------|
| CouncilScribe/src/checkpoint.py | 71-82 | `rewind_for_retag()` does not delete `transcript_named.json` / `llm_partial_results.json`; does not call `self.save()` | Blocker (correctness gap, not a stub) | Force-retag with mid-Stage-4 crash leaves inconsistent artifacts; method atomicity discipline broken (H-01 + M-01 from code review) |
| CouncilScribe/run_local.py | 307-309 | Dead defensive branch `elif not cli_body and persisted_body and force_retag: pass` — unreachable because D-12 exits before run_pipeline | Info | Code smell only — does not affect behavior |

### Human Verification Required

#### 1. End-to-end tagged Bloomington meeting

**Test:** Run `python run_local.py --body bloomington-common-council <existing-meeting-dir>` against a real meeting directory with a cached roster at `~/CouncilScribe/config/rosters/bloomington-common-council.json`.

**Expected:** Pipeline prints `Body: bloomington-common-council`, passes the fail-fast guard (no D-08 error), Stage 4 runs with the Bloomington roster, and `transcript_named.json` contains speaker names that appear in the Bloomington Common Council roster.

**Why human:** Requires real audio file, a GPU (pyannote speaker diarization), and a refreshed cached roster file. VALIDATION.md explicitly defers end-to-end identification fidelity to Phase 111. Cannot test programmatically without these resources.

### Gaps Summary

**1 gap blocking full D-04 promise (H-01 + M-01 from code review):**

`rewind_for_retag()` in `CouncilScribe/src/checkpoint.py` was implemented to delete only `pre_identifications.json` when a `--force-retag` changes the body_slug. The plan (109-01 D-04 rationale) correctly identified that `transcript_named.json`, summaries, and voice-profile enrollments produced against the old roster are stale, but the implementation only deleted one of the three files. In the happy path this is not observable — Stage 4 re-runs and overwrites `transcript_named.json` cleanly. The risk surfaces on a crash between `rewind_for_retag()` and the completion of Stage 4: the directory would hold old-roster names in `transcript_named.json` while `pipeline_state.json` reports the new slug at stage TRANSCRIBED, and a subsequent resume that skips Stage 4 (due to a future bug or a manual `completed_stage` edit) would serve stale identification output.

The companion issue (M-01) is that `rewind_for_retag()` mutates in-memory state and deletes `pre_identifications.json` but does not call `self.save()`. The current single caller adds the save explicitly and correctly, but this creates an invisible contract that any future caller can silently break. The class's atomic-write discipline (tempfile + os.replace) is designed so all state mutations are self-contained in `save()` — splitting `rewind_for_retag` across the method + caller defeats that guarantee.

**Fix:** Extend `rewind_for_retag()` to delete `llm_partial_results.json` and `transcript_named.json` in addition to `pre_identifications.json`, move `self.save()` inside the method (deleting files first, then saving rewound state), remove the docstring's "Caller must ... then call save()" language, and drop the now-redundant explicit `state.save()` at run_local.py:302. Add the two new file names to `test_force_retag_rewinds_and_clears` assertions.

The three ROADMAP success criteria are all fully met. The gap is a correctness defect in crash-recovery behavior, not a missing feature.

---

_Verified: 2026-04-11_
_Verifier: Claude (gsd-verifier)_
