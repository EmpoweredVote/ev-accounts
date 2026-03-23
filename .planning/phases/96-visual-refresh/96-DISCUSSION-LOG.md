# Phase 96: Visual Refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-23
**Phase:** 96-visual-refresh
**Areas discussed:** CSS migration strategy, Component refresh scope, Data viz palette, ev-ui integration depth

---

## CSS Migration Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Full conversion (Recommended) | Install Tailwind CSS 4, convert all 12 component .css files to Tailwind utility classes inline. Removes all companion .css files. Matches essentials/CompassV2. | ✓ |
| Token swap only | Install Tailwind CSS 4 and ev-ui preset for theme, keep existing .css files. Just replace CSS variable names. | |
| Incremental hybrid | Install Tailwind, convert UI chrome to utility classes, leave D3 chart .css files. | |

**User's choice:** Full conversion
**Notes:** None

### Follow-up: D3 Chart CSS

| Option | Description | Selected |
|--------|-------------|----------|
| Keep D3 chart CSS (Recommended) | BudgetIcicle.css, BudgetSunburst.css, BudgetTree.css stay as companion files. Everything else converts. | ✓ |
| Convert everything | Even D3 chart styling moves to Tailwind where possible. | |

**User's choice:** Keep D3 chart CSS
**Notes:** D3 directly manipulates SVG elements — companion CSS files are the right pattern

---

## Component Refresh Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Token swap only (Recommended) | Keep existing layouts, just update colors/fonts/spacing to EV tokens. | |
| Light polish | Token swap plus minor refinements: consistent border-radius, shadows, hover/focus states. | |
| Full redesign | Rethink component layouts to match essentials/CompassV2 visual quality. New card styles, spacing, interactions. | ✓ |

**User's choice:** Full redesign
**Notes:** None

### Follow-up: Priority

| Option | Description | Selected |
|--------|-------------|----------|
| All UI chrome equally | All components get equal redesign attention. | ✓ |
| Header + navigation first | Focus on header area; data tables get token swaps only. | |
| Cards + data display first | Focus on data presentation; navigation chrome gets token swaps only. | |

**User's choice:** All UI chrome equally
**Notes:** None

### Follow-up: Visual Reference

| Option | Description | Selected |
|--------|-------------|----------|
| Match essentials style | Use essentials app as the visual reference. | |
| Match CompassV2 style | Use CompassV2 as the reference. | |
| Claude's discretion | Stay within EV tokens but let Claude design the best layout for budget data. | ✓ |

**User's choice:** Claude's discretion
**Notes:** "Also use the /frontend-design skill to make the design soar" — treasury has unique data density needs

---

## Data Viz Palette

| Option | Description | Selected |
|--------|-------------|----------|
| Use ev-ui palette (Recommended) | Replace custom --data-* vars with canonical ev-ui dataVizPalette (10 hues × 5 shades). Single source of truth. | ✓ |
| Keep treasury palette | Treasury's current 6-hue palette tuned for budget data. Move to Tailwind @theme but keep hex values. | |

**User's choice:** Use ev-ui palette
**Notes:** User pointed to `ev-ui/design-system/index.html` and `ev-ui/src/tokens.js` as the authoritative source for data viz colors

---

## ev-ui Integration Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Preset + tokens only (Recommended) | Import tailwind-preset + tokens.js. Build treasury-specific components from scratch with Tailwind classes. | ✓ |
| Import SiteHeader | Use ev-ui SiteHeader for top nav, build everything else treasury-specific. | |
| Import multiple components | Use SiteHeader plus other reusable components from ev-ui. | |

**User's choice:** Preset + tokens only
**Notes:** Treasury's UI needs are distinct from essentials/compass

### Follow-up: Token Import Method

| Option | Description | Selected |
|--------|-------------|----------|
| Tailwind @theme (Recommended) | Define data viz colors in @theme block, available as utility classes. D3 charts access via CSS custom properties. | ✓ |
| JS runtime import | Import dataVizPalette from tokens.js directly in chart components. | |

**User's choice:** Tailwind @theme
**Notes:** None

---

## Claude's Discretion

- Visual layout decisions for budget data components
- Specific Tailwind utility class patterns
- Animation/transition choices
- Component decomposition during conversion

## Deferred Ideas

None — discussion stayed within phase scope
