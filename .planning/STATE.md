# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-27 after v2.1 milestone start)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** v2.1 Inform Account Tier — Make Inform a first-class experience with yellow profile, low-friction signup, and an invitational path toward Connected.
**Anti-funnel principle:** Inform Accounts are the expected entry point for most users. "Connect" is framed as unlocking shared participation — never as a conversion goal.

## Current Position

**Phase 68 (Yellow Inform Profile Page) — pending. Phase 67 fully shipped, pending verification.**

v2.0 roadmap: 6 phases (60–65), 34 requirements. Phase 60–63 shipped. Phase 64–65 pending.
v2.1 roadmap: created 2026-04-27. 3 phases (66–68), 21 requirements. 12/21 requirements complete.

Phase 60 (Design Foundation) shipped 2026-04-25: 4/4 plans, DSGN-01–06 verified.
Phase 61 (Auth Flow Restyle) shipped 2026-04-25: 5/5 plans, AUTH-01–06 verified.
Phase 62 (Onboarding Restyle) shipped 2026-04-25: 3/3 plans, ONBD-01–05 verified.
Phase 63 (Profile Page + Activity Feed) shipped 2026-04-27: API-01 + FIX-01 closed (63-01); PROF-01–06 completed in admin/src/pages/ProfilePage.tsx (login.empowered.vote/profile, built 2026-04-26). 63-02 closed as superseded — duplicate app/src profile page not needed; canonical profile is login.empowered.vote/profile.
Phase 64–65 (InformLanding, Dashboard): pending.
Phase 66 (Inform Profiles Backend Foundation) shipped 2026-04-27: 3/3 plans, IBAK-01–06 verified. inform.inform_profiles table live, trigger active, backfill done, gem routing tier-branched, /me inform_profile field live, PATCH /location-hint live, signup_with_invite gem transfer deployed.
Phase 67 (Login Hub + Inform Signup Flow) shipped 2026-04-27: 3/3 plans complete, LHUB-01–02 + ISUP-01–04 closed. 67-01: yellow "Create an Account" CTA + InformConstraintsModal on Login page. 67-02: InformSignup.tsx at /signup/inform — three-field form, yellow theming, posts to /api/auth/signup without invite_code. 67-03: display_name persisted to public.users on Inform signup path. Pending formal /gsd:verify-work.
Phase 68 (Yellow Inform Profile Page): pending.

Last activity: 2026-04-29 — discovered 67-02 was committed 2026-04-27 outside GSD flow; wrote 67-02-SUMMARY.md; STATE updated. Phase 67 fully shipped.

**v1.9 Roles — SHIPPED 2026-04-06 ✅**
8 phases, 19 plans, 17/17 requirements. Archived to `.planning/milestones/v1.9-ROADMAP.md`.

**Phase 59 (Referral Code System) — SHIPPED 2026-04-08 ✅**
4 plans complete. Level-gated invite quota system with social accountability live.

Progress: [v1.0 ✅][v1.1 ✅][v1.2 ✅][v1.3 ✅][v1.4 ✅][v1.5 ✅][v1.6 🔄][v1.7 ✅][v1.8 ✅][v1.9 ✅][v2.0 🔄][v2.1 🔄] Phase 60 ✅ Phase 61 ✅ Phase 62 ✅ Phase 63 ✅ Phase 64 ░ Phase 65 ░ Phase 66 ✅ Phase 67 ✅ Phase 68 ░

## Performance Metrics

**v2.0 Scope**
- Phases: 6 (60–65)
- Requirements: 34 (DSGN-01–06, AUTH-01–06, ONBD-01–05, PROF-01–06, API-01, FIX-01, LAND-01–05, DASH-01–04)
- Plans complete: 0
- Plans total: TBD (determined per phase during planning)

**v2.1 Scope**
- Phases: 3 (66–68)
- Requirements: 21 (IBAK-01–06, LHUB-01–02, ISUP-01–04, IPRO-01–06, CEXP-01–03)
- Plans complete: 0
- Plans total: ~9 (3 plans per phase, TBD)

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.1 DB Patterns (from 66-01)

- **inform.inform_profiles auto-creation**: `trg_create_inform_profile` AFTER INSERT trigger on `public.users` calls `inform.handle_new_user()` (SECURITY DEFINER, `SET search_path = ''`) — same pattern as connect/empower tier auto-profile creation.
- **Yellow gem transfer on Connect**: `signup_with_invite` does `SELECT yellow_gem_balance FOR UPDATE` on inform_profiles (prevents concurrent award race), zeros the balance, then seeds `connected_profiles.gem_balance_yellow = COALESCE(v_inform_balance, 0)` — atomically within the RPC transaction.
- **IF FOUND guard on zero-out**: inform_profiles UPDATE only fires when row exists — handles users created before trigger deployment.
- **inform schema NOT in PostgREST**: all reads/writes to `inform.*` must use `pool.query()` (direct postgres), never PostgREST/supabaseAdmin.schema('inform').

### v2.0 Copy Decisions (from Phase 61)

- **AppNav**: No "Civic Platform" text — logo only. Wordmark belongs to auth pages, not the nav chrome.
- **Signup heading**: "Create your Connected Account" — names the tier (Connected) explicitly.
- **Legal name copy**: "During Alpha, your identity is verified through our invite network — one person, one voice." — "Never shown publicly" removed because legal name may surface on Empowered accounts in future features.
- **WelcomeScreen heading**: "Join to participate" — invitational, not "Get started" or conversion-funnel language.
- **AuthInput inputClassName**: escape-hatch for per-field styling (e.g., `font-mono tracking-wider` on invite code) without touching base styles.

### v2.0 Component Patterns (from 60-02, 60-03, 60-04)

**Chrome components (60-04):**
- **StepProgress bar height**: `h-1.5` (6px) — thinner than DashboardPage XP bar (`h-2`) per v2.0 spec
- **StepProgress fill**: `bg-ev-blue` (NOT ev-teal) — v2.0 primary CTA blue palette
- **Conditional slot pattern**: `{children && <div className="flex items-center gap-3">{children}</div>}` — avoids empty flex spacing
- **No Link/a on logo**: AppNav logo has no wrapper — navigation belongs to the consumer page
- **AppNav dimensions**: `max-w-lg` container, `h-14` height (56px), `sticky top-0 z-10` — matches DashboardPage header

### v2.0 Component Patterns (from 60-02, 60-03)

**Button components (60-03):**
- **PrimaryButton palette**: `bg-ev-blue text-white` / hover: `bg-ev-blue/90` / shape: `w-full rounded-xl py-3 font-bold text-base`
- **SecondaryButton palette**: `bg-gray-800 text-white border border-gray-700` / hover: `bg-gray-700` — gray-800 chosen (not ev-navy) so it layers above AuthCard's gray-900 background
- **Prop parity**: both buttons share identical interface (children/onClick/type/disabled/className with same defaults) — swap by changing only the import name
- **type defaults to 'button'**: forms must explicitly pass `type="submit"` — prevents accidental submission outside form context
- **No loading prop**: loading text is consumer responsibility via children

### v2.0 Component Patterns (from 60-02)

- **AuthCard base classes**: `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` — no width; parent owns sizing
- **AuthCard background**: `bg-gray-900` not `bg-ev-navy` — card must contrast against navy page background
- **AuthInput onChange**: `(value: string) => void` — component extracts e.target.value; caller receives string
- **AuthInput focus ring**: `focus:ring-ev-blue` solid (no opacity variant) per design spec
- **AuthInput error state**: switches to `border-ev-red focus:ring-ev-red` + renders `<p className="text-ev-red">` below input
- **Component export convention**: named `export function X`, `interface` for props — matches AuthGuard.tsx pattern

### v2.0 Design Constraints

- **App surface only** — All v2.0 work is in `app/src` (end-user app at `app.empowered.vote`). Admin tool (`admin/src`) and contributor portal (`/contributor`) are out of scope.
- **`ev-blue` token also goes in admin** — DSGN-01 adds `ev-blue` to both `app/src/index.css` and `admin/src/index.css`; admin is otherwise untouched.
- **No Framer** — end-user frontend is the `/app` React app in this repo, not Framer. All v2.0 UI work goes in `app/src`.
- **Tailwind v4 `@theme`** — color tokens defined via `@theme` block in index.css, same pattern as existing `ev-red`, `ev-teal`, etc. in admin.
- **InformLanding routing** — unauthenticated root (`/`) renders `InformLandingPage`; authenticated root renders `DashboardPage`. Phase 64 owns the routing split.
- **Activity feed endpoint** — `GET /api/account/me/activity` reads from `connect.xp_transactions` (the existing append-only ledger). Returns last 20 entries. Requires Connected tier. Shipped 63-01.
- **FIX-01 CLOSED (63-01)** — invite label round-trip confirmed working end-to-end: DashboardPage sends `label`, invites.ts reads it, inviteQuotaService passes it as `$2` to the RPC. Phase 59 rename (`optional_name` → `label`) already resolved the bug. No code change needed.
- **`description` aliases `source` in /me/activity (63-01)** — `xp_transactions` has no `description` column; API maps `source` into `description` to keep contract clean and decouple frontend from schema column names.

### v2.0 Phase Dependencies

```
Phase 60 (Design Foundation)
  └── Phase 61 (Auth Flow Restyle)       — needs AuthCard, AuthInput, PrimaryButton, AppNav, StepProgress
  └── Phase 62 (Onboarding Restyle)      — needs AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton
                                           — needs WelcomeScreen from Phase 61 to exist before removing WelcomeStep
  └── Phase 63 (Profile Page + Activity) — needs design tokens only (no auth-flow dependency)
  └── Phase 64 (InformLanding)           — needs AppNav with auth links
  └── Phase 65 (Dashboard Redesign)      — needs Phase 60 tokens + Phase 63 API + Phase 64 routing split
```

### v2.0 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 60 — Design Foundation | DSGN-01, DSGN-02, DSGN-03, DSGN-04, DSGN-05, DSGN-06 | 6 |
| 61 — Auth Flow Restyle | AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06 | 6 |
| 62 — Onboarding Restyle | ONBD-01, ONBD-02, ONBD-03, ONBD-04, ONBD-05 | 5 |
| 63 — Profile Page + Activity Feed | PROF-01, PROF-02, PROF-03, PROF-04, PROF-05, PROF-06, API-01, FIX-01 | 8 |
| 64 — InformLanding | LAND-01, LAND-02, LAND-03, LAND-04, LAND-05 | 5 |
| 65 — Dashboard Redesign | DASH-01, DASH-02, DASH-03, DASH-04 | 4 |
| **Total** | | **34 / 34** ✓ |

### v2.1 Requirement Coverage

| Phase | Requirements | Count |
|-------|-------------|-------|
| 66 — Inform Profiles Backend Foundation | IBAK-01, IBAK-02, IBAK-03, IBAK-04, IBAK-05, IBAK-06 | 6 |
| 67 — Login Hub + Inform Signup Flow | LHUB-01, LHUB-02, ISUP-01, ISUP-02, ISUP-03, ISUP-04 | 6 |
| 68 — Yellow Inform Profile Page + Connected Explainer | IPRO-01, IPRO-02, IPRO-03, IPRO-04, IPRO-05, IPRO-06, CEXP-01, CEXP-02, CEXP-03 | 9 |
| **Total** | | **21 / 21** ✓ |

### v2.1 Phase Dependencies

```
Phase 66 (Inform Profiles Backend Foundation)
  └── Phase 67 (Login Hub + Inform Signup Flow) — needs DB trigger so signup auto-creates inform_profiles row
  └── Phase 68 (Yellow Inform Profile Page)     — needs /me inform_profile object (Phase 66) + signup creates the account (Phase 67)
```

### Open Blockers

None for v2.0 start.

**Carried forward from v1.9 (non-blocking):**
- Verify `app.empowered.vote` in Render `CORS_ORIGIN` env var
- Smoke-test admin grant UI → adminRouter → grant_role RPC chain end-to-end in production
- Backport district-join approach to `getMatchingGrant` (compass_stance_editor — currently fail-open)
- `medicare` topic_key mismatch in `essentials.quotes` (pre-existing)
- v1.6 phases 42–43 (Decommission + DNS, Integration Documentation) still pending

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |
| 007 | Admin access requests panel + Resend email notification on new submissions | 2026-03-19 | 4a2bb7a | [007-admin-access-requests-panel-and-notifications](./quick/007-admin-access-requests-panel-and-notifications/) |
| 008 | Fix representatives/me to return precise results for Connected users | 2026-03-29 | 8dfa38e | [008-fix-representatives-me-to-return-precise](./quick/008-fix-representatives-me-to-return-precise/) |
| 009 | Add weekly district staleness check cron for Connected users | 2026-03-29 | 10e5447 | [009-add-weekly-district-staleness-check-cron](./quick/009-add-weekly-district-staleness-check-cron/) |
| 010 | Fix BUG-01: restore deleted district rows for 54 CA Cicero politicians + quarantine CAL Access committee records | 2026-03-30 | dd06d9f | [010-fix-bug-01-restore-cicero-districts-quarant](./quick/010-fix-bug-01-restore-cicero-districts-quarant/) |
| 011 | Fix BUG-03: city/local officials missing from GET /essentials/representatives/me | 2026-03-30 | 64ccc0a | [011-fix-bug-03-city-officials-in-representatives](./quick/011-fix-bug-03-city-officials-in-representatives/) |
| 012 | Fix CA NATIONAL_UPPER senators (Padilla + Schiff) missing from geofence search | 2026-03-30 | 1b95f0e | [012-fix-ca-national-upper-senators-padilla-geofence](./quick/012-fix-ca-national-upper-senators-padilla-geofence/) |
| 013 | Phase 43 — Integration Documentation for Chris Andrews' team | 2026-03-30 | 85267c1 | [013-phase-43-integration-documentation-for-chri](./quick/013-phase-43-integration-documentation-for-chri/) |
| 014 | Add City Council district to jurisdiction data (connected_profiles + DashboardPage) | 2026-04-09 | c88eee1 | [014-add-city-council-district-to-jurisdicti](./quick/014-add-city-council-district-to-jurisdicti/) |
| 015 | Session polling for cross-app logout sync | 2026-04-09 | 091fb16 | [015-session-polling-cross-app-logout-sync](./quick/015-session-polling-cross-app-logout-sync/) |
| 016 | CA SoS 2026 challenger ingestion — 49 challengers across 16 LA County Primary races | 2026-04-13 | cfc2f40 | [016-ca-sos-challenger-ingestion](./quick/016-ca-sos-challenger-ingestion/) |
| 017 | Import verified 2026 LA County primary candidates | 2026-04-13 | — | [017-import-verified-2026-la-county-primary-c](./quick/017-import-verified-2026-la-county-primary-c/) |
| 018 | Add municipality_geo_id support so LA City races display for LA residents | 2026-04-13 | — | [018-add-municipality-geo-id-support-so-la-ci](./quick/018-add-municipality-geo-id-support-so-la-ci/) |
| 019 | Rename accounts.empowered.vote → login.empowered.vote in runtime code | 2026-04-15 | ac151ef | [019-rename-accounts-to-login-empowered-vote](./quick/019-rename-accounts-to-login-empowered-vote/) |
| 020 | FC post history tab on DashboardPage — PostHistory component with cursor pagination | 2026-04-17 | 0da4072 | [020-build-fc-post-history-feature-on-account](./quick/020-build-fc-post-history-feature-on-account/) |

## Session Continuity

Last session: 2026-04-27T22:16:49Z
Stopped at: Completed 67-01-PLAN.md — InformConstraintsModal + Login.tsx CTA wired. LHUB-01 + LHUB-02 UI complete, awaiting human verify + plans 67-02/03 for signup route + backend.
Resume file: None
