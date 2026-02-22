# Phase 20: Compare Bug Fix - Context

**Gathered:** 2026-02-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the comparison politician overlay on the radar chart so it renders exactly once, eliminating the double-shape visual artifact on the compare page. Removing and re-adding a comparison should produce the same clean single overlay.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
- Overlay appearance (opacity, color, layering) — keep current design intent, just fix the double render
- Toggle behavior (animation style when adding/removing comparison) — maintain existing transitions
- Fix boundary — address root cause of double render; clean up related rendering issues if they contribute to the bug

</decisions>

<specifics>
## Specific Ideas

No specific requirements — user confirmed all aspects are straightforward. Fix the bug cleanly.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 20-compare-bug-fix*
*Context gathered: 2026-02-21*
