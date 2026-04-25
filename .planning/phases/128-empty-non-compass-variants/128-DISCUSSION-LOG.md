# Phase 128: Empty & Non-Compass Variants - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-24
**Phase:** 128-empty-non-compass-variants
**Areas discussed:** Variant detection & API, View toggle behavior, Empty variant (placeholder + CTA + topic scope), Administrative variant content, Judicial variant content, Retention judge dual-appearance, Portrait-view content for non-compass variants

---

## Variant Detection & API

| Option | Description | Selected |
|--------|-------------|----------|
| Parent passes explicit `variant` prop (Recommended) | Page-level code runs classify/role logic and passes `variant='compass' \| 'empty' \| 'administrative' \| 'judicial'`. Card stays presentational. | ✓ |
| Card derives from `politician.office_title` | Card runs its own regex. Couples ev-ui to role classification. | |
| Card derives from `userAnswers` count only | Hybrid — handles empty automatically; admin/judicial still need a prop. | |

**User's choice:** Parent passes explicit `variant` prop.
**Notes:** Aligns with Phase 127 D-01/D-03 (flat props, parent-owned state).

---

## View Toggle Behavior (Compass vs Portrait)

| Option | Description | Selected |
|--------|-------------|----------|
| Non-compass variants ignore `view` (Recommended) | Admin/judicial always portrait-forward. | |
| Toggle still flips between layouts | Compass view shows a placeholder card section where radar would be. | ✓ |
| Empty respects toggle; admin/judicial don't | Hybrid. | |

**User's choice:** Toggle still flips between layouts. "I think we still flip from portrait and we will need to put something in its place. I'm still working on what that might actually be."
**Notes:** This drove the follow-up question about what fills the radar slot in compass view. Answer: neutral plate with copy.

---

## Empty Variant — Radar Slot Visual

| Option | Description | Selected |
|--------|-------------|----------|
| Ghosted placeholder radar (Recommended) | Grey/dashed spokes with no filled shape. | ✓ |
| Partial radar with only answered topics | Shows 1-2 points; may look broken. | |
| Illustrated CTA, no radar shape | Replace radar entirely with icon. | |

**User's choice:** Ghosted placeholder radar.
**Notes:** "Use the current way we are doing it" — referring to existing `PlaceholderRadar` component in `essentials/src/components/CompassFirstCard.jsx:53-152`. Lift verbatim into ev-ui.

---

## Empty Variant — CTA Target

| Option | Description | Selected |
|--------|-------------|----------|
| Deep-link to CompassV2 calibration overlay (Recommended) | URL like `https://compass.empowered.vote/?calibrate=1` opens existing CalibrationOverlay (v1.2). | ✓ |
| Stay in Essentials, open inline modal | Embed mini calibration in Essentials. | |
| Navigate to Library page in CompassV2 | User picks topics themselves. | |

**User's choice:** Deep-link to CompassV2 calibration overlay.
**Notes:** "We already have that built too and it's most similar to the deep-link option which opens the compass onboarding flow." `CalibrationOverlay` already supports `startAtPick` and `resumeMode` props.

---

## Empty Variant — Topic Preselection Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Topics relevant to that politician's level (Recommended) | Federal politician → federal topics; state → state. | |
| All unanswered topics, any level | User fills compass broadly. | ✓ |
| Only topics where THIS politician has a stance | Most targeted. | |

**User's choice:** All unanswered topics, any level.
**Notes:** Breadth over precision targeting.

---

## Administrative Variant — Radar Slot Replacement (Compass View)

| Option | Description | Selected |
|--------|-------------|----------|
| Role description block (Recommended) | Use `officeDescriptions.js` copy. | |
| Contact/office info block | Phone, email, website from `politician_contacts`. | |
| Neutral "No compass for this role" plate | Static message + icon, uniform across roles. | |
| Role description + primary contact link | Combination. | |

**User's choice:** *Other (free text)* — "Let's do something like 'Compass currently unavailable for this role' to signal that we are working on something, but don't have it yet."
**Notes:** This becomes the **canonical plate copy**, used for both administrative AND judicial variants (see judicial answer below). Signals work-in-progress rather than permanent absence.

---

## Administrative Variant — Role-Specific Hooks

| Option | Description | Selected |
|--------|-------------|----------|
| Treasurer → Treasury Tracker link (Recommended) | Cross-link to `treasurytracker.empowered.vote`. | |
| Clerk → records portal link | If URL exists in contacts. | |
| Auditor → audit reports link | Only when URL exists. | |
| Keep it uniform, no role-specific hooks | Same content for all admin roles. | ✓ |

**User's choice:** Keep it uniform, no role-specific hooks.
**Notes:** Cross-links deferred to a future enhancement, not this phase.

---

## Judicial Variant — Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Same neutral plate as admin (Recommended) | "Compass currently unavailable for this role." | ✓ |
| Judge-specific plate with court info | Plus court level and appointment source. | |
| Retention history visualization | Small bar chart of past retention percentages. | |

**User's choice:** Same neutral plate as admin.
**Notes:** Uniform copy with administrative variant. Court info and retention viz deferred.

---

## Retention Judge Dual-Appearance

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve existing dual-appearance unchanged (Recommended) | Retention judges appear in both elected and appointed filter views; same judicial variant in both. | ✓ |
| Show different content per filter context | Elected → emphasize retention vote; Appointed → emphasize appointment source. | |

**User's choice:** Preserve existing dual-appearance unchanged.
**Notes:** Filter-layer behavior in `essentials/src/pages/Results.jsx` is untouched by this phase.

---

## Portrait-View Content for Non-Compass Variants

| Option | Description | Selected |
|--------|-------------|----------|
| Standard portrait, no extra content (Recommended) | Same as Phase 127 portrait view; photo replaces radar slot, meta column unchanged. | ✓ |
| Add "No compass available" caption under photo | Italic text under portrait. | |
| Show role description in portrait too | `officeDescriptions.js` copy under photo. | |

**User's choice:** Standard portrait, no extra content.
**Notes:** Grid uniformity with compass-variant cards.

---

## Claude's Discretion

- Exact CTA button placement and styling within the empty variant
- Internal file layout in `ev-ui/src/` (single file vs split helpers)
- Whether to extract `PlaceholderRadar` as a separately-exported ev-ui component
- Plate styling for "Compass currently unavailable for this role." (typography, optional icon, background, spacing)
- Whether the empty-variant deep-link returns the user to Essentials after calibration completes

## Deferred Ideas

- Role-specific compass content (treasurer budget summaries, judicial retention bars, clerk records)
- Treasurer → Treasury Tracker cross-link
- Clerk → records portal cross-link
- Auditor → audit reports cross-link
- Judicial retention history visualization
- Court level + appointment source callouts on judicial cards
- Topic preselection filtered by politician's level (federal/state/local)
- Inline calibration modal in Essentials (rejected in favor of deep-link)
- Different judicial variant content per elected/appointed filter context
