# Project Research Summary

**Project:** v2026.4.1 Essentials Visual Polish & Election Improvements
**Domain:** Visual polish — icon system, tier hue differentiation, compass-first card prototype, headshot fixes, election page cleanup
**Researched:** 2026-04-02
**Confidence:** HIGH — all findings from direct codebase inspection and verified npm registry data

## Executive Summary

This milestone is a focused visual polish pass on the `essentials` app and its shared `ev-ui` component library. The feature set is well-scoped and low-risk individually, but the shared library dependency chain (ev-ui feeds essentials, CompassV2, and EV-readrank) means every ev-ui change has a multi-app blast radius. Experts build this type of design system polish by treating the shared library as a stable contract: new props are always optional with safe fallbacks, visual variants live in the consuming app until confirmed, and the library is published consciously rather than incrementally. All findings here come from direct code inspection of the current codebase, not external documentation.

The recommended approach is a dependency-ordered build: ev-ui token and prop additions first (tierColors in tokens.js, icons.js SVG exports, optional tier/icons props on CategorySection and PoliticianCard), followed by a single ev-ui publish (v0.1.55), then wiring changes in essentials. The compass-first card is the exception — it stays local to essentials as a prototype, never touching ev-ui until the layout is confirmed across a full release cycle. Landing page improvements and the incumbent badge removal are independent of the ev-ui release cycle and can be batched with Phase 1 to clear quick wins early.

The primary risk in this milestone is inadvertent partisan color association in the tier hue system. The EV platform has a hard antipartisan principle, and federal/state/local tier differentiation using common US political color vocabulary (red/blue) would undermine user trust even if unintentional. The safe resolution is using shade variation within the existing teal brand palette only. A secondary risk is the ev-ui breaking change cascade — any prop addition must be optional with a null-safe fallback, verified rendering without the prop before publishing. A third risk is the hover-only tooltip pattern being inaccessible on mobile: tooltips must supplement labels, not replace them.

## Key Findings

### Recommended Stack

Two new npm dependencies are justified for this milestone: `lucide-react` (v1.7.0) for icons and `@floating-ui/react` (v0.27.19) for tooltip positioning. Both are React 19 compatible (explicit peer dep declarations confirmed via npm registry), and the combined bundle impact is approximately 7–9kB gzipped. However, these belong in `essentials` only, not in `ev-ui`. The shared library already uses inline SVG components for its compass icon, and adding an icon library to ev-ui would impose bundle overhead on all three consumer apps without opt-out. The ev-ui `tsup.config.js` uses `splitting: false` — all components bundle together, so any dependency added to ev-ui ships to every consumer.

All other new capabilities require no new packages. Tier colors use JavaScript inline styles from `tokens.js` (the existing ev-ui design token system — not Tailwind classes, which cannot override ev-ui inline styles). The headshot crop issue is a one-line CSS `object-position: top` fix applied to the `<img>` element in PoliticianCard. The compass-first card prototype reuses `RadarChartCore` already available from ev-ui.

**Core technologies (new additions only):**
- `lucide-react` v1.7.0 in essentials: icon system — 29.4M weekly downloads, tree-shakeable via Vite, React 19 explicit peer dep confirmed
- `@floating-ui/react` v0.27.19 in essentials: tooltip positioning primitives — ~7kB gzipped, accessible ARIA patterns built-in, handles mobile viewport collision
- `tokens.js` (ev-ui): add `tierColors` export alongside existing `pillars` — teal-scale shade variation, single source of truth synced to Penpot
- `ev-ui/src/icons.js` (NEW FILE): inline SVG React components (`BallotIcon`, `LegislativeIcon`, `ExecutiveIcon`, `JudicialIcon`) — follows existing inline compass SVG pattern, zero new library dependency in ev-ui

### Expected Features

The milestone has a clear MVP tier that is LOW-to-MEDIUM complexity and a deferred tier that carries HIGH complexity and data dependency risk.

**Must have (table stakes):**
- Visual tier distinction (Federal/State/Local hue differentiation) — users cannot assess representative relevance without knowing which level of government they represent; all major civic directories use tier grouping
- Icon metadata row on politician cards (ballot status, compass available, branch type) — replaces verbose text badges; reduces cognitive load on information-heavy listing pages
- Accessible hover tooltips on icons — WCAG 1.4.1 requires non-color cues; tooltips satisfy progressive disclosure while icons handle scannable users
- Location shortcut buttons on Landing page — current landing shows no explanation for why no results appear in unsupported areas; "No results" without coverage context destroys trust

**Should have (differentiators for this milestone):**
- Within-Local sub-tier hue differentiation (city vs county vs township) — not offered by any competing civic directory; reduces visual blur when 30+ local officials appear on screen
- Branch-type icon (legislative/executive/judicial) derived from `district_type` — helps users mentally organize what their representatives do; unique to EV
- Headshot crop default fix (`object-position: top` on PoliticianCard `<img>`) — improves approximately 90% of the 503 CDN headshots with zero data migration

**Defer:**
- Compass-first card as a default view — HIGH null-data risk; most local officials lack compass stance data; keep as opt-in toggle prototype only, activated only for politicians with confirmed stances
- Full ev-ui PoliticianCard redesign — too broad for this milestone; scope changes to optional prop additions only
- Headshot re-uploads — CSS fix first; re-upload only after the audit script identifies truly broken source images that CSS cannot salvage

**Out of scope (anti-features):**
- Party color coding — hard violation of the documented antipartisan principle
- Automatic face-centered crop via Supabase Storage — Supabase Storage does not support face detection; cover/contain/fill only
- Expanding CompassPreview into a persistent sidebar panel — conflicts with the existing sticky sidebar in Results
- Animated tier badge transitions — distracts from content; `prefers-reduced-motion` violation risk

### Architecture Approach

The build is organized around a clean dependency boundary: ev-ui receives additive prop changes only (optional props with null-safe fallbacks), essentials consumes those changes after a deliberate version publish, and the compass-first card prototype stays entirely local to essentials. The critical architectural constraint is that ev-ui components use JavaScript inline style objects from `tokens.js`, not Tailwind utility classes. Tailwind classes applied from outside the component cannot override inline styles without `!important`. Tier color injection requires either an explicit named prop (preferred) or the `style` prop pass-through that `CategorySection` already exposes. Dynamic Tailwind class string construction (e.g., `` `bg-ev-${tier}-050` ``) must never be used — Tailwind CSS 4's static analyzer will not include dynamically constructed class names in the output bundle.

**Major components:**
1. `ev-ui/src/tokens.js` — add `tierColors` export; teal-scale shade variation (Federal=teal-700, State=teal-500, Local=yellow-600 or teal-200); single source of truth
2. `ev-ui/src/icons.js` (NEW) — inline SVG exports following existing PoliticianCard compass icon pattern; zero new ev-ui dependencies
3. `ev-ui/src/CategorySection.jsx` — add optional `tier` prop; apply `tierColors[tier]` to title pill background/border when present; neutral defaults when absent
4. `ev-ui/src/PoliticianCard.jsx` — add optional `icons[]` prop and `imageFocalPoint` prop; `icons[]` renders alongside/replacing text badge for on-ballot signal
5. `essentials/src/pages/Results.jsx` — wire `tier` into CategorySection calls; wire `icons[]` from existing computed signals (getSeatBallotStatus, politicianIdsWithStances, district_type)
6. `essentials/src/pages/Landing.jsx` — add location shortcut buttons + coverage disclaimer (no API changes; 74-line file, minimal scope)
7. `essentials/src/components/CompassFirstCard.jsx` (NEW, local prototype) — compass-first layout using RadarChartCore; feature-flagged toggle in Results; stays local until design is confirmed
8. `essentials/src/components/ElectionsView.jsx` — remove incumbent badge (visual only, scope limited to badge prop removal); add tier icons to separator rows

### Critical Pitfalls

1. **ev-ui change breaks all three consumer apps simultaneously** — All new ev-ui props must be optional with safe fallbacks. Never make a new prop required at existing call sites. Verify the component renders correctly without any new props before running `npm publish`. Test in essentials dev first. Emergency rollback (re-publish previous version + redeploy 3 Cloudflare Pages apps) is slow — prevention is essential.

2. **Tier hue system inadvertently introduces partisan color associations** — Use teal lightness/shade variation only (teal-700 for Federal, teal-500 for State, yellow/teal-200 for Local). Never use red or blue, which carry embedded US political party associations. Lock the palette before implementation — do not design colors during code writing. Run the antipartisan color check before finalizing.

3. **`buildTitleAndSubtitle()` logic drift between ev-ui and essentials** — This function is duplicated in `ev-ui/src/PoliticianProfile.jsx` and `essentials/src/pages/Results.jsx`. The CLAUDE.md explicitly documents this. Any touch to title/subtitle display logic must update both files in the same commit. Do not touch this function at all during this milestone unless fixing a documented bug — even icon placement near titles can create pressure to refactor the title logic.

4. **Hover-only icon tooltips are inaccessible on mobile** — Tooltips must provide detail, not the primary label. Every icon must be paired with a visible text label or `aria-label` in the default no-interaction state. WCAG 1.4.13 requires hover content to be dismissible, hoverable, and persistent — but the right fix is ensuring the icon meaning does not require hover at all. Mobile users (likely majority of civic app users) cannot hover. Test on real iPhone with Safari before shipping.

5. **Removing "incumbent" marker must not touch `is_incumbent` branching in CandidateProfile** — The scope is: remove the `badge="Incumbent"` prop from the PoliticianCard call in ElectionsView.jsx only. The `is_incumbent` flag in CandidateProfile.jsx controls whether the full legislator profile or minimal challenger view renders — this branching logic must not be touched. Add a code comment to the branching point: `// badge display removed in v2026.4.1 but this routing logic stays`.

## Implications for Roadmap

Based on research, the ev-ui publish is the critical path. Everything that touches ev-ui must complete before essentials wiring can proceed. Independent tasks (Landing page buttons, incumbent badge removal, Ruben Marte data fix) have no ev-ui dependency and can be batched early. The compass-first card prototype is last because it depends on Phase 2 card patterns being stable, and its high null-data rate risk makes early deployment inadvisable.

### Phase 1: ev-ui Foundation + Quick Wins
**Rationale:** All tier-color and icon wiring in essentials depends on ev-ui publishing new props. This is the critical path and must be completed before any essentials wiring can proceed. Quick independent wins (incumbent badge removal, Ruben Marte data fix) are batched here to clear known issues while the library work proceeds. Palette must be locked before any token code is written.
**Delivers:** ev-ui v0.1.55 with `tierColors` in tokens.js, `icons.js` SVG exports, optional `tier` prop on CategorySection, optional `icons[]` and `imageFocalPoint` props on PoliticianCard. Incumbent badge removed from ElectionsView. Ruben Marte politician_id data fix applied.
**Addresses:** Icon metadata system (table stakes), tier hue foundation (table stakes), headshot crop default improvement (differentiator)
**Avoids:** Breaking consumer apps (optional props, null-safe fallbacks, verified without props before publish); partisan color associations (teal scale locked before implementation begins)

### Phase 2: essentials Wiring + Landing Page
**Rationale:** Depends on ev-ui v0.1.55 being installed in essentials. Once the library is updated, Results.jsx can wire `tier` into CategorySection and `icons[]` into PoliticianCard using signals already computed (ballotStatus, politicianIdsWithStances, district_type). Landing page improvements are independent of ev-ui and run in parallel within this phase.
**Delivers:** Tier hue visible across all Federal/State/Local sections in Results. Icon metadata row (ballot, compass, branch type) on politician cards with accessible tooltips. Location shortcut buttons on Landing.jsx with coverage disclaimer text.
**Uses:** tierColors from tokens.js (via ev-ui prop); lucide-react + @floating-ui/react in essentials for icon tooltips
**Implements:** Icon signal resolution data flow (Results.jsx → PoliticianCard icons prop), tier color flow (classify.js → Results.jsx → CategorySection tier prop → tierColors)
**Avoids:** Dynamic Tailwind class interpolation for tier hues; Tailwind override of ev-ui inline styles; hover-only tooltip patterns (pair icons with visible labels)

### Phase 3: Compass-First Card Prototype + Headshot Audit
**Rationale:** Deferred until Phase 2 is complete and the icon/tier card patterns are finalized. CompassFirstCard.jsx can reuse the icon and tier patterns established in Phase 2. The headshot audit script is independent tooling with no user-facing changes and can run at any point.
**Delivers:** `CompassFirstCard.jsx` local prototype in essentials with feature-flagged toggle in Results (activated only when `politicianIdsWithStances.has(pol.id)` is true). Node.js audit script querying `essentials.politician_images`, downloading images via `sharp`, and outputting a CSV of flagged politician IDs and URLs for manual review.
**Avoids:** Promoting CompassFirstCard to ev-ui during prototype (keep local until layout confirmed across one full release cycle); re-uploading all 503 headshots unnecessarily (CSS objectPosition fix in Phase 1 handles ~90%; audit identifies only true outliers that CSS cannot salvage)

### Phase Ordering Rationale

- ev-ui must publish before essentials wiring: ev-ui inline styles cannot be overridden from outside the component. New props must exist in the published library before consuming apps can use them.
- Icon and tooltip approach must be locked in Phase 1 before Phase 2 tooltip implementation: changing icon system mid-wiring doubles rework. Decide inline SVG vs. lucide-react, number of icons, and mobile label strategy before writing any icon code.
- Compass-first card is last: it depends on Phase 2 card patterns being stable; its high null-data rate risk makes early deployment low-value without broader stance data coverage for local officials.
- Quick wins batched in Phase 1: incumbent badge removal and Ruben Marte fix are low-risk and independent. Batching them early prevents simple tasks from perpetually deferring to "later."

### Research Flags

Phases with well-documented patterns (skip additional research):
- **Phase 1 — ev-ui token/prop additions:** Established codebase patterns (tokens.js, inline SVG, optional props). No external unknowns.
- **Phase 2 — Landing page buttons:** 74-line file, no API changes, navigate() call with pre-built URL. No research needed.
- **Phase 2 — Incumbent badge removal:** One-line ElectionsView prop change. Pitfall is documented and scoped.
- **Phase 3 — Headshot audit script:** `sharp` is well-documented for Node.js image processing. Supabase Storage URL pattern is already established in the codebase.

Phases that benefit from validation before or during implementation:
- **Phase 2 — Icon tooltip accessibility on mobile:** The @floating-ui/react hover+focus interaction pattern is documented in STACK.md with a working code sample, but mobile touch behavior (tap-to-open tooltip, dismiss on outside tap) should be validated on a real iPhone with Safari early in Phase 2, not at the end. This is a QA step, not additional research.
- **Phase 3 — Compass-first card null rate:** Before building the prototype, run `SELECT COUNT(DISTINCT politician_id) FROM compass.stances` vs `SELECT COUNT(*) FROM essentials.politicians` to determine the real null rate. If coverage is below 20% for local officials (the primary audience), the toggle may not be worth the prototype effort in this milestone.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All package versions confirmed via npm view; React 19 peer deps explicitly verified; CSS techniques confirmed from official Tailwind CSS 4 docs and codebase patterns |
| Features | HIGH | All existing functionality verified by direct code inspection of ev-ui and essentials source; new feature complexity assessments grounded in actual file sizes and current prop interfaces |
| Architecture | HIGH | All findings from direct source inspection; build order derived from real dependency graph in the code (tsup splitting:false, inline style specificity, classify.js tier taxonomy) |
| Pitfalls | HIGH | Most pitfalls documented from actual codebase patterns (inline style specificity, tsup splitting:false, duplicate buildTitleAndSubtitle, CandidateProfile is_incumbent branching); WCAG citations verified from W3C |

**Overall confidence:** HIGH

### Gaps to Address

- **Compass-first card null rate:** Unknown what percentage of `essentials.politicians` have compass stance data. Query `SELECT COUNT(DISTINCT politician_id) FROM compass.stances` before committing to Phase 3 scope. If local official coverage is below 20%, the prototype is low-value and should remain deferred until stance data improves.
- **Exact geo_id values for location shortcut buttons:** Landing page shortcut buttons need the correct `geo_id` + `mtfcc` values for Monroe County IN and LA County CA to pre-fill the LocationBrowser correctly, or a representative address string that will resolve via the existing geocoding pipeline. Retrieve from the database before Phase 2 implementation.
- **Final tier color palette decision:** PITFALLS research recommends teal-scale shade variation only (Federal=teal-700, State=teal-500, Local=teal-200). FEATURES research suggests yellow for Local. These conflict slightly. This decision must be made and locked before Phase 1 token work begins — PITFALLS guidance (partisan color risk) should take precedence: default to teal-scale only.

## Sources

### Primary (HIGH confidence)
- `ev-ui/src/tokens.js` — colorScales, colors, pillars, semantic tokens, full teal and skyblue scales
- `ev-ui/src/PoliticianCard.jsx` — prop interface, inline style object pattern, existing compass SVG component (lines 168-205)
- `ev-ui/src/CategorySection.jsx` — prop interface, tooltip pattern (onMouseEnter/onMouseLeave), style prop pass-through
- `ev-ui/src/tsup.config.js` — `splitting: false` confirmed; all components bundle together
- `ev-ui/package.json` — current version: 0.1.54; no sideEffects declaration
- `essentials/src/pages/Results.jsx` — full renderPoliticianCard() flow, politicianIdsWithStances Set, classify.js integration, getSeatBallotStatus usage
- `essentials/src/pages/Landing.jsx` — confirmed 74 lines, single address input, no location shortcuts
- `essentials/src/lib/classify.js` — classifyCategory() tier/group taxonomy, FEDERAL_ORDER, STATE_ORDER, LOCAL_ORDER exports
- `essentials/src/components/ElectionsView.jsx` — getTier(), incumbent badge prop, tier separator rendering
- `essentials/src/components/PoliticianCard.jsx` — legacy vertical card (separate from ev-ui, used in PoliticianGrid)
- lucide-react npm registry: v1.7.0, peer deps `^16.5.1 || ^17.0.0 || ^18.0.0 || ^19.0.0` confirmed via npm view
- @floating-ui/react npm registry: v0.27.19, peer deps `>=17.0.0` confirmed via npm view
- Tailwind CSS v4 Theme Variables docs — `@theme` directive generates CSS custom properties; OKLCH color support
- WCAG 1.4.1 Use of Color (W3C) — color cannot be sole visual differentiator
- WCAG 1.4.13 Content on Hover or Focus (W3C) — hover content must be dismissible, hoverable, persistent
- Supabase Storage image transformations docs — confirmed no face detection; cover/contain/fill only

### Secondary (MEDIUM confidence)
- React Icon Libraries Bundle Size Benchmark (Medium/nkcroft, 2026) — lucide delta/source ratio ~1x vs phosphor 16-18x; confirmed lucide tree-shaking superiority
- Design Tokens That Scale in 2026 (Mavik Labs) — OKLCH token pattern for perceptually even tier hue steps
- Smart cropping with native browser Face Detection (IODigital) — confirms CSS object-position + Face Detection API limitations; ~70% browser support for Face Detection API
- USWDS Icon List component — icon + adjacent text as accessible metadata pattern; `aria-hidden` on decorative icons
- tsup tree-shaking guide (dorshinar.me) — `splitting: false` behavior confirmed; sideEffects: false requirement for consumer tree-shaking
- Floating UI React docs — useHover, useFocus, useRole, FloatingPortal patterns confirmed

### Tertiary (LOW confidence)
- None — all findings in this summary are supported by primary or secondary sources

---
*Research completed: 2026-04-02*
*Ready for roadmap: yes*
