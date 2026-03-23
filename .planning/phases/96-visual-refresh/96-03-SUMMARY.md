---
phase: 96-visual-refresh
plan: 03
subsystem: treasury-tracker
tags: [d3-charts, data-viz, color-palette, design-tokens]
dependency_graph:
  requires: [96-01]
  provides: [getCategoryColor utility, D3 chart color migration]
  affects: [BudgetSunburst, BudgetIcicle, BudgetTree]
tech_stack:
  added: [src/utils/chartColors.ts]
  patterns: [CSS custom property color cycling via getCategoryColor, categoryIndex propagation through data hierarchy]
key_files:
  created:
    - treasury-tracker/src/utils/chartColors.ts
  modified:
    - treasury-tracker/src/components/BudgetSunburst.tsx
    - treasury-tracker/src/components/BudgetSunburst.css
    - treasury-tracker/src/components/BudgetIcicle.tsx
    - treasury-tracker/src/components/BudgetTree.tsx
decisions:
  - getCategoryColor returns var(--color-data-{hue}-500) CSS custom property strings; SVG fill attribute natively resolves CSS vars
  - categoryIndex=-1 reserved for root Budget node in BudgetTree which uses --color-ev-muted-blue instead of data palette
  - Root category index propagated to all subcategory levels so sibling subcategories share the same hue as their parent
metrics:
  duration: ~5 minutes
  completed: 2026-03-23T15:35:00Z
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 6
---

# Phase 96 Plan 03: D3 Chart Color Migration Summary

Migrated all three D3 chart components from reading stored `category.color` hex fields to computing fills by category index using the canonical ev-ui dataVizPalette CSS custom properties.

## What Was Built

getCategoryColor utility that cycles through 10 data viz hues (teal, skyblue, ocean, coral, terracotta, yellow, honey, sage, dusk, stone) using CSS custom properties from the `--color-data-*` namespace defined in index.css. All three D3 chart components now import and use this utility.

## Tasks

### Task 1: Create shared getCategoryColor utility and migrate BudgetSunburst

**Commit:** 26b38ec

**Files:**
- `src/utils/chartColors.ts` — New utility with `getCategoryColor(index, shade)` and `getResolvedCategoryColor(index, shade)`
- `src/components/BudgetSunburst.tsx` — Added `categoryIndex` to `HierarchyNode`, propagated through `buildHierarchy` recursion, replaced `.attr('fill', d => d.data.color || '#ccc')` with `.attr('fill', d => getCategoryColor(d.data.categoryIndex ?? 0))`, center circle updated from `var(--muted-blue)` to `var(--color-ev-muted-blue)`
- `src/components/BudgetSunburst.css` — Focus outline updated from `var(--muted-blue)` to `var(--color-ev-muted-blue)`

### Task 2: Migrate BudgetIcicle and BudgetTree to data viz palette

**Commit:** 24cc651

**Files:**
- `src/components/BudgetIcicle.tsx` — Added `categoryIndex` to `BarSegment`, root-level segments get index `i`, subcategory segments inherit root category index via `rootIndexMap`, replaced `backgroundColor: segment.category.color` with `backgroundColor: getCategoryColor(segment.categoryIndex)`
- `src/components/BudgetTree.tsx` — Replaced `color: string` field in `TreeNode` with `categoryIndex: number`, root Budget node uses `categoryIndex: -1` (maps to `--color-ev-muted-blue`), child nodes at root level get their own index, child nodes at deeper levels inherit root index, `getNodeFill()` helper wraps the special-case logic, removed `getContrastColor` (no longer needed)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Stale CSS imports for deleted companion files**
- **Found during:** Task 1 — `npm run build` failed with "Could not resolve './LineItemsTable.css'"
- **Issue:** Plan 96-02 (parallel wave) deleted `LineItemsTable.css`, `LinkedTransactionsPanel.css`, `TransactionLineItemsTable.css` but the TSX imports were not removed
- **Fix:** Removed stale `import './LineItemsTable.css'`, `import './LinkedTransactionsPanel.css'`, `import './TransactionLineItemsTable.css'` from the respective components
- **Files modified:** `src/components/LineItemsTable.tsx`, `src/components/LinkedTransactionsPanel.tsx`, `src/components/TransactionLineItemsTable.tsx`
- **Commit:** 6321dfd

## Known Stubs

None. All chart fills are wired to live CSS custom properties via getCategoryColor.

## Verification Results

- `npm run build` exits 0
- `grep -rn "\.data\.color|category\.color" ... | grep -i "fill|background"` returns no results
- `grep -rn "data-navy|data-indigo|data-puce|data-cocoa|data-chestnut|data-olive" src/` returns no results
- All 3 D3 CSS companion files exist (BudgetIcicle.css, BudgetSunburst.css, BudgetTree.css)
- All 3 chart components import `getCategoryColor` from `../utils/chartColors`

## Self-Check: PASSED
