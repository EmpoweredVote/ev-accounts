---
phase: 40-frontend-auth-updates
plan: 04
status: complete
completed: 2026-03-22
---

# 40-04 Summary: Read & Rank + Treasury Tracker Migration

**One-liner:** Read & Rank migrated to TypeScript Bearer token auth (tsc passes); Treasury Tracker proxy updated; both repos ready for deployment against ev-accounts.

## What Was Built

Read & Rank needed a full TypeScript auth migration — new `auth.ts` wrapper, useAuthState and verdictSync migrated, App.tsx gets hash extraction and Auth Hub sign-in link. Treasury Tracker needed only its Netlify proxy and duplicate `_redirects` file updated. Both repos cloned from GitHub and committed.

## Tasks Completed

1. **Create auth.ts Bearer token wrapper (Read & Rank)** — commit `1ee1c0d`
2. **Migrate useAuthState, verdictSync, api.ts to Bearer auth** — commit `d0ade1d`
3. **Update App.tsx hash extraction and Auth Hub sign-in link** — commit `a2496cf`
4. **Set VITE_API_URL to accounts.empowered.vote** — commit `235c797`
5. **Update treasury-tracker netlify proxy to ev-accounts** — commit `308e9de`

## Files Modified

**Read & Rank (/c/read-rank):**
- `src/lib/auth.ts` — CREATED: fully typed apiFetch, extractHashToken, redirectToLogin, getToken/setToken/clearToken
- `src/hooks/useAuthState.ts` — extractHashToken on init, apiFetch('/auth/me'), display_name
- `src/utils/verdictSync.ts` — apiFetch for verdict POST
- `src/data/api.ts` — searchPoliticians migrated (extra file found)
- `src/App.tsx` — extractHashToken on mount, sign-in link → Auth Hub
- `.env.production` — VITE_API_URL=https://accounts.empowered.vote (created)

**Treasury Tracker (/c/treasury-tracker):**
- `netlify.toml` — proxy to accounts.empowered.vote/api/:splat
- `public/_redirects` — duplicate proxy also updated (was overriding netlify.toml)
- `src/data/dataLoader.ts` — hardcoded api.empowered.vote fallback updated
- `.env.production` — VITE_API_URL=https://accounts.empowered.vote (created)

## Deviations

- `src/data/api.ts` had `credentials: 'include'` on `searchPoliticians` — not in plan's explicit list but found during grep scan, migrated (Rule 2 — missing critical).
- Treasury Tracker `public/_redirects` had duplicate Go server proxy — fixed alongside netlify.toml (Rule 1 — blocking: would have overridden the proxy change).
- Treasury Tracker `src/data/dataLoader.ts` had hardcoded `api.empowered.vote` fallback — updated to avoid hitting old Go server (Rule 1 — bug fix).

## Key Technical Notes

- Read & Rank uses direct API calls (no Netlify proxy) — `VITE_API_URL` env var in Netlify dashboard must be updated to `https://accounts.empowered.vote` before cutover (documented in runbook).
- `npx tsc --noEmit` exits with code 0 — no TypeScript errors.
- Treasury Tracker makes no live API calls (loads static JSON from bundled `./data/` files) — the proxy update is infrastructure prep for future API-backed treasury routes.
- Both repos were cloned fresh from GitHub for this migration.
