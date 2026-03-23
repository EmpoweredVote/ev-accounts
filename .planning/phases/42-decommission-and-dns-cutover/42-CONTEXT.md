# Phase 42: Decommission and DNS Cutover - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Retire EV-Backend (Go server) and make `api.empowered.vote` resolve to the ev-accounts Express server. Includes: traffic gate verification, DNS flip, post-flip monitoring window, Go server scale-down, and CORS/env var audit. Does not include new feature work — this is a pure operational decommission.

</domain>

<decisions>
## Implementation Decisions

### Cutover Sequencing

- **Hard flip** — not staged/canary. All four frontends already point to ev-accounts directly (Phase 40), so DNS flip is largely symbolic. Alpha scale (<10 users) makes staged migration unnecessary overhead.
- **Pre-lower DNS TTL to 300 seconds** (5 min) **24 hours before the flip**. This ensures the flip propagates within 5 minutes and rollback is equally fast. Raise TTL back to 3600 after confirming stability.
- **Full sequence:**
  1. T-24h: Lower DNS TTL to 300s
  2. T-0: Verify zero application traffic in Render logs (24-hour window)
  3. Flip DNS: `api.empowered.vote` → ev-accounts Express
  4. Monitor ev-accounts for 4 hours
  5. If no new 5xx errors: scale Go server to zero on Render
  6. T+1 week: Archive Go GitHub repo

### Traffic Gate

- **Monitoring method:** Render logs on the Go server (no external monitoring needed at alpha scale)
- **Zero traffic definition:** Zero application-level requests — Render's own health check pings do NOT count
- **If traffic doesn't reach zero within 48 hours:** Investigate the source. If fixable (stale URL, forgotten integration), fix it and restart the 24-hour clock. If unresolvable (bot, crawler), flip anyway — don't hold the decommission indefinitely

### Rollback Readiness

- **Standby window:** Keep Go server running for **4 hours** post-flip before scaling to zero. This is the easy rollback window (just flip DNS back).
- **Rollback trigger:** Any new 5xx errors on ev-accounts routes that weren't present before the flip. Low bar — rollback is cheap while Go is still running.
- **Decision authority:** Chris is sole monitor and decision-maker during the post-flip window.
- After Go is scaled to zero, rollback becomes more complex (restart Go on Render + flip DNS) — avoid if possible by catching issues in the 4-hour window.

### CORS Configuration

- **Hardcode exact production domains** — no wildcard `*.empowered.vote`. List only the four production frontend origins explicitly.
- Exact domains need to be looked up from Render/DNS config (task for planner — check each frontend service's production URL)
- CORS config lives in ev-accounts Express `index.ts`

### Pre-Flip Checklist (Env Var Audit)

- Runbook must include a **formal checklist** to verify all four Render frontend services have no stale Go server URLs in their environment variables
- Check before flipping DNS — not ad-hoc

### Claude's Discretion

- Exact CORS domain list (look up from Render/existing code during planning)
- Health check endpoint implementation (`GET /api/health → {"status":"ok"}`)
- Exact runbook document format and structure

</decisions>

<specifics>
## Specific Ideas

- User confirmed this is an Alpha deployment with <10 accounts — operational complexity should match that scale (simple procedures, no fancy tooling)
- Staged/canary migration "makes sense for live services with lots of active concurrent users" — explicitly not our situation
- The 4-hour Go standby window is specifically because it's easy to flip DNS back while Go is still running; once scaled to zero, rollback gets harder

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 42-decommission-and-dns-cutover*
*Context gathered: 2026-03-23*
