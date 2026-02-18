# Phase 4: Compass UX Enhancements - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Enrich the compass quiz experience with question prompts on issue cards and the compare page, stable per-user stance randomization (direction flip), inline answer editing from the Library page via a slide-in panel, and federal/state/local level indicators on issue cards. No new quiz mechanics or navigation changes.

</domain>

<decisions>
## Implementation Decisions

### Question prompts
- Question text **replaces** the category title on issue cards — cards show the question (e.g., "What should the government do about healthcare?"), not the bare title
- On the compare page, the question appears **above the stances** as a header, separate from the politician stance columns
- Backend seeds default question text using a template like "What should the government do about {title}?" — admins can customize via textarea in the admin topic editor
- If a topic has no question set, the **frontend auto-generates** "What should the government do about {title}?" on the fly — no empty states

### Library popup (slide-in panel)
- Clicking an issue card on the Library page opens a **slide-in panel from the right** (drawer style) — library grid stays visible behind it
- Stances in the panel use the **same UI as the quiz** answer options — consistent experience
- Selecting a different stance **saves instantly** (localStorage and/or server) and the **panel stays open** for review — no save button needed
- Panel content is **minimal: question + stances only** — no extra topic metadata or descriptions

### Stance randomization
- Per-user seed stored as a **localStorage guest ID** generated on first visit
- Each topic's stances are either shown in **original order or fully reversed** (binary flip per topic, decided by seed) — not a full shuffle, preserving the spectrum
- When a guest creates an account, the **guest seed migrates** to the account — stance order never changes for that user
- If a guest clears localStorage or uses a new browser, they get a **fresh guest ID and new randomization** — acceptable since they're anonymous

### Level indicators
- Level shown as **icon + text** at the **bottom of the issue card** (footer position)
- Icons are **custom SVG** matching the EV design system (Capitol dome for federal, state house for state, city hall for local)
- Level data comes from a **new column on compass.topics** (federal/state/local enum) — admin sets it per topic

### Claude's Discretion
- SVG icon design for the three level indicators
- Exact slide-in panel animation and width
- Spacing and typography adjustments for question text replacing titles
- How the admin textarea for question editing integrates with the existing topic form

</decisions>

<specifics>
## Specific Ideas

- Question replacement should feel natural — the card's primary text IS the question, not a title with a question tacked on
- Slide-in panel should feel lightweight, not modal-heavy — the library stays visible
- Stance flip should be invisible to users — they should never know the order was randomized

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-compass-ux-enhancements*
*Context gathered: 2026-02-17*
