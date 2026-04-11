---
phase: 108
slug: councilscribe-roster-client-cli
status: draft
nyquist_compliant: true
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
| **Config file** | `CouncilScribe/pytest.ini` (Wave 0 creates) |
| **Quick run command** | `cd CouncilScribe && python -m pytest tests/ -x -q` |
| **Full suite command** | `cd CouncilScribe && python -m pytest tests/ -v` |
| **Estimated runtime** | ~5 seconds (all unit tests, HTTP stubbed via `unittest.mock.patch`) |

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
| 108-01-T1 | 01 | 0 | infra (CSROSTER-01..05) | — | test harness collects without errors | collection | `cd CouncilScribe && python -m pytest tests/ --collect-only -q` | `CouncilScribe/pytest.ini`, `CouncilScribe/tests/conftest.py`, `CouncilScribe/tests/fixtures/bloomington_roster_response.json` | pending |
| 108-01-T2 | 01 | 1 | CSROSTER-03 | — | RED: D-01..D-07 tests written and failing at import | unit (RED) | `cd CouncilScribe && python -m pytest tests/test_alias_gen.py --collect-only -q` | `CouncilScribe/tests/test_alias_gen.py` | pending |
| 108-01-T3 | 01 | 1 | CSROSTER-03 | — | GREEN: alias generator implements D-01..D-08; zero `party` refs | unit (GREEN) | `cd CouncilScribe && python -m pytest tests/test_alias_gen.py -x -q && ! grep -n party src/alias_gen.py` | `CouncilScribe/src/alias_gen.py` | pending |
| 108-01-T4 | 01 | 2 | CSROSTER-01 | T-108-01, T-108-02, T-108-04 | HTTP client with size cap, slug validation, env/arg base URL, error envelope; zero `party` refs | unit | `cd CouncilScribe && python -m pytest tests/test_essentials_client.py -x -q && ! grep -n party src/essentials_client.py` | `CouncilScribe/src/essentials_client.py`, `CouncilScribe/tests/test_essentials_client.py` | pending |
| 108-01-T5 | 01 | 3 | CSROSTER-02, CSROSTER-01 | T-108-03 | Atomic write + cache preservation on network/disk failure; payload shape; zero `party` keys in output | unit | `cd CouncilScribe && python -m pytest tests/test_refresh_roster.py -x -q && ! grep -n party refresh_roster.py` | `CouncilScribe/refresh_roster.py`, `CouncilScribe/tests/test_refresh_roster.py` | pending |
| 108-01-T6 | 01 | 4 | CSROSTER-04, CSROSTER-05 | — | load_roster slug path + legacy fallback + 30-day staleness warning + Z-suffix ISO parsing; run_local.py signature compat | unit | `cd CouncilScribe && python -m pytest tests/test_roster_load.py -x -q && python -m pytest tests/ -q` | `CouncilScribe/src/roster.py` (modified), `CouncilScribe/tests/test_roster_load.py` | pending |
| 108-01-T7 | 01 | 5 | CSROSTER-01..05 (regression) | all | Antipartisan grep encoded as test; full suite regression; run_local.py AST backward-compat check | unit + static | `cd CouncilScribe && python -m pytest tests/ -v && ! grep -n party src/essentials_client.py src/alias_gen.py refresh_roster.py src/roster.py` | `CouncilScribe/tests/test_antipartisan.py` | pending |

---

## Wave 0 Requirements

- [x] `CouncilScribe/requirements.txt` — append `pytest>=8` (Task 1)
- [x] `CouncilScribe/pytest.ini` — `testpaths = tests` config (Task 1)
- [x] `CouncilScribe/tests/__init__.py` — empty marker (Task 1)
- [x] `CouncilScribe/tests/conftest.py` — `tmp_config_dir`, `sample_politician_*`, `sample_roster_response` fixtures (Task 1)
- [x] `CouncilScribe/tests/fixtures/bloomington_roster_response.json` — mirrors Phase 107 `RosterResponse` shape, zero `party` keys (Task 1)
- [x] `CouncilScribe/tests/test_alias_gen.py` — D-01..D-07 test stubs (Task 2, RED)
- [x] `CouncilScribe/tests/test_essentials_client.py` — HTTP + error envelope + size cap + slug validation stubs (Task 4)
- [x] `CouncilScribe/tests/test_refresh_roster.py` — atomic write + cache preservation stubs (Task 5)
- [x] `CouncilScribe/tests/test_roster_load.py` — slug path + legacy fallback + staleness stubs (Task 6)
- [x] `CouncilScribe/tests/test_antipartisan.py` — grep assertion (Task 7)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real end-to-end refresh against live `accounts.empowered.vote` | CSROSTER-01, CSROSTER-02 | Live endpoint smoke test, not a unit test | Run `python refresh_roster.py --body bloomington-common-council`; confirm `~/CouncilScribe/config/rosters/bloomington-common-council.json` exists and contains expected aliases for `Piedmont-Smith` and `Asare` |
| Offline behavior preserves existing cache | CSROSTER-03 | Requires manually disabling network | With an existing cache present, disable network (airplane mode / block in firewall), run `refresh_roster.py --body bloomington-common-council`, confirm CLI exits non-zero with clear error AND cache file bytes unchanged (compare sha256 before/after) |
| Staleness warning visible in real run | CSROSTER-05 | Relies on filesystem mtime / cached `fetched_at` > 30 days | Backdate the `fetched_at` field in the cache JSON, call `load_roster(body_slug=...)`, confirm warning appears on stderr/log without blocking |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (planner-signed; awaiting execution)
