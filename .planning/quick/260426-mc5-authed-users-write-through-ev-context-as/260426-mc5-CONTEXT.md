---
quick_id: 260426-mc5
status: ready_for_planning
date: 2026-04-26
---

# Quick Task 260426-mc5: Authed users write through ev-context as a cache - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Task Boundary

Make logged-in users mirror their writes (compass answers, address, read-rank verdicts) into the ev-context broker so they get the same instant cross-subdomain hydration that guests already enjoy. The API remains the source of truth — ev-context becomes a stale-while-revalidate (SWR) cache for authed users, not a write target of record.

**In scope:**
- New hook(s) in `@empoweredvote/ev-ui` that wrap the existing API call sites for the three named domains.
- Wiring those hooks into the four consumer apps: CompassV2, essentials, read-rank, treasury-tracker.
- userId-stamped payloads in ev-context so cached authed data can't leak across user switches.
- Logout handling that falls back to the guest slice without wiping it.

**Out of scope (this task):**
- Problem #1 (the "I signed up later" promotion prompt) — separate follow-up task.
- Mirroring anything beyond compass answers, address, verdicts (selected_topics, XP, gems, etc.).
- Backend changes — no new endpoints, no schema changes. ev-accounts is untouched.

</domain>

<decisions>
## Implementation Decisions

### Scope of mirroring
- **Only the three named domains: compass answers, address, read-rank verdicts.**
- Why: smallest blast radius, exactly the data that already hydrates cross-app UI. Selected topics, XP, gems, jurisdictions, and profile state are deferred — they have lower hydration value and bigger staleness risk.

### Reconciliation UX
- **Silent swap (SWR pattern).**
- Render cached data instantly on mount, then fetch from API in the background. When the API response arrives, replace the rendered data without notification, animation, or "updating…" indicator.
- API always wins on conflict. The cache is a hint, not a source of truth.

### userId stamping & logout
- **Stamp authed payloads with `userId`. Ignore on mismatch.**
- The ev-context payload schema gains a `userId` field (or per-key stamping — planner to decide concrete shape) on each authed write.
- On read: if stamped userId !== current userId, ignore the cached authed slice and fall back to API (or to the guest slice if logged out).
- On logout: do not wipe ev-context. The authed slice becomes inert (mismatched userId on next read), and the guest slice (unstamped, or stamped `null`) is what subsequent guest reads see.
- On user switch (rare): same mechanism — old stamped slice becomes inert; new user's first authed write overwrites it.
- Privacy note: stamped authed data sits in ev-context's iframe `localStorage` until overwritten. This is acceptable because it lives only on the user's own browser, and the data is the user's own non-sensitive civic preferences. No tokens, no PII beyond address.

### Where the logic lives
- **A hook (or small set of hooks) in `@empoweredvote/ev-ui`.**
- Tentative shape: `useEvContextCache({ key, fetchFromApi, writeToApi, isLoggedIn, userId })` — exact API shape is the planner's call.
- Each consumer app replaces its current "fetch from API on mount + POST on write" sites with this hook. This is a refactor of existing call sites, not a parallel new system.
- Centralizing in ev-ui means: one place to fix bugs, one place to evolve the schema, automatic propagation through the existing ev-ui auto-bump pipeline.

### Claude's Discretion
- **Concrete payload shape under `userId` stamping.** Whether to stamp at the top-level (`{ userId, compass, address, verdicts }`) or per-key (`{ compass: { userId, value }, ... }`). Planner picks based on what minimizes diff with existing ev-context contract and what `evContext.set()` merge behavior already does.
- **Hook granularity.** Single generic `useEvContextCache` vs. three domain-specific hooks (`useCompassCache`, `useAddressCache`, `useVerdictsCache`). Whichever produces clearer call sites in the consumer apps.
- **Order of consumer-app rollout.** Suggest CompassV2 first (highest-traffic compass writes) → essentials (already deepest ev-context integration per CLAUDE.md) → read-rank → treasury-tracker (read-only of address, smallest change).
- **Same-origin localStorage fallback.** Existing ev-context contract preserves a same-origin localStorage fallback for when the broker iframe is down. Keep that behavior intact for authed users too.

</decisions>

<specifics>
## Specific Ideas

- **Existing ev-context contract** (from CLAUDE.md):
  - `evContext.get()` → `{ compass, address, verdicts, ... } | null`
  - `evContext.set(value)` — merge writes; preserve other apps' top-level keys
  - `evContext.subscribe(cb)` — live updates from other tabs/subdomains
- **Existing promotion seam:** `promoteCompassImportDraft()` in `ev-accounts/backend/src/lib/compassService.ts:36-66` — runs on first authed `GET /compass/answers`, migrates a `compass_import_draft` from `connect.verification_sessions` into `inform.compass_responses`. This task does not modify that seam; it's the inverse direction (mirror authed-server-state into client cache).
- **Existing write endpoints (already in place, no changes needed):**
  - `POST /compass/answers` (compass answers)
  - `POST /compass/verdicts` (read-rank verdicts)
  - `POST /connect/set-location` (address)
- **Existing read endpoints:**
  - `GET /compass/answers`
  - `GET /compass/verdicts`
  - `/account/me` (returns location among other things — planner to decide whether to use this for address read or a more targeted endpoint)
- **Reference pattern:** essentials' existing `suggestedSaveAddress` flow (mentioned in CLAUDE.md) is the closest existing precedent for guest→authed data movement. Worth reading before designing the hook.

</specifics>

<canonical_refs>
## Canonical References

- `CLAUDE.md` — "Cross-subdomain shared state (ev-context)" section: usage contract, conventions, "When NOT to use it"
- `CLAUDE.md` — "Current Workstreams › ev-context follow-ups": the explicit follow-ups this task addresses (#2 of 4)
- `ev-accounts/backend/src/lib/compassService.ts` — `promoteCompassImportDraft()` (existing guest→authed seam, for context only)
- ev-context broker repo: `EmpoweredVote/ev-context` (already wired in CompassV2 and essentials CompassContext as of 2026-04-25)

</canonical_refs>
