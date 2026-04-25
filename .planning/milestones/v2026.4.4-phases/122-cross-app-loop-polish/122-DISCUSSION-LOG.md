# Phase 122: Cross-App Loop Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 122-cross-app-loop-polish
**Areas discussed:** CompassCard return visitor (INTG-01), Compass→Essentials link scope (INTG-02), Treasury CTA placement (INTG-03), Verification & sequencing

---

## CompassCard Return Visitor (INTG-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Chart if guestCompass cached, CTA if not | Read guestCompass from Essentials localStorage. If data exists, render comparison overlay. If empty, show calibration CTA. | ✓ |
| Always show CTA (status quo) | Keep current behavior — always prompt to calibrate even for returning visitors. | |
| Show a 'Return to compass' prompt | Compact nudge with link back to Compass rather than inline rendering. | |

**User's choice:** Chart if guestCompass cached, CTA if not (Recommended)
**Notes:** Intended behavior — the question is where the relay chain is broken.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Diagnose first — don't assume | Research verifies: fragment write, localStorage read, CompassCard render condition. Fix whichever layer is broken. | ✓ |
| Fragment write is likely broken | guestCompass key probably not being saved when fragment is processed. | |
| CompassCard render condition is likely wrong | guestCompass saved correctly but hasUserCompass fails on mount. | |

**User's choice:** Diagnose first — don't assume (Recommended)
**Notes:** No premature assumption about which layer is broken.

---

## Compass→Essentials Link Scope (INTG-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Verify it works + fix candidate ID mapping | Confirm link resolves correctly for picker politicians. Fix candidate_id vs politician_id mismatch if found. | ✓ |
| The link format is wrong — needs slug not UUID | Essentials may require slugs rather than UUIDs. | |
| The link exists but compass fragment isn't attached | Link may drop the user's compass state on navigation. | |

**User's choice:** Verify it works + fix candidate ID mapping (Recommended)
**Notes:** The link EXISTS in ComparePanel and already appends serializeCompassFragment(). Primary concern is candidate ID mapping.

---

## Treasury CTA Placement (INTG-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Results page local section only | Contextual CTA in local-tier section when address falls in a municipality with Treasury data. | ✓ |
| Both Results page and profile pages | CTA on Results page AND on local politician profile pages. | |
| Profile pages only | CTA only on local politician profiles. | |

**User's choice:** Results page local section only (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcode Bloomington for now | Only Bloomington has data — hardcode the check. Simple, no API needed. | |
| Query the Treasury API for cities | Call treasury/cities endpoint to determine which municipalities have data. Dynamic. | ✓ |
| VITE env var config | Configure eligible city slugs via environment variable. | |

**User's choice:** Query the Treasury API for cities
**Notes:** Dynamic approach allows the CTA to automatically appear when new municipalities are added to Treasury Tracker.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Inline banner in local tier header area | Compact contextual banner near the 'Local' section heading. | |
| Below all local cards | CTA card/row at the bottom of the entire local section. | |
| Claude's discretion | Let the planner decide placement. | |

**User's choice (freeform):** Below each municipality section that has a budget. CTA should appear per municipality (township, city, county) — not one CTA for the whole local tier. Link text: "Explore [municipality] revenue and expenses". No dollar amount.
**Notes:** More granular than the presented options — per-municipality, not per-tier. This is the canonical behavior captured in CONTEXT.md D-08 through D-12.

---

## Verification & Sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Production verification, same pattern as 118/119 | Final verification on production URLs after Render deploy. | ✓ |
| Dev environment is sufficient | Verify locally before deploying. | |
| Claude's discretion | Planner determines verification evidence. | |

**User's choice:** Production verification, same pattern as 118/119 (Recommended)

---

| Option | Description | Selected |
|--------|-------------|----------|
| INTG-01 → INTG-02 → INTG-03 in one plan | All three fixes in sequence, one PR, one deploy. | ✓ |
| INTG-02 first (verify existing link), then INTG-01, then INTG-03 | Start with lowest-risk verification. | |
| Separate plans per INTG item | 3 separate plans shipping independently. | |

**User's choice:** INTG-01 → INTG-02 → INTG-03 in one plan (Recommended)

---

## Claude's Discretion

- Exact diagnostic commands and localStorage inspection steps for INTG-01
- Whether to add a defensive dev-mode log when guestCompass is empty
- Visual treatment of the Treasury CTA (color, icon, spacing)
- Whether Treasury deep-link can route to specific municipality

## Deferred Ideas

None — discussion stayed within phase scope.
