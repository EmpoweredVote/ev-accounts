---
phase: 96-visual-refresh
plan: 01
subsystem: ui
tags: [tailwindcss, react, vite, ev-ui, css-migration, design-tokens]

requires: []
provides:
  - Tailwind CSS 4 infrastructure in treasury-tracker with @tailwindcss/vite plugin
  - Full EV brand token @theme block with ev-coral, ev-muted-blue, ev-yellow, ev-light-blue
  - Complete 10-hue x 5-shade data visualization palette (--color-data-* namespace)
  - Navigation chrome (header, EntitySwitcher, DatasetTabs, SearchBar, YearSelector, Breadcrumb) fully redesigned with Tailwind + EV tokens
  - App.css and EntitySwitcher.css deleted; all styles converted to inline Tailwind utility classes
affects:
  - 96-02 (subsequent component conversions — LineItemsTable, BudgetVisualization, CategoryList)
  - 96-03 (D3 chart CSS updates to use --color-data-* namespace)

tech-stack:
  added:
    - tailwindcss ^4.2.2
    - "@tailwindcss/vite ^4.2.2"
    - "@chrisandrewsedu/ev-ui ^0.1.53 (upgraded from ^0.1.6)"
  patterns:
    - CSS-first Tailwind 4 config: @import tailwindcss + @theme block in index.css (no tailwind.config.js)
    - "@tailwindcss/vite plugin in vite.config.ts (matching CompassV2 pattern)"
    - EV brand tokens declared inline in @theme (not via @import of tailwind-preset.js)
    - Data viz colors in separate --color-data-* namespace to prevent brand token bleed into D3 charts
    - Font-manrope class via --font-manrope CSS custom property in @theme

key-files:
  created: []
  modified:
    - treasury-tracker/package.json (added tailwindcss, @tailwindcss/vite, upgraded ev-ui)
    - treasury-tracker/vite.config.ts (added @tailwindcss/vite plugin)
    - treasury-tracker/src/index.css (full rewrite: Tailwind import, Google Fonts, @theme with EV tokens + data viz palette)
    - treasury-tracker/src/App.tsx (removed CSS imports, converted all JSX to Tailwind classes)
    - treasury-tracker/src/components/EntitySwitcher.tsx (full Tailwind redesign: ring-ev-muted-blue, tracking-wider, border-ev-muted-blue)
    - treasury-tracker/src/components/datasets/DatasetTabs.tsx (Tailwind tabs: border-b-ev-muted-blue active, mobile card dropdown)
    - treasury-tracker/src/components/SearchBar.tsx (lucide Search/X icons, text-ev-coral clear button, aria-label="Clear search")
    - treasury-tracker/src/components/YearSelector.tsx (pill-style rounded-full, bg-ev-muted-blue active)
    - treasury-tracker/src/components/Breadcrumb.tsx (text-ev-muted-blue clickable crumbs)
  deleted:
    - treasury-tracker/src/App.css
    - treasury-tracker/src/components/EntitySwitcher.css

key-decisions:
  - "Define all EV tokens inline in @theme rather than @import of tailwind-preset.js (JS file, not CSS — cannot be CSS-imported in Tailwind v4)"
  - "Use @tailwindcss/vite plugin path (not @tailwindcss/postcss) matching CompassV2 pattern — simpler for Vite projects"
  - "Google Fonts @import wrapped with layer(base) to address lightningcss warning about @import ordering"
  - "SiteHeader import from ev-ui kept in App.tsx — it is actively rendered in JSX and works with 0.1.53"

patterns-established:
  - "Pattern: Tailwind CSS 4 in treasury-tracker uses @import tailwindcss + inline @theme block (no tailwind.config.js)"
  - "Pattern: EV tokens in @theme use --color-ev-* naming (e.g., --color-ev-coral, --color-ev-muted-blue)"
  - "Pattern: Data viz palette uses --color-data-{hue}-{shade} naming, separate from EV brand tokens"
  - "Pattern: Navigation chrome components use focus-visible:ring-2 focus-visible:ring-ev-muted-blue ring-offset-2 for keyboard accessibility"

requirements-completed: [VIS-01, VIS-02, VIS-05, VIS-03]

duration: 7min
completed: 2026-03-23
---

# Phase 96 Plan 01: Tailwind CSS 4 Infrastructure + Navigation Chrome Summary

**Tailwind CSS 4 installed via @tailwindcss/vite in treasury-tracker with full EV token @theme block, ev-ui upgraded to 0.1.53, and all navigation chrome components (App shell, EntitySwitcher, DatasetTabs, SearchBar, YearSelector, Breadcrumb) fully redesigned with Tailwind utility classes and EV design tokens.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-03-23T19:50:28Z
- **Completed:** 2026-03-23T19:57:35Z
- **Tasks:** 2/2
- **Files modified:** 9 (plus 2 deleted)

## Accomplishments

- Tailwind CSS 4 operational in treasury-tracker with @tailwindcss/vite Vite plugin and CSS-first config
- ev-ui upgraded from ^0.1.6 to ^0.1.53; SiteHeader continues to work correctly
- index.css fully rewritten: @import tailwindcss, Manrope font, full @theme block with EV brand tokens + 10-hue x 5-shade data viz palette
- App.css and EntitySwitcher.css deleted; zero legacy CSS companion files remain (except D3 chart companions)
- All 6 navigation/chrome components converted to Tailwind with EV design tokens and proper accessibility (focus rings, aria-labels)

## Task Commits

1. **Task 1: Install Tailwind CSS 4, upgrade ev-ui, rewrite index.css and vite.config.ts** - `4f89d40` (feat)
2. **Task 2: Delete App.css and convert App.tsx + navigation chrome components to Tailwind** - `af0d5e4` (feat)

## Files Created/Modified

- `treasury-tracker/package.json` - Added tailwindcss ^4.2.2, @tailwindcss/vite ^4.2.2, upgraded ev-ui to ^0.1.53
- `treasury-tracker/vite.config.ts` - Added @tailwindcss/vite plugin
- `treasury-tracker/src/index.css` - Full rewrite: @import tailwindcss, @theme block with all EV tokens and data viz palette, global reset
- `treasury-tracker/src/App.tsx` - Removed CSS imports, full Tailwind shell redesign (min-h-screen, bg-[#F7F7F8], header with shadow-sm)
- `treasury-tracker/src/components/EntitySwitcher.tsx` - Full Tailwind redesign with ring-ev-muted-blue, tracking-wider group labels, border-ev-muted-blue selected state
- `treasury-tracker/src/components/datasets/DatasetTabs.tsx` - Desktop tabs with border-b-ev-muted-blue active indicator; mobile card dropdown with rounded-xl
- `treasury-tracker/src/components/SearchBar.tsx` - Lucide Search/X icons, ev-muted-blue focus ring, ev-coral clear button with aria-label="Clear search"
- `treasury-tracker/src/components/YearSelector.tsx` - Pill-style buttons with rounded-full, bg-ev-muted-blue active state
- `treasury-tracker/src/components/Breadcrumb.tsx` - text-ev-muted-blue clickable crumbs, gray-500 separators
- `treasury-tracker/src/App.css` - DELETED
- `treasury-tracker/src/components/EntitySwitcher.css` - DELETED

## Decisions Made

- EV brand tokens defined inline in @theme block (not via CSS @import of tailwind-preset.js), because the preset is a JS file and cannot be resolved as a CSS @import in Tailwind CSS 4's build pipeline — matching CompassV2 and essentials actual pattern
- Used @tailwindcss/vite plugin (not @tailwindcss/postcss) — simpler for Vite projects with no PostCSS requirements beyond Tailwind
- Google Fonts @import uses `layer(base)` suffix to reduce lightningcss CSS optimizer warning about @import ordering (warning is non-blocking, build exits 0)
- SiteHeader from ev-ui kept in App.tsx — it is actively used in JSX for auth-aware header and works correctly with ev-ui 0.1.53

## Deviations from Plan

None — plan executed exactly as written. The RESEARCH.md Pitfall 1 (ev-ui tailwind-preset CSS @import) was anticipated and handled by defining tokens inline as specified.

## Issues Encountered

- lightningcss optimizer warning: "@import rules must precede all rules" for Google Fonts URL import after @tailwindcss. This is a known Tailwind CSS 4 limitation (the tailwindcss import must come first). Added `layer(base)` to the Google Fonts import to reduce the warning. Build exits 0 with only a warning, not an error.

## Known Stubs

None — this plan is infrastructure/CSS only. No data stubs introduced.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Tailwind CSS 4 foundation is operational; all subsequent component conversions (Phase 96, Plans 02+) can use Tailwind utility classes and the full EV token set
- The --color-data-* custom properties are now defined in @theme and accessible to D3 charts via CSS var() calls
- Ready for Plan 02: LineItemsTable, BudgetVisualization, CategoryList, and PerDollarBreakdown conversion
- No blockers

---
*Phase: 96-visual-refresh*
*Completed: 2026-03-23*
