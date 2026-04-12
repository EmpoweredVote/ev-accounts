# Phase 110: Profile schema v3 + re-enrollment — Research

**Researched:** 2026-04-11
**Domain:** CouncilScribe voice profile DB — Python dataclasses, pickle serialization, slug keying, re-enrollment CLI
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CSPROFILE-01 | `ProfileDB` schema bumped v2→v3. `StoredProfile` gains `politician_slug` (nullable) and `politician_id` (uuid, nullable) fields. `load_profiles()` auto-discards v2 profiles on mismatch (same v1→v2 pattern). | `src/enroll.py` current v2 schema is fully read. Auto-discard pattern at lines 48-61 is the exact code to replicate. `PROFILE_SCHEMA_VERSION = 2` in `src/config.py` line 75. |
| CSPROFILE-02 | When enrolling a speaker whose confirmed name resolves to a roster member, profile key becomes `essentials:<politician_slug>` and `politician_slug`/`politician_id` are populated from the roster. | Roster cache JSON shape is verified — `politician_slug` and `politician_id` are present on every roster member. The `_enroll_one` function is the single insertion point. `SpeakerMapping` in `src/models.py` does not yet carry `politician_slug`; the roster-lookup must happen at enroll time. |
| CSPROFILE-03 | Non-roster speakers enroll under local auto-generated slugs; roster-keyed and local-keyed profiles coexist in the same DB. | `_name_to_slug()` already generates local slugs. Coexistence is a natural consequence of `dict[str, StoredProfile]` — no structural change needed, just two distinct key prefixes. |
| CSPROFILE-04 | `reenroll_profiles.py` updated to load per-body rosters, match each `transcript_named.json` speaker name to the body roster, promote matches to `essentials:<slug>` keys during re-enrollment. | `reenroll_profiles.py` is fully read. It currently discovers meeting dirs, loads `pipeline_state.json`-implied body_slug (now available via Phase 109's `PipelineState.body_slug`), and calls `enroll_speakers`. It needs: (a) read `body_slug` from `pipeline_state.json`, (b) call `load_roster(body_slug=...)`, (c) pass roster into enroll path, (d) use essentials key when name matches. |
| CSPROFILE-05 | A politician-slug-keyed profile accumulates embeddings across every meeting that politician speaks in — re-enrolling against a second meeting adds to the existing profile rather than creating a duplicate. | `_enroll_one` already merges into an existing key (lines 113-117 of `enroll.py`). With a stable `essentials:<politician_slug>` key, accumulation is automatic. |
</phase_requirements>

---

## Summary

Phase 110 extends the CouncilScribe voice profile system so profiles for known politicians are keyed by their essentials identity (`essentials:<politician_slug>`) rather than a locally-generated name slug. The profile dataclass (`StoredProfile`) gains two nullable identity fields, the schema version bumps to 3, and the existing v1→v2 auto-discard-on-load pattern is replicated for v2→v3. Two enrollment paths need updating: the live `enroll_speakers` function called from `run_local.py`, and the batch `reenroll_profiles.py` re-enrollment script. A new helper must resolve "does this speaker name match a roster member?" and, if yes, return the canonical `essentials:<politician_slug>` key and populate the new identity fields.

Phase 109 is fully complete (60 tests green, 3/3 roadmap criteria verified). It established `PipelineState.body_slug` persisted per meeting, `load_roster(body_slug=...)` with per-body caching, and Stage 4 body-aware roster consumption. Phase 110 is the direct downstream consumer: it assumes every tagged meeting has a `body_slug` in its `pipeline_state.json` and a corresponding roster cache at `~/CouncilScribe/config/rosters/{slug}.json`.

The H-01 gap from Phase 109 verification (incomplete `rewind_for_retag()`) appears to have been fixed already — the current `checkpoint.py` (read in this session) shows `rewind_for_retag()` deletes all three stale files and calls `self.save()` internally. Phase 110 inherits a clean foundation.

**Primary recommendation:** Extend `StoredProfile` with two nullable fields, bump `PROFILE_SCHEMA_VERSION` to 3, add a `resolve_enrollment_key()` helper, and update both enrollment paths to use it. All changes are confined to `src/enroll.py`, `src/config.py`, `reenroll_profiles.py`, and a new test module.

---

## Standard Stack

### Core (existing — no new dependencies)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| Python | 3.13 (venv) | Runtime | `[VERIFIED: .venv/bin/python]` |
| pickle | stdlib | Profile DB persistence | Already in use — PROFILE_SCHEMA_VERSION guards deserialization |
| dataclasses | stdlib | `StoredProfile`, `ProfileDB` | Already in use |
| numpy | (installed) | Embedding arrays | Already in use |
| pytest | (installed) | Test runner | 60 tests already green |

No new dependencies are needed. This phase is pure Python dataclass and control-flow work.

---

## Architecture Patterns

### Existing Profile DB Shape (v2, current)

```python
# src/enroll.py — current v2
@dataclass
class StoredProfile:
    speaker_id: str          # local slug, e.g. "adams_jane"
    display_name: str
    embeddings: list[np.ndarray]
    centroid: Optional[np.ndarray]
    meetings_seen: list[str]
    total_segments_confirmed: int

@dataclass
class ProfileDB:
    schema_version: int = 2   # config.PROFILE_SCHEMA_VERSION
    profiles: dict[str, StoredProfile]
```

`[VERIFIED: src/enroll.py lines 17-28, src/config.py line 75]`

### Target Profile DB Shape (v3)

```python
# v3 additions to StoredProfile
@dataclass
class StoredProfile:
    speaker_id: str           # profile key (essentials:<slug> OR local slug)
    display_name: str
    embeddings: list[np.ndarray]
    centroid: Optional[np.ndarray]
    meetings_seen: list[str]
    total_segments_confirmed: int
    politician_slug: Optional[str] = None  # NEW — essentials identifier
    politician_id: Optional[str] = None    # NEW — essentials UUID

@dataclass
class ProfileDB:
    schema_version: int = 3   # bumped
    profiles: dict[str, StoredProfile]
```

New fields default `None` on existing in-memory creation. Because pickle serializes the full object graph, v2 pickles will deserialize fine as v2 `ProfileDB` objects — the version mismatch check fires on `db.schema_version != config.PROFILE_SCHEMA_VERSION` (3 vs 2) and discards them exactly as v1→v2 did. `[VERIFIED: src/enroll.py lines 48-61]`

### Auto-Discard Pattern (v1→v2, replicate for v2→v3)

```python
# src/enroll.py load_profiles() — existing pattern to replicate exactly
stored_version = getattr(db, "schema_version", 1)
if stored_version != config.PROFILE_SCHEMA_VERSION:
    print(
        f"  [enroll] Profile DB schema v{stored_version} incompatible with "
        f"current v{config.PROFILE_SCHEMA_VERSION} ..."
    )
    backup = path.with_suffix(f".v{stored_version}.pkl.bak")
    try:
        path.rename(backup)
        print(f"  [enroll] Previous DB backed up to {backup.name}")
    except OSError:
        pass
    return ProfileDB()
```

`[VERIFIED: src/enroll.py lines 48-61]` — No change needed here. Bumping `PROFILE_SCHEMA_VERSION` to 3 in `config.py` activates this logic automatically for any v2 pickle on disk.

### Profile Key Convention

| Speaker type | Key format | Example |
|---|---|---|
| Known politician (roster match) | `essentials:<politician_slug>` | `essentials:isabel-piedmont-smith` |
| Non-roster speaker (local) | `<lastname>_<firstname>` | `smith_john` |

The colon in `essentials:` is deliberately namespace-separating — it cannot appear in a local slug (which uses underscores). No collision risk. `[ASSUMED]` — based on Python dict key behavior, not an API contract; verify no existing local slug inadvertently contains "essentials:".

### New Helper: resolve_enrollment_key()

The core new logic is a function that, given a speaker's display name and a loaded `Roster`, returns either an essentials key + identity fields or falls back to the existing local-slug path:

```python
def resolve_enrollment_key(
    display_name: str,
    roster: Optional[Roster],
) -> tuple[str, Optional[str], Optional[str]]:
    """Return (profile_key, politician_slug, politician_id).

    If display_name matches a roster member: key = 'essentials:<politician_slug>',
    politician_slug and politician_id from roster entry.
    Otherwise: key = _name_to_slug(display_name), both identity fields None.
    """
```

The roster cache JSON already carries `politician_slug` and `politician_id` on every member (verified in `refresh_roster.py` `_build_cache_payload()` and the conftest fixture). `[VERIFIED: CouncilScribe/refresh_roster.py lines 39-46, tests/conftest.py lines 62-78]`

The matching logic reuses `correct_speaker_name()` from `src/roster.py` — if it returns a different (corrected) name, the speaker is a roster member. But `correct_speaker_name()` returns a canonical *name*, not a `politician_slug`. Therefore `resolve_enrollment_key()` must also look up the matching member's `politician_slug` and `politician_id` from the per-body roster JSON (not from the `Roster` dataclass, which only carries `name` and `aliases`).

**Design decision (for planner):** Either (a) enrich `RosterMember` to carry `politician_slug` and `politician_id`, or (b) load the raw roster JSON alongside the `Roster` object in the enrollment paths that need identity data. Option (a) is cleaner but touches `src/roster.py`. Option (b) is lower-risk for the existing test suite. Both are valid — planner decides.

`[ASSUMED]` — the cleanest approach is (a): extend `RosterMember` with `politician_slug: Optional[str] = None` and `politician_id: Optional[str] = None`, and populate them in `load_roster(body_slug=...)`. The `Roster` dataclass is already in `src/roster.py` and importing from it in `enroll.py` is already done (`fix_profiles_with_roster` does it). Planner may confirm or override.

### Enrollment Path Updates

**Path 1: `enroll_speakers()` in `src/enroll.py`** — called from `run_local.py` Stage 6 (ENROLLED):

Current signature:
```python
def enroll_speakers(
    db: ProfileDB,
    speaker_embeddings: dict[str, np.ndarray],
    mappings: dict[str, SpeakerMapping],
    meeting_id: str,
    segments: list[Segment],
) -> ProfileDB:
```

Add `roster: Optional[Roster] = None` parameter. Inside, replace `slug = _name_to_slug(mapping.speaker_name)` with a call to `resolve_enrollment_key(mapping.speaker_name, roster)` to get key + identity fields. Pass identity fields into `_enroll_one`.

**Path 2: `reenroll_profiles.py`** — standalone script:

Per CSPROFILE-04, the re-enrollment script must:
1. Read `pipeline_state.json` from each meeting dir to get `body_slug` — `PipelineState` is already importable from `src.checkpoint`. `[VERIFIED: src/checkpoint.py line 35]`
2. Call `load_roster(body_slug=body_slug)` for each body.
3. Pass the `Roster` into `enroll_speakers()` (or its new signature) so matches get promoted.
4. When no `body_slug` is persisted for a meeting, fall back to `load_roster()` (legacy) — or enroll with `roster=None` (local slugs only). The REQUIREMENTS.md does not require back-filling old untagged meetings; planner decides whether to warn or silently use local keys.

**`_enroll_one()` extension** — add `politician_slug` and `politician_id` parameters (both defaulting `None`), set them on the profile object during creation and update on merge if the profile is being promoted from a local key to a politician key for the first time.

### Profile Key Promotion Scenario

When re-enrolling against a meeting, a speaker enrolled in a previous meeting under a local slug (`piedmont_smith_isabel`) may now match as `essentials:isabel-piedmont-smith`. The current `_enroll_one` will see the essentials key as new and create a fresh profile — the old local-keyed profile still exists with its accumulated embeddings.

This creates a split: one profile under a local slug with old embeddings, one under an essentials slug with new embeddings. CSPROFILE-05 requires accumulation under the politician key, but it is CSPROFILE-04 specifically that says "promote matches to essentials keys during re-enrollment." The requirement does NOT say "merge any pre-existing local-slug profile" — that is a future "Profile merge tooling" item listed in REQUIREMENTS.md §"Future Requirements (Deferred)".

**Implication for planner:** The re-enrollment run will create `essentials:<slug>` profiles for each matched speaker, starting from scratch. Existing `adams_jane`-style local profiles left over from earlier meetings are simply not touched. This is correct behavior per the spec. Tests should confirm the old local profile remains and the essentials profile is new (not a merge).

`[VERIFIED: REQUIREMENTS.md Future Requirements section — "Profile merge tooling driven by essentials identity" is explicitly deferred]`

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Speaker name → roster member match | Custom fuzzy string match | `correct_speaker_name()` from `src/roster.py` — already handles exact, alias, substring, and fuzzy matching with configurable threshold |
| Per-body roster loading | Direct JSON file reads | `load_roster(body_slug=...)` from `src/roster.py` — already handles slug path, staleness warning, and missing-file None return |
| Pipeline state persistence | Direct JSON writes | `PipelineState` from `src/checkpoint.py` — atomic tempfile+replace, body_slug attribute already present |
| Alias generation | Custom logic | `generate_aliases()` from `src/alias_gen.py` — already handles hyphen/space, accent folding, title stripping |

---

## Common Pitfalls

### Pitfall 1: Pickle deserialization with new optional fields

**What goes wrong:** Adding `politician_slug: Optional[str] = None` as a dataclass field with a default value works fine for *new* instances, but a pickled v2 `StoredProfile` object will deserialize without the new fields present on the instance — Python pickle does not call `__init__` on deserialization, it reconstructs `__dict__` directly. Accessing `profile.politician_slug` on a v2-deserialized object will raise `AttributeError`.

**Why it happens:** pickle restores `__dict__`, not `__init__`. Dataclass defaults only populate during `__init__`.

**How to avoid:** The auto-discard-on-version-mismatch pattern prevents this entirely — a v2 DB is discarded before any `StoredProfile` objects are accessed. As long as `PROFILE_SCHEMA_VERSION` is bumped to 3 before any code reads `politician_slug`, no v2 profile will survive into active use. `[VERIFIED: src/enroll.py lines 48-61]`

**Warning signs:** `AttributeError: 'StoredProfile' object has no attribute 'politician_slug'` in tests that construct a `StoredProfile` without the new fields. Ensure any directly constructed `StoredProfile` in tests passes the new optional fields or uses `field(default=None)`.

### Pitfall 2: Roster lookup only available at enrollment time, not at match time

**What goes wrong:** `match_voice_profiles()` in `src/identify.py` uses the profile key (e.g., `essentials:isabel-piedmont-smith`) as the match result's `speaker_name`. The `SpeakerMapping.speaker_name` will be the essentials key string, not a human-readable name, unless special handling is added.

**Why it happens:** Layer 1 returns `best_name = profile_id` which is the profile dict key. With v3 keys like `essentials:isabel-piedmont-smith`, downstream display (transcript output) would show the raw key string.

**How to avoid:** The `StoredProfile.display_name` field carries the human-readable name. When Layer 1 produces a match against an `essentials:` key, the display name should be fetched from the profile DB. Check how `run_local.py` translates Layer 1 results to display names — this is downstream of Phase 110 but the planner should document the data flow implication so Phase 111 doesn't hit this unexpectedly.

`[ASSUMED]` — this is a risk based on code reading; the planner should trace `match_voice_profiles` output through to `SpeakerMapping.speaker_name` usage in `run_local.py` Stage 4 output generation and confirm display_name is used correctly.

### Pitfall 3: `reenroll_profiles.py` doesn't import `PipelineState`

**What goes wrong:** The re-enrollment script currently imports only `src.config`, `src.diarize`, `src.enroll`, and `src.models`. It will need to also import `src.checkpoint.PipelineState` to read `body_slug` from each meeting's `pipeline_state.json`.

**Why it happens:** Phase 109 added `body_slug` to `PipelineState` — `reenroll_profiles.py` predates that and has no awareness of it.

**How to avoid:** Add `from src.checkpoint import PipelineState` in `reenroll_profiles.py` and replace the manual `meeting_dir` traversal with `PipelineState(meeting_dir).body_slug` to get the body slug. `[VERIFIED: src/checkpoint.py line 35 — body_slug attribute confirmed]`

### Pitfall 4: Roster not available for every meeting during re-enrollment

**What goes wrong:** Some meetings in the directory may be untagged (no `body_slug` in their `pipeline_state.json`) because they were processed before Phase 109. The re-enrollment script iterates all meetings with `transcript_named.json`.

**Why it happens:** Phase 109 preserves legacy untagged meetings (D-05); these will have `body_slug = None`.

**How to avoid:** When `body_slug` is None, call `enroll_speakers(... roster=None)` so untagged meeting speakers fall through to local-slug keying. This is backward-compatible behavior. The test for CSPROFILE-04 should cover the case where a meeting has no `body_slug` and confirm local slugs are used.

### Pitfall 5: `enroll_confirmed()` also uses `_name_to_slug()` and needs updating

**What goes wrong:** There are two enrollment entry points: `enroll_speakers()` (auto/batch) and `enroll_confirmed()` (interactive, called for borderline speakers). Both call `_name_to_slug()` to derive the key. If only `enroll_speakers()` is updated to use `resolve_enrollment_key()`, interactively confirmed roster members will still enroll under local slugs.

**Why it happens:** `enroll_confirmed()` at `src/enroll.py` lines 291-310 is a separate function with identical slug derivation logic.

**How to avoid:** Apply the same `resolve_enrollment_key()` change to `enroll_confirmed()`. This may be lower urgency (interactive enrollment typically happens during a live meeting run, where a roster is available), but it should be included for correctness.

`[VERIFIED: src/enroll.py lines 291-310]`

---

## Code Examples

### Pattern: Auto-discard on schema version mismatch (existing, replicate exactly)

```python
# src/enroll.py — load_profiles(), lines 48-61
# Source: VERIFIED by direct file read
stored_version = getattr(db, "schema_version", 1)
if stored_version != config.PROFILE_SCHEMA_VERSION:
    print(
        f"  [enroll] Profile DB schema v{stored_version} incompatible with "
        f"current v{config.PROFILE_SCHEMA_VERSION} (embedding model changed). "
        f"Discarding {len(db.profiles)} stale profile(s); re-enroll from fresh meetings."
    )
    backup = path.with_suffix(f".v{stored_version}.pkl.bak")
    try:
        path.rename(backup)
        print(f"  [enroll] Previous DB backed up to {backup.name}")
    except OSError:
        pass
    return ProfileDB()
```

The v2→v3 bump requires zero changes to this code — only `config.PROFILE_SCHEMA_VERSION` needs to go from 2 to 3.

### Pattern: Reading body_slug from a meeting's PipelineState

```python
# reenroll_profiles.py — new addition
from src.checkpoint import PipelineState

state = PipelineState(meeting_dir)   # reads pipeline_state.json
body_slug = state.body_slug          # None for untagged legacy meetings
```

### Pattern: Per-body roster in re-enrollment loop

```python
# reenroll_profiles.py — updated meeting loop
from src.roster import load_roster

for meeting_dir in meetings:
    state = PipelineState(meeting_dir)
    roster = load_roster(body_slug=state.body_slug) if state.body_slug else load_roster()
    # pass roster into enroll_speakers (updated signature)
```

### Pattern: Roster cache shape (confirmed)

```json
// ~/CouncilScribe/config/rosters/bloomington-common-council.json
// Source: VERIFIED tests/fixtures/bloomington_roster_response.json + refresh_roster.py
{
  "body_key": "Bloomington Common Council",
  "body_slug": "bloomington-common-council",
  "fetched_at": "2026-04-11T12:00:00Z",
  "politicians": [
    {
      "politician_slug": "isabel-piedmont-smith",
      "politician_id": "uuid-ips",
      "full_name": "Isabel Piedmont-Smith",
      "preferred_name": "Isabel",
      "title": "Councilmember",
      "district_label": "District 5",
      "aliases": ["Isabel Piedmont-Smith", "Piedmont-Smith", ...]
    }
  ]
}
```

---

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `~/CouncilScribe/profiles/speaker_profiles.pkl` — a v2 ProfileDB with profiles keyed by local slugs (e.g., `piedmont_smith_isabel`, `rowley_*`, `piemont_smith_*` — see councilscribe.md memory). | On first run with v3 code, `load_profiles()` detects version mismatch, backs up as `.v2.pkl.bak`, returns empty DB. Operator re-runs `reenroll_profiles.py` to rebuild with v3 essentials keys. No data migration script needed — auto-discard pattern handles it. |
| Live service config | None (CouncilScribe is a local CLI tool, not a running service). | None |
| OS-registered state | None | None |
| Secrets/env vars | `HF_TOKEN` / `HUGGINGFACE_TOKEN` in `.env.local` — code rename only, HF_TOKEN key is unchanged. `reenroll_profiles.py` already reads it. | None |
| Build artifacts | `.venv/` — 60 tests green, no stale install artifacts from this phase's changes (no pyproject.toml rename). | None |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pytest (installed in `.venv`) |
| Config file | `CouncilScribe/pytest.ini` |
| Quick run command | `.venv/bin/pytest tests/test_profile_v3.py -x -q` |
| Full suite command | `.venv/bin/pytest tests/ -q` |

60 tests currently green. Phase 110 adds a new test module.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CSPROFILE-01 | Load v2 pickle: auto-discard, backup created, return empty DB | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_v2_auto_discard -x -q` | No — Wave 0 |
| CSPROFILE-01 | New `StoredProfile` has `politician_slug` and `politician_id` fields defaulting None | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_stored_profile_v3_fields -x -q` | No — Wave 0 |
| CSPROFILE-01 | `ProfileDB.schema_version` == 3 | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_profile_db_schema_version -x -q` | No — Wave 0 |
| CSPROFILE-02 | Enroll roster-matched speaker: key is `essentials:<slug>`, fields populated | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_enroll_roster_member_uses_essentials_key -x -q` | No — Wave 0 |
| CSPROFILE-02 | `StoredProfile.politician_slug` and `politician_id` match roster member after enroll | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_essentials_profile_identity_fields -x -q` | No — Wave 0 |
| CSPROFILE-03 | Non-roster speaker enrolls under local slug, not `essentials:` prefix | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_non_roster_speaker_local_slug -x -q` | No — Wave 0 |
| CSPROFILE-03 | Essentials-keyed and local-keyed profiles coexist in same DB | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_mixed_profiles_coexist -x -q` | No — Wave 0 |
| CSPROFILE-04 | `reenroll_profiles.py` reads `body_slug` from `pipeline_state.json` | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_reads_body_slug -x -q` | No — Wave 0 |
| CSPROFILE-04 | `reenroll_profiles.py` promotes roster-matched speaker to `essentials:` key | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_promotes_to_essentials_key -x -q` | No — Wave 0 |
| CSPROFILE-04 | `reenroll_profiles.py` falls back to local slug for untagged meetings | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_reenroll_untagged_meeting_local_slug -x -q` | No — Wave 0 |
| CSPROFILE-05 | Re-enrolling same politician in a second meeting adds embeddings to existing essentials profile | unit | `.venv/bin/pytest tests/test_profile_v3.py::test_essentials_profile_accumulates_across_meetings -x -q` | No — Wave 0 |

### Wave 0 Gaps

- `tests/test_profile_v3.py` — covers all 11 test functions above
- Fixtures: use existing `fake_roster_cache` and `tmp_config_dir` from `tests/conftest.py` — no new fixtures needed for most tests. A `fake_v2_profile_db` fixture will be needed for CSPROFILE-01 auto-discard test (must construct a v2 `ProfileDB`, pickle it to a tempfile, then verify `load_profiles()` discards it).

### Sampling Rate

- Per task commit: `.venv/bin/pytest tests/test_profile_v3.py -x -q`
- Per wave merge: `.venv/bin/pytest tests/ -q`
- Phase gate: Full suite (60 + ~11 new = 71) green before `/gsd-verify-work`

---

## Open Questions

1. **Where does `politician_slug`/`politician_id` live on `RosterMember`?**
   - What we know: `RosterMember` currently only has `name` and `aliases`. The essentials identity fields are in the raw roster JSON. `correct_speaker_name()` returns a canonical name string — it cannot return a slug.
   - What's unclear: Should `RosterMember` be extended, or should `resolve_enrollment_key()` do a second lookup against the raw roster JSON?
   - Recommendation: Extend `RosterMember` with `politician_slug: Optional[str] = None` and `politician_id: Optional[str] = None` in `src/roster.py`, populate from the per-body cache in `load_roster(body_slug=...)`. This is the cleanest path. Planner should confirm this is acceptable scope for `src/roster.py` in Phase 110.

2. **What happens to profile display_name resolution when Layer 1 matches an `essentials:` key?**
   - What we know: `match_voice_profiles()` in `src/identify.py` returns `speaker_name = best_name` where `best_name` is the profile dict key. With v3, that key is `essentials:isabel-piedmont-smith`.
   - What's unclear: Does the `run_local.py` Stage 4 output pipeline use `speaker_name` directly for `transcript_named.json` display, or does it look up `display_name` from the profile? If the former, `transcript_named.json` will show raw `essentials:` keys in speaker fields — which is undesirable.
   - Recommendation: This is a Phase 111 concern (CSIDENT-04 is explicitly about the full identification output chain), but Phase 110 should be aware of the display_name implication. Planner should note that `StoredProfile.display_name` carries the human-readable name and the identify layer or Stage 4 writer will need to resolve it.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The colon in `essentials:` key prefix cannot appear in a local slug (collision-safe) | Architecture Patterns: Profile Key Convention | Low — local slugs use `_name_to_slug()` which produces `lastname_firstname` with no colons. Risk is negligible. |
| A2 | Enriching `RosterMember` with `politician_slug`/`politician_id` is the cleanest approach | Architecture Patterns: resolve_enrollment_key() | Medium — touching `src/roster.py` adds a dependency change. Planner may prefer the raw-JSON-lookup alternative. |
| A3 | Phase 109 H-01 gap is already fixed in `checkpoint.py` | Summary | Low — verified by reading the current file; fix is present. |
| A4 | `enroll_confirmed()` should also use `resolve_enrollment_key()` | Common Pitfalls #5 | Medium — omitting it means interactive borderline-enrollment of roster members still uses local keys. Functionally a bug but lower urgency than the auto-enroll path. |
| A5 | Untagged meeting re-enrollment should silently use local keys (no warning) | Architecture Patterns: reenroll path | Low — REQUIREMENTS.md CSPROFILE-04 says "match each transcript_named.json speaker name to the roster for that meeting's body." If there's no body, there's no roster, so local keys are the only option. |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python venv (.venv) | All tests | Yes | 3.13 | — |
| pytest | Test runner | Yes | installed | — |
| numpy | Profile embeddings | Yes | installed | — |
| HF_TOKEN | `reenroll_profiles.py` embedding extraction | Yes (in .env.local per memory) | — | — |
| `~/CouncilScribe/profiles/speaker_profiles.pkl` | v2→v3 auto-discard test | Yes (v2 DB exists from Phase 109 baseline) | v2 | Auto-discarded on v3 load |
| `~/CouncilScribe/config/rosters/bloomington-common-council.json` | Re-enrollment integration | May need refresh | Phase 108/109 built it | `refresh_roster.py --body bloomington-common-council` |

---

## Security Domain

This phase is a local CLI tool operating on files in the user's home directory. It has no network endpoints, no authentication, and no user-supplied data paths. Security enforcement is not applicable to this phase.

---

## Sources

### Primary (HIGH confidence — verified by direct file read)

- `CouncilScribe/src/enroll.py` — current v2 `StoredProfile`, `ProfileDB`, `load_profiles()`, `enroll_speakers()`, `_enroll_one()`, `enroll_confirmed()`
- `CouncilScribe/src/config.py` — `PROFILE_SCHEMA_VERSION = 2`, `PROFILES_DIR`, `PROFILE_DB_FILENAME`
- `CouncilScribe/src/checkpoint.py` — `PipelineState.body_slug` (line 35), `rewind_for_retag()` (lines 71-95)
- `CouncilScribe/src/roster.py` — `RosterMember`, `Roster`, `load_roster(body_slug=...)`, `correct_speaker_name()`
- `CouncilScribe/src/models.py` — `SpeakerMapping`, `Segment` dataclasses
- `CouncilScribe/reenroll_profiles.py` — current re-enrollment script, imports, main() flow
- `CouncilScribe/refresh_roster.py` — `_build_cache_payload()` confirming `politician_slug`/`politician_id` persisted in roster cache
- `CouncilScribe/tests/conftest.py` — existing fixtures (`fake_roster_cache`, `tagged_meeting_dir`, politician sample fixtures)
- `CouncilScribe/tests/fixtures/bloomington_roster_response.json` — confirmed roster JSON shape
- `.planning/REQUIREMENTS.md` — CSPROFILE-01 through CSPROFILE-05 authoritative wording
- `.planning/phases/109-per-meeting-body-tagging/109-CONTEXT.md` — Phase 109 decisions and confirmed outputs
- `.planning/phases/109-per-meeting-body-tagging/109-VERIFICATION.md` — Phase 109 gap status (H-01 now fixed)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all existing libraries verified in codebase
- Architecture: HIGH — full source reading of all affected files; patterns verified directly
- Pitfalls: HIGH for pickle/dataclass issues (well-understood Python behavior); MEDIUM for display_name downstream impact (requires Phase 111 tracing)
- Test map: HIGH — mirrors existing Phase 108/109 test conventions exactly

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (stable domain — CouncilScribe local CLI, no external API changes)
