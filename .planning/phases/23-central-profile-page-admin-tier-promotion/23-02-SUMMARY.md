---
phase: 23-central-profile-page-admin-tier-promotion
plan: 02
subsystem: ui
tags: [react, tailwind, admin-ui, tier-promotion, compass, profile]

# Dependency graph
requires:
  - phase: 23-01
    provides: promote_to_connected RPC, GET /api/account/profile/:userId, GET /api/admin/accounts/:userId/promotion-history
provides:
  - Extended AccountDetailPage with compass section, empowered profile section, promotion history table, and promote-to-connected modal flow
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tier-conditional section rendering: check profileData?.selected_topic_ids !== undefined (not tier string) so Connected and Empowered both see Compass"
    - "Promote button absent (not disabled) for non-Inform tiers: {account.tier === 'inform' && <button>} — DOM element does not exist"
    - "Promotion modal as fixed overlay z-50 with loading state disabling both Cancel and CTA buttons"
    - "Success toast with setTimeout auto-clear (5s) using promotionSuccess string state"
    - "Parallel data fetches on mount: profile + account + promotion history each in separate useEffects"

key-files:
  created: []
  modified:
    - admin/src/pages/admin/AccountDetailPage.tsx

key-decisions:
  - "Profile endpoint for Compass data: fetched from /api/account/profile/:userId (public endpoint) rather than a separate admin endpoint — re-uses Phase 23-01 work without duplication"
  - "Compass section visibility gate: profileData?.selected_topic_ids !== undefined — presence of the field (not the tier string) since the service returns it for Connected and Empowered"
  - "Promotion history refresh after successful promote: reset promotionPage to 1 and re-fetch inline rather than relying on a useEffect dependency cascade"
  - "Profile fetch errors are non-fatal: catch swallows error and sets profileData to null — compass/empowered sections simply don't render"

patterns-established:
  - "Absent button (not disabled) for conditional admin actions: use {condition && <button>} not disabled prop"
  - "apiFetch error handling for promotion: check message for '409'/'already' and '404'/'not found' to display tier-specific messages"

# Metrics
duration: 3min
completed: 2026-03-14
---

# Phase 23 Plan 02: Central Profile Page + Admin Tier Promotion Summary

**Admin AccountDetailPage extended with tier-conditional compass answers table, empowered profile block, paginated promotion history, and Inform-only promote-to-connected modal with optional note and 5s success toast**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-14T15:44:36Z
- **Completed:** 2026-03-14T15:47:39Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Compass section shows selected topic count (Connected/Empowered) and answers table (Empowered only) — Connected-tier shows privacy notice
- Empowered Profile section shows legal_name, candidate_page_slug link, is_active badge, empowered_at date, and optional demoted_at
- Promotion History section always rendered with paginated table (date, admin email, previous/new tier badges, note)
- Promote to Connected button conditionally absent (not disabled) for Connected/Empowered users; modal with optional note (max 500 chars) and full loading state
- Successful promotion: fetchAccount() refresh, promotion history re-fetch, inline green toast that auto-clears after 5 seconds

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend AccountDetailPage with Compass, Empowered Profile, and Promotion Sections** - `1e935d0` (feat)

**Plan metadata:** _(docs commit follows)_

## Files Created/Modified

- `admin/src/pages/admin/AccountDetailPage.tsx` - Extended from 499 to 858 lines; adds ProfileData/PromotionEntry interfaces, three new sections, and full promotion flow

## Decisions Made

- **Profile endpoint for Compass data:** Fetched from `/api/account/profile/:userId` (the public endpoint built in 23-01) rather than a separate admin endpoint. Re-uses existing work and the endpoint already returns tier-conditional compass data.
- **Compass section visibility gate:** `profileData?.selected_topic_ids !== undefined` (field presence) rather than checking `account.tier` string — keeps the gate anchored to what the API actually returns.
- **Promotion history refresh after promote:** Reset `promotionPage` to 1 and call `apiFetch` inline in `handlePromote` rather than adding `promotionPage` as a `useEffect` dependency that could cause double-fetch loops.
- **Profile fetch errors non-fatal:** `catch` swallows error, sets `profileData` to null — compass and empowered sections simply do not render if profile endpoint is unavailable.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 23 Plan 03 (global promotion log admin page) can proceed — all backend endpoints are in place.
- PROMO-01, PROMO-02, PROMO-03, and PROFILE-03 requirements are now fully satisfied.

---
*Phase: 23-central-profile-page-admin-tier-promotion*
*Completed: 2026-03-14*
