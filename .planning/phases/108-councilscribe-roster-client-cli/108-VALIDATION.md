---
phase: 108
slug: councilscribe-roster-client-cli
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-11
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x (new — no existing test suite) |
| **Config file** | `CouncilScribe/pytest.ini` or `pyproject.toml` (Wave 0 installs) |
| **Quick run command** | `cd CouncilScribe && pytest tests/ -x -q` |
| **Full suite command** | `cd CouncilScribe && pytest tests/ -v` |
| **Estimated runtime** | ~5 seconds (all unit tests, HTTP stubbed via `unittest.mock`) |

---

## Sampling Rate

- **After every task commit:** Run `pytest tests/ -x -q`
- **After every plan wave:** Run `pytest tests/ -v`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _(to be populated by planner — one row per task with acceptance_criteria)_ | | | | | | | | | |

---

## Wave 0 Requirements

- [ ] `CouncilScribe/requirements.txt` — add `pytest>=8` dev dependency
- [ ] `CouncilScribe/tests/__init__.py` — empty marker
- [ ] `CouncilScribe/tests/conftest.py` — shared fixtures (tmp_path wrapper for CONFIG_DIR, sample politician dict fixtures)
- [ ] `CouncilScribe/tests/test_alias_gen.py` — stubs for CSROSTER-02 (D-01 through D-07)
- [ ] `CouncilScribe/tests/test_essentials_client.py` — stubs for CSROSTER-01, CSROSTER-03 (HTTP stub via `unittest.mock.patch`)
- [ ] `CouncilScribe/tests/test_refresh_roster.py` — stubs for CSROSTER-02 (atomic write, cache preservation)
- [ ] `CouncilScribe/tests/test_roster_load.py` — stubs for CSROSTER-04, CSROSTER-05 (slug path, legacy fallback, staleness warning)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real end-to-end refresh against live `accounts.empowered.vote` | CSROSTER-01, CSROSTER-02 | Hitting the live Phase 107 endpoint is a smoke test, not a unit test | Run `python refresh_roster.py --body bloomington-common-council`; confirm `~/CouncilScribe/config/rosters/bloomington-common-council.json` exists and contains expected aliases for `Piedmont-Smith` and `Asare` |
| Offline behavior preserves existing cache | CSROSTER-03 | Requires manually disabling network | With an existing cache present, disable network (airplane mode / block in firewall), run `refresh_roster.py --body bloomington-common-council`, confirm CLI exits non-zero with clear error AND cache file bytes unchanged (compare sha256 before/after) |
| Staleness warning visible in real run | CSROSTER-05 | Relies on filesystem mtime / cached `fetched_at` > 30 days | Backdate the `fetched_at` field in the cache JSON, call `load_roster(body_slug=...)`, confirm warning appears on stderr/log without blocking |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
