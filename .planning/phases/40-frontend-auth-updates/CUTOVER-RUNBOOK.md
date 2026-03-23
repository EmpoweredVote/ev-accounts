# Phase 40 Cutover Runbook: Frontend Auth Migration

**Version:** 1.0
**Date:** 2026-03-22
**Status:** Ready for review

---

## Section 1: Overview

### What Is Changing

All four Empowered Vote frontend apps are switching from cookie-based Go server auth to Bearer token auth against the ev-accounts Express API (`accounts.empowered.vote`).

**Before:** Each app sent `credentials: "include"` on every fetch, relying on a cookie set by the Go server (`api.empowered.vote`). Login happened on each app individually.

**After:** Each app uses a shared `apiFetch()` wrapper that attaches `Authorization: Bearer {token}` on every authenticated request. Login happens once at Auth Hub (`accounts.empowered.vote`) and the token is delivered back to the calling app via hash fragment (`#access_token=`). Token is stored in `localStorage` and reused across requests.

### What Was Already Done (Plans 40-01 through 40-04)

- **Auth Hub** (40-01): Login/signup pages now redirect back with `#access_token=` in the hash fragment. Re-auth banner displays when arriving from a `?redirect=` param.
- **CompassV2** (40-02): 26 files migrated. Login/Register pages are now redirect stubs. All `credentials: "include"` fetch calls replaced with `apiFetch()`. `netlify.toml` proxy updated.
- **Essentials** (40-03): 10 files migrated. Sign In button added. All fetch calls use `apiFetch()`. `netlify.toml` proxy updated.
- **Read & Rank** (40-04): Full TypeScript auth wrapper. `useAuthState`, `verdictSync`, `api.ts` migrated. `App.tsx` extracts hash token on mount. `.env.production` set to `https://accounts.empowered.vote`.
- **Treasury Tracker** (40-04): `netlify.toml` proxy updated. `_redirects` duplicate fixed. `dataLoader.ts` hardcoded fallback updated.

### Cutover Approach

Simultaneous cutover — all 4 apps deploy at the same time. This is intentional: rolling cutover would leave some apps on the old auth model while others are on the new one, creating cross-app session inconsistency.

**Estimated downtime:** Zero. Users who visit during or after cutover see a login prompt and log in once. Their data is unaffected.

**Monitoring window:** 1–3 days post-cutover before Phase 42 (Go server decommission) begins.

### Parties and Roles

| Party | Role |
|-------|------|
| **Chris Cantrell** | Final go/no-go decision. Posts user communication. Has Render access for ev-accounts. |
| **Claude** | Executes technical steps (CORS update, PR creation, verification via logs). |
| **Chris Andrews** | Has Netlify dashboard access for all 4 apps. Sets env vars in Netlify. Merges PRs. |

---

## Section 2: Pre-Cutover — CORS Setup (DO THIS FIRST)

**This must be done before any PRs are merged.** If the CORS_ORIGIN env var on ev-accounts doesn't include the frontend domains, the apps will get CORS errors immediately after deploy.

### Step-by-Step

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Select the **ev-accounts** service
3. Click **Environment** in the left sidebar
4. Find the `CORS_ORIGIN` environment variable
5. Update the value to include ALL frontend production domains (comma-separated, no trailing slashes, no spaces)
6. Click **Save Changes**
7. Trigger a manual redeploy (or wait for Render to auto-redeploy on env change)
8. Confirm ev-accounts is back up: `curl https://accounts.empowered.vote/health` should return 200

### Required Domains

Replace the placeholders below with the actual Netlify/custom URLs before cutover. Get these from Chris Andrews or the Netlify dashboard.



``
```

**Known production domains:**
- CompassV2: `https://compass.empowered.vote`
- Essentials: `https://essentials.empowered.vote`
- Read & Rank: `https://readrank.empowered.vote`
- Treasury Tracker: `https://treasurytracker.empowered.vote`

**Also include staging/preview URLs if doing staging verification first.** Netlify branch deploy and deploy preview URLs follow the pattern `https://deploy-preview-N--SITE-NAME.netlify.app`. Add these to CORS_ORIGIN during staging, then update again with just production domains before prod cutover (or keep both — extra origins are harmless).

CORS_ORIGIN=https://ctc.empowered.vote,https://civic-trivia-frontend.onrender.com,https://accounts.empowered.vote,https://ev-accounts.onrender.com,https://validation-quests-frontend.onrender.com,https://quests.empowered.vote,https://app.empowered.vote,https://profile.empowered.vote,https://accounts.empowered.vote,https://essentials.empowered.vote,https://compass.empowered.vote,https://readrank.empowered.vote,https://treasurytracker.empowered.vote,https://ev-compass.netlify.app,https://api.empowered.vote

**Format rules:**
- Comma-separated, no trailing slashes
- `https://` prefix required on every origin
- No wildcards (CORS_ORIGIN expects exact origins)

---

## Section 3: Netlify Dashboard Env Var Update

**Chris Andrews owns all four Netlify dashboards.** This step is his.

### Read & Rank — VITE_API_URL Required

Read & Rank uses **direct API calls** (no Netlify proxy) — unlike the other three apps which proxy through Netlify. This means the API base URL must be set as an environment variable in the Netlify dashboard, overriding the `.env.production` file in the repo.

**Steps for Chris Andrews:**

1. Log in to [Netlify](https://app.netlify.com)
2. Open the **read-rank** site
3. Go to **Site configuration** → **Environment variables**
4. Add or update: `VITE_API_URL` = `https://accounts.empowered.vote`
5. Click **Save**
6. Trigger a redeploy (or this will take effect on the next deploy from the PR merge)

### CompassV2, Essentials, Treasury Tracker — No Env Var Change Needed

These three apps use the Netlify proxy approach. The `netlify.toml` proxy rule forwards `/api/*` to `https://accounts.empowered.vote/api/:splat`. The browser sees same-origin requests, so `VITE_API_URL` is not needed in the Netlify dashboard for these apps.

The proxy change is in the code (`netlify.toml`) and takes effect when the PR is merged.

---

## Section 4: Pre-Cutover Staging Verification Checklist

Run through these checks on **staging deploys** before touching production. Use Netlify branch deploys or preview URLs for each app.

### Auth Hub

- [ ] Visit `https://accounts.empowered.vote/login?redirect=https://compass.empowered.vote`
- [ ] Confirm re-auth banner shows above the login form ("We've made some improvements...")
- [ ] Log in with valid Alpha credentials
- [ ] Confirm redirect lands on `https://compass.empowered.vote#access_token=...`
- [ ] Confirm `#access_token=` is present in the URL hash fragment (check browser address bar)
- [ ] Test signup: visit `/signup?redirect=https://compass.empowered.vote`, complete signup, confirm "Go to sign in" navigates to `/login?redirect=https://compass.empowered.vote`

### CompassV2

- [ ] Navigate to CompassV2 staging URL as unauthenticated user
- [ ] Confirm redirect to Auth Hub login with `?redirect=` pointing back to CompassV2
- [ ] Log in at Auth Hub
- [ ] Confirm redirect returns to CompassV2 with token in hash (`#access_token=...` in URL)
- [ ] Confirm CompassV2 loads authenticated state (user name shows, calibration/compare accessible)
- [ ] Walk through calibration flow: answer at least 3 questions → confirm saves
- [ ] Walk through compare flow: select a politician → confirm alignment score loads
- [ ] If you are an admin user: navigate to `/admin` → confirm admin dashboard loads
- [ ] Open browser **Network tab** → confirm ALL `/api/*` requests go to `accounts.empowered.vote` — zero requests to `api.empowered.vote`
- [ ] Open browser **Console** → confirm zero CORS errors

### Essentials

- [ ] Navigate to Essentials staging URL as unauthenticated user
- [ ] Confirm Sign In button is visible in the nav/header
- [ ] Click Sign In → confirm redirect to Auth Hub login with `?redirect=` pointing back to Essentials
- [ ] Log in → confirm redirect returns to Essentials with token in hash
- [ ] Confirm authenticated state loads (e.g., enhanced data, user-specific features)
- [ ] Run address search with a valid Indiana address → confirm results load
- [ ] Open browser **Network tab** → confirm zero `credentials: include` headers on any request
- [ ] Open browser **Console** → confirm zero CORS errors

### Read & Rank

- [ ] Navigate to Read & Rank staging URL as unauthenticated user
- [ ] Confirm sign-in link is visible and points to Auth Hub
- [ ] Log in at Auth Hub → confirm redirect back to Read & Rank with token in hash
- [ ] Confirm user is authenticated (name shows or verdicts are user-specific)
- [ ] Submit a verdict on a quote → confirm verdict syncs (no errors in network tab)
- [ ] Open browser **Network tab** → confirm `Authorization: Bearer` header on API calls
- [ ] Open browser **Console** → confirm zero CORS errors

### Treasury Tracker

- [ ] Navigate to Treasury Tracker staging URL
- [ ] Confirm no console errors on load
- [ ] Confirm static budget/treasury data loads correctly
- [ ] Open browser **Network tab** → confirm zero requests to `api.empowered.vote` or `ev-backend-h3n8`
- [ ] Open browser **Console** → confirm zero CORS errors
- [ ] (Optional) If logged in to another app: confirm Treasury Tracker picks up token from localStorage if implemented

---

## Section 5: Production Cutover Steps (In Order)

Execute these steps in sequence. Do not skip ahead.

**Step 1 — Confirm CORS_ORIGIN is ready (ED or Claude)**

Verify `CORS_ORIGIN` on the ev-accounts Render service includes all 4 production frontend domains. See Section 2. Do NOT proceed if any production domain is missing.

```
# Quick check: ask Claude to verify via Render or test a CORS preflight from a frontend domain
curl -I -H "Origin: https://compass.empowered.vote" https://accounts.empowered.vote/api/auth/me
# Should return: Access-Control-Allow-Origin: https://compass.empowered.vote
```

**Step 2 — Confirm Netlify VITE_API_URL is set for Read & Rank (Chris Andrews)**

Chris Andrews confirms `VITE_API_URL=https://accounts.empowered.vote` is set in Netlify → read-rank → Environment variables. See Section 3.

**Step 3 — Create or confirm PRs are ready (Claude)**

All 4 repos should have PRs with the auth migration changes. Confirm the following PRs are open and green (no CI failures):

- `EmpoweredVote/CompassV2` — 26 files migrated, netlify.toml updated
- `EmpoweredVote/essentials` — 10 files migrated, netlify.toml updated
- `EmpoweredVote/read-rank` — auth.ts + migrations + .env.production
- `EmpoweredVote/treasury-tracker` — netlify.toml + _redirects + dataLoader.ts

**Step 4 — ED final go/no-go**

ED reviews staging verification results and gives final approval to proceed with production merge.

**Step 5 — Merge all 4 PRs (Chris Andrews)**

Chris Andrews merges all 4 PRs. Merge them as close together as possible — ideally within a 1-2 minute window. Netlify auto-deploys on merge.

Order does not strictly matter since CORS is already set, but suggested order: CompassV2 → Essentials → Read & Rank → Treasury Tracker.

**Step 6 — Wait for all 4 Netlify deploys to complete**

Each Netlify deploy takes approximately 2-3 minutes. Chris Andrews monitors the deploy logs in the Netlify dashboard for each app. All 4 must show "Published" before proceeding to verification.

**Step 7 — Production verification**

Repeat the staging checklist (Section 4) on each app's **production URL**. Prioritize:
- Auth Hub redirect flow end-to-end
- CompassV2 login and calibration
- Essentials Sign In flow
- Read & Rank verdict sync
- Treasury Tracker loads without errors

**Step 8 — Post user communication (ED)**

ED posts the message in Section 8 to the Alpha user Discord/Slack channel.

---

## Section 6: Rollback Plan

**Trigger:** Any of the following within 30 minutes of cutover:
- User reports cannot log in
- 5+ consecutive auth failures in Render logs for ev-accounts
- CORS errors visible in browser across multiple users
- Netlify deploy failure on any of the 4 apps

**Rollback is fast because no database changes were made.** All changes are in env vars and netlify.toml.

### Rollback Steps

**Step R1 — Chris Andrews reverts VITE_API_URL for Read & Rank in Netlify dashboard**

Netlify → read-rank → Site configuration → Environment variables → delete or revert `VITE_API_URL` to `https://api.empowered.vote` (or the previous value).

**Step R2 — Chris Andrews reverts the PRs in all 4 repos**

For each of the 4 repos, create a revert PR (or force-push a revert to the branch) and merge it. Netlify auto-deploys on merge.

GitHub provides a "Revert" button on merged PRs. Clicking it creates a pre-filled revert PR.

Order: same as cutover — CompassV2 → Essentials → Read & Rank → Treasury Tracker.

**Step R3 — Wait for all 4 Netlify deploys to complete**

Same 2-3 minute wait. Verify each app shows "Published" in Netlify dashboard.

**Notes:**

- `CORS_ORIGIN` change on Render is harmless and does NOT need to be reverted. Adding new origins cannot break existing auth.
- Old Go server cookie sessions remain valid for their full TTL (typically several hours to days). Users who hadn't visited any app yet can still use old sessions after rollback.
- No database changes were made in Phase 40 — no DB rollback steps.
- The re-auth banner on Auth Hub login page can stay — it only renders when a `?redirect=` param is present, so it is invisible to users arriving directly.

**Estimated rollback time:** 5-10 minutes (dominated by Netlify deploy time).

---

## Section 7: Known Behavior Changes After Cutover

### 1. Forced Re-Login for All Users

All current sessions are cookie-based (Go server). Bearer tokens are stored in `localStorage`. These are completely separate session stores. There is no migration path.

**Effect:** Every user will see a login prompt on their first visit after cutover, regardless of whether they were previously logged in.

**Mitigation:** Re-auth banner on Auth Hub login page ("We've made some improvements — please log in again"). User communication in Discord/Slack before cutover.

### 2. CompassV2 Guest-Answer Migration Dropped

Before migration, `Register.jsx` included a `buildGuestState()` function that could migrate locally-stored anonymous quiz answers into the new user's account at registration time.

This function has been removed as part of the migration. Users who took the compass quiz anonymously before creating an account can no longer migrate those answers by re-registering.

**Impact:** LOW. The Alpha user base is small. Anonymous sessions rarely persist to account creation in practice.

### 3. display_name vs username

CompassV2 previously used `data.username` (Go server field). After cutover it uses `data.display_name` (ev-accounts field).

For all existing Alpha users, these values are identical — `display_name` in ev-accounts was populated from the same source during the v1.0 migration.

**Impact:** None expected. If a display name appears wrong for a specific user, the fix is a manual `display_name` update in the ev-accounts Supabase dashboard.

### 4. CompassV2 Register Page Redirects to Auth Hub

Users who navigate directly to `https://compass.empowered.vote/register` are now redirected to Auth Hub signup instead of seeing a local registration form.

**Impact:** None for UX — the signup experience is functionally the same. The redirect is transparent.

---

## Section 8: User Communication

**Timing:** Post to Discord/Slack approximately 30 minutes before the cutover window opens.

**Channel:** Alpha user Discord server or Slack channel (whichever is primary for Alpha communication).

**Who posts:** ED. Not Chris Andrews or Claude.

**Draft message:**

> We're updating our login system today. If you see a "please log in again" message, just sign in with your usual email and password — your data is safe. This is a one-time step.

**Optional extended version if users are active and may need more context:**

> We're rolling out an update to our login system across all Empowered Vote apps (Compass, Essentials, Read & Rank, Treasury Tracker). After the update, you'll see a prompt to log in once more — this is expected. Your account data, quiz answers, and verdicts are all safe. Just use your usual email and password and you'll be right back where you left off. If you run into any issues, let us know here.

**Note:** The re-auth banner on the Auth Hub login page handles in-app messaging for users who arrive without seeing the Discord message.

---

## Section 9: Post-Cutover Monitoring (1–3 Day Window)

Monitor actively for the first 3 days after cutover. This window gates Phase 42 (Go server decommission) — do not begin decommission until monitoring is clear.

### What to Watch

**Render logs for ev-accounts (`accounts.empowered.vote`):**
- Watch for spike in 401 responses → indicates token extraction or Bearer header attachment is failing
- Watch for CORS errors → indicates a frontend domain was missed in CORS_ORIGIN
- Watch for unusual 500 error rate → indicates an API incompatibility
- Access logs should show all 4 app domains as Origin headers

**Netlify deploy logs (Chris Andrews monitors):**
- Confirm all 4 deploys show "Published" and no build errors
- If a post-cutover PR is needed (hotfix), watch for redeploy success

**Browser console (spot-check with any user report):**
- CORS errors: `Access-Control-Allow-Origin` missing → CORS_ORIGIN env var gap
- 401 loops: repeated 401s → apiFetch token not attaching correctly
- `undefined` display names → display_name field is null in ev-accounts

**Go server traffic (Render logs for the Go server `api.empowered.vote`):**
- Go server request volume should drop dramatically immediately after cutover
- It will not reach zero immediately — users with pre-cutover sessions may hit the Go server until their sessions expire
- **Success signal:** Go server logs show zero traffic for 24 consecutive hours

### Decision Gate

When Go server logs are zero for 24 hours AND no user-reported auth issues in the monitoring window:

**Phase 42 (Decommission and DNS Cutover) is unblocked.**

Bring this to ED for final go/no-go before starting Phase 42.

---

## Section 10: Party Responsibilities

| Step | ED | Claude | Chris Andrews |
|------|----|--------|---------------|
| Code changes (plans 01–04) | Review | Write | Review PRs |
| CORS_ORIGIN Render update | Approve / Execute | Draft exact value, verify response headers | N/A |
| Netlify VITE_API_URL (Read & Rank) | N/A | N/A | **Execute in Netlify dashboard** |
| PR creation for all 4 repos | N/A | **Create PRs** | Review |
| Final go/no-go | **Decision** | Recommend | Provide readiness confirmation |
| Merge all 4 PRs | N/A | N/A | **Execute** |
| Staging verification | Test user flows | Verify Render logs, check network tab | Test user flows |
| Production verification | Test user flows | Verify Render logs | Confirm deploy success |
| User communication | **Post message** | Draft message | N/A |
| Post-cutover monitoring | Watch user reports | Watch ev-accounts API logs | Watch Netlify deploy logs |
| Go server traffic monitoring | N/A | **Check Render logs daily** | N/A |
| Phase 42 go/no-go (decommission) | **Decision** | Recommend (zero-traffic signal) | Confirm frontend side is clean |

---

## Appendix: Quick Reference

### CORS Preflight Test (verify CORS is set before merging PRs)

```bash
# Replace with actual production domain
curl -I -X OPTIONS \
  -H "Origin: https://compass.empowered.vote" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  https://accounts.empowered.vote/api/auth/me
# Expected: HTTP/2 200 or 204, Access-Control-Allow-Origin: https://compass.empowered.vote
```

### Go Server Traffic Check (post-cutover monitoring)

Check Render logs for the ev-backend service. Look for the volume trend on `/auth/me` and `/api/*` endpoints. A healthy trend shows a steep dropoff immediately after cutover, reaching zero within 24-48 hours as old sessions expire.

### Repo Locations (local development)

| App | GitHub | Local Path |
|-----|--------|------------|
| CompassV2 | EmpoweredVote/CompassV2 | `/c/EV-CompassV2` |
| Essentials | EmpoweredVote/essentials | `/c/Transparent Motivations/essentials` |
| Read & Rank | EmpoweredVote/read-rank | `/c/read-rank` |
| Treasury Tracker | EmpoweredVote/treasury-tracker | `/c/treasury-tracker` |
| ev-accounts (auth hub) | EmpoweredVote/ev-accounts | `C:/EV-Accounts` |
