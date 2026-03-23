# Phase 96: Visual Refresh - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Treasury Tracker adopts the full EV design system: Tailwind CSS 4 with ev-ui tailwind-preset, EV design tokens for all UI chrome, Manrope typography, and the canonical ev-ui data visualization palette for chart segment fills. All non-D3 component CSS files are fully converted to Tailwind utility classes. Components get a full visual redesign — not just token swaps.

</domain>

<decisions>
## Implementation Decisions

### CSS Migration Strategy
- **D-01:** Full conversion from plain CSS to Tailwind CSS 4 utility classes. All companion `.css` files are removed except D3 chart components.
- **D-02:** D3 chart CSS files (BudgetIcicle.css, BudgetSunburst.css, BudgetTree.css) remain as companion files since D3 directly manipulates SVG elements with class-based selectors.
- **D-03:** Tailwind CSS 4 uses CSS-first config (`@import "tailwindcss"` + `@theme` block in index.css), matching essentials and CompassV2 apps.

### Component Refresh Scope
- **D-04:** Full redesign of all UI chrome — header, EntitySwitcher, DatasetTabs, CategoryList, Breadcrumb, SearchBar, YearSelector, buttons, LineItemsTable, PerDollarBreakdown. Not just token swaps — new layouts, spacing, shadows, hover states.
- **D-05:** All UI chrome components receive equal design attention. No component is token-swap-only.
- **D-06:** Use the `/frontend-design` skill during execution to achieve high design quality. Treasury has unique data density needs — design should be optimized for budget data presentation, not necessarily mirroring essentials or CompassV2 layouts.

### Data Visualization Palette
- **D-07:** Replace treasury-tracker's custom 6-hue `--data-*` CSS vars with ev-ui's canonical `dataVizPalette` (10 hues × 5 shades, brand-derived from tokens.js).
- **D-08:** Chart segment fills use separate `--data-*` namespace — no EV brand token bleed into chart fills (carried forward from STATE.md decision).
- **D-09:** Data viz colors defined in Tailwind `@theme` block so they're available as utility classes (e.g., `bg-data-teal-500`) and accessible by D3 charts via CSS custom properties.

### ev-ui Integration
- **D-10:** Import tailwind-preset and tokens only — no ev-ui React components. Treasury-specific components are built from scratch using Tailwind classes.
- **D-11:** ev-ui upgraded from `^0.1.6` to `^0.1.53+` (current version).

### Claude's Discretion
- Visual layout decisions for budget data components — Claude has creative freedom within EV design tokens to optimize for data density and readability
- Specific Tailwind utility class patterns (flex vs grid, spacing values, responsive breakpoints)
- Animation/transition choices within ev-ui's defined animation tokens
- Component decomposition during the conversion

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### EV Design System
- `ev-ui/design-system/index.html` — Complete design system reference with data viz palette swatches, component patterns, button states, pillar colors, and chart examples
- `ev-ui/src/tokens.js` — Canonical design tokens: colors, colorScales, dataVizPalette (10 hues × 5 shades), fonts, spacing, borderRadius, shadows
- `ev-ui/src/tailwind-preset.js` — Tailwind CSS preset that maps tokens to Tailwind theme extensions

### Existing App References (Tailwind CSS 4 integration pattern)
- `essentials/src/index.css` — Reference for how `@import "tailwindcss"` + `@theme` block is structured in an EV app
- `CompassV2/src/index.css` — Another reference for Tailwind CSS 4 integration pattern

### Treasury Tracker Current State
- `treasury-tracker/src/index.css` — Current CSS variable definitions (to be replaced)
- `treasury-tracker/src/App.css` — Current component styles (to be converted to Tailwind)
- `treasury-tracker/package.json` — Current dependencies including ev-ui ^0.1.6

### Prior Phase Context
- `.planning/phases/95-entity-switcher/95-CONTEXT.md` — EntitySwitcher component decisions (D-01, D-02)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Manrope font import** already exists in `index.css` — just needs to be preserved in Tailwind migration
- **EV brand color CSS vars** already defined — will be replaced by Tailwind @theme tokens from ev-ui preset
- **ev-ui tailwind-preset** exports complete theme with colors, spacing, typography, animations, shadows

### Established Patterns
- **essentials/CompassV2 Tailwind 4 pattern:** `@import "tailwindcss"` + `@theme { }` block in index.css — treasury should match this exactly
- **D3 chart components** use companion .css files with class-based SVG selectors — this pattern stays
- **Component structure:** 23 components in `src/components/`, 12 with companion `.css` files to convert

### Integration Points
- `index.css` — Entry point for Tailwind import and @theme block
- `package.json` — ev-ui version upgrade, add tailwindcss + postcss devDependencies
- `vite.config.ts` — May need postcss configuration for Tailwind CSS 4
- All component `.tsx` files — className attributes replace CSS class references

</code_context>

<specifics>
## Specific Ideas

- Use the `/frontend-design` skill during execution to make the design exceptional — the user wants treasury-tracker to "soar" visually
- Treasury has unique data density needs (budget categories, line items, per-dollar breakdowns) — design should be optimized for this, not copied from other EV apps
- The ev-ui design system at `ev-ui/design-system/index.html` is the authoritative visual reference

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 96-visual-refresh*
*Context gathered: 2026-03-23*
