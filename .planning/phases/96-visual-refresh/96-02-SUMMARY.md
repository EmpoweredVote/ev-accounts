---
phase: 96-visual-refresh
plan: 02
subsystem: ui
tags: [tailwind, css-migration, react, treasury-tracker, design-system, ev-tokens]

requires:
  - phase: 96-01
    provides: Tailwind CSS 4 integration, EV token @theme block in index.css, companion CSS deletion pattern

provides:
  - All non-D3 data display components converted from CSS to Tailwind with EV design tokens
  - LineItemsTable: ev-muted-blue header icon and total row, text-red-700 over-budget variance, tabular-nums
  - LinkedTransactionsPanel: rounded-xl card surface, ev-muted-blue icon, stat grid, transaction list
  - TransactionLineItemsTable: summary cards with ev-muted-blue amounts, full Tailwind table
  - CategoryList: rounded-xl card grid with hover:shadow-md, data viz palette by index
  - CategoryDetail: EV card surface, font-bold font-manrope headings, data viz legend by index
  - BudgetVisualization: ev-muted-blue active toggle, no companion CSS file
  - BudgetBar: h-3 rounded-full segmented bar using var(--color-data-{hue}-500)
  - PerDollarBreakdown: tabular-nums amounts, ev-muted-blue denomination selector
  - BudgetSunburst.css/BudgetTree.css: old CSS vars replaced with EV hex values

affects: [96-03, treasury-tracker components, visual-refresh phase]

tech-stack:
  added: []
  patterns:
    - "DATA_VIZ_HUES constant from chartColors.ts used for index-based color cycling in non-D3 components"
    - "var(--color-data-{hue}-500) CSS custom property pattern for bar/dot fills in CategoryList, BudgetBar, PerDollarBreakdown"
    - "EV card pattern: bg-white border border-[#E2EBEF] rounded-xl overflow-hidden"
    - "Header section pattern: flex items-start gap-4 px-6 py-4 bg-[#F7F7F8] border-b border-[#D3D7DE] with w-10 h-10 bg-ev-muted-blue icon"
    - "Table pattern: sticky thead with bg-[#F7F7F8], border-[#E2EBEF] row dividers, hover:bg-[#F7F7F8]"
    - "Variance colors: text-[#059669] under-budget, text-[#6B7280] on-budget, text-red-700 over-budget"

key-files:
  created: []
  modified:
    - treasury-tracker/src/components/LineItemsTable.tsx
    - treasury-tracker/src/components/LinkedTransactionsPanel.tsx
    - treasury-tracker/src/components/TransactionLineItemsTable.tsx
    - treasury-tracker/src/components/CategoryList.tsx
    - treasury-tracker/src/components/CategoryDetail.tsx
    - treasury-tracker/src/components/BudgetVisualization.tsx
    - treasury-tracker/src/components/BudgetBar.tsx
    - treasury-tracker/src/components/PerDollarBreakdown.tsx
    - treasury-tracker/src/components/BudgetSunburst.css
    - treasury-tracker/src/components/BudgetTree.css

key-decisions:
  - "DATA_VIZ_HUES from chartColors.ts used in CategoryList, BudgetBar, PerDollarBreakdown for index-based color assignment — not category.color"
  - "BudgetSunburst.css/BudgetTree.css old CSS vars fixed inline (Rule 1) since they would break at runtime with no --black/--text-gray/--white definitions"

patterns-established:
  - "Non-D3 color swatches use DATA_VIZ_HUES[index % 10] with var(--color-data-{hue}-500) CSS custom properties"
  - "stat/summary card pattern: bg-[#F7F7F8] rounded-lg p-4 border border-[#E2EBEF] with xs uppercase tracking-wider label"

requirements-completed: [VIS-03]

duration: 15min
completed: 2026-03-23
---

# Phase 96 Plan 02: Data Display Components Redesign Summary

**All non-D3 data display components converted from CSS companion files to Tailwind utility classes with EV design tokens; categorical color swatches use the data viz palette by index position.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-23T15:20:00Z
- **Completed:** 2026-03-23T15:34:32Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Deleted 4 companion CSS files: LineItemsTable.css, LinkedTransactionsPanel.css, TransactionLineItemsTable.css, BudgetVisualization.css
- Full Tailwind redesign of 8 components using EV card surfaces, ev-muted-blue accents, and EV typography tokens
- CategoryList, BudgetBar, and PerDollarBreakdown now use `DATA_VIZ_HUES[index % 10]` with CSS custom properties instead of `category.color` stored values
- Fixed old CSS vars (`var(--black)`, `var(--text-gray)`, `var(--white)`, `var(--muted-blue)`) in D3 companion CSS files that would break at runtime

## Task Commits

Task 1 was committed by the parallel plan 03 agent (which ran concurrently):

1. **Task 1a: LineItemsTable full redesign** - `6321dfd` (fix 96-03: remove stale CSS imports — included full Tailwind redesign)
2. **Task 1b: LinkedTransactionsPanel + TransactionLineItemsTable** - `24cc651` (feat 96-03: BudgetIcicle/BudgetTree — included Tailwind conversion labeled as linter companion work)
3. **Task 2: CategoryList, CategoryDetail, BudgetVisualization, BudgetBar, PerDollarBreakdown** - `c6f5a9d` (feat 96-02)

## Files Created/Modified

- `treasury-tracker/src/components/LineItemsTable.tsx` - Redesigned: ev-muted-blue header icon, text-ev-muted-blue total row, text-red-700/[#059669] variance, tabular-nums, py-3 data density
- `treasury-tracker/src/components/LinkedTransactionsPanel.tsx` - Redesigned: rounded-xl card, stat grid, ev-muted-blue icon, border-l-2 border-ev-muted-blue transaction items
- `treasury-tracker/src/components/TransactionLineItemsTable.tsx` - Redesigned: summary cards with ev-muted-blue values, full Tailwind table matching LineItemsTable pattern
- `treasury-tracker/src/components/CategoryList.tsx` - Redesigned: grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3, rounded-xl cards, hover:shadow-md, DATA_VIZ_HUES by index
- `treasury-tracker/src/components/CategoryDetail.tsx` - Redesigned: EV card surfaces, font-bold font-manrope headings, 30px display amounts, data viz legend by index
- `treasury-tracker/src/components/BudgetVisualization.tsx` - Redesigned: ev-muted-blue active toggle button, border-[#E2EBEF] inactive, no CSS companion file
- `treasury-tracker/src/components/BudgetBar.tsx` - Redesigned: w-full h-3 bg-[#EBEDEF] rounded-full, DATA_VIZ_HUES[index] fill via CSS vars
- `treasury-tracker/src/components/PerDollarBreakdown.tsx` - Redesigned: EV card surface, ev-muted-blue denomination selector, tabular-nums, DATA_VIZ_HUES by index
- `treasury-tracker/src/components/BudgetSunburst.css` - Fixed old CSS vars replaced with EV hex values
- `treasury-tracker/src/components/BudgetTree.css` - Fixed var(--white) → #FFFFFF

## Decisions Made

- DATA_VIZ_HUES from chartColors.ts used in non-D3 components for index-based color assignment — maintains visual consistency with D3 charts without storing category.color
- BudgetSunburst.css/BudgetTree.css old CSS vars fixed inline since those vars are no longer defined in index.css after plan 01 migration

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed old CSS vars in BudgetSunburst.css breaking at runtime**
- **Found during:** Overall verification check
- **Issue:** BudgetSunburst.css still used `var(--black)`, `var(--text-gray)`, `var(--light-gray)`, `var(--white)`, `var(--muted-blue)` — these vars are no longer defined after plan 01 removed the old CSS variable block from index.css
- **Fix:** Replaced with EV hex values: `#1C1C1C`, `#6B7280`, `#F7F7F8`, `#FFFFFF`, `var(--color-ev-muted-blue)`
- **Files modified:** treasury-tracker/src/components/BudgetSunburst.css
- **Verification:** `grep -rn "var(--black)\|var(--text-gray)\|var(--white)\|var(--light-gray)\|var(--muted-blue)"` returns no results
- **Committed in:** c6f5a9d (Task 2 commit)

**2. [Rule 3 - Blocking] Fixed var(--white) in BudgetTree.css**
- **Found during:** Overall verification check
- **Issue:** BudgetTree.css tooltip had `color: var(--white)` — undefined after plan 01 migration
- **Fix:** Replaced with `color: #FFFFFF`
- **Files modified:** treasury-tracker/src/components/BudgetTree.css
- **Committed in:** c6f5a9d (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 blocking — undefined CSS vars that would cause invisible text at runtime)
**Impact on plan:** Both fixes were correctness requirements — old vars break visual rendering. No scope creep.

## Issues Encountered

- Task 1 components (LineItemsTable, LinkedTransactionsPanel, TransactionLineItemsTable) were committed by the parallel plan 03 agent as companion work. Verified all acceptance criteria still met.
- `getCategoryColor` import in BudgetSunburst.tsx erroneously reported as unused by TypeScript in initial build check — actual usage confirmed at line 279, build passed without modification.

## Next Phase Readiness

- All non-D3 components use EV design tokens with no companion CSS files
- Plan 03 (D3 chart CSS migration) can proceed — data viz palette already aligned
- Final overall verification: only BudgetIcicle.css, BudgetSunburst.css, BudgetTree.css remain as CSS companion files (D3 only)

---
*Phase: 96-visual-refresh*
*Completed: 2026-03-23*
