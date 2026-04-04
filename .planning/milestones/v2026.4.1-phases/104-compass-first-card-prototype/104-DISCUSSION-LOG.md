# Phase 104: Compass-First Card Prototype - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 104-compass-first-card-prototype
**Areas discussed:** Card layout, Photo treatment, Mock data strategy, Page structure, Layout variants

---

## Card Layout

| Option | Description | Selected |
|--------|-------------|----------|
| Radar dominant | Radar chart takes ~60% of card area at top, name/title below | ✓ |
| Side-by-side split | Radar on left half, name/title/photo on right | |
| Compact radar badge | Small ~80px radar as corner badge | |

**User's choice:** Radar dominant
**Notes:** User selected the preview showing radar as visual anchor with name/title below

### Dual Overlay

| Option | Description | Selected |
|--------|-------------|----------|
| Dual overlay | Coral (user) + blue (politician) when user has compass data | ✓ |
| Politician-only | Always just politician's radar in blue | |
| You decide | Claude picks | |

**User's choice:** Dual overlay

### Interactivity

| Option | Description | Selected |
|--------|-------------|----------|
| Static view-only | Radar as visual summary only, click card for full profile | ✓ |
| Interactive | Clickable spokes for inversion toggle on card | |
| You decide | Claude picks | |

**User's choice:** Static view-only

### Spoke Labels

| Option | Description | Selected |
|--------|-------------|----------|
| Shape only | No labels on mini radar, cleaner at card size | ✓ |
| Abbreviated labels | Short 1-2 word topic labels around radar | |
| You decide | Claude picks | |

**User's choice:** Shape only

### Radar Size

| Option | Description | Selected |
|--------|-------------|----------|
| ~150px square | Fits well in card width | |
| ~200px square | Larger, more detail visible | ✓ |
| You decide | Claude picks | |

**User's choice:** ~200px square

### Card Navigation

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, same nav | Click navigates to /politician/:id | ✓ |
| No navigation | Cards are view-only | |
| You decide | Claude picks | |

**User's choice:** Yes, same nav

### Icons

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, include icons | Keep Phase 103 icon overlays | ✓ |
| Skip icons for prototype | Focus on compass layout only | |
| You decide | Claude picks | |

**User's choice:** Yes, include icons

### Card Background

| Option | Description | Selected |
|--------|-------------|----------|
| White background | Clean white, radar colors only | ✓ |
| Tier-tinted background | Light teal tint behind radar | |
| You decide | Claude picks | |

**User's choice:** White background

---

## Photo Treatment

| Option | Description | Selected |
|--------|-------------|----------|
| No photo at all | Remove headshot entirely, radar IS the visual identity | ✓ |
| Small avatar beside name | ~32-40px circular photo next to name/title | |
| Small avatar in radar center | ~40px circular photo centered inside radar | |

**User's choice:** No photo at all

### No-Data Placeholder

| Option | Description | Selected |
|--------|-------------|----------|
| Initials placeholder radar | Empty radar with initials in center | |
| Fall back to current photo card | Show existing PoliticianCard for no-data politicians | |
| Hide them entirely | Only show politicians with mock data | |

**User's choice:** Other — "We should have a placeholder radar but I don't think we need initials. We'll have their name below, so just the placeholder radar/compass."

### Placeholder Styling

| Option | Description | Selected |
|--------|-------------|----------|
| Dashed outline | Dashed polygon outline in light gray | ✓ |
| Faint filled shape | Very light gray filled polygon | |
| You decide | Claude picks | |

**User's choice:** Dashed outline

---

## Mock Data Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| JSON file in essentials | Local JSON/JS mapping politician IDs to mock stances | ✓ |
| Inline in component | Hardcode directly in prototype component | |
| You decide | Claude picks | |

**User's choice:** JSON file in essentials

### Coverage

| Option | Description | Selected |
|--------|-------------|----------|
| ~5-8 politicians | Enough to fill visible section, mixed with placeholders | |
| All politicians for one address | Mock stances for every politician returned | ✓ |
| You decide | Claude picks | |

**User's choice:** All politicians for one address

### Address

| Option | Description | Selected |
|--------|-------------|----------|
| Bloomington, IN | Monroe County, richest data coverage | ✓ |
| LA County, CA | Larger count, more complex structure | |
| You decide | Claude picks | |

**User's choice:** Bloomington, IN

### Stance Values

| Option | Description | Selected |
|--------|-------------|----------|
| Varied and plausible | Hand-craft distinct profiles, assign to politicians | ��� |
| Random values | Generate random stance values | |
| You decide | Claude picks | |

**User's choice:** Varied and plausible

### Topic IDs

| Option | Description | Selected |
|--------|-------------|----------|
| Real topic IDs | Use actual UUIDs from compass.topics | ✓ |
| Placeholder topics | Invent fake topic names/IDs | |
| You decide | Claude picks | |

**User's choice:** Real topic IDs

---

## Page Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Full rep layout | Mirror Results page — tier sections, CategorySection headers, card grid | ✓ |
| Simple showcase grid | Flat grid, no tier grouping | |
| You decide | Claude picks | |

**User's choice:** Full rep layout

### Header

| Option | Description | Selected |
|--------|-------------|----------|
| Brief banner | Small explanatory banner at top | ✓ |
| No explanation | Just cards, no context | |
| You decide | Claude picks | |

**User's choice:** Brief banner

### Data Source

| Option | Description | Selected |
|--------|-------------|----------|
| Live API fetch | Hit /api/essentials/search on page load | ✓ |
| Static snapshot | Hardcode full politician list | |
| You decide | Claude picks | |

**User's choice:** Live API fetch

### Sidebar

| Option | Description | Selected |
|--------|-------------|----------|
| Main content only | No sidebar, address input, or LocationBrowser | ✓ |
| Full Results layout with sidebar | Mirror exact Results page including sidebar | |
| You decide | Claude picks | |

**User's choice:** Main content only

### Grid Density

| Option | Description | Selected |
|--------|-------------|----------|
| Same responsive grid | Reuse Results page breakpoints, 2-3 cards per row | |
| Wider cards, fewer per row | Larger cards, 2 max on desktop | ✓ |
| You decide | Claude picks | |

**User's choice:** Wider cards, fewer per row

### SiteHeader

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, include SiteHeader | Consistent with every other essentials page | ✓ |
| No header | Minimal prototype, no nav chrome | |
| You decide | Claude picks | |

**User's choice:** Yes, include SiteHeader

---

## Layout Variants

User requested 2-3 prototype layout options to compare visually, not just one fixed design. Mentioned using frontend-design skill.

| Option | Description | Selected |
|--------|-------------|----------|
| Toggle switcher on page | Small control at top to switch between variants | ✓ |
| Separate sub-routes | /prototype/a, /prototype/b, /prototype/c | |
| All variants on one page | Stacked vertically, see all at once | |

**User's choice:** Toggle switcher on page

### Variant Dimension

| Option | Description | Selected |
|--------|-------------|----------|
| Card shape/density | Tall/spacious vs compact/dense vs wide/horizontal | ✓ |
| Photo inclusion | No photo vs avatar beside name vs avatar in center | |
| Information density | Minimal vs medium vs rich | |

**User's choice:** Card shape/density

---

## Claude's Discretion

- Segmented control styling for variant toggle
- Responsive breakpoints for each variant's grid
- Exact topic IDs (researcher queries compass.topics)
- Politician-to-profile-type mapping for mock data
- Dashed outline placeholder exact styling

## Deferred Ideas

None — discussion stayed within phase scope
