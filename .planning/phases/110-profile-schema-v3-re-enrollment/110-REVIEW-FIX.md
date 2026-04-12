---
phase: 110-profile-schema-v3-re-enrollment
fixed_at: 2026-04-11T23:45:00Z
review_path: .planning/phases/110-profile-schema-v3-re-enrollment/110-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 110: Code Review Fix Report

**Fixed at:** 2026-04-11T23:45:00Z
**Source review:** .planning/phases/110-profile-schema-v3-re-enrollment/110-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: Arbitrary code execution via pickle.load on profile database

**Files modified:** `CouncilScribe/src/enroll.py`
**Commit:** 2f09bdd
**Applied fix:** Added `RestrictedUnpickler` class that restricts pickle deserialization to known safe module roots (`numpy`, `builtins`) and the `src.enroll` module. Replaced `pickle.load(f)` with `RestrictedUnpickler(f).load()` in `load_profiles()`. Any attempt to unpickle objects from untrusted modules now raises `pickle.UnpicklingError`.

### WR-01: fix_profiles_with_roster does not produce essentials-keyed profiles

**Files modified:** `CouncilScribe/src/enroll.py`
**Commit:** 2f09bdd
**Applied fix:** Replaced the `_name_to_slug` + `rename_profile` delegation with inline logic that calls `resolve_enrollment_key(new_name, roster)` to compute the new key. Roster-matched profiles are now re-keyed under `essentials:<politician_slug>` with identity fields (`politician_slug`, `politician_id`) populated, consistent with `enroll_speakers` and `enroll_confirmed`.

### WR-02: rename_profile does not preserve identity fields during merge

**Files modified:** `CouncilScribe/src/enroll.py`
**Commit:** 2f09bdd
**Applied fix:** Added identity field preservation in the merge branch of `rename_profile`: when the source profile has `politician_slug` set and the target lacks it, the source's `politician_slug` and `politician_id` are copied to the target before recomputing the centroid.

## Verification

All 74 tests passed after applying fixes (`pytest tests/ -q` -- 74 passed in 0.98s). No regressions introduced.

---

_Fixed: 2026-04-11T23:45:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
