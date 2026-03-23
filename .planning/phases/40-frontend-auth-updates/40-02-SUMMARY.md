---
phase: 40-frontend-auth-updates
plan: 02
status: complete
completed: 2026-03-22
---

# 40-02 Summary: CompassV2 Bearer Token Migration

**One-liner:** CompassV2 fully migrated from cookie-based Go server auth to Bearer token auth against ev-accounts — 26 files updated, Login/Register replaced with Auth Hub redirects, all critical checks pass.

## What Was Built

CompassV2's entire auth layer replaced. Every `credentials: "include"` fetch call now goes through `apiFetch()` with `Authorization: Bearer {token}`. Login and Register pages are pure redirect stubs that bounce users to Auth Hub. AdminRoute uses `/auth/me` + `is_admin` instead of the Go-specific `/auth/admin-check`. Hash fragment token extraction runs on app init.

## Tasks Completed

1. **Create auth.js Bearer token wrapper** — commit `9ad1393`
2. **Migrate Login and Register to Auth Hub redirects** — commit `f9cfe61`
3. **Migrate CompassContext and route guards to Bearer auth** — commit `78dc4e3`
4. **Migrate all page components and hooks to apiFetch** — commits `43d0348`, `d0c9b33`
5. **Update env and netlify proxy to ev-accounts** — commit `723b16b`
6. **Migrate remaining components to apiFetch (extra files)** — commit `202960a`

## Files Modified (26 total in /c/EV-CompassV2)

- `src/lib/auth.js` — CREATED: apiFetch, extractHashToken, redirectToLogin, getToken/setToken/clearToken
- `src/pages/Login.jsx` — Auth Hub redirect stub
- `src/pages/Register.jsx` — Auth Hub signup redirect stub
- `src/components/CompassContext.jsx` — extractHashToken on init, apiFetch, display_name
- `src/components/ProtectedRoute.jsx` — apiFetch auth check
- `src/components/AdminRoute.jsx` — /auth/me + is_admin (not /auth/admin-check)
- `src/components/Layout.jsx` — apiFetch logout + clearToken
- `src/pages/Home.jsx`, `BuildCompass.jsx`, `Compass.jsx`, `Library.jsx`, `Quiz.jsx` — apiFetch
- `src/hooks/usePoliticianList.js`, `src/hooks/IsAdmin.jsx` — apiFetch
- `src/components/admin/AdminDashboard.jsx`, `AttachAnswers.jsx`, `CreateTopic.jsx`, `PoliticianAdminPanel.jsx`, `TopicAccordion.jsx`, `TopicEditor.jsx` — apiFetch
- `src/components/AddTopicModal.jsx`, `CalibrationOverlay.jsx`, `ComparePanel.jsx`, `ReplaceTopicModal.jsx` — apiFetch (extra files found during scan)
- `.env.production` — VITE_API_URL=https://accounts.empowered.vote
- `netlify.toml` — proxy to accounts.empowered.vote/api/:splat

## Deviations

- 5 extra component files had `credentials: "include"` not listed in the plan: `AddTopicModal`, `CalibrationOverlay`, `ComparePanel`, `ReplaceTopicModal`, `IsAdmin`. All migrated (Rule 2 — missing critical).
- `IsAdmin.jsx` used `/auth/admin` endpoint — migrated to `/auth/me` + `is_admin` check consistent with AdminRoute.

## Key Technical Notes

- Guest-answer migration logic in Register.jsx intentionally dropped (buildGuestState function removed). Alpha users who had local quiz answers before registering lose them on re-registration. LOW impact — documented in runbook.
- `IsAdmin.jsx` had its own `/auth/admin` call separate from AdminRoute — both now use same `/auth/me` + `is_admin` pattern.
- Plan's file list was not exhaustive — full repo grep scan required to achieve ZERO credentials: "include".
