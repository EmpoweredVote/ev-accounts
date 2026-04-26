# Phase 129: Essentials Adoption & Prototype Retirement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 129-essentials-adoption-prototype-retirement
**Areas discussed:** View toggle placement, CompassPreview fate, Prototype retirement approach, Elections page toggle scope

---

## View Toggle Placement

| Option | Description | Selected |
|--------|-------------|----------|
| Top of card grid, right-aligned | Above the card grid, right side of content area | |
| Inside the existing filter bar | Inline with elected/appointed filter | |
| Floating sticky control | Fixed position at bottom-right of viewport | |
| You decide | Claude picks based on existing layout | |

**User's choice:** Toggle was removed — no longer needed
**Notes:** The production card (CompassCardVertical) shows both portrait and compass radar simultaneously in a vertical layout. No view toggle was shipped. Phase 129 does not need to add one.

---

## Toggle Labels (follow-up)

| Option | Description | Selected |
|--------|-------------|----------|
| Compass / Portrait | Names what's shown in each view | |
| Compass / Photo | More concrete than "Portrait" | |
| You decide | Claude picks | |

**User's choice:** We removed the toggle
**Notes:** Moot — no toggle exists on the live pages.

---

## Card Default View (follow-up clarification)

| Option | Description | Selected |
|--------|-------------|----------|
| Always compass view | Radar always visible | |
| Always portrait view | Photo always visible | |
| Compass when available, portrait fallback | Radar + portrait based on variant | ✓ |

**User's choice:** "We made a vertical card with the portrait and name/position above and the compass below, so we are actually showing both"
**Notes:** The card is CompassCardVertical — a single layout showing portrait + name at top, radar below. Both are always visible. This confirms no toggle is needed.

---

## Current State Confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — CompassCardVertical is already live in Results.jsx | Phase 129 is primarily cleanup | ✓ |
| Yes vertical, but not yet wired | Card exists but not on live pages | |
| It's more nuanced | Needs further explanation | |

**User's choice:** Yes — CompassCardVertical is already live in Results.jsx

---

## Remaining Work

| Option | Description | Selected |
|--------|-------------|----------|
| Retire /prototype route | Remove/redirect the /prototype page | ✓ |
| Verify Elections page cards | Check incumbents + challengers show correct variants | |
| ev-ui auto-bump pipeline | Bump version, verify auto-bump PRs, check CompassV2 | |
| Wire remaining things in Results.jsx | Additional connection points needed | |

**User's choice:** Retire /prototype route only
**Notes:** Adoption is already done. ev-ui bump is Phase 128's scope. Elections page is already correct.

---

## CompassPreview

| Option | Description | Selected |
|--------|-------------|----------|
| Remove it | Redundant with inline radar on every card | ✓ |
| Keep it for portrait context | Still useful for detailed inspection | |
| You decide | Claude evaluates current wiring | |

**User's choice:** Remove it (Recommended)
**Notes:** CompassPreview floating popover is redundant now that every card shows the radar inline.

---

## Prototype Retirement Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Hard redirect to /representatives | Replace route with Navigate redirect | |
| Delete route and file | Remove route from App.jsx + delete Prototype.jsx | ✓ |
| Leave route, remove nav links | Keep URL accessible but no in-app links | |
| Replace with internal reference note | Keep route, replace content with a note | |

**User's choice:** Delete route and file
**Notes:** Clean deletion. Also deletes prototype-only dependencies: CompassFirstCard.jsx and mockCompassData.js.

---

## Elections Page Scope

| Option | Description | Selected |
|--------|-------------|----------|
| No — Elections page is already good | No changes needed | ✓ |
| Yes — retire /prototype from Elections too | /prototype reference or link to clean up | |
| Something else to address | Specific Elections page issue | |

**User's choice:** No — Elections page is already good

---

## Claude's Discretion

- Whether SegmentedControl import in Results.jsx is still needed (used for Representatives/Elections tab — verify before removing)
- Whether CompassPreview.jsx has other callers before deleting

## Deferred Ideas

None.
