---
phase: 40-frontend-auth-updates
plan: 03
status: complete
completed: 2026-03-22
---

# 40-03 Summary: Essentials Bearer Token Migration

**One-liner:** Essentials migrated from cookie auth to Bearer token auth — all fetch calls use apiFetch, hash extraction on init, Sign In link added for unauthenticated users, Netlify proxy updated.

## What Was Built

Essentials had no login UI — the entire auth model was silent cookie sessions from the Go server. After migration: all API calls go through `apiFetch()` with Bearer header, hash fragment extraction runs on init (to receive tokens from Auth Hub redirect), and unauthenticated users now see a Sign In button that redirects to Auth Hub with return URL.

## Tasks Completed

1. **Create auth.js Bearer token wrapper** — commit `07c0f1e`
2. **Migrate api, compass, adminApi to apiFetch** — commit `38eb5a1`
3. **Migrate CompassContext to Bearer auth with hash extraction** — commit `5003ce9`
4. **Add Sign In link for unauthenticated users** — commit `f699dfa`
5. **Update netlify proxy to ev-accounts** — commit `6a66991`
6. **Migrate inline fetch in page components (extra files)** — commit `753757f`

## Files Modified (10 total in /c/Transparent Motivations/essentials)

- `src/lib/auth.js` — CREATED: apiFetch, extractHashToken, redirectToLogin, getToken/setToken/clearToken
- `src/lib/api.jsx` — all credentials: "include" replaced with apiFetch
- `src/lib/compass.js` — all credentials: "include" replaced with apiFetch
- `src/lib/adminApi.js` — all credentials: "include" replaced with apiFetch
- `src/contexts/CompassContext.jsx` — extractHashToken on init, apiFetch, display_name, clearToken on logout
- `src/components/AuthIndicator.jsx` — Sign In button added for unauthenticated state (was returning null)
- `src/components/Layout.jsx` — Sign in menu item calls redirectToLogin() (was hardcoded compass URL)
- `src/pages/CandidateProfile.jsx` — inline fetch migrated (extra file found during scan)
- `src/pages/Profile.jsx` — inline fetch migrated (extra file found during scan)
- `netlify.toml` — proxy to accounts.empowered.vote/api/:splat

## Deviations

- `CandidateProfile.jsx` and `Profile.jsx` had inline fetch calls with `credentials: "include"` not in the plan's scope — both migrated (Rule 1 — bug fix).
- `Layout.jsx` had a hardcoded `compass.empowered.vote` sign-in URL — updated to `redirectToLogin()`.

## Key Technical Notes

- Essentials had no VITE_API_URL in local .env.production — uses Netlify proxy approach (API_BASE falls back to '/api'). The Netlify proxy forwards to ev-accounts. This avoids CORS issues since browser sees same-origin requests.
- `AuthIndicator.jsx` was silently returning null for unauthenticated users — the new Sign In button is the critical missing piece for the auth flow.
- `data.display_name` confirmed as correct field name (was `data.userName` in CompassContext).
