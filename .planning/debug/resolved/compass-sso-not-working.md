---
status: resolved
trigger: "compass-sso-not-working: User logs in at accounts.empowered.vote, visits compass.empowered.vote, loads as guest. SSO never worked on production."
created: 2026-03-26T00:00:00Z
updated: 2026-03-26T00:01:00Z
---

## Current Focus

hypothesis: CompassV2 SSO fetch uses a relative URL `/api/auth/session` in the committed version, which hits compass.empowered.vote/api/auth/session (nonexistent) instead of the accounts API. The fix (using API_BASE) exists in the local working copy but was never committed and pushed.
test: Read git diff and git log to confirm discrepancy between local and committed code
expecting: Fix = commit the working-copy change and push to GitHub so Render rebuilds
next_action: Commit the staged fix in C:/EV-CompassV2 and push to origin/main

## Symptoms

expected: User logged in at accounts.empowered.vote navigates to compass.empowered.vote and sees authenticated state automatically
actual: compass.empowered.vote always loads as guest — SSO never triggers authentication
errors: None visible; SSO fetch silently fails because it hits the wrong host
reproduction: Log in at accounts.empowered.vote, open compass.empowered.vote in same browser
started: Since initial production deployment — never worked

## Eliminated

- hypothesis: CompassV2 does not have SSO code at all
  evidence: CompassContext.jsx lines 99-144 have the full async IIFE SSO pattern
  timestamp: 2026-03-26T00:00:00Z

- hypothesis: CORS is the issue
  evidence: CompassV2 auth.js has hardcoded API_BASE pointing to accounts-api.empowered.vote. CORS config in backend/src/index.ts allows CORS_ORIGIN list. The relative-URL bug causes the request to never reach accounts API at all, making CORS irrelevant.
  timestamp: 2026-03-26T00:00:00Z

- hypothesis: ev_session cookie is not being set on login
  evidence: Memory file confirms cookie is set correctly in Phase 44; other apps (CTC, VQ, Profile Hub) work. The issue is specific to the fetch URL in CompassV2.
  timestamp: 2026-03-26T00:00:00Z

## Evidence

- timestamp: 2026-03-26T00:00:00Z
  checked: C:/EV-CompassV2/src/components/CompassContext.jsx (working copy)
  found: Line 109 has `fetch(\`${API_BASE}/auth/session\`, ...)` — correct
  implication: Local fix is present

- timestamp: 2026-03-26T00:00:00Z
  checked: git show f2fc6b6:src/components/CompassContext.jsx line 109
  found: `fetch('/api/auth/session', ...)` — relative URL, hits compass.empowered.vote/api/auth/session
  implication: The committed/deployed version has the bug; the local fix was never committed

- timestamp: 2026-03-26T00:00:00Z
  checked: git diff src/components/CompassContext.jsx in C:/EV-CompassV2
  found: Two-line diff — adds `API_BASE` to import and changes fetch URL from relative to absolute
  implication: The fix is minimal and correct; just needs to be committed and pushed

- timestamp: 2026-03-26T00:00:00Z
  checked: C:/EV-CompassV2/src/lib/auth.js
  found: API_BASE hardcoded to 'https://accounts-api.empowered.vote/api' (not env-var driven)
  implication: No env var dependency issue; the absolute URL is correct for production

- timestamp: 2026-03-26T00:00:00Z
  checked: Memory file project_sso_render_deployment.md
  found: Root cause was documented on 2026-03-25 but the fix was not committed/pushed. Also notes remaining Render steps (CORS_ORIGIN, custom domain, NPM_TOKEN).
  implication: Code fix exists locally; Render deployment steps also needed for full SSO

## Resolution

root_cause: CompassContext.jsx SSO fetch uses relative URL '/api/auth/session' in the deployed (committed) version. This sends the request to compass.empowered.vote/api/auth/session — which doesn't exist — instead of https://accounts-api.empowered.vote/api/auth/session. The browser receives a 404 or network error, the catch block swallows it silently, and CompassV2 falls back to guest mode. The fix (using API_BASE for the absolute URL) exists in the local working copy but was never committed.
fix: Commit the two-line diff in C:/EV-CompassV2 (add API_BASE to import, use ${API_BASE}/auth/session in fetch). Push to GitHub — Render auto-deploys. Also requires: CORS_ORIGIN env var on accounts API Render service must include https://compass.empowered.vote, and compass.empowered.vote custom domain must be configured in Render (for ev_session cookie domain match).
verification: Fix committed (46a1185) in C:/EV-CompassV2. Confirmed committed version now has API_BASE import and absolute URL fetch. Push to GitHub triggers Render auto-deploy. Remaining deployment prereqs documented in Resolution.fix.
files_changed:
  - C:/EV-CompassV2/src/components/CompassContext.jsx
