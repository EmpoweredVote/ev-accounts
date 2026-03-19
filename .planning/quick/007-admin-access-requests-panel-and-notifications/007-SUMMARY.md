---
phase: quick-007
plan: 01
subsystem: admin, api, email
tags: [resend, email, admin-ui, react, express, access-requests]

# Dependency graph
requires:
  - phase: auth
    provides: POST /api/auth/request-access and access_requests table
  - phase: admin
    provides: admin route infrastructure (requireAuth, requireAdmin, adminService pattern)
provides:
  - GET /api/admin/access-requests endpoint returning requests newest-first
  - Resend email utility (emailService.ts) with graceful no-op when API key absent
  - Fire-and-forget admin notification email on new access requests
  - Admin UI page at /admin/access-requests with table display
affects: [future email features, admin onboarding workflows]

# Tech tracking
tech-stack:
  added: [resend@^4.x]
  patterns:
    - Fire-and-forget email pattern — sendEmail never throws, never awaited in request path
    - emailService.ts as thin Resend wrapper — all email calls go through this module
    - RESEND_API_KEY absent = graceful no-op with console.warn (dev-friendly)

key-files:
  created:
    - backend/src/lib/emailService.ts
    - admin/src/pages/admin/AccessRequestsPage.tsx
  modified:
    - backend/src/lib/adminService.ts
    - backend/src/routes/admin.ts
    - backend/src/routes/auth.ts
    - backend/.env.example
    - admin/src/pages/admin/AdminLayout.tsx
    - admin/src/App.tsx

key-decisions:
  - "sendEmail is never awaited in route handlers — email failure must not delay or break the access request response"
  - "emailService gracefully no-ops when RESEND_API_KEY is unset — enables local dev without Resend config"
  - "ADMIN_EMAIL env var controls notification recipient — not hardcoded"
  - "Access Requests nav item placed after Invite Tree (onboarding/access management group)"

patterns-established:
  - "Fire-and-forget email: call sendEmail() without await in route handlers; it handles errors internally"
  - "emailService.ts owns all Resend SDK usage — routes never import Resend directly"

# Metrics
duration: 3min
completed: 2026-03-19
---

# Quick Task 007: Admin Access Requests Panel and Notifications Summary

**Resend email notification on new waitlist submissions + admin panel page listing all access requests newest-first**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-03-19T21:29:27Z
- **Completed:** 2026-03-19T21:32:24Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Created `emailService.ts` — thin Resend wrapper that gracefully no-ops when `RESEND_API_KEY` is absent
- Added `listAccessRequests()` to `adminService.ts` and wired up `GET /api/admin/access-requests`
- Hooked fire-and-forget email notification into `POST /api/auth/request-access`
- Built `AccessRequestsPage.tsx` with table display (email + date), loading/error/empty states, dark mode
- Added "Access Requests" to admin sidebar nav and registered route in App.tsx

## Task Commits

1. **Task 1: Email service + admin GET endpoint + notification hook** - `ee37a1a` (feat)
2. **Task 2: Admin UI — Access Requests page + routing** - `4a2bb7a` (feat)

## Files Created/Modified

- `backend/src/lib/emailService.ts` — Resend wrapper; exports `sendEmail`; graceful no-op without API key
- `backend/src/lib/adminService.ts` — added `listAccessRequests()` export
- `backend/src/routes/admin.ts` — added `GET /api/admin/access-requests` route; imported `listAccessRequests`
- `backend/src/routes/auth.ts` — imported `sendEmail`; fire-and-forget notification after `insertAccessRequest`
- `backend/.env.example` — added `RESEND_API_KEY` and `ADMIN_EMAIL` entries
- `admin/src/pages/admin/AccessRequestsPage.tsx` — new page with table, loading/error/empty states
- `admin/src/pages/admin/AdminLayout.tsx` — added "Access Requests" nav item after Invite Tree
- `admin/src/App.tsx` — imported `AccessRequestsPage`; registered `/admin/access-requests` route

## Decisions Made

- `sendEmail` is never awaited in the route handler — email failure must not delay or fail the access request response
- `emailService.ts` gracefully no-ops when `RESEND_API_KEY` is absent, logging a warning — enables local dev without Resend config
- `ADMIN_EMAIL` env var controls notification recipient — `chris@empowered.vote` is already set in the production `.env`
- Access Requests nav item is placed after Invite Tree, grouping it with the onboarding/access management cluster

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — `RESEND_API_KEY` is already configured in production `.env` and `ADMIN_EMAIL=chris@empowered.vote` is already set. New `.env.example` entries document them for future developers.

## Next Phase Readiness

- Email infrastructure is in place for future transactional emails (invite delivery, etc.)
- Access requests are now visible in the admin panel with real-time email alerts

---
*Phase: quick-007*
*Completed: 2026-03-19*
