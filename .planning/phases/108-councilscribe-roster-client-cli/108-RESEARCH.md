# Phase 108: CouncilScribe roster client + CLI — Research

**Researched:** 2026-04-11
**Domain:** Python HTTP client, dataclass extension, CLI (argparse), atomic file I/O, alias generation
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- D-01: Base alias variants — full_name, surname, first+last, preferred+last (when set/different), Title LastName, title-stripped LastName (when different)
- D-02: Hyphenated surnames emit space variant; do NOT split into halves
- D-03: Accented chars — emit both accented and NFKD-ASCII-folded variants
- D-04: Title stripping — strip `Council|Vice|Deputy` prefix only when next token is `President|Chair|Mayor|Speaker|Clerk`
- D-05: Dedup is case-insensitive only; punctuation/whitespace variants are kept distinct
- D-06: Aliases stored in original case
- D-07: Generation order is deterministic
- D-08: Alias generator is a pure function (one politician dict -> list[str])
- Cache path: `~/CouncilScribe/config/rosters/{body_slug}.json`
- Cache payload must include: `body_key`, `body_slug`, `fetched_at`, `politicians[]` with `politician_slug`, `full_name`, `aliases[]`, `title`, `district_label`
- `load_roster()` must accept optional `body_slug` kwarg, fall back to legacy when absent
- 30-day staleness warning is non-blocking
- Network failure must not corrupt existing cache file
- Antipartisan: no `party` field read, logged, or persisted anywhere

### Claude's Discretion
- HTTP library (`requests` vs `httpx`) and timeout/retry policy
- Module layout: one `essentials_client.py` or split with `alias_gen.py`
- Whether to reuse/extend existing `Roster`/`RosterMember` or introduce parallel `BodyRoster`/`PoliticianMember`
- CLI flags beyond `--body {slug}`
- Staleness warning string format and logging channel
- Atomic-write mechanism
- Unit test layout and HTTP stub approach

### Deferred Ideas (OUT OF SCOPE)
- Meeting-level `--body` plumbing into `run_local.py` (Phase 109)
- `StoredProfile` schema changes (Phase 110)
- Identification pipeline integration (Phase 111)
- Auto-refresh on staleness
- Multiple roster versions/history
- Splitting hyphenated surnames into halves
- Broader title-stripping rule
- Lowercasing aliases at storage time
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CSROSTER-01 | `src/essentials_client.py` HTTP client, configurable base URL via `EV_ACCOUNTS_URL`, offline-graceful | requests library already in project; env var pattern confirmed; error handling design documented below |
| CSROSTER-02 | `refresh_roster.py` CLI writes `~/CouncilScribe/config/rosters/{body_slug}.json` with required fields | Cache payload fields confirmed from Phase 107 D-16; atomic-write pattern verified on macOS |
| CSROSTER-03 | Auto-generate aliases per politician covering all D-01..D-08 variants | Pure function design; all stdlib tools confirmed (unicodedata.normalize, regex); alias gen logic fully specified |
| CSROSTER-04 | `load_roster()` slug-first with legacy fallback | Existing `load_roster(path=None)` signature; extension via new `body_slug=None` kwarg confirmed backward-safe |
| CSROSTER-05 | `fetched_at` staleness warning (non-blocking, 30 days) | `datetime.fromisoformat` + `datetime.now(timezone.utc)` confirmed correct; placement design specified |
</phase_requirements>

---

## Summary

Phase 108 is a contained Python-only addition to CouncilScribe with no schema changes and no modifications to `run_local.py`. The work divides cleanly into three units: (1) an HTTP client module, (2) a pure-function alias generator, and (3) a `load_roster()` extension with a new `body_slug` keyword argument. All upstream contracts are locked in Phase 107's service (`essentialsBodiesService.ts`) and route (`essentialsBodies.ts`), both of which are already written and readable.

The key architectural insight is that the canonical `RosterMember.name` string that flows into `correct_speaker_name()` and `roster_names_for_prompt()` should be `"{title} {last_name}"` — not `full_name` — to preserve the pattern that the existing tests and `transcript_named.json` files already encode (e.g. `"Council President Asare"`, `"Councilmember Piedmont-Smith"`). This means the per-body cache stores `full_name` in the `politicians[]` array (per CSROSTER-02) but when loading into the `Roster` dataclass the `RosterMember.name` is constructed from `title + " " + last_name` extracted from `full_name`.

All ten open questions from the CONTEXT.md are answered below with HIGH or MEDIUM confidence from codebase inspection and stdlib verification.

**Primary recommendation:** Use `requests` (already in `requirements.txt`), extend `load_roster()` with a `body_slug=None` kwarg that resolves the per-body cache path, keep alias generation in a dedicated `alias_gen.py` for clean unit testing, and store `"{title} {last_name}"` as `RosterMember.name` for backward-compatible LLM prompt output.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `requests` | >=2.28 (2.32.5 installed) [VERIFIED: codebase grep + pip list] | HTTP GET to ev-accounts endpoints | Already in `requirements.txt`; used in `src/download.py` |
| `argparse` | stdlib | CLI argument parsing | Pattern established by `run_local.py`; no extra deps |
| `tempfile` + `os.replace` | stdlib | Atomic cache writes | `os.replace` is POSIX-atomic on same filesystem [VERIFIED: macOS test] |
| `unicodedata.normalize` | stdlib | NFKD ASCII-folding for D-03 | `normalize('NFKD', s)` + filter `.isascii()` — verified produces `García -> Garcia` [VERIFIED: local test] |
| `datetime` + `timezone.utc` | stdlib | `fetched_at` ISO parsing + staleness delta | `datetime.fromisoformat()` handles ISO-8601 from API; `timezone.utc` for correct delta [VERIFIED: local test] |
| `json` | stdlib | Cache read/write | Consistent with `add_alias()` which uses `indent=2, ensure_ascii=False` [VERIFIED: roster.py:208] |

### Not Needed
- `httpx` — no async requirement; `requests` is sufficient for a one-shot CLI
- `responses` / `respx` — no test library currently in project; hand-rolled fake or `unittest.mock.patch` is the zero-dep choice (see Validation Architecture)

---

## Architecture Patterns

### Recommended Project Structure

```
CouncilScribe/
├── src/
│   ├── essentials_client.py   # NEW: HTTP client + fetch_roster()
│   ├── alias_gen.py           # NEW: generate_aliases() pure function
│   ├── roster.py              # MODIFIED: load_roster() gets body_slug kwarg
│   └── config.py              # UNCHANGED
├── refresh_roster.py          # NEW: CLI at repo root (next to run_local.py)
├── tests/
│   ├── test_alias_gen.py      # NEW: unit tests per D-01..D-08
│   ├── test_essentials_client.py  # NEW: HTTP + error handling tests
│   └── test_roster.py         # NEW: load_roster slug path + legacy fallback
└── requirements.txt           # UNCHANGED (requests already listed)
```

A `tests/` directory does not currently exist. Wave 0 creates it with a `conftest.py`.

### Pattern 1: load_roster() Extension (backward-compatible)

**What:** Add `body_slug: Optional[str] = None` to `load_roster()`. When supplied, resolve path to `CONFIG_DIR / "rosters" / f"{body_slug}.json"`. Legacy `path` param behavior is unchanged.

**When to use:** The Phase 109 planner threads `body_slug` through; until then all existing callers pass nothing.

```python
# Source: inferred from roster.py:31-52 [VERIFIED: codebase read]
def load_roster(
    path: Optional[Path] = None,
    body_slug: Optional[str] = None,
) -> Optional[Roster]:
    if body_slug is not None:
        path = config.CONFIG_DIR / "rosters" / f"{body_slug}.json"
        # Staleness check lives here (slug path only)
    elif path is None:
        path = config.CONFIG_DIR / "council_roster.json"
    if not path.exists():
        return None
    # ... rest unchanged for legacy path
    # For slug path: deserialize BodyRoster cache, build Roster from it
```

**Key:** The `body_slug` path deserializes a different JSON shape (CSROSTER-02 payload) into the same `Roster` return type.

### Pattern 2: Canonical name construction from per-body cache

The legacy roster uses `"Council President Asare"` and `"Councilmember Piedmont-Smith"` as `RosterMember.name`. The `roster_names_for_prompt()` function emits those strings directly to the LLM prompt (roster.py:225). The `transcript_named.json` speaker names also carry this format.

**Conclusion:** When building a `Roster` from a per-body cache, set `RosterMember.name = f"{title} {last_name}"` where `last_name` is the last whitespace-token of `full_name`. This matches the legacy format exactly. `full_name` (`"Isabel Piedmont-Smith"`) must also appear in `aliases[]` (it is variant #1 in D-01), so matching still works.

**The Phase 107 API returns `last_name` only as a computed value inside the service** (`COALESCE(p.last_name, '')` in the SQL SELECT). The `last_name` field is returned in the SQL but **not exposed in the `RosterMember` TypeScript interface** and **not in the D-16 response shape**. The client must extract it from `full_name` using the last-whitespace-token rule (same as `_extract_surname` minus the title-stripping, since the API returns `full_name` without titles).

[VERIFIED: essentialsBodiesService.ts read — `last_name` is fetched in SQL but stripped before the `members` array is constructed; it's used only for sort ordering server-side]

### Pattern 3: Atomic cache write

```python
# Source: [ASSUMED pattern] — tempfile + os.replace is POSIX-standard
import tempfile, os, json
from pathlib import Path

def _write_json_atomic(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_fd, tmp_path = tempfile.mkstemp(
        dir=path.parent, prefix=".tmp_", suffix=".json"
    )
    try:
        with os.fdopen(tmp_fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        os.replace(tmp_path, path)
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise
```

`os.replace` is atomic on macOS/Linux when `tmp_path` and `path` are on the same filesystem (same `config.CONFIG_DIR` subtree guarantees this). [VERIFIED: `os.replace` ran successfully on macOS in local test]

### Pattern 4: Alias generator structure

```python
# Source: alias rules from 108-CONTEXT.md D-01..D-08 [VERIFIED: context read]
from unicodedata import normalize
import re

def generate_aliases(politician: dict) -> list[str]:
    """Pure function: one politician record -> ordered deduplicated alias list."""
    # politician keys: full_name, preferred_name, title
    # Returns list[str] in deterministic order per D-07
    ...
```

Placement: `src/alias_gen.py` — separate from `essentials_client.py` so it can be imported by Phase 109/111 without pulling in HTTP deps.

### Pattern 5: fetch_roster() error contract

```python
# Source: essentialsBodies.ts route [VERIFIED: codebase read]
class EssentialsClientError(Exception):
    def __init__(self, message: str, code: str | None = None, status: int | None = None):
        super().__init__(message)
        self.code = code    # e.g. "BODY_NOT_FOUND", "VALIDATION_ERROR"
        self.status = status

def fetch_roster(body_slug: str, base_url: str | None = None) -> dict:
    """Fetches roster JSON. Raises EssentialsClientError on any failure."""
    ...
```

The CLI catches this and exits non-zero with a human-readable message. `load_roster()` is never called by the CLI — it only reads the cache; the CLI only writes.

### Anti-Patterns to Avoid
- **Reading `party` anywhere in the new files:** the API never returns it (Phase 107 D-15), but a defensive grep assertion in CI or test confirms no accidental reference slips in.
- **Writing directly to the final path without a temp file:** crash between open and close leaves a partial JSON that `load_roster()` then raises on.
- **Calling `load_roster()` from `refresh_roster.py`:** the CLI writes the cache; `load_roster()` reads it. Keeping the two flows separate prevents circular confusion.
- **Emitting staleness warning from the legacy path of `load_roster()`:** legacy cache has no `fetched_at` — the check must only run when `body_slug` is supplied.
- **Lowercasing `last_name` extraction too early:** extract the raw last token from `full_name` before any case transformation; alias generator stores original case per D-06.

---

## Open Questions (Resolved)

### Q1: HTTP library
**Answer:** Use `requests`. [VERIFIED: `requirements.txt` — `requests>=2.28`; `src/download.py` already imports and uses it] `httpx` is not installed. No async requirement exists for a one-shot CLI. Timeout policy: connect=10s, read=15s is sufficient for a small roster payload; single attempt, no retry (operator can re-run).

### Q2: Dataclass strategy
**Answer:** Extend `load_roster()` rather than introduce a parallel type. The simplest path: load the per-body JSON cache inside `load_roster()` and construct the existing `Roster` / `RosterMember` types directly, deriving `RosterMember.name` from `title + " " + last_name_of(full_name)`. No new dataclass needed. Optional: add `body_key`, `body_slug`, `fetched_at` as fields on a thin wrapper dict that the CLI verifies on write — but those fields never need to reach `correct_speaker_name` or `roster_names_for_prompt`, so the `Roster` type is sufficient as-is.

If the planner prefers a typed wrapper, `@dataclass BodyRosterCache` with `body_key`, `body_slug`, `fetched_at`, `politicians: list[dict]` can hold the raw cache and convert to `Roster` via a helper. Both approaches are backward-compatible.

### Q3: Canonical name in per-body cache
**Answer:** `"{title} {last_name}"` — this matches the legacy format (`"Council President Asare"`, `"Councilmember Piedmont-Smith"`). [VERIFIED: council_roster.json read — every `name` field is `"{role} {surname}"`] `full_name` (`"Isabel Piedmont-Smith"`) appears as alias variant #1 per D-01, so both forms are searchable. The LLM prompt via `roster_names_for_prompt()` then emits the same title+surname format it always has.

**Last-name extraction from `full_name`:** use the last whitespace-split token of `full_name` (e.g. `"Isabel Piedmont-Smith".split()[-1]` → `"Piedmont-Smith"`). This is distinct from `_extract_surname()` in `roster.py` which strips titles — `full_name` from the API never includes a title, so no stripping needed.

### Q4: Atomic-write mechanism
**Answer:** `tempfile.mkstemp(dir=path.parent)` + `os.fdopen` + `os.replace`. [VERIFIED: local macOS test succeeded] Using `dir=path.parent` guarantees same-filesystem placement. The manual cleanup on exception prevents temp file leaks. Matches the recommendation in CONTEXT.md and is the Python stdlib idiomatic pattern.

### Q5: Test stubbing
**Answer:** No test suite exists in CouncilScribe (`tests/` directory absent). [VERIFIED: directory listing] No `pytest`, `responses`, or `respx` in the installed packages visible from the project environment. Recommend hand-rolled fake using `unittest.mock.patch("requests.Session.get")` — zero extra dependencies, works with stdlib `unittest` or `pytest` (whichever Wave 0 installs). For the alias generator tests, no mocking needed — pure function.

If `pytest` is added to `requirements.txt` (which it should be for this phase), `unittest.mock` works inside pytest without additional plugins.

### Q6: Alias generator placement
**Answer:** `src/alias_gen.py` — dedicated module. Rationale: (1) importable by Phase 109/111 without pulling in `requests`; (2) unit tests in `tests/test_alias_gen.py` cover D-01..D-08 independently without any client machinery; (3) `essentials_client.py` imports it for use in `fetch_roster()` after receiving the API response.

### Q7: Staleness check placement
**Answer:** Inside `load_roster()` at the `body_slug` code path, after successfully deserializing the cached file and before returning the `Roster`. Emit via `import logging; logging.warning(...)` and also `print(..., file=sys.stderr)` for CLI visibility. Never runs on the legacy path. Example logic:

```python
import sys, logging
from datetime import datetime, timezone

fetched_at_str = data.get("fetched_at", "")
if fetched_at_str:
    fetched_at = datetime.fromisoformat(fetched_at_str)
    age_days = (datetime.now(timezone.utc) - fetched_at).days
    if age_days > 30:
        msg = (
            f"Roster '{body_slug}' is {age_days} days old "
            f"(fetched {fetched_at_str[:10]}). "
            f"Re-run: refresh_roster.py --body {body_slug}"
        )
        logging.warning(msg)
        print(f"WARNING: {msg}", file=sys.stderr)
```

[VERIFIED: `datetime.fromisoformat` handles ISO-8601 with `+00:00` suffix in Python 3.11+; the API emits `new Date().toISOString()` → `Z`-suffix form. Python 3.11+ handles `Z`; for Python 3.10 compatibility use `.replace('Z', '+00:00')` before parsing.]

### Q8: CLI UX
**Answer:** Mandatory `--body <slug>`. Recommended optional flags:

| Flag | Type | Default | Purpose |
|------|------|---------|---------|
| `--body` | str, required | — | Body slug (e.g. `bloomington-common-council`) |
| `--base-url` | str | `https://accounts.empowered.vote` | Override API base for local dev |
| `--force` | flag | False | Skip staleness check warning, re-fetch unconditionally |
| `--output` | path | derived from slug | Override output path (dev/testing) |

Exit codes: 0 = success, 1 = network error / body not found / write error. Progress to stdout, errors to stderr.

### Q9: Error envelope handling

Based on `essentialsBodies.ts` route [VERIFIED: codebase read]:

| Scenario | HTTP Status | Response body | CLI behavior |
|----------|------------|---------------|--------------|
| Unknown slug | 404 | `{"code":"BODY_NOT_FOUND","message":"..."}` | Print "Body not found: {slug}" to stderr, exit 1 |
| Invalid slug format | 422 | `{"code":"VALIDATION_ERROR","message":"..."}` | Print "Invalid slug format: {slug}" to stderr, exit 1 |
| Transport failure (ConnectionError, Timeout) | n/a | n/a | Print "Network error: {exc}" to stderr, exit 1; existing cache NOT touched |
| 5xx server error | 500 | `{"code":"INTERNAL_ERROR","message":"..."}` | Print "Server error (500): {message}" to stderr, exit 1; existing cache NOT touched |
| Empty roster (200, members=[]) | 200 | `{"members":[]}` | Write cache as-is; print "Warning: {slug} has 0 active members" to stdout |

The client raises `EssentialsClientError` for all non-200 cases. The CLI catches it, prints a formatted message, and exits 1. The atomic-write pattern means the existing cache is never touched on any failure path.

### Q10: Antipartisan validation
**Answer:** Mechanical check = grep assertion in test suite. Add a test:

```python
import subprocess, sys
def test_no_party_references():
    """Assert no new files reference party fields (antipartisan enforcement)."""
    result = subprocess.run(
        ["grep", "-rn", r"\bparty\b", "src/essentials_client.py", "src/alias_gen.py",
         "refresh_roster.py"],
        capture_output=True, text=True
    )
    assert result.returncode != 0 or result.stdout == "", \
        f"Found 'party' reference in Phase 108 files:\n{result.stdout}"
```

Additionally: code review checklist item — grep `party` in the three new files before PR merge.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTTP | Custom socket-level client | `requests.get(url, timeout=(10,15))` | Already in project; handles redirects, encoding, keep-alive |
| Unicode normalization | Manual char-by-char accent table | `unicodedata.normalize('NFKD', s)` | Handles all Unicode accents, verified on García/Muñoz [VERIFIED: local test] |
| Atomic file write | `open(path, 'w')` directly | `tempfile.mkstemp` + `os.replace` | Crash-safe; no partial-write corruption [VERIFIED: macOS test] |
| ISO-8601 parsing | Regex date parser | `datetime.fromisoformat(s.replace('Z', '+00:00'))` | Stdlib; handles timezone-aware comparison correctly |

---

## Common Pitfalls

### Pitfall 1: `os.replace` across filesystems
**What goes wrong:** `os.replace(tmp, dst)` raises `OSError: [Errno 18] Invalid cross-device link` if `tmp` and `dst` are on different filesystems.
**Why it happens:** `tempfile.NamedTemporaryFile()` with no `dir=` argument defaults to `/tmp`, which may be `tmpfs` — different from `~/CouncilScribe/config/`.
**How to avoid:** Always pass `dir=path.parent` to `tempfile.mkstemp()`. [VERIFIED: macOS test used `dir=path.parent`]
**Warning signs:** `OSError` with errno 18 on first cache write.

### Pitfall 2: `datetime.fromisoformat` with Z-suffix on Python < 3.11
**What goes wrong:** `datetime.fromisoformat("2026-02-01T00:00:00Z")` raises `ValueError` on Python 3.10 and earlier (Z was not recognized until 3.11).
**Why it happens:** The API emits `new Date().toISOString()` which produces the `Z`-suffix form.
**How to avoid:** Normalize before parsing: `s.replace('Z', '+00:00')`. Also works on 3.11+ as the `+00:00` form is always valid.
**Warning signs:** `ValueError: Invalid isoformat string` in staleness check.

### Pitfall 3: `last_name` not in Phase 107 API response
**What goes wrong:** Code tries to read `member["last_name"]` from the JSON — key not present.
**Why it happens:** `last_name` is fetched in the SQL but intentionally excluded from the `RosterMember` TypeScript interface and never serialized. [VERIFIED: essentialsBodiesService.ts read — `last_name` only used for server-side sort, not in returned object]
**How to avoid:** Extract last name client-side from `full_name`: `full_name.split()[-1]`.
**Warning signs:** `KeyError: 'last_name'` when building `RosterMember.name`.

### Pitfall 4: Staleness warning fires on legacy roster
**What goes wrong:** `load_roster()` emits spurious staleness warning when called with no args (legacy path), because code incorrectly checks `fetched_at` on both paths.
**Why it happens:** Legacy `council_roster.json` has no `fetched_at` field.
**How to avoid:** Guard the staleness block behind `if body_slug is not None:` — the check is skipped entirely on the legacy path.

### Pitfall 5: Dedup removes intentional punctuation variants
**What goes wrong:** Aliases `"Piedmont-Smith"` and `"Piedmont Smith"` are deduplicated as near-duplicates by an overly aggressive dedup rule.
**Why it happens:** Treating whitespace/hyphen differences as equivalent.
**How to avoid:** Per D-05, dedup is case-insensitive only — two strings differing only in case collapse, but `"Piedmont-Smith"` and `"Piedmont Smith"` are distinct and both kept.

### Pitfall 6: `load_roster()` signature breaks existing call sites
**What goes wrong:** Adding `body_slug` as a positional parameter breaks the four `run_local.py` call sites that call `load_roster()` with no args.
**Why it happens:** Wrong parameter ordering.
**How to avoid:** Use `body_slug: Optional[str] = None` as a keyword-only argument after `path`. All four existing call sites (`run_local.py:568, 1021, 1719, 1749`) pass nothing — they continue to work unchanged.

---

## Code Examples

### Alias generation for Piedmont-Smith (D-02 hyphen expansion)

```python
# Source: D-02 rule from 108-CONTEXT.md [VERIFIED: context read]
# Input: {"full_name": "Isabel Piedmont-Smith", "preferred_name": "Isabel", "title": "Councilmember"}
# Expected output (in order):
[
    "Isabel Piedmont-Smith",          # D-01 variant 1: full_name
    "Isabel Piedmont Smith",          # D-02: hyphen->space of full_name
    "Piedmont-Smith",                 # D-01 variant 2: surname
    "Piedmont Smith",                 # D-02: hyphen->space of surname
    "Isabel Piedmont-Smith",          # D-01 variant 3: first+last (== full_name, deduped)
    # preferred_name "Isabel" == first_name "Isabel" -> D-01 variant 4 SKIPPED
    "Councilmember Piedmont-Smith",   # D-01 variant 5: Title LastName
    "Councilmember Piedmont Smith",   # D-02: hyphen->space of title+surname
    # D-04: "Councilmember" has no strippable prefix -> no variant 6
]
# After dedup: "Isabel Piedmont-Smith" appears twice (variants 1 and 3) -> collapsed to one
# Final: ["Isabel Piedmont-Smith", "Isabel Piedmont Smith", "Piedmont-Smith",
#         "Piedmont Smith", "Councilmember Piedmont-Smith", "Councilmember Piedmont Smith"]
```

### Alias generation for Council President Asare (D-04 title strip)

```python
# Input: {"full_name": "Saki Asare", "preferred_name": "Saki", "title": "Council President"}
# Expected output:
[
    "Saki Asare",             # full_name
    "Asare",                  # surname
    "Saki Asare",             # first+last (== full_name, deduped)
    # preferred_name "Saki" == first_name "Saki" -> skipped
    "Council President Asare", # Title LastName
    "President Asare",        # D-04: strip "Council " prefix, "President" is in the keep-list
]
# Final: ["Saki Asare", "Asare", "Council President Asare", "President Asare"]
```

### fetch_roster() skeleton

```python
# Source: essentialsBodies.ts error shapes [VERIFIED: codebase read]
import os, requests

class EssentialsClientError(Exception):
    def __init__(self, message, code=None, status=None):
        super().__init__(message)
        self.code = code
        self.status = status

def fetch_roster(body_slug: str, base_url: str | None = None) -> dict:
    base = (base_url or os.environ.get("EV_ACCOUNTS_URL", "https://accounts.empowered.vote")).rstrip("/")
    url = f"{base}/api/essentials/bodies/{body_slug}/roster"
    try:
        resp = requests.get(url, timeout=(10, 15))
    except requests.exceptions.RequestException as exc:
        raise EssentialsClientError(f"Network error: {exc}") from exc
    if resp.status_code == 404:
        body = resp.json()
        raise EssentialsClientError(body.get("message", "Body not found"), code=body.get("code"), status=404)
    if resp.status_code == 422:
        body = resp.json()
        raise EssentialsClientError(body.get("message", "Validation error"), code=body.get("code"), status=422)
    if resp.status_code >= 500:
        raise EssentialsClientError(f"Server error ({resp.status_code})", status=resp.status_code)
    resp.raise_for_status()
    return resp.json()
```

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest (not currently installed — Wave 0 adds `pytest>=8` to requirements.txt) |
| Config file | none — Wave 0 creates `tests/conftest.py` |
| Quick run command | `cd CouncilScribe && python -m pytest tests/ -x -q` |
| Full suite command | `cd CouncilScribe && python -m pytest tests/ -v` |

No existing test files detected. [VERIFIED: directory listing — no `tests/` directory]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CSROSTER-01 | fetch_roster() returns parsed dict on 200 | unit | `pytest tests/test_essentials_client.py::test_fetch_roster_success -x` | Wave 0 |
| CSROSTER-01 | fetch_roster() raises EssentialsClientError on 404 | unit | `pytest tests/test_essentials_client.py::test_fetch_roster_404 -x` | Wave 0 |
| CSROSTER-01 | fetch_roster() raises EssentialsClientError on network failure | unit | `pytest tests/test_essentials_client.py::test_fetch_roster_network_error -x` | Wave 0 |
| CSROSTER-01 | EV_ACCOUNTS_URL env var overrides default base URL | unit | `pytest tests/test_essentials_client.py::test_base_url_from_env -x` | Wave 0 |
| CSROSTER-02 | refresh_roster.py writes JSON with required fields | integration | `pytest tests/test_refresh_roster.py::test_writes_required_fields -x` | Wave 0 |
| CSROSTER-02 | Atomic write: existing cache not corrupted on write error | unit | `pytest tests/test_essentials_client.py::test_atomic_write_no_corruption -x` | Wave 0 |
| CSROSTER-03 | generate_aliases produces full_name variant (D-01) | unit | `pytest tests/test_alias_gen.py::test_full_name_variant -x` | Wave 0 |
| CSROSTER-03 | generate_aliases hyphen->space expansion (D-02) | unit | `pytest tests/test_alias_gen.py::test_hyphen_space_variant -x` | Wave 0 |
| CSROSTER-03 | generate_aliases ASCII-fold for accented chars (D-03) | unit | `pytest tests/test_alias_gen.py::test_ascii_fold_variant -x` | Wave 0 |
| CSROSTER-03 | generate_aliases title strip (D-04) | unit | `pytest tests/test_alias_gen.py::test_title_strip_variant -x` | Wave 0 |
| CSROSTER-03 | generate_aliases case-insensitive dedup only (D-05) | unit | `pytest tests/test_alias_gen.py::test_dedup_case_insensitive_only -x` | Wave 0 |
| CSROSTER-03 | generate_aliases deterministic order (D-07) | unit | `pytest tests/test_alias_gen.py::test_deterministic_order -x` | Wave 0 |
| CSROSTER-03 | preferred_name variant skipped when equal to first_name | unit | `pytest tests/test_alias_gen.py::test_preferred_name_skipped_when_same -x` | Wave 0 |
| CSROSTER-04 | load_roster(body_slug=...) reads per-body cache | unit | `pytest tests/test_roster.py::test_load_roster_slug_path -x` | Wave 0 |
| CSROSTER-04 | load_roster() with no args reads legacy council_roster.json | unit | `pytest tests/test_roster.py::test_load_roster_legacy_fallback -x` | Wave 0 |
| CSROSTER-04 | load_roster(body_slug=...) returns None if no file | unit | `pytest tests/test_roster.py::test_load_roster_slug_missing -x` | Wave 0 |
| CSROSTER-05 | Staleness warning emitted when cache > 30 days old | unit | `pytest tests/test_roster.py::test_staleness_warning_emitted -x` | Wave 0 |
| CSROSTER-05 | No staleness warning on legacy path (no fetched_at) | unit | `pytest tests/test_roster.py::test_no_staleness_on_legacy -x` | Wave 0 |
| Antipartisan | No `party` reference in new Phase 108 source files | unit | `pytest tests/test_antipartisan.py::test_no_party_in_new_files -x` | Wave 0 |

### HTTP Stubbing Strategy (no `responses` library)

Use `unittest.mock.patch` on `requests.Session.get` or a thin `_make_request()` helper inside `essentials_client.py` that can be monkey-patched:

```python
# In essentials_client.py — injectable for testing
def _http_get(url: str, timeout: tuple) -> requests.Response:
    return requests.get(url, timeout=timeout)

# In test
from unittest.mock import patch, MagicMock
def test_fetch_roster_success(tmp_path):
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {"slug": "test", "members": []}
    with patch("src.essentials_client._http_get", return_value=mock_resp):
        result = fetch_roster("test")
    assert result["slug"] == "test"
```

### Atomic-write safety test

```python
def test_atomic_write_no_corruption(tmp_path):
    """Existing cache is unchanged when write raises mid-way."""
    original = {"slug": "test", "members": [{"full_name": "Alice Smith"}]}
    cache_path = tmp_path / "test.json"
    cache_path.write_text(json.dumps(original))
    
    with patch("os.replace", side_effect=OSError("simulated crash")):
        with pytest.raises(OSError):
            _write_json_atomic(cache_path, {"slug": "test", "members": []})
    
    # Original cache intact
    assert json.loads(cache_path.read_text()) == original
```

### Sampling Rate
- **Per task commit:** `python -m pytest tests/ -x -q`
- **Per wave merge:** `python -m pytest tests/ -v`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `tests/__init__.py` — package init
- [ ] `tests/conftest.py` — shared fixtures (tmp_path roster dir, sample politician dicts)
- [ ] `tests/test_alias_gen.py` — covers CSROSTER-03 / D-01..D-08
- [ ] `tests/test_essentials_client.py` — covers CSROSTER-01, CSROSTER-02 (write)
- [ ] `tests/test_roster.py` — covers CSROSTER-04, CSROSTER-05
- [ ] `tests/test_antipartisan.py` — covers antipartisan grep assertion
- [ ] Framework install: add `pytest>=8` to `requirements.txt`

---

## Security Domain

Phase 108 makes unauthenticated GET requests to a public API. ASVS categories with meaningful applicability:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | public endpoint, no auth token |
| V5 Input Validation | yes (minimal) | body slug validated by CLI before sending; API also validates with 422 |
| V6 Cryptography | no | |
| V10 Malicious Code | yes | antipartisan enforcement — no party field processed |

No secrets or credentials involved. The one security-adjacent concern is the `EV_ACCOUNTS_URL` env var: it accepts any URL, which could point to a malicious server. This is acceptable for an operator-level tool (same trust level as the operator's shell environment).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3 | All new code | ✓ | system Python 3 | — |
| `requests` | HTTP client | ✓ | 2.32.5 [VERIFIED: pip show] | — |
| `pytest` | Test suite | not installed in project venv | — | Wave 0 adds to requirements.txt |
| `unicodedata` | D-03 ASCII fold | ✓ | stdlib | — |
| `tempfile` / `os` | Atomic write | ✓ | stdlib | — |
| `argparse` | CLI | ✓ | stdlib | — |
| ev-accounts API | Integration test (optional) | depends on Phase 107 completion | — | Unit tests stub HTTP; integration test is optional smoke test |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** `pytest` — add to `requirements.txt` in Wave 0. Integration test against live API is optional; unit tests cover all requirements with mocks.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `last_name` is NOT present in Phase 107 API response; must be extracted from `full_name` | Architecture Patterns / Pitfall 3 | If `last_name` IS in response, the extraction code still works (just redundant). Risk: LOW |
| A2 | Python on the operator machine is 3.11+ (needed for `datetime.fromisoformat('...Z')` without workaround) | Pitfall 2 | If 3.10, the `Z`-suffix workaround `.replace('Z','+00:00')` is needed. Risk: LOW — workaround is one line |
| A3 | No `pytest` currently in CouncilScribe venv | Validation Architecture | If pytest IS available, Wave 0 skip count drops by one. Risk: LOW |

---

## Sources

### Primary (HIGH confidence)
- `CouncilScribe/src/roster.py` — full read; `Roster`/`RosterMember` dataclasses, `load_roster()` signature, `correct_speaker_name()`, `roster_names_for_prompt()`, write pattern
- `CouncilScribe/src/config.py` — `CONFIG_DIR` derivation
- `CouncilScribe/requirements.txt` — confirmed `requests>=2.28`, `pytest` absent
- `ev-accounts/backend/src/lib/essentialsBodiesService.ts` — full read; confirmed `last_name` in SQL but not in TypeScript interface/response
- `ev-accounts/backend/src/routes/essentialsBodies.ts` — full read; error envelopes confirmed
- `CouncilScribe/config/council_roster.json` — reference format; `name` field is `"{role} {surname}"`
- `.planning/phases/108-councilscribe-roster-client-cli/108-CONTEXT.md` — locked decisions D-01..D-08
- `.planning/phases/107-essentials-body-roster-endpoint/107-CONTEXT.md` — upstream data contract D-15, D-16

### Secondary (MEDIUM confidence)
- Local macOS tests: `os.replace` atomic write confirmed, `unicodedata.normalize('NFKD')` folding confirmed, `datetime` delta calculation confirmed

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from requirements.txt and codebase grep
- Architecture: HIGH — based on full read of all relevant source files
- Pitfalls: HIGH — derived from reading actual code, not hypothetical
- Validation: HIGH — test map derived from requirement text and locked decisions

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (stable, no fast-moving dependencies)
