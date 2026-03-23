# Phase 96: Visual Refresh - Research

**Researched:** 2026-03-23
**Domain:** Tailwind CSS 4 integration, EV design system adoption, CSS migration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Full conversion from plain CSS to Tailwind CSS 4 utility classes. All companion `.css` files are removed except D3 chart components.
- **D-02:** D3 chart CSS files (BudgetIcicle.css, BudgetSunburst.css, BudgetTree.css) remain as companion files since D3 directly manipulates SVG elements with class-based selectors.
- **D-03:** Tailwind CSS 4 uses CSS-first config (`@import "tailwindcss"` + `@theme` block in index.css), matching essentials and CompassV2 apps.
- **D-04:** Full redesign of all UI chrome — header, EntitySwitcher, DatasetTabs, CategoryList, Breadcrumb, SearchBar, YearSelector, buttons, LineItemsTable, PerDollarBreakdown. Not just token swaps — new layouts, spacing, shadows, hover states.
- **D-05:** All UI chrome components receive equal design attention. No component is token-swap-only.
- **D-06:** Use the `/frontend-design` skill during execution to achieve high design quality. Treasury has unique data density needs — design should be optimized for budget data presentation, not necessarily mirroring essentials or CompassV2 layouts.
- **D-07:** Replace treasury-tracker's custom 6-hue `--data-*` CSS vars with ev-ui's canonical `dataVizPalette` (10 hues × 5 shades, brand-derived from tokens.js).
- **D-08:** Chart segment fills use separate `--data-*` namespace — no EV brand token bleed into chart fills.
- **D-09:** Data viz colors defined in Tailwind `@theme` block so they're available as utility classes (e.g., `bg-data-teal-500`) and accessible by D3 charts via CSS custom properties.
- **D-10:** Import tailwind-preset and tokens only — no ev-ui React components. Treasury-specific components are built from scratch using Tailwind classes.
- **D-11:** ev-ui upgraded from `^0.1.6` to `^0.1.53+` (current version).

### Claude's Discretion

- Visual layout decisions for budget data components — Claude has creative freedom within EV design tokens to optimize for data density and readability
- Specific Tailwind utility class patterns (flex vs grid, spacing values, responsive breakpoints)
- Animation/transition choices within ev-ui's defined animation tokens
- Component decomposition during the conversion

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIS-01 | Tailwind CSS 4 installed in treasury-tracker with ev-ui tailwind-preset | Tailwind CSS 4 installation pattern verified from essentials and CompassV2; two approaches available — Vite plugin (D-03 path) or PostCSS |
| VIS-02 | ev-ui upgraded from ^0.1.6 to current version | Current version confirmed as 0.1.53 from npm registry and local ev-ui/package.json |
| VIS-03 | UI chrome (header, cards, tabs, buttons) uses EV design tokens | Full token map verified from ev-ui/src/tokens.js and tailwind-preset.js; UI-SPEC defines exact class assignments |
| VIS-04 | Chart colors updated to use EV brand-aligned data visualization palette | dataVizPalette (10 hues × 5 shades) verified in ev-ui/src/tokens.js; color property stored in treasury.budget_categories DB column — requires color assignment update in import scripts or API layer |
| VIS-05 | Typography uses Manrope consistent with other EV apps | Manrope already imported in treasury-tracker/src/index.css; needs preservation in Tailwind migration; font-manrope class available via ev-ui tailwind-preset |
</phase_requirements>

---

## Summary

Treasury Tracker needs a full CSS stack replacement: remove plain CSS files (except D3 companions), add Tailwind CSS 4, import ev-ui tailwind-preset, and redesign all UI chrome components using EV design tokens. The 96-UI-SPEC.md document provides the complete visual contract — every component class spec, color assignment, spacing value, and typography rule. Research confirms the UI-SPEC is accurate and implementation-ready.

The critical complexity is the **two-path Tailwind CSS 4 installation**: CompassV2 uses the `@tailwindcss/vite` Vite plugin (simpler, no `postcss.config.js`), while essentials uses the `@tailwindcss/postcss` PostCSS approach. Treasury-tracker uses Vite 7 like essentials, but either path works. The Vite plugin approach is simpler for a project with no PostCSS plugin requirements beyond Tailwind.

The **data visualization color migration** has a backend dimension: the `color` field is stored as a string in `treasury.budget_categories`. Current import scripts write EV brand hex values directly (e.g., `#00657C`, `#59B0C4`). After this phase, charts should derive colors from the canonical `--color-data-*` CSS custom properties rather than from stored hex values. The frontend can compute colors by index position (cycling through the 10-hue dataVizPalette), making the stored `color` field effectively unused for chart fills.

**Primary recommendation:** Use the `@tailwindcss/vite` plugin approach matching CompassV2, remove all non-D3 CSS companion files, implement full component redesigns per 96-UI-SPEC.md, and assign chart colors by category index using CSS custom properties — never from the stored `color` field.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| tailwindcss | ^4.1.12 | Utility-first CSS framework | Used across all EV apps; v4 is CSS-first |
| @tailwindcss/vite | ^4.1.10 | Vite plugin for Tailwind CSS 4 | CompassV2 pattern; simpler than PostCSS route for Vite projects |
| @chrisandrewsedu/ev-ui | ^0.1.53 | EV design tokens + Tailwind preset | Project design system; upgraded from 0.1.6 |

### Supporting (already installed)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| lucide-react | ^0.562.0 | Icon library | Already in deps; use for all icons in redesigned chrome |
| d3 | ^7.9.0 | Data visualization | Stays; D3 chart CSS companion files remain unchanged in structure |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @tailwindcss/vite | @tailwindcss/postcss + postcss.config.js | PostCSS approach used in essentials; either works but Vite plugin is simpler |

### Installation

```bash
cd treasury-tracker
npm install --save-dev tailwindcss @tailwindcss/vite
npm install @chrisandrewsedu/ev-ui@^0.1.53
```

**Version verification:**
- tailwindcss: 4.1.12 (confirmed from essentials package.json)
- @tailwindcss/vite: 4.1.10 (confirmed from CompassV2 package.json)
- @chrisandrewsedu/ev-ui: 0.1.53 (confirmed from npm registry and local ev-ui/package.json)

---

## Architecture Patterns

### Recommended Project Structure (after migration)

```
treasury-tracker/src/
├── index.css               # Tailwind import + @theme block (full data viz palette)
├── App.css                 # REMOVED — all styles become inline Tailwind on components
├── components/
│   ├── EntitySwitcher.tsx  # Rewritten with Tailwind classes
│   ├── EntitySwitcher.css  # REMOVED
│   ├── LineItemsTable.tsx  # Rewritten with Tailwind classes
│   ├── LineItemsTable.css  # REMOVED
│   ├── BudgetIcicle.tsx    # Color source updated to CSS vars
│   ├── BudgetIcicle.css    # KEPT — D3 SVG selector patterns preserved, colors updated
│   ├── BudgetSunburst.tsx  # Color source updated to CSS vars
│   ├── BudgetSunburst.css  # KEPT — D3 SVG selector patterns preserved, colors updated
│   ├── BudgetTree.tsx      # Color source updated to CSS vars
│   └── BudgetTree.css      # KEPT — D3 SVG selector patterns preserved, colors updated
└── ...
```

### Pattern 1: Tailwind CSS 4 index.css Structure

**What:** CSS-first configuration with @theme block replacing tailwind.config.js
**When to use:** All Tailwind CSS 4 apps in the EV workspace

```css
/* Source: essentials/src/index.css + CompassV2/src/index.css patterns */
@import "tailwindcss";
@import "@chrisandrewsedu/ev-ui/tailwind-preset";
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&display=swap');

@theme {
  /* Data viz palette — separate --data-* namespace */
  --color-data-teal-100: #C0E8F2;
  --color-data-teal-300: #55D9F6;
  --color-data-teal-400: #3AABB8;
  --color-data-teal-500: #00657C;
  --color-data-teal-700: #003E4D;
  /* ... (full 10-hue × 5-shade palette per 96-UI-SPEC.md) */
}

/* Reset */
*, *::before, *::after { box-sizing: border-box; }
body { font-family: 'Manrope', sans-serif; }
```

### Pattern 2: Vite Config for Tailwind CSS 4

**What:** Add `@tailwindcss/vite` Tailwind plugin to vite.config.ts
**When to use:** Vite-based projects (simpler than PostCSS route)

```typescript
// Source: CompassV2/vite.config.js pattern adapted for TypeScript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: '/',
})
```

### Pattern 3: ev-ui tailwind-preset Import (v4 CSS-first)

**What:** Import the preset as a CSS import, not a JS config
**When to use:** Tailwind CSS 4 projects (v4 eliminated tailwind.config.js in favor of CSS-first)

```css
/* Source: 96-UI-SPEC.md */
@import "@chrisandrewsedu/ev-ui/tailwind-preset";
```

This makes `ev-coral`, `ev-muted-blue`, `ev-yellow`, `ev-teal-*`, `font-manrope`, and all token-based classes available.

**Note:** The ev-ui tailwind-preset.js uses `export default` (ES module). The `tailwind-preset` export path is declared in ev-ui/package.json `exports` field — it resolves to `./src/tailwind-preset.js`. This works as a CSS `@import` in Tailwind CSS 4.

### Pattern 4: Chart Color Assignment by Index

**What:** D3 charts compute fill color from category index using CSS custom properties, not the stored `color` field in BudgetCategory
**When to use:** Any D3 chart that renders budget categories

```typescript
// Source: Architecture pattern derived from D-07, D-08, D-09
const DATA_VIZ_HUES = [
  'teal', 'skyblue', 'ocean', 'coral', 'terracotta',
  'yellow', 'honey', 'sage', 'dusk', 'stone'
];

function getCategoryColor(index: number, shade: '500' | '700' = '500'): string {
  const hue = DATA_VIZ_HUES[index % DATA_VIZ_HUES.length];
  return `var(--color-data-${hue}-${shade})`;
}
```

This replaces reading `category.color` for chart fills and reads CSS custom properties from the `@theme` block instead.

### Anti-Patterns to Avoid

- **Keeping App.css:** The entire App.css file must be replaced with Tailwind utility classes inlined on components. Leaving any non-reset rules in App.css creates a hybrid that's harder to maintain.
- **EV brand tokens as chart fills:** Never use `ev-coral`, `ev-muted-blue`, or `ev-yellow` as D3 `fill` or `backgroundColor` for data segments. Use `--color-data-*` custom properties only (D-08).
- **Inline hex values for brand colors:** Replace `#00657C`, `#FF5740`, `#FED12E` inline style references with Tailwind classes using EV token names.
- **No `tailwind.config.js`:** Tailwind CSS 4 is CSS-first. Do not create a tailwind.config.js — put all theme customization in the `@theme {}` block in index.css.
- **Mixing PostCSS and Vite plugin:** Pick one approach. If using `@tailwindcss/vite`, do not also add `@tailwindcss/postcss` to a postcss.config.js.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| EV brand color definitions | Custom CSS vars in :root | ev-ui tailwind-preset `@import` | Preset contains all color scales, shadows, animations, font family |
| Font-family declaration | Manual @font-face or CSS var | ev-ui `font-manrope` class from preset | Preset maps `fontFamily.manrope` from tokens.js |
| Focus ring styles | Custom box-shadow | ev-ui focus token pattern: `ring-2 ring-ev-muted-blue ring-offset-2` | Matches WCAG AA pattern across all EV apps |
| Data viz color cycling | Custom palette array with hex values | CSS custom property indexing via `--color-data-*` from @theme | Allows chart fills to stay in sync with design system; prevents brand token bleed |
| Animation keyframes | Custom @keyframes | ev-ui `animate-fade-in`, `animate-slide-up`, `animate-scale-in` classes | Keyframes already declared in tailwind-preset.js |

**Key insight:** The ev-ui tailwind-preset contains the entire EV token system — colors, spacing, shadows, animations, font. Importing it once via `@import "@chrisandrewsedu/ev-ui/tailwind-preset"` in index.css replaces all manual color/token declarations.

---

## Common Pitfalls

### Pitfall 1: ev-ui tailwind-preset as Vite CSS @import Resolution

**What goes wrong:** `@import "@chrisandrewsedu/ev-ui/tailwind-preset"` fails at build time because Vite resolves bare specifier CSS imports differently than JS imports.
**Why it happens:** The `tailwind-preset` export in ev-ui package.json points to a `.js` file (not `.css`), so a CSS `@import` may not resolve correctly via the `node_modules` bare specifier.
**How to avoid:** If CSS `@import` fails, use the absolute node_modules path: `@import "../../node_modules/@chrisandrewsedu/ev-ui/src/tailwind-preset.js"`. Alternatively, inline the `@theme` block manually with all token values from tokens.js — this is what CompassV2 and essentials actually do (they define tokens inline in @theme, not via @import of the preset).
**Warning signs:** Build error mentioning unresolved `@import`, or Tailwind classes like `ev-coral` not working in production.

**Critical note from source inspection:** Both essentials and CompassV2 define tokens manually in their `@theme` blocks — they do NOT use `@import "@chrisandrewsedu/ev-ui/tailwind-preset"` as a CSS import. They only use the preset for JS config (tailwind.config.js / v3 pattern). In CSS-first Tailwind v4, the preset tokens are declared directly in `@theme`. The 96-UI-SPEC.md shows this inline approach as the correct pattern.

### Pitfall 2: SiteHeader Import from ev-ui

**What goes wrong:** App.tsx currently imports `SiteHeader` from `@chrisandrewsedu/ev-ui`. This import persists after the upgrade to 0.1.53 and may need to be audited.
**Why it happens:** The SiteHeader was imported in the original App.tsx (line 2: `import { SiteHeader } from '@chrisandrewsedu/ev-ui'`). REQUIREMENTS.md notes "SiteHeader integration" as deferred/out of scope.
**How to avoid:** Verify whether SiteHeader is actively used in the rendered JSX. If not used, remove the import. If used, keep it but verify it still works with 0.1.53.
**Warning signs:** TypeScript error after ev-ui upgrade if SiteHeader API changed between 0.1.6 and 0.1.53.

### Pitfall 3: Stored `color` Field in BudgetCategory API Response

**What goes wrong:** D3 charts currently read `segment.category.color` (a hex string) for segment fill. After migration, if charts still read from `category.color`, they will render the old brand colors (e.g., `#00657C`, `#59B0C4`) instead of the new `--color-data-*` CSS variables.
**Why it happens:** The `color` field is stored in `treasury.budget_categories` in the database. Import scripts (Indiana, LA) write hex values to this column. Frontend code reads `category.color` directly in BudgetIcicle.tsx (`segment.category.color`) and BudgetSunburst.tsx (`.attr('fill', d => d.data.color || '#ccc')`).
**How to avoid:** Replace all `category.color` reads in D3 chart components with computed `getCategoryColor(index)` calls that return `var(--color-data-{hue}-500)`. The stored `color` field becomes unused for fills.
**Warning signs:** Chart segments render in old brand colors (#00657C / #59B0C4 / #FF5740) after migration.

### Pitfall 4: CSS Companion File Removal Breaks BudgetVisualization

**What goes wrong:** BudgetVisualization.css is listed as a non-D3 companion file to convert, but BudgetVisualization.tsx imports it. Removing the CSS file without updating the import causes a build error.
**Why it happens:** The component has `import './BudgetVisualization.css'` at the top. The file must be removed AND the import statement deleted simultaneously.
**How to avoid:** For every CSS file removal, grep for its import in the corresponding `.tsx` file and remove the import statement in the same edit.
**Warning signs:** Vite build error: "Cannot resolve module './BudgetVisualization.css'".

### Pitfall 5: App.css Import in App.tsx

**What goes wrong:** App.tsx has `import './App.css'` on line 16. After conversion, App.css must be removed and this import deleted. If App.css is emptied but not deleted (or the import remains pointing to an empty file), Tailwind may tree-shake correctly but the empty import is noise.
**Why it happens:** The full component styles currently live in App.css (header, tabs, search, year selector, etc.). After conversion, these all become inline Tailwind classes.
**How to avoid:** Remove App.css entirely and delete the import statement from App.tsx as part of the migration. Reset rules (`*, *::before, *::after { box-sizing: border-box; }`) go into index.css.

### Pitfall 6: Tailwind CSS 4 No-Config vs Tailwind CSS 3

**What goes wrong:** Developer tries to create `tailwind.config.js` or `tailwind.config.ts` for extending the theme.
**Why it happens:** Muscle memory from Tailwind CSS 3. Tailwind CSS 4 is CSS-first — all customization goes in `@theme {}` blocks in CSS.
**How to avoid:** All token customization (data viz palette, any overrides) goes in `@theme {}` in `index.css`. No `.config.js` file.

---

## Code Examples

### Complete index.css Structure

```css
/* Source: verified from essentials/src/index.css + CompassV2/src/index.css + 96-UI-SPEC.md */
@import "tailwindcss";
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@400;500;600;700&display=swap');

@theme {
  /* EV Brand Colors (inline from ev-ui/src/tokens.js — CSS-first Tailwind v4) */
  --color-ev-coral: #FF5740;
  --color-ev-muted-blue: #00657C;
  --color-ev-light-blue: #59B0C4;
  --color-ev-yellow: #FED12E;
  --color-ev-yellow-light: #FEF3C7;
  --color-ev-yellow-dark: #D0A301;
  /* Color scales: ev-coral-050 through ev-coral-950, ev-teal-050..., etc. */
  /* (Full scale from tokens.js colorScales) */

  /* Font */
  --font-manrope: 'Manrope', sans-serif;

  /* Data Visualization Palette — SEPARATE namespace (D-08) */
  --color-data-teal-100: #C0E8F2;
  --color-data-teal-300: #55D9F6;
  --color-data-teal-400: #3AABB8;
  --color-data-teal-500: #00657C;
  --color-data-teal-700: #003E4D;
  --color-data-skyblue-100: #CDE0E5;
  --color-data-skyblue-300: #A7CFD8;
  --color-data-skyblue-400: #7FBECC;
  --color-data-skyblue-500: #59B0C4;
  --color-data-skyblue-700: #327E8F;
  --color-data-ocean-100: #CDDCED;
  --color-data-ocean-300: #7BADD4;
  --color-data-ocean-400: #4D8FC2;
  --color-data-ocean-500: #2563A0;
  --color-data-ocean-700: #193F68;
  --color-data-coral-100: #F6E6E4;
  --color-data-coral-300: #F2988C;
  --color-data-coral-400: #F66855;
  --color-data-coral-500: #FF5740;
  --color-data-coral-700: #B31D09;
  --color-data-terracotta-100: #F0DCD4;
  --color-data-terracotta-300: #D9A48E;
  --color-data-terracotta-400: #CF8568;
  --color-data-terracotta-500: #C2674A;
  --color-data-terracotta-700: #7A3D2C;
  --color-data-yellow-100: #F6F2E4;
  --color-data-yellow-300: #F2DC8D;
  --color-data-yellow-400: #F5D356;
  --color-data-yellow-500: #FED12E;
  --color-data-yellow-700: #9F7F09;
  --color-data-honey-100: #F5EACE;
  --color-data-honey-300: #E8C563;
  --color-data-honey-400: #DCA930;
  --color-data-honey-500: #D4940B;
  --color-data-honey-700: #805A06;
  --color-data-sage-100: #D4E8DA;
  --color-data-sage-300: #9ACBAA;
  --color-data-sage-400: #74B589;
  --color-data-sage-500: #5A9A6E;
  --color-data-sage-700: #376043;
  --color-data-dusk-100: #E4DFF0;
  --color-data-dusk-300: #B5A8CF;
  --color-data-dusk-400: #9788B8;
  --color-data-dusk-500: #7C6B9E;
  --color-data-dusk-700: #4D4263;
  --color-data-stone-100: #EBEDEF;
  --color-data-stone-300: #B3BBCC;
  --color-data-stone-400: #8F9EBC;
  --color-data-stone-500: #6B7280;
  --color-data-stone-700: #41454E;
}

/* Global reset */
*, *::before, *::after { box-sizing: border-box; }
body {
  @apply font-manrope antialiased bg-[#F7F7F8] text-[#1C1C1C];
  line-height: 1.5;
  min-height: 100vh;
}
```

### EntitySwitcher Tailwind Pattern (from 96-UI-SPEC.md)

```tsx
/* Replacing EntitySwitcher.css with Tailwind utility classes */

// Button
<button className="flex items-center gap-2 min-h-[44px] px-4 py-2 bg-white border border-[#E2EBEF] rounded-lg font-manrope text-base font-medium text-[#1C1C1C] cursor-pointer transition-colors duration-200 hover:bg-[#F7F7F8] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ev-muted-blue focus-visible:ring-offset-2">

// Dropdown
<div className="absolute top-full mt-1 left-0 min-w-56 bg-white border border-[#E2EBEF] rounded-lg shadow-lg z-10 overflow-hidden">

// Group label
<span className="block px-4 py-2 text-xs font-bold uppercase tracking-wider text-[#6B7280]">

// Option (selected)
<button className="block w-full px-4 py-3 text-sm text-left border-l-2 border-ev-muted-blue bg-[#F7F7F8] hover:bg-[#F7F7F8]">

// Option (default)
<button className="block w-full px-4 py-3 text-sm text-left border-l-2 border-transparent hover:bg-[#F7F7F8]">
```

### D3 Chart Color Assignment

```typescript
/* Replacing category.color reads with CSS custom property cycling */

const DATA_VIZ_HUES = [
  'teal', 'skyblue', 'ocean', 'coral', 'terracotta',
  'yellow', 'honey', 'sage', 'dusk', 'stone'
] as const;

function getCategoryColor(index: number, shade: '100' | '300' | '400' | '500' | '700' = '500'): string {
  const hue = DATA_VIZ_HUES[index % DATA_VIZ_HUES.length];
  return `var(--color-data-${hue}-${shade})`;
}

// Usage in D3 (BudgetSunburst.tsx):
// BEFORE: .attr('fill', d => d.data.color || '#ccc')
// AFTER:  .attr('fill', (d, i) => getCategoryColor(d.data.sortOrder || i))

// Usage in React (BudgetIcicle.tsx):
// BEFORE: backgroundColor: segment.category.color
// AFTER:  backgroundColor: getCategoryColor(segment.index)
```

---

## Component Inventory

### CSS Files to REMOVE (10 files)

| File | Styles Migrate To |
|------|------------------|
| `App.css` | Inline Tailwind classes on each component |
| `EntitySwitcher.css` | `EntitySwitcher.tsx` Tailwind classes |
| `LineItemsTable.css` | `LineItemsTable.tsx` Tailwind classes |
| `LinkedTransactionsPanel.css` | `LinkedTransactionsPanel.tsx` Tailwind classes |
| `TransactionLineItemsTable.css` | `TransactionLineItemsTable.tsx` Tailwind classes |
| `BudgetVisualization.css` | `BudgetVisualization.tsx` Tailwind classes |
| `SearchBar.css` (via App.css) | Inline on SearchBar |
| `CategoryList.css` (via App.css) | Inline on CategoryList |
| `YearSelector.css` (via App.css) | Inline on YearSelector |
| `Breadcrumb.css` (via App.css) | Inline on Breadcrumb |

### CSS Files to KEEP and UPDATE (3 files)

| File | What Changes |
|------|-------------|
| `BudgetIcicle.css` | Update `--data-*` var references to new `--color-data-*` tokens |
| `BudgetSunburst.css` | Update `--data-*` var references to new `--color-data-*` tokens |
| `BudgetTree.css` | Update `--data-*` var references to new `--color-data-*` tokens |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tailwind.config.js` theme extension | CSS `@theme {}` block in index.css | Tailwind CSS v4 (2025) | No config file needed; all token customization in CSS |
| `presets: [require(...)]` in config | `@import "..."` in CSS | Tailwind CSS v4 | Preset loading is now a CSS import |
| Single PostCSS approach | Vite plugin OR PostCSS | Tailwind CSS v4 | `@tailwindcss/vite` available as lighter alternative |
| Direct hex color on D3 fills | CSS custom property via `var()` | Best practice | Chart colors stay in sync with design system; single source of truth |

---

## Open Questions

1. **SiteHeader usage in App.tsx**
   - What we know: `import { SiteHeader } from '@chrisandrewsedu/ev-ui'` appears on line 2 of App.tsx
   - What's unclear: Whether SiteHeader is rendered in JSX (it may be unused after phase 95 work) or whether the ev-ui 0.1.53 API changed its props
   - Recommendation: Planner should include a task to audit the SiteHeader import and either remove it or verify compatibility

2. **ev-ui tailwind-preset as CSS @import**
   - What we know: The preset is a `.js` file, not a `.css` file. CompassV2 and essentials define tokens inline in `@theme` rather than importing the preset.
   - What's unclear: Whether Tailwind CSS 4's CSS-first mode can actually resolve `@import "@chrisandrewsedu/ev-ui/tailwind-preset"` at build time via Vite.
   - Recommendation: Define all tokens inline in `@theme {}` block (matching essentials/CompassV2 pattern). Do not rely on the CSS `@import` path for the preset. The preset is a JS-format artifact — useful for v3 config, but in v4 you hand-declare `@theme` values.

---

## Environment Availability

Step 2.6: No external tool dependencies beyond npm packages. All required packages (`tailwindcss`, `@tailwindcss/vite`, `@chrisandrewsedu/ev-ui`) install from npm. No external services, databases, or CLIs required for this phase beyond the existing development toolchain.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js / npm | Package install | Yes | (system) | — |
| @chrisandrewsedu/ev-ui 0.1.53 | VIS-02, token system | Yes (on npm registry) | 0.1.53 | — |
| tailwindcss v4 | VIS-01 | Not yet in treasury-tracker | 4.1.12 | — |
| @tailwindcss/vite | VIS-01 | Not yet in treasury-tracker | 4.1.10 | @tailwindcss/postcss |

---

## Validation Architecture

`workflow.nyquist_validation` is not set to false in `.planning/config.json` — section included.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None detected — no test config files or test directories found in treasury-tracker |
| Config file | None |
| Quick run command | `npm run build` (TypeScript compile + Vite build as smoke test) |
| Full suite command | `npm run build` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIS-01 | Tailwind CSS 4 installed; build succeeds with Tailwind classes | smoke | `cd treasury-tracker && npm run build` | N/A (build test) |
| VIS-02 | ev-ui 0.1.53 resolves; no import errors | smoke | `cd treasury-tracker && npm run build` | N/A (build test) |
| VIS-03 | UI chrome uses ev-* classes; no old CSS var references remain | manual-only | `grep -r "var(--coral)\|var(--muted-blue)\|var(--light-gray)" src/` | N/A |
| VIS-04 | Chart fills reference `--color-data-*`; no `category.color` in D3 fill logic | manual-only | `grep -rn "category\.color\|\.data\.color" src/components/` | N/A |
| VIS-05 | Manrope font renders; `font-manrope` class applied to body | smoke | `cd treasury-tracker && npm run build` | N/A (build test) |

### Sampling Rate

- **Per task commit:** `cd treasury-tracker && npm run build` — catches TypeScript errors and missing imports immediately
- **Per wave merge:** `cd treasury-tracker && npm run build && npm run dev` — visual verification in browser
- **Phase gate:** Build green + manual visual verification before `/gsd:verify-work`

### Wave 0 Gaps

No unit test framework exists in treasury-tracker. This is a visual/CSS phase — unit tests are not appropriate. The build command serves as the automated gate. Manual visual inspection is the verification method for design quality.

*(No test infrastructure to create — existing build system is sufficient for this phase)*

---

## Project Constraints (from CLAUDE.md)

| Directive | Constraint |
|-----------|-----------|
| GitHub account | Always use `chrisandrewsedu` for all git operations |
| No secrets in commits | `.env.local` never committed; verify before each commit |
| Multi-project workspace | Changes scoped to `treasury-tracker/` only; do not touch other app directories |
| npm registry | `@chrisandrewsedu/ev-ui` fetches from GitHub Packages — `.npmrc` must stay intact with `NPM_TOKEN` env var reference |
| Design system | Colors: ev-coral (#ff5740), ev-muted-blue (#00657c), ev-yellow (#fed12e); Font: Manrope |
| Tailwind CSS 4 | CSS-first config (`@import "tailwindcss"` + `@theme {}` block); no tailwind.config.js |

---

## Sources

### Primary (HIGH confidence)

- `ev-ui/src/tokens.js` — All design tokens verified: colors, colorScales, dataVizPalette (10 hues × 5 shades), fonts, spacing, shadows, duration, easing
- `ev-ui/src/tailwind-preset.js` — Tailwind theme extension structure, color naming convention (`ev-*` prefix), animation definitions
- `ev-ui/package.json` — Confirmed version 0.1.53, export paths for `./tokens` and `./tailwind-preset`
- `essentials/src/index.css` — Verified Tailwind CSS 4 integration pattern with `@import "tailwindcss"` + `@theme {}` block + PostCSS approach
- `CompassV2/src/index.css` — Verified Tailwind CSS 4 minimal `@theme {}` pattern
- `CompassV2/vite.config.js` — Verified `@tailwindcss/vite` Vite plugin approach
- `essentials/postcss.config.js` — Verified `@tailwindcss/postcss` PostCSS approach
- `treasury-tracker/src/index.css` — Current CSS vars confirmed (6-hue data palette to be replaced)
- `treasury-tracker/src/App.css` — Current styles confirmed (all to be removed)
- `treasury-tracker/package.json` — Current deps confirmed (ev-ui ^0.1.6, no tailwindcss)
- `treasury-tracker/src/components/` — All 23 components inventoried; 10 companion CSS files identified
- `treasury-tracker/src/types/budget.ts` — BudgetCategory `color: string` field confirmed
- `EV-Backend/internal/treasury/models.go` — `Color string` field confirmed in BudgetCategory model
- `.planning/phases/96-visual-refresh/96-UI-SPEC.md` — Complete visual contract verified; all component specs, color assignments, interaction patterns documented

### Secondary (MEDIUM confidence)

- npm registry: `@chrisandrewsedu/ev-ui` version 0.1.53 confirmed via `npm view` command
- `essentials/package.json` + `CompassV2/package.json` — Tailwind CSS 4 package versions cross-referenced (tailwindcss ^4.1.12, @tailwindcss/vite ^4.1.10, @tailwindcss/postcss available)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from live package.json files and npm registry
- Architecture patterns: HIGH — verified from existing EV apps using same Tailwind CSS 4 stack
- Pitfalls: HIGH — identified from direct code inspection of treasury-tracker source, not speculation
- Component inventory: HIGH — verified by listing actual files in treasury-tracker/src/components/

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (30 days — stable Tailwind CSS 4 + ev-ui design system)
