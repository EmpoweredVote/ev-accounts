# Phase 12: Quick UX Fixes - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix two UX issues in CompassV2: (1) Library page defaults to showing all topics instead of only unanswered, and (2) question framing changes from "What should the government do about..." to "Where do you stand on [topic]?" with a content pass on vague topic titles. No new capabilities — just default behavior and text changes.

</domain>

<decisions>
## Implementation Decisions

### Library default filter
- Replace the current checkbox filter with a toggle switch
- Toggle states: "All" (default) / "Unanswered"
- Default to "All" — user sees every topic on first visit
- Position the toggle switch above the topic cards (between intro text and first card)
- When on "All", answered topics get a subtle indicator (small checkmark or muted badge) — same card style, just a visual hint

### Question framing text
- New framing: "Where do you stand on [topic]?" — replaces old "What should the government do about..."
- Appears on Library topic cards AND quiz/answer view
- On Library cards: Claude decides how it relates to the topic title (layout flexibility)
- In quiz/answer view: appears as a prompt above the answer options
- Exact same framing text everywhere — no shortened variants

### Topic title rewrites
- Rewrite vague topic titles directly in the database (not display-only mapping)
- Style: short descriptive action phrases (e.g., "Misinformation" → "Combating Online Misinformation") that read naturally in "Where do you stand on ___?"
- Batch review process: Claude drafts all rewrites, presents a before/after table for user approval before applying
- Radar chart keeps short labels — does NOT use the new longer titles
- Add a `short_name` field to topics for radar chart labels, independent of the full title

### Transition behavior
- New framing applies to ALL topics — answered and unanswered alike. No distinction based on prior interaction
- Title is a display field linked by topic ID — renaming doesn't require answer migration
- No user notification about the change — it just appears naturally on next visit

### Claude's Discretion
- Library card layout for framing text relative to topic title
- Toggle switch styling details (colors, size, animation)
- Exact subtle indicator design for answered topics in "All" view
- Deriving initial `short_name` values from existing titles

</decisions>

<specifics>
## Specific Ideas

- Toggle switch instead of checkbox for the Library filter — user specifically prefers this interaction pattern
- "Where do you stand on [topic]?" must be consistent everywhere it appears — no abbreviations
- Batch approval of topic rewrites — user wants to see the full before/after table before any DB changes

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-quick-ux-fixes*
*Context gathered: 2026-02-18*
