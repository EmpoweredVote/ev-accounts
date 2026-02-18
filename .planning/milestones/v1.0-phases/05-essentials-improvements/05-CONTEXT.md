# Phase 5: Essentials Improvements - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Enhance the Essentials politician view with four capabilities: optional candidate visibility alongside officials, federal section reordering, position term dates on profile cards, and tier-specific building imagery in the sidebar. The underlying data pipeline (BallotReady integration, caching) is already built — this phase is about presentation and display improvements.

</domain>

<decisions>
## Implementation Decisions

### Candidate toggle & integration
- Toggle switch (on/off) labeled "Show Candidates" — not tabs
- Toggle placement is subtle/secondary — doesn't compete with main results
- Default state: off (officials only)
- When toggled on, candidate cards appear **inline alongside** officials within the same tier categories (e.g., a Senate candidate sits next to current U.S. Senators in the Federal section)
- No separate "Candidates" section — they mix into existing tier structure

### Candidate card design
- Corner badge saying "Candidate" in EV coral (#ff5740) — the primary visual differentiator
- Card layout otherwise matches official cards
- Show profile photo if available (same treatment as officials)
- Additional info on candidate cards: **election date + race name** (e.g., "Nov 2026 — U.S. Senate")

### Building imagery
- Real photographs in **tall/portrait orientation** in the left sidebar, below the tier radio buttons (matching current Bloomington screenshot layout)
- **Scroll-spy behavior on "All" filter**: image defaults to local building, then transitions to state capitol as user scrolls to state officials, then to U.S. Capitol for federal section
- When a specific tier filter is selected (Local/State/Federal), show that tier's building image statically
- **Match to user's searched location**: show the actual buildings for their city, their state capitol, and U.S. Capitol
- MVP localities with curated images: **Bloomington, IN (Monroe County)** and **Los Angeles, CA (Los Angeles County)**
- All other localities get a generic fallback image per tier

### Position term dates
- Format: **Month Year — Month Year** (e.g., "Jan 2023 — Dec 2026")
- Placement: directly below the politician's title/role on the card
- **Show actual term end date, not "Present"** — users should see when the elected term expires and reelection is needed
- If date data is unavailable: **hide the date line entirely** (no placeholder text)

### Federal category ordering
- Exact order: U.S. Senate > U.S. House > President/VP > Cabinet > Agencies
- Legislative branch first, then executive branch

### Claude's Discretion
- Scroll-spy implementation approach (IntersectionObserver vs scroll events)
- Toggle switch styling details (size, exact placement in sidebar)
- Candidate badge exact positioning and sizing within card corner
- Fallback building image selection for non-curated localities
- Image transition animation between buildings during scroll
- How to source/store building images (Supabase Storage bucket structure)

</decisions>

<specifics>
## Specific Ideas

- Building image placement follows the existing Bloomington screenshot layout — tall photo in left sidebar below filters, with location label above it
- The scroll-spy image swap on "All" filter creates a sense of progression as users move through government tiers
- Term dates serve an informational purpose about election cycles, not just indicating "currently serving" — this helps voters understand when seats are contested
- Candidate cards in coral badge should feel clearly distinct but not alarming — the badge is a label, not a warning

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-essentials-improvements*
*Context gathered: 2026-02-18*
