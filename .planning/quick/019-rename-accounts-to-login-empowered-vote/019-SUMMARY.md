---
phase: quick
plan: "019"
subsystem: infra
tags: [domain, dns, cors, supabase-auth, render, redirect]

# Dependency graph
requires: []
provides:
  - All runtime code references to accounts.empowered.vote updated to login.empowered.vote
  - INFRA-CHECKLIST.md documenting 4 manual pre-deploy steps (DNS, Render, Supabase Auth, CORS)
affects: [deploy, dns-cutover, cors, supabase-auth-config]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Domain rename: update runtime strings only; leave historical .planning docs and docs/*.md as-is"

key-files:
  created:
    - .planning/quick/019-rename-accounts-to-login-empowered-vote/INFRA-CHECKLIST.md
  modified:
    - app/src/components/AuthGuard.tsx
    - app/src/pages/DashboardPage.tsx
    - backend/src/routes/auth.ts
    - admin/src/pages/PrivacyPage.tsx

key-decisions:
  - "Code commits safe to push immediately; Render deploy must be held until user completes INFRA-CHECKLIST"
  - "accounts.empowered.vote kept as alias in all infra layers during transition"
  - "docs/ and .planning/ references left as-is (historical); flagged in checklist for later cleanup"

patterns-established: []

# Metrics
duration: 2min
completed: 2026-04-15
---

# Quick Task 019: Rename accounts.empowered.vote to login.empowered.vote Summary

**4 runtime code files updated from accounts.empowered.vote to login.empowered.vote; INFRA-CHECKLIST.md produced with 4 ordered manual steps (DNS CNAME, Render custom domain, Supabase Auth redirect URLs, CORS_ORIGIN) the user must complete before deploying.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-15T21:08:34Z
- **Completed:** 2026-04-15T21:10:59Z
- **Tasks:** 2
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- Created INFRA-CHECKLIST.md with 4 ordered infrastructure steps, a verification section, and post-migration cleanup notes
- Updated AuthGuard.tsx unauthenticated redirect to `https://login.empowered.vote/login?redirect=...`
- Updated DashboardPage.tsx admin panel link to `https://login.empowered.vote/admin`
- Updated backend auth.ts access-request notification email link to `https://login.empowered.vote/admin/access-requests`
- Updated PrivacyPage.tsx display text from `accounts.empowered.vote` to `login.empowered.vote`
- TypeScript compilation passes cleanly for all 3 projects (app, admin, backend)

## Task Commits

1. **Task 1: Create INFRA-CHECKLIST.md** - `c47f97d` (docs)
2. **Task 2: Update 4 runtime code references** - `ac151ef` (feat)

## Files Created/Modified

- `.planning/quick/019-rename-accounts-to-login-empowered-vote/INFRA-CHECKLIST.md` - Manual pre-deploy infrastructure checklist (4 steps + verification + cleanup notes)
- `app/src/components/AuthGuard.tsx` - Unauthenticated redirect target updated
- `app/src/pages/DashboardPage.tsx` - Admin panel link updated
- `backend/src/routes/auth.ts` - Access request email link updated
- `admin/src/pages/PrivacyPage.tsx` - Privacy policy display domain updated

## Decisions Made

- **Code safe to push, deploy must wait:** The code changes carry no risk in isolation; the Render deploy must not go live until the user completes all 4 infra steps. This ordering is documented prominently in INFRA-CHECKLIST.md.
- **accounts.empowered.vote stays as alias:** All infra layers (DNS, Render, Supabase Auth, CORS) keep the old domain during transition to avoid breaking existing links or sessions.
- **docs/ and .planning/ left unchanged:** These contain historical references. The checklist flags them for a follow-up cleanup pass rather than changing them now.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**Manual infrastructure steps required before deploying.** See [INFRA-CHECKLIST.md](./INFRA-CHECKLIST.md) for:

1. DNS: Add `login.empowered.vote` CNAME (keep `accounts.empowered.vote` alias)
2. Render: Add `login.empowered.vote` as custom domain on the admin static site service
3. Supabase Auth: Add `login.empowered.vote` and `login.empowered.vote/**` to redirect URLs; update Site URL
4. Render API: Add `https://login.empowered.vote` to `CORS_ORIGIN` env var

Complete all 4 steps and verify before triggering a Render deploy of the code changes.

## Next Phase Readiness

- Code changes committed and ready to push
- No further code changes needed for this rename
- After infra steps complete, deploy will route unauthenticated app users and admin panel links to the new canonical domain
- Follow-up: update docs/*.md references to `accounts.empowered.vote` in a documentation cleanup pass

---
*Phase: quick-019*
*Completed: 2026-04-15*
