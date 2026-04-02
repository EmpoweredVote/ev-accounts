# API URL Cutover Notice — Action Required

**Date:** 2026-04-02
**Affects:** All apps integrating with the Empowered Vote Accounts API

---

## What Changed

The Accounts API has moved to a new canonical URL:

| | URL |
|---|---|
| **Old (deprecated)** | `https://accounts-api.empowered.vote` |
| **New (canonical)** | `https://api.empowered.vote` |

The DNS cutover happened in late March 2026 (Phase 42). The old subdomain (`accounts-api.empowered.vote`) may continue to resolve for a period, but it is no longer the authoritative endpoint and should not be relied upon.

---

## What You Need to Do

Find wherever your app sets the Accounts API base URL — typically an environment variable like `VITE_API_URL`, `NEXT_PUBLIC_API_URL`, `API_BASE_URL`, or similar — and update it:

```
# Before
VITE_API_URL=https://accounts-api.empowered.vote

# After
VITE_API_URL=https://api.empowered.vote
```

Then redeploy your app. On Render, this is: **Environment → update the variable → Manual Deploy**.

---

## How to Tell If You're Affected

Open your app in a browser, log in via SSO, then open DevTools → Network tab. Filter by `accounts-api`. If you see any requests going to `accounts-api.empowered.vote`, you need to update.

Symptoms of the stale URL:
- App doesn't inherit SSO session after logging in at `accounts.empowered.vote`
- Console shows `GET https://accounts-api.empowered.vote/api/account/me 401 (Unauthorized)`
- App appears logged out even when `ev_session` cookie is present

---

## Background

The Accounts API previously ran on a Go server with a separate Render service URL exposed via the `accounts-api.empowered.vote` subdomain. As part of platform consolidation, the Go server was decommissioned and the Express API (`ev-accounts-api.onrender.com`) became the sole backend. The DNS entry `api.empowered.vote` was created as the clean public-facing URL for all integrations going forward.

The full integration guide is at `docs/INTEGRATION-GUIDE-v2.md`.

---

## Questions

Reach out to Chris Cantrell (@ccantrell-storygames) or check `docs/INTEGRATION-GUIDE-v2.md` for the full API reference.
