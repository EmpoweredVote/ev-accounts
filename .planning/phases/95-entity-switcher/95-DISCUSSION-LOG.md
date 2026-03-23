# Phase 95: Entity Switcher - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-22
**Phase:** 95-entity-switcher
**Areas discussed:** Switcher placement & style, Hero card adaptation, Data loading on switch, URL & deep linking

---

## Switcher Placement & Style

### Where should the entity switcher live?

| Option | Description | Selected |
|--------|-------------|----------|
| Replace City/State/Federal tabs | The existing NavigationTabs are non-functional placeholders. Replace with entity dropdown in same header position. | ✓ |
| Dropdown above hero card | Place entity selector as prominent element above the hero section. | |
| Sidebar or panel | Side panel listing all entities, always visible. | |

**User's choice:** Replace City/State/Federal tabs
**Notes:** Clean swap — no new UI real estate needed.

### How should entities be grouped?

| Option | Description | Selected |
|--------|-------------|----------|
| By type | Group by entity_type: Cities, Counties, Townships. Matches DB model. | ✓ |
| By state | Group by state: Indiana, California. | |
| Flat list | No grouping, alphabetical. | |

**User's choice:** By type

### Display format

| Option | Description | Selected |
|--------|-------------|----------|
| Name, ST | e.g., "Bloomington, IN" / "Monroe County, IN". Compact, familiar. | ✓ |
| Full name with state | e.g., "City of Bloomington, Indiana". More formal. | |
| You decide | Claude picks best format. | |

**User's choice:** Name, ST

---

## Hero Card Adaptation

### How should the hero section adapt?

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic title, no photo | Title updates, remove background photo entirely. | |
| Dynamic title + per-entity photo | Title AND background photo change per entity. | ✓ |
| Minimal hero — just title bar | Shrink hero to simple title bar. | |

**User's choice:** Dynamic title + per-entity photo

### Where should entity photos come from?

| Option | Description | Selected |
|--------|-------------|----------|
| Config file URLs | Add hero_image_url to treasury-import-config.json. | |
| DB field on municipality | Add hero_image_url column to treasury.municipalities. | ✓ |
| You decide | Claude picks approach. | |

**User's choice:** DB field on municipality

### Info cards when population unavailable

| Option | Description | Selected |
|--------|-------------|----------|
| Hide per-resident stat | Show total budget but hide per-resident calculation. | ✓ |
| Hide entire info card | Don't show info card at all. | |
| Show placeholder text | Show "Population data not available". | |

**User's choice:** Hide per-resident stat

---

## Data Loading on Switch

### Loading behavior when switching entities

| Option | Description | Selected |
|--------|-------------|----------|
| Spinner overlay | Show spinner over content, keep header interactive. | ✓ |
| Skeleton placeholders | Gray pulsing rectangles in place of content. | |
| Instant swap with stale data | Show old data while new loads. | |

**User's choice:** Spinner overlay

### Year and dataset on entity switch

| Option | Description | Selected |
|--------|-------------|----------|
| Persist both | Keep year and dataset. Fall back if unavailable. | ✓ |
| Reset to defaults | Always reset to operating/latest year. | |
| Persist dataset, reset year | Keep dataset tab, reset year. | |

**User's choice:** Persist both

### Missing dataset type handling

| Option | Description | Selected |
|--------|-------------|----------|
| Disable the tab | Show tab but grayed out with tooltip. | ✓ |
| Hide the tab entirely | Only show tabs with data. | |
| Show empty state | Tab clickable but shows "No data available". | |

**User's choice:** Disable the tab

---

## URL & Deep Linking

### Entity in URL

| Option | Description | Selected |
|--------|-------------|----------|
| Query parameter | ?entity=bloomington-in — shareable, bookmarkable. | ✓ |
| Path-based routing | /bloomington-in/ as URL path segment. | |
| No URL state | Session-only, always loads default. | |

**User's choice:** Query parameter

### Default entity

| Option | Description | Selected |
|--------|-------------|----------|
| Bloomington | Default to Bloomington, IN — original and most complete. | ✓ |
| First in list | First entity alphabetically/by ID. | |
| You decide | Claude picks. | |

**User's choice:** Bloomington

### Year and dataset in URL

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, all three | ?entity=...&year=...&dataset=... — fully shareable. | ✓ |
| Entity only | Only entity in URL. | |
| You decide | Claude picks. | |

**User's choice:** Yes, all three

---

## Claude's Discretion

- Entity slug format for URL params
- API endpoint design for listing municipalities with available datasets/years
- Spinner implementation details
- How to derive available years per entity

## Deferred Ideas

None — discussion stayed within phase scope.
