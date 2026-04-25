# Phase 127: CompassCardHorizontal in ev-ui - Context

**Gathered:** 2026-04-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish a horizontal compass-first politician card (`CompassCardHorizontal`) in `@empoweredvote/ev-ui`, based on the existing `/prototype` variant C (radar-left / metadata-right). The card:
- Renders a radar (via internal `RadarChartCore`) or a portrait, based on a parent-controlled `view` prop
- Preserves existing PoliticianCard affordances with no regression
- Is demonstrated by the existing `essentials /prototype` harness across all three prop shapes

Out of scope in this phase: empty/no-compass/administrative/judicial variants (Phase 128), essentials page adoption and `/prototype` retirement (Phase 129).

</domain>

<decisions>
## Implementation Decisions

### Component API
- **D-01:** Flat top-level props — `politician`, `userAnswers`, `tierVisuals` as separate props (mirrors existing `PoliticianCard`; easiest partial data handling). Not a single config object; not slot-based.
- **D-02:** Radar is rendered internally by the card via `RadarChartCore` (imported within ev-ui). Consumers pass raw answers/stances; the card handles rendering. No render-prop / children API for the chart.
- **D-03:** Card accepts a controlled `view` prop (`'compass' | 'portrait'`) — the card does NOT own view state and does NOT render its own toggle button. Parent is the source of truth.

### View Toggle
- **D-04:** View state lives at the **parent/page level**, not per-card. One page-level `SegmentedControl` flips all cards on the page simultaneously.
- **D-05:** View preference persists **globally per-user via localStorage** (one key, e.g. `ev:compass-card-view`). Survives navigation and return visits.
- **D-06:** No per-card toggle button in this phase. If a single-card override is ever needed, consumers pass `view` directly.

### Metadata Parity (CARD-03)
- **D-07:** Representatives-page card meta column contains: **name, position, district/ward/etc, affordance icons** (tier/branch badge, elected/appointed marker, etc.). All current PoliticianCard affordances preserved.
- **D-08:** Elections-page card meta column contains: **name, position running for, district/ward/etc, affordance icons, and a "running unopposed" banner** where applicable.
- **D-09:** Card supports a surface variant distinction (e.g., `surface: 'representatives' | 'elections'`) so the meta layout can switch between these two content sets. Exact prop name to be finalized by planner.
- **D-10:** In **portrait view**, the radar slot is replaced by a large politician portrait at the same dimensions (preserves grid uniformity). Initials circle fallback when no photo, matching existing PoliticianCard visual language.

### Styling & Theming
- **D-11:** Component sources colors, spacing, radii, and shadows from `ev-ui/src/tokens.js` and `tailwind-preset.js`. No inlined constants copied from variant C. Consumers can theme via the existing token surface.
- **D-12:** Antipartisan constraint enforced — no party labels or partisan color treatments anywhere on the card.

### Harness
- **D-13:** The prototype harness demonstrating all three prop shapes (with data, empty, portrait-only) **remains at `essentials/src/pages/Prototype.jsx`** for this phase. No new ev-ui demo page. Harness retires in Phase 129 with `/prototype`.

### Claude's Discretion
- Internal file layout within `ev-ui/src/` (e.g., one file vs split helper files for `PlaceholderRadar`, meta renderer)
- Exact prop name for the Representatives/Elections surface distinction (D-09)
- Whether the localStorage key is defined in ev-ui or essentials (likely essentials; ev-ui ideally stays stateless)
- Tests: snapshot vs DOM assertions, which testing lib — pick what matches existing ev-ui conventions
- Handling of `userAnswers`/`tierVisuals` when missing — render gracefully (placeholder radar / default tier) without throwing

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & roadmap
- `.planning/ROADMAP.md` §"Phase 127: CompassCardHorizontal in ev-ui" — goal, success criteria, dependencies
- `.planning/REQUIREMENTS.md` §"CARD — Compass-first card component (ev-ui)" — CARD-01, CARD-02, CARD-03

### Existing implementation to lift from
- `essentials/src/components/CompassFirstCard.jsx` — variant C (horizontal layout) is the source of truth for this component
- `essentials/src/pages/Prototype.jsx` — current harness; remains the Phase 127 harness
- `essentials/src/components/PoliticianCard.jsx` — affordance checklist for CARD-03 parity

### ev-ui surface & conventions
- `ev-ui/src/index.js` — public export barrel
- `ev-ui/src/RadarChartCore.jsx` — internal chart dependency
- `ev-ui/src/tokens.js` — design tokens (colors, spacing, radii)
- `ev-ui/src/tailwind-preset.js` — Tailwind theming
- `ev-ui/src/PoliticianCard.jsx` — the closest existing card analog in ev-ui (affordance reference)
- `ev-ui/README-AUTOBUMP.md` — release/publish pipeline (relevant for planner)

### Project-level constraints
- `CLAUDE.md` §"Design System" — ev-coral / ev-muted-blue / ev-light-blue / ev-yellow palette, Manrope font
- Antipartisan principle (user memory: `feedback_antipartisan.md`) — no party labels, no partisan color associations

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/components/CompassFirstCard.jsx` variant C — near-complete reference implementation (VARIANT_CONFIG.C has `horizontal: true`, 250px radar, proper padding/shadow/radii). Planner should port this into ev-ui, strip variants A/B, and rewire constants through tokens.
- `ev-ui/src/RadarChartCore.jsx` — already published and stable; used directly.
- `ev-ui/src/PoliticianCard.jsx` — existing card patterns for badges, unopposed icon, term dates, initials fallback — source-of-truth for CARD-03 parity.
- `ev-ui/src/tokens.js` + `ev-ui/src/tailwind-preset.js` — theming surface for D-11.

### Established Patterns
- Flat prop contracts across existing ev-ui components (D-01 aligns with convention).
- `essentials` owns page-level state (answers, filters, view mode); ev-ui components are presentational — matches D-03/D-04 (parent-controlled view).
- Auto-bump pipeline (OIDC → npm → `repository_dispatch` → consumer auto-merge) handles release; planner doesn't need bespoke publish steps.

### Integration Points
- New component exported from `ev-ui/src/index.js` as `CompassCardHorizontal`.
- Consumers (essentials Representatives, Elections, Prototype) continue to import from `@empoweredvote/ev-ui`.
- Page-level `SegmentedControl` for view toggle is a Phase 129 concern (essentials adoption); Phase 127 only needs the harness to exercise both values of the `view` prop.

</code_context>

<specifics>
## Specific Ideas

- Use variant C as the visual reference (already approved/live at `/prototype`). Ports cleanly into ev-ui.
- Meta column content split by surface (representatives vs elections) came directly from user — planner should prefer a single prop (e.g., `surface`) over forking into two components, to keep API surface small.
- Portrait view replaces the radar at the **same dimensions** — grid uniformity is explicit user intent.
- No per-card toggle button means the card itself does not need any interactive chrome for view switching in this phase — simplifies the component.

</specifics>

<deferred>
## Deferred Ideas

- **Empty/non-compass variants** — placeholder radar when user has <3 answers, administrative-role layout, judicial layout → Phase 128 (STATE-01, STATE-02, STATE-03).
- **Essentials adoption + `/prototype` retirement** → Phase 129 (ADOPT-01..04).
- **ev-ui standalone demo page** (rejected for now at D-13). Could resurface if ev-ui grows past a handful of components.
- **Per-card inline view toggle** — rejected at D-06. If discoverability data later indicates users miss the page-level control, revisit.
- **Stance summary snippet in portrait view** — rejected at D-10 to keep grid uniform. Possible future enhancement.

</deferred>

---

*Phase: 127-compass-card-horizontal-ev-ui*
*Context gathered: 2026-04-19*
