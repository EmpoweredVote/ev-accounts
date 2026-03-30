# Phase 100: Elected/Appointed Filter - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-30
**Phase:** 100-elected-appointed-filter
**Areas discussed:** Filter placement & interaction, Filter UI style, Backend vs frontend filtering, Retention judge presentation

---

## Filter Placement & Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Stacked filters | Both filters active simultaneously (e.g., "State" + "Elected") | ✓ |
| Combined single filter | Replace tier filter with single combined filter | |
| Secondary toggle | Small segmented control, visually subordinate to tier filter | |

**User's choice:** Stacked filters
**Notes:** None

### Follow-up: Position relative to tier filter

| Option | Description | Selected |
|--------|-------------|----------|
| Above tier filter | Elected/Appointed first, then tier | |
| Below tier filter | Tier first, then Elected/Appointed | ✓ |
| You decide | Claude picks best placement | |

**User's choice:** Below tier filter
**Notes:** None

---

## Filter UI Style

| Option | Description | Selected |
|--------|-------------|----------|
| Match tier filter | Radio buttons on desktop, pill buttons on mobile | |
| Segmented control | Compact iOS-style pill toggle, visually distinct from tier | ✓ |
| You decide | Claude picks best style | |

**User's choice:** Segmented control
**Notes:** None

---

## Backend vs Frontend Filtering

| Option | Description | Selected |
|--------|-------------|----------|
| Client-side | Filter already-returned list in React, no backend changes | ✓ |
| Server-side | Add query param, backend WHERE clause, re-fetch on change | |
| You decide | Claude picks based on data volume | |

**User's choice:** Client-side (Recommended)
**Notes:** None

### Follow-up: Resolution of priority chain

| Option | Description | Selected |
|--------|-------------|----------|
| Client-side resolution | Frontend combines politician.is_appointed + office-level + faces_retention_vote | ✓ |
| Backend resolved field | Backend adds computed filter_category field | |

**User's choice:** Client-side resolution
**Notes:** None

---

## Retention Judge Presentation

| Option | Description | Selected |
|--------|-------------|----------|
| No indicator | Silently appear in both views, no extra visual noise | ✓ |
| Subtle badge | Small "Retention Vote" badge or tooltip | |
| You decide | Claude picks based on design philosophy | |

**User's choice:** No indicator
**Notes:** None

---

## Claude's Discretion

- Segmented control visual styling (colors, active state, sizing)
- Mobile responsive behavior
- State management approach
- Animation/transition on filter change
- Label text on small screens

## Deferred Ideas

None — discussion stayed within phase scope
