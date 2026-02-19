# Phase 13: Topic Selection Enforcement - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Enforce compass topic limits (max 8, min 3) across all entry points, and show compass membership status on Library cards. Users can add and remove topics from the compass via the Library. Creating the onboarding flow is Phase 14.

</domain>

<decisions>
## Implementation Decisions

### Cap reached behavior (max 8 topics)
- Add button on Library cards is disabled (grayed out) when user has 8 topics on the compass
- A counter badge in the Library page header shows "X/8 topics on compass" — persistent and updates live with every add/remove
- Cap enforced across ALL entry points: Library cards, drawer, and any existing quiz flow — not just Library
- No toast or tooltip needed — the disabled button + counter badge communicates the cap

### Under-minimum state (fewer than 3 answered topics)
- Compass page shows a progress message instead of the chart: "Answer X more topics to see your compass"
- Dot progress indicator: 3 dots, filled for answered topics, empty for remaining — minimal and clean
- No CTA button to Library — bottom nav already provides that; just the message + dots
- Immediate swap: if a removal drops the user below 3, the chart is replaced by the progress message instantly

### On-compass indicators (Library cards)
- Library cards for topics on the compass get an ev-light-blue (#59b0c4) border — clear visual distinction
- Indicator on card only, not inside the drawer
- Cards NOT on the compass have no visual change — stay as they are today
- No dimming or muting of non-compass cards

### Remove-from-compass flow
- The add button on a card becomes a remove button (X icon) when the topic is on the compass — single action slot that swaps state
- Remove also available inside the topic drawer as a "Remove from compass" action — both card + drawer
- Quick confirmation popover before removal: "Remove from compass?" with Yes/Cancel
- Removing preserves the user's answer — only removes from compass display, not the stance data
- If removing drops below 3 topics: allow with warning ("Your compass needs 3+ topics to display") but let them proceed
- Instant UI update on removal: border disappears, remove button swaps back to add button, counter badge updates

### Claude's Discretion
- Confirmation popover styling and animation
- Exact counter badge positioning and design in Library header
- Dot progress indicator sizing and placement on compass page
- How disabled state looks on different card variants
- Which existing quiz/add flows need cap enforcement wiring

</decisions>

<specifics>
## Specific Ideas

- Counter badge should feel lightweight — informational, not alarming (think "5/8" in muted text, not a warning badge)
- The add/remove button swap should feel like a toggle — same position, different icon/action

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 13-topic-selection-enforcement*
*Context gathered: 2026-02-18*
