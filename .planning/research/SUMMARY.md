# Project Research Summary

**Project:** Empowered Vote — Quality & Consolidation Milestone
**Domain:** Civic engagement platform (multi-app, guest-first quiz + politician discovery)
**Researched:** 2026-02-17
**Confidence:** HIGH

## Executive Summary

Empowered Vote is a brownfield civic engagement platform with a working Go + React stack. This milestone is not greenfield — it is six targeted improvements to an existing, deployed product: guest-first quiz access, compass topic prompts, stance randomization, candidate display, building imagery, and project consolidation. All four research dimensions agree on a central finding: none of these improvements require new runtime dependencies or architectural pivots. The existing stack (Go/Chi/GORM, React 19/Vite/Tailwind, Supabase PostgreSQL) handles every requirement, and the right moves are additive data model changes, localStorage-first state patterns, and an incremental monorepo migration.

The recommended approach is sequenced by dependency, not by feature complexity. The cookie domain fix and route audit must ship first — before any guest auth work — because existing sessions can be silently broken if cookie config changes alongside the auth model. Once that blocker is resolved, the guest-first auth flow unlocks stance randomization (both share the same guest identity/seed pattern), while topic question fields and candidate display can proceed in parallel on the backend. Building images are a low-risk late-milestone item. Consolidation to npm workspaces is a developer experience improvement, not a user-facing feature, and should be the first structural change so parallel dev streams benefit from the reduced ev-ui publish friction.

The primary risk cluster is data integrity during the auth model transition and candidate data handling. Guest state must be explicitly synced on registration (not silently dropped), candidate records must be visually and data-model separated from incumbent records, and any schema changes on live tables must use explicit SQL migrations with backfills rather than relying on GORM AutoMigrate alone. For a 2-3 person team on a nonprofit civic platform, sequencing is the discipline: finishing shared dependencies (auth layer, data model) before dependent features begin is more important than parallelizing everything.

## Key Findings

### Recommended Stack

No new runtime dependencies are required for any of the six improvement areas. The existing Go 1.24.3/Chi/GORM backend, React 19/Vite/Tailwind CSS 4 frontends, and Supabase PostgreSQL handle all requirements. Supabase Storage (already the database provider) handles building images at $0 marginal cost via public bucket URLs. For project structure, npm workspaces at the repo root eliminates the ev-ui publish cycle without adding new tooling. Turborepo, Auth0, Clerk, React Query, and TypeScript migration are all explicitly out of scope for this milestone — each introduces overhead disproportionate to a 2-3 person team.

**Core technologies (unchanged):**
- Go + Chi + GORM: API backend — no changes; all new features are additive endpoints and schema columns
- React 19 + Vite + Tailwind CSS 4: frontend — no version upgrades needed mid-milestone
- Supabase PostgreSQL: database — AutoMigrate for dev convenience, explicit SQL migrations for live-table changes
- Supabase Storage: building images — public bucket, direct `<img src>` with no SDK required
- npm workspaces: project consolidation — local ev-ui symlink replaces publish cycle, medium confidence

**Critical version note:** Vite version skew exists (CompassV2 on 6.x, essentials on 7.x). Do not attempt to reconcile during this milestone; it creates unnecessary risk.

### Expected Features

Research across iSideWith, Vote Compass, Ballotpedia, Center for Civic Design, and Guides.vote identifies clear table-stakes patterns that EV is missing and differentiators worth building now vs. deferring.

**Must have (table stakes):**
- Guest quiz without login — all high-traffic political quiz platforms (iSideWith, Vote Compass, Pew Typology) run without auth gates; this is the primary conversion driver
- localStorage answer persistence for returning guests — users expect their answers to survive tab close
- Post-completion save prompt, not pre-quiz login gate — the login wall before quiz results is the primary conversion killer
- Permanent per-user stance ordering — re-randomizing on each visit confuses returning users; the order must be stable once set
- Clear visual distinction between candidates and officeholders — mixing them in one undifferentiated list is a misinformation risk on a civic platform
- Opt-in candidate toggle (default: officials only) — candidates are noisier data; users' primary need is "who represents me now"
- Three-tier government navigation (Federal/State/Local) with correct priority ordering — standard across all voter guide platforms

**Should have (competitive differentiators):**
- Seamless guest-to-account merge (localStorage state promoted to server on registration)
- Question/prompt field above each stance issue (gives context when stances arrive in non-default order)
- Building/landmark imagery per government tier (U.S. Capitol, state capitols, actual local city halls)
- Election date shown on candidate cards
- Federal category ordering: President/VP → Senate → House → Cabinet/Agencies (currently reversed)

**Defer to v2+:**
- Issue-level importance weighting (iSideWith does this; significant complexity, skip for now)
- Shareable result links encoding quiz seed in URL
- Issue level indicators on compass topics (requires `level` enum on Topic model + admin UI — additive but not blocking)
- Full unified SPA (separate apps remain separate for this milestone)
- Supabase politician image proxy (only if BallotReady CDN URLs prove unstable)

### Architecture Approach

The target architecture is additive: new fields on existing models, new endpoints alongside existing ones, and localStorage as the primary persistence layer for guest state. No existing interfaces change meaning — all new fields use `omitempty` for backward compatibility and backend deploys precede frontend deploys. The guest auth flow uses a well-established pattern (localStorage state included as `guest_state` in the register/login request body, cleared on success) with server-wins merge strategy when a returning user already has server-side answers.

**Major components:**
1. **CompassContext (React)** — Always persists answers/topics/inversions/seed to localStorage regardless of auth state; syncs to server only when authenticated
2. **EV-Backend /auth handlers** — Accept optional `guest_state` body on register/login; write guest answers in a single transaction; return `stance_seed` on `/auth/me`
3. **EV-Backend /compass/topics** — Extended with nullable `question TEXT` column; `omitempty` in DTO; no regression for existing consumers
4. **EV-Backend /essentials/candidates/{zip}** — New endpoint querying `election_records JOIN politicians` for upcoming elections; returns `CandidateOut` DTO with race context
5. **essentials Dashboard (React)** — Officials/Candidates toggle; visual differentiation via badge/label on candidate cards
6. **npm workspace root** — Symlinks `packages/ev-ui` so consuming apps get changes without publish cycle

**Key patterns:**
- Backend deploys first (new nullable fields), frontend deploys second (reads new field with fallback)
- Guest identity: localStorage UUID (`ev_stance_seed`, `ev_guest_answers`) synced to `app_auth.users.stance_seed` on registration
- Candidate data: separate query path from officeholder data; never upsert candidate records over incumbent records

### Critical Pitfalls

1. **Cookie domain must be fixed before any auth model changes** — The `.empowered.vote` cookie domain is currently omitted for cross-domain dev (noted in CLAUDE.md). If cookie config changes simultaneously with the guest auth rollout, existing logged-in users can be silently logged out. Fix the cookie domain in a standalone deploy first, verify session continuity across browsers, then begin guest auth work.

2. **Guest state merge must be explicit, not assumed** — The most common failure in guest-to-auth flows is that merge never actually happens: the backend creates a new session, the frontend reads localStorage, but no sync POST is made. Design the `guest_state` payload in the register/login request body from day one and test the merge path explicitly. The "server wins" merge strategy (server answers take precedence over local answers for returning users) prevents data clobbering.

3. **Candidate data must not overwrite incumbent data** — BallotReady returns both officeholders and candidates. If the upsert logic uses `external_id` as the conflict key without a type discriminator, a candidate record can clobber the sitting politician's office title, district, or contact data. Treat candidates as a separate data entity with their own record type or discriminator; candidacy data enriches but does not replace officeholder data.

4. **Schema changes on live tables need explicit SQL migrations, not AutoMigrate alone** — GORM AutoMigrate adds columns but does not backfill existing rows. Adding `question TEXT` or `stance_seed TEXT` via AutoMigrate leaves existing rows with NULL; if the frontend or Go struct assumes the field is always present, API responses break for old records. Use AutoMigrate for dev convenience, write explicit migration scripts for production, and mark new fields as `omitempty` in JSON until all rows are backfilled.

5. **Parallel work streams on shared files cause merge conflicts** — With 2-3 developers, concurrent branches touching `internal/auth/`, `CompassContext.jsx`, and `ev-ui` simultaneously produce unmanageable conflicts. Sequence milestones so shared dependencies (auth layer, data model columns) merge to main before dependent features begin. Treat `ev-ui` and `internal/auth/` as shared infrastructure requiring explicit team sign-off before merge.

## Implications for Roadmap

Based on combined research, the dependency graph is clear. Cookie domain fix is a non-negotiable prerequisite. Monorepo migration is a developer tooling improvement that benefits all subsequent work. Guest auth unlocks stance randomization. Topic question fields and candidate display can proceed in parallel once the data model groundwork is laid. Building images are independent and low-risk.

### Phase 1: Cookie Domain Fix and Route Audit
**Rationale:** Pitfall #4 and #15 are explicit blockers. Any auth model change that ships before the cookie domain is resolved risks silently logging out existing users. This is a 1-2 hour backend change that must land and be verified in production before any other auth work begins. The route audit (documenting which Chi routes are public/guest-ok/auth-required) is the planning artifact that prevents Pitfall #3.
**Delivers:** Production-safe cookie config; route manifest documenting auth levels per endpoint
**Avoids:** Pitfalls 3, 4, 15 (session collision, route exposure, cross-subdomain auth breakage)

### Phase 2: Monorepo Migration (npm Workspaces)
**Rationale:** ARCHITECTURE.md recommends doing this first to unblock parallel work. Once ev-ui is a local workspace package, all subsequent phases that touch shared components (PoliticianCard for candidate badges, any new ev-ui exports) get changes immediately without a publish cycle. This is a structural change with no user-visible impact — the right time is before feature work begins.
**Delivers:** Single `npm install` at root; ev-ui as local symlink; shared dev dependencies hoisted; Netlify per-app build configs updated
**Avoids:** Pitfalls 13, 16 (ev-ui version skew, NPM_TOKEN breaking in CI)
**Research flag:** Standard npm workspaces pattern — skip phase research, follow ARCHITECTURE.md implementation steps directly

### Phase 3: Guest-First Auth + Stance Seed
**Rationale:** Guest auth is the highest-impact user-facing change (it removes the primary conversion blocker per FEATURES.md). Stance seed is architecturally coupled — both use the same guest identity pattern (`ev_stance_seed` in localStorage, `stance_seed` on the user record) and the seed is included in the `guest_state` sync payload on registration. They should be a single phase to avoid building the guest identity twice.
**Delivers:** Full quiz access without login; localStorage-persisted answers for guests; permanent per-user stance randomization; guest-to-account merge on registration
**Addresses:** Must-have table stakes (guest quiz, localStorage persistence, post-completion save prompt)
**Implements:** CompassContext localStorage-first pattern; `/auth/register` and `/auth/login` `guest_state` handling; `stance_seed` field on user model; deterministic Fisher-Yates shuffle in `util/`
**Avoids:** Pitfalls 1, 2, 9, 10 (merge never happens, no guest identity, non-reproducible seed, biased shuffle)
**Research flag:** Well-documented pattern — skip phase research. Use ARCHITECTURE.md Section 1 (guest auth) and Section 3 (stance randomization) as implementation spec.

### Phase 4: Topic Question Field
**Rationale:** Independent of auth (no shared dependencies with Phase 3) and can be executed in parallel by a second developer. However, it is a prerequisite for the stance randomization UX to make sense — users need the question/prompt for context when stances arrive in a non-default order. FEATURES.md explicitly notes this dependency. Schema migration is safe (nullable column, AutoMigrate in dev, explicit SQL for production, `omitempty` in DTO).
**Delivers:** `question TEXT` column on `compass.topics`; question rendered above stance options with `title` fallback; admin UI textarea for question input
**Addresses:** "Should have" differentiator (question/prompt above issue)
**Avoids:** Pitfalls 5, 6 (non-nullable field breakage, field meaning change)
**Research flag:** Standard additive schema change — skip phase research.

### Phase 5: Candidate Display in Essentials
**Rationale:** BallotReady candidacy data is already fetched and stored (Phase B complete per CLAUDE.md). The remaining work is the query path, DTO, and frontend toggle. This is a medium-complexity phase because of the data integrity risks (Pitfalls 7, 8, 11, 12). It should not run in parallel with Phase 3 if the same developer is working on both — concurrent changes to `internal/essentials/` and `internal/auth/` create conflict risk.
**Delivers:** `GET /essentials/candidates/{zip}` endpoint; Officials/Candidates toggle in Dashboard; candidate badge/label on PoliticianCard; `CandidateOut` DTO with race context (office sought, election date)
**Addresses:** Table-stakes candidate display (clear visual distinction, opt-in toggle, election date shown)
**Implements:** Separate query path (election_records JOIN politicians); type discriminator to prevent overwriting incumbent data; shorter TTL for candidate cache (7-14 days vs 90-day incumbent TTL)
**Avoids:** Pitfalls 7, 8, 11, 12 (candidate overwrites incumbent, stale candidates, visual conflation, missing race context)
**Research flag:** Medium complexity due to data integrity requirements. Recommend a short research phase to confirm the district-to-ZIP mapping query for candidates (different from the officeholder path) and to validate BallotReady candidacy data freshness.

### Phase 6: Federal Category Reordering + Building Imagery
**Rationale:** Two independent, low-risk frontend items. Federal reordering is a constant change in `classify.js` — zero backend changes, zero risk. Building imagery is a static asset curation task with straightforward Supabase Storage implementation. Both improve the government navigation UX per FEATURES.md recommendations. Group them to avoid a trivial single-item phase.
**Delivers:** Federal section ordered President/VP → Senate → House → Cabinet/Agencies; building images (U.S. Capitol, state capitols, Bloomington City Hall, LA City Hall) served from Supabase Storage public bucket; graceful `onError` fallback on all politician images
**Addresses:** "Should have" differentiators (building imagery, correct category priority ordering); image expiry resilience
**Avoids:** Pitfalls 17, 18 (inconsistent image aspect ratios, BallotReady image 404s)
**Research flag:** Standard implementation — skip phase research. Use STACK.md Section 5 for Supabase Storage setup.

### Phase Ordering Rationale

- **Cookie fix before auth (Phase 1 before 3):** Explicit blocker from PITFALLS.md — cannot safely change auth model with broken cookie config
- **Monorepo before features (Phase 2 before 3-6):** Removes the ev-ui publish friction that slows all subsequent phases; structural change with no user-visible risk
- **Guest auth before stance seed (combined in Phase 3):** Seed is part of the guest identity; building them separately would require refactoring the guest state schema twice
- **Question field parallel to guest auth (Phase 4 alongside 3):** No shared code or schema dependencies; safe for a second developer to run simultaneously
- **Candidates after auth (Phase 5 after 3-4):** Prevents concurrent changes to `internal/essentials/` and `internal/auth/` from the same developer; also ensures the candidate card visual design can reference the same `PoliticianCard` patterns established during guest auth work
- **Building images last (Phase 6):** Zero blocking dependencies; deferring keeps the critical path uncluttered; asset curation work can proceed asynchronously while Phase 5 is in progress

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 5 (Candidates):** District-to-ZIP mapping query for candidates is not the same as the officeholder path (officeholders have confirmed districts; candidates have prospective districts). Validate query approach against actual BallotReady candidacy data schema before implementation begins.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Cookie fix):** Documented configuration change in CLAUDE.md — no research needed
- **Phase 2 (Monorepo):** npm workspaces is a well-documented pattern; ARCHITECTURE.md Section 6 provides step-by-step migration
- **Phase 3 (Guest auth + seed):** ARCHITECTURE.md Sections 1 and 3 serve as implementation spec; pattern matches Shopify cart merge and Google Docs anonymous → signed-in flows
- **Phase 4 (Question field):** Additive schema migration with established AutoMigrate + explicit SQL approach
- **Phase 6 (Federal order + images):** Frontend constant change + Supabase Storage public bucket; no research needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All six improvement areas explicitly assessed against existing stack; zero new dependencies identified; versions current |
| Features | HIGH | Cross-referenced against iSideWith, Vote Compass, Ballotpedia, Center for Civic Design, Guides.vote; table stakes vs. differentiators well-supported |
| Architecture | HIGH | Component boundaries, data flows, and build orders are specific to this codebase; not generic advice |
| Pitfalls | HIGH | 20 pitfalls identified with prevention strategies; all grounded in the specific codebase state described in CLAUDE.md |

**Overall confidence: HIGH**

### Gaps to Address

- **Candidate district-to-ZIP mapping query:** The officeholder path uses `zip_politicians` which links confirmed incumbents. Candidates may not have a confirmed district yet (they are running for a future seat). The query strategy for `GET /essentials/candidates/{zip}` needs validation against the actual `election_records` schema before Phase 5 implementation begins. Flag for the Phase 5 research step.
- **Stance randomization spectrum semantics:** STACK.md flags an open question: does "spectrum preserved" mean (a) shuffle any order or (b) flip direction only? Clarify with the team before Phase 3 begins — the implementation differs. Option (b) (flip direction) is simpler and recommended.
- **City/locale list for building images:** FEATURES.md notes that building image infrastructure should not be built for 50 cities if only 2 matter for the demo. Confirm the demo target localities (currently assumed: U.S. Capitol, state capitols generically, Bloomington City Hall, LA City Hall) before Phase 6 begins.
- **Monorepo Netlify site configuration:** Each app needs a Netlify site with `Base directory` set. Confirm which apps have active Netlify deployments before executing Phase 2 migration to avoid breaking CI for deployed sites.

## Sources

### Primary (HIGH confidence)
- iSideWith — political quiz UX patterns, guest-first quiz design
- Vote Compass — no-login quiz pattern, post-completion save CTA
- Center for Civic Design — voter guide field guide, candidate/incumbent labeling recommendations
- Ballotpedia — candidate vs. incumbent display, federal content ordering
- CLAUDE.md (codebase) — existing stack, completed phases, current implementation state
- EV-Backend source (Go modules) — Chi/GORM/Supabase versions and patterns
- Supabase Storage documentation — public bucket URLs, CDN capabilities, free tier limits

### Secondary (MEDIUM confidence)
- Pew Research Political Typology Quiz — fully anonymous quiz pattern
- Guides.vote (7M+ distribution) — candidate display in voter guide context
- Prism Political Quiz — seeded randomization for shareable quiz results
- PLOS One: "The political preferences of LLMs" — response order bias research validating stance randomization need
- npm workspaces documentation — monorepo consolidation pattern

### Tertiary (LOW confidence)
- Assumed BallotReady candidacy data freshness (7-14 day cycle) — should be validated against actual BallotReady release cadence before setting candidate cache TTL
- State capitol image availability on Wikipedia Commons — assumed public domain; verify licenses before use in production

---
*Research completed: 2026-02-17*
*Ready for roadmap: yes*
