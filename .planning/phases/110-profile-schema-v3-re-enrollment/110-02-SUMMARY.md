---
phase: 110-profile-schema-v3-re-enrollment
plan: 02
subsystem: CouncilScribe voice profiles
tags: [re-enrollment, roster-passthrough, body-slug]
dependency_graph:
  requires: [110-01]
  provides: [body-slug-aware-reenrollment]
  affects: [reenroll_profiles.py]
tech_stack:
  added: []
  patterns: [pipeline-state-body-slug-read, roster-passthrough-to-enroll]
key_files:
  created: []
  modified:
    - CouncilScribe/reenroll_profiles.py
    - CouncilScribe/tests/test_profile_v3.py
decisions:
  - Monkeypatch reenroll_profiles module-level names (not src.enroll) since from-imports bind at import time
  - Wrap PipelineState loading in try/except for robustness with legacy meetings
metrics:
  duration_seconds: 165
  completed: "2026-04-12T03:30:27Z"
  tasks_completed: 1
  tasks_total: 1
  test_count: 14
  test_pass: 14
---

# Phase 110 Plan 02: Reenroll Body-Slug-Aware Re-enrollment Summary

Updated reenroll_profiles.py to read body_slug from each meeting's pipeline_state.json via PipelineState, load the per-body roster, and pass it to enroll_speakers so roster-matched speakers promote to essentials-keyed profile keys during batch re-enrollment.

## What Was Done

### Task 1: reenroll_profiles.py body-slug-aware re-enrollment with roster passthrough

**TDD RED** (9636ce6):
- Added 3 failing tests to test_profile_v3.py:
  - `test_reenroll_reads_body_slug`: verifies PipelineState body_slug is read and roster loaded, producing essentials-keyed profile
  - `test_reenroll_promotes_to_essentials_key`: verifies identity fields (politician_slug, politician_id, display_name) on promoted profile
  - `test_reenroll_untagged_meeting_local_slug`: verifies untagged legacy meetings fall back to local slug keys without essentials prefix

**TDD GREEN** (1f3acea):
- Added `from src.checkpoint import PipelineState` and `from src.roster import load_roster` imports
- In the meeting loop, added PipelineState loading with try/except fallback to None for robustness
- Added roster loading via `load_roster(body_slug=body_slug)` when body_slug is present
- Updated `enroll_speakers()` call to pass `roster=roster`
- Fixed test monkeypatching to target `reenroll_profiles.*` module-level names instead of `src.enroll.*` (since `from` imports bind at import time)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed monkeypatch targets for reenroll tests**
- **Found during:** Task 1 GREEN phase
- **Issue:** Tests monkeypatched `src.enroll.save_profiles` and `src.enroll.load_profiles`, but reenroll_profiles.py uses `from src.enroll import save_profiles` which binds at import time, so monkeypatching the source module doesn't affect the already-imported reference.
- **Fix:** Changed monkeypatch targets to `reenroll_profiles.save_profiles`, `reenroll_profiles.load_profiles`, and `reenroll_profiles.extract_speaker_embeddings`
- **Files modified:** CouncilScribe/tests/test_profile_v3.py
- **Commit:** 1f3acea

## Verification Results

- `PipelineState` import confirmed at reenroll_profiles.py line 37
- `state = PipelineState(meeting_dir)` confirmed at line 121
- `load_roster(body_slug=body_slug)` confirmed at line 128
- `roster=roster` in enroll_speakers call confirmed at line 177
- 14/14 profile v3 tests pass
- 74/74 full suite tests pass

## Self-Check: PASSED
