# Phase 109: Per-meeting body tagging — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11
**Phase:** 109-per-meeting-body-tagging
**Areas discussed:** Re-run / override policy, Fail-fast timing

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Metadata storage | Add body_slug to existing pipeline_state.json vs new meeting_meta.json file. | |
| Re-run / override policy | What happens on already-tagged meetings vs new flag vs no flag. | ✓ |
| Fail-fast timing | When does a missing cached roster error fire. | ✓ |
| Scope of call-site updates | Which load_roster() sites Phase 109 touches vs defers to Phase 110. | |

**User's choice:** Re-run / override policy and Fail-fast timing. The two unselected areas were captured in CONTEXT.md under "Items intentionally not discussed (Claude's discretion)" with locked constraints.

---

## Re-run / Override Policy

### Q1: Mismatched body_slug on re-run

| Option | Description | Selected |
|--------|-------------|----------|
| Hard error | Fail with a message telling operator to use --force-retag. | ✓ |
| Silent override | Trust the flag; overwrite persisted slug. | |
| Interactive prompt | Print old vs new and ask y/N. | |

**User's choice:** Hard error (Recommended).

### Q2: No flag on already-tagged meeting

| Option | Description | Selected |
|--------|-------------|----------|
| Read from metadata silently | Slug persists and is read back without flag. Matches CSMEETING-02 wording. | ✓ |
| Warn but proceed | Print a WARNING that metadata is being inherited. | |
| Require the flag every time | Refuse to continue without --body. | |

**User's choice:** Read from metadata silently (Recommended).

### Q3: No flag on brand-new meeting

| Option | Description | Selected |
|--------|-------------|----------|
| Legacy fallback | No body persisted; Stage 4 uses legacy global roster. Today's workflow unchanged. | ✓ |
| Hard error | Require --body on every new meeting. | |
| Prompt / warn then legacy | Print warning then fall back. | |

**User's choice:** Legacy fallback (Recommended).

### Q4: Escape hatch for retag

| Option | Description | Selected |
|--------|-------------|----------|
| --force-retag flag | Explicit flag that overwrites persisted slug. | ✓ |
| No escape hatch | Manual JSON edit required. | |
| Delete-and-retag helper script | Separate retag_meeting.py utility. | |

**User's choice:** --force-retag flag (Recommended).

### Q5: Downstream stage invalidation on retag

| Option | Description | Selected |
|--------|-------------|----------|
| Reset Stage 4+ | Rewind completed_stage to TRANSCRIBED so Stages 4-7 re-run. | ✓ |
| Leave state alone, just swap slug | Retag only; operator re-runs manually. | |
| Refuse retag past Stage 3 | Reject retag on completed meetings. | |

**User's choice:** Reset Stage 4+ (Recommended).

---

## Fail-fast Timing

### Q6: Where does missing-cache error fire

| Option | Description | Selected |
|--------|-------------|----------|
| Before Stage 1 | After arg parse + metadata load, before any ingestion. Fast and operator-friendly. | ✓ |
| At CLI arg parse | Fastest, but cannot see persisted slug from metadata. | |
| At Stage 4 load | Operator loses hours of transcription time on a bad slug. | |

**User's choice:** Before Stage 1 (Recommended).

### Q7: Error shape

| Option | Description | Selected |
|--------|-------------|----------|
| Printed + sys.exit(2) | 2-line stderr message, exit code 2. Matches argparse conventions. | ✓ |
| Raise RosterNotFoundError | Custom exception main() catches. | |
| Logging.error + sys.exit(1) | Use logging instead of print. | |

**User's choice:** Printed + sys.exit(2) (Recommended).

### Q8: Stale cache vs missing cache

| Option | Description | Selected |
|--------|-------------|----------|
| Proceed with warning | Staleness stays non-blocking per Phase 108 D-05; fail-fast only on missing. | ✓ |
| Fail fast on stale | Treat 30+ days as effectively missing. | |

**User's choice:** Proceed with warning (Recommended).

### Q9: Resume after cache deletion

| Option | Description | Selected |
|--------|-------------|----------|
| Fail fast at resume | Same pre-Stage-1 check; operator refreshes and re-invokes. | ✓ |
| Fall back to legacy roster | Silent fallback. Violates CSMEETING-03. | |
| Proceed without any roster | Run Stage 4 with roster=None. | |

**User's choice:** Fail fast at resume (Recommended).

---

## Claude's Discretion

- Metadata storage location (pipeline_state.json extension vs new meeting_meta.json) — planner's call within the constraints captured in CONTEXT.md.
- Scope of Stage 4 call-site updates — Phase 109 must update every `load_roster()` site inside `run_local.py` (lines 568, 1019, 1718, 1749). `reenroll_profiles.py` is explicitly Phase 110.
- HTTP client / argparse mechanics for `--body` and `--force-retag`.
- Exact helper module layout for the pre-Stage-1 guard.
- Test layout, mock/stub choices.

## Deferred Ideas

- `reenroll_profiles.py` body awareness → Phase 110 (CSPROFILE-04).
- Per-row body slugs in batch CSV.
- Auto-refresh of stale rosters.
- Migration of existing untagged meetings.
- Interactive confirmation for `--force-retag`.
- Richer `meeting_meta.json` schema beyond `body_slug`.
