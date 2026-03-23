# Phase 42: Decommission and DNS Cutover - Research

**Researched:** 2026-03-23
**Domain:** DNS cutover, Render service decommission, operational runbook
**Confidence:** HIGH (all findings from direct codebase inspection)

---

## Summary

This phase is a pure operational decommission — no feature code. The four Netlify frontends already proxy to `accounts.empowered.vote` (Phase 40 complete), so the DNS flip is largely symbolic: it makes `api.empowered.vote` resolve to the same Express server the frontends already hit. The primary work is: (1) traffic gate verification on the Go server, (2) adding `api.empowered.vote` as a custom domain on the ev-accounts Render service, (3) flipping the DNS record, (4) a post-flip monitoring window, and (5) Go server scale-down.

The codebase is clean of hardcoded Go server URLs in the ev-accounts backend and all four Netlify frontends. The CORS_ORIGIN env var on ev-accounts already includes `api.empowered.vote`, so no CORS change is needed post-flip. The only env var work is updating `app/.env.production` and `render.yaml` (the Render-hosted `/app` static site) which still reference the internal `ev-accounts-api.onrender.com` URL — these can be updated to `accounts.empowered.vote` as part of this phase's cleanup.

**Primary recommendation:** Add `api.empowered.vote` as a custom domain on the ev-accounts Render service (dashboard action, not code), flip the DNS record in Route 53, keep the Go server live for 4 hours post-flip as a rollback window, then scale to zero.

---

## Standard Stack

This phase is infrastructure-only — no npm packages to install. The relevant tooling:

### Core Operational Tools

| Tool | Purpose | Access Owner |
|------|---------|--------------|
| AWS Route 53 | DNS management for `empowered.vote` | Chris Cantrell (ED) |
| Render Dashboard | Service scaling and custom domain config | Chris Cantrell (ED) |
| Render Logs | Traffic gate verification | Claude (check) / ED (final call) |
| curl | CORS preflight and health check verification | Claude |

### DNS Provider: Route 53

**Source:** `PLATFORM-CONSOLIDATION.md` line 963 — "Update Route 53 DNS to point `api.empowered.vote` to the ev-accounts Render service"

Route 53 is the authoritative DNS provider for `empowered.vote`. The DNS flip requires:
1. Lowering the TTL on the `api.empowered.vote` A/CNAME record to 300s (T-24h)
2. Updating the record value to point to the ev-accounts Render service (T-0)
3. Raising TTL back to 3600 after stability is confirmed

**Note:** PLATFORM-CONSOLIDATION.md also mentions "Frontend Apps on Cloudflare Pages" for some apps, but that is the hosting platform, not the DNS provider. DNS for `empowered.vote` is Route 53.

---

## Architecture Patterns

### Current State (Confirmed by Code Inspection)

```
api.empowered.vote ──────────────────► ev-backend (Go) on Render
                                        Service name: ev-backend
                                        Legacy Render URL: ev-backend-h3n8.onrender.com

accounts.empowered.vote ─────────────► ev-accounts (Express) on Render
                                        Current Render URL: ev-accounts-api.onrender.com

All 4 Netlify frontends ─────────────► accounts.empowered.vote (via netlify.toml proxy)
```

### Target State (After Phase 42)

```
api.empowered.vote ──────────────────► ev-accounts (Express) on Render  [DNS flip]
accounts.empowered.vote ─────────────► ev-accounts (Express) on Render  [unchanged]

All 4 Netlify frontends ─────────────► accounts.empowered.vote (via netlify.toml proxy)  [unchanged]
ev-backend (Go) ─────────────────────► scaled to zero, then archived
```

### Netlify Proxy Status (Phase 40 Complete — Verified)

All four Netlify-hosted frontends already proxy to `accounts.empowered.vote`:

| App | netlify.toml proxy target | Status |
|-----|--------------------------|--------|
| CompassV2 (`/c/EV-CompassV2/netlify.toml`) | `https://accounts.empowered.vote/api/:splat` | Clean |
| Essentials (`/c/Transparent Motivations/essentials/netlify.toml`) | `https://accounts.empowered.vote/api/:splat` | Clean |
| Read & Rank (`/c/read-rank/netlify.toml`) | SPA redirect only, no API proxy — uses `VITE_API_URL` env var | Clean |
| Treasury Tracker (`/c/treasury-tracker/netlify.toml`) | `https://accounts.empowered.vote/api/:splat` | Clean |

No `ev-backend-h3n8.onrender.com` or `api.empowered.vote` references exist in any of these files.

### CORS Configuration (Already Correct)

**Source:** `additional_context` in phase input + confirmed in `backend/src/index.ts`

Current `CORS_ORIGIN` production value:
```
https://ctc.empowered.vote,https://civic-trivia-frontend.onrender.com,https://accounts.empowered.vote,https://ev-accounts.onrender.com,https://validation-quests-frontend.onrender.com,https://quests.empowered.vote,https://app.empowered.vote,https://profile.empowered.vote,https://essentials.empowered.vote,https://compass.empowered.vote,https://readrank.empowered.vote,https://treasurytracker.empowered.vote,https://ev-compass.netlify.app,https://api.empowered.vote
```

`api.empowered.vote` is already in the list. No CORS change is needed for the DNS flip. After the flip, `api.empowered.vote` resolves to ev-accounts itself — the origin header from any browser request will still be one of the listed frontend domains, not `api.empowered.vote`. This entry is harmless to keep.

### Go Server Render Service Details

**Source:** `C:/EV-Backend/render.yaml` + Phase 40 research

- Render service name: `ev-backend`
- Legacy direct URL: `https://ev-backend-h3n8.onrender.com`
- Custom domain: `api.empowered.vote`
- Health check path: `/` (root)
- `ALLOWED_ORIGINS` env var: `https://compass.empowered.vote,https://essentials.empowered.vote,https://api.empowered.vote`

Render's "Scale to Zero" feature (available on the dashboard for web services) stops the service without deleting it. This is the correct first decommission step — keeps rollback possible for one week before archive.

### Render Custom Domain: What Needs To Happen

The ev-accounts service currently has `accounts.empowered.vote` as a custom domain. To also serve `api.empowered.vote`, the Render dashboard must have `api.empowered.vote` added as a second custom domain on the ev-accounts web service **before** the DNS record is updated. Render validates domain ownership via a CNAME record during setup.

**Sequence:**
1. Add `api.empowered.vote` as a custom domain on ev-accounts in Render dashboard
2. Render provides a CNAME/A target (e.g., `[service-slug].onrender.com`)
3. Update Route 53: `api.empowered.vote` CNAME → Render's provided value
4. Render confirms domain active
5. Test: `curl https://api.empowered.vote/api/health` returns `{"status":"ok",...}`

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Traffic monitoring | Custom log parser | Render Dashboard logs (visual) | Alpha scale — eyeballing the log volume is sufficient |
| DNS change automation | Script | Route 53 console directly | One-time operation, no automation needed |
| Rollback automation | Script | Manual DNS revert in Route 53 | 4-hour window is short; manual is faster and safer |

---

## Common Pitfalls

### Pitfall 1: Adding Custom Domain to Render AFTER DNS Flip

**What goes wrong:** DNS propagates pointing `api.empowered.vote` to Render's servers, but Render doesn't yet know to serve traffic for that hostname. Requests get a 404 or SSL error.

**Why it happens:** Render validates custom domains before routing traffic to them. The domain must be registered in the Render dashboard first.

**How to avoid:** Add `api.empowered.vote` to the ev-accounts Render service **before** lowering TTL, definitely before flipping the DNS record.

**Warning signs:** `curl https://api.empowered.vote/api/health` returns SSL error or 404 immediately after flip.

### Pitfall 2: Health Check Pings Counted as "Traffic"

**What goes wrong:** Render's own health check pings the Go server's health endpoint, making log volume never reach zero.

**Why it happens:** Render sends health check requests to the configured path (`/` for Go server) on a regular interval.

**How to avoid:** Per the CONTEXT.md decision, zero traffic means zero **application-level** requests. Health check pings from Render to the Go server at `/` do NOT count. Look at the request paths — application traffic would be `/auth/*`, `/compass/*`, `/essentials/*`, etc.

**Warning signs:** If log volume is constant at exactly 1 req/minute with path `/` — that's the health check, not application traffic.

### Pitfall 3: Render Service Has Two Custom Domains — SSL for Both

**What goes wrong:** After adding `api.empowered.vote` as a second custom domain on ev-accounts, the SSL cert doesn't cover the new domain yet. HTTPS fails.

**Why it happens:** Render provisions SSL certificates per custom domain after the CNAME validates. This can take a few minutes.

**How to avoid:** After adding the domain in Render dashboard, wait for Render to show the domain as "Verified" before flipping DNS. Don't flip until SSL cert is provisioned.

### Pitfall 4: Stale Internal URL in `app/.env.production` and `render.yaml`

**What goes wrong:** The `/app` React app (at `profile.empowered.vote` and `app.empowered.vote`) still has `VITE_API_URL=https://ev-accounts-api.onrender.com` baked in. After the DNS flip, it still works (internal Render URL stays live), but it's stale and inconsistent.

**Why it happens:** These files weren't updated in Phase 40 because Phase 40 focused on Netlify frontends.

**How to avoid:** Update `app/.env.production` and `render.yaml` to use `https://accounts.empowered.vote` as part of this phase. These are the ev-accounts repo's own static app — easy to update in the same PR.

**Files to update:**
- `C:/EV-Accounts/app/.env.production` — line 1: `VITE_API_URL=https://ev-accounts-api.onrender.com`
- `C:/EV-Accounts/render.yaml` — line 9: `value: https://ev-accounts-api.onrender.com`

### Pitfall 5: Docs Reference Stale URLs

**What goes wrong:** Integration docs still tell CTC and VQ teams to use `ev-accounts-api.onrender.com`.

**Why it happens:** These docs were written before any custom domain existed.

**How to avoid:** Update the following docs as part of phase cleanup (low urgency but good hygiene):
- `docs/SMOKE-TEST-INTEG.md` — all `ev-accounts-api.onrender.com` curl examples
- `docs/ONBOARDING-VQ.md` — `ACCOUNTS_URL` env var example
- `docs/ONBOARDING-CTC.md` — `EMPOWERED_ACCOUNTS_URL` / `EMPOWERED_ACCOUNTS_API_URL` env var examples

### Pitfall 6: ev-backend `ALLOWED_ORIGINS` Includes `api.empowered.vote`

**What goes wrong:** After DNS flip, `api.empowered.vote` resolves to ev-accounts. If any client (unlikely) was relying on making CORS-authenticated requests to the Go server from a browser, the Go server would reject origins from the new ev-accounts service.

**Why it happens:** The Go server's `ALLOWED_ORIGINS` env var includes `api.empowered.vote` itself (confirmed in `EV-Backend/render.yaml`).

**How to avoid:** This is informational only — no browsers are calling the Go server after Phase 40. Not a blocking concern.

---

## Code Examples

### Health Check Verification

```bash
# Verify ev-accounts health (current working state)
curl -s https://accounts.empowered.vote/api/health
# Expected: {"status":"ok","timestamp":"..."}

# Verify api.empowered.vote AFTER DNS flip + Render domain registration
curl -s https://api.empowered.vote/api/health
# Expected: {"status":"ok","timestamp":"..."}
```

### CORS Preflight Verification

```bash
# Test that ev-accounts accepts requests from all four production frontends
# Run for each of the four domains before declaring health
curl -I -X OPTIONS \
  -H "Origin: https://compass.empowered.vote" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  https://accounts.empowered.vote/api/auth/me
# Expected: Access-Control-Allow-Origin: https://compass.empowered.vote
```

### DNS TTL Lowering (Route 53 Console)

Route 53 → Hosted zones → `empowered.vote` → Find `api.empowered.vote` record → Edit → Change TTL to `300`. Save. Wait 24 hours for old TTL (typically 3600s) to expire before flipping the value.

### Render Scale to Zero

Render Dashboard → ev-backend service → Settings → Scaling → set "Min instances" to 0 (or use "Suspend service" if available on the plan). This stops the service without deleting it.

---

## Env Var Audit Checklist

The CONTEXT.md requires a formal pre-flip checklist for all Render frontend services. Here is the full audit based on codebase inspection:

### Netlify Frontends (4 apps — Chris Andrews's dashboard)

| App | Env Var to Check | Current Value (Phase 40) | Expected for Phase 42 |
|-----|-----------------|-------------------------|----------------------|
| CompassV2 | No `VITE_API_URL` env var needed | N/A (uses proxy) | No change |
| Essentials | No `VITE_API_URL` env var needed | N/A (uses proxy) | No change |
| Read & Rank | `VITE_API_URL` | `https://accounts.empowered.vote` | No change |
| Treasury Tracker | No `VITE_API_URL` env var needed | N/A (uses proxy) | No change |

All four apps already point away from the Go server. No Netlify env var changes required.

### Render-Hosted Apps (ev-accounts repo)

| Service | File / Env Var | Current Value | Action |
|---------|---------------|---------------|--------|
| `empowered-vote-app` static | `render.yaml` VITE_API_URL | `https://ev-accounts-api.onrender.com` | Update to `https://accounts.empowered.vote` |
| `empowered-vote-app` static | `app/.env.production` | `https://ev-accounts-api.onrender.com` | Update to `https://accounts.empowered.vote` |

### Validation Quests (Render — Chris Andrews / VQ team)

| Service | Env Var | Current Value | Action |
|---------|---------|---------------|--------|
| `validation-quests-frontend` | `VITE_ACCOUNTS_API_URL` | `https://ev-accounts-api.onrender.com` | Inform VQ team to update (or update now) |

**Source:** `C:/Validation Quests/render.yaml` — `VITE_ACCOUNTS_API_URL: https://ev-accounts-api.onrender.com`

This is informational — `ev-accounts-api.onrender.com` continues to work after the DNS flip (Render's internal URL stays live). But it's stale. Best updated during this phase as part of the cleanup sweep.

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|-----------------|-------|
| `api.empowered.vote` → Go server | `api.empowered.vote` → ev-accounts Express | Phase 42 makes this change |
| All frontends proxied through Go | All frontends call ev-accounts directly | Phase 40 complete |
| `ev-backend-h3n8.onrender.com` in netlify.toml | `accounts.empowered.vote` in netlify.toml | Phase 40 complete |

---

## Open Questions

1. **Route 53 console access**
   - What we know: Route 53 is the DNS provider (from PLATFORM-CONSOLIDATION.md)
   - What's unclear: Chris Cantrell is the owner, but we cannot verify Route 53 account access before the session
   - Recommendation: Runbook must include explicit step — "ED confirms Route 53 access before T-24h"

2. **Render custom domain: is `api.empowered.vote` already added to ev-accounts?**
   - What we know: `accounts.empowered.vote` is a confirmed custom domain on ev-accounts. `api.empowered.vote` is NOT in the codebase as a known ev-accounts custom domain.
   - What's unclear: Whether Chris may have added it manually to Render dashboard already (can't be verified via code)
   - Recommendation: Runbook must include a step to check Render dashboard for existing custom domains on ev-accounts before attempting to add `api.empowered.vote`

3. **Render plan: does ev-accounts have "Scale to Zero" for the Go server?**
   - What we know: `ev-backend/render.yaml` uses `plan: starter`
   - What's unclear: Starter plan may have limitations on manual scaling controls
   - Recommendation: Planner should note that "scale to zero" may mean "suspend service" in Render dashboard depending on plan. The runbook should include both options.

4. **CTC frontend — does it have any `api.empowered.vote` references?**
   - What we know: The CTC frontend repo is not locally present at a standard path. `ev-accounts-api.onrender.com` is the URL CTC uses (per ONBOARDING-CTC.md)
   - What's unclear: Whether CTC's Render service has any stale env vars pointing to the Go server
   - Recommendation: Runbook checklist should include a note for ED to verify CTC's Render service env vars manually (not blocking for DNS flip, but good hygiene)

---

## Sources

### Primary (HIGH confidence)

- Direct inspection of `C:/EV-CompassV2/netlify.toml` — proxy target confirmed
- Direct inspection of `C:/read-rank/netlify.toml` — no API proxy, uses VITE_API_URL
- Direct inspection of `C:/treasury-tracker/netlify.toml` — proxy target confirmed
- Direct inspection of `C:/Transparent Motivations/essentials/netlify.toml` — proxy target confirmed
- Direct inspection of `C:/EV-Accounts/backend/src/index.ts` — CORS config pattern
- Direct inspection of `C:/EV-Backend/render.yaml` — Go server service name and ALLOWED_ORIGINS
- Direct inspection of `C:/EV-Accounts/render.yaml` — ev-accounts app env var
- Direct inspection of `C:/EV-Accounts/app/.env.production` — stale internal URL confirmed
- Direct inspection of `C:/Validation Quests/render.yaml` — VQ frontend VITE_ACCOUNTS_API_URL
- `PLATFORM-CONSOLIDATION.md` line 963 — Route 53 as DNS provider

### Tertiary (LOW confidence — single doc source)

- Route 53 as DNS provider: sourced from PLATFORM-CONSOLIDATION.md only (Chris Andrews's doc). Cannot verify via Route 53 console from here. Treat as presumed-correct, confirm with ED before T-24h.

---

## Metadata

**Confidence breakdown:**
- Netlify proxy status (Phase 40 done): HIGH — direct file inspection, zero Go server URLs found
- Go server Render service name: HIGH — from `EV-Backend/render.yaml`
- DNS provider (Route 53): LOW — single document source, not independently verified
- CORS config: HIGH — read from `backend/src/index.ts` and confirmed env var value in phase context
- Stale env var refs: HIGH — direct file inspection of `app/.env.production`, `render.yaml`, `Validation Quests/render.yaml`
- Docs requiring update: HIGH — direct file inspection of `docs/SMOKE-TEST-INTEG.md`, `ONBOARDING-*.md`

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (infrastructure stable, no moving parts)
