---
phase: 51
plan: 01
subsystem: CompassV2
tags: [compare, politician-picker, hook, component, keyboard-nav]
dependency_graph:
  requires: []
  provides: [usePoliticianList, InlinePoliticianPicker]
  affects: [CompareModal, ComparePanel]
tech_stack:
  added: []
  patterns: [module-level-cache, shared-hook, controlled-dropdown]
key_files:
  created:
    - CompassV2/src/hooks/usePoliticianList.js
    - CompassV2/src/components/InlinePoliticianPicker.jsx
  modified:
    - CompassV2/src/components/CompareModal.jsx
decisions:
  - Module-level cache (cachedList + pendingPromise) chosen over React Context to keep hook self-contained and avoid Provider wrapping
  - InlinePoliticianPicker manages its own open/close state locally (no lift-up needed) because only one instance ever renders at a time
metrics:
  duration: "~2 minutes"
  completed: "2026-02-28"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 51 Plan 01: Shared Politician List & InlinePoliticianPicker Component Summary

**One-liner:** Extracted politician list fetch into a module-cached shared hook; built a full-featured inline dropdown picker with keyboard nav, search, clear, and browse-all actions.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| A1 | Create usePoliticianList shared hook | ae66d75 | `src/hooks/usePoliticianList.js`, `src/components/CompareModal.jsx` |
| A2 | Build InlinePoliticianPicker component | 6db66fc | `src/components/InlinePoliticianPicker.jsx` |

## What Was Built

### usePoliticianList hook (`CompassV2/src/hooks/usePoliticianList.js`)
- Module-level `cachedList` and `pendingPromise` variables ensure the `/compass/politicians` API call happens exactly once across all React component instances
- Returns `{ politicians, loading }` — same interface both CompareModal and InlinePoliticianPicker consume
- If cache is already populated when hook mounts, it skips `useEffect` and sets state synchronously (no flicker)

### CompareModal update (`CompassV2/src/components/CompareModal.jsx`)
- Removed local `useState([])` + `useEffect` fetch (12 lines)
- Replaced with single `const { politicians } = usePoliticianList();`
- PoliticianPicker internal component unchanged — still receives same `politicians` array

### InlinePoliticianPicker component (`CompassV2/src/components/InlinePoliticianPicker.jsx`)
- **Collapsed trigger:** photo (size-16 rounded-full with ring), name (font-bold), office title (neutral-500), animated chevron (rotates 180 on open)
- **Dropdown:** search input with focus-on-open, "Clear comparison" row (X icon), "Browse all politicians" row (link icon), scrollable politician list (max-h-64)
- **Currently selected** politician highlighted: `bg-[#59b0c4]/10` tint + checkmark icon
- **Keyboard navigation:** ArrowUp/Down moves highlight and calls `ensureVisible()`, Enter selects, Escape closes
- **Click-outside:** document `mousedown` listener on container ref, cleaned up on unmount
- **Photo fallback chain:** `photo_origin_url || photo_custom_url || placeholder`

## Verification

```
MUST_HAVE:
- [x] usePoliticianList hook exists and caches the fetch (module-level)
- [x] CompareModal uses usePoliticianList (no local fetch)
- [x] InlinePoliticianPicker renders collapsed trigger with photo + name + chevron
- [x] InlinePoliticianPicker dropdown shows search input + "Clear comparison" + politician list
- [x] Keyboard navigation works (arrow keys, Enter, Escape)
- [x] Click-outside closes the dropdown
- [x] "Clear comparison" option calls onClear callback
- [x] "Browse all" / expand button calls onOpenFullModal callback

MUST_NOT:
- [x] Does not break existing CompareModal functionality
- [x] Does not duplicate the API fetch (shared hook handles caching)
- [x] Does not introduce any new npm dependencies
```

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **Module-level cache pattern** — Used `let cachedList = null; let pendingPromise = null;` at module scope rather than React Context or Zustand. Self-contained, no Provider setup required, works identically in both CompareModal and InlinePoliticianPicker.

2. **Local open/close state in InlinePoliticianPicker** — The component manages its own dropdown state internally. Since only one instance renders at a time in the UI, no lift-up or Context needed.

## Self-Check: PASSED

Files created:
- FOUND: CompassV2/src/hooks/usePoliticianList.js
- FOUND: CompassV2/src/components/InlinePoliticianPicker.jsx

Files modified:
- FOUND: CompassV2/src/components/CompareModal.jsx (uses usePoliticianList, no local fetch)

Commits:
- FOUND: ae66d75 (feat(51-01): create usePoliticianList shared hook)
- FOUND: 6db66fc (feat(51-01): build InlinePoliticianPicker component)
