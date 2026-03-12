# Feature Research

**Domain:** Read & Rank Integration — quote verdict sharing, standalone app extraction, topic-level integration in politician profiles
**Researched:** 2026-03-11
**Confidence:** HIGH (existing codebase fully inspected; all state shapes, API responses, and localStorage patterns confirmed from source)

---

## Context: What Already Exists

This is a subsequent milestone. The following are fully shipped and must not be changed unless explicitly in scope:

- `EV-prototypes/read-rank/`: Complete swipe-based quote evaluation app — IssueHub, EvaluationPhase, RankingPhase, ResultsPhase, CandidateAlignmentPage. Zustand store (`useReadRankStore`) with `persist` middleware writing to `localStorage` key `readrank-storage`.
- `GET /essentials/quotes`: Returns `{ quotes, candidates, issues }`. Read & Rank already consumes this.
- `essentials/`: CompassCard + StanceAccordion on politician profiles. CompassContext with priority chain: logged-in API > URL fragment > `localStorage` guest compass key `guestCompass`.
- URL fragment bridge: CompassV2 encodes compass data into `#compass=BASE64(...)` on navigation to Essentials. CompassContext reads and strips the fragment on mount, saves to `guestCompass` localStorage key for future visits.
- Session cookie with `Domain: .empowered.vote` — shared across all `*.empowered.vote` subdomains (shipped in v2026.3.2).

The gaps this milestone closes:

1. Read & Rank is only reachable via EV-prototypes Netlify deployment — no standalone URL, no fresh design
2. Quote verdicts (agreed/disagreed/ranked) exist only in `readrank-storage` on whichever subdomain the user visited — inaccessible to Essentials
3. Essentials politician profiles show compass stances but no quote-level verdicts per topic
4. URL fragment bridge is a workaround: one-time, breaks on direct navigation, not real sharing

---

## Feature Landscape

### Table Stakes (Users Expect These)

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Read & Rank accessible at a clean URL | A standalone civic tool needs its own home. `readrank.empowered.vote` sets expectations of a polished product. Any URL referencing "prototypes" signals an experiment, not a product. | MEDIUM | New GitHub repo + Cloudflare Pages deployment. Copy source from `EV-prototypes/read-rank`. Wire up `VITE_API_URL`. No changes to the actual swipe mechanics. Complexity is repo setup, not logic. |
| Quote verdicts visible on Essentials politician profiles under each topic | Users who evaluate a quote on Read & Rank expect that evaluation to show up when they're researching that politician on Essentials. The verdict is the insight — "I agreed with what Sen. X said about climate" is directly profile-relevant. | MEDIUM | Requires: (1) shared localStorage key accessible from `essentials.empowered.vote`, (2) reading verdicts from that key in StanceAccordion or a new sub-component, (3) rendering the verdict badge/label inline under the topic in the accordion. The hard part is the key must be readable cross-subdomain. |
| Cross-app localStorage sharing under `.empowered.vote` | Browsers enforce localStorage per origin (scheme + hostname + port). `readrank.empowered.vote` and `essentials.empowered.vote` have different hostnames — they cannot read each other's localStorage. This is a hard browser constraint. | MEDIUM | Standard pattern: use a shared key written to `sessionStorage`/`localStorage` under the root domain via an invisible iframe postMessage bridge OR write the shared verdict state to a key that both apps agree to read from a common location. The practical solution for this stack: a dedicated `localStorage` synchronization mechanism using a shared subdomain `storage.empowered.vote` as an iframe relay, OR move to a simpler approach — write verdicts to a backend endpoint and read them from any subdomain via the same session cookie that already works cross-subdomain. The session cookie already uses `Domain: .empowered.vote` so the logged-in path is straightforward. The guest path requires the iframe relay or an alternative. |
| Guest verdict sharing (no login required) | Compass works guest-first. Read & Rank works guest-first. Verdicts must also work guest-first or users who skip login get a broken experience on profiles. | HIGH | This is the technically hardest requirement. Cross-subdomain localStorage requires a relay mechanism. An iframe-based postMessage relay hosted at a shared origin (`shared.empowered.vote` or similar) is the standard pattern. Complexity: implementing the relay, testing cross-origin postMessage, handling race conditions. Alternative: encode verdicts in a URL fragment when navigating from Read & Rank to Essentials (same pattern as the compass bridge) — simpler but only works at point-of-navigation, not on subsequent profile visits. |
| Retire URL fragment bridge | The fragment bridge is a one-time one-way hand-off. Users visiting Essentials a second time from a bookmark get no compass data unless they came from CompassV2 again. Shared domain localStorage (or server storage) fixes this permanently. | LOW | Once the new sharing mechanism is live, remove the `parseCompassFragment` call from CompassContext and the fragment-encoding code from CompassV2. Remove the `guestCompass` localStorage key and replace with the new shared key. Sequence: new mechanism must be verified working before removing the old one. |

### Differentiators (Competitive Advantage)

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Visual refresh for standalone Read & Rank | The EV-prototypes version looks like a dev prototype — dark background, muted palette, inconsistent with Essentials/CompassV2 visual language. A polished standalone at `readrank.empowered.vote` using `ev-coral`, `ev-muted-blue`, Manrope font, and card-based design matches the platform brand and makes the tool demoable. | MEDIUM | Component-level visual changes only — swipe mechanics, store, and API integration stay identical. Focus: landing/hub page design, QuoteCard styling, ResultsPhase layout. The existing EvaluationPhase swipe mechanics are polished; the hub and results need the most work. |
| Server-side verdict storage for logged-in users | Verdicts stored only in localStorage are lost when users clear storage or switch devices. Logged-in users expect their data to follow them, consistent with how compass answers sync to the backend. | HIGH | Requires: (1) new `essentials.quote_verdicts` table (politician_id, topic_key, quote_id, verdict: agreed/disagreed, rank, badge), (2) backend endpoints (upsert verdict, get verdicts for user), (3) Read & Rank writes to API when logged in, localStorage when guest, (4) CompassContext-style priority chain in verdict reading: API > localStorage > empty. Session cookie already works cross-subdomain for logged-in users so no additional auth work is needed. |
| "You agreed/disagreed" inline badge on StanceAccordion rows | Each StanceAccordion row shows the politician's stance on a topic. Showing the user's own verdict from Read & Rank inline (a small "You agreed" green badge or "You disagreed" red badge next to the politician's stance label) provides immediate context without requiring a separate section or UI disruption. | LOW | Conditional rendering: if `verdicts[topic_key]` exists, render a badge. No layout change — badge appears alongside existing stance label. Depends on verdicts being accessible in Essentials context. |
| "Explore this topic on Read & Rank" deep-link from StanceAccordion | When a StanceAccordion row is expanded, show a small CTA: "See what politicians said about [topic] →" linking to `readrank.empowered.vote?topic=[topic_key]`. Deep-link support requires Read & Rank to accept a `?topic=` query param and auto-enter the appropriate issue on load. | LOW | Two parts: (a) add `?topic=` query param handling to Read & Rank IssueHub to pre-select and immediately start an issue, (b) add the deep-link in StanceAccordion expanded content. No backend changes. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time cross-tab verdict sync | "If I rate a quote in one tab, the other tab should update" | Adds BroadcastChannel/SharedWorker complexity. Zero practical value — users don't have Read & Rank and Essentials open simultaneously in a workflow that requires live sync. | Let the profile page re-read localStorage on mount. Stale-on-same-visit is acceptable; fresh on next page load is sufficient. |
| Verdict analytics / aggregated scores | "Show what percentage of users agreed with each politician" | Antipartisan mission of the platform. Aggregated verdicts become a popularity ranking, which is exactly what the platform is trying to replace with individual alignment. | Keep verdicts private and personal — "you agreed" not "60% of users agreed". |
| Full candidate profile page inside Read & Rank | ResultsPhase currently has a "View Your Alignment" CTA that navigates to `/candidate/:id/alignment` (CandidateAlignmentPage). A full politician profile would duplicate what Essentials does and require maintaining two copies of profile data. | Maintenance burden. Data duplication. Different data access patterns (Read & Rank uses `candidateId` string, Essentials uses DB politician UUID). | CandidateAlignmentPage in Read & Rank shows verdict summary for one candidate. The CTA links to `essentials.empowered.vote/profile/:slug` for the full profile. No duplication. |
| Automatic verdict migration from old `readrank-storage` key to new shared key | "Migrate existing user verdicts from the EV-prototypes deployment" | Users accessing EV-prototypes have zero overlap with `readrank.empowered.vote` — different origins, no cookie sharing. Migration is impossible without user action. | Accept that the standalone launch starts fresh. No migration needed. |
| Verdict-weighted compass alignment score | "Use Read & Rank verdicts to adjust the radar chart" | Compass measures stance similarity on abstract policy positions. Quotes are specific statements with rhetoric that may not represent a politician's actual vote record. Mixing the two produces an unreliable hybrid. | Keep them separate. Compass shows stance overlap. Read & Rank shows quote-by-quote reactions. Present them side by side on profiles, not merged. |

---

## Feature Dependencies

```
[Shared .empowered.vote localStorage OR server-side verdicts]
    └──required-by──> Guest verdict reading in Essentials
    └──required-by──> "You agreed/disagreed" badge on StanceAccordion
    └──required-by──> Retire URL fragment bridge (guest compass must use new shared storage)

[Read & Rank standalone repo at readrank.empowered.vote]
    └──enables──> Clean URL for deep-links from StanceAccordion
    └──enables──> Cloudflare Pages deployment (consistent with CompassV2 and Essentials)
    └──independent-of──> Shared localStorage mechanism (can deploy standalone before sharing works)

[Server-side verdict storage]
    └──requires──> New DB table + backend endpoints
    └──requires──> Read & Rank writes to API when logged in
    └──enhances──> Shared localStorage (logged-in users don't need the iframe relay)
    └──parallel-to──> Guest localStorage sharing (both must work; guest path is the harder one)

["You agreed/disagreed" badge on StanceAccordion]
    └──requires──> Verdicts accessible in Essentials (via shared localStorage or API)
    └──requires──> Verdict data keyed by topic_key (matches Quote.issue field from API)
    └──independent-of──> Visual refresh (badge works in both old and new design)

["Explore on Read & Rank" deep-link]
    └──requires──> Read & Rank standalone at readrank.empowered.vote
    └──requires──> ?topic= query param handling in Read & Rank IssueHub
    └──independent-of──> Verdict sharing mechanism

[Retire URL fragment bridge]
    └──requires──> Shared localStorage or server storage working for guest compass data
    └──requires──> Verification that new mechanism handles all guest paths
    └──last-step──> Must be done AFTER new mechanism is confirmed working
```

### Dependency Notes

- **Critical path:** Shared localStorage (or server-side for logged-in users) must ship before "You agreed/disagreed" badges can appear in Essentials. Everything else is independent.
- **Standalone repo ships before sharing works:** The standalone deployment can launch with the same isolated `readrank-storage` localStorage behavior as today. Verdict sharing is a second step.
- **Guest sharing is the hardest problem:** The iframe postMessage relay pattern is the browser-standard solution but adds ~1 day of implementation + testing. An alternative for the guest path: write verdicts to a shared key at a predictable origin using a relay page. A simpler but limited alternative: encode verdicts in the URL when navigating to Essentials (same as the existing compass bridge) — one-time hand-off only.
- **Server-side storage unlocks logged-in cross-device sync:** The session cookie already works across all `*.empowered.vote` subdomains. For logged-in users, POST `/essentials/verdicts` from Read & Rank and GET `/essentials/verdicts` in Essentials is sufficient — no localStorage magic needed for this path.

---

## MVP Definition

### Launch With (v2026.3.4)

Minimum needed to validate the concept and deliver visible user value.

- [ ] **Read & Rank standalone repo and deployment** — New repo, Cloudflare Pages, `readrank.empowered.vote`. Same mechanics, polished visual design. No swipe/store changes. Required before any cross-app linking works.
- [ ] **Server-side verdict storage for logged-in users** — `essentials.quote_verdicts` table. POST `/essentials/verdicts` (upsert). GET `/essentials/verdicts` (for current user). Read & Rank writes to API when session cookie present; localStorage when guest. This is the reliable path and directly reuses the existing session cookie infrastructure.
- [ ] **"You agreed/disagreed" badge on StanceAccordion for logged-in users** — Read verdicts from `/essentials/verdicts` in Essentials CompassContext (or a parallel VerdictContext). Show agree/disagree badge inline in StanceAccordion rows where a verdict exists. Scoped to logged-in users initially.
- [ ] **Guest verdict sharing via URL fragment** — When navigating from Read & Rank results to an Essentials profile, encode the current issue's verdicts in the URL (e.g., `#verdicts=BASE64(...)`). Essentials reads and caches in localStorage. Same pattern as the compass bridge — one-time hand-off, good enough for the guest MVP path. The `guestVerdicts` key mirrors `guestCompass`.

### Add After Validation (v1.x)

- [ ] **Persistent guest verdict storage via shared subdomain relay** — Implement the iframe postMessage relay at `shared.empowered.vote` (or reuse a lightweight relay page) to write a shared verdict key accessible from both `readrank.empowered.vote` and `essentials.empowered.vote`. Trigger: user testing reveals that guests lose verdicts between sessions frequently enough to be a friction point.
- [ ] **"Explore this topic on Read & Rank" deep-link from StanceAccordion** — `?topic=` query param handling in IssueHub. CTA link in StanceAccordion expanded content. Trigger: after standalone Read & Rank is live.
- [ ] **Retire URL fragment compass bridge** — Replace with shared localStorage mechanism once proven. Trigger: new sharing mechanism confirmed reliable across browsers.
- [ ] **Visual refresh completion** — Full landing page, onboarding micro-copy, empty state polish. Trigger: after standalone launch confirms the basic experience works.

### Future Consideration (v2+)

- [ ] **Cross-device verdict sync for guests** — Would require account creation or device-linking. Out of scope until there's clear demand.
- [ ] **Verdict history view on profile pages** — "All quotes I evaluated for this politician." Requires enough users with verdict history to validate demand.
- [ ] **Read & Rank progress across all issues shown on Essentials profile** — "You've evaluated 3 of 5 issues with this politician's quotes." Needs verdict data indexed by politician_id, which the server-side storage provides.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Standalone Read & Rank repo + Cloudflare Pages | HIGH — prerequisite for everything else | MEDIUM — repo setup + CF Pages config | P1 |
| Visual refresh (standalone) | HIGH — demoable product | MEDIUM — frontend-only | P1 |
| Server-side verdict storage (logged-in) | HIGH — reliable cross-app sharing | HIGH — new DB table + 2 endpoints + store changes | P1 |
| "You agreed/disagreed" badge in StanceAccordion (logged-in) | HIGH — direct profile value | LOW — frontend rendering using existing accordion structure | P1 |
| Guest verdict URL fragment bridge | MEDIUM — guest continuity at navigation time | LOW — mirrors existing compass bridge pattern | P1 |
| "Explore on Read & Rank" deep-link | MEDIUM — drives engagement between apps | LOW — query param + one CTA link | P2 |
| Persistent guest verdict storage (iframe relay) | MEDIUM — removes guest friction long-term | HIGH — cross-origin relay setup + testing | P2 |
| Retire URL fragment compass bridge | LOW — cleanup | LOW — delete code after new mechanism verified | P2 |
| Cross-device verdict sync for guests | LOW — edge case | HIGH — auth or device linking required | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Cross-App State Sharing Patterns (Domain-Specific Research)

The core challenge — sharing state between `readrank.empowered.vote` and `essentials.empowered.vote` — is a well-understood browser constraint problem. These are the viable patterns for this stack:

### Pattern A: Server as Shared State (recommended for logged-in users)
Store verdicts in the database. Read them via API from any subdomain using the existing session cookie (`Domain: .empowered.vote`). No localStorage engineering needed for this path. This is the right pattern for the logged-in case.

**Confidence:** HIGH — session cookie already verified working cross-subdomain (v2026.3.2 fix).

### Pattern B: URL Fragment Hand-off (recommended for guest MVP)
When navigating cross-subdomain, encode state in `#fragment=BASE64(...)`. The destination app reads and strips the fragment on mount, then saves to its own localStorage. This is already proven by the existing compass bridge. One-time hand-off: data is available only after direct navigation, not on subsequent sessions.

**Confidence:** HIGH — identical pattern already in production.

### Pattern C: Shared Subdomain iframe Relay (for persistent guest sharing)
A lightweight HTML page hosted at a shared origin (e.g., `shared.empowered.vote/storage.html`) acts as a localStorage broker. Both apps open it in a hidden iframe and use `postMessage` to read/write. This is the standard browser workaround for cross-subdomain localStorage.

**Confidence:** MEDIUM — pattern is well-documented but adds setup complexity and an additional subdomain/deployment to manage. Race condition handling required.

### Pattern D: BroadcastChannel / SharedWorker
Works only for same-origin tabs. Does not solve cross-subdomain sharing. Not applicable here.

**Confidence:** HIGH that this does NOT apply.

---

## localStorage Key Contract

For cross-app sharing to work, both apps must agree on key names and data format. Recommended:

| Key | Owner | Format | Notes |
|-----|-------|--------|-------|
| `readrank-storage` | Read & Rank only | Zustand persist blob (existing) | Not shared; internal to Read & Rank |
| `guestCompass` | Essentials only | `{ a: {short_title: value}, s: [topicId], i: {spoke: bool} }` | Existing; may retire when fragment bridge retires |
| `ev-verdicts` | Shared (Read & Rank writes, Essentials reads) | `{ [topic_key]: { agreed: [quoteId], disagreed: [quoteId], badges: { diamond: quoteId, gold: quoteId } } }` | New; scoped to guest path; logged-in path uses API |

The `ev-verdicts` key design is scoped by topic_key (matching the `Quote.issue` field from the API) to enable O(1) lookup when rendering StanceAccordion rows.

---

## Sources

- Codebase: `EV-prototypes/read-rank/src/store/useReadRankStore.ts` — Zustand store shape, `readrank-storage` key, IssueProgress structure, agreed/disagreed/badge state
- Codebase: `EV-prototypes/read-rank/src/data/api.ts` — `fetchQuotesData()` consuming `GET /essentials/quotes`
- Codebase: `essentials/src/contexts/CompassContext.jsx` — Priority chain pattern: API > fragment > localStorage; `guestCompass` key
- Codebase: `essentials/src/lib/compass.js` — `parseCompassFragment`, `saveGuestCompass`, `loadGuestCompass`, `clearGuestCompass`
- Codebase: `essentials/src/components/CompassCard.jsx` — Profile section structure, StanceAccordion integration
- Codebase: `essentials/src/components/StanceAccordion.jsx` — Per-topic row structure, lazy context fetch, accordion expand/collapse
- Codebase: `EV-Backend/internal/essentials/handlers.go` — `GetQuotes` handler, `QuoteOut` struct, `CandidateReadRankOut` struct
- Codebase: `EV-Backend/internal/essentials/routes.go` — `GET /quotes` route confirmed
- MDN Web Docs (cross-origin localStorage): https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage — iframe postMessage pattern for cross-origin storage relay
- Browser storage spec: Same-origin policy for localStorage enforced by hostname — `readrank.empowered.vote` and `essentials.empowered.vote` are different origins despite same parent domain

---
*Feature research for: v2026.3.4 Read & Rank Integration milestone*
*Researched: 2026-03-11*
