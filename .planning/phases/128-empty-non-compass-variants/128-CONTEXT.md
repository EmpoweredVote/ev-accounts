# Phase 128: Empty & Non-Compass Variants - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add three card variants to `CompassCardHorizontal` (published in Phase 127) for cases where the default compass view doesn't apply:

1. **Empty variant** — user has fewer than 3 compass topics answered → ghosted placeholder radar + "Build your compass" CTA that deep-links into CompassV2's existing CalibrationOverlay flow
2. **Administrative variant** — clerk, auditor, recorder, treasurer, and similar non-policy offices → "Compass currently unavailable for this role" plate in the radar slot when in compass view; standard portrait in portrait view
3. **Judicial variant** — judges (including retention judges) → same neutral plate as administrative

The Phase 127 card API stays intact: parent owns view state via `view: 'compass' | 'portrait'`, flat top-level props, presentational component.

Out of scope: essentials Representatives/Elections page adoption + `/prototype` retirement (Phase 129).

</domain>

<decisions>
## Implementation Decisions

### Variant Detection & API
- **D-01:** Card accepts an explicit `variant` prop from the parent: `'compass' | 'empty' | 'administrative' | 'judicial'`. Page-level code runs the role/answer-count classification; the card stays presentational. This matches Phase 127 D-01/D-03 (flat props, parent-owned state).
- **D-02:** Variant classification logic lives in `essentials/src/lib/classify.js` (existing) — `essentials` decides which variant to pass; `ev-ui` does not regex politician titles.
- **D-03:** Empty-variant detection happens in the parent (essentials page) by counting answered topics in `userAnswers`. The threshold is the existing 3-topic minimum (v1.2). The card itself does NOT inspect `userAnswers.length`.

### View Toggle Behavior
- **D-04:** The existing `view` prop ('compass' | 'portrait') still applies to ALL variants. The page-level SegmentedControl flips every card on the page.
- **D-05:** In COMPASS view, non-compass variants (administrative, judicial) replace the radar slot with a neutral plate: **"Compass currently unavailable for this role."** Same copy for both administrative and judicial — uniform "we're working on it" signal.
- **D-06:** In PORTRAIT view, non-compass variants render exactly like compass-variant portrait view from Phase 127: portrait photo (or initials fallback) replaces the radar slot at the same dimensions; meta column unchanged. No extra captions, no role description copy. Grid uniformity preserved.

### Empty Variant (STATE-01)
- **D-07:** Radar slot shows the existing **`PlaceholderRadar`** component (dashed octagon SVG) already defined in `essentials/src/components/CompassFirstCard.jsx:53-152`. Lift this into ev-ui along with the new variants in Phase 128.
- **D-08:** CTA copy: **"Build your compass"** (or close variant). CTA button placement: under or overlaid on the placeholder radar — exact placement is Claude's discretion within the component.
- **D-09:** CTA target: deep-link into CompassV2's existing **`CalibrationOverlay`** flow (`CompassV2/src/components/CalibrationOverlay.jsx`). The overlay already supports `startAtPick` and `resumeMode` props — wire the deep-link to land at the appropriate entry point.
- **D-10:** Topic preselection scope: **all unanswered topics across all levels** (federal, state, local). Not filtered by the politician's level. User builds a broad compass; politician-specific filtering happens at card render time.
- **D-11:** Empty variant also respects the `view` toggle — in PORTRAIT view, the placeholder radar is replaced by the standard portrait (same as other variants); the CTA disappears in portrait view because the placeholder context is gone.

### Administrative Variant (STATE-02)
- **D-12:** Detection: politicians whose office title matches the existing classify.js admin pattern — clerk, auditor, recorder, treasurer, assessor (see `essentials/src/lib/classify.js:172-176, 213` and `essentials/src/utils/branchType.js:36`).
- **D-13:** Compass-view content: **"Compass currently unavailable for this role."** plate. Same copy for all admin titles. No role-specific hooks (no Treasury Tracker link, no records portal link, no audit reports link) — uniform treatment in this phase.
- **D-14:** Portrait-view content: standard portrait, no extra caption. Identical to Phase 127 portrait behavior.

### Judicial Variant (STATE-03)
- **D-15:** Detection: politicians with `district_type = 'JUDICIAL'` or whose office title matches judge/justice/court (see `essentials/src/utils/officeDescriptions.js:89`).
- **D-16:** Compass-view content: **same neutral "Compass currently unavailable for this role." plate** as administrative variant. No retention history viz, no court level callout, no appointment source line in this phase.
- **D-17:** Portrait-view content: standard portrait, no extra caption.
- **D-18:** Retention judge dual-appearance is preserved unchanged. Retention judges continue to appear in BOTH elected and appointed filter views on the representatives page (existing behavior, Phase 127 success criterion still applies). The judicial variant renders identically in both filter contexts.

### Claude's Discretion
- Exact CTA button placement, styling, and micro-copy variations (overlay vs below the placeholder, button vs link)
- Internal file layout in `ev-ui/src/` (one component file with branched render vs split files per variant)
- Copy of `PlaceholderRadar` into ev-ui — keep as inline helper or extract as a separately-exported component
- Plate styling for the "Compass currently unavailable for this role." text — typography, icon (or no icon), background treatment, spacing — should harmonize with placeholder radar dimensions for grid uniformity
- Whether the empty-variant CTA preserves the user's intended destination after calibration completes (deep-return vs let user navigate manually)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & roadmap
- `.planning/ROADMAP.md` §"Phase 128: Empty & Non-Compass Variants" — goal, success criteria, dependencies
- `.planning/REQUIREMENTS.md` §"STATE-01..03" — empty/admin/judicial variant requirements
- `.planning/phases/127-compass-card-horizontal-ev-ui/127-CONTEXT.md` — locked Phase 127 decisions (flat props, parent-owned view, surface prop)

### Existing implementation to lift / extend
- `essentials/src/components/CompassFirstCard.jsx:53-152` — `PlaceholderRadar` SVG (dashed octagon) — lift into ev-ui
- `essentials/src/lib/classify.js:172-176, 213` — administrative role detection (clerk/treasurer/auditor/recorder/assessor)
- `essentials/src/utils/branchType.js:36` — additional admin title regex
- `essentials/src/utils/officeDescriptions.js:89` — judicial title regex
- `CompassV2/src/components/CalibrationOverlay.jsx` — deep-link target (supports `startAtPick`, `resumeMode`)
- `CompassV2/src/pages/Compass.jsx:279-309, 695` — calibration overlay invocation patterns

### ev-ui surface (Phase 127 output)
- `ev-ui/src/CompassCardHorizontal.jsx` (Phase 127) — extend with new variants
- `ev-ui/src/RadarChartCore.jsx` — internal radar dependency
- `ev-ui/src/tokens.js` + `ev-ui/src/tailwind-preset.js` — design tokens for plate/CTA styling
- `ev-ui/src/index.js` — export barrel
- `ev-ui/README-AUTOBUMP.md` — release pipeline

### Project-level constraints
- `CLAUDE.md` §"Design System" — ev-coral / ev-muted-blue / ev-light-blue / ev-yellow palette, Manrope font
- Antipartisan principle — no party labels, no partisan color treatments

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`PlaceholderRadar`** (in `essentials/src/components/CompassFirstCard.jsx`) — dashed octagon SVG, accepts `size` and `name`. Already used as the no-data fallback. Lift into ev-ui as part of Phase 128.
- **`CalibrationOverlay`** (in `CompassV2/src/components/CalibrationOverlay.jsx`) — full calibration flow with `startAtPick` and `resumeMode` props. The deep-link target already exists; only the URL/handoff contract needs to be defined.
- **`classify.js` admin/judicial detection** — centralized title-classification logic in essentials. Phase 128 reuses this to derive `variant` at the page level.
- **`SegmentedControl`** (in `essentials/src/components/SegmentedControl.jsx`) — page-level view toggle, also used in Phase 129 work.

### Established Patterns
- ev-ui components are **presentational**; essentials owns classification, filter state, and view state (matches Phase 127 D-03, D-04).
- 3-topic minimum is an established v1.2 platform constant — empty detection threshold matches it.
- Retention judge dual-appearance is implemented at the filter layer in `essentials/src/pages/Results.jsx`; card-level changes in this phase do not alter that layer.

### Integration Points
- New `variant` prop added to `CompassCardHorizontal` in `ev-ui/src/index.js` export.
- Page-level consumers (essentials Representatives, Elections, Prototype) compute variant before passing to the card. Phase 129 handles wiring to the live pages; Phase 128 only needs the prototype harness to exercise all four variant values.
- Deep-link from empty variant to CompassV2 lives across two repos — define the URL contract clearly so each side stays loose-coupled.

</code_context>

<specifics>
## Specific Ideas

- **Uniform plate copy** — both administrative and judicial use *"Compass currently unavailable for this role."* The user explicitly chose this phrasing to signal "we're working on it" rather than "no compass exists" (the latter would imply permanence). Planner should NOT split into separate copy per role type.
- **Reuse PlaceholderRadar verbatim** — user pointed at "the current way we are doing it"; the component already does the right thing. Do not redesign.
- **Reuse CalibrationOverlay deep-link** — user explicitly noted "we already have that built." Avoid duplicating onboarding UX in Essentials.
- **No role-specific hooks** — user explicitly chose uniform treatment over Treasury Tracker / records portal / audit reports links. These are deferred ideas, not future P128 scope.
- **All-unanswered, all-levels** — empty CTA preselects every unanswered topic regardless of politician's level (federal/state/local). User chose breadth over precision targeting.

</specifics>

<deferred>
## Deferred Ideas

- **Role-specific compass content** — when role-aware non-compass content is designed (treasurer budget summaries, judicial retention bars, clerk records summaries), revisit the plate. The neutral "currently unavailable" copy was chosen partly to make this future replacement low-risk.
- **Treasurer → Treasury Tracker link** — natural cross-link to `treasurytracker.empowered.vote`. Could be a small post-Phase 128 enhancement if Treasury coverage expands.
- **Clerk → public records portal link** — depends on having reliable records URLs in `politician_contacts`.
- **Auditor → audit reports link** — same.
- **Judicial retention history viz** — small bar chart of past retention percentages instead of the neutral plate. Requires retention vote data ingestion first.
- **Court level + appointment source callouts on judicial cards** — content design pending; deferred until retention/court data is available.
- **Topic preselection by politician level** — currently the empty CTA surfaces all unanswered topics regardless of level. If post-launch data shows users want focused calibration, revisit (rejected here in D-10).
- **Inline calibration modal in Essentials** — rejected at D-09 in favor of deep-linking CompassV2. Could revisit if cross-app navigation friction surfaces in feedback.
- **Different judicial variant content per filter context** (elected vs appointed) — rejected at D-18 to keep dual-appearance behavior unchanged.

</deferred>

---

*Phase: 128-empty-non-compass-variants*
*Context gathered: 2026-04-24*
