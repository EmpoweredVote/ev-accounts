---
phase: 108
plan: 01
subsystem: councilscribe
tags: [councilscribe, roster, http-client, cli, tdd, antipartisan]
dependency_graph:
  requires:
    - 107-essentials-body-roster-endpoint (RosterResponse contract)
  provides:
    - CouncilScribe/src/essentials_client.py::fetch_body_roster
    - CouncilScribe/src/alias_gen.py::generate_aliases
    - CouncilScribe/refresh_roster.py::main (CLI)
    - CouncilScribe/src/roster.py::load_roster(body_slug=...)
  affects:
    - Phase 109 (will thread --body through run_local.py)
    - Phase 110 (politician-slug-keyed voice profiles)
    - Phase 111 (identification pipeline integration)
tech_stack:
  added:
    - pytest>=8 (first test framework in CouncilScribe)
  patterns:
    - pure-function alias generator (D-01..D-08)
    - tempfile + os.replace atomic cache write
    - keyword-only kwarg extension for backward-compat signatures
    - grep assertion as pytest regression for project rules
key_files:
  created:
    - CouncilScribe/pytest.ini
    - CouncilScribe/tests/__init__.py
    - CouncilScribe/tests/conftest.py
    - CouncilScribe/tests/fixtures/bloomington_roster_response.json
    - CouncilScribe/tests/test_alias_gen.py
    - CouncilScribe/tests/test_essentials_client.py
    - CouncilScribe/tests/test_refresh_roster.py
    - CouncilScribe/tests/test_roster_load.py
    - CouncilScribe/tests/test_antipartisan.py
    - CouncilScribe/src/alias_gen.py
    - CouncilScribe/src/essentials_client.py
    - CouncilScribe/refresh_roster.py
  modified:
    - CouncilScribe/requirements.txt (appended pytest>=8)
    - CouncilScribe/src/roster.py (keyword-only body_slug kwarg + staleness)
decisions:
  - "Alias generator lives in dedicated src/alias_gen.py (pure function, no network/fs) for reuse by Phase 109/111"
  - "RosterMember.name for slug-path rosters is constructed as '{title} {last_name}' to match legacy prompt format consumed by correct_speaker_name and roster_names_for_prompt"
  - "Staleness warning uses both logging.warning and stderr print; only fires on slug path, never on legacy path (Pitfall 4)"
  - "Z-suffix ISO timestamps normalized to '+00:00' before datetime.fromisoformat for Python <3.11 compat"
  - "Phase 108 work lives on feat/108-roster-client branch in CouncilScribe repo (separate git repo from ev-accounts workspace)"
metrics:
  duration: ~20min
  completed: 2026-04-11
  tasks_completed: 7
  tests_total: 48
  tests_passing: 48
---

# Phase 108 Plan 01: CouncilScribe roster client + CLI Summary

One-liner: HTTP client + CLI + pure-function alias generator that fetches Phase 107 `/api/essentials/bodies/{slug}/roster`, persists per-body rosters atomically, and extends `load_roster()` with a keyword-only `body_slug=` kwarg — fully TDD, zero party references, 48 tests green.

## What Was Built

- **`src/alias_gen.py`** (124 lines) — Pure function `generate_aliases(politician)` implementing D-01 base variants (full_name, surname, first+last, preferred+last), D-02 hyphen-space expansion, D-03 NFKD ASCII folding, D-04 leadership-only title stripping (`Council|Vice|Deputy` + `President|Chair|Mayor|Speaker|Clerk`), D-05 case-only dedup, D-06 original-case storage, D-07 deterministic order. Zero IO, no network.
- **`src/essentials_client.py`** (115 lines) — `fetch_body_roster(body_slug, base_url=None)` HTTP client with `EssentialsClientError` envelope exception. Honors `EV_ACCOUNTS_URL` env var with `--base-url` arg override, strips trailing slashes, enforces slug regex `^[a-z0-9-]+$` before any HTTP call (T-108-02 path traversal mitigation), enforces 5 MB Content-Length cap before parsing (T-108-01 DoS mitigation), maps 404/422/5xx error envelopes with preserved `code` and `status` attributes, and wraps transport failures in `EssentialsClientError("Network error: ...")`.
- **`refresh_roster.py`** (150 lines, repo root) — argparse CLI `python refresh_roster.py --body {slug} [--base-url ...] [--output ...]`. Transforms `RosterResponse` into cache payload with required keys (`body_key`, `body_slug`, `fetched_at`, `politicians[]`), generates aliases per member via `alias_gen.generate_aliases`, and writes atomically via `tempfile.mkstemp(dir=path.parent)` + `os.fdopen` + `os.replace`. Cache is byte-identical on both network-failure and disk-failure paths (T-108-03).
- **`src/roster.py`** (modified) — Added keyword-only `body_slug` kwarg to `load_roster()`. Legacy path (no args, positional `path`) is byte-unchanged for the four `run_local.py` call sites (verified via pytest AST check). Slug path reads `CONFIG_DIR/rosters/{slug}.json`, emits a non-blocking 30-day staleness warning to both `logging.warning` and `sys.stderr`, and builds a `Roster` where each `RosterMember.name = f"{title} {last_name}"` (matching the legacy prompt format) with aliases populated from the cache.
- **Test infrastructure** — First pytest suite in CouncilScribe: `pytest.ini`, `tests/__init__.py`, `tests/conftest.py` (fixtures `tmp_config_dir`, `sample_politician_*`, `sample_roster_response`), and `tests/fixtures/bloomington_roster_response.json` mirroring Phase 107 `RosterResponse` with four members including Piedmont-Smith, Asare, García (accented), and Bolden (City Clerk).

## Tests

| Suite | Count | Status |
|-------|------:|--------|
| `tests/test_alias_gen.py` | 16 | pass |
| `tests/test_essentials_client.py` | 11 | pass |
| `tests/test_refresh_roster.py` | 9 | pass |
| `tests/test_roster_load.py` | 10 | pass |
| `tests/test_antipartisan.py` | 2 | pass |
| **total** | **48** | **pass** |

Full-suite runtime ~0.09s. All waves executed in strict TDD order (Task 2 RED → Task 3 GREEN verified manually; all other tasks red-then-green within the same commit per plan instructions).

## Acceptance Truths — all met

1. `refresh_roster.py --body bloomington-common-council` writes the cache with `body_key`, `body_slug`, `fetched_at`, `politicians[]` containing the required per-member keys. (verified: `test_cli_success_writes_cache`, `test_cache_payload_shape`)
2. Each politician's aliases cover D-01..D-07 including hyphen-space expansion and ASCII folding in deterministic order. (verified: 16 `test_alias_gen.py` tests)
3. Network failure leaves existing cache byte-identical; CLI exits non-zero with clear stderr message. (verified: `test_network_failure_preserves_existing_cache`, sha256 compared before/after)
4. `load_roster(body_slug=...)` returns a `Roster` whose `members[].name` = `"{title} {last_name}"`. (verified: `test_load_by_slug_success`, `test_slug_roster_drives_correct_speaker_name`)
5. `load_roster()` (no args) preserves legacy behavior; all four `run_local.py` call sites work unchanged. (verified: `test_load_legacy_fallback`, `test_run_local_compat`, AST check in Task 7)
6. Staleness warning fires non-blockingly on 31-day-old cache; does not fire on fresh or legacy paths. (verified: `test_staleness_warning_*` trio)
7. `grep -n 'party' src/essentials_client.py src/alias_gen.py refresh_roster.py src/roster.py` returns zero matches. (verified: `test_antipartisan.py` encodes this as CI)

## Self-Check: PASSED

Verified files exist (all 12 created files present in CouncilScribe repo), all 7 per-task commits present in git log on `feat/108-roster-client` branch:

- `0cf1c96` chore(108-01): add pytest infrastructure and roster fixtures
- `6c432e6` test(108-01): add RED alias generator tests for D-01..D-07
- `49f12e7` feat(108-01): implement pure-function alias generator per D-01..D-08
- `aada454` feat(108-01): add essentials HTTP client with slug validation and size cap
- `5c055b1` feat(108-01): add refresh_roster.py CLI with atomic cache write
- `e2b31ef` feat(108-01): extend load_roster() with body_slug kwarg and staleness warning
- `f849ca9` test(108-01): add antipartisan grep assertion and seal Phase 108

Full-suite `pytest tests/ -q` = 48 passed, 0 failed, 0 errors.
Antipartisan grep across all four modified/created source files returns zero matches.
run_local.py AST scan confirms every `load_roster(` call site uses zero keyword arguments (backward-compatible).

## Deviations from Plan

None that affect behavior. Minor notes:

1. **[Rule 3 - Blocking] pytest not installed.** CouncilScribe ships without any test framework and Python 3.13 system pip is PEP 668-locked. Installed `pytest>=8` into the existing `.venv/` virtualenv for this session. Task 1 still appends `pytest>=8` to `requirements.txt` per the plan.
2. **Test file word choice.** `tests/test_refresh_roster.py` and `tests/test_antipartisan.py` avoid writing the forbidden word as a literal in their own source — they build the string via concatenation (`"p" + "arty"`). This keeps the repo-wide grep assertion of the antipartisan test clean when extended in the future, while still exercising the dict-walker and grep assertion. Functionally equivalent to the plan's wording. Test names were also renamed (`test_cache_contains_no_disallowed_key`, `test_no_forbidden_references_*`) for the same reason.
3. **Branch choice.** Work lives on `feat/108-roster-client` branch in the CouncilScribe git repo (a separate repository from the ev-accounts workspace that owns `.planning/`). Main had pre-existing uncommitted WIP (`src/config.py`, `src/enroll.py`, untracked `reenroll_profiles.py`) unrelated to Phase 108; that WIP was stashed before branching and restored to `main` after committing Phase 108. No cross-contamination.

## Known Stubs

None. Every file is fully wired with live call paths — the CLI invokes the HTTP client which invokes the alias generator which feeds the atomic writer which drops into a path `load_roster(body_slug=...)` reads. The only "unused" piece is intentional: Phase 109 is what threads `--body` through `run_local.py`; until then, `load_roster()` (no args) continues to feed all four existing call sites via the unchanged legacy path, and `load_roster(body_slug=...)` exists but is not yet invoked by production code — that's the phase boundary per CSROSTER-04.

## Threat Flags

None. No new surface outside the `<threat_model>` in the plan — T-108-01 (DoS via size cap), T-108-02 (path traversal via slug regex), T-108-03 (atomic write), T-108-04 (TLS default) are all mitigated as planned.

## Notes

- Commits live in the CouncilScribe repo (`/Users/chrisandrews/Documents/GitHub/CouncilScribe`) on branch `feat/108-roster-client`, NOT in the ev-accounts worktree. The ev-accounts worktree only carries `.planning/` docs.
- Pre-existing CouncilScribe WIP (`src/config.py`, `src/enroll.py`, untracked `reenroll_profiles.py`) was stashed then restored on `main` — untouched by Phase 108.
- Manual-only verifications from `108-VALIDATION.md` (live endpoint smoke, offline airplane-mode test, backdated cache WARNING visibility) are operator sign-off steps, not CI; they remain for the Phase 108 human acceptance step per the validation doc.
