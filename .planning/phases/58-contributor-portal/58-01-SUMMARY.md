---
plan: 58-01
phase: 58-contributor-portal
status: complete
completed: 2026-04-04
---

# Plan 58-01: Backend API Micro-fixes — Summary

## What Was Built

Two one-line backend changes that unblock the Contributor Portal frontend.

## Deliverables

### Task 1: granted_at in contributor/me response
- `backend/src/routes/contributor.ts` — added `granted_at: g.granted_at` to the `grants.map()` object (commit `4895a93`)
- Updated JSDoc comment to document `granted_at` in response shape
- `UserRoleGrant.granted_at` was already present on the grant object — just not being passed through

### Task 2: essentials_data_editor access to contributor politicians endpoint
- `backend/src/routes/compassContributor.ts` — added `essentials_data_editor` to `requireRole` array and `contributorGrants.filter()` for the `GET /contributors/politicians` route (commit `4c575c3`)
- Updated file header comment to mention essentials_data_editor
- PUT stance routes remain restricted to compass_stance_editor + campaign_manager only

## Verification

- `cd backend && npx tsc --noEmit` passes with zero errors
- `granted_at` present in contributor.ts response mapping
- `essentials_data_editor` in requireRole AND contributorGrants filter for GET /contributors/politicians
- PUT /stances routes unchanged (no scope creep)

## Issues / Deviations

None. Both changes were exactly as specified — single-field additions with no service-layer modifications needed.
