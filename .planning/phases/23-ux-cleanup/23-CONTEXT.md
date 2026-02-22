# Phase 23: UX Cleanup - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove stale controls from Compass and Library pages, fix mobile stat card layout, and restructure text hierarchy so the question text drives user engagement. Requirements: UX-01 through UX-04.

</domain>

<decisions>
## Implementation Decisions

### Button removals (UX-01, UX-02)
- Remove "Edit Topics" button from the compass page entirely — users navigate to Library to edit topics
- Remove "Clear" button from the Library page entirely — no replacement affordance

### Mobile stat cards (UX-03)
- Answered/Remaining stat cards on the Library page must fill full width on mobile screens
- No partial-width or misaligned layout on any mobile viewport

### Text hierarchy restructure (UX-04)
This is a significant hierarchy swap — the question text becomes the primary content users engage with.

**Library page cards:**
- Topic name stays as the card title (e.g., "Healthcare")
- Question text replaces the tension poles as the subtitle (e.g., "How should healthcare be funded and delivered?")

**LibraryDrawer (stance selection view):**
- Question text becomes the title (e.g., "How open or restrictive should immigration policy be?")
- Topic name becomes the subtitle (e.g., "Immigration") — just the name, no poles
- The separate italic question text line currently between subtitle and stances is removed (it moved to title position)

**Quiz page:**
- Same swap as LibraryDrawer — question text becomes the h1 title, topic name moves to subtitle position

**Tension poles (e.g., "Open Borders & Expanded Entry — Closed Borders & Restricted Entry"):**
- Remove entirely from all views — Library cards, LibraryDrawer, and Quiz page
- The question text captures the spectrum well enough on its own

### Claude's Discretion
- Exact font sizes and weights for the swapped hierarchy
- Styling of the new subtitle lines (color, weight, spacing)
- Any transition/animation adjustments needed after the swap
- Mobile stat card implementation details (flexbox, grid, etc.)

</decisions>

<specifics>
## Specific Ideas

- User referenced the current LibraryDrawer screenshot showing "Immigration" as title with "Open Borders & Expanded Entry — Closed Borders & Restricted Entry" as subtitle and italic question text below — wants this inverted so the question drives the view
- The intent is that questions are what users actually need to engage with — topic names are labels, not the content

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 23-ux-cleanup*
*Context gathered: 2026-02-22*
