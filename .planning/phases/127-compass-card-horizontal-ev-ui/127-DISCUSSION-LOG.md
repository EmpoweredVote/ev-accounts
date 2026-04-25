# Phase 127: CompassCardHorizontal in ev-ui - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-19
**Phase:** 127-compass-card-horizontal-ev-ui
**Areas discussed:** Component API shape, View toggle persistence, Metadata parity layout, Prototype harness + tokens

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Component API shape | Props contract; monolithic vs slot-based | ✓ |
| View toggle persistence | Per-page / per-session / localStorage / parent-controlled | ✓ |
| Metadata parity layout | Affordance placement in narrower meta column | ✓ |
| Prototype harness + tokens | Harness location + styling source | ✓ |

---

## Component API shape

### Q1: How should CompassCardHorizontal accept data?

| Option | Description | Selected |
|--------|-------------|----------|
| Flat props (Recommended) | politician, userAnswers, tierVisuals as separate props | ✓ |
| Single config object | One `data` prop containing all fields | |
| Slot-based composition | `<CompassCard.Radar/>`, `<CompassCard.Meta/>`, `<CompassCard.Toggle/>` | |

**User's choice:** Flat props (Recommended)

### Q2: Where does the radar SVG come from inside the card?

| Option | Description | Selected |
|--------|-------------|----------|
| Internal RadarChartCore (Recommended) | Card imports RadarChartCore internally | ✓ |
| Render-prop / children | Consumer passes pre-rendered radar | |
| Portrait mode only swaps | Always RadarChartCore; swap for photo in portrait | |

**User's choice:** Internal RadarChartCore (Recommended)

---

## View toggle persistence

### Q1: When the user clicks compass↔portrait, what should stick?

| Option | Description | Selected |
|--------|-------------|----------|
| Global per-session (Recommended) | One page-level toggle flips all cards; localStorage-persisted | ✓ |
| Per-card, per-session | Each card toggles; persists via localStorage keyed by politician | |
| Per-card, page-only | Each card toggles; resets on navigation | |
| Parent-controlled (headless) | `view` + `onViewChange` props; consumer owns persistence | |

**User's choice:** Global per-session (Recommended)

### Q2: Where does the toggle control live?

| Option | Description | Selected |
|--------|-------------|----------|
| Small icon button on each card (Recommended) | Icon in card corner, per-card toggle | |
| Page-level SegmentedControl only | One top-of-page control, no per-card toggle | ✓ |
| Both | Per-card + page-level | |

**User's choice:** Page-level SegmentedControl only
**Notes:** Combined with global-per-session persistence, this implies the card takes a controlled `view` prop — no per-card toggle button in the component itself.

---

## Metadata parity layout

### Q1: The meta column is narrower than current PoliticianCard. How to handle the affordance set?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep everything, stack vertically (Recommended) | All affordances preserved, more aggressive wrap | |
| Keep everything, two-row badge strip | Badges in a horizontal strip above name | |
| Drop secondary metadata to profile | Move years/term to profile only | |
| Other (free-text) | User described exact split per surface | ✓ |

**User's choice:** Free-text — "Representatives: name, position, district/ward/etc, icons. Elections: name, position running for, district/ward/etc, icons, and a 'running unopposed' banner where applicable."
**Notes:** Implies a surface-aware variant (representatives vs elections) in the component API.

### Q2: In portrait/photo view (compass hidden), what replaces the radar slot?

| Option | Description | Selected |
|--------|-------------|----------|
| Large portrait + initials fallback (Recommended) | Photo fills radar slot at same dimensions | ✓ |
| Portrait + stance summary snippet | Smaller photo + short summary line | |
| Portrait only; card shrinks | Card becomes more compact in portrait mode | |

**User's choice:** Large portrait + initials fallback (Recommended)

---

## Prototype harness + tokens

### Q1: Where does the prototype harness live?

| Option | Description | Selected |
|--------|-------------|----------|
| Keep essentials /prototype (Recommended) | Continue using existing page until Phase 129 retirement | ✓ |
| Add ev-ui demo page | New /demo route inside ev-ui | |
| Both — ev-ui demo + essentials prototype | Migrate canonical harness; keep essentials as smoke test | |

**User's choice:** Keep essentials /prototype (Recommended)

### Q2: Variant C currently inlines style constants. How should the published component source its look?

| Option | Description | Selected |
|--------|-------------|----------|
| Pull from ev-ui tokens.js (Recommended) | Colors/spacing/radii/shadows from tokens.js + tailwind-preset | ✓ |
| Bake variant C constants inline | Copy variant C style values as-is | |
| Tokens where they exist, inline the rest | Pragmatic compromise | |

**User's choice:** Pull from ev-ui tokens.js (Recommended)

---

## Claude's Discretion

- Internal file layout in `ev-ui/src/`
- Exact prop name for the representatives-vs-elections surface distinction
- Where the localStorage key lives (likely essentials)
- Test approach and lib (match ev-ui conventions)
- Graceful handling when `userAnswers` / `tierVisuals` are missing

## Deferred Ideas

- Empty/no-compass/administrative/judicial variants → Phase 128
- Essentials page adoption + `/prototype` retirement → Phase 129
- ev-ui standalone demo page (could resurface if ev-ui grows)
- Per-card inline view toggle
- Stance summary snippet in portrait view
