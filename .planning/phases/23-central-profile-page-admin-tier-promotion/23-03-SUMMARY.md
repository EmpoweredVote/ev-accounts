---
phase: 23-central-profile-page-admin-tier-promotion
plan: 03
subsystem: ui
tags: [react, typescript, admin, search-dropdown, promotions, pagination]

# Dependency graph
requires:
  - phase: 23-01
    provides: POST /api/admin/accounts/:userId/promote, GET /api/admin/promotions backend endpoints and tier_promotion_log table

provides:
  - Search-as-you-type dropdown on AccountsPage fetching inline results from /api/admin/accounts
  - PromotionsPage component rendering paginated global promotion audit log at /admin/promotions
  - Promotions nav item in AdminLayout sidebar
  - /admin/promotions route registered in App.tsx

affects: [future admin UI phases consuming promotion audit data]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "useRef blur timer: onMouseDown on dropdown items prevents blur-before-click race condition; 150ms setTimeout clears on focus"
    - "Dual fetch pattern: main table and dropdown use separate apiFetch calls triggered by same debouncedSearch value"

key-files:
  created:
    - admin/src/pages/admin/PromotionsPage.tsx
  modified:
    - admin/src/pages/admin/AccountsPage.tsx
    - admin/src/pages/admin/AdminLayout.tsx
    - admin/src/App.tsx

key-decisions:
  - "onMouseDown (not onClick) on dropdown items prevents blur handler firing before the click event registers"
  - "Dropdown fetches independently from main table — both share debouncedSearch but are separate state, keeping table behavior unchanged"
  - "searchResults capped at 8 via .slice(0, 8) before setState"

patterns-established:
  - "Search dropdown pattern: relative wrapper on input, absolute dropdown below, blur timer with ref, onMouseDown for item clicks"

# Metrics
duration: 3min
completed: 2026-03-14
---

# Phase 23 Plan 03: Search Dropdown + Global Promotions Page Summary

**Search-as-you-type dropdown on AccountsPage (up to 8 inline results) and paginated PromotionsPage at /admin/promotions with tier transition audit log**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-14T15:45:16Z
- **Completed:** 2026-03-14T15:48:41Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- AccountsPage gains an inline search dropdown that appears below the search field when 2+ chars typed, showing display_name, email, and tier badge for up to 8 matching users; clicking navigates to the account detail page
- PromotionsPage renders a paginated table consuming GET /api/admin/promotions with date, linked target user, admin email, previous/new tier badges, and note columns
- AdminLayout and App.tsx updated to expose /admin/promotions with sidebar nav item

## Task Commits

1. **Task 1: Search-as-you-type dropdown on AccountsPage** - `019836f` (feat)
2. **Task 2: Global promotions page, nav item, route** - `9d152ae` (feat)

## Files Created/Modified

- `admin/src/pages/admin/AccountsPage.tsx` - Added relative wrapper, showSearchDropdown/searchResults state, separate dropdown fetch useEffect, focus/blur handlers, and absolute dropdown UI
- `admin/src/pages/admin/PromotionsPage.tsx` - New page: PromotionEntry/PromotionsResponse interfaces, paginated table with tier badges and linked target user
- `admin/src/pages/admin/AdminLayout.tsx` - Added Promotions nav item after Accounts
- `admin/src/App.tsx` - Imported PromotionsPage, added /admin/promotions route

## Decisions Made

- **onMouseDown on dropdown items** — blur fires before click; onMouseDown precedes blur in browser event order, ensuring navigation happens before the dropdown hides
- **Independent dropdown fetch** — dropdown results are fetched separately from the main table so the table's tier/standing filters, pagination, and loading state remain independent and unmodified
- **searchResults capped at 8** — slice before setState keeps the dropdown compact; the full results still populate the main table

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 23-01 (backend) and 23-03 (search/promotions UI) are complete. Plan 23-02 (admin profile page consuming GET /api/account/profile/:userId) remains.
- No blockers for 23-02.

---
*Phase: 23-central-profile-page-admin-tier-promotion*
*Completed: 2026-03-14*
