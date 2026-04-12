---
name: 260412-lqd CONTEXT
description: Center calibration question title in CompassV2 (full + curated modes)
type: quick-task-context
---

# Quick Task 260412-lqd: Center calibration question title - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Task Boundary

Fix off-center question/title in CompassV2 calibration screens. Root cause: the
flex wrapper around `<h1>` + `?` icon link (added when the how-it-works page was
introduced) is missing `justify-center`, so it stretches full-width and
left-aligns its children while the category pill above and the topic subtitle
below remain centered.

Affected: `CompassV2/src/pages/Quiz.jsx`
- Full mode: line 573 `<div className="flex items-center gap-2">`
- Curated mode: line 681 `<div className="flex items-center gap-2">`

</domain>

<decisions>
## Implementation Decisions

### Fix scope
- Fix both full mode and curated mode. Same bug, same fix, keeps modes visually
  consistent.

### Icon alignment on wrapped questions
- Keep `items-center` (vertical centering). Add `justify-center` for horizontal
  centering. Icon stays centered on the block when question wraps to 2 lines.

### Claude's Discretion
- Exact class change: add `justify-center` to the existing flex wrapper
  (`flex items-center gap-2 justify-center`). No other restructuring.

</decisions>

<specifics>
## Specific Ideas

User screenshot shows: "CIVIL RIGHTS AND SOCIAL POLICY" pill centered, question
text "What role should government play..." left-aligned with `?` icon trailing,
"Civil Rights" subtitle centered. Goal: question line also centered.

</specifics>

<canonical_refs>
## Canonical References

No external specs — pure layout fix.

</canonical_refs>
