# EV-Backend Decommission and DNS Cutover Runbook

**Prepared:** 2026-03-23
**Executor:** Chris Cantrell (ED)
**Phase:** 42 — Decommission and DNS Cutover

---

## Prerequisites

Before starting any step in this runbook, the following must be true:

- **Phase 40 complete:** All four Netlify frontends (CompassV2, Essentials, Read & Rank, Treasury Tracker) proxy API calls to `https://accounts.empowered.vote`. No frontend references the Go server.
- **Phase 41 complete:** Validation Quests and CTC trivia schemas are confirmed in the ev-accounts Supabase project. VQ and CTC service endpoints are live on ev-accounts.
- **ev-accounts Express API is serving production traffic** at `https://accounts.empowered.vote` without errors.

If any prerequisite is not met, stop and resolve before proceeding.

---

## Section 1: Pre-Flight Checklist (T-48h to T-24h)

Complete ALL of the following before proceeding to Section 2. Do not lower the DNS TTL until every box is checked.

- [ ] **Route 53 access confirmed** — Log into the AWS console. Navigate to Route 53 > Hosted zones. Confirm the `empowered.vote` hosted zone is visible and you have permission to edit records.

- [ ] **Render dashboard access confirmed** — Log into Render. Confirm you can see both the `ev-backend` service (Go server) and the `ev-accounts-api` service (Express server) with their logs and settings tabs accessible.

- [ ] **Add `api.empowered.vote` as a custom domain on ev-accounts (Render)**
  1. Render Dashboard > `ev-accounts-api` service > Settings > Custom Domains
  2. If `api.empowered.vote` is already listed with status "Verified" — check this box and continue
  3. If not listed: click "Add Custom Domain" > enter `api.empowered.vote` > follow Render's CNAME verification instructions
  4. Wait for Render to show status "Verified" (SSL certificate provisioned — can take a few minutes)
  5. **Do NOT proceed to DNS flip until this shows "Verified"** — Render must know to route traffic for this hostname before DNS points here, or requests will fail with SSL errors

- [ ] **Netlify frontend env vars clean** — Verify all four Netlify-hosted frontends have no stale Go server URLs:
  - CompassV2 — uses netlify.toml proxy, no `VITE_API_URL` env var needed
  - Essentials (Transparent Motivations) — uses netlify.toml proxy, no `VITE_API_URL` needed
  - Read & Rank — `VITE_API_URL` should be `https://accounts.empowered.vote` (not the Go server)
  - Treasury Tracker — uses netlify.toml proxy, no `VITE_API_URL` needed

- [ ] **CTC Render service env vars checked** — In the Render dashboard, open the CTC service environment tab. Note any `ev-accounts-api.onrender.com` references for post-cutover cleanup (not a blocker for the DNS flip — the internal Render URL stays live after flip, but should be updated as cleanup).

- [ ] **VQ Render service env vars checked** — In the Render dashboard, open the VQ frontend service environment tab. Note any `ev-accounts-api.onrender.com` references for post-cutover cleanup (same — not blocking).

- [ ] **ev-accounts health check passes**
  ```bash
  curl -s https://accounts.empowered.vote/api/health
  ```
  Expected response: `{"status":"ok","timestamp":"..."}`
  If this fails: stop and investigate before proceeding.

- [ ] **CORS preflight passes for all four production frontends**
  ```bash
  # Run for each domain below
  curl -I -X OPTIONS \
    -H "Origin: https://compass.empowered.vote" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Authorization" \
    https://accounts.empowered.vote/api/auth/me

  # Repeat for:
  #   -H "Origin: https://essentials.empowered.vote"
  #   -H "Origin: https://readrank.empowered.vote"
  #   -H "Origin: https://treasurytracker.empowered.vote"
  ```
  Each must return `Access-Control-Allow-Origin: https://[that-domain]` in the response headers.

All 7 items checked? Proceed to Section 2.

---

## Section 2: Lower DNS TTL (T-24h)

Lower the TTL on the `api.empowered.vote` DNS record 24 hours before the flip. This ensures that when you change the record value in Section 4, all resolvers pick up the new value within 5 minutes.

**Steps:**

1. Log into AWS Console > Route 53 > Hosted zones > click `empowered.vote`
2. Find the `api.empowered.vote` record (type A or CNAME)
3. Click the record to select it, then click "Edit record"
4. Change the TTL value from its current setting (likely `3600`) to `300`
5. Click "Save changes"
6. Note the timestamp when you saved: `___________`

**Verification:**
```bash
# Run from your local machine — should show TTL of 300 after propagation
dig api.empowered.vote | grep -A1 "ANSWER SECTION"
# Look for the TTL value in the second column of the answer line
```

**Wait 24 hours** (until the original TTL has expired everywhere) before proceeding to Section 3.

---

## Section 3: Traffic Gate Verification (T-0)

Before flipping the DNS record, verify that no application-level traffic is reaching the Go server. This confirms all frontends and integrations have already migrated to ev-accounts.

**Steps:**

1. Go to Render Dashboard > `ev-backend` service > Logs tab
2. Review the last 24 hours of logs
3. **Health check pings do NOT count** — Render sends requests to the health check path (`/`) approximately once per minute. If you see a steady stream of requests to `/` only, that is Render's own health monitoring. Ignore these.
4. **Application traffic would appear as requests to paths like:** `/auth/*`, `/compass/*`, `/essentials/*`, `/api/*`, `/politicians*`
5. If you see zero application-level requests in the last 24 hours → proceed to Section 4
6. If you see application-level traffic:
   - Identify the source (User-Agent header, IP, path pattern)
   - Fix the stale URL in the calling service
   - Restart the 24-hour clock — wait another 24 hours with zero traffic before flipping
   - If traffic persists for 48 hours and the source is unresolvable (bot, external crawler, unknown): proceed with the flip anyway — do not hold the decommission indefinitely for uncontrollable traffic

Traffic gate passes? Proceed to Section 4.

---

## Section 4: DNS Flip (T-0, after traffic gate passes)

Point `api.empowered.vote` to the ev-accounts Express service on Render.

**Steps:**

1. Log into AWS Console > Route 53 > Hosted zones > click `empowered.vote`
2. Find the `api.empowered.vote` record
3. Click "Edit record"
4. Update the record value to point to the ev-accounts Render service. Use the same target value that `accounts.empowered.vote` currently points to (typically a CNAME to the Render-provided hostname, e.g., `ev-accounts-api.onrender.com` as a CNAME target — **note:** this is the Render internal hostname used as DNS target, not exposed to users). You can look up the current `accounts.empowered.vote` target to confirm the exact CNAME value.
5. Leave TTL at `300` (do not change — you'll raise it in Section 7)
6. Click "Save changes"
7. Note the cutover timestamp: `___________`

**Wait 5 minutes** for TTL propagation, then verify:

**Verification — health check via new hostname:**
```bash
curl -s https://api.empowered.vote/api/health
```
Expected: `{"status":"ok","timestamp":"..."}`

If you get an SSL error or connection refused: the Render custom domain for `api.empowered.vote` may not be verified yet. Go back to Section 1 pre-flight item 3 and confirm Render shows "Verified" for this domain.

**Verification — CORS preflight via new hostname:**
```bash
curl -I -X OPTIONS \
  -H "Origin: https://compass.empowered.vote" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  https://api.empowered.vote/api/auth/me
```
Expected: `Access-Control-Allow-Origin: https://compass.empowered.vote`

Both checks pass? Proceed to Section 5.

**Rollback if either check fails:**
1. Go back to Route 53 > `api.empowered.vote` record
2. Revert the record value to the Go server's previous target value
3. Wait 5 minutes for propagation
4. Verify: `curl -s https://api.empowered.vote/api/health` — should return Go server health response
5. Investigate why ev-accounts failed before attempting the flip again

---

## Section 5: Post-Flip Monitoring (T-0 to T+4h)

Keep the Go server running for 4 hours after the DNS flip. This is the easy rollback window.

**What to watch:**

- Monitor Render Dashboard > `ev-accounts-api` service > Logs for 4 hours
- Watch for any HTTP 5xx errors on routes that were working before the flip
- Compare against baseline: 5xx errors on routes that were already broken pre-flip do not count

**Rollback trigger:**

Any new 5xx errors on previously-working routes that you cannot explain and fix within minutes. The rollback bar is deliberately low — while Go is still running, reverting is fast and cheap.

**Rollback procedure (during the 4-hour window):**

1. Route 53 > `empowered.vote` hosted zone > `api.empowered.vote` record
2. Revert the record value to the Go server's previous target
3. Click "Save changes"
4. Wait 5 minutes (TTL is 300s)
5. Verify: `curl -s https://api.empowered.vote/api/health` returns Go server response
6. Investigate and fix the ev-accounts issue before attempting another flip

**If the 4-hour window passes with no new 5xx errors:** Proceed to Section 6.

---

## Section 6: Scale Go Server to Zero (T+4h)

Only proceed if Section 5 monitoring passed (no new 5xx errors in 4 hours).

After scaling to zero, rollback becomes harder (requires restarting Go service on Render + DNS revert). Catch any issues in the 4-hour window to avoid this.

**Steps:**

1. Render Dashboard > `ev-backend` service > Settings tab
2. Look for a "Suspend service" option, or navigate to the Scaling section and set "Min instances" to `0`
   - On Render Starter plan: use "Suspend service" (stops the service without deleting it)
   - On Render Standard/Pro plans: set min instances to 0 under the scaling controls
3. Confirm the service status changes to "Suspended" or shows 0/0 instances
4. Note the suspension timestamp: `___________`

**Verification (Go server is down):**
```bash
curl -s --max-time 10 https://ev-backend-h3n8.onrender.com
# Expected: connection timeout or empty response (not a fast HTTP response)
```

**api.empowered.vote still works (ev-accounts is serving):**
```bash
curl -s https://api.empowered.vote/api/health
# Expected: {"status":"ok","timestamp":"..."}
```

Proceed to Section 7 at T+24h.

---

## Section 7: Raise DNS TTL (T+24h)

After 24 hours of stable operation with the Go server scaled to zero, restore the DNS TTL to a normal value.

**Steps:**

1. AWS Console > Route 53 > Hosted zones > `empowered.vote`
2. Find the `api.empowered.vote` record
3. Click "Edit record"
4. Change TTL from `300` to `3600`
5. Click "Save changes"

No verification needed — this is a performance optimization (reduces DNS lookup frequency), not a correctness change.

Proceed to Section 8 at T+1 week.

---

## Section 8: Archive Go Repo (T+1 week)

After one week with no issues and no need to refer back to the Go server source code:

**Steps:**

1. Log into GitHub
2. Navigate to the EV-Backend repository (the Go server source)
3. Settings tab > scroll to the "Danger Zone" section at the bottom
4. Click "Archive this repository"
5. Confirm the repository name when prompted
6. The repository is now read-only — all history is preserved, but no new commits can be pushed

**Note:** Archiving is reversible. If you ever need to unarchive, go to Settings > uncheck "Archive this repository".

---

## Section 9: Post-Cutover Cleanup (Non-Blocking)

These items are not required for the cutover to be complete, but should be done at leisure to keep environments tidy:

- **VQ Render service:** Update `VITE_ACCOUNTS_API_URL` env var from `https://ev-accounts-api.onrender.com` to `https://accounts.empowered.vote`. The old Render internal URL still routes correctly (Render keeps internal routing alive), but the canonical URL is cleaner.

- **CTC Render service:** Check for any `ev-accounts-api.onrender.com` env vars (noted in Section 1 pre-flight). Update each to `https://accounts.empowered.vote`.

- **trivia_service Supavisor registration (Phase 41 open blocker):** CTC is currently using the postgres superuser connection. To switch to the scoped `trivia_service` role:
  1. Supabase Dashboard > Database > Roles > find `trivia_service` > Reset Password. Choose a new strong password and store it in the team secret manager — never write it into this runbook or any file in the repo.
  2. Update CTC's `DATABASE_URL` to: `postgresql://trivia_service.kxsdzaojfaibhuzmclfq:<PASSWORD>@aws-0-us-west-1.pooler.supabase.com:5432/postgres`

- **Delete EV-Backend Render service (optional, T+1 month):** After one month with no issues and the GitHub repo archived, delete the `ev-backend` Render service entirely. This stops any Render billing for the suspended service if applicable.

---

## Requirements Satisfied

| Requirement | Section | Description |
|-------------|---------|-------------|
| CONS-20 | §1–§9 | Runbook covers full decommission sequence from pre-flight to archive |
| CONS-21 | §3 | Traffic gate verification before DNS flip — zero application-level request requirement |
| CONS-22 | §5 | 4-hour Go server standby window with documented rollback trigger and procedure |

---

*Phase: 42-decommission-and-dns-cutover*
*Decisions reference: .planning/phases/42-decommission-and-dns-cutover/42-CONTEXT.md*
*Prepared: 2026-03-23*
