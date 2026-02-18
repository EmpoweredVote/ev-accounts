# Phase 6: Audit Gap Closure - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Close 3 integration gaps found by the v1 milestone audit: Quiz.jsx missing question_text display, Register.jsx not sending guest_state on the banner registration path, and CandidateOut.ChamberName not populated from BallotReady race data. No new features — strictly fixing what was missed in Phases 4 and 5.

</domain>

<decisions>
## Implementation Decisions

### Quiz question display
- Claude's discretion on whether question_text fully replaces the title or shows both (match Library card approach)
- Shrink font progressively to fit full question text rather than truncating with ellipsis
- Applies to both full quiz mode and curated quiz mode
- Also verify ComparePanel shows question_text — fix if missing (not just Quiz cards)
- Fallback chain: question_text -> title (standard pattern)

### Registration answer feedback
- Toast notification after successful registration: brief confirmation like "Your quiz answers have been saved to your account"
- Same toast regardless of merge outcome — don't surface server-wins merge complexity to user
- Fix Register.jsx (standalone page from banner) AND verify inline modal path still sends guest_state correctly
- User stays on current page after registration — banner disappears since they're now logged in

### Candidate chamber classification
- Claude's discretion on fallback approach when BallotReady race data lacks clear chamber name (generic group vs keyword inference)
- Keep current Phase 5 candidate display behavior — just fix ChamberName so grouping works correctly
- Show candidates even with minimal data — don't filter out incomplete records
- **No party affiliation on any candidate card** — even when BallotReady provides party data, do not display it

### Claude's Discretion
- Quiz heading approach (replace vs primary/secondary) — match whatever Library cards already do
- ChamberName fallback strategy — pick the approach that produces most accurate groupings
- Toast styling — match existing toast patterns in the app

</decisions>

<specifics>
## Specific Ideas

- "No party affiliation" is a hard rule for all candidate cards, not just incomplete ones — this is a deliberate product decision
- Toast for answer preservation should be brief and reassuring, not technical
- ComparePanel needs the same question_text treatment as Quiz cards — audit both

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-audit-gap-closure*
*Context gathered: 2026-02-18*
