---
phase: 108-councilscribe-roster-client-cli
verified: 2026-04-11T00:00:00Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
human_verification:
  - test: "End-to-end refresh against live accounts.empowered.vote"
    expected: "`python refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` containing aliases for Piedmont-Smith and Asare"
    why_human: "Live endpoint smoke test — requires network access to production API"
  - test: "Offline behavior preserves existing cache (airplane mode)"
    expected: "With an existing cache present, disable network, run `refresh_roster.py --body bloomington-common-council` — CLI exits non-zero with clear stderr error AND cache file sha256 is byte-identical before/after"
    why_human: "Requires manually disabling network (airplane mode / firewall)"
  - test: "Staleness warning visible on real backdated cache"
    expected: "Backdate `fetched_at` in an existing cache to >30 days ago, call `load_roster(body_slug=...)`, confirm WARNING line appears on stderr and logging.warning without blocking"
    why_human: "Relies on real filesystem cache plus operator observation of stderr; unit-tested version uses monkeypatched datetime"
---

# Phase 108: CouncilScribe roster client + CLI Verification Report

**Phase Goal:** CouncilScribe can fetch and cache any body's roster locally with auto-generated aliases, with graceful offline behavior and staleness warnings.
**Verified:** 2026-04-11
**Status:** human_needed (all 7 automated must-haves verified; 3 manual-only validations remain per 108-VALIDATION.md)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `refresh_roster.py --body bloomington-common-council` writes `~/CouncilScribe/config/rosters/bloomington-common-council.json` with `body_key`, `body_slug`, `fetched_at`, `politicians[]` containing `politician_slug`, `full_name`, `aliases[]`, `title`, `district_label` | VERIFIED | `refresh_roster.py` `_build_cache_payload` (lines 29-62) emits exactly those keys; `_write_json_atomic` persists via tempfile + `os.replace`; `test_cli_success_writes_cache` + `test_cache_payload_shape` green |
| 2 | Aliases cover D-01..D-04 variants with D-05 case-only dedup in deterministic D-07 order | VERIFIED | `src/alias_gen.py::generate_aliases` implements all 6 base variants, `_expand_accent` (D-03), `_expand_hyphen_space` (D-02), `_strip_leadership_title` (D-04), `_case_dedup` (D-05); 16 unit tests in `test_alias_gen.py` all pass |
| 3 | With network disabled, `refresh_roster.py` exits non-zero with clear stderr message and existing cache is byte-identical | VERIFIED | `essentials_client.py` wraps `RequestException` in `EssentialsClientError("Network error: ...")`; `refresh_roster.py:130-133` prints to stderr and returns 1; atomic writer only calls `os.replace` after successful JSON dump, so network failure never reaches disk; `test_network_failure_preserves_existing_cache` validates sha256 equivalence |
| 4 | `load_roster(body_slug=...)` returns a Roster whose `members[].name` = `"{title} {last_name}"` with aliases populating `correct_speaker_name` | VERIFIED | `src/roster.py:107-121` builds canonical name as `f"{title} {last_name}"` using last whitespace token of full_name; `test_load_by_slug_success` + `test_slug_roster_drives_correct_speaker_name` pass |
| 5 | `load_roster()` (no args) preserves legacy behavior across all 4 `run_local.py` call sites | VERIFIED | `src/roster.py:54-70` legacy path unchanged (keyword-only `body_slug` kwarg protects positional callers); `grep -n 'load_roster(' run_local.py` shows all 4 call sites at 568/1021/1719/1749 use `load_roster()` with zero args; `test_load_legacy_fallback` + `test_run_local_compat` pass |
| 6 | 31-day-old cache emits non-blocking `logging.warning` + stderr WARNING; fresh and legacy paths do NOT warn | VERIFIED | `src/roster.py:79-102` staleness block only runs on slug path; calls both `logging.warning(msg)` and `print(f"WARNING: {msg}", file=sys.stderr)`; Z-suffix normalized to `+00:00` for `datetime.fromisoformat`; `test_staleness_warning_*` trio passes |
| 7 | Zero `party` references in Phase 108 source files | VERIFIED | `grep -n 'party' src/essentials_client.py src/alias_gen.py refresh_roster.py src/roster.py` returned exit code 1 (no matches); `tests/test_antipartisan.py` encodes this as a pytest regression |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `CouncilScribe/src/alias_gen.py` | Pure `generate_aliases` per D-01..D-08 | VERIFIED | 124 lines; zero IO; exports `generate_aliases`; imported by `refresh_roster.py` |
| `CouncilScribe/src/essentials_client.py` | `fetch_body_roster` + `EssentialsClientError` | VERIFIED | 114 lines; slug regex `^[a-z0-9-]+$` (T-108-02); 5 MB Content-Length cap (T-108-01); env + arg base URL; 404/422/5xx/network error envelopes |
| `CouncilScribe/refresh_roster.py` | CLI with atomic cache write | VERIFIED | 151 lines; argparse; tempfile + `os.replace`; imports alias_gen + essentials_client |
| `CouncilScribe/src/roster.py` (modified) | `load_roster(path=None, *, body_slug=None)` | VERIFIED | Added 300-line module; legacy path preserved (lines 54-70); slug path + staleness (72-126) |
| `CouncilScribe/tests/test_alias_gen.py` | 16 tests covering D-01..D-07 | VERIFIED | 152 lines; all 16 pass |
| `CouncilScribe/tests/test_essentials_client.py` | 11 HTTP tests | VERIFIED | 123 lines; all 11 pass |
| `CouncilScribe/tests/test_refresh_roster.py` | 9 atomic-write tests | VERIFIED | 148 lines; all 9 pass |
| `CouncilScribe/tests/test_roster_load.py` | 10 slug/legacy/staleness tests | VERIFIED | 142 lines; all 10 pass |
| `CouncilScribe/tests/test_antipartisan.py` | Grep regression + run_local AST check | VERIFIED | 47 lines; 2 tests pass |
| `CouncilScribe/tests/fixtures/bloomington_roster_response.json` | Mirrors Phase 107 RosterResponse | VERIFIED | 4 members incl. Piedmont-Smith, Asare, García (accented), Bolden (City Clerk) |
| `CouncilScribe/pytest.ini` | pytest config | VERIFIED | Present with `testpaths = tests` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `refresh_roster.py` | `src/essentials_client.py::fetch_body_roster` | `from src.essentials_client import ...` | WIRED | line 26 + called line 129 |
| `refresh_roster.py` | `src/alias_gen.py::generate_aliases` | `from src.alias_gen import ...` | WIRED | line 25 + called line 46 per member |
| `src/roster.py::load_roster` | `~/CouncilScribe/config/rosters/{body_slug}.json` | `config.CONFIG_DIR / "rosters" / f"{body_slug}.json"` | WIRED | line 73 |
| `src/roster.py::load_roster` | legacy `council_roster.json` | default when both args None | WIRED | lines 55-57 |
| `refresh_roster.py` CLI output | `load_roster(body_slug=...)` consumer | on-disk JSON contract | WIRED | payload keys (`body_slug`, `fetched_at`, `politicians[].aliases`) match what `load_roster` reads lines 77-121 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|-------------------|--------|
| `refresh_roster.main` | `response` | `fetch_body_roster` → `requests.get` → Phase 107 API | Yes (on live endpoint; unit tests use mocked response with real fixture) | FLOWING |
| `load_roster(body_slug=...)` | `data` | Atomic cache JSON on disk | Yes — written only on successful fetch | FLOWING |
| `RosterMember.aliases` | `pol.get("aliases")` | `generate_aliases` output persisted in cache | Yes — verified via round-trip in `test_slug_roster_drives_correct_speaker_name` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full pytest suite green | `python -m pytest tests/ -q` | `48 passed in 0.12s` | PASS |
| Antipartisan grep (Phase 108 files) | `grep -n 'party' src/essentials_client.py src/alias_gen.py refresh_roster.py src/roster.py` | exit 1 (no matches) | PASS |
| `run_local.py` backward-compat | `grep -n 'load_roster(' run_local.py` | 4 call sites all `load_roster()` with zero args (lines 568, 1021, 1719, 1749) | PASS |
| Branch commit chain | `git log --oneline feat/108-roster-client` | 7 atomic commits present (0cf1c96 → f849ca9) | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|------------|------------|-------------|--------|----------|
| CSROSTER-01 | 108-01-PLAN | HTTP client with configurable base URL + graceful offline | SATISFIED | `src/essentials_client.py` with `EV_ACCOUNTS_URL` env + `--base-url` flag + `EssentialsClientError` network wrapping |
| CSROSTER-02 | 108-01-PLAN | CLI writes `~/CouncilScribe/config/rosters/{body_slug}.json` with required keys | SATISFIED | `refresh_roster.py::_build_cache_payload` + `_write_json_atomic`; Truth #1 |
| CSROSTER-03 | 108-01-PLAN | Auto-generated aliases from base variants with dedup | SATISFIED | `src/alias_gen.py` D-01..D-08 + 16 tests; Truth #2 |
| CSROSTER-04 | 108-01-PLAN | `load_roster()` prefers per-body slug, falls back to legacy | SATISFIED | `src/roster.py:34-126`; keyword-only kwarg; Truth #4 + #5 |
| CSROSTER-05 | 108-01-PLAN | `fetched_at` + non-blocking >30 day warning | SATISFIED | `src/roster.py:79-102`; Truth #6 |

No ORPHANED requirements — all 5 IDs mapped to Phase 108 in REQUIREMENTS.md are accounted for in the plan's `requirements:` frontmatter and verified.

### Anti-Patterns Found

None. Scanned `src/alias_gen.py`, `src/essentials_client.py`, `refresh_roster.py`, `src/roster.py` changes:

- No TODO/FIXME/PLACEHOLDER comments in Phase 108 files.
- No empty `return null/[]/{}` stubs — every function has substantive logic.
- No hardcoded empty props — cache payload built from real response dict.
- No `party` references (antipartisan enforced).
- `console.log`-only handlers: N/A (Python, and all CLI prints are real status output).

### Human Verification Required

Per `108-VALIDATION.md` §Manual-Only Verifications — three operator sign-off steps that cannot be run in CI:

1. **Live endpoint smoke test** — Run `python refresh_roster.py --body bloomington-common-council` against production `accounts.empowered.vote`; confirm cache file created with Piedmont-Smith and Asare aliases. (CSROSTER-01, CSROSTER-02)
2. **Offline byte-identity test** — With an existing cache present, disable network (airplane mode), re-run the CLI, confirm non-zero exit with clear stderr message AND compare sha256 before/after. (CSROSTER-03)
3. **Staleness warning visibility** — Backdate `fetched_at` in an existing cache to >30 days, call `load_roster(body_slug=...)`, confirm WARNING line appears on stderr without blocking. (CSROSTER-05)

### Gaps Summary

No automated gaps. All 7 acceptance truths verified, all 5 CSROSTER-* requirements satisfied, 48/48 tests passing, zero anti-patterns, antipartisan grep clean, backward compatibility with `run_local.py` confirmed via AST check and static grep of all 4 call sites.

The **only** remaining work to close Phase 108 is the 3 manual validations listed above, which are explicitly designated as operator sign-off in `108-VALIDATION.md` and cannot be automated without network/filesystem clock manipulation.

---

*Verified: 2026-04-11*
*Verifier: Claude (gsd-verifier)*
