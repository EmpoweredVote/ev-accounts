# Phase 129: Essentials Adoption & Prototype Retirement - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

The `CompassCardVertical` (portrait + name/position above, radar below — shows both in a single vertical layout) is already live on the Representatives and Elections pages. No further "adoption" work is needed.

Phase 129 scope is:
1. **Retire `/prototype`** — delete the route, the page file, and prototype-only dependencies
2. **Remove `CompassPreview`** — floating mini-radar popover in Results.jsx is now redundant with the inline compass on every card
3. **Verify** both pages still function correctly end-to-end

Out of scope: ev-ui version bump (Phase 128 plan 04), Elections page card wiring (already done), view toggle UI (removed — card shows both portrait and radar simultaneously, no toggle needed).

</domain>

<decisions>
## Implementation Decisions

### Card Architecture (from Phase 127/128 — confirmed)
- **D-01:** The production card is `CompassCardVertical` — portrait + name/position above, radar (compass) below. Both elements are always visible. There is no view toggle.
- **D-02:** Variant prop (`compass | empty | administrative | judicial`) is computed at the page level by `computeVariant()` in `essentials/src/lib/classify.js`. Card is presentational.

### Prototype Retirement
- **D-03:** Delete **both** the route definition in `essentials/src/App.jsx` **and** the page file `essentials/src/pages/Prototype.jsx`.
- **D-04:** Delete prototype-only dependencies: `essentials/src/components/CompassFirstCard.jsx` and `essentials/src/data/mockCompassData.js`. Confirmed these are only referenced from `Prototype.jsx`.
- **D-05:** No redirect — no route survives. A user hitting `/prototype` will get the app's 404/fallback behavior.

### CompassPreview Removal
- **D-06:** Remove `CompassPreview` from `essentials/src/pages/Results.jsx`: delete the import, the `previewPol` state, and the `<CompassPreview>` JSX block (Results.jsx:13, 405, 1345–1354). The popover is redundant — every card already shows the radar inline.
- **D-07:** The `CompassPreview` component file (`essentials/src/components/CompassPreview.jsx`) should also be deleted if it has no other callers outside Results.jsx.

### Elections Page
- **D-08:** No changes needed. Elections page candidate cards are already correct — incumbents show full compass, challengers render the appropriate empty/minimal variant via `computeVariant()`.

### Claude's Discretion
- Whether to keep or remove the `SegmentedControl` import in `Results.jsx` (currently imported but only used for the Representatives/Elections tab — check if it's still needed for that tab control before removing)
- Whether the `CompassPreview.jsx` component has other callers in the codebase before deleting

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & roadmap
- `.planning/ROADMAP.md` §"Phase 129: Essentials Adoption & Prototype Retirement" — goal, success criteria
- `.planning/REQUIREMENTS.md` §"ADOPTION — Wire into Essentials" — ADOPT-01..04

### Prior phase context (locked decisions)
- `.planning/phases/127-compass-card-horizontal-ev-ui/127-CONTEXT.md` — Phase 127 locked decisions
- `.planning/phases/128-empty-non-compass-variants/128-CONTEXT.md` — Phase 128 locked decisions

### Files being deleted
- `essentials/src/pages/Prototype.jsx` — route, page, harness (delete entirely)
- `essentials/src/components/CompassFirstCard.jsx` — local prototype component (prototype-only; delete)
- `essentials/src/data/mockCompassData.js` — mock data for prototype (prototype-only; delete)

### Files being modified
- `essentials/src/App.jsx:12, 60` — remove Prototype import and `<Route path="/prototype">` definition
- `essentials/src/pages/Results.jsx:13, 405, 1345–1354` — remove CompassPreview import, previewPol state, and JSX block
- `essentials/src/components/CompassPreview.jsx` — delete if no remaining callers

### Current production card
- `essentials/src/pages/Results.jsx` — uses `CompassCardVertical` from `@empoweredvote/ev-ui`; `computeVariant()` from `classify.js`
- `essentials/src/components/ElectionsView.jsx` — same; already wired for incumbents + challengers

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/lib/classify.js:computeVariant` — already handles all 4 variants; no changes needed here

### Established Patterns
- Route deletion pattern: remove import in App.jsx, remove `<Route>` element
- CompassPreview is a local component, not from ev-ui — safe to delete from essentials without affecting other repos

### Integration Points
- `essentials/src/App.jsx` owns route definitions — single file to update for prototype removal
- `Results.jsx` CompassPreview usage is self-contained (import + state + JSX) — clean removal

</code_context>

<specifics>
## Specific Notes

- **Card shape confirmed by user:** The production card is vertical (portrait + name above, compass below), showing both elements simultaneously. No toggle was shipped. This diverged from Phase 127's horizontal concept — the `CompassCardVertical` component in ev-ui is the production card.
- **Phase 128 plan 04 handles ev-ui bump** — Phase 129 does not need to bump ev-ui. The auto-bump pipeline and CompassV2 regression verification are Phase 128 scope.
- **Adoption is already done** — CompassCardVertical is live on Representatives and Elections pages. Phase 129 is cleanup only.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 129-essentials-adoption-prototype-retirement*
*Context gathered: 2026-04-26*
