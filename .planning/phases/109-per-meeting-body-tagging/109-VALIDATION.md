---
phase: 109
slug: per-meeting-body-tagging
status: locked
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-11
updated: 2026-04-11
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 7.x |
| **Config file** | `CouncilScribe/pytest.ini` (or `pyproject.toml` — confirmed via Phase 108 conventions) |
| **Quick run command** | `cd CouncilScribe && pytest tests/test_body_tagging.py -x -q` |
| **Full suite command** | `cd CouncilScribe && pytest -x -q` |
| **Estimated runtime** | ~10 seconds (body_tagging module) / ~30 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run quick run command (targeted `test_body_tagging.py`)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

Task IDs use the format `{phase}-{plan}-{task}`. Waves: 1 = Plan 01 (metadata + CLI), 2 = Plan 02 (guard), 3 = Plan 03 (Stage 4 wire).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 109-01-01 | 01 | 1 (W0) | CSMEETING-01/02/03 | T-109-01 | Wave 0 stub creation: 11 failing test stubs covering every D-XX | unit (stub) | `pytest tests/test_body_tagging.py --collect-only -q` (collection succeeds) | ⬜ pending |
| 109-01-02 | 01 | 1 | CSMEETING-01 | T-109-01 | PipelineState round-trips body_slug via atomic write; rewind_for_retag resets stage + removes pre_identifications.json | unit | `python -c "from src.checkpoint import PipelineState, PipelineStage; ..." roundtrip script (in plan verify block)` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | T-109-01 | `--body` flag persists body_slug; re-invocation reads silently; prints `Body: <slug>` | unit | `pytest tests/test_body_tagging.py::test_first_run_persists_body_slug -x -q` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | T-109-01 | Omitting `--body` on re-invocation reads persisted slug (D-06) | unit | `pytest tests/test_body_tagging.py::test_reinvocation_reads_persisted_slug -x -q` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | T-109-01 | Mismatched `--body Y` against persisted `X` → D-02 hard error | unit | `pytest tests/test_body_tagging.py::test_mismatched_body_hard_error -x -q` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | T-109-02 | `--force-retag` rewrites slug, rewinds to TRANSCRIBED, deletes pre_identifications.json (D-03, D-04, D-11) | unit | `pytest tests/test_body_tagging.py::test_force_retag_rewinds_and_clears -x -q` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | — | `--force-retag` without `--body` → argparse error exit 2 (D-12) | unit | `pytest tests/test_body_tagging.py::test_force_retag_requires_body -x -q` | ⬜ pending |
| 109-01-03 | 01 | 1 | CSMEETING-01 | — | `_run_batch` propagates `body=` and `force_retag=` into batch_args Namespace | unit | `pytest tests/test_body_tagging.py::test_batch_propagates_body -x -q` | ⬜ pending |
| 109-02-01 | 02 | 2 | CSMEETING-02 | T-109-03 | `ensure_body_roster_cached` validates slug regex + raises exit 2 on missing cache (D-07, D-08, D-13) | unit | in-plan verify script exercising helper directly | ⬜ pending |
| 109-02-02 | 02 | 2 | CSMEETING-02 | T-109-01 | Missing cached roster prints 2-line stderr error + exits 2 BEFORE Stage 1 ingestion | unit | `pytest tests/test_body_tagging.py::test_missing_roster_fails_fast -x -q` | ⬜ pending |
| 109-02-02 | 02 | 2 | CSMEETING-02 | T-109-01 | Resume after cached roster deleted fails fast identically (D-10) | unit | `pytest tests/test_body_tagging.py::test_resume_after_cache_delete_fails_fast -x -q` | ⬜ pending |
| 109-02-02 | 02 | 2 | CSMEETING-02 | — | Stale cache (>30 days old) does NOT fail fast — Phase 108 warning fires (D-09) | unit | `pytest tests/test_body_tagging.py::test_stale_cache_is_non_blocking -x -q` | ⬜ pending |
| 109-03-01 | 03 | 3 | CSMEETING-03 | T-109-01 | Stage 4 `load_roster(body_slug=effective_body_slug)` when tagged; identify_speakers + roster_names_for_prompt + LLM prompt receive body-specific Roster | unit | `pytest tests/test_body_tagging.py::test_stage4_uses_body_roster -x -q` | ⬜ pending |
| 109-03-01 | 03 | 3 | CSMEETING-03 | T-109-02 | No-body + no-persisted-slug path still calls bare `load_roster()` (D-05 legacy fallback intact) | unit | `pytest tests/test_body_tagging.py::test_legacy_fallback_intact -x -q` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Acknowledged non-coverage (deliberate scope narrowing per 109-RESEARCH.md §1)

The 3 offline `load_roster()` sites in `run_local.py` (lines ~1021, ~1719, ~1749) are intentionally left on the bare legacy path in Phase 109. They have no meeting context (no `meeting_dir`, no `PipelineState`) and CSMEETING-03 wording scopes to Stage 4 pipeline execution. Phase 110/111 will revisit them. Plan 03 Task 1 documents this in a code comment.

---

## Wave 0 Requirements

- [ ] `CouncilScribe/tests/test_body_tagging.py` — module with 11 test stubs (Plan 01 Task 1). Mirror Phase 108's `test_roster_load.py` conventions.
- [ ] `CouncilScribe/tests/conftest.py` — ensure `fake_roster_cache` factory + `tmp_config_dir` + `tmp_meetings_dir` + `tagged_meeting_dir` fixtures exist. Plan 01 Task 1 adds any that are missing.
- [ ] `pytest` framework already installed per Phase 108 — no new deps.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First real tagged Bloomington meeting end-to-end (`--body bloomington-common-council`) produces identification against the body roster and prints `Body: bloomington-common-council` | CSMEETING-01/02/03 | Requires real audio + GPU + refreshed cached roster. Full end-to-end identification fidelity is Phase 111's job. | Phase 109 manual smoke: run `python run_local.py --body bloomington-common-council <existing-meeting-dir>` and confirm `Body:` banner, no crash, and `transcript_named.json` regenerates. Defer phantom-name elimination assertion to Phase 111. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (Plan 01 Task 1 creates test_body_tagging.py)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** locked — ready for execute-phase
