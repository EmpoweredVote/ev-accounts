---
phase: 110
slug: profile-schema-v3-re-enrollment
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 110 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest (installed in `.venv`) |
| **Config file** | `CouncilScribe/pytest.ini` |
| **Quick run command** | `.venv/bin/pytest tests/test_profile_v3.py -x -q` |
| **Full suite command** | `.venv/bin/pytest tests/ -q` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `.venv/bin/pytest tests/test_profile_v3.py -x -q`
- **After every plan wave:** Run `.venv/bin/pytest tests/ -q`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-01 | 01 | 1 | CSPROFILE-01 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_profile_db_schema_version -x -q` | ❌ W0 | ⬜ pending |
| 110-01-02 | 01 | 1 | CSPROFILE-01 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_stored_profile_v3_fields -x -q` | ❌ W0 | ⬜ pending |
| 110-01-03 | 01 | 1 | CSPROFILE-01 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_v2_auto_discard -x -q` | ❌ W0 | ⬜ pending |
| 110-01-04 | 01 | 1 | CSPROFILE-02 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_enroll_roster_member_uses_essentials_key -x -q` | ❌ W0 | ⬜ pending |
| 110-01-05 | 01 | 1 | CSPROFILE-02 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_essentials_profile_identity_fields -x -q` | ❌ W0 | ⬜ pending |
| 110-01-06 | 01 | 1 | CSPROFILE-03 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_non_roster_speaker_local_slug -x -q` | ❌ W0 | ⬜ pending |
| 110-01-07 | 01 | 1 | CSPROFILE-03 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_mixed_profiles_coexist -x -q` | ❌ W0 | ⬜ pending |
| 110-01-08 | 01 | 1 | CSPROFILE-04 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_reads_body_slug -x -q` | ❌ W0 | ⬜ pending |
| 110-01-09 | 01 | 1 | CSPROFILE-04 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_promotes_to_essentials_key -x -q` | ❌ W0 | ⬜ pending |
| 110-01-10 | 01 | 1 | CSPROFILE-04 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_untagged_meeting_local_slug -x -q` | ❌ W0 | ⬜ pending |
| 110-01-11 | 01 | 1 | CSPROFILE-05 | — | N/A | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_essentials_profile_accumulates_across_meetings -x -q` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/test_profile_v3.py` — stubs for all 11 test functions (CSPROFILE-01 through CSPROFILE-05)
- [ ] `fake_v2_profile_db` fixture — construct a v2 `ProfileDB`, pickle to tempfile for auto-discard test

*Existing infrastructure covers remaining needs: `fake_roster_cache`, `tmp_config_dir`, `tagged_meeting_dir` from `tests/conftest.py`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Re-running `reenroll_profiles.py` against a real Bloomington meeting produces `essentials:` keys | CSPROFILE-02/04 | Requires real audio files and roster cache | 1. Ensure roster cache exists at `~/CouncilScribe/config/rosters/bloomington-common-council.json` 2. Run `python reenroll_profiles.py` 3. Inspect output for `essentials:` prefix keys |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
