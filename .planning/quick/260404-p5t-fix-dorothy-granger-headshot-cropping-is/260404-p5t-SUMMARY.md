---
phase: quick
plan: 260404-p5t
subsystem: essentials + ev-accounts
tags: [headshots, image-cropping, focal-point, politician-profile]
dependency_graph:
  requires: []
  provides: [focal_point on politician_images, per-image crop control]
  affects: [essentials frontend, ev-accounts API]
tech_stack:
  added: []
  patterns: [focal_point CSS object-position per-image override]
key_files:
  created:
    - ev-accounts/backend/migrations/050_image_focal_point.sql
  modified:
    - ev-accounts/backend/src/lib/essentialsService.ts
    - ev-accounts/backend/src/lib/essentialsBrowseService.ts
    - essentials/src/pages/Results.jsx
    - essentials/src/pages/Profile.jsx
    - essentials/src/components/PoliticianGrid.jsx
    - essentials/src/components/ElectionsView.jsx
decisions:
  - "center 40% chosen as Dorothy Granger's focal point to shift crop down and show face"
  - "ElectionsView uses candidate.focal_point passthrough with fallback — elections API does not yet return focal_point so this is a forward-compatible stub"
  - "essentialsBrowseService required focal_point update alongside essentialsService (Rule 1 - Bug: same type annotation used by both)"
metrics:
  duration: 15m
  completed: "2026-04-04"
  tasks_completed: 2
  files_changed: 6
---

# Quick Task 260404-p5t: Fix Dorothy Granger Headshot Cropping — Summary

**One-liner:** Per-image focal_point column on politician_images with CSS object-position wiring through backend API and essentials frontend, fixing Dorothy Granger's neck/chest crop.

## Tasks Completed

| Task | Description | Commit (ev-accounts) | Commit (essentials) |
|------|-------------|---------------------|---------------------|
| 1 | Add focal_point column and update backend queries | 4f379b1 | — |
| 2 | Wire focal_point through essentials frontend | — | 7f041f3 |

## What Was Built

**Migration (050_image_focal_point.sql):**
- Adds `focal_point VARCHAR(50) DEFAULT NULL` to `essentials.politician_images`
- Sets `focal_point = 'center 40%'` for Dorothy Granger via name lookup
- Column comment explains it's a CSS `object-position` value

**Backend (essentialsService.ts + essentialsBrowseService.ts):**
- `PoliticianImage` interface extended with `focal_point: string | null`
- `PoliticianFlatRecord.images` array type updated to include `focal_point`
- `batchFetchImages` SELECT and map updated in both services
- `getPoliticianById` SELECT and image mapping updated

**Frontend (essentials):**
- `getImageData()` helper added to Results.jsx and PoliticianGrid.jsx — returns `{ url, focalPoint }`
- `getImageUrl()` kept as wrapper for backward compatibility
- `imageFocalPoint` prop on PoliticianCard in Results.jsx and PoliticianGrid.jsx now uses per-image focal_point with `'center 20%'` fallback
- Profile.jsx passes `imageFocalPoint` to PoliticianProfile from `pol.images[0].focal_point`
- ElectionsView.jsx: `candidate.focal_point || 'center 20%'` (forward-compatible; elections API doesn't return focal_point yet)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] essentialsBrowseService also uses PoliticianImage array type**
- **Found during:** Task 1 TypeScript compile check
- **Issue:** `essentialsBrowseService.ts` has its own `batchFetch` with the same inline image type — TypeScript error TS2322 after updating `PoliticianImage` interface
- **Fix:** Updated SELECT query, Map generic type, and push object in essentialsBrowseService to include `focal_point`
- **Files modified:** `ev-accounts/backend/src/lib/essentialsBrowseService.ts`
- **Commit:** 4f379b1

## Known Stubs

- **ElectionsView.jsx line ~245:** `candidate.focal_point || 'center 20%'` — elections API shape uses `photo_url` directly (no image objects), so `candidate.focal_point` will always be undefined until the elections endpoint is updated to return focal_point per image.

## Self-Check: PASSED

- FOUND: ev-accounts/backend/migrations/050_image_focal_point.sql
- FOUND: ev-accounts/backend/src/lib/essentialsService.ts
- FOUND: essentials/src/pages/Results.jsx
- FOUND: essentials/src/pages/Profile.jsx
- FOUND: ev-accounts commit 4f379b1
- FOUND: essentials commit 7f041f3
