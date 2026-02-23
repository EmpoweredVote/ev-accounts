# Phase 30: Fix Compass Calibration Flow Layout and Write-In Option - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix the answer step layout in CalibrationOverlay to be cohesive (chart and stances aligned, question text above stances not centered on page) and add the write-in option that already exists in Quiz/LibraryDrawer but is missing from the calibration flow.

</domain>

<decisions>
## Implementation Decisions

### Answer step layout
- Change from 60/40 split to 50/50 split (chart left, question + stances right)
- Question text and topic title must sit directly above the stances column, not centered across the full page width
- Radar chart vertically centers beside the stances column (stances take natural height, chart aligns to their center)
- Dead space between chart and stances must be eliminated — they should read as a unified pair
- Mobile: keep chart visible above stances in column layout (don't hide it)

### Write-in integration
- Use the same drag-and-drop approach as Quiz page (dnd-kit with PointerSensor + TouchSensor)
- "Write your own..." trigger button appears below all stance cards
- When write-in activates, chart stays visible in the 50/50 split — drag-and-drop list replaces the stances on the right
- Support both desktop and mobile (reuse existing touch sensor implementation from Quiz page)
- Data handling: same decimal positioning system (writeIns stored in CompassContext, synced to localStorage)

### Claude's Discretion
- Sticky vs scrolling header (topic pills + progress bar) — pick what works with new layout
- Exact chart sizing within the 50% column
- Transition animation when switching between stance mode and write-in mode
- Mobile chart size above stances

</decisions>

<specifics>
## Specific Ideas

- Current layout problem visible in screenshots: radar chart floats with excessive whitespace, stances pushed far right, question text centered on full page width instead of anchored above stances
- Second screenshot (5 topics) shows slightly better proportions but same structural issue
- Existing write-in pattern in Quiz.jsx and LibraryDrawer.jsx should be reused — SortableWriteInCard, SortableStanceLabel components, same drag-and-drop mechanics

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 30-fix-compass-calibration-flow-layout-and-write-in-option*
*Context gathered: 2026-02-22*
