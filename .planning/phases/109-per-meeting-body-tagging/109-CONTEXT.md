# Phase 109: Per-meeting body tagging — Context

**Gathered:** 2026-04-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Thread `body_slug` through CouncilScribe so every meeting run declares which governing body it belongs to, that tag persists across pipeline stages, and Stage 4 identification consumes the body-specific cached roster built in Phase 108 — with no fallback to the legacy global roster whenever a body_slug is present.

**Concretely in scope:**
1. `run_local.py` accepts `--body {slug}` (and `--force-retag`) and persists `body_slug` into per-meeting metadata on first use.
2. Subsequent invocations of the same meeting read `body_slug` back from metadata without re-specifying the flag.
3. A pre-Stage-1 guard validates that `{slug}.json` exists in `~/CouncilScribe/config/rosters/` and fails fast if not.
4. Stage 4 identification (`run_local.py:568`) calls `load_roster(body_slug=...)` instead of the bare legacy `load_roster()` whenever a body is tagged. All three sub-consumers — `correct_speaker_name`, pattern matching, and the LLM prompt via `roster_names_for_prompt` — consume that body-specific roster.
5. If no `--body` flag is passed AND no body_slug is persisted, the legacy `load_roster()` path continues to work unchanged (Phase 108 fallback semantics).

**Out of scope (deferred to later phases):**
- `StoredProfile` schema changes / politician-slug-keyed profiles → Phase 110.
- `reenroll_profiles.py` awareness of per-body rosters → Phase 110 (CSPROFILE-04 explicitly names it).
- Live-roster-driven identification fidelity / phantom-name elimination on real meetings → Phase 111.
- Auto-refresh of cached rosters; multi-version caching; per-row body slugs in batch CSV.

Immediate consumer is Phase 110 (profile schema v3 + re-enrollment), which assumes every Bloomington meeting processed by Phase 109 carries a persisted `body_slug` and is being identified against the cached roster for that slug.

</domain>

<decisions>
## Implementation Decisions

### Re-run / override policy

- **D-01: First run persists, subsequent runs read silently.** On first invocation, `--body X` is required to write `body_slug=X` into per-meeting metadata. On every subsequent invocation against the same meeting, omitting `--body` reads the persisted slug back silently (matches CSMEETING-02 wording verbatim). Print the resolved slug for operator visibility (single info line), but do not require re-passing the flag.

- **D-02: Mismatched flag is a hard error.** If the meeting already persists `body_slug=X` and the operator passes `--body Y`, `run_local.py` exits non-zero with a clear message: meeting already tagged as X, pass `--body X` or use `--force-retag` to change it. This prevents silent corruption of identification results by running Stage 4 against the wrong roster.

- **D-03: `--force-retag` is the escape hatch.** Operators who genuinely need to change a meeting's body (typo, reclassified body, etc.) pass `--body Y --force-retag`. This overwrites the persisted `body_slug` without touching JSON by hand. No separate helper script.

- **D-04: `--force-retag` invalidates downstream stages.** When `--force-retag` rewrites `body_slug`, it also rewinds `completed_stage` to `TRANSCRIBED` (stage 3). Stages 4/5/6/7 re-run against the new roster on the same invocation. Rationale: `transcript_named.json`, summaries, and voice-profile enrollments produced against the old roster are now stale — forcing re-run is the only way to keep artifacts consistent.

- **D-05: No flag, no persisted slug → legacy fallback.** A brand-new meeting run with no `--body` flag at all continues to work exactly as today — Stage 4 calls bare `load_roster()`, which resolves to `~/CouncilScribe/config/council_roster.json`. No warning, no error. Untagged meetings keep working through the Phase 108/109 transition period; operators migrate incrementally by tagging new meetings.

- **D-06: No flag, yes persisted slug → read from metadata silently.** On a resume / re-invocation of an already-tagged meeting, omitting `--body` is the common case (see D-01). The effective body_slug is whatever is persisted; print it for visibility (single `Body: <slug>` info line) but do not warn.

### Fail-fast timing & shape

- **D-07: Fail fast BEFORE Stage 1.** The cached-roster existence check runs after argparse and after metadata load/merge (so it sees either the flag or the persisted slug), but before any ingestion/diarization/transcription work. Operators get the error in roughly one second and have not burned GPU or disk. This is the correct interpretation of CSMEETING-02's "fails fast with a clear error message."

- **D-08: Error shape — print to stderr + `sys.exit(2)`.** On missing cached roster, print a 2-line error to stderr:
  - Line 1: `ERROR: Body "<slug>" has no cached roster at ~/CouncilScribe/config/rosters/<slug>.json`
  - Line 2: `Run: python refresh_roster.py --body <slug>`
  Then `sys.exit(2)` (same exit code argparse uses for usage errors, distinct from the generic `1` for runtime failures). Matches existing CouncilScribe CLI conventions and is straightforward to assert in tests.

- **D-09: Stale cache does NOT fail fast.** A cached roster file that exists but is older than 30 days (Phase 108's staleness threshold) still loads — the non-blocking WARNING from `load_roster(body_slug=...)` fires as today. Fail-fast only triggers on truly missing files. This preserves Phase 108 D-05 ("30-day staleness warning is non-blocking") without contradiction.

- **D-10: Resume with deleted cache fails fast identically.** If a prior run persisted `body_slug=X`, completed through Stage 3, and then `~/CouncilScribe/config/rosters/X.json` was deleted (by the operator, by a cleanup script, whatever), a subsequent resume invocation fails fast at the same pre-Stage-1 check. Operator re-runs `refresh_roster.py --body X`, re-invokes `run_local.py` with no `--body` flag, and the pipeline picks up from its checkpoint. This is the only behavior consistent with CSMEETING-03 ("no code path falls back to the legacy global roster when a body_slug is present") — falling back to the legacy roster mid-resume would silently swap identification rosters, which is exactly the bug this phase prevents.

### Items intentionally not discussed (Claude's discretion)

Two gray areas were surfaced but deliberately **not** discussed — planner/researcher decide, but the constraints below are locked:

- **Metadata storage location** — adding `body_slug` to existing `pipeline_state.json` vs introducing a new `meeting_meta.json`. Either is acceptable. Constraints: (a) the file must already be written atomically (temp + `os.replace`, see `src/checkpoint.py:45-62`); (b) the value must survive checkpoint/resume identically; (c) reading it must not add a stage dependency (the pre-Stage-1 guard needs to see the slug before `PipelineState.mark_complete` has been called for Stage 1). Recommendation: extend `pipeline_state.json` via `PipelineState` to minimize file proliferation, but planner may introduce `meeting_meta.json` if it turns out `PipelineState` shouldn't carry non-stage config.

- **Scope of Stage 4 call-site updates** — `run_local.py` calls `load_roster()` at four current sites: line 568 (main pipeline Stage 4), line 1019 (post-identification enroll path), and lines 1718 / 1749 (two further paths — likely `pre_identify` and/or `reenroll` style flows). Phase 109 MUST update every call site inside `run_local.py` (lines 568, 1019, 1718, 1749) so none of them fall back to legacy when the current meeting has `body_slug` set. `reenroll_profiles.py` (the standalone script at repo root) is explicitly **out of scope** — Phase 110 owns it via CSPROFILE-04. If researcher finds a call site I missed, update it too; the rule is "within run_local.py, no code path loads the legacy roster when the running meeting is tagged."

### Claude's Discretion (for researcher / planner)

- Whether the body_slug lives on `PipelineState` as an attribute or in a sibling `meeting_meta.json` file (see constraints above).
- Exact argparse wiring for `--body` and `--force-retag` — both should also be exposed on `batch_args` in `run_batch()` (lines ~950-964) so batch mode can propagate a single global body to every CSV row. Per-row body slugs in the batch CSV are explicitly out of scope (deferred).
- Exact signature for the pre-Stage-1 guard helper — a small `ensure_body_roster_cached(body_slug: str) -> None` that raises or exits is the obvious shape, but planner's call whether to put it in `run_local.py`, a new `src/body.py`, or extend `src/roster.py`.
- How to thread `body_slug` through to `identify_speakers` / `correct_speaker_name` / the LLM prompt — the cleanest path is to load the `Roster` object once via `load_roster(body_slug=body_slug)` and pass that `roster` object into all existing consumers (they already accept a `Roster`). No API changes should be needed beyond the `load_roster` call itself.
- Test layout: mirror the Phase 108 convention of `CouncilScribe/tests/test_*` modules. At minimum, cover D-01 (first-run persist), D-02 (mismatch error), D-03 (force-retag overwrite), D-04 (stage rewind), D-05 (legacy fallback intact), D-07 (pre-Stage-1 timing), D-08 (error format + exit code), D-10 (resume after cache delete).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & requirements
- `.planning/ROADMAP.md` §"Phase 109: Per-meeting body tagging" — goal, depends-on, success criteria.
- `.planning/REQUIREMENTS.md` §"CSMEETING" — CSMEETING-01, CSMEETING-02, CSMEETING-03 (authoritative wording).

### Upstream phase (locked data shape + semantics)
- `.planning/phases/108-councilscribe-roster-client-cli/108-CONTEXT.md` — Phase 108 decisions. Particularly D-05 (non-blocking staleness), and the slug-vs-legacy branch in `load_roster`.
- `.planning/phases/107-essentials-body-roster-endpoint/107-CONTEXT.md` — Phase 107 response shape (the roster that ends up cached).

### CouncilScribe code to study / modify
- `CouncilScribe/run_local.py` — argparse, `run_pipeline`, `run_batch`. Stage 4 lives around line 550-650. `load_roster()` call sites: **568** (Stage 4 main), **1019** (enroll path), **1718** and **1749** (further paths — researcher to confirm purpose). All four must be updated in Phase 109.
- `CouncilScribe/src/roster.py` — `load_roster(path, *, body_slug)` already exists from Phase 108 (line 34). No changes expected in Phase 109 unless researcher finds a signature gap. `correct_speaker_name` (line 148) and `roster_names_for_prompt` (line 289) are the downstream consumers.
- `CouncilScribe/src/checkpoint.py` — `PipelineState` class, atomic write via temp + `os.replace` (lines 45-62). Either extend this with a `body_slug` attribute + persistence, or sit a parallel `meeting_meta.json` alongside `pipeline_state.json` in the same meeting directory.
- `CouncilScribe/src/config.py` — `CONFIG_DIR` (`~/CouncilScribe/config`), `MEETINGS_DIR`. The cached rosters live at `CONFIG_DIR / "rosters" / f"{body_slug}.json"` per Phase 108.
- `CouncilScribe/src/identify.py` — `identify_speakers` signature; confirms what a `Roster` argument looks like in practice.
- `CouncilScribe/src/llm_utils.py` — `llm_identify_speakers` consumes `roster_hint` (built from `roster_names_for_prompt(roster)`). The body-specific roster must flow through here so LLM prompts see only body-roster names.

### Principles & conventions
- `CLAUDE.md` §"Antipartisan" / user memory `feedback_antipartisan.md` — no `party` field handling anywhere in new code. Code review grep for `party` in any file Phase 109 touches.
- User memory `councilscribe.md` — CouncilScribe project background, meetings already processed, operator workflow context.

### Out of scope for THIS phase (reference only)
- `CouncilScribe/reenroll_profiles.py` — Phase 110 territory (CSPROFILE-04). Do not modify in Phase 109 even if `run_local.py` updates tempt parallel edits there.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PipelineState` (`src/checkpoint.py:26`) already persists per-meeting JSON with atomic write-temp-then-rename. Adding a `body_slug: Optional[str]` attribute plus round-tripping it through `_load()` / `save()` is a ~10-line extension and is the lowest-friction home for the persisted slug.
- `load_roster(body_slug=...)` already exists (`src/roster.py:34`) and returns `None` when the cache is missing — Phase 109's fail-fast guard can simply call `load_roster(body_slug=slug)` once upfront and error on `None`, instead of duplicating path-existence logic.
- `correct_speaker_name` and `roster_names_for_prompt` already take a `Roster` object agnostically — no API changes needed at the consumer sites; just pass the body-specific `Roster` instead of the legacy one.
- `argparse` wiring for `run_local.py` already exists — `--body` and `--force-retag` slot into the existing parser alongside `--skip-llm`, `--no-merge`, etc.

### Established Patterns
- Per-meeting metadata lives in `<meetings_dir>/<meeting_id>/pipeline_state.json`. Atomic writes via temp file + `os.replace` (`src/checkpoint.py:51-58`). Resume logic reads it at top of every stage.
- CLI scripts print progress to stdout and errors to stderr. Exit codes: argparse usage errors exit 2; runtime errors exit 1 (or propagate exceptions). Phase 109 uses exit 2 for the missing-roster failure per D-08.
- Batch mode (`run_batch`, ~line 913) builds an `argparse.Namespace` per entry and calls `run_pipeline`. Any new flags (`--body`, `--force-retag`) must be added to the `batch_args = argparse.Namespace(...)` constructor around line 950-964, or `run_pipeline` will AttributeError on `args.body`.

### Integration Points
- **Arg parsing:** add `--body` and `--force-retag` to the top-level argparse in `run_local.py` main, propagate into `run_pipeline(args)` and `run_batch(args)`.
- **Metadata load/merge:** very early in `run_pipeline`, after `meeting_dir` is known and `PipelineState` is constructed, resolve effective `body_slug` = `args.body or state.body_slug` (with D-02 conflict check and D-03 force-retag escape).
- **Pre-Stage-1 guard:** immediately after resolve, if effective `body_slug` is set, assert that `CONFIG_DIR / "rosters" / f"{body_slug}.json"` exists. On miss: print + exit(2) per D-08. If legacy (D-05), skip the guard entirely.
- **Stage 4 sites (lines 568, 1019, 1718, 1749):** replace bare `load_roster()` with `load_roster(body_slug=effective_body_slug) if effective_body_slug else load_roster()`. Encapsulate as a helper if it gets repetitive.
- **`run_batch`:** `batch_args` Namespace must include `body` and `force_retag` so every per-entry `run_pipeline` call sees the same body. No per-row body support in this phase.

### Risks
- **State rewind on `--force-retag` (D-04)** is the most fragile piece. `PipelineState.completed_stage` is the single source of truth; rewinding it works, but researcher should verify no other file (e.g. `transcript_named.json`) is used as an independent resume signal that would short-circuit the re-run. If so, those files need deletion or the rewind is incomplete.
- **Four separate `load_roster()` call sites** is a refactoring smell. Each must be audited — the ones at 1718 / 1749 might be in `pre_identify` / `correct_transcript` paths that are only reached under rare flags. Missing one means a code path silently loads the legacy roster when it shouldn't. Researcher to enumerate and confirm.
- **Non-body meetings during the transition period.** D-05 keeps legacy working, which is correct, but it also means two code paths coexist in Phase 109. Tests should cover both paths explicitly so a future refactor doesn't accidentally break the legacy one.
- **`run_batch` body propagation.** Easy to forget a new flag in the `argparse.Namespace(...)` constructor — then batch mode silently falls back to legacy even when `--body` was passed at the top level. Add an explicit assertion / test for this.

</code_context>

<specifics>
## Specific Ideas

- **`--force-retag` is blast-radius-aware.** Operators don't invoke it on a whim — the doc (and the error message in D-02) should spell out "this will re-run Stages 4-7 against the new roster" so nobody is surprised when their `transcript_named.json` gets regenerated.
- **Single `Body: <slug>` info line on every re-invocation (D-06)** is important for debugging. When an operator reports "my identification is wrong," the very first log line tells us which roster was actually loaded. Put it immediately after argparse resolution, before the "STAGE 1" banner.
- **Fail-fast error format is test-critical.** The planner will want to assert the exact error string in a test (stderr + exit code 2). Keep the format stable across this phase: `ERROR: Body "<slug>" has no cached roster at ~/CouncilScribe/config/rosters/<slug>.json\nRun: python refresh_roster.py --body <slug>\n`.
- **Tagged meetings and legacy meetings coexist.** Phase 109 is explicitly not a migration of every historical meeting. A meeting processed today without `--body` stays legacy forever unless the operator rebuilds the meeting dir. That's fine — Phase 111 will identify the first tagged Bloomington meeting end-to-end and the existing legacy meetings stay on their old path until the operator chooses to retag.
- **The `--force-retag` path also validates the new slug's cache** (D-04 → Stage 4 re-run → D-07 guard already ran). No extra check needed, but the flow should be: parse flag → detect mismatch → require `--force-retag` → validate new cache exists → rewind stage → proceed. If validation fails, nothing is rewritten yet.

</specifics>

<deferred>
## Deferred Ideas

- **`reenroll_profiles.py` body awareness** — Phase 110 owns this (CSPROFILE-04). Explicitly out of scope for Phase 109 even though the two files share identification logic.
- **`StoredProfile` politician_slug keys** — Phase 110.
- **Live-roster identification fidelity on a real meeting** — Phase 111.
- **Per-row body slugs in batch CSV** — currently `--body` is a global flag applied uniformly to every row. Mixed-body batches are a separate problem and can wait until there's a second jurisdiction to batch-process.
- **Auto-refresh of stale rosters from run_local.py** — Phase 108 D-05 kept staleness non-blocking and there's no operator demand for auto-refresh yet. Revisit if a Bloomington roster goes 30+ days without a refresh in practice.
- **Migration of existing untagged meetings** — Phase 109 adds the tagging capability but does not migrate historical meetings. Untagged meetings continue to work via the legacy fallback. A bulk retag workflow is a future enhancement if it's ever needed.
- **Richer `meeting_meta.json` with more than body_slug** — if planner chooses the separate-file approach, other phase-level metadata (source URL, operator name, notes, etc.) could accumulate there. Phase 109 adds only `body_slug`; leave the file structure minimal.
- **Interactive confirmation for `--force-retag`** — considered and rejected because it breaks non-interactive CI / batch flows. If operators want a safety net, they can grep `pipeline_state.json` themselves before running.

</deferred>

---

*Phase: 109-per-meeting-body-tagging*
*Context gathered: 2026-04-11*
