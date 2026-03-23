---
phase: 95-entity-switcher
plan: "02"
subsystem: ui
tags: [react, typescript, entity-switcher, url-sync, dropdown, spinner, aria]

requires:
  - phase: 95-01
    provides: Municipality interface with available_datasets metadata, listMunicipalities() API call, state-aware cache key
provides:
  - EntitySwitcher dropdown component (grouped by entity_type, ARIA-complete)
  - Entity-driven App.tsx with URL deep linking (pushState)
  - Dynamic hero card (title + background from selectedEntity)
  - Spinner overlay during entity switch (header stays interactive)
  - DatasetTabs disabled state for unavailable dataset types per entity
affects: [treasury-tracker, entity-switcher-verification]

tech-stack:
  added: []
  patterns:
    - "Entity state as single source of truth in App.tsx (selectedEntity → hero, breadcrumbs, year list, dataset tabs, URL)"
    - "Pitfall 1 avoidance: compute effective year before setState in handleEntityChange, never via useEffect chain"
    - "Pitfall 2 avoidance: URL sync guarded by if (!selectedEntity) return — no pushState on mount"
    - "Disabled tab state: pointerEvents=none + aria-disabled + title tooltip (defense in depth)"

key-files:
  created:
    - treasury-tracker/src/components/EntitySwitcher.tsx
    - treasury-tracker/src/components/EntitySwitcher.css
  modified:
    - treasury-tracker/src/App.tsx
    - treasury-tracker/src/App.css
    - treasury-tracker/src/components/datasets/DatasetTabs.tsx
  deleted:
    - treasury-tracker/src/components/NavigationTabs.tsx

key-decisions:
  - "Entity state initialized from URL on mount — municipality load, entity resolution, and URL sync happen in a single useEffect to avoid race conditions"
  - "handleEntityChange computes effectiveYear before setSelectedEntity to prevent double-fetch (Pitfall 1)"
  - "URL sync guarded: if (!selectedEntity) return — prevents overwriting valid URL params before municipalities load (Pitfall 2)"
  - "info-card Context section conditionally rendered: selectedEntity.population > 0 AND operatingBudgetData present (D-06)"
  - "EntitySwitcher renders Townships group if any exist — future-proof for entity_type expansion"

requirements-completed: [UI-01, UI-02, UI-03]

duration: ~15min
completed: 2026-03-23
---

# Phase 95 Plan 02: EntitySwitcher and App Rewire Summary

**EntitySwitcher dropdown with entity-grouped municipalities replaces NavigationTabs; App.tsx fully rewired with URL deep linking, dynamic hero, spinner overlay, and per-entity disabled dataset tabs.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-23
- **Completed:** 2026-03-23
- **Tasks:** 3 of 3 (Task 3 = human-verify checkpoint — approved)
- **Files modified:** 5 (2 created, 1 deleted, 3 modified)

## Accomplishments

- EntitySwitcher component created following YearSelector dropdown pattern — groups Cities/Counties by entity_type with ARIA listbox semantics and Escape/click-outside dismiss
- App.tsx rewired: selectedEntity drives hero title, hero background, breadcrumb label, available year list, available dataset types, and all loadBudgetData() calls
- URL deep linking via native URLSearchParams + pushState — `?entity=bloomington-in&year=2025&dataset=operating` — with Pitfall 1 and Pitfall 2 guards
- Spinner overlay on `.main-content-wrapper` (header stays interactive during entity switch per D-07)
- DatasetTabs: `availableDatasets` prop added; tabs disabled via opacity + pointer-events + aria-disabled + title tooltip (D-09)
- NavigationTabs.tsx deleted (replaced by EntitySwitcher)

## Task Commits

1. **Task 1: Create EntitySwitcher component with CSS** — `018a0f1` (feat)
2. **Task 2: Rewire App.tsx** — `938a885` (feat)
3. **Task 3: Visual verification** — approved by user
4. **Post-verification fix** — `470de71` (fix: guard dataset totals loading)

## Files Created/Modified

- `treasury-tracker/src/components/EntitySwitcher.tsx` — Dropdown grouped by entity_type, ARIA-complete, click-outside + Escape dismiss
- `treasury-tracker/src/components/EntitySwitcher.css` — entity-switcher-button (44px min-height), entity-group-label, entity-option, selected state
- `treasury-tracker/src/App.tsx` — Full rewire: entity state, URL sync, dynamic hero, spinner overlay, disabled tabs, no hardcoded Bloomington
- `treasury-tracker/src/App.css` — Added .main-content-wrapper, .content-loading-overlay, .spinner, @keyframes spin
- `treasury-tracker/src/components/datasets/DatasetTabs.tsx` — Added availableDatasets prop, disabled state on desktop + mobile tabs

## Decisions Made

- Entity state initialized from URL on mount in a single useEffect (municipality load + entity resolution + URL sync) to avoid race conditions
- `handleEntityChange` computes `effectiveYear` before calling `setSelectedEntity` — prevents Pitfall 1 (double-fetch flash)
- URL sync useEffect guarded with `if (!selectedEntity) return` — prevents Pitfall 2 (overwriting incoming URL params on mount)
- Context info card conditionally rendered based on `selectedEntity.population > 0 && operatingBudgetData` — no "N/A" shown per UI-SPEC
- EntitySwitcher also renders a "Townships" group if any township entities exist — future-proof for entity_type expansion
- Revenue description changed from "where city revenue comes from" to "where funds come from" (entity-neutral)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Error state uses entity-specific message per UI-SPEC**
- **Found during:** Task 2 (App.tsx rewire, C11 step)
- **Issue:** Plan's error state copy said "Unable to load data" but UI-SPEC copywriting contract specifies "Couldn't load {Entity Name} data. Check your connection and try again."
- **Fix:** Updated error state to use `selectedEntity.name` in the message
- **Files modified:** treasury-tracker/src/App.tsx
- **Committed in:** 938a885 (Task 2 commit)

**2. [Rule 2 - Missing Critical] `operatingBudgetData` null guard in info card**
- **Found during:** Task 2 (C13 step for info card)
- **Issue:** Plan wrapped Context div in `selectedEntity.population > 0` but didn't guard operatingBudgetData null access for the budget total display
- **Fix:** Guard `operatingBudgetData?.metadata.fiscalYear` and `operatingBudgetData?.metadata.totalBudget` to render `—` when null; also require both conditions for Context section
- **Files modified:** treasury-tracker/src/App.tsx
- **Committed in:** 938a885 (Task 2 commit)

**3. [Rule 1 - Bug] `loading || !operatingBudgetData` full-page block removed**
- **Found during:** Task 2 (C11 step)
- **Issue:** Original plan's loading guard was `if (loading || !operatingBudgetData)` which blocks the spinner overlay pattern — the spinner overlay requires rendering the main DOM structure, not an early return
- **Fix:** Changed to `if (!selectedEntity)` for initial load only, with a separate `if (!loading && !budgetData)` for error state; budget section wrapped in `{budgetData && (...)}`
- **Files modified:** treasury-tracker/src/App.tsx
- **Committed in:** 938a885 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 missing critical, 1 bug)
**Impact on plan:** All auto-fixes necessary for correctness and UI-SPEC compliance. No scope creep.

## Issues Encountered

- Worktree was at commit `4ed8d00` (pre-Plan 01) while main was at `fa6ce50` (Plan 01 complete). Merged main into the worktree branch before starting — fast-forward merge, no conflicts.
- Bloomington was not in the database — imported via `import-budgets --source=bloomington` CLI (15 budgets: operating/revenue/salaries x 2021-2025)
- Revenue loading threw errors for entities without revenue data — fixed by guarding with available_datasets check (`470de71`)

## Known Stubs

None — EntitySwitcher renders live API data from listMunicipalities(). The hero_image_url null fallback is intentional (documented in RESEARCH.md Pitfall 4 — photos not yet populated). The fallback URL is the Bloomington courthouse image, which is a valid image not a broken placeholder.

## Next Phase Readiness

- Phase 95 complete — entity switching verified by user
- TypeScript compiles clean
- Hero images pending (user will add later) — fallback image works
- Population data is 0 for non-Bloomington entities (context card hidden when population=0)

## Self-Check: PASSED
