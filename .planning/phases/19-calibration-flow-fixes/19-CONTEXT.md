# Phase 19: Calibration Flow Fixes - Context

**Gathered:** 2026-02-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the compass calibration flow to correctly handle all mixed answered/unanswered topic states. Users with unanswered topics are auto-routed into calibration, the radar chart renders gracefully with partial data, the below-3 threshold shows a calibration prompt instead of a dead end, and completing calibration from any state produces a fully rendered compass. No new features — this is edge-case fixing for the existing calibration and compass rendering.

</domain>

<decisions>
## Implementation Decisions

### Auto-routing behavior
- Instant redirect: user lands on /compass with unanswered topics and is immediately sent into calibration — no compass shown first
- Calibration starts at the first unanswered topic and steps through remaining unanswered topics sequentially (no pick screen)
- Exit is available only after the user has at least 3 answered topics — before that, they must continue calibrating
- Once 3+ answered, a "View compass" or "Skip" option becomes available to bail out early

### Mixed-state radar chart
- All selected topic spokes are visible, but unanswered spokes are grayed out / dashed with no data point
- Unanswered (gray) spokes are clickable — clicking opens calibration for that specific topic
- The filled user shape draws to center (zero) for unanswered spokes — shape pinches inward at those positions
- Chart re-renders immediately when topics are added or removed — no save/confirm step

### Below-3 threshold
- When answered topics are fewer than 3, the chart area shows an inline message with a specific count: "Answer X more topics to see your compass" plus a CTA button to enter calibration
- Full page layout remains visible (Library, navigation, etc.) — only the chart area is replaced by the prompt
- Deselecting topics to drop below 3 shows the inline prompt only — no auto-routing into calibration in this case (user chooses when to re-enter)

### Calibration resumption
- Already-answered topics appear in the calibration flow but are marked as completed (checkmark, grayed card) — user can see their progress
- Answered topics are tappable to re-answer — clicking a completed card re-opens it for re-calibration
- No progress indicator (counter or bar) — the completed/uncompleted card states serve as the visual progress
- When all topics are answered, calibration disappears and compass renders instantly — no completion animation or celebration moment

### Claude's Discretion
- URL routing strategy (whether auto-routing changes URL to /compass/calibrate or stays on /compass)
- Exact gray spoke visual style (dashed lines, opacity levels, etc.)
- Transition animations between calibration and compass states
- Exact wording and styling of the below-3 inline prompt

</decisions>

<specifics>
## Specific Ideas

No specific references — open to standard approaches that fit the existing compass and calibration UI patterns.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 19-calibration-flow-fixes*
*Context gathered: 2026-02-21*
