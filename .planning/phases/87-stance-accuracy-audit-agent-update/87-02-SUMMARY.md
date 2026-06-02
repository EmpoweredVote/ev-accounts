---
phase: 87-stance-accuracy-audit-agent-update
plan: 02
subsystem: agent-config
tags: [skill, research-stances, five-chairs, agent-prompt, stance-accuracy]

# Dependency graph
requires:
  - phase: 87-stance-accuracy-audit-agent-update
    provides: "87-CONTEXT.md D-01 through D-04 — five-chairs philosophy text, replacement decision, and block content"
provides:
  - "SKILL.md updated with five-chairs framing block replacing SCALE RULE block"
  - "Researcher agent evaluative posture: text-match-to-chair, direction-agnostic, defensibility-required"
  - "Topic Resolution query updated to fetch stance texts alongside topic IDs and keys"
  - "TOPIC SCALE REFERENCE section added to agent prompt template with full stance text"
affects: [research-stances, phase-88-stance-corrections, politician-stance-researcher]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Five-chairs evaluative posture: agent reads stance text per value and matches documented record to chair, not to directional assumption"
    - "TOPIC SCALE REFERENCE: stance texts embedded in agent prompt at dispatch time so agent never infers direction from position alone"

key-files:
  created: []
  modified:
    - ".claude/skills/research-stances/SKILL.md"

key-decisions:
  - "SCALE RULE — CRITICAL block removed entirely; FIVE-CHAIRS FRAMING block is the sole authoritative voice on value assignment (D-01)"
  - "Five-chairs text sourced verbatim from CONTEXT.md D-02 / specifics — not paraphrased; wording finalized by planner"
  - "Topic Resolution query extended to include stance texts (json_agg of value+text) so agents receive full scale at dispatch"
  - "TOPIC SCALE REFERENCE section added after FIVE-CHAIRS block so agent prompt flows naturally into the per-topic text reference"

patterns-established:
  - "Five-chairs framing: assign values by text-match to named chair, never by directional or partisan assumption"
  - "Defensibility requirement: every assignment must support the claim 'they both hold the position that [specific written text]'"

requirements-completed:
  - SACC-04

# Metrics
duration: 18min
completed: 2026-06-02
---

# Phase 87 Plan 02: SKILL.md Five-Chairs Framing Summary

**SCALE RULE block replaced with five-chairs framing in research-stances/SKILL.md — researcher agents now match documented record to named chair text, never infer value from party or direction**

## Performance

- **Duration:** 18 min
- **Started:** 2026-06-02T21:00:00Z
- **Completed:** 2026-06-02T21:18:00Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Replaced 6-line `SCALE RULE — CRITICAL` block with 20-line `FIVE-CHAIRS FRAMING` block in the STEP 1 agent prompt template
- Extended Topic Resolution query (STEP 0) to include stance texts via `json_agg` join on `inform.compass_stances`
- Added `TOPIC SCALE REFERENCE` section to agent prompt so agents see full stance text for each value at dispatch time
- All surrounding SKILL.md structure preserved: STEP 0–4, ERROR HANDLING, REWRITE RE-EVALUATION MODE, TOOL RULE, dispatch rules

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace SCALE RULE block with FIVE-CHAIRS FRAMING block in SKILL.md** - `cd1dea6` (feat)

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `.claude/skills/research-stances/SKILL.md` — FIVE-CHAIRS FRAMING block replaces SCALE RULE; Topic Resolution query extended to include stance texts; TOPIC SCALE REFERENCE section added to agent prompt template

## Decisions Made

- **Applied full restructuring alongside framing swap:** The worktree was initialized at commit `602e2b5` (the clean HEAD), which contained the old SKILL.md without either SCALE RULE or FIVE-CHAIRS blocks. The main repo's working directory had uncommitted changes that added SCALE RULE + TOPIC SCALE REFERENCE. Rather than applying only a narrow text replacement (which would have left the file without the stance-text query), the full intended restructuring was applied to the worktree with FIVE-CHAIRS substituted for SCALE RULE. This matches the plan's stated intent: the planner wrote 87-02 to take the file from pre-restructuring to final state.

- **FIVE-CHAIRS block placed before TOPIC SCALE REFERENCE:** Per PATTERNS.md, the FIVE-CHAIRS block opens the evaluative framing section; TOPIC SCALE REFERENCE follows it. This order ensures the agent reads the evaluative posture before seeing the per-topic value texts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Applied full SKILL.md restructuring rather than narrow 6-line replacement**

- **Found during:** Task 1 (Replace SCALE RULE block)
- **Issue:** The worktree's SKILL.md was at the pre-restructuring state (commit 602e2b5) — it had neither SCALE RULE nor the TOPIC SCALE REFERENCE section. The plan's action described a "surgical text replacement" of the SCALE RULE block, but the block did not exist in the worktree. A narrow edit would have left the file missing the stance-text query and TOPIC SCALE REFERENCE section.
- **Fix:** Applied the full intended final state: updated Topic Resolution query to include stance texts, substituted FIVE-CHAIRS FRAMING for SCALE RULE, added TOPIC SCALE REFERENCE section, preserved all other structure (STEP 0–4, rewrite mode, TOOL RULE). This is the state the planner intended as the output of this plan.
- **Files modified:** `.claude/skills/research-stances/SKILL.md`
- **Verification:** Automated node verify script passes; all acceptance criteria grep checks pass
- **Committed in:** `cd1dea6` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking)
**Impact on plan:** Auto-fix necessary because the worktree's starting state differed from the plan's assumption. The outcome is the correct intended final state.

## Issues Encountered

- Worktree initialized at `602e2b5` which predates the main repo's working-directory SKILL.md changes. The plan assumed SCALE RULE was present in the file at execution time; it was not. Resolved by applying the full intended restructuring as a single write, substituting FIVE-CHAIRS for SCALE RULE as specified.

## User Setup Required

None — no external service configuration required.

## Verification Results

All acceptance criteria confirmed passing:

| Check | Result |
|-------|--------|
| `grep "SCALE RULE" SKILL.md` | 0 matches |
| `grep -c "FIVE-CHAIRS FRAMING" SKILL.md` | 1 |
| `grep -iE "five (named )?chairs" SKILL.md` | Match: "five named chairs in a room" |
| `EXACT TEXT at this value?` present | Yes |
| Defensibility claim present | Yes: "defensible with the specific written text" |
| Direction-varies rule present | Yes: "direction varies by topic" + "no correct end" |
| `TOPIC SCALE REFERENCE` preserved | Yes |
| `TOOL RULE — CRITICAL` preserved | Yes |
| `subagent_type: "politician-stance-researcher"` present | Yes |
| `REWRITE RE-EVALUATION MODE` preserved | Yes |
| File grows by ~16+ lines net | Yes: +53 insertions, -12 deletions = +41 net |

## Next Phase Readiness

- SACC-04 closed: all future `/research-stances` runs will dispatch agents with five-chairs framing
- Phase 88 can begin stance corrections; researcher agents will now match documented record to chair text rather than inferring direction from party
- The `87-AUDIT-REPORT.md` from plan 87-01 provides the correction priority queue for Phase 88

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. This plan edited a single agent configuration file (SKILL.md). No threat flags.

---
*Phase: 87-stance-accuracy-audit-agent-update*
*Completed: 2026-06-02*
