# Phase 111: Live Roster Drives Identification — Research

**Researched:** 2026-04-12
**Domain:** CouncilScribe speaker identification pipeline (Layer 2 pattern matcher, Layer 3 LLM prompt, SpeakerMapping output)
**Confidence:** HIGH — all findings verified by direct codebase inspection

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CSIDENT-01 | `correct_speaker_name` uses the live (fetched) roster's politician names and aliases — phantoms disappear from identification output | `correct_speaker_name` already does fuzzy matching; the gap is that `apply_pattern_matching` creates unchecked mappings that bypass roster validation before `correct_mappings` runs |
| CSIDENT-02 | Layer 2 pattern matcher rejects name matches whose surname doesn't fuzzy-match any active roster member (above a configurable threshold) | `apply_pattern_matching` has no roster parameter today; needs roster passed in + a surname check that returns `None` (discards) if no roster member matches above threshold |
| CSIDENT-03 | Layer 3 LLM prompt receives the live roster as context (including district labels for disambiguation) | `roster_names_for_prompt()` returns names only; `RosterMember` lacks `district_label`; both need updating |
| CSIDENT-04 | `SpeakerMapping` records `politician_slug` alongside `speaker_name`; downstream `transcript_named.json` carries essentials linkage | `SpeakerMapping` dataclass has no `politician_slug`/`politician_id` fields; `correct_mappings` doesn't populate them; `SpeakerMapping.to_dict()` doesn't emit them |
</phase_requirements>

---

## Summary

Phase 111 is the final integration phase in the v2026.4.2 milestone. All upstream plumbing is in place: the essentials roster endpoint (Phase 107), the roster client + cached per-body rosters (Phase 108), body-slug tagging flowing through pipeline state (Phase 109), and voice profiles keyed by `politician_slug` (Phase 110). Phase 111 connects the live roster data to the identification logic itself.

There are four concrete gaps to close, each mapping 1:1 to a CSIDENT requirement. Two are data-model gaps (`RosterMember.district_label` and `SpeakerMapping.politician_slug`/`politician_id`). One is a missing parameter + validation in the Layer 2 pattern matcher (`apply_pattern_matching` needs a roster argument and surname-rejection logic). One is a text format upgrade in `roster_names_for_prompt` to include district labels.

Because the model changes (`SpeakerMapping` fields) affect `to_dict`/`from_dict`, the `transcript_named.json` schema gains two optional fields — this is backward compatible (old readers ignore unknown keys; new readers return `None` for absent keys).

**Primary recommendation:** Implement all four changes in a single plan with TDD — the changes are tightly coupled (the roster flows from Layer 2 validation through to SpeakerMapping output), and keeping them in one plan avoids a partial-state where mappings have `politician_slug` but the pattern matcher still emits phantom names.

---

## Architecture Patterns

### Current Identification Flow (verified)

```
Stage 4 run_local.py
│
├── load_roster(body_slug=effective_body_slug)     # Phase 109: body-specific roster
│   └── returns Roster{members=[RosterMember(name, aliases, politician_slug, politician_id)]}
│
├── identify_speakers(segments, speaker_embeddings,
│       stored_profiles, llm_identify_fn, roster, profile_db)
│   │
│   ├── Layer 1: match_voice_profiles(...)
│   │   └── returns {label -> SpeakerMapping(speaker_label, speaker_name, confidence, id_method)}
│   │
│   ├── Layer 2: apply_pattern_matching(segments)          # NO roster parameter today
│   │   └── regex patterns fire, returns raw transcript names (phantoms pass through)
│   │
│   ├── Layer 3: llm_identify_fn(segments, mappings)
│   │   └── llm_identify_speakers(..., roster_hint=roster_hint)
│   │       where roster_hint = roster_names_for_prompt(roster)
│   │           = "Known council members for this body: Name1, Name2, ..."
│   │           (NO district labels today)
│   │
│   └── correct_mappings(mappings, roster)                 # roster-corrects names in place
│       └── does NOT populate politician_slug on SpeakerMapping
│
├── apply_mappings_to_segments(segments, mappings)
│   └── copies speaker_name/confidence/id_method to segments
│
└── json.dump(meeting.to_dict(), named_transcript_path)
    └── SpeakerMapping.to_dict() emits: speaker_label, speaker_name, confidence,
        id_method, needs_review
        (NO politician_slug today)
```

### Required Changes

The four required changes are:

1. **`RosterMember` — add `district_label` field** (`src/roster.py`)
   - `load_roster(body_slug=...)` already reads `district_label` from the per-body cache JSON (it's in the fixture and in the Phase 107 API response shape), but does not store it on `RosterMember`
   - Needed by `roster_names_for_prompt` for CSIDENT-03

2. **`roster_names_for_prompt` — include district labels** (`src/roster.py`)
   - Current: `"Known council members for this body: Name1, Name2"`
   - Target: each member formatted as `"Name (District)" or "Name"` when district absent
   - Example: `"Known council members for this body:\n- Councilmember Piedmont-Smith (District 5)\n- Council President Asare (At-Large)"`
   - The LLM uses this to disambiguate speakers by district when names or roles overlap

3. **`apply_pattern_matching` — add roster parameter + surname rejection** (`src/identify.py`)
   - Signature change: `apply_pattern_matching(segments, roster=None)`
   - After a name is extracted and passes `_is_plausible_name`, add:
     ```python
     if roster is not None and not _surname_matches_roster(name, roster, threshold=config.ROSTER_SURNAME_THRESHOLD):
         continue  # discard — surname not in live roster
     ```
   - `_surname_matches_roster(name, roster, threshold)` extracts surname from `name`, then fuzzy-matches against all aliases of all roster members using `difflib.SequenceMatcher` (already used in `roster.py`), returning `True` if any match >= threshold
   - The threshold belongs in `config.py` as a new constant: `ROSTER_SURNAME_THRESHOLD = 0.80`
   - Call-site in `identify_speakers` changes: `apply_pattern_matching(segments, roster=roster)`

4. **`SpeakerMapping` — add `politician_slug` and `politician_id` fields** (`src/models.py`)
   - Add optional fields: `politician_slug: Optional[str] = None` and `politician_id: Optional[str] = None`
   - Update `to_dict()` to include them when non-None (same pattern used for `speaker_name`, `confidence`, `id_method`)
   - Update `from_dict()` to read them via `.get()` defaulting to None
   - Update `correct_mappings()` in `roster.py` to populate these fields when a match is found: after correcting `mapping.speaker_name`, look up the matching `RosterMember` and copy `politician_slug`/`politician_id` to the mapping

### Anti-Patterns to Avoid

- **Changing the Layer 3 LLM model or prompt structure:** The LLM change is additive — the `roster_hint` string passed to `prompt_for_speaker_id` already formats into the prompt. Only the content of that string changes (adds district labels). Do not restructure the prompt format.
- **Filtering in `correct_mappings` instead of `apply_pattern_matching`:** The requirement says the Layer 2 pattern matcher rejects non-roster names. `correct_mappings` is a post-hoc correction, not a rejection gate. The rejection must happen inside `apply_pattern_matching` so the bad mapping is never created.
- **Requiring a roster in `apply_pattern_matching`:** The function must still work without a roster (when no body is tagged or the legacy path is active). The roster parameter must remain optional and the function must behave identically to current behavior when `roster=None`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fuzzy surname matching | Custom edit-distance implementation | `difflib.SequenceMatcher` (already imported in `roster.py`) | Already vendored, sufficient accuracy, no new dependency |
| District label formatting | Separate template engine | Inline f-string in `roster_names_for_prompt` | Simple enough for one-liner; consistency with current approach |

---

## Common Pitfalls

### Pitfall 1: `from_dict` backwards compatibility
**What goes wrong:** Adding `politician_slug` and `politician_id` to `SpeakerMapping.from_dict()` without `.get()` defaults causes `KeyError` when loading old `transcript_named.json` files that lack these keys.
**How to avoid:** Always use `d.get("politician_slug")` (returns None) — same pattern as `speaker_name`, `confidence`, `id_method` in the existing `from_dict`.

### Pitfall 2: `RosterMember.district_label` not populated for legacy roster path
**What goes wrong:** Adding `district_label` to `RosterMember` but only populating it in the slug path (per-body cache) means the legacy `council_roster.json` path creates members with `district_label=None`. This is acceptable — `roster_names_for_prompt` must handle None gracefully, omitting the district parenthetical.
**How to avoid:** `roster_names_for_prompt` should use `f" ({m.district_label})" if m.district_label else ""` in the format string.

### Pitfall 3: Pattern matcher rejecting legitimate names when roster isn't fresh
**What goes wrong:** Staff members, city attorneys, and other non-council speakers may appear in transcripts but are not in the council roster. If `apply_pattern_matching` rejects any name not in the roster, these legitimate identifications are discarded.
**How to avoid:** The requirement is specifically about Whisper hallucinations on uncommon SURNAMES. Apply the rejection only when the extracted name does NOT plausibly match any roster alias above the configured threshold. Non-roster speakers (public commenters, staff) will generally self-identify with a title pattern like "As the city attorney..." (the `title_context` pattern) which captures a role word, not a roster-unknown surname. The `_is_plausible_name` check already handles garbage. The rejection is a second gate, not a whitelist.

### Pitfall 4: `correct_mappings` not finding the `RosterMember` after name correction
**What goes wrong:** After `correct_speaker_name` corrects the name (returning the canonical member name), code tries to find the `RosterMember` by comparing `corrected == member.name`. This works for exact matches but may fail if there are subtle whitespace or case differences.
**How to avoid:** Use the same case-insensitive comparison already used in `correct_speaker_name` step 1: `corrected.lower() == member.name.lower()`.

### Pitfall 5: `apply_pattern_matching` signature change breaks `identify_speakers` call
**What goes wrong:** Adding `roster=None` to `apply_pattern_matching` while forgetting to thread `roster` through `identify_speakers`.
**How to avoid:** `identify_speakers` already receives a `roster` parameter (line 286 of `identify.py`). The internal call `apply_pattern_matching(segments)` must be updated to `apply_pattern_matching(segments, roster=roster)`.

---

## Code Examples

### Pattern 1: Adding `politician_slug` to `SpeakerMapping`

```python
# src/models.py — verified current state

@dataclass
class SpeakerMapping:
    speaker_label: str
    speaker_name: Optional[str] = None
    confidence: float = 0.0
    id_method: Optional[str] = None
    needs_review: bool = False
    politician_slug: Optional[str] = None   # ADD: essentials identifier
    politician_id: Optional[str] = None     # ADD: essentials UUID

    def to_dict(self) -> dict:
        d = {
            "speaker_label": self.speaker_label,
            "speaker_name": self.speaker_name,
            "confidence": self.confidence,
            "id_method": self.id_method,
            "needs_review": self.needs_review,
        }
        if self.politician_slug is not None:
            d["politician_slug"] = self.politician_slug
        if self.politician_id is not None:
            d["politician_id"] = self.politician_id
        return d

    @classmethod
    def from_dict(cls, d: dict) -> SpeakerMapping:
        return cls(
            speaker_label=d["speaker_label"],
            speaker_name=d.get("speaker_name"),
            confidence=d.get("confidence", 0.0),
            id_method=d.get("id_method"),
            needs_review=d.get("needs_review", False),
            politician_slug=d.get("politician_slug"),   # ADD
            politician_id=d.get("politician_id"),       # ADD
        )
```

### Pattern 2: `RosterMember` district_label field

```python
# src/roster.py — current RosterMember (verified)
@dataclass
class RosterMember:
    name: str
    aliases: list[str] = field(default_factory=list)
    politician_slug: Optional[str] = None
    politician_id: Optional[str] = None
    district_label: Optional[str] = None   # ADD

# In load_roster slug path (per-body cache), update the member construction:
slug_members.append(
    RosterMember(
        name=canonical,
        aliases=list(pol.get("aliases", [])),
        politician_slug=pol.get("politician_slug"),
        politician_id=pol.get("politician_id"),
        district_label=pol.get("district_label") or None,  # ADD; empty string -> None
    )
)
```

### Pattern 3: `roster_names_for_prompt` with district labels

```python
# src/roster.py — current (verified)
def roster_names_for_prompt(roster: Roster) -> str:
    if not roster or not roster.members:
        return ""
    names = [m.name for m in roster.members]
    return "Known council members for this body: " + ", ".join(names)

# Target:
def roster_names_for_prompt(roster: Roster) -> str:
    if not roster or not roster.members:
        return ""
    lines = []
    for m in roster.members:
        district = f" ({m.district_label})" if m.district_label else ""
        lines.append(f"- {m.name}{district}")
    return "Known council members for this body:\n" + "\n".join(lines)
```

### Pattern 4: `apply_pattern_matching` roster-gated surname rejection

```python
# src/identify.py — add helper + update signature

def _surname_matches_roster(name: str, roster, threshold: float) -> bool:
    """Return True if the extracted surname fuzzy-matches any roster member alias."""
    from difflib import SequenceMatcher
    from .roster import _extract_surname  # already exists in roster.py

    surname = _extract_surname(name)
    if not surname:
        return False
    for member in roster.members:
        for alias in member.aliases:
            alias_surname = _extract_surname(alias)
            score = SequenceMatcher(None, surname.lower(), alias_surname.lower()).ratio()
            if score >= threshold:
                return True
    return False


def apply_pattern_matching(
    segments: list[Segment],
    roster=None,               # ADD: optional Roster for surname gating (CSIDENT-02)
) -> dict[str, list[SpeakerMapping]]:
    # ... (existing code) ...
    # Inside the match loop, after _is_plausible_name check, add:
    if roster is not None and not _surname_matches_roster(name, roster, config.ROSTER_SURNAME_THRESHOLD):
        continue  # Discard — surname not in live roster
```

### Pattern 5: `correct_mappings` populates `politician_slug`

```python
# src/roster.py — current (verified)
def correct_mappings(mappings: dict, roster: Roster) -> dict:
    for label, mapping in mappings.items():
        if mapping.speaker_name:
            corrected = correct_speaker_name(mapping.speaker_name, roster)
            if corrected != mapping.speaker_name:
                mapping.speaker_name = corrected

    return mappings

# Target: after correcting name, look up the matching member and populate identity fields
def correct_mappings(mappings: dict, roster: Roster) -> dict:
    for label, mapping in mappings.items():
        if mapping.speaker_name:
            corrected = correct_speaker_name(mapping.speaker_name, roster)
            if corrected != mapping.speaker_name:
                mapping.speaker_name = corrected
            # Populate politician identity fields for any roster-matched speaker (CSIDENT-04)
            for member in roster.members:
                if corrected.lower() == member.name.lower() and member.politician_slug:
                    mapping.politician_slug = member.politician_slug
                    mapping.politician_id = member.politician_id
                    break
    return mappings
```

### Pattern 6: `config.py` new constant

```python
# src/config.py — add to Thresholds section
ROSTER_SURNAME_THRESHOLD = 0.80  # Layer 2 pattern match rejected if surname similarity below this
```

### Pattern 7: `identify_speakers` threads roster to Layer 2

```python
# src/identify.py — current Layer 2 call (line ~313, verified)
pattern_candidates = apply_pattern_matching(segments)

# Target:
pattern_candidates = apply_pattern_matching(segments, roster=roster)
```

---

## File-Level Change Map

| File | Change | Requirement |
|------|--------|-------------|
| `src/models.py` | Add `politician_slug`, `politician_id` to `SpeakerMapping`; update `to_dict` / `from_dict` | CSIDENT-04 |
| `src/roster.py` | Add `district_label` to `RosterMember`; populate in `load_roster` slug path; update `roster_names_for_prompt`; update `correct_mappings` to populate identity fields on mapping | CSIDENT-01, CSIDENT-03, CSIDENT-04 |
| `src/identify.py` | Add `_surname_matches_roster` helper; add `roster=None` to `apply_pattern_matching`; thread `roster=roster` in `identify_speakers` call to Layer 2 | CSIDENT-02 |
| `src/config.py` | Add `ROSTER_SURNAME_THRESHOLD = 0.80` | CSIDENT-02 |

No changes needed to `run_local.py` — the `roster` object already flows into `identify_speakers` (Phase 109 completed this). No changes needed to `llm_utils.py` — the `roster_hint` string is already passed to the LLM prompt; only the content of that string changes (via `roster_names_for_prompt`). No changes needed to `enroll.py`.

---

## Standard Stack

All existing — no new dependencies.

| Component | Version | Purpose |
|-----------|---------|---------|
| `difflib.SequenceMatcher` | stdlib | Fuzzy surname matching in `_surname_matches_roster` — already used in `roster.py` |
| Python `dataclasses` | stdlib | `SpeakerMapping` and `RosterMember` field additions |
| `pytest` | >=8 | TDD test harness (existing) |

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | pytest >= 8 |
| Config file | `CouncilScribe/pytest.ini` |
| Quick run command | `cd CouncilScribe && python3.13 -m pytest tests/test_identification.py -x -q` |
| Full suite command | `cd CouncilScribe && python3.13 -m pytest tests/ -x -q` |

(Python binary: found at `~/.pyenv` or system; pyc cache shows `cpython-313` so Python 3.13 is the active interpreter for this project's tests)

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File |
|--------|----------|-----------|------|
| CSIDENT-01 | `correct_speaker_name` called on pattern-matched name returns roster canonical or None | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-02 | Pattern matcher with roster: "Piafra" surname rejected; "Piedmont-Smith" accepted | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-02 | Pattern matcher without roster: behavior unchanged (no regression) | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-03 | `roster_names_for_prompt` includes district labels when `district_label` is set | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-03 | `roster_names_for_prompt` omits parenthetical when `district_label` is None | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-04 | `SpeakerMapping.to_dict()` includes `politician_slug` when set | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-04 | `SpeakerMapping.from_dict()` round-trips `politician_slug` / `politician_id` | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-04 | `correct_mappings` with roster populates `politician_slug` on matched mapping | unit | `tests/test_identification.py` (Wave 0 gap) |
| CSIDENT-01/02 | End-to-end: `identify_speakers` with phantom name produces no phantom in final mappings | integration | `tests/test_identification.py` (Wave 0 gap) |

### Wave 0 Gaps

- [ ] `tests/test_identification.py` — new test file covering all CSIDENT-* behaviors above
- No new fixtures needed — `conftest.py` already provides `fake_roster_cache` and `tagged_meeting_dir`; `_make_roster()` helper from `test_profile_v3.py` can be extracted to conftest or duplicated inline

---

## Environment Availability

Step 2.6: SKIPPED — this phase makes only code and test changes within the CouncilScribe Python project. No new external tools, services, or runtimes are introduced.

---

## Security Domain

No new authentication, session management, or cryptographic operations. The changes are internal data-model and logic changes.

### Applicable ASVS Categories

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V5 Input Validation | yes | `_surname_matches_roster` receives user-controlled text from Whisper transcription; `_is_plausible_name` + SequenceMatcher ratio provide bounded processing — no regex catastrophic backtracking introduced |
| All others | no | No auth, no session, no network calls, no cryptography in this phase |

---

## Open Questions

1. **`_extract_surname` is currently private to `roster.py`**
   - What we know: `_extract_surname` is defined in `roster.py` and used internally by `correct_speaker_name`. It needs to be called from `identify.py` for the surname rejection helper.
   - What's unclear: whether to export it (rename without underscore) or duplicate a small version inline in `identify.py`.
   - Recommendation: Make it public in `roster.py` (rename to `extract_surname`) and import it in `identify.py`. This is cleaner than duplication and the function is already tested indirectly through `correct_speaker_name` tests.

2. **Whether Layer 1 (voice profile) matches need `politician_slug` populated**
   - What we know: `match_voice_profiles` returns a `SpeakerMapping` with `speaker_name` = the profile key (e.g., `essentials:isabel-piedmont-smith`). CSIDENT-04 says "when a speaker is confidently matched to a politician (any layer)."
   - What's unclear: Should Layer 1 voice matches also get `politician_slug` populated? The profile key encodes the slug, but `SpeakerMapping.politician_slug` would be cleaner downstream.
   - Recommendation: Let `correct_mappings` handle this uniformly. After all layers run, `correct_mappings` runs against the roster and populates `politician_slug` for any mapping whose speaker_name matches a roster member. This covers Layer 1 (voice profile key resolves to a canonical name via roster correction), Layer 2 (pattern match name corrected and keyed), and Layer 3 (LLM-assigned name corrected and keyed). No per-layer changes needed.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `_extract_surname` being made public is sufficient for `identify.py` to use it without circular imports | Architecture Patterns | Import cycle `identify.py -> roster.py` already exists (roster.correct_mappings is imported in identify_speakers) — so this is safe [VERIFIED: identify.py line 328 already imports from .roster] |

All other claims are directly verified by reading the source files.

---

## Sources

### Primary (HIGH confidence — verified by direct codebase read)

- `CouncilScribe/src/identify.py` — full file read; `apply_pattern_matching`, `identify_speakers`, `SpeakerMapping` usage confirmed
- `CouncilScribe/src/models.py` — full file read; `SpeakerMapping` dataclass confirmed, no `politician_slug` field
- `CouncilScribe/src/roster.py` — full file read; `RosterMember`, `correct_speaker_name`, `correct_mappings`, `roster_names_for_prompt` all confirmed; `_extract_surname` confirmed private
- `CouncilScribe/src/enroll.py` — full file read; `StoredProfile.politician_slug` confirmed; `resolve_enrollment_key` confirmed
- `CouncilScribe/src/llm_utils.py` — full file read; `roster_hint` parameter confirmed passed to `prompt_for_speaker_id`; prompt format confirmed
- `CouncilScribe/src/config.py` — full file read; threshold constants confirmed; no `ROSTER_SURNAME_THRESHOLD` exists yet
- `CouncilScribe/run_local.py` lines 645–762 — Stage 4 confirmed; `correct_mappings`, `roster_hint`, `identify_speakers` call signatures confirmed
- `CouncilScribe/tests/test_profile_v3.py` — full file read; baseline 14 tests confirmed
- `CouncilScribe/tests/conftest.py` — full file read; fixtures confirmed
- `.planning/phases/110-profile-schema-v3-re-enrollment/110-02-SUMMARY.md` — Phase 110 completion confirmed (74/74 tests pass)

---

## Metadata

**Confidence breakdown:**
- File-level change map: HIGH — derived from direct reading of all affected files
- Architecture: HIGH — call graph traced in source
- Pitfalls: HIGH — derived from code reading, not speculation
- Test coverage: HIGH — existing test patterns confirmed; Wave 0 gap is a new test file

**Research date:** 2026-04-12
**Valid until:** 2026-05-12 (stable codebase; no external dependency changes expected)
