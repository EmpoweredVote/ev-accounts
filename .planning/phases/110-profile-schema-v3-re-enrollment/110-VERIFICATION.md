---
phase: 110-profile-schema-v3-re-enrollment
verified: 2026-04-11T23:50:00Z
status: gaps_found
score: 4/5
overrides_applied: 0
gaps:
  - truth: "run_local.py pipeline passes roster to enroll_speakers and enroll_confirmed"
    status: failed
    reason: "enroll_speakers (line 849) and enroll_confirmed (line 908) in run_local.py are called without roster= parameter, so roster-aware essentials keying only works in reenroll_profiles.py, not the live pipeline"
    artifacts:
      - path: "run_local.py"
        issue: "Lines 849-852 and 908-911 call enroll_speakers/enroll_confirmed without roster= kwarg despite roster variable being in scope (loaded at line 669)"
    missing:
      - "Pass roster=roster to enroll_speakers() at line 849 and enroll_confirmed() at line 908 in run_local.py"
---

# Phase 110: Profile Schema v3 + Re-Enrollment Verification Report

**Phase Goal:** Bump CouncilScribe voice profile schema to v3 with essentials identity fields and roster-aware enrollment keys, plus body-slug-aware batch re-enrollment.
**Verified:** 2026-04-11T23:50:00Z
**Status:** gaps_found
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Profile schema bumped to v3 with identity fields | VERIFIED | `config.py:77` sets `PROFILE_SCHEMA_VERSION = 3`; `StoredProfile` has `politician_slug` and `politician_id` fields (enroll.py:27-28); v2 DBs auto-discarded with backup on load (enroll.py:54-66) |
| 2 | RosterMember carries identity fields from essentials API | VERIFIED | `roster.py:25-26` adds `politician_slug` and `politician_id` to RosterMember; `load_roster(body_slug=...)` populates them from cache JSON (roster.py:122-123) |
| 3 | resolve_enrollment_key produces essentials-prefixed keys for roster members | VERIFIED | `enroll.py:107-131` implements resolve_enrollment_key; roster-matched members keyed as `essentials:<politician_slug>` with identity fields; non-roster speakers fall back to local slug |
| 4 | enroll_speakers and enroll_confirmed use roster-aware keys when roster provided | VERIFIED | Both functions accept `roster` parameter and call `resolve_enrollment_key` (enroll.py:190, 353); identity fields flow through `_enroll_one` (enroll.py:140-165) |
| 5 | run_local.py live pipeline passes roster to enrollment functions | FAILED | `enroll_speakers` at line 849 and `enroll_confirmed` at line 908 in run_local.py are called WITHOUT `roster=roster`, despite the `roster` variable being loaded at line 669 and in scope. Roster-aware keying only works in `reenroll_profiles.py`, not the live pipeline. |

**Score:** 4/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `src/config.py` | Schema version bump to 3 | VERIFIED | Line 77: `PROFILE_SCHEMA_VERSION = 3` with migration comment |
| `src/enroll.py` | StoredProfile v3 + resolve_enrollment_key + roster-aware enrollment | VERIFIED | 362 lines; identity fields on StoredProfile, resolve_enrollment_key, both enroll functions accept roster param |
| `src/roster.py` | RosterMember identity fields + load_roster populates them | VERIFIED | politician_slug/politician_id on RosterMember dataclass; load_roster slug path populates from cache |
| `reenroll_profiles.py` | Body-slug-aware batch re-enrollment | VERIFIED | Reads body_slug from PipelineState, loads roster via load_roster(body_slug=...), passes to enroll_speakers |
| `tests/test_profile_v3.py` | Test coverage for all v3 features | VERIFIED | 14 tests covering schema version, identity fields, enrollment keying, essentials keys, re-enrollment; all 14 pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| enroll_speakers | resolve_enrollment_key | direct call at line 190 | WIRED | Returns (slug, pol_slug, pol_id) tuple, passed to _enroll_one |
| enroll_confirmed | resolve_enrollment_key | direct call at line 353 | WIRED | Same pattern as enroll_speakers |
| resolve_enrollment_key | correct_speaker_name | import + call at line 120 | WIRED | Matches display_name against roster members |
| resolve_enrollment_key | RosterMember.politician_slug | attribute access at line 123-127 | WIRED | Returns member identity fields when matched |
| reenroll_profiles.py | PipelineState.body_slug | attribute access at line 122 | WIRED | Reads body_slug from pipeline state JSON |
| reenroll_profiles.py | load_roster(body_slug=...) | function call at line 128 | WIRED | Loads body-specific roster cache |
| reenroll_profiles.py | enroll_speakers(roster=) | kwarg at line 177 | WIRED | Passes loaded roster to enrollment |
| run_local.py | enroll_speakers(roster=) | missing kwarg at line 849 | NOT_WIRED | roster variable exists in scope but not passed |
| run_local.py | enroll_confirmed(roster=) | missing kwarg at line 908 | NOT_WIRED | roster variable exists in scope but not passed |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 14 profile v3 tests pass | `pytest tests/test_profile_v3.py -v` | 14 passed in 0.66s | PASS |
| Schema version is 3 | `grep PROFILE_SCHEMA_VERSION src/config.py` | `PROFILE_SCHEMA_VERSION = 3` | PASS |
| resolve_enrollment_key exists and is called | `grep resolve_enrollment_key src/enroll.py` | defined + 2 call sites | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CSPROFILE-01 | N/A | (No REQUIREMENTS.md found) | CANNOT VERIFY | No REQUIREMENTS.md exists in .planning/ |
| CSPROFILE-02 | N/A | (No REQUIREMENTS.md found) | CANNOT VERIFY | No REQUIREMENTS.md exists in .planning/ |
| CSPROFILE-03 | N/A | (No REQUIREMENTS.md found) | CANNOT VERIFY | No REQUIREMENTS.md exists in .planning/ |
| CSPROFILE-04 | N/A | (No REQUIREMENTS.md found) | CANNOT VERIFY | No REQUIREMENTS.md exists in .planning/ |
| CSPROFILE-05 | N/A | (No REQUIREMENTS.md found) | CANNOT VERIFY | No REQUIREMENTS.md exists in .planning/ |

**Note:** No REQUIREMENTS.md or ROADMAP.md exists in `.planning/`. No PLAN.md or SUMMARY.md files exist for this phase. The requirement IDs CSPROFILE-01 through CSPROFILE-05 cannot be cross-referenced. Verification was performed against the phase goal and commit history.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| src/enroll.py | 313-333 | fix_profiles_with_roster does not use resolve_enrollment_key | Warning | Profiles corrected via --fix-profiles will not get essentials: keys (noted in code review WR-01) |
| src/enroll.py | 250-280 | rename_profile does not preserve identity fields during merge | Warning | Source profile's politician_slug/politician_id silently dropped on merge (noted in code review WR-02) |
| run_local.py | 849, 908 | enroll_speakers/enroll_confirmed called without roster= | Blocker | Live pipeline enrollment does not use roster-aware keying |

### Human Verification Required

None -- all verifiable items checked programmatically.

### Gaps Summary

One gap blocks full goal achievement: the live pipeline in `run_local.py` does not pass the `roster` variable to `enroll_speakers()` (line 849) or `enroll_confirmed()` (line 908), even though the roster is loaded and in scope at line 669. This means roster-aware `essentials:` keying works correctly in `reenroll_profiles.py` (batch re-enrollment) but NOT during normal pipeline execution. The fix is a two-line change adding `roster=roster` to both call sites.

The code review (110-REVIEW.md) also identified two additional warnings (WR-01: `fix_profiles_with_roster` and WR-02: `rename_profile` not using resolve_enrollment_key / preserving identity fields) that are lower priority but represent inconsistencies in the enrollment key strategy.

---

_Verified: 2026-04-11T23:50:00Z_
_Verifier: Claude (gsd-verifier)_
