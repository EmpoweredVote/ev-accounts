---
phase: 109
slug: per-meeting-body-tagging
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 7.x |
| **Config file** | `CouncilScribe/pytest.ini` (or `pyproject.toml` — planner to confirm) |
| **Quick run command** | `cd CouncilScribe && pytest tests/test_body_tagging.py -x -q` |
| **Full suite command** | `cd CouncilScribe && pytest -x -q` |
| **Estimated runtime** | ~10 seconds (body_tagging module) / ~30 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick run command (targeted test_body_tagging.py)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-01-01 | 01 | 0 | CSMEETING-01 | — | N/A | unit (stub) | `pytest tests/test_body_tagging.py -x -q` | ❌ W0 | ⬜ pending |
| 109-01-02 | 01 | 1 | CSMEETING-01 | — | `--body` flag persists `body_slug` into `PipelineState`; subsequent invocations read it silently | unit | `pytest tests/test_body_tagging.py::test_first_run_persists_body_slug -x -q` | ❌ W0 | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | — | Omitting `--body` on re-invocation of a tagged meeting reads persisted slug and prints `Body: <slug>` info line | unit | `pytest tests/test_body_tagging.py::test_reinvocation_reads_persisted_slug -x -q` | ❌ W0 | ⬜ pending |
| 109-01-04 | 01 | 1 | CSMEETING-01 | — | Mismatched `--body Y` against persisted `body_slug=X` exits non-zero with D-02 error | unit | `pytest tests/test_body_tagging.py::test_mismatched_body_hard_error -x -q` | ❌ W0 | ⬜ pending |
| 109-01-05 | 01 | 1 | CSMEETING-01 | — | `--force-retag` rewrites `body_slug` and rewinds `completed_stage` to TRANSCRIBED; deletes `pre_identifications.json` | unit | `pytest tests/test_body_tagging.py::test_force_retag_rewinds_and_clears -x -q` | ❌ W0 | ⬜ pending |
| 109-01-06 | 01 | 1 | CSMEETING-01 | — | `--force-retag` without `--body` is a hard error (argparse-level) | unit | `pytest tests/test_body_tagging.py::test_force_retag_requires_body -x -q` | ❌ W0 | ⬜ pending |
| 109-02-01 | 02 | 1 | CSMEETING-02 | — | Missing cached roster prints 2-line stderr error (literal `~/CouncilScribe/...` path) + exits 2 BEFORE Stage 1 ingestion | unit | `pytest tests/test_body_tagging.py::test_missing_roster_fails_fast -x -q` | ❌ W0 | ⬜ pending |
| 109-02-02 | 02 | 1 | CSMEETING-02 | — | Resume after cached roster deleted fails fast identically (D-10) | unit | `pytest tests/test_body_tagging.py::test_resume_after_cache_delete_fails_fast -x -q` | ❌ W0 | ⬜ pending |
| 109-02-03 | 02 | 1 | CSMEETING-02 | — | Stale cache (file exists, >30 days old) does NOT fail fast — Phase 108 warning fires (D-09) | unit | `pytest tests/test_body_tagging.py::test_stale_cache_is_non_blocking -x -q` | ❌ W0 | ⬜ pending |
| 109-03-01 | 03 | 1 | CSMEETING-03 | — | Stage 4 `load_roster()` at `run_local.py:568` uses `body_slug=` when set; consumers (`correct_speaker_name`, `roster_names_for_prompt`, LLM prompt) receive body-specific `Roster` | unit | `pytest tests/test_body_tagging.py::test_stage4_uses_body_roster -x -q` | ❌ W0 | ⬜ pending |
| 109-03-02 | 03 | 1 | CSMEETING-03 | — | No-body-flag + no-persisted-slug path still calls bare `load_roster()` (D-05 legacy fallback intact) | unit | `pytest tests/test_body_tagging.py::test_legacy_fallback_intact -x -q` | ❌ W0 | ⬜ pending |
| 109-03-03 | 03 | 1 | CSMEETING-01, 03 | — | `run_batch` propagates `--body` / `--force-retag` into per-entry `batch_args` Namespace | unit | `pytest tests/test_body_tagging.py::test_batch_propagates_body -x -q` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `CouncilScribe/tests/test_body_tagging.py` — create module with test stubs covering CSMEETING-01/02/03 per the map above. Mirror Phase 108's `test_roster.py` conventions (same fixtures from `conftest.py`, same subprocess-invocation pattern for CLI-level tests, same `capsys` usage for stderr assertions).
- [ ] `CouncilScribe/tests/conftest.py` — confirm existing fixtures cover: temp `CONFIG_DIR`, temp `MEETINGS_DIR`, factory for fake cached roster JSON. If gaps exist, planner adds them in Wave 0.
- [ ] `pytest` framework already installed per Phase 108 — no new deps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First real tagged Bloomington meeting end-to-end (`--body bloomington-common-council`) produces identification against the body roster and prints `Body: bloomington-common-council` | CSMEETING-01/02/03 | Requires real audio input + GPU + cached roster refreshed from Phase 107 endpoint. Belongs to Phase 111, not 109. | Deferred to Phase 111. Phase 109 manual smoke: run `python run_local.py --body bloomington-common-council <existing-meeting-dir>` and confirm `Body:` banner + no crash. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter (planner/checker flips this after PLAN.md task IDs are locked)

**Approval:** pending
