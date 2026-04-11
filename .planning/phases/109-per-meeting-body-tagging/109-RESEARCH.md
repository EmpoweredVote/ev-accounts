# Phase 109: Per-meeting body tagging — Research

**Researched:** 2026-04-11
**Domain:** CouncilScribe pipeline — per-meeting metadata persistence, argparse wiring, Stage 4 call-site updates, fail-fast guard
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** First run persists `body_slug=X` into per-meeting metadata. Subsequent runs read it back silently. Print `Body: <slug>` info line for operator visibility.
- **D-02:** Mismatched flag (`--body Y` when already tagged as X) is a hard error. Message tells operator to pass `--body X` or use `--force-retag`.
- **D-03:** `--force-retag` is the escape hatch to overwrite persisted `body_slug`.
- **D-04:** `--force-retag` rewinds `completed_stage` to `TRANSCRIBED` (stage 3 = value 3). Stages 4/5/6/7 re-run.
- **D-05:** No flag + no persisted slug → legacy `load_roster()` path unchanged, no warning.
- **D-06:** No flag + persisted slug → read from metadata silently; print `Body: <slug>` info line.
- **D-07:** Fail-fast guard (cached roster existence check) runs BEFORE Stage 1 banner, after argparse + state load/merge.
- **D-08:** Error to stderr, two lines, `sys.exit(2)`. Exact format:
  - Line 1: `ERROR: Body "<slug>" has no cached roster at ~/CouncilScribe/config/rosters/<slug>.json`
  - Line 2: `Run: python refresh_roster.py --body <slug>`
- **D-09:** Stale cache (>30 days) is non-blocking warning only — Phase 108 semantics preserved.
- **D-10:** Resume after cache delete fails fast identically to D-08.

### Claude's Discretion

- Whether `body_slug` lives on `PipelineState` or a new `meeting_meta.json` (constraints: atomic write, survives resume, readable before Stage 1 complete).
- Argparse wiring for `--body` and `--force-retag`, including batch propagation.
- Signature and location of `ensure_body_roster_cached` guard helper.
- How to thread `body_slug` through to `identify_speakers` / `correct_speaker_name` / LLM prompt.
- Test layout mirroring Phase 108 convention.

### Deferred Ideas (OUT OF SCOPE)

- `reenroll_profiles.py` body awareness (Phase 110 / CSPROFILE-04)
- `StoredProfile` politician_slug keys (Phase 110)
- Live-roster identification fidelity on real meetings (Phase 111)
- Per-row body slugs in batch CSV
- Auto-refresh of stale rosters from `run_local.py`
- Migration of existing untagged meetings
- Interactive confirmation for `--force-retag`
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CSMEETING-01 | Meeting metadata accepts `body_slug` field (stored in `pipeline_state.json` or new `meeting_meta.json`) | PipelineState extension is lowest-friction; 10-line change; atomic write already exists. |
| CSMEETING-02 | `run_local.py` accepts `--body` flag, records on first run, reads from metadata on subsequent; fails fast if slug has no cached roster | Exact argparse insertion point, guard location, and error format documented below. |
| CSMEETING-03 | Stage 4 loads body-specific roster for `correct_speaker_name`, pattern matching, and LLM prompt; no legacy fallback when body is tagged | All four call sites enumerated; pattern matching and LLM already accept `Roster` object; load once, thread through. |
</phase_requirements>

---

## Summary

Phase 109 threads a `body_slug` through CouncilScribe's pipeline so every meeting run declares which governing body it belongs to, that tag persists across invocations, and Stage 4 identification loads the body-specific cached roster rather than the legacy global one. The work is entirely within `run_local.py` (argparse, `run_pipeline`, `_run_batch`) and `src/checkpoint.py` (PipelineState extension). No changes are needed in `src/roster.py`, `src/identify.py`, or `src/llm_utils.py` — the existing APIs already accept a `Roster` object; Phase 109 just populates that object from the right cache file.

The three primary work items are: (1) extend `PipelineState` with a `body_slug` attribute that round-trips through the existing atomic JSON write; (2) add `--body` / `--force-retag` argparse flags and implement the D-01..D-06 resolve logic at the top of `run_pipeline`; (3) replace all four bare `load_roster()` calls inside `run_local.py` with the body-aware conditional call.

**Primary recommendation:** Extend `PipelineState` directly (option A). The atomic write infrastructure is already in place, the `_load()` / `save()` pair needs ~10 lines of new code, and having body_slug alongside `completed_stage` in one JSON file simplifies the resume logic — no file-ordering or race-condition concerns.

---

## 1. Call-Site Enumeration (CRITICAL)

All four `load_roster()` calls confirmed by grep. None of them currently pass `body_slug`. Every call inside `run_local.py` MUST be updated when a body is tagged.

### Site 1 — Line 568: Stage 4 main pipeline path (run_pipeline)

**Function:** `run_pipeline(args)`, the main pipeline execution function.

**Enclosing block:** Stage 4: Speaker Identification banner. Code path is reached on every non-checkpoint-skipped pipeline invocation. When `state.is_complete(PipelineStage.IDENTIFIED)` is True the code below line 568 still executes to load roster and build `roster_hint` (lines 568-571 run unconditionally before the checkpoint branch).

**Current code (lines 562-571):**
```python
from src.roster import load_roster, roster_names_for_prompt

named_transcript_path = meeting_dir / "transcript_named.json"
llm_partial_path = meeting_dir / "llm_partial_results.json"

# Load roster for name correction
roster = load_roster()
if roster:
    print(f"  Loaded council roster: {len(roster.members)} members ({roster.city} {roster.body})")
roster_hint = roster_names_for_prompt(roster) if roster else ""
```

**What it does:** Loads the roster unconditionally. `roster` is passed to `identify_speakers(roster=roster)` (line 608-614) and `roster_hint` flows into the LLM lambda (line 602-604).

**Required change:** Replace with:
```python
roster = load_roster(body_slug=effective_body_slug) if effective_body_slug else load_roster()
```

`effective_body_slug` is resolved earlier in `run_pipeline` (see section 3). The log line should reflect which path was taken.

**Consumer path summary:**
- `roster` → `identify_speakers(..., roster=roster)` (line 608-614) → `correct_mappings` inside `identify_speakers` (src/identify.py:327-329) → `correct_speaker_name` (src/roster.py:148)
- `roster_hint` → `llm_identify_speakers(llm, segs, maps, roster_hint=roster_hint)` (line 602-604) → LLM prompt injection

Both consumers accept a `Roster` object; no signature changes needed anywhere downstream.

---

### Site 2 — Line 1021: `_fix_transcripts()` — bulk transcript re-correction utility

**Function:** `_fix_transcripts()` — a standalone utility invoked via `--fix-transcripts` flag.

**Enclosing block:** Top of `_fix_transcripts`, loads a single global roster and applies it to every meeting directory's `transcript_named.json`.

**Current code (lines 1019-1025):**
```python
from src.roster import add_alias, correct_speaker_name, load_roster

roster = load_roster()
if not roster:
    print("No council roster found. Cannot fix transcripts.")
    print(f"  Create one at: {config.CONFIG_DIR / 'council_roster.json'}")
    sys.exit(1)
```

**Scope concern:** This function iterates over ALL meetings. In Phase 109, meetings may have different `body_slug` values (or none). The current code applies one global roster to all meetings, which was correct before Phase 109. After Phase 109, applying the legacy roster to a tagged meeting is technically incorrect but is NOT the core fix in this phase — the success criteria for CSMEETING-03 is about `run_pipeline` Stage 4 (the live pipeline), not the offline `_fix_transcripts` utility.

**Recommended treatment:** Phase 109 leaves `_fix_transcripts()` (line 1021) using the legacy `load_roster()` unchanged. The utility is not part of CSMEETING-03's scope. Add a comment noting this will be updated when Phase 110 / Phase 111 land. Document this explicitly in the PLAN as an acknowledged gap, not a bug.

---

### Site 3 — Line 1719: `--show-roster` utility command

**Function:** `main()`, inside the `if args.show_roster:` branch (lines 1716-1730).

**Enclosing block:** Utility command that prints the current roster and exits. Not called during pipeline execution.

**Current code (lines 1718-1729):**
```python
from src.roster import load_roster
roster = load_roster()
if not roster:
    print("No council roster found.")
    print(f"  Create one at: {config.CONFIG_DIR / 'council_roster.json'}")
else:
    print(f"Council Roster: {roster.city} {roster.body}")
    ...
```

**Analysis:** This utility is NOT reached during pipeline execution. It has no meeting context — there is no `meeting_id` or `meeting_dir` when `--show-roster` is invoked. It cannot meaningfully use `body_slug` without a meeting ID argument. Per CONTEXT.md's rule ("no code path loads the legacy roster when the running meeting is tagged"), this applies only to meeting-execution code paths, not to a utility that intentionally displays the legacy global roster.

**Recommended treatment:** Leave line 1719 as bare `load_roster()` in Phase 109. Optionally accept `--body` on `--show-roster` to also show a per-body roster, but that is discretionary enhancement, not required by any CSMEETING requirement. Document as acknowledged gap.

---

### Site 4 — Line 1749: `--fix-profiles` utility command

**Function:** `main()`, inside the `if args.fix_profiles:` branch (lines 1746-1768).

**Enclosing block:** Utility that renames stored voice profiles to match roster canonical names and exits.

**Current code (lines 1748-1752):**
```python
from src.roster import load_roster
roster = load_roster()
if not roster:
    print("No council roster found. Cannot fix profiles.")
    sys.exit(1)
```

**Analysis:** Like `--show-roster`, this utility has no meeting context. It loads the legacy roster to canonicalize profile names globally. CSMEETING-03 applies to Stage 4 pipeline execution, not to offline profile-management utilities.

**Recommended treatment:** Leave line 1749 as bare `load_roster()` in Phase 109. The profile schema is being redesigned in Phase 110 (CSPROFILE-01..04) which will update this code properly. Document as acknowledged gap.

---

### Summary Table

| Line | Function | Path | Phase 109 Update Required? |
|------|----------|------|---------------------------|
| 568 | `run_pipeline` | Stage 4 main pipeline | YES — core of CSMEETING-03 |
| 1021 | `_fix_transcripts` | `--fix-transcripts` utility | NO — offline utility, multi-meeting, leave for Phase 110/111 |
| 1719 | `main()` | `--show-roster` utility | NO — no meeting context, leave as is |
| 1749 | `main()` | `--fix-profiles` utility | NO — profile schema handled in Phase 110 |

**No missed call sites.** The grep confirmed exactly four `load_roster()` call sites in `run_local.py` (lines 562 import + 568 call, 1019 import + 1021 call, 1718 import + 1719 call, 1748 import + 1749 call). No other files in the repo call `load_roster()` except `src/roster.py` itself and test files. [VERIFIED: grep of CouncilScribe/*.py]

---

## 2. PipelineState Extension vs meeting_meta.json

### Current PipelineState Structure [VERIFIED: src/checkpoint.py]

```python
class PipelineStage(IntEnum):
    NOT_STARTED = 0
    INGESTED = 1
    DIARIZED = 2
    TRANSCRIBED = 3
    IDENTIFIED = 4
    SUMMARIZED = 5
    ENROLLED = 6
    EXPORTED = 7

class PipelineState:
    def __init__(self, meeting_dir: Path) -> None:
        self.meeting_dir = meeting_dir
        self._state_file = meeting_dir / "pipeline_state.json"
        self.completed_stage: PipelineStage = PipelineStage.NOT_STARTED
        self.transcription_progress: int = 0
        self.total_segments: int = 0
        self._load()
```

**Current serialized shape (`pipeline_state.json`):**
```json
{
  "completed_stage": 3,
  "transcription_progress": 47,
  "total_segments": 312
}
```

**Atomic write path (lines 45-62):** `tempfile.mkstemp` in `meeting_dir`, write JSON with `os.fdopen`, then `os.replace` to atomically rename. Exception handling removes the temp file on failure. This is the established pattern.

**`_load()` (lines 37-43):** Uses `data.get("completed_stage", 0)` etc. — defensively reads with `.get()`, so any new key with a default is backward-compatible with existing state files that don't have the key.

### Recommendation: Option A — Extend PipelineState [ASSUMED: preference; constraints from CONTEXT.md are verified]

**Rationale grounded in the code:**

1. The `_load()` method already uses `.get(key, default)` for every field (lines 41-43). Adding `self.body_slug = data.get("body_slug")` (defaulting to `None`) requires zero structural change to the deserialization logic and is backward-compatible with all existing `pipeline_state.json` files.

2. The `save()` method (lines 45-62) writes `data` dict then atomically renames. Adding `"body_slug": self.body_slug` (or omitting it when `None` to keep the file clean) is a one-line addition.

3. `PipelineState` is constructed very early in `run_pipeline` (line 231): `state = PipelineState(meeting_dir)`. The pre-Stage-1 guard (D-07) needs to read `body_slug` after state is loaded — if `body_slug` is on `PipelineState`, it's available immediately after construction, before any stage runs. No file-ordering problem.

4. The CONTEXT.md constraint "the value must survive checkpoint/resume identically" is satisfied because `pipeline_state.json` is already the resume document.

5. Option B (new `meeting_meta.json`) would require: a new write function with its own atomic-write implementation, a new load function, explicit ordering relative to `PipelineState` construction, and two JSON files to keep in sync. No advantage justifies this complexity.

**Exact field specification:**

```python
class PipelineState:
    def __init__(self, meeting_dir: Path) -> None:
        ...
        self.body_slug: Optional[str] = None   # NEW
        self._load()

    def _load(self) -> None:
        if self._state_file.exists():
            with open(self._state_file, "r") as f:
                data = json.load(f)
            self.completed_stage = PipelineStage(data.get("completed_stage", 0))
            self.transcription_progress = data.get("transcription_progress", 0)
            self.total_segments = data.get("total_segments", 0)
            self.body_slug = data.get("body_slug")   # NEW — None if absent

    def save(self) -> None:
        data = {
            "completed_stage": int(self.completed_stage),
            "transcription_progress": self.transcription_progress,
            "total_segments": self.total_segments,
        }
        if self.body_slug is not None:             # NEW
            data["body_slug"] = self.body_slug     # NEW
        # ... atomic write unchanged ...
```

**Backward compatibility:** Existing `pipeline_state.json` files without `"body_slug"` will load with `state.body_slug = None`, triggering the D-05 legacy fallback. No migration needed.

---

## 3. Argparse Wiring and Batch Propagation

### Current argparse block [VERIFIED: run_local.py:1633-1713]

The `main()` function builds a single `ArgumentParser` starting at line 1634. Existing flags relevant to understand the insertion point:

```python
parser.add_argument("--skip-llm", action="store_true", ...)   # line 1680
parser.add_argument("--skip-summary", action="store_true", ...)  # line 1683
parser.add_argument("--confirm-enroll", action="store_true", ...)  # line 1684
parser.add_argument("--no-merge", action="store_true", ...)  # line 1686
parser.add_argument("--use-vtt", action="store_true", ...)  # line 1688
```

**Insertion point for new flags:** After `--use-vtt` (line 1688), before the `# Utilities` comment block (line 1691). Both flags relate to pipeline execution behavior, not utilities.

**New flags to add:**
```python
parser.add_argument("--body", metavar="SLUG",
                    help="Governing body slug (e.g. bloomington-common-council). "
                         "Required on first run; read from metadata on subsequent runs.")
parser.add_argument("--force-retag", action="store_true",
                    help="Overwrite a previously persisted body_slug. "
                         "Rewinds pipeline to Stage 3 (TRANSCRIBED) and re-runs "
                         "Stages 4-7 against the new roster.")
```

Note: argparse stores `--force-retag` as `args.force_retag` (hyphen → underscore).

### `_run_batch` Namespace construction [VERIFIED: run_local.py:950-964]

The current `batch_args` Namespace is constructed at lines 950-964:

```python
batch_args = argparse.Namespace(
    input=entry["input"],
    date=entry["date"],
    city=entry["city"],
    meeting_type=entry["meeting_type"],
    meeting_id="",
    num_speakers=0,
    noise_reduce=False,
    skip_llm=args.skip_llm if hasattr(args, "skip_llm") else False,
    skip_summary=True,  # skip summary in batch mode
    confirm_enroll=False,
    no_merge=args.no_merge if hasattr(args, "no_merge") else False,
    pre_identify=False,
    use_vtt=args.use_vtt if hasattr(args, "use_vtt") else False,
)
```

**Fields to add:**
```python
body=args.body if hasattr(args, "body") else None,
force_retag=args.force_retag if hasattr(args, "force_retag") else False,
```

The `hasattr` guard pattern is already used for `skip_llm`, `no_merge`, and `use_vtt` — use the same pattern for consistency. This propagates a global `--body` to every meeting in the batch.

### `run_pipeline` body_slug resolve logic

`run_pipeline(args)` starts at line 197. The `PipelineState` is constructed at line 231. The guard and resolve logic must be inserted between line 231 (state constructed) and line 253 (Stage 1 banner printed).

There is currently NO existing `args.body` reference anywhere in `run_pipeline` or `_run_batch`. [VERIFIED: grep of run_local.py]

**Insertion point (after line 246 "Resuming from checkpoint" block, before line 248 `num_speakers` assignment):**

```python
# --- Body slug resolution (D-01..D-06) ---
effective_body_slug: Optional[str] = None

arg_body = getattr(args, "body", None)
force_retag = getattr(args, "force_retag", False)

if arg_body and state.body_slug and arg_body != state.body_slug and not force_retag:
    # D-02: mismatch is hard error
    print(f"ERROR: Meeting already tagged as body \"{state.body_slug}\". "
          f"Pass --body {state.body_slug} or use --force-retag to change it.",
          file=sys.stderr)
    sys.exit(2)

if arg_body and force_retag and state.body_slug and arg_body != state.body_slug:
    # D-03/D-04: overwrite + rewind
    state.body_slug = arg_body
    state.completed_stage = PipelineStage.TRANSCRIBED
    state.save()
    effective_body_slug = arg_body
elif arg_body:
    # D-01: first run or same slug re-passed
    state.body_slug = arg_body
    state.save()
    effective_body_slug = arg_body
else:
    # D-05 / D-06: read from metadata (may be None for legacy meetings)
    effective_body_slug = state.body_slug

if effective_body_slug:
    print(f"  Body: {effective_body_slug}")

# --- Pre-Stage-1 guard (D-07) ---
if effective_body_slug:
    _ensure_body_roster_cached(effective_body_slug)
```

---

## 4. Stage Rewind Mechanics for D-04

### Stage constants [VERIFIED: src/checkpoint.py:15-23]

```python
class PipelineStage(IntEnum):
    NOT_STARTED = 0
    INGESTED = 1
    DIARIZED = 2
    TRANSCRIBED = 3   # ← D-04 rewinds to here
    IDENTIFIED = 4
    SUMMARIZED = 5
    ENROLLED = 6
    EXPORTED = 7
```

### Resume logic [VERIFIED: run_local.py, all stage blocks]

`is_complete(stage)` returns `True` when `completed_stage >= stage` (checkpoint.py:68-69). Each stage block opens with:
```python
if state.is_complete(PipelineStage.STAGE_N):
    print("  Already complete. Skipping.")
    ...
else:
    # do work
    state.mark_complete(PipelineStage.STAGE_N)
```

**Rewind effect of setting `completed_stage = TRANSCRIBED` (value 3):**
- Stage 1 (INGESTED=1): `3 >= 1` → True → skipped (audio already on disk, correct)
- Stage 2 (DIARIZED=2): `3 >= 2` → True → skipped (diarization.json on disk, correct)
- Stage 3 (TRANSCRIBED=3): `3 >= 3` → True → skipped (transcript_raw.json on disk, correct)
- Stage 4 (IDENTIFIED=4): `3 >= 4` → False → re-runs against new roster
- Stage 5 (SUMMARIZED=5): `3 >= 5` → False → re-runs
- Stage 6 (ENROLLED=6): `3 >= 6` → False → re-runs
- Stage 7 (EXPORTED=7): `3 >= 7` → False → re-runs

This is exactly the desired behavior per D-04.

### Artifact files: independent resume signals?

**Investigation result:** Only `pipeline_state.json` (via `state.is_complete(...)`) gates stage re-execution. No artifact file is independently checked as a resume signal that would short-circuit the stage logic. Specifically:

| Artifact | How handled on resume |
|----------|----------------------|
| `audio.wav` | Stage 1 is skipped via checkpoint; audio.wav is NOT independently checked as a skip signal |
| `diarization.json` | Stage 2 checkpoint; but Stage 2 code does check `diarization_path.exists()` as a sub-step optimization (lines 308-311) — loads existing file instead of re-running diarization. This is within Stage 2's branch; Stage 2 is already marked complete so the whole stage is skipped. Not an independent resume signal. |
| `embeddings.json` | Loaded in Stage 4 if it exists (line 581-584) — this is within Stage 4's execution, not a skip guard |
| `transcript_raw.json` | No independent existence check outside the stage checkpoint logic |
| `transcript_named.json` | Loaded in Stage 4 IF `state.is_complete(IDENTIFIED)` (line 573-578). After force-retag rewinds to TRANSCRIBED, `is_complete(IDENTIFIED)` is False, so `transcript_named.json` is NOT loaded from checkpoint — Stage 4 re-runs and overwrites it. |
| `summary.json` | Loaded in Stage 5 only if `state.is_complete(SUMMARIZED)` — same logic; rewind means it re-runs |
| `llm_partial_results.json` | Cleaned up at end of Stage 4 (line 621-622); not a resume signal |
| `pre_identifications.json` | Used as input within Stage 4 execution (lines 623-635) when it exists — not a skip guard |
| Voice profiles (`speaker_profiles.pkl`) | Enrolled in Stage 6; rewind causes Stage 6 to re-run and re-enroll against new identification results |

**Conclusion:** Setting `state.completed_stage = PipelineStage.TRANSCRIBED` and calling `state.save()` is sufficient to cause Stages 4-7 to re-run. No artifact deletion is required. The `transcript_named.json` will be overwritten by the re-run Stage 4. Voice profiles will be re-enrolled in the re-run Stage 6.

**One nuance:** `pre_identifications.json` (written by `--pre-identify` or `--identify-speakers` commands) is consumed by Stage 4 as "ground truth overrides" (lines 623-635). After `--force-retag`, the pre-identifications were produced against the old roster context. The planner should decide whether to delete `pre_identifications.json` on force-retag, or document that operators should re-run `--identify-speakers` after a retag. This is a gray area not covered by the decisions.

---

## 5. Pre-Stage-1 Guard Placement

### Exact insertion point [VERIFIED: run_local.py:197-260]

The `run_pipeline` execution sequence before the Stage 1 banner:

| Line | Action |
|------|--------|
| 197 | `def run_pipeline(args)` |
| 199-203 | Imports (numpy, torch, src modules) |
| 206 | Print data directory |
| 209-212 | Resolve `audio_path` from `args.input`, exit if missing |
| 215-216 | Get HuggingFace token (reads env / cached login / prompts) |
| 219-226 | Print device info (CPU/GPU detect, no IO) |
| 229-231 | Compute `meeting_id`, construct `PipelineState` (reads pipeline_state.json) |
| 233-239 | Create `Meeting` object (in-memory only) |
| 241-246 | Print meeting info + checkpoint status |
| 248-249 | Set `num_speakers`, `wav_path` |
| 252-255 | Stage 1 banner |

**Guard insertion point:** After line 246 (checkpoint status print) and before line 248 (`num_speakers = ...`). The resolve logic (section 3 above) goes here first, followed by the guard call.

**"Fail in ~1 second" claim:** The guard runs after `PipelineState` construction (reads one small JSON file) and HuggingFace token resolution. The token resolution (line 215) may prompt the user if not cached — this is the only slow step before the guard. If HF token is cached (the normal case), the guard fires in well under 1 second. Even with a token prompt, it fires before any GPU/disk work.

**`get_hf_token()` concern:** On first run (no cached token), the operator would be prompted for HF token before seeing the roster error. This is slightly suboptimal UX but is pre-existing behavior. An enhancement would move the guard before HF token resolution, but that requires restructuring `run_pipeline`. Given the CONTEXT says "after argparse and after metadata load/merge", the current placement (after PipelineState construction but before Stage 1) is correct. The HF token prompt is an existing ordering the CONTEXT does not ask to change.

### Guard helper signature recommendation

Place `_ensure_body_roster_cached` as a module-level function in `run_local.py` (not in a new `src/body.py` or in `src/roster.py`). Rationale: it contains `sys.exit(2)` which is CLI-specific behavior inappropriate for a library module; it will be called only from `run_local.py`. The `src/roster.py` already provides `load_roster(body_slug=...)` which returns `None` on missing cache — the guard can delegate to it:

```python
def _ensure_body_roster_cached(body_slug: str) -> None:
    """Fail fast if the per-body roster cache is missing (D-07, D-08, D-10)."""
    from src.roster import load_roster
    from src import config

    roster = load_roster(body_slug=body_slug)
    if roster is None:
        slug_path = config.CONFIG_DIR / "rosters" / f"{body_slug}.json"
        print(
            f'ERROR: Body "{body_slug}" has no cached roster at {slug_path}',
            file=sys.stderr,
        )
        print(
            f"Run: python refresh_roster.py --body {body_slug}",
            file=sys.stderr,
        )
        sys.exit(2)
```

Note: D-08 specifies `~/CouncilScribe/config/rosters/...` in the error message. But `config.CONFIG_DIR` resolves to `~/CouncilScribe/config` by default, and may be overridden via `CS_DATA_DIR`. Using `config.CONFIG_DIR / "rosters" / f"{body_slug}.json"` gives the actual path, which is more useful to the operator than a hardcoded `~/` path. The planner should decide between actual path vs hardcoded `~/` per D-08's exact wording.

**D-09 interaction:** `load_roster(body_slug=...)` returns `None` ONLY when the file is missing. If the file exists but is stale, it returns a valid `Roster` with a warning printed to stderr (Phase 108 behavior). So `_ensure_body_roster_cached` calling `load_roster` naturally implements D-09 — stale cache is non-blocking, missing cache exits 2.

**Avoid double-load:** The guard calls `load_roster(body_slug=...)` to check existence. Stage 4 also calls `load_roster(body_slug=...)`. This is two file reads of the same JSON. To avoid duplication, the planner could have the guard return the `Roster` object and Stage 4 reuses it. However, given that Stage 4 may be many stages away from the guard, passing `roster` through all that code is messy. Two reads is acceptable (the file is small). Document this as an acknowledged minor inefficiency.

---

## 6. Error Format + Testability

### Exact error string [VERIFIED: 109-CONTEXT.md D-08]

```
ERROR: Body "<slug>" has no cached roster at ~/CouncilScribe/config/rosters/<slug>.json
Run: python refresh_roster.py --body <slug>
```

Note: The D-08 spec uses `~/CouncilScribe/config/rosters/` which is a hardcoded representation. The actual path in the error should use `config.CONFIG_DIR` to respect `CS_DATA_DIR` overrides — but the planner should confirm whether to match D-08 literally (hardcoded `~/`) or use the actual resolved path. Research recommendation: use actual resolved path for operator usability; document this deviation from the spec wording.

### Test assertion approach

```python
def test_fail_fast_missing_roster(tmp_config_dir):
    """D-08: missing roster → stderr message + sys.exit(2)."""
    # Arrange: no roster file written
    with pytest.raises(SystemExit) as exc_info:
        _ensure_body_roster_cached("bloomington-common-council")
    assert exc_info.value.code == 2

def test_fail_fast_error_message(tmp_config_dir, capsys):
    """D-08: error message shape."""
    with pytest.raises(SystemExit):
        _ensure_body_roster_cached("bloomington-common-council")
    captured = capsys.readouterr()
    assert 'ERROR: Body "bloomington-common-council"' in captured.err
    assert "has no cached roster" in captured.err
    assert "refresh_roster.py --body bloomington-common-council" in captured.err
```

Using `capsys.readouterr().err` is correct for testing `print(..., file=sys.stderr)`. Exit code is asserted via `exc_info.value.code`. This mirrors the Phase 108 test style.

For testing the full `run_pipeline` guard integration, subprocess tests or monkeypatching `sys.argv` + `run_pipeline` + capturing SystemExit are both viable. The guard helper tests above are preferable as unit tests that run fast without pipeline setup.

---

## 7. Test Layout

### Phase 108 test files [VERIFIED: CouncilScribe/tests/]

```
tests/
├── __init__.py
├── conftest.py              # Shared fixtures: tmp_config_dir, sample_politician_*, sample_roster_response
├── fixtures/
│   └── bloomington_roster_response.json
├── test_alias_gen.py        # Phase 108: alias generation
├── test_antipartisan.py     # Phase 108: antipartisan enforcement
├── test_essentials_client.py  # Phase 108: HTTP client
├── test_refresh_roster.py   # Phase 108: CLI refresh_roster.py
└── test_roster_load.py      # Phase 108: load_roster() slug + legacy paths
```

### Phase 109 test module recommendation

**Module name:** `tests/test_body_tagging.py`

**Test cases mapped to decisions:**

| Test name | Decision | What it tests |
|-----------|----------|---------------|
| `test_first_run_persists_body_slug` | D-01 | `--body X` on new meeting writes `body_slug=X` to `pipeline_state.json` |
| `test_subsequent_run_reads_slug_silently` | D-01/D-06 | Second call with no `--body` reads persisted slug; prints `Body: X` line |
| `test_mismatch_flag_is_hard_error` | D-02 | `--body Y` when persisted `body_slug=X` → sys.exit(2) with message |
| `test_force_retag_overwrites_slug` | D-03 | `--body Y --force-retag` when persisted X → body_slug becomes Y |
| `test_force_retag_rewinds_completed_stage` | D-04 | After force-retag, `state.completed_stage == PipelineStage.TRANSCRIBED` |
| `test_legacy_fallback_no_body_flag` | D-05 | New meeting with no `--body` → `effective_body_slug = None`, bare `load_roster()` path |
| `test_fail_fast_missing_roster` | D-07/D-08 | `_ensure_body_roster_cached("missing")` → exit(2) |
| `test_fail_fast_error_message_format` | D-08 | stderr lines match exact format |
| `test_stale_cache_does_not_fail_fast` | D-09 | 31-day-old cache → loads successfully (warning fires but no exit) |
| `test_resume_after_cache_delete_fails_fast` | D-10 | State has `body_slug=X`, roster deleted → guard exits(2) on resume |
| `test_body_slug_survives_save_load_roundtrip` | CSMEETING-01 | `PipelineState` with `body_slug` saves + reloads correctly |
| `test_legacy_state_file_loads_without_body_slug` | Backward compat | Existing JSON without `body_slug` key → `state.body_slug = None` |
| `test_batch_args_propagates_body` | `_run_batch` | `batch_args.body` is set from `args.body` |

**Additional `conftest.py` fixture needed:**

```python
@pytest.fixture
def tmp_meeting_dir(tmp_path, tmp_config_dir):
    """Create a temp meeting directory with a fresh PipelineState."""
    mdir = tmp_path / "meetings" / "2026-04-11-regular-session"
    mdir.mkdir(parents=True)
    return mdir
```

Tests that exercise `PipelineState` directly (D-01, D-04, backward compat) need a `meeting_dir` fixture. The existing `tmp_config_dir` fixture only covers `CONFIG_DIR`.

**No subprocess invocation needed** for unit tests of the guard helper and `PipelineState` extension. Subprocess-level tests for the full CLI integration would require mocking GPU/HF token initialization; that is integration test territory and optional for Phase 109.

---

## 8. Risks and Unknowns

### Risk 1: `pre_identifications.json` after force-retag

**What:** When `--force-retag` rewinds to TRANSCRIBED, Stage 4 re-runs. If `pre_identifications.json` exists (from a prior `--pre-identify` or `--identify-speakers` run), Stage 4 still applies it as ground truth overrides (lines 623-635). Those pre-identifications were built in the context of the OLD roster. They may use canonical names from the old roster (e.g. "Councilmember Piedmont-Smith") which may or may not match the new roster.

**Severity:** Medium. If old and new roster both contain the same person (which is typical for a typo-retag), pre-identifications are still valid. If the body genuinely changes, pre-identifications may be stale.

**Recommendation:** Document in PLAN. The simplest mitigation: on force-retag, if `pre_identifications.json` exists, print a warning: "Pre-identifications file exists and will be applied against the new roster. Delete it if you want fully automated identification." Do not auto-delete (non-interactive safety).

### Risk 2: `--show-roster` utility will silently show wrong roster

**What:** After Phase 109, operators with tagged meetings might run `--show-roster` expecting to see the body-specific roster, but get the legacy global one. This is confusing but not a data corruption risk.

**Severity:** Low. Addressed by deferred enhancement (accept `--body` on `--show-roster`).

### Risk 3: `_fix_transcripts` applies legacy roster to tagged meetings

**What:** The `--fix-transcripts` utility (line 1021) loads one global roster and applies it to all meetings. If a tagged meeting exists, it corrects names against the legacy roster, not the body-specific one.

**Severity:** Low for Phase 109. `_fix_transcripts` is an offline utility for batch correction; Phase 109 success criteria do not include it. Phase 110 / 111 will address this properly.

### Risk 4: batch mode per-row body slug limitation

**What:** `--body` in batch mode applies to ALL rows. If a batch CSV mixes meetings from multiple bodies, this is wrong. Per CONTEXT, per-row body slugs are deferred.

**Severity:** Low until multi-jurisdiction support is needed. Document the limitation.

### Risk 5: `CS_DATA_DIR` path in error message

**What:** D-08 specifies `~/CouncilScribe/config/rosters/...` literally. If the operator has `CS_DATA_DIR` set to a different path, the error message would show the wrong path if hardcoded.

**Recommendation:** Use `config.CONFIG_DIR / "rosters" / f"{body_slug}.json"` in the error message. Deviation from D-08 literal spec is intentional and justified.

### Risk 6: `--force-retag` without `--body` flag

**What:** Operator runs `--force-retag` without `--body`. What should happen?

**Analysis:** `--force-retag` without `--body` is meaningless — there's no new slug to write. The resolve logic in section 3 handles this: if `arg_body is None` and `force_retag is True`, the `if arg_body and force_retag` branch is skipped; effective_body_slug falls through to `state.body_slug`. The `--force-retag` flag is silently ignored.

**Recommendation:** Add an argparse validation: if `args.force_retag and not args.body`, print a warning or error. Most defensible as an error: "ERROR: --force-retag requires --body". Document in PLAN.

### Risk 7: `Stage 4 load_roster` runs even on checkpoint-skipped path

**What:** Lines 568-571 run BEFORE the `if state.is_complete(IDENTIFIED)` checkpoint check (line 573). This means `load_roster()` fires on every `run_pipeline` invocation, including ones where Stage 4 is already complete. After Phase 109, the fail-fast guard runs before Stage 1, so a missing roster will be caught before the pipeline proceeds. But for a tagged meeting with a valid roster, the roster is loaded twice (once at the guard check and once at line 568) if Stage 4 is re-running.

**Severity:** Negligible. Two JSON file reads of a small file.

---

## Architecture Patterns

### Resolve flow for `effective_body_slug`

```
parse args
  ↓
construct PipelineState (reads pipeline_state.json, loads body_slug if present)
  ↓
resolve effective_body_slug:
  - arg_body ≠ state.body_slug AND no --force-retag → exit(2) D-02
  - arg_body + --force-retag → overwrite state.body_slug + rewind to TRANSCRIBED D-03/D-04
  - arg_body (no conflict) → write state.body_slug D-01
  - no arg_body → use state.body_slug (may be None) D-05/D-06
  ↓
if effective_body_slug: print "Body: <slug>"
  ↓
if effective_body_slug: _ensure_body_roster_cached(effective_body_slug) → exit(2) if missing D-07/D-08/D-10
  ↓
[Stage 1 banner]
...
[Stage 4]
roster = load_roster(body_slug=effective_body_slug) if effective_body_slug else load_roster()
```

### Code pattern for conditional load_roster (Stage 4, line 568 replacement)

```python
roster = (
    load_roster(body_slug=effective_body_slug)
    if effective_body_slug
    else load_roster()
)
if roster:
    source = f"body-specific ({effective_body_slug})" if effective_body_slug else "legacy"
    print(f"  Loaded council roster ({source}): {len(roster.members)} members")
roster_hint = roster_names_for_prompt(roster) if roster else ""
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic JSON write | Custom file write | Existing `PipelineState.save()` pattern (tempfile + os.replace) | Already battle-tested in codebase |
| Roster existence check | Path.exists() directly | `load_roster(body_slug=...)` returning None | Centralizes path resolution, gets staleness warning for free |
| Argparse namespace for batch | Custom dict | `argparse.Namespace(...)` matching existing pattern | Maintains API consistency with run_pipeline |

---

## Validation Architecture

### Test Framework [VERIFIED: tests/ directory structure]

| Property | Value |
|----------|-------|
| Framework | pytest (inferred from existing tests using `pytest.raises`, `caplog`, `capsys`) |
| Config file | No `pytest.ini` observed in repo root; standard pytest discovery |
| Quick run command | `cd CouncilScribe && python -m pytest tests/test_body_tagging.py -x` |
| Full suite command | `cd CouncilScribe && python -m pytest tests/ -x` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Command |
|--------|----------|-----------|---------|
| CSMEETING-01 | `body_slug` stored in `pipeline_state.json` | unit | `pytest tests/test_body_tagging.py::test_body_slug_survives_save_load_roundtrip` |
| CSMEETING-01 | Backward compat: existing state files without `body_slug` | unit | `pytest tests/test_body_tagging.py::test_legacy_state_file_loads_without_body_slug` |
| CSMEETING-02 | First run persists | unit | `pytest tests/test_body_tagging.py::test_first_run_persists_body_slug` |
| CSMEETING-02 | Subsequent read silently | unit | `pytest tests/test_body_tagging.py::test_subsequent_run_reads_slug_silently` |
| CSMEETING-02 | Mismatch hard error | unit | `pytest tests/test_body_tagging.py::test_mismatch_flag_is_hard_error` |
| CSMEETING-02 | Fail-fast exit code + format | unit | `pytest tests/test_body_tagging.py::test_fail_fast_missing_roster test_fail_fast_error_message_format` |
| CSMEETING-02 | Resume after cache delete fails fast | unit | `pytest tests/test_body_tagging.py::test_resume_after_cache_delete_fails_fast` |
| CSMEETING-03 | Legacy fallback intact | unit | `pytest tests/test_body_tagging.py::test_legacy_fallback_no_body_flag` |

### Wave 0 Gaps

- [ ] `tests/test_body_tagging.py` — covers all 13 test cases in section 7
- [ ] `tests/conftest.py` — add `tmp_meeting_dir` fixture (alongside existing `tmp_config_dir`)

*(No new framework install needed — pytest is already in use)*

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Planner will choose Option A (extend PipelineState) over meeting_meta.json | Section 2 | If Option B chosen: need separate atomic write impl, file-ordering logic |
| A2 | `_fix_transcripts` (line 1021) is out of scope for CSMEETING-03 | Section 1, Site 2 | If planner disagrees: requires per-meeting body_slug lookup in the iteration loop |
| A3 | `--show-roster` (line 1719) and `--fix-profiles` (line 1749) are out of scope | Section 1, Sites 3-4 | Low risk — these are utility commands not in CSMEETING success criteria |
| A4 | `pre_identifications.json` should be warned-about but not auto-deleted on force-retag | Section 8 Risk 1 | If planner prefers auto-delete: add `(meeting_dir / "pre_identifications.json").unlink(missing_ok=True)` to force-retag branch |
| A5 | Error message should use actual `config.CONFIG_DIR` path, not hardcoded `~/` | Section 5 / Section 6 | If D-08 literal spec is enforced: use `Path.home() / "CouncilScribe/config/rosters"` |

---

## Sources

### Primary (HIGH confidence)
- [VERIFIED: CouncilScribe/src/checkpoint.py] — PipelineState class, stage constants, atomic write pattern, `_load()` `.get()` usage
- [VERIFIED: CouncilScribe/run_local.py] — All four `load_roster()` call sites, argparse block (lines 1633-1713), `_run_batch` Namespace (lines 950-964), `run_pipeline` opening sequence (lines 197-260)
- [VERIFIED: CouncilScribe/src/roster.py] — `load_roster()` signature, None-on-missing behavior, staleness warning, `correct_speaker_name`, `roster_names_for_prompt`
- [VERIFIED: CouncilScribe/src/config.py] — `CONFIG_DIR` path construction, `CS_DATA_DIR` override
- [VERIFIED: CouncilScribe/src/identify.py] — `identify_speakers()` signature, roster accepted as optional param
- [VERIFIED: CouncilScribe/tests/] — Phase 108 test file names, conftest.py fixtures, test_roster_load.py assertion patterns
- [VERIFIED: .planning/phases/109-per-meeting-body-tagging/109-CONTEXT.md] — All locked decisions D-01..D-10
- [VERIFIED: .planning/REQUIREMENTS.md] — CSMEETING-01..03 authoritative wording

### Secondary (MEDIUM confidence)
- [CITED: .planning/phases/108-councilscribe-roster-client-cli/108-CONTEXT.md] — D-05 staleness semantics (non-blocking), `load_roster(body_slug=None)` return behavior

---

## Metadata

**Confidence breakdown:**
- Call-site enumeration: HIGH — grep-verified all four sites, confirmed function contexts by reading code
- PipelineState extension: HIGH — read full checkpoint.py, confirmed `.get()` pattern in `_load()`
- Argparse wiring: HIGH — read full argparse block and `_run_batch` Namespace construction
- Stage rewind mechanics: HIGH — read all stage checkpoint patterns in run_pipeline
- Guard placement: HIGH — traced run_pipeline execution sequence line by line
- Test layout: HIGH — read Phase 108 test files and conftest.py directly

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (stable codebase; no external dependencies to expire)

---

## RESEARCH COMPLETE
