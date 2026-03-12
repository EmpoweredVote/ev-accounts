# Project Research Summary

**Project:** v2026.3.4 Read & Rank Integration
**Domain:** Cross-app civic tech integration — standalone app extraction, cross-subdomain state sharing, quote verdict display
**Researched:** 2026-03-11
**Confidence:** HIGH

## Executive Summary

This milestone integrates an existing prototype (Read & Rank, currently buried in EV-prototypes on Netlify) into the production Empowered Vote platform as a first-class app at `readrank.empowered.vote`. The extraction itself is low-risk — the source code is complete, the stack is identical to the other EV apps, and Cloudflare Pages deployment follows an established pattern. The technically interesting work is the cross-app state bridge: users evaluate politician quotes on Read & Rank and expect those verdicts to surface when they visit politician profiles on Essentials. Since `readrank.empowered.vote` and `essentials.empowered.vote` are different browser origins, direct localStorage sharing is impossible by browser spec.

The recommended approach is layered: use the existing URL fragment bridge pattern (already proven in production for compass data) to hand off verdicts at point-of-navigation for guest users, while server-side storage in a new `compass.quote_verdicts` table handles logged-in users reliably across devices. This avoids introducing a new iframe relay subdomain and its associated complexity. The verdict data then surfaces in Essentials via an extended CompassContext that feeds a new `verdictsByTopic` prop to the existing `StanceAccordion` component — minimal UI surgery for meaningful per-politician profile value.

The top risks are infrastructure-level rather than product-level: forgetting to update CORS in the backend before deploying the new subdomain, missing the `.npmrc` in the extracted repo causing CI failures, and conflating the extraction commit with feature changes. All three are well-understood and easily avoided with a disciplined phase order: extract and deploy first with zero behavior changes, then layer in verdict integration, then add the logged-in server sync.

---

## Key Findings

### Recommended Stack

The existing stack requires no new runtime dependencies. React 19, Vite 7, Tailwind CSS 4, Zustand 5, Framer Motion 12, @use-gesture/react, and @dnd-kit are already in place. The only new infrastructure is two deployment artifacts (a `wrangler.toml` with SPA routing config and an `.npmrc` for GitHub npm registry access), one backend table (`compass.quote_verdicts`), and three backend endpoints. ev-ui needs a minor version bump to v0.1.42+ to carry verdict badge props on `StanceAccordion`.

**Core technologies:**
- Cloudflare Pages + `wrangler.toml`: static SPA deployment — same pattern as CompassV2 and Essentials; `not_found_handling = "single-page-application"` handles React Router routes
- `compass.quote_verdicts` table: server-side verdict storage keyed to `(user_id, quote_id)` — mirrors compass answers pattern exactly; Go GORM model with bulk upsert
- URL fragment bridge (`#compass=BASE64`): extended with a new `v` key for verdicts — reuses proven production mechanism; adds ~3.2KB to encoded URL, well under 8KB browser limit
- `guestVerdicts` localStorage key: written by Read & Rank, read by Essentials on profile load — mirrors `guestCompass` convention
- ev-ui `verdicts` prop on `StanceAccordion`: verdict badge display in politician profiles — bump to `^0.1.42`

**What NOT to add:** iframe postMessage relay (fragile, Safari ITP issues, unnecessary), BroadcastChannel (same-origin only — subdomains are different origins), third-party sync services, new PostgreSQL schema (verdicts belong in `compass.` alongside answers), `document.domain` manipulation (Chrome 115+ and Firefox 101+ fully deprecated this).

### Expected Features

**Must have (P1 — table stakes for this milestone):**
- Read & Rank standalone at `readrank.empowered.vote` — prerequisite for everything; without a clean URL there is no standalone product to integrate
- Visual refresh to match EV brand (ev-coral, ev-muted-blue, Manrope) — the prototype palette signals an experiment; the standalone product must be demoable
- Server-side verdict storage for logged-in users — reliable cross-app sharing via existing `.empowered.vote` session cookie; new `POST/GET /compass/verdicts` endpoints
- "You agreed/disagreed" badge inline on StanceAccordion for logged-in users — direct profile value; the verdict is the insight
- Guest verdict URL fragment bridge — guest continuity at point-of-navigation; mirrors existing compass bridge with `v` key added to fragment payload

**Should have (P2 — add after validation):**
- "Explore this topic on Read & Rank" deep-link from StanceAccordion with `?topic=` query param pre-selecting an issue
- Persistent guest verdict storage via iframe relay if user testing surfaces frequent session loss
- Retire URL fragment compass bridge once new mechanism is verified in production

**Defer (v2+):**
- Cross-device verdict sync for guests (requires account creation or device-linking)
- Verdict history view ("all quotes I evaluated for this politician")
- Progress indicator across all issues on Essentials profile

**Anti-features to avoid explicitly:** Real-time cross-tab sync (zero practical value), aggregated verdict analytics (contradicts the platform's anti-partisan mission — keep verdicts private and personal), full politician profile inside Read & Rank (duplicates Essentials), automatic verdict migration from EV-prototypes origin (impossible — different origin, no cookie sharing, zero user overlap).

### Architecture Approach

The integration is additive: the existing component boundaries in both apps are respected, new data flows through an extended CompassContext in Essentials, and the backend grows by one table and three endpoints that match established patterns. The verdict journey flows: Zustand store in Read & Rank serializes verdict decisions into the existing `#compass=` fragment payload as a new `v` key, Essentials `parseCompassFragment()` extracts it on profile load, CompassContext stores it alongside compass answers, CompassCard derives a `verdictsByTopic` map by fetching politician-scoped quotes from a new filtered endpoint, and StanceAccordion renders badges from that map.

**Major components:**
1. `ev-readrank` (new standalone repo) — extracted from `EV-prototypes/read-rank/`; BrowserRouter basename fixed to `/`; Vite base `"/"`; `wrangler.toml` for SPA routing; Zustand persist key renamed with migration
2. `compass.quote_verdicts` table + `/compass/verdicts` endpoints — server-side verdict CRUD; `(user_id, quote_id)` unique constraint; bulk upsert pattern matching compass answers; `QuoteVerdict` GORM model
3. Extended `CompassContext` (Essentials) — adds `verdicts` state field with load priority: fragment → localStorage (`ev_readrank_verdicts`) → API → empty; mirrors existing compass load chain
4. `CompassCard` + `StanceAccordion` (Essentials) — CompassCard fetches politician quotes via new `GET /essentials/quotes?politician_id=X`; derives `verdictsByTopic` map keyed by topic key; passes to StanceAccordion as new prop
5. `buildEssentialsUrl()` (Read & Rank) — serializes Zustand verdict state into fragment for "View on Essentials" CTA in ResultsPhase and CandidateAlignmentPage; only serializes verdict summary (`{ [quoteId]: verdict enum }`), not full progress tree

### Critical Pitfalls

1. **localStorage is origin-isolated — subdomains cannot share it directly** — Commit to the URL fragment bridge + backend architecture before writing any sharing code. Never test cross-subdomain state on localhost (false positive — all localhost ports share an origin). `document.domain` is deprecated and does not affect storage APIs in any modern browser.

2. **Missing `.npmrc` in new repo breaks CI on first build** — Copy `.npmrc` from EV-prototypes and set `NPM_TOKEN` as a Cloudflare Pages environment variable during extraction, not as a follow-up. Local installs pass silently due to `~/.npmrc`, masking the problem until CI runs.

3. **CORS not updated for new subdomain** — Add `readrank.empowered.vote` to `internal/middleware/middleware.go` in the same phase as Cloudflare deployment. API calls fail silently at the network layer while the UI renders fine; the failure mode is invisible until DevTools inspection.

4. **Renaming Zustand persist key silently resets all existing user state** — Implement `onRehydrateStorage` migration from old `readrank-storage` key to `ev_readrank` in the same commit as the rename. Never defer key migration. Test by seeding old key in DevTools and loading new build.

5. **ev-ui version divergence between extraction and production apps** — Read & Rank prototype pins `^0.1.6`; Essentials and CompassV2 are at `^0.1.41`. Update ev-ui to current version before extraction proceeds — peer dependency conflicts cause runtime errors with duplicate React instances.

6. **Visual redesign breaking swipe gesture logic** — Document which DOM elements carry `bind()` props from `@use-gesture/react` before any CSS work. Avoid `transform` or `overflow: hidden` on gesture container parents; gesture boundaries are calculated from the bound element's bounding rect.

---

## Implications for Roadmap

The dependency graph is clear and dictates phase order. Standalone extraction is the prerequisite for cross-app linking. Backend verdict endpoints are the prerequisite for the logged-in display path. The fragment bridge extension in Read & Rank depends on Essentials being able to receive and display verdicts. Three workstreams can run in parallel: (1) extraction + visual refresh, (2) backend verdict endpoints, (3) ev-ui update.

### Phase 1: Standalone Extraction + Deployment

**Rationale:** Everything downstream depends on having `readrank.empowered.vote` live. This phase has zero behavior changes — it is a structural move, not a feature. Keeping it isolated makes debugging trivial and gives a known-good baseline before integration begins. Conflating extraction with feature changes (anti-pattern 4 from ARCHITECTURE.md) is the most common cause of untraceable regressions in extraction work.
**Delivers:** `readrank.empowered.vote` serving the existing Read & Rank app; all three routes working (`/`, `/candidate/:id/alignment`, `/animation-options`); Cloudflare Pages CI passing.
**Addresses:** Standalone app accessibility (P1 table stakes feature)
**Must complete in this phase:** `.npmrc` added; `NPM_TOKEN` set in Cloudflare Pages env; `wrangler.toml` added with `not_found_handling = "single-page-application"`; BrowserRouter basename changed from `/read-rank/dist` to `/`; Vite base set to `"/"`; Zustand persist key renamed from `readrank-storage` to `ev_readrank` with `onRehydrateStorage` migration; ev-ui updated from `^0.1.6` to `^0.1.41`; `readrank.empowered.vote` added to CORS allowlist in `internal/middleware/middleware.go`.

### Phase 2: Visual Refresh (Read & Rank)

**Rationale:** Isolated to one repo with no cross-app dependencies. Can run in parallel with Phase 3. Must be a separate commit from Phase 1 — extraction first, verify it works identically to the prototype, then apply visual changes. This is the differentiator that makes the standalone product demoable.
**Delivers:** `readrank.empowered.vote` with EV brand design — ev-coral, ev-muted-blue, Manrope font, card-based layout; hub page, QuoteCard styling, ResultsPhase layout updated to match CompassV2/Essentials visual language. Swipe mechanics, store, and API integration unchanged.
**Addresses:** Visual refresh (P1 differentiator)
**Avoids:** Gesture regression — document `bind()` element boundaries before redesign begins; test on iOS Safari and Android Chrome device emulation after each card component change.

### Phase 3: Backend — Verdict Storage Endpoints

**Rationale:** Server-side verdict storage unlocks the logged-in path without any client-side cross-subdomain hacks. Can run in parallel with Phase 2. Must complete before the logged-in path in Phase 4 can be wired end-to-end.
**Delivers:** `compass.quote_verdicts` table (via AutoMigrate); `POST /compass/verdicts` (bulk upsert, authenticated); `GET /compass/verdicts` (authenticated); `GET /essentials/quotes?politician_id=X` (filtered, public — extends existing `GetQuotes` handler).
**Uses:** Existing GORM + Chi + SessionMiddleware pattern; `QuoteVerdict` model added to `internal/compass/models.go`; routes registered in `internal/compass/routes.go`. No new Go libraries.

### Phase 4: Verdict Integration in Essentials

**Rationale:** Depends on Phase 3 (backend API endpoints) and ev-ui `^0.1.42` (Phase 5, below). The fragment and localStorage paths can begin before Phase 3 lands, but the full logged-in path requires the backend. This is the primary user-facing value delivery.
**Delivers:** Extended `CompassContext` with `verdicts` state field; `parseCompassFragment()` extracting `v` key; `loadGuestVerdicts()` / `saveGuestVerdicts()` / `parseVerdictFragment()` / `fetchUserVerdicts()` utilities in `essentials/src/lib/`; `CompassCard` calling `GET /essentials/quotes?politician_id=X` and deriving `verdictsByTopic` map; `StanceAccordion` rendering agree/disagree/diamond/gold badges via new `verdictsByTopic` prop; ev-ui updated to `^0.1.42`.
**Addresses:** "You agreed/disagreed" badge on StanceAccordion (P1 feature); guest verdict URL fragment caching (P1 feature).

### Phase 5: ev-ui Verdict Badge Component

**Rationale:** Cross-repo dependency. Must be published before Phase 4 can consume the new prop. Fully independent of Phases 1-3 and can run in parallel with everything. Small, bounded change with no risk of regression in existing callers.
**Delivers:** ev-ui v0.1.42 published to GitHub npm registry; `StanceAccordion` accepts `verdictsByTopic` prop (`Record<topicKey, verdict>`); renders agree (green) / disagree (red) / diamond / gold badge inline in topic row when verdict is present; backward compatible — existing callers with no prop pass unchanged.

### Phase 6: Read & Rank — "View on Essentials" CTA and Fragment Serialization

**Rationale:** Completes the cross-app verdict journey by adding the entry point. Depends on Phase 4 being deployed — Essentials must be able to receive and display verdicts before Read & Rank is linked there. Relatively small amount of work: one utility function and one CTA component addition.
**Delivers:** `buildEssentialsUrl()` in Read & Rank serializing Zustand verdict state into `#compass=BASE64({..., v: verdicts})` fragment (verdict summary only — not full progress tree); "View on Essentials" CTA in ResultsPhase and CandidateAlignmentPage linking to `essentials.empowered.vote/politician/:slug`; `serializeCompassFragment()` in CompassV2 extended with `v` key for the return-banner path.
**Addresses:** Cross-app verdict hand-off; closes the guest verdict loop end-to-end.

### Phase 7: Logged-In Verdict Sync (Read & Rank → Backend)

**Rationale:** Lower priority than the guest path — most civic-research users are not logged in for their first evaluation session. Delivers cross-device persistence for the subset of logged-in users. Depends on Phase 3 (backend endpoints) and Phase 6 (Read & Rank integration is wired). Small amount of backend-call code in Read & Rank's session check.
**Delivers:** Read & Rank checks session cookie on load; if authenticated, POSTs current Zustand verdicts to `POST /compass/verdicts`; Essentials CompassContext loads verdicts from `GET /compass/verdicts` as highest-priority source for logged-in users (above fragment and localStorage).
**Addresses:** Server-side verdict storage for logged-in users (P1 feature — crosses the completion line when the logged-in sync path is wired end-to-end from Read & Rank through backend to Essentials display).

### Phase Ordering Rationale

- Phases 1 and 3 can run in parallel (different repos, different concerns — frontend extraction vs. backend endpoint additions).
- Phase 2 can run in parallel with Phase 3 (visual work in Read & Rank is independent of backend).
- Phase 5 (ev-ui) can run in parallel with all other phases; it is a prerequisite for Phase 4 but has no incoming dependencies.
- Phase 4 has a soft dependency on Phase 3 for the logged-in path; the fragment and localStorage paths can be implemented independently.
- Phase 6 depends on Phase 4 being deployed — Essentials must accept and display verdicts before Read & Rank links to it.
- Phase 7 is intentionally last — it is an enhancement to the core flow, not launch-blocking for the integration.

### Research Flags

Phases with well-documented patterns (standard — can skip `/gsd:research-phase`):
- **Phase 1:** All config changes confirmed from direct codebase inspection; Cloudflare Pages deployment pattern is identical to existing EV apps.
- **Phase 3:** `QuoteVerdict` model is a direct copy of the `CompassAnswer` model pattern; endpoint structure is confirmed from existing `internal/compass/` handlers. No novel patterns.
- **Phase 5:** ev-ui minor version bump following the established publish pattern. One optional prop following existing precedents on `CategorySection`.

Phases that may benefit from brief design review before implementation:
- **Phase 4:** The exact ev-ui `^0.1.42` badge component API (prop shape, verdict enum values, badge label text, color tokens) needs to be agreed between Phase 5 and Phase 4 before either begins implementation. A brief coordination step — not a full research phase.
- **Phase 6:** The `buildEssentialsUrl()` URL fragment size should be verified against the current quote count before implementation to confirm the payload stays under the 8KB browser URL length limit (current estimate: ~3.2KB encoded — within budget, but worth confirming against actual quote IDs).

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings from direct source code inspection of actual repos; no speculation. Cloudflare Pages pattern confirmed from official docs. No new libraries required. |
| Features | HIGH | Feature priorities derived from the existing codebase gaps and the explicit v2026.3.4 milestone scope in PROJECT.md. All referenced source files were directly inspected. |
| Architecture | HIGH | Build order and component boundaries derived from direct codebase inspection of all modified files. Data flow diagrams in ARCHITECTURE.md verified against actual component code. |
| Pitfalls | HIGH | Browser storage isolation verified via MDN spec. Zustand key pitfall verified from direct inspection of `useReadRankStore.ts`. CORS and `.npmrc` pitfalls verified from existing `middleware.go` and `netlify.toml` patterns. |

**Overall confidence:** HIGH

### Gaps to Address

- **ev-ui verdict badge component API design:** Research confirms that ev-ui needs a `verdicts` prop on `StanceAccordion` and that v0.1.42 is the target version, but the exact prop shape (how `verdictsByTopic` is typed, what badge variants are supported, what label text reads) needs coordination between Phase 4 and Phase 5 implementors before either begins. Not a research gap — a design coordination step.

- **`?topic=` deep-link IssueHub implementation (P2):** The IssueHub component structure was inspected but the query param handling for the "Explore on Read & Rank" deep-link was not fully specced. This is explicitly P2 scope and can be addressed during that phase's planning.

- **Guest persistent verdict storage (iframe relay):** Explicitly deferred to v1.x+. The gap is intentional — the URL fragment bridge covers the guest MVP path. If user testing after launch reveals guests frequently lose verdicts between sessions, the iframe postMessage relay at a shared subdomain (`shared.empowered.vote`) is the documented path forward. Do not pre-build it.

---

## Sources

### Primary (HIGH confidence)
- `EV-prototypes/read-rank/src/store/useReadRankStore.ts` — Zustand state shape, persist key `readrank-storage`, ev-ui `^0.1.6`, per-issue agree/disagree/badge data
- `EV-prototypes/read-rank/src/data/api.ts` — `fetchQuotesData()` consuming `GET /essentials/quotes`
- `essentials/src/contexts/CompassContext.jsx` — priority chain pattern (fragment > API > localStorage > empty), `guestCompass` key, fragment parse on mount
- `essentials/src/lib/compass.js` — `parseCompassFragment()`, `saveGuestCompass()`, fragment schema `{a, s, i}`
- `essentials/src/components/CompassCard.jsx` — dual fetch, StanceAccordion integration
- `essentials/src/components/StanceAccordion.jsx` — row structure, prop surface
- `CompassV2/src/components/ReturnBanner.jsx` — `serializeCompassFragment()` existing serialization pattern
- `EV-Backend/internal/essentials/handlers.go` — `GetQuotes` handler, `QuoteOut` struct, SQL pattern
- `EV-Backend/internal/essentials/routes.go` — existing route surface, `/quotes` GET endpoint
- `EV-Backend/internal/compass/models.go` — existing model pattern for `compass.` schema (CompassAnswer as QuoteVerdict template)
- Cloudflare Pages docs — `not_found_handling = "single-page-application"` in `wrangler.toml` confirmed
- MDN Web API: `Window.localStorage` — origin isolation per scheme+host+port confirmed
- MDN: Same-origin policy — `document.domain` does NOT affect storage APIs in modern browsers

### Secondary (MEDIUM confidence)
- npmjs.com: `framer-motion` 12.35.2 — latest version as of 2026-03-10
- Cloudflare Community — SPA routing 404 behavior and `_redirects` vs `wrangler.toml` placement distinction

---
*Research completed: 2026-03-11*
*Ready for roadmap: yes*
