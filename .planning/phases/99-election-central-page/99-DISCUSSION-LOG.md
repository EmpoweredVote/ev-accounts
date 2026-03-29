# Phase 99: Election Central Page - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-29
**Phase:** 99-election-central-page
**Areas discussed:** Navigation & Entry Point, Race Card Layout, Grouping & Hierarchy, Empty & Partial States

---

## Navigation & Entry Point

### How should users access Election Central?

| Option | Description | Selected |
|--------|-------------|----------|
| Tab toggle | "Representatives" / "Elections" tab pair at top of Results page. Same address, toggle between views. | ✓ |
| Separate route with link | New /elections route. Link on Results page navigates with address params. | |
| Integrated inline | "Upcoming Elections" section added below politician grid on same page. | |

**User's choice:** Tab toggle
**Notes:** None

### Should tab state be reflected in URL?

| Option | Description | Selected |
|--------|-------------|----------|
| URL search param | e.g. /results?view=elections&address=... — shareable, back button works | ✓ |
| Separate routes | /results vs /elections — cleaner URLs but route-level changes needed | |
| Client-side only | Component state only — simplest but loses state on refresh/share | |

**User's choice:** URL search param
**Notes:** None

### Default tab when user searches an address?

| Option | Description | Selected |
|--------|-------------|----------|
| Representatives | Current behavior preserved — users see officials first | ✓ |
| Elections (when data exists) | Auto-land on Elections tab if data exists, fallback to Representatives | |
| You decide | Claude picks | |

**User's choice:** Representatives
**Notes:** None

### Visual indicator on Elections tab?

| Option | Description | Selected |
|--------|-------------|----------|
| Count badge | Small number badge like "Elections (3)" | |
| Dot indicator | Simple colored dot when elections exist — subtle, no count | ✓ |
| No indicator | Just "Elections" label — cleanest | |
| You decide | Claude picks | |

**User's choice:** Dot indicator
**Notes:** None

---

## Race Card Layout

### How should each race be displayed?

| Option | Description | Selected |
|--------|-------------|----------|
| Position header + candidate row | Card with position title header, candidates as compact rows | |
| Candidate grid cards | Section header, candidates as individual cards in grid (like PoliticianCard) | ✓ |
| You decide | Claude picks | |

**User's choice:** Candidate grid cards
**Notes:** "The cards should basically be the same as the ones on the results page."

### Incumbent badge style?

| Option | Description | Selected |
|--------|-------------|----------|
| Small text badge | Compact "Incumbent" label in ev-muted-blue below name | ✓ |
| Icon + text | Small icon (checkmark/shield) paired with "Incumbent" text | |
| You decide | Claude picks | |

**User's choice:** Small text badge
**Notes:** None

### Election date and countdown placement?

| Option | Description | Selected |
|--------|-------------|----------|
| Below position header | Subtitle line under position name | |
| Above position header | Top-level banner for the race section | ✓ |

**User's choice:** Above position header
**Notes:** "I imagine the election date and countdown would be at the top of the elections page, like a header."

### Confirm: election header shown once per election, not per race?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, election header once | Date/countdown shown once per election, races listed below | ✓ |
| Per-race date | Each race card shows its own election date | |

**User's choice:** Election header once
**Notes:** None

---

## Grouping & Hierarchy

### Tier building images?

| Option | Description | Selected |
|--------|-------------|----------|
| Same building images | Reuse existing tier building images and CategorySection from ev-ui | ✓ |
| Simplified headers only | Text-only headers without building images | |
| You decide | Claude picks | |

**User's choice:** Same building images
**Notes:** None

### Multiple elections ordering?

| Option | Description | Selected |
|--------|-------------|----------|
| Chronological, soonest first | Nearest election at top — most actionable | ✓ |
| Grouped by type | All Primaries first, then Generals, then Specials | |
| You decide | Claude picks | |

**User's choice:** Chronological, soonest first
**Notes:** None

### Race ordering within tiers?

| Option | Description | Selected |
|--------|-------------|----------|
| By importance | Executive first, then upper chamber, then lower | |
| Same as Representatives page | Follow exact same order as Results page | ✓ |
| Alphabetical | Positions sorted A-Z | |

**User's choice:** Same as Representatives page
**Notes:** "I changed my mind on the order of the races in each tier. I just want it to follow the exact same order as what the representatives page shows, not by importance." Also: "as long as the tiers follow the same order (local first)."

---

## Empty & Partial States

### No elections empty state?

| Option | Description | Selected |
|--------|-------------|----------|
| Friendly message with explanation | Centered message about expanding coverage | ✓ |
| Coverage map context | Names specific coverage areas (Bloomington IN, LA County CA) | |
| You decide | Claude writes copy | |

**User's choice:** Friendly message with explanation
**Notes:** None

### No-photo fallback?

| Option | Description | Selected |
|--------|-------------|----------|
| Initials avatar | Circle with initials in ev-muted-blue — matches PoliticianCard fallback | ✓ |
| Generic silhouette | Person silhouette icon | |
| You decide | Claude picks | |

**User's choice:** Initials avatar
**Notes:** None

### Elections tab dot when no elections?

| Option | Description | Selected |
|--------|-------------|----------|
| Hidden when no elections | Dot only appears when elections exist | ✓ |
| Always visible | Tab always has the dot | |
| You decide | Claude picks | |

**User's choice:** Hidden when no elections
**Notes:** None

---

## Additional Decisions (raised by user)

### Candidate ordering within a race

| Option | Description | Selected |
|--------|-------------|----------|
| Fully random each load | Different order every page load | |
| Seeded per user | Random but stable for user's session — consistent and impartial | ✓ |
| You decide | Claude picks | |

**User's choice:** Seeded per user
**Notes:** "We want the order of the candidates to be random. We don't want anyone to think that we are prioritizing any particular candidate." Aligns with antipartisan mission.

---

## Claude's Discretion

- Loading skeleton design for Elections tab
- Election header visual treatment (typography, spacing)
- Mobile responsive breakpoints for candidate card grid
- Seed derivation for candidate randomization
- Prefetch vs lazy-load election data on tab switch

## Deferred Ideas

None — discussion stayed within phase scope
