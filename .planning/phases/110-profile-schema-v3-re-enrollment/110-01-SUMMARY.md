---
phase: 110-profile-schema-v3-re-enrollment
plan: 01
subsystem: CouncilScribe voice profiles
tags: [schema-migration, enrollment, identity-linking]
dependency_graph:
  requires: [109-per-meeting-body-tagging]
  provides: [profile-schema-v3, essentials-keyed-enrollment, resolve-enrollment-key]
  affects: [reenroll_profiles.py, run_local.py-stage-6]
tech_stack:
  added: []
  patterns: [essentials-prefixed-profile-keys, roster-aware-enrollment]
key_files:
  created:
    - CouncilScribe/tests/test_profile_v3.py
  modified:
    - CouncilScribe/src/config.py
    - CouncilScribe/src/enroll.py
    - CouncilScribe/src/roster.py
decisions:
  - Extend RosterMember with politician_slug/politician_id rather than raw JSON lookup
  - Use essentials: prefix for roster-matched profile keys (colon namespace separator)
  - Identity fields backfill on existing profiles during merge (if previously None)
metrics:
  duration_seconds: 192
  completed: "2026-04-12T03:25:00Z"
  tasks_completed: 2
  tasks_total: 2
  test_count: 11
  test_pass: 11
---

# Phase 110 Plan 01: Profile Schema v3 + Essentials Identity Fields Summary

Voice profile schema bumped v2 to v3 with politician_slug and politician_id on StoredProfile and RosterMember; resolve_enrollment_key routes roster-matched speakers to essentials-prefixed keys while non-roster speakers keep local slugs.

## What Was Done

### Task 1: Schema bump + RosterMember enrichment (be5d995)
- Bumped `PROFILE_SCHEMA_VERSION` from 2 to 3 in `config.py`
- Added `politician_slug: Optional[str] = None` and `politician_id: Optional[str] = None` to `StoredProfile` dataclass
- Added same two fields to `RosterMember` dataclass
- Updated `load_roster()` slug path to populate identity fields from per-body cache JSON
- 5 tests: schema version, v3 fields, v2 auto-discard with backup, roster member identity, load_roster population

### Task 2: resolve_enrollment_key + enrollment wiring (41370ea)
- Added `resolve_enrollment_key()` helper that checks display name against roster via `correct_speaker_name()`, returns `(essentials:<slug>, slug, id)` for matches or `(local_slug, None, None)` for non-roster speakers
- Updated `_enroll_one()` to accept and set `politician_slug`/`politician_id` on profile creation and backfill on merge
- Updated `enroll_speakers()` signature with `roster: Optional[Roster] = None` parameter
- Updated `enroll_confirmed()` signature with same optional roster parameter
- Added `TYPE_CHECKING` import guard for `Roster` to avoid circular imports
- 6 tests: essentials key usage, identity field population, local slug fallback, mixed profile coexistence, cross-meeting accumulation, confirmed enrollment path

## Deviations from Plan

None -- plan executed exactly as written.

## Verification Results

- `PROFILE_SCHEMA_VERSION = 3` confirmed in config.py line 77
- `politician_slug` present in both enroll.py (StoredProfile) and roster.py (RosterMember)
- `essentials:` prefix confirmed in resolve_enrollment_key
- 11/11 new tests pass
- 71/71 full suite tests pass (60 existing + 11 new)

## Self-Check: PASSED
